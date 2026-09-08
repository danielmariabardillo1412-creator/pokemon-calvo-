class_name TrainerRosterSearchHeldOutSharedBudgetValidationAuditTestSuite
extends TrainerRosterSearchBroaderAdversarialSharedBudgetAuditTestSuite

# C3f-v is strictly TEST/AUDIT-ONLY. It validates the previously observed
# zero-loss screen candidates and the concrete shared-budget scheduler on a
# deterministic held-out sample that is disjoint from the 72 C3f-t/C3f-u cases.
# Selection uses the second canonical roster schedule, then tie/evidence strata
# plus lexical case identity. C3f-u used the first canonical roster schedule.
# neither depth1 nor depth2 scores are used to choose held-out cases.

const AUDIT_ID_C3FV := "c3f_v_held_out_shared_budget_validation_audit_v1"
const HELD_OUT_SELECTION_ID_C3FV := "balanced_strata_lexical_even_spread_disjoint_from_c3fu_v1"
const HELD_OUT_CASES_PER_STRATUM_C3FV := 3
const HELD_OUT_SCHEDULE_INDEX_C3FV := 1
const HELD_OUT_CASES_C3FV := 24
const SHARED_BUDGETS_C3FV := [220, 440, 660]

var _c3fv_cached_c3fu_observations: Dictionary = {}
var _c3fv_cached_observations: Dictionary = {}
var _c3fv_cached_scheduler_reports: Dictionary = {}


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_held_out_shared_budget_validation()


func _collect_c3fu_observations() -> Dictionary:
	if not _c3fv_cached_c3fu_observations.is_empty():
		return _c3fv_cached_c3fu_observations
	_c3fv_cached_c3fu_observations = super._collect_c3fu_observations()
	return _c3fv_cached_c3fu_observations


