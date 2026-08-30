class_name TrainerSearchFoundationTestSuite
extends RefCounted

const OWN_HIT := &"search_own_hit"
const TANK_HIT := &"search_tank_hit"
const OPP_HEAVY := &"search_opponent_heavy"
const OPP_SECRET := &"search_opponent_secret"
const OPP_BENCH_HIT := &"search_opponent_bench_hit"

const GLASS_SPECIES := &"search_glass_species"
const TANK_SPECIES := &"search_tank_species"
const OPP_SPECIES := &"search_opponent_species"
const OPP_BENCH_SPECIES := &"search_opponent_bench_species"
const ABILITY_A := &"search_ability_a"
const ABILITY_B := &"search_ability_b"

var _check: Callable
var _catalog := DefinitionCatalog.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_build_catalog()
	var tests := [
		"_test_worlds_are_safe_deterministic_and_weighted",
		"_test_hidden_move_and_unseen_bench_do_not_leak",
		"_test_belief_dimensions_materialize_without_live_rng",
		"_test_revealed_ability_prunes_worlds",
		"_test_simultaneous_search_is_deterministic_and_non_mutating",
		"_test_profile_risk_changes_robust_score",
		"_test_search_brain_avoids_glass_cannon_loss",
	]
	for test_name in tests:
		print("TRAINER_SEARCH_TEST %s" % test_name)
		self.call(test_name)


