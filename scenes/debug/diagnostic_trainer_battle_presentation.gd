class_name DiagnosticTrainerBattlePresentation
extends TrainerBattlePresentationController

signal diagnostic_event(entry: Dictionary)

# Technical-build-only observer. The real autonomous trainer session remains authoritative.
# This wrapper only publishes player commands, battle events and detached AI reports.


func open_for_active_battle() -> bool:
	var ok := super.open_for_active_battle()
	if ok:
		diagnostic_event.emit({
			"event": "battle_opened",
			"scope": "trainer",
			"trainer_id": String(session.opponent_trainer_id) if session != null else "",
			"profile_id": String(session.trainer_profile_id()) if session != null else "",
			"expertise_id": String(session.trainer_expertise_id()) if session != null else "",
		})
	return ok


func _submit_autonomous_player_action(player_action: BattleAction) -> Array[BattleEvent]:
	diagnostic_event.emit({
		"event": "player_action",
		"scope": "trainer",
		"action": player_action.to_dict() if player_action != null else {},
	})
	var events := super._submit_autonomous_player_action(player_action)
	var serialized: Array[Dictionary] = []
	for event in events:
		if event != null:
			serialized.append(event.to_dict())
	var payload := {
		"event": "turn_resolved",
		"scope": "trainer",
		"battle_events": serialized,
		"last_error": session.last_error if session != null else "missing_session",
		"profile_id": String(session.trainer_profile_id()) if session != null else "",
		"expertise_id": String(session.trainer_expertise_id()) if session != null else "",
		"shadow_report": session.last_trainer_shadow_report.duplicate(true) if session != null else {},
		"proposal_report": session.last_trainer_action_proposal_report.duplicate(true) if session != null else {},
		"substitution_report": session.last_trainer_action_substitution_report.duplicate(true) if session != null else {},
		"tie_report": session.last_trainer_game_ready_tie_report.duplicate(true) if session != null else {},
	}
	diagnostic_event.emit(payload)
	return events


func _append_log(text: String) -> void:
	super._append_log(text)
	diagnostic_event.emit({
		"event": "ui_log",
		"scope": "trainer",
		"text": text,
	})
