class_name TrainerTacticalIntelligenceTestSuite
extends RefCounted

const TEST_FIRE := &"trainer_tactical_fire"
const TEST_NORMAL := &"trainer_tactical_normal"
const TEST_ELECTRIC := &"trainer_tactical_electric"
const TEST_GRASS := &"trainer_tactical_grass"
const TEST_IDLE := &"trainer_tactical_idle"
const TEST_SETUP := &"trainer_tactical_setup"
const TEST_POISON := &"trainer_tactical_poison"
const TEST_WEAK := &"trainer_tactical_weak"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_profile_contract",
		"_test_action_space_uses_battle_core_legality",
		"_test_tactical_prefers_super_effective_move",
		"_test_blunder_guard_blocks_known_immunity",
		"_test_structured_effect_utility_and_status_immunity",
		"_test_switch_matchup_evaluation",
		"_test_team_preservation_layer",
		"_test_controller_keeps_brain_on_safe_context",
		"_test_trace_and_benchmark_are_deterministic",
	]
	for name in tests:
		print("TRAINER_TACTICAL_TEST %s" % name)
		self.call(name)


func _import_pokeapi() -> GameData:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(
		_load_json("res://data/manifests/pokemon_api_manifest.json")
	)
	return DataImporter.new().import_dataset(raw, manifest)["game_data"]


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _add_test_moves() -> void:
	_add_move(TEST_FIRE, "Tactical Fire", 80, &"fire", "special", 100)
	_add_move(TEST_NORMAL, "Tactical Normal", 60, &"normal", "physical", 100)
	_add_move(TEST_ELECTRIC, "Tactical Electric", 80, &"electric", "special", 100)
	_add_move(TEST_GRASS, "Tactical Grass", 80, &"grass", "special", 100)
	_add_move(TEST_WEAK, "Tactical Weak", 20, &"normal", "physical", -1)
	_add_move(TEST_IDLE, "Tactical Idle", 0, &"normal", "status", -1)

	var setup := _add_move(TEST_SETUP, "Tactical Setup", 0, &"normal", "status", -1)
	setup.effect_specs = [
		BattleEffectSpec.new(
			BattleEffectSpec.MODIFY_STAT_STAGE,
			BattleEffectSpec.SELF,
			2,
			0,
			10000,
			&"",
			StatStages.ATTACK,
		)
	]

	var poison := _add_move(TEST_POISON, "Tactical Poison", 0, &"poison", "status", 100)
	poison.effect_specs = [
		BattleEffectSpec.new(
			BattleEffectSpec.INFLICT_STATUS,
			BattleEffectSpec.OPPONENT,
			0,
			0,
			10000,
			&"poison",
		)
	]


func _add_move(
	move_id: StringName,
	label: String,
	power: int,
	type_id: StringName,
	damage_class: String,
	accuracy: int,
) -> MoveDefinition:
	if _catalog.move_catalog.has(move_id):
		return _catalog.move(move_id)
	var move := MoveDefinition.new()
	move.id = move_id
	move.display_name = label
	move.power = power
	move.type_id = type_id
	move.priority = 0
	move.damage_class = damage_class
	move.accuracy = accuracy
	move.pp = 30
	_catalog.add_move(move)
	return move


func _creature(
	species_id: StringName,
	seed_value: int,
	instance_id: StringName,
	move_ids: Array[StringName],
	level: int = 30,
) -> CreatureInstance:
	return CreatureFactory.create(
		_catalog.species(species_id),
		level,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id, "moves": move_ids},
	)


func _state(
	party_a: Array[CreatureInstance],
	party_b: Array[CreatureInstance],
	seed_value: int = 991,
) -> BattleState:
	return BattleState.create_with_parties(
		&"trainer_tactical_test",
		party_a,
		party_b,
		seed_value,
	)


func _context(
	server: AuthoritativeBattleServer,
	side_id: StringName = &"side_b",
	memory: TrainerBattleMemory = null,
) -> TrainerDecisionContext:
	var local_memory := memory if memory != null else TrainerBattleMemory.new()
	if local_memory.battle_id == &"":
		local_memory.begin(server.state, side_id)
	var belief := TrainerBeliefState.new()
	belief.begin(local_memory)
	var observation := TrainerObservationBuilder.build(server.state, side_id, local_memory)
	return TrainerDecisionContext.create(
		observation,
		belief,
		local_memory,
		TrainerActionSpace.from_server(server, side_id),
	)


func _action_by_move(context: TrainerDecisionContext, move_id: StringName) -> BattleAction:
	for action in context.legal_actions:
		if action.action_type == BattleAction.MOVE and action.move_id == move_id:
			return action
	return null


