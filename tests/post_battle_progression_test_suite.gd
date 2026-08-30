class_name PostBattleProgressionTestSuite
extends RefCounted

const BLAST := &"post_progression_blast"
const IDLE := &"post_progression_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_progression_system_rejects_forged_move_choices",
		"_test_settlement_queues_detached_move_choices_fifo",
		"_test_pending_choice_blocks_lifecycle_and_io",
		"_test_invalid_resolution_is_side_effect_free",
		"_test_decline_consumes_exactly_one_decision",
		"_test_replace_consumes_exactly_one_decision",
		"_test_all_choices_resolved_allows_save_load_and_reset",
		"_test_evolution_events_are_not_promoted_to_blocking_queue",
		"_test_completed_session_requires_explicit_reset_before_next_encounter",
	]
	for name in tests:
		print("PBP_TEST %s" % name)
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
		blast.display_name = "Post Progression Blast"
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
		idle.display_name = "Post Progression Idle"
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


func _guaranteed_table(species_id: StringName = &"pikachu", level: int = 2) -> WildEncounterTable:
	var table := WildEncounterTable.new(&"post_progression_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"post_progression_slot", species_id, 1, level, level))
	return table


func _player_with(creature: CreatureInstance) -> PlayerCollection:
	var pc := PlayerCollection.new()
	pc.party.add_creature(creature)
	return pc


func _ensure_move(creature: CreatureInstance, move_id: StringName) -> void:
	if not creature.has_move(move_id):
		creature.add_move(move_id, _catalog)


func _battle_actions(session: WildAdventureSession) -> Array[BattleAction]:
	var state := session.battle_state()
	var player := state.active_for_side(&"side_a")
	var wild := state.active_for_side(&"side_b")
	return [
		_client.request_move(state.turn + 1, player.instance_id, BLAST, wild.instance_id, &"side_a"),
		_client.request_move(state.turn + 1, wild.instance_id, IDLE, player.instance_id, &"side_b"),
	]


func _fill_four_moves_excluding(creature: CreatureInstance, excluded: Array[StringName]) -> void:
	creature.moveset.clear()
	creature.move_ids.clear()
	if not excluded.has(BLAST):
		creature.add_move(BLAST, _catalog)
	for move_id in _catalog.move_catalog.all_ids():
		if creature.moveset.size() >= ProgressionRuleset.MOVE_SLOTS_MAX:
			break
		if excluded.has(move_id) or move_id == IDLE or creature.has_move(move_id):
			continue
		creature.add_move(move_id, _catalog)
	creature.initialize_move_pp(_catalog)


func _move_choices(events: Array) -> Array[ProgressionEvent]:
	var out: Array[ProgressionEvent] = []
	for raw in events:
		if raw is ProgressionEvent and (raw as ProgressionEvent).kind == ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED:
			out.append(raw as ProgressionEvent)
	return out


func _evolution_events(events: Array) -> Array[ProgressionEvent]:
	var out: Array[ProgressionEvent] = []
	for raw in events:
		if raw is ProgressionEvent and (raw as ProgressionEvent).kind == ProgressionEvent.EVOLUTION_AVAILABLE:
			out.append(raw as ProgressionEvent)
	return out


func _session_victory_to_level(
	start_level: int,
	target_level: int,
	seed_value: int,
	instance_id: StringName,
) -> Dictionary:
	var starter := _creature(&"bulbasaur", start_level, seed_value, instance_id)
	var species: CreatureSpecies = _catalog.species_catalog.get_by_id(&"bulbasaur")
	var target_moves := LearnsetSystem.moves_learned_at_level(species, target_level)
	_fill_four_moves_excluding(starter, target_moves)
	starter.experience = _rules.experience_for_level(species.growth_rate, target_level) - 1
	var session := WildAdventureSession.new(_player_with(starter), _catalog, _rules)
	var encounter := session.begin_encounter(_guaranteed_table(), _rng(seed_value + 100), seed_value + 200)
	if encounter.status != WildEncounterResult.ENCOUNTER:
		return {"session": session, "starter": starter, "settlement": null}
	_ensure_move(encounter.creature, IDLE)
	encounter.creature.current_hp = 1
	session.submit_turn(_battle_actions(session))
	var settlement := session.settle_finished_battle()
	return {"session": session, "starter": starter, "settlement": settlement}


func _drain_choices_by_decline(session: WildAdventureSession) -> bool:
	var guard := 0
	while session.has_pending_progression_decisions() and guard < 32:
		var result := session.resolve_pending_move_choice(ProgressionSystem.DECLINE_MOVE)
		if not result.ok:
			return false
		guard += 1
	return not session.has_pending_progression_decisions()


func _generated_choice_fixture() -> Dictionary:
	var species: CreatureSpecies = _catalog.species_catalog.get_by_id(&"bulbasaur")
	var c := _creature(&"bulbasaur", 12, 501, &"choice_domain")
	var learned := LearnsetSystem.moves_learned_at_level(species, 13)
	_fill_four_moves_excluding(c, learned)
	c.experience = _rules.experience_for_level(species.growth_rate, 12)
	var need := _rules.experience_for_level(species.growth_rate, 13) - c.experience
	var events := ProgressionSystem.gain_experience(c, need, species, _catalog, _rules)
	var choices := _move_choices(events)
	return {"creature": c, "choices": choices}


func _test_progression_system_rejects_forged_move_choices() -> void:
	var fixture := _generated_choice_fixture()
	var c := fixture.creature as CreatureInstance
	var choices: Array = fixture.choices
	_check.call("pbp_domain_choice_generated", not choices.is_empty())
	if choices.is_empty():
		return
	var choice := choices[0] as ProgressionEvent
	var before := c.move_ids.duplicate()

	var wrong_creature := ProgressionEvent.new(
		ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED,
		&"someone_else",
		choice.data.duplicate(true),
	)
	_check.call("pbp_domain_wrong_creature_rejected", not ProgressionSystem.apply_move_choice(
		c, wrong_creature, ProgressionSystem.DECLINE_MOVE, _catalog
	))

	var forged_move := ProgressionEvent.new(
		ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED,
		c.instance_id,
		{"new_move_id": IDLE, "level": int(choice.data.get("level", 0))},
	)
	_check.call("pbp_domain_unlearnable_move_rejected", not ProgressionSystem.apply_move_choice(
		c, forged_move, ProgressionSystem.REPLACE_MOVE, _catalog, c.move_ids[0]
	))

	var missing_level := ProgressionEvent.new(
		ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED,
		c.instance_id,
		{"new_move_id": choice.data.get("new_move_id", &"")},
	)
	_check.call("pbp_domain_missing_level_rejected", not ProgressionSystem.apply_move_choice(
		c, missing_level, ProgressionSystem.DECLINE_MOVE, _catalog
	))

	_check.call("pbp_domain_replace_requires_explicit_target", not ProgressionSystem.apply_move_choice(
		c, choice, ProgressionSystem.REPLACE_MOVE, _catalog
	))
	_check.call("pbp_domain_forgery_no_mutation", c.move_ids == before)


func _test_settlement_queues_detached_move_choices_fifo() -> void:
	var fixture := _session_victory_to_level(12, 13, 601, &"queue_hero")
	var session := fixture.session as WildAdventureSession
	var settlement := fixture.settlement as WildBattleSettlement
	_check.call("pbp_queue_settlement_ok", settlement != null and settlement.ok and settlement.player_won)
	if settlement == null:
		return
	var choices := _move_choices(settlement.progression_events)
	_check.call("pbp_queue_source_choices_exist", not choices.is_empty())
	_check.call("pbp_queue_count_matches_source", session.pending_progression_decision_count() == choices.size())
	var snapshot := session.pending_progression_decision()
	_check.call("pbp_queue_snapshot_kind", snapshot.get("kind", "") == ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED)
	_check.call("pbp_queue_snapshot_creature", StringName(snapshot.get("creature_id", "")) == &"queue_hero")
	_check.call("pbp_queue_snapshot_has_level", int((snapshot.get("data", {}) as Dictionary).get("level", 0)) == 13)
	if not choices.is_empty():
		var original_pending_move := StringName((snapshot.get("data", {}) as Dictionary).get("new_move_id", ""))
		(choices[0] as ProgressionEvent).data["new_move_id"] = IDLE
		var after := session.pending_progression_decision()
		_check.call("pbp_queue_detached_from_settlement_event",
			StringName((after.get("data", {}) as Dictionary).get("new_move_id", "")) == original_pending_move)


func _test_pending_choice_blocks_lifecycle_and_io() -> void:
	var fixture := _session_victory_to_level(12, 13, 701, &"blocked_hero")
	var session := fixture.session as WildAdventureSession
	_check.call("pbp_block_pending_exists", session.has_pending_progression_decisions())
	var before_status := session.status
	_check.call("pbp_block_reset_rejected", not session.reset_after_completion() and session.status == before_status)
	var save := session.save_game("user://post_progression_blocked.json")
	_check.call("pbp_block_save_rejected", not save.ok and save.reason == "progression_decision_pending")
	var load := session.load_game("user://post_progression_missing.json")
	_check.call("pbp_block_load_precedes_io", not load.ok and load.reason == "progression_decision_pending")
	var rng := _rng(7777)
	var control := _rng(7777)
	var encounter := session.begin_encounter(_guaranteed_table(&"squirtle", 3), rng, 777)
	_check.call("pbp_block_next_encounter", encounter.status == WildEncounterResult.INVALID and encounter.reason == "progression_decision_pending")
	_check.call("pbp_block_next_encounter_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_invalid_resolution_is_side_effect_free() -> void:
	var fixture := _session_victory_to_level(12, 13, 801, &"invalid_hero")
	var session := fixture.session as WildAdventureSession
	var starter := fixture.starter as CreatureInstance
	var before_moves := starter.move_ids.duplicate()
	var before_count := session.pending_progression_decision_count()
	var invalid_intent := session.resolve_pending_move_choice("FORGED_INTENT")
	_check.call("pbp_invalid_intent_rejected", not invalid_intent.ok and invalid_intent.reason == "move_choice_rejected")
	_check.call("pbp_invalid_intent_queue_stable", session.pending_progression_decision_count() == before_count)
	_check.call("pbp_invalid_intent_moves_stable", starter.move_ids == before_moves)
	var no_target := session.resolve_pending_move_choice(ProgressionSystem.REPLACE_MOVE)
	_check.call("pbp_invalid_missing_target_rejected", not no_target.ok and no_target.reason == "move_choice_rejected")
	_check.call("pbp_invalid_missing_target_queue_stable", session.pending_progression_decision_count() == before_count)
	_check.call("pbp_invalid_missing_target_moves_stable", starter.move_ids == before_moves)


func _test_decline_consumes_exactly_one_decision() -> void:
	var fixture := _session_victory_to_level(12, 13, 901, &"decline_hero")
	var session := fixture.session as WildAdventureSession
	var starter := fixture.starter as CreatureInstance
	var before_moves := starter.move_ids.duplicate()
	var before_count := session.pending_progression_decision_count()
	var result := session.resolve_pending_move_choice(ProgressionSystem.DECLINE_MOVE)
	_check.call("pbp_decline_ok", result.ok and result.reason.is_empty())
	_check.call("pbp_decline_exactly_one", result.remaining == before_count - 1 and session.pending_progression_decision_count() == before_count - 1)
	_check.call("pbp_decline_moves_unchanged", starter.move_ids == before_moves)
	_check.call("pbp_decline_status_stays_completed", session.status == WildAdventureSession.COMPLETED)


func _test_replace_consumes_exactly_one_decision() -> void:
	var fixture := _session_victory_to_level(12, 13, 1001, &"replace_hero")
	var session := fixture.session as WildAdventureSession
	var starter := fixture.starter as CreatureInstance
	var snapshot := session.pending_progression_decision()
	var data := snapshot.get("data", {}) as Dictionary
	var new_move := StringName(data.get("new_move_id", ""))
	var old_move: StringName = starter.move_ids[0] if not starter.move_ids.is_empty() else &""
	var before_count := session.pending_progression_decision_count()
	var result := session.resolve_pending_move_choice(ProgressionSystem.REPLACE_MOVE, old_move)
	_check.call("pbp_replace_ok", result.ok)
	_check.call("pbp_replace_new_present", new_move != &"" and starter.has_move(new_move))
	_check.call("pbp_replace_old_absent", old_move != &"" and not starter.has_move(old_move))
	_check.call("pbp_replace_keeps_four", starter.moveset.size() == ProgressionRuleset.MOVE_SLOTS_MAX)
	_check.call("pbp_replace_exactly_one", session.pending_progression_decision_count() == before_count - 1)


func _test_all_choices_resolved_allows_save_load_and_reset() -> void:
	var fixture := _session_victory_to_level(12, 13, 1101, &"complete_hero")
	var session := fixture.session as WildAdventureSession
	_check.call("pbp_complete_started_pending", session.has_pending_progression_decisions())
	_check.call("pbp_complete_drain_choices", _drain_choices_by_decline(session))
	_check.call("pbp_complete_no_pending", not session.has_pending_progression_decisions())
	var path := "user://post_progression_resolved.json"
	var save := session.save_game(path)
	_check.call("pbp_complete_save_allowed", save.ok)
	var load := session.load_game(path)
	_check.call("pbp_complete_load_allowed", load.ok and session.status == WildAdventureSession.READY)

	var fixture2 := _session_victory_to_level(12, 13, 1102, &"reset_hero")
	var session2 := fixture2.session as WildAdventureSession
	_check.call("pbp_complete_second_drain", _drain_choices_by_decline(session2))
	_check.call("pbp_complete_reset_allowed", session2.reset_after_completion())
	_check.call("pbp_complete_reset_ready", session2.status == WildAdventureSession.READY)


func _test_evolution_events_are_not_promoted_to_blocking_queue() -> void:
	var fixture := _session_victory_to_level(15, 16, 1201, &"evo_audit_hero")
	var session := fixture.session as WildAdventureSession
	var settlement := fixture.settlement as WildBattleSettlement
	_check.call("pbp_evo_settlement_ok", settlement != null and settlement.ok)
	if settlement == null:
		return
	var move_choices := _move_choices(settlement.progression_events)
	var evolutions := _evolution_events(settlement.progression_events)
	_check.call("pbp_evo_event_exists", not evolutions.is_empty())
	_check.call("pbp_evo_queue_only_move_choices", session.pending_progression_decision_count() == move_choices.size())
	# If there are no move choices at this level, the coarse evolution event must not by itself block
	# reset/save. If there are move choices, drain them first and then assert the same property.
	var drained := _drain_choices_by_decline(session)
	_check.call("pbp_evo_move_queue_drained", drained)
	_check.call("pbp_evo_not_blocking_after_move_choices", not session.has_pending_progression_decisions())


func _test_completed_session_requires_explicit_reset_before_next_encounter() -> void:
	var pc := _player_with(_creature(&"bulbasaur", 5, 1301, &"capture_complete_hero"))
	pc.inventory.add(&"master_ball", 1)
	var session := WildAdventureSession.new(pc, _catalog, _rules)
	var first := session.begin_encounter(_guaranteed_table(), _rng(1302), 1302)
	var captured := session.capture_current(&"master_ball", _rng(1303))
	_check.call("pbp_lifecycle_capture_completed", first.status == WildEncounterResult.ENCOUNTER and captured.session_completed and session.status == WildAdventureSession.COMPLETED)
	var rng := _rng(1313)
	var control := _rng(1313)
	var blocked := session.begin_encounter(_guaranteed_table(&"squirtle", 3), rng, 1314)
	_check.call("pbp_lifecycle_completed_rejected", blocked.status == WildEncounterResult.INVALID and blocked.reason == "session_not_ready")
	_check.call("pbp_lifecycle_completed_no_rng", is_equal_approx(rng.randf(), control.randf()))
	_check.call("pbp_lifecycle_reset_capture", session.reset_after_completion())
	var next := session.begin_encounter(_guaranteed_table(&"squirtle", 3), _rng(1315), 1315)
	_check.call("pbp_lifecycle_after_reset_starts", next.status == WildEncounterResult.ENCOUNTER and session.has_active_battle())