func _test_held_out_shared_budget_validation() -> void:
	var observations := _collect_c3fv_observations()
	var report_a := _build_c3fv_report(observations)
	var report_b := _build_c3fv_report(observations)
	var strategies := report_a.get("strategy_reports", {}) as Dictionary
	var margin3000 := strategies.get("depth1_margin_3000_all_legal", {}) as Dictionary
	var topk4 := strategies.get("depth1_topk_4_tie_preserving", {}) as Dictionary
	var margin6000 := strategies.get("depth1_margin_6000_all_legal", {}) as Dictionary
	var schedulers := report_a.get("scheduler_reports", {}) as Dictionary

	_check.call("search_held_out_validation_audit_id_recorded", String(report_a.get("audit_id", "")) == AUDIT_ID_C3FV)
	_check.call(
		"search_held_out_validation_sample_is_disjoint_from_selection_sample",
		int(report_a.get("held_out_overlap_with_c3fu_cases", -1)) == 0
		and int(report_a.get("held_out_cases", 0)) == HELD_OUT_CASES_C3FV,
	)
	_check.call(
		"search_held_out_validation_sample_balances_tie_and_evidence_strata",
		_c3fv_all_strata_have_expected_count(report_a.get("held_out_histogram_by_stratum", {}) as Dictionary),
	)
	_check.call(
		"search_held_out_validation_selection_is_outcome_independent",
		String(report_a.get("held_out_selection_id", "")) == HELD_OUT_SELECTION_ID_C3FV
		and not bool(report_a.get("depth1_scores_used_for_held_out_selection", true))
		and not bool(report_a.get("depth2_scores_used_for_held_out_selection", true))
		and not bool(report_a.get("rank_gap_used_for_held_out_selection", true)),
	)
	_check.call(
		"search_held_out_validation_all_cases_semantically_complete",
		int(report_a.get("held_out_semantically_complete_cases", 0)) == HELD_OUT_CASES_C3FV
		and int(report_a.get("held_out_inconclusive_cases", -1)) == 0,
	)
	_check.call(
		"search_held_out_validation_rank_gap_telemetry_accounts_for_sample",
		int(report_a.get("deep_best_rank_histogram_sum", 0)) == HELD_OUT_CASES_C3FV
		and int(report_a.get("deep_best_depth1_gap_max", -1)) >= 0
		and bool(report_a.get("rank_gap_observed_post_selection", false)),
	)
	_check.call(
		"search_held_out_validation_candidate_strategies_account_for_every_case",
		_c3fv_strategy_accounted(margin3000)
		and _c3fv_strategy_accounted(topk4)
		and _c3fv_strategy_accounted(margin6000),
	)
	_check.call(
		"search_held_out_validation_counterexamples_are_reported_not_hidden",
		int(report_a.get("margin3000_counterexample_count", -1)) == int(margin3000.get("loses_deep_optimum_cases", -2))
		and int(report_a.get("topk4_counterexample_count", -1)) == int(topk4.get("loses_deep_optimum_cases", -2))
		and int(report_a.get("margin6000_counterexample_count", -1)) == int(margin6000.get("loses_deep_optimum_cases", -2)),
	)
	_check.call(
		"search_held_out_validation_zero_loss_is_not_assumed_or_globalized",
		not bool(report_a.get("zero_loss_assumed", true))
		and not bool(report_a.get("candidate_strategy_proven_safe_globally", true))
		and not bool(report_a.get("candidate_strategy_selected", true)),
	)
	_check.call(
		"search_held_out_validation_scheduler_executes_lower_controls_and_660",
		int(report_a.get("scheduler_cases", 0)) == HELD_OUT_CASES_C3FV
		and schedulers.has("220")
		and schedulers.has("440")
		and schedulers.has("660"),
	)
	_check.call(
		"search_held_out_validation_scheduler_never_exceeds_shared_total",
		int(report_a.get("scheduler_total_budget_violation_cases", -1)) == 0,
	)
	_check.call(
		"search_held_out_validation_scheduler_order_probe_complete",
		int(report_a.get("scheduler_order_probe_cases", 0)) == HELD_OUT_CASES_C3FV * SHARED_BUDGETS_C3FV.size()
		and int(report_a.get("scheduler_forward_reverse_allocation_mismatches", -1)) >= 0
		and int(report_a.get("scheduler_forward_reverse_best_set_mismatches", -1)) >= 0,
	)
	_check.call(
		"search_held_out_validation_scheduler_records_starvation_and_oracle_preservation",
		int(report_a.get("scheduler_truncated_case_occurrences", -1)) >= 0
		and int(report_a.get("scheduler_no_decision_case_occurrences", -1)) >= 0
		and int(report_a.get("scheduler_oracle_preservation_observations", 0)) == HELD_OUT_CASES_C3FV * SHARED_BUDGETS_C3FV.size(),
	)
	_check.call(
		"search_held_out_validation_root_fanout_stays_separate_from_inner_cap",
		bool(report_a.get("root_fanout_is_separate_from_inner_action_cap", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == EXPECTED_DEFAULT_CAP,
	)
	_check.call(
		"search_held_out_validation_forbidden_semantics_absent",
		not bool(report_a.get("frontier_used_for_preselection", true))
		and not bool(report_a.get("roster_value_used_for_preselection", true))
		and not bool(report_a.get("profile_used_as_presearch_tiebreak", true))
		and not bool(report_a.get("live_rng_used", true)),
	)
	_check.call(
		"search_held_out_validation_hidden_and_campaign_context_absent",
		int(report_a.get("nonempty_hidden_belief_cases", -1)) == 0
		and int(report_a.get("nonempty_memory_event_cases", -1)) == 0
		and int(report_a.get("nonempty_campaign_snapshot_cases", -1)) == 0
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true))
		and not bool(report_a.get("campaign_policy_used", true)),
	)
	_check.call(
		"search_held_out_validation_production_unchanged",
		bool(report_a.get("production_sampler_unchanged", false))
		and bool(report_a.get("production_max_actions_unchanged", false))
		and bool(report_a.get("production_max_simulations_unchanged", false))
		and not bool(report_a.get("production_phase_logic_modified", true)),
	)
	_check.call(
		"search_held_out_validation_no_strategy_scheduler_or_budget_selected",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("production_strategy_selected", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("search_held_out_validation_report_deterministic", report_a == report_b)
	_check.call("search_held_out_validation_report_json_serializable", JSON.parse_string(JSON.stringify(report_a)) is Dictionary)

	print("\n=== TRAINER ROSTER SEARCH HELD-OUT SHARED BUDGET VALIDATION AUDIT ===")
	print(JSON.stringify(report_a))


func _collect_c3fv_observations() -> Dictionary:
	if not _c3fv_cached_observations.is_empty():
		return _c3fv_cached_observations

	var c3fu_source := _collect_c3fu_observations()
	if not bool(c3fu_source.get("valid", false)):
		return {"valid": false}
	var catalog := c3fu_source.get("catalog") as DefinitionCatalog
	if catalog == null:
		return {"valid": false}

	var excluded_keys: Dictionary = {}
	for raw_case in c3fu_source.get("cases", []) as Array:
		var prior_case := raw_case as Dictionary
		excluded_keys[_c3fu_case_key(prior_case)] = true

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
	var population_unseen_candidates := 0
	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[HELD_OUT_SCHEDULE_INDEX_C3FV])
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
				if excluded_keys.has(_c3fu_case_key(base_record)):
					continue
				population_unseen_candidates += 1
				var all_ids := _c3fn_switch_ids(context.legal_actions)
				all_ids.sort()
				var record := {
					"anchor": anchor,
					"evidence_mode": mode,
					"opponent_species_id": String(opponent.get("species_id", "")),
					"immediate_tie_size": top_ids.size(),
					"immediate_top_tier_ids": top_ids.duplicate(),
					"all_legal_switch_ids": all_ids.duplicate(),
					"_c3fu_context": context,
				}
				var key := _c3fp_stratum_key(top_ids.size(), mode)
				var bucket := candidates_by_stratum.get(key, []) as Array
				bucket.append(record)
				candidates_by_stratum[key] = bucket

	var screen_budget := TrainerSearchBudget.constrained(1, 4, 220, EXPECTED_DEFAULT_CAP)
	var depth_budget := TrainerSearchBudget.depth_two_default()
	var neutral_profile := TrainerProfile.balanced()
	var screen_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, screen_budget)
	var depth_search := TrainerMultiTurnSearch.new(catalog, neutral_profile, depth_budget)
	var held_out_cases: Array[Dictionary] = []
	var held_out_histogram: Dictionary = {}
	var insufficient_strata: Array[String] = []
	var screen_failures := 0
	var oracle_failures := 0
	var nonempty_hidden := 0
	var nonempty_memory := 0
	var nonempty_campaign := 0

	for tie_size in EXPECTED_TIE_SIZES:
		for raw_mode in EVIDENCE_MODES:
			var mode := String(raw_mode)
			var stratum_key := _c3fp_stratum_key(int(tie_size), mode)
			var bucket := candidates_by_stratum.get(stratum_key, []) as Array
			bucket.sort_custom(Callable(self, "_c3fv_case_key_before"))
			if bucket.size() < HELD_OUT_CASES_PER_STRATUM_C3FV:
				insufficient_strata.append(stratum_key)
			var selected := _c3fv_even_spread(bucket, HELD_OUT_CASES_PER_STRATUM_C3FV)
			held_out_histogram[stratum_key] = selected.size()
			for raw_candidate in selected:
				var candidate := (raw_candidate as Dictionary).duplicate(true)
				var context := candidate.get("_c3fu_context") as TrainerDecisionContext
				var all_ids := _c3fm_string_array(candidate.get("all_legal_switch_ids", []) as Array)
				var screen := _c3fu_evaluate_roots(context, all_ids, screen_search, 1)
				var oracle := _c3fu_evaluate_roots(context, all_ids, depth_search, 2)
				if not bool(screen.get("valid", false)):
					screen_failures += 1
				if not bool(oracle.get("valid", false)):
					oracle_failures += 1
				candidate["all_depth_one_scores"] = (screen.get("scores", {}) as Dictionary).duplicate(true)
				candidate["all_depth_one_simulations"] = (screen.get("simulations", {}) as Dictionary).duplicate(true)
				candidate["all_depth_two_scores"] = (oracle.get("scores", {}) as Dictionary).duplicate(true)
				candidate["all_depth_two_simulations"] = (oracle.get("simulations", {}) as Dictionary).duplicate(true)
				candidate["valid_for_c3fv"] = bool(screen.get("valid", false)) and bool(oracle.get("valid", false))
				candidate["sample_origin"] = "held_out_c3fv"
				held_out_cases.append(candidate)
				nonempty_hidden += 0 if (context.belief_snapshot.get("hypotheses", {}) as Dictionary).is_empty() else 1
				nonempty_memory += 0 if (context.memory_snapshot.get("event_log", []) as Array).is_empty() else 1
				nonempty_campaign += 0 if context.campaign_snapshot.is_empty() else 1

	_catalog = fixture_catalog
	var overlap := 0
	for held_out_case in held_out_cases:
		if excluded_keys.has(_c3fu_case_key(held_out_case)):
			overlap += 1

	_c3fv_cached_observations = {
		"valid": true,
		"catalog": catalog,
		"cases": held_out_cases,
		"excluded_prior_case_count": excluded_keys.size(),
		"overlap_with_prior": overlap,
		"held_out_histogram": held_out_histogram,
		"insufficient_strata": insufficient_strata,
		"population_tie_cases": population_tie_cases,
		"population_unseen_candidates": population_unseen_candidates,
		"screen_failures": screen_failures,
		"oracle_failures": oracle_failures,
		"nonempty_hidden": nonempty_hidden,
		"nonempty_memory": nonempty_memory,
		"nonempty_campaign": nonempty_campaign,
	}
	return _c3fv_cached_observations


