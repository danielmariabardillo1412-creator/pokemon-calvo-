extends Node

# Narrow experimental binding. The full laboratory is never enabled as a move
# registry. All battle amounts/actors come from the existing resolved timeline.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const PACK := "res://.godot/battle_elemental_pilot/manifest.json"
const BASE_PACK := "res://.godot/battle_base_pilot/manifest.json"
const LEGACY_PACK := "res://.godot/battle_ivy_pilot/manifest.json"
const CONTRACTS := {
	"ivy_cudgel": {"frames": 38, "impact_frame": 29, "hp_end_frame": 37, "reference": "IVYCUDGEL", "classification": "RUNTIME_SUPPORTED", "type_id": "grass", "category": "physical"},
	"tera_blast": {"frames": 70, "impact_frame": 47, "hp_end_frame": 59, "reference": "TECHNOBLAST", "classification": "PARTIAL_RUNTIME", "type_id": "normal", "category": "special"},
	"flamethrower": {"frames": 19, "front_frames": 20, "impact_frame": 7, "front_impact_frame": 8, "hp_end_frame": 18, "reference": "FLAMETHROWER", "classification": "RUNTIME_SUPPORTED", "type_id": "fire", "category": "special", "power": 90},
	"thunderbolt": {"frames": 27, "impact_frame": 14, "hp_end_frame": 23, "reference": "THUNDERBOLT", "classification": "RUNTIME_SUPPORTED", "type_id": "electric", "category": "special", "power": 90},
	"ice_beam": {"frames": 28, "impact_frame": 6, "hp_end_frame": 22, "reference": "ICEBEAM", "classification": "RUNTIME_SUPPORTED", "type_id": "ice", "category": "special", "power": 90}}
var preview: Control
var available := false
var last_error := ""
var _indices: Dictionary = {}


func configure(arena: Control, path: String = PACK) -> void:
	preview = Preview.new()
	preview.effects_only = true
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.add_child(preview)
	preview.hide()
	if path == PACK and not FileAccess.file_exists(path):
		path = BASE_PACK if FileAccess.file_exists(BASE_PACK) else LEGACY_PACK
	if not preview.load_pack(path):
		last_error = preview.last_error
		return  # Optional local cache missing: existing presentation remains intact.
	var data: Dictionary = preview.pack
	var legacy: bool = data.get("selection") == "battle_ivy_base"
	var elemental: bool = data.get("selection") == "battle_elemental_set"
	if not (legacy and data.clips.size() == 2 or data.get("selection") == "battle_base_pair" and data.clips.size() == 4 or elemental and data.clips.size() == 10):
		last_error = "Selección no habilitada para combate"
		return
	var bindings: Dictionary = {"ivy_cudgel": data.get("battle_pilot", {})} if legacy else data.get("battle_bindings", {})
	var expected: Array = ["ivy_cudgel"] if legacy else ["ivy_cudgel", "tera_blast"]
	if elemental:
		expected.append_array(["flamethrower", "thunderbolt", "ice_beam"])
	if bindings.size() != expected.size():
		last_error = "Marcadores incompletos"
		return
	for move: String in expected:
		var timing: Dictionary = bindings.get(move, {})
		for side: String in ["back", "front"]:
			var marker: Dictionary = timing.get(side, timing)
			var profile := _profile(move, side)
			if marker.get("impact_frame") != profile.impact_frame or marker.get("hp_end_frame") != profile.hp_end_frame:
				last_error = "Marcadores de impacto no validados"
				return
	for index in data.clips.size():
		var row: Dictionary = data.clips[index]
		var contract: Dictionary = _profile(String(row.move_id), String(row.actor_side))
		if not row.move_id in expected or contract.is_empty() or row.frames.size() != contract.frames or row.fps != 20 or row.reference_animation_id != contract.reference or row.classification_unchanged != contract.classification or not String(row.context_key).is_empty() or not String(row.variant_key).is_empty():
			last_error = "Referencia no habilitada para este piloto"
			_indices.clear()
			return
		_indices[String(row.id)] = index
	available = true
	for move: String in expected:
		available = available and _indices.has(move + "/back") and _indices.has(move + "/front")


