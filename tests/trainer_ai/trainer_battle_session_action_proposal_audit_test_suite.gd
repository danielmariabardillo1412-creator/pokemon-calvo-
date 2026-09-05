class_name TrainerBattleSessionActionProposalAuditTestSuite
extends TrainerRosterSearchCrossKindDeepScoreComparabilityAuditTestSuite

# C3f-aj heavy lifecycle audit. It deliberately does NOT call super.run(): C3f-ai
# remains certified in FASE33 while this suite exercises the new production proposal
# seam inside the dedicated Trainer Battle Session gate.

const AUDIT_ID_C3FAJ := "c3f_aj_production_action_proposal_lifecycle_audit_v1"
const VALIDATED_C3FAJ := "PRODUCTION_ACTION_PROPOSAL_VALIDATED_NO_SUBSTITUTION"
const BLOCKED_C3FAJ := "BLOCKED"

const EXPECTED_CURRENT_SCORES := {
	"move:c3fad_setup_b": 0,
	"move:c3fad_chip_b": 1292,
	"switch:c3fae_b1": 0,
	"switch:c3fae_b2": -2287,
	"item:hyper_potion:c3fae_b0": 0,
	"item:hyper_potion:c3fae_b1": -157,
	"item:hyper_potion:c3fae_b2": 0,
	"item:potion:c3fae_b0": 0,
	"item:potion:c3fae_b1": 0,
	"item:potion:c3fae_b2": 0,
}

const EXPECTED_BRANCH_SCORES := {
	"move:c3fad_setup_b": 0,
	"move:c3fad_chip_b": 1257,
	"switch:c3fae_b1": 0,
	"switch:c3fae_b2": -1437,
	"item:hyper_potion:c3fae_b0": 0,
	"item:hyper_potion:c3fae_b1": -74,
	"item:hyper_potion:c3fae_b2": 0,
	"item:potion:c3fae_b0": 0,
	"item:potion:c3fae_b1": 0,
	"item:potion:c3fae_b2": 0,
}

var _proposal_check: Callable


func run(check_callback: Callable) -> void:
	_proposal_check = check_callback
	var report := _build_c3faj_report()
	var current := report.get("current_side_b", {}) as Dictionary
	var branch := report.get("branch_side_b", {}) as Dictionary
	var tie := report.get("synthetic_tie", {}) as Dictionary
	var incomplete := report.get("synthetic_incomplete", {}) as Dictionary
	var mismatch := report.get("mismatched_memory", {}) as Dictionary
	var prebegin := report.get("prebegin", {}) as Dictionary
	var wrong_side := report.get("wrong_side", {}) as Dictionary

	_proposal_check.call("c3faj_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAJ)
	_proposal_check.call("c3faj_status_validated", String(report.get("tranche_status", "")) == VALIDATED_C3FAJ)
	_proposal_check.call("c3faj_current_proposal_ready", String(current.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY)
	_proposal_check.call("c3faj_current_all_legal_roots", int(current.get("legal_action_count", 0)) == 10 and int(current.get("evaluated_root_count", 0)) == 10 and bool(current.get("root_all_legal", false)))
	_proposal_check.call("c3faj_current_kind_histogram", _histogram_is_2_2_6(current.get("legal_action_kind_histogram", {}) as Dictionary))
	_proposal_check.call("c3faj_current_depth2_complete", bool(current.get("evaluations_complete", false)) and int(current.get("common_depth", 0)) == 2 and _all_dict_int(current.get("root_depths", {}) as Dictionary, 2))
	_proposal_check.call("c3faj_current_same_models_budget", bool(current.get("metadata_models_match", false)) and bool(current.get("same_budget", false)))
	_proposal_check.call("c3faj_current_exact_c3fai_score_parity", _dict_int_equal(current.get("root_scores", {}) as Dictionary, EXPECTED_CURRENT_SCORES))
	_proposal_check.call("c3faj_current_simulation_parity", _all_dict_int(current.get("root_simulations", {}) as Dictionary, 56))
	_proposal_check.call("c3faj_current_unique_move_winner", String(current.get("selected_root_id", "")) == "move:c3fad_chip_b" and String(current.get("selected_kind", "")) == "MOVE")
	_proposal_check.call("c3faj_current_detached_action_matches_root", bool(current.get("proposal_action_detached", false)) and _proposal_action_root_id(current) == String(current.get("selected_root_id", "")))
	_proposal_check.call("c3faj_current_order_invariant", bool(current.get("order_invariant", false)))

	_proposal_check.call("c3faj_branch_proposal_ready", String(branch.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY)
	_proposal_check.call("c3faj_branch_all_legal_roots", int(branch.get("legal_action_count", 0)) == 10 and int(branch.get("evaluated_root_count", 0)) == 10 and bool(branch.get("root_all_legal", false)))
	_proposal_check.call("c3faj_branch_kind_histogram", _histogram_is_2_2_6(branch.get("legal_action_kind_histogram", {}) as Dictionary))
	_proposal_check.call("c3faj_branch_depth2_complete", bool(branch.get("evaluations_complete", false)) and int(branch.get("common_depth", 0)) == 2 and _all_dict_int(branch.get("root_depths", {}) as Dictionary, 2))
	_proposal_check.call("c3faj_branch_exact_c3fai_score_parity", _dict_int_equal(branch.get("root_scores", {}) as Dictionary, EXPECTED_BRANCH_SCORES))
	_proposal_check.call("c3faj_branch_simulation_parity", _all_dict_int(branch.get("root_simulations", {}) as Dictionary, 56))
	_proposal_check.call("c3faj_branch_unique_move_winner", String(branch.get("selected_root_id", "")) == "move:c3fad_chip_b" and String(branch.get("selected_kind", "")) == "MOVE")
	_proposal_check.call("c3faj_branch_does_not_mutate_live", bool(report.get("branch_live_state_unchanged", false)) and bool(report.get("branch_live_memories_unchanged", false)))

	_proposal_check.call("c3faj_proposal_on_off_same_events", bool(report.get("on_off_same_events", false)))
	_proposal_check.call("c3faj_proposal_on_off_same_state", bool(report.get("on_off_same_state", false)))
	_proposal_check.call("c3faj_proposal_on_off_same_memories", bool(report.get("on_off_same_memories", false)))
	_proposal_check.call("c3faj_explicit_opponent_action_unchanged", bool(report.get("explicit_opponent_action_unchanged", false)))
	_proposal_check.call("c3faj_off_has_no_proposal_telemetry", bool(report.get("off_report_empty", false)))
	_proposal_check.call("c3faj_on_materializes_proposal_telemetry", bool(report.get("on_report_materialized", false)))

	_proposal_check.call("c3faj_synthetic_tie_unresolved", String(tie.get("outcome", "")) == TrainerItemAwareActionProposal.TIE_UNRESOLVED and String(tie.get("selected_root_id", "")).is_empty())
	_proposal_check.call("c3faj_synthetic_incomplete_fails_closed", String(incomplete.get("outcome", "")) == TrainerItemAwareActionProposal.INCOMPLETE_COMMON_DEPTH and String(incomplete.get("selected_root_id", "")).is_empty())
	_proposal_check.call("c3faj_mismatched_memory_fails_closed", String(mismatch.get("proposal_status", "")) == TrainerItemAwareActionProposal.BLOCKED and String(mismatch.get("blocked_reason", "")) == "memory_side_mismatch")
	_proposal_check.call("c3faj_prebegin_fails_closed", String(prebegin.get("proposal_status", "")) == TrainerItemAwareActionProposal.BLOCKED and String(prebegin.get("blocked_reason", "")) == "trainer_memory_not_ready")
	_proposal_check.call("c3faj_wrong_side_fails_closed", String(wrong_side.get("proposal_status", "")) == TrainerItemAwareActionProposal.BLOCKED)
	_proposal_check.call("c3faj_null_opponent_still_required", bool(report.get("null_opponent_still_required", false)))

	_proposal_check.call("c3faj_no_hidden_tiebreaks", _barriers_closed(current) and _barriers_closed(branch))
	_proposal_check.call("c3faj_behavior_and_substitution_closed", not bool(current.get("behavior_integration_authorized", true)) and not bool(current.get("action_substitution_authorized", true)) and not bool(branch.get("behavior_integration_authorized", true)) and not bool(branch.get("action_substitution_authorized", true)))
	_proposal_check.call("c3faj_scheduler_shared_budget_fase34_closed", current.get("selected_strategy_id", "x") == null and current.get("selected_scheduler_id", "x") == null and current.get("selected_shared_budget", "x") == null and not bool(current.get("shared_660_reopened", true)) and not bool(current.get("fase34_open", true)))
	_proposal_check.call("c3faj_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AJ ACTION PROPOSAL AUDIT ===")
	print(JSON.stringify(report))


func _build_c3faj_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return {"audit_id": AUDIT_ID_C3FAJ, "tranche_status": BLOCKED_C3FAJ}

	var off := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	var on := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	if off == null or on == null or off.battle_state() == null or on.battle_state() == null:
		return {"audit_id": AUDIT_ID_C3FAJ, "tranche_status": BLOCKED_C3FAJ}
	off.set_trainer_action_proposal_enabled(false)
	on.set_trainer_action_proposal_enabled(true)
	var off_actions := _c3fae_actions(off.battle_state())
	var on_actions := _c3fae_actions(on.battle_state())
	if off_actions.size() != 2 or on_actions.size() != 2:
		return {"audit_id": AUDIT_ID_C3FAJ, "tranche_status": BLOCKED_C3FAJ}
	var opponent_before := JSON.stringify(on_actions[1].to_dict())
	var off_events := off.submit_player_action(off_actions[0], off_actions[1])
	var on_events := on.submit_player_action(on_actions[0], on_actions[1])
	var current := on.last_trainer_action_proposal_report.duplicate(true)
	var on_off_same_events := _events_signature(off_events) == _events_signature(on_events)
	var on_off_same_state := JSON.stringify(off.battle_state().to_dict()) == JSON.stringify(on.battle_state().to_dict())
	var on_off_same_memories := (
		_memory_json(off.trainer_memory_snapshot_for_side(SIDE_A_C3FAF)) == _memory_json(on.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
		and _memory_json(off.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)) == _memory_json(on.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
	)
	var explicit_unchanged := opponent_before == JSON.stringify(on_actions[1].to_dict())

	var branch_session := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	if branch_session == null or branch_session.battle_state() == null:
		return {"audit_id": AUDIT_ID_C3FAJ, "tranche_status": BLOCKED_C3FAJ}
	var live_state_before := JSON.stringify(branch_session.battle_state().to_dict())
	var live_a_before := _memory_json(branch_session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
	var live_b_before := _memory_json(branch_session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
	var fork := BattleSimulationFork.from_state(branch_session.battle_state(), catalog)
	var branch_events: Array[BattleEvent] = []
	var branch_state: BattleState = null
	if fork != null and fork.state() != null:
		var branch_actions := _c3fae_actions(fork.state())
		if branch_actions.size() == 2:
			branch_events = fork.submit_turn(branch_actions)
			branch_state = fork.state()
	var branch: Dictionary = {}
	if branch_state != null and not branch_events.is_empty() and not _c3faf_has_rejection(branch_events):
		branch = branch_session.trainer_branch_action_proposal_report_for_side(SIDE_B_C3FAF, branch_events, branch_state)
	var branch_state_unchanged := live_state_before == JSON.stringify(branch_session.battle_state().to_dict())
	var branch_memories_unchanged := (
		live_a_before == _memory_json(branch_session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
		and live_b_before == _memory_json(branch_session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
	)

	var proposal := TrainerItemAwareActionProposal.new()
	var tie := proposal.resolve_scores_for_contract(
		["move:x", "item:y:z"],
		{"move:x": 100, "item:y:z": 100},
		{"move:x": 2, "item:y:z": 2},
		{"move:x": "MOVE", "item:y:z": "ITEM"},
	)
	var incomplete := proposal.resolve_scores_for_contract(
		["move:x", "switch:y"],
		{"move:x": 100, "switch:y": 90},
		{"move:x": 2, "switch:y": 1},
		{"move:x": "MOVE", "switch:y": "SWITCH"},
	)
	var side_a_memory := branch_session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF)
	var mismatch := proposal.evaluate(branch_session.battle_state(), SIDE_B_C3FAF, side_a_memory, catalog)

	var prebegin_session := TrainerBattleSession.new(PlayerCollection.new(), catalog, ProgressionRuleset.new())
	var prebegin := prebegin_session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF)
	var wrong_side := branch_session.trainer_action_proposal_report_for_side(&"side_c")
	branch_session.set_trainer_action_proposal_enabled(true)
	var null_actions := _c3fae_actions(branch_session.battle_state())
	var null_events: Array[BattleEvent] = []
	if null_actions.size() == 2:
		null_events = branch_session.submit_player_action(null_actions[0], null)
	var null_opponent_required := null_events.is_empty() and branch_session.last_error == "opponent_action_required"

	var validated := (
		String(current.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY
		and String(branch.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY
		and _dict_int_equal(current.get("root_scores", {}) as Dictionary, EXPECTED_CURRENT_SCORES)
		and _dict_int_equal(branch.get("root_scores", {}) as Dictionary, EXPECTED_BRANCH_SCORES)
		and on_off_same_events
		and on_off_same_state
		and on_off_same_memories
		and explicit_unchanged
		and branch_state_unchanged
		and branch_memories_unchanged
		and null_opponent_required
	)
	return {
		"audit_id": AUDIT_ID_C3FAJ,
		"tranche_status": VALIDATED_C3FAJ if validated else BLOCKED_C3FAJ,
		"current_side_b": current,
		"branch_side_b": branch,
		"on_off_same_events": on_off_same_events,
		"on_off_same_state": on_off_same_state,
		"on_off_same_memories": on_off_same_memories,
		"explicit_opponent_action_unchanged": explicit_unchanged,
		"off_report_empty": off.last_trainer_action_proposal_report.is_empty(),
		"on_report_materialized": not current.is_empty(),
		"branch_live_state_unchanged": branch_state_unchanged,
		"branch_live_memories_unchanged": branch_memories_unchanged,
		"synthetic_tie": tie,
		"synthetic_incomplete": incomplete,
		"mismatched_memory": mismatch,
		"prebegin": prebegin,
		"wrong_side": wrong_side,
		"null_opponent_still_required": null_opponent_required,
		"production_files_modified": true,
		"battle_core_modified": false,
		"brains_modified": false,
		"sampler_modified": false,
		"budget_modified": false,
		"phase_logic_modified": false,
		"behavior_integration_authorized": false,
		"action_substitution_authorized": false,
		"fase34_open": false,
	}


func _events_signature(events: Array[BattleEvent]) -> String:
	var values: Array = []
	for event in events:
		values.append(event.to_dict() if event != null else null)
	return JSON.stringify(values)


func _proposal_action_root_id(report: Dictionary) -> String:
	var raw: Variant = report.get("proposal_action", null)
	if not raw is Dictionary:
		return ""
	var action := BattleAction.from_dict((raw as Dictionary).duplicate(true))
	if action == null:
		return ""
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	return "move:%s" % String(action.move_id)


func _histogram_is_2_2_6(histogram: Dictionary) -> bool:
	return int(histogram.get("MOVE", 0)) == 2 and int(histogram.get("SWITCH", 0)) == 2 and int(histogram.get("ITEM", 0)) == 6


func _dict_int_equal(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for key in expected.keys():
		if not actual.has(key) or int(actual[key]) != int(expected[key]):
			return false
	return true


func _all_dict_int(values: Dictionary, expected: int) -> bool:
	if values.is_empty():
		return false
	for value in values.values():
		if int(value) != expected:
			return false
	return true


func _barriers_closed(report: Dictionary) -> bool:
	return (
		not bool(report.get("kind_priority_used", true))
		and not bool(report.get("lexical_tiebreak_used", true))
		and not bool(report.get("input_order_tiebreak_used", true))
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