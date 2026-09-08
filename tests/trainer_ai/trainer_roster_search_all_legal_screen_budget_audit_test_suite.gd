class_name TrainerRosterSearchAllLegalScreenBudgetAuditTestSuite
extends TrainerRosterSearchAllLegalSwitchRootSemanticsAuditTestSuite

# C3f-t is TEST/AUDIT-ONLY. C3f-s proved that immediate contextual top-tier
# pruning can delete the unique depth-2 optimum. This tranche therefore screens
# every legal switch symmetrically at depth 1, then compares bounded promotion
# families against the already-certified all-legal depth-2 oracle. No production
# sampler, search budget, brain, switching policy, Pareto rule or campaign policy
# is modified or selected. Shared-budget controls below are accounting models only.

const AUDIT_ID_C3FT := "c3f_t_all_legal_depth1_screen_budget_audit_v1"
const TOP_K_VALUES := [1, 2, 3, 4]
const ALL_LEGAL_MARGIN_THRESHOLDS := [500, 1500, 3000, 6000]
const SHARED_BUDGET_ACCOUNTING_CONTROLS := [220, 440, 660, 880, 1100]

var _c3ft_cached_c3fs_observations: Dictionary = {}


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_all_legal_depth1_screen_and_budget()


# Parent C3f-s calls this virtual collector during super.run(). Cache that exact
# all-legal depth-2 oracle and attach the reconstructed decision contexts for the
# depth-1 screen. The context objects are test-only and never enter serialized
# reports.
func _collect_c3fs_observations() -> Dictionary:
	if not _c3ft_cached_c3fs_observations.is_empty():
		return _c3ft_cached_c3fs_observations

	var observations := super._collect_c3fs_observations()
	if not bool(observations.get("valid", false)):
		_c3ft_cached_c3fs_observations = observations
		return observations

	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		observations["c3ft_context_attach_failures"] = EXPECTED_SELECTED_CASES
		_c3ft_cached_c3fs_observations = observations
		return observations

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
	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])
	var context_attach_failures := 0
	var augmented_cases: Array[Dictionary] = []
	for raw_case in observations.get("cases", []) as Array:
		var case := (raw_case as Dictionary).duplicate(true)
		var anchor := int(case.get("anchor", -1))
		var sample_index := int(anchor / maxi(1, ROSTER_SAMPLE_STRIDE))
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sample_index)
		var opponent := member_by_species.get(String(case.get("opponent_species_id", "")), {}) as Dictionary
		if degraded.is_empty() or opponent.is_empty():
			context_attach_failures += 1
			augmented_cases.append(case)
			continue
		var context := _build_shadow_context(
			degraded,
			opponent,
			String(case.get("evidence_mode", "")),
			catalog,
		)
		if context == null:
			context_attach_failures += 1
		else:
			case["_c3ft_context"] = context
		augmented_cases.append(case)

	_catalog = fixture_catalog
	observations["cases"] = augmented_cases
	observations["c3ft_context_attach_failures"] = context_attach_failures
	observations["_c3ft_catalog"] = catalog
	_c3ft_cached_c3fs_observations = observations
	return observations


