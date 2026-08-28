extends Node

var _passed := 0
var _failed := 0
var _catalog: DefinitionCatalog
var _client := BattleClient.new()


func _ready() -> void:
	_catalog = _build_catalog()
	_run_all()
	print("\n=== FOUNDATION V1: %d PASS / %d FAIL ===" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	_test_priority()
	_test_speed()
	_test_damage()
	_test_stab()
	_test_effectiveness()
	_test_knockout()
	_test_poison()
	_test_deterministic_rng()
	_test_speed_tie_is_deterministic()
	_test_battle_events()
	_test_serialization_round_trip()
	_test_server_rejects_forged_action()
	_test_client_sends_intent_only()


func _test_priority() -> void:
	var server := _server(11, 50, 5)
	var events := server.submit_turn(_actions(server.state, &"strike", &"quick_strike"))
	var first_action := _first_event(events, BattleEvent.ACTION_USED)
	_check("priority", first_action != null and first_action.actor_id == &"creature_b")


func _test_speed() -> void:
	var server := _server(12, 50, 5)
	var events := server.submit_turn(_actions(server.state, &"strike", &"strike"))
	var first_action := _first_event(events, BattleEvent.ACTION_USED)
	_check("speed", first_action != null and first_action.actor_id == &"creature_a")


func _test_damage() -> void:
	var server := _server(13, 50, 5)
	var target := server.state.creature(&"creature_b")
	var hp_before := target.current_hp
	var events := server.submit_turn(_actions(server.state, &"strike", &"wait"))
	var damage_event := _first_event(events, BattleEvent.DAMAGE_APPLIED)
	_check(
		"damage",
		damage_event != null
		and damage_event.amount > 0
		and target.current_hp == hp_before - damage_event.amount,
	)


func _test_stab() -> void:
	var calculator := DamageCalculator.new()
	var defender := _creature(&"target", &"leafling", 10, 100)
	var fire_attacker := _creature(&"fire", &"embercub", 10, 100)
	var grass_attacker := _creature(&"grass", &"leafling", 10, 100)
	var with_stab := calculator.calculate(
		fire_attacker, defender, _catalog.move(&"ember"), _catalog, SeededRandomSource.new(99)
	)
	var without_stab := calculator.calculate(
		grass_attacker, defender, _catalog.move(&"ember"), _catalog, SeededRandomSource.new(99)
	)
	_check(
		"stab",
		with_stab.stab_basis_points == 15000
		and without_stab.stab_basis_points == 10000
		and with_stab.amount > without_stab.amount,
	)


func _test_effectiveness() -> void:
	var result := DamageCalculator.new().calculate(
		_creature(&"attacker", &"embercub", 10, 100),
		_creature(&"defender", &"leafling", 10, 100),
		_catalog.move(&"ember"),
		_catalog,
		SeededRandomSource.new(21),
	)
	_check("effectiveness", result.effectiveness_basis_points == 20000)


func _test_knockout() -> void:
	var server := _server(14, 50, 5)
	server.state.creature(&"creature_b").current_hp = 1
	var events := server.submit_turn(_actions(server.state, &"strike", &"wait"))
	_check(
		"knockout",
		_first_event(events, BattleEvent.KNOCKED_OUT) != null
		and _first_event(events, BattleEvent.BATTLE_ENDED) != null
		and server.state.phase == BattleState.FINISHED
		and server.state.winner_id == &"creature_a",
	)


func _test_poison() -> void:
	var server := _server(15, 50, 5)
	var poisoned := server.state.creature(&"creature_b")
	poisoned.status_ids.append(&"poison")
	var hp_before := poisoned.current_hp
	var events := server.submit_turn(_actions(server.state, &"wait", &"wait"))
	var status_event := _first_event(events, BattleEvent.STATUS_DAMAGE)
	_check(
		"poison",
		status_event != null
		and status_event.metadata.status_id == "poison"
		and poisoned.current_hp == hp_before - status_event.amount,
	)


func _test_deterministic_rng() -> void:
	var first := _server(8675309, 20, 10)
	var second := _server(8675309, 20, 10)
	var first_events := first.submit_turn(_actions(first.state, &"ember", &"strike"))
	var second_events := second.submit_turn(_actions(second.state, &"ember", &"strike"))
	_check(
		"deterministic_rng",
		JSON.stringify(_event_dicts(first_events)) == JSON.stringify(_event_dicts(second_events))
		and JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot()),
	)


