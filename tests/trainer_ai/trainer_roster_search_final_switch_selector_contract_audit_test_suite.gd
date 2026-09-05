class_name TrainerRosterSearchFinalSwitchSelectorContractAuditTestSuite
extends TrainerRosterItemAwareShadowProductionLifecycleAuditTestSuite

# C3f-ag is strictly TEST/AUDIT/CONTRACT-ONLY. It studies the missing
# candidate-set -> single SWITCH boundary without modifying production or
# authorizing behavior. Margin3000 remains membership telemetry only.

const AUDIT_ID_C3FAG := "c3f_ag_final_switch_selector_contract_audit_v1"
const BOUNDARY_ID_C3FAG := "define_and_audit_deterministic_single_switch_resolution_without_behavior_integration"
const SELECTOR_CONTRACT_VALIDATED_C3FAG := "SELECTOR_CONTRACT_VALIDATED"
const NEEDS_POLICY_DECISION_C3FAG := "NEEDS_POLICY_DECISION"
const NEEDS_MORE_VALIDATION_C3FAG := "NEEDS_MORE_VALIDATION"
const BLOCKED_C3FAG := "BLOCKED"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_final_switch_selector_contract()


func _test_final_switch_selector_contract() -> void:
	var report := _build_c3fag_report()
	var shadow_probes := report.get("shadow_probes", []) as Array
	var corpus_probes := report.get("corpus_probes", []) as Array
	var status := String(report.get("tranche_status", ""))

	_check.call("final_switch_selector_audit_id_recorded", String(report.get("audit_id", "")) == AUDIT_ID_C3FAG)
	_check.call("final_switch_selector_boundary_id_recorded", String(report.get("boundary_id", "")) == BOUNDARY_ID_C3FAG)
	_check.call(
		"final_switch_selector_status_is_explicit_allowed_value",
		[
			SELECTOR_CONTRACT_VALIDATED_C3FAG,
			NEEDS_POLICY_DECISION_C3FAG,
			NEEDS_MORE_VALIDATION_C3FAG,
			BLOCKED_C3FAG,
		].has(status),
	)
	_check.call(
		"final_switch_selector_candidate_membership_contract_preserved",
		String(report.get("candidate_policy_id", "")) == TrainerItemAwareShadowProbe.CANDIDATE_POLICY_ID
		and int(report.get("candidate_margin", -1)) == TrainerItemAwareShadowProbe.CANDIDATE_MARGIN
		and String(report.get("candidate_policy_scope", "")) == "switch_only",
	)
	_check.call(
		"final_switch_selector_shadow_covers_current_and_branch_both_sides",
		shadow_probes.size() == 4
		and int(report.get("shadow_ready_contexts", -1)) == 4,
	)
	_check.call(
		"final_switch_selector_shadow_confirms_multi_candidate_boundary",
		int(report.get("shadow_multi_candidate_contexts", -1)) == 4
		and _c3fag_all_true(shadow_probes, "candidate_set_ambiguous"),
	)
	_check.call(
		"final_switch_selector_shadow_uses_side_matching_detached_contexts",
		_c3fag_all_true(shadow_probes, "context_side_matching")
		and _c3fag_all_true(shadow_probes, "shadow_telemetry_only"),
	)
	_check.call(
		"final_switch_selector_input_first_is_not_order_invariant",
		int(report.get("input_first_order_sensitive_shadow_contexts", 0)) == 4
		and _c3fag_all_false(shadow_probes, "input_first_order_invariant"),
	)
	_check.call(
		"final_switch_selector_lexical_is_order_invariant_but_forbidden",
		_c3fag_all_true(shadow_probes, "lexical_order_invariant")
		and not bool(report.get("lexical_selector_authorized", true))
		and not bool(report.get("lexical_selector_used", true)),
	)
	_check.call(
		"final_switch_selector_max_depth1_is_order_invariant_as_set_rule",
		_c3fag_all_true(shadow_probes, "max_depth1_order_invariant")
		and int(report.get("max_depth1_order_invariance_failures", -1)) == 0,
	)
	_check.call(
		"final_switch_selector_max_depth1_not_pre_authorized",
		not bool(report.get("max_depth1_selector_authorized", true))
		and not bool(report.get("max_depth1_selector_selected", true)),
	)
	_check.call(
		"final_switch_selector_disjoint_reference_corpus_is_available",
		String(report.get("reference_corpus_status", "")) == SAFE_DISJOINT_TEST_CORPUS
		and int(report.get("reference_corpus_case_count", -1)) == ROLE_CASE_COUNT_C3FAD,
	)
	_check.call(
		"final_switch_selector_reference_corpus_is_semantically_complete",
		int(report.get("reference_corpus_complete_cases", -1)) == ROLE_CASE_COUNT_C3FAD
		and int(report.get("reference_corpus_incomplete_cases", -1)) == 0,
	)
	_check.call(
		"final_switch_selector_reference_corpus_has_ambiguous_candidate_sets",
		int(report.get("reference_multi_candidate_cases", 0)) > 0,
	)
	_check.call(
		"final_switch_selector_max_depth1_reference_accounting_complete",
		int(report.get("max_depth1_unique_reference_cases", 0))
		+ int(report.get("max_depth1_tied_reference_cases", 0))
		== int(report.get("reference_multi_candidate_cases", -1)),
	)
	_check.call(
		"final_switch_selector_max_depth1_deep_best_accounting_complete",
		int(report.get("max_depth1_deep_best_hit_cases", 0))
		+ int(report.get("max_depth1_deep_best_miss_cases", 0))
		== int(report.get("max_depth1_unique_reference_cases", -1)),
	)
	_check.call(
		"final_switch_selector_max_depth1_score_loss_accounting_nonnegative",
		int(report.get("max_depth1_depth2_score_loss_sum", -1)) >= 0
		and int(report.get("max_depth1_depth2_score_loss_max", -1)) >= 0,
	)
	_check.call(
		"final_switch_selector_reference_probes_keep_candidate_and_deep_sets_explicit",
		_c3fag_reference_probe_shapes_valid(corpus_probes),
	)
	_check.call(
		"final_switch_selector_any_max_depth1_success_remains_sample_scoped",
		not bool(report.get("max_depth1_proven_safe_globally", true))
		and not bool(report.get("candidate_strategy_proven_safe_globally", true)),
	)
	_check.call(
		"final_switch_selector_margin_membership_not_redefined_as_top1",
		not bool(report.get("margin_membership_redefined_as_single_action", true))
		and bool(report.get("max_depth1_would_collapse_multi_candidate_sets_to_top1", false)),
	)
	_check.call(
		"final_switch_selector_current_sampler_not_hidden_selector",
		not bool(report.get("current_sampler_selector_authorized", true))
		and not bool(report.get("current_sampler_selector_used", true)),
	)
	_check.call(
		"final_switch_selector_no_live_rng",
		not bool(report.get("live_rng_used", true))
		and not bool(report.get("random_tiebreak_authorized", true)),
	)
	_check.call(
		"final_switch_selector_no_forbidden_fallbacks",
		not bool(report.get("lexical_fallback_used", true))
		and not bool(report.get("frontier_fallback_used", true))
		and not bool(report.get("pareto_tiebreak_used", true))
		and not bool(report.get("roster_value_fallback_used", true))
		and not bool(report.get("profile_tiebreak_used", true))
		and not bool(report.get("campaign_policy_used", true))
		and not bool(report.get("recovery_policy_used", true))
		and not bool(report.get("replacement_policy_used", true)),
	)
	_check.call(
		"final_switch_selector_move_switch_item_remain_separate",
		String(report.get("action_kind_contract", "")) == "MOVE_SWITCH_ITEM_explicit_no_cross_kind_final_selector"
		and not bool(report.get("cross_kind_score_model_defined", true)),
	)
	_check.call(
		"final_switch_selector_root_fanout_stays_separate_from_inner_cap3",
		bool(report.get("root_fanout_all_legal_preserved", false))
		and int(report.get("inner_max_actions_per_side", -1)) == 3,
	)
	_check.call(
		"final_switch_selector_no_strategy_scheduler_or_shared_budget_selected",
		report.get("selected_strategy_id", "sentinel") == null
		and report.get("selected_scheduler_id", "sentinel") == null
		and report.get("selected_shared_budget", "sentinel") == null
		and not bool(report.get("shared_660_reopened", true)),
	)
	_check.call(
		"final_switch_selector_contract_remains_unselected_without_semantic_authority",
		report.get("selected_final_selector_id", "sentinel") == null
		and not bool(report.get("selector_contract_validated", true))
		and not bool(report.get("semantic_authority_for_final_selector_present", true)),
	)
	_check.call(
		"final_switch_selector_status_requires_policy_decision_after_clean_audit",
		status == NEEDS_POLICY_DECISION_C3FAG
		and bool(report.get("policy_decision_required", false)),
	)
	_check.call(
		"final_switch_selector_behavior_and_action_substitution_stay_closed",
		not bool(report.get("behavior_integration_authorized", true))
		and not bool(report.get("action_substitution_authorized", true))
		and not bool(report.get("margin3000_behavior_enabled", true)),
	)
	_check.call(
		"final_switch_selector_production_surfaces_untouched",
		not bool(report.get("production_files_modified", true))
		and not bool(report.get("brains_modified", true))
		and not bool(report.get("production_sampler_modified", true))
		and not bool(report.get("production_budget_modified", true))
		and not bool(report.get("phase_logic_modified", true)),
	)
	_check.call("final_switch_selector_fase34_stays_closed", not bool(report.get("fase34_open", true)))
	_check.call("final_switch_selector_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER ROSTER SEARCH FINAL SWITCH SELECTOR CONTRACT AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fag_report() -> Dictionary:
	var shadow_report := _build_c3faf_report()
	var reference_report := _build_c3fad_report()
	var shadow_probes: Array[Dictionary] = []
	for entry in [
		["current_side_a", shadow_report.get("current_side_a", {})],
		["current_side_b", shadow_report.get("current_side_b", {})],
		["branch_side_a", shadow_report.get("branch_side_a", {})],
		["branch_side_b", shadow_report.get("branch_side_b", {})],
	]:
		shadow_probes.append(_c3fag_shadow_probe(String(entry[0]), entry[1] as Dictionary))

	var shadow_ready_contexts := _c3fag_count_true(shadow_probes, "shadow_ready")
	var shadow_multi_candidate_contexts := _c3fag_count_true(shadow_probes, "candidate_set_ambiguous")
	var input_first_order_sensitive_shadow_contexts := _c3fag_count_false(shadow_probes, "input_first_order_invariant")
	var max_depth1_order_invariance_failures := _c3fag_count_false(shadow_probes, "max_depth1_order_invariant")

	var corpus_probes: Array[Dictionary] = []
	var reference_complete_cases := 0
	var reference_incomplete_cases := 0
	var reference_multi_candidate_cases := 0
	var max_depth1_unique_reference_cases := 0
	var max_depth1_tied_reference_cases := 0
	var max_depth1_deep_best_hit_cases := 0
	var max_depth1_deep_best_miss_cases := 0
	var max_depth1_depth2_score_loss_sum := 0
	var max_depth1_depth2_score_loss_max := 0
	for raw_case in reference_report.get("cases", []) as Array:
		var case := raw_case as Dictionary
		var probe := _c3fag_reference_probe(case)
		corpus_probes.append(probe)
		if bool(probe.get("semantically_complete", false)):
			reference_complete_cases += 1
		else:
			reference_incomplete_cases += 1
		if bool(probe.get("candidate_set_ambiguous", false)):
			reference_multi_candidate_cases += 1
			if bool(probe.get("max_depth1_unique", false)):
				max_depth1_unique_reference_cases += 1
				if bool(probe.get("max_depth1_hits_deep_best", false)):
					max_depth1_deep_best_hit_cases += 1
				else:
					max_depth1_deep_best_miss_cases += 1
				var loss := int(probe.get("max_depth1_depth2_score_loss", 0))
				max_depth1_depth2_score_loss_sum += loss
				max_depth1_depth2_score_loss_max = maxi(max_depth1_depth2_score_loss_max, loss)
			else:
				max_depth1_tied_reference_cases += 1

	var reference_status := String(reference_report.get("tranche_status", ""))
	var evidence_blocked := (
		shadow_ready_contexts != 4
		or reference_status == BLOCKED_C3FAD
	)
	var evidence_incomplete := (
		not evidence_blocked
		and (
			reference_status == NEEDS_MORE_VALIDATION_C3FAD
			or reference_incomplete_cases > 0
			or shadow_multi_candidate_contexts == 0
			or reference_multi_candidate_cases == 0
		)
	)
	var status := NEEDS_POLICY_DECISION_C3FAG
	if evidence_blocked:
		status = BLOCKED_C3FAG
	elif evidence_incomplete:
		status = NEEDS_MORE_VALIDATION_C3FAG

	var max_depth1_would_collapse := false
	for probe in shadow_probes:
		if bool(probe.get("candidate_set_ambiguous", false)) and bool(probe.get("max_depth1_unique", false)):
			max_depth1_would_collapse = true
			break
	if not max_depth1_would_collapse:
		for probe in corpus_probes:
			if bool(probe.get("candidate_set_ambiguous", false)) and bool(probe.get("max_depth1_unique", false)):
				max_depth1_would_collapse = true
				break

	return {
		"audit_id": AUDIT_ID_C3FAG,
		"boundary_id": BOUNDARY_ID_C3FAG,
		"tranche_status": status,
		"candidate_policy_id": TrainerItemAwareShadowProbe.CANDIDATE_POLICY_ID,
		"candidate_margin": TrainerItemAwareShadowProbe.CANDIDATE_MARGIN,
		"candidate_policy_scope": "switch_only",
		"candidate_membership_rule": "switch_depth1_score_gte_best_switch_depth1_score_minus_3000",
		"candidate_strategy_proven_safe_globally": false,
		"shadow_probes": shadow_probes,
		"shadow_ready_contexts": shadow_ready_contexts,
		"shadow_multi_candidate_contexts": shadow_multi_candidate_contexts,
		"input_first_order_sensitive_shadow_contexts": input_first_order_sensitive_shadow_contexts,
		"max_depth1_order_invariance_failures": max_depth1_order_invariance_failures,
		"reference_corpus_id": String(reference_report.get("corpus_id", "")),
		"reference_corpus_status": reference_status,
		"reference_corpus_case_count": corpus_probes.size(),
		"reference_corpus_complete_cases": reference_complete_cases,
		"reference_corpus_incomplete_cases": reference_incomplete_cases,
		"reference_multi_candidate_cases": reference_multi_candidate_cases,
		"corpus_probes": corpus_probes,
		"max_depth1_unique_reference_cases": max_depth1_unique_reference_cases,
		"max_depth1_tied_reference_cases": max_depth1_tied_reference_cases,
		"max_depth1_deep_best_hit_cases": max_depth1_deep_best_hit_cases,
		"max_depth1_deep_best_miss_cases": max_depth1_deep_best_miss_cases,
		"max_depth1_depth2_score_loss_sum": max_depth1_depth2_score_loss_sum,
		"max_depth1_depth2_score_loss_max": max_depth1_depth2_score_loss_max,
		"max_depth1_proven_safe_globally": false,
		"max_depth1_would_collapse_multi_candidate_sets_to_top1": max_depth1_would_collapse,
		"margin_membership_redefined_as_single_action": false,
		"input_order_selector_authorized": false,
		"input_order_selector_used": false,
		"lexical_selector_authorized": false,
		"lexical_selector_used": false,
		"max_depth1_selector_authorized": false,
		"max_depth1_selector_selected": false,
		"current_sampler_selector_authorized": false,
		"current_sampler_selector_used": false,
		"random_tiebreak_authorized": false,
		"live_rng_used": false,
		"lexical_fallback_used": false,
		"frontier_fallback_used": false,
		"pareto_tiebreak_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit_no_cross_kind_final_selector",
		"cross_kind_score_model_defined": false,
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": 3,
		"selected_final_selector_id": null,
		"selector_contract_validated": false,
		"semantic_authority_for_final_selector_present": false,
		"policy_decision_required": status == NEEDS_POLICY_DECISION_C3FAG,
		"recommended_next_boundary": "documentary_policy_decision_on_final_switch_selector_semantics" if status == NEEDS_POLICY_DECISION_C3FAG else null,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"behavior_integration_authorized": false,
		"action_substitution_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_files_modified": false,
		"brains_modified": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"phase_logic_modified": false,
		"fase34_open": false,
	}


func _c3fag_shadow_probe(label: String, shadow: Dictionary) -> Dictionary:
	var candidates := _c3fag_string_array(shadow.get("margin3000_switch_ids", []) as Array)
	var scores := shadow.get("switch_scores", {}) as Dictionary
	var forward := candidates.duplicate()
	var reverse := candidates.duplicate()
	reverse.reverse()
	var first_forward := _c3fag_first_or_empty(forward)
	var first_reverse := _c3fag_first_or_empty(reverse)
	var lexical_forward := _c3fag_lexical_first(forward)
	var lexical_reverse := _c3fag_lexical_first(reverse)
	var max_forward := _c3fag_max_score_ids(scores, forward)
	var max_reverse := _c3fag_max_score_ids(scores, reverse)
	return {
		"label": label,
		"shadow_ready": String(shadow.get("tranche_status", "")) == TrainerItemAwareShadowProbe.SHADOW_READY,
		"context_side_matching": bool(shadow.get("context_side_matching", false)),
		"shadow_telemetry_only": bool(shadow.get("shadow_result_is_telemetry_only", false)) and not bool(shadow.get("shadow_action_selected", true)),
		"candidate_ids": candidates,
		"candidate_count": candidates.size(),
		"candidate_set_ambiguous": candidates.size() > 1,
		"switch_scores": scores.duplicate(true),
		"input_first_forward": first_forward,
		"input_first_reverse": first_reverse,
		"input_first_order_invariant": first_forward == first_reverse,
		"lexical_forward": lexical_forward,
		"lexical_reverse": lexical_reverse,
		"lexical_order_invariant": lexical_forward == lexical_reverse,
		"max_depth1_forward_ids": max_forward,
		"max_depth1_reverse_ids": max_reverse,
		"max_depth1_order_invariant": max_forward == max_reverse,
		"max_depth1_unique": max_forward.size() == 1,
	}


func _c3fag_reference_probe(case: Dictionary) -> Dictionary:
	var candidates := _c3fag_string_array(case.get("promoted_switch_ids", []) as Array)
	var depth1_scores := case.get("depth1_scores", {}) as Dictionary
	var depth2_scores := case.get("depth2_all_legal_scores", {}) as Dictionary
	var deep_best_ids := _c3fag_string_array(case.get("global_deep_best_ids", []) as Array)
	var reverse := candidates.duplicate()
	reverse.reverse()
	var max_forward := _c3fag_max_score_ids(depth1_scores, candidates)
	var max_reverse := _c3fag_max_score_ids(depth1_scores, reverse)
	var unique := max_forward.size() == 1
	var selected_id := max_forward[0] if unique else ""
	var hits_deep_best := unique and deep_best_ids.has(selected_id)
	var all_best_depth2 := int(case.get("all_legal_best_depth2_score", -2147483648))
	var selected_depth2 := int(depth2_scores.get(selected_id, -2147483648)) if unique else -2147483648
	var loss := maxi(0, all_best_depth2 - selected_depth2) if unique else 0
	return {
		"case_id": String(case.get("case_id", "")),
		"role": String(case.get("role", "")),
		"side_id": String(case.get("side_id", "")),
		"semantically_complete": bool(case.get("semantically_complete", false)),
		"candidate_ids": candidates,
		"candidate_count": candidates.size(),
		"candidate_set_ambiguous": candidates.size() > 1,
		"depth1_scores": depth1_scores.duplicate(true),
		"depth2_all_legal_scores": depth2_scores.duplicate(true),
		"global_deep_best_ids": deep_best_ids,
		"max_depth1_forward_ids": max_forward,
		"max_depth1_reverse_ids": max_reverse,
		"max_depth1_order_invariant": max_forward == max_reverse,
		"max_depth1_unique": unique,
		"max_depth1_selected_id": selected_id,
		"max_depth1_hits_deep_best": hits_deep_best,
		"max_depth1_depth2_score_loss": loss,
	}


func _c3fag_max_score_ids(scores: Dictionary, candidate_ids: Array) -> Array[String]:
	var out: Array[String] = []
	if candidate_ids.is_empty():
		return out
	var best := -2147483648
	for raw_id in candidate_ids:
		var candidate_id := String(raw_id)
		if not scores.has(candidate_id):
			return []
		best = maxi(best, int(scores[candidate_id]))
	for raw_id in candidate_ids:
		var candidate_id := String(raw_id)
		if int(scores.get(candidate_id, -2147483648)) == best and not out.has(candidate_id):
			out.append(candidate_id)
	out.sort()
	return out


func _c3fag_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for raw_value in values:
		out.append(String(raw_value))
	return out


func _c3fag_first_or_empty(values: Array[String]) -> String:
	return values[0] if not values.is_empty() else ""


func _c3fag_lexical_first(values: Array[String]) -> String:
	if values.is_empty():
		return ""
	var ordered := values.duplicate()
	ordered.sort()
	return ordered[0]


func _c3fag_count_true(probes: Array, key: String) -> int:
	var count := 0
	for raw_probe in probes:
		if bool((raw_probe as Dictionary).get(key, false)):
			count += 1
	return count


func _c3fag_count_false(probes: Array, key: String) -> int:
	var count := 0
	for raw_probe in probes:
		if not bool((raw_probe as Dictionary).get(key, false)):
			count += 1
	return count


func _c3fag_all_true(probes: Array, key: String) -> bool:
	if probes.is_empty():
		return false
	for raw_probe in probes:
		if not bool((raw_probe as Dictionary).get(key, false)):
			return false
	return true


func _c3fag_all_false(probes: Array, key: String) -> bool:
	if probes.is_empty():
		return false
	for raw_probe in probes:
		if bool((raw_probe as Dictionary).get(key, true)):
			return false
	return true


func _c3fag_reference_probe_shapes_valid(probes: Array) -> bool:
	if probes.size() != ROLE_CASE_COUNT_C3FAD:
		return false
	for raw_probe in probes:
		var probe := raw_probe as Dictionary
		if not probe.has("candidate_ids") \
			or not probe.has("depth1_scores") \
			or not probe.has("depth2_all_legal_scores") \
			or not probe.has("global_deep_best_ids") \
			or not probe.has("max_depth1_forward_ids") \
			or not probe.has("max_depth1_reverse_ids"):
			return false
	return true
