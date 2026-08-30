class_name WildRunCommandTestSuite
extends RefCounted

const HIT := &"run_hit"

var _check: Callable
var _catalog: DefinitionCatalog
var _progression := ProgressionRuleset.new()
var _client := BattleClient.new()
var _escape := WildEscapeRuleset.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_move()
	var tests := [
		"_test_ruleset_contract",
		"_test_run_serialization_round_trip",
		"_test_faster_run_is_guaranteed_without_rng_or_reaction",
		"_test_slow_run_requires_valid_reaction_before_rng",
		"_test_slow_run_requires_rng_without_mutation",
		"_test_failed_run_consumes_turn_and_gets_one_response",
		"_test_attempt_bonus_accumulates",
		"_test_success_after_failure_ends_without_second_response",
		"_test_failed_run_can_end_in_defeat",
		"_test_invalid_run_does_not_increment_attempts",
	]
	for name in tests:
		print("RUN_TEST %s" % name)
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
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _add_test_move() -> void:
	if _catalog.move_catalog.has(HIT):
		return
	var move := MoveDefinition.new()
	move.id = HIT
	move.display_name = "Run Hit"
	move.power = 40
	move.type_id = &"normal"
	move.priority = 0
	move.damage_class = "physical"
	move.accuracy = -1
	move.pp = 40
	_catalog.add_move(move)


func _creature(species_id: StringName, seed_value: int, instance_id: StringName) -> CreatureInstance:
	var creature := CreatureFactory.create(
		_catalog.species_catalog.get_by_id(species_id),
		8,
		_catalog,
		_progression,
		_rng(seed_value),
		{"instance_id": instance_id},
	)
	creature.add_move(HIT, _catalog)
	return creature


