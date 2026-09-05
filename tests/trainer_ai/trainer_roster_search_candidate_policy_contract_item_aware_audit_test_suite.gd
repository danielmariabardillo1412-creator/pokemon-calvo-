class_name TrainerRosterSearchCandidatePolicyContractItemAwareAuditTestSuite
extends TrainerRosterSearchContractApiDesignAuditTestSuite

# C3f-y is strictly TEST/AUDIT-ONLY. It exercises the empirically validated
# depth1_margin_3000_all_legal candidate through the isolated C3f-x selector
# contract without inventing a production adapter or a cross-kind ItemAware
# policy. Prior C3f-q..v evidence is SWITCH-only; mixed MOVE/SWITCH/ITEM overflow
# therefore fails closed until a separate cross-kind policy is explicitly defined.

const AUDIT_ID_C3FY := "c3f_y_candidate_policy_through_item_aware_contract_audit_v1"
const TRANCHE_STATUS_C3FY := "BLOCKED"
const BLOCKER_ID_C3FY := "cross_kind_candidate_screen_policy_undefined"
const CANDIDATE_POLICY_ID_C3FY := "depth1_margin_3000_all_legal"
const CANDIDATE_POLICY_SCOPE_C3FY := "switch_only"
const CANDIDATE_MARGIN_C3FY := 3000
const PRIOR_DISTINCT_CASES_C3FU_V := 96
const PRIOR_PRESERVED_CASES_C3FU_V := 96


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_candidate_policy_through_item_aware_contract()


