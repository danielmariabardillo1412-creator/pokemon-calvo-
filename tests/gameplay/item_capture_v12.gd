extends "res://tests/gameplay/item_capture_v11.gd"

const ContextEffects = preload("res://modules/capture/capture_context_ball_effects.gd")
const V12 := "res://.godot/item_capture_v12/"
const NEW_BALLS: Array[StringName] = [&"quick_ball", &"timer_ball", &"level_ball"]
const CONTEXTS := [[0, 100, 1.0], [1, 100, 1.3], [9, 1, 3.7], [10, 50, 4.0], [11, 100, 4.0], [100, 25, 4.0]]

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done: push_error("CAPTURE_V12 timeout"); quit(2))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V12)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	_context_matrix()
	_invalid_contexts()
	_legacy_contexts()
	await _native_contexts()
	await _field_contexts()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"cases": cases, "successes": successes, "failures": failures, "native_rows": native_rows, "gpu": capture}
	var file := FileAccess.open(V12 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true
	print("ITEM_CAPTURE_V12 ", report.status, " checks=", checks, " cases=", cases, " GPU=", capture)
	quit(0 if errors.is_empty() else 1)

func _ctx(turns: int, catcher: int) -> CaptureBattleContext:
	var ctx := CaptureBattleContext.new(); ctx.completed_turns = turns; ctx.catcher_level = catcher
	return ctx

func _probability(c: CreatureInstance, factor: float, capped := false) -> float:
	var rate := float(catalogs.species(c.base_species_id()).capture_rate) * factor
	if capped: rate = minf(rate, 255.0)
	var hp := float(3 * c.stats.max_hp - 2 * c.current_hp) / (3 * c.stats.max_hp)
	return minf(1.0, (rate / 255.0) * hp)

func _level_factor(catcher: int, target: int) -> float:
	var ratio := float(catcher) / target
	return 8.0 if ratio >= 4.0 else 4.0 if ratio >= 2.0 else 2.0 if ratio > 1.0 else 1.0

func _context_matrix() -> void:
	var index := 0
	for sid: String in catalogs.variant_allowed_species:
		index += 1
		for ball: StringName in NEW_BALLS:
			for row: Array in CONTEXTS:
				var c := _prepared(StringName(sid), (index % 100) + 1, false)
				var ctx := _ctx(row[0], row[1]); var factor: float = row[2]
				if ball == &"quick_ball": factor = 5.0 if row[0] == 0 else 1.0
				if ball == &"level_ball": factor = _level_factor(row[1], c.level)
				var p := _probability(c, factor, ball == &"level_ball")
				var rng := RandomNumberGenerator.new(); rng.seed = index + 1201
				var control := RandomNumberGenerator.new(); control.state = rng.state
				var caught := control.randf() < p
				var bag := PlayerInventory.new(); bag.add(ball, 3)
				var party := CreatureParty.new(); var before := c.to_dict()
				var result := CaptureInventoryService.resolve(CaptureAttempt.new(c, ball, ctx), rng, catalogs, party, bag)
				check("context probability " + String(ball), is_equal_approx(result.result.probability, p) and (result.result.status == CaptureResult.SUCCESS) == caught)
				check("one draw and one unit", rng.state == control.state and bag.quantity(ball) == 2 and result.result.consume_item and party.size() == (1 if caught else 0))
				check("no creature fields changed", c.to_dict() == before and (not caught or is_same(result.captured, c)))
				cases += 1
				if caught: successes += 1
				else: failures += 1
	check("whole contextual matrix", cases == 19368 and index == 1076)
	var c := _mon(&"mew", 25)
	for row: Array in [[25, 1.0], [26, 2.0], [49, 2.0], [50, 4.0], [99, 4.0], [100, 8.0]]:
		var expected := minf(row[1], 255.0 / catalogs.species(c.species_id).capture_rate)
		check("Level boundary " + str(row[0]), is_equal_approx(ContextEffects.multiplier(&"level_ball", c, catalogs.species(c.species_id), _ctx(0, row[0])), expected))

func _invalid_contexts() -> void:
	var selection := service_for()
	for ball: StringName in NEW_BALLS:
		check("new ball is permitted and defined", selection.selection.content_allowed(ball) and catalogs.item(ball) != null)
		for mode in 7:
			var c := _mon(); var ctx := _ctx(0, 50)
			var bag := PlayerInventory.new(); bag.add(ball, 2)
			match mode:
				0: ctx = CaptureBattleContext.new()
				1: ctx.completed_turns = -2; ctx.catcher_level = 101
				2: ctx.is_wild = false
				3: ctx.battle_finished = true
				4: c.current_hp = 0
				5: bag.remove(ball, 2)
				6: bag.corrupted = true
			var rng := RandomNumberGenerator.new(); rng.seed = 171
			var state := rng.state; var before := c.to_dict(); var inventory := bag.to_dict()
			var party := CreatureParty.new()
			var result := CaptureInventoryService.resolve(CaptureAttempt.new(c, ball, ctx), rng, catalogs, party, bag)
			check("invalid context no consumption " + String(ball) + str(mode), result.result.status == CaptureResult.INVALID and not result.result.consume_item and rng.state == state and bag.to_dict() == inventory and party.is_empty() and c.to_dict() == before)
	var c := _mon()
	check("Quick does not require catcher level", CaptureSystem.validate_attempt(CaptureAttempt.new(c, &"quick_ball", _ctx(0, -1)), catalogs) == "")
	check("Level does not invent or require a turn counter", CaptureSystem.validate_attempt(CaptureAttempt.new(c, &"level_ball", _ctx(-1, 50)), catalogs) == "")

func _fail_seed(p: float) -> int:
	for seed_value in range(1, 100):
		var rng := RandomNumberGenerator.new(); rng.seed = seed_value
		if rng.randf() > p + 0.01: return seed_value
	return 1

func _legacy_contexts() -> void:
	for ball: StringName in NEW_BALLS:
		var owner := PlayerCollection.new(); owner.party.add_creature(_mon(&"mew", 10, &"legacy_own")); owner.party.add_creature(_mon(&"mew", 100, &"reserve")); owner.inventory.add(ball, 3)
		var table := WildEncounterTable.new(&"context_route"); table.add_slot(WildEncounterSlot.new(&"slot", &"mew", 1, 25, 25))
		var encounter_rng := RandomNumberGenerator.new(); encounter_rng.seed = 172
		var session := WildAdventureSession.new(owner, catalogs, ProgressionRuleset.new())
		check("legacy encounter starts", session.begin_encounter(table, encounter_rng).status == WildEncounterResult.ENCOUNTER)
		var wild := session.current_wild()
		wild.moveset.clear(); wild.move_ids.clear(); wild.add_move(&"growl", catalogs)
		var p := _probability(wild, 5.0 if ball == &"quick_ball" else 1.0, ball == &"level_ball")
		var rng := RandomNumberGenerator.new(); rng.seed = _fail_seed(p)
		var reaction := BattleAction.new(1, wild.instance_id, &"growl", &"legacy_own", BattleAction.MOVE, &"side_b")
		var result := session.submit_player_command(WildBattleCommand.capture(1, &"side_a", ball), rng, reaction)
		check("legacy live context first attempt", result.accepted and result.capture_outcome != null and is_equal_approx(result.capture_outcome.resolution.result.probability, p) and session.battle_state().turn == 1)
		var next := session.capture_current(ball, rng)
		var after := _probability(wild, 1.3 if ball == &"timer_ball" else 1.0, ball == &"level_ball")
		check("legacy completed turn and active level context", is_equal_approx(next.resolution.result.probability, after))

func _capture_p(result: Dictionary) -> float:
	return float(result.get("capture_outcome", {}).get("capture", {}).get("result", {}).get("probability", -1.0))

func _native_contexts() -> void:
	for ball: StringName in NEW_BALLS:
		var owner := PlayerCollection.new(); owner.party.add_creature(_mon(&"mew", 10, &"context_own")); owner.party.add_creature(_mon(&"mew", 100, &"context_reserve"))
		owner.inventory.add(ball, 3); owner.inventory.add(&"master_ball")
		var wild := _mon(&"mew", 25, &"context_wild")
		var first := _probability(wild, 5.0 if ball == &"quick_ball" else 1.0, ball == &"level_ball")
		var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
		check("native contextual encounter begins", await session.begin_wild(self, wild, [23, 19, 29, 43], _fail_seed(first)))
		var original := session.snapshot()
		var rejected: Dictionary = await session.capture(ball, session.revision + 1)
		check("wrong revision consumes no context or RNG", not rejected.accepted and session.snapshot() == original)
		var result: Dictionary = await session.capture(ball, session.revision)
		check("native first-turn and active-level probability", result.accepted and is_equal_approx(_capture_p(result), first) and session.completion_reason == "" and session.battle_state().turn == 1)
		var saved := session.snapshot(); await session.close(); session = Native.new(catalogs, owner, "gen9calvounifiedv1")
		check("native restores context without extra save fields", await session.restore_saved(self, saved))
		var expected: float
		if ball == &"timer_ball":
			for i in 9: check("native harmless turn advances timer", (await session.submit("move 1", session.revision)).accepted)
			expected = _probability(wild, 4.0)
			check("native timer cap at ten completed turns", session.battle_state().turn == 10)
		elif ball == &"level_ball":
			check("native actual switch changes catcher", (await session.submit("switch 2", session.revision)).accepted and session.battle_state().active_for_side(&"side_a").level == 100)
			expected = _probability(wild, 8.0, true)
		else: expected = _probability(wild, 1.0)
		var before: int = session.battle_state().turn
		result = await session.capture(ball, session.revision)
		check("native reconstructed context after restore", result.accepted and is_equal_approx(_capture_p(result), expected))
		native_rows.append({"ball": String(ball), "first_probability": first, "after_restore_probability": _capture_p(result), "completed_turns_before_second_throw": before})
		if session.completion_reason == "": check("master closes contextual encounter", (await session.capture(&"master_ball", session.revision)).accepted)
		check("two contextual balls published once", owner.inventory.quantity(ball) == 1 and owner.party.size() == 3)
		await session.close()

func _field_contexts() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100; config.wild_species_id = "caterpie"; config.wild_min_level = 5; config.wild_max_level = 5
	scene._on_configuration_applied(config)
	for ball: StringName in NEW_BALLS: scene.field_collection().inventory.add(ball, 8)
	scene.player.global_position = Vector2(420, 150); await scene._on_player_step_completed(scene.player.global_position)
	var bridge = scene._native_battles; var view = bridge.view; view._playback.set_process(false)
	check("new balls appear in existing picker", view._capture_balls.item_count == CaptureRuleset.ordered_ball_ids().size() - 1)
	for i in view._capture_balls.item_count:
		if view._capture_balls.get_item_metadata(i) == "quick_ball": view._capture_balls.select(i)
	view._refresh_view()
	check("Quick selector name and usability", view._ball.text.contains("Veloz") and not view._ball.disabled)
	bridge.save_path = V12 + ("field_gpu.json" if capture else "field_headless.json")
	check("first-turn field checkpoint saves", bridge.save_game())
	check("first-turn field checkpoint restores", await bridge.load_game()); view._playback.set_process(false)
	for i in view._capture_balls.item_count:
		if view._capture_balls.get_item_metadata(i) == "quick_ball": view._capture_balls.select(i)
	view._refresh_view()
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("context ball UI capture", root.get_texture().get_image().save_png(V12 + "context_selector.png") == OK)
		check("context controls fit viewport", view._flee.get_global_rect().end.x <= root.size.x and view._ball.get_global_rect().end.y <= root.size.y)
	var result: Dictionary = await view.adventure_command("ball")
	check("restored first turn preserves Quick bonus", result.accepted and is_equal_approx(_capture_p(result), 1.0) and view.session.completion_reason == "CAPTURED")
	await _drain(view); await bridge.leave_battle()
	check("map consumes selected Quick exactly once", scene.field_collection().inventory.quantity(&"quick_ball") == 7)
	if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame
