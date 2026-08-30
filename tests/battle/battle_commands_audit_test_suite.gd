class_name BattleCommandsAuditTestSuite
extends RefCounted

const HIT := &"command_audit_hit"
const IDLE := &"command_audit_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_move(HIT, 40, "physical")
	_add_move(IDLE, 0, "status")
	_test_failed_capture_exactly_one_response_and_player_pp_untouched()
	_test_same_side_response_is_rejected_before_capture()
	_test_full_party_success_routes_to_storage_without_response()


func _import_pokeapi() -> GameData:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	return DataImporter.new().import_dataset(raw, manifest)["game_data"]


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text()) as Dictionary


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _add_move(move_id: StringName, power: int, damage_class: String) -> void:
	if _catalog.move_catalog.has(move_id):
		return
	var move := MoveDefinition.new()
	move.id = move_id
	move.display_name = String(move_id)
	move.power = power
	move.type_id = &"normal"
	move.priority = 0
	move.damage_class = damage_class
	move.accuracy = -1
	move.pp = 40
	_catalog.add_move(move)


func _creature(species_id: StringName, seed_value: int, instance_id: StringName) -> CreatureInstance:
	return CreatureFactory.create(
		_catalog.species_catalog.get_by_id(species_id),
		8,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	)


func _session(pc: PlayerCollection) -> WildAdventureSession:
	var session := WildAdventureSession.new(pc, _catalog, _rules)
	var table := WildEncounterTable.new(&"command_audit_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"command_audit_slot", &"pikachu", 1, 8, 8))
	var encounter := session.begin_encounter(table, _rng(990), 777)
	if encounter.creature != null:
		encounter.creature.add_move(HIT, _catalog)
		encounter.creature.add_move(IDLE, _catalog)
	return session


func _player_collection(count: int = 1) -> PlayerCollection:
	var pc := PlayerCollection.new()
	for i in range(count):
		var creature := _creature(&"bulbasaur", 100 + i, StringName("audit_player_%d" % i))
		creature.add_move(HIT, _catalog)
		creature.add_move(IDLE, _catalog)
		pc.party.add_creature(creature)
	return pc


func _opponent_action(session: WildAdventureSession, move_id: StringName) -> BattleAction:
	var state := session.battle_state()
	var actor := session.current_wild()
	var target := session.player_active()
	return _client.request_move(
		state.turn + 1, actor.instance_id, move_id, target.instance_id, &"side_b"
	)


func _player_action(session: WildAdventureSession, move_id: StringName) -> BattleAction:
	var state := session.battle_state()
	var actor := session.player_active()
	var target := session.current_wild()
	return _client.request_move(
		state.turn + 1, actor.instance_id, move_id, target.instance_id, &"side_a"
	)


func _find_failure_seed(target: CreatureInstance, ball_id: StringName) -> int:
	var capture_rules := CaptureRuleset.new()
	var species := _catalog.species_catalog.get_by_id(target.species_id)
	var ball := capture_rules.ball(ball_id)
	var probability := capture_rules.catch_probability(
		species.capture_rate,
		ball.base_multiplier,
		capture_rules.status_bonus(target.status_state.persistent_id),
		target.stats.max_hp,
		target.current_hp,
	)
	for seed_value in range(1, 5000):
		if _rng(seed_value).randf() >= probability:
			return seed_value
	return -1


func _action_used_count(events: Array[BattleEvent], actor_id: StringName) -> int:
	var count := 0
	for event in events:
		if event.kind == BattleEvent.ACTION_USED and event.actor_id == actor_id:
			count += 1
	return count


func _test_failed_capture_exactly_one_response_and_player_pp_untouched() -> void:
	var pc := _player_collection()
	pc.inventory.add(&"poke_ball", 2)
	var session := _session(pc)
	var player := session.player_active()
	var wild := session.current_wild()
	var player_pp := player.move_slot(HIT).current_pp
	var wild_pp := wild.move_slot(HIT).current_pp
	var seed_value := _find_failure_seed(wild, &"poke_ball")
	var capture_rng := _rng(seed_value)
	var control := _rng(seed_value)
	control.randf() # CaptureSystem uses one probability draw for this valid non-guaranteed attempt.
	var result := session.submit_player_command(
		WildBattleCommand.capture(1, &"side_a", &"poke_ball"),
		capture_rng,
		_opponent_action(session, HIT),
	)
	_check.call("bcmd_audit_player_pp_untouched", player.move_slot(HIT).current_pp == player_pp)
	_check.call("bcmd_audit_exactly_one_response", _action_used_count(result.battle_events, wild.instance_id) == 1 and wild.move_slot(HIT).current_pp == wild_pp - 1)
	_check.call("bcmd_audit_capture_rng_once", is_equal_approx(capture_rng.randf(), control.randf()))


func _test_same_side_response_is_rejected_before_capture() -> void:
	var pc := _player_collection()
	pc.inventory.add(&"poke_ball", 1)
	var session := _session(pc)
	var capture_rng := _rng(888)
	var control := _rng(888)
	var result := session.submit_player_command(
		WildBattleCommand.capture(1, &"side_a", &"poke_ball"),
		capture_rng,
		_player_action(session, HIT),
	)
	_check.call("bcmd_audit_same_side_rejected", not result.accepted and result.reason == "invalid_opponent_response:reaction_same_side")
	_check.call("bcmd_audit_same_side_ball_safe", pc.inventory.quantity(&"poke_ball") == 1)
	_check.call("bcmd_audit_same_side_no_turn", session.battle_state().turn == 0)
	_check.call("bcmd_audit_same_side_no_rng", is_equal_approx(capture_rng.randf(), control.randf()))


func _test_full_party_success_routes_to_storage_without_response() -> void:
	var pc := _player_collection(6)
	pc.inventory.add(&"master_ball", 1)
	var session := _session(pc)
	var wild := session.current_wild()
	var wild_id := wild.instance_id
	var wild_pp := wild.move_slot(HIT).current_pp
	var result := session.submit_player_command(
		WildBattleCommand.capture(1, &"side_a", &"master_ball"),
		_rng(999),
		_opponent_action(session, HIT),
	)
	_check.call("bcmd_audit_full_party_success", result.succeeded() and result.session_completed)
	_check.call("bcmd_audit_full_party_stays_six", pc.party.size() == 6)
	_check.call("bcmd_audit_full_party_storage_identity", pc.storage.contains_instance_id(wild_id) and pc.storage.get_creature(wild_id) == wild)
	_check.call("bcmd_audit_full_party_no_response", result.battle_events.is_empty() and wild.move_slot(HIT).current_pp == wild_pp)
