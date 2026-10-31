extends "res://tests/gameplay/field_held_v16.gd"

# Real bag -> native battle -> save/load -> capture -> field ownership.
# Reuse the prior ownership contract; never derive game mechanics in the UI.
const V23 := "res://.godot/encounter_held_v23/"
const ENCOUNTER_IDS: Array[StringName] = [&"cleanse_tag", &"pure_incense"]
const Modifiers = preload("res://modules/gameplay/encounter_item_modifiers.gd")


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(600).timeout.connect(func():
		if not done: push_error("ENCOUNTER_HELD_V23 timeout"); quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V23)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	if not capture:
		for id: StringName in ENCOUNTER_IDS:
			for route: String in ["keep", "fling", "trick", "knock_off"]:
				await _medicine_case(id, route, false)
	for id: StringName in ENCOUNTER_IDS:
		for route: String in (["keep"] if capture else ["keep", "fling", "trick"]):
			await _map_encounter_item(id, route)
	var report := {"status":"PASS" if errors.is_empty() else "FAIL", "checks":checks, "errors":errors, "routes":routes, "gpu":capture}
	var file := FileAccess.open(V23 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true
	print("ENCOUNTER_HELD_V23 ", report.status, " checks=", checks, " GPU=", capture)
	quit(0 if errors.is_empty() else 1)


func _map_encounter_item(id: StringName, route: String) -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100
	config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var own_id: StringName = owner.party.get_creatures()[0].instance_id
	var creature := _with_moves(own_id, ["growl", "fling", "trick"], false)
	creature.friendship = 100
	check("map owner setup " + String(id), owner.replace_owned_same_identity(creature))
	owner.inventory.add(id, 3); owner.inventory.add(&"master_ball", 2)
	var initial := _physical_medicine(owner, id)
	check("real bag opens " + String(id), scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	_select(bag, String(id))
	check("equip preserves physical units " + String(id), bag._apply("equip").accepted and _physical_medicine(owner, id) == initial)
	var before := snapshot(bag.service)
	check("rate effect is not direct bag use", not bag._apply("use").accepted and snapshot(bag.service) == before)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("equipped bag screenshot " + String(id), root.get_texture().get_image().save_png(V23 + String(id) + "_bag.png") == OK)
		check("bag fits viewport", bag.position.y >= 0 and bag.position.y + bag.size.y <= root.size.y)
	bag.hide(); await process_frame
	var bridge = scene._native_battles
	bridge.save_path = V23 + ("gpu_" if capture else "headless_") + String(id) + "_" + route + ".json"
	check("equipped field save/load " + String(id), bridge.save_game() and await bridge.load_game())
	owner = scene.field_collection()
	check("equipped field load keeps descriptor ID", owner.owned_creature(own_id).held_item_id == id)
	var position := Vector2(420, 150)
	var zone: StringName = scene.zone_at_position(position)
	var table: WildEncounterTable = scene._director._tables.get(zone)
	var authored := table.to_dict()
	var modified := Modifiers.prepare_table(table, owner.party.get_creatures())
	check("real equipped leader still reduces the table", modified.encounter_chance_bp == 6667 and table.to_dict() == authored)
	# Choose a real encounter seed via the existing resolver without mutating
	# the director or its metrics during fixture selection.
	var hit_seed := 0
	var miss_seed := 0
	for seed in range(1, 65):
		var probe := RandomNumberGenerator.new(); probe.seed = seed
		var result := WildEncounterSystem.resolve(modified, probe, scene._catalogs, scene._session.progression_ruleset)
		if result.status == WildEncounterResult.ENCOUNTER and hit_seed == 0: hit_seed = seed
		if result.status == WildEncounterResult.NONE and miss_seed == 0: miss_seed = seed
		if hit_seed != 0 and miss_seed != 0: break
	check("deterministic hit and miss fixtures exist", hit_seed != 0 and miss_seed != 0)
	if hit_seed == 0 or miss_seed == 0: scene.queue_free(); await process_frame; return
	scene.player.global_position = position
	scene._director._encounter_rng.seed = miss_seed
	await scene._on_player_step_completed(position)
	check("reduced-rate miss stays on map", not bridge.occupied())
	scene._director._encounter_rng.seed = hit_seed
	await scene._on_player_step_completed(position)
	var view = bridge.view
	var ready: bool = view != null and view.session != null and view.session.battle_state() != null
	check("actual map enters native with " + String(id) + " " + bridge.last_error, ready)
	if not ready: scene.queue_free(); await process_frame; return
	view._playback.set_process(false)
	check("native sees the held item", view.session.battle_state().creature(own_id).held_item_id == id)
	var choice: String = {"keep":"move 1", "fling":"move 2", "trick":"move 3"}[route]
	var result: Dictionary = await view.choose(choice)
	check("real battle action " + String(id) + " " + route, result.accepted)
	if not result.accepted: await view.session.close(); scene.queue_free(); await process_frame; return
	await _drain_view(view)
	check("post-action native save", bridge.save_game())
	check("post-action native load " + bridge.last_error, await bridge.load_game())
	view = bridge.view; view._playback.set_process(false)
	check("capture settles the exact native item ownership", (await view.adventure_command("master")).accepted)
	await _drain_view(view); await bridge.leave_battle()
	owner = scene.field_collection()
	var expected := initial - (1 if route == "fling" else 0)
	check("no duplicate or resurrected physical unit", _physical_medicine(owner, id) == expected)
	check("field leader uses current settled ownership", Modifiers.leader_item(owner.party.get_creatures()) == (id if route == "keep" else &""))
	check("authored encounter table never changed", table.to_dict() == authored)
	check("settled field save/load", bridge.save_game() and await bridge.load_game())
	check("physical unit count survives field reload", _physical_medicine(scene.field_collection(), id) == expected)
	routes.append({"item_id":String(id), "route":"map_" + route, "native_handoff":true, "physical_units":expected})
	if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame
