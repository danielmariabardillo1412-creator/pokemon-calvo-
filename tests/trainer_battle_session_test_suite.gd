class_name TrainerBattleSessionTestSuite
extends RefCounted

const BLAST := &"trainer_test_blast"
const IDLE := &"trainer_test_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_missing_trainer_id_rejected",
		"_test_no_alive_player_rejected",
		"_test_no_alive_opponent_rejected",
		"_test_identity_overlap_rejected",
		"_test_begin_builds_real_battle",
		"_test_begin_while_active_rejected",
		"_test_no_wild_only_commands_exposed",
		"_test_settlement_requires_finished_battle",
		"_test_wrong_side_rejected_without_turn",
		"_test_victory_settles_and_applies_progression",
		"_test_defeat_settles_without_progression",
		"_test_reset_allows_next_trainer_battle",
	]
	for name in tests:
		print("TRAINER_BATTLE_TEST %s" % name)
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
	if not _catalog.move_catalog.has(BLAST):
		var blast := MoveDefinition.new()
		blast.id = BLAST
		blast.display_name = "Trainer Test Blast"
		blast.power = 10000
		blast.type_id = &"normal"
		blast.priority = 10
		blast.damage_class = "physical"
		blast.accuracy = -1
		blast.pp = 20
		_catalog.add_move(blast)
	if not _catalog.move_catalog.has(IDLE):
		var idle := MoveDefinition.new()
		idle.id = IDLE
		idle.display_name = "Trainer Test Idle"
		idle.power = 0
		idle.type_id = &"normal"
		idle.priority = 0
		idle.damage_class = "status"
		idle.accuracy = -1
		idle.pp = 40
		_catalog.add_move(idle)


func _creature(species_id: StringName, level: int, seed_value: int, instance_id: StringName) -> CreatureInstance:
	return CreatureFactory.create(
		_catalog.species_catalog.get_by_id(species_id),
		level,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	)


func _player_with(creature: CreatureInstance) -> PlayerCollection:
	var collection := PlayerCollection.new()
	collection.party.add_creature(creature)
	return collection


func _session(player_collection: PlayerCollection) -> TrainerBattleSession:
	return TrainerBattleSession.new(player_collection, _catalog, _rules)


func _roster(creature: CreatureInstance) -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = [creature]
	return out


func _ensure_move(creature: CreatureInstance, move_id: StringName) -> void:
	if not creature.has_move(move_id):
		creature.add_move(move_id, _catalog)


