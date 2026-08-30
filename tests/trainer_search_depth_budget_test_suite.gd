class_name TrainerSearchDepthBudgetTestSuite
extends RefCounted

const GREEDY_MOVE := &"depth_greedy_hit"
const TANK_MOVE := &"depth_tank_hit"
const OPP_HEAVY := &"depth_opponent_heavy"
const OPP_LIGHT := &"depth_opponent_light"
const OPP_SECRET := &"depth_opponent_secret"

const GLASS_SPECIES := &"depth_glass_species"
const TANK_SPECIES := &"depth_tank_species"
const HEAVY_SPECIES := &"depth_heavy_species"
const LIGHT_SPECIES := &"depth_light_species"

var _check: Callable
var _catalog := DefinitionCatalog.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_build_catalog()
	var tests := [
		"_test_budget_contract_is_deterministic",
		"_test_depth_two_search_is_complete_safe_and_non_mutating",
		"_test_tight_budget_discards_partial_depth_two_matrix",
		"_test_depth_one_budget_never_expands_second_turn",
		"_test_depth_two_avoids_second_turn_horizon_trap",
		"_test_light_pressure_keeps_obvious_attack",
		"_test_planning_benchmark_detects_horizon_improvement",
	]
	for test_name in tests:
		print("TRAINER_DEPTH_BUDGET_TEST %s" % test_name)
		self.call(test_name)