func _test_all_legal_depth1_screen_and_budget() -> void:
	var observations := _collect_c3ft_observations()
	var report_a := _build_c3ft_report(observations)
	var report_b := _build_c3ft_report(observations)
	var strategies := report_a.get("strategy_reports", {}) as Dictionary
	var source_report := report_a.get("source_c3fs_summary", {}) as Dictionary
	var mixed_probe := report_a.get("mixed_root_diversity_probe", {}) as Dictionary

	_check.call(
		"search_all_legal_screen_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FT,
	)
	_check.call(
		"search_all_legal_screen_reuses_exact_c3fs_oracle",
		int(report_a.get("selected_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(report_a.get("all_legal_switch_occurrences", 0)) == 240
		and int(source_report.get("non_top_only_deep_best_cases", -1)) == 6,
	)
	_check.call(
		"search_all_legal_screen_contexts_attached_without_failure",
		int(report_a.get("context_attach_failures", -1)) == 0
		and int(report_a.get("screen_context_failures", -1)) == 0,
	)
	_check.call(
		"search_all_legal_screen_evaluates_every_legal_switch_depth1",
		int(report_a.get("all_legal_depth1_evaluations", 0))
		== int(report_a.get("all_legal_switch_occurrences", -1)),
	)
	_check.call(
		"search_all_legal_screen_depth1_budget_is_explicit_and_unchanged",
		int(report_a.get("screen_depth_turns", -1)) == 1
		and int(report_a.get("screen_max_worlds", -1)) == 4
		and int(report_a.get("screen_max_simulations", -1)) == 220
		and int(report_a.get("screen_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP,
	)
	_check.call(
		"search_all_legal_screen_collection_complete",
		int(report_a.get("screen_result_failures", -1)) == 0
		and int(report_a.get("screen_incomplete_depth_evaluations", -1)) == 0
		and int(report_a.get("screen_budget_exhausted_evaluations", -1)) == 0
		and int(report_a.get("screen_world_coverage_failures", -1)) == 0,
	)
	_check.call(
		"search_all_legal_screen_deep_best_rank_accounting_complete",
		int(report_a.get("deep_best_candidate_occurrences", 0))
		== int(source_report.get("global_deep_unique_best_cases", -1))
		and int(report_a.get("deep_best_rank_histogram_sum", 0))
		== int(report_a.get("deep_best_candidate_occurrences", -1)),
	)
	_check.call(
		"search_all_legal_screen_non_top_winners_all_characterized",
		int(report_a.get("non_top_deep_winner_records", 0))
		== int(source_report.get("non_top_only_deep_best_cases", -1))
		and int(report_a.get("non_top_deep_winner_records", 0)) > 0,
	)
	_check.call(
		"search_all_legal_screen_declares_topk_and_margin_families",
		(report_a.get("top_k_values", []) as Array).size() == TOP_K_VALUES.size()
		and (report_a.get("margin_thresholds", []) as Array).size() == ALL_LEGAL_MARGIN_THRESHOLDS.size(),
	)
	_check.call(
		"search_all_legal_screen_all_strategies_account_for_every_case",
		_c3ft_strategy_case_accounting_complete(strategies, EXPECTED_SELECTED_CASES),
	)
	_check.call(
		"search_all_legal_screen_all_screen_strategies_order_invariant",
		int(report_a.get("strategy_reorder_mismatch_cases", -1)) == 0,
	)
	_check.call(
		"search_all_legal_screen_topk_preserves_equal_score_tiers",
		bool(report_a.get("top_k_ties_preserved", false))
		and not bool(report_a.get("lexical_cutoff_used_for_top_k", true)),
	)
	_check.call(
		"search_all_legal_screen_strategy_loss_is_measured_not_assumed",
		_c3ft_strategy_loss_partitions_complete(strategies, EXPECTED_SELECTED_CASES),
	)
	_check.call(
		"search_all_legal_screen_staged_cost_uses_actual_depth1_and_cached_depth2",
		int(report_a.get("all_legal_depth1_screen_simulations_sum", 0)) > 0
		and int(report_a.get("full_all_legal_depth2_reference_simulations_sum", 0))
		== int(source_report.get("full_legal_simulations_sum", -1)),
	)
	_check.call(
		"search_all_legal_screen_cost_frontier_is_descriptive_only",
		(report_a.get("cost_loss_frontier_strategy_ids", []) as Array).size() > 0
		and not bool(report_a.get("cost_loss_frontier_selects_production_strategy", true)),
	)
	_check.call(
		"search_all_legal_screen_budget_controls_are_accounting_only",
		bool(report_a.get("shared_budget_controls_are_accounting_only", false))
		and not bool(report_a.get("shared_budget_execution_modeled", true))
		and bool(report_a.get("equal_reservation_accounting_only", false)),
	)
	_check.call(
		"search_all_legal_screen_reservation_tables_account_for_every_budget",
		_c3ft_reservation_tables_complete(strategies),
	)
	_check.call(
		"search_all_legal_screen_root_fanout_kept_separate_from_inner_cap",
		bool(report_a.get("root_fanout_is_separate_from_inner_action_cap", false))
		and bool(report_a.get("one_move_slot_reserved_in_cap_analysis", false))
		and int(report_a.get("cap_three_switch_capacity_with_one_move", -1)) == 2,
	)
	_check.call(
		"search_all_legal_screen_mixed_probe_preserves_move_switch_diversity",
		int(mixed_probe.get("move_diversity_failure_cases", -1)) == 0
		and int(mixed_probe.get("switch_diversity_failure_cases", -1)) == 0,
	)
	_check.call(
		"search_all_legal_screen_mixed_probe_is_order_invariant",
		int(mixed_probe.get("switch_reorder_root_set_mismatch_cases", -1)) == 0
		and bool(mixed_probe.get("synthetic_moves_used_for_geometry_only", false))
		and not bool(mixed_probe.get("deep_scores_recomputed_with_synthetic_moves", true)),
	)
	_check.call(
		"search_all_legal_screen_forbidden_semantics_absent",
		not bool(report_a.get("frontier_used_for_preselection", true))
		and not bool(report_a.get("roster_value_used_for_preselection", true))
		and not bool(report_a.get("profile_used_as_presearch_tiebreak", true))
		and not bool(report_a.get("live_rng_used", true)),
	)
	_check.call(
		"search_all_legal_screen_hidden_and_campaign_context_absent",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true)),
	)
	_check.call(
		"search_all_legal_screen_production_unchanged",
		bool(report_a.get("production_sampler_unchanged", false))
		and bool(report_a.get("production_max_actions_unchanged", false))
		and bool(report_a.get("production_max_simulations_unchanged", false))
		and not bool(report_a.get("production_phase_logic_modified", true)),
	)
	_check.call(
		"search_all_legal_screen_no_strategy_or_budget_selected",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("search_all_legal_screen_report_deterministic", report_a == report_b)
	_check.call(
		"search_all_legal_screen_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH ALL LEGAL DEPTH1 SCREEN BUDGET AUDIT ===")
	print(JSON.stringify(report_a))


func _collect_c3ft_observations() -> Dictionary:
	var source := _collect_c3fs_observations()
	if not bool(source.get("valid", false)):
		return {"valid": false}
	var catalog := source.get("_c3ft_catalog") as DefinitionCatalog
	if catalog == null:
		return {"valid": false}

	var screen_budget := TrainerSearchBudget.constrained(1, 4, 220, EXPECTED_DEFAULT_CAP)
	var neutral_profile := TrainerProfile.balanced()
	var screen_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, screen_budget)
	var screened_cases: Array[Dictionary] = []
	var depth1_evaluations := 0
	var screen_result_failures := 0
	var incomplete_depth := 0
	var budget_exhausted := 0
	var world_coverage_failures := 0
	var screen_context_failures := 0
	var screen_simulations_sum := 0
	var nonempty_hidden_belief_cases := 0
	var nonempty_memory_event_cases := 0
	var nonempty_campaign_snapshot_cases := 0

	for raw_case in source.get("cases", []) as Array:
		var source_case := raw_case as Dictionary
		var context := source_case.get("_c3ft_context") as TrainerDecisionContext
		if context == null:
			screen_context_failures += 1
			continue
		var hypotheses := context.belief_snapshot.get("hypotheses", {}) as Dictionary
		if not hypotheses.is_empty():
			nonempty_hidden_belief_cases += 1
		var memory_events := context.memory_snapshot.get("event_log", []) as Array
		if not memory_events.is_empty():
			nonempty_memory_event_cases += 1
		if not context.campaign_snapshot.is_empty():
			nonempty_campaign_snapshot_cases += 1

		var all_ids := _c3fm_string_array(source_case.get("all_legal_switch_ids", []) as Array)
		all_ids.sort()
		var depth1_scores: Dictionary = {}
		var depth1_simulations: Dictionary = {}
		var valid_case := true
		for candidate_id in all_ids:
			var action := _c3fp_find_switch_action(context, candidate_id)
			depth1_evaluations += 1
			if action == null:
				screen_result_failures += 1
				valid_case = false
				continue
			var result := screen_search.evaluate(context, action)
			if result.is_empty() or not result.has("metadata"):
				screen_result_failures += 1
				valid_case = false
				continue
			var metadata := result.get("metadata", {}) as Dictionary
			var simulations := int(metadata.get("simulations_used", 0))
			depth1_scores[candidate_id] = int(result.get("score", 0))
			depth1_simulations[candidate_id] = simulations
			screen_simulations_sum += simulations
			if int(metadata.get("fully_completed_depth", 0)) != 1:
				incomplete_depth += 1
				valid_case = false
			if bool(metadata.get("budget_exhausted", false)):
				budget_exhausted += 1
				valid_case = false
			if int(metadata.get("world_coverage_basis_points", 0)) != 10000:
				world_coverage_failures += 1
				valid_case = false

		var screened := source_case.duplicate(true)
		screened.erase("_c3ft_context")
		screened["all_depth_one_scores"] = depth1_scores.duplicate(true)
		screened["all_depth_one_simulations"] = depth1_simulations.duplicate(true)
		screened["valid_for_screen"] = valid_case and depth1_scores.size() == all_ids.size()
		screened_cases.append(screened)

	return {
		"valid": true,
		"source": source,
		"cases": screened_cases,
		"screen_budget": screen_budget.to_dict(),
		"all_legal_depth1_evaluations": depth1_evaluations,
		"screen_result_failures": screen_result_failures,
		"screen_incomplete_depth_evaluations": incomplete_depth,
		"screen_budget_exhausted_evaluations": budget_exhausted,
		"screen_world_coverage_failures": world_coverage_failures,
		"screen_context_failures": screen_context_failures,
		"all_legal_depth1_screen_simulations_sum": screen_simulations_sum,
		"nonempty_hidden_belief_cases": nonempty_hidden_belief_cases,
		"nonempty_memory_event_cases": nonempty_memory_event_cases,
		"nonempty_campaign_snapshot_cases": nonempty_campaign_snapshot_cases,
	}


func _build_c3ft_report(observations: Dictionary) -> Dictionary:
	var source := observations.get("source", {}) as Dictionary
	var source_report := _build_c3fs_report(source)
	var cases := observations.get("cases", []) as Array
	var strategy_reports := _c3ft_new_strategy_reports()
	var strategy_reorder_mismatches := 0
	var all_legal_switch_occurrences := 0
	var deep_best_candidate_occurrences := 0
	var deep_best_rank_histogram: Dictionary = {}
	var deep_best_gap_sum := 0
	var deep_best_gap_max := 0
	var deep_best_screen_leader_cases := 0
	var non_top_winner_records: Array[Dictionary] = []
	var full_depth2_reference_sum := 0
	var full_depth2_reference_max_context := 0

	for raw_case in cases:
		var case := raw_case as Dictionary
		var all_ids := _c3fm_string_array(case.get("all_legal_switch_ids", []) as Array)
		all_ids.sort()
		var reverse_ids := all_ids.duplicate()
		reverse_ids.reverse()
		var top_ids := _c3fm_string_array(case.get("immediate_top_tier_ids", []) as Array)
		var depth1_scores := case.get("all_depth_one_scores", {}) as Dictionary
		var depth1_simulations := case.get("all_depth_one_simulations", {}) as Dictionary
		var depth2_scores := case.get("all_depth_two_scores", {}) as Dictionary
		var depth2_simulations := case.get("all_depth_two_simulations", {}) as Dictionary
		var deep_best_ids := _c3fs_best_ids(depth2_scores)
		var screen_cost := _c3fq_sum_simulations(all_ids, depth1_simulations)
		var context_depth2_cost := _c3fq_sum_simulations(all_ids, depth2_simulations)
		all_legal_switch_occurrences += all_ids.size()
		full_depth2_reference_sum += context_depth2_cost
		full_depth2_reference_max_context = maxi(full_depth2_reference_max_context, context_depth2_cost)

		for deep_id in deep_best_ids:
			deep_best_candidate_occurrences += 1
			var rank := _c3ft_score_rank(deep_id, all_ids, depth1_scores)
			var gap := _c3ft_depth1_gap_from_leader(deep_id, all_ids, depth1_scores)
			var rank_key := str(rank)
			deep_best_rank_histogram[rank_key] = int(deep_best_rank_histogram.get(rank_key, 0)) + 1
			deep_best_gap_sum += gap
			deep_best_gap_max = maxi(deep_best_gap_max, gap)
			if rank == 1:
				deep_best_screen_leader_cases += 1
			if not top_ids.has(deep_id):
				var retention: Dictionary = {}
				for raw_k in TOP_K_VALUES:
					var k := int(raw_k)
					retention["topk_%d" % k] = _c3ft_promote_top_k_tie_preserving(all_ids, depth1_scores, k).has(deep_id)
				for raw_margin in ALL_LEGAL_MARGIN_THRESHOLDS:
					var margin := int(raw_margin)
					retention["margin_%d" % margin] = _c3fq_promote_by_margin(all_ids, depth1_scores, margin).has(deep_id)
				non_top_winner_records.append({
					"anchor": int(case.get("anchor", -1)),
					"evidence_mode": String(case.get("evidence_mode", "")),
					"opponent_species_id": String(case.get("opponent_species_id", "")),
					"deep_best_switch_id": deep_id,
					"depth1_rank": rank,
					"depth1_gap_from_leader": gap,
					"depth1_score": int(depth1_scores.get(deep_id, 0)),
					"depth2_score": int(depth2_scores.get(deep_id, 0)),
					"retained_by": retention,
				})

		_c3ft_record_strategy(
			strategy_reports,
			"full_all_legal_depth2_reference",
			all_ids,
			deep_best_ids,
			0,
			depth2_simulations,
			all_ids.size(),
		)
		_c3ft_record_strategy(
			strategy_reports,
			"all_legal_screen_no_prune_control",
			all_ids,
			deep_best_ids,
			screen_cost,
			depth2_simulations,
			all_ids.size(),
		)

		for raw_k in TOP_K_VALUES:
			var k := int(raw_k)
			var strategy_id := "depth1_topk_%d_tie_preserving" % k
			var promoted := _c3ft_promote_top_k_tie_preserving(all_ids, depth1_scores, k)
			var promoted_reverse := _c3ft_promote_top_k_tie_preserving(reverse_ids, depth1_scores, k)
			if promoted != promoted_reverse:
				strategy_reorder_mismatches += 1
			_c3ft_record_strategy(
				strategy_reports,
				strategy_id,
				promoted,
				deep_best_ids,
				screen_cost,
				depth2_simulations,
				all_ids.size(),
			)

		for raw_margin in ALL_LEGAL_MARGIN_THRESHOLDS:
			var margin := int(raw_margin)
			var strategy_id := "depth1_margin_%d_all_legal" % margin
			var promoted := _c3fq_promote_by_margin(all_ids, depth1_scores, margin)
			var promoted_reverse := _c3fq_promote_by_margin(reverse_ids, depth1_scores, margin)
			if promoted != promoted_reverse:
				strategy_reorder_mismatches += 1
			_c3ft_record_strategy(
				strategy_reports,
				strategy_id,
				promoted,
				deep_best_ids,
				screen_cost,
				depth2_simulations,
				all_ids.size(),
			)

	var screen_budget := observations.get("screen_budget", {}) as Dictionary
	var mixed_probe := source_report.get("mixed_root_diversity_probe", {}) as Dictionary
	var rank_histogram_sum := 0
	for raw_count in deep_best_rank_histogram.values():
		rank_histogram_sum += int(raw_count)
	var cost_frontier := _c3fq_cost_loss_frontier(strategy_reports)
	return {
		"audit_id": AUDIT_ID_C3FT,
		"dataset_probe_id": TrainerRosterStructuralRealDataAuditTestSuite.PROBE_ID,
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"action_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"selected_cases": cases.size(),
		"all_legal_switch_occurrences": all_legal_switch_occurrences,
		"context_attach_failures": int(source.get("c3ft_context_attach_failures", 0)),
		"screen_context_failures": int(observations.get("screen_context_failures", 0)),
		"all_legal_depth1_evaluations": int(observations.get("all_legal_depth1_evaluations", 0)),
		"screen_result_failures": int(observations.get("screen_result_failures", 0)),
		"screen_incomplete_depth_evaluations": int(observations.get("screen_incomplete_depth_evaluations", 0)),
		"screen_budget_exhausted_evaluations": int(observations.get("screen_budget_exhausted_evaluations", 0)),
		"screen_world_coverage_failures": int(observations.get("screen_world_coverage_failures", 0)),
		"all_legal_depth1_screen_simulations_sum": int(observations.get("all_legal_depth1_screen_simulations_sum", 0)),
		"screen_depth_turns": int(screen_budget.get("depth_turns", 0)),
		"screen_max_worlds": int(screen_budget.get("max_worlds", 0)),
		"screen_max_simulations": int(screen_budget.get("max_simulations", 0)),
		"screen_max_actions_per_side": int(screen_budget.get("max_actions_per_side", 0)),
		"full_all_legal_depth2_reference_simulations_sum": full_depth2_reference_sum,
		"full_all_legal_depth2_reference_simulations_max_per_context": full_depth2_reference_max_context,
		"deep_best_candidate_occurrences": deep_best_candidate_occurrences,
		"deep_best_rank_histogram": deep_best_rank_histogram,
		"deep_best_rank_histogram_sum": rank_histogram_sum,
		"deep_best_screen_leader_cases": deep_best_screen_leader_cases,
		"deep_best_depth1_gap_sum": deep_best_gap_sum,
		"deep_best_depth1_gap_mean": int(deep_best_gap_sum / maxi(1, deep_best_candidate_occurrences)),
		"deep_best_depth1_gap_max": deep_best_gap_max,
		"non_top_deep_winner_records": non_top_winner_records.size(),
		"non_top_deep_winner_details": non_top_winner_records,
		"top_k_values": TOP_K_VALUES.duplicate(),
		"margin_thresholds": ALL_LEGAL_MARGIN_THRESHOLDS.duplicate(),
		"top_k_ties_preserved": true,
		"lexical_cutoff_used_for_top_k": false,
		"strategy_reports": strategy_reports,
		"strategy_reorder_mismatch_cases": strategy_reorder_mismatches,
		"cost_loss_frontier_strategy_ids": cost_frontier,
		"cost_loss_frontier_selects_production_strategy": false,
		"shared_budget_accounting_controls": SHARED_BUDGET_ACCOUNTING_CONTROLS.duplicate(),
		"shared_budget_controls_are_accounting_only": true,
		"shared_budget_execution_modeled": false,
		"equal_reservation_accounting_only": true,
		"root_fanout_is_separate_from_inner_action_cap": true,
		"one_move_slot_reserved_in_cap_analysis": true,
		"cap_three_switch_capacity_with_one_move": 2,
		"mixed_root_diversity_probe": mixed_probe,
		"source_c3fs_summary": {
			"global_deep_unique_best_cases": int(source_report.get("global_deep_unique_best_cases", 0)),
			"non_top_only_deep_best_cases": int(source_report.get("non_top_only_deep_best_cases", 0)),
			"non_top_becomes_deep_best_cases": int(source_report.get("non_top_becomes_deep_best_cases", 0)),
			"full_legal_simulations_sum": int(source_report.get("full_legal_simulations_sum", 0)),
			"full_legal_simulations_max_per_context": int(source_report.get("full_legal_simulations_max_per_context", 0)),
		},
		"nonempty_hidden_belief_cases": int(observations.get("nonempty_hidden_belief_cases", 0)),
		"nonempty_memory_event_cases": int(observations.get("nonempty_memory_event_cases", 0)),
		"nonempty_campaign_snapshot_cases": int(observations.get("nonempty_campaign_snapshot_cases", 0)),
		"live_rng_used": false,
		"profile_used_as_presearch_tiebreak": false,
		"frontier_used_for_preselection": false,
		"roster_value_used_for_preselection": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"campaign_policy_used": false,
		"production_sampler_unchanged": true,
		"production_max_actions_unchanged": true,
		"production_max_simulations_unchanged": true,
		"production_phase_logic_modified": false,
		"selected_strategy_id": null,
		"selected_shared_budget": null,
		"production_strategy_selected": false,
		"search_sampling_redesign_authorized": false,
		"behavior_integration_authorized": false,
		"recommended_next_boundary": "interpret_all_legal_screen_preservation_cost_and_shared_budget_before_any_sampler_port",
	}


func _c3ft_new_strategy_reports() -> Dictionary:
	var reports: Dictionary = {}
	reports["full_all_legal_depth2_reference"] = _c3ft_new_strategy(
		"full_all_legal_depth2_reference", false, false, true
	)
	reports["all_legal_screen_no_prune_control"] = _c3ft_new_strategy(
		"all_legal_screen_no_prune_control", true, false, true
	)
	for raw_k in TOP_K_VALUES:
		var k := int(raw_k)
		var strategy_id := "depth1_topk_%d_tie_preserving" % k
		reports[strategy_id] = _c3ft_new_strategy(strategy_id, true, false, true)
	for raw_margin in ALL_LEGAL_MARGIN_THRESHOLDS:
		var margin := int(raw_margin)
		var strategy_id := "depth1_margin_%d_all_legal" % margin
		reports[strategy_id] = _c3ft_new_strategy(strategy_id, true, false, true)
	return reports


func _c3ft_new_strategy(
	strategy_id: String,
	uses_depth1_screen: bool,
	negative_control: bool,
	order_invariant: bool,
) -> Dictionary:
	var exceed: Dictionary = {}
	var reservation: Dictionary = {}
	for raw_control in SHARED_BUDGET_ACCOUNTING_CONTROLS:
		var key := str(int(raw_control))
		exceed[key] = 0
		reservation[key] = {
			"deep_best_reservation_fit_cases": 0,
			"all_promoted_roots_reservation_fit_cases": 0,
		}
	return {
		"strategy_id": strategy_id,
		"uses_depth1_screen": uses_depth1_screen,
		"negative_control": negative_control,
		"order_invariant": order_invariant,
		"cases": 0,
		"preserves_deep_optimum_cases": 0,
		"loses_deep_optimum_cases": 0,
		"promoted_switches_sum": 0,
		"promoted_switches_max": 0,
		"cases_promoting_one_switch": 0,
		"cases_promoting_two_switches": 0,
		"cases_promoting_more_than_two_switches": 0,
		"would_exceed_cap3_if_collapsed_with_one_move_cases": 0,
		"screening_simulations_sum": 0,
		"depth_two_simulations_sum": 0,
		"total_simulations_sum": 0,
		"total_simulations_max_per_context": 0,
		"total_cost_exceed_cases": exceed,
		"equal_reservation_fit_by_budget": reservation,
	}


func _c3ft_record_strategy(
	strategy_reports: Dictionary,
	strategy_id: String,
	promoted_ids: Array[String],
	deep_best_ids: Array[String],
	screen_cost: int,
	depth2_simulations: Dictionary,
	_legal_switch_count: int,
) -> void:
	var report := strategy_reports.get(strategy_id, {}) as Dictionary
	report["cases"] = int(report.get("cases", 0)) + 1
	var preserves := _c3fo_intersects(promoted_ids, deep_best_ids)
	if preserves:
		report["preserves_deep_optimum_cases"] = int(report.get("preserves_deep_optimum_cases", 0)) + 1
	else:
		report["loses_deep_optimum_cases"] = int(report.get("loses_deep_optimum_cases", 0)) + 1

	report["promoted_switches_sum"] = int(report.get("promoted_switches_sum", 0)) + promoted_ids.size()
	report["promoted_switches_max"] = maxi(int(report.get("promoted_switches_max", 0)), promoted_ids.size())
	if promoted_ids.size() == 1:
		report["cases_promoting_one_switch"] = int(report.get("cases_promoting_one_switch", 0)) + 1
	elif promoted_ids.size() == 2:
		report["cases_promoting_two_switches"] = int(report.get("cases_promoting_two_switches", 0)) + 1
	elif promoted_ids.size() > 2:
		report["cases_promoting_more_than_two_switches"] = int(report.get("cases_promoting_more_than_two_switches", 0)) + 1
		report["would_exceed_cap3_if_collapsed_with_one_move_cases"] = int(
			report.get("would_exceed_cap3_if_collapsed_with_one_move_cases", 0)
		) + 1

	var deep_cost := _c3fq_sum_simulations(promoted_ids, depth2_simulations)
	var total_cost := screen_cost + deep_cost
	report["screening_simulations_sum"] = int(report.get("screening_simulations_sum", 0)) + screen_cost
	report["depth_two_simulations_sum"] = int(report.get("depth_two_simulations_sum", 0)) + deep_cost
	report["total_simulations_sum"] = int(report.get("total_simulations_sum", 0)) + total_cost
	report["total_simulations_max_per_context"] = maxi(
		int(report.get("total_simulations_max_per_context", 0)), total_cost
	)

	var exceed := report.get("total_cost_exceed_cases", {}) as Dictionary
	var reservation := report.get("equal_reservation_fit_by_budget", {}) as Dictionary
	for raw_control in SHARED_BUDGET_ACCOUNTING_CONTROLS:
		var control := int(raw_control)
		var key := str(control)
		if total_cost > control:
			exceed[key] = int(exceed.get(key, 0)) + 1
		var remaining := maxi(0, control - screen_cost)
		var share := int(remaining / maxi(1, promoted_ids.size()))
		var all_fit := not promoted_ids.is_empty()
		for candidate_id in promoted_ids:
			if int(depth2_simulations.get(candidate_id, 0)) > share:
				all_fit = false
				break
		var deep_best_fit := false
		for deep_id in deep_best_ids:
			if promoted_ids.has(deep_id) and int(depth2_simulations.get(deep_id, 0)) <= share:
				deep_best_fit = true
				break
		var bucket := reservation.get(key, {}) as Dictionary
		if deep_best_fit:
			bucket["deep_best_reservation_fit_cases"] = int(bucket.get("deep_best_reservation_fit_cases", 0)) + 1
		if all_fit:
			bucket["all_promoted_roots_reservation_fit_cases"] = int(bucket.get("all_promoted_roots_reservation_fit_cases", 0)) + 1
		reservation[key] = bucket
	report["total_cost_exceed_cases"] = exceed
	report["equal_reservation_fit_by_budget"] = reservation
	strategy_reports[strategy_id] = report


func _c3ft_promote_top_k_tie_preserving(
	candidate_ids: Array[String],
	depth1_scores: Dictionary,
	k: int,
) -> Array[String]:
	if candidate_ids.is_empty() or k <= 0:
		return []
	var scores: Array[int] = []
	for candidate_id in candidate_ids:
		scores.append(int(depth1_scores.get(candidate_id, -2147483648)))
	scores.sort()
	scores.reverse()
	var threshold_index := mini(k - 1, scores.size() - 1)
	var threshold := scores[threshold_index]
	var promoted: Array[String] = []
	for candidate_id in candidate_ids:
		if int(depth1_scores.get(candidate_id, -2147483648)) >= threshold:
			promoted.append(candidate_id)
	promoted.sort()
	return promoted


func _c3ft_score_rank(
	candidate_id: String,
	candidate_ids: Array[String],
	depth1_scores: Dictionary,
) -> int:
	var target := int(depth1_scores.get(candidate_id, -2147483648))
	var higher := 0
	for other_id in candidate_ids:
		if int(depth1_scores.get(other_id, -2147483648)) > target:
			higher += 1
	return higher + 1


func _c3ft_depth1_gap_from_leader(
	candidate_id: String,
	candidate_ids: Array[String],
	depth1_scores: Dictionary,
) -> int:
	var best := -2147483648
	for other_id in candidate_ids:
		best = maxi(best, int(depth1_scores.get(other_id, -2147483648)))
	return maxi(0, best - int(depth1_scores.get(candidate_id, -2147483648)))


func _c3ft_strategy_case_accounting_complete(
	strategies: Dictionary,
	expected_cases: int,
) -> bool:
	for raw_report in strategies.values():
		var report := raw_report as Dictionary
		if int(report.get("cases", -1)) != expected_cases:
			return false
	return true


func _c3ft_strategy_loss_partitions_complete(
	strategies: Dictionary,
	expected_cases: int,
) -> bool:
	for raw_report in strategies.values():
		var report := raw_report as Dictionary
		if (
			int(report.get("preserves_deep_optimum_cases", 0))
			+ int(report.get("loses_deep_optimum_cases", 0))
			!= expected_cases
		):
			return false
	return true


func _c3ft_reservation_tables_complete(strategies: Dictionary) -> bool:
	for raw_report in strategies.values():
		var report := raw_report as Dictionary
		var reservation := report.get("equal_reservation_fit_by_budget", {}) as Dictionary
		if reservation.size() != SHARED_BUDGET_ACCOUNTING_CONTROLS.size():
			return false
		for raw_control in SHARED_BUDGET_ACCOUNTING_CONTROLS:
			if not reservation.has(str(int(raw_control))):
				return false
	return true
