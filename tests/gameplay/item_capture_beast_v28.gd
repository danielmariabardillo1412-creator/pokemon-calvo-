extends "res://tests/gameplay/item_capture_v11.gd"

# Bloque 3 V28: Ente Ball, Gen VII+ ball modifier dentro de calvo_capture_v1.
# Solo son pruebas adicionales; los tests históricos siguen intactos.
const OUT_BEAST := "res://.godot/item_capture_beast_v28/"
const WILD_BEASTS: Array[StringName] = [
	&"nihilego", &"buzzwole", &"pheromosa", &"xurkitree",
	&"celesteela", &"kartana", &"guzzlord", &"poipole",
	&"naganadel", &"stakataka", &"blacephalon",
]
var routes_beast: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_beast")
	create_timer(300.0).timeout.connect(func():
		if not done:
			push_error("ITEM_CAPTURE_BEAST_V28 timeout")
			quit(2))

func _run_beast() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_BEAST)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("beast regional variant overlay", Variants.apply(catalogs))
	var selection := service_for()
	check("beast catalog exists and content allowed",
		catalogs.item(&"beast_ball") != null and selection.selection.content_allowed(&"beast_ball"))
	check("beast registered exactly once",
		CaptureRuleset.new().is_known_ball(&"beast_ball")
		and CaptureRuleset.ordered_ball_ids().count(&"beast_ball") == 1)
	_boundaries_beast()
	_matrix_beast()
	_rejections_beast()
	await _native_beast()
	await _field_beast()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL",
		"checks": checks, "errors": errors, "cases": cases,
		"successes": successes, "failures": failures,
		"routes": routes_beast, "profile": "Gen VII+ Beast Ball inside calvo_capture_v1",
		"limits": ["No complete Gen IX shake/RNG formula",
			"Base species classification; in-battle Transform not certified",
			"No automatic Beast Ball gifts or economy",
			"GPU/manual visual inspection not exercised"]}
	var file := FileAccess.open(OUT_BEAST + "godot.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	done = true
	print("ITEM_CAPTURE_BEAST_V28 ", report.status, " checks=", checks,
		" cases=", cases, " errors=", errors.size())
	quit(0 if errors.is_empty() and checks > 300 and cases > 200 else 1)

# La tabla de expectativas es independiente de BallEffects. Las once especies
# son los ultraentes reconocidos; no contar sus legendarios relacionados.
func _is_beast(sid: StringName) -> bool:
	return WILD_BEASTS.has(sid)

func _expected_beast_probability(c: CreatureInstance) -> float:
	var sp: CreatureSpecies = catalogs.species(c.base_species_id())
	var factor := 5.0 if _is_beast(c.base_species_id()) else 410.0 / 4096.0
	var status_multiplier := 2.0 if c.status_state.persistent_id == &"sleep" else 1.0
	var hp_factor := float(3 * c.stats.max_hp - 2 * c.current_hp) / float(3 * c.stats.max_hp)
	return minf(1.0, float(sp.capture_rate) / 255.0 * factor * status_multiplier * hp_factor)

func _boundaries_beast() -> void:
	for sid: StringName in WILD_BEASTS:
		var sp: CreatureSpecies = catalogs.species(sid)
		check("ultra beast exists " + String(sid), sp != null)
		if sp == null: continue
		var c := _mon(sid, 10, StringName("beast_" + String(sid)))
		check("ultra beast x5 multiplier " + String(sid),
			is_equal_approx(BallEffects.multiplier(&"beast_ball", c, sp), 5.0))
	for sid: StringName in [&"mew", &"caterpie", &"solgaleo", &"lunala", &"necrozma"]:
		var sp: CreatureSpecies = catalogs.species(sid)
		check("non ultra exists " + String(sid), sp != null)
		if sp == null: continue
		var c := _mon(sid, 10, StringName("not_beast_" + String(sid)))
		check("non ultra uses 410/4096 " + String(sid),
			is_equal_approx(BallEffects.multiplier(&"beast_ball", c, sp), 410.0 / 4096.0))
	check("beast does not alter ordinary Poke Ball multiplier",
		BallEffects.multiplier(&"poke_ball", _mon(), catalogs.species(&"mew")) == 1.0)

func _matrix_beast() -> void:
	var seen: Dictionary = {}
	var index := 0
	for sid: String in catalogs.variant_allowed_species:
		index += 1
		for asleep in [false, true]:
			for full_hp in [false, true]:
				var c := _prepared(StringName(sid), (index % 100) + 1, asleep)
				if full_hp: c.current_hp = c.stats.max_hp
				var original := c.to_dict()
				var chance := _expected_beast_probability(c)
				var rng := RandomNumberGenerator.new()
				rng.seed = 2803 + index * 7 + int(asleep) * 3 + int(full_hp)
				var control := RandomNumberGenerator.new()
				control.state = rng.state
				var succeeds := control.randf() < chance
				var bag := PlayerInventory.new()
				bag.add(&"beast_ball", 2)
				var party := CreatureParty.new()
				var result := CaptureInventoryService.resolve(
					CaptureAttempt.new(c, &"beast_ball", CaptureBattleContext.new()), rng,
					catalogs, party, bag)
				check("beast probability and seeded outcome " + sid,
					is_equal_approx(result.result.probability, chance)
					and (result.result.status == CaptureResult.SUCCESS) == succeeds)
				check("beast one item and one roll " + sid,
					result.result.consume_item and bag.quantity(&"beast_ball") == 1
					and rng.state == control.state and party.size() == (1 if succeeds else 0))
				check("beast no hidden creature mutation " + sid,
					c.to_dict() == original and (not succeeds or is_same(result.captured, c)))
				if _is_beast(c.base_species_id()): seen[String(c.base_species_id())] = true
				cases += 1
				if succeeds: successes += 1
				else: failures += 1
	check("beast 11 species present in eligible sweep", seen.size() == 11)
	check("beast matrix positive and negative outcomes",
		cases > 200 and successes > 0 and failures > 0)

func _rejections_beast() -> void:
	for mode in 9:
		var c := _prepared(&"buzzwole", 8, false)
		var ctx := CaptureBattleContext.new()
		var bag := PlayerInventory.new()
		bag.add(&"beast_ball", 2)
		var party := CreatureParty.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 3102
		match mode:
			0: ctx.is_wild = false
			1: ctx.battle_finished = true
			2: ctx.target_owner_trainer_id = &"trainer"
			3: c.current_hp = 0
			4: bag.remove(&"beast_ball", 2)
			5: bag.corrupted = true
			6: c.level = 0
			7: c.current_hp = c.stats.max_hp + 1
			8: ctx = null
		var before := c.to_dict()
		var stock := bag.to_dict()
		var state := rng.state
		var result := CaptureInventoryService.resolve(
			CaptureAttempt.new(c, &"beast_ball", ctx), rng, catalogs, party, bag)
		check("beast invalid does not mutate or spend " + str(mode),
			result.result.status == CaptureResult.INVALID
			and not result.result.consume_item and rng.state == state
			and bag.to_dict() == stock and c.to_dict() == before and party.is_empty())

func _native_beast() -> void:
	var owner := PlayerCollection.new()
	var ally := _mon(&"mew", 100, &"beast_native_owner")
	ally.moveset.clear()
	ally.move_ids.clear()
	ally.add_move(&"spore", catalogs)
	check("beast native original owner", owner.party.add_creature(ally))
	owner.inventory.add(&"beast_ball", 2)
	var wild := _prepared(&"buzzwole", 1, false)
	wild.current_hp = 1
	var wild_id := wild.instance_id
	var clocks := {}
	var session := FieldNative.new(catalogs, owner, clocks, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, wild, [23, 19, 29, 43])
	check("beast native wild battle starts", opened)
	if not opened:
		await session.close()
		return
	var snap := session.snapshot()
	check("beast native stale revision rejected", not (await session.capture(&"beast_ball", session.revision + 1)).accepted and session.snapshot() == snap)
	check("beast native Spore applies sleep",
		(await session.submit("move 1", session.revision)).accepted
		and session.battle_state().creature(wild_id).status_state.persistent_id == &"sleep")
	var saved := session.snapshot()
	await session.close()
	session = FieldNative.new(catalogs, owner, clocks, "gen9calvounifiedv1")
	var restored := await session.restore_saved(self, saved)
	check("beast native checkpoint restored", restored)
	if not restored:
		await session.close()
		return
	var result: Dictionary = await session.capture(&"beast_ball", session.revision)
	var caught := owner.owned_creature(wild_id)
	check("beast native owner gains caught beast", result.accepted
		and session.completion_reason == "CAPTURED" and caught != null)
	check("beast native physical ball consumed once", owner.inventory.quantity(&"beast_ball") == 1)
	if caught != null:
		check("beast native identity and species persist", caught.instance_id == wild_id
			and caught.base_species_id() == &"buzzwole")
		check("beast native existing save schema round-trip",
			CreatureInstance.from_dict(caught.to_dict()).to_dict() == caught.to_dict())
	var after := owner.inventory.to_dict()
	check("beast native duplicate capture rejected",
		not (await session.capture(&"beast_ball", session.revision)).accepted
		and owner.inventory.to_dict() == after)
	routes_beast.append({"route": "native_capture_success", "ball": "beast_ball", "species": "buzzwole"})
	await session.close()

func _field_beast() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100
	config.wild_species_id = "buzzwole"
	config.wild_min_level = 5
	config.wild_max_level = 5
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var own_id: StringName = owner.party.get_creatures()[0].instance_id
	var ally := _mon(&"mew", 100, own_id)
	ally.moveset.clear()
	ally.move_ids.clear()
	ally.add_move(&"false_swipe", catalogs)
	ally.add_move(&"spore", catalogs)
	check("beast map owner replaced", owner.replace_owned_same_identity(ally))
	owner.inventory.add(&"beast_ball", 8)
	var bridge = scene._native_battles
	bridge.save_path = OUT_BEAST + "map_beast_ball_save.json"
	check("beast map bag saved", bridge.save_game())
	check("beast map bag restored", await bridge.load_game())
	var before := scene.field_collection().inventory.quantity(&"beast_ball")
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view
	view._playback.set_process(false)
	var ready := view.session != null and view.session.battle_state() != null
	check("beast map native encounter opened", ready)
	if not ready:
		scene.queue_free()
		await process_frame
		return
	var wild_id := view.session.battle_state().active_for_side(&"side_b").instance_id
	check("beast map False Swipe HP floor",
		(await view.choose("move 1")).accepted
		and view.session.battle_state().creature(wild_id).current_hp == 1)
	await _drain(view)
	check("beast map Spore sleeps living foe",
		(await view.choose("move 2")).accepted
		and view.session.battle_state().creature(wild_id).status_state.persistent_id == &"sleep")
	await _drain(view)
	check("beast map capture checkpoint save", bridge.save_game())
	var restored := await bridge.load_game()
	check("beast map capture checkpoint restore", restored)
	if not restored:
		if view.session != null: await view.session.close()
		scene.queue_free()
		await process_frame
		return
	view._playback.set_process(false)
	var selected := false
	for i in view._capture_balls.item_count:
		if view._capture_balls.get_item_metadata(i) == "beast_ball":
			view._capture_balls.select(i)
			selected = true
	view._refresh_view()
	check("beast map selector exposes owned Beast Ball",
		selected and view._capture_balls.selected_ball() == &"beast_ball" and not view._ball.disabled)
	var result: Dictionary = await view.adventure_command("ball")
	check("beast map ball caught native ultra beast", result.accepted
		and view.session.completion_reason == "CAPTURED"
		and result.get("capture_outcome", {}).get("capture", {}).get("result", {}).get("ball_id") == "beast_ball")
	await _drain(view)
	await bridge.leave_battle()
	owner = scene.field_collection()
	var caught := owner.owned_creature(wild_id)
	check("beast map physical cost and captured owner",
		owner.inventory.quantity(&"beast_ball") == before - 1
		and caught != null and caught.base_species_id() == &"buzzwole")
	check("beast map final save", bridge.save_game())
	check("beast map final restore", await bridge.load_game())
	check("beast map persisted species, bag and owner",
		scene.field_collection().inventory.quantity(&"beast_ball") == before - 1
		and scene.field_collection().owned_creature(wild_id) != null
		and scene.field_collection().owned_creature(wild_id).base_species_id() == &"buzzwole")
	routes_beast.append({"route": "map_picker_save_load", "ball": "beast_ball", "species": "buzzwole"})
	if view.session != null: await view.session.close()
	scene.queue_free()
	await process_frame
