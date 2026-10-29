extends "res://tests/gameplay/item_field_effects_v4.gd"

const Variants = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Native = preload("res://modules/gameplay/showdown_adventure_session.gd")
const FieldNative = preload("res://modules/gameplay/field_native_session.gd")
const BallEffects = preload("res://modules/capture/capture_ball_effects.gd")
const V11 := "res://.godot/item_capture_v11/"
const BALLS: Array[StringName] = [&"nest_ball", &"fast_ball", &"dream_ball", &"heal_ball", &"premier_ball"]
var cases := 0
var successes := 0
var failures := 0
var native_rows: Array = []

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done: push_error("CAPTURE_V11 timeout"); quit(2))

func _mon(sid: StringName = &"mew", level := 50, id: StringName = &"ball_target") -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 601
	var c := CreatureFactory.create(catalogs.species(sid), level, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": id, "nature_id": "hardy", "moves": ["growl"], "ability_id": ""})
	return c

func _prepared(sid: StringName, level: int, asleep: bool) -> CreatureInstance:
	var c := _mon(sid, level)
	c.current_hp = maxi(1, int(c.stats.max_hp / 2.0)); c.friendship = 117; c.is_shiny = true
	c.moveset[0].current_pp = 3; c.moveset[0].max_pp = 64
	if asleep: status(c, &"sleep")
	return c

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V11)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	var selection := service_for()
	for ball: StringName in BALLS:
		check("catalog and policy allow ball", catalogs.item(ball) != null and selection.selection.content_allowed(ball))
	_matrix()
	_boundaries()
	await _native()
	await _native_failure()
	await _real_field()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"cases": cases, "successes": successes, "failures": failures, "native_rows": native_rows, "gpu": capture}
	var file := FileAccess.open(V11 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true
	print("ITEM_CAPTURE_V11 ", report.status, " checks=", checks, " cases=", cases, " GPU=", capture)
	quit(0 if errors.is_empty() else 1)

# Independent expected multiplier table, plus the existing calvo_capture_v1
# probability contract. This phase does not claim to replace it with Gen IX.
func _expected(ball: StringName, c: CreatureInstance) -> float:
	var sp := catalogs.species(c.base_species_id())
	var rate := float(sp.capture_rate)
	var multiplier := 1.0
	if ball == &"nest_ball" and c.level < 31: multiplier = (41.0 - c.level) / 10.0
	if ball == &"fast_ball" and sp.base_speed >= 100: rate = minf(rate * 4.0, 255.0)
	if ball == &"dream_ball" and c.status_state.persistent_id == &"sleep": multiplier = 4.0
	var bonus := 2.0 if c.status_state.persistent_id == &"sleep" else 1.0
	var hp := float(3 * c.stats.max_hp - 2 * c.current_hp) / (3 * c.stats.max_hp)
	return minf(1.0, (rate / 255.0) * multiplier * bonus * hp)

func _matrix() -> void:
	var index := 0
	for sid: String in catalogs.variant_allowed_species:
		index += 1
		for ball: StringName in BALLS:
			for asleep in [false, true]:
				var c := _prepared(StringName(sid), (index % 100) + 1, asleep)
				var expected_p := _expected(ball, c); var before := c.to_dict()
				var rng := RandomNumberGenerator.new(); rng.seed = index + 700
				var control := RandomNumberGenerator.new(); control.state = rng.state
				var caught := control.randf() < expected_p
				var bag := PlayerInventory.new(); bag.add(ball, 3)
				var party := CreatureParty.new()
				var resolution := CaptureInventoryService.resolve(CaptureAttempt.new(c, ball, CaptureBattleContext.new()), rng, catalogs, party, bag)
				var result := resolution.result
				check("probability " + sid + String(ball), is_equal_approx(result.probability, expected_p) and (result.status == CaptureResult.SUCCESS) == caught)
				check("one throw one RNG one ball", rng.state == control.state and bag.quantity(ball) == 2 and result.consume_item and party.size() == (1 if caught else 0))
				var expected := before.duplicate(true)
				if caught and ball == &"heal_ball":
					expected.current_hp = c.stats.max_hp
					expected.status_ids = []; expected.status_state = BattleStatusState.new().to_dict()
					for slot: Dictionary in expected.moveset: slot.current_pp = slot.max_pp
				check("only catch effect changes creature", c.to_dict() == expected and (not caught or is_same(resolution.captured, c)))
				if caught: successes += 1
				else: failures += 1
				cases += 1
	check("all eligible species and five balls", index == 1076 and cases == 10760)
	for level in [1, 30, 31, 40, 100]:
		var c := _mon(&"mew", level)
		var expected := {1: 4.0, 30: 1.1, 31: 1.0, 40: 1.0, 100: 1.0}
		check("Nest level boundary " + str(level), is_equal_approx(BallEffects.multiplier(&"nest_ball", c, catalogs.species(c.species_id)), expected[level]))
	for pair: Array in [["pikachu", 1.0], ["mew", 4.0], ["raichu", 3.4]]:
		var c := _mon(StringName(pair[0]))
		check("Fast uses base speed and caps modified rate at 255", is_equal_approx(BallEffects.multiplier(&"fast_ball", c, catalogs.species(c.species_id)), pair[1]))
	var c := _mon(); c.status_state.add_volatile(&"yawn")
	check("drowsiness is not sleep", BallEffects.multiplier(&"dream_ball", c, catalogs.species(c.species_id)) == 1.0)

func _boundaries() -> void:
	for ball: StringName in BALLS:
		for mode in 8:
			var c := _prepared(&"mew", 50, true)
			var ctx := CaptureBattleContext.new()
			var bag := PlayerInventory.new(); bag.add(ball, 2)
			var party := CreatureParty.new(); var rng := RandomNumberGenerator.new(); rng.seed = 187
			match mode:
				0: ctx.is_wild = false
				1: ctx.battle_finished = true
				2: ctx.target_owner_trainer_id = &"trainer"
				3: c.current_hp = 0
				4: bag.remove(ball, 2)
				5: bag.corrupted = true
				6: c.level = 0
				7: c.current_hp = c.stats.max_hp + 1
			var before := c.to_dict(); var inventory := bag.to_dict(); var state := rng.state
			var result := CaptureInventoryService.resolve(CaptureAttempt.new(c, ball, ctx), rng, catalogs, party, bag)
			check("invalid attempt no changes " + String(ball) + str(mode), result.result.status == CaptureResult.INVALID and not result.result.consume_item and c.to_dict() == before and rng.state == state and bag.to_dict() == inventory and party.is_empty())
	# Heal must work for full parties routed to storage, and restore spent boosted
	# PP rather than reset their maxima. Force success through an ordinary RNG draw.
	var c := _prepared(&"caterpie", 5, true); var party := CreatureParty.new()
	for i in 6: party.add_creature(_mon(&"mew", 50, StringName("own_" + str(i))))
	var bag := PlayerInventory.new(); bag.add(&"heal_ball")
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var result := CaptureInventoryService.resolve(CaptureAttempt.new(c, &"heal_ball", CaptureBattleContext.new()), rng, catalogs, party, bag)
	check("Heal successful storage route", result.result.status == CaptureResult.SUCCESS and result.disposition == CaptureDisposition.STORAGE_REQUIRED)
	var storage := CreatureStorage.new(); var routed := CaptureOwnershipRouter.new().route(result, party, storage)
	check("Heal applied before storage", routed.stored and storage.get_creature(c.instance_id).current_hp == c.stats.max_hp and c.status_state.persistent_id == &"" and c.moveset[0].current_pp == 64 and c.moveset[0].max_pp == 64)
	for unsupported: StringName in [&"quick_ball", &"timer_ball", &"net_ball", &"luxury_ball", &"banana_ball"]:
		check("unsupported remains deferred " + String(unsupported), not CaptureRuleset.new().is_known_ball(unsupported))

func _native() -> void:
	for ball: StringName in BALLS:
		var owner := PlayerCollection.new(); owner.party.add_creature(_mon(&"mew", 50, &"native_own")); owner.inventory.add(ball, 2)
		var own := owner.party.get_creatures()[0]
		own.moveset.clear(); own.move_ids.clear(); own.add_move(&"spore", catalogs)
		var wild := _prepared(&"caterpie", 5, false)
		wild.current_hp = 1
		var clocks := {}
		var session := FieldNative.new(catalogs, owner, clocks, "gen9calvounifiedv1")
		var opened: bool = await session.begin_wild(self, wild, [23, 19, 29, 43])
		check("native begins " + String(ball) + ": " + session.last_error, opened)
		if opened:
			check("native establishes real sleep clock", (await session.submit("move 1", session.revision)).accepted and session.battle_state().creature(wild.instance_id).status_state.persistent_id == &"sleep")
			var saved := session.snapshot(); await session.close()
			session = FieldNative.new(catalogs, owner, clocks, "gen9calvounifiedv1")
			check("new ball inventory checkpoint restores", await session.restore_saved(self, saved))
			var result: Dictionary = await session.capture(ball, session.revision)
			check("native captures with selected ball", result.accepted and session.completion_reason == "CAPTURED" and owner.inventory.quantity(ball) == 1 and owner.party.size() == 2)
			var caught := owner.owned_creature(wild.instance_id)
			check("native captured identity and PP", caught != null and caught.instance_id == wild.instance_id and caught.is_shiny and caught.moveset[0].max_pp == 64 and caught.moveset[0].current_pp == (64 if ball == &"heal_ball" else 3))
			if caught != null: check("native Heal alone cures captured target", caught.current_hp == (caught.stats.max_hp if ball == &"heal_ball" else 1) and caught.status_state.persistent_id == (&"" if ball == &"heal_ball" else &"sleep"))
			check("published clocks follow final captured status", clocks.has(String(wild.instance_id)) == (ball != &"heal_ball"))
			native_rows.append({"ball": String(ball), "accepted": result.accepted, "completion": session.completion_reason})
		await session.close()

func _native_failure() -> void:
	for ball: StringName in [&"nest_ball", &"heal_ball"]:
		var owner := PlayerCollection.new(); owner.party.add_creature(_mon(&"mew", 100, &"failure_own"))
		owner.inventory.add(ball, 2); owner.inventory.add(&"master_ball")
		var wild := _mon(&"mew", 100, &"failure_wild")
		var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
		check("failure encounter begins", await session.begin_wild(self, wild, [23, 19, 29, 43], 1))
		var before := JSON.stringify([owner.party.to_dict(), owner.inventory.to_dict()])
		var original := session.snapshot()
		var rng := RandomNumberGenerator.new(); rng.state = int(original.adventure.capture_rng)
		var roll := rng.randf()
		check("failure draw chosen without changing production RNG", roll > _expected(ball, wild))
		var result: Dictionary = await session.capture(ball, session.revision)
		check("failed ball spends staged inventory and one turn", result.accepted and result.capture_result.status == "FAILED" and session.inventory.quantity(ball) == 1 and session.battle_state().turn == 1)
		check("failed ball leaves campaign unpublished", JSON.stringify([owner.party.to_dict(), owner.inventory.to_dict()]) == before)
		var saved := session.snapshot()
		check("failed ball records exact RNG and spending", saved.adventure.capture_rng == str(rng.state) and saved.adventure.spent_items[String(ball)] == 1)
		await session.close(); session = Native.new(catalogs, owner, "gen9calvounifiedv1")
		check("failed special ball checkpoint restores", await session.restore_saved(self, saved))
		check("restore preserves staged throw", session.inventory.quantity(ball) == 1 and session.snapshot().adventure.capture_rng == str(rng.state))
		check("settlement publishes both ball costs once", (await session.capture(&"master_ball", session.revision)).accepted and owner.inventory.quantity(ball) == 1 and owner.inventory.quantity(&"master_ball") == 0)
		native_rows.append({"ball": String(ball), "failed_attempt_restore_settlement": true})
		await session.close()

func _drain(view: Control) -> void:
	for i in 2000:
		if not view._playback.is_playing(): break
		view._playback.advance(0.25)
	await process_frame

func _real_field() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100; config.wild_species_id = "caterpie"; config.wild_min_level = 5; config.wild_max_level = 5
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	for ball: StringName in BALLS: owner.inventory.add(ball, 8)
	owner.inventory.add(&"master_ball", 2)
	scene.player.global_position = Vector2(420, 150); await scene._on_player_step_completed(scene.player.global_position)
	var bridge = scene._native_battles; var view = bridge.view
	view._playback.set_process(false)
	check("map encounter has ball selector", view.session != null and view.session.has_active_battle() and view._capture_balls.item_count == 8)
	for i in view._capture_balls.item_count:
		if view._capture_balls.get_item_metadata(i) == "heal_ball": view._capture_balls.select(i)
	view._refresh_view()
	check("UI selected real Heal ball", view._capture_balls.selected_ball() == &"heal_ball" and not view._ball.disabled and view._ball.text.contains("Sana"))
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("ball selector capture", root.get_texture().get_image().save_png(V11 + "ball_selector.png") == OK)
		check("capture controls fit", view._ball.get_global_rect().end.y <= root.size.y and view._capture_balls.get_global_rect().end.y <= root.size.y and view._ball.get_global_rect().end.x <= root.size.x and view._master.get_global_rect().end.x <= root.size.x)
	bridge.save_path = V11 + ("field_gpu.json" if capture else "field_headless.json")
	check("map ball save", bridge.save_game())
	check("map ball load", await bridge.load_game()); view._playback.set_process(false)
	for i in view._capture_balls.item_count:
		if view._capture_balls.get_item_metadata(i) == "heal_ball": view._capture_balls.select(i)
	view._refresh_view()
	var before: int = owner.inventory.quantity(&"heal_ball")
	var result: Dictionary = await view.adventure_command("ball")
	check("UI command uses selected ball", result.accepted and result.get("capture_outcome", {}).get("capture", {}).get("result", {}).get("ball_id") == "heal_ball")
	await _drain(view)
	if view.session.completion_reason == "":
		check("failed throw is staged", view.session.inventory.quantity(&"heal_ball") == before - 1 and scene.field_collection().inventory.quantity(&"heal_ball") == before)
		check("failed throw save", bridge.save_game())
		check("failed throw restore", await bridge.load_game()); view._playback.set_process(false)
		check("master finishes after restored special throw", (await view.adventure_command("master")).accepted)
		await _drain(view)
	await bridge.leave_battle()
	check("special ball cost settled exactly once", scene.field_collection().inventory.quantity(&"heal_ball") == before - 1)
	if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame
