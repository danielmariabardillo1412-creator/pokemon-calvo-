extends "res://scenes/visual/battle_community_move_pilot.gd"

## Confirmed damage only. Never plays native body withdrawal/expulsion cells,
## selects a replacement or treats a KO replacement as a move's special effect.
const EXTERNAL_PACK := "res://.godot/battle_external_damage/manifest.json"
const PACK_SHA := "175ceb67c22c67ec90aca69eb79697b5a4c95f2568226d04c8e82c03079e6105"
const DAMAGE_PROFILES := {
	"circle_throw": {"frames": 19, "impact_frame": 2, "hp_end_frame": 10, "reference": "CIRCLETHROW", "classification": "RUNTIME_SUPPORTED", "type_id": "fighting", "category": "physical", "power": 60},
	"dragon_tail": {"frames": 20, "impact_frame": 7, "hp_end_frame": 15, "reference": "DRAGONTAIL", "classification": "RUNTIME_SUPPORTED", "type_id": "dragon", "category": "physical", "power": 60},
	"flip_turn": {"frames": 30, "impact_frame": 12, "hp_end_frame": 20, "reference": "FLIPTURN", "classification": "PARTIAL_RUNTIME", "type_id": "water", "category": "physical", "power": 60},
	"u_turn": {"frames": 28, "impact_frame": 14, "hp_end_frame": 22, "reference": "UTURN", "classification": "RUNTIME_SUPPORTED", "type_id": "bug", "category": "physical", "power": 70},
	"volt_switch": {"frames": 26, "impact_frame": 18, "hp_end_frame": 24, "reference": "VOLTSWITCH", "classification": "RUNTIME_SUPPORTED", "type_id": "electric", "category": "special", "power": 70},
}


func configure(arena: Control, path: String = EXTERNAL_PACK) -> void:
	preview = Preview.new()
	preview.effects_only = true
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.add_child(preview)
	preview.hide()
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != PACK_SHA:
		last_error = "Pack de daño externo ausente o distinto del validado"
		return
	if not preview.load_pack(path):
		last_error = preview.last_error
		return
	var data: Dictionary = preview.pack
	if data.get("selection") != "battle_external_damage_v1" or data.get("scope") != "CONFIRMED_DAMAGE_ONLY_NO_PIVOT_OR_PHAZE" or data.clips.size() != 10:
		last_error = "Selección externa no habilitada"
		return
	for n in data.clips.size():
		var row: Dictionary = data.clips[n]
		var profile := _profile(String(row.move_id), String(row.actor_side))
		if profile.is_empty() or row.frames.size() != profile.frames or row.fps != 20 or row.reference_animation_id != profile.reference or row.classification_unchanged != profile.classification:
			last_error = "Contrato de daño externo distinto"
			_indices.clear()
			return
		_indices[String(row.id)] = n
	available = _indices.size() == 10


func _profile(move: String, _side: String) -> Dictionary:
	return DAMAGE_PROFILES.get(move, {}).duplicate(true)


func _accepts(move: String, metadata: Dictionary) -> bool:
	if not DAMAGE_PROFILES.has(move) or metadata.get("effects_empty") != true or metadata.get("target") != "selected-pokemon":
		return false
	var profile: Dictionary = DAMAGE_PROFILES[move]
	for field: String in ["classification", "type_id", "category", "power"]:
		if metadata.get(field) != profile[field]:
			return false
	return true


func decorate(sequence: Array[Dictionary], before: Dictionary) -> Array[Dictionary]:
	if not available:
		return sequence
	var result := super.decorate(sequence, before)
	for step: Dictionary in result:
		if DAMAGE_PROFILES.has(String(step.get("community_clip", "")).get_base_dir()):
			var mechanics_pilot := bool(before.get("switch_move_rules_enabled", false))
			step["external_damage_only"] = not mechanics_pilot
			step["special_effect_implemented"] = mechanics_pilot
			if not mechanics_pilot:
				var note := "[Prueba: el daño está resuelto; el efecto de relevo/expulsión sigue pendiente.]"
				step.text = String(step.get("text", "")) + ("\n" if not String(step.get("text", "")).is_empty() else "") + note
	return result
