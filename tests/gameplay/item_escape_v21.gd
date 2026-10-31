extends "res://tests/gameplay/showdown_adventure_test_runner.gd"

const OUT_ESCAPE := "res://.godot/item_escape_v21/"
const ESCAPE_IDS: Array[StringName] = [&"poke_doll", &"fluffy_tail", &"poke_toy"]
var capture := false
var scene: Node2D


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			push_error("ITEM_ESCAPE_V21 timeout"); quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_ESCAPE)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("exact imported family", Session.Escape.items().keys().size() == 3)
	if not capture:
		for id: StringName in ESCAPE_IDS:
			for format: String in ["gen8customgame", "gen9customgame", "gen9calvounifiedv1"]: await positive(id, format, false)
			await positive(id, "gen9calvounifiedv1", true)
			await rejections(id)
			await staged_medicine_then_escape(id)
		await forged_active_spending()
		await forced_switch()
	for id: StringName in ESCAPE_IDS: await map_bag(id)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "gpu": capture}
	var file := FileAccess.open(OUT_ESCAPE + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_ESCAPE_V21 ", report.status, " checks=", checks, " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func owner_snapshot(player: PlayerCollection) -> Dictionary:
	return {"party": player.party.to_dict(), "storage": player.storage.to_dict(), "inventory": player.inventory.to_dict()}


func positive(id: StringName, format: String, trapped: bool) -> void:
	var player := collection(); player.inventory.add(id, 2)
	active = Session.new(catalogs, player, format)
	check("real wild session " + String(id) + format, await active.begin_wild(self, creature("escape_enemy", "mew", 100, [&"mean_look"])))
	if trapped:
		check("native trapping turn", (await active.submit("move 2", active.revision)).accepted)
		check("actual native trapped state", active._checkpoint.roster[0].pokemon[0].trapped)
	var saved: Dictionary = active.snapshot(); await active.close()
	active = Session.new(catalogs, player, format)
	check("restore before item", await active.restore_saved(self, saved))
	var before: Dictionary = active.snapshot(); var hp: int = active.battle_state().active_for_side(&"side_a").current_hp
	var exp: int = player.party.get_creatures()[0].experience
	var result: Dictionary = await active.use_item(id, &"own_0", active.revision)
	check("guaranteed escape " + String(id), result.accepted and active.completion_reason == "FLED" and not active.has_active_battle())
	check("exactly one unit settled", player.inventory.quantity(id) == 1 and active.inventory.quantity(id) == 1)
	check("no native turn or RNG", active.snapshot().native == before.native and result.events.is_empty())
	check("no application RNG or attempt", active.snapshot().adventure.escape_rng == before.adventure.escape_rng and active.snapshot().adventure.capture_rng == before.adventure.capture_rng and active.escape_attempts == int(before.adventure.escape_attempts))
	check("guaranteed resolution", result.escape_resolution.escaped and not result.escape_resolution.rng_consumed and result.escape_resolution.roll == -1)
	check("no XP healing or unrelated spending", result.progression_events.is_empty() and player.party.get_creatures()[0].experience == exp and player.party.get_creatures()[0].current_hp == hp and player.inventory.quantity(&"potion") == 3)
	var settled: Dictionary = owner_snapshot(player)
	check("cannot consume twice", not (await active.use_item(id, &"own_0", active.revision)).accepted and owner_snapshot(player) == settled)
	await active.close()


func rejection(id: StringName, label: String, target: StringName, rev: int, slot := -1) -> void:
	var before: Dictionary = active.snapshot(); var owner_before: Dictionary = owner_snapshot(active.player)
	check(label, not (await active.use_item(id, target, rev, slot)).accepted and active.snapshot() == before and owner_snapshot(active.player) == owner_before)


func rejections(id: StringName) -> void:
	var player := collection(2); player.inventory.add(id, 2)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("rejection wild opens", await active.begin_wild(self, creature("reject_enemy")))
	await rejection(id, "stale revision", &"own_0", active.revision + 1)
	await rejection(id, "reserve actor", &"own_1", active.revision)
	await rejection(id, "foreign target", &"reject_enemy", active.revision)
	await rejection(id, "unexpected move", &"own_0", active.revision, 0)
	active._command_busy = true; await rejection(id, "competing command", &"own_0", active.revision)
	check("rejection retains IPC ownership", active._command_busy); active._command_busy = false
	active.needs_recovery = true; await rejection(id, "interrupted session", &"own_0", active.revision); active.needs_recovery = false
	player.inventory.add(&"ether"); await rejection(id, "changed campaign", &"own_0", active.revision)
	await active.close()
	player = collection(); active = Session.new(catalogs, player)
	check("missing item session", await active.begin_wild(self, creature("no_item_enemy")))
	await rejection(id, "no owned item", &"own_0", active.revision); await active.close()
	player = collection(); player.inventory.add(id, 2); active = Session.new(catalogs, player)
	check("trainer session", await active.begin_trainer(self, &"route_trainer", [creature("trainer_enemy")] as Array[CreatureInstance]))
	check("trainer does not offer item", not active.battle_item_usable(id))
	await rejection(id, "trainer rejection", &"own_0", active.revision); await active.close()


func staged_medicine_then_escape(id: StringName) -> void:
	var player := collection(); player.party.get_creatures()[0].current_hp = 30; player.inventory.add(id, 2)
	active = Session.new(catalogs, player)
	check("medicine escape session", await active.begin_wild(self, creature("medicine_enemy", "mew", 50, [&"growl"])))
	check("medicine uses native turn first", (await active.use_item(&"potion", &"own_0", active.revision)).accepted)
	check("medicine spending remains staged", player.inventory.quantity(&"potion") == 3 and active.inventory.quantity(&"potion") == 2)
	var saved: Dictionary = active.snapshot(); await active.close(); active = Session.new(catalogs, player)
	check("restore prior staged spending", await active.restore_saved(self, saved))
	check("escape publishes both transactions once", (await active.use_item(id, &"own_0", active.revision)).accepted and player.inventory.quantity(&"potion") == 2 and player.inventory.quantity(id) == 1 and player.party.get_creatures()[0].current_hp == 50)
	await active.close()


func forged_active_spending() -> void:
	var player := collection(); player.inventory.add(&"poke_doll", 2); active = Session.new(catalogs, player)
	check("forgery fixture starts", await active.begin_wild(self, creature("forgery_enemy")))
	var forged: Dictionary = active.snapshot().duplicate(true)
	var bag := PlayerInventory.from_dict(forged.adventure.inventory); bag.remove(&"poke_doll")
	forged.adventure.inventory = bag.to_dict(); forged.adventure.spent_items.poke_doll = 1
	var candidate := Session.new(catalogs, player)
	check("active checkpoint cannot invent terminal escape spending", not await candidate.restore_saved(self, forged) and candidate.last_error == "adventure_snapshot_spending")
	await candidate.close(); await active.close()


func forced_switch() -> void:
	var player := collection(2); player.party.get_creatures()[0].current_hp = 1
	for id: StringName in ESCAPE_IDS: player.inventory.add(id)
	active = Session.new(catalogs, player)
	check("forced switch fixture", await active.begin_wild(self, creature("ko_enemy", "mewtwo", 100, [&"psychic"])))
	check("actual KO", (await active.submit("move 2", active.revision)).accepted and active.phase() != "move")
	for id: StringName in ESCAPE_IDS: await rejection(id, "no item during mandatory replacement", &"own_0", active.revision)
	await active.close()


func select_item(view: Control, id: StringName) -> void:
	var found := false
	for i: int in view._medicine_items.item_count:
		if view._medicine_items.get_item_metadata(i) == String(id): view._medicine_items.select(i); found = true
	check("battle bag offers " + String(id), found)
	view._refresh_medicine_moves()


func map_bag(id: StringName) -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection(); owner.inventory.add(id, 2)
	var bridge = scene._native_battles; bridge.save_path = OUT_ESCAPE + ("gpu_" if capture else "headless_") + String(id) + ".json"
	scene.player.global_position = Vector2(420, 150); await scene._on_player_step_completed(scene.player.global_position)
	var view: Control = bridge.view; view._playback.set_process(false)
	check("map real encounter", view.session != null and view.session.has_active_battle())
	check("map save before use", bridge.save_game()); check("map load before use", await bridge.load_game()); view._playback.set_process(false)
	owner = scene.field_collection()
	view.open_medicine_bag(); select_item(view, id)
	check("escape UI hides target label and PP", not view._medicine_target_label.visible and not view._medicine_targets.visible and not view._medicine_moves.visible and view._medicine_hint.text.contains("consume una unidad"))
	# Switching back to medicine restores the old controls in the same popup.
	if view.session.inventory.has(&"potion"):
		select_item(view, &"potion"); check("medicine target controls restored", view._medicine_targets.visible and view._medicine_target_label.visible)
		select_item(view, id)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("popup compact and within window", view._medicine_popup.size.y < scene.get_viewport_rect().size.y and view._medicine_popup.position.y >= 0 and view._medicine_popup.position.y + view._medicine_popup.size.y <= scene.get_viewport_rect().size.y)
		check("GPU escape bag", root.get_texture().get_image().save_png(OUT_ESCAPE + String(id) + ".png") == OK)
	var result: Dictionary = await view.use_selected_medicine()
	check("real bag completes escape " + JSON.stringify(result) + " phase=" + view.session.phase() + " error=" + view.session.last_error, result.accepted and view.session.completion_reason == "FLED" and owner.inventory.quantity(id) == 1)
	check("completion log", view._event_log.get_parsed_text().contains("Has escapado usando"))
	for i in 2000:
		if not view._playback.is_playing(): break
		view._playback.advance(0.25)
	await process_frame
	check("completed UI cannot spend twice", not (await view.use_selected_medicine()).accepted and owner.inventory.quantity(id) == 1)
	await bridge.leave_battle()
	check("back in field", not bridge.busy and not view.visible)
	check("stale closed bag is safe", not (await view.use_selected_medicine()).accepted and owner.inventory.quantity(id) == 1)
	check("map final save", bridge.save_game()); check("map final load", await bridge.load_game())
	check("consumed count persists", scene.field_collection().inventory.quantity(id) == 1)
	scene.queue_free(); await process_frame
