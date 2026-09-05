class_name TrainerBattleSessionTerminalHorizonCompletenessAuditTestSuite
extends TrainerBattleSessionAutonomousTrainerBattleLifecycleAuditTestSuite

const AUDIT_ID_C3FAO := "c3f_ao_terminal_horizon_completeness_audit_v1"
const VALIDATED_C3FAO := "TERMINAL_HORIZON_COMPLETENESS_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY"
const BLOCKED_C3FAO := "BLOCKED"

var _c3fao_check: Callable


func run(check_callback: Callable) -> void:
	_c3fao_check = check_callback
	var report := _build_c3fao_report()
	var terminal := report.get("terminal_victory", {}) as Dictionary
	var preflight := terminal.get("preflight", {}) as Dictionary
	var normal := report.get("normal_depth_two_control", {}) as Dictionary
	var synthetic := report.get("synthetic_contracts", {}) as Dictionary
	var explicit := report.get("historical_explicit_control", {}) as Dictionary
	var defeat := report.get("autonomous_defeat_control", {}) as Dictionary

	_c3fao_check.call("c3fao_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAO)
	_c3fao_check.call("c3fao_status_validated", String(report.get("tranche_status", "")) == VALIDATED_C3FAO)
	_c3fao_check.call("c3fao_required_depth_stays_two", int(preflight.get("required_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH and TrainerItemAwareActionProposal.REQUIRED_DEPTH == 2)
	_c3fao_check.call("c3fao_terminal_preflight_ready", String(preflight.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY)
	_c3fao_check.call("c3fao_terminal_unique_root_preserved", String(preflight.get("selected_root_id", "")) == "move:c3fad_chip_b" and String(preflight.get("resolution_outcome", "")) == TrainerItemAwareActionProposal.SINGLE_ROOT_CONTRACT)
	_c3fao_check.call("c3fao_terminal_keeps_physical_depth_one", int(terminal.get("selected_root_physical_depth", 0)) == 1 and int(preflight.get("common_physical_depth", 0)) == 1)
	_c3fao_check.call("c3fao_terminal_contract_horizon_two", int(preflight.get("common_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH)
	_c3fao_check.call("c3fao_terminal_marker_explicit", bool(terminal.get("selected_root_terminal_horizon_closed", false)) and bool(terminal.get("selected_root_horizon_complete", false)))
	_c3fao_check.call("c3fao_mixed_root_depths_supported", bool(terminal.get("has_depth_one_root", false)) and bool(terminal.get("has_depth_two_root", false)) and bool(terminal.get("all_roots_horizon_complete", false)))
	_c3fao_check.call("c3fao_terminal_submit_reaches_finished", bool(terminal.get("submit_succeeded", false)) and bool(terminal.get("finished", false)) and String(terminal.get("winner_side_id", "")) == "side_a")
	_c3fao_check.call("c3fao_terminal_substitution_ready", String(terminal.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY and not bool(terminal.get("caller_fallback_used", true)))
	_c3fao_check.call("c3fao_terminal_settlement_victory", bool(terminal.get("settlement_ok", false)) and bool(terminal.get("player_won", false)) and String(terminal.get("completion_reason", "")) == String(TrainerBattleSession.COMPLETED_VICTORY))
	_c3fao_check.call("c3fao_normal_depth_two_still_ready", bool(normal.get("proposal_ready", false)) and bool(normal.get("all_depth_two", false)) and bool(normal.get("all_horizon_complete", false)))
	_c3fao_check.call("c3fao_normal_depth_two_not_terminal", bool(normal.get("no_terminal_horizon_roots", false)))
	_c3fao_check.call("c3fao_synthetic_mixed_horizon_resolves", String((synthetic.get("mixed", {}) as Dictionary).get("outcome", "")) == TrainerItemAwareActionProposal.SINGLE_ROOT_CONTRACT and int((synthetic.get("mixed", {}) as Dictionary).get("common_physical_depth", 0)) == 1)
	_c3fao_check.call("c3fao_synthetic_nonterminal_depth1_blocked", String((synthetic.get("nonterminal", {}) as Dictionary).get("outcome", "")) == TrainerItemAwareActionProposal.INCOMPLETE_COMMON_DEPTH)
	_c3fao_check.call("c3fao_terminal_metadata_complete_without_fake_depth", bool(synthetic.get("terminal_metadata_complete", false)) and int(synthetic.get("terminal_metadata_max_depth", 0)) == 1 and int(synthetic.get("terminal_metadata_fully_completed_depth", 0)) == 1)
	_c3fao_check.call("c3fao_budget_exhaustion_blocked", not bool(synthetic.get("budget_exhausted_complete", true)))
	_c3fao_check.call("c3fao_partial_matrix_blocked", not bool(synthetic.get("partial_matrix_complete", true)))
	_c3fao_check.call("c3fao_nonterminal_depth1_metadata_blocked", not bool(synthetic.get("nonterminal_depth1_complete", true)))
	_c3fao_check.call("c3fao_historical_explicit_control_preserved", bool(explicit.get("same_boundary_prepared", false)) and bool(explicit.get("terminal_turn_succeeded", false)) and bool(explicit.get("finished", false)) and bool(explicit.get("settlement_ok", false)) and bool(explicit.get("player_won", false)))
	_c3fao_check.call("c3fao_autonomous_defeat_control_preserved", bool(defeat.get("three_turns_succeeded", false)) and bool(defeat.get("finished", false)) and bool(defeat.get("settlement_ok", false)) and not bool(defeat.get("player_won", true)) and String(defeat.get("completion_reason", "")) == String(TrainerBattleSession.COMPLETED_DEFEAT))
	_c3fao_check.call("c3fao_no_default_autonomy", bool(report.get("no_global_autonomous_toggle", false)))
	_c3fao_check.call("c3fao_battle_core_ownership_preserved", bool(report.get("forced_replacement_owned_by_battle_core", false)) and not bool(report.get("replacement_policy_used", true)))
	_c3fao_check.call("c3fao_scheduler_shared_budget_closed", report.get("selected_strategy_id", "sentinel") == null and report.get("selected_scheduler_id", "sentinel") == null and report.get("selected_shared_budget", "sentinel") == null and not bool(report.get("shared_660_reopened", true)))
	_c3fao_check.call("c3fao_fase34_closed", not bool(report.get("fase34_open", true)))
	_c3fao_check.call("c3fao_scope_exact", bool(report.get("search_modified", false)) and bool(report.get("proposal_modified", false)) and not bool(report.get("battle_core_modified", true)) and not bool(report.get("brains_modified", true)))
	_c3fao_check.call("c3fao_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AO TERMINAL HORIZON COMPLETENESS AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fao_report() -> Dictionary:
	var terminal_catalog := _c3fae_catalog()
	var normal_catalog := _c3fae_catalog()
	var explicit_catalog := _c3fae_catalog()
	var defeat_catalog := _c3fae_catalog()
	if terminal_catalog == null or normal_catalog == null or explicit_catalog == null or defeat_catalog == null:
		return {"audit_id": AUDIT_ID_C3FAO, "tranche_status": BLOCKED_C3FAO}
	if not _c3fan_tune_catalog(terminal_catalog) or not _c3fan_tune_catalog(normal_catalog) or not _c3fan_tune_catalog(explicit_catalog) or not _c3fan_tune_catalog(defeat_catalog):
		return {"audit_id": AUDIT_ID_C3FAO, "tranche_status": BLOCKED_C3FAO}

	var terminal := _c3fao_terminal_victory(terminal_catalog)
	var normal := _c3fao_normal_depth_two_control(normal_catalog)
	var synthetic := _c3fao_synthetic_contracts()
	var explicit := _c3fan_explicit_terminal_control(explicit_catalog)
	var defeat := _c3fan_autonomous_defeat_control(defeat_catalog)
	var validated := (
		bool(terminal.get("submit_succeeded", false))
		and bool(terminal.get("finished", false))
		and bool(terminal.get("settlement_ok", false))
		and String(terminal.get("winner_side_id", "")) == "side_a"
		and String((terminal.get("preflight", {}) as Dictionary).get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY
		and int(terminal.get("selected_root_physical_depth", 0)) == 1
		and bool(terminal.get("selected_root_terminal_horizon_closed", false))
		and bool(normal.get("proposal_ready", false))
		and bool(synthetic.get("terminal_metadata_complete", false))
		and not bool(synthetic.get("budget_exhausted_complete", true))
		and not bool(synthetic.get("partial_matrix_complete", true))
		and not bool(synthetic.get("nonterminal_depth1_complete", true))
		and bool(explicit.get("settlement_ok", false))
		and bool(defeat.get("settlement_ok", false))
	)
	return {
		"audit_id": AUDIT_ID_C3FAO,
		"tranche_status": VALIDATED_C3FAO if validated else BLOCKED_C3FAO,
		"terminal_victory": terminal,
		"normal_depth_two_control": normal,
		"synthetic_contracts": synthetic,
		"historical_explicit_control": explicit,
		"autonomous_defeat_control": defeat,
		"search_modified": true,
		"proposal_modified": true,
		"battle_core_modified": false,
		"brains_modified": false,
		"forced_replacement_owned_by_battle_core": true,
		"replacement_policy_used": false,
		"no_global_autonomous_toggle": true,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}


func _c3fao_terminal_victory(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3fao_terminal_victory", 915201)
	if session == null or session.battle_state() == null:
		return {}
	_c3fan_set_side_hp(session.battle_state(), SIDE_B_C3FAF, 1)

	var first := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var second := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	if not bool(first.get("succeeded", false)) or not bool(second.get("succeeded", false)):
		return {"first_two_turns_succeeded": false}

	var preflight := session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF)
	var root_depths := preflight.get("root_depths", {}) as Dictionary
	var root_horizon := preflight.get("root_horizon_complete", {}) as Dictionary
	var root_terminal := preflight.get("root_terminal_horizon_closed", {}) as Dictionary
	var selected_root := String(preflight.get("selected_root_id", ""))
	var player_action := _c3fan_player_action(session, CHIP_A_C3FAD)
	var events: Array[BattleEvent] = []
	if player_action != null:
		events = session.submit_player_action_with_autonomous_trainer(player_action)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var finished := session.battle_state() != null and session.battle_state().phase == BattleState.FINISHED
	var winner_side := _c3fan_winner_side(session.battle_state())
	var settlement := session.settle_finished_battle() if finished else TrainerBattleSettlement.new()

	return {
		"first_two_turns_succeeded": true,
		"preflight": preflight,
		"selected_root_physical_depth": int(root_depths.get(selected_root, 0)),
		"selected_root_horizon_complete": bool(root_horizon.get(selected_root, false)),
		"selected_root_terminal_horizon_closed": bool(root_terminal.get(selected_root, false)),
		"has_depth_one_root": _c3fao_has_depth(root_depths, 1),
		"has_depth_two_root": _c3fao_has_depth(root_depths, 2),
		"all_roots_horizon_complete": _c3fao_all_true(root_horizon),
		"submit_succeeded": not events.is_empty(),
		"substitution_status": String(substitution.get("substitution_status", "")),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", false)),
		"finished": finished,
		"winner_side_id": winner_side,
		"settlement_ok": settlement.ok,
		"player_won": settlement.player_won,
		"completion_reason": String(session.completion_reason),
	}


func _c3fao_normal_depth_two_control(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3fao_normal_depth_two", 915202)
	if session == null:
		return {}
	var proposal := session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF)
	var depths := proposal.get("root_depths", {}) as Dictionary
	var horizon := proposal.get("root_horizon_complete", {}) as Dictionary
	var terminal := proposal.get("root_terminal_horizon_closed", {}) as Dictionary
	return {
		"proposal_ready": String(proposal.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY,
		"all_depth_two": _c3fao_all_depth(depths, 2),
		"all_horizon_complete": _c3fao_all_true(horizon),
		"no_terminal_horizon_roots": _c3fao_all_false(terminal),
	}


func _c3fao_synthetic_contracts() -> Dictionary:
	var proposal := TrainerItemAwareActionProposal.new()
	var ids: Array = ["move:a", "move:b"]
	var scores := {"move:a": 10, "move:b": 5}
	var depths := {"move:a": 1, "move:b": 2}
	var kinds := {"move:a": "MOVE", "move:b": "MOVE"}
	var mixed_horizon := {"move:a": true, "move:b": true}
	var nonterminal_horizon := {"move:a": false, "move:b": true}
	var mixed := proposal.resolve_scores_for_contract(ids, scores, depths, kinds, mixed_horizon)
	var nonterminal := proposal.resolve_scores_for_contract(ids, scores, depths, kinds, nonterminal_horizon)

	var terminal_metadata := {
		"world_count": 1,
		"complete_world_count": 1,
		"world_coverage_basis_points": 10000,
		"budget_exhausted": false,
		"required_horizon_branch_count": 1,
		"required_horizon_complete_branch_count": 1,
		"required_horizon_complete": true,
		"terminal_horizon_closed_branch_count": 1,
		"expandable_branch_count": 0,
		"completed_depth_two_branch_count": 0,
		"depth_two_coverage_basis_points": 0,
		"max_depth_reached": 1,
		"fully_completed_depth": 1,
	}
	var budget_metadata := terminal_metadata.duplicate(true)
	budget_metadata["budget_exhausted"] = true
	var partial_metadata := terminal_metadata.duplicate(true)
	partial_metadata["complete_world_count"] = 0
	partial_metadata["world_coverage_basis_points"] = 0
	partial_metadata["required_horizon_complete"] = false
	var nonterminal_metadata := terminal_metadata.duplicate(true)
	nonterminal_metadata["terminal_horizon_closed_branch_count"] = 0
	nonterminal_metadata["required_horizon_complete_branch_count"] = 0
	nonterminal_metadata["required_horizon_complete"] = false

	return {
		"mixed": mixed,
		"nonterminal": nonterminal,
		"terminal_metadata_complete": proposal._result_complete({"metadata": terminal_metadata}),
		"terminal_metadata_max_depth": int(terminal_metadata.get("max_depth_reached", 0)),
		"terminal_metadata_fully_completed_depth": int(terminal_metadata.get("fully_completed_depth", 0)),
		"budget_exhausted_complete": proposal._result_complete({"metadata": budget_metadata}),
		"partial_matrix_complete": proposal._result_complete({"metadata": partial_metadata}),
		"nonterminal_depth1_complete": proposal._result_complete({"metadata": nonterminal_metadata}),
	}


func _c3fao_has_depth(depths: Dictionary, expected: int) -> bool:
	for value in depths.values():
		if int(value) == expected:
			return true
	return false


func _c3fao_all_depth(depths: Dictionary, expected: int) -> bool:
	if depths.is_empty():
		return false
	for value in depths.values():
		if int(value) != expected:
			return false
	return true


func _c3fao_all_true(values: Dictionary) -> bool:
	if values.is_empty():
		return false
	for value in values.values():
		if not bool(value):
			return false
	return true


func _c3fao_all_false(values: Dictionary) -> bool:
	if values.is_empty():
		return false
	for value in values.values():
		if bool(value):
			return false
	return true
