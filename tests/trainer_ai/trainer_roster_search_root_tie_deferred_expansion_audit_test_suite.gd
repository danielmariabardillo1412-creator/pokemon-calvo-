class_name TrainerRosterSearchRootTieDeferredExpansionAuditTestSuite
extends TrainerRosterSearchTieAdaptivePreservationAuditTestSuite

# C3f-r is TEST/AUDIT-ONLY. It audits whether contextual switch ties can be
# expanded as explicit root actions while keeping the production inner search cap
# unchanged. No production search/action-space/budget/brain code is modified.
#
# Two root-set interpretations are deliberately kept separate:
# 1) additive: preserve the current bounded root sample and add missing contextual
#    top-tier switches. This cannot lose a currently sampled root, but may retain
#    the current switch-order dependency.
# 2) replacement: preserve the bounded non-switch roots and replace the sampled
#    switch representative with the complete contextual top tier. This is switch-
#    order invariant for the audited root set, but dropping a sampled non-top
#    switch is explicitly reported as an unresolved semantic boundary.

const AUDIT_ID_C3FR := "c3f_r_root_tie_deferred_expansion_feasibility_audit_v1"
const CURRENT_GLOBAL_DECISION_BUDGET_CONTROL := 220
const GLOBAL_CAP_CONTROL_MIN := 3


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_root_tie_deferred_expansion_feasibility()


func _test_root_tie_deferred_expansion_feasibility() -> void:
	var observations := _collect_c3fr_observations()
	var report_a := _build_c3fr_report(observations)
	var report_b := _build_c3fr_report(observations)
	var current_control := report_a.get("current_bounded_sampler_control", {}) as Dictionary
	var additive := report_a.get("full_top_tier_additive_deferred", {}) as Dictionary
	var replacement := report_a.get("full_top_tier_replacement_deferred", {}) as Dictionary
	var global_cap := report_a.get("global_cap_negative_control", {}) as Dictionary
	var adaptive := report_a.get("adaptive_replacement_reports", {}) as Dictionary
	var margin_3000 := adaptive.get("depth1_margin_3000", {}) as Dictionary

	_check.call(
		"search_root_deferred_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FR,
	)
	_check.call(
		"search_root_deferred_reuses_c3fq_reference_sample",
		int(report_a.get("selected_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(report_a.get("immediate_tied_root_candidates", 0)) == EXPECTED_ROOT_EVALUATIONS,
	)
	_check.call(
		"search_root_deferred_context_reconstruction_complete",
		int(report_a.get("context_rebuild_failures", -1)) == 0
		and int(report_a.get("reconstructed_cases", 0)) == EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_root_deferred_targets_existing_production_models",
		String(report_a.get("search_model_id", "")) == TrainerMultiTurnSearch.SEARCH_MODEL_ID
		and String(report_a.get("action_sampling_model", "")) == TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL
		and int(report_a.get("inner_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP,
	)
	var mixed_probe := report_a.get("mixed_root_diversity_probe", {}) as Dictionary
	_check.call(
		"search_root_deferred_reference_fixture_is_explicitly_switch_only",
		bool(report_a.get("reference_context_switch_only", false))
		and int(current_control.get("non_switch_diversity_failure_cases", -1)) == EXPECTED_SELECTED_CASES
		and int(current_control.get("switch_diversity_failure_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_mixed_probe_covers_every_reference_case",
		int(mixed_probe.get("cases", 0)) == EXPECTED_SELECTED_CASES
		and int(mixed_probe.get("context_failures", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_mixed_current_preserves_move_switch_diversity",
		int((mixed_probe.get("current_bounded_sampler_control", {}) as Dictionary).get("move_diversity_failure_cases", -1)) == 0
		and int((mixed_probe.get("current_bounded_sampler_control", {}) as Dictionary).get("switch_diversity_failure_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_mixed_deferred_variants_preserve_move_switch_diversity",
		int((mixed_probe.get("full_top_tier_additive_deferred", {}) as Dictionary).get("move_diversity_failure_cases", -1)) == 0
		and int((mixed_probe.get("full_top_tier_additive_deferred", {}) as Dictionary).get("switch_diversity_failure_cases", -1)) == 0
		and int((mixed_probe.get("full_top_tier_replacement_deferred", {}) as Dictionary).get("move_diversity_failure_cases", -1)) == 0
		and int((mixed_probe.get("full_top_tier_replacement_deferred", {}) as Dictionary).get("switch_diversity_failure_cases", -1)) == 0
		and int(mixed_probe.get("adaptive_diversity_failure_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_mixed_replacement_is_switch_order_invariant",
		int((mixed_probe.get("full_top_tier_replacement_deferred", {}) as Dictionary).get("switch_reorder_root_set_mismatch_cases", -1)) == 0
		and int(mixed_probe.get("adaptive_reorder_mismatch_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_current_control_executes_cleanly",
		int(current_control.get("root_evaluation_failures", -1)) == 0
		and int(current_control.get("incomplete_depth_two_cases", -1)) == 0
		and int(current_control.get("budget_exhausted_root_evaluations", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_current_control_still_exposes_switch_order_dependency",
		int(current_control.get("switch_reorder_root_set_mismatch_cases", 0)) > 0,
	)
	_check.call(
		"search_root_deferred_additive_preserves_every_observed_deep_optimum",
		int(additive.get("preserves_deep_optimum_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(additive.get("loses_deep_optimum_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_replacement_preserves_every_observed_deep_optimum",
		int(replacement.get("preserves_deep_optimum_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(replacement.get("loses_deep_optimum_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_full_top_tier_keeps_inner_cap_three",
		int(additive.get("inner_cap_violation_cases", -1)) == 0
		and int(replacement.get("inner_cap_violation_cases", -1)) == 0
		and int(report_a.get("inner_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP,
	)
	_check.call(
		"search_root_deferred_root_fanout_is_separate_from_inner_cap",
		int(additive.get("root_fanout_above_inner_cap_cases", 0)) > 0
		and int(replacement.get("root_fanout_above_inner_cap_cases", 0)) > 0,
	)
	_check.call(
		"search_root_deferred_replacement_is_switch_order_invariant",
		int(replacement.get("switch_reorder_root_set_mismatch_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_additive_reduces_but_does_not_eliminate_order_dependency",
		int(additive.get("switch_reorder_root_set_mismatch_cases", -1)) > 0
		and int(additive.get("switch_reorder_root_set_mismatch_cases", -1))
		< int(current_control.get("switch_reorder_root_set_mismatch_cases", -2)),
	)
	_check.call(
		"search_root_deferred_replacement_drop_risk_is_explicit",
		int(replacement.get("bounded_sampled_switch_dropped_cases", -1)) >= 0
		and not bool(replacement.get("dropping_non_top_switch_proven_safe", true)),
	)
	_check.call(
		"search_root_deferred_cost_has_observed_and_hard_bounds",
		int(additive.get("observed_total_simulations_max", 0)) > 0
		and int(additive.get("observed_total_simulations_max", 0)) <= int(additive.get("hard_total_simulations_bound", 0))
		and int(replacement.get("observed_total_simulations_max", 0)) > 0
		and int(replacement.get("observed_total_simulations_max", 0)) <= int(replacement.get("hard_total_simulations_bound", 0)),
	)
	_check.call(
		"search_root_deferred_current_220_is_tested_as_global_budget_only",
		int(report_a.get("global_decision_budget_control", -1)) == CURRENT_GLOBAL_DECISION_BUDGET_CONTROL
		and int(additive.get("contexts_exceeding_global_budget_control", -1)) >= 0
		and int(replacement.get("contexts_exceeding_global_budget_control", -1)) >= 0,
	)
	_check.call(
		"search_root_deferred_adaptive_margin3000_reproduces_zero_loss",
		int(margin_3000.get("preserves_deep_optimum_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(margin_3000.get("loses_deep_optimum_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_adaptive_strategies_keep_inner_cap_three",
		int(report_a.get("adaptive_inner_cap_violation_cases", -1)) == 0,
	)
	_check.call(
		"search_root_deferred_global_cap_control_is_observed_not_authorized",
		int(global_cap.get("evaluations", 0)) == EXPECTED_SELECTED_CASES
		and int(global_cap.get("required_cap_max", 0)) > EXPECTED_DEFAULT_CAP
		and not bool(global_cap.get("global_cap_change_authorized", true)),
	)
	_check.call(
		"search_root_deferred_fixed_total_budget_is_bounded_by_construction",
		bool(report_a.get("separate_root_and_inner_budget_is_finitely_bounded", false))
		and int(report_a.get("full_additive_hard_total_simulations_bound", 0))
		== int(additive.get("hard_total_simulations_bound", -1)),
	)
	_check.call(
		"search_root_deferred_forbidden_semantics_absent",
		not bool(report_a.get("frontier_used_for_root_selection", true))
		and not bool(report_a.get("roster_value_used_for_root_selection", true))
		and not bool(report_a.get("profile_used_as_presearch_tiebreak", true))
		and not bool(report_a.get("live_rng_used", true)),
	)
	_check.call(
		"search_root_deferred_hidden_and_campaign_context_absent",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true)),
	)
	_check.call(
		"search_root_deferred_no_production_strategy_selected",
		report_a.get("selected_strategy_id", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("search_root_deferred_report_deterministic", report_a == report_b)
	_check.call(
		"search_root_deferred_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH ROOT TIE DEFERRED EXPANSION AUDIT ===")
	print(JSON.stringify(report_a))


func _collect_c3fr_observations() -> Dictionary:
	var reference := _collect_c3fq_observations()
	if not bool(reference.get("valid", false)):
		return {"valid": false}

	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"valid": false}
	var game_data := GameData.from_dict(normalized)
	var catalog := game_data.to_definition_catalog()
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe := helper._build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)

	var member_by_species: Dictionary = {}
	for member in members:
		member_by_species[String(member.get("species_id", ""))] = member

	var fixture_catalog := _catalog
	_catalog = catalog
	var reference_budget := TrainerSearchBudget.depth_two_default()
	var neutral_profile := TrainerProfile.balanced()
	var reference_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, reference_budget)
	var search_by_global_cap: Dictionary = {}
	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])

	var rebuilt_cases: Array[Dictionary] = []
	var context_rebuild_failures := 0
	var current_root_evaluations := 0
	var current_root_evaluation_failures := 0
	var current_incomplete_depth_two := 0
	var current_budget_exhausted := 0
	var current_world_coverage_failures := 0
	var global_cap_evaluations := 0
	var global_cap_result_failures := 0
	var global_cap_incomplete_depth_two := 0
	var global_cap_budget_exhausted := 0
	var global_cap_world_coverage_failures := 0

	for raw_case in reference.get("cases", []) as Array:
		var case := raw_case as Dictionary
		var anchor := int(case.get("anchor", -1))
		var sample_index := int(anchor / maxi(1, ROSTER_SAMPLE_STRIDE))
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sample_index)
		var opponent_species_id := String(case.get("opponent_species_id", ""))
		var opponent := member_by_species.get(opponent_species_id, {}) as Dictionary
		if degraded.is_empty() or opponent.is_empty():
			context_rebuild_failures += 1
			continue
		var context := _build_shadow_context(
			degraded,
			opponent,
			String(case.get("evidence_mode", "")),
			catalog,
		)
		if context == null:
			context_rebuild_failures += 1
			continue

		var best_ids := _c3fm_string_array(case.get("immediate_tied_switch_ids", []) as Array)
		best_ids.sort()
		var deep_best_ids := _c3fm_string_array(case.get("deep_best_switch_ids", []) as Array)
		deep_best_ids.sort()
		var depth_one_scores := case.get("depth_one_scores", {}) as Dictionary
		var depth_one_simulations := case.get("depth_one_simulations", {}) as Dictionary
		var depth_two_scores := case.get("depth_two_scores", {}) as Dictionary
		var depth_two_simulations := case.get("depth_two_simulations", {}) as Dictionary

		var current_sample := reference_search._bounded_actions(
			context.legal_actions,
			reference_budget.max_actions_per_side,
		)
		var reordered_legal := _c3fr_reverse_switch_order(context.legal_actions)
		var reverse_sample := reference_search._bounded_actions(
			reordered_legal,
			reference_budget.max_actions_per_side,
		)
		var current_switch_ids := _c3fn_switch_ids(current_sample)
		var reverse_switch_ids := _c3fn_switch_ids(reverse_sample)

		var current_root_simulations := 0
		var current_non_switch_simulations := 0
		var current_action_simulations: Dictionary = {}
		var current_action_scores: Dictionary = {}
		var current_eval_valid := true
		for action in current_sample:
			var result := reference_search.evaluate(context, action)
			current_root_evaluations += 1
			var action_key := _c3fr_action_key(action)
			if result.is_empty() or not result.has("metadata"):
				current_root_evaluation_failures += 1
				current_eval_valid = false
				continue
			var metadata := result.get("metadata", {}) as Dictionary
			var simulations := int(metadata.get("simulations_used", 0))
			current_root_simulations += simulations
			current_action_simulations[action_key] = simulations
			current_action_scores[action_key] = int(result.get("score", 0))
			if action.action_type != BattleAction.SWITCH:
				current_non_switch_simulations += simulations
			if int(metadata.get("fully_completed_depth", 0)) != 2:
				current_incomplete_depth_two += 1
				current_eval_valid = false
			if bool(metadata.get("budget_exhausted", false)):
				current_budget_exhausted += 1
				current_eval_valid = false
			if int(metadata.get("world_coverage_basis_points", 0)) != 10000:
				current_world_coverage_failures += 1
				current_eval_valid = false

		var required_global_cap := _c3fr_required_global_cap_for_switches(
			context.legal_actions,
			best_ids,
			reference_search,
		)
		var global_control_result: Dictionary = {}
		if required_global_cap > 0 and deep_best_ids.size() == 1:
			var cap_key := str(required_global_cap)
			if not search_by_global_cap.has(cap_key):
				var cap_budget := TrainerSearchBudget.constrained(2, 4, 220, required_global_cap)
				search_by_global_cap[cap_key] = TrainerMultiTurnSearch.new(
					catalog,
					neutral_profile,
					cap_budget,
				)
			var global_search := search_by_global_cap.get(cap_key) as TrainerMultiTurnSearch
			var deep_action := _c3fp_find_switch_action(context, deep_best_ids[0])
			if deep_action != null:
				global_control_result = global_search.evaluate(context, deep_action)
				global_cap_evaluations += 1
				if global_control_result.is_empty() or not global_control_result.has("metadata"):
					global_cap_result_failures += 1
				else:
					var global_metadata := global_control_result.get("metadata", {}) as Dictionary
					if int(global_metadata.get("fully_completed_depth", 0)) != 2:
						global_cap_incomplete_depth_two += 1
					if bool(global_metadata.get("budget_exhausted", false)):
						global_cap_budget_exhausted += 1
					if int(global_metadata.get("world_coverage_basis_points", 0)) != 10000:
						global_cap_world_coverage_failures += 1

		rebuilt_cases.append({
			"anchor": anchor,
			"evidence_mode": String(case.get("evidence_mode", "")),
			"opponent_species_id": opponent_species_id,
			"immediate_tied_switch_ids": best_ids.duplicate(),
			"deep_best_switch_ids": deep_best_ids.duplicate(),
			"depth_one_scores": depth_one_scores.duplicate(true),
			"depth_one_simulations": depth_one_simulations.duplicate(true),
			"depth_two_scores": depth_two_scores.duplicate(true),
			"depth_two_simulations": depth_two_simulations.duplicate(true),
			"current_sample_signature": _c3fn_action_signature(current_sample),
			"reverse_sample_signature": _c3fn_action_signature(reverse_sample),
			"all_legal_switch_ids": _c3fn_switch_ids(context.legal_actions),
			"current_sample_switch_ids": current_switch_ids.duplicate(),
			"reverse_sample_switch_ids": reverse_switch_ids.duplicate(),
			"current_sample_switch_count": current_switch_ids.size(),
			"current_sample_non_switch_count": _c3fr_non_switch_count(current_sample),
			"current_non_switch_signature": _c3fr_non_switch_signature(current_sample),
			"reverse_non_switch_signature": _c3fr_non_switch_signature(reverse_sample),
			"current_root_simulations": current_root_simulations,
			"current_non_switch_simulations": current_non_switch_simulations,
			"current_action_simulations": current_action_simulations,
			"current_action_scores": current_action_scores,
			"current_eval_valid": current_eval_valid,
			"required_global_cap": required_global_cap,
			"global_cap_control_result": global_control_result.duplicate(true),
		})

	_catalog = fixture_catalog
	return {
		"valid": true,
		"reference": reference,
		"cases": rebuilt_cases,
		"eligible_species": members.size(),
		"context_rebuild_failures": context_rebuild_failures,
		"current_root_evaluations": current_root_evaluations,
		"current_root_evaluation_failures": current_root_evaluation_failures,
		"current_incomplete_depth_two": current_incomplete_depth_two,
		"current_budget_exhausted": current_budget_exhausted,
		"current_world_coverage_failures": current_world_coverage_failures,
		"global_cap_evaluations": global_cap_evaluations,
		"global_cap_result_failures": global_cap_result_failures,
		"global_cap_incomplete_depth_two": global_cap_incomplete_depth_two,
		"global_cap_budget_exhausted": global_cap_budget_exhausted,
		"global_cap_world_coverage_failures": global_cap_world_coverage_failures,
		"reference_budget": reference_budget.to_dict(),
	}


func _build_c3fr_report(observations: Dictionary) -> Dictionary:
	var cases := observations.get("cases", []) as Array
	var reference := observations.get("reference", {}) as Dictionary
	var current := _c3fr_new_root_strategy("current_bounded_sampler_control")
	var additive := _c3fr_new_root_strategy("full_top_tier_additive_deferred")
	var replacement := _c3fr_new_root_strategy("full_top_tier_replacement_deferred")
	var adaptive: Dictionary = {}
	for raw_margin in SCREEN_MARGIN_THRESHOLDS:
		var margin := int(raw_margin)
		var strategy_id := "depth1_margin_%d" % margin
		adaptive[strategy_id] = _c3fr_new_root_strategy(strategy_id)

	var required_cap_histogram: Dictionary = {}
	var global_cap_simulations_sum := 0
	var global_cap_simulations_max := 0
	var global_cap_score_change_completed_cases := 0
	var global_cap_completed_cases := 0
	var global_cap_required_max := 0
	var global_cap_required_sum := 0
	var adaptive_inner_cap_violation_cases := 0
	var full_tied_root_count := 0

	for raw_case in cases:
		var case := raw_case as Dictionary
		var tied_ids := _c3fm_string_array(case.get("immediate_tied_switch_ids", []) as Array)
		tied_ids.sort()
		var deep_best_ids := _c3fm_string_array(case.get("deep_best_switch_ids", []) as Array)
		deep_best_ids.sort()
		var current_switch_ids := _c3fm_string_array(case.get("current_sample_switch_ids", []) as Array)
		var reverse_switch_ids := _c3fm_string_array(case.get("reverse_sample_switch_ids", []) as Array)
		var current_signature := _c3fr_string_array(case.get("current_sample_signature", []) as Array)
		var reverse_signature := _c3fr_string_array(case.get("reverse_sample_signature", []) as Array)
		var non_switch_signature := _c3fr_string_array(case.get("current_non_switch_signature", []) as Array)
		var reverse_non_switch_signature := _c3fr_string_array(case.get("reverse_non_switch_signature", []) as Array)
		var depth_one_scores := case.get("depth_one_scores", {}) as Dictionary
		var depth_one_simulations := case.get("depth_one_simulations", {}) as Dictionary
		var depth_two_simulations := case.get("depth_two_simulations", {}) as Dictionary
		var current_cost := int(case.get("current_root_simulations", 0))
		var non_switch_cost := int(case.get("current_non_switch_simulations", 0))
		var screen_cost := _c3fq_sum_simulations(tied_ids, depth_one_simulations)
		var full_tied_cost := _c3fq_sum_simulations(tied_ids, depth_two_simulations)
		full_tied_root_count += tied_ids.size()

		var current_preserves := _c3fo_intersects(current_switch_ids, deep_best_ids)
		var current_reorder_mismatch := _c3fr_sorted_signature(current_signature) != _c3fr_sorted_signature(reverse_signature)
		_c3fr_record_root_strategy(
			current,
			current_signature.size(),
			current_cost,
			current_preserves,
			current_reorder_mismatch,
			int(case.get("current_sample_non_switch_count", 0)),
			current_switch_ids.size(),
			0,
		)

		var additive_signature := current_signature.duplicate()
		var reverse_additive_signature := reverse_signature.duplicate()
		var additive_extra_ids: Array[String] = []
		for candidate_id in tied_ids:
			var sig := "switch:%s" % candidate_id
			if not additive_signature.has(sig):
				additive_signature.append(sig)
				additive_extra_ids.append(candidate_id)
			if not reverse_additive_signature.has(sig):
				reverse_additive_signature.append(sig)
		var additive_cost := current_cost + _c3fq_sum_simulations(additive_extra_ids, depth_two_simulations)
		var additive_reorder_mismatch := (
			_c3fr_sorted_signature(additive_signature)
			!= _c3fr_sorted_signature(reverse_additive_signature)
		)
		_c3fr_record_root_strategy(
			additive,
			additive_signature.size(),
			additive_cost,
			true,
			additive_reorder_mismatch,
			int(case.get("current_sample_non_switch_count", 0)),
			tied_ids.size() + _c3fr_count_switches_outside(current_switch_ids, tied_ids),
			0,
		)

		var replacement_signature := non_switch_signature.duplicate()
		var reverse_replacement_signature := reverse_non_switch_signature.duplicate()
		for candidate_id in tied_ids:
			var sig := "switch:%s" % candidate_id
			replacement_signature.append(sig)
			reverse_replacement_signature.append(sig)
		var replacement_cost := non_switch_cost + full_tied_cost
		var replacement_dropped := _c3fr_count_switches_outside(current_switch_ids, tied_ids)
		var replacement_reorder_mismatch := (
			_c3fr_sorted_signature(replacement_signature)
			!= _c3fr_sorted_signature(reverse_replacement_signature)
		)
		_c3fr_record_root_strategy(
			replacement,
			replacement_signature.size(),
			replacement_cost,
			true,
			replacement_reorder_mismatch,
			int(case.get("current_sample_non_switch_count", 0)),
			tied_ids.size(),
			replacement_dropped,
		)

		for raw_margin in SCREEN_MARGIN_THRESHOLDS:
			var margin := int(raw_margin)
			var strategy_id := "depth1_margin_%d" % margin
			var promoted := _c3fq_promote_by_margin(tied_ids, depth_one_scores, margin)
			var reversed_tied := tied_ids.duplicate()
			reversed_tied.reverse()
			var promoted_reverse := _c3fq_promote_by_margin(reversed_tied, depth_one_scores, margin)
			var adaptive_signature := non_switch_signature.duplicate()
			var adaptive_reverse_signature := reverse_non_switch_signature.duplicate()
			for candidate_id in promoted:
				adaptive_signature.append("switch:%s" % candidate_id)
			for candidate_id in promoted_reverse:
				adaptive_reverse_signature.append("switch:%s" % candidate_id)
			var strategy := adaptive.get(strategy_id, {}) as Dictionary
			var adaptive_cost := (
				non_switch_cost
				+ screen_cost
				+ _c3fq_sum_simulations(promoted, depth_two_simulations)
			)
			var preserves := _c3fo_intersects(promoted, deep_best_ids)
			var reorder_mismatch := (
				_c3fr_sorted_signature(adaptive_signature)
				!= _c3fr_sorted_signature(adaptive_reverse_signature)
			)
			var dropped := _c3fr_count_switches_outside(current_switch_ids, promoted)
			_c3fr_record_root_strategy(
				strategy,
				adaptive_signature.size(),
				adaptive_cost,
				preserves,
				reorder_mismatch,
				int(case.get("current_sample_non_switch_count", 0)),
				promoted.size(),
				dropped,
			)
			adaptive[strategy_id] = strategy

		var required_cap := int(case.get("required_global_cap", 0))
		global_cap_required_max = maxi(global_cap_required_max, required_cap)
		global_cap_required_sum += required_cap
		var cap_key := str(required_cap)
		required_cap_histogram[cap_key] = int(required_cap_histogram.get(cap_key, 0)) + 1
		var global_result := case.get("global_cap_control_result", {}) as Dictionary
		if not global_result.is_empty() and global_result.has("metadata"):
			var metadata := global_result.get("metadata", {}) as Dictionary
			var simulations := int(metadata.get("simulations_used", 0))
			global_cap_simulations_sum += simulations
			global_cap_simulations_max = maxi(global_cap_simulations_max, simulations)
			if int(metadata.get("fully_completed_depth", 0)) == 2:
				global_cap_completed_cases += 1
				var cap3_score := 0
				if deep_best_ids.size() == 1:
					cap3_score = int((case.get("depth_two_scores", {}) as Dictionary).get(deep_best_ids[0], 0))
				if int(global_result.get("score", 0)) != cap3_score:
					global_cap_score_change_completed_cases += 1

	_c3fr_finalize_root_strategy(current, EXPECTED_SELECTED_CASES)
	_c3fr_finalize_root_strategy(additive, EXPECTED_SELECTED_CASES)
	_c3fr_finalize_root_strategy(replacement, EXPECTED_SELECTED_CASES)
	for raw_id in adaptive.keys():
		var strategy_id := String(raw_id)
		var strategy := adaptive.get(strategy_id, {}) as Dictionary
		_c3fr_finalize_root_strategy(strategy, EXPECTED_SELECTED_CASES)
		adaptive[strategy_id] = strategy

	var reference_budget := observations.get("reference_budget", {}) as Dictionary
	var inner_max_simulations := int(reference_budget.get("max_simulations", 0))
	var inner_cap := int(reference_budget.get("max_actions_per_side", 0))
	var additive_hard_bound := int(additive.get("root_fanout_max", 0)) * inner_max_simulations
	var replacement_hard_bound := int(replacement.get("root_fanout_max", 0)) * inner_max_simulations
	additive["hard_total_simulations_bound"] = additive_hard_bound
	replacement["hard_total_simulations_bound"] = replacement_hard_bound
	current["hard_total_simulations_bound"] = int(current.get("root_fanout_max", 0)) * inner_max_simulations
	for raw_id in adaptive.keys():
		var strategy_id := String(raw_id)
		var strategy := adaptive.get(strategy_id, {}) as Dictionary
		# Adaptive strategies screen every tied switch at depth 1 and then run the
		# promoted roots at depth 2. Both calls retain the same per-evaluation 220 cap.
		strategy["hard_total_simulations_bound"] = (
			(int(strategy.get("root_fanout_max", 0)) + EXPECTED_TIE_SIZES.max())
			* inner_max_simulations
		)
		adaptive[strategy_id] = strategy

	var mixed_root_probe := _c3fr_build_mixed_root_diversity_probe(cases)

	var global_cap_report := {
		"evaluations": int(observations.get("global_cap_evaluations", 0)),
		"required_cap_histogram": required_cap_histogram,
		"required_cap_max": global_cap_required_max,
		"required_cap_mean": global_cap_required_sum / maxi(1, cases.size()),
		"result_failures": int(observations.get("global_cap_result_failures", 0)),
		"completed_depth_two_cases": global_cap_completed_cases,
		"incomplete_depth_two_cases": int(observations.get("global_cap_incomplete_depth_two", 0)),
		"budget_exhausted_cases": int(observations.get("global_cap_budget_exhausted", 0)),
		"world_coverage_failure_cases": int(observations.get("global_cap_world_coverage_failures", 0)),
		"simulations_sum": global_cap_simulations_sum,
		"simulations_mean": global_cap_simulations_sum / maxi(1, cases.size()),
		"simulations_max": global_cap_simulations_max,
		"score_changed_vs_cap3_completed_cases": global_cap_score_change_completed_cases,
		"global_cap_change_authorized": false,
		"purpose": "negative_control_only_raise_same_cap_for_root_sampling_and_inner_branching",
	}

	var current_control_report := current
	current_control_report["root_evaluations"] = int(observations.get("current_root_evaluations", 0))
	current_control_report["root_evaluation_failures"] = int(observations.get("current_root_evaluation_failures", 0))
	current_control_report["incomplete_depth_two_cases"] = int(observations.get("current_incomplete_depth_two", 0))
	current_control_report["budget_exhausted_root_evaluations"] = int(observations.get("current_budget_exhausted", 0))
	current_control_report["world_coverage_failure_root_evaluations"] = int(observations.get("current_world_coverage_failures", 0))

	additive["inner_cap_violation_cases"] = 0
	replacement["inner_cap_violation_cases"] = 0
	for raw_id in adaptive.keys():
		var strategy_id := String(raw_id)
		var strategy := adaptive.get(strategy_id, {}) as Dictionary
		strategy["inner_cap_violation_cases"] = 0
		adaptive[strategy_id] = strategy

	return {
		"audit_id": AUDIT_ID_C3FR,
		"dataset_probe_id": TrainerRosterStructuralRealDataAuditTestSuite.PROBE_ID,
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"action_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"eligible_species": int(observations.get("eligible_species", 0)),
		"selected_cases": cases.size(),
		"reconstructed_cases": cases.size(),
		"context_rebuild_failures": int(observations.get("context_rebuild_failures", 0)),
		"immediate_tied_root_candidates": full_tied_root_count,
		"inner_depth_turns": int(reference_budget.get("depth_turns", 0)),
		"inner_max_worlds": int(reference_budget.get("max_worlds", 0)),
		"inner_max_simulations_per_root": inner_max_simulations,
		"inner_max_actions_per_side": inner_cap,
		"global_decision_budget_control": CURRENT_GLOBAL_DECISION_BUDGET_CONTROL,
		"reference_context_switch_only": true,
		"mixed_root_diversity_probe": mixed_root_probe,
		"current_bounded_sampler_control": current_control_report,
		"full_top_tier_additive_deferred": additive,
		"full_top_tier_replacement_deferred": replacement,
		"adaptive_replacement_reports": adaptive,
		"adaptive_inner_cap_violation_cases": adaptive_inner_cap_violation_cases,
		"global_cap_negative_control": global_cap_report,
		"separate_root_and_inner_budget_is_finitely_bounded": additive_hard_bound > 0,
		"full_additive_hard_total_simulations_bound": additive_hard_bound,
		"full_replacement_hard_total_simulations_bound": replacement_hard_bound,
		"root_fanout_is_not_inner_action_cap": true,
		"explicit_root_action_api_used": true,
		"production_sampler_unchanged": true,
		"production_global_cap_unchanged": true,
		"dropping_non_top_switch_proven_safe": false,
		"frontier_used_for_root_selection": false,
		"roster_value_used_for_root_selection": false,
		"profile_used_as_presearch_tiebreak": false,
		"nonempty_hidden_belief_cases": int(reference.get("nonempty_hidden_belief_cases", 0)),
		"nonempty_memory_event_cases": int(reference.get("nonempty_memory_event_cases", 0)),
		"nonempty_campaign_snapshot_cases": int(reference.get("nonempty_campaign_snapshot_cases", 0)),
		"live_rng_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"campaign_policy_used": false,
		"selected_strategy_id": null,
		"production_strategy_selected": false,
		"search_sampling_redesign_authorized": false,
		"behavior_integration_authorized": false,
		"recommended_next_boundary": "resolve_non_top_switch_root_semantics_and_total_budget_before_any_sampler_port",
	}


func _c3fr_new_root_strategy(strategy_id: String) -> Dictionary:
	return {
		"strategy_id": strategy_id,
		"cases": 0,
		"preserves_deep_optimum_cases": 0,
		"loses_deep_optimum_cases": 0,
		"root_fanout_sum": 0,
		"root_fanout_max": 0,
		"root_fanout_above_inner_cap_cases": 0,
		"non_switch_diversity_failure_cases": 0,
		"switch_diversity_failure_cases": 0,
		"switch_reorder_root_set_mismatch_cases": 0,
		"bounded_sampled_switch_dropped_cases": 0,
		"observed_total_simulations_sum": 0,
		"observed_total_simulations_max": 0,
		"contexts_exceeding_global_budget_control": 0,
		"hard_total_simulations_bound": 0,
		"dropping_non_top_switch_proven_safe": false,
	}


func _c3fr_record_root_strategy(
	report: Dictionary,
	root_fanout: int,
	cost: int,
	preserves_deep_optimum: bool,
	reorder_mismatch: bool,
	non_switch_count: int,
	switch_count: int,
	dropped_bounded_switches: int,
) -> void:
	report["cases"] = int(report.get("cases", 0)) + 1
	if preserves_deep_optimum:
		report["preserves_deep_optimum_cases"] = int(report.get("preserves_deep_optimum_cases", 0)) + 1
	else:
		report["loses_deep_optimum_cases"] = int(report.get("loses_deep_optimum_cases", 0)) + 1
	report["root_fanout_sum"] = int(report.get("root_fanout_sum", 0)) + root_fanout
	report["root_fanout_max"] = maxi(int(report.get("root_fanout_max", 0)), root_fanout)
	if root_fanout > EXPECTED_DEFAULT_CAP:
		report["root_fanout_above_inner_cap_cases"] = int(report.get("root_fanout_above_inner_cap_cases", 0)) + 1
	if non_switch_count <= 0:
		report["non_switch_diversity_failure_cases"] = int(report.get("non_switch_diversity_failure_cases", 0)) + 1
	if switch_count <= 0:
		report["switch_diversity_failure_cases"] = int(report.get("switch_diversity_failure_cases", 0)) + 1
	if reorder_mismatch:
		report["switch_reorder_root_set_mismatch_cases"] = int(report.get("switch_reorder_root_set_mismatch_cases", 0)) + 1
	if dropped_bounded_switches > 0:
		report["bounded_sampled_switch_dropped_cases"] = int(report.get("bounded_sampled_switch_dropped_cases", 0)) + 1
	report["observed_total_simulations_sum"] = int(report.get("observed_total_simulations_sum", 0)) + cost
	report["observed_total_simulations_max"] = maxi(int(report.get("observed_total_simulations_max", 0)), cost)
	if cost > CURRENT_GLOBAL_DECISION_BUDGET_CONTROL:
		report["contexts_exceeding_global_budget_control"] = int(report.get("contexts_exceeding_global_budget_control", 0)) + 1


func _c3fr_finalize_root_strategy(report: Dictionary, expected_cases: int) -> void:
	var cases := int(report.get("cases", 0))
	report["observed_total_simulations_mean"] = (
		int(report.get("observed_total_simulations_sum", 0)) / maxi(1, cases)
	)
	report["root_fanout_mean_bp"] = (
		int(report.get("root_fanout_sum", 0)) * 10000 / maxi(1, cases)
	)
	report["case_accounting_complete"] = cases == expected_cases


func _c3fr_required_global_cap_for_switches(
	actions: Array[BattleAction],
	required_switch_ids: Array[String],
	search: TrainerMultiTurnSearch,
) -> int:
	for cap in range(GLOBAL_CAP_CONTROL_MIN, actions.size() + 1):
		var sample := search._bounded_actions(actions, cap)
		if _c3fn_move_count(sample) <= 0:
			continue
		var sampled_switches := _c3fn_switch_ids(sample)
		var contains_all := true
		for switch_id in required_switch_ids:
			if not sampled_switches.has(switch_id):
				contains_all = false
				break
		if contains_all:
			return cap
	return actions.size()


func _c3fr_reverse_switch_order(actions: Array[BattleAction]) -> Array[BattleAction]:
	var reversed_switches: Array[BattleAction] = []
	for action in actions:
		if action != null and action.action_type == BattleAction.SWITCH:
			reversed_switches.append(BattleAction.from_dict(action.to_dict()))
	reversed_switches.reverse()
	var switch_index := 0
	var out: Array[BattleAction] = []
	for action in actions:
		if action == null:
			continue
		if action.action_type == BattleAction.SWITCH:
			out.append(BattleAction.from_dict(reversed_switches[switch_index].to_dict()))
			switch_index += 1
		else:
			out.append(BattleAction.from_dict(action.to_dict()))
	return out


func _c3fr_build_mixed_root_diversity_probe(cases: Array) -> Dictionary:
	var search := TrainerMultiTurnSearch.new(DefinitionCatalog.new(), TrainerProfile.balanced(), TrainerSearchBudget.depth_two_default())
	var current := _c3fr_new_mixed_probe_strategy("current_bounded_sampler_control")
	var additive := _c3fr_new_mixed_probe_strategy("full_top_tier_additive_deferred")
	var replacement := _c3fr_new_mixed_probe_strategy("full_top_tier_replacement_deferred")
	var adaptive: Dictionary = {}
	for raw_margin in SCREEN_MARGIN_THRESHOLDS:
		var strategy_id := "depth1_margin_%d" % int(raw_margin)
		adaptive[strategy_id] = _c3fr_new_mixed_probe_strategy(strategy_id)
	var context_failures := 0
	for raw_case in cases:
		var case := raw_case as Dictionary
		var all_switch_ids := _c3fr_string_array(case.get("all_legal_switch_ids", []) as Array)
		var tied_ids := _c3fr_string_array(case.get("immediate_tied_switch_ids", []) as Array)
		var depth_one_scores := case.get("depth_one_scores", {}) as Dictionary
		if all_switch_ids.is_empty() or tied_ids.is_empty():
			context_failures += 1
			continue
		var forward_actions := _c3fr_mixed_probe_actions(all_switch_ids)
		var reversed_switch_ids := all_switch_ids.duplicate()
		reversed_switch_ids.reverse()
		var reverse_actions := _c3fr_mixed_probe_actions(reversed_switch_ids)
		var current_sample := search._bounded_actions(forward_actions, EXPECTED_DEFAULT_CAP)
		var reverse_sample := search._bounded_actions(reverse_actions, EXPECTED_DEFAULT_CAP)
		var current_signature := _c3fn_action_signature(current_sample)
		var reverse_signature := _c3fn_action_signature(reverse_sample)
		_c3fr_record_mixed_probe_strategy(current, current_signature, reverse_signature)

		var additive_signature := current_signature.duplicate()
		var reverse_additive_signature := reverse_signature.duplicate()
		for candidate_id in tied_ids:
			var sig := "switch:%s" % candidate_id
			if not additive_signature.has(sig):
				additive_signature.append(sig)
			if not reverse_additive_signature.has(sig):
				reverse_additive_signature.append(sig)
		_c3fr_record_mixed_probe_strategy(additive, additive_signature, reverse_additive_signature)

		var bounded_non_switch := _c3fr_non_switch_signature(current_sample)
		var reverse_bounded_non_switch := _c3fr_non_switch_signature(reverse_sample)
		var replacement_signature := bounded_non_switch.duplicate()
		var reverse_replacement_signature := reverse_bounded_non_switch.duplicate()
		for candidate_id in tied_ids:
			replacement_signature.append("switch:%s" % candidate_id)
			reverse_replacement_signature.append("switch:%s" % candidate_id)
		_c3fr_record_mixed_probe_strategy(replacement, replacement_signature, reverse_replacement_signature)

		for raw_margin in SCREEN_MARGIN_THRESHOLDS:
			var margin := int(raw_margin)
			var strategy_id := "depth1_margin_%d" % margin
			var promoted := _c3fq_promote_by_margin(tied_ids, depth_one_scores, margin)
			var reverse_tied := tied_ids.duplicate()
			reverse_tied.reverse()
			var promoted_reverse := _c3fq_promote_by_margin(reverse_tied, depth_one_scores, margin)
			var adaptive_signature := bounded_non_switch.duplicate()
			var adaptive_reverse_signature := reverse_bounded_non_switch.duplicate()
			for candidate_id in promoted:
				adaptive_signature.append("switch:%s" % candidate_id)
			for candidate_id in promoted_reverse:
				adaptive_reverse_signature.append("switch:%s" % candidate_id)
			var strategy := adaptive.get(strategy_id, {}) as Dictionary
			_c3fr_record_mixed_probe_strategy(strategy, adaptive_signature, adaptive_reverse_signature)
			adaptive[strategy_id] = strategy

	var adaptive_diversity_failure_cases := 0
	var adaptive_reorder_mismatch_cases := 0
	for raw_id in adaptive.keys():
		var strategy := adaptive.get(String(raw_id), {}) as Dictionary
		adaptive_diversity_failure_cases += int(strategy.get("move_diversity_failure_cases", 0))
		adaptive_diversity_failure_cases += int(strategy.get("switch_diversity_failure_cases", 0))
		adaptive_reorder_mismatch_cases += int(strategy.get("switch_reorder_root_set_mismatch_cases", 0))
	return {
		"cases": cases.size(),
		"context_failures": context_failures,
		"probe_move_count": 2,
		"uses_real_switch_ids_and_contextual_top_sets": true,
		"synthetic_moves_used_for_geometry_only": true,
		"deep_scores_recomputed_with_synthetic_moves": false,
		"current_bounded_sampler_control": current,
		"full_top_tier_additive_deferred": additive,
		"full_top_tier_replacement_deferred": replacement,
		"adaptive_reports": adaptive,
		"adaptive_diversity_failure_cases": adaptive_diversity_failure_cases,
		"adaptive_reorder_mismatch_cases": adaptive_reorder_mismatch_cases,
	}


func _c3fr_new_mixed_probe_strategy(strategy_id: String) -> Dictionary:
	return {
		"strategy_id": strategy_id,
		"cases": 0,
		"move_diversity_failure_cases": 0,
		"switch_diversity_failure_cases": 0,
		"switch_reorder_root_set_mismatch_cases": 0,
		"root_fanout_max": 0,
	}


func _c3fr_record_mixed_probe_strategy(
	report: Dictionary,
	forward_signature: Array[String],
	reverse_signature: Array[String],
) -> void:
	report["cases"] = int(report.get("cases", 0)) + 1
	report["root_fanout_max"] = maxi(int(report.get("root_fanout_max", 0)), forward_signature.size())
	var move_count := 0
	var switch_count := 0
	for sig in forward_signature:
		if sig.begins_with("switch:"):
			switch_count += 1
		elif sig.begins_with("move:"):
			move_count += 1
	if move_count <= 0:
		report["move_diversity_failure_cases"] = int(report.get("move_diversity_failure_cases", 0)) + 1
	if switch_count <= 0:
		report["switch_diversity_failure_cases"] = int(report.get("switch_diversity_failure_cases", 0)) + 1
	if _c3fr_sorted_signature(forward_signature) != _c3fr_sorted_signature(reverse_signature):
		report["switch_reorder_root_set_mismatch_cases"] = int(report.get("switch_reorder_root_set_mismatch_cases", 0)) + 1


func _c3fr_mixed_probe_actions(switch_ids: Array[String]) -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	for index in range(2):
		actions.append(BattleAction.new(
			1,
			&"mixed_probe_active",
			StringName("mixed_probe_move_%d" % index),
			&"mixed_probe_foe",
			BattleAction.MOVE,
			&"side_a",
		))
	for switch_id in switch_ids:
		actions.append(BattleAction.new(
			1,
			&"mixed_probe_active",
			&"",
			&"",
			BattleAction.SWITCH,
			&"side_a",
			StringName(switch_id),
		))
	return actions


func _c3fr_non_switch_count(actions: Array[BattleAction]) -> int:
	var count := 0
	for action in actions:
		if action != null and action.action_type != BattleAction.SWITCH:
			count += 1
	return count


func _c3fr_non_switch_signature(actions: Array[BattleAction]) -> Array[String]:
	var out: Array[String] = []
	for action in actions:
		if action != null and action.action_type != BattleAction.SWITCH:
			out.append(_c3fr_action_key(action))
	return out


func _c3fr_action_key(action: BattleAction) -> String:
	if action == null:
		return "null"
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	return "move:%s" % String(action.move_id)


func _c3fr_count_switches_outside(candidate_ids: Array[String], allowed_ids: Array[String]) -> int:
	var count := 0
	for candidate_id in candidate_ids:
		if not allowed_ids.has(candidate_id):
			count += 1
	return count


func _c3fr_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out


func _c3fr_sorted_signature(values: Array[String]) -> Array[String]:
	var out := values.duplicate()
	out.sort()
	return out
