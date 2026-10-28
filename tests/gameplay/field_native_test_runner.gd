extends SceneTree

const OUT := "res://.godot/field_native_checks/"
var scene: Node2D
var bridge: Node
var view: Control
var checks := 0
var errors: Array[String] = []
var captures: Array = []
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)
		if bridge != null: printerr(bridge.last_error)


func mon(id: String, species: String, level: int, moves: Array) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(scene._catalogs.species(StringName(species)), level, scene._catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""; return c


func setup_party(moves: Array = ["reflect"], species: String = "mew", level: int = 40) -> void:
	if view.session != null: view._playback.cancel(); await view.session.close()
	view.hide(); bridge.busy = false; bridge.kind = ""; bridge.clocks.clear()
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "pidgey"; config.wild_min_level = 5; config.wild_max_level = 5; config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	scene._session.player.party = CreatureParty.new()
	scene._session.player.party.add_creature(mon("own", species, level, moves))
	scene._session.player.party.add_creature(mon("reserve", "mew", 50, ["flamethrower", "tackle"]))
	scene._session.player.inventory.add(&"potion", 2)
	scene.player.global_position = Vector2(420, 150)
	bridge._unlock_world(); await physics_frame


func encounter() -> void:
	await scene._on_player_step_completed(scene.player.global_position)
	check("grass starts native battle", scene.has_active_demo_battle() and view.session != null and view.session.has_active_battle())
	check("legacy server is idle", not scene._session.has_active_battle() and not scene._trainer_session.has_active_battle())
	view._playback.set_process(false)


func drain() -> void:
	var count := 0
	while view._playback.is_playing() and count < 2000:
		view._playback.advance(0.25); count += 1
	await process_frame; await process_frame
	view._refresh_view()
	check("native timeline completes", not view._playback.is_playing())


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(240).timeout.connect(func():
		if not done:
			if view != null and view.session != null: view.session.stop_now()
			check("watchdog", false); _finish())
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	bridge = scene._native_battles; view = bridge.view
	bridge.save_path = OUT + "save.json"
	check("ordinary field defaults to native connection", bridge != null and scene.is_demo_ready())
	check("project entry is the same field", ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/visual/field_demo.tscn")
	var initial: Vector2 = scene.player.global_position
	Input.action_press("ui_right")
	for i in 6: await physics_frame
	Input.action_release("ui_right"); await physics_frame
	check("normal map keyboard movement", scene.player.global_position.x > initial.x)
	var state: int = scene._director._encounter_rng.state
	await scene._on_player_step_completed(Vector2(96, 180))
	check("outside grass does not consume encounter RNG", scene._director._encounter_rng.state == state)
	scene.toggle_pokemon_gallery()
	check("gallery blocks save and trainer commands", not bridge.save_game() and not scene.start_demo_trainer_battle())
	await scene._on_player_step_completed(Vector2(420, 150))
	check("gallery blocks encounter commands and RNG", not bridge.occupied() and scene._director._encounter_rng.state == state)
	scene.toggle_pokemon_gallery()
	check("closing gallery returns normal input", scene.player.movement_enabled)
	await capture("route_native")
	await setup_party()
	var owned: CreatureInstance = scene._session.player.party.get_creature(&"own")
	await encounter()
	check("map is locked during native battle", not scene.player.movement_enabled and not scene._can_configure())
	var position: Vector2 = scene.player.global_position
	Input.action_press("ui_right")
	for i in 4: await physics_frame
	Input.action_release("ui_right")
	check("held movement cannot leak through combat", scene.player.global_position == position)
	await capture("wild_native")
	check("map battle accepts native move", (await view.choose("move 1")).accepted); await drain()
	check("unsettled battle keeps original owned object unchanged", scene._session.player.party.get_creature(&"own") == owned)
	view.open_medicine_bag()
	for i in view._medicine_items.item_count:
		if view._medicine_items.get_item_metadata(i) == "potion": view._medicine_items.select(i)
	for i in view._medicine_targets.item_count:
		if view._medicine_targets.get_item_metadata(i) == "own": view._medicine_targets.select(i)
	view._refresh_medicine_moves()
	check("map medicine uses real staged inventory", (await view.use_selected_medicine()).accepted and view.session.inventory.quantity(&"potion") == 1 and scene.demo_inventory_quantity(&"potion") == 2); await drain()
	check("active native map save", bridge.save_game())
	var saved: Dictionary = view.session.snapshot()
	var saved_party: int = scene.demo_party_size()
	bridge.load_game.call_deferred(); await process_frame
	check("load locks battle command input", bridge.busy and view._working and not (await view.choose("move 1")).accepted)
	check("save cannot race an in-flight load", not bridge.save_game())
	while bridge.busy: await process_frame
	view._playback.set_process(false)
	check("load lock releases onto the same checkpoint", view.session.snapshot() == saved and not view._working)
	check("native capture from map", (await view.adventure_command("master")).accepted); await drain()
	check("capture updates real map collection", scene.demo_party_size() == saved_party + 1 and scene.demo_inventory_quantity(&"master_ball") == 0)
	var reloaded: bool = await bridge.load_game()
	if reloaded and view.session.snapshot() != saved:
		var debug_file := FileAccess.open(OUT + "snapshot_diff.json", FileAccess.WRITE)
		debug_file.store_string(JSON.stringify({"before": saved, "after": view.session.snapshot()}, "  ")); debug_file.close()
	check("load rolls back to exact active checkpoint", reloaded and view.session.snapshot() == saved and scene.demo_party_size() == saved_party and scene.demo_inventory_quantity(&"master_ball") == 1)
	view._playback.set_process(false)
	check("recapture after checkpoint reload happens once", (await view.adventure_command("master")).accepted); await drain()
	check("capture has one canonical ownership", scene.demo_party_size() == saved_party + 1)
	check("medicine spending persists exactly once", scene.demo_inventory_quantity(&"potion") == 1)
	check("settled map save", bridge.save_game())
	await bridge.leave_battle()
	check("return to same map position", not bridge.occupied() and scene.player.movement_enabled and scene.player.global_position == position)
	await capture("captured_map")
	check("settled save loads without resurrecting battle", await bridge.load_game() and not bridge.occupied() and scene.demo_party_size() == saved_party + 1 and scene.demo_inventory_quantity(&"master_ball") == 0)
	await _save_failures()
	await _forced_switch()
	await _trainer()
	await _flee_and_defeat()
	await _sleep_continuity()
	await _pc_capture()
	await _mechanics_and_recovery()
	if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame
	_finish()


func _save_failures() -> void:
	var bytes := FileAccess.get_file_as_bytes(bridge.save_path)
	var collection: PlayerCollection = scene._session.player
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(bridge.save_path))
	envelope.payload.world.position = [280, 180] # Centre obstacle, even with a valid checksum.
	envelope.sha256 = JSON.stringify(envelope.payload).sha256_text()
	var f := FileAccess.open(bridge.save_path, FileAccess.WRITE); f.store_string(JSON.stringify(envelope)); f.close()
	var before: Vector2 = scene.player.global_position
	check("blocked destination rejected without publication", not await bridge.load_game() and scene._session.player == collection and scene.player.global_position == before)
	f = FileAccess.open(bridge.save_path, FileAccess.WRITE); f.store_buffer(bytes); f.close()
	bridge.saves.serializer.rename_failure_inject = func(a: String, b: String):
		if a.ends_with(".tmp"): return ERR_CANT_CREATE
		return DirAccess.rename_absolute(ProjectSettings.globalize_path(a), ProjectSettings.globalize_path(b))
	check("failed atomic publish preserves last good save", not bridge.save_game() and FileAccess.get_file_as_bytes(bridge.save_path) == bytes)
	bridge.saves.serializer.rename_failure_inject = Callable()
	check("old good save remains loadable", await bridge.load_game())
	var invalid_preset: Dictionary = scene._active_config.duplicate(true)
	invalid_preset.player_team = []
	scene._on_configuration_applied(invalid_preset)
	check("rejected configuration cannot overwrite good campaign", not bridge.save_game() and FileAccess.get_file_as_bytes(bridge.save_path) == bytes)
	check("good campaign recovers after rejected configuration", await bridge.load_game() and scene.player.movement_enabled)


func _forced_switch() -> void:
	await setup_party(["tackle"], "caterpie", 5)
	scene._session.player.party.get_creature(&"own").current_hp = 1
	await encounter()
	check("KO requests native replacement", (await view.choose("move 1")).accepted and view.session.phase() == "player_switch"); await drain()
	check("replacement checkpoint saves", bridge.save_game())
	check("replacement checkpoint reloads exact phase", await bridge.load_game() and view.session.phase() == "player_switch")
	view._playback.set_process(false)
	check("replacement accepted through map UI", (await view.choose("switch 2")).accepted); await drain()
	check("replacement may attack", (await view.choose("move 1")).accepted); await drain()
	check("victory publishes real KO and XP", view.session.completion_reason == "VICTORY" and scene._session.player.party.get_creature(&"own").current_hp == 0 and scene._session.player.party.get_creature(&"reserve").experience > 0)
	await capture("victory_native")
	var xp: int = scene._session.player.party.get_creature(&"reserve").experience
	check("finished battle saves", bridge.save_game())
	await bridge.leave_battle()
	check("loading settled victory does not pay XP twice", await bridge.load_game() and scene._session.player.party.get_creature(&"reserve").experience == xp and not bridge.occupied())


func _trainer() -> void:
	await setup_party(["flamethrower"])
	var opponent := mon("trainer_owned", "caterpie", 5, ["tackle"])
	check("trainer owner fixture", scene._trainer_campaign_owner.configure(scene.TECHNICAL_TRAINER_ID, [opponent] as Array[CreatureInstance]))
	check("trainer trigger accepts native queue", scene.start_demo_trainer_battle())
	while bridge.busy: await process_frame
	view._playback.set_process(false)
	check("trainer uses same native path", view.session.battle_kind == "trainer" and scene.has_active_demo_trainer_battle())
	check("trainer recovery blocked during native battle", not scene.recover_demo_trainer_full())
	check("trainer forbids capture and flee", not (await view.session.capture(&"master_ball", view.session.revision)).accepted and not (await view.session.flee(view.session.revision)).accepted and not view._ball.visible)
	check("trainer checkpoint saves", bridge.save_game())
	check("trainer checkpoint recovers owned roster", await bridge.load_game() and view.session.battle_kind == "trainer")
	view._playback.set_process(false)
	var owner: TrainerCampaignRosterOwner = scene._trainer_campaign_owner
	var original: CreatureInstance = owner.owned_creature(&"trainer_owned")
	check("trainer move through visible UI", (await view.choose("move 1")).accepted); await drain()
	check("trainer KO persists on same owned object", view.session.completion_reason == "VICTORY" and owner.owned_creature(&"trainer_owned") == original and original.current_hp == 0)
	await capture("trainer_victory")
	check("trainer result saves", bridge.save_game())
	await bridge.leave_battle()
	check("defeated trainer is not silently restored", not scene.start_demo_trainer_battle())
	check("trainer defeat persists after map load", await bridge.load_game() and scene._trainer_campaign_owner.owned_creature(&"trainer_owned").current_hp == 0 and not scene.start_demo_trainer_battle())


func _flee_and_defeat() -> void:
	await setup_party()
	await encounter()
	check("map escape uses real session", (await view.adventure_command("flee")).accepted and view.session.completion_reason == "FLED"); await drain()
	check("escape does not spend capture inventory", scene.demo_inventory_quantity(&"master_ball") == 1)
	await bridge.leave_battle()
	check("escape returns to movement", scene.player.movement_enabled and not bridge.occupied())
	await setup_party(["tackle"], "caterpie", 5)
	scene._session.player.party.remove_creature(&"reserve")
	scene._session.player.party.get_creature(&"own").current_hp = 1
	var initial_xp: int = scene._session.player.party.get_creature(&"own").experience
	await encounter()
	check("last real KO produces defeat", (await view.choose("move 1")).accepted); await drain()
	check("defeat preserves KO without XP or healing", view.session.completion_reason == "DEFEAT" and scene._session.player.party.get_creature(&"own").current_hp == 0 and scene._session.player.party.get_creature(&"own").experience == initial_xp)
	check("defeated collection saves", bridge.save_game()); await bridge.leave_battle()
	check("defeat reload preserves no living party", await bridge.load_game() and scene._session.player.party.get_creature(&"own").current_hp == 0)
	var state: int = scene._director._encounter_rng.state
	await scene._on_player_step_completed(scene.player.global_position)
	check("no encounter or RNG draw without living party", not bridge.occupied() and scene._director._encounter_rng.state == state)


func _sleep_continuity() -> void:
	await setup_party(["rest", "tackle"])
	scene._session.player.party.get_creature(&"own").current_hp = 10
	await encounter()
	check("native Rest accepted", (await view.choose("move 1")).accepted); await drain()
	check("capture can settle while player sleeps", (await view.adventure_command("master")).accepted); await drain()
	var clock: Dictionary = bridge.clocks.get("own", {})
	check("sleep clock comes from native condition", not clock.is_empty() and scene._session.player.party.get_creature(&"own").status_state.turns_remaining == int(clock.time))
	check("sleeping collection saves", bridge.save_game()); await bridge.leave_battle()
	check("sleeping collection reloads", await bridge.load_game())
	await encounter()
	check("next encounter preserves exact sleep clock", view.session._checkpoint.roster[0].pokemon[0].sleep_clock == clock)
	check("sleep action uses native remaining turns", (await view.choose("move 2")).accepted); await drain()
	check("sleep checkpoint saves", bridge.save_game())
	var saved: Dictionary = view.session.snapshot()
	check("sleep checkpoint restores without reroll", await bridge.load_game() and view.session.snapshot() == saved)


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var file := OUT + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(file) == OK)
	captures.append({"path": file.trim_prefix("res://"), "sha256": FileAccess.get_sha256(file)})


