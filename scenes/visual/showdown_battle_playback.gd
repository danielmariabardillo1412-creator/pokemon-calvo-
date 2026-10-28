extends "res://scenes/visual/battle_animation_playback.gd"


func _snapshot() -> Dictionary:
	var result := super._snapshot()
	if _presentation.session != null:
		for side: Dictionary in _presentation.session._checkpoint.get("roster", []):
			for row: Dictionary in side.pokemon:
				var id := String(row.instance_id)
				var dynamax: bool = "dynamax" in row.get("volatiles", [])
				if result.get("creatures", {}).has(id): result.creatures[id]["dynamax"] = dynamax
				for view: String in result.get("views", {}):
					if result.views[view].instance_id == id: result.views[view]["dynamax"] = dynamax
	if _presentation.has_method("adventure_command") and _presentation.session != null:
		var reason: String = _presentation.session.completion_reason
		if reason == "CAPTURED" and result.get("views", {}).has("front"): result.views.front.visible = false
		if reason == "FLED" and result.get("views", {}).has("back"): result.views.back.visible = false
	return result


# Native side/field/protection effects are confirmed generic status events.
# Reuse the reviewed clip registry without changing its legacy admission rules.
func build_sequence(events: Array, before: Dictionary, messages: Array = []) -> Array[Dictionary]:
	var sequence := super.build_sequence(events, before, messages)
	var used := false
	for step: Dictionary in sequence:
		if step.get("event_kind") == String(BattleEvent.ACTION_USED): used = false
		if step.has("catalog_clip") or step.has("community_clip"): used = true
		var resolved: Dictionary = step.get("resolved_event", {})
		var action: Dictionary = step.get("action_context", {})
		var move := String(action.get("move_id", ""))
		if used or resolved.get("kind") not in [String(BattleEvent.ACTION_USED), String(BattleEvent.MOVE_EFFECT_RESOLVED)] or resolved.get("metadata", {}).get("backend") != "showdown_v1": continue
		if resolved.get("actor_id") != action.get("actor_id"): continue
		var origin := ""
		for side: String in ["back", "front"]:
			if step.views.get(side, {}).get("instance_id") == action.get("actor_id"): origin = side
		var key := move + "/" + origin
		if not _live_catalog.bindings.has(key): continue
		step["catalog_clip"] = key; step["catalog_origin"] = origin
		var binding: Dictionary = _live_catalog.bindings[key]
		step.duration = float(binding.frames) / float(binding.fps)
		step.state = "reposo"; step.effect = ""; step.erase("move_visual")
		used = true
	return sequence


func _write_hud(hud: Dictionary) -> void:
	var localized := hud.duplicate(true)
	if localized.has("enemy_text"): localized.enemy_text = String(localized.enemy_text).replace("Salvaje: ", "Rival: ")
	super._write_hud(localized)
