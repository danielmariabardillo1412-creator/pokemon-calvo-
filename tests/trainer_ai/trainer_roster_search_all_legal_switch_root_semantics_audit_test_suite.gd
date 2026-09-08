class_name TrainerRosterSearchAllLegalSwitchRootSemanticsAuditTestSuite
extends TrainerRosterSearchRootTieDeferredExpansionAuditTestSuite

# C3f-s is TEST/AUDIT-ONLY. It resolves the semantic boundary left by C3f-r:
# whether a legal switch outside the immediate contextual top tier can become a
# best root after the existing depth-2 search. Every legal switch is evaluated as
# an explicit root while the production inner cap remains unchanged at three.
# Total-budget numbers are accounting controls only; they never decide which root
# is searched and therefore cannot become an accidental pruning policy.

const AUDIT_ID_C3FS := "c3f_s_all_legal_switch_root_semantics_total_budget_audit_v1"
const TOTAL_BUDGET_COST_CONTROLS := [220, 440, 660, 880, 1100]
const MARGIN_3000 := 3000

var _c3fs_cached_c3fr_observations: Dictionary = {}


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_all_legal_switch_root_semantics_and_total_budget()


# Parent C3f-r calls this virtual method during super.run(). Cache that exact
# observation set so C3f-s can reuse the certified 48-case geometry without
# recomputing C3f-q/r a second time in the same process.
func _collect_c3fr_observations() -> Dictionary:
	if not _c3fs_cached_c3fr_observations.is_empty():
		return _c3fs_cached_c3fr_observations
	_c3fs_cached_c3fr_observations = super._collect_c3fr_observations()
	return _c3fs_cached_c3fr_observations


func _test_all_legal_switch_root_semantics_and_total_budget() -> void:
	var observations := _collect_c3fs_observations()
	var report_a := _build_c3fs_report(observations)
	var report_b := _build_c3fs_report(observations)
	var mixed_probe := report_a.get("mixed_root_diversity_probe", {}) as Dictionary

	_check.call(
		"search_all_legal_root_semantics_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FS,
	)
	_check.call(
		"search_all_legal_root_semantics_reuses_c3fr_sample",
		int(report_a.get("selected_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(report_a.get("source_c3fr_selected_cases", 0)) == EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_all_legal_root_semantics_evaluates_every_legal_switch",
		int(report_a.get("all_legal_root_evaluations", 0))
		== int(report_a.get("all_legal_switch_occurrences", -1))
		and int(report_a.get("all_legal_root_evaluations", 0)) > EXPECTED_ROOT_EVALUATIONS,
	)
	_check.call(
		"search_all_legal_root_semantics_keeps_inner_depth2_cap3",
		int(report_a.get("inner_depth_turns", -1)) == 2
		and int(report_a.get("inner_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP
		and int(report_a.get("inner_max_simulations_per_root", -1)) == 220,
	)
	_check.call(
		"search_all_legal_root_semantics_context_rebuild_complete",
		int(report_a.get("context_rebuild_failures", -1)) == 0
		and int(report_a.get("rebuilt_cases", 0)) == EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_all_legal_root_semantics_search_collection_complete",
		int(report_a.get("root_evaluation_failures", -1)) == 0
		and int(report_a.get("incomplete_depth_two_root_evaluations", -1)) == 0
		and int(report_a.get("budget_exhausted_root_evaluations", -1)) == 0
		and int(report_a.get("world_coverage_failure_root_evaluations", -1)) == 0,
	)
	_check.call(
		"search_all_legal_root_semantics_top_tier_score_parity",
		int(report_a.get("top_tier_score_parity_mismatches", -1)) == 0
		and int(report_a.get("top_tier_best_set_parity_mismatches", -1)) == 0,
	)
	_check.call(
		"search_all_legal_root_semantics_semantic_case_accounting",
		int(report_a.get("semantically_complete_cases", 0))
		+ int(report_a.get("semantically_inconclusive_cases", 0))
		== EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_all_legal_root_semantics_replacement_partition_accounted",
		int(report_a.get("top_tier_contains_global_deep_best_cases", 0))
		+ int(report_a.get("replacement_pruning_loses_global_deep_best_cases", 0))
		== int(report_a.get("semantically_complete_cases", -1)),
	)
	_check.call(
		"search_all_legal_root_semantics_non_top_accounting_is_set_based",
		int(report_a.get("non_top_only_deep_best_cases", 0))
		== int(report_a.get("replacement_pruning_loses_global_deep_best_cases", -1))
		and int(report_a.get("non_top_becomes_deep_best_cases", 0))
		>= int(report_a.get("non_top_only_deep_best_cases", -1)),
	)
	_check.call(
		"search_all_legal_root_semantics_deep_ties_are_sets",
		int(report_a.get("global_deep_unique_best_cases", 0))
		+ int(report_a.get("global_deep_multiple_best_cases", 0))
		== int(report_a.get("semantically_complete_cases", -1))
		and not bool(report_a.get("lexical_representative_used_for_semantics", true)),
	)
	_check.call(
		"search_all_legal_root_semantics_pruning_populations_explicit",
		int(report_a.get("replacement_legal_prune_cases", -1)) >= 0
		and int(report_a.get("adaptive_margin3000_legal_prune_cases", -1)) >= 0
		and int(report_a.get("source_c3fr_replacement_bounded_drop_cases", -1)) == 29
		and int(report_a.get("source_c3fr_margin3000_bounded_drop_cases", -1)) == 44,
	)
	_check.call(
		"search_all_legal_root_semantics_margin3000_loss_accounted",
		int(report_a.get("adaptive_margin3000_pruning_loses_global_deep_best_cases", -1)) >= 0
		and int(report_a.get("adaptive_margin3000_pruning_loses_global_deep_best_cases", 0))
		<= int(report_a.get("semantically_complete_cases", -1)),
	)
	_check.call(
		"search_all_legal_root_semantics_total_cost_is_finitely_bounded",
		int(report_a.get("full_legal_hard_total_simulations_bound_per_context", 0)) > 0
		and int(report_a.get("full_legal_simulations_max_per_context", 0))
		<= int(report_a.get("full_legal_hard_total_simulations_bound_per_context", -1)),
	)
	_check.call(
		"search_all_legal_root_semantics_budget_controls_are_cost_only",
		bool(report_a.get("total_budget_controls_are_accounting_only", false))
		and not bool(report_a.get("shared_total_budget_allocation_modeled", true))
		and not bool(report_a.get("cost_control_used_for_semantic_pruning", true)),
	)
	_check.call(
		"search_all_legal_root_semantics_mixed_probe_covers_sample",
		int(mixed_probe.get("cases", 0)) == EXPECTED_SELECTED_CASES
		and int(mixed_probe.get("context_failures", -1)) == 0,
	)
	_check.call(
		"search_all_legal_root_semantics_mixed_probe_preserves_diversity",
		int(mixed_probe.get("move_diversity_failure_cases", -1)) == 0
		and int(mixed_probe.get("switch_diversity_failure_cases", -1)) == 0,
	)
	_check.call(
		"search_all_legal_root_semantics_mixed_probe_order_invariant",
		int(mixed_probe.get("switch_reorder_root_set_mismatch_cases", -1)) == 0
		and bool(mixed_probe.get("synthetic_moves_used_for_geometry_only", false))
		and not bool(mixed_probe.get("deep_scores_recomputed_with_synthetic_moves", true)),
	)
	_check.call(
		"search_all_legal_root_semantics_forbidden_semantics_absent",
		not bool(report_a.get("frontier_used_for_root_selection", true))
		and not bool(report_a.get("roster_value_used_for_root_selection", true))
		and not bool(report_a.get("profile_used_as_presearch_tiebreak", true))
		and not bool(report_a.get("live_rng_used", true)),
	)
	_check.call(
		"search_all_legal_root_semantics_hidden_and_campaign_context_absent",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true)),
	)
	_check.call(
		"search_all_legal_root_semantics_production_unchanged",
		bool(report_a.get("production_sampler_unchanged", false))
		and bool(report_a.get("production_max_actions_unchanged", false))
		and bool(report_a.get("production_max_simulations_unchanged", false))
		and not bool(report_a.get("production_phase_logic_modified", true)),
	)
	_check.call(
		"search_all_legal_root_semantics_no_strategy_selected",
		report_a.get("selected_strategy_id", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("search_all_legal_root_semantics_report_deterministic", report_a == report_b)
	_check.call(
		"search_all_legal_root_semantics_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH ALL LEGAL SWITCH ROOT SEMANTICS AUDIT ===")
	print(JSON.stringify(report_a))


func _collect_c3fs_observations() -> Dictionary:
	var source := _collect_c3fr_observations()
	if not bool(source.get("valid", false)):
		return {"valid": false}
	var source_report := _build_c3fr_report(source)

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
	var neutral_profile := TrainerProfile.balanced()
	var reference_budget := TrainerSearchBudget.depth_two_default()
	var reference_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, reference_budget)
	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])

	var rebuilt_cases: Array[Dictionary] = []
	var context_rebuild_failures := 0
	var all_legal_root_evaluations := 0
	var root_evaluation_failures := 0
	var incomplete_depth_two := 0
	var budget_exhausted := 0
	var world_coverage_failures := 0
	var top_tier_score_parity_mismatches := 0
	var top_tier_best_set_parity_mismatches := 0

	for raw_case in source.get("cases", []) as Array:
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

		var all_legal_ids := _c3fn_switch_ids(context.legal_actions)
		all_legal_ids.sort()
		var top_tier_ids := _c3fm_string_array(case.get("immediate_tied_switch_ids", []) as Array)
		top_tier_ids.sort()
		var depth_one_scores := case.get("depth_one_scores", {}) as Dictionary
		var prior_top_depth_two_scores := case.get("depth_two_scores", {}) as Dictionary
		var prior_top_deep_best_ids := _c3fm_string_array(case.get("deep_best_switch_ids", []) as Array)
		prior_top_deep_best_ids.sort()
		var margin3000_ids := _c3fq_promote_by_margin(top_tier_ids, depth_one_scores, MARGIN_3000)

		var all_depth_two_scores: Dictionary = {}
		var all_depth_two_simulations: Dictionary = {}
		var context_simulations := 0
		var valid_case := true
		for candidate_id in all_legal_ids:
			var action := _c3fp_find_switch_action(context, candidate_id)
			all_legal_root_evaluations += 1
			if action == null:
				root_evaluation_failures += 1
				valid_case = false
				continue
			var result := reference_search.evaluate(context, action)
			if result.is_empty() or not result.has("metadata"):
				root_evaluation_failures += 1
				valid_case = false
				continue
			var metadata := result.get("metadata", {}) as Dictionary
			var simulations := int(metadata.get("simulations_used", 0))
			context_simulations += simulations
			all_depth_two_scores[candidate_id] = int(result.get("score", 0))
			all_depth_two_simulations[candidate_id] = simulations
			if int(metadata.get("fully_completed_depth", 0)) != 2:
				incomplete_depth_two += 1
				valid_case = false
			if bool(metadata.get("budget_exhausted", false)):
				budget_exhausted += 1
				valid_case = false
			if int(metadata.get("world_coverage_basis_points", 0)) != 10000:
				world_coverage_failures += 1
				valid_case = false
			if top_tier_ids.has(candidate_id):
				if int(prior_top_depth_two_scores.get(candidate_id, 2147483647)) != int(result.get("score", 0)):
					top_tier_score_parity_mismatches += 1

		var top_tier_recomputed_best := _c3fs_best_ids_for_subset(all_depth_two_scores, top_tier_ids)
		if valid_case and top_tier_recomputed_best != prior_top_deep_best_ids:
			top_tier_best_set_parity_mismatches += 1

		rebuilt_cases.append({
			"anchor": anchor,
			"evidence_mode": String(case.get("evidence_mode", "")),
			"opponent_species_id": opponent_species_id,
			"all_legal_switch_ids": all_legal_ids.duplicate(),
			"immediate_top_tier_ids": top_tier_ids.duplicate(),
			"margin3000_ids": margin3000_ids.duplicate(),
			"replacement_dropped_legal_ids": _c3fs_difference(all_legal_ids, top_tier_ids),
			"margin3000_dropped_legal_ids": _c3fs_difference(all_legal_ids, margin3000_ids),
			"all_depth_two_scores": all_depth_two_scores.duplicate(true),
			"all_depth_two_simulations": all_depth_two_simulations.duplicate(true),
			"context_simulations": context_simulations,
			"valid_for_semantics": valid_case,
			"prior_top_deep_best_ids": prior_top_deep_best_ids.duplicate(),
		})

	_catalog = fixture_catalog
	return {
		"valid": true,
		"source": source,
		"source_report": source_report,
		"cases": rebuilt_cases,
		"eligible_species": members.size(),
		"context_rebuild_failures": context_rebuild_failures,
		"all_legal_root_evaluations": all_legal_root_evaluations,
		"root_evaluation_failures": root_evaluation_failures,
		"incomplete_depth_two_root_evaluations": incomplete_depth_two,
		"budget_exhausted_root_evaluations": budget_exhausted,
		"world_coverage_failure_root_evaluations": world_coverage_failures,
		"top_tier_score_parity_mismatches": top_tier_score_parity_mismatches,
		"top_tier_best_set_parity_mismatches": top_tier_best_set_parity_mismatches,
		"reference_budget": reference_budget.to_dict(),
	}


func _build_c3fs_report(observations: Dictionary) -> Dictionary:
	var cases := observations.get("cases", []) as Array
	var source := observations.get("source", {}) as Dictionary
	var source_report := observations.get("source_report", {}) as Dictionary
	var source_replacement := source_report.get("full_top_tier_replacement_deferred", {}) as Dictionary
	var source_adaptive := source_report.get("adaptive_replacement_reports", {}) as Dictionary
	var source_margin3000 := source_adaptive.get("depth1_margin_3000", {}) as Dictionary
	var reference := source.get("reference", {}) as Dictionary
	var reference_budget := observations.get("reference_budget", {}) as Dictionary

	var semantically_complete_cases := 0
	var semantically_inconclusive_cases := 0
	var all_legal_switch_occurrences := 0
	var legal_switch_count_histogram: Dictionary = {}
	var contexts_with_non_top_legal_switches := 0
	var replacement_legal_prune_cases := 0
	var adaptive_margin3000_legal_prune_cases := 0
	var non_top_becomes_deep_best_cases := 0
	var non_top_only_deep_best_cases := 0
	var non_top_joint_deep_best_cases := 0
	var top_tier_contains_global_deep_best_cases := 0
	var top_tier_contains_all_global_deep_best_cases := 0
	var replacement_pruning_loses_global_deep_best_cases := 0
	var replacement_pruning_removes_any_global_deep_best_cases := 0
	var adaptive_margin3000_pruning_loses_global_deep_best_cases := 0
	var adaptive_margin3000_pruning_removes_any_global_deep_best_cases := 0
	var global_deep_unique_best_cases := 0
	var global_deep_multiple_best_cases := 0
	var global_deep_best_set_size_histogram: Dictionary = {}
	var full_legal_simulations_sum := 0
	var full_legal_simulations_max_per_context := 0
	var full_legal_root_fanout_max := 0
	var replacement_pruned_root_occurrences := 0
	var margin3000_pruned_root_occurrences := 0
	var semantic_examples: Array[Dictionary] = []
	var cost_control_exceed_cases: Dictionary = {}
	for raw_control in TOTAL_BUDGET_COST_CONTROLS:
		cost_control_exceed_cases[str(int(raw_control))] = 0

	for raw_case in cases:
		var case := raw_case as Dictionary
		var all_ids := _c3fm_string_array(case.get("all_legal_switch_ids", []) as Array)
		var top_ids := _c3fm_string_array(case.get("immediate_top_tier_ids", []) as Array)
		var margin_ids := _c3fm_string_array(case.get("margin3000_ids", []) as Array)
		var replacement_dropped := _c3fm_string_array(case.get("replacement_dropped_legal_ids", []) as Array)
		var margin_dropped := _c3fm_string_array(case.get("margin3000_dropped_legal_ids", []) as Array)
		var scores := case.get("all_depth_two_scores", {}) as Dictionary
		var context_simulations := int(case.get("context_simulations", 0))

		all_legal_switch_occurrences += all_ids.size()
		full_legal_root_fanout_max = maxi(full_legal_root_fanout_max, all_ids.size())
		var legal_count_key := str(all_ids.size())
		legal_switch_count_histogram[legal_count_key] = int(legal_switch_count_histogram.get(legal_count_key, 0)) + 1
		full_legal_simulations_sum += context_simulations
		full_legal_simulations_max_per_context = maxi(full_legal_simulations_max_per_context, context_simulations)
		for raw_control in TOTAL_BUDGET_COST_CONTROLS:
			var control := int(raw_control)
			if context_simulations > control:
				var key := str(control)
				cost_control_exceed_cases[key] = int(cost_control_exceed_cases.get(key, 0)) + 1

		if not replacement_dropped.is_empty():
			contexts_with_non_top_legal_switches += 1
			replacement_legal_prune_cases += 1
			replacement_pruned_root_occurrences += replacement_dropped.size()
		if not margin_dropped.is_empty():
			adaptive_margin3000_legal_prune_cases += 1
			margin3000_pruned_root_occurrences += margin_dropped.size()

		if not bool(case.get("valid_for_semantics", false)) or scores.size() != all_ids.size():
			semantically_inconclusive_cases += 1
			continue
		semantically_complete_cases += 1
		var global_best_ids := _c3fs_best_ids(scores)
		var top_best_overlap := _c3fs_intersection(global_best_ids, top_ids)
		var margin_best_overlap := _c3fs_intersection(global_best_ids, margin_ids)
		var non_top_best_ids := _c3fs_difference(global_best_ids, top_ids)
		var top_contains_all := non_top_best_ids.is_empty()
		var best_size_key := str(global_best_ids.size())
		global_deep_best_set_size_histogram[best_size_key] = int(global_deep_best_set_size_histogram.get(best_size_key, 0)) + 1
		if global_best_ids.size() == 1:
			global_deep_unique_best_cases += 1
		else:
			global_deep_multiple_best_cases += 1

		if not top_best_overlap.is_empty():
			top_tier_contains_global_deep_best_cases += 1
		else:
			replacement_pruning_loses_global_deep_best_cases += 1
		if top_contains_all:
			top_tier_contains_all_global_deep_best_cases += 1
		if not non_top_best_ids.is_empty():
			non_top_becomes_deep_best_cases += 1
			replacement_pruning_removes_any_global_deep_best_cases += 1
			if top_best_overlap.is_empty():
				non_top_only_deep_best_cases += 1
			else:
				non_top_joint_deep_best_cases += 1
		if margin_best_overlap.is_empty():
			adaptive_margin3000_pruning_loses_global_deep_best_cases += 1
		if _c3fs_difference(global_best_ids, margin_ids).size() > 0:
			adaptive_margin3000_pruning_removes_any_global_deep_best_cases += 1

		if semantic_examples.size() < 12 and (
			not non_top_best_ids.is_empty()
			or margin_best_overlap.is_empty()
		):
			semantic_examples.append({
				"anchor": int(case.get("anchor", -1)),
				"evidence_mode": String(case.get("evidence_mode", "")),
				"opponent_species_id": String(case.get("opponent_species_id", "")),
				"all_legal_switch_ids": all_ids.duplicate(),
				"immediate_top_tier_ids": top_ids.duplicate(),
				"margin3000_ids": margin_ids.duplicate(),
				"global_deep_best_ids": global_best_ids.duplicate(),
				"non_top_global_deep_best_ids": non_top_best_ids.duplicate(),
				"depth_two_scores": scores.duplicate(true),
				"context_simulations": context_simulations,
			})

	var inner_max_simulations := int(reference_budget.get("max_simulations", 0))
	var hard_bound_per_context := full_legal_root_fanout_max * inner_max_simulations
	var mixed_probe := _c3fs_build_mixed_root_diversity_probe(cases)
	return {
		"audit_id": AUDIT_ID_C3FS,
		"dataset_probe_id": TrainerRosterStructuralRealDataAuditTestSuite.PROBE_ID,
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"action_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"eligible_species": int(observations.get("eligible_species", 0)),
		"selected_cases": cases.size(),
		"rebuilt_cases": cases.size(),
		"source_c3fr_selected_cases": int(source_report.get("selected_cases", 0)),
		"source_c3fr_replacement_bounded_drop_cases": int(source_replacement.get("bounded_sampled_switch_dropped_cases", 0)),
		"source_c3fr_margin3000_bounded_drop_cases": int(source_margin3000.get("bounded_sampled_switch_dropped_cases", 0)),
		"context_rebuild_failures": int(observations.get("context_rebuild_failures", 0)),
		"all_legal_switch_occurrences": all_legal_switch_occurrences,
		"all_legal_root_evaluations": int(observations.get("all_legal_root_evaluations", 0)),
		"legal_switch_count_histogram": legal_switch_count_histogram,
		"full_legal_root_fanout_max": full_legal_root_fanout_max,
		"root_evaluation_failures": int(observations.get("root_evaluation_failures", 0)),
		"incomplete_depth_two_root_evaluations": int(observations.get("incomplete_depth_two_root_evaluations", 0)),
		"budget_exhausted_root_evaluations": int(observations.get("budget_exhausted_root_evaluations", 0)),
		"world_coverage_failure_root_evaluations": int(observations.get("world_coverage_failure_root_evaluations", 0)),
		"top_tier_score_parity_mismatches": int(observations.get("top_tier_score_parity_mismatches", 0)),
		"top_tier_best_set_parity_mismatches": int(observations.get("top_tier_best_set_parity_mismatches", 0)),
		"semantically_complete_cases": semantically_complete_cases,
		"semantically_inconclusive_cases": semantically_inconclusive_cases,
		"contexts_with_non_top_legal_switches": contexts_with_non_top_legal_switches,
		"replacement_legal_prune_cases": replacement_legal_prune_cases,
		"replacement_pruned_root_occurrences": replacement_pruned_root_occurrences,
		"adaptive_margin3000_legal_prune_cases": adaptive_margin3000_legal_prune_cases,
		"adaptive_margin3000_pruned_root_occurrences": margin3000_pruned_root_occurrences,
		"non_top_becomes_deep_best_cases": non_top_becomes_deep_best_cases,
		"non_top_only_deep_best_cases": non_top_only_deep_best_cases,
		"non_top_joint_deep_best_cases": non_top_joint_deep_best_cases,
		"top_tier_contains_global_deep_best_cases": top_tier_contains_global_deep_best_cases,
		"top_tier_contains_all_global_deep_best_cases": top_tier_contains_all_global_deep_best_cases,
		"replacement_pruning_loses_global_deep_best_cases": replacement_pruning_loses_global_deep_best_cases,
		"replacement_pruning_removes_any_global_deep_best_cases": replacement_pruning_removes_any_global_deep_best_cases,
		"adaptive_margin3000_pruning_loses_global_deep_best_cases": adaptive_margin3000_pruning_loses_global_deep_best_cases,
		"adaptive_margin3000_pruning_removes_any_global_deep_best_cases": adaptive_margin3000_pruning_removes_any_global_deep_best_cases,
		"global_deep_unique_best_cases": global_deep_unique_best_cases,
		"global_deep_multiple_best_cases": global_deep_multiple_best_cases,
		"global_deep_best_set_size_histogram": global_deep_best_set_size_histogram,
		"semantic_examples": semantic_examples,
		"full_legal_simulations_sum": full_legal_simulations_sum,
		"full_legal_simulations_mean_per_context": full_legal_simulations_sum / maxi(1, cases.size()),
		"full_legal_simulations_max_per_context": full_legal_simulations_max_per_context,
		"full_legal_hard_total_simulations_bound_per_context": hard_bound_per_context,
		"total_budget_cost_controls": TOTAL_BUDGET_COST_CONTROLS.duplicate(),
		"cost_control_exceed_cases": cost_control_exceed_cases,
		"total_budget_controls_are_accounting_only": true,
		"shared_total_budget_allocation_modeled": false,
		"cost_control_used_for_semantic_pruning": false,
		"inner_depth_turns": int(reference_budget.get("depth_turns", 0)),
		"inner_max_worlds": int(reference_budget.get("max_worlds", 0)),
		"inner_max_simulations_per_root": inner_max_simulations,
		"inner_max_actions_per_side": int(reference_budget.get("max_actions_per_side", 0)),
		"mixed_root_diversity_probe": mixed_probe,
		"reference_context_switch_only": true,
		"lexical_representative_used_for_semantics": false,
		"deep_best_semantics": "all_equal_max_score_switch_ids",
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
		"production_sampler_unchanged": true,
		"production_max_actions_unchanged": true,
		"production_max_simulations_unchanged": true,
		"production_phase_logic_modified": false,
		"selected_strategy_id": null,
		"production_strategy_selected": false,
		"search_sampling_redesign_authorized": false,
		"behavior_integration_authorized": false,
		"recommended_next_boundary": "interpret_non_top_deep_root_risk_and_total_cost_before_any_sampler_port",
	}


func _c3fs_best_ids(scores: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var best_score := -2147483648
	for raw_id in scores.keys():
		var candidate_id := String(raw_id)
		var score := int(scores.get(raw_id, -2147483648))
		if score > best_score:
			best_score = score
			ids.clear()
			ids.append(candidate_id)
		elif score == best_score:
			ids.append(candidate_id)
	ids.sort()
	return ids


func _c3fs_best_ids_for_subset(scores: Dictionary, candidate_ids: Array[String]) -> Array[String]:
	var subset_scores: Dictionary = {}
	for candidate_id in candidate_ids:
		if scores.has(candidate_id):
			subset_scores[candidate_id] = int(scores.get(candidate_id, 0))
	return _c3fs_best_ids(subset_scores)


func _c3fs_intersection(left: Array[String], right: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for value in left:
		if right.has(value):
			out.append(value)
	out.sort()
	return out


func _c3fs_difference(left: Array[String], right: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for value in left:
		if not right.has(value):
			out.append(value)
	out.sort()
	return out


func _c3fs_build_mixed_root_diversity_probe(cases: Array) -> Dictionary:
	var search := TrainerMultiTurnSearch.new(
		DefinitionCatalog.new(),
		TrainerProfile.balanced(),
		TrainerSearchBudget.depth_two_default(),
	)
	var context_failures := 0
	var move_diversity_failures := 0
	var switch_diversity_failures := 0
	var reorder_mismatches := 0
	var root_fanout_max := 0
	for raw_case in cases:
		var case := raw_case as Dictionary
		var all_ids := _c3fm_string_array(case.get("all_legal_switch_ids", []) as Array)
		if all_ids.is_empty():
			context_failures += 1
			continue
		var reversed_ids := all_ids.duplicate()
		reversed_ids.reverse()
		var forward_actions := _c3fr_mixed_probe_actions(all_ids)
		var reverse_actions := _c3fr_mixed_probe_actions(reversed_ids)
		var forward_bounded := search._bounded_actions(forward_actions, EXPECTED_DEFAULT_CAP)
		var reverse_bounded := search._bounded_actions(reverse_actions, EXPECTED_DEFAULT_CAP)
		var forward_roots := _c3fr_non_switch_signature(forward_bounded)
		var reverse_roots := _c3fr_non_switch_signature(reverse_bounded)
		for candidate_id in all_ids:
			forward_roots.append("switch:%s" % candidate_id)
		for candidate_id in reversed_ids:
			reverse_roots.append("switch:%s" % candidate_id)
		root_fanout_max = maxi(root_fanout_max, forward_roots.size())
		var move_count := 0
		var switch_count := 0
		for signature in forward_roots:
			if signature.begins_with("move:"):
				move_count += 1
			elif signature.begins_with("switch:"):
				switch_count += 1
		if move_count <= 0:
			move_diversity_failures += 1
		if switch_count <= 0:
			switch_diversity_failures += 1
		if _c3fr_sorted_signature(forward_roots) != _c3fr_sorted_signature(reverse_roots):
			reorder_mismatches += 1
	return {
		"cases": cases.size(),
		"context_failures": context_failures,
		"probe_move_count": 2,
		"uses_real_switch_ids": true,
		"synthetic_moves_used_for_geometry_only": true,
		"deep_scores_recomputed_with_synthetic_moves": false,
		"move_diversity_failure_cases": move_diversity_failures,
		"switch_diversity_failure_cases": switch_diversity_failures,
		"switch_reorder_root_set_mismatch_cases": reorder_mismatches,
		"root_fanout_max": root_fanout_max,
	}
