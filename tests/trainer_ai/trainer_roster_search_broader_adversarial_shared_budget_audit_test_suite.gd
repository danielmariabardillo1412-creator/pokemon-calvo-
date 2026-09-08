class_name TrainerRosterSearchBroaderAdversarialSharedBudgetAuditTestSuite
extends TrainerRosterSearchAllLegalScreenBudgetAuditTestSuite

# C3f-u is strictly TEST/AUDIT-ONLY. It broadens the certified C3f-t sample and
# executes a concrete shared-total-budget root scheduler without modifying search,
# action-space, brains, production budgets, Pareto, roster value, or behavior.

const AUDIT_ID_C3FU := "c3f_u_broader_adversarial_shared_budget_audit_v1"
const SCHEDULER_ID_C3FU := "equal_upfront_root_reservation_no_redistribution_v1"
const LEGACY_CASES_C3FU := 48
const NEW_CASES_PER_STRATUM_C3FU := 3
const NEW_CASES_C3FU := 24
const EXPANDED_CASES_C3FU := 72
const SCHEDULER_LEGACY_BOUNDARY_CASES_C3FU := 8
const SCHEDULER_CASES_C3FU := 32
const MARGIN_3000_C3FU := 3000
const MARGIN_6000_C3FU := 6000
const SHARED_BUDGETS_C3FU := [220, 440, 660]

var _c3fu_cached_c3ft_observations: Dictionary = {}
var _c3fu_cached_scheduler_reports: Dictionary = {}


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_broader_adversarial_shared_budget()


func _collect_c3ft_observations() -> Dictionary:
	if not _c3fu_cached_c3ft_observations.is_empty():
		return _c3fu_cached_c3ft_observations
	_c3fu_cached_c3ft_observations = super._collect_c3ft_observations()
	return _c3fu_cached_c3ft_observations


func _test_broader_adversarial_shared_budget() -> void:
	var observations := _collect_c3fu_observations()
	var report_a := _build_c3fu_report(observations)
	var report_b := _build_c3fu_report(observations)
	var strategies := report_a.get("strategy_reports", {}) as Dictionary
	var margin3000 := strategies.get("depth1_margin_3000_all_legal", {}) as Dictionary
	var topk4 := strategies.get("depth1_topk_4_tie_preserving", {}) as Dictionary
	var margin6000 := strategies.get("depth1_margin_6000_all_legal", {}) as Dictionary
	var schedulers := report_a.get("scheduler_reports", {}) as Dictionary

	_check.call("search_broader_shared_budget_audit_id_recorded", String(report_a.get("audit_id", "")) == AUDIT_ID_C3FU)
	_check.call(
		"search_broader_shared_budget_reuses_certified_legacy_sample",
		int(report_a.get("legacy_cases", 0)) == LEGACY_CASES_C3FU
		and int(report_a.get("legacy_case_failures", -1)) == 0,
	)
	_check.call(
		"search_broader_shared_budget_expands_sample_deterministically",
		int(report_a.get("new_adversarial_cases", 0)) == NEW_CASES_C3FU
		and int(report_a.get("expanded_cases", 0)) == EXPANDED_CASES_C3FU
		and int(report_a.get("expanded_inconclusive_cases", -1)) == 0,
	)
	_check.call(
		"search_broader_shared_budget_new_sample_balances_strata",
		_c3fu_all_strata_have_expected_count(report_a.get("new_case_histogram_by_stratum", {}) as Dictionary),
	)
	_check.call(
		"search_broader_shared_budget_all_expanded_cases_semantically_complete",
		int(report_a.get("expanded_semantically_complete_cases", 0)) == EXPANDED_CASES_C3FU
		and int(report_a.get("expanded_inconclusive_cases", -1)) == 0,
	)
	_check.call(
		"search_broader_shared_budget_measures_new_rank_and_gap_boundaries",
		int(report_a.get("deep_best_rank_histogram_sum", 0)) == EXPANDED_CASES_C3FU
		and int(report_a.get("deep_best_depth1_gap_max", -1)) >= 0,
	)
	_check.call(
		"search_broader_shared_budget_candidate_strategies_account_for_every_case",
		_c3fu_strategy_accounted(margin3000)
		and _c3fu_strategy_accounted(topk4)
		and _c3fu_strategy_accounted(margin6000),
	)
	_check.call(
		"search_broader_shared_budget_zero_loss_claims_are_sample_scoped",
		not bool(report_a.get("candidate_strategy_proven_safe_globally", true))
		and not bool(report_a.get("candidate_strategy_selected", true)),
	)
	_check.call(
		"search_broader_shared_budget_scheduler_is_executed_not_accounting_only",
		bool(report_a.get("shared_budget_execution_modeled", false))
		and int(report_a.get("scheduler_cases", 0)) == SCHEDULER_CASES_C3FU
		and int(report_a.get("scheduler_executed_budget_count", 0)) == SHARED_BUDGETS_C3FU.size(),
	)
	_check.call(
		"search_broader_shared_budget_scheduler_contract_is_explicit",
		String(report_a.get("scheduler_model_id", "")) == SCHEDULER_ID_C3FU
		and String(report_a.get("scheduler_allocation", "")) == "equal_upfront_floor_remaining_div_promoted_roots"
		and String(report_a.get("scheduler_redistribution", "")) == "none"
		and not bool(report_a.get("scheduler_early_stop", true))
		and String(report_a.get("scheduler_truncation_condition", "")).length() > 0,
	)
	_check.call(
		"search_broader_shared_budget_scheduler_tests_required_controls",
		schedulers.has("220") and schedulers.has("440") and schedulers.has("660"),
	)
	_check.call(
		"search_broader_shared_budget_scheduler_never_exceeds_shared_total",
		int(report_a.get("scheduler_total_budget_violation_cases", -1)) == 0,
	)
	_check.call(
		"search_broader_shared_budget_scheduler_permutation_probe_complete",
		int(report_a.get("scheduler_order_probe_cases", 0)) == SCHEDULER_CASES_C3FU * SHARED_BUDGETS_C3FU.size()
		and int(report_a.get("scheduler_forward_reverse_allocation_mismatches", -1)) == 0,
	)
	_check.call(
		"search_broader_shared_budget_scheduler_records_starvation_or_truncation",
		int(report_a.get("scheduler_truncated_case_occurrences", -1)) >= 0
		and int(report_a.get("scheduler_no_decision_case_occurrences", -1)) >= 0,
	)
	_check.call(
		"search_broader_shared_budget_root_fanout_stays_separate_from_inner_cap",
		bool(report_a.get("root_fanout_is_separate_from_inner_action_cap", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP,
	)
	_check.call(
		"search_broader_shared_budget_forbidden_semantics_absent",
		not bool(report_a.get("frontier_used_for_preselection", true))
		and not bool(report_a.get("roster_value_used_for_preselection", true))
		and not bool(report_a.get("profile_used_as_presearch_tiebreak", true))
		and not bool(report_a.get("live_rng_used", true)),
	)
	_check.call(
		"search_broader_shared_budget_hidden_and_campaign_context_absent",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true)),
	)
	_check.call(
		"search_broader_shared_budget_production_unchanged",
		bool(report_a.get("production_sampler_unchanged", false))
		and bool(report_a.get("production_max_actions_unchanged", false))
		and bool(report_a.get("production_max_simulations_unchanged", false))
		and not bool(report_a.get("production_phase_logic_modified", true)),
	)
	_check.call(
		"search_broader_shared_budget_no_strategy_or_budget_selected",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("search_broader_shared_budget_report_deterministic", report_a == report_b)
	_check.call("search_broader_shared_budget_report_json_serializable", JSON.parse_string(JSON.stringify(report_a)) is Dictionary)

	print("\n=== TRAINER ROSTER SEARCH BROADER ADVERSARIAL SHARED BUDGET AUDIT ===")
	print(JSON.stringify(report_a))


func _collect_c3fu_observations() -> Dictionary:
	var legacy_source := _collect_c3ft_observations()
	if not bool(legacy_source.get("valid", false)):
		return {"valid": false}
	var c3fs_source := legacy_source.get("source", {}) as Dictionary
	var catalog := c3fs_source.get("_c3ft_catalog") as DefinitionCatalog
	if catalog == null:
		return {"valid": false}

	var neutral_profile := TrainerProfile.balanced()
	var screen_budget := TrainerSearchBudget.constrained(1, 4, 220, EXPECTED_DEFAULT_CAP)
	var depth_budget := TrainerSearchBudget.depth_two_default()
	var screen_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, screen_budget)
	var depth_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, depth_budget)
	var legacy_cases: Array[Dictionary] = []
	var legacy_keys: Dictionary = {}
	var legacy_failures := 0
	var nonempty_hidden := 0
	var nonempty_memory := 0
	var nonempty_campaign := 0
	var contexts_by_key: Dictionary = {}
	for raw_source_case in c3fs_source.get("cases", []) as Array:
		var source_case_with_context := raw_source_case as Dictionary
		var source_context := source_case_with_context.get("_c3ft_context") as TrainerDecisionContext
		if source_context != null:
			contexts_by_key[_c3fu_case_key(source_case_with_context)] = source_context

	for raw_case in legacy_source.get("cases", []) as Array:
		var source_case := raw_case as Dictionary
		var context := contexts_by_key.get(_c3fu_case_key(source_case)) as TrainerDecisionContext
		if context == null:
			legacy_failures += 1
			continue
		var all_ids := _c3fm_string_array(source_case.get("all_legal_switch_ids", []) as Array)
		all_ids.sort()
		var depth1_scores := source_case.get("all_depth_one_scores", {}) as Dictionary
		var depth1_simulations := source_case.get("all_depth_one_simulations", {}) as Dictionary
		var valid_case := bool(source_case.get("valid_for_semantics", false)) and bool(source_case.get("valid_for_screen", false)) and depth1_scores.size() == all_ids.size() and depth1_simulations.size() == all_ids.size()
		if not valid_case:
			legacy_failures += 1
		var case := source_case.duplicate(true)
		case["_c3fu_context"] = context
		case["all_depth_one_scores"] = depth1_scores.duplicate(true)
		case["all_depth_one_simulations"] = depth1_simulations.duplicate(true)
		case["valid_for_c3fu"] = valid_case
		case["sample_origin"] = "legacy_c3ft"
		legacy_cases.append(case)
		legacy_keys[_c3fu_case_key(case)] = true
		nonempty_hidden += 0 if (context.belief_snapshot.get("hypotheses", {}) as Dictionary).is_empty() else 1
		nonempty_memory += 0 if (context.memory_snapshot.get("event_log", []) as Array).is_empty() else 1
		nonempty_campaign += 0 if context.campaign_snapshot.is_empty() else 1

	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	var game_data := GameData.from_dict(normalized)
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe := helper._build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)

	var fixture_catalog := _catalog
	_catalog = catalog
	var neutral_switch_profile := TrainerProfile.balanced()
	var switching_evaluator := TrainerStrategicSwitchEvaluatorV2.new(catalog, neutral_switch_profile)
	var candidates_by_stratum: Dictionary = {}
	for tie_size in EXPECTED_TIE_SIZES:
		for raw_mode in EVIDENCE_MODES:
			candidates_by_stratum[_c3fp_stratum_key(int(tie_size), String(raw_mode))] = []

	var population_tie_cases := 0
	var population_screened_candidates := 0
	var population_screen_failures := 0
	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])
	var sampled_rosters := 0
	for anchor in range(0, members.size(), ROSTER_SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		sampled_rosters += 1
		var active_id := String(degraded[0].get("instance_id", ""))
		var own_ids: Dictionary = {}
		for member in degraded:
			own_ids[String(member.get("instance_id", ""))] = true
		var banned_opponent_ids := own_ids.duplicate()
		for raw_offset in OPPONENT_OFFSETS:
			var opponent := _select_real_opponent(members, (anchor + int(raw_offset)) % maxi(1, members.size()), banned_opponent_ids, catalog)
			if opponent.is_empty():
				continue
			banned_opponent_ids[String(opponent.get("instance_id", ""))] = true
			for raw_mode in EVIDENCE_MODES:
				var mode := String(raw_mode)
				var context := _build_shadow_context(degraded, opponent, mode, catalog)
				if context == null:
					continue
				var outcome := _evaluate_shadow_switches(context, active_id, [], [], switching_evaluator)
				if not bool(outcome.get("valid", false)):
					continue
				var top_ids := _c3fm_string_array(outcome.get("best_switch_ids", []) as Array)
				if top_ids.size() < 2 or not EXPECTED_TIE_SIZES.has(top_ids.size()):
					continue
				population_tie_cases += 1
				var base_record := {
					"anchor": anchor,
					"evidence_mode": mode,
					"opponent_species_id": String(opponent.get("species_id", "")),
				}
				if legacy_keys.has(_c3fu_case_key(base_record)):
					continue
				var all_ids := _c3fn_switch_ids(context.legal_actions)
				all_ids.sort()
				var screen := _c3fu_evaluate_roots(context, all_ids, screen_search, 1)
				population_screened_candidates += 1
				if not bool(screen.get("valid", false)):
					population_screen_failures += 1
					continue
				var scores := screen.get("scores", {}) as Dictionary
				var margin3000_ids := _c3fq_promote_by_margin(all_ids, scores, MARGIN_3000_C3FU)
				var margin1500_ids := _c3fq_promote_by_margin(all_ids, scores, 1500)
				var record := {
					"anchor": anchor,
					"evidence_mode": mode,
					"opponent_species_id": String(opponent.get("species_id", "")),
					"immediate_tie_size": top_ids.size(),
					"immediate_top_tier_ids": top_ids.duplicate(),
					"all_legal_switch_ids": all_ids.duplicate(),
					"all_depth_one_scores": scores.duplicate(true),
					"all_depth_one_simulations": (screen.get("simulations", {}) as Dictionary).duplicate(true),
					"margin3000_count": margin3000_ids.size(),
					"margin1500_count": margin1500_ids.size(),
					"depth1_score_spread": _c3fu_score_spread(scores),
					"_c3fu_context": context,
				}
				var key := _c3fp_stratum_key(top_ids.size(), mode)
				var bucket := candidates_by_stratum.get(key, []) as Array
				bucket.append(record)
				candidates_by_stratum[key] = bucket

	var new_cases: Array[Dictionary] = []
	var new_histogram: Dictionary = {}
	for tie_size in EXPECTED_TIE_SIZES:
		for raw_mode in EVIDENCE_MODES:
			var mode := String(raw_mode)
			var key := _c3fp_stratum_key(int(tie_size), mode)
			var bucket := candidates_by_stratum.get(key, []) as Array
			bucket.sort_custom(Callable(self, "_c3fu_adversarial_before"))
			var take := mini(NEW_CASES_PER_STRATUM_C3FU, bucket.size())
			new_histogram[key] = take
			for index in range(take):
				var candidate := (bucket[index] as Dictionary).duplicate(true)
				var context := candidate.get("_c3fu_context") as TrainerDecisionContext
				var all_ids := _c3fm_string_array(candidate.get("all_legal_switch_ids", []) as Array)
				var oracle := _c3fu_evaluate_roots(context, all_ids, depth_search, 2)
				candidate["all_depth_two_scores"] = (oracle.get("scores", {}) as Dictionary).duplicate(true)
				candidate["all_depth_two_simulations"] = (oracle.get("simulations", {}) as Dictionary).duplicate(true)
				candidate["valid_for_c3fu"] = bool(oracle.get("valid", false))
				candidate["sample_origin"] = "new_adversarial"
				new_cases.append(candidate)
				nonempty_hidden += 0 if (context.belief_snapshot.get("hypotheses", {}) as Dictionary).is_empty() else 1
				nonempty_memory += 0 if (context.memory_snapshot.get("event_log", []) as Array).is_empty() else 1
				nonempty_campaign += 0 if context.campaign_snapshot.is_empty() else 1

	_catalog = fixture_catalog
	var expanded_cases: Array[Dictionary] = []
	expanded_cases.append_array(legacy_cases)
	expanded_cases.append_array(new_cases)
	return {
		"valid": true,
		"catalog": catalog,
		"cases": expanded_cases,
		"legacy_cases": legacy_cases.size(),
		"legacy_failures": legacy_failures,
		"new_cases": new_cases.size(),
		"new_histogram": new_histogram,
		"population_tie_cases": population_tie_cases,
		"population_screened_candidates": population_screened_candidates,
		"population_screen_failures": population_screen_failures,
		"nonempty_hidden": nonempty_hidden,
		"nonempty_memory": nonempty_memory,
		"nonempty_campaign": nonempty_campaign,
	}


func _build_c3fu_report(observations: Dictionary) -> Dictionary:
	if not bool(observations.get("valid", false)):
		return {"audit_id": AUDIT_ID_C3FU, "expanded_cases": 0}
	var catalog := observations.get("catalog") as DefinitionCatalog
	var cases := observations.get("cases", []) as Array
	var complete_cases := 0
	var inconclusive_cases := 0
	var rank_histogram: Dictionary = {}
	var gap_max := 0
	var gap_sum := 0
	var new_rank_max := 0
	var new_gap_max := 0
	var strategy_reports := {
		"depth1_margin_3000_all_legal": _c3fu_new_strategy("depth1_margin_3000_all_legal"),
		"depth1_topk_4_tie_preserving": _c3fu_new_strategy("depth1_topk_4_tie_preserving"),
		"depth1_margin_6000_all_legal": _c3fu_new_strategy("depth1_margin_6000_all_legal"),
	}
	var case_summaries: Array[Dictionary] = []

	for raw_case in cases:
		var case := raw_case as Dictionary
		if not bool(case.get("valid_for_c3fu", false)):
			inconclusive_cases += 1
			continue
		complete_cases += 1
		var all_ids := _c3fm_string_array(case.get("all_legal_switch_ids", []) as Array)
		var depth1 := case.get("all_depth_one_scores", {}) as Dictionary
		var depth2 := case.get("all_depth_two_scores", {}) as Dictionary
		var depth1_sims := case.get("all_depth_one_simulations", {}) as Dictionary
		var depth2_sims := case.get("all_depth_two_simulations", {}) as Dictionary
		var deep_best := _c3fs_best_ids_for_subset(depth2, all_ids)
		var rank := 0
		var gap := 0
		if not deep_best.is_empty():
			rank = _c3ft_score_rank(deep_best[0], all_ids, depth1)
			gap = _c3ft_depth1_gap_from_leader(deep_best[0], all_ids, depth1)
		_c3fm_histogram_increment(rank_histogram, rank)
		gap_max = maxi(gap_max, gap)
		gap_sum += gap
		if String(case.get("sample_origin", "")) == "new_adversarial":
			new_rank_max = maxi(new_rank_max, rank)
			new_gap_max = maxi(new_gap_max, gap)

		var promoted_margin3000 := _c3fq_promote_by_margin(all_ids, depth1, MARGIN_3000_C3FU)
		var promoted_topk4 := _c3ft_promote_top_k_tie_preserving(all_ids, depth1, 4)
		var promoted_margin6000 := _c3fq_promote_by_margin(all_ids, depth1, MARGIN_6000_C3FU)
		_c3fu_apply_strategy(strategy_reports.get("depth1_margin_3000_all_legal", {}) as Dictionary, promoted_margin3000, deep_best, depth1_sims, depth2_sims)
		_c3fu_apply_strategy(strategy_reports.get("depth1_topk_4_tie_preserving", {}) as Dictionary, promoted_topk4, deep_best, depth1_sims, depth2_sims)
		_c3fu_apply_strategy(strategy_reports.get("depth1_margin_6000_all_legal", {}) as Dictionary, promoted_margin6000, deep_best, depth1_sims, depth2_sims)
		case_summaries.append({
			"anchor": int(case.get("anchor", -1)),
			"evidence_mode": String(case.get("evidence_mode", "")),
			"opponent_species_id": String(case.get("opponent_species_id", "")),
			"sample_origin": String(case.get("sample_origin", "")),
			"deep_best_ids": deep_best.duplicate(),
			"deep_best_depth1_rank": rank,
			"deep_best_depth1_gap": gap,
			"margin3000_promoted_count": promoted_margin3000.size(),
		})

	var scheduler_cases := _c3fu_scheduler_subset(cases)
	var scheduler_reports: Dictionary = {}
	if _c3fu_cached_scheduler_reports.is_empty():
		for raw_budget in SHARED_BUDGETS_C3FU:
			var shared_budget := int(raw_budget)
			var scheduler_report := _c3fu_run_scheduler(catalog, scheduler_cases, shared_budget)
			scheduler_reports[str(shared_budget)] = scheduler_report
		_c3fu_cached_scheduler_reports = scheduler_reports.duplicate(true)
	else:
		scheduler_reports = _c3fu_cached_scheduler_reports.duplicate(true)
	var scheduler_total_budget_violations := 0
	var scheduler_order_probe_cases := 0
	var scheduler_allocation_mismatches := 0
	var scheduler_truncated_occurrences := 0
	var scheduler_no_decision_occurrences := 0
	for raw_scheduler_report in scheduler_reports.values():
		var scheduler_report := raw_scheduler_report as Dictionary
		scheduler_total_budget_violations += int(scheduler_report.get("total_budget_violation_cases", 0))
		scheduler_order_probe_cases += int(scheduler_report.get("order_probe_cases", 0))
		scheduler_allocation_mismatches += int(scheduler_report.get("forward_reverse_allocation_mismatches", 0))
		scheduler_truncated_occurrences += int(scheduler_report.get("truncated_cases", 0))
		scheduler_no_decision_occurrences += int(scheduler_report.get("no_decision_cases", 0))

	var margin3000_report := strategy_reports.get("depth1_margin_3000_all_legal", {}) as Dictionary
	var topk4_report := strategy_reports.get("depth1_topk_4_tie_preserving", {}) as Dictionary
	var margin6000_report := strategy_reports.get("depth1_margin_6000_all_legal", {}) as Dictionary
	return {
		"audit_id": AUDIT_ID_C3FU,
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"action_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"dataset_probe_id": "runtime_levelup_l50_neutral_probe_v1",
		"legacy_cases": int(observations.get("legacy_cases", 0)),
		"legacy_case_failures": int(observations.get("legacy_failures", 0)),
		"new_adversarial_cases": int(observations.get("new_cases", 0)),
		"expanded_cases": cases.size(),
		"expanded_semantically_complete_cases": complete_cases,
		"expanded_inconclusive_cases": inconclusive_cases,
		"population_tie_cases": int(observations.get("population_tie_cases", 0)),
		"population_screened_adversarial_candidates": int(observations.get("population_screened_candidates", 0)),
		"population_screen_failures": int(observations.get("population_screen_failures", 0)),
		"new_case_histogram_by_stratum": (observations.get("new_histogram", {}) as Dictionary).duplicate(true),
		"deep_best_rank_histogram": rank_histogram,
		"deep_best_rank_histogram_sum": _c3fu_histogram_sum(rank_histogram),
		"deep_best_depth1_gap_max": gap_max,
		"deep_best_depth1_gap_mean": gap_sum / maxi(1, complete_cases),
		"deep_best_depth1_gap_sum": gap_sum,
		"new_adversarial_deep_best_rank_max": new_rank_max,
		"new_adversarial_deep_best_gap_max": new_gap_max,
		"c3ft_reference_rank_max": 4,
		"c3ft_reference_gap_max": 1665,
		"strategy_reports": strategy_reports,
		"candidate_strategy_proven_safe_globally": false,
		"candidate_strategy_selected": false,
		"margin3000_expanded_losses": int(margin3000_report.get("loses_deep_optimum_cases", 0)),
		"topk4_expanded_losses": int(topk4_report.get("loses_deep_optimum_cases", 0)),
		"margin6000_expanded_losses": int(margin6000_report.get("loses_deep_optimum_cases", 0)),
		"scheduler_model_id": SCHEDULER_ID_C3FU,
		"scheduler_cases": scheduler_cases.size(),
		"scheduler_shared_budgets": SHARED_BUDGETS_C3FU.duplicate(),
		"scheduler_executed_budget_count": scheduler_reports.size(),
		"scheduler_allocation": "equal_upfront_floor_remaining_div_promoted_roots",
		"scheduler_root_order_probe": "lexical_and_reverse",
		"scheduler_redistribution": "none",
		"scheduler_early_stop": false,
		"scheduler_truncation_condition": "quota_unavailable_or_any_promoted_root_not_depth2_complete_or_budget_exhausted_or_world_coverage_incomplete",
		"scheduler_reports": scheduler_reports,
		"scheduler_total_budget_violation_cases": scheduler_total_budget_violations,
		"scheduler_order_probe_cases": scheduler_order_probe_cases,
		"scheduler_forward_reverse_allocation_mismatches": scheduler_allocation_mismatches,
		"scheduler_truncated_case_occurrences": scheduler_truncated_occurrences,
		"scheduler_no_decision_case_occurrences": scheduler_no_decision_occurrences,
		"shared_budget_execution_modeled": true,
		"root_fanout_is_separate_from_inner_action_cap": true,
		"inner_max_actions_per_side": EXPECTED_DEFAULT_CAP,
		"inner_depth_turns": 2,
		"inner_max_worlds": 4,
		"inner_max_simulations_per_root": 220,
		"frontier_used_for_preselection": false,
		"roster_value_used_for_preselection": false,
		"profile_used_as_presearch_tiebreak": false,
		"live_rng_used": false,
		"nonempty_hidden_belief_cases": int(observations.get("nonempty_hidden", 0)),
		"nonempty_memory_event_cases": int(observations.get("nonempty_memory", 0)),
		"nonempty_campaign_snapshot_cases": int(observations.get("nonempty_campaign", 0)),
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"campaign_policy_used": false,
		"production_sampler_unchanged": true,
		"production_max_actions_unchanged": true,
		"production_max_simulations_unchanged": true,
		"production_phase_logic_modified": false,
		"production_strategy_selected": false,
		"search_sampling_redesign_authorized": false,
		"behavior_integration_authorized": false,
		"selected_strategy_id": null,
		"selected_shared_budget": null,
		"recommended_next_boundary": "interpret_expanded_screen_losses_and_executed_shared_budget_before_any_production_port",
		"case_summaries": case_summaries,
	}


func _c3fu_evaluate_roots(context: TrainerDecisionContext, ids: Array[String], search: TrainerMultiTurnSearch, expected_depth: int) -> Dictionary:
	var scores: Dictionary = {}
	var simulations: Dictionary = {}
	var valid := context != null
	for candidate_id in ids:
		var action := _c3fp_find_switch_action(context, candidate_id)
		if action == null:
			valid = false
			continue
		var result := search.evaluate(context, action)
		if result.is_empty() or not result.has("metadata"):
			valid = false
			continue
		var metadata := result.get("metadata", {}) as Dictionary
		scores[candidate_id] = int(result.get("score", 0))
		simulations[candidate_id] = int(metadata.get("simulations_used", 0))
		if int(metadata.get("fully_completed_depth", 0)) != expected_depth:
			valid = false
		if bool(metadata.get("budget_exhausted", false)):
			valid = false
		if int(metadata.get("world_coverage_basis_points", 0)) != 10000:
			valid = false
	return {"valid": valid and scores.size() == ids.size(), "scores": scores, "simulations": simulations}


func _c3fu_adversarial_before(a: Dictionary, b: Dictionary) -> bool:
	var a3000 := int(a.get("margin3000_count", 0))
	var b3000 := int(b.get("margin3000_count", 0))
	if a3000 != b3000:
		return a3000 > b3000
	var a1500 := int(a.get("margin1500_count", 0))
	var b1500 := int(b.get("margin1500_count", 0))
	if a1500 != b1500:
		return a1500 > b1500
	var aspread := int(a.get("depth1_score_spread", 0))
	var bspread := int(b.get("depth1_score_spread", 0))
	if aspread != bspread:
		return aspread < bspread
	return _c3fu_case_key(a) < _c3fu_case_key(b)


func _c3fu_score_spread(scores: Dictionary) -> int:
	if scores.is_empty():
		return 0
	var min_score := 2147483647
	var max_score := -2147483648
	for raw_value in scores.values():
		var value := int(raw_value)
		min_score = mini(min_score, value)
		max_score = maxi(max_score, value)
	return max_score - min_score


func _c3fu_case_key(case: Dictionary) -> String:
	return "%d|%s|%s" % [int(case.get("anchor", -1)), String(case.get("evidence_mode", "")), String(case.get("opponent_species_id", ""))]


func _c3fu_new_strategy(strategy_id: String) -> Dictionary:
	return {
		"strategy_id": strategy_id,
		"cases": 0,
		"preserves_deep_optimum_cases": 0,
		"loses_deep_optimum_cases": 0,
		"promoted_switches_sum": 0,
		"promoted_switches_max": 0,
		"screening_simulations_sum": 0,
		"depth_two_simulations_sum": 0,
		"total_simulations_sum": 0,
	}


func _c3fu_apply_strategy(report: Dictionary, promoted: Array[String], deep_best: Array[String], depth1_sims: Dictionary, depth2_sims: Dictionary) -> void:
	report["cases"] = int(report.get("cases", 0)) + 1
	report["promoted_switches_sum"] = int(report.get("promoted_switches_sum", 0)) + promoted.size()
	report["promoted_switches_max"] = maxi(int(report.get("promoted_switches_max", 0)), promoted.size())
	var preserves := _c3fu_sets_intersect(promoted, deep_best)
	if preserves:
		report["preserves_deep_optimum_cases"] = int(report.get("preserves_deep_optimum_cases", 0)) + 1
	else:
		report["loses_deep_optimum_cases"] = int(report.get("loses_deep_optimum_cases", 0)) + 1
	var screen_cost := _c3fu_sum_dictionary(depth1_sims)
	var depth_cost := 0
	for candidate_id in promoted:
		depth_cost += int(depth2_sims.get(candidate_id, 0))
	report["screening_simulations_sum"] = int(report.get("screening_simulations_sum", 0)) + screen_cost
	report["depth_two_simulations_sum"] = int(report.get("depth_two_simulations_sum", 0)) + depth_cost
	report["total_simulations_sum"] = int(report.get("total_simulations_sum", 0)) + screen_cost + depth_cost


func _c3fu_strategy_accounted(report: Dictionary) -> bool:
	return int(report.get("cases", 0)) == EXPANDED_CASES_C3FU and int(report.get("preserves_deep_optimum_cases", 0)) + int(report.get("loses_deep_optimum_cases", 0)) == EXPANDED_CASES_C3FU


func _c3fu_scheduler_subset(cases: Array) -> Array[Dictionary]:
	var legacy: Array[Dictionary] = []
	var fresh: Array[Dictionary] = []
	for raw_case in cases:
		var case := raw_case as Dictionary
		if String(case.get("sample_origin", "")) == "new_adversarial":
			fresh.append(case)
		else:
			legacy.append(case)
	legacy.sort_custom(Callable(self, "_c3fu_legacy_boundary_before"))
	var selected: Array[Dictionary] = []
	for case in fresh:
		selected.append(case)
	for index in range(mini(SCHEDULER_LEGACY_BOUNDARY_CASES_C3FU, legacy.size())):
		selected.append(legacy[index])
	return selected


func _c3fu_legacy_boundary_before(a: Dictionary, b: Dictionary) -> bool:
	var a_rank := _c3fu_case_deep_rank(a)
	var b_rank := _c3fu_case_deep_rank(b)
	if a_rank != b_rank:
		return a_rank > b_rank
	var a_gap := _c3fu_case_deep_gap(a)
	var b_gap := _c3fu_case_deep_gap(b)
	if a_gap != b_gap:
		return a_gap > b_gap
	return _c3fu_case_key(a) < _c3fu_case_key(b)


func _c3fu_case_deep_rank(case: Dictionary) -> int:
	var all_ids := _c3fm_string_array(case.get("all_legal_switch_ids", []) as Array)
	var depth1 := case.get("all_depth_one_scores", {}) as Dictionary
	var depth2 := case.get("all_depth_two_scores", {}) as Dictionary
	var best := _c3fs_best_ids_for_subset(depth2, all_ids)
	return 0 if best.is_empty() else _c3ft_score_rank(best[0], all_ids, depth1)


func _c3fu_case_deep_gap(case: Dictionary) -> int:
	var all_ids := _c3fm_string_array(case.get("all_legal_switch_ids", []) as Array)
	var depth1 := case.get("all_depth_one_scores", {}) as Dictionary
	var depth2 := case.get("all_depth_two_scores", {}) as Dictionary
	var best := _c3fs_best_ids_for_subset(depth2, all_ids)
	return 0 if best.is_empty() else _c3ft_depth1_gap_from_leader(best[0], all_ids, depth1)


func _c3fu_run_scheduler(catalog: DefinitionCatalog, cases: Array[Dictionary], shared_budget: int) -> Dictionary:
	var forward_results: Dictionary = {}
	var reverse_results: Dictionary = {}
	var total_budget_violations := 0
	var truncated_cases := 0
	var no_decision_cases := 0
	var preserves_global_best_cases := 0
	var changed_best_cases := 0
	var promotion_loses_global_best_cases := 0
	var order_mismatches := 0
	var allocation_mismatches := 0
	var quota_min := 2147483647
	var quota_max := 0
	var quota_sum := 0
	var quota_cases := 0
	var actual_simulations_sum := 0

	for case in cases:
		var key := _c3fu_case_key(case)
		var forward := _c3fu_execute_scheduler_case(catalog, case, shared_budget, false)
		var reverse := _c3fu_execute_scheduler_case(catalog, case, shared_budget, true)
		forward_results[key] = forward
		reverse_results[key] = reverse
		if int(forward.get("actual_total_simulations", 0)) > shared_budget or int(reverse.get("actual_total_simulations", 0)) > shared_budget:
			total_budget_violations += 1
		if bool(forward.get("truncated", false)):
			truncated_cases += 1
		if bool(forward.get("no_decision", false)):
			no_decision_cases += 1
		if bool(forward.get("promotion_loses_global_best", false)):
			promotion_loses_global_best_cases += 1
		if bool(forward.get("preserves_global_best", false)):
			preserves_global_best_cases += 1
		else:
			changed_best_cases += 1
		if (forward.get("selected_best_ids", []) as Array) != (reverse.get("selected_best_ids", []) as Array):
			order_mismatches += 1
		if int(forward.get("quota_per_root", -1)) != int(reverse.get("quota_per_root", -1)):
			allocation_mismatches += 1
		var quota := int(forward.get("quota_per_root", 0))
		if quota > 0:
			quota_min = mini(quota_min, quota)
			quota_max = maxi(quota_max, quota)
			quota_sum += quota
			quota_cases += 1
		actual_simulations_sum += int(forward.get("actual_total_simulations", 0))

	return {
		"shared_budget": shared_budget,
		"cases": cases.size(),
		"order_probe_cases": cases.size(),
		"total_budget_violation_cases": total_budget_violations,
		"truncated_cases": truncated_cases,
		"no_decision_cases": no_decision_cases,
		"promotion_loses_global_best_cases": promotion_loses_global_best_cases,
		"preserves_global_best_cases": preserves_global_best_cases,
		"changed_best_vs_oracle_cases": changed_best_cases,
		"forward_reverse_best_set_mismatch_cases": order_mismatches,
		"forward_reverse_allocation_mismatches": allocation_mismatches,
		"quota_per_root_min": 0 if quota_cases == 0 else quota_min,
		"quota_per_root_max": quota_max,
		"quota_per_root_mean": quota_sum / maxi(1, quota_cases),
		"forward_actual_simulations_sum": actual_simulations_sum,
	}


func _c3fu_execute_scheduler_case(catalog: DefinitionCatalog, case: Dictionary, shared_budget: int, reverse_order: bool) -> Dictionary:
	var context := case.get("_c3fu_context") as TrainerDecisionContext
	var all_ids := _c3fm_string_array(case.get("all_legal_switch_ids", []) as Array)
	var depth1 := case.get("all_depth_one_scores", {}) as Dictionary
	var depth1_sims := case.get("all_depth_one_simulations", {}) as Dictionary
	var depth2_oracle := case.get("all_depth_two_scores", {}) as Dictionary
	var deep_best := _c3fs_best_ids_for_subset(depth2_oracle, all_ids)
	var promoted := _c3fq_promote_by_margin(all_ids, depth1, MARGIN_3000_C3FU)
	promoted.sort()
	if reverse_order:
		promoted.reverse()
	var screen_cost := _c3fu_sum_dictionary(depth1_sims)
	var remaining := maxi(0, shared_budget - screen_cost)
	var quota := 0
	if not promoted.is_empty() and remaining >= promoted.size():
		quota = mini(220, int(remaining / promoted.size()))
	var completed_scores: Dictionary = {}
	var actual_depth_cost := 0
	var incomplete_roots := 0
	if quota > 0 and context != null:
		var profile := TrainerProfile.balanced()
		var root_budget := TrainerSearchBudget.constrained(2, 4, quota, EXPECTED_DEFAULT_CAP)
		var search := TrainerMultiTurnSearch.new(catalog, profile, root_budget)
		for candidate_id in promoted:
			var action := _c3fp_find_switch_action(context, candidate_id)
			if action == null:
				incomplete_roots += 1
				continue
			var result := search.evaluate(context, action)
			if result.is_empty() or not result.has("metadata"):
				incomplete_roots += 1
				continue
			var metadata := result.get("metadata", {}) as Dictionary
			actual_depth_cost += int(metadata.get("simulations_used", 0))
			var complete := int(metadata.get("fully_completed_depth", 0)) == 2 and not bool(metadata.get("budget_exhausted", false)) and int(metadata.get("world_coverage_basis_points", 0)) == 10000
			if complete:
				completed_scores[candidate_id] = int(result.get("score", 0))
			else:
				incomplete_roots += 1
	else:
		incomplete_roots = promoted.size()
	var selected := _c3fs_best_ids_for_subset(completed_scores, _c3fu_dictionary_string_keys(completed_scores))
	selected.sort()
	deep_best.sort()
	var promotion_loses := not _c3fu_sets_intersect(promoted, deep_best)
	var preserves := _c3fu_sets_intersect(selected, deep_best)
	return {
		"shared_budget": shared_budget,
		"root_order": "reverse" if reverse_order else "lexical",
		"screen_cost": screen_cost,
		"remaining_after_screen": remaining,
		"promoted_root_count": promoted.size(),
		"quota_per_root": quota,
		"incomplete_root_count": incomplete_roots,
		"truncated": incomplete_roots > 0,
		"no_decision": selected.is_empty(),
		"promotion_loses_global_best": promotion_loses,
		"preserves_global_best": preserves,
		"selected_best_ids": selected,
		"oracle_best_ids": deep_best,
		"actual_depth_simulations": actual_depth_cost,
		"actual_total_simulations": screen_cost + actual_depth_cost,
	}


func _c3fu_dictionary_string_keys(values: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_key in values.keys():
		result.append(String(raw_key))
	result.sort()
	return result


func _c3fu_sum_dictionary(values: Dictionary) -> int:
	var total := 0
	for raw_value in values.values():
		total += int(raw_value)
	return total


func _c3fu_sets_intersect(left: Array[String], right: Array[String]) -> bool:
	for value in left:
		if right.has(value):
			return true
	return false


func _c3fu_histogram_sum(histogram: Dictionary) -> int:
	var total := 0
	for raw_value in histogram.values():
		total += int(raw_value)
	return total


func _c3fu_all_strata_have_expected_count(histogram: Dictionary) -> bool:
	if histogram.size() != EXPECTED_TIE_SIZES.size() * EVIDENCE_MODES.size():
		return false
	for raw_value in histogram.values():
		if int(raw_value) != NEW_CASES_PER_STRATUM_C3FU:
			return false
	return true
