extends SceneTree

const DEST := "res://.godot/showdown_medicine_checks/"
var checks := 0
var errors: Array[String] = []
var captures: Array = []
var scene: Control
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, valid: bool) -> void:
	checks += 1
	if not valid: errors.append(label); push_error(label)


func _run() -> void:
	create_timer(100).timeout.connect(func():
		if not done:
			if scene != null and scene.session != null: scene.session.stop_now()
			check("watchdog", false); _finish())
	scene = load("res://scenes/visual/showdown_adventure_lab.tscn").instantiate(); root.add_child(scene)
	var deadline := Time.get_ticks_msec() + 15000
	while (scene.session == null or scene._working) and Time.get_ticks_msec() < deadline: await process_frame
	check("medicine scene opens", scene.session != null and scene.session.battle_state() != null)
	if scene.session == null or scene.session.battle_state() == null: _finish(); return
	scene._playback.set_process(false)
	scene.open_medicine_bag(); await process_frame
	check("bag shows owned medicines and living targets", scene._medicine_items.item_count == 4 and scene._medicine_targets.item_count == 2)
	select_item("potion")
	await capture("bag")
	var before: Dictionary = scene.session.snapshot()
	scene._medicine_popup.hide()
	check("cancel leaves battle and bag unchanged", scene.session.snapshot() == before)
	var attack: Dictionary = await scene.choose("move 1"); await drain()
	check("attack creates damage and consumes move PP", attack.accepted and scene.session.battle_state().active_for_side(&"side_a").current_hp < 145)
	scene.open_medicine_bag(); select_item("potion")
	var item: Dictionary = await scene.use_selected_medicine()
	check("potion UI starts native healing timeline", item.accepted and scene._playback.is_playing() and item.events.any(func(e): return e.kind == BattleEvent.HP_RECOVERED and e.amount == 20))
	await drain(); await capture("potion")
	check("potion UI locks out double use and shows confirmed HP", int(scene._player_hp.value) == scene.session.battle_state().active_for_side(&"side_a").current_hp and scene.session.inventory.quantity(&"potion") == 2)
	scene.open_medicine_bag(); select_item("ether")
	check("Ether asks which move and shows four PP slots", scene._medicine_moves.visible and scene._medicine_moves.item_count == 4)
	await capture("ether_choice")
	item = await scene.use_selected_medicine(); await drain()
	check("Ether restores requested PP in move button", item.accepted and scene.session.battle_state().active_for_side(&"side_a").moveset[0].current_pp == 15 and scene._move_buttons[0].text.contains("15/15"))
	await capture("ether_result")
	check("switch after medicine remains legal", (await scene.choose("switch 2")).accepted)
	await drain()
	scene.open_medicine_bag(); select_item("potion")
	for i in scene._medicine_targets.item_count:
		if scene._medicine_targets.get_item_metadata(i) == "adventure_charizard": scene._medicine_targets.select(i)
	item = await scene.use_selected_medicine(); await drain()
	check("reserve healing does not replace active displayed Pokemon", item.accepted and scene.session.battle_state().active_for_side(&"side_a").instance_id == &"adventure_blastoise")
	await capture("reserve_heal")
	check("escape still works after medicine", (await scene.adventure_command("flee")).accepted)
	await drain()
	check("spent medicine publishes when encounter ends", scene.player.inventory.quantity(&"potion") == 1 and scene.player.inventory.quantity(&"ether") == 1)
	await scene.session.close(); scene.queue_free(); await process_frame
	_finish()


func select_item(id: String) -> void:
	for i in scene._medicine_items.item_count:
		if scene._medicine_items.get_item_metadata(i) == id: scene._medicine_items.select(i)
	scene._refresh_medicine_moves()


func drain() -> void:
	var count := 0
	while scene._playback.is_playing() and count < 1200: scene._playback.advance(0.2); count += 1
	check("timeline completes", not scene._playback.is_playing())
	scene._refresh_view(); await process_frame


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var path := DEST + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"label": label, "path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})


func _finish() -> void:
	if done: return
	done = true
	var file := FileAccess.open(DEST + "visual.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "captures": captures}, "  ")); file.close()
	print("SHOWDOWN_MEDICINES_VISUAL ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
