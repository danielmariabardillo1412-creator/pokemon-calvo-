class_name WildRunCommandAuditTestSuite
extends RefCounted

const TAP := &"run_audit_tap"

var _check: Callable
var _catalog: DefinitionCatalog
var _progression := ProgressionRuleset.new()
var _client := BattleClient.new()
var _escape := WildEscapeRuleset.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_tap_move()
	var tests := [
		"_test_ruleset_boundaries",
		"_test_session_invalid_speed_precedes_reaction",
		"_test_wrong_side_is_side_effect_free",
		"_test_run_does_not_consume_capture_rng",
		"_test_escape_uses_persistent_speed_not_stages",
		"_test_failed_escape_runs_end_turn_status",
		"_test_flee_preserves_persistent_state_without_rewards",
		"_test_escape_attempt_reset_lifecycle",
	]
	for name in tests:
		print("RUN_AUDIT %s" % name)
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


func _add_tap_move() -> void:
	if _catalog.move_catalog.has(TAP):
		return
	var move := MoveDefinition.new()
	move.id = TAP
	move.display_name = "Run Audit Tap"
	move.power = 1
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
	creature.add_move(TAP, _catalog)
	return creature


func _session(seed_value: int) -> WildAdventureSession:
	var collection := PlayerCollection.new()
	collection.party.add_creature(_creature(&"bulbasaur", seed_value + 1, &"run_audit_player"))
	collection.inventory.add(&"poke_ball", 2)
	var session := WildAdventureSession.new(collection, _catalog, _progression)
	var table := WildEncounterTable.new(&"run_audit_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"run_audit_slot", &"pikachu", 1, 8, 8))
	var encounter := session.begin_encounter(table, _rng(seed_value + 2), seed_value + 3)
	if encounter.creature != null:
		encounter.creature.add_move(TAP, _catalog)
	return session


func _command(session: WildAdventureSession, side_id: StringName = &"side_a") -> WildBattleCommand:
	return WildBattleCommand.run(session.battle_state().turn + 1, side_id)


func _reaction(session: WildAdventureSession) -> BattleAction:
	return _client.request_move(
		session.battle_state().turn + 1,
		session.current_wild().instance_id,
		TAP,
		session.player_active().instance_id,
		&"side_b",
	)


func _find_seed_for_roll(odds: int, want_success: bool) -> int:
	for seed_value in range(1, 20000):
		var roll := _rng(seed_value).randi_range(0, WildEscapeRuleset.ROLL_MAX)
		if (roll < odds) == want_success:
			return seed_value
	return -1


func _find_seed_for_exact_roll(target_roll: int) -> int:
	for seed_value in range(1, 100000):
		if _rng(seed_value).randi_range(0, WildEscapeRuleset.ROLL_MAX) == target_roll:
			return seed_value
	return -1


func _first(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event != null and event.kind == kind:
			return event
	return null


func _test_ruleset_boundaries() -> void:
	var equal := _escape.resolve(80, 80, 1, null)
	_check.call("run_audit_equal_speed_guaranteed", equal.succeeded() and not equal.rng_consumed)
	var accumulated := _escape.resolve(100, 101, 5, null)
	_check.call("run_audit_odds_over_255_guaranteed", accumulated.succeeded() and accumulated.odds > WildEscapeRuleset.ROLL_MAX and not accumulated.rng_consumed)
	var odds := _escape.odds(10, 100, 1)
	var exact_seed := _find_seed_for_exact_roll(odds)
	var exact := _escape.resolve(10, 100, 1, _rng(exact_seed))
	_check.call("run_audit_exact_threshold_seed", exact_seed > 0 and exact.roll == odds)
	_check.call("run_audit_threshold_is_strict", not exact.escaped)
	var bad_speed := _escape.resolve(0, 100, 1, _rng(1))
	var bad_attempt := _escape.resolve(10, 100, 0, _rng(1))
	_check.call("run_audit_invalid_speed_semantic", bad_speed.reason == "invalid_escape_speed" and not bad_speed.rng_consumed)
	_check.call("run_audit_invalid_attempt_semantic", bad_attempt.reason == "invalid_escape_attempt" and not bad_attempt.rng_consumed)


func _test_session_invalid_speed_precedes_reaction() -> void:
	var session := _session(22000)
	session.player_active().stats.speed = 0
	session.current_wild().stats.speed = 200
	var escape_rng := _rng(22077)
	var control := _rng(22077)
	var result := session.submit_player_command(_command(session), null, null, escape_rng)
	_check.call("run_audit_session_bad_speed_reason", not result.accepted and result.reason == "invalid_escape_speed")
	_check.call("run_audit_session_bad_speed_no_turn_attempt", session.battle_state().turn == 0 and session.escape_attempts() == 0)
	_check.call("run_audit_session_bad_speed_rng_safe", escape_rng.randi() == control.randi())


func _test_wrong_side_is_side_effect_free() -> void:
	var session := _session(22100)
	session.player_active().stats.speed = 1
	session.current_wild().stats.speed = 200
	var escape_rng := _rng(22177)
	var control := _rng(22177)
	var wrong := _command(session, &"side_b")
	var result := session.submit_player_command(wrong, null, _reaction(session), escape_rng)
	_check.call("run_audit_wrong_side_rejected", not result.accepted and result.reason == "wrong_participant")
	_check.call("run_audit_wrong_side_no_turn_attempt", session.battle_state().turn == 0 and session.escape_attempts() == 0)
	_check.call("run_audit_wrong_side_rng_safe", escape_rng.randi() == control.randi())


func _test_run_does_not_consume_capture_rng() -> void:
	var session := _session(22200)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	var odds := _escape.odds(player.stats.speed, wild.stats.speed, 1)
	var failure_seed := _find_seed_for_roll(odds, false)
	var capture_rng := _rng(22277)
	var capture_control := _rng(22277)
	var result := session.submit_player_command(_command(session), capture_rng, _reaction(session), _rng(failure_seed))
	_check.call("run_audit_capture_rng_failed_run", result.succeeded() and not result.escape_resolution.escaped)
	_check.call("run_audit_capture_rng_untouched", capture_rng.randi() == capture_control.randi())
	_check.call("run_audit_inventory_untouched", session.player.inventory.quantity(&"poke_ball") == 2)


func _test_escape_uses_persistent_speed_not_stages() -> void:
	var session := _session(22300)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 10
	wild.stats.speed = 100
	player.stat_stages.change(StatStages.SPEED, 6)
	var expected_odds := _escape.odds(10, 100, 1)
	var failure_seed := _find_seed_for_roll(expected_odds, false)
	var result := session.submit_player_command(_command(session), null, _reaction(session), _rng(failure_seed))
	_check.call("run_audit_speed_stage_does_not_change_odds", result.escape_resolution != null and result.escape_resolution.odds == expected_odds)
	_check.call("run_audit_speed_stage_still_probabilistic", result.succeeded() and not result.escape_resolution.escaped and result.escape_resolution.rng_consumed)


func _test_failed_escape_runs_end_turn_status() -> void:
	var session := _session(22400)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	player.status_state.persistent_id = &"poison"
	var failure_seed := _find_seed_for_roll(_escape.odds(1, 200, 1), false)
	var result := session.submit_player_command(_command(session), null, _reaction(session), _rng(failure_seed))
	var status_event := _first(result.battle_events, BattleEvent.STATUS_DAMAGE)
	_check.call("run_audit_failed_run_status_pipeline", result.succeeded() and status_event != null)
	_check.call("run_audit_failed_run_status_is_poison", status_event != null and StringName(status_event.metadata.get("status_id", "")) == &"poison")


func _test_flee_preserves_persistent_state_without_rewards() -> void:
	var session := _session(22500)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 200
	wild.stats.speed = 1
	player.current_hp = maxi(1, player.current_hp - 3)
	player.status_state.persistent_id = &"poison"
	var hp_before := player.current_hp
	var xp_before := player.experience
	var party_before := session.player.party.size()
	var wild_id := wild.instance_id
	var result := session.submit_player_command(_command(session), null, null, null)
	_check.call("run_audit_flee_success", result.succeeded() and result.session_completed and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("run_audit_flee_no_xp", player.experience == xp_before)
	_check.call("run_audit_flee_no_heal", player.current_hp == hp_before)
	_check.call("run_audit_flee_persistent_status_kept", player.status_state.persistent_id == &"poison")
	_check.call("run_audit_flee_no_ownership", session.player.party.size() == party_before and session.player.owned_creature(wild_id) == null)


func _test_escape_attempt_reset_lifecycle() -> void:
	var session := _session(22600)
	session.player_active().stats.speed = 200
	session.current_wild().stats.speed = 1
	var result := session.submit_player_command(_command(session), null, null, null)
	_check.call("run_audit_attempt_visible_after_flee", result.succeeded() and session.escape_attempts() == 1)
	_check.call("run_audit_reset_completion", session.reset_after_completion() and session.escape_attempts() == 0 and session.status == WildAdventureSession.READY)
	var table := WildEncounterTable.new(&"run_audit_again", 10000)
	table.add_slot(WildEncounterSlot.new(&"run_audit_again_slot", &"pikachu", 1, 8, 8))
	var encounter := session.begin_encounter(table, _rng(22677), 22678)
	_check.call("run_audit_new_encounter_started", encounter.status == WildEncounterResult.ENCOUNTER and session.has_active_battle())
	_check.call("run_audit_new_encounter_attempt_zero", session.escape_attempts() == 0)
