class_name TrainerRosterSearchTieDepthPreservationAuditTestSuite
extends TrainerRosterSearchSwitchSamplingStrategyComparisonAuditTestSuite

# C3f-p is deliberately TEST/AUDIT-ONLY. It does not modify search, action-space,
# budgets, brains, switching scores, roster value, Pareto, or behavior. It takes
# real contexts where TrainerStrategicSwitchEvaluatorV2 has multiple equal maxima,
# then evaluates every tied root switch independently through the existing
# TrainerMultiTurnSearch depth-2 implementation.

const AUDIT_ID_C3FP := "c3f_p_switch_tie_depth_preservation_audit_v1"
const SAMPLE_PER_TIE_SIZE_PER_MODE := 6
const EXPECTED_TIE_SIZES := [2, 3, 4, 5]
const EXPECTED_SELECTED_CASES := 48
const EXPECTED_ROOT_EVALUATIONS := 168


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_switch_tie_depth_preservation()


func _test_switch_tie_depth_preservation() -> void:
	var report_a := _build_c3fp_report()
	var report_b := _build_c3fp_report()
	var selected_by_size := report_a.get("selected_case_histogram_by_tie_size", {}) as Dictionary
	var selected_by_mode := report_a.get("selected_case_histogram_by_evidence_mode", {}) as Dictionary

	_check.call(
		"search_tie_depth_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FP,
	)
	_check.call(
		"search_tie_depth_uses_existing_production_models",
		String(report_a.get("search_model_id", "")) == TrainerMultiTurnSearch.SEARCH_MODEL_ID
		and String(report_a.get("action_sampling_model", "")) == TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL
		and String(report_a.get("switching_model_id", "")) == TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
	)
	_check.call(
		"search_tie_depth_uses_c3fm_population_geometry",
		int(report_a.get("eligible_species", 0)) == EXPECTED_ELIGIBLE_SPECIES
		and int(report_a.get("population_scenarios", 0)) == EXPECTED_SCENARIOS
		and int(report_a.get("population_tie_cases", 0)) == 306,
	)
	_check.call(
		"search_tie_depth_sample_is_stratified_and_complete",
		int(report_a.get("selected_cases", 0)) == EXPECTED_SELECTED_CASES
		and int(selected_by_size.get("2", 0)) == 12
		and int(selected_by_size.get("3", 0)) == 12
		and int(selected_by_size.get("4", 0)) == 12
		and int(selected_by_size.get("5", 0)) == 12
		and int(selected_by_mode.get("species_fallback", 0)) == 24
		and int(selected_by_mode.get("revealed_damaging_move", 0)) == 24,
	)
	_check.call(
		"search_tie_depth_root_evaluation_accounting",
		int(report_a.get("root_search_evaluations", 0)) == EXPECTED_ROOT_EVALUATIONS,
	)
	_check.call(
		"search_tie_depth_has_no_context_or_search_failures",
		int(report_a.get("context_build_failures", -1)) == 0
		and int(report_a.get("search_result_failures", -1)) == 0,
	)
	_check.call(
		"search_tie_depth_completes_requested_depth",
		int(report_a.get("depth_two_incomplete_evaluations", -1)) == 0
		and int(report_a.get("budget_exhausted_evaluations", -1)) == 0
		and int(report_a.get("world_coverage_failures", -1)) == 0,
	)
	_check.call(
		"search_tie_depth_preserves_existing_budget",
		int(report_a.get("depth_turns", -1)) == 2
		and int(report_a.get("max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP
		and int(report_a.get("max_worlds", -1)) == 4
		and int(report_a.get("max_simulations", -1)) == 220,
	)
	_check.call(
		"search_tie_depth_preserves_move_switch_sampling_boundary",
		String(report_a.get("action_sampling_model", "")) == "kind_stratified_round_robin_v1"
		and bool(report_a.get("production_sampler_unchanged", false))
		and bool(report_a.get("move_switch_diversity_boundary_preserved", false)),
	)
	_check.call(
		"search_tie_depth_all_selected_cases_accounted",
		int(report_a.get("depth_divergence_cases", 0))
		+ int(report_a.get("depth_all_still_tied_cases", 0))
		== EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_tie_depth_deep_best_partition_accounted",
		int(report_a.get("depth_unique_best_cases", 0))
		+ int(report_a.get("depth_multiple_best_cases", 0))
		== EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_tie_depth_slot_preservation_accounting",
		int(report_a.get("lexical_one_slot_preserves_deep_optimum_cases", 0))
		+ int(report_a.get("lexical_one_slot_loses_deep_optimum_cases", 0))
		== EXPECTED_SELECTED_CASES
		and int(report_a.get("lexical_two_slot_preserves_deep_optimum_cases", 0))
		+ int(report_a.get("lexical_two_slot_loses_deep_optimum_cases", 0))
		== EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_tie_depth_full_tier_never_drops_observed_deep_optimum",
		int(report_a.get("full_top_tier_loses_deep_optimum_cases", -1)) == 0
		and int(report_a.get("full_top_tier_preserves_deep_optimum_cases", 0)) == EXPECTED_SELECTED_CASES,
	)
	_check.call(
		"search_tie_depth_cost_accounting_is_monotonic",
		int(report_a.get("full_tier_simulations_sum", 0)) >= int(report_a.get("two_slot_simulations_sum", 0))
		and int(report_a.get("two_slot_simulations_sum", 0)) >= int(report_a.get("one_slot_simulations_sum", 0))
		and int(report_a.get("full_tier_root_evaluations", 0)) == EXPECTED_ROOT_EVALUATIONS
		and int(report_a.get("one_slot_root_evaluations", 0)) == EXPECTED_SELECTED_CASES
		and int(report_a.get("two_slot_root_evaluations", 0)) == EXPECTED_SELECTED_CASES * 2,
	)
	_check.call(
		"search_tie_depth_public_context_only",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("live_rng_used", true)),
	)
	_check.call(
		"search_tie_depth_profile_is_held_constant_not_pre_tiebreak",
		String(report_a.get("search_profile_id", "")) == "balanced"
		and not bool(report_a.get("profile_used_as_presearch_tiebreak", true))
		and not bool(report_a.get("profile_varied_across_tied_candidates", true)),
	)
	_check.call(
		"search_tie_depth_keeps_pareto_and_roster_value_out",
		not bool(report_a.get("frontier_used_for_depth_selection", true))
		and not bool(report_a.get("roster_value_integrated", true)),
	)
	_check.call(
		"search_tie_depth_keeps_campaign_policies_out",
		not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true)),
	)
	_check.call(
		"search_tie_depth_does_not_select_production_policy",
		report_a.get("selected_sampler_strategy_id", "sentinel") == null
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("search_tie_depth_report_deterministic", report_a == report_b)
	_check.call(
		"search_tie_depth_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH SWITCH TIE DEPTH PRESERVATION AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fp_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FP, "eligible_species": 0}

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
	var depth_budget := TrainerSearchBudget.depth_two_default()
	var search := TrainerMultiTurnSearch.new(catalog, neutral_profile, depth_budget)

	var population_scenarios := 0
	var population_tie_cases := 0
	var population_tie_histogram: Dictionary = {}
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
				if best_ids.size() < 2:
					continue
				population_tie_cases += 1
				_c3fm_histogram_increment(population_tie_histogram, best_ids.size())
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
	var stratum_population_counts: Dictionary = {}
	for tie_size in EXPECTED_TIE_SIZES:
		for raw_mode in EVIDENCE_MODES:
			var mode := String(raw_mode)
			var key := _c3fp_stratum_key(int(tie_size), mode)
			var records := strata.get(key, []) as Array
			stratum_population_counts[key] = records.size()
			for record in _c3fp_spaced_sample(records, SAMPLE_PER_TIE_SIZE_PER_MODE):
				selected_records.append((record as Dictionary).duplicate(false))

	var selected_by_size: Dictionary = {}
	var selected_by_mode: Dictionary = {}
	var deep_best_size_histogram: Dictionary = {}
	var depth_divergence_cases := 0
	var depth_all_still_tied_cases := 0
	var depth_unique_best_cases := 0
	var depth_multiple_best_cases := 0
	var arbitrary_single_representative_not_proven_safe_cases := 0
	var lexical_one_slot_preserves := 0
	var lexical_one_slot_loses := 0
	var lexical_two_slot_preserves := 0
	var lexical_two_slot_loses := 0
	var full_top_tier_preserves := 0
	var full_top_tier_loses := 0
	var two_slot_recovers_one_slot_loss_cases := 0
	var root_search_evaluations := 0
	var search_result_failures := 0
	var depth_two_incomplete_evaluations := 0
	var budget_exhausted_evaluations := 0
	var world_coverage_failures := 0
	var full_tier_simulations_sum := 0
	var one_slot_simulations_sum := 0
	var two_slot_simulations_sum := 0
	var score_spread_sum := 0
	var score_spread_max := 0
	var mode_summary: Dictionary = {}
	var tie_size_summary: Dictionary = {}
	for raw_mode in EVIDENCE_MODES:
		mode_summary[String(raw_mode)] = _c3fp_new_summary()
	for tie_size in EXPECTED_TIE_SIZES:
		tie_size_summary[String.num_int64(int(tie_size))] = _c3fp_new_summary()
	var divergence_examples: Array[Dictionary] = []

	for record in selected_records:
		var context := record.get("context") as TrainerDecisionContext
		var best_ids := _c3fm_string_array(record.get("best_ids", []) as Array)
		var mode := String(record.get("mode", ""))
		_c3fm_histogram_increment(selected_by_size, best_ids.size())
		selected_by_mode[mode] = int(selected_by_mode.get(mode, 0)) + 1

		var depth_scores: Dictionary = {}
		var simulations_by_id: Dictionary = {}
		var case_valid := true
		for candidate_id in best_ids:
			var action := _c3fp_find_switch_action(context, candidate_id)
			if action == null:
				search_result_failures += 1
				case_valid = false
				continue
			var result := search.evaluate(context, action)
			root_search_evaluations += 1
			if result.is_empty() or not result.has("metadata"):
				search_result_failures += 1
				case_valid = false
				continue
			var metadata := result.get("metadata", {}) as Dictionary
			if String(metadata.get("search_model", "")) != TrainerMultiTurnSearch.SEARCH_MODEL_ID:
				search_result_failures += 1
				case_valid = false
			if int(metadata.get("fully_completed_depth", 0)) != 2:
				depth_two_incomplete_evaluations += 1
				case_valid = false
			if bool(metadata.get("budget_exhausted", false)):
				budget_exhausted_evaluations += 1
				case_valid = false
			if int(metadata.get("world_coverage_basis_points", 0)) != 10000:
				world_coverage_failures += 1
				case_valid = false
			depth_scores[candidate_id] = int(result.get("score", 0))
			simulations_by_id[candidate_id] = int(metadata.get("simulations_used", 0))

		if not case_valid or depth_scores.size() != best_ids.size():
			continue

		var deep_best_score := -2147483648
		var deep_worst_score := 2147483647
		var distinct_scores: Dictionary = {}
		for candidate_id in best_ids:
			var score := int(depth_scores.get(candidate_id, 0))
			deep_best_score = maxi(deep_best_score, score)
			deep_worst_score = mini(deep_worst_score, score)
			distinct_scores[String.num_int64(score)] = true
		var deep_best_ids: Array[String] = []
		for candidate_id in best_ids:
			if int(depth_scores.get(candidate_id, 0)) == deep_best_score:
				deep_best_ids.append(candidate_id)
		deep_best_ids.sort()
		_c3fm_histogram_increment(deep_best_size_histogram, deep_best_ids.size())
		var diverged := distinct_scores.size() > 1
		if diverged:
			depth_divergence_cases += 1
			arbitrary_single_representative_not_proven_safe_cases += 1
		else:
			depth_all_still_tied_cases += 1
		if deep_best_ids.size() == 1:
			depth_unique_best_cases += 1
		else:
			depth_multiple_best_cases += 1

		var lexical_one: Array[String] = [best_ids[0]]
		var lexical_two: Array[String] = []
		for index in range(mini(2, best_ids.size())):
			lexical_two.append(best_ids[index])
		var one_preserves := _c3fo_intersects(lexical_one, deep_best_ids)
		var two_preserves := _c3fo_intersects(lexical_two, deep_best_ids)
		if one_preserves:
			lexical_one_slot_preserves += 1
		else:
			lexical_one_slot_loses += 1
		if two_preserves:
			lexical_two_slot_preserves += 1
		else:
			lexical_two_slot_loses += 1
		if not one_preserves and two_preserves:
			two_slot_recovers_one_slot_loss_cases += 1
		if _c3fo_intersects(best_ids, deep_best_ids):
			full_top_tier_preserves += 1
		else:
			full_top_tier_loses += 1

		var case_full_simulations := 0
		for candidate_id in best_ids:
			case_full_simulations += int(simulations_by_id.get(candidate_id, 0))
		full_tier_simulations_sum += case_full_simulations
		one_slot_simulations_sum += int(simulations_by_id.get(best_ids[0], 0))
		for index in range(mini(2, best_ids.size())):
			two_slot_simulations_sum += int(simulations_by_id.get(best_ids[index], 0))
		var spread := deep_best_score - deep_worst_score
		score_spread_sum += spread
		score_spread_max = maxi(score_spread_max, spread)

		var mode_record := mode_summary.get(mode, {}) as Dictionary
		_c3fp_record_summary(mode_record, diverged, one_preserves, two_preserves, spread)
		mode_summary[mode] = mode_record
		var size_key := String.num_int64(best_ids.size())
		var size_record := tie_size_summary.get(size_key, {}) as Dictionary
		_c3fp_record_summary(size_record, diverged, one_preserves, two_preserves, spread)
		tie_size_summary[size_key] = size_record

		if diverged and divergence_examples.size() < 12:
			divergence_examples.append({
				"anchor": int(record.get("anchor", -1)),
				"evidence_mode": mode,
				"opponent_species_id": String(record.get("opponent_species_id", "")),
				"immediate_tied_switch_ids": best_ids.duplicate(),
				"depth_two_scores": depth_scores.duplicate(true),
				"depth_two_best_switch_ids": deep_best_ids.duplicate(),
				"lexical_one_slot_id": best_ids[0],
				"lexical_one_slot_loses_deep_optimum": not one_preserves,
				"lexical_two_slot_ids": lexical_two.duplicate(),
				"lexical_two_slot_loses_deep_optimum": not two_preserves,
				"score_spread": spread,
				"simulations_by_switch_id": simulations_by_id.duplicate(true),
			})

	_catalog = fixture_catalog
	var valid_selected_cases := depth_divergence_cases + depth_all_still_tied_cases
	var mean_spread := score_spread_sum / valid_selected_cases if valid_selected_cases > 0 else 0
	return {
		"audit_id": AUDIT_ID_C3FP,
		"dataset_probe_id": TrainerRosterStructuralRealDataAuditTestSuite.PROBE_ID,
		"eligible_species": members.size(),
		"sampled_rosters": sampled_rosters,
		"population_scenarios": population_scenarios,
		"population_tie_cases": population_tie_cases,
		"population_tie_histogram": population_tie_histogram,
		"stratum_population_counts": stratum_population_counts,
		"sample_per_tie_size_per_mode": SAMPLE_PER_TIE_SIZE_PER_MODE,
		"selected_cases": selected_records.size(),
		"selected_case_histogram_by_tie_size": selected_by_size,
		"selected_case_histogram_by_evidence_mode": selected_by_mode,
		"root_search_evaluations": root_search_evaluations,
		"search_result_failures": search_result_failures,
		"depth_two_incomplete_evaluations": depth_two_incomplete_evaluations,
		"budget_exhausted_evaluations": budget_exhausted_evaluations,
		"world_coverage_failures": world_coverage_failures,
		"context_build_failures": context_build_failures,
		"depth_divergence_cases": depth_divergence_cases,
		"depth_all_still_tied_cases": depth_all_still_tied_cases,
		"depth_unique_best_cases": depth_unique_best_cases,
		"depth_multiple_best_cases": depth_multiple_best_cases,
		"deep_best_set_size_histogram": deep_best_size_histogram,
		"arbitrary_single_representative_not_proven_safe_cases": arbitrary_single_representative_not_proven_safe_cases,
		"lexical_one_slot_preserves_deep_optimum_cases": lexical_one_slot_preserves,
		"lexical_one_slot_loses_deep_optimum_cases": lexical_one_slot_loses,
		"lexical_two_slot_preserves_deep_optimum_cases": lexical_two_slot_preserves,
		"lexical_two_slot_loses_deep_optimum_cases": lexical_two_slot_loses,
		"two_slot_recovers_one_slot_loss_cases": two_slot_recovers_one_slot_loss_cases,
		"full_top_tier_preserves_deep_optimum_cases": full_top_tier_preserves,
		"full_top_tier_loses_deep_optimum_cases": full_top_tier_loses,
		"score_spread_sum": score_spread_sum,
		"score_spread_mean": mean_spread,
		"score_spread_max": score_spread_max,
		"mode_summary": mode_summary,
		"tie_size_summary": tie_size_summary,
		"divergence_examples": divergence_examples,
		"full_tier_root_evaluations": EXPECTED_ROOT_EVALUATIONS,
		"one_slot_root_evaluations": selected_records.size(),
		"two_slot_root_evaluations": selected_records.size() * 2,
		"full_tier_simulations_sum": full_tier_simulations_sum,
		"one_slot_simulations_sum": one_slot_simulations_sum,
		"two_slot_simulations_sum": two_slot_simulations_sum,
		"full_tier_extra_simulations_vs_one_slot": full_tier_simulations_sum - one_slot_simulations_sum,
		"full_tier_extra_simulations_vs_two_slot": full_tier_simulations_sum - two_slot_simulations_sum,
		"full_tier_simulation_multiplier_bp_vs_one_slot": (
			full_tier_simulations_sum * 10000 / one_slot_simulations_sum
			if one_slot_simulations_sum > 0 else 0
		),
		"full_tier_simulation_multiplier_bp_vs_two_slot": (
			full_tier_simulations_sum * 10000 / two_slot_simulations_sum
			if two_slot_simulations_sum > 0 else 0
		),
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"action_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"switching_model_id": TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
		"depth_turns": depth_budget.depth_turns,
		"max_worlds": depth_budget.max_worlds,
		"max_simulations": depth_budget.max_simulations,
		"max_actions_per_side": depth_budget.max_actions_per_side,
		"production_sampler_unchanged": true,
		"move_switch_diversity_boundary_preserved": true,
		"nonempty_hidden_belief_cases": nonempty_hidden_belief_cases,
		"nonempty_memory_event_cases": nonempty_memory_event_cases,
		"nonempty_campaign_snapshot_cases": nonempty_campaign_snapshot_cases,
		"live_rng_used": false,
		"deterministic_synthetic_search_worlds_used": true,
		"search_profile_id": String(neutral_profile.profile_id),
		"profile_used_as_presearch_tiebreak": false,
		"profile_varied_across_tied_candidates": false,
		"frontier_used_for_depth_selection": false,
		"roster_value_integrated": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"campaign_policy_used": false,
		"selected_sampler_strategy_id": null,
		"search_sampling_redesign_authorized": false,
		"behavior_integration_authorized": false,
		"recommended_next_boundary": "interpret_depth_divergence_and_cost_before_any_sampler_port",
	}


func _c3fp_stratum_key(tie_size: int, mode: String) -> String:
	return "%d|%s" % [tie_size, mode]


func _c3fp_spaced_sample(records: Array, count: int) -> Array:
	var out: Array = []
	if records.is_empty() or count <= 0:
		return out
	var take := mini(count, records.size())
	for index in range(take):
		var source_index := index * records.size() / take
		out.append(records[source_index])
	return out


func _c3fp_find_switch_action(
	context: TrainerDecisionContext,
	candidate_id: String,
) -> BattleAction:
	if context == null:
		return null
	for action in context.legal_actions:
		if (
			action != null
			and action.action_type == BattleAction.SWITCH
			and String(action.switch_instance_id) == candidate_id
		):
			return BattleAction.from_dict(action.to_dict())
	return null


func _c3fp_new_summary() -> Dictionary:
	return {
		"cases": 0,
		"divergence_cases": 0,
		"all_still_tied_cases": 0,
		"one_slot_preserves": 0,
		"one_slot_loses": 0,
		"two_slot_preserves": 0,
		"two_slot_loses": 0,
		"score_spread_sum": 0,
		"score_spread_max": 0,
	}


func _c3fp_record_summary(
	report: Dictionary,
	diverged: bool,
	one_preserves: bool,
	two_preserves: bool,
	spread: int,
) -> void:
	report["cases"] = int(report.get("cases", 0)) + 1
	if diverged:
		report["divergence_cases"] = int(report.get("divergence_cases", 0)) + 1
	else:
		report["all_still_tied_cases"] = int(report.get("all_still_tied_cases", 0)) + 1
	if one_preserves:
		report["one_slot_preserves"] = int(report.get("one_slot_preserves", 0)) + 1
	else:
		report["one_slot_loses"] = int(report.get("one_slot_loses", 0)) + 1
	if two_preserves:
		report["two_slot_preserves"] = int(report.get("two_slot_preserves", 0)) + 1
	else:
		report["two_slot_loses"] = int(report.get("two_slot_loses", 0)) + 1
	report["score_spread_sum"] = int(report.get("score_spread_sum", 0)) + spread
	report["score_spread_max"] = maxi(int(report.get("score_spread_max", 0)), spread)
