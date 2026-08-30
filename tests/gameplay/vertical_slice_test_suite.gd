class_name VerticalSliceTestSuite
extends RefCounted

const BLAST := &"vertical_blast"
const IDLE := &"vertical_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_no_alive_player_rejected_without_rng",
		"_test_begin_encounter_builds_real_battle",
		"_test_begin_while_active_rejected_without_second_rng",
		"_test_settlement_requires_finished_battle",
		"_test_victory_progression_evolution_save_load_continue",
		"_test_capture_party_save_load",
		"_test_capture_full_party_routes_storage",
		"_test_failed_capture_consumes_ball_and_keeps_battle",
		"_test_missing_ball_keeps_rng_and_battle",
		"_test_save_blocked_while_battle_active",
		"_test_defeat_closes_without_xp",
		"_test_post_battle_clears_transient_stages",
		"_test_party_evolution_replacement_preserves_order",
		"_test_storage_evolution_replacement_preserves_slot",
		"_test_forged_evolution_target_rejected",
		"_test_evolution_preserves_move_index_and_held_item",
	]
	for name in tests:
		print("VS_TEST %s" % name)
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
		blast.display_name = "Vertical Blast"
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
		idle.display_name = "Vertical Idle"
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


func _guaranteed_table(species_id: StringName = &"pikachu", level: int = 5) -> WildEncounterTable:
	var table := WildEncounterTable.new(&"vertical_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"vertical_slot", species_id, 1, level, level))
	return table


func _player_with(creature: CreatureInstance) -> PlayerCollection:
	var pc := PlayerCollection.new()
	pc.party.add_creature(creature)
	return pc


func _session(pc: PlayerCollection) -> WildAdventureSession:
	return WildAdventureSession.new(pc, _catalog, _rules)


func _ensure_move(creature: CreatureInstance, move_id: StringName) -> void:
	if not creature.has_move(move_id):
		creature.add_move(move_id, _catalog)


func _battle_actions(session: WildAdventureSession, player_move: StringName, wild_move: StringName) -> Array[BattleAction]:
	var state := session.battle_state()
	var player := state.active_for_side(&"side_a")
	var wild := state.active_for_side(&"side_b")
	return [
		_client.request_move(state.turn + 1, player.instance_id, player_move, wild.instance_id, &"side_a"),
		_client.request_move(state.turn + 1, wild.instance_id, wild_move, player.instance_id, &"side_b"),
	]


func _find_capture_failure_seed(target: CreatureInstance, ball_id: StringName) -> int:
	var crs := CaptureRuleset.new()
	var species := _catalog.species_catalog.get_by_id(target.species_id)
	var ball := crs.ball(ball_id)
	var p := crs.catch_probability(
		species.capture_rate,
		ball.base_multiplier,
		crs.status_bonus(target.status_state.persistent_id),
		target.stats.max_hp,
		target.current_hp,
	)
	for seed_value in range(1, 5000):
		if _rng(seed_value).randf() >= p:
			return seed_value
	return -1


func _first_evolution(events: Array) -> ProgressionEvent:
	for event in events:
		if event is ProgressionEvent and event.kind == ProgressionEvent.EVOLUTION_AVAILABLE:
			return event
	return null


func _test_no_alive_player_rejected_without_rng() -> void:
	var c := _creature(&"bulbasaur", 5, 1, &"ko_player")
	c.current_hp = 0
	var s := _session(_player_with(c))
	var rng := _rng(100)
	var control := _rng(100)
	var result := s.begin_encounter(_guaranteed_table(), rng, 1)
	_check.call("vs_no_alive_rejected", result.status == WildEncounterResult.INVALID and result.reason == "no_available_player_creature")
	_check.call("vs_no_alive_no_rng", is_equal_approx(rng.randf(), control.randf()))
	_check.call("vs_no_alive_no_battle", not s.has_active_battle())


func _test_begin_encounter_builds_real_battle() -> void:
	var c := _creature(&"bulbasaur", 5, 2, &"starter")
	var s := _session(_player_with(c))
	var result := s.begin_encounter(_guaranteed_table(&"pikachu", 4), _rng(2), 777)
	_check.call("vs_begin_encounter", result.status == WildEncounterResult.ENCOUNTER and s.has_active_battle())
	_check.call("vs_begin_same_player_ref", s.player_active() == c)
	_check.call("vs_begin_same_wild_ref", s.current_wild() == result.creature)
	_check.call("vs_begin_sides", s.battle_state().side_for_creature(c.instance_id).side_id == &"side_a" and s.battle_state().side_for_creature(result.creature.instance_id).side_id == &"side_b")


func _test_begin_while_active_rejected_without_second_rng() -> void:
	var s := _session(_player_with(_creature(&"bulbasaur", 5, 3, &"starter")))
	s.begin_encounter(_guaranteed_table(), _rng(3), 3)
	var second_rng := _rng(333)
	var control := _rng(333)
	var second := s.begin_encounter(_guaranteed_table(&"squirtle", 5), second_rng, 4)
	_check.call("vs_double_begin_rejected", second.status == WildEncounterResult.INVALID and second.reason == "battle_already_active")
	_check.call("vs_double_begin_no_rng", is_equal_approx(second_rng.randf(), control.randf()))
	_check.call("vs_double_begin_original_active", s.has_active_battle() and s.current_wild().species_id == &"pikachu")


func _test_settlement_requires_finished_battle() -> void:
	var s := _session(_player_with(_creature(&"bulbasaur", 5, 4, &"starter")))
	s.begin_encounter(_guaranteed_table(), _rng(4), 4)
	var settled := s.settle_finished_battle()
	_check.call("vs_settle_early_rejected", not settled.ok and settled.reason == "battle_not_finished")
	_check.call("vs_settle_early_still_active", s.has_active_battle())


func _test_victory_progression_evolution_save_load_continue() -> void:
	var starter := _creature(&"bulbasaur", 15, 10, &"hero_bulba")
	starter.experience = _rules.experience_for_level(
		_catalog.species_catalog.get_by_id(&"bulbasaur").growth_rate, 16
	) - 1
	_ensure_move(starter, BLAST)
	starter.held_item_id = &"leftovers"
	var pc := _player_with(starter)
	pc.inventory.add(&"poke_ball", 5)
	var s := _session(pc)
	var encounter := s.begin_encounter(_guaranteed_table(&"pikachu", 2), _rng(10), 12345)
	_ensure_move(encounter.creature, IDLE)
	encounter.creature.current_hp = 1
	var events := s.submit_turn(_battle_actions(s, BLAST, IDLE))
	_check.call("vs_victory_real_battle_finished", s.battle_state().phase == BattleState.FINISHED and not events.is_empty())
	var settlement := s.settle_finished_battle()
	_check.call("vs_victory_settled", settlement.ok and settlement.player_won and s.completion_reason == WildAdventureSession.COMPLETED_VICTORY)
	_check.call("vs_victory_level_up", starter.level >= 16 and starter.experience > 0)
	var evolution := _first_evolution(settlement.progression_events)
	_check.call("vs_victory_evolution_available", evolution != null and StringName(evolution.data.get("species_id", "")) == &"ivysaur")
	var evolved := s.apply_evolution_event(evolution)
	_check.call("vs_evolution_applied", evolved != null and evolved.species_id == &"ivysaur")
	_check.call("vs_evolution_same_identity_owned", evolved.instance_id == &"hero_bulba" and s.player.party.get_creature(&"hero_bulba") == evolved)
	_check.call("vs_evolution_move_index", evolved.has_move(BLAST) and evolved.move_ids.has(BLAST))
	_check.call("vs_evolution_held_item", evolved.held_item_id == &"leftovers")

	var save_path := "user://vertical_slice_victory.json"
	var saved := s.save_game(save_path)
	_check.call("vs_victory_save", saved.ok)
	var loaded := s.load_game(save_path)
	_check.call("vs_victory_load", loaded.ok and s.status == WildAdventureSession.READY)
	var restored := s.player.party.get_creature(&"hero_bulba")
	_check.call("vs_victory_load_fidelity", restored != null and restored.species_id == &"ivysaur" and restored.level >= 16 and restored.held_item_id == &"leftovers")
	_check.call("vs_victory_inventory_fidelity", s.player.inventory.quantity(&"poke_ball") == 5)
	var continued := s.begin_encounter(_guaranteed_table(&"squirtle", 3), _rng(11), 54321)
	_check.call("vs_continue_after_load", continued.status == WildEncounterResult.ENCOUNTER and s.has_active_battle() and s.player_active().instance_id == &"hero_bulba")


func _test_capture_party_save_load() -> void:
	var pc := _player_with(_creature(&"bulbasaur", 5, 20, &"capture_starter"))
	pc.inventory.add(&"master_ball", 1)
	var s := _session(pc)
	var encounter := s.begin_encounter(_guaranteed_table(&"pikachu", 7), _rng(20), 20)
	var captured_id := encounter.creature.instance_id
	var result := s.capture_current(&"master_ball", _rng(21))
	_check.call("vs_capture_party_success", result.succeeded() and result.session_completed)
	_check.call("vs_capture_party_owned", s.player.party.contains_instance_id(captured_id) and s.player.party.get_creature(captured_id) == encounter.creature)
	_check.call("vs_capture_party_ball_used", s.player.inventory.quantity(&"master_ball") == 0)
	var path := "user://vertical_slice_capture.json"
	_check.call("vs_capture_party_save", s.save_game(path).ok)
	_check.call("vs_capture_party_load", s.load_game(path).ok)
	var restored := s.player.party.get_creature(captured_id)
	_check.call("vs_capture_party_load_identity", restored != null and restored.instance_id == captured_id and restored.species_id == &"pikachu")


func _test_capture_full_party_routes_storage() -> void:
	var pc := PlayerCollection.new()
	for i in range(6):
		pc.party.add_creature(_creature(&"bulbasaur", 5, 30 + i, StringName("full_%d" % i)))
	pc.inventory.add(&"master_ball", 1)
	var s := _session(pc)
	var encounter := s.begin_encounter(_guaranteed_table(&"pikachu", 8), _rng(30), 30)
	var captured_id := encounter.creature.instance_id
	var result := s.capture_current(&"master_ball", _rng(31))
	_check.call("vs_capture_storage_success", result.succeeded() and result.routing != null and result.routing.stored)
	_check.call("vs_capture_storage_party_six", s.player.party.size() == 6)
	_check.call("vs_capture_storage_owned", s.player.storage.contains_instance_id(captured_id) and s.player.storage.get_creature(captured_id) == encounter.creature)
	_check.call("vs_capture_storage_ball_used", s.player.inventory.quantity(&"master_ball") == 0)
	var path := "user://vertical_slice_storage_capture.json"
	_check.call("vs_capture_storage_save", s.save_game(path).ok)
	_check.call("vs_capture_storage_load", s.load_game(path).ok and s.player.storage.contains_instance_id(captured_id))


func _test_failed_capture_consumes_ball_and_keeps_battle() -> void:
	var pc := _player_with(_creature(&"bulbasaur", 5, 40, &"fail_starter"))
	pc.inventory.add(&"poke_ball", 2)
	var s := _session(pc)
	s.begin_encounter(_guaranteed_table(&"pikachu", 5), _rng(40), 40)
	var target := s.current_wild()
	var seed_value := _find_capture_failure_seed(target, &"poke_ball")
	_check.call("vs_capture_failure_seed_found", seed_value > 0)
	var result := s.capture_current(&"poke_ball", _rng(seed_value))
	_check.call("vs_capture_failure_status", result.resolution != null and result.resolution.result.status == CaptureResult.FAILED)
	_check.call("vs_capture_failure_consumed", s.player.inventory.quantity(&"poke_ball") == 1)
	_check.call("vs_capture_failure_battle_continues", s.has_active_battle() and not s.player.party.contains_instance_id(target.instance_id))


func _test_missing_ball_keeps_rng_and_battle() -> void:
	var s := _session(_player_with(_creature(&"bulbasaur", 5, 50, &"no_ball_starter")))
	s.begin_encounter(_guaranteed_table(), _rng(50), 50)
	var rng := _rng(5050)
	var control := _rng(5050)
	var result := s.capture_current(&"ultra_ball", rng)
	_check.call("vs_missing_ball_rejected", result.resolution != null and result.resolution.result.status == CaptureResult.INVALID and result.resolution.result.reason == "item_not_owned")
	_check.call("vs_missing_ball_no_rng", is_equal_approx(rng.randf(), control.randf()))
	_check.call("vs_missing_ball_battle_active", s.has_active_battle())


func _test_save_blocked_while_battle_active() -> void:
	var s := _session(_player_with(_creature(&"bulbasaur", 5, 60, &"save_guard")))
	s.begin_encounter(_guaranteed_table(), _rng(60), 60)
	var before_party := s.player.party.size()
	var result := s.save_game("user://must_not_save_active.json")
	_check.call("vs_save_active_blocked", not result.ok and result.reason == "active_wild_battle")
	_check.call("vs_save_active_no_state_mutation", s.has_active_battle() and s.player.party.size() == before_party)


func _test_defeat_closes_without_xp() -> void:
	var starter := _creature(&"bulbasaur", 5, 70, &"defeat_starter")
	_ensure_move(starter, IDLE)
	var before_xp := starter.experience
	var s := _session(_player_with(starter))
	var encounter := s.begin_encounter(_guaranteed_table(&"pikachu", 5), _rng(70), 70)
	_ensure_move(encounter.creature, BLAST)
	starter.current_hp = 1
	s.submit_turn(_battle_actions(s, IDLE, BLAST))
	var settlement := s.settle_finished_battle()
	_check.call("vs_defeat_settled", settlement.ok and not settlement.player_won and s.completion_reason == WildAdventureSession.COMPLETED_DEFEAT)
	_check.call("vs_defeat_no_xp", starter.experience == before_xp and settlement.progression_events.is_empty())
	_check.call("vs_defeat_player_ko_persists", starter.current_hp == 0)


func _test_post_battle_clears_transient_stages() -> void:
	var starter := _creature(&"bulbasaur", 5, 80, &"stage_starter")
	_ensure_move(starter, BLAST)
	starter.stat_stages.change(StatStages.ATTACK, 4)
	var s := _session(_player_with(starter))
	var encounter := s.begin_encounter(_guaranteed_table(&"pikachu", 2), _rng(80), 80)
	_ensure_move(encounter.creature, IDLE)
	encounter.creature.current_hp = 1
	s.submit_turn(_battle_actions(s, BLAST, IDLE))
	s.settle_finished_battle()
	_check.call("vs_post_battle_stage_reset", starter.stat_stages.get_stage(StatStages.ATTACK) == 0)
	_check.call("vs_post_battle_status_ready", s.status == WildAdventureSession.COMPLETED)


func _test_party_evolution_replacement_preserves_order() -> void:
	var bulba := _creature(&"bulbasaur", 16, 90, &"party_evo")
	var pika := _creature(&"pikachu", 10, 91, &"party_other")
	var pc := PlayerCollection.new()
	pc.party.add_creature(bulba)
	pc.party.add_creature(pika)
	var before := pc.party.get_ordered_ids()
	var s := _session(pc)
	var event := ProgressionEvent.new(ProgressionEvent.EVOLUTION_AVAILABLE, bulba.instance_id, {"species_id": &"ivysaur"})
	var evolved := s.apply_evolution_event(event)
	_check.call("vs_party_evo_applied", evolved != null and pc.party.get_creature(&"party_evo") == evolved)
	_check.call("vs_party_evo_order", pc.party.get_ordered_ids() == before)
	_check.call("vs_party_evo_other_unchanged", pc.party.get_creature(&"party_other") == pika)


func _test_storage_evolution_replacement_preserves_slot() -> void:
	var bulba := _creature(&"bulbasaur", 16, 100, &"storage_evo")
	var pc := PlayerCollection.new()
	pc.storage.add_creature(bulba)
	var before := pc.storage.locate(bulba.instance_id).duplicate(true)
	var s := _session(pc)
	var event := ProgressionEvent.new(ProgressionEvent.EVOLUTION_AVAILABLE, bulba.instance_id, {"species_id": &"ivysaur"})
	var evolved := s.apply_evolution_event(event)
	var after := pc.storage.locate(bulba.instance_id)
	_check.call("vs_storage_evo_applied", evolved != null and pc.storage.get_creature(&"storage_evo") == evolved)
	_check.call("vs_storage_evo_slot", before == after)
	_check.call("vs_storage_evo_location", pc.location_of(&"storage_evo") == &"STORAGE")


func _test_forged_evolution_target_rejected() -> void:
	var bulba := _creature(&"bulbasaur", 16, 110, &"forged_evo")
	var pc := _player_with(bulba)
	var s := _session(pc)
	var forged := ProgressionEvent.new(ProgressionEvent.EVOLUTION_AVAILABLE, bulba.instance_id, {"species_id": &"mewtwo"})
	var result := s.apply_evolution_event(forged)
	_check.call("vs_forged_evo_rejected", result == null)
	_check.call("vs_forged_evo_unchanged", pc.party.get_creature(&"forged_evo") == bulba and bulba.species_id == &"bulbasaur")


func _test_evolution_preserves_move_index_and_held_item() -> void:
	var bulba := _creature(&"bulbasaur", 16, 120, &"fidelity_evo")
	_ensure_move(bulba, BLAST)
	bulba.held_item_id = &"leftovers"
	bulba.status_state.persistent_id = &"poison"
	var pc := _player_with(bulba)
	var s := _session(pc)
	var event := ProgressionEvent.new(ProgressionEvent.EVOLUTION_AVAILABLE, bulba.instance_id, {"species_id": &"ivysaur"})
	var evolved := s.apply_evolution_event(event)
	_check.call("vs_evo_fidelity_moves", evolved != null and evolved.has_move(BLAST) and evolved.move_ids.has(BLAST) and evolved.move_slot(BLAST) != null)
	_check.call("vs_evo_fidelity_item", evolved != null and evolved.held_item_id == &"leftovers")
	_check.call("vs_evo_fidelity_status", evolved != null and evolved.status_state.persistent_id == &"poison")
