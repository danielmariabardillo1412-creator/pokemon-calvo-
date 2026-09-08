class_name TrainerRosterSearchTieAdaptivePreservationAuditTestSuite
extends TrainerRosterSearchTieDepthPreservationCanonicalPhaseAuditTestSuite

# C3f-q is TEST/AUDIT-ONLY. It compares conditional tie-preservation designs on
# the same stratified real-data contexts certified by C3f-p. Production search,
# action-space, budgets, brains, switching, Pareto and roster value remain untouched.
#
# Each immediate switching top-set is screened symmetrically at depth 1 using the
# production search with the same worlds/simulation/action caps as depth 2. Candidate
# policies then decide which members receive the full depth-2 evaluation. Lexical
# order is retained only for negative controls and stable serialization.

const AUDIT_ID_C3FQ := "c3f_q_adaptive_tie_preservation_cost_audit_v1"
const SCREEN_MARGIN_THRESHOLDS := [0, 500, 1500, 3000, 6000]
const GAP_FULL_FALLBACK_THRESHOLDS := [500, 1500, 3000]


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_adaptive_tie_preservation_cost()


func _test_adaptive_tie_preservation_cost() -> void:
	var observations := _collect_c3fq_observations()
	var report_a := _build_c3fq_policy_report(observations)
	var report_b := _build_c3fq_policy_report(observations)
	var strategies := report_a.get("strategy_reports", {}) as Dictionary
	var full_reference := strategies.get("full_top_tier_depth_two_reference", {}) as Dictionary
	var lexical_one := strategies.get("lexical_one_slot_negative_control", {}) as Dictionary
	var lexical_two := strategies.get("lexical_two_slot_negative_control", {}) as Dictionary

	_check.call(
		"search_tie_adaptive_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FQ,
	)
	_check.call(
		"search_tie_adaptive_inherits_c3fp_sample",
		int(report_a.get("selected_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(report_a.get("immediate_tied_root_candidates", 0)) == EXPECTED_ROOT_EVALUATIONS,
	)
	_check.call(
		"search_tie_adaptive_depth_one_budget_is_comparable",
		int(report_a.get("screen_depth_turns", -1)) == 1
		and int(report_a.get("screen_max_worlds", -1)) == 4
		and int(report_a.get("screen_max_simulations", -1)) == 220
		and int(report_a.get("screen_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP,
	)
	_check.call(
		"search_tie_adaptive_depth_two_reference_budget_unchanged",
		int(report_a.get("reference_depth_turns", -1)) == 2
		and int(report_a.get("reference_max_worlds", -1)) == 4
		and int(report_a.get("reference_max_simulations", -1)) == 220
		and int(report_a.get("reference_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP,
	)
	_check.call(
		"search_tie_adaptive_search_collection_complete",
		int(report_a.get("depth_one_evaluations", 0)) == EXPECTED_ROOT_EVALUATIONS
		and int(report_a.get("depth_two_reference_evaluations", 0)) == EXPECTED_ROOT_EVALUATIONS
		and int(report_a.get("search_result_failures", -1)) == 0
		and int(report_a.get("incomplete_depth_evaluations", -1)) == 0
		and int(report_a.get("budget_exhausted_evaluations", -1)) == 0
		and int(report_a.get("world_coverage_failures", -1)) == 0,
	)
	_check.call(
		"search_tie_adaptive_reference_reproduces_c3fp_unique_deep_best",
		int(report_a.get("reference_depth_divergence_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(report_a.get("reference_unique_deep_best_cases", 0)) == EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_tie_adaptive_full_reference_preserves_all_deep_optima",
		int(full_reference.get("loses_deep_optimum_cases", -1)) == 0
		and int(full_reference.get("preserves_deep_optimum_cases", 0)) == EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_tie_adaptive_negative_controls_reproduce_c3fp_risk",
		int(lexical_one.get("loses_deep_optimum_cases", -1)) == 29
		and int(lexical_two.get("loses_deep_optimum_cases", -1)) == 18,
	)
	_check.call(
		"search_tie_adaptive_all_contextual_strategies_order_invariant",
		int(report_a.get("contextual_strategy_reorder_mismatches", -1)) == 0,
	)
	_check.call(
		"search_tie_adaptive_all_contextual_strategies_use_depth_one_only",
		bool(report_a.get("contextual_preselection_uses_only_depth_one_scores", false)),
	)
	_check.call(
		"search_tie_adaptive_cost_accounting_has_real_screening",
		int(report_a.get("depth_one_screening_simulations_sum", 0)) > 0
		and int(report_a.get("full_reference_depth_two_simulations_sum", 0)) > 0,
	)
	_check.call(
		"search_tie_adaptive_tie_only_population_boundary_recorded",
		int(report_a.get("population_tie_cases", 0)) == 306
		and int(report_a.get("population_untied_cases", 0)) == 206
		and int(report_a.get("population_scenarios", 0)) == EXPECTED_SCENARIOS,
	)
	_check.call(
		"search_tie_adaptive_move_switch_diversity_boundary_explicit",
		bool(report_a.get("production_sampler_unchanged", false))
		and bool(report_a.get("one_move_slot_reserved_in_cap_analysis", false)),
	)
	_check.call(
		"search_tie_adaptive_forbidden_semantics_absent",
		not bool(report_a.get("frontier_used_for_preselection", true))
		and not bool(report_a.get("roster_value_used_for_preselection", true))
		and not bool(report_a.get("profile_used_as_presearch_tiebreak", true))
		and not bool(report_a.get("live_rng_used", true)),
	)
	_check.call(
		"search_tie_adaptive_hidden_and_campaign_context_absent",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true)),
	)
	_check.call(
		"search_tie_adaptive_shared_budget_not_faked",
		not bool(report_a.get("shared_budget_reuse_modeled", true)),
	)
	_check.call(
		"search_tie_adaptive_no_strategy_selected_for_production",
		report_a.get("selected_strategy_id", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("search_tie_adaptive_policy_report_deterministic", report_a == report_b)
	_check.call(
		"search_tie_adaptive_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH TIE ADAPTIVE PRESERVATION COST AUDIT ===")
	print(JSON.stringify(report_a))


func _collect_c3fq_observations() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"valid": false, "eligible_species": 0}

	var game_data := GameData.from_dict(normalized)
	var catalog := game_data.to_definition_catalog()
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe := helper._build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)

	var fixture_catalog := _catalog
	_catalog = catalog
	var contract_builder := TrainerRosterComponentFirstContract.new(catalog, _operational_ruleset)
	var frontier_evaluator := TrainerRosterParetoFrontier.new()
	var neutral_profile := TrainerProfile.balanced()
	var switching_evaluator := TrainerStrategicSwitchEvaluatorV2.new(catalog, neutral_profile)
	var screen_budget := TrainerSearchBudget.constrained(1, 4, 220, EXPECTED_DEFAULT_CAP)
	var reference_budget := TrainerSearchBudget.depth_two_default()
	var screen_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, screen_budget)
	var reference_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, reference_budget)

	var population_scenarios := 0
	var population_tie_cases := 0
	var context_build_failures := 0
	var nonempty_hidden_belief_cases := 0
	var nonempty_memory_event_cases := 0
	var nonempty_campaign_snapshot_cases := 0
	var strata: Dictionary = {}
	for tie_size in EXPECTED_TIE_SIZES:
		for raw_mode in EVIDENCE_MODES:
			strata[_c3fp_stratum_key(int(tie_size), String(raw_mode))] = []

	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])
	var sampled_rosters := 0
	for anchor in range(0, members.size(), ROSTER_SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var contract := contract_builder.build_contract(degraded)
		var frontier := frontier_evaluator.evaluate(contract)
		sampled_rosters += 1
		var frontier_ids := _c3fm_string_array(frontier.get("frontier_instance_ids", []) as Array)
		var dominated_ids := _c3fm_string_array(frontier.get("dominated_instance_ids", []) as Array)
		var active_id := String(degraded[0].get("instance_id", ""))
		var own_ids: Dictionary = {}
		for member in degraded:
			own_ids[String(member.get("instance_id", ""))] = true
		var banned_opponent_ids := own_ids.duplicate()

		for raw_offset in OPPONENT_OFFSETS:
			var opponent := _select_real_opponent(
				members,
				(anchor + int(raw_offset)) % maxi(1, members.size()),
				banned_opponent_ids,
				catalog,
			)
			if opponent.is_empty():
				context_build_failures += 1
				continue
			banned_opponent_ids[String(opponent.get("instance_id", ""))] = true

			for raw_mode in EVIDENCE_MODES:
				var mode := String(raw_mode)
				var context := _build_shadow_context(degraded, opponent, mode, catalog)
				if context == null:
					context_build_failures += 1
					continue
				population_scenarios += 1
				var hypotheses := context.belief_snapshot.get("hypotheses", {}) as Dictionary
				if not hypotheses.is_empty():
					nonempty_hidden_belief_cases += 1
				var memory_events := context.memory_snapshot.get("event_log", []) as Array
				if not memory_events.is_empty():
					nonempty_memory_event_cases += 1
				if not context.campaign_snapshot.is_empty():
					nonempty_campaign_snapshot_cases += 1

				var outcome := _evaluate_shadow_switches(
					context,
					active_id,
					frontier_ids,
					dominated_ids,
					switching_evaluator,
				)
				if not bool(outcome.get("valid", false)):
					context_build_failures += 1
					continue
				var best_ids := _c3fm_string_array(outcome.get("best_switch_ids", []) as Array)
				best_ids.sort()
				if best_ids.size() < 2:
					continue
				population_tie_cases += 1
				var key := _c3fp_stratum_key(best_ids.size(), mode)
				if strata.has(key):
					var records := strata.get(key, []) as Array
					records.append({
						"anchor": anchor,
						"mode": mode,
						"opponent_species_id": String(opponent.get("species_id", "")),
						"context": context,
						"best_ids": best_ids,
					})
					strata[key] = records

	var selected_records: Array[Dictionary] = []
	for tie_size in EXPECTED_TIE_SIZES:
		for raw_mode in EVIDENCE_MODES:
			var key := _c3fp_stratum_key(int(tie_size), String(raw_mode))
			var records := strata.get(key, []) as Array
			for record in _c3fp_spaced_sample(records, SAMPLE_PER_TIE_SIZE_PER_MODE):
				selected_records.append((record as Dictionary).duplicate(false))

	var cases: Array[Dictionary] = []
	var depth_one_evaluations := 0
	var depth_two_reference_evaluations := 0
	var search_result_failures := 0
	var incomplete_depth_evaluations := 0
	var budget_exhausted_evaluations := 0
	var world_coverage_failures := 0
	var depth_one_screening_simulations_sum := 0
	var full_reference_depth_two_simulations_sum := 0
	var reference_depth_divergence_cases := 0
	var reference_unique_deep_best_cases := 0

	for record in selected_records:
		var context := record.get("context") as TrainerDecisionContext
		var best_ids := _c3fm_string_array(record.get("best_ids", []) as Array)
		best_ids.sort()
		var depth_one_scores: Dictionary = {}
		var depth_two_scores: Dictionary = {}
		var depth_one_simulations: Dictionary = {}
		var depth_two_simulations: Dictionary = {}
		var valid_case := true

		for candidate_id in best_ids:
			var action := _c3fp_find_switch_action(context, candidate_id)
			if action == null:
				search_result_failures += 1
				valid_case = false
				continue

			var screen_result := screen_search.evaluate(context, action)
			depth_one_evaluations += 1
			if screen_result.is_empty() or not screen_result.has("metadata"):
				search_result_failures += 1
				valid_case = false
			else:
				var screen_metadata := screen_result.get("metadata", {}) as Dictionary
				if int(screen_metadata.get("fully_completed_depth", 0)) != 1:
					incomplete_depth_evaluations += 1
					valid_case = false
				if bool(screen_metadata.get("budget_exhausted", false)):
					budget_exhausted_evaluations += 1
					valid_case = false
				if int(screen_metadata.get("world_coverage_basis_points", 0)) != 10000:
					world_coverage_failures += 1
					valid_case = false
				depth_one_scores[candidate_id] = int(screen_result.get("score", 0))
				depth_one_simulations[candidate_id] = int(screen_metadata.get("simulations_used", 0))
				depth_one_screening_simulations_sum += int(screen_metadata.get("simulations_used", 0))

			var reference_result := reference_search.evaluate(context, action)
			depth_two_reference_evaluations += 1
			if reference_result.is_empty() or not reference_result.has("metadata"):
				search_result_failures += 1
				valid_case = false
			else:
				var reference_metadata := reference_result.get("metadata", {}) as Dictionary
				if int(reference_metadata.get("fully_completed_depth", 0)) != 2:
					incomplete_depth_evaluations += 1
					valid_case = false
				if bool(reference_metadata.get("budget_exhausted", false)):
					budget_exhausted_evaluations += 1
					valid_case = false
				if int(reference_metadata.get("world_coverage_basis_points", 0)) != 10000:
					world_coverage_failures += 1
					valid_case = false
				depth_two_scores[candidate_id] = int(reference_result.get("score", 0))
				depth_two_simulations[candidate_id] = int(reference_metadata.get("simulations_used", 0))
				full_reference_depth_two_simulations_sum += int(reference_metadata.get("simulations_used", 0))

		if not valid_case or depth_one_scores.size() != best_ids.size() or depth_two_scores.size() != best_ids.size():
			continue

		var deep_best_score := -2147483648
		var deep_worst_score := 2147483647
		for candidate_id in best_ids:
			var score := int(depth_two_scores.get(candidate_id, 0))
			deep_best_score = maxi(deep_best_score, score)
			deep_worst_score = mini(deep_worst_score, score)
		var deep_best_ids: Array[String] = []
		for candidate_id in best_ids:
			if int(depth_two_scores.get(candidate_id, 0)) == deep_best_score:
				deep_best_ids.append(candidate_id)
		deep_best_ids.sort()
		if deep_best_score != deep_worst_score:
			reference_depth_divergence_cases += 1
		if deep_best_ids.size() == 1:
			reference_unique_deep_best_cases += 1

		cases.append({
			"anchor": int(record.get("anchor", -1)),
			"evidence_mode": String(record.get("mode", "")),
			"opponent_species_id": String(record.get("opponent_species_id", "")),
			"immediate_tied_switch_ids": best_ids.duplicate(),
			"depth_one_scores": depth_one_scores.duplicate(true),
			"depth_two_scores": depth_two_scores.duplicate(true),
			"depth_one_simulations": depth_one_simulations.duplicate(true),
			"depth_two_simulations": depth_two_simulations.duplicate(true),
			"deep_best_switch_ids": deep_best_ids.duplicate(),
		})

	_catalog = fixture_catalog
	return {
		"valid": true,
		"eligible_species": members.size(),
		"sampled_rosters": sampled_rosters,
		"population_scenarios": population_scenarios,
		"population_tie_cases": population_tie_cases,
		"population_untied_cases": population_scenarios - population_tie_cases,
		"selected_cases": cases.size(),
		"cases": cases,
		"depth_one_evaluations": depth_one_evaluations,
		"depth_two_reference_evaluations": depth_two_reference_evaluations,
		"search_result_failures": search_result_failures,
		"incomplete_depth_evaluations": incomplete_depth_evaluations,
		"budget_exhausted_evaluations": budget_exhausted_evaluations,
		"world_coverage_failures": world_coverage_failures,
		"context_build_failures": context_build_failures,
		"depth_one_screening_simulations_sum": depth_one_screening_simulations_sum,
		"full_reference_depth_two_simulations_sum": full_reference_depth_two_simulations_sum,
		"reference_depth_divergence_cases": reference_depth_divergence_cases,
		"reference_unique_deep_best_cases": reference_unique_deep_best_cases,
		"nonempty_hidden_belief_cases": nonempty_hidden_belief_cases,
		"nonempty_memory_event_cases": nonempty_memory_event_cases,
		"nonempty_campaign_snapshot_cases": nonempty_campaign_snapshot_cases,
		"screen_budget": screen_budget.to_dict(),
		"reference_budget": reference_budget.to_dict(),
	}


func _build_c3fq_policy_report(observations: Dictionary) -> Dictionary:
	var cases := observations.get("cases", []) as Array
	var strategy_reports: Dictionary = {}
	strategy_reports["lexical_one_slot_negative_control"] = _c3fq_new_strategy(
		"lexical_one_slot_negative_control", false, true, false
	)
	strategy_reports["lexical_two_slot_negative_control"] = _c3fq_new_strategy(
		"lexical_two_slot_negative_control", false, true, false
	)
	for raw_margin in SCREEN_MARGIN_THRESHOLDS:
		var margin := int(raw_margin)
		var strategy_id := "depth1_margin_%d" % margin
		strategy_reports[strategy_id] = _c3fq_new_strategy(strategy_id, true, false, true)
	for raw_gap in GAP_FULL_FALLBACK_THRESHOLDS:
		var gap := int(raw_gap)
		var strategy_id := "depth1_gap_%d_full_fallback" % gap
		strategy_reports[strategy_id] = _c3fq_new_strategy(strategy_id, true, false, true)
	strategy_reports["full_top_tier_depth_two_reference"] = _c3fq_new_strategy(
		"full_top_tier_depth_two_reference", true, false, false
	)

	var contextual_strategy_reorder_mismatches := 0
	var promotion_examples: Array[Dictionary] = []
	for raw_case in cases:
		var case := raw_case as Dictionary
		var best_ids := _c3fm_string_array(case.get("immediate_tied_switch_ids", []) as Array)
		best_ids.sort()
		var depth_one_scores := case.get("depth_one_scores", {}) as Dictionary
		var depth_one_simulations := case.get("depth_one_simulations", {}) as Dictionary
		var depth_two_simulations := case.get("depth_two_simulations", {}) as Dictionary
		var deep_best_ids := _c3fm_string_array(case.get("deep_best_switch_ids", []) as Array)
		deep_best_ids.sort()
		var screen_cost := _c3fq_sum_simulations(best_ids, depth_one_simulations)

		_c3fq_record_strategy(
			strategy_reports,
			"lexical_one_slot_negative_control",
			[best_ids[0]],
			deep_best_ids,
			0,
			depth_two_simulations,
			best_ids.size(),
		)
		var lexical_two: Array[String] = []
		for index in range(mini(2, best_ids.size())):
			lexical_two.append(best_ids[index])
		_c3fq_record_strategy(
			strategy_reports,
			"lexical_two_slot_negative_control",
			lexical_two,
			deep_best_ids,
			0,
			depth_two_simulations,
			best_ids.size(),
		)

		for raw_margin in SCREEN_MARGIN_THRESHOLDS:
			var margin := int(raw_margin)
			var strategy_id := "depth1_margin_%d" % margin
			var promoted := _c3fq_promote_by_margin(best_ids, depth_one_scores, margin)
			var reversed_ids := best_ids.duplicate()
			reversed_ids.reverse()
			var reorder_promoted := _c3fq_promote_by_margin(reversed_ids, depth_one_scores, margin)
			if promoted != reorder_promoted:
				contextual_strategy_reorder_mismatches += 1
			_c3fq_record_strategy(
				strategy_reports,
				strategy_id,
				promoted,
				deep_best_ids,
				screen_cost,
				depth_two_simulations,
				best_ids.size(),
			)

		for raw_gap in GAP_FULL_FALLBACK_THRESHOLDS:
			var gap := int(raw_gap)
			var strategy_id := "depth1_gap_%d_full_fallback" % gap
			var promoted := _c3fq_promote_gap_full_fallback(best_ids, depth_one_scores, gap)
			var reversed_ids := best_ids.duplicate()
			reversed_ids.reverse()
			var reorder_promoted := _c3fq_promote_gap_full_fallback(reversed_ids, depth_one_scores, gap)
			if promoted != reorder_promoted:
				contextual_strategy_reorder_mismatches += 1
			_c3fq_record_strategy(
				strategy_reports,
				strategy_id,
				promoted,
				deep_best_ids,
				screen_cost,
				depth_two_simulations,
				best_ids.size(),
			)

		_c3fq_record_strategy(
			strategy_reports,
			"full_top_tier_depth_two_reference",
			best_ids,
			deep_best_ids,
			0,
			depth_two_simulations,
			best_ids.size(),
		)

		if promotion_examples.size() < 12:
			promotion_examples.append({
				"anchor": int(case.get("anchor", -1)),
				"evidence_mode": String(case.get("evidence_mode", "")),
				"opponent_species_id": String(case.get("opponent_species_id", "")),
				"tie_size": best_ids.size(),
				"depth_one_scores": depth_one_scores.duplicate(true),
				"deep_best_switch_ids": deep_best_ids.duplicate(),
				"depth1_margin_0": _c3fq_promote_by_margin(best_ids, depth_one_scores, 0),
				"depth1_margin_1500": _c3fq_promote_by_margin(best_ids, depth_one_scores, 1500),
				"depth1_gap_1500_full_fallback": _c3fq_promote_gap_full_fallback(best_ids, depth_one_scores, 1500),
			})

	var pareto_strategy_ids := _c3fq_cost_loss_frontier(strategy_reports)
	var screen_budget := observations.get("screen_budget", {}) as Dictionary
	var reference_budget := observations.get("reference_budget", {}) as Dictionary
	return {
		"audit_id": AUDIT_ID_C3FQ,
		"dataset_probe_id": TrainerRosterStructuralRealDataAuditTestSuite.PROBE_ID,
		"eligible_species": int(observations.get("eligible_species", 0)),
		"sampled_rosters": int(observations.get("sampled_rosters", 0)),
		"population_scenarios": int(observations.get("population_scenarios", 0)),
		"population_tie_cases": int(observations.get("population_tie_cases", 0)),
		"population_untied_cases": int(observations.get("population_untied_cases", 0)),
		"tie_only_expansion_population_rate_bp": (
			int(observations.get("population_tie_cases", 0)) * 10000
			/ maxi(1, int(observations.get("population_scenarios", 0)))
		),
		"selected_cases": cases.size(),
		"immediate_tied_root_candidates": _c3fq_total_candidate_count(cases),
		"depth_one_evaluations": int(observations.get("depth_one_evaluations", 0)),
		"depth_two_reference_evaluations": int(observations.get("depth_two_reference_evaluations", 0)),
		"search_result_failures": int(observations.get("search_result_failures", 0)),
		"incomplete_depth_evaluations": int(observations.get("incomplete_depth_evaluations", 0)),
		"budget_exhausted_evaluations": int(observations.get("budget_exhausted_evaluations", 0)),
		"world_coverage_failures": int(observations.get("world_coverage_failures", 0)),
		"context_build_failures": int(observations.get("context_build_failures", 0)),
		"reference_depth_divergence_cases": int(observations.get("reference_depth_divergence_cases", 0)),
		"reference_unique_deep_best_cases": int(observations.get("reference_unique_deep_best_cases", 0)),
		"depth_one_screening_simulations_sum": int(observations.get("depth_one_screening_simulations_sum", 0)),
		"full_reference_depth_two_simulations_sum": int(observations.get("full_reference_depth_two_simulations_sum", 0)),
		"screen_depth_turns": int(screen_budget.get("depth_turns", 0)),
		"screen_max_worlds": int(screen_budget.get("max_worlds", 0)),
		"screen_max_simulations": int(screen_budget.get("max_simulations", 0)),
		"screen_max_actions_per_side": int(screen_budget.get("max_actions_per_side", 0)),
		"reference_depth_turns": int(reference_budget.get("depth_turns", 0)),
		"reference_max_worlds": int(reference_budget.get("max_worlds", 0)),
		"reference_max_simulations": int(reference_budget.get("max_simulations", 0)),
		"reference_max_actions_per_side": int(reference_budget.get("max_actions_per_side", 0)),
		"screen_margin_thresholds": SCREEN_MARGIN_THRESHOLDS.duplicate(),
		"gap_full_fallback_thresholds": GAP_FULL_FALLBACK_THRESHOLDS.duplicate(),
		"strategy_reports": strategy_reports,
		"cost_loss_pareto_strategy_ids": pareto_strategy_ids,
		"promotion_examples": promotion_examples,
		"contextual_strategy_reorder_mismatches": contextual_strategy_reorder_mismatches,
		"contextual_preselection_uses_only_depth_one_scores": true,
		"production_sampler_unchanged": true,
		"one_move_slot_reserved_in_cap_analysis": true,
		"cap_three_switch_capacity_with_one_move": 2,
		"shared_budget_reuse_modeled": false,
		"shared_budget_reuse_note": "staged_cost_is_actual_depth1_screen_plus_selected_depth2_evaluations_no_cache_reuse_assumed",
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
		"selected_strategy_id": null,
		"production_strategy_selected": false,
		"search_sampling_redesign_authorized": false,
		"behavior_integration_authorized": false,
		"recommended_next_boundary": "interpret_cost_loss_frontier_and_cap3_feasibility_before_any_sampler_port",
	}


func _c3fq_new_strategy(
	strategy_id: String,
	order_invariant: bool,
	negative_control: bool,
	uses_depth_one_screen: bool,
) -> Dictionary:
	return {
		"strategy_id": strategy_id,
		"order_invariant": order_invariant,
		"negative_control": negative_control,
		"uses_depth_one_screen": uses_depth_one_screen,
		"cases": 0,
		"preserves_deep_optimum_cases": 0,
		"loses_deep_optimum_cases": 0,
		"promoted_switches_sum": 0,
		"promoted_switches_max": 0,
		"cases_promoting_one_switch": 0,
		"cases_promoting_two_switches": 0,
		"cases_promoting_more_than_two_switches": 0,
		"cap3_with_one_move_violation_cases": 0,
		"screening_simulations_sum": 0,
		"depth_two_simulations_sum": 0,
		"total_simulations_sum": 0,
	}


func _c3fq_record_strategy(
	strategy_reports: Dictionary,
	strategy_id: String,
	promoted_ids: Array[String],
	deep_best_ids: Array[String],
	screen_cost: int,
	depth_two_simulations: Dictionary,
	_immediate_tie_size: int,
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
		report["cap3_with_one_move_violation_cases"] = int(report.get("cap3_with_one_move_violation_cases", 0)) + 1
	var depth_two_cost := _c3fq_sum_simulations(promoted_ids, depth_two_simulations)
	report["screening_simulations_sum"] = int(report.get("screening_simulations_sum", 0)) + screen_cost
	report["depth_two_simulations_sum"] = int(report.get("depth_two_simulations_sum", 0)) + depth_two_cost
	report["total_simulations_sum"] = int(report.get("total_simulations_sum", 0)) + screen_cost + depth_two_cost
	strategy_reports[strategy_id] = report


func _c3fq_promote_by_margin(
	candidate_ids: Array[String],
	depth_one_scores: Dictionary,
	margin: int,
) -> Array[String]:
	var best_score := -2147483648
	for candidate_id in candidate_ids:
		best_score = maxi(best_score, int(depth_one_scores.get(candidate_id, -2147483648)))
	var promoted: Array[String] = []
	for candidate_id in candidate_ids:
		if int(depth_one_scores.get(candidate_id, -2147483648)) >= best_score - margin:
			promoted.append(candidate_id)
	promoted.sort()
	return promoted


func _c3fq_promote_gap_full_fallback(
	candidate_ids: Array[String],
	depth_one_scores: Dictionary,
	gap_threshold: int,
) -> Array[String]:
	var best_tier := _c3fq_promote_by_margin(candidate_ids, depth_one_scores, 0)
	if best_tier.size() > 1:
		var full := candidate_ids.duplicate()
		full.sort()
		return full
	var best_score := int(depth_one_scores.get(best_tier[0], -2147483648))
	var second_score := -2147483648
	for candidate_id in candidate_ids:
		if best_tier.has(candidate_id):
			continue
		second_score = maxi(second_score, int(depth_one_scores.get(candidate_id, -2147483648)))
	if second_score > -2147483648 and best_score - second_score <= gap_threshold:
		var full := candidate_ids.duplicate()
		full.sort()
		return full
	return best_tier


func _c3fq_sum_simulations(candidate_ids: Array[String], simulations: Dictionary) -> int:
	var total := 0
	for candidate_id in candidate_ids:
		total += int(simulations.get(candidate_id, 0))
	return total


func _c3fq_total_candidate_count(cases: Array) -> int:
	var total := 0
	for raw_case in cases:
		var case := raw_case as Dictionary
		total += (case.get("immediate_tied_switch_ids", []) as Array).size()
	return total


func _c3fq_cost_loss_frontier(strategy_reports: Dictionary) -> Array[String]:
	var candidate_ids: Array[String] = []
	for raw_id in strategy_reports.keys():
		var strategy_id := String(raw_id)
		var report := strategy_reports.get(strategy_id, {}) as Dictionary
		if bool(report.get("negative_control", false)):
			continue
		candidate_ids.append(strategy_id)
	candidate_ids.sort()
	var frontier: Array[String] = []
	for strategy_id in candidate_ids:
		var candidate := strategy_reports.get(strategy_id, {}) as Dictionary
		var candidate_loss := int(candidate.get("loses_deep_optimum_cases", 0))
		var candidate_cost := int(candidate.get("total_simulations_sum", 0))
		var dominated := false
		for other_id in candidate_ids:
			if other_id == strategy_id:
				continue
			var other := strategy_reports.get(other_id, {}) as Dictionary
			var other_loss := int(other.get("loses_deep_optimum_cases", 0))
			var other_cost := int(other.get("total_simulations_sum", 0))
			if (
				other_loss <= candidate_loss
				and other_cost <= candidate_cost
				and (other_loss < candidate_loss or other_cost < candidate_cost)
			):
				dominated = true
				break
		if not dominated:
			frontier.append(strategy_id)
	frontier.sort()
	return frontier
