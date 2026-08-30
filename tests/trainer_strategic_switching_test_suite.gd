class_name TrainerStrategicSwitchingTestSuite
extends RefCounted

const TEST_FIRE := &"strategic_switch_fire"
const TEST_WATER := &"strategic_switch_water"
const TEST_GRASS := &"strategic_switch_grass"
const TEST_ELECTRIC := &"strategic_switch_electric"
const TEST_NORMAL := &"strategic_switch_normal"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_no_effect_active_switches_to_valid_counter",
		"_test_bad_matchup_switches_to_clear_counter",
		"_test_good_matchup_does_not_ping_pong",
		"_test_reacts_after_observed_player_switch",
		"_test_switch_trace_is_explainable_and_safe",
	]
	for name in tests:
		print("TRAINER_STRATEGIC_SWITCH_TEST %s" % name)
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
	_add_move(TEST_FIRE, 80, &"fire", "special")
	_add_move(TEST_WATER, 80, &"water", "special")
	_add_move(TEST_GRASS, 80, &"grass", "special")
	_add_move(TEST_ELECTRIC, 80, &"electric", "special")
	_add_move(TEST_NORMAL, 60, &"normal", "physical")


func _add_move(
	move_id: StringName,
	power: int,
	type_id: StringName,
	damage_class: String,
) -> void:
	if _catalog.move_catalog.has(move_id):
		return
	var move := MoveDefinition.new()
	move.id = move_id
	move.display_name = String(move_id)
	move.power = power
	move.type_id = type_id
	move.priority = 0
	move.damage_class = damage_class
	move.accuracy = 100
	move.pp = 30
	_catalog.add_move(move)


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
	seed_value: int = 9101,
) -> BattleState:
	return BattleState.create_with_parties(
		&"trainer_strategic_switch_test",
		party_a,
		party_b,
		seed_value,
	)


func _context(
	server: AuthoritativeBattleServer,
	memory: TrainerBattleMemory = null,
) -> TrainerDecisionContext:
	var local_memory := memory if memory != null else TrainerBattleMemory.new()
	if local_memory.battle_id == &"":
		local_memory.begin(server.state, &"side_b")
	var belief := TrainerBeliefState.new()
	belief.begin(local_memory)
	var observation := TrainerObservationBuilder.build(server.state, &"side_b", local_memory)
	return TrainerDecisionContext.create(
		observation,
		belief,
		local_memory,
		TrainerActionSpace.from_server(server, &"side_b"),
	)


func _test_no_effect_active_switches_to_valid_counter() -> void:
	var player := _creature(&"geodude", 1, &"no_effect_player", [TEST_NORMAL])
	var active := _creature(&"pikachu", 2, &"no_effect_active", [TEST_ELECTRIC])
	var counter := _creature(&"squirtle", 3, &"no_effect_counter", [TEST_WATER])
	var server := AuthoritativeBattleServer.new(_state([player], [active, counter]), _catalog)
	var context := _context(server)

	var tactical := TacticalTrainerBrain.new(_catalog)
	var tactical_choice := tactical.choose_action(context)
	_check.call(
		"strategic_switch_no_effect_tactical_switches",
		tactical_choice != null
		and tactical_choice.action_type == BattleAction.SWITCH
		and tactical_choice.switch_instance_id == counter.instance_id,
	)

	var adaptive := AdaptiveBranchingTrainerBrain.new(_catalog)
	var adaptive_choice := adaptive.choose_action(context)
	_check.call(
		"strategic_switch_no_effect_adaptive_switches",
		adaptive_choice != null
		and adaptive_choice.action_type == BattleAction.SWITCH
		and adaptive_choice.switch_instance_id == counter.instance_id,
	)


func _test_bad_matchup_switches_to_clear_counter() -> void:
	var player := _creature(&"squirtle", 11, &"counter_player", [TEST_WATER])
	var active := _creature(&"charmander", 12, &"counter_active", [TEST_FIRE])
	var counter := _creature(&"pikachu", 13, &"counter_bench", [TEST_ELECTRIC])
	var server := AuthoritativeBattleServer.new(_state([player], [active, counter], 9102), _catalog)
	var context := _context(server)
	var brain := TacticalTrainerBrain.new(_catalog)
	var choice := brain.choose_action(context)
	_check.call(
		"strategic_switch_clear_counter_selected",
		choice != null
		and choice.action_type == BattleAction.SWITCH
		and choice.switch_instance_id == counter.instance_id,
	)

	var evaluator := TrainerStrategicSwitchEvaluator.new(_catalog)
	var switch_action := _switch_action(context, counter.instance_id)
	var result := evaluator.evaluate(context, switch_action)
	var reasons := result.get("reasons", []) as Array
	_check.call(
		"strategic_switch_clear_counter_reason",
		reasons.has("clear_offensive_matchup_gain")
		or reasons.has("escape_super_effective_threat"),
	)


