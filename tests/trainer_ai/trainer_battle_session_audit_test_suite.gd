class_name TrainerBattleSessionAuditTestSuite
extends RefCounted

const BLAST := &"trainer_audit_blast"
const IDLE := &"trainer_audit_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_duplicate_opponent_identity_rejected",
		"_test_empty_opponent_identity_rejected",
		"_test_reset_while_active_rejected",
		"_test_wrong_opponent_side_rejected_without_turn",
		"_test_forged_player_actor_rejected_by_battle_core",
		"_test_stale_turn_rejected_without_mutation",
		"_test_multi_roster_forced_replacement_and_victory",
		"_test_submit_after_settlement_rejected",
		"_test_second_settlement_rejected",
		"_test_fainted_first_opponent_selects_living_active",
	]
	for name in tests:
		print("TRAINER_BATTLE_AUDIT %s" % name)
		self.call(name)


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


func _add_test_moves() -> void:
	var blast := MoveDefinition.new()
	blast.id = BLAST
	blast.display_name = "Trainer Audit Blast"
	blast.power = 10000
	blast.type_id = &"normal"
	blast.priority = 10
	blast.damage_class = "physical"
	blast.accuracy = -1
	blast.pp = 20
	_catalog.add_move(blast)

	var idle := MoveDefinition.new()
	idle.id = IDLE
	idle.display_name = "Trainer Audit Idle"
	idle.power = 0
	idle.type_id = &"normal"
	idle.priority = 0
	idle.damage_class = "status"
	idle.accuracy = -1
	idle.pp = 40
	_catalog.add_move(idle)


func _creature(species_id: StringName, seed_value: int, instance_id: StringName) -> CreatureInstance:
	return CreatureFactory.create(
		_catalog.species_catalog.get_by_id(species_id),
		5,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	)


func _ensure_move(creature: CreatureInstance, move_id: StringName) -> void:
	if not creature.has_move(move_id):
		creature.add_move(move_id, _catalog)


func _player_with(creature: CreatureInstance) -> PlayerCollection:
	var collection := PlayerCollection.new()
	collection.party.add_creature(creature)
	return collection


func _roster(creatures: Array[CreatureInstance]) -> Array[CreatureInstance]:
	return creatures


func _session(player_creature: CreatureInstance) -> TrainerBattleSession:
	return TrainerBattleSession.new(_player_with(player_creature), _catalog, _rules)


func _actions(
	session: TrainerBattleSession,
	player_move: StringName,
	opponent_move: StringName,
) -> Array[BattleAction]:
	var state := session.battle_state()
	var player_creature := state.active_for_side(&"side_a")
	var opponent_creature := state.active_for_side(&"side_b")
	var out: Array[BattleAction] = [
		_client.request_move(
			state.turn + 1,
			player_creature.instance_id,
			player_move,
			opponent_creature.instance_id,
			&"side_a",
		),
		_client.request_move(
			state.turn + 1,
			opponent_creature.instance_id,
			opponent_move,
			player_creature.instance_id,
			&"side_b",
		),
	]
	return out


func _has_rejection(events: Array[BattleEvent]) -> bool:
	for event in events:
		if event != null and event.kind == BattleEvent.ACTION_REJECTED:
			return true
	return false


func _test_duplicate_opponent_identity_rejected() -> void:
	var player := _creature(&"bulbasaur", 101, &"audit_dup_player")
	var foe_a := _creature(&"charmander", 102, &"audit_dup_foe")
	var foe_b := _creature(&"squirtle", 103, &"audit_dup_foe")
	var foes: Array[CreatureInstance] = [foe_a, foe_b]
	var session := _session(player)
	var ok := session.begin_battle(&"audit_duplicate", foes, 101)
	_check.call("trainer_audit_duplicate_rejected", not ok and session.last_error == "invalid_opponent_roster:duplicate_creature_identity")
	_check.call("trainer_audit_duplicate_no_battle", not session.has_active_battle())


