class_name TrainerBattleSessionCrossBattleResetLifecycleAuditTestSuite
extends TrainerBattleSessionTerminalHorizonCompletenessAuditTestSuite

# C3f-ap is strictly TEST/AUDIT-ONLY. It closes the remaining lifecycle seam after
# a certified autonomous trainer battle: settle -> reset -> begin a second battle on
# the SAME TrainerBattleSession -> submit a fresh autonomous side_b action. No default
# autonomy, Trainer Brain, scheduler/shared budget, replacement policy or FASE34 opens.

const AUDIT_ID_C3FAP := "c3f_ap_cross_battle_reset_lifecycle_audit_v1"
const VALIDATED_C3FAP := "CROSS_BATTLE_RESET_LIFECYCLE_VALIDATED_WITH_FRESH_AUTONOMY"
const BLOCKED_C3FAP := "BLOCKED"
const FIRST_TRAINER_C3FAP := &"c3fap_first"
const SECOND_TRAINER_C3FAP := &"c3fap_second"

var _c3fap_check: Callable


func run(check_callback: Callable) -> void:
	# C3f-ao is independently executed by the Evaluation Corpus runner. This suite
	# isolates only the cross-battle reset/reuse boundary authorized by freeze 26.63.
	_c3fap_check = check_callback
	var report := _build_c3fap_report()
	var first := report.get("first_battle", {}) as Dictionary
	var settled := report.get("after_settlement", {}) as Dictionary
	var reset := report.get("after_reset", {}) as Dictionary
	var second := report.get("second_battle", {}) as Dictionary
	var autonomous := second.get("autonomous_turn", {}) as Dictionary
	var historical := second.get("historical_explicit_turn", {}) as Dictionary

	_c3fap_check.call("c3fap_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAP)
	_c3fap_check.call("c3fap_status_validated", String(report.get("tranche_status", "")) == VALIDATED_C3FAP)
	_c3fap_check.call("c3fap_same_session_object_reused", bool(report.get("same_session_object", false)))
	_c3fap_check.call("c3fap_first_three_autonomous_turns_succeed", bool(first.get("three_turns_succeeded", false)))
	_c3fap_check.call("c3fap_first_reaches_finished_victory", bool(first.get("finished", false)) and String(first.get("winner_side_id", "")) == "side_a")
	_c3fap_check.call("c3fap_first_terminal_report_bound_to_first_battle", bool(first.get("terminal_report_bound", false)))
	_c3fap_check.call("c3fap_first_settlement_succeeds", bool(first.get("settlement_ok", false)) and bool(first.get("player_won", false)))

	_c3fap_check.call("c3fap_settlement_completes_session", String(settled.get("status", "")) == String(TrainerBattleSession.COMPLETED) and String(settled.get("completion_reason", "")) == String(TrainerBattleSession.COMPLETED_VICTORY))
	_c3fap_check.call("c3fap_settlement_drops_active_battle", not bool(settled.get("has_active_battle", true)) and bool(settled.get("battle_state_null", false)))
	_c3fap_check.call("c3fap_settlement_clears_reports", bool(settled.get("reports_empty", false)))
	_c3fap_check.call("c3fap_settlement_memory_inaccessible", not bool(settled.get("memory_wiring_ready", true)) and bool(settled.get("memory_snapshots_null", false)))
	_c3fap_check.call("c3fap_settlement_disables_optional_toggles", bool(settled.get("optional_toggles_off", false)))

	_c3fap_check.call("c3fap_reset_succeeds", bool(reset.get("reset_ok", false)))
	_c3fap_check.call("c3fap_reset_returns_ready", String(reset.get("status", "")) == String(TrainerBattleSession.READY))
	_c3fap_check.call("c3fap_reset_clears_completion_identity", String(reset.get("completion_reason", "x")).is_empty() and String(reset.get("opponent_trainer_id", "x")).is_empty() and String(reset.get("last_error", "x")).is_empty())
	_c3fap_check.call("c3fap_reset_has_no_active_or_stale_memory", not bool(reset.get("has_active_battle", true)) and bool(reset.get("battle_state_null", false)) and not bool(reset.get("memory_wiring_ready", true)) and bool(reset.get("memory_snapshots_null", false)))
	_c3fap_check.call("c3fap_reset_keeps_reports_and_toggles_clear", bool(reset.get("reports_empty", false)) and bool(reset.get("optional_toggles_off", false)))

	_c3fap_check.call("c3fap_second_roster_objects_are_fresh", bool(second.get("fresh_opponent_objects", false)))
	_c3fap_check.call("c3fap_second_begin_on_same_session", bool(second.get("begin_ok", false)) and String(second.get("status_after_begin", "")) == String(TrainerBattleSession.BATTLE_ACTIVE))
	_c3fap_check.call("c3fap_second_battle_id_is_fresh", bool(second.get("battle_id_fresh", false)) and String(second.get("battle_id", "")).contains(String(SECOND_TRAINER_C3FAP)))
	_c3fap_check.call("c3fap_second_starts_turn_zero", int(second.get("turn_after_begin", -1)) == 0)
	_c3fap_check.call("c3fap_second_fresh_dual_memory", bool(second.get("fresh_memory_both_sides", false)))
	_c3fap_check.call("c3fap_second_pre_action_reports_empty", bool(second.get("pre_action_reports_empty", false)))
	_c3fap_check.call("c3fap_second_optional_toggles_still_off", bool(second.get("optional_toggles_off", false)))

	_c3fap_check.call("c3fap_second_autonomous_turn_succeeds", bool(autonomous.get("succeeded", false)) and int(autonomous.get("turn_after", -1)) == 1)
	_c3fap_check.call("c3fap_second_proposal_fresh_binding", bool(autonomous.get("proposal_bound_to_second", false)) and int(autonomous.get("proposal_turn", -1)) == 0 and int(autonomous.get("proposal_action_turn", -1)) == 1)
	_c3fap_check.call("c3fap_second_substitution_ready_no_caller", String(autonomous.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY and autonomous.get("caller_action", "sentinel") == null and not bool(autonomous.get("caller_fallback_used", true)))
	_c3fap_check.call("c3fap_second_memory_updates_without_first_battle_id", bool(autonomous.get("memory_bound_to_second", false)) and bool(autonomous.get("first_battle_id_absent", false)))
	_c3fap_check.call("c3fap_second_historical_explicit_turn_preserved", bool(historical.get("succeeded", false)) and bool(historical.get("reports_empty", false)))

	_c3fap_check.call("c3fap_no_default_autonomy_or_brain", bool(report.get("no_global_autonomous_toggle", false)) and not bool(report.get("trainer_brain_integration_authorized", true)))
	_c3fap_check.call("c3fap_scheduler_shared_budget_660_closed", report.get("selected_strategy_id", "sentinel") == null and report.get("selected_scheduler_id", "sentinel") == null and report.get("selected_shared_budget", "sentinel") == null and not bool(report.get("shared_660_reopened", true)))
	_c3fap_check.call("c3fap_replacement_policy_and_fase34_closed", not bool(report.get("replacement_policy_used", true)) and not bool(report.get("fase34_open", true)))
	_c3fap_check.call("c3fap_audit_only_scope", bool(report.get("audit_only_scope", false)) and not bool(report.get("production_modified", true)) and not bool(report.get("brains_modified", true)))
	_c3fap_check.call("c3fap_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AP CROSS-BATTLE RESET LIFECYCLE AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fap_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null or not _c3fan_tune_catalog(catalog):
		return _c3fap_blocked_report()

	var session := _c3faf_started_session(catalog, FIRST_TRAINER_C3FAP, 915301)
	if session == null or session.battle_state() == null:
		return _c3fap_blocked_report()
	var session_object_id := session.get_instance_id()
	var first_battle_id := String(session.battle_state().battle_id)
	var first_opponent_object_ids := _c3fap_side_object_ids(session.battle_state(), SIDE_B_C3FAF)
	_c3fan_set_side_hp(session.battle_state(), SIDE_B_C3FAF, 1)

	var first_turn := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var second_turn := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var third_turn := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var first_finished := session.battle_state() != null and session.battle_state().phase == BattleState.FINISHED
	var first_winner := _c3fan_winner_side(session.battle_state())
	var terminal_proposal := session.last_trainer_action_proposal_report.duplicate(true)
	var terminal_report_bound := String(terminal_proposal.get("battle_id", "")) == first_battle_id and int(terminal_proposal.get("turn", -1)) == 2
	var settlement := session.settle_finished_battle() if first_finished else TrainerBattleSettlement.new()
	var first := {
		"battle_id": first_battle_id,
		"three_turns_succeeded": bool(first_turn.get("succeeded", false)) and bool(second_turn.get("succeeded", false)) and bool(third_turn.get("succeeded", false)),
		"finished": first_finished,
		"winner_side_id": first_winner,
		"terminal_report_bound": terminal_report_bound,
		"settlement_ok": settlement.ok,
		"player_won": settlement.player_won,
	}

	var settled := {
		"status": String(session.status),
		"completion_reason": String(session.completion_reason),
		"has_active_battle": session.has_active_battle(),
		"battle_state_null": session.battle_state() == null,
		"reports_empty": _c3fap_reports_empty(session),
		"memory_wiring_ready": session.trainer_memory_wiring_ready(),
		"memory_snapshots_null": session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF) == null and session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF) == null,
		"optional_toggles_off": _c3fap_optional_toggles_off(session),
	}

	var reset_ok := session.reset_after_completion()
	var reset := {
		"reset_ok": reset_ok,
		"status": String(session.status),
		"completion_reason": String(session.completion_reason),
		"opponent_trainer_id": String(session.opponent_trainer_id),
		"last_error": session.last_error,
		"has_active_battle": session.has_active_battle(),
		"battle_state_null": session.battle_state() == null,
		"reports_empty": _c3fap_reports_empty(session),
		"memory_wiring_ready": session.trainer_memory_wiring_ready(),
		"memory_snapshots_null": session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF) == null and session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF) == null,
		"optional_toggles_off": _c3fap_optional_toggles_off(session),
	}

	var fresh_roster := _c3fap_fresh_opponent_roster(catalog)
	var fresh_object_ids := _c3fap_roster_object_ids(fresh_roster)
	var fresh_objects := fresh_roster.size() == 3 and not _c3fap_has_overlap(first_opponent_object_ids, fresh_object_ids)
	var second_begin := false
	if reset_ok and fresh_roster.size() == 3:
		second_begin = session.begin_battle(SECOND_TRAINER_C3FAP, fresh_roster, 915302)
	if second_begin:
		_c3faf_install_items(session)

	var second_battle_id := String(session.battle_state().battle_id) if second_begin and session.battle_state() != null else ""
	var memory_a := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF) if second_begin else null
	var memory_b := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF) if second_begin else null
	var fresh_memory := (
		memory_a != null and memory_b != null
		and String(memory_a.battle_id) == second_battle_id
		and String(memory_b.battle_id) == second_battle_id
		and memory_a.last_observed_turn == 0 and memory_b.last_observed_turn == 0
		and memory_a.event_log.is_empty() and memory_b.event_log.is_empty()
		and second_battle_id != first_battle_id
	)
	var pre_action_reports_empty := _c3fap_reports_empty(session) if second_begin else false
	var toggles_off_second := _c3fap_optional_toggles_off(session) if second_begin else false

	var autonomous := _c3fap_second_autonomous_turn(session, first_battle_id, second_battle_id) if second_begin else {}
	var historical := _c3fap_historical_turn(session) if bool(autonomous.get("succeeded", false)) else {}
	var second := {
		"fresh_opponent_objects": fresh_objects,
		"begin_ok": second_begin,
		"status_after_begin": String(TrainerBattleSession.BATTLE_ACTIVE) if second_begin else String(session.status),
		"battle_id": second_battle_id,
		"battle_id_fresh": not second_battle_id.is_empty() and second_battle_id != first_battle_id,
		"turn_after_begin": 0 if second_begin else -1,
		"fresh_memory_both_sides": fresh_memory,
		"pre_action_reports_empty": pre_action_reports_empty,
		"optional_toggles_off": toggles_off_second,
		"autonomous_turn": autonomous,
		"historical_explicit_turn": historical,
	}

	var same_session := session.get_instance_id() == session_object_id
	var validated := (
		bool(first.get("three_turns_succeeded", false))
		and first_finished and first_winner == "side_a"
		and terminal_report_bound and settlement.ok and settlement.player_won
		and String(settled.get("status", "")) == String(TrainerBattleSession.COMPLETED)
		and bool(settled.get("reports_empty", false)) and bool(settled.get("memory_snapshots_null", false))
		and reset_ok and String(reset.get("status", "")) == String(TrainerBattleSession.READY)
		and bool(reset.get("reports_empty", false)) and bool(reset.get("memory_snapshots_null", false))
		and fresh_objects and second_begin and fresh_memory and pre_action_reports_empty
		and bool(autonomous.get("succeeded", false))
		and bool(autonomous.get("proposal_bound_to_second", false))
		and String(autonomous.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		and bool(autonomous.get("memory_bound_to_second", false))
		and bool(autonomous.get("first_battle_id_absent", false))
		and bool(historical.get("succeeded", false)) and bool(historical.get("reports_empty", false))
		and same_session
	)

	return {
		"audit_id": AUDIT_ID_C3FAP,
		"tranche_status": VALIDATED_C3FAP if validated else BLOCKED_C3FAP,
		"same_session_object": same_session,
		"first_battle": first,
		"after_settlement": settled,
		"after_reset": reset,
		"second_battle": second,
		"no_global_autonomous_toggle": not session.has_method("set_trainer_autonomous_enabled") and not session.has_method("trainer_autonomous_is_enabled"),
		"trainer_brain_integration_authorized": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"replacement_policy_used": false,
		"fase34_open": false,
		"audit_only_scope": true,
		"production_modified": false,
		"brains_modified": false,
	}


func _c3fap_second_autonomous_turn(session: TrainerBattleSession, first_battle_id: String, second_battle_id: String) -> Dictionary:
	if session == null or session.battle_state() == null:
		return {}
	var before := session.battle_state().turn
	var action := _c3fan_player_action(session, CHIP_A_C3FAD)
	if action == null:
		return {}
	var events := session.submit_player_action_with_autonomous_trainer(action)
	var proposal := session.last_trainer_action_proposal_report.duplicate(true)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var proposal_action := proposal.get("proposal_action", {}) as Dictionary
	var memory_a := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF)
	var memory_b := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)
	var proposal_json := JSON.stringify(proposal)
	var memory_a_json := JSON.stringify(memory_a.to_dict()) if memory_a != null else ""
	var memory_b_json := JSON.stringify(memory_b.to_dict()) if memory_b != null else ""
	return {
		"succeeded": not events.is_empty() and session.last_error.is_empty() and session.battle_state() != null and session.battle_state().turn == before + 1,
		"turn_before": before,
		"turn_after": session.battle_state().turn if session.battle_state() != null else -1,
		"proposal_turn": int(proposal.get("turn", -1)),
		"proposal_action_turn": int(proposal_action.get("turn", -1)),
		"proposal_bound_to_second": String(proposal.get("battle_id", "")) == second_battle_id and String(proposal.get("battle_id", "")) != first_battle_id,
		"substitution_status": String(substitution.get("substitution_status", "")),
		"caller_action": substitution.get("caller_action", "sentinel"),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", true)),
		"memory_bound_to_second": memory_a != null and memory_b != null and String(memory_a.battle_id) == second_battle_id and String(memory_b.battle_id) == second_battle_id and memory_a.last_observed_turn == 1 and memory_b.last_observed_turn == 1 and not memory_a.event_log.is_empty() and not memory_b.event_log.is_empty(),
		"first_battle_id_absent": not proposal_json.contains(first_battle_id) and not memory_a_json.contains(first_battle_id) and not memory_b_json.contains(first_battle_id),
	}


