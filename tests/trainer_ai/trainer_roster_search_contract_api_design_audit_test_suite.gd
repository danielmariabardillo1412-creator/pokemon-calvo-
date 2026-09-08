class_name TrainerRosterSearchContractApiDesignAuditTestSuite
extends TrainerRosterSearchProductionSeamMappingAuditTestSuite

# C3f-x is strictly TEST/AUDIT-ONLY. It turns the C3f-w NEEDS_NEW_API finding
# into executable fail-closed contracts without modifying production search,
# brains, budgets, action generation or behavior.

const AUDIT_ID_C3FX := "c3f_x_search_contract_api_design_audit_v1"
const CONTRACT_STATUS_C3FX := "CONTRACT_API_ISOLATABLE_POLICY_UNSELECTED"
const SELECTOR_CONTRACT_ID_C3FX := "side_aware_action_kind_aware_fail_closed_selector_contract_v1"
const SCHEDULER_CONTRACT_ID_C3FX := "shared_total_equal_quota_no_redistribution_contract_v1"
const RECOMMENDED_NEXT_BOUNDARY_C3FX := "test_candidate_screen_policy_through_isolated_contract_on_item_aware_roles_before_any_production_adapter"

const ROLE_ROOT_OPPONENT := "root_opponent_response"
const ROLE_OWN_DEPTH2 := "own_depth2_continuation"
const ROLE_OPPONENT_DEPTH2 := "opponent_depth2_continuation"

const OUTCOME_COMPLETE := "COMPLETE"
const OUTCOME_TRUNCATED := "TRUNCATED"
const OUTCOME_NO_DECISION := "NO_DECISION"

const OBSERVER_SIDE := "own"
const OPPONENT_SIDE := "opponent"
const INNER_ACTION_CAP := 3
const PER_ROOT_SIMULATION_CAP := 220
const CONTROL_BUDGETS := [220, 440, 660]


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_contract_api_design()