func _test_empty_opponent_identity_rejected() -> void:
	var player := _creature(&"bulbasaur", 104, &"audit_empty_player")
	var foe := _creature(&"charmander", 105, &"audit_empty_foe")
	foe.instance_id = &""
	var foes: Array[CreatureInstance] = [foe]
	var session := _session(player)
	var ok := session.begin_battle(&"audit_empty", foes, 102)
	_check.call("trainer_audit_empty_id_rejected", not ok and session.last_error == "invalid_opponent_roster:creature_identity_required")
	_check.call("trainer_audit_empty_id_no_battle", not session.has_active_battle())


func _test_reset_while_active_rejected() -> void:
	var player := _creature(&"bulbasaur", 106, &"audit_reset_player")
	var foe := _creature(&"charmander", 107, &"audit_reset_foe")
	var foes: Array[CreatureInstance] = [foe]
	var session := _session(player)
	_check.call("trainer_audit_reset_begin", session.begin_battle(&"audit_reset", foes, 103))
	_check.call("trainer_audit_reset_active_rejected", not session.reset_after_completion() and session.last_error == "session_not_completed")
	_check.call("trainer_audit_reset_active_preserved", session.has_active_battle() and session.opponent_active() == foe)


func _test_wrong_opponent_side_rejected_without_turn() -> void:
	var player := _creature(&"bulbasaur", 108, &"audit_side_player")
	var foe := _creature(&"charmander", 109, &"audit_side_foe")
	_ensure_move(player, IDLE)
	_ensure_move(foe, IDLE)
	var foes: Array[CreatureInstance] = [foe]
	var session := _session(player)
	session.begin_battle(&"audit_side", foes, 104)
	var actions := _actions(session, IDLE, IDLE)
	var turn_before := session.battle_state().turn
	actions[1].side_id = &"side_a"
	var events := session.submit_player_action(actions[0], actions[1])
	_check.call("trainer_audit_wrong_opponent_side", events.is_empty() and session.last_error == "wrong_opponent_side")
	_check.call("trainer_audit_wrong_opponent_no_turn", session.battle_state().turn == turn_before)


func _test_forged_player_actor_rejected_by_battle_core() -> void:
	var player := _creature(&"bulbasaur", 110, &"audit_forge_player")
	var foe := _creature(&"charmander", 111, &"audit_forge_foe")
	_ensure_move(player, IDLE)
	_ensure_move(foe, IDLE)
	var foes: Array[CreatureInstance] = [foe]
	var session := _session(player)
	session.begin_battle(&"audit_forge", foes, 105)
	var state := session.battle_state()
	var turn_before := state.turn
	var forged := _client.request_move(
		state.turn + 1,
		foe.instance_id,
		IDLE,
		player.instance_id,
		&"side_a",
	)
	var valid_foe := _client.request_move(
		state.turn + 1,
		foe.instance_id,
		IDLE,
		player.instance_id,
		&"side_b",
	)
	var events := session.submit_player_action(forged, valid_foe)
	_check.call("trainer_audit_forged_actor_core_rejects", _has_rejection(events))
	_check.call("trainer_audit_forged_actor_reason", not session.last_error.is_empty())
	_check.call("trainer_audit_forged_actor_no_turn", session.battle_state().turn == turn_before)


func _test_stale_turn_rejected_without_mutation() -> void:
	var player := _creature(&"bulbasaur", 112, &"audit_stale_player")
	var foe := _creature(&"charmander", 113, &"audit_stale_foe")
	_ensure_move(player, IDLE)
	_ensure_move(foe, IDLE)
	var foes: Array[CreatureInstance] = [foe]
	var session := _session(player)
	session.begin_battle(&"audit_stale", foes, 106)
	var actions := _actions(session, IDLE, IDLE)
	var turn_before := session.battle_state().turn
	actions[0].turn = turn_before
	var events := session.submit_player_action(actions[0], actions[1])
	_check.call("trainer_audit_stale_core_rejects", _has_rejection(events))
	_check.call("trainer_audit_stale_reason", not session.last_error.is_empty())
	_check.call("trainer_audit_stale_no_turn", session.battle_state().turn == turn_before)


