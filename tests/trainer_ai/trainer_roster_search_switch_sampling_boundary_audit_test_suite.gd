class_name TrainerRosterSearchSwitchSamplingBoundaryAuditTestSuite
extends TrainerRosterFrontierSwitchingShadowOverlapAuditTestSuite

# C3f-n is deliberately TEST/AUDIT-ONLY. It audits the existing bounded action
# sampler used by TrainerMultiTurnSearch before any roster-value evidence is
# allowed to enter search. No production behavior, score, legal action or search
# budget is modified here.

const AUDIT_ID_C3FN := "c3f_n_search_switch_sampling_order_boundary_audit_v1"
const SYNTHETIC_MOVE_COUNT := 4
const SYNTHETIC_SWITCH_COUNT := 5
const EXPECTED_DEFAULT_ACTION_CAP := 3


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_search_switch_sampling_boundary()


func _test_search_switch_sampling_boundary() -> void:
	var report_a := _build_c3fn_report()
	var report_b := _build_c3fn_report()

	_check.call(
		"search_switch_sampling_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FN,
	)
	_check.call(
		"search_switch_sampling_targets_existing_search_model",
		String(report_a.get("search_model_id", "")) == TrainerMultiTurnSearch.SEARCH_MODEL_ID
		and String(report_a.get("action_sampling_model", "")) == TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
	)
	_check.call(
		"search_switch_sampling_default_budget_cap_recorded",
		int(report_a.get("default_max_actions_per_side", -1)) == EXPECTED_DEFAULT_ACTION_CAP,
	)
	_check.call(
		"search_switch_sampling_uses_expected_synthetic_geometry",
		int(report_a.get("synthetic_move_count", 0)) == SYNTHETIC_MOVE_COUNT
		and int(report_a.get("synthetic_switch_count", 0)) == SYNTHETIC_SWITCH_COUNT
		and int(report_a.get("synthetic_total_actions", 0)) == SYNTHETIC_MOVE_COUNT + SYNTHETIC_SWITCH_COUNT,
	)
	_check.call(
		"search_switch_sampling_default_sample_shape",
		int(report_a.get("default_sample_size", 0)) == EXPECTED_DEFAULT_ACTION_CAP
		and int(report_a.get("default_sample_move_count", 0)) == 2
		and int(report_a.get("default_sample_switch_count", 0)) == 1,
	)
	_check.call(
		"search_switch_sampling_default_keeps_only_one_of_five_switches",
		int(report_a.get("default_sample_switch_count", 0)) == 1
		and int(report_a.get("default_switch_omitted_count", -1)) == 4,
	)
	_check.call(
		"search_switch_sampling_default_switch_coverage_is_twenty_percent",
		int(report_a.get("default_switch_coverage_bp", -1)) == 2000,
	)
	_check.call(
		"search_switch_sampling_reverse_order_changes_sampled_switch",
		bool(report_a.get("reverse_order_changes_sampled_switch", false)),
	)
	_check.call(
		"search_switch_sampling_rotations_can_select_every_switch_by_order_only",
		int(report_a.get("rotation_cases", 0)) == SYNTHETIC_SWITCH_COUNT
		and int(report_a.get("distinct_sampled_switches_across_rotations", 0)) == SYNTHETIC_SWITCH_COUNT
		and bool(report_a.get("all_switches_can_be_selected_by_order_only", false)),
	)
	_check.call(
		"search_switch_sampling_full_cap_preserves_all_switches",
		int(report_a.get("full_cap_switch_count", 0)) == SYNTHETIC_SWITCH_COUNT
		and bool(report_a.get("full_cap_preserves_all_switches", false)),
	)
	_check.call(
		"search_switch_sampling_is_not_switch_order_invariant_under_default_cap",
		not bool(report_a.get("default_sampling_switch_order_invariant", true))
		and bool(report_a.get("input_switch_order_dependency_proven", false)),
	)
	_check.call(
		"search_switch_sampling_bias_predates_frontier",
		not bool(report_a.get("frontier_used_for_sampling", true))
		and not bool(report_a.get("roster_value_used_for_sampling", true)),
	)
	_check.call(
		"search_switch_sampling_does_not_authorize_behavior_integration",
		not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true)),
	)
	_check.call(
		"search_switch_sampling_recommends_order_invariant_boundary_first",
		String(report_a.get("recommended_next_boundary", ""))
		== "audit_order_invariant_context_aware_switch_sampling_before_search_roster_value_integration",
	)
	_check.call("search_switch_sampling_report_deterministic", report_a == report_b)
	_check.call(
		"search_switch_sampling_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH SWITCH SAMPLING BOUNDARY AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fn_report() -> Dictionary:
	var budget := TrainerSearchBudget.depth_two_default()
	var search := TrainerMultiTurnSearch.new(
		DefinitionCatalog.new(),
		TrainerProfile.balanced(),
		budget,
	)
	var switch_ids: Array[String] = [
		"switch_alpha",
		"switch_beta",
		"switch_gamma",
		"switch_delta",
		"switch_epsilon",
	]
	var forward_actions := _c3fn_actions(switch_ids)
	var forward_sample := search._bounded_actions(forward_actions, budget.max_actions_per_side)

	var reverse_ids: Array[String] = []
	for index in range(switch_ids.size() - 1, -1, -1):
		reverse_ids.append(switch_ids[index])
	var reverse_sample := search._bounded_actions(
		_c3fn_actions(reverse_ids),
		budget.max_actions_per_side,
	)

	var forward_sample_switch_ids := _c3fn_switch_ids(forward_sample)
	var reverse_sample_switch_ids := _c3fn_switch_ids(reverse_sample)
	var rotation_records: Array[Dictionary] = []
	var distinct_selected: Dictionary = {}
	for offset in range(switch_ids.size()):
		var rotated: Array[String] = []
		for index in range(switch_ids.size()):
			rotated.append(switch_ids[(index + offset) % switch_ids.size()])
		var sample := search._bounded_actions(
			_c3fn_actions(rotated),
			budget.max_actions_per_side,
		)
		var sampled_switches := _c3fn_switch_ids(sample)
		for switch_id in sampled_switches:
			distinct_selected[switch_id] = true
		rotation_records.append({
			"input_switch_ids": rotated,
			"sampled_switch_ids": sampled_switches,
			"sample_signature": _c3fn_action_signature(sample),
		})

	var full_cap := SYNTHETIC_MOVE_COUNT + SYNTHETIC_SWITCH_COUNT
	var full_sample := search._bounded_actions(forward_actions, full_cap)
	var full_switch_ids := _c3fn_switch_ids(full_sample)
	var sorted_expected := switch_ids.duplicate()
	sorted_expected.sort()
	var sorted_full := full_switch_ids.duplicate()
	sorted_full.sort()

	var default_switch_count := forward_sample_switch_ids.size()
	var default_switch_coverage_bp := (
		default_switch_count * 10000 / SYNTHETIC_SWITCH_COUNT
		if SYNTHETIC_SWITCH_COUNT > 0
		else 0
	)
	return {
		"audit_id": AUDIT_ID_C3FN,
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"action_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"default_max_actions_per_side": budget.max_actions_per_side,
		"synthetic_move_count": SYNTHETIC_MOVE_COUNT,
		"synthetic_switch_count": SYNTHETIC_SWITCH_COUNT,
		"synthetic_total_actions": forward_actions.size(),
		"default_sample_size": forward_sample.size(),
		"default_sample_move_count": _c3fn_move_count(forward_sample),
		"default_sample_switch_count": default_switch_count,
		"default_sample_switch_ids": forward_sample_switch_ids,
		"default_sample_signature": _c3fn_action_signature(forward_sample),
		"default_switch_omitted_count": SYNTHETIC_SWITCH_COUNT - default_switch_count,
		"default_switch_coverage_bp": default_switch_coverage_bp,
		"reverse_sample_switch_ids": reverse_sample_switch_ids,
		"reverse_sample_signature": _c3fn_action_signature(reverse_sample),
		"reverse_order_changes_sampled_switch": forward_sample_switch_ids != reverse_sample_switch_ids,
		"rotation_cases": rotation_records.size(),
		"rotation_records": rotation_records,
		"distinct_sampled_switches_across_rotations": distinct_selected.size(),
		"all_switches_can_be_selected_by_order_only": distinct_selected.size() == SYNTHETIC_SWITCH_COUNT,
		"full_cap": full_cap,
		"full_cap_switch_count": full_switch_ids.size(),
		"full_cap_preserves_all_switches": sorted_full == sorted_expected,
		"default_sampling_switch_order_invariant": forward_sample_switch_ids == reverse_sample_switch_ids,
		"input_switch_order_dependency_proven": forward_sample_switch_ids != reverse_sample_switch_ids,
		"frontier_used_for_sampling": false,
		"roster_value_used_for_sampling": false,
		"behavior_integration_authorized": false,
		"search_sampling_redesign_authorized": false,
		"recommended_next_boundary": "audit_order_invariant_context_aware_switch_sampling_before_search_roster_value_integration",
	}


func _c3fn_actions(switch_ids: Array[String]) -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	for index in range(SYNTHETIC_MOVE_COUNT):
		actions.append(BattleAction.new(
			1,
			&"sampling_active",
			StringName("sampling_move_%d" % index),
			&"sampling_foe",
			BattleAction.MOVE,
			&"side_b",
		))
	for switch_id in switch_ids:
		actions.append(BattleAction.new(
			1,
			&"sampling_active",
			&"",
			&"",
			BattleAction.SWITCH,
			&"side_b",
			StringName(switch_id),
		))
	return actions


func _c3fn_switch_ids(actions: Array[BattleAction]) -> Array[String]:
	var out: Array[String] = []
	for action in actions:
		if action != null and action.action_type == BattleAction.SWITCH:
			out.append(String(action.switch_instance_id))
	return out


func _c3fn_move_count(actions: Array[BattleAction]) -> int:
	var count := 0
	for action in actions:
		if action != null and action.action_type == BattleAction.MOVE:
			count += 1
	return count


func _c3fn_action_signature(actions: Array[BattleAction]) -> Array[String]:
	var out: Array[String] = []
	for action in actions:
		if action == null:
			out.append("null")
		elif action.action_type == BattleAction.SWITCH:
			out.append("switch:%s" % String(action.switch_instance_id))
		elif action.action_type == BattleAction.ITEM:
			out.append("item:%s" % String(action.item_id))
		else:
			out.append("move:%s" % String(action.move_id))
	return out
