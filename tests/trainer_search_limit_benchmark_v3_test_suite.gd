class_name TrainerSearchLimitBenchmarkV3TestSuite
extends TrainerSearchLimitBenchmarkV2TestSuite

# V3 records the empirical result of the horizon probes instead of preserving the
# original falsified expectation. Both balanced and setup_weight=0 planners chain
# the same three-turn line through receding-horizon replanning. Therefore FASE 27
# does not claim depth=2 as a demonstrated bottleneck.


func _test_isolated_horizon_limit(by_id: Dictionary) -> void:
	var record := by_id.get("isolated_three_turn_horizon", {}) as Dictionary
	var planner := record.get("planner", {}) as Dictionary
	var oracle := record.get("oracle", {}) as Dictionary
	_check.call("limit_horizon_isolated_planner_wins_all", int(planner.get("wins", -1)) == 6 and int(planner.get("losses", -1)) == 0)
	_check.call("limit_horizon_isolated_oracle_wins_all", int(oracle.get("wins", -1)) == 6 and int(oracle.get("losses", -1)) == 0)
	var planner_result := _first_result(record, "planner_matches")
	var oracle_result := _first_result(record, "oracle_matches")
	_check.call("limit_horizon_isolated_planner_opens_focus", _candidate_move_at(planner_result, 0) == H_ATTACK_SETUP)
	_check.call("limit_horizon_isolated_planner_speed_setup_second", _candidate_move_at(planner_result, 1) == H_SPEED_SETUP)
	_check.call("limit_horizon_isolated_planner_strikes_third", _candidate_move_at(planner_result, 2) == H_STRIKE)
	_check.call("limit_horizon_isolated_planner_finishes_in_three_turns", int(planner_result.get("turn_count", 0)) == 3)
	_check.call("limit_horizon_isolated_oracle_opens_speed_setup", _candidate_move_at(oracle_result, 0) == H_SPEED_SETUP)
	_check.call("limit_horizon_isolated_oracle_focus_second", _candidate_move_at(oracle_result, 1) == H_ATTACK_SETUP)
	_check.call("limit_horizon_isolated_oracle_strikes_third", _candidate_move_at(oracle_result, 2) == H_STRIKE)
	var trace := _first_candidate_trace(planner_result)
	var trace_json := JSON.stringify(trace)
	_check.call("limit_horizon_isolated_uses_probe_profile", String(trace.get("profile_id", "")) == "search_only_horizon_probe")
	_check.call("limit_horizon_isolated_depth_two_complete", trace_json.contains("\"fully_completed_depth\":2"))
	_check.call("limit_horizon_isolated_not_budget_exhausted", trace_json.contains("\"budget_exhausted\":false"))


func _scenarios() -> Array[Dictionary]:
	var scenarios := super._scenarios()
	for scenario in scenarios:
		if String(scenario.get("id", "")) == "isolated_three_turn_horizon":
			scenario["family"] = "receding_horizon_without_setup_prior_positive_control"
			scenario["expected_limit"] = "depth_two_still_chains_three_turn_plan_without_setup_weight"
	return scenarios