func _session(battle_seed: int = 21001) -> WildAdventureSession:
	var player := PlayerCollection.new()
	player.party.add_creature(_creature(&"bulbasaur", 21010, &"run_player"))
	player.inventory.add(&"poke_ball", 2)
	var session := WildAdventureSession.new(player, _catalog, _progression)
	var table := WildEncounterTable.new(&"run_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"run_slot", &"pikachu", 1, 8, 8))
	var encounter := session.begin_encounter(table, _rng(21020), battle_seed)
	if encounter.creature != null:
		encounter.creature.add_move(HIT, _catalog)
	return session


func _run_command(session: WildAdventureSession) -> WildBattleCommand:
	return WildBattleCommand.run(session.battle_state().turn + 1, &"side_a")


func _opponent_action(session: WildAdventureSession) -> BattleAction:
	var state := session.battle_state()
	return _client.request_move(
		state.turn + 1,
		session.current_wild().instance_id,
		HIT,
		session.player_active().instance_id,
		&"side_b",
	)


func _find_roll_seed(odds: int, want_success: bool) -> int:
	for seed_value in range(1, 10000):
		var roll := _rng(seed_value).randi_range(0, WildEscapeRuleset.ROLL_MAX)
		if (roll < odds) == want_success:
			return seed_value
	return -1


func _test_ruleset_contract() -> void:
	var guaranteed := _escape.resolve(100, 100, 1, null)
	_check.call("run_ruleset_id", WildEscapeRuleset.ID == &"calvo_escape_v1")
	_check.call("run_faster_guaranteed", guaranteed.succeeded() and not guaranteed.rng_consumed)
	_check.call("run_attempt_bonus", _escape.odds(10, 100, 2) - _escape.odds(10, 100, 1) == WildEscapeRuleset.ATTEMPT_BONUS)
	var a := _escape.resolve(10, 100, 1, _rng(77))
	var b := _escape.resolve(10, 100, 1, _rng(77))
	_check.call("run_rng_deterministic", a.roll == b.roll and a.escaped == b.escaped and a.rng_consumed and b.rng_consumed)


func _test_run_serialization_round_trip() -> void:
	var command := WildBattleCommand.run(7, &"side_a")
	var restored := WildBattleCommand.from_dict(command.to_dict())
	_check.call("run_serial_kind", restored.command_type == WildBattleCommand.RUN)
	_check.call("run_serial_turn", restored.turn == 7)
	_check.call("run_serial_side", restored.side_id == &"side_a")
	_check.call("run_serial_no_forged_action", restored.action == null and restored.ball_id == &"")


func _test_faster_run_is_guaranteed_without_rng_or_reaction() -> void:
	var session := _session(21101)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 200
	wild.stats.speed = 20
	player.stat_stages.change(StatStages.ATTACK, 3)
	player.status_state.add_volatile(&"run_marker")
	var player_pp := player.move_slot(HIT).current_pp
	var wild_pp := wild.move_slot(HIT).current_pp
	var balls := session.player.inventory.quantity(&"poke_ball")
	var result := session.submit_player_command(_run_command(session), null, null, null)
	_check.call("run_fast_success", result.succeeded() and result.escape_resolution != null and result.escape_resolution.escaped)
	_check.call("run_fast_no_rng", not result.escape_resolution.rng_consumed)
	_check.call("run_fast_completed", result.turn_consumed and result.session_completed and session.status == WildAdventureSession.COMPLETED and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("run_fast_no_response", result.battle_events.is_empty() and wild.move_slot(HIT).current_pp == wild_pp)
	_check.call("run_fast_player_pp_safe", player.move_slot(HIT).current_pp == player_pp)
	_check.call("run_fast_inventory_safe", session.player.inventory.quantity(&"poke_ball") == balls)
	_check.call("run_fast_transient_reconciled", player.stat_stages.get_stage(StatStages.ATTACK) == 0 and player.status_state.volatile.is_empty())


func _test_slow_run_requires_valid_reaction_before_rng() -> void:
	var session := _session(21201)
	session.player_active().stats.speed = 1
	session.current_wild().stats.speed = 200
	var escape_rng := _rng(21277)
	var control := _rng(21277)
	var result := session.submit_player_command(_run_command(session), null, null, escape_rng)
	_check.call("run_bad_reaction_rejected", not result.accepted and result.reason.begins_with("invalid_opponent_response:"))
	_check.call("run_bad_reaction_no_attempt", session.escape_attempts() == 0 and session.battle_state().turn == 0)
	_check.call("run_bad_reaction_rng_safe", escape_rng.randi() == control.randi())


func _test_slow_run_requires_rng_without_mutation() -> void:
	var session := _session(21301)
	session.player_active().stats.speed = 1
	session.current_wild().stats.speed = 200
	var wild_pp := session.current_wild().move_slot(HIT).current_pp
	var result := session.submit_player_command(_run_command(session), null, _opponent_action(session), null)
	_check.call("run_rng_required", not result.accepted and result.reason == "escape_rng_required")
	_check.call("run_rng_required_no_attempt", session.escape_attempts() == 0 and session.battle_state().turn == 0)
	_check.call("run_rng_required_no_response", session.current_wild().move_slot(HIT).current_pp == wild_pp)


func _test_failed_run_consumes_turn_and_gets_one_response() -> void:
	var session := _session(21401)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	var odds := _escape.odds(player.stats.speed, wild.stats.speed, 1)
	var failure_seed := _find_roll_seed(odds, false)
	var hp_before := player.current_hp
	var wild_pp := wild.move_slot(HIT).current_pp
	var result := session.submit_player_command(_run_command(session), null, _opponent_action(session), _rng(failure_seed))
	_check.call("run_fail_seed", failure_seed > 0)
	_check.call("run_fail_accepted", result.succeeded() and result.escape_resolution != null and not result.escape_resolution.escaped)
	_check.call("run_fail_turn", result.turn_consumed and session.battle_state().turn == 1 and session.escape_attempts() == 1)
	_check.call("run_fail_rng_once", result.escape_resolution.rng_consumed)
	_check.call("run_fail_response_once", wild.move_slot(HIT).current_pp == wild_pp - 1)
	_check.call("run_fail_damage", player.current_hp < hp_before)
	_check.call("run_fail_continues", session.has_active_battle() and not result.session_completed)


func _test_attempt_bonus_accumulates() -> void:
	var session := _session(21501)
	session.player_active().stats.speed = 1
	session.current_wild().stats.speed = 200
	var odds1 := _escape.odds(1, 200, 1)
	var odds2 := _escape.odds(1, 200, 2)
	var fail1 := _find_roll_seed(odds1, false)
	var first := session.submit_player_command(_run_command(session), null, _opponent_action(session), _rng(fail1))
	var fail2 := _find_roll_seed(odds2, false)
	var second := session.submit_player_command(_run_command(session), null, _opponent_action(session), _rng(fail2))
	_check.call("run_attempt_first_failed", first.succeeded() and not first.escape_resolution.escaped)
	_check.call("run_attempt_second_failed", second.succeeded() and not second.escape_resolution.escaped)
	_check.call("run_attempt_count_two", session.escape_attempts() == 2 and session.battle_state().turn == 2)
	_check.call("run_attempt_odds_grow", second.escape_resolution.odds == first.escape_resolution.odds + WildEscapeRuleset.ATTEMPT_BONUS)


func _test_success_after_failure_ends_without_second_response() -> void:
	var session := _session(21601)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	var fail_seed := _find_roll_seed(_escape.odds(1, 200, 1), false)
	var first := session.submit_player_command(_run_command(session), null, _opponent_action(session), _rng(fail_seed))
	var pp_after_fail := wild.move_slot(HIT).current_pp
	var success_seed := _find_roll_seed(_escape.odds(1, 200, 2), true)
	var second := session.submit_player_command(_run_command(session), null, _opponent_action(session), _rng(success_seed))
	_check.call("run_then_success_first_failed", first.succeeded() and not first.escape_resolution.escaped)
	_check.call("run_then_success_seed", success_seed > 0)
	_check.call("run_then_success_completed", second.succeeded() and second.escape_resolution.escaped and second.session_completed and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("run_then_success_no_second_response", second.battle_events.is_empty() and wild.move_slot(HIT).current_pp == pp_after_fail)
	_check.call("run_then_success_attempt_two", second.escape_resolution.attempt == 2)


func _test_failed_run_can_end_in_defeat() -> void:
	var session := _session(21701)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	player.current_hp = 1
	var fail_seed := _find_roll_seed(_escape.odds(1, 200, 1), false)
	var result := session.submit_player_command(_run_command(session), null, _opponent_action(session), _rng(fail_seed))
	_check.call("run_defeat_failed_escape", result.succeeded() and not result.escape_resolution.escaped)
	_check.call("run_defeat_battle_finished", result.battle_finished and player.is_knocked_out())
	var settlement := session.settle_finished_battle()
	_check.call("run_defeat_settled", settlement.ok and not settlement.player_won and session.completion_reason == WildAdventureSession.COMPLETED_DEFEAT)


func _test_invalid_run_does_not_increment_attempts() -> void:
	var session := _session(21801)
	session.player_active().stats.speed = 1
	session.current_wild().stats.speed = 200
	var bad := WildBattleCommand.run(session.battle_state().turn + 2, &"side_a")
	var escape_rng := _rng(21877)
	var control := _rng(21877)
	var result := session.submit_player_command(bad, null, _opponent_action(session), escape_rng)
	_check.call("run_invalid_wrong_turn", not result.accepted and result.reason == "wrong_turn")
	_check.call("run_invalid_no_attempt", session.escape_attempts() == 0 and session.battle_state().turn == 0)
	_check.call("run_invalid_rng_safe", escape_rng.randi() == control.randi())
