class_name BattleCommandsTestSuite
extends RefCounted

const HIT := &"command_hit"
const BLAST := &"command_blast"
const IDLE := &"command_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_action_command_runs_normal_authoritative_turn",
		"_test_capture_failure_consumes_turn_and_gets_response",
		"_test_capture_success_ends_without_response",
		"_test_missing_ball_is_not_a_turn",
		"_test_invalid_opponent_response_rejected_before_capture",
		"_test_wrong_command_turn_rejected",
		"_test_wrong_command_side_rejected",
		"_test_capture_requires_rng",
		"_test_invalid_player_action_is_not_a_turn",
		"_test_failed_capture_runs_end_turn_status",
		"_test_failed_capture_response_can_finish_battle",
		"_test_command_serialization_round_trip",
	]
	for name in tests:
		print("BCMD_TEST %s" % name)
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
	_add_move(HIT, 40)
	_add_move(BLAST, 10000)
	_add_move(IDLE, 0, "status")


func _add_move(move_id: StringName, power: int, damage_class: String = "physical") -> void:
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


func _player() -> PlayerCollection:
	var pc := PlayerCollection.new()
	var starter := _creature(&"bulbasaur", 10, &"command_player")
	starter.add_move(HIT, _catalog)
	starter.add_move(IDLE, _catalog)
	pc.party.add_creature(starter)
	return pc


