class_name TrainerAdaptiveBranchingTestSuite
extends TrainerSearchLimitBenchmarkV3TestSuite


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return AdaptiveBranchingTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)


func _search_only_horizon_planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	var profile := TrainerProfile.balanced()
	profile.profile_id = &"search_only_horizon_probe"
	profile.setup_weight_bp = 0
	return AdaptiveBranchingTrainerBrain.new(
		catalog,
		profile,
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)


func _test_branching_limit(by_id: Dictionary) -> void:
	var record := by_id.get("known_fourth_response", {}) as Dictionary
	var planner := record.get("planner", {}) as Dictionary
	var oracle := record.get("oracle", {}) as Dictionary
	_check.call("adaptive_branch_planner_wins_all", int(planner.get("wins", -1)) == 6 and int(planner.get("losses", -1)) == 0)
	_check.call("adaptive_branch_oracle_wins_all", int(oracle.get("wins", -1)) == 6 and int(oracle.get("losses", -1)) == 0)
	var planner_result := _first_result(record, "planner_matches")
	var oracle_result := _first_result(record, "oracle_matches")
	_check.call("adaptive_branch_planner_opens_debuff", _candidate_move_at(planner_result, 0) == B_DEBUFF)
	_check.call("adaptive_branch_oracle_opens_debuff", _candidate_move_at(oracle_result, 0) == B_DEBUFF)
	_check.call("adaptive_branch_actual_reference_uses_nuke", _first_events_contain_move(planner_result, B_NUKE))
	var trace := _first_candidate_trace(planner_result)
	var trace_json := JSON.stringify(trace)
	_check.call("adaptive_branch_trace_includes_public_nuke", trace_json.contains(String(B_NUKE)))
	_check.call("adaptive_branch_trace_still_caps_three", trace_json.contains("\"max_actions_per_side\":3"))
	_check.call("adaptive_branch_search_not_budget_exhausted", trace_json.contains("\"budget_exhausted\":false"))
	_check.call("adaptive_branch_selector_model_recorded", trace_json.contains(TrainerAdaptiveBranchingSearch.BRANCHING_SELECTOR_MODEL))
	_check.call("adaptive_branch_ordering_model_recorded", trace_json.contains(TrainerThreatOrderedWorldFactory.ORDERING_MODEL))
	_check.call("adaptive_branch_weak_tail_is_pruned", not trace_json.contains(String(B_WEAK_C)))
