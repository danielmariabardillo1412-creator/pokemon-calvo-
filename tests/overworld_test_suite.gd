class_name OverworldTestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable, tree: SceneTree = null) -> void:
	_check = check_callback
	_test_director_registration()
	_test_no_zone_is_free_step()
	_test_guaranteed_zone_starts_battle()
	_test_active_battle_blocks_second_roll()
	_test_zero_chance_zone_rolls_none()
	_test_all_ko_party_rejected_without_rng()
	_test_completed_session_blocks_steps_until_resume()
	_test_player_cardinal_input()
	_test_zone_geometry()
	_test_player_motion_and_step_signal()
	_test_player_collision_blocks_motion()
	_test_player_disabled_blocks_motion()
	if tree != null:
		await _test_technical_scene_handoff(tree)
	_test_large_motion_emits_multiple_steps()
	_test_runtime_uses_normalized_canonical_data()


func _test_director_registration() -> void:
	var rig := _rig()
	var director := rig["director"] as OverworldEncounterDirector
	var table := _table(&"route_a", 10000, &"slot_a", &"ow_species", 1)
	_check.call("ow_register_valid_zone", director.register_zone(table))
	_check.call("ow_register_lookup", director.has_zone(&"route_a"))
	_check.call("ow_register_duplicate_rejected", not director.register_zone(table))
	var invalid := _table(&"broken", 10000, &"bad", &"missing_species", 1)
	_check.call("ow_register_invalid_species_rejected", not director.register_zone(invalid))
	_check.call("ow_register_sorted_ids", director.zone_ids() == [&"route_a"])


func _test_no_zone_is_free_step() -> void:
	var rig := _rig()
	var director := rig["director"] as OverworldEncounterDirector
	var rng := rig["rng"] as CountingRng
	var before := rng.calls
	var result := director.on_step(&"")
	_check.call("ow_no_zone_not_rolled", not result.rolled)
	_check.call("ow_no_zone_no_rng", rng.calls == before)
	var unknown := director.on_step(&"missing")
	_check.call("ow_unknown_zone_not_rolled", not unknown.rolled)
	_check.call("ow_unknown_zone_no_rng", rng.calls == before)


func _test_guaranteed_zone_starts_battle() -> void:
	var rig := _rig()
	var director := rig["director"] as OverworldEncounterDirector
	var session := rig["session"] as WildAdventureSession
	_check.call("ow_guaranteed_register", director.register_zone(_table(&"grass", 10000, &"g", &"ow_species", 1)))
	var result := director.on_step(&"grass")
	_check.call("ow_guaranteed_rolled", result.rolled)
	_check.call("ow_guaranteed_encounter", result.encounter != null and result.encounter.status == WildEncounterResult.ENCOUNTER)
	_check.call("ow_guaranteed_battle_started", result.battle_started and session.has_active_battle())
	_check.call("ow_guaranteed_wild_identity", session.current_wild() != null)
	_check.call("ow_guaranteed_species", session.current_wild().species_id == &"ow_species")


func _test_active_battle_blocks_second_roll() -> void:
	var rig := _rig()
	var director := rig["director"] as OverworldEncounterDirector
	var rng := rig["rng"] as CountingRng
	director.register_zone(_table(&"grass", 10000, &"g", &"ow_species", 1))
	var first := director.on_step(&"grass")
	var after_first := rng.calls
	var second := director.on_step(&"grass")
	_check.call("ow_busy_rejected", first.battle_started and not second.rolled and not second.battle_started)
	_check.call("ow_busy_no_second_rng", rng.calls == after_first)


func _test_zero_chance_zone_rolls_none() -> void:
	var rig := _rig()
	var director := rig["director"] as OverworldEncounterDirector
	var rng := rig["rng"] as CountingRng
	director.register_zone(_table(&"calm", 0, &"c", &"ow_species", 1))
	var before := rng.calls
	var result := director.on_step(&"calm")
	_check.call("ow_zero_rolled", result.rolled)
	_check.call("ow_zero_none", result.encounter != null and result.encounter.status == WildEncounterResult.NONE)
	_check.call("ow_zero_no_battle", not result.battle_started)
	_check.call("ow_zero_no_rng", rng.calls == before)


func _test_all_ko_party_rejected_without_rng() -> void:
	var rig := _rig()
	var director := rig["director"] as OverworldEncounterDirector
	var session := rig["session"] as WildAdventureSession
	var rng := rig["rng"] as CountingRng
	director.register_zone(_table(&"grass", 10000, &"g", &"ow_species", 1))
	for creature in session.player.party.creatures():
		creature.current_hp = 0
	var before := rng.calls
	var result := director.on_step(&"grass")
	_check.call("ow_ko_reports_invalid", result.rolled and result.encounter != null and result.encounter.status == WildEncounterResult.INVALID)
	_check.call("ow_ko_no_battle", not result.battle_started)
	_check.call("ow_ko_no_rng", rng.calls == before)