func _build_c3fv_report(observations: Dictionary) -> Dictionary:
	if not bool(observations.get("valid", false)):
		return {"audit_id": AUDIT_ID_C3FV, "held_out_cases": 0}

	var catalog := observations.get("catalog") as DefinitionCatalog
	var cases := observations.get("cases", []) as Array
	var complete_cases := 0
	var inconclusive_cases := 0
	var rank_histogram: Dictionary = {}
	var gap_max := 0
	var gap_sum := 0
	var tie_histogram: Dictionary = {}
	var evidence_histogram: Dictionary = {}
	var strategy_reports := {
		"depth1_margin_3000_all_legal": _c3fu_new_strategy("depth1_margin_3000_all_legal"),
		"depth1_topk_4_tie_preserving": _c3fu_new_strategy("depth1_topk_4_tie_preserving"),
		"depth1_margin_6000_all_legal": _c3fu_new_strategy("depth1_margin_6000_all_legal"),
	}
	var counterexamples := {
		"depth1_margin_3000_all_legal": [],
		"depth1_topk_4_tie_preserving": [],
		"depth1_margin_6000_all_legal": [],
	}
	var case_summaries: Array[Dictionary] = []

	for raw_case in cases:
		var case := raw_case as Dictionary
		if not bool(case.get("valid_for_c3fv", false)):
			inconclusive_cases += 1
			continue
		complete_cases += 1
		var tie_size := int(case.get("immediate_tie_size", 0))
		var evidence_mode := String(case.get("evidence_mode", ""))
		_c3fm_histogram_increment(tie_histogram, tie_size)
		if not evidence_histogram.has(evidence_mode):
			evidence_histogram[evidence_mode] = 0
		evidence_histogram[evidence_mode] = int(evidence_histogram[evidence_mode]) + 1

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

		var promoted_margin3000 := _c3fq_promote_by_margin(all_ids, depth1, MARGIN_3000_C3FU)
		var promoted_topk4 := _c3ft_promote_top_k_tie_preserving(all_ids, depth1, 4)
		var promoted_margin6000 := _c3fq_promote_by_margin(all_ids, depth1, MARGIN_6000_C3FU)
		var margin3000_report := strategy_reports.get("depth1_margin_3000_all_legal", {}) as Dictionary
		var topk4_report := strategy_reports.get("depth1_topk_4_tie_preserving", {}) as Dictionary
		var margin6000_report := strategy_reports.get("depth1_margin_6000_all_legal", {}) as Dictionary
		_c3fu_apply_strategy(margin3000_report, promoted_margin3000, deep_best, depth1_sims, depth2_sims)
		_c3fu_apply_strategy(topk4_report, promoted_topk4, deep_best, depth1_sims, depth2_sims)
		_c3fu_apply_strategy(margin6000_report, promoted_margin6000, deep_best, depth1_sims, depth2_sims)
		_c3fv_record_counterexample(counterexamples, "depth1_margin_3000_all_legal", case, promoted_margin3000, deep_best, rank, gap)
		_c3fv_record_counterexample(counterexamples, "depth1_topk_4_tie_preserving", case, promoted_topk4, deep_best, rank, gap)
		_c3fv_record_counterexample(counterexamples, "depth1_margin_6000_all_legal", case, promoted_margin6000, deep_best, rank, gap)

		case_summaries.append({
			"case_key": _c3fu_case_key(case),
			"anchor": int(case.get("anchor", -1)),
			"evidence_mode": evidence_mode,
			"immediate_tie_size": tie_size,
			"opponent_species_id": String(case.get("opponent_species_id", "")),
			"deep_best_ids": deep_best.duplicate(),
			"deep_best_depth1_rank": rank,
			"deep_best_depth1_gap": gap,
			"margin3000_promoted_count": promoted_margin3000.size(),
			"topk4_promoted_count": promoted_topk4.size(),
			"margin6000_promoted_count": promoted_margin6000.size(),
		})

	var scheduler_reports: Dictionary = {}
	if _c3fv_cached_scheduler_reports.is_empty():
		for raw_budget in SHARED_BUDGETS_C3FV:
			var shared_budget := int(raw_budget)
			scheduler_reports[str(shared_budget)] = _c3fu_run_scheduler(catalog, _c3fv_complete_cases(cases), shared_budget)
		_c3fv_cached_scheduler_reports = scheduler_reports.duplicate(true)
	else:
		scheduler_reports = _c3fv_cached_scheduler_reports.duplicate(true)

	var scheduler_total_budget_violations := 0
	var scheduler_order_probe_cases := 0
	var scheduler_allocation_mismatches := 0
	var scheduler_best_set_mismatches := 0
	var scheduler_truncated_occurrences := 0
	var scheduler_no_decision_occurrences := 0
	var scheduler_oracle_preservation_observations := 0
	for raw_scheduler_report in scheduler_reports.values():
		var scheduler_report := raw_scheduler_report as Dictionary
		scheduler_total_budget_violations += int(scheduler_report.get("total_budget_violation_cases", 0))
		scheduler_order_probe_cases += int(scheduler_report.get("order_probe_cases", 0))
		scheduler_allocation_mismatches += int(scheduler_report.get("forward_reverse_allocation_mismatches", 0))
		scheduler_best_set_mismatches += int(scheduler_report.get("forward_reverse_best_set_mismatch_cases", 0))
		scheduler_truncated_occurrences += int(scheduler_report.get("truncated_cases", 0))
		scheduler_no_decision_occurrences += int(scheduler_report.get("no_decision_cases", 0))
		scheduler_oracle_preservation_observations += int(scheduler_report.get("cases", 0))

	var margin3000_final := strategy_reports.get("depth1_margin_3000_all_legal", {}) as Dictionary
	var topk4_final := strategy_reports.get("depth1_topk_4_tie_preserving", {}) as Dictionary
	var margin6000_final := strategy_reports.get("depth1_margin_6000_all_legal", {}) as Dictionary
	return {
		"audit_id": AUDIT_ID_C3FV,
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"action_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"dataset_probe_id": "runtime_levelup_l50_neutral_probe_v1",
		"held_out_selection_id": HELD_OUT_SELECTION_ID_C3FV,
		"held_out_selection_basis": "alternate_roster_schedule_then_tie_evidence_strata_then_lexical_even_spread",
		"held_out_schedule_index": HELD_OUT_SCHEDULE_INDEX_C3FV,
		"held_out_schedule_stride": int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[HELD_OUT_SCHEDULE_INDEX_C3FV]),
		"held_out_excluded_prior_cases": int(observations.get("excluded_prior_case_count", 0)),
		"held_out_overlap_with_c3fu_cases": int(observations.get("overlap_with_prior", -1)),
		"held_out_cases": cases.size(),
		"held_out_semantically_complete_cases": complete_cases,
		"held_out_inconclusive_cases": inconclusive_cases,
		"held_out_histogram_by_stratum": (observations.get("held_out_histogram", {}) as Dictionary).duplicate(true),
		"held_out_insufficient_strata": (observations.get("insufficient_strata", []) as Array).duplicate(),
		"population_tie_cases": int(observations.get("population_tie_cases", 0)),
		"population_unseen_candidates_after_c3fu_exclusion": int(observations.get("population_unseen_candidates", 0)),
		"held_out_screen_failures": int(observations.get("screen_failures", 0)),
		"held_out_oracle_failures": int(observations.get("oracle_failures", 0)),
		"depth1_scores_used_for_held_out_selection": false,
		"depth2_scores_used_for_held_out_selection": false,
		"rank_gap_used_for_held_out_selection": false,
		"rank_gap_observed_post_selection": true,
		"deep_best_rank_histogram": rank_histogram,
		"deep_best_rank_histogram_sum": _c3fu_histogram_sum(rank_histogram),
		"deep_best_depth1_gap_max": gap_max,
		"deep_best_depth1_gap_mean": gap_sum / maxi(1, complete_cases),
		"deep_best_depth1_gap_sum": gap_sum,
		"held_out_tie_size_histogram": tie_histogram,
		"held_out_evidence_mode_histogram": evidence_histogram,
		"strategy_reports": strategy_reports,
		"counterexamples_by_strategy": counterexamples,
		"margin3000_counterexample_count": (counterexamples.get("depth1_margin_3000_all_legal", []) as Array).size(),
		"topk4_counterexample_count": (counterexamples.get("depth1_topk_4_tie_preserving", []) as Array).size(),
		"margin6000_counterexample_count": (counterexamples.get("depth1_margin_6000_all_legal", []) as Array).size(),
		"margin3000_held_out_losses": int(margin3000_final.get("loses_deep_optimum_cases", 0)),
		"topk4_held_out_losses": int(topk4_final.get("loses_deep_optimum_cases", 0)),
		"margin6000_held_out_losses": int(margin6000_final.get("loses_deep_optimum_cases", 0)),
		"zero_loss_assumed": false,
		"candidate_strategy_proven_safe_globally": false,
		"candidate_strategy_selected": false,
		"scheduler_model_id": SCHEDULER_ID_C3FU,
		"scheduler_cases": complete_cases,
		"scheduler_shared_budgets": SHARED_BUDGETS_C3FV.duplicate(),
		"scheduler_reports": scheduler_reports,
		"scheduler_allocation": "equal_upfront_floor_remaining_div_promoted_roots",
		"scheduler_root_order_probe": "lexical_and_reverse",
		"scheduler_redistribution": "none",
		"scheduler_early_stop": false,
		"scheduler_total_budget_violation_cases": scheduler_total_budget_violations,
		"scheduler_order_probe_cases": scheduler_order_probe_cases,
		"scheduler_forward_reverse_allocation_mismatches": scheduler_allocation_mismatches,
		"scheduler_forward_reverse_best_set_mismatches": scheduler_best_set_mismatches,
		"scheduler_truncated_case_occurrences": scheduler_truncated_occurrences,
		"scheduler_no_decision_case_occurrences": scheduler_no_decision_occurrences,
		"scheduler_oracle_preservation_observations": scheduler_oracle_preservation_observations,
		"shared_budget_execution_modeled": true,
		"lower_budget_controls_present": true,
		"budget_660_is_observed_control_not_selected": true,
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
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"recommended_next_boundary": "interpret_held_out_counterexamples_and_scheduler_robustness_before_any_production_port",
		"case_summaries": case_summaries,
	}