func _switch_action(context: TrainerDecisionContext, target_id: StringName) -> BattleAction:
	for action in context.legal_actions:
		if (
			action.action_type == BattleAction.SWITCH
			and action.switch_instance_id == target_id
		):
			return action
	return null


func _test_profile_contract() -> void:
	var balanced := TrainerProfile.balanced()
	var aggressive := TrainerProfile.aggressive()
	var cautious := TrainerProfile.cautious()
	var technical := TrainerProfile.technical()
	var round_trip := TrainerProfile.from_dict(
		JSON.parse_string(JSON.stringify(cautious.to_dict()))
	)
	_check.call("tactical_profile_balanced_id", balanced.profile_id == TrainerProfile.BALANCED)
	_check.call(
		"tactical_profile_aggressive_damage",
		aggressive.damage_weight_bp > balanced.damage_weight_bp,
	)
	_check.call(
		"tactical_profile_cautious_preservation",
		cautious.preservation_weight_bp > balanced.preservation_weight_bp,
	)
	_check.call(
		"tactical_profile_technical_status",
		technical.status_weight_bp > balanced.status_weight_bp,
	)
	_check.call(
		"tactical_profile_round_trip",
		JSON.stringify(round_trip.to_dict()) == JSON.stringify(cautious.to_dict()),
	)


func _test_action_space_uses_battle_core_legality() -> void:
	var player := _creature(&"bulbasaur", 1, &"space_player", [TEST_WEAK])
	var trainer := _creature(
		&"charmander",
		2,
		&"space_trainer",
		[TEST_FIRE, TEST_NORMAL],
	)
	var healthy_bench := _creature(&"squirtle", 3, &"space_healthy", [TEST_WEAK])
	var knocked_bench := _creature(&"pikachu", 4, &"space_knocked", [TEST_WEAK])
	var state := _state([player], [trainer, healthy_bench, knocked_bench])
	var server := AuthoritativeBattleServer.new(state, _catalog)
	trainer.move_slot(TEST_NORMAL).current_pp = 0
	knocked_bench.current_hp = 0

	var actions := TrainerActionSpace.from_server(server, &"side_b")
	var has_fire := false
	var has_empty_pp := false
	var has_healthy_switch := false
	var has_knocked_switch := false
	var all_core_valid := true
	for action in actions:
		if action.action_type == BattleAction.MOVE:
			has_fire = has_fire or action.move_id == TEST_FIRE
			has_empty_pp = has_empty_pp or action.move_id == TEST_NORMAL
		else:
			has_healthy_switch = has_healthy_switch or action.switch_instance_id == &"space_healthy"
			has_knocked_switch = has_knocked_switch or action.switch_instance_id == &"space_knocked"
		all_core_valid = (
			all_core_valid
			and server.validate_reaction_action(action, &"side_a").is_empty()
		)

	_check.call("tactical_action_space_has_legal_move", has_fire)
	_check.call("tactical_action_space_excludes_zero_pp", not has_empty_pp)
	_check.call("tactical_action_space_has_legal_switch", has_healthy_switch)
	_check.call("tactical_action_space_excludes_knocked_switch", not has_knocked_switch)
	_check.call("tactical_action_space_all_core_valid", all_core_valid)
	if not actions.is_empty():
		var original_id := actions[0].move_id
		actions[0].move_id = &"forged_after_generation"
		var fresh := TrainerActionSpace.from_server(server, &"side_b")
		_check.call(
			"tactical_action_space_detached",
			not fresh.is_empty() and fresh[0].move_id == original_id,
		)


func _test_tactical_prefers_super_effective_move() -> void:
	var player := _creature(&"bulbasaur", 11, &"super_player", [TEST_WEAK])
	var trainer := _creature(
		&"charmander",
		12,
		&"super_trainer",
		[TEST_FIRE, TEST_NORMAL],
	)
	var server := AuthoritativeBattleServer.new(_state([player], [trainer]), _catalog)
	var context := _context(server)
	var brain := TacticalTrainerBrain.new(_catalog, TrainerProfile.balanced())
	var chosen := brain.choose_action(context)

	_check.call("tactical_super_effective_action_exists", chosen != null)
	_check.call(
		"tactical_super_effective_selected",
		chosen != null and chosen.move_id == TEST_FIRE,
	)
	var trace_json := JSON.stringify(brain.last_trace.to_dict())
	_check.call(
		"tactical_trace_marks_public_proxy",
		trace_json.contains(TrainerTacticalEvaluator.DAMAGE_PROXY_ID),
	)
	_check.call(
		"tactical_trace_no_hidden_enemy_stats",
		not trace_json.contains("\"ivs\"")
		and not trace_json.contains("\"evs\"")
		and not trace_json.contains("\"nature_id\"")
		and not trace_json.contains("\"rng_state\""),
	)


func _test_blunder_guard_blocks_known_immunity() -> void:
	var player := _creature(&"geodude", 21, &"immune_player", [TEST_WEAK])
	var trainer := _creature(
		&"pikachu",
		22,
		&"immune_trainer",
		[TEST_ELECTRIC, TEST_NORMAL],
	)
	var server := AuthoritativeBattleServer.new(_state([player], [trainer]), _catalog)
	var context := _context(server)
	var electric := _action_by_move(context, TEST_ELECTRIC)
	var guard := TrainerBlunderGuard.inspect(context, electric, _catalog)
	var brain := TacticalTrainerBrain.new(_catalog)
	var chosen := brain.choose_action(context)

	_check.call(
		"tactical_guard_known_immunity",
		bool(guard.get("blocked", false))
		and guard.get("reason", "") == "known_type_immunity",
	)
	_check.call(
		"tactical_guard_chooses_nonimmune_alternative",
		chosen != null and chosen.move_id == TEST_NORMAL,
	)


func _test_structured_effect_utility_and_status_immunity() -> void:
	var water_player := _creature(&"squirtle", 31, &"utility_water", [TEST_WEAK])
	var trainer := _creature(
		&"charmander",
		32,
		&"utility_trainer",
		[TEST_SETUP, TEST_POISON, TEST_IDLE],
	)
	var water_server := AuthoritativeBattleServer.new(
		_state([water_player], [trainer]),
		_catalog,
	)
	var water_context := _context(water_server)
	var evaluator := TrainerTacticalEvaluator.new(_catalog, TrainerProfile.technical())
	var setup_result := evaluator.evaluate(
		water_context,
		_action_by_move(water_context, TEST_SETUP),
	)
	var poison_result := evaluator.evaluate(
		water_context,
		_action_by_move(water_context, TEST_POISON),
	)
	var idle_result := evaluator.evaluate(
		water_context,
		_action_by_move(water_context, TEST_IDLE),
	)
	_check.call(
		"tactical_structured_setup_beats_idle",
		int(setup_result.get("score", 0)) > int(idle_result.get("score", 0)),
	)
	_check.call(
		"tactical_structured_status_beats_idle",
		int(poison_result.get("score", 0)) > int(idle_result.get("score", 0)),
	)

	var poison_type_player := _creature(
		&"bulbasaur",
		33,
		&"utility_poison_type",
		[TEST_WEAK],
	)
	var poison_server := AuthoritativeBattleServer.new(
		_state([poison_type_player], [trainer]),
		_catalog,
	)
	var poison_context := _context(poison_server)
	var immune_result := evaluator.evaluate(
		poison_context,
		_action_by_move(poison_context, TEST_POISON),
	)
	_check.call(
		"tactical_status_known_immunity_not_rewarded",
		int(immune_result.get("score", 0)) <= 0,
	)


func _test_switch_matchup_evaluation() -> void:
	var player := _creature(&"squirtle", 41, &"switch_player", [TEST_WEAK])
	var trainer := _creature(&"charmander", 42, &"switch_current", [TEST_FIRE])
	var bench := _creature(&"bulbasaur", 43, &"switch_bench", [TEST_GRASS])
	var server := AuthoritativeBattleServer.new(
		_state([player], [trainer, bench]),
		_catalog,
	)
	var context := _context(server)
	var evaluator := TrainerTacticalEvaluator.new(_catalog)
	var move_result := evaluator.evaluate(
		context,
		_action_by_move(context, TEST_FIRE),
	)
	var switch_result := evaluator.evaluate(
		context,
		_switch_action(context, &"switch_bench"),
	)
	_check.call(
		"tactical_switch_identifies_matchup_gain",
		int(switch_result.get("score", 0)) > 0
		and int(switch_result.get("score", 0)) > -int(move_result.get("score", 0)),
	)
	_check.call(
		"tactical_switch_reason_explainable",
		(switch_result.get("reasons", []) as Array).has("improved_offensive_matchup"),
	)


