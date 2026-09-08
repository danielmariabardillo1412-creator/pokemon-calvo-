class_name OverworldTraversalAuditTestSuite
extends RefCounted

const MAIN_SCENE := "res://scenes/overworld/technical_overworld.tscn"

var _check: Callable


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	_test_metrics_encounter_rate_and_runs()
	_test_portal_and_ledge_contracts()
	await _test_executable_traversal_lab(tree)


func _test_metrics_encounter_rate_and_runs() -> void:
	var metrics := TechnicalAuditMetrics.new()
	metrics.begin_run({"encounter_chance_percent": 25})
	for index in range(100):
		metrics.note_step(&"technical_grass")
		var is_encounter := index % 4 == 3
		metrics.note_encounter_roll(
			is_encounter,
			WildEncounterResult.ENCOUNTER if is_encounter else WildEncounterResult.NONE,
			"" if is_encounter else "chance_miss",
		)
	var summary := metrics.summary()
	var run := summary.get("current_run", {}) as Dictionary
	var overworld := run.get("overworld", {}) as Dictionary
	var encounters := run.get("encounters", {}) as Dictionary
	var rate_audit := encounters.get("rate_audit", {}) as Dictionary
	_check.call("ow_audit_metrics_one_run", int(summary.get("run_count", 0)) == 1)
	_check.call("ow_audit_metrics_steps", int(overworld.get("steps_in_encounter_zones", 0)) == 100)
	_check.call("ow_audit_metrics_rolls", int(encounters.get("rolls", 0)) == 100)
	_check.call("ow_audit_metrics_encounters", int(encounters.get("encounters", 0)) == 25)
	_check.call("ow_audit_metrics_misses", int(encounters.get("misses", 0)) == 75)
	_check.call("ow_audit_metrics_observed_rate", is_equal_approx(float(encounters.get("observed_rate_percent", -1.0)), 25.0))
	_check.call("ow_audit_metrics_expected_rate", is_equal_approx(float(encounters.get("configured_rate_percent", -1.0)), 25.0))
	_check.call("ow_audit_metrics_rate_ok", String(rate_audit.get("status", "")) == "OK")
	_check.call("ow_audit_metrics_dry_streak", int(encounters.get("max_dry_streak_rolls", -1)) == 3)
	_check.call("ow_audit_metrics_mean_interval", is_equal_approx(float(encounters.get("mean_observed_interval_rolls", 0.0)), 4.0))

	metrics.begin_run({"encounter_chance_percent": 50})
	summary = metrics.summary()
	_check.call("ow_audit_metrics_archives_prior_run", (summary.get("completed_runs", []) as Array).size() == 1)
	_check.call("ow_audit_metrics_second_run_clean", int((summary.get("current_run", {}) as Dictionary).get("run_index", -1)) == 1)


func _test_portal_and_ledge_contracts() -> void:
	var portal := OverworldPortal.new()
	portal.fade_out_msec = 120
	portal.hold_msec = 40
	portal.fade_in_msec = 120
	_check.call("ow_portal_expected_duration", portal.expected_duration_msec() == 280)

	var ledge := OverworldLedge.new()
	ledge.allowed_direction = Vector2.DOWN
	_check.call("ow_ledge_accepts_allowed_direction", ledge.direction_matches(Vector2.DOWN))
	_check.call("ow_ledge_rejects_reverse_direction", not ledge.direction_matches(Vector2.UP))
	_check.call("ow_ledge_rejects_side_direction", not ledge.direction_matches(Vector2.LEFT))