func _test_speed_tie_is_deterministic() -> void:
	var first := _server(44, 10, 10)
	var second := _server(44, 10, 10)
	var first_events := first.submit_turn(_actions(first.state, &"strike", &"strike"))
	var second_events := second.submit_turn(_actions(second.state, &"strike", &"strike"))
	var first_action := _first_event(first_events, BattleEvent.ACTION_USED)
	var second_action := _first_event(second_events, BattleEvent.ACTION_USED)
	_check(
		"deterministic_speed_tie",
		first_action != null
		and second_action != null
		and first_action.actor_id == second_action.actor_id,
	)


func _test_battle_events() -> void:
	var server := _server(16, 50, 5)
	var events := server.submit_turn(_actions(server.state, &"strike", &"wait"))
	var kinds: Array[StringName] = []
	for event in events:
		kinds.append(event.kind)
	var collector := BattleEventCollector.new()
	collector.consume(events)
	_check(
		"battle_events",
		kinds == [
			BattleEvent.ACTION_USED,
			BattleEvent.DAMAGE_APPLIED,
			BattleEvent.ACTION_USED,
			BattleEvent.TURN_ENDED,
		]
		and collector.received.size() == events.size()
		and collector.received[0].has("kind"),
	)


func _test_serialization_round_trip() -> void:
	var server := _server(123456, 50, 5)
	server.state.creature(&"creature_b").status_ids.append(&"poison")
	server.submit_turn(_actions(server.state, &"wait", &"wait"))
	var snapshot := server.snapshot()
	var json_text := JSON.stringify(snapshot)
	var parsed = JSON.parse_string(json_text)
	var restored := BattleState.from_dict(parsed)
	_check(
		"battle_state_serialization",
		json_text == JSON.stringify(restored.to_dict())
		and restored.rng_state == server.state.rng_state
		and restored.creature(&"creature_b").status_ids.has(&"poison"),
	)


func _test_server_rejects_forged_action() -> void:
	var server := _server(17, 50, 5)
	var hp_before := server.state.creature(&"creature_b").current_hp
	var forged := _client.request_move(1, &"creature_a", &"not_owned", &"creature_b")
	var valid := _client.request_move(1, &"creature_b", &"wait", &"creature_a")
	var events := server.submit_turn([forged, valid])
	_check(
		"server_authority",
		events.size() == 1
		and events[0].kind == BattleEvent.ACTION_REJECTED
		and events[0].metadata.reason == "invalid_move"
		and server.state.turn == 0
		and server.state.creature(&"creature_b").current_hp == hp_before,
	)


func _test_client_sends_intent_only() -> void:
	var payload := _client.request_move(1, &"creature_a", &"strike", &"creature_b").to_dict()
	_check(
		"client_intent_only",
		payload.keys().size() == 4
		and not payload.has("damage")
		and not payload.has("hp")
		and not payload.has("winner_id"),
	)


func _server(seed: int, speed_a: int, speed_b: int) -> AuthoritativeBattleServer:
	var first := _creature(&"creature_a", &"embercub", speed_a, 120)
	var second := _creature(&"creature_b", &"leafling", speed_b, 120)
	var state := BattleState.new(&"test_battle", [first, second], seed)
	return AuthoritativeBattleServer.new(state, _catalog)


func _creature(
	id: StringName,
	species_id: StringName,
	speed: int,
	max_hp: int,
) -> CreatureInstance:
	return CreatureInstance.new(
		id,
		species_id,
		20,
		StatBlock.new(max_hp, 30, 20, speed),
		[&"strike", &"quick_strike", &"ember", &"wait"],
	)


func _actions(
	state: BattleState,
	move_a: StringName,
	move_b: StringName,
) -> Array[BattleAction]:
	var turn := state.turn + 1
	return [
		_client.request_move(turn, &"creature_a", move_a, &"creature_b"),
		_client.request_move(turn, &"creature_b", move_b, &"creature_a"),
	]


func _first_event(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event.kind == kind:
			return event
	return null


func _event_dicts(events: Array[BattleEvent]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		result.append(event.to_dict())
	return result


func _build_catalog() -> DefinitionCatalog:
	var catalog := DefinitionCatalog.new()
	for path in [
		"res://data/types/normal.tres",
		"res://data/types/fire.tres",
		"res://data/types/grass.tres",
	]:
		catalog.add_type(load(path) as TypeDefinition)
	for path in [
		"res://data/moves/strike.tres",
		"res://data/moves/quick_strike.tres",
		"res://data/moves/ember.tres",
		"res://data/moves/wait.tres",
	]:
		catalog.add_move(load(path) as MoveDefinition)
	for path in [
		"res://data/species/embercub.tres",
		"res://data/species/leafling.tres",
	]:
		catalog.add_species(load(path) as CreatureSpecies)
	catalog.add_status(load("res://data/statuses/poison.tres") as StatusDefinition)
	return catalog


func _check(test_name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % test_name)
	else:
		_failed += 1
		push_error("FAIL  %s" % test_name)
