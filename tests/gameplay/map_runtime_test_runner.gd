extends SceneTree

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _ledge_matrix()
	await _blocked_landings()
	await _movement_matrix()
	await _visual_map_audit()
	print("=== MAP RUNTIME RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _ledge_fixture(start: Vector2, facing: Vector2) -> Dictionary:
	var world := Node2D.new()
	var actor := OverworldPlayer.new()
	actor.name = "Player"
	actor.position = start
	actor.facing = facing
	actor.add_child(_shape(Vector2(20, 20)))
	actor.set_physics_process(false)
	world.add_child(actor)
	var barrier := StaticBody2D.new()
	barrier.position = Vector2(200, 278)
	barrier.add_child(_shape(Vector2(96, 12)))
	world.add_child(barrier)
	var landing := Marker2D.new()
	landing.name = "Landing"
	landing.position = Vector2(200, 306)
	world.add_child(landing)
	var ledge := OverworldLedge.new()
	ledge.position = Vector2(200, 252)
	ledge.collision_layer = 2
	ledge.collision_mask = 1
	ledge.landing_path = NodePath("../Landing")
	ledge.jump_duration_msec = 1
	ledge.add_child(_shape(Vector2(96, 24)))
	world.add_child(ledge)
	var traversal := OverworldTraversalController.new()
	world.add_child(traversal)
	root.add_child(world)
	traversal.configure(actor)
	traversal.register_ledge(ledge)
	var jumps := [0]
	var steps := [0]
	var rejections := [0]
	traversal.ledge_jump_started.connect(func(_payload: Dictionary): jumps[0] += 1)
	actor.step_completed.connect(func(_position: Vector2): steps[0] += 1)
	ledge.jump_rejected.connect(func(_ledge: OverworldLedge, _actor: OverworldPlayer, _reason: String): rejections[0] += 1)
	return {"world": world, "actor": actor, "ledge": ledge, "traversal": traversal, "jumps": jumps, "steps": steps, "rejections": rejections}


func _shape(size: Vector2) -> CollisionShape2D:
	var node := CollisionShape2D.new()
	node.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	node.shape = shape
	return node


func _settle() -> void:
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame


func _walk(fixture: Dictionary, direction: Vector2, frames: int) -> void:
	for i in frames:
		fixture.actor.apply_motion(direction, 1.0 / 60.0)
		await physics_frame
		await process_frame


func _dispose(fixture: Dictionary) -> void:
	fixture.world.queue_free()
	await process_frame
	await physics_frame


func _ledge_matrix() -> void:
	# Reproduce the reported failure through Area2D + real mover, not jump_ledge().
	for distance in [1.0, 8.0, 32.0, 56.0]:
		var fixture := _ledge_fixture(Vector2(200, 262 - distance), Vector2.LEFT)
		await _settle()
		_check("ledge_still_at_%dpx_does_not_autojump" % int(distance), fixture.jumps[0] == 0)
		await _walk(fixture, Vector2.DOWN, 42)
		_check("ledge_down_from_%dpx_jumps_once" % int(distance), fixture.jumps[0] == 1)
		_check("ledge_down_from_%dpx_lands_below" % int(distance), fixture.actor.position.y >= 306)
		await _dispose(fixture)
	# No sideways teleport to the authored centre of a wide ledge.
	for x in [164.0, 180.0, 200.0, 220.0, 236.0]:
		var fixture := _ledge_fixture(Vector2(x, 210), Vector2.DOWN)
		await _settle()
		await _walk(fixture, Vector2.DOWN, 42)
		_check("ledge_width_%d_jump" % int(x), fixture.jumps[0] == 1)
		_check("ledge_width_%d_preserves_x" % int(x), is_equal_approx(fixture.actor.position.x, x))
		await _dispose(fixture)
	var stationary := _ledge_fixture(Vector2(200, 252), Vector2.DOWN)
	await _settle()
	_check("ledge_stationary_inside_does_not_jump", stationary.jumps[0] == 0)
	await _dispose(stationary)
	var reverse := _ledge_fixture(Vector2(200, 306), Vector2.UP)
	await _settle()
	await _walk(reverse, Vector2.UP, 25)
	_check("ledge_reverse_never_jumps", reverse.jumps[0] == 0)
	_check("ledge_reverse_barrier_holds", reverse.actor.position.y >= 292)
	await _dispose(reverse)
	var locked := _ledge_fixture(Vector2(200, 252), Vector2.LEFT)
	locked.actor.movement_enabled = false
	await _settle()
	await _walk(locked, Vector2.DOWN, 3)
	_check("ledge_locked_does_not_jump", locked.jumps[0] == 0)
	locked.actor.movement_enabled = true
	await _walk(locked, Vector2.DOWN, 8)
	_check("ledge_unlock_can_jump_without_reentry", locked.jumps[0] == 1)
	await _dispose(locked)
	var away := _ledge_fixture(Vector2(200, 252), Vector2.LEFT)
	await _settle()
	await _walk(away, Vector2.UP, 12)
	_check("ledge_walking_away_does_not_jump", away.jumps[0] == 0)
	_check("held_wrong_direction_emits_one_diagnostic", away.rejections[0] == 1)
	await _dispose(away)
	var sideways := _ledge_fixture(Vector2(148, 252), Vector2.LEFT)
	await _settle()
	await _walk(sideways, Vector2.DOWN, 8)
	_check("ledge_side_overlap_does_not_jump", sideways.jumps[0] == 0)
	await _dispose(sideways)
	var horizontal := _ledge_fixture(Vector2(252, 180), Vector2.UP)
	horizontal.ledge.position = Vector2(252, 200)
	horizontal.ledge.allowed_direction = Vector2.RIGHT
	horizontal.ledge.get_node("CollisionShape2D").shape.size = Vector2(24, 96)
	horizontal.world.get_node("Landing").position = Vector2(306, 200)
	for child in horizontal.world.get_children():
		if child is StaticBody2D:
			child.position = Vector2(278, 200)
			child.get_node("CollisionShape2D").shape.size = Vector2(12, 96)
	await _settle()
	await _walk(horizontal, Vector2.RIGHT, 8)
	_check("horizontal_ledge_jumps_from_standstill", horizontal.jumps[0] == 1)
	_check("horizontal_ledge_preserves_y", is_equal_approx(horizontal.actor.position.y, 180))
	await _dispose(horizontal)


func _blocked_landings() -> void:
	var fixture := _ledge_fixture(Vector2(200, 252), Vector2.LEFT)
	var blocker := StaticBody2D.new()
	blocker.position = Vector2(200, 306)
	blocker.add_child(_shape(Vector2(40, 20)))
	fixture.world.add_child(blocker)
	await _settle()
	await _walk(fixture, Vector2.DOWN, 8)
	_check("occupied_landing_refuses_jump", fixture.jumps[0] == 0)
	_check("occupied_landing_stays_above_barrier", fixture.actor.position.y < 272)
	_check("occupied_landing_does_not_lock_player", fixture.actor.movement_enabled and not fixture.traversal.is_busy())
	blocker.queue_free()
	await _settle()
	await _walk(fixture, Vector2.DOWN, 8)
	_check("cleared_landing_retries_without_running_back", fixture.jumps[0] == 1)
	await _dispose(fixture)


func _movement_matrix() -> void:
	for hz in [20, 30, 60, 120]:
		var world := Node2D.new()
		var actor := OverworldPlayer.new()
		actor.add_child(_shape(Vector2(20, 20)))
		actor.set_physics_process(false)
		world.add_child(actor)
		root.add_child(world)
		var steps := [0]
		actor.step_completed.connect(func(_p: Vector2): steps[0] += 1)
		await _settle()
		for i in hz * 2:
			actor.apply_motion(Vector2.RIGHT, 1.0 / float(hz))
		_check("motion_%dhz_two_seconds_distance" % hz, absf(actor.position.x - 192.0) < 0.05)
		_check("motion_%dhz_six_steps" % hz, steps[0] == 6)
		actor.position = Vector2.ZERO
		actor.reset_step_meter()
		actor.apply_motion(Vector2(1, 1), 0.5)
		_check("motion_%dhz_no_diagonal_speedup" % hz, absf(actor.position.length() - 48.0) < 0.05 and is_zero_approx(actor.position.y))
		var before := actor.position
		actor.apply_motion(Vector2.LEFT, 0)
		actor.apply_motion(Vector2.LEFT, -1)
		_check("motion_%dhz_nonpositive_delta_no_move" % hz, actor.position.is_equal_approx(before))
		world.queue_free()
		await process_frame
	# The step that starts a battle must stop producing later fake steps in the same tick.
	var owner := Node2D.new()
	var mover := OverworldPlayer.new()
	mover.add_child(_shape(Vector2(20, 20)))
	mover.set_physics_process(false)
	owner.add_child(mover)
	root.add_child(owner)
	var boundaries: Array[Vector2] = []
	mover.step_completed.connect(func(point: Vector2):
		boundaries.append(point)
		mover.movement_enabled = false
	)
	await _settle()
	mover.apply_motion(Vector2.RIGHT, 1.0)
	_check("movement_lock_stops_later_step_events_in_tick", boundaries.size() == 1)
	_check("movement_lock_stops_at_first_encounter_step", mover.position.is_equal_approx(Vector2(32, 0)))
	owner.queue_free()
	await process_frame


func _visual_map_audit() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await _settle()
	var actor: OverworldPlayer = scene.player
	actor.set_physics_process(false)
	_check("visual_real_map_boots", scene.is_demo_ready())
	var initial_position := actor.position
	var initial_rng: int = scene._director._encounter_rng.state
	scene.toggle_geometry_overlay()
	_check("collision_overlay_opens", scene._geometry_overlay.visible)
	scene.toggle_geometry_overlay()
	_check("collision_overlay_closes_without_affecting_game", not scene._geometry_overlay.visible and actor.position.is_equal_approx(initial_position) and scene._director._encounter_rng.state == initial_rng)
	_check("grass_left_boundary_is_inside", scene.zone_at_position(Vector2(384, 180)) == &"technical_grass")
	_check("grass_right_boundary_is_outside", scene.zone_at_position(Vector2(576, 180)) == &"")
	_check("grass_above_boundary_is_safe", scene.zone_at_position(Vector2(480, 99.99)) == &"")
	_check("grass_bottom_boundary_is_outside", scene.zone_at_position(Vector2(480, 260)) == &"")
	# Time in grass must clip a crossing segment, not count all or none by its endpoint.
	scene._grass_walking_seconds = 0
	scene._observe_walk(Vector2(32, 0), Vector2(32, 0), Vector2(375, 180), Vector2(407, 180))
	_check("grass_entry_time_counts_only_23px_inside", is_equal_approx(float(scene._grass_walking_seconds), 23.0 / 96.0))
	scene._grass_walking_seconds = 0
	scene._observe_walk(Vector2(32, 0), Vector2(32, 0), Vector2(565, 180), Vector2(597, 180))
	_check("grass_exit_time_counts_11px_inside", is_equal_approx(float(scene._grass_walking_seconds), 11.0 / 96.0))
	for row in [
		[Vector2(50, 180), Vector2.LEFT, Vector2(34, 180)],
		[Vector2(600, 180), Vector2.RIGHT, Vector2(606, 180)],
		[Vector2(320, 50), Vector2.UP, Vector2(320, 34)],
		[Vector2(340, 310), Vector2.DOWN, Vector2(340, 326)],
	]:
		actor.position = row[0]
		actor.reset_step_meter()
		await _settle()
		actor.apply_motion(row[1], 1.0)
		_check("map_outer_wall_%s" % str(row[1]), actor.position.distance_to(row[2]) < 0.25)
	var grass := scene.get_node("EncounterZone") as OverworldEncounterZone
	_check("grass_full_crossing_clipped_to_192px", is_equal_approx(grass.distance_within_segment(Vector2(350, 180), Vector2(610, 180)), 192))
	_check("grass_bottom_edge_distance_zero", is_zero_approx(grass.distance_within_segment(Vector2(400, 260), Vector2(500, 260))))
	_check("grass_top_edge_consistent_with_containment", is_equal_approx(grass.distance_within_segment(Vector2(400, 100), Vector2(432, 100)), 32))
	await _frequency_audit(scene)
	var portal: OverworldPortal = scene.get_node("BuildingEntrance")
	var blocked_destination := StaticBody2D.new()
	blocked_destination.position = scene.get_node("BuildingEntrySpawn").position
	blocked_destination.add_child(_shape(Vector2(40, 40)))
	scene.add_child(blocked_destination)
	await _settle()
	var before := actor.position
	_check("occupied_portal_destination_refused", not await scene.traversal_controller.traverse_portal(portal))
	_check("occupied_portal_keeps_position_and_control", actor.position.is_equal_approx(before) and actor.movement_enabled)
	blocked_destination.queue_free()
	await _settle()
	portal.fade_out_msec = 50
	portal.hold_msec = 50
	portal.fade_in_msec = 50
	actor.position = Vector2(72, 278)
	actor.reset_step_meter()
	var transitions := [0]
	scene.traversal_controller.transition_finished.connect(func(_p: Dictionary): transitions[0] += 1)
	await _settle()
	for i in 20:
		actor.apply_motion(Vector2.DOWN, 1.0 / 60.0)
		await physics_frame
		await process_frame
		if scene.traversal_is_busy():
			break
	_check("walking_into_real_door_starts_transition", scene.traversal_is_busy())
	var buttons: Array[Button] = []
	_collect_buttons(scene.get_node("CanvasLayer/FieldHUD"), buttons)
	for button in buttons:
		if button.text.contains("Ajustes"):
			# Programmatic emission exercises the callback even before disabled redraw.
			button.pressed.emit()
	_check("settings_cannot_open_during_door_fade", not scene.test_panel.is_panel_open())
	for i in 30:
		await physics_frame
		await process_frame
		if not scene.traversal_is_busy():
			break
	_check("walk_in_door_finishes_once", transitions[0] == 1)
	_check("walk_in_door_reaches_safe_room", scene.technical_region_id() == &"building")
	_check("door_restores_movement_without_open_settings", actor.movement_enabled and not scene.test_panel.is_panel_open())
	if scene.test_panel.is_panel_open():
		scene.test_panel._close_config()
	# Verify settings arrows do not move the actor, and Escape closes the panel.
	scene.test_panel._open_config()
	var paused := actor.position
	actor.apply_motion(Vector2.RIGHT, 1.0)
	_check("settings_input_does_not_move_character", actor.position.is_equal_approx(paused))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_key_input(escape)
	_check("escape_closes_settings_and_unlocks", not scene.test_panel.is_panel_open() and actor.movement_enabled)
	# Repeat the close-range ledge report with keyboard input on the actual visual map.
	actor.position = Vector2(164, 261)
	actor.facing = Vector2.LEFT
	actor.velocity = Vector2.ZERO
	actor.reset_step_meter()
	await _settle()
	var jumps_before: int = scene.technical_audit_summary().current_run.ledges.jumps
	actor.set_physics_process(true)
	Input.action_press("ui_down")
	for i in 20:
		await physics_frame
		await process_frame
	Input.action_release("ui_down")
	await _settle()
	actor.set_physics_process(false)
	_check("visual_map_keyboard_near_ledge_jumps_once", int(scene.technical_audit_summary().current_run.ledges.jumps) == jumps_before + 1)
	_check("visual_map_keyboard_ledge_preserves_x", is_equal_approx(actor.position.x, 164))
	_check("visual_map_keyboard_ledge_lands_below", actor.position.y >= 306)
	# Exercise the actual grass -> battle -> capture -> exploration path with a long frame.
	scene.test_panel._encounter_chance.value = 100
	scene.restart_field_run()
	actor.position = Vector2(420, 150)
	actor.reset_step_meter()
	await _settle()
	actor.apply_motion(Vector2.RIGHT, 1.0)
	_check("long_frame_real_encounter_starts", scene.has_active_demo_battle())
	_check("long_frame_stops_at_first_grass_step", actor.position.is_equal_approx(Vector2(452, 150)))
	var current: Dictionary = scene.technical_audit_summary().current_run
	_check("long_frame_only_one_encounter_roll", int(current.encounters.rolls) == 1)
	var locked_position := actor.position
	actor.apply_motion(Vector2.DOWN, 1.0)
	_check("battle_input_cannot_walk_or_roll", actor.position.is_equal_approx(locked_position) and int(scene.technical_audit_summary().current_run.encounters.rolls) == 1)
	if scene.has_active_demo_battle():
		var ui: BattlePresentationController = scene.battle_presentation
		var before_party: int = scene.demo_party_size()
		var captured := ui.submit_capture_ball(&"master_ball")
		_check("capture_path_still_updates_party", captured.accepted and captured.session_completed and scene.demo_party_size() == before_party + 1)
		var duplicate := ui.submit_capture_ball(&"master_ball")
		_check("duplicate_capture_does_not_duplicate_creature", not duplicate.accepted and scene.demo_party_size() == before_party + 1)
		_check("capture_continue_resumes_once", ui.continue_after_completion() and not ui.continue_after_completion())
		_check("capture_does_not_trigger_encounter_while_still", not scene.has_active_demo_battle() and int(scene.technical_audit_summary().current_run.encounters.rolls) == 1)
		actor.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		_check("post_capture_movement_is_small_and_normal", actor.position.x > locked_position.x and actor.position.x < locked_position.x + 2)
	scene.queue_free()
	await process_frame
	await physics_frame


func _frequency_audit(scene) -> void:
	var table := WildEncounterTable.new(&"probability_probe", 0)
	table.add_slot(WildEncounterSlot.new(&"only_pidgey", &"pidgey", 1, 4, 4))
	for percent in [0, 5, 15, 30, 100]:
		table.encounter_chance_bp = percent * 100
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261018
		var successes := 0
		var invalid := 0
		var samples := 4000 if percent > 0 and percent < 100 else 40
		for i in samples:
			var result := WildEncounterSystem.resolve(table, rng, scene._catalogs, ProgressionRuleset.new())
			if result.status == WildEncounterResult.ENCOUNTER:
				successes += 1
			elif result.status != WildEncounterResult.NONE:
				invalid += 1
		var expected := float(percent) / 100.0
		var observed := float(successes) / float(samples)
		var tolerance := 5.0 * sqrt(expected * (1.0 - expected) / float(samples))
		_check("frequency_%d_no_invalid_results" % percent, invalid == 0)
		_check("frequency_%d_within_five_sigma" % percent, absf(observed - expected) <= tolerance + 0.000001)
		print("RATE_PROBE target=%d%% observed=%.3f%% samples=%d encounters=%d" % [percent, observed * 100.0, samples, successes])


func _collect_buttons(node: Node, buttons: Array[Button]) -> void:
	if node is Button:
		buttons.append(node)
	for child in node.get_children():
		_collect_buttons(child, buttons)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS " + label)
	else:
		_failed += 1
		push_error("FAIL " + label)