func _test_executable_traversal_lab(tree: SceneTree) -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_check.call("ow_traversal_main_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	_check.call("ow_traversal_main_scene_instantiates", scene != null)
	if scene == null:
		return
	tree.root.add_child(scene)
	await tree.process_frame
	await tree.physics_frame

	var player := scene.get_node_or_null("Player") as OverworldPlayer
	var traversal := scene.get_node_or_null("TraversalController") as OverworldTraversalController
	var building_enter := scene.get_node_or_null("BuildingEntrance") as OverworldPortal
	var building_exit := scene.get_node_or_null("BuildingExit") as OverworldPortal
	var cave_enter := scene.get_node_or_null("CaveEntrance") as OverworldPortal
	var cave_exit := scene.get_node_or_null("CaveExit") as OverworldPortal
	var ledge := scene.get_node_or_null("LedgeTrigger") as OverworldLedge
	var building_spawn := scene.get_node_or_null("BuildingEntrySpawn") as Marker2D
	var cave_spawn := scene.get_node_or_null("CaveEntrySpawn") as Marker2D
	var ledge_landing := scene.get_node_or_null("LedgeLanding") as Marker2D

	_check.call("ow_traversal_bootstrap_ready", bool(scene.call("is_demo_ready")))
	_check.call("ow_traversal_player_present", player != null)
	_check.call("ow_traversal_controller_present", traversal != null)
	_check.call("ow_traversal_four_portals", tree.get_nodes_in_group("overworld_portals").size() == 4)
	_check.call("ow_traversal_one_ledge", tree.get_nodes_in_group("overworld_ledges").size() == 1)
	if (
		player == null
		or traversal == null
		or building_enter == null
		or building_exit == null
		or cave_enter == null
		or cave_exit == null
		or ledge == null
		or building_spawn == null
		or cave_spawn == null
		or ledge_landing == null
	):
		scene.queue_free()
		await tree.process_frame
		return

	_check.call("ow_traversal_surface_region_initial", String(scene.call("technical_region_id")) == "surface")
	_check.call("ow_traversal_building_has_no_encounter_zone", String(scene.call("zone_at_position", building_spawn.global_position)).is_empty())
	_check.call("ow_traversal_cave_has_encounter_zone", String(scene.call("zone_at_position", Vector2(320, 655))) == "technical_cave_floor")

	# Use the exact runtime traversal API with near-zero presentation time for headless CI.
	building_enter.fade_out_msec = 0
	building_enter.hold_msec = 0
	building_enter.fade_in_msec = 0
	var building_enter_ok: bool = await traversal.traverse_portal(building_enter)
	_check.call("ow_traversal_building_enter_ok", building_enter_ok)
	_check.call("ow_traversal_building_destination_exact", player.global_position.is_equal_approx(building_spawn.global_position))
	_check.call("ow_traversal_building_region", String(scene.call("technical_region_id")) == "building")
	_check.call("ow_traversal_building_movement_restored", player.movement_enabled)
	_check.call("ow_traversal_building_idle_after_enter", not traversal.is_busy())

	building_exit.fade_out_msec = 0
	building_exit.hold_msec = 0
	building_exit.fade_in_msec = 0
	var building_exit_ok: bool = await traversal.traverse_portal(building_exit)
	_check.call("ow_traversal_building_exit_ok", building_exit_ok)
	_check.call("ow_traversal_building_exit_surface", String(scene.call("technical_region_id")) == "surface")

	cave_enter.fade_out_msec = 0
	cave_enter.hold_msec = 0
	cave_enter.fade_in_msec = 0
	var cave_enter_ok: bool = await traversal.traverse_portal(cave_enter)
	_check.call("ow_traversal_cave_enter_ok", cave_enter_ok)
	_check.call("ow_traversal_cave_destination_exact", player.global_position.is_equal_approx(cave_spawn.global_position))
	_check.call("ow_traversal_cave_region", String(scene.call("technical_region_id")) == "cave")
	_check.call("ow_traversal_cave_spawn_no_immediate_roll_zone", String(scene.call("zone_at_position", cave_spawn.global_position)).is_empty())

	cave_exit.fade_out_msec = 0
	cave_exit.hold_msec = 0
	cave_exit.fade_in_msec = 0
	var cave_exit_ok: bool = await traversal.traverse_portal(cave_exit)
	_check.call("ow_traversal_cave_exit_ok", cave_exit_ok)
	_check.call("ow_traversal_cave_exit_surface", String(scene.call("technical_region_id")) == "surface")

	# Jump through the real controller seam and verify exact landing/restored movement.
	player.global_position = Vector2(200, 230)
	player.facing = Vector2.DOWN
	player.reset_step_meter()
	ledge.jump_duration_msec = 1
	var ledge_ok: bool = await traversal.jump_ledge(ledge)
	_check.call("ow_traversal_ledge_jump_ok", ledge_ok)
	_check.call("ow_traversal_ledge_landing_exact", player.global_position.is_equal_approx(ledge_landing.global_position))
	_check.call("ow_traversal_ledge_movement_restored", player.movement_enabled)

	# From below, the collision barrier must stop a reverse crossing.
	player.global_position = Vector2(200, 306)
	player.velocity = Vector2.ZERO
	player.reset_step_meter()
	await tree.physics_frame
	var reverse_moved := player.apply_motion(Vector2.UP, 0.5)
	_check.call("ow_traversal_ledge_reverse_collision", reverse_moved.length() < player.move_speed * 0.5 - 1.0)
	_check.call("ow_traversal_ledge_reverse_stays_below", player.global_position.y >= 293.0)

	var audit := scene.call("technical_audit_summary") as Dictionary
	var current_run := audit.get("current_run", {}) as Dictionary
	var transitions := current_run.get("transitions", {}) as Dictionary
	var ledges := current_run.get("ledges", {}) as Dictionary
	_check.call("ow_traversal_metrics_four_transitions", int(transitions.get("completed", 0)) == 4)
	_check.call("ow_traversal_metrics_two_kinds", (transitions.get("by_kind", {}) as Dictionary).size() == 2)
	_check.call("ow_traversal_metrics_ledge_recorded", int(ledges.get("jumps", 0)) == 1)
	_check.call("ow_traversal_metrics_no_position_errors", int(transitions.get("position_error_count", -1)) == 0 and int(ledges.get("position_error_count", -1)) == 0)

	scene.queue_free()
	await tree.process_frame
