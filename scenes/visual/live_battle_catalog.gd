extends Node

# Lazy registry over the reviewed source shards. It never enables a move's rules.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const PACK := "res://.godot/live_battle_catalog/manifest.json"
const PACK_SHA := "6f019bef19115e6de02878d7afb1a4f89a64c0d72e8d159c1ef4435f8702a24c"
var available := false
var bindings := {}
var preview: Control
var _arena: Control
var _path := ""


func configure(arena: Control) -> void:
	_arena = arena
	if not FileAccess.file_exists(PACK) or FileAccess.get_sha256(PACK) != PACK_SHA: return
	var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PACK))
	bindings = pack.get("clips", {}).duplicate(true)
	available = bindings.size() == 1822


func decorate(sequence: Array[Dictionary], before: Dictionary) -> Array[Dictionary]:
	if not available or not before.get("live_moves_enabled", false): return sequence
	var output: Array[Dictionary] = []
	var used := false
	for original: Dictionary in sequence:
		var step := original.duplicate(true)
		if step.get("event_kind") == String(BattleEvent.ACTION_USED): used = false
		var action: Dictionary = step.get("action_context", {})
		var event: Dictionary = step.get("resolved_event", {})
		var move := String(action.get("move_id", ""))
		var metadata: Dictionary = before.get("moves", {}).get(move, {})
		var kind := String(event.get("kind", ""))
		var origin := ""
		for side: String in ["back", "front"]:
			if step.views.get(side, {}).get("instance_id") == action.get("actor_id", "none"): origin = side
		var confirmed: bool = kind == String(BattleEvent.DAMAGE_APPLIED) and event.get("actor_id") == action.get("actor_id") and event.get("target_id") == action.get("target_id") and int(event.get("amount", 0)) > 0
		if metadata.get("category") == "status" and not step.get("trigger_context", false):
			confirmed = kind in [String(BattleEvent.STATUS_APPLIED), String(BattleEvent.STATUS_CURED), String(BattleEvent.STAT_STAGE_CHANGED), String(BattleEvent.STAT_STAGES_REASSIGNED), String(BattleEvent.HP_RECOVERED)] and event.get("actor_id") == action.get("actor_id")
			if kind == String(BattleEvent.STAT_STAGE_CHANGED) and int(event.get("amount", 0)) == 0: confirmed = false
		var special: bool = step.has("community_clip") or step.has("transform_binding")
		var doll: bool = not step.views.get("back", {}).get("substitute", {}).is_empty() or not step.views.get("front", {}).get("substitute", {}).is_empty()
		var key := move + "/" + origin
		if confirmed and not used and not special and not doll and bindings.has(key):
			used = true
			step["catalog_clip"] = key
			step["catalog_origin"] = origin
			step.duration = float(bindings[key].frames) / float(bindings[key].fps)
			step.state = "reposo"
			step.effect = ""
			step.erase("move_visual")
			for n in range(output.size() - 1, -1, -1):
				if output[n].get("event_kind") == String(BattleEvent.ACTION_USED):
					output[n].erase("move_visual")
					break
		output.append(step)
	return output


func _load(key: String) -> bool:
	if not bindings.has(key): return false
	var row: Dictionary = bindings[key]
	var path := "res://" + String(row.path)
	if path != _path:
		clear()
		if is_instance_valid(preview): preview.queue_free()
		preview = Preview.new()
		preview.effects_only = false
		preview.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		preview.size = _arena.size
		_arena.add_child(preview)
		preview.hide()
		_path = ""
		if FileAccess.get_sha256(path) != row.sha256 or not preview.load_pack(path): return false
		_path = path
	if preview.clip.get("id") != key:
		if not preview.select_clip(int(row.index)): return false
	return true


func show_entry(entry: Dictionary, arena: Control, elapsed: float) -> void:
	var key := String(entry.get("catalog_clip", ""))
	if not _load(key):
		clear()
		return
	preview.size = arena.size
	preview.back_species = arena.player_species
	preview.front_species = arena.enemy_species
	preview.show_seconds(minf(elapsed, float(entry.duration) - 0.000001))
	preview._arena.hide()
	preview.show()
	var own_only: bool = preview.clip.get("target_scope") == "user"
	var origin := String(entry.get("catalog_origin", ""))
	arena.set_runtime_visibility(own_only and origin != "back" and entry.views.get("back", {}).get("visible", true),
		own_only and origin != "front" and entry.views.get("front", {}).get("visible", true))


func clear() -> void:
	if is_instance_valid(preview): preview.hide()
