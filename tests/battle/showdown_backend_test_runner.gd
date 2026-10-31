extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const DEST := "res://.godot/showdown_backend_checks/"
var checks := 0
var errors: Array[String] = []
var captures: Array = []
var scene: Control
var gpu := false
var done := false
var clip_keys: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, valid: bool) -> void:
	checks += 1
	if not valid: errors.append(label); push_error(label)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	create_timer(120).timeout.connect(func():
		if not done:
			if scene != null and scene.session != null: scene.session.stop_now()
			check("test completes before watchdog", false)
			_finish())
	var script = load("res://scenes/visual/showdown_battle_lab.gd")
	check("experimental presentation script compiles", script != null and script.can_instantiate())
	if script == null or not script.can_instantiate(): _finish(); return
	scene = load("res://scenes/visual/showdown_battle_lab.tscn").instantiate()
	root.add_child(scene)
	var deadline := Time.get_ticks_msec() + 15000
	while (scene.session == null or scene._working) and Time.get_ticks_msec() < deadline: await process_frame
	check("experimental scene boots native backend", scene.session != null and scene.session.battle_state() != null)
	if scene.session == null or scene.session.battle_state() == null: _finish(); return
	scene._playback.set_process(false)
	check("legacy default project scene is unchanged", ProjectSettings.get_setting("application/run/main_scene") != "res://scenes/visual/showdown_battle_lab.tscn")
	check("native request renders four player choices", scene._move_buttons.size() == 4 and not scene._move_buttons[0].disabled)
	await _capture("initial")
	var state: BattleState = scene.session.battle_state()
	var hp := state.active_for_side(&"side_a").current_hp
	var result: Dictionary = await scene.choose("move 2")
	check("native Protect accepted", result.get("accepted", false))
	check("Protect prevents enemy damage", scene.session.battle_state().active_for_side(&"side_a").current_hp == hp)
	await _drain("protect")
	var before: Dictionary = scene.session.snapshot()
	var rejected: Dictionary = await scene.choose("switch 99")
	check("invalid switch rejected atomically", not rejected.get("accepted", true) and scene.session.snapshot() == before)
	var stale: Dictionary = await scene.session.submit("move 1", -1)
	check("stale UI revision rejected", not stale.accepted and scene.session.snapshot() == before)
	check("experimental save writes its own file", scene.save_battle(DEST + "saved.json"))
	check("experimental save header is explicit", JSON.parse_string(FileAccess.get_file_as_string(DEST + "saved.json")).backend == Backend.BACKEND)
	check("same native state survives UI load", await scene.load_battle(DEST + "saved.json") and scene.session.snapshot() == before)
	var replay := Backend.new(scene.catalogs)
	check("detached native replay starts from versioned snapshot", await replay.restore_saved(self, before))
	var screen: Dictionary = await scene.choose("move 3")
	var replayed: Dictionary = await replay.submit("move 3", replay.revision)
	var screen_rows: Array = []; var replay_rows: Array = []
	for e: BattleEvent in screen.get("events", []): screen_rows.append(e.to_dict())
	for e: BattleEvent in replayed.get("events", []): replay_rows.append(e.to_dict())
	check("saved continuation preserves resolved events and RNG", replayed.accepted and screen_rows == replay_rows and replay.snapshot() == scene.session.snapshot())
	await replay.close()
	check("native Reflect accepted through generic event adapter", screen.accepted)
	await _drain("reflect")
	var pivot: Dictionary = await scene.choose("move 4")
	check("native U-turn creates an actual replacement request", pivot.accepted and scene.session.phase() == "player_switch")
	await _drain("pivot")
	check("moves disabled during a forced replacement", scene._move_buttons[0].disabled and not scene._switch_button.disabled)
	check("mid-turn pivot can be saved", scene.save_battle(DEST + "pivot.json"))
	var pivot_before: Dictionary = scene.session.snapshot()
	check("mid-turn request survives restore", await scene.load_battle(DEST + "pivot.json") and scene.session.snapshot() == pivot_before and scene.session.phase() == "player_switch")
	var switched: Dictionary = await scene.choose("switch 2")
	check("pivot continuation returns to ordinary requests", switched.accepted and scene.session.phase() == "move" and scene.session.battle_state().active_for_side(&"side_a").instance_id == &"player_2")
	await _drain("switch")
	var healing: Dictionary = await scene.choose("move 3")
	check("native Life Dew reuses the existing HP timeline", healing.accepted)
	await _drain("healing")
	var turns := 0
	while scene.session.phase() != "finished" and turns < 30:
		if scene._playback.is_playing(): await _drain("automatic_switch_%d" % turns); continue
		if scene._working or scene._auto_pending:
			await process_frame; continue
		var phase: String = scene.session.phase()
		var choice := "move 1"
		if phase == "player_switch":
			choice = String(scene._selector.get_item_metadata(0)) if scene._selector.item_count > 0 else ""
		elif phase == "opponent_switch": choice = ""
		var played: Dictionary = await scene.choose(choice)
		check("complete battle command accepted %d" % turns, played.get("accepted", false))
		if not played.get("accepted", false): printerr(scene.session.last_error); break
		await _drain("battle_%d" % turns)
		turns += 1
	check("native battle reaches a terminal result", scene.session.phase() == "finished")
	check("terminal UI disables attacks", scene._move_buttons[0].disabled)
	check("curated battle reaches a player victory", scene.session.battle_state().winner_id == &"side_a")
	check("native Protect and Reflect use reviewed existing clips", "protect/back" in clip_keys and "reflect/back" in clip_keys)
	check("terminal native state can be saved", scene.save_battle(DEST + "finished.json"))
	await _capture("finished")
	await _unsupported_turn()
	await _regional_round_trip()
	var malformed := Backend.new(scene.catalogs)
	check("legacy save is not migrated implicitly", not await malformed.restore_saved(self, {"schema_version": 2, "turn": 3}))
	var wrong_policy: Dictionary = scene.session.snapshot(); wrong_policy.policy_sha256 = "other_rules"
	check("saved rules profile mismatch is rejected before starting worker", not await malformed.restore_saved(self, wrong_policy) and malformed._client == null)
	var broken: Dictionary = scene.session.snapshot(); broken.origin = {"p1": [{"instance_id": "bad"}], "p2": []}
	check("malformed origin is rejected before starting worker", not await malformed.restore_saved(self, broken) and malformed._client == null)
	var pid: int = scene.session._client.pid
	await scene.session.close()
	check("session closes its owned native worker", not OS.is_process_running(pid))
	scene.queue_free(); await process_frame
	_finish()


func _unsupported_turn() -> void:
	var catalog: DefinitionCatalog = scene.catalogs
	var rng := RandomNumberGenerator.new(); rng.seed = 12
	var rules := ProgressionRuleset.new()
	var actor := CreatureFactory.create(catalog.species(&"mew"), 50, catalog, rules, rng, {"instance_id": &"a", "moves": [&"transform", &"tackle"]})
	var target := CreatureFactory.create(catalog.species(&"snorlax"), 50, catalog, rules, rng, {"instance_id": &"b", "moves": [&"tackle"]})
	var backend := Backend.new(catalog)
	check("unsupported-transition fixture starts", await backend.open(self, [actor] as Array[CreatureInstance], [target] as Array[CreatureInstance]))
	var original := actor.to_dict().duplicate(true)
	var before: Dictionary = backend.snapshot()
	var failed: Dictionary = await backend.submit("move 2 terastallize", backend.revision)
	check("unsupported tera protocol rejects the prepared turn", not failed.accepted and backend.snapshot() == before)
	var following: Dictionary = await backend.submit("move 2", backend.revision)
	check("rejected draft does not poison the next command", following.accepted)
	check("native combat does not mutate source campaign creature", actor.to_dict() == original)
	var confirmed: Dictionary = backend.snapshot()
	OS.kill(backend._client.pid); await create_timer(0.03).timeout
	var interrupted: Dictionary = await backend.submit("move 2", backend.revision)
	check("worker loss preserves last confirmed native snapshot", not interrupted.accepted and backend.needs_recovery and backend.snapshot() == confirmed)
	var recovered := Backend.new(catalog)
	check("interrupted battle can resume from confirmed native state", await recovered.restore_saved(self, confirmed) and recovered.snapshot() == confirmed)
	await recovered.close()
	await backend.close()
	actor.moveset.clear(); actor.move_ids.clear(); actor.add_move(&"splash", catalog)
	var denied := Backend.new(catalog)
	check("existing randomlock move exclusions remain enforced", not await denied.open(self, [actor] as Array[CreatureInstance], [target] as Array[CreatureInstance]))
	check("policy rejection starts no process", denied._client == null)


func _regional_round_trip() -> void:
	var catalog := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional catalog loads existing reviewed resources", preload("res://modules/creatures/progression/pokemon_variant_catalog.gd").apply(catalog))
	var rng := RandomNumberGenerator.new(); rng.seed = 99
	var rules := ProgressionRuleset.new()
	var a := CreatureFactory.create(catalog.species(&"vulpix_alola"), 50, catalog, rules, rng, {"instance_id": &"regional_a", "is_shiny": true, "moves": [&"ice_beam", &"protect"]})
	var b := CreatureFactory.create(catalog.species(&"darmanitan_galar_standard"), 50, catalog, rules, rng, {"instance_id": &"regional_b", "moves": [&"tackle"]})
	var backend := Backend.new(catalog)
	check("regional source IDs import via explicit native aliases", await backend.open(self, [a] as Array[CreatureInstance], [b] as Array[CreatureInstance]))
	if backend.battle_state() != null:
		check("shiny appearance survives native projection", backend.battle_state().active_for_side(&"side_a").appearance_id() == a.appearance_id() and a.is_shiny)
		var saved: Dictionary = backend.snapshot()
		var restored := Backend.new(catalog)
		check("regional/shiny native save round trip", await restored.restore_saved(self, saved) and restored.snapshot() == saved)
		await restored.close()
	await backend.close()


func _drain(label: String) -> void:
	var snapshot: Dictionary = scene.session.snapshot()
	var frames := 0
	while scene._playback.is_playing() and frames < 1200:
		var step: Dictionary = scene._playback._sequence[scene._playback._index]
		var key := String(step.get("catalog_clip", step.get("community_clip", "")))
		if not key.is_empty() and key not in clip_keys: clip_keys.append(key)
		if gpu and not key.is_empty() and not captures.any(func(c): return c.label == label):
			scene._playback.advance(minf(0.2, float(step.duration) * 0.4))
			await _capture(label)
		scene._playback.advance(0.15); frames += 1
	check("playback completes " + label, not scene._playback.is_playing())
	check("playback preserves native snapshot/RNG " + label, scene.session.snapshot() == snapshot)
	var state: BattleState = scene.session.battle_state()
	check("HUD reconciles both native HP " + label, int(scene._player_hp.value) == state.active_for_side(&"side_a").current_hp and int(scene._enemy_hp.value) == state.active_for_side(&"side_b").current_hp)
	await process_frame


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var path := DEST + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"label": label, "path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})


func _finish() -> void:
	done = true
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "gpu": gpu, "captures": captures, "clip_keys": clip_keys}
	FileAccess.open(DEST + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("SHOWDOWN_BACKEND ", report.status, " checks=", checks, " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)