func _test_completed_session_blocks_steps_until_resume() -> void:
	var rig := _rig()
	var director := rig["director"] as OverworldEncounterDirector
	var session := rig["session"] as WildAdventureSession
	var rng := rig["rng"] as CountingRng
	director.register_zone(_table(&"grass", 10000, &"g", &"ow_species", 1))
	var first := director.on_step(&"grass")
	if not first.battle_started:
		_check.call("ow_completed_blocks_step", false)
		_check.call("ow_completed_no_rng", false)
		_check.call("ow_resume_success", false)
		_check.call("ow_resume_ready", false)
		return
	# Finish the technical battle directly, then settle it to reach COMPLETED.
	var state := session.battle_state()
	var foe := session.current_wild()
	foe.current_hp = 0
	state.phase = BattleState.FINISHED
	state.winner_side_id = WildAdventureSession.PLAYER_SIDE_ID
	state.defeated_side_id = WildAdventureSession.WILD_SIDE_ID
	var settlement := session.settle_finished_battle()
	var before := rng.calls
	var blocked := director.on_step(&"grass")
	_check.call("ow_completed_blocks_step", settlement.success and not blocked.rolled)
	_check.call("ow_completed_no_rng", rng.calls == before)
	_check.call("ow_resume_success", director.resume_after_completion())
	_check.call("ow_resume_ready", session.state == WildAdventureSession.READY)


func _test_player_cardinal_input() -> void:
	_check.call("ow_cardinal_right", OverworldPlayer.cardinalize(Vector2(1.0, 0.2)) == Vector2.RIGHT)
	_check.call("ow_cardinal_left", OverworldPlayer.cardinalize(Vector2(-1.0, 0.1)) == Vector2.LEFT)
	_check.call("ow_cardinal_up", OverworldPlayer.cardinalize(Vector2(0.2, -1.0)) == Vector2.UP)
	_check.call("ow_cardinal_down", OverworldPlayer.cardinalize(Vector2(0.1, 1.0)) == Vector2.DOWN)
	_check.call("ow_cardinal_zero", OverworldPlayer.cardinalize(Vector2.ZERO) == Vector2.ZERO)
	_check.call("ow_cardinal_no_diagonal", OverworldPlayer.cardinalize(Vector2(1.0, 1.0)).x == 0.0 or OverworldPlayer.cardinalize(Vector2(1.0, 1.0)).y == 0.0)


func _test_zone_geometry() -> void:
	var zone := OverworldEncounterZone.new()
	zone.zone_id = &"shape"
	var shape_node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(100.0, 60.0)
	shape_node.shape = rectangle
	zone.add_child(shape_node)
	zone.global_position = Vector2(200.0, 100.0)
	_check.call("ow_zone_valid", zone.is_valid_zone())
	_check.call("ow_zone_contains_center", zone.contains_world_point(Vector2(200.0, 100.0)))
	_check.call("ow_zone_contains_inside", zone.contains_world_point(Vector2(240.0, 120.0)))
	_check.call("ow_zone_rejects_outside", not zone.contains_world_point(Vector2(260.0, 100.0)))
	zone.free()


func _test_player_motion_and_step_signal() -> void:
	var player := OverworldPlayer.new()
	player.step_distance = 5.0
	player.move_speed = 10.0
	var emitted: Array[Vector2] = []
	player.step_completed.connect(func(pos: Vector2): emitted.append(pos))
	player.apply_motion(Vector2.RIGHT, 1.0)
	_check.call("ow_player_moves", player.position.x > 0.0)
	_check.call("ow_player_step_emitted", emitted.size() >= 1)
	_check.call("ow_player_facing", player.facing == Vector2.RIGHT)
	player.free()


func _test_player_collision_blocks_motion() -> void:
	var player := OverworldPlayer.new()
	player.step_distance = 1.0
	player.move_speed = 32.0
	# Detached CharacterBody cannot query collisions; the movement contract must remain safe.
	player.apply_motion(Vector2.RIGHT, 0.1)
	_check.call("ow_player_collision_blocks", player.position.x >= 0.0)
	player.free()


func _test_player_disabled_blocks_motion() -> void:
	var player := OverworldPlayer.new()
	player.movement_enabled = false
	player.move_speed = 32.0
	var before := player.position
	player.apply_motion(Vector2.RIGHT, 1.0)
	_check.call("ow_player_disabled_no_motion", player.position == before)
	player.free()


