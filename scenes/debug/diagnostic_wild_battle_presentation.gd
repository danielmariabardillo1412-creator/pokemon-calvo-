class_name DiagnosticWildBattlePresentation
extends SpanishBattlePresentationController

signal diagnostic_event(entry: Dictionary)

# Technical-build-only observer. It wraps the real presentation without changing
# Battle Core, capture, run, switching or opponent policy behavior.


func open_for_active_battle() -> bool:
	var ok := super.open_for_active_battle()
	if ok:
		diagnostic_event.emit({"event": "battle_opened", "scope": "wild"})
	return ok


func submit_player_move(move_id: StringName) -> Array[BattleEvent]:
	diagnostic_event.emit({"event": "command", "scope": "wild", "kind": "move", "move_id": String(move_id)})
	var events := super.submit_player_move(move_id)
	_emit_resolution("move", events)
	return events


func submit_player_switch(switch_instance_id: StringName) -> WildBattleCommandResult:
	diagnostic_event.emit({"event": "command", "scope": "wild", "kind": "switch", "switch_instance_id": String(switch_instance_id)})
	var result := super.submit_player_switch(switch_instance_id)
	_emit_command_result("switch", result)
	return result


func submit_capture_ball(ball_id: StringName) -> WildBattleCommandResult:
	diagnostic_event.emit({"event": "command", "scope": "wild", "kind": "capture", "ball_id": String(ball_id)})
	var result := super.submit_capture_ball(ball_id)
	_emit_command_result("capture", result)
	return result


func submit_player_run() -> WildBattleCommandResult:
	diagnostic_event.emit({"event": "command", "scope": "wild", "kind": "run"})
	var result := super.submit_player_run()
	_emit_command_result("run", result)
	return result


func _append_log(text: String) -> void:
	super._append_log(text)
	diagnostic_event.emit({
		"event": "ui_log",
		"scope": "wild",
		"text": SpanishGameText.translate_runtime_message(text),
		"raw_text": text,
	})


func _emit_resolution(kind: String, events: Array[BattleEvent]) -> void:
	var serialized: Array[Dictionary] = []
	for event in events:
		if event != null:
			serialized.append(event.to_dict())
	diagnostic_event.emit({
		"event": "command_result",
		"scope": "wild",
		"kind": kind,
		"battle_events": serialized,
	})


func _emit_command_result(kind: String, result: WildBattleCommandResult) -> void:
	var serialized: Array[Dictionary] = []
	if result != null:
		for event in result.battle_events:
			if event != null:
				serialized.append(event.to_dict())
	var escape_dict: Dictionary = {}
	if result != null and result.escape_resolution != null:
		escape_dict = {
			"escaped": result.escape_resolution.escaped,
			"attempt": result.escape_resolution.attempt,
			"odds": result.escape_resolution.odds,
			"roll": result.escape_resolution.roll,
			"rng_consumed": result.escape_resolution.rng_consumed,
			"reason": result.escape_resolution.reason,
		}
	diagnostic_event.emit({
		"event": "command_result",
		"scope": "wild",
		"kind": kind,
		"accepted": result != null and result.accepted,
		"reason": result.reason if result != null else "missing_result",
		"turn_consumed": result.turn_consumed if result != null else false,
		"session_completed": result.session_completed if result != null else false,
		"battle_finished": result.battle_finished if result != null else false,
		"capture_outcome": (
			result.capture_outcome.to_dict()
			if result != null and result.capture_outcome != null
			else {}
		),
		"escape_resolution": escape_dict,
		"battle_events": serialized,
	})