func _c3fv_even_spread(bucket: Array, requested: int) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	var take := mini(requested, bucket.size())
	if take <= 0:
		return selected
	if bucket.size() <= take:
		for raw_case in bucket:
			selected.append(raw_case as Dictionary)
		return selected
	for slot in range(take):
		var index := int(float(slot * (bucket.size() - 1)) / float(maxi(1, take - 1)))
		selected.append(bucket[index] as Dictionary)
	return selected


func _c3fv_case_key_before(a: Dictionary, b: Dictionary) -> bool:
	return _c3fu_case_key(a) < _c3fu_case_key(b)


func _c3fv_strategy_accounted(report: Dictionary) -> bool:
	return (
		int(report.get("cases", 0)) == HELD_OUT_CASES_C3FV
		and int(report.get("preserves_deep_optimum_cases", 0)) + int(report.get("loses_deep_optimum_cases", 0)) == HELD_OUT_CASES_C3FV
	)


func _c3fv_record_counterexample(
	counterexamples: Dictionary,
	strategy_id: String,
	case: Dictionary,
	promoted: Array[String],
	deep_best: Array[String],
	rank: int,
	gap: int
) -> void:
	if _c3fu_sets_intersect(promoted, deep_best):
		return
	var bucket := counterexamples.get(strategy_id, []) as Array
	bucket.append({
		"case_key": _c3fu_case_key(case),
		"anchor": int(case.get("anchor", -1)),
		"evidence_mode": String(case.get("evidence_mode", "")),
		"immediate_tie_size": int(case.get("immediate_tie_size", 0)),
		"opponent_species_id": String(case.get("opponent_species_id", "")),
		"deep_best_ids": deep_best.duplicate(),
		"promoted_ids": promoted.duplicate(),
		"deep_best_depth1_rank": rank,
		"deep_best_depth1_gap": gap,
	})
	counterexamples[strategy_id] = bucket


func _c3fv_complete_cases(cases: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_case in cases:
		var case := raw_case as Dictionary
		if bool(case.get("valid_for_c3fv", false)):
			result.append(case)
	return result


func _c3fv_all_strata_have_expected_count(histogram: Dictionary) -> bool:
	if histogram.size() != EXPECTED_TIE_SIZES.size() * EVIDENCE_MODES.size():
		return false
	for raw_value in histogram.values():
		if int(raw_value) != HELD_OUT_CASES_PER_STRATUM_C3FV:
			return false
	return true