func _test_team_preservation_layer() -> void:
	var player := _creature(&"geodude", 51, &"strategy_active_enemy", [TEST_WEAK])
	var future := _creature(&"bulbasaur", 52, &"strategy_future_enemy", [TEST_WEAK])
	var trainer := _creature(
		&"charmander",
		53,
		&"strategy_unique_answer",
		[TEST_FIRE],
	)
	var bench := _creature(&"squirtle", 54, &"strategy_bench", [TEST_NORMAL])
	var state := _state([player, future], [trainer, bench])
	var server := AuthoritativeBattleServer.new(state, _catalog)
	trainer.current_hp = maxi(1, trainer.stats.max_hp * 4 / 10)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	memory.mark_seen(&"strategy_future_enemy")
	var context := _context(server, &"side_b", memory)
	var evaluator := TrainerTeamStrategicEvaluator.new(
		_catalog,
		TrainerProfile.cautious(),
	)
	var move_result := evaluator.evaluate(
		context,
		_action_by_move(context, TEST_FIRE),
	)
	var switch_result := evaluator.evaluate(
		context,
		_switch_action(context, &"strategy_bench"),
	)
	_check.call(
		"tactical_team_preservation_penalizes_risk",
		int(move_result.get("score", 0)) < 0,
	)
	_check.call(
		"tactical_team_preservation_rewards_switch",
		int(switch_result.get("score", 0)) > 0,
	)
	_check.call(
		"tactical_team_preservation_explains_unique_answer",
		(move_result.get("reasons", []) as Array).has("risk_unique_answer")
		and (switch_result.get("reasons", []) as Array).has("preserve_unique_answer"),
	)


func _test_controller_keeps_brain_on_safe_context() -> void:
	var player := _creature(
		&"bulbasaur",
		61,
		&"controller_player",
		[TEST_WEAK],
	)
	var trainer := _creature(
		&"charmander",
		62,
		&"controller_trainer",
		[TEST_FIRE, TEST_NORMAL],
	)
	var state := _state([player], [trainer])
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var brain := TacticalTrainerBrain.new(_catalog)
	var controller := TrainerIntelligenceController.new(&"side_b", brain)
	_check.call("tactical_controller_begin", controller.begin(server))
	var chosen := controller.choose_action(server)
	_check.call("tactical_controller_action", chosen != null and chosen.move_id == TEST_FIRE)
	_check.call(
		"tactical_controller_context_safe",
		controller.last_context != null
		and controller.last_context.observation != null
		and not controller.last_context.observation.to_dict().has("rng_state"),
	)

	var player_action := _client.request_move(
		state.turn + 1,
		player.instance_id,
		TEST_WEAK,
		trainer.instance_id,
		&"side_a",
	)
	var actions: Array[BattleAction] = [player_action, chosen]
	var events := server.submit_turn(actions)
	_check.call("tactical_controller_observe", controller.observe(events, server))
	_check.call(
		"tactical_controller_memory_reveal",
		controller.memory.revealed_move_ids(player.instance_id).has(TEST_WEAK),
	)


func _test_trace_and_benchmark_are_deterministic() -> void:
	var grass_player := _creature(&"bulbasaur", 71, &"bench_grass", [TEST_WEAK])
	var fire_trainer := _creature(
		&"charmander",
		72,
		&"bench_fire",
		[TEST_FIRE, TEST_NORMAL],
	)
	var grass_server := AuthoritativeBattleServer.new(
		_state([grass_player], [fire_trainer], 1001),
		_catalog,
	)
	var first_context := _context(grass_server)

	var ground_player := _creature(&"geodude", 73, &"bench_ground", [TEST_WEAK])
	var electric_trainer := _creature(
		&"pikachu",
		74,
		&"bench_electric",
		[TEST_ELECTRIC, TEST_NORMAL],
	)
	var ground_server := AuthoritativeBattleServer.new(
		_state([ground_player], [electric_trainer], 1002),
		_catalog,
	)
	var second_context := _context(ground_server)

	var cases: Array[Dictionary] = [
		{
			"id": "fire_vs_grass",
			"context": first_context,
			"expected_action_key": "move:%s" % String(TEST_FIRE),
		},
		{
			"id": "electric_immunity",
			"context": second_context,
			"expected_action_key": "move:%s" % String(TEST_NORMAL),
		},
	]
	var brain := TacticalTrainerBrain.new(_catalog)
	var first := TrainerTacticalBenchmark.run(brain, cases)
	var second := TrainerTacticalBenchmark.run(brain, cases)
	_check.call(
		"tactical_benchmark_expected",
		int(first.get("matched_expected", 0)) == int(first.get("expected_count", -1)),
	)
	_check.call(
		"tactical_benchmark_no_null",
		int(first.get("null_actions", -1)) == 0,
	)
	_check.call(
		"tactical_benchmark_deterministic_signature",
		first.get("signature", "") == second.get("signature", ""),
	)
	var trace_data := brain.last_trace.to_dict()
	var restored := TrainerDecisionTrace.from_dict(
		JSON.parse_string(JSON.stringify(trace_data))
	)
	_check.call(
		"tactical_trace_round_trip",
		JSON.stringify(restored.to_dict()) == JSON.stringify(trace_data),
	)
