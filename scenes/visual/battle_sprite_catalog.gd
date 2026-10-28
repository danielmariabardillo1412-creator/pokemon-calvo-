extends RefCounted

# Presentation-only adapter: no battle rules or gameplay RNG.
const PACK_ROOT := "res://assets/local_battle_catalog/"
const MANIFEST_PATH := PACK_ROOT + "manifest.json"
const METRICS_PATH := PACK_ROOT + "presentation_metrics.json"
const SCALE_REFERENCE_PATH := PACK_ROOT + "scale_reference.json"
const VARIANT_ROOT := "res://assets/local_battle_variants/"
const VARIANT_MANIFEST := VARIANT_ROOT + "manifest.json"
const MAX_CACHE_ENTRIES := 8
const MAX_CACHE_BYTES := 128 * 1024 * 1024
static var _manifest: Dictionary = {}
static var _loaded := false
static var _cache: Dictionary = {}
static var _lru: Array[String] = []
static var _cache_bytes := 0
static var _metrics: Dictionary = {}
static var _metrics_loaded := false
static var _scale_reference: Dictionary = {}
static var _scale_reference_loaded := false
static var last_error := ""
static var _variants_loaded := false
static var _variants: Dictionary = {}


static func species_rows() -> Dictionary:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(MANIFEST_PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
			if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("species") is Dictionary:
				_manifest = parsed
	var rows: Dictionary = _manifest.get("species", {}).duplicate()
	_load_variants()
	for key: String in _variants:
		if not key.ends_with("__shiny"): rows[key] = _variants[key]
	return rows


static func _load_variants() -> void:
	if _variants_loaded: return
	_variants_loaded = true
	if not FileAccess.file_exists(VARIANT_MANIFEST): return
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/pokemon_variants_v1.json"))
	if not config is Dictionary or config.get("asset_manifest_sha256") != FileAccess.get_sha256(VARIANT_MANIFEST): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VARIANT_MANIFEST))
	if not parsed is Dictionary or parsed.get("version") != 1: return
	if parsed.get("base_manifest_sha256") != FileAccess.get_sha256(MANIFEST_PATH): return
	_variants = parsed.get("entries", {})


static func row_for(species: StringName) -> Dictionary:
	_load_variants()
	if _variants.has(String(species)): return _variants[String(species)]
	return species_rows().get(String(species), {})


static func has_shiny(species: StringName) -> bool:
	_load_variants()
	return _variants.has(String(species) + "__shiny")


static func clear_cache() -> void:
	_cache.clear()
	_lru.clear()
	_cache_bytes = 0


static func presentation_metrics() -> Dictionary:
	if not _metrics_loaded:
		_metrics_loaded = true
		if FileAccess.file_exists(METRICS_PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(METRICS_PATH))
			if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("species") is Dictionary:
				if parsed.get("manifest_sha256", "") == FileAccess.get_sha256(MANIFEST_PATH):
					_metrics = parsed.species
	return _metrics


static func presentation_bounds(species: StringName, side: String, clip: Dictionary) -> Rect2:
	var box: Array = presentation_metrics().get(String(species), {}).get(side, {}).get("bounds", [])
	_load_variants()
	if _variants.has(String(species)):
		box = _variants[String(species)].get("metrics", {}).get(side, {}).get("bounds", [])
	if box.size() == 4:
		var factor := presentation_scale(species, side)
		return Rect2(Vector2(float(box[0]), float(box[1])) * factor, Vector2(float(box[2]) - float(box[0]), float(box[3]) - float(box[1])) * factor)
	# Optional pack metrics absent/stale: conservative full-cell bounds, not an alias.
	var region: Array = clip.regions[0]
	return Rect2(-Vector2(clip.pivot) * float(clip.unit_scale), Vector2(float(region[2]), float(region[3])) * float(clip.unit_scale))