func _test_contract_api_design() -> void:
	var report_a := _build_c3fx_report()
	var report_b := _build_c3fx_report()
	var selector := report_a.get("selector_contract", {}) as Dictionary
	var scheduler := report_a.get("scheduler_contract", {}) as Dictionary
	var selector_complete := selector.get("complete_probe", {}) as Dictionary
	var selector_overflow := selector.get("overflow_probe", {}) as Dictionary
	var selector_bad_perspective := selector.get("opponent_private_memory_reuse_probe", {}) as Dictionary
	var selector_reverse := selector.get("reverse_order_probe", {}) as Dictionary
	var budget_reports := scheduler.get("budget_reports", {}) as Dictionary
	var budget_220 := budget_reports.get("220", {}) as Dictionary
	var budget_440 := budget_reports.get("440", {}) as Dictionary
	var budget_660 := budget_reports.get("660", {}) as Dictionary
	var budget_zero := scheduler.get("zero_budget_probe", {}) as Dictionary
	var order_probe := scheduler.get("root_order_probe", {}) as Dictionary

	_check.call(
		"search_contract_api_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FX,
	)
	_check.call(
		"search_contract_api_status_is_isolatable_but_policy_unselected",
		String(report_a.get("contract_status", "")) == CONTRACT_STATUS_C3FX,
	)
	_check.call(
		"search_contract_api_selector_contract_id_recorded",
		String(selector.get("contract_id", "")) == SELECTOR_CONTRACT_ID_C3FX,
	)
	_check.call(
		"search_contract_api_selector_models_all_three_inner_roles",
		(selector.get("supported_roles", []) as Array) == [
			ROLE_ROOT_OPPONENT,
			ROLE_OWN_DEPTH2,
			ROLE_OPPONENT_DEPTH2,
		],
	)
	_check.call(
		"search_contract_api_selector_requires_explicit_side_and_sanitized_perspective",
		bool(selector.get("side_id_required", false))
		and bool(selector.get("sanitized_perspective_required", false))
		and bool(selector.get("perspective_side_must_match_role", false)),
	)
	_check.call(
		"search_contract_api_selector_preserves_move_switch_item_kinds",
		(selector_complete.get("input_kind_histogram", {}) as Dictionary) == {
			"MOVE": 1,
			"SWITCH": 1,
			"ITEM": 1,
		}
		and (selector_complete.get("selected_kind_histogram", {}) as Dictionary) == {
			"MOVE": 1,
			"SWITCH": 1,
			"ITEM": 1,
		},
	)
	_check.call(
		"search_contract_api_selector_complete_when_no_semantic_reduction_needed",
		String(selector_complete.get("outcome", "")) == OUTCOME_COMPLETE
		and int(selector_complete.get("input_count", -1)) == INNER_ACTION_CAP
		and int(selector_complete.get("selected_count", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_contract_api_selector_overflow_fails_closed_without_policy",
		String(selector_overflow.get("outcome", "")) == OUTCOME_NO_DECISION
		and String(selector_overflow.get("reason", "")) == "semantic_overflow_policy_not_selected"
		and (selector_overflow.get("selected_signature", []) as Array).is_empty(),
	)
	_check.call(
		"search_contract_api_selector_has_no_lexical_fallback",
		not bool(selector.get("lexical_fallback_authorized", true))
		and not bool(selector.get("canonicalization_used_for_behavior", true)),
	)
	_check.call(
		"search_contract_api_selector_rejects_observer_private_memory_for_opponent",
		String(selector_bad_perspective.get("outcome", "")) == OUTCOME_NO_DECISION
		and String(selector_bad_perspective.get("reason", "")) == "opponent_perspective_cannot_reuse_observer_private_memory",
	)
	_check.call(
		"search_contract_api_selector_accepts_distinct_sanitized_opponent_perspective",
		String((selector.get("opponent_perspective_probe", {}) as Dictionary).get("outcome", "")) == OUTCOME_COMPLETE,
	)
	_check.call(
		"search_contract_api_selector_rejects_role_perspective_mismatch",
		String((selector.get("role_perspective_mismatch_probe", {}) as Dictionary).get("outcome", "")) == OUTCOME_NO_DECISION,
	)
	_check.call(
		"search_contract_api_selector_no_reduction_is_set_invariant_to_input_order",
		bool(selector_reverse.get("selected_set_matches", false))
		and not bool(selector_reverse.get("lexical_sort_used_to_select", true)),
	)
	_check.call(
		"search_contract_api_scheduler_contract_id_recorded",
		String(scheduler.get("contract_id", "")) == SCHEDULER_CONTRACT_ID_C3FX,
	)
	_check.call(
		"search_contract_api_scheduler_owns_one_shared_total_budget",
		bool(scheduler.get("shared_total_budget_owned_by_scheduler", false))
		and int(scheduler.get("per_root_cap", -1)) == PER_ROOT_SIMULATION_CAP,
	)
	_check.call(
		"search_contract_api_scheduler_tests_expected_control_budgets",
		(scheduler.get("control_budgets", []) as Array) == CONTROL_BUDGETS,
	)
	_check.call(
		"search_contract_api_budget_220_is_truncated_and_accounted",
		String(budget_220.get("outcome", "")) == OUTCOME_TRUNCATED
		and int(budget_220.get("simulations_allocated", -1)) <= 220
		and int(budget_220.get("budget_violations", -1)) == 0,
	)
	_check.call(
		"search_contract_api_budget_440_is_truncated_and_accounted",
		String(budget_440.get("outcome", "")) == OUTCOME_TRUNCATED
		and int(budget_440.get("simulations_allocated", -1)) <= 440
		and int(budget_440.get("budget_violations", -1)) == 0,
	)
	_check.call(
		"search_contract_api_budget_660_completes_without_exceeding_total",
		String(budget_660.get("outcome", "")) == OUTCOME_COMPLETE
		and int(budget_660.get("simulations_allocated", -1)) <= 660
		and int(budget_660.get("complete_roots", -1)) == 5
		and int(budget_660.get("budget_violations", -1)) == 0,
	)
	_check.call(
		"search_contract_api_zero_budget_is_explicit_no_decision",
		String(budget_zero.get("outcome", "")) == OUTCOME_NO_DECISION
		and int(budget_zero.get("simulations_allocated", -1)) == 0,
	)
	_check.call(
		"search_contract_api_scheduler_is_root_order_invariant",
		bool(order_probe.get("allocations_match", false))
		and bool(order_probe.get("outcomes_match", false)),
	)
	_check.call(
		"search_contract_api_scheduler_does_not_redistribute_unused_quota",
		int(budget_660.get("redistributed_simulations", -1)) == 0
		and int(budget_660.get("unused_budget", -1)) == 160,
	)
	_check.call(
		"search_contract_api_shared_660_is_not_five_times_per_root_220",
		int(scheduler.get("five_root_independent_per_root_hard_cap", -1)) == 1100
		and int(scheduler.get("shared_control_budget", -1)) == 660
		and int(scheduler.get("five_root_independent_per_root_hard_cap", -1)) != int(scheduler.get("shared_control_budget", -1)),
	)
	_check.call(
		"search_contract_api_scheduler_exposes_all_required_outcomes",
		(scheduler.get("outcome_enum", []) as Array) == [
			OUTCOME_COMPLETE,
			OUTCOME_TRUNCATED,
			OUTCOME_NO_DECISION,
		],
	)
	_check.call(
		"search_contract_api_selects_no_production_strategy_scheduler_or_budget",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null,
	)
	_check.call(
		"search_contract_api_keeps_global_safety_unproven",
		not bool(report_a.get("candidate_strategy_proven_safe_globally", true)),
	)
	_check.call(
		"search_contract_api_keeps_behavior_and_production_adapter_unauthorized",
		not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("production_adapter_authorized", true)),
	)
	_check.call(
		"search_contract_api_keeps_production_and_fase34_unchanged",
		not bool(report_a.get("production_files_modified", true))
		and not bool(report_a.get("fase34_open", true))
		and bool(report_a.get("root_fanout_all_legal_preserved", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_contract_api_recommends_test_only_policy_adapter_audit_next",
		String(report_a.get("recommended_next_boundary", "")) == RECOMMENDED_NEXT_BOUNDARY_C3FX,
	)
	_check.call("search_contract_api_report_deterministic", report_a == report_b)
	_check.call(
		"search_contract_api_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH CONTRACT API DESIGN AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fx_report() -> Dictionary:
	var complete_request := _c3fx_selector_request(
		ROLE_OWN_DEPTH2,
		OBSERVER_SIDE,
		_c3fx_perspective(OBSERVER_SIDE, "observer_memory"),
		_c3fx_actions(OBSERVER_SIDE),
		INNER_ACTION_CAP,
	)
	var complete_probe := _c3fx_select(complete_request)

	var overflow_actions := _c3fx_actions(OBSERVER_SIDE)
	overflow_actions.append(
		BattleAction.new(1, &"own_actor", &"move_extra", &"target", BattleAction.MOVE, StringName(OBSERVER_SIDE))
	)
	var overflow_probe := _c3fx_select(
		_c3fx_selector_request(
			ROLE_OWN_DEPTH2,
			OBSERVER_SIDE,
			_c3fx_perspective(OBSERVER_SIDE, "observer_memory"),
			overflow_actions,
			INNER_ACTION_CAP,
		)
	)

	var opponent_perspective_probe := _c3fx_select(
		_c3fx_selector_request(
			ROLE_OPPONENT_DEPTH2,
			OPPONENT_SIDE,
			_c3fx_perspective(OPPONENT_SIDE, "opponent_perspective_memory"),
			_c3fx_actions(OPPONENT_SIDE),
			INNER_ACTION_CAP,
		)
	)
	var opponent_private_memory_reuse_probe := _c3fx_select(
		_c3fx_selector_request(
			ROLE_OPPONENT_DEPTH2,
			OPPONENT_SIDE,
			_c3fx_perspective(OPPONENT_SIDE, "observer_private_memory"),
			_c3fx_actions(OPPONENT_SIDE),
			INNER_ACTION_CAP,
		)
	)
	var role_perspective_mismatch_probe := _c3fx_select(
		_c3fx_selector_request(
			ROLE_ROOT_OPPONENT,
			OPPONENT_SIDE,
			_c3fx_perspective(OBSERVER_SIDE, "observer_memory"),
			_c3fx_actions(OPPONENT_SIDE),
			INNER_ACTION_CAP,
		)
	)

	var reverse_actions := _c3fx_actions(OBSERVER_SIDE)
	reverse_actions.reverse()
	var reverse_result := _c3fx_select(
		_c3fx_selector_request(
			ROLE_OWN_DEPTH2,
			OBSERVER_SIDE,
			_c3fx_perspective(OBSERVER_SIDE, "observer_memory"),
			reverse_actions,
			INNER_ACTION_CAP,
		)
	)
	var forward_set := _c3fx_sorted_strings(complete_probe.get("selected_signature", []) as Array)
	var reverse_set := _c3fx_sorted_strings(reverse_result.get("selected_signature", []) as Array)

	var roots := _c3fx_root_requests()
	var budget_reports := {}
	for budget in CONTROL_BUDGETS:
		budget_reports[str(budget)] = _c3fx_schedule(roots, int(budget), PER_ROOT_SIMULATION_CAP)
	var reversed_roots := roots.duplicate(true)
	reversed_roots.reverse()
	var forward_440 := budget_reports.get("440", {}) as Dictionary
	var reverse_440 := _c3fx_schedule(reversed_roots, 440, PER_ROOT_SIMULATION_CAP)

	return {
		"audit_id": AUDIT_ID_C3FX,
		"contract_status": CONTRACT_STATUS_C3FX,
		"recommended_next_boundary": RECOMMENDED_NEXT_BOUNDARY_C3FX,
		"selector_contract": {
			"contract_id": SELECTOR_CONTRACT_ID_C3FX,
			"supported_roles": [ROLE_ROOT_OPPONENT, ROLE_OWN_DEPTH2, ROLE_OPPONENT_DEPTH2],
			"side_id_required": true,
			"sanitized_perspective_required": true,
			"perspective_side_must_match_role": true,
			"action_kinds": ["MOVE", "SWITCH", "ITEM"],
			"inner_limit": INNER_ACTION_CAP,
			"overflow_without_semantic_policy": OUTCOME_NO_DECISION,
			"lexical_fallback_authorized": false,
			"canonicalization_used_for_behavior": false,
			"complete_probe": complete_probe,
			"overflow_probe": overflow_probe,
			"opponent_perspective_probe": opponent_perspective_probe,
			"opponent_private_memory_reuse_probe": opponent_private_memory_reuse_probe,
			"role_perspective_mismatch_probe": role_perspective_mismatch_probe,
			"reverse_order_probe": {
				"selected_set_matches": forward_set == reverse_set,
				"forward_set_for_telemetry_only": forward_set,
				"reverse_set_for_telemetry_only": reverse_set,
				"lexical_sort_used_to_select": false,
			},
		},
		"scheduler_contract": {
			"contract_id": SCHEDULER_CONTRACT_ID_C3FX,
			"shared_total_budget_owned_by_scheduler": true,
			"per_root_cap": PER_ROOT_SIMULATION_CAP,
			"control_budgets": CONTROL_BUDGETS.duplicate(),
			"shared_control_budget": 660,
			"five_root_independent_per_root_hard_cap": 5 * PER_ROOT_SIMULATION_CAP,
			"outcome_enum": [OUTCOME_COMPLETE, OUTCOME_TRUNCATED, OUTCOME_NO_DECISION],
			"redistribution_authorized": false,
			"lexical_fallback_authorized": false,
			"frontier_fallback_authorized": false,
			"roster_value_fallback_authorized": false,
			"profile_tiebreak_authorized": false,
			"hidden_belief_fallback_authorized": false,
			"budget_reports": budget_reports,
			"zero_budget_probe": _c3fx_schedule(roots, 0, PER_ROOT_SIMULATION_CAP),
			"root_order_probe": {
				"allocations_match": (forward_440.get("allocations", {}) as Dictionary) == (reverse_440.get("allocations", {}) as Dictionary),
				"outcomes_match": (forward_440.get("root_outcomes", {}) as Dictionary) == (reverse_440.get("root_outcomes", {}) as Dictionary),
			},
		},
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"candidate_strategy_proven_safe_globally": false,
		"behavior_integration_authorized": false,
		"production_adapter_authorized": false,
		"production_files_modified": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"fase34_open": false,
	}


func _c3fx_selector_request(
	role: String,
	side_id: String,
	perspective: Dictionary,
	actions: Array[BattleAction],
	limit: int,
) -> Dictionary:
	var cloned_actions: Array[BattleAction] = []
	for action in actions:
		cloned_actions.append(BattleAction.from_dict(action.to_dict()))
	return {
		"role": role,
		"side_id": side_id,
		"observer_side_id": OBSERVER_SIDE,
		"opponent_side_id": OPPONENT_SIDE,
		"perspective": perspective.duplicate(true),
		"actions": cloned_actions,
		"limit": limit,
	}


func _c3fx_select(request: Dictionary) -> Dictionary:
	var empty := {
		"outcome": OUTCOME_NO_DECISION,
		"reason": "invalid_request",
		"input_count": 0,
		"selected_count": 0,
		"input_signature": [],
		"selected_signature": [],
		"input_kind_histogram": {},
		"selected_kind_histogram": {},
	}
	var role := String(request.get("role", ""))
	var side_id := String(request.get("side_id", ""))
	var observer_side_id := String(request.get("observer_side_id", ""))
	var opponent_side_id := String(request.get("opponent_side_id", ""))
	var perspective := request.get("perspective", {}) as Dictionary
	var actions := request.get("actions", []) as Array
	var limit := int(request.get("limit", 0))
	empty["input_count"] = actions.size()
	empty["input_signature"] = _c3fx_action_signature(actions)
	empty["input_kind_histogram"] = _c3fx_kind_histogram(actions)

	if role not in [ROLE_ROOT_OPPONENT, ROLE_OWN_DEPTH2, ROLE_OPPONENT_DEPTH2]:
		empty["reason"] = "unsupported_role"
		return empty
	if side_id.is_empty() or limit <= 0:
		empty["reason"] = "missing_side_or_limit"
		return empty
	if not bool(perspective.get("sanitized", false)):
		empty["reason"] = "unsanitized_perspective"
		return empty
	var expected_side := observer_side_id if role == ROLE_OWN_DEPTH2 else opponent_side_id
	if String(perspective.get("side_id", "")) != expected_side or side_id != expected_side:
		empty["reason"] = "role_perspective_side_mismatch"
		return empty
	if expected_side == opponent_side_id and String(perspective.get("memory_scope", "")) == "observer_private_memory":
		empty["reason"] = "opponent_perspective_cannot_reuse_observer_private_memory"
		return empty
	for raw_action in actions:
		var action := raw_action as BattleAction
		if action == null or String(action.side_id) != side_id:
			empty["reason"] = "action_side_mismatch"
			return empty
		if _c3fx_action_kind(action).is_empty():
			empty["reason"] = "unsupported_action_kind"
			return empty
	if actions.size() > limit:
		empty["reason"] = "semantic_overflow_policy_not_selected"
		return empty

	var selected: Array[BattleAction] = []
	for raw_action in actions:
		selected.append(BattleAction.from_dict((raw_action as BattleAction).to_dict()))
	return {
		"outcome": OUTCOME_COMPLETE,
		"reason": "all_actions_fit_without_semantic_reduction",
		"input_count": actions.size(),
		"selected_count": selected.size(),
		"input_signature": _c3fx_action_signature(actions),
		"selected_signature": _c3fx_action_signature(selected),
		"input_kind_histogram": _c3fx_kind_histogram(actions),
		"selected_kind_histogram": _c3fx_kind_histogram(selected),
	}


func _c3fx_perspective(side_id: String, memory_scope: String) -> Dictionary:
	return {
		"side_id": side_id,
		"sanitized": true,
		"memory_scope": memory_scope,
		"hidden_opponent_roster_available": false,
		"private_rng_available": false,
	}


func _c3fx_actions(side_id: String) -> Array[BattleAction]:
	var side := StringName(side_id)
	var actor := StringName("%s_actor" % side_id)
	var actions: Array[BattleAction] = []
	actions.append(BattleAction.new(1, actor, &"move_primary", &"target", BattleAction.MOVE, side))
	actions.append(BattleAction.new(1, actor, &"", &"", BattleAction.SWITCH, side, &"switch_primary"))
	actions.append(BattleAction.new(1, actor, &"", actor, BattleAction.ITEM, side, &"", &"potion"))
	return actions


func _c3fx_action_kind(action: BattleAction) -> String:
	if action == null:
		return ""
	match action.action_type:
		BattleAction.MOVE:
			return "MOVE"
		BattleAction.SWITCH:
			return "SWITCH"
		BattleAction.ITEM:
			return "ITEM"
		_:
			return ""


func _c3fx_action_signature(actions: Array) -> Array[String]:
	var out: Array[String] = []
	for raw_action in actions:
		var action := raw_action as BattleAction
		if action == null:
			out.append("null")
			continue
		match action.action_type:
			BattleAction.MOVE:
				out.append("move:%s" % String(action.move_id))
			BattleAction.SWITCH:
				out.append("switch:%s" % String(action.switch_instance_id))
			BattleAction.ITEM:
				out.append("item:%s:%s" % [String(action.item_id), String(action.target_id)])
			_:
				out.append("unknown")
	return out


func _c3fx_kind_histogram(actions: Array) -> Dictionary:
	var out := {"MOVE": 0, "SWITCH": 0, "ITEM": 0}
	for raw_action in actions:
		var kind := _c3fx_action_kind(raw_action as BattleAction)
		if out.has(kind):
			out[kind] = int(out[kind]) + 1
	return out


func _c3fx_sorted_strings(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	out.sort()
	return out


func _c3fx_root_requests() -> Array:
	return [
		{"root_id": "root_0", "requested_simulations": 40},
		{"root_id": "root_1", "requested_simulations": 80},
		{"root_id": "root_2", "requested_simulations": 120},
		{"root_id": "root_3", "requested_simulations": 130},
		{"root_id": "root_4", "requested_simulations": 130},
	]


func _c3fx_schedule(root_requests: Array, shared_budget: int, per_root_cap: int) -> Dictionary:
	var normalized_budget := maxi(0, shared_budget)
	var normalized_cap := maxi(0, per_root_cap)
	var root_count := root_requests.size()
	var quota := 0
	if root_count > 0:
		quota = mini(normalized_cap, int(normalized_budget / root_count))
	var allocations := {}
	var root_outcomes := {}
	var total_allocated := 0
	var complete_roots := 0
	var truncated_roots := 0
	var no_decision_roots := 0
	var budget_violations := 0

	for raw_request in root_requests:
		var request := raw_request as Dictionary
		var root_id := String(request.get("root_id", ""))
		var requested := clampi(int(request.get("requested_simulations", 0)), 0, normalized_cap)
		var allocated := mini(requested, quota)
		allocations[root_id] = allocated
		total_allocated += allocated
		var outcome := OUTCOME_NO_DECISION
		if requested <= allocated:
			outcome = OUTCOME_COMPLETE
			complete_roots += 1
		elif allocated > 0:
			outcome = OUTCOME_TRUNCATED
			truncated_roots += 1
		else:
			no_decision_roots += 1
		root_outcomes[root_id] = outcome
		if allocated > normalized_cap:
			budget_violations += 1
	if total_allocated > normalized_budget:
		budget_violations += 1

	var global_outcome := OUTCOME_NO_DECISION
	if root_count > 0 and complete_roots == root_count:
		global_outcome = OUTCOME_COMPLETE
	elif total_allocated > 0:
		global_outcome = OUTCOME_TRUNCATED

	return {
		"shared_budget": normalized_budget,
		"per_root_cap": normalized_cap,
		"root_count": root_count,
		"equal_upfront_quota": quota,
		"allocations": allocations,
		"root_outcomes": root_outcomes,
		"outcome": global_outcome,
		"complete_roots": complete_roots,
		"truncated_roots": truncated_roots,
		"no_decision_roots": no_decision_roots,
		"simulations_allocated": total_allocated,
		"unused_budget": normalized_budget - total_allocated,
		"redistributed_simulations": 0,
		"budget_violations": budget_violations,
	}
