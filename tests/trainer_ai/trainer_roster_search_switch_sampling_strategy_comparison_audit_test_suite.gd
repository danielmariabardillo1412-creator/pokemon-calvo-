class_name TrainerRosterSearchSwitchSamplingStrategyComparisonAuditTestSuite
extends TrainerRosterSearchSwitchSamplingBoundaryAuditTestSuite

# C3f-o is deliberately TEST/AUDIT-ONLY. It compares bounded switch-sampling
# strategies without changing TrainerMultiTurnSearch, TrainerActionSpace, budgets,
# brains, scores, legal actions, Pareto production, or behavior. Candidate outputs
# are shadow evidence only and no strategy is selected for production here.

const AUDIT_ID_C3FO := "c3f_o_switch_sampling_strategy_comparison_audit_v1"
const STRATEGY_LEXICAL_CONTROL := "lexical_id_one_switch_negative_control"
const STRATEGY_PARETO_CONTROL := "pareto_frontier_one_switch_negative_control"
const STRATEGY_CONTEXTUAL_ONE := "contextual_switch_score_one_switch_candidate"
const STRATEGY_CONTEXTUAL_TWO := "contextual_switch_score_two_switch_candidate"
const EXPECTED_DEFAULT_CAP := 3
const MIN_MOVE_SLOTS_FOR_DIVERSITY := 1
const EXPECTED_STRATEGY_COUNT := 4


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_switch_sampling_strategy_comparison()


func _test_switch_sampling_strategy_comparison() -> void:
	var report_a := _build_c3fo_report()
	var report_b := _build_c3fo_report()
	var strategies := report_a.get("strategy_reports", {}) as Dictionary
	var lexical := strategies.get(STRATEGY_LEXICAL_CONTROL, {}) as Dictionary
	var pareto := strategies.get(STRATEGY_PARETO_CONTROL, {}) as Dictionary
	var contextual_one := strategies.get(STRATEGY_CONTEXTUAL_ONE, {}) as Dictionary
	var contextual_two := strategies.get(STRATEGY_CONTEXTUAL_TWO, {}) as Dictionary
	var scenarios := int(report_a.get("scenarios", 0))

	_check.call(
		"search_sampling_strategy_comparison_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FO,
	)
	_check.call(
		"search_sampling_strategy_comparison_uses_existing_models",
		String(report_a.get("search_model_id", "")) == TrainerMultiTurnSearch.SEARCH_MODEL_ID
		and String(report_a.get("current_sampling_model_id", "")) == TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL
		and String(report_a.get("switching_model_id", "")) == TrainerStrategicSwitchEvaluatorV2.MODEL_ID
		and String(report_a.get("frontier_model_id", "")) == TrainerRosterParetoFrontier.MODEL_ID,
	)
	_check.call(
		"search_sampling_strategy_comparison_uses_c3fm_matrix",
		int(report_a.get("eligible_species", 0)) == EXPECTED_ELIGIBLE_SPECIES
		and int(report_a.get("sampled_rosters", 0)) == EXPECTED_ROSTERS
		and int(report_a.get("scenarios", 0)) == EXPECTED_SCENARIOS
		and int(report_a.get("switch_candidate_occurrences", 0))
		== EXPECTED_SCENARIOS * EXPECTED_SWITCH_CANDIDATES_PER_SCENARIO,
	)
	_check.call(
		"search_sampling_strategy_comparison_keeps_default_cap",
		int(report_a.get("bounded_action_cap", -1)) == EXPECTED_DEFAULT_CAP
		and int(report_a.get("minimum_move_slots_for_diversity", -1)) == MIN_MOVE_SLOTS_FOR_DIVERSITY,
	)
	_check.call(
		"search_sampling_strategy_comparison_public_legal_context_only",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("rng_used", true)),
	)
	_check.call(
		"search_sampling_strategy_comparison_profile_is_neutral_and_explicit",
		int(report_a.get("neutral_switch_weight_bp", -1)) == 10000
		and not bool(report_a.get("trainer_profile_semantic_preference_used", true)),
	)
	_check.call(
		"search_sampling_strategy_comparison_has_four_declared_strategies",
		strategies.size() == EXPECTED_STRATEGY_COUNT,
	)
	_check.call(
		"search_sampling_strategy_comparison_all_strategies_order_invariant",
		int(report_a.get("reorder_probe_cases", 0)) == scenarios * EXPECTED_STRATEGY_COUNT
		and int(report_a.get("reorder_mismatch_cases", -1)) == 0,
	)
	_check.call(
		"search_sampling_strategy_comparison_all_strategies_are_bounded",
		int(report_a.get("bounded_size_violation_cases", -1)) == 0,
	)
	_check.call(
		"search_sampling_strategy_comparison_explicit_move_switch_diversity",
		int(report_a.get("diversity_failure_cases", -1)) == 0
		and int(contextual_one.get("move_slots", 0)) == 2
		and int(contextual_one.get("switch_slots", 0)) == 1
		and int(contextual_two.get("move_slots", 0)) == 1
		and int(contextual_two.get("switch_slots", 0)) == 2,
	)
	_check.call(
		"search_sampling_contextual_one_preserves_some_optimum_everywhere",
		int(contextual_one.get("any_optimum_preserved_cases", -1)) == scenarios
		and int(contextual_one.get("loses_all_optima_cases", -1)) == 0,
	)
	_check.call(
		"search_sampling_contextual_two_preserves_some_optimum_everywhere",
		int(contextual_two.get("any_optimum_preserved_cases", -1)) == scenarios
		and int(contextual_two.get("loses_all_optima_cases", -1)) == 0,
	)
	_check.call(
		"search_sampling_two_switch_slots_preserve_more_complete_optimal_sets",
		int(contextual_two.get("all_optima_preserved_cases", 0))
		> int(contextual_one.get("all_optima_preserved_cases", 0)),
	)
	_check.call(
		"search_sampling_cap_three_still_has_multi_optimum_overflow",
		int(contextual_two.get("top_set_overflow_cases", 0)) > 0
		and int(report_a.get("contexts_requiring_cap_above_three_for_full_optimal_set", 0)) > 0
		and int(report_a.get("required_total_cap_max", 0)) > EXPECTED_DEFAULT_CAP,
	)
	_check.call(
		"search_sampling_contextual_cutoff_ties_are_explicit",
		int(contextual_one.get("lexical_equal_score_cutoff_cases", 0)) > 0
		and bool(contextual_one.get("lexical_only_within_equal_score_ties", false))
		and not bool(contextual_one.get("lexical_semantic_preference", true)),
	)
	_check.call(
		"search_sampling_lexical_control_is_rejected_as_semantic_policy",
		bool(lexical.get("negative_control", false))
		and bool(lexical.get("lexical_semantic_preference", false))
		and not bool(lexical.get("production_ready", true)),
	)
	_check.call(
		"search_sampling_pareto_control_reproduces_hard_pruning_risk",
		bool(pareto.get("negative_control", false))
		and bool(pareto.get("frontier_hard_filter", false))
		and int(pareto.get("loses_all_optima_cases", 0)) > 0
		and not bool(report_a.get("frontier_hard_pruning_authorized", true)),
	)
	_check.call(
		"search_sampling_contextual_candidate_can_retain_dominated_counter",
		int(contextual_one.get("selected_dominated_cases", 0)) > 0
		and not bool(contextual_one.get("frontier_hard_filter", true)),
	)
	_check.call(
		"search_sampling_full_optimal_set_requirement_is_accounted",
		int(report_a.get("cap_three_one_move_preserves_full_optimal_set_cases", 0))
		+ int(report_a.get("cap_three_one_move_cannot_preserve_full_optimal_set_cases", 0))
		== scenarios,
	)
	_check.call(
		"search_sampling_comparison_does_not_select_production_strategy",
		report_a.get("selected_strategy_id", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call(
		"search_sampling_comparison_keeps_forbidden_policy_out",
		not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true))
		and not bool(report_a.get("roster_value_integrated", true)),
	)
	_check.call("search_sampling_strategy_comparison_report_deterministic", report_a == report_b)
	_check.call(
		"search_sampling_strategy_comparison_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH SWITCH SAMPLING STRATEGY COMPARISON AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fo_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FO, "eligible_species": 0}

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
	var strategy_specs: Array[Dictionary] = [
		{
			"strategy_id": STRATEGY_LEXICAL_CONTROL,
			"selector": "lexical",
			"switch_slots": 1,
			"context_aware": false,
			"frontier_hard_filter": false,
			"negative_control": true,
			"lexical_semantic_preference": true,
			"lexical_only_within_equal_score_ties": false,
		},
		{
			"strategy_id": STRATEGY_PARETO_CONTROL,
			"selector": "pareto",
			"switch_slots": 1,
			"context_aware": false,
			"frontier_hard_filter": true,
			"negative_control": true,
			"lexical_semantic_preference": true,
			"lexical_only_within_equal_score_ties": false,
		},
		{
			"strategy_id": STRATEGY_CONTEXTUAL_ONE,
			"selector": "contextual",
			"switch_slots": 1,
			"context_aware": true,
			"frontier_hard_filter": false,
			"negative_control": false,
			"lexical_semantic_preference": false,
			"lexical_only_within_equal_score_ties": true,
		},
		{
			"strategy_id": STRATEGY_CONTEXTUAL_TWO,
			"selector": "contextual",
			"switch_slots": 2,
			"context_aware": true,
			"frontier_hard_filter": false,
			"negative_control": false,
			"lexical_semantic_preference": false,
			"lexical_only_within_equal_score_ties": true,
		},
	]
	var strategy_reports: Dictionary = {}
	for spec in strategy_specs:
		var strategy_id := String(spec.get("strategy_id", ""))
		strategy_reports[strategy_id] = _c3fo_new_strategy_report(spec)

	var sampled_rosters := 0
	var scenarios := 0
	var switch_candidate_occurrences := 0
	var context_build_failures := 0
	var contract_validation_failures := 0
	var frontier_validation_failures := 0
	var nonempty_hidden_belief_cases := 0
	var nonempty_memory_event_cases := 0
	var nonempty_campaign_snapshot_cases := 0
	var reorder_probe_cases := 0
	var reorder_mismatch_cases := 0
	var bounded_size_violation_cases := 0
	var diversity_failure_cases := 0
	var best_set_size_histogram: Dictionary = {}
	var required_total_cap_histogram: Dictionary = {}
	var required_total_cap_max := 0
	var cap_three_one_move_preserves_full_optimal_set_cases := 0
	var cap_three_one_move_cannot_preserve_full_optimal_set_cases := 0
	var overflow_examples: Array[Dictionary] = []

	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])
	for anchor in range(0, members.size(), ROSTER_SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var contract := contract_builder.build_contract(degraded)
		var frontier := frontier_evaluator.evaluate(contract)
		sampled_rosters += 1
		if (
			String(contract.get("model_id", "")) != TrainerRosterComponentFirstContract.MODEL_ID
			or int(contract.get("member_count", -1)) != degraded.size()
		):
			contract_validation_failures += 1
		if (
			String(frontier.get("model_id", "")) != TrainerRosterParetoFrontier.MODEL_ID
			or not bool(frontier.get("input_contract_valid", false))
		):
			frontier_validation_failures += 1

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

				scenarios += 1
				var scores := outcome.get("candidate_scores", {}) as Dictionary
				var best_ids := _c3fm_string_array(outcome.get("best_switch_ids", []) as Array)
				var candidate_ids := _c3fo_sorted_candidate_ids(scores)
				var reversed_ids: Array[String] = candidate_ids.duplicate()
				reversed_ids.reverse()
				switch_candidate_occurrences += candidate_ids.size()
				_c3fm_histogram_increment(best_set_size_histogram, best_ids.size())
				var required_total_cap := MIN_MOVE_SLOTS_FOR_DIVERSITY + best_ids.size()
				_c3fm_histogram_increment(required_total_cap_histogram, required_total_cap)
				required_total_cap_max = maxi(required_total_cap_max, required_total_cap)
				if required_total_cap <= EXPECTED_DEFAULT_CAP:
					cap_three_one_move_preserves_full_optimal_set_cases += 1
				else:
					cap_three_one_move_cannot_preserve_full_optimal_set_cases += 1
					if overflow_examples.size() < 12:
						overflow_examples.append({
							"anchor": anchor,
							"evidence_mode": mode,
							"opponent_species_id": String(opponent.get("species_id", "")),
							"best_switch_ids": best_ids.duplicate(),
							"best_set_size": best_ids.size(),
							"required_total_cap_with_one_move": required_total_cap,
						})

				for spec in strategy_specs:
					var strategy_id := String(spec.get("strategy_id", ""))
					var selected := _c3fo_select_strategy(
						spec,
						candidate_ids,
						scores,
						frontier_ids,
					)
					var reversed_selected := _c3fo_select_strategy(
						spec,
						reversed_ids,
						scores,
						frontier_ids,
					)
					var strategy_report := strategy_reports.get(strategy_id, {}) as Dictionary
					_c3fo_record_strategy_case(
						strategy_report,
						selected,
						reversed_selected,
						best_ids,
						candidate_ids,
						scores,
						dominated_ids,
					)
					strategy_reports[strategy_id] = strategy_report
					reorder_probe_cases += 1
					if selected != reversed_selected:
						reorder_mismatch_cases += 1
					var switch_slots := int(spec.get("switch_slots", 0))
					var move_slots := EXPECTED_DEFAULT_CAP - switch_slots
					if selected.size() > switch_slots or selected.size() + move_slots > EXPECTED_DEFAULT_CAP:
						bounded_size_violation_cases += 1
					if selected.is_empty() or move_slots < MIN_MOVE_SLOTS_FOR_DIVERSITY:
						diversity_failure_cases += 1

	_catalog = fixture_catalog
	var contextual_one := strategy_reports.get(STRATEGY_CONTEXTUAL_ONE, {}) as Dictionary
	var contextual_two := strategy_reports.get(STRATEGY_CONTEXTUAL_TWO, {}) as Dictionary
	return {
		"audit_id": AUDIT_ID_C3FO,
		"dataset_probe_id": TrainerRosterStructuralRealDataAuditTestSuite.PROBE_ID,
		"eligible_species": members.size(),
		"sample_stride": ROSTER_SAMPLE_STRIDE,
		"sampled_rosters": sampled_rosters,
		"opponent_offsets": OPPONENT_OFFSETS.duplicate(),
		"evidence_modes": EVIDENCE_MODES.duplicate(),
		"scenarios": scenarios,
		"switch_candidate_occurrences": switch_candidate_occurrences,
		"context_build_failures": context_build_failures,
		"contract_validation_failures": contract_validation_failures,
		"frontier_validation_failures": frontier_validation_failures,
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"current_sampling_model_id": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"switching_model_id": TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
		"source_contract_model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"frontier_model_id": TrainerRosterParetoFrontier.MODEL_ID,
		"bounded_action_cap": EXPECTED_DEFAULT_CAP,
		"minimum_move_slots_for_diversity": MIN_MOVE_SLOTS_FOR_DIVERSITY,
		"strategy_reports": strategy_reports,
		"best_set_size_histogram": best_set_size_histogram,
		"required_total_cap_histogram": required_total_cap_histogram,
		"required_total_cap_max": required_total_cap_max,
		"cap_three_one_move_preserves_full_optimal_set_cases": cap_three_one_move_preserves_full_optimal_set_cases,
		"cap_three_one_move_cannot_preserve_full_optimal_set_cases": cap_three_one_move_cannot_preserve_full_optimal_set_cases,
		"contexts_requiring_cap_above_three_for_full_optimal_set": cap_three_one_move_cannot_preserve_full_optimal_set_cases,
		"contextual_one_all_optima_preserved_cases": int(contextual_one.get("all_optima_preserved_cases", 0)),
		"contextual_two_all_optima_preserved_cases": int(contextual_two.get("all_optima_preserved_cases", 0)),
		"overflow_examples": overflow_examples,
		"reorder_probe_cases": reorder_probe_cases,
		"reorder_mismatch_cases": reorder_mismatch_cases,
		"bounded_size_violation_cases": bounded_size_violation_cases,
		"diversity_failure_cases": diversity_failure_cases,
		"nonempty_hidden_belief_cases": nonempty_hidden_belief_cases,
		"nonempty_memory_event_cases": nonempty_memory_event_cases,
		"nonempty_campaign_snapshot_cases": nonempty_campaign_snapshot_cases,
		"neutral_switch_weight_bp": neutral_profile.switch_weight_bp,
		"trainer_profile_semantic_preference_used": false,
		"rng_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"campaign_policy_used": false,
		"roster_value_integrated": false,
		"frontier_hard_pruning_authorized": false,
		"selected_strategy_id": null,
		"production_strategy_selected": false,
		"search_sampling_redesign_authorized": false,
		"behavior_integration_authorized": false,
		"recommended_next_boundary": "resolve_contextual_tie_overflow_and_search_depth_preservation_before_any_sampler_port",
	}


func _c3fo_new_strategy_report(spec: Dictionary) -> Dictionary:
	var switch_slots := int(spec.get("switch_slots", 0))
	return {
		"strategy_id": String(spec.get("strategy_id", "")),
		"selector": String(spec.get("selector", "")),
		"switch_slots": switch_slots,
		"move_slots": EXPECTED_DEFAULT_CAP - switch_slots,
		"bounded_total_cap": EXPECTED_DEFAULT_CAP,
		"context_aware": bool(spec.get("context_aware", false)),
		"frontier_hard_filter": bool(spec.get("frontier_hard_filter", false)),
		"negative_control": bool(spec.get("negative_control", false)),
		"lexical_semantic_preference": bool(spec.get("lexical_semantic_preference", false)),
		"lexical_only_within_equal_score_ties": bool(spec.get("lexical_only_within_equal_score_ties", false)),
		"production_ready": false,
		"cases": 0,
		"reorder_mismatches": 0,
		"any_optimum_preserved_cases": 0,
		"all_optima_preserved_cases": 0,
		"partial_optimum_cases": 0,
		"loses_all_optima_cases": 0,
		"top_set_overflow_cases": 0,
		"lexical_equal_score_cutoff_cases": 0,
		"selected_dominated_cases": 0,
	}


func _c3fo_select_strategy(
	spec: Dictionary,
	input_ids: Array[String],
	scores: Dictionary,
	frontier_ids: Array[String],
) -> Array[String]:
	var selector := String(spec.get("selector", ""))
	var slots := int(spec.get("switch_slots", 0))
	match selector:
		"lexical":
			return _c3fo_select_lexical(input_ids, slots)
		"pareto":
			return _c3fo_select_pareto(input_ids, frontier_ids, slots)
		"contextual":
			return _c3fo_select_contextual(input_ids, scores, slots)
	return []


func _c3fo_select_lexical(input_ids: Array[String], slots: int) -> Array[String]:
	var ordered := _c3fo_unique_sorted_ids(input_ids)
	var out: Array[String] = []
	for candidate_id in ordered:
		if out.size() >= slots:
			break
		out.append(candidate_id)
	return out


func _c3fo_select_pareto(
	input_ids: Array[String],
	frontier_ids: Array[String],
	slots: int,
) -> Array[String]:
	var eligible: Array[String] = []
	for candidate_id in input_ids:
		if frontier_ids.has(candidate_id):
			eligible.append(candidate_id)
	return _c3fo_select_lexical(eligible, slots)


func _c3fo_select_contextual(
	input_ids: Array[String],
	scores: Dictionary,
	slots: int,
) -> Array[String]:
	var remaining := _c3fo_unique_sorted_ids(input_ids)
	var out: Array[String] = []
	while out.size() < slots and not remaining.is_empty():
		var best_score := -2147483648
		for candidate_id in remaining:
			best_score = maxi(best_score, int(scores.get(candidate_id, -2147483648)))
		var tied: Array[String] = []
		for candidate_id in remaining:
			if int(scores.get(candidate_id, -2147483648)) == best_score:
				tied.append(candidate_id)
		tied.sort()
		for candidate_id in tied:
			if out.size() >= slots:
				break
			out.append(candidate_id)
		for candidate_id in tied:
			remaining.erase(candidate_id)
	return out


func _c3fo_record_strategy_case(
	report: Dictionary,
	selected: Array[String],
	reversed_selected: Array[String],
	best_ids: Array[String],
	candidate_ids: Array[String],
	scores: Dictionary,
	dominated_ids: Array[String],
) -> void:
	report["cases"] = int(report.get("cases", 0)) + 1
	if selected != reversed_selected:
		report["reorder_mismatches"] = int(report.get("reorder_mismatches", 0)) + 1
	var any_optimum := _c3fo_intersects(selected, best_ids)
	var all_optima := _c3fo_contains_all(selected, best_ids)
	if any_optimum:
		report["any_optimum_preserved_cases"] = int(report.get("any_optimum_preserved_cases", 0)) + 1
	else:
		report["loses_all_optima_cases"] = int(report.get("loses_all_optima_cases", 0)) + 1
	if all_optima:
		report["all_optima_preserved_cases"] = int(report.get("all_optima_preserved_cases", 0)) + 1
	elif any_optimum:
		report["partial_optimum_cases"] = int(report.get("partial_optimum_cases", 0)) + 1
	var slots := int(report.get("switch_slots", 0))
	if best_ids.size() > slots:
		report["top_set_overflow_cases"] = int(report.get("top_set_overflow_cases", 0)) + 1
	if (
		bool(report.get("lexical_only_within_equal_score_ties", false))
		and _c3fo_cutoff_has_equal_score_omission(selected, candidate_ids, scores)
	):
		report["lexical_equal_score_cutoff_cases"] = int(report.get("lexical_equal_score_cutoff_cases", 0)) + 1
	if _c3fo_intersects(selected, dominated_ids):
		report["selected_dominated_cases"] = int(report.get("selected_dominated_cases", 0)) + 1


func _c3fo_cutoff_has_equal_score_omission(
	selected: Array[String],
	candidate_ids: Array[String],
	scores: Dictionary,
) -> bool:
	if selected.is_empty():
		return false
	var cutoff_id := selected[selected.size() - 1]
	var cutoff_score := int(scores.get(cutoff_id, -2147483648))
	var selected_at_cutoff := 0
	var candidates_at_cutoff := 0
	for candidate_id in selected:
		if int(scores.get(candidate_id, -2147483648)) == cutoff_score:
			selected_at_cutoff += 1
	for candidate_id in candidate_ids:
		if int(scores.get(candidate_id, -2147483648)) == cutoff_score:
			candidates_at_cutoff += 1
	return candidates_at_cutoff > selected_at_cutoff


func _c3fo_sorted_candidate_ids(scores: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw_id in scores.keys():
		out.append(String(raw_id))
	out.sort()
	return out


func _c3fo_unique_sorted_ids(input_ids: Array[String]) -> Array[String]:
	var seen: Dictionary = {}
	for candidate_id in input_ids:
		if not candidate_id.is_empty():
			seen[candidate_id] = true
	var out: Array[String] = []
	for raw_id in seen.keys():
		out.append(String(raw_id))
	out.sort()
	return out


func _c3fo_intersects(left: Array[String], right: Array[String]) -> bool:
	for value in left:
		if right.has(value):
			return true
	return false


func _c3fo_contains_all(container: Array[String], required: Array[String]) -> bool:
	for value in required:
		if not container.has(value):
			return false
	return true
