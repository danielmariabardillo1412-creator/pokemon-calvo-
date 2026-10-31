extends "res://scenes/visual/battle_community_move_pilot.gd"

const STATUS_PACK := "res://.godot/battle_status_switch/manifest.json"
const STATUS_SHA := "6e6255dee81de130110edb89c3fa8ca5b161ce72a05524d9d2b4e54bf41ffb81"
const PROFILES := {
	"roar": {"frames": 21, "cue": 5, "reference": "ROAR", "type_id": "normal", "target": "selected-pokemon"},
	"whirlwind": {"frames": 26, "cue": 1, "reference": "GUST", "type_id": "normal", "target": "selected-pokemon"},
	"teleport": {"frames": 21, "cue": 6, "reference": "TELEPORT", "type_id": "psychic", "target": "user"},
	"baton_pass": {"frames": 31, "front_frames": 35, "cue": 0, "reference": "BATONPASS", "type_id": "normal", "target": "user"},
	"parting_shot": {"frames": 26, "cue": 2, "reference": "PARTINGSHOT", "type_id": "dark", "target": "selected-pokemon"}}


func configure(arena: Control, path: String = STATUS_PACK) -> void:
	preview = Preview.new()
	preview.effects_only = true
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.add_child(preview)
	preview.hide()
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != STATUS_SHA or not preview.load_pack(path):
		last_error = "Pack de efectos de estado ausente o distinto del validado"
		return
	if preview.pack.get("selection") != "status_switch_v1" or preview.pack.get("scope") != "EXPLICIT_SINGLES_CONFIRMED_STATUS_ONLY" or preview.pack.clips.size() != 10:
		last_error = "Selección de estado inválida"
		return
	for n in preview.pack.clips.size():
		var clip: Dictionary = preview.pack.clips[n]
		var profile := _profile(String(clip.move_id), String(clip.actor_side))
		if profile.is_empty() or clip.frames.size() != profile.frames or clip.fps != 20 or clip.reference_animation_id != profile.reference or clip.classification_unchanged != "DATA_ONLY":
			last_error = "Contrato de estado distinto"
			_indices.clear()
			return
		_indices[String(clip.id)] = n
	available = _indices.size() == 10


func _profile(move: String, side: String) -> Dictionary:
	var profile: Dictionary = PROFILES.get(move, {}).duplicate()
	if side == "front" and profile.has("front_frames"):
		profile.frames = profile.front_frames
	return profile


func _accepts(move: String, metadata: Dictionary) -> bool:
	if not PROFILES.has(move):
		return false
	return metadata.get("classification") == "DATA_ONLY" and metadata.get("effects_empty") == true \
		and metadata.get("power") == 0 and metadata.get("category") == "status" \
		and metadata.get("type_id") == PROFILES[move].type_id and metadata.get("target") == PROFILES[move].target


func decorate(sequence: Array[Dictionary], before: Dictionary) -> Array[Dictionary]:
	if not available or not _enabled(before):
		return sequence
	var result: Array[Dictionary] = []
	for original: Dictionary in sequence:
		var step := original.duplicate(true)
		var resolved: Dictionary = step.get("resolved_status", {})
		var move := String(resolved.get("move_id", ""))
		var origin := ""
		for side: String in ["back", "front"]:
			var view: Dictionary = step.views.get(side, {})
			if view.get("instance_id", "") == resolved.get("actor_id", "none") and view.get("visible", false):
				origin = side
		if _is_confirmed(step) and _accepts(move, before.get("moves", {}).get(move, {})) and _indices.has(move + "/" + origin):
			var profile := _profile(move, origin)
			step["community_clip"] = move + "/" + origin
			step["status_switch_native"] = true
			step.duration = float(profile.frames) / 20.0
			step["community_impact"] = float(profile.cue) / 20.0
			step["community_hp_end"] = float(profile.cue + 1) / 20.0
			step.side = origin
			step.state = "reposo"
			step.effect = ""
			step.erase("move_visual")
			# Suppress duplicate procedural glyphs/drops from this confirmed status
			# action. Reflections have a different source side, but the same action ID.
			for prior in range(result.size() - 1, -1, -1):
				var visual: Dictionary = result[prior].get("move_visual", {})
				if visual.get("move_id", "") == move:
					result[prior].erase("move_visual")
				if result[prior].get("event_kind") == String(BattleEvent.ACTION_USED):
					break
		result.append(step)
	return result


func _enabled(before: Dictionary) -> bool:
	return bool(before.get("switch_move_rules_enabled", false))


func _is_confirmed(step: Dictionary) -> bool:
	return step.get("event_kind") == String(BattleEvent.MOVE_EFFECT_RESOLVED)
