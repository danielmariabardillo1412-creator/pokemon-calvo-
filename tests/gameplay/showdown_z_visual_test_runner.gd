extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const OUT := "res://.godot/showdown_z_checks/"
var scene: Control
var checks := 0
var errors: Array[String] = []
var captures: Array = []
var clips: Array[String] = []
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)


func mon(id: String, species: String, moves: Array, item: String = "", level: int = 50) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(scene.catalogs.species(StringName(species)), level, scene.catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""; c.held_item_id = StringName(item); return c


func open_case(own: CreatureInstance, enemy: CreatureInstance) -> void:
	scene._playback.cancel(); await scene.session.close()
	scene.session = Backend.new(scene.catalogs)
	scene._z_toggle.set_pressed_no_signal(false)
	check("visual opens " + String(own.moveset[0].move_id), await scene.session.open(self, [own] as Array[CreatureInstance], [enemy] as Array[CreatureInstance]))
	scene._event_log.clear(); scene._event_log.text = "Prueba de movimientos Z."
	scene.diagnostic_event.emit({"event": "battle_opened"}); scene._refresh_view()


func _run() -> void:
	create_timer(120).timeout.connect(func():
		if not done:
			if scene != null and scene.session != null: scene.session.stop_now()
			check("watchdog", false); _finish())
	scene = load("res://scenes/visual/showdown_battle_lab.tscn").instantiate(); root.add_child(scene)
	var deadline := Time.get_ticks_msec() + 15000
	while (scene.session == null or scene._working) and Time.get_ticks_msec() < deadline: await process_frame
	if scene.session == null or scene.session.battle_state() == null: check("scene ready", false); _finish(); return
	scene._playback.set_process(false)
	await open_case(mon("own", "charizard", ["flamethrower", "protect"], "firium_z_held"), mon("enemy", "mew", ["reflect"], "", 100))
	check("Z selector available", not scene._z_toggle.disabled)
	scene._z_toggle.button_pressed = true
	check("only native damaging offer selectable", not scene._move_buttons[0].disabled and scene._move_buttons[1].disabled and scene._move_buttons[0].text.contains("Z"))
	check("UI Z accepted", (await scene.choose("move 1")).accepted)
	await drain("inferno_back")
	check("Z uses existing reviewed back clip", "inferno_overdrive_special/back" in clips)
	check("spent Z selector disabled", scene._z_toggle.disabled and not scene._z_toggle.button_pressed)
	check("base PP shown after Z", scene._move_buttons[0].text.contains("PP"))
	await capture("inferno_done")
	await open_case(mon("own", "mew", ["tackle"], "normalium_z_held"), mon("enemy", "mew", ["protect"], "", 100))
	scene._z_toggle.button_pressed = true
	check("damaging Z passes Protect with native reduced damage", (await scene.choose("move 1")).accepted and scene.session.battle_state().creature(&"enemy").current_hp < scene.session.battle_state().creature(&"enemy").stats.max_hp)
	check("native Protect break protocol present", str(scene.session._checkpoint.snapshot.native.log).contains("-zbroken"))
	await drain("protect_chip")
	await open_case(mon("own", "mew", ["shadow_ball"], "ghostium_z_held"), mon("enemy", "snorlax", ["reflect"], "", 100))
	scene._z_toggle.button_pressed = true
	check("immune target is legitimate result and spends Z", (await scene.choose("move 1")).accepted and scene.session.z_move_id(0).is_empty() and scene.session.battle_state().creature(&"enemy").current_hp == scene.session.battle_state().creature(&"enemy").stats.max_hp)
	await drain("")
	await open_case(mon("own", "mew", ["reflect"], "", 100), mon("enemy", "pikachu", ["volt_tackle"], "pikanium_z_held"))
	scene.diagnostic_event.emit({"event": "command", "kind": "move"})
	var result: Dictionary = await scene.session._submit_choices({"p1": "move 1", "p2": "move 1 zmove"})
	check("opponent signature Z accepted", result.accepted)
	if result.accepted:
		var events: Array[BattleEvent] = []; events.assign(result.events)
		scene._playback.note_event_messages(events)
		var rows: Array = []
		for e: BattleEvent in events: rows.append(e.to_dict())
		scene.diagnostic_event.emit({"event": "turn_resolved", "battle_events": rows}); scene._refresh_view()
		await drain("catastropika_front")
		check("signature Z uses reviewed front clip", "catastropika/front" in clips)
	await open_case(mon("own", "mew", ["conversion"], "normalium_z_held"), mon("enemy", "mew", ["reflect"]))
	check("status Z unavailable in UI", scene._z_toggle.disabled and not scene._move_buttons[0].disabled)
	check("ordinary status still accepted in UI", (await scene.choose("move 1")).accepted)
	await drain("")
	await scene.session.close(); scene.queue_free(); await process_frame
	_finish()


func drain(label: String) -> void:
	var count := 0
	var captured := false
	var desired: String = {"inferno_back": "inferno_overdrive_special/back", "protect_chip": "breakneck_blitz_physical/back", "catastropika_front": "catastropika/front"}.get(label, "")
	while scene._playback.is_playing() and count < 2000:
		var step: Dictionary = scene._playback._sequence[scene._playback._index]
		var key := String(step.get("catalog_clip", step.get("community_clip", "")))
		if not key.is_empty() and key not in clips: clips.append(key)
		if not captured and key == desired and not label.is_empty():
			scene._playback.advance(float(step.get("duration", 0.4)) * 0.4)
			check("inputs locked during Z playback " + label, scene._move_buttons[0].disabled)
			await capture(label); captured = true
		scene._playback.advance(0.25); count += 1
		await process_frame
	check("timeline finishes", not scene._playback.is_playing())
	if not label.is_empty(): check("captured requested Z clip " + desired, captured)
	scene._refresh_view()
	check("HUD matches native HP", int(scene._player_hp.value) == scene.session.battle_state().active_for_side(&"side_a").current_hp and int(scene._enemy_hp.value) == scene.session.battle_state().active_for_side(&"side_b").current_hp)


func capture(label: String) -> void:
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var file := OUT + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(file) == OK)
	captures.append({"path": file.trim_prefix("res://"), "sha256": FileAccess.get_sha256(file)})


func _finish() -> void:
	if done: return
	done = true
	var f := FileAccess.open(OUT + "visual.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "captures": captures, "clips": clips}, "  ")); f.close()
	print("SHOWDOWN_Z_VISUAL ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
