extends "res://scenes/visual/battle_status_switch_pilot.gd"

const CASTS := "res://.godot/battle_weather/casts.json"
const CAST_SHA := "c14aa0a4adae54e980a82ab2dad18b0c7c3dbb684fc847b73cbd5f18875d0704"
const FRAMES := {"rain_dance": 26, "hail": 13, "sandstorm": 24, "snowscape": 13, "chilly_reception": 30}
const REFERENCES := {"rain_dance": "RAINDANCE", "hail": "HAIL", "sandstorm": "SANDSTORM", "snowscape": "SNOWSCAPE", "chilly_reception": "CHILLYRECEPTION"}


func configure(arena: Control, path: String = CASTS) -> void:
	preview = Preview.new()
	preview.effects_only = true
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.add_child(preview)
	preview.hide()
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != CAST_SHA or not preview.load_pack(path):
		last_error = "Pack local de clima ausente o distinto"
		return
	for n in preview.pack.clips.size():
		var row: Dictionary = preview.pack.clips[n]
		if not FRAMES.has(String(row.move_id)) or row.frames.size() != FRAMES[String(row.move_id)] or row.fps != 20 or row.reference_animation_id != REFERENCES[String(row.move_id)]:
			_indices.clear()
			return
		_indices[String(row.id)] = n
	available = _indices.size() == 10


func _profile(move: String, _side: String) -> Dictionary:
	return {"frames": FRAMES[move], "cue": 0} if FRAMES.has(move) else {}


func _accepts(move: String, data: Dictionary) -> bool:
	var types := {"rain_dance": "water", "hail": "ice", "sandstorm": "rock", "snowscape": "ice", "chilly_reception": "ice"}
	return FRAMES.has(move) and data.get("power") == 0 and data.get("category") == "status" \
		and data.get("target") == "entire-field" and data.get("effects_empty") == true \
		and data.get("classification") == "DATA_ONLY" and data.get("type_id") == types[move]


func _enabled(before: Dictionary) -> bool:
	return bool(before.get("weather_rules_enabled", false))


func _is_confirmed(step: Dictionary) -> bool:
	return step.get("event_kind") == String(BattleEvent.WEATHER_CHANGED) or (
		step.get("event_kind") == String(BattleEvent.MOVE_EFFECT_RESOLVED)
		and step.get("resolved_status", {}).get("move_id", "") == "chilly_reception")