static func scale_references() -> Dictionary:
	if not _scale_reference_loaded:
		_scale_reference_loaded = true
		if FileAccess.file_exists(SCALE_REFERENCE_PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCALE_REFERENCE_PATH))
			if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("species") is Dictionary:
				if parsed.get("manifest_sha256", "") == FileAccess.get_sha256(MANIFEST_PATH):
					_scale_reference = parsed.species
	return _scale_reference


static func presentation_scale(species: StringName, side: String) -> float:
	var factor := float(scale_references().get(String(species), {}).get(side, {}).get("factor", 1.0))
	return factor if is_finite(factor) and factor > 0.0 else 1.0


static func cache_stats() -> Dictionary:
	return {"entries": _cache.size(), "bytes": _cache_bytes}


static func animation(species: StringName, side: String, state: String = "reposo") -> Dictionary:
	last_error = ""
	var key := "%s/%s/%s" % [species, state, side]
	if _cache.has(key):
		_lru.erase(key)
		_lru.append(key)
		return _cache[key]
	var row: Dictionary = row_for(species)
	var view: Dictionary = row.get("states", {}).get(state, {}).get(side, {})
	if view.is_empty():
		last_error = "Sin recurso: " + key
		return {}
	var relative := String(view.get("atlas", ""))
	if not relative.begins_with("atlases/") or relative.contains("..") or relative.contains(":") or relative.contains("\\"):
		last_error = "Ruta inválida: " + key
		return {}
	var path := (VARIANT_ROOT if _variants.has(String(species)) else PACK_ROOT) + relative
	if not FileAccess.file_exists(path):
		last_error = "Archivo ausente: " + key
		return {}
	if _variants.has(String(species)) and FileAccess.get_sha256(path) != view.get("sha256", ""):
		last_error = "Recurso alterado: " + key
		return {}
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		last_error = "PNG ilegible: " + key
		return {}
	var dimensions: Array = view.get("dimensions", [])
	if dimensions.size() != 2 or image.get_width() != int(dimensions[0]) or image.get_height() != int(dimensions[1]):
		last_error = "Dimensiones inválidas: " + key
		return {}
	var regions: Array = view.get("regions", [])
	var durations: Array = view.get("durations", [])
	if regions.is_empty() or regions.size() != durations.size():
		last_error = "Fotogramas inválidos: " + key
		return {}
	var ends: Array[float] = []
	var seconds := 0.0
	for index in regions.size():
		var region: Array = regions[index]
		if region.size() != 4 or float(durations[index]) <= 0.0:
			last_error = "Región/cadencia inválida: " + key
			return {}
		var rect := Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
		if rect.size.x <= 0 or rect.size.y <= 0 or not Rect2(Vector2.ZERO, Vector2(image.get_size())).encloses(rect):
			last_error = "Región fuera de atlas: " + key
			return {}
		seconds += float(durations[index])
		ends.append(seconds)
	var bytes := image.get_width() * image.get_height() * 4
	if bytes > MAX_CACHE_BYTES:
		last_error = "Atlas demasiado grande: " + key
		return {}
	while not _lru.is_empty() and (_cache.size() >= MAX_CACHE_ENTRIES or _cache_bytes + bytes > MAX_CACHE_BYTES):
		var oldest: String = _lru.pop_front()
		_cache_bytes -= int(_cache[oldest].bytes)
		_cache.erase(oldest)
	var result := {"texture": ImageTexture.create_from_image(image), "regions": regions,
		"ends": ends, "seconds": seconds, "loop": bool(view.get("loop", true)),
		"pivot": Vector2(float(view.pivot[0]), float(view.pivot[1])),
		"unit_scale": float(view.get("unit_scale", 1.0)) * presentation_scale(species, side), "bytes": bytes}
	_cache[key] = result
	_lru.append(key)
	_cache_bytes += bytes
	return result


static func frame_index(clip: Dictionary, elapsed: float) -> int:
	if clip.is_empty():
		return -1
	var time := maxf(0.0, elapsed)
	if bool(clip.loop):
		time = fmod(time, float(clip.seconds))
	for index in clip.ends.size():
		if time < float(clip.ends[index]):
			return index
	return clip.ends.size() - 1