func _c3fap_historical_turn(session: TrainerBattleSession) -> Dictionary:
	if session == null or session.battle_state() == null or session.battle_state().phase != BattleState.WAITING_FOR_ACTIONS:
		return {}
	var before := session.battle_state().turn
	var actions := _c3fae_actions(session.battle_state())
	if actions.size() != 2:
		return {}
	var events := session.submit_player_action(actions[0], actions[1])
	return {
		"succeeded": not events.is_empty() and session.last_error.is_empty() and session.battle_state() != null and session.battle_state().turn == before + 1,
		"reports_empty": session.last_trainer_action_proposal_report.is_empty() and session.last_trainer_action_substitution_report.is_empty(),
	}


func _c3fap_fresh_opponent_roster(catalog: DefinitionCatalog) -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	var bundle := _c3fae_session_bundle(catalog)
	for value in bundle.get("opponent_roster", []):
		var creature := value as CreatureInstance
		if creature != null:
			out.append(creature)
	return out


func _c3fap_side_object_ids(state: BattleState, side_id: StringName) -> Array[int]:
	var out: Array[int] = []
	if state == null:
		return out
	for side in state.sides:
		if side.side_id != side_id:
			continue
		for creature_id in side.party_ids:
			var creature := state.creature(creature_id)
			if creature != null:
				out.append(creature.get_instance_id())
	return out


