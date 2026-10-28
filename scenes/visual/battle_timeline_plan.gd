extends RefCounted

# Presentation projection only: amounts come from resolved events, not damage rules.
const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const MoveVisuals = preload("res://scenes/visual/battle_move_visuals.gd")


static func build(events: Array, before: Dictionary, messages: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var views: Dictionary = before.get("views", {}).duplicate(true)
	var creatures: Dictionary = before.get("creatures", {}).duplicate(true)
	var last_action: Dictionary = {}
	var triggered := false
	var weather: Dictionary = before.get("weather", {}).duplicate(true)
	for index in events.size():
		if not events[index] is Dictionary:
			continue
		var event: Dictionary = events[index]
		var kind := String(event.get("kind", ""))
		if event.get("metadata", {}).has("native_dynamax") and creatures.has(String(event.get("target_id", ""))):
			creatures[String(event.target_id)]["dynamax"] = bool(event.metadata.native_dynamax)
		if kind in [String(BattleEvent.WEATHER_CHANGED), String(BattleEvent.WEATHER_UPKEEP)]:
			weather = event.get("metadata", {}).get("weather", {}).duplicate(true)
		elif kind == String(BattleEvent.WEATHER_ENDED):
			weather = {}
		if kind == String(BattleEvent.ACTION_USED):
			last_action = event
			triggered = false
		if kind in [String(BattleEvent.ABILITY_TRIGGERED), String(BattleEvent.ITEM_TRIGGERED)]: triggered = true
		if kind in [String(BattleEvent.PP_CHANGED), String(BattleEvent.TURN_ENDED)]:
			continue # Keep technical events in diagnostics, not as visible log noise.
		var text := String(messages[index]) if index < messages.size() else ""
		var instance_id := ""
		var requested := "reposo"
		var effect := ""
		var duration := 0.28
		var from_views := _health_views(views, creatures)
		if kind == String(BattleEvent.SWITCHED):
			instance_id = String(event.get("target_id", ""))
			var incoming: Dictionary = creatures.get(instance_id, {})
			if incoming.is_empty():
				continue
			var image_side := String(incoming.side)
			var outgoing: Dictionary = from_views.get(image_side, {})
			if not outgoing.is_empty() and bool(outgoing.get("visible", true)):
				var withdrawn := from_views.duplicate(true)
				withdrawn[image_side].visible = false
				result.append(_step(from_views, withdrawn, image_side, "withdraw", 0.32, kind, index, text))
				text = ""
			var withdrawn_id := String(outgoing.get("instance_id", ""))
			if creatures.has(withdrawn_id): creatures[withdrawn_id].erase("substitute")
			incoming.visible = true
			views[incoming.side] = incoming.duplicate(true)
			from_views = _health_views(views, creatures)
			effect = "send_out"
			duration = 0.35
		elif kind in [String(BattleEvent.TRANSFORMED), String(BattleEvent.TRANSFORM_REVERTED)]:
			instance_id = String(event.get("actor_id", ""))
			var changed: Dictionary = creatures.get(instance_id, {})
			if changed.is_empty(): continue
			changed.species = String(event.get("metadata", {}).get("appearance_id", event.get("metadata", {}).get("species_id", changed.species)))
			duration = 0.3
		elif kind in [String(BattleEvent.SUBSTITUTE_CREATED), String(BattleEvent.SUBSTITUTE_TRANSFERRED), String(BattleEvent.SUBSTITUTE_DAMAGED), String(BattleEvent.SUBSTITUTE_BROKEN)]:
			instance_id = String(event.get("target_id", ""))
			var owner: Dictionary = creatures.get(instance_id, {})
			if owner.is_empty(): continue
			if kind == String(BattleEvent.SUBSTITUTE_BROKEN):
				owner.erase("substitute")
			else:
				var doll: Dictionary = event.get("metadata", {})
				owner["substitute"] = {"hp": int(doll.get("hp", 0)), "max_hp": int(doll.get("max_hp", 0))}
			if kind == String(BattleEvent.SUBSTITUTE_DAMAGED): effect = "impact"
			duration = 0.5
		elif kind == String(BattleEvent.KNOCKED_OUT):
			instance_id = String(event.get("target_id", ""))
			var fainted: Dictionary = creatures.get(instance_id, {})
			if fainted.is_empty() or views.get(String(fainted.side), {}).get("instance_id", "") != instance_id:
				continue
			fainted.visible = false
			effect = "faint"
			duration = 0.5
		elif kind == String(BattleEvent.ACTION_USED):
			instance_id = String(event.get("actor_id", ""))
			requested = "ataque"
			effect = "action"
			duration = 0.42
		elif kind in [String(BattleEvent.MOVE_EFFECT_RESOLVED), String(BattleEvent.WEATHER_CHANGED), String(BattleEvent.STAT_STAGES_REASSIGNED)]:
			instance_id = String(event.get("actor_id", ""))
			duration = 0.6
		elif kind == String(BattleEvent.BATTLE_ENDED) and event.get("metadata", {}).get("reason", "") == "forced_escape":
			instance_id = String(event.get("target_id", ""))
			var leaving: Dictionary = creatures.get(instance_id, {})
			if not leaving.is_empty():
				leaving.visible = false
			effect = "flee"
			duration = 0.4
		elif kind in [String(BattleEvent.DAMAGE_APPLIED), String(BattleEvent.STATUS_DAMAGE), String(BattleEvent.RECOIL_DAMAGE), String(BattleEvent.HP_RECOVERED), String(BattleEvent.HP_COST)]:
			instance_id = String(event.get("target_id", ""))
			var amount := int(event.get("amount", 0))
			if amount <= 0:
				continue
			var target: Dictionary = creatures.get(instance_id, {})
			if target.is_empty():
				continue
			var old_hp := int(target.get("hp", 1))
			if event.get("metadata", {}).has("native_max_hp"):
				target.max_hp = int(event.metadata.native_max_hp)
			if kind == String(BattleEvent.HP_RECOVERED):
				target.hp = mini(int(target.get("max_hp", old_hp)), old_hp + amount)
				effect = "heal"
			else:
				target.hp = maxi(0, old_hp - amount)
				if kind != String(BattleEvent.HP_COST):
					requested = "dano"
					effect = "impact"
			if event.get("metadata", {}).has("native_hp"): target.hp = int(event.metadata.native_hp)
			duration = 0.6
		elif text.is_empty():
			continue
		var side := ""
		var state := "reposo"
		if not instance_id.is_empty():
			var creature: Dictionary = creatures.get(instance_id, {})
			if creature.is_empty():
				continue
			side = String(creature.side)
			if views.get(side, {}).get("instance_id", "") != instance_id:
				# Off-screen HP still affects a subsequent switch, not the active image.
				if text.is_empty():
					continue
				side = ""
				effect = ""
			else:
				var view: Dictionary = Catalog.row_for(StringName(creature.species)).get("states", {}).get(requested, {}).get(side, {})
				if requested != "reposo" and not view.is_empty() and int(creature.get("substitute", {}).get("hp", 0)) <= 0:
					state = requested
					duration = 0.0
					for seconds: Variant in view.durations:
						duration += float(seconds)
					if requested == "ataque":
						effect = "" # Native body motion does not also get a generic lunge.
		var step := {"views": from_views, "after_views": _health_views(views, creatures),
			"side": side, "state": state, "effect": effect, "duration": duration,
			"event_kind": kind, "event_index": index, "text": text}
		if before.get("live_moves_enabled", false):
			step["action_context"] = last_action.duplicate(true)
			step["resolved_event"] = event.duplicate(true)
			step["trigger_context"] = triggered
		if kind == String(BattleEvent.TRANSFORMED): step["appearance_change"] = event.get("metadata", {}).duplicate(true)
		if before.get("weather_rules_enabled", false):
			step["weather"] = weather.duplicate(true)
		if kind in [String(BattleEvent.MOVE_EFFECT_RESOLVED), String(BattleEvent.WEATHER_CHANGED), String(BattleEvent.SUBSTITUTE_CREATED)]:
			step["resolved_status"] = {"move_id": String(event.get("move_id", "")),
				"actor_id": instance_id, "target_id": String(event.get("target_id", ""))}
		var visual := MoveVisuals.describe(event, before.get("moves", {}), creatures, from_views, last_action)
		if not visual.is_empty():
			step["move_visual"] = visual
		result.append(step)
	return result


static func command(entry: Dictionary, before: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not bool(entry.get("accepted", false)):
		return result
	var views: Dictionary = before.get("views", {}).duplicate(true)
	if String(entry.get("kind", "")) == "capture":
		var outcome: Dictionary = entry.get("capture_outcome", {}).get("capture", {}).get("result", {})
		var status := String(outcome.get("status", ""))
		var shakes := int(outcome.get("shake_count", -1))
		if not views.has("front") or String(outcome.get("target_id", "")).is_empty():
			return result
		if status not in [String(CaptureResult.SUCCESS), String(CaptureResult.FAILED)] or shakes < 0 or shakes > 3:
			return result
		if String(outcome.get("target_id", "")) != String(views.get("front", {}).get("instance_id", "")):
			return result
		if status == String(CaptureResult.SUCCESS) and not bool(entry.get("session_completed", false)):
			return result
		var hidden := views.duplicate(true)
		hidden.front.visible = false
		var ball_id := String(outcome.get("ball_id", ""))
		result.append(_capture_step(views, views, "throw", ball_id, 0.4))
		result.append(_capture_step(views, hidden, "absorb", ball_id, 0.3))
		result.append(_capture_step(hidden, hidden, "settle", ball_id, 0.2))
		for shake in shakes:
			var step := _capture_step(hidden, hidden, "shake", ball_id, 0.3)
			step["shake_number"] = shake + 1
			result.append(step)
		if status == String(CaptureResult.SUCCESS):
			result.append(_capture_step(hidden, hidden, "caught", ball_id, 0.4))
		else:
			# Breakout draws the original image from zero size to full size.
			result.append(_capture_step(views, views, "breakout", ball_id, 0.3))
	elif String(entry.get("kind", "")) == "run" and bool(entry.get("session_completed", false)) and bool(entry.get("escape_resolution", {}).get("escaped", false)):
		var hidden := views.duplicate(true)
		if not hidden.has("back"):
			return result
		hidden.back.visible = false
		result.append(_step(views, hidden, "back", "flee", 0.4, "fled", -1, ""))
	if before.get("weather_rules_enabled", false):
		var weather: Dictionary = before.get("weather", {}).duplicate(true)
		for step: Dictionary in result:
			if step.get("capture_phase", "") == "caught" or step.get("event_kind", "") == "fled":
				weather = {}
			step["weather"] = weather.duplicate(true)
	return result


static func _step(views: Dictionary, after: Dictionary, side: String, effect: String, duration: float, kind: String, index: int, text: String) -> Dictionary:
	return {"views": views.duplicate(true), "after_views": after.duplicate(true), "side": side,
		"state": "reposo", "effect": effect, "duration": duration, "event_kind": kind, "event_index": index, "text": text}


static func _capture_step(views: Dictionary, after: Dictionary, phase: String, ball_id: String, duration: float) -> Dictionary:
	var effect := "capture_" + phase if phase in ["absorb", "breakout"] else ""
	var result := _step(views, after, "front", effect, duration, "capture_" + phase, -1, "")
	result["capture_phase"] = phase
	result["ball_id"] = ball_id
	return result


static func _health_views(views: Dictionary, creatures: Dictionary) -> Dictionary:
	var result := views.duplicate(true)
	for side: String in result:
		var id := String(result[side].get("instance_id", ""))
		if creatures.has(id):
			result[side] = creatures[id].duplicate(true)
	return result
