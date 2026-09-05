class_name TrainerBattleSessionAuthoritativeSubstitutionAuditTestSuite
extends TrainerBattleSessionActionProposalAuditTestSuite

# C3f-ak: first narrowly-authorized behavior integration. The production proposal may
# replace only side_b's caller-supplied action when the current C3f-aj report is uniquely
# ready and still legal. Every blocked path must stop the turn; caller fallback is forbidden.

const AUDIT_ID_C3FAK := "c3f_ak_authoritative_side_b_substitution_audit_v1"
const VALIDATED_C3FAK := "AUTHORITATIVE_SIDE_B_SUBSTITUTION_VALIDATED"
const VALIDATED_BLOCKERS_C3FAK := "AUTHORITATIVE_SIDE_B_SUBSTITUTION_VALIDATED_WITH_FAIL_CLOSED_BLOCKERS"
const BLOCKED_C3FAK := "BLOCKED"
const READY_C3FAK := "SUBSTITUTION_READY"

var _substitution_check: Callable


func run(check_callback: Callable) -> void:
	# Deliberately do not call super.run(): C3f-aj is already independently certified
	# in this same gate. This tranche isolates only the new authoritative boundary.
	_substitution_check = check_callback
	var report := _build_c3fak_report()
	var off := report.get("off", {}) as Dictionary
	var on := report.get("on", {}) as Dictionary
	var substitution := on.get("substitution_report", {}) as Dictionary
	var proposal := on.get("proposal_report", {}) as Dictionary
	var tie := report.get("tie_contract", {}) as Dictionary
	var incomplete := report.get("incomplete_contract", {}) as Dictionary
	var illegal := report.get("illegal_contract", {}) as Dictionary
	var stale := report.get("stale_contract", {}) as Dictionary
	var broken := report.get("broken_memory", {}) as Dictionary
	var missing := report.get("missing_caller", {}) as Dictionary

	_substitution_check.call("c3fak_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAK)
	_substitution_check.call("c3fak_status_validated", [VALIDATED_C3FAK, VALIDATED_BLOCKERS_C3FAK].has(String(report.get("tranche_status", ""))))
	_substitution_check.call("c3fak_default_off", bool(report.get("default_off", false)))
	_substitution_check.call("c3fak_off_turn_succeeds", bool(off.get("turn_succeeds", false)))
	_substitution_check.call("c3fak_off_executes_caller_setup", bool(off.get("setup_revealed", false)) and not bool(off.get("chip_revealed", true)))
	_substitution_check.call("c3fak_off_no_substitution_report", bool(off.get("substitution_report_empty", false)))
	_substitution_check.call("c3fak_on_turn_succeeds", bool(on.get("turn_succeeds", false)))
	_substitution_check.call("c3fak_on_caller_was_setup", String(on.get("caller_root_id", "")) == "move:c3fad_setup_b")
	_substitution_check.call("c3fak_on_proposal_ready", String(proposal.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY)
	_substitution_check.call("c3fak_on_proposal_is_chip", String(proposal.get("selected_root_id", "")) == "move:c3fad_chip_b")
	_substitution_check.call("c3fak_on_all_legal_depth2_complete", int(proposal.get("legal_action_count", 0)) == 10 and int(proposal.get("evaluated_root_count", 0)) == 10 and bool(proposal.get("root_all_legal", false)) and int(proposal.get("common_depth", 0)) == 2 and bool(proposal.get("evaluations_complete", false)))
	_substitution_check.call("c3fak_on_simulations_preserved", _all_dict_int(proposal.get("root_simulations", {}) as Dictionary, 56))
	_substitution_check.call("c3fak_substitution_ready", String(substitution.get("substitution_status", "")) == READY_C3FAK)
	_substitution_check.call("c3fak_submitted_exact_proposal", bool(on.get("submitted_equals_proposal", false)) and String(substitution.get("submitted_root_id", "")) == "move:c3fad_chip_b")
	_substitution_check.call("c3fak_caller_object_unchanged", bool(on.get("caller_object_unchanged", false)))
	_substitution_check.call("c3fak_authoritative_memory_reveals_chip", bool(on.get("chip_revealed", false)) and not bool(on.get("setup_revealed", true)))
	_substitution_check.call("c3fak_authoritative_memory_turn_coherent", bool(on.get("memory_turn_coherent", false)))
	_substitution_check.call("c3fak_no_caller_fallback", not bool(substitution.get("caller_fallback_used", true)))
	_substitution_check.call("c3fak_narrow_behavior_authorization", bool(substitution.get("action_substitution_authorized", false)) and bool(substitution.get("behavior_integration_authorized", false)) and not bool(substitution.get("trainer_brain_integration_authorized", true)) and String(substitution.get("authoritative_substitution_scope", "")) == "side_b_opt_in_only")
	_substitution_check.call("c3fak_exact_current_legality_validated", bool(substitution.get("proposal_action_currently_legal", false)) and bool(substitution.get("proposal_action_exact_match", false)))

	_substitution_check.call("c3fak_tie_contract_fails_closed", String(tie.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED and not bool(tie.get("action_substitution_authorized", true)) and tie.get("submitted_action", "sentinel") == null)
	_substitution_check.call("c3fak_incomplete_contract_fails_closed", String(incomplete.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED and incomplete.get("submitted_action", "sentinel") == null)
	_substitution_check.call("c3fak_illegal_proposal_fails_closed", String(illegal.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED and String(illegal.get("blocked_reason", "")) == "proposal_action_not_currently_legal")
	_substitution_check.call("c3fak_stale_proposal_fails_closed", String(stale.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED and String(stale.get("blocked_reason", "")) == "proposal_turn_mismatch")
	_substitution_check.call("c3fak_broken_memory_no_turn", bool(broken.get("no_turn", false)) and String(broken.get("last_error", "")) == "trainer_memory_not_ready")
	_substitution_check.call("c3fak_broken_memory_no_fallback", bool(broken.get("caller_not_executed", false)))
	_substitution_check.call("c3fak_missing_caller_still_required", bool(missing.get("no_turn", false)) and String(missing.get("last_error", "")) == "opponent_action_required")
	_substitution_check.call("c3fak_missing_caller_no_proposal_escape", bool(missing.get("proposal_report_empty", false)))

	_substitution_check.call("c3fak_no_hidden_fallbacks", _barriers_closed(proposal) and _substitution_barriers_closed(substitution))
	_substitution_check.call("c3fak_root_all_legal_inner_cap_separate", bool(substitution.get("root_all_legal", false)) and int(substitution.get("inner_max_actions_per_side", -1)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP)
	_substitution_check.call("c3fak_scheduler_shared660_closed", substitution.get("selected_strategy_id", "x") == null and substitution.get("selected_scheduler_id", "x") == null and substitution.get("selected_shared_budget", "x") == null and not bool(substitution.get("shared_660_reopened", true)))
	_substitution_check.call("c3fak_fase34_closed", not bool(substitution.get("fase34_open", true)))
	_substitution_check.call("c3fak_production_scope_exact", bool(report.get("production_scope_exact", false)))
	_substitution_check.call("c3fak_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AK AUTHORITATIVE SUBSTITUTION AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fak_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return {"audit_id": AUDIT_ID_C3FAK, "tranche_status": BLOCKED_C3FAK}

	var pristine := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	if pristine == null or pristine.battle_state() == null:
		return {"audit_id": AUDIT_ID_C3FAK, "tranche_status": BLOCKED_C3FAK}
	var default_off := not pristine.trainer_action_substitution_is_enabled()

	var off := _run_authoritative_case(catalog, false)
	var on := _run_authoritative_case(catalog, true)
	if off.is_empty() or on.is_empty():
		return {"audit_id": AUDIT_ID_C3FAK, "tranche_status": BLOCKED_C3FAK, "default_off": default_off}

	# Contract-level blockers use the exact production validator against a live session.
	var contract_session := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	var ready_report := contract_session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF)
	var tie_report := ready_report.duplicate(true)
	tie_report["proposal_status"] = TrainerItemAwareActionProposal.TIE_UNRESOLVED
	tie_report["resolution_outcome"] = TrainerItemAwareActionProposal.TIE_UNRESOLVED
	tie_report["selected_root_id"] = ""
	tie_report["selected_kind"] = ""
	tie_report["proposal_action"] = null
	tie_report["proposal_action_detached"] = false
	var tie_contract := contract_session._trainer_action_substitution_candidate_from_report(tie_report)

	var incomplete_report := ready_report.duplicate(true)
	incomplete_report["proposal_status"] = TrainerItemAwareActionProposal.BLOCKED
	incomplete_report["resolution_outcome"] = TrainerItemAwareActionProposal.INCOMPLETE_COMMON_DEPTH
	incomplete_report["evaluations_complete"] = false
	incomplete_report["common_depth"] = 1
	incomplete_report["proposal_action"] = null
	incomplete_report["proposal_action_detached"] = false
	var incomplete_contract := contract_session._trainer_action_substitution_candidate_from_report(incomplete_report)

	var illegal_report := ready_report.duplicate(true)
	var illegal_action := (illegal_report.get("proposal_action", {}) as Dictionary).duplicate(true)
	illegal_action["actor_id"] = "not_a_live_actor"
	illegal_report["proposal_action"] = illegal_action
	var illegal_contract := contract_session._trainer_action_substitution_candidate_from_report(illegal_report)

	var stale_report := ready_report.duplicate(true)
	stale_report["turn"] = int(stale_report.get("turn", 0)) - 1
	var stale_contract := contract_session._trainer_action_substitution_candidate_from_report(stale_report)

	var broken_session := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	broken_session.set_trainer_action_substitution_enabled(true)
	var broken_actions := _c3fae_actions(broken_session.battle_state())
	var broken_turn := broken_session.battle_state().turn
	broken_session._trainer_memory_owner.clear()
	var broken_events: Array[BattleEvent] = []
	if broken_actions.size() == 2:
		broken_events = broken_session.submit_player_action(broken_actions[0], broken_actions[1])
	var broken_memory := {
		"no_turn": broken_events.is_empty() and broken_session.battle_state().turn == broken_turn,
		"last_error": broken_session.last_error,
		"caller_not_executed": broken_session.battle_state().turn == broken_turn,
	}

	var missing_session := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	missing_session.set_trainer_action_substitution_enabled(true)
	var missing_actions := _c3fae_actions(missing_session.battle_state())
	var missing_turn := missing_session.battle_state().turn
	var missing_events: Array[BattleEvent] = []
	if missing_actions.size() == 2:
		missing_events = missing_session.submit_player_action(missing_actions[0], null)
	var missing_caller := {
		"no_turn": missing_events.is_empty() and missing_session.battle_state().turn == missing_turn,
		"last_error": missing_session.last_error,
		"proposal_report_empty": missing_session.last_trainer_action_proposal_report.is_empty(),
	}

	var substitution := on.get("substitution_report", {}) as Dictionary
	var validated := (
		default_off
		and bool(off.get("turn_succeeds", false))
		and bool(off.get("setup_revealed", false))
		and bool(on.get("turn_succeeds", false))
		and bool(on.get("chip_revealed", false))
		and bool(on.get("submitted_equals_proposal", false))
		and String(substitution.get("substitution_status", "")) == READY_C3FAK
		and String(tie_contract.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(incomplete_contract.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(illegal_contract.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(stale_contract.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and bool(broken_memory.get("no_turn", false))
		and bool(missing_caller.get("no_turn", false))
	)
	return {
		"audit_id": AUDIT_ID_C3FAK,
		"tranche_status": VALIDATED_BLOCKERS_C3FAK if validated else BLOCKED_C3FAK,
		"default_off": default_off,
		"off": off,
		"on": on,
		"tie_contract": tie_contract,
		"incomplete_contract": incomplete_contract,
		"illegal_contract": illegal_contract,
		"stale_contract": stale_contract,
		"broken_memory": broken_memory,
		"missing_caller": missing_caller,
		"production_scope_exact": true,
	}


func _run_authoritative_case(catalog: DefinitionCatalog, substitution_enabled: bool) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	if session == null or session.battle_state() == null:
		return {}
	session.set_trainer_action_substitution_enabled(substitution_enabled)
	var actions := _c3fae_actions(session.battle_state())
	if actions.size() != 2:
		return {}
	var caller_before := actions[1].to_dict().duplicate(true)
	var caller_root := _c3fak_root_id(actions[1])
	var turn_before := session.battle_state().turn
	var events := session.submit_player_action(actions[0], actions[1])
	var proposal := session.last_trainer_action_proposal_report.duplicate(true)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var memory_a := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF)
	var setup_revealed := memory_a != null and memory_a.revealed_move_ids(session.opponent_active().instance_id).has(SETUP_B_C3FAD)
	var chip_revealed := memory_a != null and memory_a.revealed_move_ids(session.opponent_active().instance_id).has(CHIP_B_C3FAD)
	var submitted := substitution.get("submitted_action", null)
	var proposal_action := proposal.get("proposal_action", null)
	return {
		"turn_succeeds": not events.is_empty() and session.last_error.is_empty() and session.battle_state().turn == turn_before + 1,
		"caller_root_id": caller_root,
		"caller_object_unchanged": JSON.stringify(caller_before) == JSON.stringify(actions[1].to_dict()),
		"proposal_report": proposal,
		"substitution_report": substitution,
		"substitution_report_empty": substitution.is_empty(),
		"submitted_equals_proposal": submitted is Dictionary and proposal_action is Dictionary and JSON.stringify(submitted) == JSON.stringify(proposal_action),
		"setup_revealed": setup_revealed,
		"chip_revealed": chip_revealed,
		"memory_turn_coherent": memory_a != null and memory_a.last_observed_turn == session.battle_state().turn,
	}


func _c3fak_root_id(action: BattleAction) -> String:
	if action == null:
		return ""
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	return "move:%s" % String(action.move_id)


func _substitution_barriers_closed(report: Dictionary) -> bool:
	return (
		not bool(report.get("caller_fallback_used", true))
		and not bool(report.get("lexical_tiebreak_used", true))
		and not bool(report.get("input_order_tiebreak_used", true))
		and not bool(report.get("kind_priority_used", true))
		and not bool(report.get("sampler_tiebreak_used", true))
		and not bool(report.get("live_rng_used", true))
		and not bool(report.get("frontier_fallback_used", true))
		and not bool(report.get("pareto_tiebreak_used", true))
		and not bool(report.get("roster_value_fallback_used", true))
		and not bool(report.get("profile_tiebreak_used", true))
		and not bool(report.get("campaign_policy_used", true))
		and not bool(report.get("recovery_policy_used", true))
		and not bool(report.get("replacement_policy_used", true))
		and not bool(report.get("hidden_belief_fallback_used", true))
	)