func _accepts(move: String, metadata: Dictionary) -> bool:
	if not CONTRACTS.has(move):
		return false
	var contract: Dictionary = CONTRACTS[move]
	if metadata.get("classification") != contract.classification or metadata.get("type_id") != contract.type_id or metadata.get("category") != contract.category:
		return false
	if contract.has("power") and (metadata.get("power") != contract.power or metadata.get("target") != "selected-pokemon"):
		return false
	# One audited partial subset, never a blanket PARTIAL_RUNTIME admission.
	return move != "tera_blast" or (metadata.get("power") == 80 and metadata.get("target") == "selected-pokemon" and metadata.get("effects_empty") == true)


func _profile(move: String, side: String) -> Dictionary:
	var profile: Dictionary = CONTRACTS.get(move, {}).duplicate()
	if side == "front":
		for field: String in ["frames", "impact_frame", "hp_end_frame"]:
			if profile.has("front_" + field):
				profile[field] = profile["front_" + field]
	return profile


func decorate(sequence: Array[Dictionary], before: Dictionary) -> Array[Dictionary]:
	if not available:
		return sequence
	var result: Array[Dictionary] = []
	for source: Dictionary in sequence:
		var step := source.duplicate(true)
		var visual: Dictionary = step.get("move_visual", {})
		var move := String(visual.get("move_id", ""))
		if step.get("event_kind") == String(BattleEvent.DAMAGE_APPLIED) and visual.get("phase") == "hit" and _accepts(move, before.get("moves", {}).get(move, {})):
			var origin := String(visual.get("source_side", ""))
			var target := String(visual.get("target_side", ""))
			var from: Dictionary = step.views.get(target, {})
			var to: Dictionary = step.after_views.get(target, {})
			if _indices.has(move + "/" + origin) and origin in ["back", "front"] and target in ["back", "front"] and origin != target and not from.is_empty() and not to.is_empty() and int(from.hp) > int(to.hp):
				var profile := _profile(move, origin)
				step.community_clip = move + "/" + origin
				step.duration = float(profile.frames) / 20.0
				step.community_impact = float(profile.impact_frame) / 20.0
				step.community_hp_end = float(profile.hp_end_frame) / 20.0
				step.state = "reposo"
				step.erase("move_visual") # Never double-render the generic elemental hit.
		result.append(step)
	# Keep the existing body preparation, but do not add an unrelated procedural
	# grass glyph in front of a confirmed-hit community clip. Misses keep fallback.
	for index in result.size():
		if not result[index].has("community_clip"):
			continue
		var origin := String(result[index].community_clip).get_file()
		var move := String(result[index].community_clip).get_base_dir()
		for prior in range(index - 1, -1, -1):
			if result[prior].get("event_kind") != String(BattleEvent.ACTION_USED):
				continue
			var cast: Dictionary = result[prior].get("move_visual", {})
			if cast.get("move_id") == move and cast.get("source_side") == origin:
				result[prior].erase("move_visual")
				result[prior].community_preparation = true
			break
	return result


func show_entry(entry: Dictionary, arena: Control, elapsed: float) -> void:
	var id := String(entry.get("community_clip", ""))
	if not available or not _indices.has(id):
		clear()
		return
	preview.size = arena.size
	preview.back_species = arena.player_species
	preview.front_species = arena.enemy_species
	preview.affine_particle_path = id.get_base_dir() == "tera_blast"
	if preview.clip.get("id", "") != id:
		preview.select_clip(_indices[id])
	preview.show_seconds(clampf(elapsed, 0.0, float(entry.duration) - 0.000001))
	preview.show()


func clear() -> void:
	if is_instance_valid(preview):
		preview.hide()
		preview.clear_preview()