func _test_good_matchup_does_not_ping_pong() -> void:
	var player := _creature(&"bulbasaur", 21, &"stay_player", [TEST_GRASS])
	var active := _creature(&"charmander", 22, &"stay_active", [TEST_FIRE])
	var bench := _creature(&"squirtle", 23, &"stay_bench", [TEST_WATER])
	var server := AuthoritativeBattleServer.new(_state([player], [active, bench], 9103), _catalog)
	var context := _context(server)
	var brain := TacticalTrainerBrain.new(_catalog)
	var choice := brain.choose_action(context)
	_check.call(
		"strategic_switch_good_matchup_stays",
		choice != null
		and choice.action_type == BattleAction.MOVE
		and choice.move_id == TEST_FIRE,
	)

	var evaluator := TrainerStrategicSwitchEvaluator.new(_catalog)
	var result := evaluator.evaluate(context, _switch_action(context, bench.instance_id))
	_check.call(
		"strategic_switch_pointless_switch_penalized",
		int(result.get("score", 0)) < 0
		and (result.get("reasons", []) as Array).has("avoid_pointless_switch"),
	)


func _test_reacts_after_observed_player_switch() -> void:
	var first_player := _creature(&"bulbasaur", 31, &"react_grass", [TEST_GRASS])
	var second_player := _creature(&"squirtle", 32, &"react_water", [TEST_WATER])
	var active := _creature(&"charmander", 33, &"react_active", [TEST_FIRE])
	var counter := _creature(&"pikachu", 34, &"react_counter", [TEST_ELECTRIC])
	var state := _state([first_player, second_player], [active, counter], 9104)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	var brain := TacticalTrainerBrain.new(_catalog)

	var before := brain.choose_action(_context(server, memory))
	_check.call(
		"strategic_switch_before_player_switch_stays",
		before != null and before.action_type == BattleAction.MOVE and before.move_id == TEST_FIRE,
	)

	_check.call(
		"strategic_switch_player_switch_applied",
		state.switch_active(&"side_a", second_player.instance_id),
	)
	memory.mark_seen(second_player.instance_id)
	var after := brain.choose_action(_context(server, memory))
	_check.call(
		"strategic_switch_reacts_to_new_active",
		after != null
		and after.action_type == BattleAction.SWITCH
		and after.switch_instance_id == counter.instance_id,
	)


func _test_switch_trace_is_explainable_and_safe() -> void:
	var player := _creature(&"geodude", 41, &"trace_player", [TEST_NORMAL])
	var active := _creature(&"pikachu", 42, &"trace_active", [TEST_ELECTRIC])
	var counter := _creature(&"squirtle", 43, &"trace_counter", [TEST_WATER])
	var server := AuthoritativeBattleServer.new(_state([player], [active, counter], 9105), _catalog)
	var brain := AdaptiveBranchingTrainerBrain.new(_catalog)
	var choice := brain.choose_action(_context(server))
	var trace_json := JSON.stringify(brain.last_trace.to_dict())
	_check.call(
		"strategic_switch_trace_selected_switch",
		choice != null and choice.action_type == BattleAction.SWITCH,
	)
	_check.call(
		"strategic_switch_trace_model_present",
		trace_json.contains(TrainerStrategicSwitchEvaluator.MODEL_ID),
	)
	_check.call(
		"strategic_switch_trace_reason_present",
		trace_json.contains("active_has_no_effective_damage"),
	)
	_check.call(
		"strategic_switch_trace_no_hidden_private_stats",
		not trace_json.contains("\"ivs\"")
		and not trace_json.contains("\"evs\"")
		and not trace_json.contains("nature_id")
		and not trace_json.contains("rng_state"),
	)


func _switch_action(context: TrainerDecisionContext, target_id: StringName) -> BattleAction:
	for action in context.legal_actions:
		if action.action_type == BattleAction.SWITCH and action.switch_instance_id == target_id:
			return action
	return null