func _table() -> WildEncounterTable:
	var table := WildEncounterTable.new(&"command_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"command_slot", &"pikachu", 1, 8, 8))
	return table


func _session(pc: PlayerCollection = null, battle_seed: int = 123) -> WildAdventureSession:
	var actual := pc if pc != null else _player()
	var session := WildAdventureSession.new(actual, _catalog, _rules)
	var encounter := session.begin_encounter(_table(), _rng(99), battle_seed)
	if encounter.creature != null:
		encounter.creature.add_move(HIT, _catalog)
		encounter.creature.add_move(BLAST, _catalog)
		encounter.creature.add_move(IDLE, _catalog)
	return session


func _player_action(session: WildAdventureSession, move_id: StringName = HIT) -> BattleAction:
	var state := session.battle_state()
	var actor := session.player_active()
	var target := session.current_wild()
	return _client.request_move(
		state.turn + 1, actor.instance_id, move_id, target.instance_id, &"side_a"
	)


func _opponent_action(session: WildAdventureSession, move_id: StringName = HIT) -> BattleAction:
	var state := session.battle_state()
	var actor := session.current_wild()
	var target := session.player_active()
	return _client.request_move(
		state.turn + 1, actor.instance_id, move_id, target.instance_id, &"side_b"
	)


func _capture_command(session: WildAdventureSession, ball_id: StringName) -> WildBattleCommand:
	return WildBattleCommand.capture(session.battle_state().turn + 1, &"side_a", ball_id)


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


func _has_action_used(events: Array[BattleEvent], actor_id: StringName, move_id: StringName) -> bool:
	for event in events:
		if event.kind == BattleEvent.ACTION_USED and event.actor_id == actor_id and event.move_id == move_id:
			return true
	return false


func _test_action_command_runs_normal_authoritative_turn() -> void:
	var s := _session()
	var player := s.player_active()
	var wild := s.current_wild()
	var player_pp := player.move_slot(HIT).current_pp
	var wild_pp := wild.move_slot(IDLE).current_pp
	var command := WildBattleCommand.from_action(_player_action(s, HIT))
	var result := s.submit_player_command(command, null, _opponent_action(s, IDLE))
	_check.call("bcmd_action_accepted", result.succeeded() and result.turn_consumed)
	_check.call("bcmd_action_turn_advanced", s.battle_state().turn == 1)
	_check.call("bcmd_action_player_used", _has_action_used(result.battle_events, player.instance_id, HIT))
	_check.call("bcmd_action_both_pp", player.move_slot(HIT).current_pp == player_pp - 1 and wild.move_slot(IDLE).current_pp == wild_pp - 1)


func _test_capture_failure_consumes_turn_and_gets_response() -> void:
	var pc := _player()
	pc.inventory.add(&"poke_ball", 2)
	var s := _session(pc)
	var wild := s.current_wild()
	var player := s.player_active()
	var failure_seed := _find_failure_seed(wild, &"poke_ball")
	var before_hp := player.current_hp
	var before_pp := wild.move_slot(HIT).current_pp
	var result := s.submit_player_command(
		_capture_command(s, &"poke_ball"), _rng(failure_seed), _opponent_action(s, HIT)
	)
	_check.call("bcmd_capture_fail_seed", failure_seed > 0)
	_check.call("bcmd_capture_fail_accepted", result.succeeded() and result.capture_outcome.resolution.result.status == CaptureResult.FAILED)
	_check.call("bcmd_capture_fail_ball", pc.inventory.quantity(&"poke_ball") == 1)
	_check.call("bcmd_capture_fail_turn", result.turn_consumed and s.battle_state().turn == 1)
	_check.call("bcmd_capture_fail_response", _has_action_used(result.battle_events, wild.instance_id, HIT) and wild.move_slot(HIT).current_pp == before_pp - 1)
	_check.call("bcmd_capture_fail_damage", player.current_hp < before_hp)
	_check.call("bcmd_capture_fail_continues", s.has_active_battle() and not result.session_completed)


func _test_capture_success_ends_without_response() -> void:
	var pc := _player()
	pc.inventory.add(&"master_ball", 1)
	var s := _session(pc)
	var wild := s.current_wild()
	var player := s.player_active()
	var wild_id := wild.instance_id
	var before_hp := player.current_hp
	var before_pp := wild.move_slot(BLAST).current_pp
	var result := s.submit_player_command(
		_capture_command(s, &"master_ball"), _rng(222), _opponent_action(s, BLAST)
	)
	_check.call("bcmd_capture_success", result.succeeded() and result.session_completed and result.turn_consumed)
	_check.call("bcmd_capture_success_reason", s.status == WildAdventureSession.COMPLETED and s.completion_reason == WildAdventureSession.COMPLETED_CAPTURED)
	_check.call("bcmd_capture_success_owned", pc.party.contains_instance_id(wild_id))
	_check.call("bcmd_capture_success_ball", pc.inventory.quantity(&"master_ball") == 0)
	_check.call("bcmd_capture_success_no_response", result.battle_events.is_empty() and player.current_hp == before_hp and wild.move_slot(BLAST).current_pp == before_pp)


func _test_missing_ball_is_not_a_turn() -> void:
	var s := _session()
	var wild := s.current_wild()
	var before_pp := wild.move_slot(HIT).current_pp
	var capture_rng := _rng(333)
	var control := _rng(333)
	var result := s.submit_player_command(
		_capture_command(s, &"ultra_ball"), capture_rng, _opponent_action(s, HIT)
	)
	_check.call("bcmd_missing_ball_rejected", not result.accepted and result.reason == "item_not_owned")
	_check.call("bcmd_missing_ball_no_turn", s.battle_state().turn == 0 and not result.turn_consumed)
	_check.call("bcmd_missing_ball_no_response", wild.move_slot(HIT).current_pp == before_pp and result.battle_events.is_empty())
	_check.call("bcmd_missing_ball_no_rng", is_equal_approx(capture_rng.randf(), control.randf()))


func _test_invalid_opponent_response_rejected_before_capture() -> void:
	var pc := _player()
	pc.inventory.add(&"poke_ball", 1)
	var s := _session(pc)
	var invalid := _opponent_action(s, HIT)
	invalid.turn += 1
	var capture_rng := _rng(444)
	var control := _rng(444)
	var result := s.submit_player_command(_capture_command(s, &"poke_ball"), capture_rng, invalid)
	_check.call("bcmd_bad_response_rejected", not result.accepted and result.reason == "invalid_opponent_response:wrong_turn")
	_check.call("bcmd_bad_response_ball_safe", pc.inventory.quantity(&"poke_ball") == 1)
	_check.call("bcmd_bad_response_no_turn", s.battle_state().turn == 0)
	_check.call("bcmd_bad_response_no_rng", is_equal_approx(capture_rng.randf(), control.randf()))


func _test_wrong_command_turn_rejected() -> void:
	var pc := _player()
	pc.inventory.add(&"poke_ball", 1)
	var s := _session(pc)
	var command := _capture_command(s, &"poke_ball")
	command.turn += 1
	var result := s.submit_player_command(command, _rng(500), _opponent_action(s, HIT))
	_check.call("bcmd_wrong_turn", not result.accepted and result.reason == "wrong_turn")
	_check.call("bcmd_wrong_turn_no_mutation", pc.inventory.quantity(&"poke_ball") == 1 and s.battle_state().turn == 0)


func _test_wrong_command_side_rejected() -> void:
	var pc := _player()
	pc.inventory.add(&"poke_ball", 1)
	var s := _session(pc)
	var command := WildBattleCommand.capture(1, &"side_b", &"poke_ball")
	var result := s.submit_player_command(command, _rng(501), _opponent_action(s, HIT))
	_check.call("bcmd_wrong_side", not result.accepted and result.reason == "wrong_participant")
	_check.call("bcmd_wrong_side_no_mutation", pc.inventory.quantity(&"poke_ball") == 1 and s.battle_state().turn == 0)


func _test_capture_requires_rng() -> void:
	var pc := _player()
	pc.inventory.add(&"poke_ball", 1)
	var s := _session(pc)
	var result := s.submit_player_command(_capture_command(s, &"poke_ball"), null, _opponent_action(s, HIT))
	_check.call("bcmd_rng_required", not result.accepted and result.reason == "capture_rng_required")
	_check.call("bcmd_rng_required_safe", pc.inventory.quantity(&"poke_ball") == 1 and s.battle_state().turn == 0)


func _test_invalid_player_action_is_not_a_turn() -> void:
	var s := _session()
	var player := s.player_active()
	var wild := s.current_wild()
	var player_pp := player.move_slot(HIT).current_pp
	var wild_pp := wild.move_slot(HIT).current_pp
	var bad_action := _player_action(s, HIT)
	bad_action.move_id = &"forged_move"
	var result := s.submit_player_command(
		WildBattleCommand.from_action(bad_action), null, _opponent_action(s, HIT)
	)
	_check.call("bcmd_bad_player_action", not result.accepted and result.reason == "invalid_move")
	_check.call("bcmd_bad_player_no_turn", s.battle_state().turn == 0)
	_check.call("bcmd_bad_player_no_pp", player.move_slot(HIT).current_pp == player_pp and wild.move_slot(HIT).current_pp == wild_pp)


func _test_failed_capture_runs_end_turn_status() -> void:
	var pc := _player()
	pc.inventory.add(&"poke_ball", 1)
	var s := _session(pc)
	var player := s.player_active()
	player.status_state.persistent_id = &"poison"
	var failure_seed := _find_failure_seed(s.current_wild(), &"poke_ball")
	var before_hp := player.current_hp
	var result := s.submit_player_command(
		_capture_command(s, &"poke_ball"), _rng(failure_seed), _opponent_action(s, IDLE)
	)
	var has_status_damage := false
	for event in result.battle_events:
		if event.kind == BattleEvent.STATUS_DAMAGE and event.target_id == player.instance_id:
			has_status_damage = true
			break
	_check.call("bcmd_fail_endturn_accepted", result.succeeded() and result.turn_consumed)
	_check.call("bcmd_fail_endturn_status", has_status_damage and player.current_hp < before_hp)


func _test_failed_capture_response_can_finish_battle() -> void:
	var pc := _player()
	pc.inventory.add(&"poke_ball", 1)
	var s := _session(pc)
	var player := s.player_active()
	player.current_hp = 1
	var failure_seed := _find_failure_seed(s.current_wild(), &"poke_ball")
	var result := s.submit_player_command(
		_capture_command(s, &"poke_ball"), _rng(failure_seed), _opponent_action(s, BLAST)
	)
	_check.call("bcmd_fail_can_finish", result.succeeded() and result.battle_finished and s.battle_state().phase == BattleState.FINISHED)
	_check.call("bcmd_fail_player_ko", player.current_hp == 0)
	var settlement := s.settle_finished_battle()
	_check.call("bcmd_fail_defeat_settles", settlement.ok and not settlement.player_won and s.completion_reason == WildAdventureSession.COMPLETED_DEFEAT)


func _test_command_serialization_round_trip() -> void:
	var s := _session()
	var action_command := WildBattleCommand.from_action(_player_action(s, HIT))
	var action_restored := WildBattleCommand.from_dict(action_command.to_dict())
	_check.call("bcmd_ser_action_kind", action_restored.command_type == WildBattleCommand.ACTION and action_restored.action != null)
	_check.call("bcmd_ser_action_fields", action_restored.turn == 1 and action_restored.side_id == &"side_a" and action_restored.action.move_id == HIT)
	var capture_command := WildBattleCommand.capture(1, &"side_a", &"great_ball")
	var capture_restored := WildBattleCommand.from_dict(capture_command.to_dict())
	_check.call("bcmd_ser_capture_kind", capture_restored.command_type == WildBattleCommand.CAPTURE)
	_check.call("bcmd_ser_capture_fields", capture_restored.turn == 1 and capture_restored.side_id == &"side_a" and capture_restored.ball_id == &"great_ball")
