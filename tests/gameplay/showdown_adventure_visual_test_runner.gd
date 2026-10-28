extends SceneTree

const DEST := "res://.godot/showdown_adventure_checks/"
var checks := 0
var errors: Array[String] = []
var captures: Array = []
var scene: Control
var done := false
var gpu := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, valid: bool) -> void:
	checks += 1
	if not valid: errors.append(label); push_error(label)


func _run() -> void:
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	create_timer(100).timeout.connect(func():
		if not done:
			if scene != null and scene.session != null: scene.session.stop_now()
			check("visual watchdog", false); _finish())
	var script = load("res://scenes/visual/showdown_adventure_lab.gd")
	check("adventure scene compiles", script != null and script.can_instantiate())
	if script == null or not script.can_instantiate(): _finish(); return
	scene = load("res://scenes/visual/showdown_adventure_lab.tscn").instantiate()
	root.add_child(scene)
	var deadline := Time.get_ticks_msec() + 15000
	while (scene.session == null or scene._working) and Time.get_ticks_msec() < deadline: await process_frame
	check("real collection session opens from scene", scene.session != null and scene.session.battle_state() != null)
	if scene.session == null or scene.session.battle_state() == null: _finish(); return
	scene._playback.set_process(false)
	check("capture escape and bag controls enabled", not scene._ball.disabled and not scene._master.disabled and not scene._flee.disabled)
	check("next encounter cannot abandon an active battle", scene._continue_button.disabled and not await scene.new_battle())
	await capture("initial")
	var result: Dictionary = await scene.adventure_command("master")
	check("capture reuses the existing ball animation sequence", scene._playback.is_playing() and scene._playback._sequence.any(func(step): return step.get("capture_phase") == "throw"))
	await drain()
	check("capture button publishes actual owned creature", result.accepted and scene.player.party.size() == 3 and scene.player.inventory.quantity(&"master_ball") == 1)
	check("terminal capture UI disables attacks and enables next encounter", scene._move_buttons[0].disabled and scene._ball.disabled and not scene._continue_button.disabled)
	await capture("captured")
	check("next encounter preserves player collection", await scene.new_battle() and scene.player.party.size() == 3 and scene.session.inventory.quantity(&"master_ball") == 1)
	check("new encounter clears previous outcome messages", not scene._event_log.get_parsed_text().contains("Capturado"))
	await capture("next_encounter")
	result = await scene.adventure_command("flee")
	check("escape reuses existing flee animation", scene._playback.is_playing())
	await drain()
	check("flee button finishes native encounter", result.accepted and scene.session.completion_reason == "FLED" and scene.player.party.size() == 3)
	await capture("escaped")
	check("third encounter reuses player HP and inventory", await scene.new_battle())
	var turns := 0
	while scene.session.phase() != "finished" and turns < 20:
		result = await scene.choose("move 1" if scene.session.phase() != "opponent_switch" else "")
		check("adventure native attack accepted %d" % turns, result.accepted)
		if not result.accepted: printerr(scene.session.last_error); break
		await drain()
		turns += 1
	await process_frame; await process_frame
	check("native victory automatically settles collection", scene.session.completion_reason == "VICTORY" and not scene.session.has_active_battle())
	check("campaign HP and PP match terminal battle", scene.player.party.get_creatures()[0].current_hp == scene.session.battle_state().active_for_side(&"side_a").current_hp and scene.player.party.get_creatures()[0].moveset[0].current_pp < scene.player.party.get_creatures()[0].moveset[0].max_pp)
	check("postbattle controls allow next encounter", not scene._continue_button.disabled and scene._move_buttons[0].disabled)
	await capture("victory")
	await scene.session.close()
	scene.queue_free(); await process_frame
	_finish()


func drain() -> void:
	var count := 0
	while scene._playback.is_playing() and count < 1200:
		scene._playback.advance(0.2); count += 1
	check("animation finishes", not scene._playback.is_playing())
	scene._refresh_view(); await process_frame


func capture(label: String) -> void:
	if not gpu: return
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var path := DEST + "adventure_" + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"label": label, "path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})


func _finish() -> void:
	if done: return
	done = true
	var file := FileAccess.open(DEST + "visual.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "gpu": gpu, "captures": captures}, "  ")); file.close()
	print("SHOWDOWN_ADVENTURE_VISUAL ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
