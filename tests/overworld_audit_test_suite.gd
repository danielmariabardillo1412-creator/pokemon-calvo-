class_name OverworldAuditTestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	await _test_large_motion_intermediate_step_positions(tree)
	_test_runtime_uses_normalized_dataset()


func _test_large_motion_intermediate_step_positions(tree: SceneTree) -> void:
	var world := Node2D.new()
	tree.root.add_child(world)
	var player := OverworldPlayer.new()
	player.move_speed = 64.0
	player.step_distance = 16.0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 8)
	shape_node.shape = shape
	player.add_child(shape_node)
	world.add_child(player)
	var positions: Array[Vector2] = []
	player.step_completed.connect(func(pos: Vector2): positions.append(pos))
	await tree.physics_frame

	var moved := player.apply_motion(Vector2.RIGHT, 0.75)
	_check.call("ow_large_motion_distance", is_equal_approx(moved.x, 48.0) and is_zero_approx(moved.y))
	_check.call("ow_large_motion_step_count", positions.size() == 3)
	var exact_positions := positions.size() == 3
	if exact_positions:
		exact_positions = (
			positions[0].is_equal_approx(Vector2(16, 0))
			and positions[1].is_equal_approx(Vector2(32, 0))
			and positions[2].is_equal_approx(Vector2(48, 0))
		)
	_check.call("ow_large_motion_intermediate_positions", exact_positions)
	world.queue_free()
	await tree.process_frame


func _test_runtime_uses_normalized_dataset() -> void:
	var source := FileAccess.get_file_as_string("res://scenes/overworld/technical_overworld.gd")
	_check.call("ow_runtime_normalized_path", source.contains("data/normalized/pokemon_api.json"))
	_check.call("ow_runtime_no_import_pipeline", not source.contains("Data" + "Importer"))
	_check.call("ow_runtime_no_raw_dataset", not source.contains("data/raw/pokemon_api.json"))
	var file := FileAccess.open("res://data/normalized/pokemon_api.json", FileAccess.READ)
	var normalized: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary if file != null else {}
	var game_data := GameData.from_dict(normalized) if not normalized.is_empty() else null
	_check.call("ow_runtime_normalized_manifest", game_data != null and game_data.manifest.is_valid())
	_check.call(
		"ow_runtime_normalized_species",
		game_data != null
		and game_data.species_catalog.get_by_id(&"bulbasaur") != null
		and game_data.species_catalog.get_by_id(&"pikachu") != null,
	)