func _c3fap_roster_object_ids(roster: Array[CreatureInstance]) -> Array[int]:
	var out: Array[int] = []
	for creature in roster:
		if creature != null:
			out.append(creature.get_instance_id())
	return out


func _c3fap_has_overlap(a: Array[int], b: Array[int]) -> bool:
	for value in a:
		if b.has(value):
			return true
	return false


func _c3fap_reports_empty(session: TrainerBattleSession) -> bool:
	return session != null and session.last_trainer_shadow_report.is_empty() and session.last_trainer_action_proposal_report.is_empty() and session.last_trainer_action_substitution_report.is_empty()


func _c3fap_optional_toggles_off(session: TrainerBattleSession) -> bool:
	return session != null and not session.trainer_shadow_item_aware_is_enabled() and not session.trainer_action_proposal_is_enabled() and not session.trainer_action_substitution_is_enabled()


func _c3fap_blocked_report() -> Dictionary:
	return {
		"audit_id": AUDIT_ID_C3FAP,
		"tranche_status": BLOCKED_C3FAP,
		"same_session_object": false,
		"first_battle": {},
		"after_settlement": {},
		"after_reset": {},
		"second_battle": {},
		"no_global_autonomous_toggle": true,
		"trainer_brain_integration_authorized": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"replacement_policy_used": false,
		"fase34_open": false,
		"audit_only_scope": true,
		"production_modified": false,
		"brains_modified": false,
	}