func _move_actions(
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


func _test_missing_trainer_id_rejected() -> void:
	var player := _creature(&"bulbasaur", 5, 1, &"trainer_player_1")
	var foe := _creature(&"charmander", 5, 2, &"trainer_foe_1")
	var session := _session(_player_with(player))
	var ok := session.begin_battle(&"", _roster(foe), 1)
	_check.call("trainer_missing_id_rejected", not ok and session.last_error == "trainer_id_required")
	_check.call("trainer_missing_id_no_battle", not session.has_active_battle() and session.status == TrainerBattleSession.READY)


func _test_no_alive_player_rejected() -> void:
	var player := _creature(&"bulbasaur", 5, 3, &"trainer_player_ko")
	player.current_hp = 0
	var foe := _creature(&"charmander", 5, 4, &"trainer_foe_2")
	var session := _session(_player_with(player))
	var ok := session.begin_battle(&"trainer_a", _roster(foe), 2)
	_check.call("trainer_no_alive_player_rejected", not ok and session.last_error == "no_available_player_creature")
	_check.call("trainer_no_alive_player_no_battle", not session.has_active_battle())


func _test_no_alive_opponent_rejected() -> void:
	var player := _creature(&"bulbasaur", 5, 5, &"trainer_player_3")
	var foe := _creature(&"charmander", 5, 6, &"trainer_foe_ko")
	foe.current_hp = 0
	var session := _session(_player_with(player))
	var ok := session.begin_battle(&"trainer_b", _roster(foe), 3)
	_check.call("trainer_no_alive_foe_rejected", not ok and session.last_error == "no_available_opponent_creature")
	_check.call("trainer_no_alive_foe_no_battle", not session.has_active_battle())


func _test_identity_overlap_rejected() -> void:
	var player := _creature(&"bulbasaur", 5, 7, &"shared_identity")
	var foe := _creature(&"charmander", 5, 8, &"shared_identity")
	var session := _session(_player_with(player))
	var ok := session.begin_battle(&"trainer_overlap", _roster(foe), 4)
	_check.call("trainer_identity_overlap_rejected", not ok and session.last_error == "creature_identity_overlap")
	_check.call("trainer_identity_overlap_no_battle", not session.has_active_battle())


func _test_begin_builds_real_battle() -> void:
	var player := _creature(&"bulbasaur", 5, 9, &"trainer_player_begin")
	var foe := _creature(&"charmander", 5, 10, &"trainer_foe_begin")
	var session := _session(_player_with(player))
	var ok := session.begin_battle(&"trainer_real", _roster(foe), 777)
	_check.call("trainer_begin_ok", ok and session.has_active_battle())
	_check.call("trainer_begin_identity", session.opponent_trainer_id == &"trainer_real")
	_check.call("trainer_begin_same_player_ref", session.player_active() == player)
	_check.call("trainer_begin_same_foe_ref", session.opponent_active() == foe)
	_check.call("trainer_begin_sides", session.battle_state().side_for_creature(player.instance_id).side_id == &"side_a" and session.battle_state().side_for_creature(foe.instance_id).side_id == &"side_b")


func _test_begin_while_active_rejected() -> void:
	var player := _creature(&"bulbasaur", 5, 11, &"trainer_player_double")
	var foe := _creature(&"charmander", 5, 12, &"trainer_foe_double")
	var second := _creature(&"squirtle", 5, 13, &"trainer_foe_second")
	var session := _session(_player_with(player))
	_check.call("trainer_first_begin_ok", session.begin_battle(&"trainer_first", _roster(foe), 5))
	var state_before := session.battle_state()
	var ok := session.begin_battle(&"trainer_second", _roster(second), 6)
	_check.call("trainer_double_begin_rejected", not ok and session.last_error == "battle_already_active")
	_check.call("trainer_double_begin_keeps_original", session.battle_state() == state_before and session.opponent_active() == foe)


func _test_no_wild_only_commands_exposed() -> void:
	var session := _session(_player_with(_creature(&"bulbasaur", 5, 14, &"trainer_surface_player")))
	_check.call("trainer_no_capture_api", not session.has_method("capture_current"))
	_check.call("trainer_no_run_api", not session.has_method("submit_player_run") and not session.has_method("submit_player_command"))


func _test_settlement_requires_finished_battle() -> void:
	var player := _creature(&"bulbasaur", 5, 15, &"trainer_player_early")
	var foe := _creature(&"charmander", 5, 16, &"trainer_foe_early")
	var session := _session(_player_with(player))
	session.begin_battle(&"trainer_early", _roster(foe), 7)
	var settlement := session.settle_finished_battle()
	_check.call("trainer_early_settlement_rejected", not settlement.ok and settlement.reason == "battle_not_finished")
	_check.call("trainer_early_settlement_keeps_battle", session.has_active_battle())


func _test_wrong_side_rejected_without_turn() -> void:
	var player := _creature(&"bulbasaur", 5, 17, &"trainer_player_side")
	var foe := _creature(&"charmander", 5, 18, &"trainer_foe_side")
	_ensure_move(player, IDLE)
	_ensure_move(foe, IDLE)
	var session := _session(_player_with(player))
	session.begin_battle(&"trainer_side", _roster(foe), 8)
	var actions := _move_actions(session, IDLE, IDLE)
	var turn_before := session.battle_state().turn
	actions[0].side_id = &"side_b"
	var events := session.submit_player_action(actions[0], actions[1])
	_check.call("trainer_wrong_player_side_rejected", events.is_empty() and session.last_error == "wrong_player_side")
	_check.call("trainer_wrong_player_side_no_turn", session.battle_state().turn == turn_before)


func _test_victory_settles_and_applies_progression() -> void:
	var player := _creature(&"bulbasaur", 5, 19, &"trainer_player_win")
	var foe := _creature(&"charmander", 5, 20, &"trainer_foe_win")
	_ensure_move(player, BLAST)
	_ensure_move(foe, IDLE)
	foe.current_hp = 1
	var session := _session(_player_with(player))
	var xp_before := player.experience
	_check.call("trainer_win_begin", session.begin_battle(&"trainer_win", _roster(foe), 9))
	var actions := _move_actions(session, BLAST, IDLE)
	var events := session.submit_player_action(actions[0], actions[1])
	_check.call("trainer_win_events", not events.is_empty())
	_check.call("trainer_win_battle_finished", session.battle_state().phase == BattleState.FINISHED)
	var settlement := session.settle_finished_battle()
	_check.call("trainer_win_settled", settlement.ok and settlement.player_won and settlement.session_completed)
	_check.call("trainer_win_reason", session.status == TrainerBattleSession.COMPLETED and session.completion_reason == TrainerBattleSession.COMPLETED_VICTORY)
	_check.call("trainer_win_progression", player.experience > xp_before and not settlement.progression_events.is_empty())
	_check.call("trainer_win_reconciled", player.current_hp > 0 and player.stat_stages.get_stage(StatStages.ATTACK) == 0)


func _test_defeat_settles_without_progression() -> void:
	var player := _creature(&"bulbasaur", 5, 21, &"trainer_player_loss")
	var foe := _creature(&"charmander", 5, 22, &"trainer_foe_loss")
	_ensure_move(player, IDLE)
	_ensure_move(foe, BLAST)
	player.current_hp = 1
	var session := _session(_player_with(player))
	var xp_before := player.experience
	_check.call("trainer_loss_begin", session.begin_battle(&"trainer_loss", _roster(foe), 10))
	var actions := _move_actions(session, IDLE, BLAST)
	session.submit_player_action(actions[0], actions[1])
	_check.call("trainer_loss_battle_finished", session.battle_state().phase == BattleState.FINISHED)
	var settlement := session.settle_finished_battle()
	_check.call("trainer_loss_settled", settlement.ok and not settlement.player_won and settlement.progression_events.is_empty())
	_check.call("trainer_loss_reason", session.status == TrainerBattleSession.COMPLETED and session.completion_reason == TrainerBattleSession.COMPLETED_DEFEAT)
	_check.call("trainer_loss_no_xp", player.experience == xp_before)


func _test_reset_allows_next_trainer_battle() -> void:
	var player := _creature(&"bulbasaur", 5, 23, &"trainer_player_reset")
	var foe := _creature(&"charmander", 5, 24, &"trainer_foe_reset_1")
	_ensure_move(player, BLAST)
	_ensure_move(foe, IDLE)
	foe.current_hp = 1
	var session := _session(_player_with(player))
	session.begin_battle(&"trainer_reset_1", _roster(foe), 11)
	var actions := _move_actions(session, BLAST, IDLE)
	session.submit_player_action(actions[0], actions[1])
	session.settle_finished_battle()
	_check.call("trainer_reset_completed", session.status == TrainerBattleSession.COMPLETED)
	_check.call("trainer_reset_ok", session.reset_after_completion() and session.status == TrainerBattleSession.READY)
	var second := _creature(&"squirtle", 5, 25, &"trainer_foe_reset_2")
	_check.call("trainer_reset_second_begin", session.begin_battle(&"trainer_reset_2", _roster(second), 12) and session.has_active_battle())
	_check.call("trainer_reset_second_identity", session.opponent_trainer_id == &"trainer_reset_2" and session.opponent_active() == second)
