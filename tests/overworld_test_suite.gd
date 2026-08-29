class_name OverworldTestSuite
extends RefCounted

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_test_director_registration()
	_test_non_zone_does_not_consume_rng()
	_test_unknown_zone_does_not_consume_rng()
	_test_guaranteed_zone_starts_real_battle()
	_test_active_battle_blocks_second_roll()
	_test_zero_chance_is_semantic_none()
	_test_ko_party_rejected_without_rng()
	_test_completed_session_requires_resume()
	_test_cardinalization()
	await _test_zone_geometry(tree)
	await _test_player_steps_and_collision(tree)
	await _test_technical_scene_handoff(tree)


func _import_pokeapi() -> GameData:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	return DataImporter.new().import_dataset(raw, manifest)["game_data"]


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text()) as Dictionary if file != null else {}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _creature(id: StringName = &"overworld_starter") -> CreatureInstance:
	return CreatureFactory.create(
		_catalog.species_catalog.get_by_id(&"bulbasaur"),
		5,
		_catalog,
		_rules,
		_rng(700),
		{"instance_id": id},
	)


func _session() -> WildAdventureSession:
	var collection := PlayerCollection.new()
	collection.party.add_creature(_creature())
	return WildAdventureSession.new(collection, _catalog, _rules)


func _table(zone_id: StringName, chance_bp: int = 10000, species_id: StringName = &"pikachu") -> WildEncounterTable:
	var table := WildEncounterTable.new(zone_id, chance_bp)
	table.add_slot(WildEncounterSlot.new(StringName("slot_%s" % String(zone_id)), species_id, 1, 4, 4))
	return table


func _test_director_registration() -> void:
	var director := OverworldEncounterDirector.new(_session(), _rng(1), 10)
	var valid := _table(&"grass_a")
	_check.call("ow_register_valid_zone", director.register_zone(valid))
	_check.call("ow_register_lookup", director.has_zone(&"grass_a"))
	_check.call("ow_register_duplicate_rejected", not director.register_zone(valid))
	var invalid := _table(&"grass_bad", 10000, &"species_does_not_exist")
	_check.call("ow_register_invalid_species_rejected", not director.register_zone(invalid))
	_check.call("ow_register_sorted_ids", director.registered_zone_ids() == [&"grass_a"])


func _test_non_zone_does_not_consume_rng() -> void:
	var rng := _rng(2)
	var control := _rng(2)
	var director := OverworldEncounterDirector.new(_session(), rng, 20)
	var out := director.on_step(&"")
	_check.call("ow_no_zone_not_rolled", not out.rolled and out.reason == "no_encounter_zone")
	_check.call("ow_no_zone_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_unknown_zone_does_not_consume_rng() -> void:
	var rng := _rng(3)
	var control := _rng(3)
	var director := OverworldEncounterDirector.new(_session(), rng, 30)
	var out := director.on_step(&"unknown")
	_check.call("ow_unknown_zone_not_rolled", not out.rolled and out.reason == "unknown_encounter_zone")
	_check.call("ow_unknown_zone_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_guaranteed_zone_starts_real_battle() -> void:
	var session := _session()
	var director := OverworldEncounterDirector.new(session, _rng(4), 40)
	_check.call("ow_guaranteed_register", director.register_zone(_table(&"grass_real")))
	var out := director.on_step(&"grass_real")
	_check.call("ow_guaranteed_rolled", out.rolled)
	_check.call("ow_guaranteed_encounter", out.encounter != null and out.encounter.status == WildEncounterResult.ENCOUNTER)
	_check.call("ow_guaranteed_battle_started", out.battle_started and session.has_active_battle())
	_check.call("ow_guaranteed_wild_identity", session.current_wild() == out.encounter.creature)
	_check.call("ow_guaranteed_species", session.current_wild().species_id == &"pikachu")


func _test_active_battle_blocks_second_roll() -> void:
	var session := _session()
	var rng := _rng(5)
	var director := OverworldEncounterDirector.new(session, rng, 50)
	director.register_zone(_table(&"grass_busy"))
	director.on_step(&"grass_busy")
	var control := _rng(1)
	control.state = rng.state
	var second := director.on_step(&"grass_busy")
	_check.call("ow_busy_rejected", not second.rolled and second.reason == "adventure_not_ready")
	_check.call("ow_busy_no_second_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_zero_chance_is_semantic_none() -> void:
	var session := _session()
	var rng := _rng(6)
	var control := _rng(6)
	var director := OverworldEncounterDirector.new(session, rng, 60)
	director.register_zone(_table(&"grass_zero", 0))
	var out := director.on_step(&"grass_zero")
	_check.call("ow_zero_rolled", out.rolled)
	_check.call("ow_zero_none", out.encounter != null and out.encounter.status == WildEncounterResult.NONE)
	_check.call("ow_zero_no_battle", not out.battle_started and not session.has_active_battle())
	_check.call("ow_zero_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_ko_party_rejected_without_rng() -> void:
	var session := _session()
	session.player.party.get_active().current_hp = 0
	var rng := _rng(7)
	var control := _rng(7)
	var director := OverworldEncounterDirector.new(session, rng, 70)
	director.register_zone(_table(&"grass_ko"))
	var out := director.on_step(&"grass_ko")
	_check.call("ow_ko_reports_invalid", out.rolled and out.reason == "no_available_player_creature")
	_check.call("ow_ko_no_battle", not out.battle_started)
	_check.call("ow_ko_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_completed_session_requires_resume() -> void:
	var session := _session()
	session.status = WildAdventureSession.COMPLETED
	var rng := _rng(8)
	var control := _rng(8)
	var director := OverworldEncounterDirector.new(session, rng, 80)
	director.register_zone(_table(&"grass_resume"))
	var blocked := director.on_step(&"grass_resume")
	_check.call("ow_completed_blocks_step", not blocked.rolled and blocked.reason == "adventure_not_ready")
	_check.call("ow_completed_no_rng", is_equal_approx(rng.randf(), control.randf()))
	_check.call("ow_resume_success", director.resume_exploration())
	_check.call("ow_resume_ready", session.status == WildAdventureSession.READY)


func _test_cardinalization() -> void:
	_check.call("ow_cardinal_right", OverworldPlayer.cardinalize(Vector2(1.0, 0.2)) == Vector2.RIGHT)
	_check.call("ow_cardinal_left", OverworldPlayer.cardinalize(Vector2(-1.0, 0.2)) == Vector2.LEFT)
	_check.call("ow_cardinal_up", OverworldPlayer.cardinalize(Vector2(0.1, -1.0)) == Vector2.UP)
	_check.call("ow_cardinal_down", OverworldPlayer.cardinalize(Vector2(0.1, 1.0)) == Vector2.DOWN)
	_check.call("ow_cardinal_zero", OverworldPlayer.cardinalize(Vector2.ZERO) == Vector2.ZERO)
	_check.call("ow_cardinal_no_diagonal", OverworldPlayer.cardinalize(Vector2(1.0, 1.0)) == Vector2.RIGHT)


func _test_zone_geometry(tree: SceneTree) -> void:
	var zone := OverworldEncounterZone.new()
	zone.zone_id = &"geometry_zone"
	zone.position = Vector2(100, 100)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64, 32)
	shape_node.shape = shape
	zone.add_child(shape_node)
	tree.root.add_child(zone)
	await tree.process_frame
	_check.call("ow_zone_valid", zone.is_valid_zone())
	_check.call("ow_zone_contains_center", zone.contains_world_point(Vector2(100, 100)))
	_check.call("ow_zone_contains_inside", zone.contains_world_point(Vector2(129, 110)))
	_check.call("ow_zone_rejects_outside", not zone.contains_world_point(Vector2(140, 100)))
	zone.queue_free()
	await tree.process_frame


func _test_player_steps_and_collision(tree: SceneTree) -> void:
	var world := Node2D.new()
	tree.root.add_child(world)
	var player := OverworldPlayer.new()
	player.move_speed = 64.0
	player.step_distance = 16.0
	var player_shape_node := CollisionShape2D.new()
	var player_shape := RectangleShape2D.new()
	player_shape.size = Vector2(16, 16)
	player_shape_node.shape = player_shape
	player.add_child(player_shape_node)
	world.add_child(player)

	var wall := StaticBody2D.new()
	wall.position = Vector2(40, 0)
	var wall_shape_node := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(16, 48)
	wall_shape_node.shape = wall_shape
	wall.add_child(wall_shape_node)
	world.add_child(wall)
	var steps := [0]
	player.step_completed.connect(func(_pos: Vector2): steps[0] += 1)
	await tree.physics_frame

	var first := player.apply_motion(Vector2.RIGHT, 0.25)
	_check.call("ow_player_moves", is_equal_approx(first.x, 16.0) and is_zero_approx(first.y))
	_check.call("ow_player_step_emitted", steps[0] == 1)
	_check.call("ow_player_facing", player.facing == Vector2.RIGHT)
	var before_collision := player.position.x
	player.apply_motion(Vector2.RIGHT, 1.0)
	_check.call("ow_player_collision_blocks", player.position.x < 32.0 and player.position.x >= before_collision)
	var before_disabled := player.position
	player.movement_enabled = false
	player.apply_motion(Vector2.LEFT, 1.0)
	_check.call("ow_player_disabled_no_motion", player.position == before_disabled)
	world.queue_free()
	await tree.process_frame


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
		_check.call("ow_scene_transition_visible", label != null and label.text.contains("BATTLE ACTIVE"))
	scene.queue_free()
	await tree.process_frame
