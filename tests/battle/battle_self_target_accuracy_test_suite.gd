class_name BattleSelfTargetAccuracyTestSuite
extends RefCounted

const SELF_ZERO := &"self_accuracy_zero"
const TARGET_ZERO := &"target_accuracy_zero"
const SELF_IDLE := &"self_accuracy_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _client := BattleClient.new()
var _rules := ProgressionRuleset.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_move(SELF_ZERO, 0, "user")
	_add_move(TARGET_ZERO, 0, "selected-pokemon")
	_add_move(SELF_IDLE, -1, "user")
	_test_self_target_skips_accuracy_check()
	_test_other_target_still_checks_accuracy()


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


func _add_move(move_id: StringName, accuracy: int, target: String) -> void:
	var move := MoveDefinition.new()
	move.id = move_id
	move.display_name = String(move_id)
	move.power = 0
	move.type_id = &"normal"
	move.priority = 0
	move.damage_class = "status"
	move.accuracy = accuracy
	move.pp = 5
	move.target = target
	_catalog.add_move(move)


func _creature(species_id: StringName, instance_id: StringName, seed_value: int) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return CreatureFactory.create(
		_catalog.species_catalog.get_by_id(species_id),
		8,
		_catalog,
		_rules,
		rng,
		{"instance_id": instance_id},
	)


func _server(primary_move: StringName) -> AuthoritativeBattleServer:
	var actor := _creature(&"bulbasaur", &"self_accuracy_actor", 101)
	var opponent := _creature(&"pikachu", &"self_accuracy_opponent", 202)
	actor.add_move(primary_move, _catalog)
	opponent.add_move(SELF_IDLE, _catalog)
	actor.stat_stages.change(StatStages.ACCURACY, -6)
	opponent.stat_stages.change(StatStages.EVASION, 6)
	var state := BattleState.new(&"self_accuracy_test", [actor, opponent], 303)
	return AuthoritativeBattleServer.new(state, _catalog)


func _actions(server: AuthoritativeBattleServer, move_id: StringName) -> Array[BattleAction]:
	var state := server.state
	var actor := state.creature(&"self_accuracy_actor")
	var opponent := state.creature(&"self_accuracy_opponent")
	return [
		_client.request_move(
			state.turn + 1,
			actor.instance_id,
			move_id,
			opponent.instance_id,
			&"side_a",
		),
		_client.request_move(
			state.turn + 1,
			opponent.instance_id,
			SELF_IDLE,
			actor.instance_id,
			&"side_b",
		),
	]


func _test_self_target_skips_accuracy_check() -> void:
	var server := _server(SELF_ZERO)
	var slot := server.state.creature(&"self_accuracy_actor").move_slot(SELF_ZERO)
	var pp_before := slot.current_pp
	var events := server.submit_turn(_actions(server, SELF_ZERO))
	_check.call(
		"battle_self_target_accuracy_no_miss",
		_has_action_used(events, &"self_accuracy_actor", SELF_ZERO)
		and not _has_miss(events, &"self_accuracy_actor", SELF_ZERO),
	)
	_check.call(
		"battle_self_target_accuracy_consumes_pp",
		slot.current_pp == pp_before - 1,
	)


func _test_other_target_still_checks_accuracy() -> void:
	var server := _server(TARGET_ZERO)
	var events := server.submit_turn(_actions(server, TARGET_ZERO))
	_check.call(
		"battle_other_target_accuracy_still_misses",
		_has_miss(events, &"self_accuracy_actor", TARGET_ZERO),
	)


func _has_action_used(
	events: Array[BattleEvent], actor_id: StringName, move_id: StringName
) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.ACTION_USED
			and event.actor_id == actor_id
			and event.move_id == move_id
		):
			return true
	return false


func _has_miss(
	events: Array[BattleEvent], actor_id: StringName, move_id: StringName
) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.MOVE_MISSED
			and event.actor_id == actor_id
			and event.move_id == move_id
		):
			return true
	return false