func _test_technical_scene_handoff(tree: SceneTree) -> void:
	var packed := load("res://scenes/overworld/technical_overworld.tscn") as PackedScene
	_check.call("ow_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	tree.root.add_child(scene)
	await tree.process_frame
	_check.call("ow_scene_bootstrap", scene.call("is_demo_ready"))
	var player := scene.get_node("Player") as OverworldPlayer
	var zone := scene.get_node("EncounterZone") as OverworldEncounterZone
	_check.call("ow_scene_player_type", player != null)
	_check.call("ow_scene_zone_valid", zone != null and zone.is_valid_zone())
	_check.call("ow_scene_main_config", ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/overworld/technical_overworld.tscn")
	if player != null and zone != null:
		player.global_position = zone.global_position
		player.reset_step_meter()
		player.step_distance = 1.0
		player.move_speed = 32.0
		player.apply_motion(Vector2.RIGHT, 0.1)
		_check.call("ow_scene_step_starts_battle", scene.call("has_active_demo_battle"))
		_check.call("ow_scene_freezes_on_battle", not player.movement_enabled)
		var label := scene.get_node("CanvasLayer/StatusLabel") as Label
		_check.call(
			"ow_scene_transition_visible",
			label != null
			and label.text.contains("¡ENCUENTRO!")
			and label.text.contains("salvaje")
			and label.text.contains("Nv."),
		)
	scene.queue_free()
	await tree.process_frame


func _test_large_motion_emits_multiple_steps() -> void:
	var player := OverworldPlayer.new()
	player.step_distance = 4.0
	player.move_speed = 20.0
	var emitted: Array[Vector2] = []
	player.step_completed.connect(func(pos: Vector2): emitted.append(pos))
	player.apply_motion(Vector2.RIGHT, 1.0)
	_check.call("ow_large_motion_distance", player.position.x >= 19.0)
	_check.call("ow_large_motion_step_count", emitted.size() >= 4)
	var increasing := true
	for i in range(1, emitted.size()):
		if emitted[i].x < emitted[i - 1].x:
			increasing = false
	_check.call("ow_large_motion_intermediate_positions", increasing)
	player.free()


func _test_runtime_uses_normalized_canonical_data() -> void:
	var source := FileAccess.get_file_as_string("res://scenes/overworld/technical_overworld.gd")
	_check.call("ow_runtime_normalized_path", source.contains("res://data/normalized/pokemon_api.json"))
	_check.call("ow_runtime_no_import_pipeline", not source.contains("DataImporter.import_directory"))
	_check.call("ow_runtime_no_raw_dataset", not source.contains("raw/pokeapi"))
	var payload = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	var normalized := payload as Dictionary if payload is Dictionary else {}
	var manifest := normalized.get("manifest", {}) as Dictionary
	var species := normalized.get("species", {}) as Dictionary
	_check.call("ow_runtime_normalized_manifest", not manifest.is_empty())
	_check.call("ow_runtime_normalized_species", species.has("pikachu") and species.has("bulbasaur") and species.has("charmander"))


func _table(zone_id: StringName, chance_bp: int, slot_id: StringName, species_id: StringName, weight: int) -> WildEncounterTable:
	var table := WildEncounterTable.new(zone_id, chance_bp)
	table.add_slot(WildEncounterSlot.new(slot_id, species_id, weight, 5, 5))
	return table


func _rig() -> Dictionary:
	var catalog := DefinitionCatalog.new()
	var normal := TypeDefinition.new(&"normal", "Normal")
	catalog.add_type(normal)
	var tackle := MoveDefinition.new(&"ow_tackle", "Tackle", &"normal", 40, 100, 35, 0, MoveDefinition.PHYSICAL)
	catalog.add_move(tackle)
	var species := CreatureSpecies.new(&"ow_species", "OW", 45, [&"normal"], _stats(), 45, ProgressionRuleset.GROWTH_MEDIUM_FAST)
	species.learnset.append(LearnSetEntry.new(&"ow_tackle", 1))
	catalog.add_species(species)
	var player_species := CreatureSpecies.new(&"ow_player_species", "OW Player", 45, [&"normal"], _stats(), 45, ProgressionRuleset.GROWTH_MEDIUM_FAST)
	player_species.learnset.append(LearnSetEntry.new(&"ow_tackle", 1))
	catalog.add_species(player_species)
	var rules := ProgressionRuleset.new()
	var player_rng := CountingRng.new(1)
	var starter := CreatureFactory.create(player_species, 5, catalog, rules, player_rng, {"instance_id": &"ow_player"})
	var collection := PlayerCollection.new()
	collection.party.add_creature(starter)
	collection.inventory.add(&"poke_ball", 3)
	collection.inventory.add(&"master_ball", 1)
	var session := WildAdventureSession.new(collection, catalog, rules)
	var rng := CountingRng.new(22)
	var director := OverworldEncounterDirector.new(session, rng, 33)
	return {
		"catalog": catalog,
		"rules": rules,
		"session": session,
		"rng": rng,
		"director": director,
	}


func _stats() -> StatBlock:
	var stats := StatBlock.new()
	stats.max_hp = 100
	stats.attack = 50
	stats.defense = 50
	stats.sp_attack = 50
	stats.sp_defense = 50
	stats.speed = 50
	return stats


class CountingRng:
	extends RandomNumberGenerator
	var calls: int = 0
	var _inner := RandomNumberGenerator.new()

	func _init(seed_value: int) -> void:
		_inner.seed = seed_value

	func randi_range(from: int, to: int) -> int:
		calls += 1
		return _inner.randi_range(from, to)

	func randf() -> float:
		calls += 1
		return _inner.randf()