func _build_catalog() -> void:
	var normal := TypeDefinition.new("Normal")
	normal.id = &"normal"
	_catalog.add_type(normal)
	_check.call("depth_fixture_normal_type_available", _catalog.type(&"normal") != null)

	_add_move(GREEDY_MOVE, 140, 0)
	_add_move(TANK_MOVE, 55, 0)
	_add_move(OPP_HEAVY, 90, 1)
	_add_move(OPP_LIGHT, 25, 0)
	_add_move(OPP_SECRET, 300, 2)

	var glass := _species(GLASS_SPECIES, 60, 130, 50, 10, 40)
	glass.learnset.append(LearnSetEntry.new(1, GREEDY_MOVE, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(glass)
	var tank := _species(TANK_SPECIES, 180, 70, 230, 10, 120)
	tank.learnset.append(LearnSetEntry.new(1, TANK_MOVE, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(tank)
	var heavy := _species(HEAVY_SPECIES, 140, 120, 80, 60, 90)
	heavy.learnset.append(LearnSetEntry.new(1, OPP_HEAVY, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(heavy)
	var light := _species(LIGHT_SPECIES, 140, 120, 80, 60, 90)
	light.learnset.append(LearnSetEntry.new(1, OPP_LIGHT, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(light)


func _species(
	id: StringName,
	hp: int,
	attack: int,
	defense: int,
	speed: int,
	special: int,
) -> CreatureSpecies:
	var species := CreatureSpecies.new()
	species.id = id
	species.display_name = String(id)
	species.primary_type_id = &"normal"
	var types: Array[StringName] = [&"normal"]
	species.type_ids = types
	species.base_hp = hp
	species.base_attack = attack
	species.base_defense = defense
	species.base_speed = speed
	species.base_special_attack = special
	species.base_special_defense = special
	return species


func _add_move(id: StringName, power: int, priority: int) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.power = power
	move.type_id = &"normal"
	move.priority = priority
	move.damage_class = "physical"
	move.accuracy = 100
	move.pp = 20
	_catalog.add_move(move)


func _creature(
	id: StringName,
	species_id: StringName,
	stats: StatBlock,
	moves: Array[StringName],
) -> CreatureInstance:
	var creature := CreatureInstance.new(id, species_id, 30, stats, moves)
	creature.initialize_move_pp(_catalog)
	return creature


func _fixture(opponent_move: StringName) -> Dictionary:
	var opponent_species := HEAVY_SPECIES if opponent_move == OPP_HEAVY else LIGHT_SPECIES
	var opponent := _creature(
		&"depth_opponent",
		opponent_species,
		StatBlock.new(200, 150, 110, 90, 120, 120),
		[opponent_move, OPP_SECRET],
	)
	var glass := _creature(
		&"depth_glass",
		GLASS_SPECIES,
		StatBlock.new(120, 250, 80, 40, 70, 80),
		[GREEDY_MOVE],
	)
	var tank := _creature(
		&"depth_tank",
		TANK_SPECIES,
		StatBlock.new(320, 100, 260, 30, 80, 220),
		[TANK_MOVE],
	)
	var party_a: Array[CreatureInstance] = [opponent]
	var party_b: Array[CreatureInstance] = [glass, tank]
	var state := BattleState.create_with_parties(&"depth_fixture", party_a, party_b, 1122334455)
	state.turn = 1
	state.battle_started = true
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	memory.reveal_move(opponent.instance_id, opponent_move)
	var belief := TrainerBeliefState.new()
	belief.begin(memory)
	var inference := TrainerBeliefInference.new(_catalog)
	var observation := TrainerObservationBuilder.build(state, &"side_b", memory)
	inference.seed_from_observation(belief, observation)
	belief.sync_revealed(memory)
	observation = TrainerObservationBuilder.build(state, &"side_b", memory)
	var legal := TrainerActionSpace.from_server(server, &"side_b")
	var context := TrainerDecisionContext.create(observation, belief, memory, legal)
	return {
		"state": state,
		"context": context,
		"glass_id": glass.instance_id,
		"tank_id": tank.instance_id,
		"opponent_id": opponent.instance_id,
	}


func _test_budget_contract_is_deterministic() -> void:
	var budget := TrainerSearchBudget.depth_two_default()
	var a := JSON.stringify(budget.to_dict())
	var b := JSON.stringify(budget.duplicate_budget().to_dict())
	_check.call("depth_budget_defaults_to_two_turns", budget.depth_turns == 2)
	_check.call("depth_budget_has_positive_world_cap", budget.max_worlds > 0)
	_check.call("depth_budget_has_positive_simulation_cap", budget.max_simulations > 0)
	_check.call("depth_budget_has_positive_action_cap", budget.max_actions_per_side > 0)
	_check.call("depth_budget_roundtrip_duplicate_is_stable", a == b)
	_check.call("depth_budget_is_count_based_not_wall_clock", not a.contains("millisecond") and not a.contains("seconds") and a.contains("deterministic_simulation_count_v1"))
	var clamped := TrainerSearchBudget.constrained(9, 0, 0, 0)
	_check.call("depth_budget_clamps_supported_depth", clamped.depth_turns == 2)
	_check.call("depth_budget_clamps_positive_limits", clamped.max_worlds == 1 and clamped.max_simulations == 1 and clamped.max_actions_per_side == 1)


func _test_depth_two_search_is_complete_safe_and_non_mutating() -> void:
	var fx := _fixture(OPP_HEAVY)
	var context := fx.context as TrainerDecisionContext
	var state := fx.state as BattleState
	var action := _move_action(context, GREEDY_MOVE)
	var before := JSON.stringify(state.to_dict())
	var budget := TrainerSearchBudget.constrained(2, 2, 32, 3)
	var search := TrainerMultiTurnSearch.new(_catalog, TrainerProfile.balanced(), budget)
	var first := search.evaluate(context, action)
	var second := search.evaluate(context, action)
	var metadata := first.get("metadata", {}) as Dictionary
	_check.call("depth_search_model_id", String(metadata.get("search_model", "")) == TrainerMultiTurnSearch.SEARCH_MODEL_ID)
	_check.call("depth_search_reaches_second_turn", int(metadata.get("max_depth_reached", 0)) == 2)
	_check.call("depth_search_fully_completes_second_turn", int(metadata.get("fully_completed_depth", 0)) == 2)
	_check.call("depth_search_uses_simulations", int(metadata.get("simulations_used", 0)) > 0)
	_check.call("depth_search_respects_simulation_cap", int(metadata.get("simulations_used", 0)) <= budget.max_simulations)
	_check.call("depth_search_default_fixture_not_exhausted", not bool(metadata.get("budget_exhausted", true)))
	_check.call("depth_search_world_coverage_complete", int(metadata.get("world_coverage_basis_points", 0)) == 10000)
	_check.call("depth_search_deterministic", JSON.stringify(first) == JSON.stringify(second))
	_check.call("depth_search_non_mutating_live_state", JSON.stringify(state.to_dict()) == before)
	var serialized := JSON.stringify(first)
	_check.call("depth_search_no_hidden_actual_move_in_trace", not serialized.contains(String(OPP_SECRET)))
	_check.call("depth_search_no_live_rng_state_in_trace", not serialized.contains("rng_state"))
	_check.call("depth_search_action_sampling_explicit", String(metadata.get("action_sampling_model", "")) == TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL)


func _test_tight_budget_discards_partial_depth_two_matrix() -> void:
	var fx := _fixture(OPP_HEAVY)
	var context := fx.context as TrainerDecisionContext
	var action := _move_action(context, GREEDY_MOVE)
	var budget := TrainerSearchBudget.constrained(2, 2, 3, 3)
	var search := TrainerMultiTurnSearch.new(_catalog, TrainerProfile.balanced(), budget)
	var first := search.evaluate(context, action)
	var second := search.evaluate(context, action)
	var metadata := first.get("metadata", {}) as Dictionary
	_check.call("depth_tight_budget_exact_cap_respected", int(metadata.get("simulations_used", 0)) == 3)
	_check.call("depth_tight_budget_reports_exhaustion", bool(metadata.get("budget_exhausted", false)))
	_check.call("depth_partial_matrix_not_counted_complete", int(metadata.get("completed_depth_two_branch_count", 0)) == 0)
	_check.call("depth_partial_matrix_keeps_max_depth_one", int(metadata.get("max_depth_reached", 0)) == 1)
	_check.call("depth_partial_matrix_keeps_fully_completed_depth_one", int(metadata.get("fully_completed_depth", 0)) == 1)
	_check.call("depth_tight_budget_is_deterministic", JSON.stringify(first) == JSON.stringify(second))


func _test_depth_one_budget_never_expands_second_turn() -> void:
	var fx := _fixture(OPP_HEAVY)
	var context := fx.context as TrainerDecisionContext
	var action := _move_action(context, GREEDY_MOVE)
	var budget := TrainerSearchBudget.constrained(1, 2, 32, 3)
	var result := TrainerMultiTurnSearch.new(_catalog, TrainerProfile.balanced(), budget).evaluate(context, action)
	var metadata := result.get("metadata", {}) as Dictionary
	_check.call("depth_one_reports_requested_depth", int((metadata.get("budget", {}) as Dictionary).get("depth_turns", 0)) == 1)
	_check.call("depth_one_never_reaches_depth_two", int(metadata.get("max_depth_reached", 0)) == 1)
	_check.call("depth_one_has_no_expandable_depth_two_branches", int(metadata.get("expandable_branch_count", 0)) == 0)
	_check.call("depth_one_uses_only_root_simulations", int(metadata.get("simulations_used", 0)) == 2)


func _test_depth_two_avoids_second_turn_horizon_trap() -> void:
	var fx := _fixture(OPP_HEAVY)
	var context := fx.context as TrainerDecisionContext
	var baseline := SearchTrainerBrain.new(_catalog, TrainerProfile.balanced())
	var baseline_action := baseline.choose_action(context)
	_check.call("depth_horizon_fixture_one_turn_prefers_greedy_hit", baseline_action != null and baseline_action.action_type == BattleAction.MOVE and baseline_action.move_id == GREEDY_MOVE)
	var budget := TrainerSearchBudget.constrained(2, 2, 32, 3)
	var planner := DepthSearchTrainerBrain.new(_catalog, TrainerProfile.balanced(), budget)
	var planner_action := planner.choose_action(context)
	_check.call("depth_horizon_planner_returns_action", planner_action != null)
	_check.call("depth_horizon_planner_switches_to_tank", planner_action != null and planner_action.action_type == BattleAction.SWITCH and planner_action.switch_instance_id == fx.tank_id)
	_check.call("depth_horizon_trace_exists", planner.last_trace != null)
	var trace := planner.last_trace.to_dict() if planner.last_trace != null else {}
	_check.call("depth_horizon_trace_uses_depth_model", JSON.stringify(trace).contains(TrainerMultiTurnSearch.SEARCH_MODEL_ID))
	_check.call("depth_horizon_trace_has_no_hidden_move", not JSON.stringify(trace).contains(String(OPP_SECRET)))
	_check.call("depth_horizon_trace_has_no_live_rng", not JSON.stringify(trace).contains("rng_state"))


func _test_light_pressure_keeps_obvious_attack() -> void:
	var fx := _fixture(OPP_LIGHT)
	var context := fx.context as TrainerDecisionContext
	var baseline := SearchTrainerBrain.new(_catalog, TrainerProfile.balanced())
	var planner := DepthSearchTrainerBrain.new(
		_catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 32, 3),
	)
	var baseline_action := baseline.choose_action(context)
	var planner_action := planner.choose_action(context)
	_check.call("depth_light_baseline_attacks", baseline_action != null and baseline_action.action_type == BattleAction.MOVE and baseline_action.move_id == GREEDY_MOVE)
	_check.call("depth_light_planner_attacks", planner_action != null and planner_action.action_type == BattleAction.MOVE and planner_action.move_id == GREEDY_MOVE)
	_check.call("depth_light_baseline_and_planner_agree", TrainerTacticalBenchmark.action_key(baseline_action) == TrainerTacticalBenchmark.action_key(planner_action))


func _test_planning_benchmark_detects_horizon_improvement() -> void:
	var horizon := _fixture(OPP_HEAVY)
	var light := _fixture(OPP_LIGHT)
	var baseline := SearchTrainerBrain.new(_catalog, TrainerProfile.balanced())
	var planner := DepthSearchTrainerBrain.new(
		_catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 32, 3),
	)
	var cases: Array[Dictionary] = [
		{
			"id": "second_turn_ko_trap",
			"context": horizon.context,
			"expected_action_key": "switch:%s" % String(horizon.tank_id),
		},
		{
			"id": "light_pressure_attack",
			"context": light.context,
			"expected_action_key": "move:%s" % String(GREEDY_MOVE),
		},
	]
	var first := TrainerPlanningBenchmark.compare(baseline, planner, cases)
	var second := TrainerPlanningBenchmark.compare(baseline, planner, cases)
	_check.call("depth_benchmark_case_count", int(first.get("case_count", 0)) == 2)
	_check.call("depth_benchmark_planner_matches_both", int(first.get("planner_matched_expected", 0)) == 2)
	_check.call("depth_benchmark_baseline_matches_one", int(first.get("baseline_matched_expected", 0)) == 1)
	_check.call("depth_benchmark_records_one_horizon_improvement", int(first.get("horizon_improvements", 0)) == 1)
	_check.call("depth_benchmark_records_no_regressions", int(first.get("regressions", 0)) == 0)
	_check.call("depth_benchmark_is_deterministic", JSON.stringify(first) == JSON.stringify(second))


func _move_action(context: TrainerDecisionContext, move_id: StringName) -> BattleAction:
	for action in context.legal_actions:
		if action.action_type == BattleAction.MOVE and action.move_id == move_id:
			return action
	return null