func _pc_capture() -> void:
	await setup_party()
	for i in 4: scene._session.player.party.add_creature(mon("bench_%d" % i, "mew", 20, ["tackle"]))
	await encounter()
	var id: StringName = view.session.battle_state().active_for_side(&"side_b").instance_id
	check("full team capture routes into actual PC", (await view.adventure_command("master")).accepted and scene.demo_party_size() == 6 and scene.demo_storage_contains(id)); await drain()
	check("party and PC save together", bridge.save_game()); await bridge.leave_battle()
	check("PC identity survives field reload", await bridge.load_game() and scene.demo_party_size() == 6 and scene.demo_storage_contains(id) and scene._session.player.storage.get_all_creatures().size() == 1)


func _mechanics_and_recovery() -> void:
	await setup_party(["flamethrower", "protect"])
	scene._session.player.party.get_creature(&"own").held_item_id = &"firium_z_held"
	await encounter()
	check("Z crystal is usable in ordinary map battle", not view._z_toggle.disabled)
	view._z_toggle.button_pressed = true
	check("map Z action uses native resolved attack", (await view.choose("move 1")).accepted and view._last_result.events.any(func(e): return e.move_id == &"inferno_overdrive_special")); await drain()
	check("map Z preserves crystal and base moves", scene._session.player.party.get_creature(&"own").held_item_id == &"firium_z_held" and scene._session.player.party.get_creature(&"own").moveset[0].move_id == &"flamethrower")
	await setup_party(["reflect", "protect"])
	await encounter()
	var saved: Dictionary = view.session.snapshot()
	OS.kill(view.session._client.pid); await create_timer(0.04).timeout
	check("dead worker rejects action and preserves checkpoint", not (await view.choose("move 1")).accepted and view.session.needs_recovery and view.session.snapshot() == saved)
	check("field recovery reopens last confirmed worker state", await bridge.recover_battle() and view.session.snapshot() == saved)
	check("recovered field accepts subsequent action", (await view.choose("move 1")).accepted); await drain()
	await setup_party(["flamethrower", "protect"])
	bridge.format_id = "gen8customgame"; bridge.kind = "wild"; bridge.busy = true
	await bridge._open(mon("max_target", "mew", 100, ["reflect"]), -1)
	view._playback.set_process(false)
	check("explicit Gen8 map profile exposes Dynamax", view._dynamax_toggle.visible and not view._dynamax_toggle.disabled)
	view._dynamax_toggle.button_pressed = true
	check("map Dynamax uses native Max action", (await view.choose("move 1")).accepted and view._last_result.events.any(func(e): return e.move_id == &"max_flare")); await drain()
	check("Dynamax field checkpoint saves", bridge.save_game())
	saved = view.session.snapshot()
	check("Dynamax reload retains explicit format and native state", await bridge.load_game() and bridge.format_id == "gen8customgame" and view.session.snapshot() == saved)
	view._playback.set_process(false)
	check("Dynamax checkpoint can capture", (await view.adventure_command("master")).accepted); await drain()
	check("temporary max HP never persists in collection", scene._session.player.party.get_creature(&"own").stats.max_hp == mon("reference", "mew", 40, ["tackle"]).stats.max_hp)
	await bridge.leave_battle(); bridge.format_id = "gen9customgame"


func _finish() -> void:
	if done: return
	done = true
	var gpu := DisplayServer.get_name() != "headless"
	var f := FileAccess.open(OUT + ("gpu.json" if gpu else "gameplay.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "captures": captures}, "  ")); f.close()
	print("FIELD_NATIVE ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " GPU=", gpu, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
