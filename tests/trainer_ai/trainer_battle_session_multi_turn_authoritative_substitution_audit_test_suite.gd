class_name TrainerBattleSessionMultiTurnAuthoritativeSubstitutionAuditTestSuite
extends TrainerBattleSessionAuthoritativeSubstitutionAuditTestSuite

# C3f-al is audit-only. It exercises the already-authorized C3f-ak substitution
# across consecutive ordinary turns and proves each turn is bound to fresh live
# state/memory. It does not broaden production behavior or remove the caller action.

const AUDIT_ID_C3FAL := "c3f_al_multi_turn_authoritative_substitution_audit_v1"
const VALIDATED_C3FAL := "MULTI_TURN_AUTHORITATIVE_SUBSTITUTION_VALIDATED"
const VALIDATED_BOUNDARY_C3FAL := "MULTI_TURN_AUTHORITATIVE_SUBSTITUTION_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY"
const BLOCKED_C3FAL := "BLOCKED"
const POISON_ROOT_C3FAL := "poisoned_stale_root"

var _multi_turn_check: Callable


func run(check_callback: Callable) -> void:
	# Do not call super.run(): C3f-ak is already independently executed by the
	# Evaluation Corpus runner. This suite isolates only the new multi-turn evidence.
	_multi_turn_check = check_callback
	var report := _build_c3fal_report()
	var turns := report.get("turns", []) as Array
	var turn_one: Dictionary = turns[0] as Dictionary if turns.size() > 0 else {}
	var turn_two: Dictionary = turns[1] as Dictionary if turns.size() > 1 else {}
	var stale := report.get("stale_first_report_after_turn_one", {}) as Dictionary
	var missing := report.get("second_turn_missing_caller", {}) as Dictionary
	var off := report.get("off_two_turn_control", {}) as Dictionary

	_multi_turn_check.call("c3fal_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAL)
	_multi_turn_check.call("c3fal_status_validated", [VALIDATED_C3FAL, VALIDATED_BOUNDARY_C3FAL].has(String(report.get("tranche_status", ""))))
	_multi_turn_check.call("c3fal_default_off", bool(report.get("default_off", false)))
	_multi_turn_check.call("c3fal_two_consecutive_turns_recorded", turns.size() == 2)

	_multi_turn_check.call("c3fal_turn_one_succeeds", bool(turn_one.get("turn_succeeds", false)))
	_multi_turn_check.call("c3fal_turn_one_fresh_turn_binding", int(turn_one.get("state_turn_before", -1)) == 0 and int(turn_one.get("proposal_turn", -1)) == 0 and int(turn_one.get("proposal_action_turn", -1)) == 1)
	_multi_turn_check.call("c3fal_turn_one_substitution_ready", String(turn_one.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY)
	_multi_turn_check.call("c3fal_turn_one_all_legal_depth2", bool(turn_one.get("root_all_legal", false)) and int(turn_one.get("legal_action_count", 0)) == int(turn_one.get("evaluated_root_count", -1)) and int(turn_one.get("common_depth", 0)) == 2 and bool(turn_one.get("evaluations_complete", false)))
	_multi_turn_check.call("c3fal_turn_one_exact_live_legality", bool(turn_one.get("proposal_action_currently_legal", false)) and bool(turn_one.get("proposal_action_exact_match", false)))
	_multi_turn_check.call("c3fal_turn_one_no_caller_fallback", not bool(turn_one.get("caller_fallback_used", true)))
	_multi_turn_check.call("c3fal_turn_one_memory_updated", int(turn_one.get("memory_last_observed_turn", -1)) == 1 and int(turn_one.get("memory_event_count", 0)) > 0)

	_multi_turn_check.call("c3fal_first_report_stale_after_turn_one", String(stale.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED and String(stale.get("blocked_reason", "")) == "proposal_turn_mismatch")
	_multi_turn_check.call("c3fal_stale_report_has_no_submission", stale.get("submitted_action", "sentinel") == null and not bool(stale.get("caller_fallback_used", true)))
	_multi_turn_check.call("c3fal_memory_ready_before_turn_two", bool(report.get("memory_ready_before_turn_two", false)) and int(report.get("memory_turn_before_turn_two", -1)) == 1 and int(report.get("memory_events_before_turn_two", 0)) > 0)

	_multi_turn_check.call("c3fal_turn_two_succeeds", bool(turn_two.get("turn_succeeds", false)))
	_multi_turn_check.call("c3fal_turn_two_fresh_turn_binding", int(turn_two.get("state_turn_before", -1)) == 1 and int(turn_two.get("proposal_turn", -1)) == 1 and int(turn_two.get("proposal_action_turn", -1)) == 2)
	_multi_turn_check.call("c3fal_turn_two_substitution_ready", String(turn_two.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY)
	_multi_turn_check.call("c3fal_turn_two_all_legal_depth2", bool(turn_two.get("root_all_legal", false)) and int(turn_two.get("legal_action_count", 0)) == int(turn_two.get("evaluated_root_count", -1)) and int(turn_two.get("common_depth", 0)) == 2 and bool(turn_two.get("evaluations_complete", false)))
	_multi_turn_check.call("c3fal_turn_two_exact_live_legality", bool(turn_two.get("proposal_action_currently_legal", false)) and bool(turn_two.get("proposal_action_exact_match", false)))
	_multi_turn_check.call("c3fal_turn_two_no_caller_fallback", not bool(turn_two.get("caller_fallback_used", true)))
	_multi_turn_check.call("c3fal_turn_two_memory_updated", int(turn_two.get("memory_last_observed_turn", -1)) == 2 and int(turn_two.get("memory_event_count", 0)) > int(turn_one.get("memory_event_count", 0)))

	_multi_turn_check.call("c3fal_poisoned_telemetry_overwritten", bool(report.get("poisoned_telemetry_overwritten", false)))
	_multi_turn_check.call("c3fal_reports_are_fresh_not_reused", bool(report.get("reports_bound_to_distinct_turns", false)) and String(turn_two.get("selected_root_id", "")) != POISON_ROOT_C3FAL and String(turn_two.get("submitted_root_id", "")) != POISON_ROOT_C3FAL)
	_multi_turn_check.call("c3fal_each_turn_re_evaluates_all_roots", bool(turn_one.get("fresh_complete_evaluation", false)) and bool(turn_two.get("fresh_complete_evaluation", false)))
	_multi_turn_check.call("c3fal_root_all_legal_inner_cap_separate", int(turn_one.get("inner_max_actions_per_side", -1)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP and int(turn_two.get("inner_max_actions_per_side", -1)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP and bool(turn_one.get("root_all_legal", false)) and bool(turn_two.get("root_all_legal", false)))
	_multi_turn_check.call("c3fal_no_hidden_fallbacks_both_turns", bool(turn_one.get("barriers_closed", false)) and bool(turn_two.get("barriers_closed", false)))

	_multi_turn_check.call("c3fal_second_turn_caller_still_required", bool(missing.get("first_turn_succeeded", false)) and bool(missing.get("no_second_turn", false)) and String(missing.get("last_error", "")) == "opponent_action_required")
	_multi_turn_check.call("c3fal_missing_second_caller_no_new_proposal", bool(missing.get("prior_report_preserved", false)) and int(missing.get("state_turn_after", -1)) == int(missing.get("state_turn_before", -2)))
	_multi_turn_check.call("c3fal_off_two_turn_historical_path", bool(off.get("two_turns_succeeded", false)) and int(off.get("state_turn", -1)) == 2)
	_multi_turn_check.call("c3fal_off_two_turn_no_substitution_reports", bool(off.get("reports_empty", false)))

	_multi_turn_check.call("c3fal_narrow_authorization_preserved", not bool(turn_one.get("trainer_brain_integration_authorized", true)) and not bool(turn_two.get("trainer_brain_integration_authorized", true)))
	_multi_turn_check.call("c3fal_scheduler_shared_budget_closed", bool(report.get("scheduler_shared_budget_closed", false)))
	_multi_turn_check.call("c3fal_forced_replacement_policy_not_added", not bool(report.get("forced_replacement_policy_used", true)) and not bool(report.get("replacement_policy_used", true)))
	_multi_turn_check.call("c3fal_fase34_closed", not bool(report.get("fase34_open", true)))
	_multi_turn_check.call("c3fal_audit_only_scope", bool(report.get("audit_only_scope", false)))
	_multi_turn_check.call("c3fal_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AL MULTI-TURN SUBSTITUTION AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fal_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return {"audit_id": AUDIT_ID_C3FAL, "tranche_status": BLOCKED_C3FAL}

	var pristine := _c3faf_started_session(catalog, &"c3fal_pristine", 913501)
	if pristine == null or pristine.battle_state() == null:
		return {"audit_id": AUDIT_ID_C3FAL, "tranche_status": BLOCKED_C3FAL}
	var default_off := not pristine.trainer_action_substitution_is_enabled()

	var session := _c3faf_started_session(catalog, &"c3fal_multi", 913502)
	if session == null or session.battle_state() == null:
		return {"audit_id": AUDIT_ID_C3FAL, "tranche_status": BLOCKED_C3FAL, "default_off": default_off}
	session.set_trainer_action_substitution_enabled(true)

	var turn_one := _run_c3fal_turn(session)
	if not bool(turn_one.get("turn_succeeds", false)):
		return {"audit_id": AUDIT_ID_C3FAL, "tranche_status": BLOCKED_C3FAL, "default_off": default_off, "turns": [turn_one]}
	var first_report := session.last_trainer_action_proposal_report.duplicate(true)
	var stale_first := session._trainer_action_substitution_candidate_from_report(first_report)

	var memory_before_second := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)
	var memory_ready_before_second := memory_before_second != null and memory_before_second.last_observed_turn == session.battle_state().turn
	var memory_turn_before_second := memory_before_second.last_observed_turn if memory_before_second != null else -1
	var memory_events_before_second := memory_before_second.event_log.size() if memory_before_second != null else 0

	# Poison the live telemetry holders deliberately. The second submit must replace
	# these values by recomputing from current state/memory; reuse would be visible.
	session.last_trainer_action_proposal_report["turn"] = -999
	session.last_trainer_action_proposal_report["selected_root_id"] = POISON_ROOT_C3FAL
	session.last_trainer_action_substitution_report["submitted_root_id"] = POISON_ROOT_C3FAL

	var turn_two := _run_c3fal_turn(session)
	var poisoned_overwritten := (
		int(turn_two.get("proposal_turn", -999)) == 1
		and String(turn_two.get("selected_root_id", "")) != POISON_ROOT_C3FAL
		and String(turn_two.get("submitted_root_id", "")) != POISON_ROOT_C3FAL
	)
	var reports_distinct := (
		int(turn_one.get("proposal_turn", -1)) != int(turn_two.get("proposal_turn", -1))
		and int(turn_one.get("proposal_action_turn", -1)) != int(turn_two.get("proposal_action_turn", -1))
	)

	var missing := _c3fal_second_turn_missing_caller(catalog)
	var off := _c3fal_off_two_turn_control(catalog)
	var both_ready := (
		bool(turn_one.get("turn_succeeds", false))
		and bool(turn_two.get("turn_succeeds", false))
		and String(turn_one.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		and String(turn_two.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		and bool(turn_one.get("proposal_action_currently_legal", false))
		and bool(turn_two.get("proposal_action_currently_legal", false))
		and memory_ready_before_second
		and poisoned_overwritten
		and reports_distinct
	)
	var boundaries_ready := (
		String(stale_first.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(stale_first.get("blocked_reason", "")) == "proposal_turn_mismatch"
		and bool(missing.get("no_second_turn", false))
		and bool(off.get("two_turns_succeeded", false))
	)
	var status := VALIDATED_BOUNDARY_C3FAL if both_ready and boundaries_ready else BLOCKED_C3FAL

	return {
		"audit_id": AUDIT_ID_C3FAL,
		"tranche_status": status,
		"default_off": default_off,
		"turns": [turn_one, turn_two],
		"stale_first_report_after_turn_one": stale_first,
		"memory_ready_before_turn_two": memory_ready_before_second,
		"memory_turn_before_turn_two": memory_turn_before_second,
		"memory_events_before_turn_two": memory_events_before_second,
		"poisoned_telemetry_overwritten": poisoned_overwritten,
		"reports_bound_to_distinct_turns": reports_distinct,
		"second_turn_missing_caller": missing,
		"off_two_turn_control": off,
		"scheduler_shared_budget_closed": _c3fal_scheduler_closed(turn_one) and _c3fal_scheduler_closed(turn_two),
		"forced_replacement_policy_used": false,
		"replacement_policy_used": bool(turn_one.get("replacement_policy_used", true)) or bool(turn_two.get("replacement_policy_used", true)),
		"fase34_open": bool(turn_one.get("fase34_open", true)) or bool(turn_two.get("fase34_open", true)),
		"audit_only_scope": true,
	}


func _run_c3fal_turn(session: TrainerBattleSession) -> Dictionary:
	if session == null or session.battle_state() == null:
		return {}
	var state_turn_before := session.battle_state().turn
	var actions := _c3fae_actions(session.battle_state())
	if actions.size() != 2:
		return {"state_turn_before": state_turn_before, "turn_succeeds": false}
	var caller_before := actions[1].to_dict().duplicate(true)
	var events := session.submit_player_action(actions[0], actions[1])
	var proposal := session.last_trainer_action_proposal_report.duplicate(true)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var memory_b := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)
	var proposal_action := proposal.get("proposal_action", {}) as Dictionary
	var complete_evaluation := (
		bool(proposal.get("evaluations_complete", false))
		and int(proposal.get("legal_action_count", 0)) > 0
		and int(proposal.get("evaluated_root_count", -1)) == int(proposal.get("legal_action_count", 0))
		and int(proposal.get("common_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH
		and _c3fal_all_simulations_positive(proposal.get("root_simulations", {}) as Dictionary)
	)
	return {
		"state_turn_before": state_turn_before,
		"state_turn_after": session.battle_state().turn,
		"turn_succeeds": not events.is_empty() and session.last_error.is_empty() and session.battle_state().turn == state_turn_before + 1,
		"caller_root_id": _c3fak_root_id(actions[1]),
		"caller_object_unchanged": JSON.stringify(caller_before) == JSON.stringify(actions[1].to_dict()),
		"proposal_turn": int(proposal.get("turn", -1)),
		"proposal_action_turn": int(proposal_action.get("turn", -1)),
		"proposal_status": String(proposal.get("proposal_status", "")),
		"selected_root_id": String(proposal.get("selected_root_id", "")),
		"substitution_status": String(substitution.get("substitution_status", "")),
		"submitted_root_id": String(substitution.get("submitted_root_id", "")),
		"proposal_action_currently_legal": bool(substitution.get("proposal_action_currently_legal", false)),
		"proposal_action_exact_match": bool(substitution.get("proposal_action_exact_match", false)),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", true)),
		"root_all_legal": bool(proposal.get("root_all_legal", false)),
		"inner_max_actions_per_side": int(proposal.get("inner_max_actions_per_side", -1)),
		"legal_action_count": int(proposal.get("legal_action_count", 0)),
		"evaluated_root_count": int(proposal.get("evaluated_root_count", 0)),
		"common_depth": int(proposal.get("common_depth", 0)),
		"evaluations_complete": bool(proposal.get("evaluations_complete", false)),
		"fresh_complete_evaluation": complete_evaluation,
		"memory_last_observed_turn": memory_b.last_observed_turn if memory_b != null else -1,
		"memory_event_count": memory_b.event_log.size() if memory_b != null else 0,
		"barriers_closed": _barriers_closed(proposal) and _substitution_barriers_closed(substitution),
		"trainer_brain_integration_authorized": bool(substitution.get("trainer_brain_integration_authorized", true)),
		"replacement_policy_used": bool(substitution.get("replacement_policy_used", true)),
		"selected_strategy_id": substitution.get("selected_strategy_id", "sentinel"),
		"selected_scheduler_id": substitution.get("selected_scheduler_id", "sentinel"),
		"selected_shared_budget": substitution.get("selected_shared_budget", "sentinel"),
		"shared_660_reopened": bool(substitution.get("shared_660_reopened", true)),
		"fase34_open": bool(substitution.get("fase34_open", true)),
	}


func _c3fal_second_turn_missing_caller(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3fal_missing", 913503)
	if session == null or session.battle_state() == null:
		return {}
	session.set_trainer_action_substitution_enabled(true)
	var first := _run_c3fal_turn(session)
	if not bool(first.get("turn_succeeds", false)):
		return {"first_turn_succeeded": false}
	var prior_report := JSON.stringify(session.last_trainer_action_proposal_report)
	var actions := _c3fae_actions(session.battle_state())
	if actions.size() != 2:
		return {"first_turn_succeeded": true, "no_second_turn": false}
	var turn_before := session.battle_state().turn
	var events := session.submit_player_action(actions[0], null)
	return {
		"first_turn_succeeded": true,
		"state_turn_before": turn_before,
		"state_turn_after": session.battle_state().turn,
		"no_second_turn": events.is_empty() and session.battle_state().turn == turn_before,
		"last_error": session.last_error,
		"prior_report_preserved": JSON.stringify(session.last_trainer_action_proposal_report) == prior_report,
	}


func _c3fal_off_two_turn_control(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3fal_off", 913504)
	if session == null or session.battle_state() == null:
		return {}
	var default_off := not session.trainer_action_substitution_is_enabled()
	var succeeded := default_off
	for _i in range(2):
		var actions := _c3fae_actions(session.battle_state())
		if actions.size() != 2:
			succeeded = false
			break
		var events := session.submit_player_action(actions[0], actions[1])
		if events.is_empty() or not session.last_error.is_empty():
			succeeded = false
			break
	return {
		"default_off": default_off,
		"two_turns_succeeded": succeeded,
		"state_turn": session.battle_state().turn,
		"reports_empty": session.last_trainer_action_substitution_report.is_empty() and session.last_trainer_action_proposal_report.is_empty(),
	}


func _c3fal_scheduler_closed(turn_report: Dictionary) -> bool:
	return (
		turn_report.get("selected_strategy_id", "sentinel") == null
		and turn_report.get("selected_scheduler_id", "sentinel") == null
		and turn_report.get("selected_shared_budget", "sentinel") == null
		and not bool(turn_report.get("shared_660_reopened", true))
	)


func _c3fal_all_simulations_positive(values: Dictionary) -> bool:
	if values.is_empty():
		return false
	for value in values.values():
		if int(value) <= 0:
			return false
	return true