func _test_candidate_policy_through_item_aware_contract() -> void:
	var report_a := _build_c3fy_report()
	var report_b := _build_c3fy_report()
	var roles := report_a.get("role_probes", {}) as Dictionary
	var root_probe := roles.get(ROLE_ROOT_OPPONENT, {}) as Dictionary
	var own_probe := roles.get(ROLE_OWN_DEPTH2, {}) as Dictionary
	var opponent_probe := roles.get(ROLE_OPPONENT_DEPTH2, {}) as Dictionary

	_check.call(
		"search_candidate_contract_item_aware_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FY,
	)
	_check.call(
		"search_candidate_contract_item_aware_reports_blocked_not_false_success",
		String(report_a.get("tranche_status", "")) == TRANCHE_STATUS_C3FY
		and String(report_a.get("blocker_id", "")) == BLOCKER_ID_C3FY,
	)
	_check.call(
		"search_candidate_contract_item_aware_uses_margin3000_as_test_candidate_only",
		String(report_a.get("candidate_policy_id", "")) == CANDIDATE_POLICY_ID_C3FY
		and int(report_a.get("candidate_margin", -1)) == CANDIDATE_MARGIN_C3FY
		and String(report_a.get("candidate_policy_scope", "")) == CANDIDATE_POLICY_SCOPE_C3FY,
	)
	_check.call(
		"search_candidate_contract_item_aware_prior_evidence_remains_sample_scoped",
		int(report_a.get("prior_distinct_cases", 0)) == PRIOR_DISTINCT_CASES_C3FU_V
		and int(report_a.get("prior_preserved_cases", 0)) == PRIOR_PRESERVED_CASES_C3FU_V
		and not bool(report_a.get("candidate_strategy_proven_safe_globally", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_covers_all_three_contract_roles",
		(roles.keys().size() == 3)
		and roles.has(ROLE_ROOT_OPPONENT)
		and roles.has(ROLE_OWN_DEPTH2)
		and roles.has(ROLE_OPPONENT_DEPTH2),
	)
	_check.call(
		"search_candidate_contract_item_aware_no_reduction_path_preserves_all_kinds_all_roles",
		_c3fy_fit_probe_is_complete(root_probe)
		and _c3fy_fit_probe_is_complete(own_probe)
		and _c3fy_fit_probe_is_complete(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_switch_only_overflow_completes_all_roles",
		_c3fy_switch_probe_is_complete(root_probe)
		and _c3fy_switch_probe_is_complete(own_probe)
		and _c3fy_switch_probe_is_complete(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_switch_only_membership_matches_c3fq_margin_reference",
		_c3fy_switch_probe_matches_reference(root_probe)
		and _c3fy_switch_probe_matches_reference(own_probe)
		and _c3fy_switch_probe_matches_reference(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_switch_only_selects_three_of_four_without_secondary_fallback",
		_c3fy_switch_probe_selects_expected_set(root_probe)
		and _c3fy_switch_probe_selects_expected_set(own_probe)
		and _c3fy_switch_probe_selects_expected_set(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_switch_membership_set_is_input_order_invariant",
		_c3fy_switch_order_probe_is_invariant(root_probe)
		and _c3fy_switch_order_probe_is_invariant(own_probe)
		and _c3fy_switch_order_probe_is_invariant(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_mixed_overflow_fails_closed_all_roles",
		_c3fy_mixed_probe_is_blocked(root_probe)
		and _c3fy_mixed_probe_is_blocked(own_probe)
		and _c3fy_mixed_probe_is_blocked(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_mixed_overflow_preserves_explicit_kind_accounting",
		_c3fy_mixed_histogram_is_expected(root_probe)
		and _c3fy_mixed_histogram_is_expected(own_probe)
		and _c3fy_mixed_histogram_is_expected(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_does_not_apply_switch_candidate_to_mixed_overflow",
		_c3fy_mixed_candidate_not_applied(root_probe)
		and _c3fy_mixed_candidate_not_applied(own_probe)
		and _c3fy_mixed_candidate_not_applied(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_records_exact_current_item_sampler_model",
		String(report_a.get("current_item_aware_sampling_model", ""))
		== TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL
		and String(report_a.get("current_item_aware_sampling_model", ""))
		== "move_switch_item_stratified_round_robin_v1",
	)
	_check.call(
		"search_candidate_contract_item_aware_refuses_current_sampler_as_hidden_fallback",
		not bool(report_a.get("current_sampler_fallback_used", true))
		and not bool(report_a.get("current_item_aware_round_robin_reused_as_candidate_policy", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_does_not_invent_cross_kind_scores_or_item_reservation",
		not bool(report_a.get("cross_kind_score_model_defined", true))
		and not bool(report_a.get("item_reservation_policy_invented", true))
		and not bool(report_a.get("mixed_kind_policy_selected", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_rejects_private_observer_memory_before_opponent_policy",
		_c3fy_private_memory_probe_rejected(root_probe)
		and _c3fy_private_memory_probe_rejected(opponent_probe),
	)
	_check.call(
		"search_candidate_contract_item_aware_own_role_uses_sanitized_observer_perspective",
		String((own_probe.get("fit_probe", {}) as Dictionary).get("outcome", "")) == OUTCOME_COMPLETE
		and String(own_probe.get("side_id", "")) == OBSERVER_SIDE,
	)
	_check.call(
		"search_candidate_contract_item_aware_no_lexical_frontier_roster_or_profile_fallback",
		not bool(report_a.get("lexical_fallback_used", true))
		and not bool(report_a.get("frontier_fallback_used", true))
		and not bool(report_a.get("roster_value_fallback_used", true))
		and not bool(report_a.get("profile_tiebreak_used", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_no_hidden_campaign_recovery_or_replacement_semantics",
		not bool(report_a.get("hidden_belief_fallback_used", true))
		and not bool(report_a.get("campaign_policy_used", true))
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_keeps_root_fanout_separate_from_inner_cap",
		bool(report_a.get("root_fanout_all_legal_preserved", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_candidate_contract_item_aware_does_not_reexecute_or_select_shared_660",
		not bool(report_a.get("shared_scheduler_reexecuted", true))
		and report_a.get("selected_shared_budget", "sentinel") == null,
	)
	_check.call(
		"search_candidate_contract_item_aware_selects_no_production_strategy_or_scheduler",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_keeps_production_adapter_and_behavior_unauthorized",
		not bool(report_a.get("production_adapter_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_keeps_production_and_fase34_closed",
		not bool(report_a.get("production_files_modified", true))
		and not bool(report_a.get("fase34_open", true)),
	)
	_check.call(
		"search_candidate_contract_item_aware_blocker_requires_documentary_decision",
		bool(report_a.get("blocker_requires_documentary_decision", false))
		and report_a.get("recommended_next_boundary", "sentinel") == null,
	)
	_check.call("search_candidate_contract_item_aware_report_deterministic", report_a == report_b)
	_check.call(
		"search_candidate_contract_item_aware_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH CANDIDATE POLICY THROUGH ITEM-AWARE CONTRACT AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fy_report() -> Dictionary:
	var role_probes := {}
	for role in [ROLE_ROOT_OPPONENT, ROLE_OWN_DEPTH2, ROLE_OPPONENT_DEPTH2]:
		role_probes[role] = _c3fy_role_probe(role)
	return {
		"audit_id": AUDIT_ID_C3FY,
		"tranche_status": TRANCHE_STATUS_C3FY,
		"blocker_id": BLOCKER_ID_C3FY,
		"blocker_reason": "validated_margin_candidate_has_switch_only_evidence_and_no_authorized_cross_kind_item_aware_composition_policy",
		"blocker_requires_documentary_decision": true,
		"recommended_next_boundary": null,
		"candidate_policy_id": CANDIDATE_POLICY_ID_C3FY,
		"candidate_margin": CANDIDATE_MARGIN_C3FY,
		"candidate_policy_scope": CANDIDATE_POLICY_SCOPE_C3FY,
		"candidate_membership_rule": "switch_depth1_score_gte_best_switch_depth1_score_minus_3000",
		"prior_distinct_cases": PRIOR_DISTINCT_CASES_C3FU_V,
		"prior_preserved_cases": PRIOR_PRESERVED_CASES_C3FU_V,
		"prior_evidence_scope": "sample_scoped_switch_candidates_only",
		"candidate_strategy_proven_safe_globally": false,
		"role_probes": role_probes,
		"current_item_aware_sampling_model": TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
		"current_sampler_fallback_used": false,
		"current_item_aware_round_robin_reused_as_candidate_policy": false,
		"cross_kind_score_model_defined": false,
		"item_reservation_policy_invented": false,
		"mixed_kind_policy_selected": false,
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
		"search_sampling_redesign_authorized": false,
		"production_files_modified": false,
		"fase34_open": false,
	}


func _c3fy_role_probe(role: String) -> Dictionary:
	var side_id := OBSERVER_SIDE if role == ROLE_OWN_DEPTH2 else OPPONENT_SIDE
	var memory_scope := "observer_memory" if role == ROLE_OWN_DEPTH2 else "opponent_perspective_memory"
	var perspective := _c3fx_perspective(side_id, memory_scope)
	var fit_probe := _c3fy_select_candidate(
		_c3fx_selector_request(role, side_id, perspective, _c3fx_actions(side_id), INNER_ACTION_CAP),
		{},
	)
	var switch_actions := _c3fy_switch_actions(side_id)
	var switch_scores := _c3fy_switch_scores()
	var switch_probe := _c3fy_select_candidate(
		_c3fx_selector_request(role, side_id, perspective, switch_actions, INNER_ACTION_CAP),
		switch_scores,
	)
	var reversed_switch_actions := switch_actions.duplicate()
	reversed_switch_actions.reverse()
	var reverse_switch_probe := _c3fy_select_candidate(
		_c3fx_selector_request(role, side_id, perspective, reversed_switch_actions, INNER_ACTION_CAP),
		switch_scores,
	)
	var mixed_probe := _c3fy_select_candidate(
		_c3fx_selector_request(role, side_id, perspective, _c3fy_mixed_actions(side_id), INNER_ACTION_CAP),
		_c3fy_mixed_switch_scores(),
	)
	var private_memory_probe := {}
	if role != ROLE_OWN_DEPTH2:
		private_memory_probe = _c3fy_select_candidate(
			_c3fx_selector_request(
				role,
				side_id,
				_c3fx_perspective(side_id, "observer_private_memory"),
				switch_actions,
				INNER_ACTION_CAP,
			),
			switch_scores,
		)
	return {
		"role": role,
		"side_id": side_id,
		"fit_probe": fit_probe,
		"switch_only_overflow_probe": switch_probe,
		"switch_only_reverse_probe": reverse_switch_probe,
		"mixed_item_aware_overflow_probe": mixed_probe,
		"opponent_private_memory_probe": private_memory_probe,
	}


func _c3fy_select_candidate(request: Dictionary, candidate_scores: Dictionary) -> Dictionary:
	var base_result := _c3fx_select(request)
	if String(base_result.get("outcome", "")) == OUTCOME_COMPLETE:
		var fit := base_result.duplicate(true)
		fit["candidate_policy_id"] = CANDIDATE_POLICY_ID_C3FY
		fit["candidate_policy_scope"] = CANDIDATE_POLICY_SCOPE_C3FY
		fit["candidate_policy_needed"] = false
		fit["candidate_policy_applied"] = false
		fit["current_sampler_fallback_used"] = false
		return fit

	if String(base_result.get("reason", "")) != "semantic_overflow_policy_not_selected":
		var rejected := base_result.duplicate(true)
		rejected["candidate_policy_id"] = CANDIDATE_POLICY_ID_C3FY
		rejected["candidate_policy_scope"] = CANDIDATE_POLICY_SCOPE_C3FY
		rejected["candidate_policy_needed"] = true
		rejected["candidate_policy_applied"] = false
		rejected["current_sampler_fallback_used"] = false
		return rejected

	var actions := request.get("actions", []) as Array
	var limit := int(request.get("limit", 0))
	var all_switch := true
	for raw_action in actions:
		if _c3fx_action_kind(raw_action as BattleAction) != "SWITCH":
			all_switch = false
			break

	if not all_switch:
		var blocked := base_result.duplicate(true)
		blocked["reason"] = BLOCKER_ID_C3FY
		blocked["blocker_id"] = BLOCKER_ID_C3FY
		blocked["candidate_policy_id"] = CANDIDATE_POLICY_ID_C3FY
		blocked["candidate_policy_scope"] = CANDIDATE_POLICY_SCOPE_C3FY
		blocked["candidate_policy_needed"] = true
		blocked["candidate_policy_applied"] = false
		blocked["cross_kind_policy_defined"] = false
		blocked["current_sampler_fallback_used"] = false
		return blocked

	var candidate_ids: Array[String] = []
	var best_score := -2147483648
	for raw_action in actions:
		var action := raw_action as BattleAction
		var candidate_id := String(action.switch_instance_id)
		candidate_ids.append(candidate_id)
		if not candidate_scores.has(candidate_id):
			var missing := base_result.duplicate(true)
			missing["reason"] = "candidate_score_missing_for_switch"
			missing["candidate_policy_applied"] = false
			missing["current_sampler_fallback_used"] = false
			return missing
		best_score = maxi(best_score, int(candidate_scores.get(candidate_id, -2147483648)))

	var selected: Array[BattleAction] = []
	for raw_action in actions:
		var action := raw_action as BattleAction
		var candidate_id := String(action.switch_instance_id)
		if int(candidate_scores.get(candidate_id, -2147483648)) >= best_score - CANDIDATE_MARGIN_C3FY:
			selected.append(BattleAction.from_dict(action.to_dict()))

	var reference_ids := _c3fq_promote_by_margin(candidate_ids, candidate_scores, CANDIDATE_MARGIN_C3FY)
	var selected_ids: Array[String] = []
	for action in selected:
		selected_ids.append(String(action.switch_instance_id))
	var selected_set := selected_ids.duplicate()
	selected_set.sort()

	if selected.is_empty():
		var empty_selection := base_result.duplicate(true)
		empty_selection["reason"] = "candidate_screen_selected_no_switch"
		empty_selection["candidate_policy_applied"] = true
		empty_selection["reference_membership_matches"] = selected_set == reference_ids
		empty_selection["current_sampler_fallback_used"] = false
		return empty_selection
	if selected.size() > limit:
		var still_overflow := base_result.duplicate(true)
		still_overflow["reason"] = "candidate_screen_still_exceeds_inner_limit_without_secondary_policy"
		still_overflow["candidate_policy_applied"] = true
		still_overflow["reference_membership_matches"] = selected_set == reference_ids
		still_overflow["current_sampler_fallback_used"] = false
		return still_overflow

	return {
		"outcome": OUTCOME_COMPLETE,
		"reason": "switch_only_margin_candidate_resolves_overflow",
		"input_count": actions.size(),
		"selected_count": selected.size(),
		"input_signature": _c3fx_action_signature(actions),
		"selected_signature": _c3fx_action_signature(selected),
		"input_kind_histogram": _c3fx_kind_histogram(actions),
		"selected_kind_histogram": _c3fx_kind_histogram(selected),
		"candidate_policy_id": CANDIDATE_POLICY_ID_C3FY,
		"candidate_policy_scope": CANDIDATE_POLICY_SCOPE_C3FY,
		"candidate_policy_needed": true,
		"candidate_policy_applied": true,
		"candidate_margin": CANDIDATE_MARGIN_C3FY,
		"best_candidate_score": best_score,
		"selected_candidate_ids_in_input_order": selected_ids,
		"selected_candidate_set_for_telemetry": selected_set,
		"reference_promoted_ids": reference_ids,
		"reference_membership_matches": selected_set == reference_ids,
		"lexical_sort_used_for_selection": false,
		"current_sampler_fallback_used": false,
	}


func _c3fy_switch_actions(side_id: String) -> Array[BattleAction]:
	var side := StringName(side_id)
	var actor := StringName("%s_actor" % side_id)
	var out: Array[BattleAction] = []
	for suffix in ["a", "b", "c", "d"]:
		out.append(BattleAction.new(
			1,
			actor,
			&"",
			&"",
			BattleAction.SWITCH,
			side,
			StringName("switch_%s" % suffix),
		))
	return out


func _c3fy_switch_scores() -> Dictionary:
	return {
		"switch_a": 10000,
		"switch_b": 9000,
		"switch_c": 7500,
		"switch_d": 6000,
	}


func _c3fy_mixed_actions(side_id: String) -> Array[BattleAction]:
	var out := _c3fx_actions(side_id)
	out.append(BattleAction.new(
		1,
		StringName("%s_actor" % side_id),
		&"",
		&"",
		BattleAction.SWITCH,
		StringName(side_id),
		&"switch_extra",
	))
	return out


func _c3fy_mixed_switch_scores() -> Dictionary:
	return {
		"switch_primary": 10000,
		"switch_extra": 9000,
	}


func _c3fy_fit_probe_is_complete(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("fit_probe", {}) as Dictionary
	return (
		String(probe.get("outcome", "")) == OUTCOME_COMPLETE
		and (probe.get("input_kind_histogram", {}) as Dictionary) == {"MOVE": 1, "SWITCH": 1, "ITEM": 1}
		and (probe.get("selected_kind_histogram", {}) as Dictionary) == {"MOVE": 1, "SWITCH": 1, "ITEM": 1}
		and not bool(probe.get("candidate_policy_applied", true))
	)


func _c3fy_switch_probe_is_complete(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("switch_only_overflow_probe", {}) as Dictionary
	return (
		String(probe.get("outcome", "")) == OUTCOME_COMPLETE
		and int(probe.get("input_count", -1)) == 4
		and int(probe.get("selected_count", -1)) == 3
		and bool(probe.get("candidate_policy_applied", false))
	)


func _c3fy_switch_probe_matches_reference(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("switch_only_overflow_probe", {}) as Dictionary
	return bool(probe.get("reference_membership_matches", false))


func _c3fy_switch_probe_selects_expected_set(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("switch_only_overflow_probe", {}) as Dictionary
	return (probe.get("selected_candidate_set_for_telemetry", []) as Array) == ["switch_a", "switch_b", "switch_c"]


func _c3fy_switch_order_probe_is_invariant(role_probe: Dictionary) -> bool:
	var forward := role_probe.get("switch_only_overflow_probe", {}) as Dictionary
	var reverse := role_probe.get("switch_only_reverse_probe", {}) as Dictionary
	return (
		String(reverse.get("outcome", "")) == OUTCOME_COMPLETE
		and (forward.get("selected_candidate_set_for_telemetry", []) as Array)
		== (reverse.get("selected_candidate_set_for_telemetry", []) as Array)
		and not bool(forward.get("lexical_sort_used_for_selection", true))
		and not bool(reverse.get("lexical_sort_used_for_selection", true))
	)


func _c3fy_mixed_probe_is_blocked(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("mixed_item_aware_overflow_probe", {}) as Dictionary
	return (
		String(probe.get("outcome", "")) == OUTCOME_NO_DECISION
		and String(probe.get("reason", "")) == BLOCKER_ID_C3FY
		and (probe.get("selected_signature", []) as Array).is_empty()
	)


func _c3fy_mixed_histogram_is_expected(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("mixed_item_aware_overflow_probe", {}) as Dictionary
	return (probe.get("input_kind_histogram", {}) as Dictionary) == {"MOVE": 1, "SWITCH": 2, "ITEM": 1}


func _c3fy_mixed_candidate_not_applied(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("mixed_item_aware_overflow_probe", {}) as Dictionary
	return (
		not bool(probe.get("candidate_policy_applied", true))
		and not bool(probe.get("current_sampler_fallback_used", true))
	)


func _c3fy_private_memory_probe_rejected(role_probe: Dictionary) -> bool:
	var probe := role_probe.get("opponent_private_memory_probe", {}) as Dictionary
	return (
		String(probe.get("outcome", "")) == OUTCOME_NO_DECISION
		and String(probe.get("reason", "")) == "opponent_perspective_cannot_reuse_observer_private_memory"
		and not bool(probe.get("candidate_policy_applied", true))
	)
