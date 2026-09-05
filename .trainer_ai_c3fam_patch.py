from pathlib import Path

session_path = Path("modules/gameplay/trainer_battle_session.gd")
s = session_path.read_text()
marker = "\n\n# Trainer battles settle only after Battle Core reaches FINISHED. Capture/Flee are not settlement\n"
assert s.count(marker) == 1
method = r'''

# C3f-am explicit autonomous side_b submission API. Calling this method is the opt-in:
# it never enables a global/default autonomous mode and never fabricates a caller action.
# Any non-ready side_b proposal fails closed before Battle Core can advance the turn.
func submit_player_action_with_autonomous_trainer(
	player_action: BattleAction,
) -> Array[BattleEvent]:
	last_error = ""
	last_trainer_action_proposal_report = {}
	last_trainer_action_substitution_report = {}
	if not has_active_battle():
		last_error = "no_active_trainer_battle"
		return []
	if player_action == null:
		last_error = "player_action_required"
		return []
	if player_action.side_id != &"side_a":
		last_error = "wrong_player_side"
		return []
	if not _trainer_memory_owner.is_ready(_battle_server.state):
		last_error = "trainer_memory_not_ready"
		return []

	var proposal_report := trainer_action_proposal_report_for_side(&"side_b")
	last_trainer_action_proposal_report = proposal_report.duplicate(true)
	var substitution_report := _trainer_action_substitution_candidate_from_report(proposal_report)
	last_trainer_action_substitution_report = substitution_report.duplicate(true)
	if String(substitution_report.get("substitution_status", "")) != SUBSTITUTION_READY:
		last_error = "trainer_action_substitution_not_ready"
		return []
	var submitted_dict := substitution_report.get("submitted_action", null)
	if not (submitted_dict is Dictionary):
		last_error = "trainer_action_substitution_not_ready"
		return []
	var autonomous_opponent_action := BattleAction.from_dict((submitted_dict as Dictionary).duplicate(true))
	if autonomous_opponent_action == null or autonomous_opponent_action.side_id != &"side_b":
		last_error = "trainer_action_substitution_not_ready"
		return []

	var events := _battle_server.submit_turn([player_action, autonomous_opponent_action])
	if not _trainer_memory_owner.observe_authoritative(events, _battle_server.state):
		_trainer_memory_owner.clear()
		last_error = "trainer_memory_fanout_failed"
		return events
	var rejection := _battle_rejection_reason(events)
	if not rejection.is_empty():
		last_error = rejection
	return events
'''
s = s.replace(marker, method + marker, 1)
session_path.write_text(s)

runner_path = Path("tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd")
r = runner_path.read_text()
old = '\tTrainerBattleSessionMultiTurnAuthoritativeSubstitutionAuditTestSuite.new().run(Callable(self, "_check"))\n'
new = old + '\tTrainerBattleSessionAutonomousSideBSubmissionApiAuditTestSuite.new().run(Callable(self, "_check"))\n'
assert r.count(old) == 1
runner_path.write_text(r.replace(old, new, 1))
