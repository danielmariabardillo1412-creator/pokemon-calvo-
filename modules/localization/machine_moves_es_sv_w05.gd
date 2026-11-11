class_name MachineMovesEsSvW05
extends RefCounted

# Consulta exclusivamente textos de movimientos MT autorizados (Scarlet/Violet).
# NO modifica el move_id, los catálogos, los PP ni las reglas de aprendizaje.
const SOURCE_PATH := "res://data/localization/machine_moves_es_sv_v1.json"
static var _loaded: bool = false
static var _entries: Dictionary = {}


static func _load_once() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(SOURCE_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_PATH))
	if not data is Dictionary:
		return
	if data.get("schema_version", 0) != 1 or data.get("locale", "") != "es":
		return
	if data.get("version", "") != "scarlet-violet" or int(data.get("active_books", 0)) != 229:
		return
	var rows: Variant = data.get("entries", {})
	if not rows is Dictionary or rows.size() != 229:
		return
	_entries = rows


# Valor neutro cuando falta una traducción: deja el fallback explícito.
# La tabla fuente tiene 229 entradas PokeAPI names.es verificadas individualmente.
static func resolve(move_id: StringName, fallback: String = "") -> Dictionary:
	_load_once()
	var raw: Variant = _entries.get(String(move_id), null)
	if raw is Dictionary:
		var nombre := String(raw.get("nombre_es", ""))
		var api_id := int(raw.get("source_api_id", 0))
		if nombre.strip_edges() != "" and api_id > 0:
			return {"name": nombre, "verified_es": true, "source_api_id": api_id,
				"source_locale": "es", "move_id": String(move_id)}
	return {"name": fallback, "verified_es": false, "source_api_id": 0,
		"source_locale": "fallback", "move_id": String(move_id)}
