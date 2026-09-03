class_name TrainerRosterSearchCrossKindCompositionPolicyAuditTestSuite
extends TrainerRosterSearchCandidatePolicyContractItemAwareAuditTestSuite

# C3f-z is strictly TEST/AUDIT-ONLY. It evaluates a narrow typed composition
# candidate without inventing a shared MOVE/SWITCH/ITEM score. MOVE and ITEM are
# preserved only while each kind has at most one member; SWITCH reduction remains
# exclusively inside the previously audited margin3000 switch-only domain. Any
# need for a second selector fails closed.

const AUDIT_ID_C3FZ := "c3f_z_cross_kind_item_aware_composition_policy_audit_v1"
const TRANCHE_STATUS_C3FZ := "SAFE_TEST_CONTRACT"
const COMPOSITION_POLICY_ID_C3FZ := "preserve_single_move_single_item_plus_switch_margin3000_fail_closed_v1"
const REASON_MULTIPLE_MOVES_C3FZ := "multiple_moves_require_per_kind_selector"
const REASON_MULTIPLE_ITEMS_C3FZ := "multiple_items_require_per_kind_selector"
const REASON_SWITCH_SECONDARY_C3FZ := "switch_subset_requires_secondary_policy"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_cross_kind_composition_policy()


func _test_cross_kind_composition_policy() -> void:
	var report_a := _build_c3fz_report()
	var report_b := _build_c3fz_report()
	var roles := report_a.get("role_probes", {}) as Dictionary
	var root_probe := roles.get(ROLE_ROOT_OPPONENT, {}) as Dictionary
	var own_probe := roles.get(ROLE_OWN_DEPTH2, {}) as Dictionary
	var opponent_probe := roles.get(ROLE_OPPONENT_DEPTH2, {}) as Dictionary

	_check.call(
		"search_cross_kind_composition_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FZ,
	)
	_check.call(
		"search_cross_kind_composition_reports_safe_test_contract_not_production_safety",
		String(report_a.get("tranche_status", "")) == TRANCHE_STATUS_C3FZ
		and bool(report_a.get("test_contract_scope_only", false))
		and not bool(report_a.get("candidate_strategy_proven_safe_globally", true)),
	)
	_check.call(
		"search_cross_kind_composition_policy_id_and_switch_candidate_recorded",
		String(report_a.get("composition_policy_id", "")) == COMPOSITION_POLICY_ID_C3FZ
		and String(report_a.get("switch_candidate_policy_id", "")) == CANDIDATE_POLICY_ID_C3FY
		and String(report_a.get("switch_candidate_scope", "")) == CANDIDATE_POLICY_SCOPE_C3FY,
	)
	_check.call(
		"search_cross_kind_composition_preconditions_are_explicit_and_narrow",
		int(report_a.get("max_move_count_without_per_kind_selector", -1)) == 1
		and int(report_a.get("max_item_count_without_per_kind_selector", -1)) == 1
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_cross_kind_composition_covers_all_three_item_aware_roles",
		roles.keys().size() == 3
		and roles.has(ROLE_ROOT_OPPONENT)
		and roles.has(ROLE_OWN_DEPTH2)
		and roles.has(ROLE_OPPONENT_DEPTH2),
	)
	_check.call(
		"search_cross_kind_composition_no_reduction_preserves_all_actions_all_roles",
		_c3fz_fit_probe_complete(root_probe)
		and _c3fz_fit_probe_complete(own_probe)
		and _c3fz_fit_probe_complete(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_switch_only_overflow_still_uses_margin3000_all_roles",
		_c3fz_switch_probe_complete(root_probe)
		and _c3fz_switch_probe_complete(own_probe)
		and _c3fz_switch_probe_complete(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_switch_only_membership_still_matches_reference",
		_c3fz_switch_probe_matches_reference(root_probe)
		and _c3fz_switch_probe_matches_reference(own_probe)
		and _c3fz_switch_probe_matches_reference(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_narrow_mixed_overflow_completes_all_roles",
		_c3fz_narrow_mixed_complete(root_probe)
		and _c3fz_narrow_mixed_complete(own_probe)
		and _c3fz_narrow_mixed_complete(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_narrow_mixed_input_histogram_is_one_move_two_switch_one_item",
		_c3fz_narrow_input_histogram(root_probe)
		and _c3fz_narrow_input_histogram(own_probe)
		and _c3fz_narrow_input_histogram(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_narrow_mixed_selected_histogram_is_one_each",
		_c3fz_narrow_selected_histogram(root_probe)
		and _c3fz_narrow_selected_histogram(own_probe)
		and _c3fz_narrow_selected_histogram(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_narrow_mixed_fills_exact_inner_cap",
		_c3fz_narrow_selected_count(root_probe) == INNER_ACTION_CAP
		and _c3fz_narrow_selected_count(own_probe) == INNER_ACTION_CAP
		and _c3fz_narrow_selected_count(opponent_probe) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_cross_kind_composition_narrow_mixed_preserves_single_move_and_item",
		_c3fz_narrow_preserves_non_switch_kinds(root_probe)
		and _c3fz_narrow_preserves_non_switch_kinds(own_probe)
		and _c3fz_narrow_preserves_non_switch_kinds(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_narrow_mixed_applies_margin_only_to_switch_subset",
		_c3fz_narrow_switch_scope_only(root_probe)
		and _c3fz_narrow_switch_scope_only(own_probe)
		and _c3fz_narrow_switch_scope_only(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_narrow_mixed_set_is_input_order_invariant",
		_c3fz_narrow_order_invariant(root_probe)
		and _c3fz_narrow_order_invariant(own_probe)
		and _c3fz_narrow_order_invariant(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_unresolved_mixed_overflow_fails_closed_all_roles",
		_c3fz_unresolved_mixed_blocked(root_probe)
		and _c3fz_unresolved_mixed_blocked(own_probe)
		and _c3fz_unresolved_mixed_blocked(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_unresolved_mixed_names_secondary_switch_policy_gap",
		_c3fz_unresolved_reason(root_probe) == REASON_SWITCH_SECONDARY_C3FZ
		and _c3fz_unresolved_reason(own_probe) == REASON_SWITCH_SECONDARY_C3FZ
		and _c3fz_unresolved_reason(opponent_probe) == REASON_SWITCH_SECONDARY_C3FZ,
	)
	_check.call(
		"search_cross_kind_composition_multiple_moves_fail_closed_all_roles",
		_c3fz_multiple_move_blocked(root_probe)
		and _c3fz_multiple_move_blocked(own_probe)
		and _c3fz_multiple_move_blocked(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_multiple_items_fail_closed_all_roles",
		_c3fz_multiple_item_blocked(root_probe)
		and _c3fz_multiple_item_blocked(own_probe)
		and _c3fz_multiple_item_blocked(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_rejects_private_observer_memory_before_opponent_policy",
		_c3fz_private_memory_rejected(root_probe)
		and _c3fz_private_memory_rejected(opponent_probe),
	)
	_check.call(
		"search_cross_kind_composition_current_item_sampler_remains_control_only",
		String(report_a.get("current_item_aware_sampling_model", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL
		and not bool(report_a.get("current_sampler_fallback_used", true))
		and not bool(report_a.get("current_item_aware_round_robin_reused_as_composition_policy", true)),
	)
	_check.call(
		"search_cross_kind_composition_defines_no_shared_cross_kind_score",
		not bool(report_a.get("cross_kind_score_model_defined", true))
		and not bool(report_a.get("move_vs_switch_score_comparison_used", true))
		and not bool(report_a.get("item_vs_switch_score_comparison_used", true)),
	)
	_check.call(
		"search_cross_kind_composition_uses_no_lexical_frontier_roster_or_profile_behavior_fallback",
		not bool(report_a.get("lexical_fallback_used", true))
		and not bool(report_a.get("frontier_fallback_used", true))
		and not bool(report_a.get("roster_value_fallback_used", true))
		and not bool(report_a.get("profile_tiebreak_used", true)),
	)
	_check.call(
		"search_cross_kind_composition_uses_no_hidden_campaign_recovery_replacement_semantics",
		not bool(report_a.get("hidden_belief_fallback_used", true))
		and not bool(report_a.get("campaign_policy_used", true))
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true)),
	)
	_check.call(
		"search_cross_kind_composition_keeps_root_fanout_separate_from_inner_cap",
		bool(report_a.get("root_fanout_all_legal_preserved", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_cross_kind_composition_does_not_reexecute_scheduler_or_select_660",
		not bool(report_a.get("shared_scheduler_reexecuted", true))
		and report_a.get("selected_shared_budget", "sentinel") == null,
	)
	_check.call(
		"search_cross_kind_composition_selects_no_production_strategy_or_scheduler",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true)),
	)
	_check.call(
		"search_cross_kind_composition_keeps_production_adapter_behavior_and_fase34_closed",
		not bool(report_a.get("production_adapter_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("production_files_modified", true))
		and not bool(report_a.get("fase34_open", true)),
	)
	_check.call("search_cross_kind_composition_report_deterministic", report_a == report_b)
	_check.call(
		"search_cross_kind_composition_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH CROSS-KIND ITEM-AWARE COMPOSITION POLICY AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fz_report() -> Dictionary:
	var role_probes := {}
	for role in [ROLE_ROOT_OPPONENT, ROLE_OWN_DEPTH2, ROLE_OPPONENT_DEPTH2]:
		role_probes[role] = _c3fz_role_probe(role)
	return {
		"audit_id": AUDIT_ID_C3FZ,
		"tranche_status": TRANCHE_STATUS_C3FZ,
		"test_contract_scope_only": true,
		"composition_policy_id": COMPOSITION_POLICY_ID_C3FZ,
		"composition_policy_preconditions": "at_most_one_move_at_most_one_item_switch_subset_resolves_with_margin3000_without_secondary_reduction",
		"max_move_count_without_per_kind_selector": 1,
		"max_item_count_without_per_kind_selector": 1,
		"switch_candidate_policy_id": CANDIDATE_POLICY_ID_C3FY,
		"switch_candidate_scope": CANDIDATE_POLICY_SCOPE_C3FY,
		"switch_candidate_margin": CANDIDATE_MARGIN_C3FY,
		"candidate_strategy_proven_safe_globally": false,
		"role_probes": role_probes,
		"current_item_aware_sampling_model": TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
		"current_sampler_fallback_used": false,
		"current_item_aware_round_robin_reused_as_composition_policy": false,
		"cross_kind_score_model_defined": false,
		"move_vs_switch_score_comparison_used": false,
		"item_vs_switch_score_comparison_used": false,
		"lexical_fallback_used": false,
		"frontier_fallback_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"hidden_belief_fallback_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"shared_scheduler_reexecuted": false,
		"selected_shared_budget": null,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"production_strategy_selected": false,
		"production_adapter_authorized": false,
		"behavior_integration_authorized": false,
		"production_files_modified": false,
		"fase34_open": false,
	}


func _c3fz_role_probe(role: String) -> Dictionary:
	var side_id := OBSERVER_SIDE if role == ROLE_OWN_DEPTH2 else OPPONENT_SIDE
	var memory_scope := "observer_memory" if role == ROLE_OWN_DEPTH2 else "opponent_perspective_memory"
	var perspective := _c3fx_perspective(side_id, memory_scope)

	var fit_probe := _c3fz_select(
		_c3fx_selector_request(role, side_id, perspective, _c3fx_actions(side_id), INNER_ACTION_CAP),
		{},
	)
	var switch_probe := _c3fz_select(
		_c3fx_selector_request(role, side_id, perspective, _c3fy_switch_actions(side_id), INNER_ACTION_CAP),
		_c3fy_switch_scores(),
	)
	var narrow_actions := _c3fy_mixed_actions(side_id)
	var narrow_probe := _c3fz_select(
		_c3fx_selector_request(role, side_id, perspective, narrow_actions, INNER_ACTION_CAP),
		{"switch_primary": 10000, "switch_extra": 6000},
	)
	var reversed_narrow := narrow_actions.duplicate()
	reversed_narrow.reverse()
	var narrow_reverse_probe := _c3fz_select(
		_c3fx_selector_request(role, side_id, perspective, reversed_narrow, INNER_ACTION_CAP),
		{"switch_primary": 10000, "switch_extra": 6000},
	)
	var unresolved_probe := _c3fz_select(
		_c3fx_selector_request(role, side_id, perspective, _c3fy_mixed_actions(side_id), INNER_ACTION_CAP),
		_c3fy_mixed_switch_scores(),
	)
	var multiple_move_probe := _c3fz_select(
		_c3fx_selector_request(role, side_id, perspective, _c3fz_multiple_move_actions(side_id), INNER_ACTION_CAP),
		{"switch_primary": 10000},
	)
	var multiple_item_probe := _c3fz_select(
		_c3fx_selector_request(role, side_id, perspective, _c3fz_multiple_item_actions(side_id), INNER_ACTION_CAP),
		{"switch_primary": 10000},
	)
	var private_memory_probe := {}
	if role != ROLE_OWN_DEPTH2:
		private_memory_probe = _c3fz_select(
			_c3fx_selector_request(
				role,
				side_id,
				_c3fx_perspective(side_id, "observer_private_memory"),
				_c3fy_mixed_actions(side_id),
				INNER_ACTION_CAP,
			),
			{"switch_primary": 10000, "switch_extra": 6000},
		)
	return {
		"role": role,
		"side_id": side_id,
		"fit_probe": fit_probe,
		"switch_only_overflow_probe": switch_probe,
		"narrow_mixed_overflow_probe": narrow_probe,
		"narrow_mixed_reverse_probe": narrow_reverse_probe,
		"unresolved_mixed_overflow_probe": unresolved_probe,
		"multiple_move_overflow_probe": multiple_move_probe,
		"multiple_item_overflow_probe": multiple_item_probe,
		"opponent_private_memory_probe": private_memory_probe,
	}


func _c3fz_select(request: Dictionary, switch_scores: Dictionary) -> Dictionary:
	var base_result := _c3fx_select(request)
	if String(base_result.get("outcome", "")) == OUTCOME_COMPLETE:
		var fit := base_result.duplicate(true)
		fit["composition_policy_id"] = COMPOSITION_POLICY_ID_C3FZ
		fit["composition_policy_needed"] = false
		fit["composition_policy_applied"] = false
		fit["switch_candidate_policy_applied"] = false
		fit["current_sampler_fallback_used"] = false
		return fit

	if String(base_result.get("reason", "")) != "semantic_overflow_policy_not_selected":
		var rejected := base_result.duplicate(true)
		rejected["composition_policy_id"] = COMPOSITION_POLICY_ID_C3FZ
		rejected["composition_policy_needed"] = true
		rejected["composition_policy_applied"] = false
		rejected["switch_candidate_policy_applied"] = false
		rejected["current_sampler_fallback_used"] = false
		return rejected

	var actions := request.get("actions", []) as Array
	var moves: Array[BattleAction] = []
	var switches: Array[BattleAction] = []
	var items: Array[BattleAction] = []
	for raw_action in actions:
		var action := raw_action as BattleAction
		match _c3fx_action_kind(action):
			"MOVE":
				moves.append(action)
			"SWITCH":
				switches.append(action)
			"ITEM":
				items.append(action)

	if moves.size() > 1:
		return _c3fz_blocked(base_result, REASON_MULTIPLE_MOVES_C3FZ, moves.size(), switches.size(), items.size())
	if items.size() > 1:
		return _c3fz_blocked(base_result, REASON_MULTIPLE_ITEMS_C3FZ, moves.size(), switches.size(), items.size())

	# Pure SWITCH overflow remains exactly in the C3f-y candidate domain.
	if moves.is_empty() and items.is_empty():
		var switch_only := _c3fy_select_candidate(request, switch_scores)
		switch_only["composition_policy_id"] = COMPOSITION_POLICY_ID_C3FZ
		switch_only["composition_policy_needed"] = true
		switch_only["composition_policy_applied"] = true
		switch_only["cross_kind_composition_used"] = false
		return switch_only

	var limit := int(request.get("limit", 0))
	var preserved_non_switch_count := moves.size() + items.size()
	var available_switch_slots := limit - preserved_non_switch_count
	if available_switch_slots <= 0:
		return _c3fz_blocked(base_result, REASON_SWITCH_SECONDARY_C3FZ, moves.size(), switches.size(), items.size())

	var switch_request := _c3fx_selector_request(
		String(request.get("role", "")),
		String(request.get("side_id", "")),
		(request.get("perspective", {}) as Dictionary),
		switches,
		available_switch_slots,
	)
	var switch_result := _c3fy_select_candidate(switch_request, switch_scores)
	if String(switch_result.get("outcome", "")) != OUTCOME_COMPLETE:
		var blocked := _c3fz_blocked(base_result, REASON_SWITCH_SECONDARY_C3FZ, moves.size(), switches.size(), items.size())
		blocked["switch_subset_outcome"] = switch_result.get("outcome", "")
		blocked["switch_subset_reason"] = switch_result.get("reason", "")
		blocked["available_switch_slots"] = available_switch_slots
		blocked["switch_candidate_policy_applied"] = bool(switch_result.get("candidate_policy_applied", false))
		return blocked

	var selected_switch_ids := {}
	for signature in (switch_result.get("selected_signature", []) as Array):
		selected_switch_ids[String(signature)] = true

	var selected: Array[BattleAction] = []
	for raw_action in actions:
		var action := raw_action as BattleAction
		var kind := _c3fx_action_kind(action)
		if kind == "MOVE" or kind == "ITEM":
			selected.append(BattleAction.from_dict(action.to_dict()))
		elif kind == "SWITCH":
			var signature := "switch:%s" % String(action.switch_instance_id)
			if selected_switch_ids.has(signature):
				selected.append(BattleAction.from_dict(action.to_dict()))

	if selected.size() > limit:
		return _c3fz_blocked(base_result, REASON_SWITCH_SECONDARY_C3FZ, moves.size(), switches.size(), items.size())

	return {
		"outcome": OUTCOME_COMPLETE,
		"reason": "narrow_typed_composition_resolves_without_cross_kind_score",
		"input_count": actions.size(),
		"selected_count": selected.size(),
		"input_signature": _c3fx_action_signature(actions),
		"selected_signature": _c3fx_action_signature(selected),
		"input_kind_histogram": _c3fx_kind_histogram(actions),
		"selected_kind_histogram": _c3fx_kind_histogram(selected),
		"composition_policy_id": COMPOSITION_POLICY_ID_C3FZ,
		"composition_policy_needed": true,
		"composition_policy_applied": true,
		"cross_kind_composition_used": true,
		"preserved_move_count": moves.size(),
		"preserved_item_count": items.size(),
		"available_switch_slots": available_switch_slots,
		"switch_input_count": switches.size(),
		"switch_selected_count": int(switch_result.get("selected_count", 0)),
		"switch_candidate_policy_id": CANDIDATE_POLICY_ID_C3FY,
		"switch_candidate_policy_scope": CANDIDATE_POLICY_SCOPE_C3FY,
		"switch_candidate_policy_applied": bool(switch_result.get("candidate_policy_applied", false)),
		"switch_reference_membership_matches": bool(switch_result.get("reference_membership_matches", false)),
		"cross_kind_score_used": false,
		"lexical_sort_used_for_selection": false,
		"current_sampler_fallback_used": false,
	}


func _c3fz_blocked(base_result: Dictionary, reason: String, move_count: int, switch_count: int, item_count: int) -> Dictionary:
	var blocked := base_result.duplicate(true)
	blocked["reason"] = reason
	blocked["composition_policy_id"] = COMPOSITION_POLICY_ID_C3FZ
	blocked["composition_policy_needed"] = true
	blocked["composition_policy_applied"] = false
	blocked["move_count"] = move_count
	blocked["switch_count"] = switch_count
	blocked["item_count"] = item_count
	blocked["switch_candidate_policy_applied"] = false
	blocked["cross_kind_score_used"] = false
	blocked["current_sampler_fallback_used"] = false
	return blocked


func _c3fz_multiple_move_actions(side_id: String) -> Array[BattleAction]:
	var actions := _c3fx_actions(side_id)
	var side := StringName(side_id)
	var actor := StringName("%s_actor" % side_id)
	actions.append(BattleAction.new(1, actor, &"move_extra", &"target", BattleAction.MOVE, side))
	return actions


func _c3fz_multiple_item_actions(side_id: String) -> Array[BattleAction]:
	var actions := _c3fx_actions(side_id)
	var side := StringName(side_id)
	var actor := StringName("%s_actor" % side_id)
	actions.append(BattleAction.new(1, actor, &"", actor, BattleAction.ITEM, side, &"", &"ether"))
	return actions


func _c3fz_fit_probe_complete(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("fit_probe", {}) as Dictionary
	return String(probe.get("outcome", "")) == OUTCOME_COMPLETE and not bool(probe.get("composition_policy_applied", true))


func _c3fz_switch_probe_complete(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("switch_only_overflow_probe", {}) as Dictionary
	return String(probe.get("outcome", "")) == OUTCOME_COMPLETE and int(probe.get("selected_count", -1)) == 3


func _c3fz_switch_probe_matches_reference(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("switch_only_overflow_probe", {}) as Dictionary
	return bool(probe.get("reference_membership_matches", false)) and bool(probe.get("candidate_policy_applied", false))


func _c3fz_narrow_mixed_complete(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("narrow_mixed_overflow_probe", {}) as Dictionary
	return String(probe.get("outcome", "")) == OUTCOME_COMPLETE and bool(probe.get("composition_policy_applied", false))


func _c3fz_narrow_input_histogram(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("narrow_mixed_overflow_probe", {}) as Dictionary
	return (probe.get("input_kind_histogram", {}) as Dictionary) == {"MOVE": 1, "SWITCH": 2, "ITEM": 1}


func _c3fz_narrow_selected_histogram(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("narrow_mixed_overflow_probe", {}) as Dictionary
	return (probe.get("selected_kind_histogram", {}) as Dictionary) == {"MOVE": 1, "SWITCH": 1, "ITEM": 1}


func _c3fz_narrow_selected_count(role_probe: Dictionary) -> int:
	var probe := role_probe.get("narrow_mixed_overflow_probe", {}) as Dictionary
	return int(probe.get("selected_count", -1))


func _c3fz_narrow_preserves_non_switch_kinds(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("narrow_mixed_overflow_probe", {}) as Dictionary
	var signatures := probe.get("selected_signature", []) as Array
	return signatures.has("move:move_primary") and signatures.has("item:potion:%s_actor" % String(role_probe.get("side_id", "")))


func _c3fz_narrow_switch_scope_only(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("narrow_mixed_overflow_probe", {}) as Dictionary
	return (
		String(probe.get("switch_candidate_policy_id", "")) == CANDIDATE_POLICY_ID_C3FY
		and String(probe.get("switch_candidate_policy_scope", "")) == CANDIDATE_POLICY_SCOPE_C3FY
		and bool(probe.get("switch_candidate_policy_applied", false))
		and not bool(probe.get("cross_kind_score_used", true))
	)


func _c3fz_narrow_order_invariant(role_probe: Dictionary) -> bool:
	var forward := role_probe.get("narrow_mixed_overflow_probe", {}) as Dictionary
	var reverse := role_probe.get("narrow_mixed_reverse_probe", {}) as Dictionary
	var forward_set := _c3fx_sorted_strings(forward.get("selected_signature", []) as Array)
	var reverse_set := _c3fx_sorted_strings(reverse.get("selected_signature", []) as Array)
	return (
		String(reverse.get("outcome", "")) == OUTCOME_COMPLETE
		and forward_set == reverse_set
		and not bool(forward.get("lexical_sort_used_for_selection", true))
		and not bool(reverse.get("lexical_sort_used_for_selection", true))
	)


func _c3fz_unresolved_mixed_blocked(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("unresolved_mixed_overflow_probe", {}) as Dictionary
	return String(probe.get("outcome", "")) == OUTCOME_NO_DECISION and (probe.get("selected_signature", []) as Array).is_empty()


func _c3fz_unresolved_reason(role_probe: Dictionary) -> String:
	return String((role_probe.get("unresolved_mixed_overflow_probe", {}) as Dictionary).get("reason", ""))


func _c3fz_multiple_move_blocked(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("multiple_move_overflow_probe", {}) as Dictionary
	return String(probe.get("outcome", "")) == OUTCOME_NO_DECISION and String(probe.get("reason", "")) == REASON_MULTIPLE_MOVES_C3FZ


func _c3fz_multiple_item_blocked(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("multiple_item_overflow_probe", {}) as Dictionary
	return String(probe.get("outcome", "")) == OUTCOME_NO_DECISION and String(probe.get("reason", "")) == REASON_MULTIPLE_ITEMS_C3FZ


func _c3fz_private_memory_rejected(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("opponent_private_memory_probe", {}) as Dictionary
	return (
		String(probe.get("outcome", "")) == OUTCOME_NO_DECISION
		and String(probe.get("reason", "")) == "opponent_perspective_cannot_reuse_observer_private_memory"
		and not bool(probe.get("composition_policy_applied", true))
	)
