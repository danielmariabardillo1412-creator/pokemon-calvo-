class_name WildBattleCommandResult
extends RefCounted

var accepted: bool = false
var reason: String = ""
var command_type: StringName = &""
var turn_consumed: bool = false
var session_completed: bool = false
var battle_finished: bool = false
var capture_outcome: WildAdventureCaptureOutcome = null
var battle_events: Array[BattleEvent] = []


func succeeded() -> bool:
	return accepted and reason.is_empty()
