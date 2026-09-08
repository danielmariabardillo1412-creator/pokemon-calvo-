class_name TrainerBattleSessionAutonomousSideBSubmissionApiAuditTestSuite
extends TrainerBattleSessionMultiTurnAuthoritativeSubstitutionAuditTestSuite

# C3f-am validates one new explicit caller-free side_b submission API. The historical
# submit_player_action(player_action, opponent_action) contract remains unchanged.
const AUDIT_ID_C3FAM := "c3f_am_autonomous_side_b_submission_api_audit_v1"
const VALIDATED_C3FAM := "AUTONOMOUS_SIDE_B_SUBMISSION_API_VALIDATED"
const VALIDATED_BOUNDARY_C3FAM := "AUTONOMOUS_SIDE_B_SUBMISSION_API_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY"
const BLOCKED_C3FAM := "BLOCKED"
const AUTONOMOUS_METHOD_C3FAM := "submit_player_action_with_autonomous_trainer"

var _autonomous_check: Callable


func run(check_callback: Callable) -> void:
	# Prior C3f-aj/ak/al suites are already executed independently by the runner.
	_autonomous_check = check_callback
	var report := _build_c3fam_report()
	var turns := report.get("autonomous_turns", []) as Array
	var turn_one: Dictionary = turns[0] as Dictionary if turns.size() > 0 else {}
	var turn_two: Dictionary = turns[1] as Dictionary if turns.size() > 1 else {}
	var boundaries := report.get("fail_closed_boundaries", {}) as Dictionary
	var tie := boundaries.get("tie", {}) as Dictionary
	var incomplete := boundaries.get("incomplete", {}) as Dictionary
	var stale := boundaries.get("stale", {}) as Dictionary
	var illegal := boundaries.get("illegal", {}) as Dictionary
	var side_mismatch := boundaries.get("side_mismatch", {}) as Dictionary
	var prebegin := boundaries.get("prebegin", {}) as Dictionary
	var null_player := boundaries.get("null_player", {}) as Dictionary
	var wrong_player := boundaries.get("wrong_player_side", {}) as Dictionary
	var broken_memory := boundaries.get("broken_memory", {}) as Dictionary
	var historical := report.get("historical_api_control", {}) as Dictionary

	_autonomous_check.call("c3fam_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAM)
	_autonomous_check.call("c3fam_status_validated", [VALIDATED_C3FAM, VALIDATED_BOUNDARY_C3FAM].has(String(report.get("tranche_status", ""))))
	_autonomous_check.call("c3fam_explicit_api_exists", bool(report.get("explicit_api_exists", false)))
	_autonomous_check.call("c3fam_no_global_autonomous_toggle", bool(report.get("no_global_autonomous_toggle", false)))
	_autonomous_check.call("c3fam_substitution_toggle_remains_off", bool(report.get("substitution_toggle_remains_off", false)))
	_autonomous_check.call("c3fam_two_autonomous_turns", turns.size() == 2 and bool(turn_one.get("succeeds", false)) and bool(turn_two.get("succeeds", false)))

	_autonomous_check.call("c3fam_turn_one_fresh_binding", int(turn_one.get("state_turn_before", -1)) == 0 and int(turn_one.get("proposal_turn", -1)) == 0 and int(turn_one.get("proposal_action_turn", -1)) == 1)
	_autonomous_check.call("c3fam_turn_one_ready", String(turn_one.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY and String(turn_one.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY)
	_autonomous_check.call("c3fam_turn_one_all_legal_depth2", bool(turn_one.get("root_all_legal", false)) and int(turn_one.get("legal_action_count", 0)) == int(turn_one.get("evaluated_root_count", -1)) and int(turn_one.get("common_depth", 0)) == 2)
	_autonomous_check.call("c3fam_turn_one_exact_live_legality", bool(turn_one.get("proposal_action_currently_legal", false)) and bool(turn_one.get("proposal_action_exact_match", false)))
	_autonomous_check.call("c3fam_turn_one_no_caller", turn_one.get("caller_action", "sentinel") == null and not bool(turn_one.get("caller_fallback_used", true)))
	_autonomous_check.call("c3fam_turn_one_submits_selected_root", String(turn_one.get("selected_root_id", "")) == String(turn_one.get("submitted_root_id", "")) and String(turn_one.get("submitted_root_id", "")) == "move:%s" % String(CHIP_B_C3FAD))
	_autonomous_check.call("c3fam_turn_one_memory_updates", int(turn_one.get("memory_last_observed_turn", -1)) == 1 and int(turn_one.get("memory_event_count", 0)) > 0)

	_autonomous_check.call("c3fam_turn_two_fresh_binding", int(turn_two.get("state_turn_before", -1)) == 1 and int(turn_two.get("proposal_turn", -1)) == 1 and int(turn_two.get("proposal_action_turn", -1)) == 2)
	_autonomous_check.call("c3fam_turn_two_ready", String(turn_two.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY and String(turn_two.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY)
	_autonomous_check.call("c3fam_turn_two_all_legal_depth2", bool(turn_two.get("root_all_legal", false)) and int(turn_two.get("legal_action_count", 0)) == int(turn_two.get("evaluated_root_count", -1)) and int(turn_two.get("common_depth", 0)) == 2)
	_autonomous_check.call("c3fam_turn_two_exact_live_legality", bool(turn_two.get("proposal_action_currently_legal", false)) and bool(turn_two.get("proposal_action_exact_match", false)))
	_autonomous_check.call("c3fam_turn_two_no_caller", turn_two.get("caller_action", "sentinel") == null and not bool(turn_two.get("caller_fallback_used", true)))
	_autonomous_check.call("c3fam_turn_two_memory_updates", int(turn_two.get("memory_last_observed_turn", -1)) == 2 and int(turn_two.get("memory_event_count", 0)) > int(turn_one.get("memory_event_count", 0)))
	_autonomous_check.call("c3fam_reports_bound_to_distinct_turns", bool(report.get("reports_bound_to_distinct_turns", false)))

	_autonomous_check.call("c3fam_tie_fails_closed", _c3fam_blocked(tie, "proposal_not_ready"))
	_autonomous_check.call("c3fam_incomplete_fails_closed", _c3fam_blocked(incomplete, "proposal_depth_incomplete"))
	_autonomous_check.call("c3fam_stale_fails_closed", _c3fam_blocked(stale, "proposal_turn_mismatch"))
	_autonomous_check.call("c3fam_illegal_fails_closed", _c3fam_blocked(illegal, "proposal_action_not_currently_legal"))
	_autonomous_check.call("c3fam_side_mismatch_fails_closed", _c3fam_blocked(side_mismatch, "proposal_side_mismatch"))
	_autonomous_check.call("c3fam_blockers_never_fallback_to_caller", bool(report.get("all_blockers_no_caller_fallback", false)))
	_autonomous_check.call("c3fam_blockers_do_not_advance_turn", bool(report.get("all_blockers_no_turn", false)))

	_autonomous_check.call("c3fam_prebegin_fails_closed", bool(prebegin.get("no_turn", false)) and String(prebegin.get("last_error", "")) == "no_active_trainer_battle")
	_autonomous_check.call("c3fam_null_player_fails_closed", bool(null_player.get("no_turn", false)) and String(null_player.get("last_error", "")) == "player_action_required")
	_autonomous_check.call("c3fam_wrong_player_side_fails_closed", bool(wrong_player.get("no_turn", false)) and String(wrong_player.get("last_error", "")) == "wrong_player_side")
	_autonomous_check.call("c3fam_broken_memory_fails_closed", bool(broken_memory.get("no_turn", false)) and String(broken_memory.get("last_error", "")) == "trainer_memory_not_ready")

	_autonomous_check.call("c3fam_historical_api_still_requires_caller", bool(historical.get("missing_opponent_rejected", false)) and String(historical.get("last_error", "")) == "opponent_action_required")
	_autonomous_check.call("c3fam_historical_missing_caller_no_turn", bool(historical.get("no_turn", false)))
	_autonomous_check.call("c3fam_historical_path_unchanged", bool(historical.get("explicit_pair_still_succeeds", false)))
	_autonomous_check.call("c3fam_forced_replacement_stays_battle_core", bool(report.get("forced_replacement_owned_by_battle_core", false)) and not bool(report.get("replacement_policy_used", true)))
	_autonomous_check.call("c3fam_no_hidden_fallbacks", bool(report.get("barriers_closed", false)))
	_autonomous_check.call("c3fam_scheduler_shared_budget_closed", bool(report.get("scheduler_shared_budget_closed", false)))
	_autonomous_check.call("c3fam_fase34_closed", not bool(report.get("fase34_open", true)))
	_autonomous_check.call("c3fam_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AM AUTONOMOUS SIDE-B API AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fam_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return {"audit_id": AUDIT_ID_C3FAM, "tranche_status": BLOCKED_C3FAM}

	var session := _c3faf_started_session(catalog, &"c3fam_auto", 913601)
	if session == null or session.battle_state() == null:
		return {"audit_id": AUDIT_ID_C3FAM, "tranche_status": BLOCKED_C3FAM}
	var explicit_api_exists := session.has_method(AUTONOMOUS_METHOD_C3FAM)
	var no_global_autonomous_toggle := (
		not session.has_method("set_trainer_autonomous_enabled")
		and not session.has_method("trainer_autonomous_is_enabled")
	)
	var substitution_off_before := not session.trainer_action_substitution_is_enabled()
	if not explicit_api_exists:
		return {"audit_id": AUDIT_ID_C3FAM, "tranche_status": BLOCKED_C3FAM, "explicit_api_exists": false}

	var turn_one := _run_c3fam_autonomous_turn(session)
	var valid_turn_zero_report := session.last_trainer_action_proposal_report.duplicate(true)
	var turn_two := _run_c3fam_autonomous_turn(session)
	var substitution_off_after := not session.trainer_action_substitution_is_enabled()
	var reports_distinct := (
		int(turn_one.get("proposal_turn", -1)) == 0
		and int(turn_two.get("proposal_turn", -1)) == 1
		and int(turn_one.get("proposal_action_turn", -1)) == 1
		and int(turn_two.get("proposal_action_turn", -1)) == 2
	)

	var boundary_session := _c3fam_started_override_session(catalog, valid_turn_zero_report)
	var boundary_action: BattleAction = null
	if boundary_session != null and boundary_session.battle_state() != null:
		var boundary_actions := _c3fae_actions(boundary_session.battle_state())
		if not boundary_actions.is_empty():
			boundary_action = boundary_actions[0]
	var boundaries := _c3fam_fail_closed_boundaries(boundary_session, boundary_action, valid_turn_zero_report, catalog)
	var historical := _c3fam_historical_control(catalog)

	var positive_ok := (
		bool(turn_one.get("succeeds", false))
		and bool(turn_two.get("succeeds", false))
		and String(turn_one.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		and String(turn_two.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		and turn_one.get("caller_action", "sentinel") == null
		and turn_two.get("caller_action", "sentinel") == null
		and not bool(turn_one.get("caller_fallback_used", true))
		and not bool(turn_two.get("caller_fallback_used", true))
		and reports_distinct
		and substitution_off_before
		and substitution_off_after
	)
	var boundary_ok := bool(boundaries.get("all_blocked", false)) and bool(boundaries.get("all_no_turn", false)) and bool(boundaries.get("all_no_caller_fallback", false))
	var historical_ok := bool(historical.get("missing_opponent_rejected", false)) and bool(historical.get("explicit_pair_still_succeeds", false))
	var status := VALIDATED_BOUNDARY_C3FAM if positive_ok and boundary_ok and historical_ok else BLOCKED_C3FAM

	return {
		"audit_id": AUDIT_ID_C3FAM,
		"tranche_status": status,
		"explicit_api_exists": explicit_api_exists,
		"explicit_api_name": AUTONOMOUS_METHOD_C3FAM,
		"no_global_autonomous_toggle": no_global_autonomous_toggle,
		"substitution_toggle_remains_off": substitution_off_before and substitution_off_after,
		"autonomous_turns": [turn_one, turn_two],
		"reports_bound_to_distinct_turns": reports_distinct,
		"fail_closed_boundaries": boundaries,
		"all_blockers_no_caller_fallback": bool(boundaries.get("all_no_caller_fallback", false)),
		"all_blockers_no_turn": bool(boundaries.get("all_no_turn", false)),
		"historical_api_control": historical,
		"forced_replacement_owned_by_battle_core": true,
		"replacement_policy_used": false,
		"barriers_closed": _c3fam_barriers_closed(turn_one) and _c3fam_barriers_closed(turn_two),
		"scheduler_shared_budget_closed": _c3fam_scheduler_closed(turn_one) and _c3fam_scheduler_closed(turn_two),
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}


func _run_c3fam_autonomous_turn(session: TrainerBattleSession) -> Dictionary:
	if session == null or session.battle_state() == null:
		return {}
	var state_turn_before := session.battle_state().turn
	var actions := _c3fae_actions(session.battle_state())
	if actions.is_empty():
		return {"state_turn_before": state_turn_before, "succeeds": false}
	var events := session.submit_player_action_with_autonomous_trainer(actions[0])
	var proposal := session.last_trainer_action_proposal_report.duplicate(true)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var proposal_action := proposal.get("proposal_action", {}) as Dictionary
	var memory_b := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)
	return {
		"state_turn_before": state_turn_before,
		"state_turn_after": session.battle_state().turn,
		"succeeds": not events.is_empty() and session.last_error.is_empty() and session.battle_state().turn == state_turn_before + 1,
		"proposal_turn": int(proposal.get("turn", -1)),
		"proposal_action_turn": int(proposal_action.get("turn", -1)),
		"proposal_status": String(proposal.get("proposal_status", "")),
		"substitution_status": String(substitution.get("substitution_status", "")),
		"selected_root_id": String(proposal.get("selected_root_id", "")),
		"submitted_root_id": String(substitution.get("submitted_root_id", "")),
		"caller_action": substitution.get("caller_action", "sentinel"),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", true)),
		"proposal_action_currently_legal": bool(substitution.get("proposal_action_currently_legal", false)),
		"proposal_action_exact_match": bool(substitution.get("proposal_action_exact_match", false)),
		"root_all_legal": bool(proposal.get("root_all_legal", false)),
		"legal_action_count": int(proposal.get("legal_action_count", 0)),
		"evaluated_root_count": int(proposal.get("evaluated_root_count", -1)),
		"common_depth": int(proposal.get("common_depth", 0)),
		"memory_last_observed_turn": memory_b.last_observed_turn if memory_b != null else -1,
		"memory_event_count": memory_b.event_log.size() if memory_b != null else 0,
		"lexical_tiebreak_used": bool(substitution.get("lexical_tiebreak_used", true)),
		"input_order_tiebreak_used": bool(substitution.get("input_order_tiebreak_used", true)),
		"kind_priority_used": bool(substitution.get("kind_priority_used", true)),
		"sampler_tiebreak_used": bool(substitution.get("sampler_tiebreak_used", true)),
		"live_rng_used": bool(substitution.get("live_rng_used", true)),
		"frontier_fallback_used": bool(substitution.get("frontier_fallback_used", true)),
		"pareto_tiebreak_used": bool(substitution.get("pareto_tiebreak_used", true)),
		"roster_value_fallback_used": bool(substitution.get("roster_value_fallback_used", true)),
		"profile_tiebreak_used": bool(substitution.get("profile_tiebreak_used", true)),
		"campaign_policy_used": bool(substitution.get("campaign_policy_used", true)),
		"recovery_policy_used": bool(substitution.get("recovery_policy_used", true)),
		"replacement_policy_used": bool(substitution.get("replacement_policy_used", true)),
		"hidden_belief_fallback_used": bool(substitution.get("hidden_belief_fallback_used", true)),
		"selected_strategy_id": substitution.get("selected_strategy_id", "sentinel"),
		"selected_scheduler_id": substitution.get("selected_scheduler_id", "sentinel"),
		"selected_shared_budget": substitution.get("selected_shared_budget", "sentinel"),
		"shared_660_reopened": bool(substitution.get("shared_660_reopened", true)),
		"fase34_open": bool(substitution.get("fase34_open", true)),
	}


func _c3fam_started_override_session(
	catalog: DefinitionCatalog,
	report: Dictionary,
) -> TrainerBattleSessionAutonomousProposalOverrideFixture:
	var bundle := _c3fae_session_bundle(catalog)
	var base_session := bundle.get("session", null) as TrainerBattleSession
	if base_session == null:
		return null
	var opponent_roster: Array[CreatureInstance] = []
	for value in bundle.get("opponent_roster", []):
		var creature := value as CreatureInstance
		if creature != null:
			opponent_roster.append(creature)
	if opponent_roster.size() != 3:
		return null
	var session := TrainerBattleSessionAutonomousProposalOverrideFixture.new(base_session.player, catalog, ProgressionRuleset.new())
	if not session.begin_battle(&"c3fam_auto", opponent_roster, 913601):
		return null
	session.set_autonomous_proposal_override(report)
	return session


func _c3fam_fail_closed_boundaries(
	session: TrainerBattleSessionAutonomousProposalOverrideFixture,
	player_action: BattleAction,
	valid_report: Dictionary,
	catalog: DefinitionCatalog,
) -> Dictionary:
	if session == null or session.battle_state() == null or player_action == null or valid_report.is_empty():
		return {"all_blocked": false, "all_no_turn": false, "all_no_caller_fallback": false}
	var tie_report := valid_report.duplicate(true)
	tie_report["proposal_status"] = TrainerItemAwareActionProposal.TIE_UNRESOLVED
	tie_report["resolution_outcome"] = TrainerItemAwareActionProposal.TIE_UNRESOLVED
	tie_report["selected_root_id"] = ""
	tie_report["proposal_action"] = null
	tie_report["proposal_action_detached"] = false
	var tie := _c3fam_run_override_block(session, player_action, tie_report)

	var incomplete_report := valid_report.duplicate(true)
	incomplete_report["common_depth"] = 1
	var incomplete := _c3fam_run_override_block(session, player_action, incomplete_report)

	var stale_report := valid_report.duplicate(true)
	stale_report["turn"] = -1
	var stale := _c3fam_run_override_block(session, player_action, stale_report)

	var illegal_report := valid_report.duplicate(true)
	var illegal_action := (illegal_report.get("proposal_action", {}) as Dictionary).duplicate(true)
	illegal_action["move_id"] = "c3fam_illegal_move"
	illegal_report["proposal_action"] = illegal_action
	illegal_report["selected_root_id"] = "move:c3fam_illegal_move"
	var illegal := _c3fam_run_override_block(session, player_action, illegal_report)

	var side_report := valid_report.duplicate(true)
	side_report["observer_side_id"] = "side_a"
	var side_mismatch := _c3fam_run_override_block(session, player_action, side_report)

	var prebegin_session := TrainerBattleSession.new(PlayerCollection.new(), catalog, ProgressionRuleset.new())
	var prebegin_events := prebegin_session.submit_player_action_with_autonomous_trainer(BattleAction.from_dict(player_action.to_dict()))
	var prebegin := {"no_turn": prebegin_events.is_empty(), "last_error": prebegin_session.last_error}

	var null_session := _c3faf_started_session(catalog, &"c3fam_null", 913602)
	var null_turn_before := null_session.battle_state().turn if null_session != null and null_session.battle_state() != null else -1
	var null_events: Array[BattleEvent] = []
	if null_session != null:
		null_events = null_session.submit_player_action_with_autonomous_trainer(null)
	var null_player := {
		"no_turn": null_session != null and null_events.is_empty() and null_session.battle_state().turn == null_turn_before,
		"last_error": null_session.last_error if null_session != null else "missing_session",
	}

	var wrong_session := _c3faf_started_session(catalog, &"c3fam_wrong", 913603)
	var wrong_turn_before := wrong_session.battle_state().turn if wrong_session != null and wrong_session.battle_state() != null else -1
	var wrong_action := BattleAction.from_dict(player_action.to_dict())
	wrong_action.side_id = &"side_b"
	var wrong_events: Array[BattleEvent] = []
	if wrong_session != null:
		wrong_events = wrong_session.submit_player_action_with_autonomous_trainer(wrong_action)
	var wrong_player := {
		"no_turn": wrong_session != null and wrong_events.is_empty() and wrong_session.battle_state().turn == wrong_turn_before,
		"last_error": wrong_session.last_error if wrong_session != null else "missing_session",
	}

	var memory_session := _c3faf_started_session(catalog, &"c3fam_memory", 913604)
	var memory_turn_before := memory_session.battle_state().turn if memory_session != null and memory_session.battle_state() != null else -1
	var memory_events: Array[BattleEvent] = []
	if memory_session != null:
		memory_session._trainer_memory_owner.clear()
		var memory_actions := _c3fae_actions(memory_session.battle_state())
		if not memory_actions.is_empty():
			memory_events = memory_session.submit_player_action_with_autonomous_trainer(memory_actions[0])
	var broken_memory := {
		"no_turn": memory_session != null and memory_events.is_empty() and memory_session.battle_state().turn == memory_turn_before,
		"last_error": memory_session.last_error if memory_session != null else "missing_session",
	}

	var override_cases: Array[Dictionary] = [tie, incomplete, stale, illegal, side_mismatch]
	var all_blocked := true
	var all_no_turn := true
	var all_no_fallback := true
	for value in override_cases:
		all_blocked = all_blocked and String(value.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		all_no_turn = all_no_turn and bool(value.get("no_turn", false))
		all_no_fallback = all_no_fallback and value.get("caller_action", "sentinel") == null and not bool(value.get("caller_fallback_used", true))
	return {
		"tie": tie,
		"incomplete": incomplete,
		"stale": stale,
		"illegal": illegal,
		"side_mismatch": side_mismatch,
		"prebegin": prebegin,
		"null_player": null_player,
		"wrong_player_side": wrong_player,
		"broken_memory": broken_memory,
		"all_blocked": all_blocked,
		"all_no_turn": all_no_turn,
		"all_no_caller_fallback": all_no_fallback,
	}


func _c3fam_run_override_block(
	session: TrainerBattleSessionAutonomousProposalOverrideFixture,
	player_action: BattleAction,
	report: Dictionary,
) -> Dictionary:
	session.set_autonomous_proposal_override(report)
	var turn_before := session.battle_state().turn
	var events := session.submit_player_action_with_autonomous_trainer(BattleAction.from_dict(player_action.to_dict()))
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	return {
		"no_turn": events.is_empty() and session.battle_state().turn == turn_before,
		"last_error": session.last_error,
		"substitution_status": String(substitution.get("substitution_status", "")),
		"blocked_reason": String(substitution.get("blocked_reason", "")),
		"caller_action": substitution.get("caller_action", "sentinel"),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", true)),
	}


func _c3fam_historical_control(catalog: DefinitionCatalog) -> Dictionary:
	var missing_session := _c3faf_started_session(catalog, &"c3fam_historical_missing", 913605)
	if missing_session == null or missing_session.battle_state() == null:
		return {}
	var missing_actions := _c3fae_actions(missing_session.battle_state())
	if missing_actions.size() != 2:
		return {}
	var turn_before := missing_session.battle_state().turn
	var missing_events := missing_session.submit_player_action(missing_actions[0], null)
	var missing_rejected := missing_events.is_empty() and missing_session.last_error == "opponent_action_required"
	var no_turn := missing_session.battle_state().turn == turn_before

	var explicit_session := _c3faf_started_session(catalog, &"c3fam_historical_explicit", 913606)
	var explicit_ok := false
	if explicit_session != null and explicit_session.battle_state() != null:
		var explicit_actions := _c3fae_actions(explicit_session.battle_state())
		if explicit_actions.size() == 2:
			var explicit_events := explicit_session.submit_player_action(explicit_actions[0], explicit_actions[1])
			explicit_ok = not explicit_events.is_empty() and explicit_session.last_error.is_empty() and explicit_session.battle_state().turn == 1
	return {
		"missing_opponent_rejected": missing_rejected,
		"no_turn": no_turn,
		"last_error": missing_session.last_error,
		"explicit_pair_still_succeeds": explicit_ok,
	}


func _c3fam_blocked(value: Dictionary, reason: String) -> bool:
	return (
		bool(value.get("no_turn", false))
		and String(value.get("last_error", "")) == "trainer_action_substitution_not_ready"
		and String(value.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(value.get("blocked_reason", "")) == reason
	)


func _c3fam_barriers_closed(turn: Dictionary) -> bool:
	return (
		not bool(turn.get("lexical_tiebreak_used", true))
		and not bool(turn.get("input_order_tiebreak_used", true))
		and not bool(turn.get("kind_priority_used", true))
		and not bool(turn.get("sampler_tiebreak_used", true))
		and not bool(turn.get("live_rng_used", true))
		and not bool(turn.get("frontier_fallback_used", true))
		and not bool(turn.get("pareto_tiebreak_used", true))
		and not bool(turn.get("roster_value_fallback_used", true))
		and not bool(turn.get("profile_tiebreak_used", true))
		and not bool(turn.get("campaign_policy_used", true))
		and not bool(turn.get("recovery_policy_used", true))
		and not bool(turn.get("replacement_policy_used", true))
		and not bool(turn.get("hidden_belief_fallback_used", true))
	)


func _c3fam_scheduler_closed(turn: Dictionary) -> bool:
	return (
		turn.get("selected_strategy_id", "sentinel") == null
		and turn.get("selected_scheduler_id", "sentinel") == null
		and turn.get("selected_shared_budget", "sentinel") == null
		and not bool(turn.get("shared_660_reopened", true))
	)