func _test_multi_roster_forced_replacement_and_victory() -> void:
	var player := _creature(&"bulbasaur", 114, &"audit_multi_player")
	var foe_a := _creature(&"charmander", 115, &"audit_multi_foe_a")
	var foe_b := _creature(&"squirtle", 116, &"audit_multi_foe_b")
	_ensure_move(player, BLAST)
	_ensure_move(foe_a, IDLE)
	_ensure_move(foe_b, IDLE)
	foe_a.current_hp = 1
	foe_b.current_hp = 1
	var foes: Array[CreatureInstance] = [foe_a, foe_b]
	var session := _session(player)
	_check.call("trainer_audit_multi_begin", session.begin_battle(&"audit_multi", foes, 107))
	var first := _actions(session, BLAST, IDLE)
	var first_events := session.submit_player_action(first[0], first[1])
	_check.call("trainer_audit_multi_first_events", not first_events.is_empty())
	_check.call("trainer_audit_multi_forced_replacement", session.battle_state().phase != BattleState.FINISHED and session.opponent_active() == foe_b)
	var second := _actions(session, BLAST, IDLE)
	var second_events := session.submit_player_action(second[0], second[1])
	_check.call("trainer_audit_multi_second_events", not second_events.is_empty())
	_check.call("trainer_audit_multi_finished", session.battle_state().phase == BattleState.FINISHED)
	var settlement := session.settle_finished_battle()
	_check.call("trainer_audit_multi_victory", settlement.ok and settlement.player_won and session.completion_reason == TrainerBattleSession.COMPLETED_VICTORY)


func _test_submit_after_settlement_rejected() -> void:
	var player := _creature(&"bulbasaur", 117, &"audit_after_player")
	var foe := _creature(&"charmander", 118, &"audit_after_foe")
	_ensure_move(player, BLAST)
	_ensure_move(foe, IDLE)
	foe.current_hp = 1
	var foes: Array[CreatureInstance] = [foe]
	var session := _session(player)
	session.begin_battle(&"audit_after", foes, 108)
	var actions := _actions(session, BLAST, IDLE)
	session.submit_player_action(actions[0], actions[1])
	session.settle_finished_battle()
	var after := session.submit_player_action(actions[0], actions[1])
	_check.call("trainer_audit_submit_after_empty", after.is_empty())
	_check.call("trainer_audit_submit_after_reason", session.last_error == "no_active_trainer_battle")


func _test_second_settlement_rejected() -> void:
	var player := _creature(&"bulbasaur", 119, &"audit_settle_player")
	var foe := _creature(&"charmander", 120, &"audit_settle_foe")
	_ensure_move(player, BLAST)
	_ensure_move(foe, IDLE)
	foe.current_hp = 1
	var foes: Array[CreatureInstance] = [foe]
	var session := _session(player)
	session.begin_battle(&"audit_settle", foes, 109)
	var actions := _actions(session, BLAST, IDLE)
	session.submit_player_action(actions[0], actions[1])
	var first := session.settle_finished_battle()
	var second := session.settle_finished_battle()
	_check.call("trainer_audit_first_settlement_ok", first.ok)
	_check.call("trainer_audit_second_settlement_rejected", not second.ok and second.reason == "no_active_trainer_battle")


func _test_fainted_first_opponent_selects_living_active() -> void:
	var player := _creature(&"bulbasaur", 121, &"audit_order_player")
	var fainted := _creature(&"charmander", 122, &"audit_order_fainted")
	var living := _creature(&"squirtle", 123, &"audit_order_living")
	fainted.current_hp = 0
	var foes: Array[CreatureInstance] = [fainted, living]
	var session := _session(player)
	_check.call("trainer_audit_order_begin", session.begin_battle(&"audit_order", foes, 110))
	_check.call("trainer_audit_order_living_active", session.opponent_active() == living)
	_check.call("trainer_audit_order_fainted_retained", session.battle_state().side_for_creature(fainted.instance_id).side_id == &"side_b")
