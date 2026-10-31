extends SceneTree

const Session = preload("res://modules/gameplay/showdown_adventure_session.gd")
const Doll = preload("res://modules/battle/application/substitute_rules.gd")
const OUT := "res://.godot/showdown_move_repair_checks/"
var scene: Control
var checks := 0
var errors: Array[String] = []
var captures: Array = []
var done := false
var clip_keys: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(name: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(name); push_error(name)


func mon(id: String, moves: Array, species: String = "mew", level: int = 50) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(scene.catalogs.species(StringName(species)), level, scene.catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""; return c


func open_case(moves: Array, enemy_moves: Array, enemy_species: String = "snorlax", format: String = "gen9customgame", hp: int = -1) -> void:
	scene._playback.cancel(); await scene.session.close()
	scene.player = PlayerCollection.new()
	var own := mon("own", moves)
	if hp >= 0: own.current_hp = hp
	scene.player.party.add_creature(own); scene.player.party.add_creature(mon("reserve", ["tackle"], "charizard"))
	scene.player.inventory.add(&"master_ball", 1)
	scene.session = Session.new(scene.catalogs, scene.player, format)
	scene._battle_format = format
	scene._dynamax_toggle.set_pressed_no_signal(false)
	check("open visual " + String(moves[0]), await scene.session.begin_wild(self, mon("enemy", enemy_moves, enemy_species)))
	scene._event_log.clear(); scene._event_log.text = "Prueba de conexión de movimientos."
	scene.diagnostic_event.emit({"event": "battle_opened"}); scene._refresh_view()


func _run() -> void:
	create_timer(150).timeout.connect(func():
		if not done:
			if scene != null and scene.session != null: scene.session.stop_now()
			check("watchdog", false); _finish())
	scene = load("res://scenes/visual/showdown_adventure_lab.tscn").instantiate(); root.add_child(scene)
	var deadline := Time.get_ticks_msec() + 15000
	while (scene.session == null or scene._working) and Time.get_ticks_msec() < deadline: await process_frame
	if scene.session == null or scene.session.battle_state() == null: check("scene opens", false); _finish(); return
	scene._playback.set_process(false)
	await open_case(["transform", "protect"], ["reflect", "tackle", "protect"])
	check("visual Transform accepted", (await scene.choose("move 1")).accepted); await drain()
	check("transformed sprite uses native species", scene._arena.player_species == &"snorlax")
	await capture("transform")
	check("transformed switch accepted", (await scene.choose("switch 2")).accepted); await drain()
	check("withdrawn transformer restored native base species", scene.session.battle_state().creature(&"own").species_id == &"mew")
	await capture("transform_switch")
	await open_case(["substitute", "tackle"], ["tackle"])
	var response: Dictionary = await scene.choose("move 1"); await drain()
	check("visual native doll survives first hit", response.accepted and Doll.hp(scene.session.battle_state().active_for_side(&"side_a")) > 0)
	await capture("substitute_damaged")
	response = await scene.choose("move 2"); await drain()
	check("visual native doll breaks on later hit", response.accepted and Doll.hp(scene.session.battle_state().active_for_side(&"side_a")) == 0)
	await capture("substitute_broken")
	await open_case(["shed_tail"], ["reflect"])
	check("Shed Tail pauses UI for replacement", (await scene.choose("move 1")).accepted and scene.session.phase() == "player_switch"); await drain()
	check("Shed Tail switch UI resumes", (await scene.choose("switch 2")).accepted); await drain()
	check("transferred doll shown on actual reserve", Doll.hp(scene.session.battle_state().active_for_side(&"side_a")) > 0 and scene._arena.player_species == &"charizard")
	await capture("shed_tail")
	await open_case(["pain_split"], ["reflect"], "snorlax", "gen9customgame", 20)
	check("visual Pain Split accepted", (await scene.choose("move 1")).accepted); await drain()
	check("Pain Split HUD exact for both sides", int(scene._player_hp.value) == scene.session.battle_state().active_for_side(&"side_a").current_hp and int(scene._enemy_hp.value) == scene.session.battle_state().active_for_side(&"side_b").current_hp)
	await capture("pain_split")
	await open_case(["tackle", "protect"], ["reflect"], "snorlax", "gen8customgame")
	check("explicit Gen8 UI offers Dynamax", scene._dynamax_toggle.visible and not scene._dynamax_toggle.disabled)
	scene._dynamax_toggle.button_pressed = true
	response = await scene.choose("move 1"); await drain()
	check("Dynamax UI choice executed native Max Strike", response.accepted and response.events.any(func(e): return e.move_id == &"max_strike" and e.kind == BattleEvent.ACTION_USED))
	check("Dynamax timeline updates max HP", int(scene._player_hp.max_value) == scene.session.battle_state().active_for_side(&"side_a").stats.max_hp and int(scene._player_hp.max_value) > 250)
	check("Max Strike uses reviewed existing clip", "max_strike/back" in clip_keys)
	await capture("max_strike")
	check("second Dynamax turn accepted", (await scene.choose("move 2")).accepted); await drain()
	check("third Dynamax turn accepted", (await scene.choose("move 2")).accepted); await drain()
	check("Dynamax expires and HUD returns to base HP", int(scene._player_hp.max_value) == scene.player.party.get_creature(&"own").stats.max_hp)
	await capture("max_expired")
	await scene.session.close(); scene.queue_free(); await process_frame
	_finish()


func drain() -> void:
	var snapshot: Dictionary = scene.session.snapshot()
	var count := 0
	while scene._playback.is_playing() and count < 2000:
		var step: Dictionary = scene._playback._sequence[scene._playback._index]
		var key := String(step.get("catalog_clip", step.get("community_clip", "")))
		if not key.is_empty() and key not in clip_keys: clip_keys.append(key)
		scene._playback.advance(0.2); count += 1
	check("timeline completes", not scene._playback.is_playing())
	check("playback never mutates native state", scene.session.snapshot() == snapshot)
	scene._refresh_view(); await process_frame


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var file := OUT + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(file) == OK)
	captures.append({"label": label, "path": file.trim_prefix("res://"), "sha256": FileAccess.get_sha256(file)})


func _finish() -> void:
	if done: return
	done = true
	var f := FileAccess.open(OUT + "visual.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "captures": captures, "clip_keys": clip_keys}, "  ")); f.close()
	print("SHOWDOWN_MOVE_REPAIR_VISUAL ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
