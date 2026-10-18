extends SceneTree

var _passed := 0
var _failed := 0
var _capture := false


func _initialize() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	_check("boots_real_catalogs_and_sessions", scene.is_demo_ready())
	var player: OverworldPlayer = scene.player
	var ui: BattlePresentationController = scene.battle_presentation
	_check("initial_chance_is_15_percent", int(scene.encounter_expectation().percent) == 15)
	_check("initial_mean_uses_distance_and_speed", is_equal_approx(float(scene.encounter_expectation().mean_walking_seconds), 100.0 / 15.0 / 3.0))
	_check("fixed_demo_species_is_pidgey", scene._active_config.wild_species_id == "pidgey")
	await _snapshot("route")
	if _capture:
		scene.toggle_geometry_overlay()
		await _snapshot("collisions")
		scene.toggle_geometry_overlay()
	# Real input travels through the player's runtime physics callback.
	var start := player.global_position
	Input.action_press("ui_right")
	for i in 12:
		await physics_frame
	Input.action_release("ui_right")
	await physics_frame
	_check("keyboard_moves_visible_player", player.global_position.x > start.x + 10)
	_check("road_does_not_roll_encounters", _encounters(scene).rolls == 0)
	player.set_physics_process(false)
	player.global_position = Vector2(236, 180)
	player.reset_step_meter()
	await physics_frame
	for i in 20:
		player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		await physics_frame
	_check("visible_wall_stops_player", player.global_position.x < 247)
	_check("blocked_movement_does_not_trigger_battle", not scene.has_active_demo_battle())
	# Zero chance is a real runtime table, not a UI-only label.
	scene.test_panel._encounter_chance.value = 0
	scene.restart_field_run()
	_check("zero_chance_has_no_finite_wait", not scene.encounter_expectation().enabled)
	player.global_position = Vector2(420, 150)
	player.reset_step_meter()
	await physics_frame
	for i in 50:
		player.apply_motion(Vector2.RIGHT if i < 25 else Vector2.LEFT, 1.0 / 30.0)
		await physics_frame
	_check("grass_generates_real_distance_rolls", int(_encounters(scene).rolls) >= 4)
	_check("zero_chance_never_starts_battle", not scene.has_active_demo_battle())
	_check("walking_time_is_observed", scene._grass_walking_seconds > 1.0)
	# The guaranteed setting makes a reproducible encounter/capture integration test.
	scene.test_panel._encounter_chance.value = 100
	scene.restart_field_run()
	_check("restart_restores_inventory", scene.demo_inventory_quantity(&"master_ball") == 1)
	_check("restart_resets_observations", int(_encounters(scene).rolls) == 0)
	player.global_position = Vector2(420, 150)
	player.reset_step_meter()
	await physics_frame
	for i in 24:
		player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		await physics_frame
		if scene.has_active_demo_battle():
			break
	_check("grass_starts_authoritative_battle", scene.has_active_demo_battle())
	_check("battle_freezes_overworld", not player.movement_enabled)
	_check("visual_battle_ui_open", ui.is_presenting_battle())
	if scene.has_active_demo_battle():
		var wild: CreatureInstance = ui.session.current_wild()
		var wild_id := wild.instance_id
		_check("encounter_species_correct", wild.species_id == &"pidgey")
		_check("encounter_level_in_zone_bounds", wild.level >= 4 and wild.level <= 6)
		_check("sprites_match_authoritative_ids", ui._arena.enemy_species == wild.species_id)
		await _snapshot("battle")
		var active_config: Dictionary = scene._active_config.duplicate(true)
		scene.cycle_frequency()
		_check("configuration_blocked_during_battle", scene._active_config == active_config)
		var before_party: int = scene.demo_party_size()
		var outcome := ui.submit_capture_ball(&"master_ball")
		_check("capture_accepted_by_domain", outcome.accepted)
		_check("capture_completes_real_session", outcome.session_completed)
		_check("capture_consumes_ball", scene.demo_inventory_quantity(&"master_ball") == 0)
		_check("capture_adds_to_party", scene.demo_party_size() == before_party + 1)
		_check("captured_identity_preserved", ui.session.player.party.contains_instance_id(wild_id))
		_check("capture_recorded_by_existing_metrics", int(scene.technical_audit_summary().current_run.capture.successes) == 1)
		await _snapshot("captured")
		_check("continue_returns_to_exploration", ui.continue_after_completion())
		_check("movement_restored", player.movement_enabled)
		_check("session_ready_after_return", ui.session.status == WildAdventureSession.READY)
	# Original transitions remain the owners of relocation and lock/unlock.
	var traversal: OverworldTraversalController = scene.traversal_controller
	for pair in [["BuildingEntrance", "building"], ["BuildingExit", "surface"], ["CaveEntrance", "cave"], ["CaveExit", "surface"]]:
		var portal := scene.get_node(String(pair[0])) as OverworldPortal
		portal.fade_out_msec = 0
		portal.fade_in_msec = 0
		portal.hold_msec = 0
		_check("portal_" + String(pair[0]), await traversal.traverse_portal(portal))
		await process_frame
		_check("region_" + String(pair[0]), scene.technical_region_id() == StringName(pair[1]))
		if pair[1] == "building":
			_check("refuge_has_no_encounter_zone", scene.zone_at_position(player.global_position) == &"")
			await _snapshot("refuge")
		if pair[1] == "cave":
			await _snapshot("cave")
	player.global_position = Vector2(200, 230)
	var ledge := scene.get_node("LedgeTrigger") as OverworldLedge
	ledge.jump_duration_msec = 1
	_check("ledge_uses_real_traversal", await traversal.jump_ledge(ledge))
	_check("ledge_lands_at_marker", player.global_position.is_equal_approx(scene.get_node("LedgeLanding").global_position))
	# Settings pause/resume the real mover, including keyboard navigation.
	scene.test_panel._open_config()
	_check("settings_pause_movement", not player.movement_enabled)
	scene.test_panel._close_config()
	_check("settings_close_restores_movement", player.movement_enabled)
	scene.queue_free()
	await process_frame
	await process_frame
	print("=== VISUAL FIELD RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _encounters(scene) -> Dictionary:
	return scene.technical_audit_summary().current_run.encounters


func _snapshot(label: String) -> void:
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.godot/visual_checks"
	DirAccess.make_dir_recursive_absolute(path)
	var error := root.get_texture().get_image().save_png(path.path_join(label + ".png"))
	_check("screenshot_" + label, error == OK)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS " + label)
	else:
		_failed += 1
		push_error("FAIL " + label)