func _build_catalog() -> void:
	_add_move(OWN_HIT, 95, 0)
	_add_move(TANK_HIT, 20, 0)
	_add_move(OPP_HEAVY, 250, 0)
	_add_move(OPP_SECRET, 400, 1)
	_add_move(OPP_BENCH_HIT, 40, 0)

	var glass := _species(GLASS_SPECIES, 40, 70, 45, 20, 45)
	glass.learnset.append(LearnSetEntry.new(1, OWN_HIT, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(glass)
	var tank := _species(TANK_SPECIES, 160, 30, 220, 25, 70)
	tank.learnset.append(LearnSetEntry.new(1, TANK_HIT, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(tank)
	var opponent := _species(OPP_SPECIES, 120, 180, 180, 140, 90)
	var abilities: Array[StringName] = [ABILITY_A, ABILITY_B]
	opponent.ability_ids = abilities
	opponent.learnset.append(LearnSetEntry.new(1, OPP_HEAVY, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(opponent)
	var opponent_bench := _species(OPP_BENCH_SPECIES, 90, 50, 80, 60, 70)
	opponent_bench.learnset.append(LearnSetEntry.new(1, OPP_BENCH_HIT, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(opponent_bench)


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


func _fixture(
	see_opponent_bench: bool = false,
	reveal_ability: bool = false,
) -> Dictionary:
	var opponent := _creature(
		&"search_opponent_active",
		OPP_SPECIES,
		StatBlock.new(320, 260, 220, 180, 90, 100),
		[OPP_HEAVY, OPP_SECRET],
	)
	opponent.ability_id = ABILITY_B
	var opponent_bench := _creature(
		&"search_opponent_bench",
		OPP_BENCH_SPECIES,
		StatBlock.new(220, 90, 120, 80, 70, 90),
		[OPP_BENCH_HIT],
	)
	var glass := _creature(
		&"search_glass",
		GLASS_SPECIES,
		StatBlock.new(100, 190, 20, 40, 60, 40),
		[OWN_HIT],
	)
	var tank := _creature(
		&"search_tank",
		TANK_SPECIES,
		StatBlock.new(320, 55, 260, 30, 45, 180),
		[TANK_HIT],
	)
	var party_a: Array[CreatureInstance] = [opponent, opponent_bench]
	var party_b: Array[CreatureInstance] = [glass, tank]
	var state := BattleState.create_with_parties(&"search_fixture", party_a, party_b, 987654321)
	state.turn = 1
	state.battle_started = true
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	memory.reveal_move(opponent.instance_id, OPP_HEAVY)
	if see_opponent_bench:
		memory.mark_seen(opponent_bench.instance_id)
	if reveal_ability:
		memory.reveal_ability(opponent.instance_id, ABILITY_B)
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
		"server": server,
		"memory": memory,
		"belief": belief,
		"context": context,
		"opponent_id": opponent.instance_id,
		"opponent_bench_id": opponent_bench.instance_id,
		"glass_id": glass.instance_id,
		"tank_id": tank.instance_id,
	}


func _test_worlds_are_safe_deterministic_and_weighted() -> void:
	var fx := _fixture()
	var context := fx.context as TrainerDecisionContext
	var state := fx.state as BattleState
	var before := JSON.stringify(state.to_dict())
	var factory := TrainerPlausibleWorldFactory.new(_catalog)
	var worlds_a := factory.build(context)
	var worlds_b := factory.build(context)
	_check.call("search_worlds_exist", not worlds_a.is_empty())
	_check.call("search_worlds_capped", worlds_a.size() <= TrainerPlausibleWorldFactory.DEFAULT_MAX_WORLDS)
	_check.call("search_world_build_non_mutating", JSON.stringify(state.to_dict()) == before)
	var weight_total := 0
	for world in worlds_a:
		weight_total += world.weight_basis_points
	_check.call("search_world_weights_sum_10000", weight_total == 10000)
	_check.call("search_world_build_deterministic_count", worlds_a.size() == worlds_b.size())
	var same := worlds_a.size() == worlds_b.size()
	for i in mini(worlds_a.size(), worlds_b.size()):
		same = same and JSON.stringify(worlds_a[i].to_dict()) == JSON.stringify(worlds_b[i].to_dict())
	_check.call("search_world_build_deterministic_metadata", same)
	var no_state_serialized := true
	for world in worlds_a:
		no_state_serialized = no_state_serialized and not world.to_dict().has("state")
	_check.call("search_world_record_does_not_serialize_state", no_state_serialized)


func _test_hidden_move_and_unseen_bench_do_not_leak() -> void:
	var fx := _fixture(false, false)
	var context := fx.context as TrainerDecisionContext
	var worlds := TrainerPlausibleWorldFactory.new(_catalog).build(context)
	var hidden_move_absent := true
	var unseen_bench_absent := true
	var secret_text_absent := true
	for world in worlds:
		var active := world.state.active_for_side(&"side_a")
		hidden_move_absent = hidden_move_absent and active != null and not active.has_move(OPP_SECRET)
		unseen_bench_absent = unseen_bench_absent and world.state.creature(fx.opponent_bench_id) == null
		secret_text_absent = secret_text_absent and not JSON.stringify(world.to_dict()).contains(String(OPP_SECRET))
	_check.call("search_hidden_actual_move_not_materialized", hidden_move_absent)
	_check.call("search_unseen_opponent_bench_not_materialized", unseen_bench_absent)
	_check.call("search_hidden_actual_move_not_in_world_metadata", secret_text_absent)
	var actions := TrainerOpponentActionSpace.from_world(worlds[0], context, _catalog)
	_check.call("search_opponent_actions_include_revealed_move", _has_move_action(actions, OPP_HEAVY))
	_check.call("search_opponent_actions_exclude_hidden_move", not _has_move_action(actions, OPP_SECRET))
	_check.call("search_opponent_actions_exclude_unseen_switch", not _has_switch_action(actions, fx.opponent_bench_id))

	var seen_fx := _fixture(true, false)
	var seen_worlds := TrainerPlausibleWorldFactory.new(_catalog).build(seen_fx.context)
	var seen_actions := TrainerOpponentActionSpace.from_world(seen_worlds[0], seen_fx.context, _catalog)
	_check.call("search_seen_bench_can_be_materialized", seen_worlds[0].state.creature(seen_fx.opponent_bench_id) != null)
	_check.call("search_seen_bench_can_be_switch_candidate", _has_switch_action(seen_actions, seen_fx.opponent_bench_id))


func _test_belief_dimensions_materialize_without_live_rng() -> void:
	var fx := _fixture(false, false)
	var context := fx.context as TrainerDecisionContext
	var state := fx.state as BattleState
	var worlds := TrainerPlausibleWorldFactory.new(_catalog).build(context)
	var abilities: Array[String] = []
	var speeds: Array[int] = []
	var rng_is_synthetic := true
	var speed_in_bound := true
	var ranges: Dictionary = context.belief_snapshot.get("ranges", {})
	var creature_ranges: Dictionary = ranges.get(String(fx.opponent_id), {})
	var speed_range: Dictionary = creature_ranges.get(String(TrainerBeliefState.DOMAIN_SPEED), {})
	var low := int(speed_range.get("min_value", 1))
	var high := int(speed_range.get("max_value", low))
	for world in worlds:
		var ability := String(world.metadata.get("active_opponent_ability_id", ""))
		var speed := int(world.metadata.get("active_opponent_speed_sample", 0))
		if not abilities.has(ability):
			abilities.append(ability)
		if not speeds.has(speed):
			speeds.append(speed)
		rng_is_synthetic = rng_is_synthetic and int(world.metadata.get("rng_seed", 0)) != state.rng_state
		speed_in_bound = speed_in_bound and speed >= low and speed <= high
	_check.call("search_worlds_sample_multiple_abilities", abilities.has(String(ABILITY_A)) and abilities.has(String(ABILITY_B)))
	_check.call("search_worlds_sample_multiple_speeds", speeds.size() >= 2)
	_check.call("search_world_speed_samples_inside_public_range", speed_in_bound)
	_check.call("search_world_rng_never_reuses_live_rng", rng_is_synthetic)
	_check.call("search_context_has_no_live_rng", not JSON.stringify(context.to_dict()).contains("rng_state"))
	var unknown_item_assumption := false
	for world in worlds:
		unknown_item_assumption = unknown_item_assumption or world.assumptions.has("opponent_unknown_item_unmodeled")
	_check.call("search_unknown_item_is_explicit_assumption", unknown_item_assumption)


func _test_revealed_ability_prunes_worlds() -> void:
	var fx := _fixture(false, true)
	var worlds := TrainerPlausibleWorldFactory.new(_catalog).build(fx.context)
	var all_revealed := not worlds.is_empty()
	for world in worlds:
		all_revealed = all_revealed and StringName(world.metadata.get("active_opponent_ability_id", "")) == ABILITY_B
	_check.call("search_revealed_ability_prunes_world_hypotheses", all_revealed)
	_check.call("search_revealed_ability_still_samples_rng_speed", worlds.size() >= 3)


func _test_simultaneous_search_is_deterministic_and_non_mutating() -> void:
	var fx := _fixture()
	var context := fx.context as TrainerDecisionContext
	var state := fx.state as BattleState
	var action := _move_action(context, OWN_HIT)
	var before := JSON.stringify(state.to_dict())
	var search := TrainerSimultaneousSearch.new(_catalog, TrainerProfile.balanced())
	var a := search.evaluate(context, action)
	var b := search.evaluate(context, action)
	var metadata := a.get("metadata", {}) as Dictionary
	_check.call("search_evaluation_has_scenarios", int(metadata.get("scenario_count", 0)) > 0)
	_check.call("search_evaluation_has_worlds", int(metadata.get("world_count", 0)) > 0)
	_check.call("search_evaluation_model_id", String(metadata.get("search_model", "")) == TrainerSimultaneousSearch.SEARCH_MODEL_ID)
	_check.call("search_worst_not_above_mean", int(metadata.get("worst_score", 0)) <= int(metadata.get("mean_score", 0)))
	_check.call("search_evaluation_deterministic", JSON.stringify(a) == JSON.stringify(b))
	_check.call("search_evaluation_does_not_mutate_live_state", JSON.stringify(state.to_dict()) == before)
	var serialized := JSON.stringify(a)
	_check.call("search_trace_has_no_hidden_move", not serialized.contains(String(OPP_SECRET)))
	_check.call("search_trace_has_no_rng_state", not serialized.contains("rng_state"))


func _test_profile_risk_changes_robust_score() -> void:
	var fx := _fixture()
	var context := fx.context as TrainerDecisionContext
	var action := _move_action(context, OWN_HIT)
	var aggressive := TrainerSimultaneousSearch.new(_catalog, TrainerProfile.aggressive()).evaluate(context, action)
	var cautious := TrainerSimultaneousSearch.new(_catalog, TrainerProfile.cautious()).evaluate(context, action)
	_check.call(
		"search_cautious_uses_more_worst_case_weight",
		int((cautious.get("metadata", {}) as Dictionary).get("risk_weight_basis_points", 0))
		> int((aggressive.get("metadata", {}) as Dictionary).get("risk_weight_basis_points", 0)),
	)
	_check.call("search_cautious_risky_action_not_scored_higher", int(cautious.get("score", 0)) <= int(aggressive.get("score", 0)))


func _test_search_brain_avoids_glass_cannon_loss() -> void:
	var fx := _fixture()
	var context := fx.context as TrainerDecisionContext
	var tactical := TacticalTrainerBrain.new(_catalog, TrainerProfile.balanced())
	var tactical_choice := tactical.choose_action(context)
	_check.call("search_fixture_tactical_prefers_attack", tactical_choice != null and tactical_choice.action_type == BattleAction.MOVE and tactical_choice.move_id == OWN_HIT)
	var search_brain := SearchTrainerBrain.new(_catalog, TrainerProfile.balanced())
	var search_choice := search_brain.choose_action(context)
	_check.call("search_brain_returns_action", search_choice != null)
	_check.call("search_brain_switches_from_glass_cannon", search_choice != null and search_choice.action_type == BattleAction.SWITCH and search_choice.switch_instance_id == fx.tank_id)
	_check.call("search_brain_trace_exists", search_brain.last_trace != null)
	var trace := search_brain.last_trace.to_dict() if search_brain.last_trace != null else {}
	_check.call("search_brain_trace_model", JSON.stringify(trace).contains(TrainerSimultaneousSearch.SEARCH_MODEL_ID))
	_check.call("search_brain_trace_has_candidate_matrix", JSON.stringify(trace).contains("scenario_count"))
	_check.call("search_brain_trace_no_hidden_move", not JSON.stringify(trace).contains(String(OPP_SECRET)))
	_check.call("search_brain_trace_no_rng_state", not JSON.stringify(trace).contains("rng_state"))


func _move_action(context: TrainerDecisionContext, move_id: StringName) -> BattleAction:
	for action in context.legal_actions:
		if action.action_type == BattleAction.MOVE and action.move_id == move_id:
			return action
	return null


func _has_move_action(actions: Array[BattleAction], move_id: StringName) -> bool:
	for action in actions:
		if action.action_type == BattleAction.MOVE and action.move_id == move_id:
			return true
	return false


func _has_switch_action(actions: Array[BattleAction], creature_id: StringName) -> bool:
	for action in actions:
		if action.action_type == BattleAction.SWITCH and action.switch_instance_id == creature_id:
			return true
	return false
