class_name WildBattleSettlement
extends RefCounted

var ok: bool = false
var reason: String = ""
var player_won: bool = false
var session_completed: bool = false
var outcome: BattleOutcome = null
var progression_events: Array = []


func evolution_events() -> Array:
	var out: Array = []
	for event in progression_events:
		if event is ProgressionEvent and event.kind == ProgressionEvent.EVOLUTION_AVAILABLE:
			out.append(event)
	return out


func to_dict() -> Dictionary:
	var progression: Array[Dictionary] = []
	for event in progression_events:
		if event is ProgressionEvent:
			progression.append({
				"kind": event.kind,
				"creature_id": String(event.creature_id),
				"data": event.data,
			})
	return {
		"ok": ok,
		"reason": reason,
		"player_won": player_won,
		"session_completed": session_completed,
		"outcome": outcome.to_dict() if outcome != null else {},
		"progression_events": progression,
	}
