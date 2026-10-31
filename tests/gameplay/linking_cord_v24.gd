extends "res://tests/gameplay/field_held_v16.gd"

const V24 := "res://.godot/linking_cord_v24/"
const Cord = preload("res://modules/inventory/linking_cord_effects.gd")
const ROUTES := {"haunter":"gengar", "kadabra":"alakazam", "machoke":"machamp", "graveler":"golem", "graveler_alola":"golem_alola", "boldore":"gigalith", "gurdurr":"conkeldurr", "phantump":"trevenant"}
var scanned := 0


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(480).timeout.connect(func():
		if not done: push_error("LINKING_CORD_V24 timeout"); quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V24)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	if not capture:
		_catalog_sweep()
		for source: String in ROUTES: _evolve_owned(StringName(source), StringName(ROUTES[source]))
		_rejections()
		for route: String in ["keep", "fling", "trick", "knock_off"]: await _medicine_case(&"linking_cord", route, false)
	for source: StringName in [&"haunter", &"graveler_alola"]: await _map_evolve(source)
	await _passive_hints()
	var report := {"status":"PASS" if errors.is_empty() else "FAIL", "checks":checks, "errors":errors, "catalog_species_scanned":scanned, "gpu":capture, "routes":routes}
	var file := FileAccess.open(V24 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true; print("LINKING_CORD_V24 ", report.status, " checks=", checks, " GPU=", capture)
	quit(0 if errors.is_empty() else 1)


func _catalog_sweep() -> void:
	var content = Service.new()
	var owner := _make(); content = _service(owner, &"linking_cord")
	for species_id: StringName in catalogs.species_catalog.all_ids():
		var species := catalogs.species(species_id)
		var c := _make(species.id)
		var before := c.to_dict()
		var options := Cord.targets(c, catalogs, content.content)
		var expected: Array[StringName] = []
		if ROUTES.has(String(species.id)): expected.append(StringName(ROUTES[String(species.id)]))
		check("route by canonical edge " + String(species.id), options == expected)
		check("preview does not mutate " + String(species.id), c.to_dict() == before)
		scanned += 1


func _evolve_owned(source: StringName, target: StringName) -> void:
	var c := _make(source, 30)
	c.current_hp = maxi(1, c.stats.max_hp - 10); c.friendship = 123; c.is_shiny = true
	status(c, &"poison"); c.held_item_id = &"oran_berry"
	c.moveset[0].current_pp = 4
	var before := c.to_dict()
	var service := _service(c, &"linking_cord")
	check("read-only options " + String(source), service.evolution_options(&"linking_cord", c.instance_id) == [target])
	var result: Dictionary = service.use_item(&"linking_cord", c.instance_id)
	var evolved: CreatureInstance = service.owner.owned_creature(c.instance_id)
	check("evolves owned source " + String(source), result.accepted and evolved.species_id == target and not is_same(c, evolved))
	check("consume exactly once " + String(source), service.owner.inventory.quantity(&"linking_cord") == 2)
	check("old object untouched " + String(source), c.to_dict() == before)
	var after := evolved.to_dict()
	for key: String in ["instance_id", "level", "experience", "ivs", "evs", "nature_id", "is_shiny", "friendship", "move_ids", "moveset", "held_item_id", "held_item_consumed", "status_state", "status_ids", "stat_stages", "current_hp"]:
		check("preserved " + String(source) + " " + key, after.has(key) and before.has(key) and after[key] == before[key])
	var saved := snapshot(service)
	check("cannot evolve again " + String(source), not service.use_item(&"linking_cord", c.instance_id).accepted and snapshot(service) == saved)
	# Storage uses the same aggregate replacement, not a party-only shortcut.
	var stored := _make(source, 30, {}, "hardy", &"stored_target")
	var owner := PlayerCollection.new(); owner.storage.add_creature(stored); owner.inventory.add(&"linking_cord")
	var storage_service := Service.new(); storage_service.configure(owner, catalogs, func(): return true)
	check("storage evolution " + String(source), storage_service.use_item(&"linking_cord", stored.instance_id).accepted and owner.storage.get_creature(stored.instance_id).species_id == target and owner.inventory.quantity(&"linking_cord") == 0)


func _reject_unchanged(service: RefCounted, target: StringName, label: String, requested: StringName = &"") -> void:
	var before := snapshot(service)
	check(label, not service.use_item(&"linking_cord", target, -1, requested).accepted and snapshot(service) == before)


func _rejections() -> void:
	for source: StringName in [&"mew", &"slowpoke", &"onix", &"shelmet", &"karrablast", &"pumpkaboo"]:
		var c := _make(source, 30); var service := _service(c, &"linking_cord")
		_reject_unchanged(service, c.instance_id, "does not weaken another evolution " + String(source))
		if source == &"pumpkaboo": check("sized forms are explicit dependency", service.use_item(&"linking_cord", c.instance_id).status == "DEPENDENCY_MISSING")
	var c := _make(&"haunter", 30); var service := _service(c, &"linking_cord")
	_reject_unchanged(service, c.instance_id, "wrong requested target", &"alakazam")
	_reject_unchanged(service, &"not_owned", "foreign creature")
	locked = true; _reject_unchanged(service, c.instance_id, "field guard rejects"); locked = false
	c.held_item_id = &"everstone"; _reject_unchanged(service, c.instance_id, "active Everstone blocks Haunter")
	c.held_item_consumed = true
	check("consumed Everstone no longer blocks", service.evolution_options(&"linking_cord", c.instance_id) == [&"gengar"])
	c.current_hp = 0; _reject_unchanged(service, c.instance_id, "no evolution revives a fainted creature")
	c.current_hp = c.stats.max_hp; c.battle_transform_original = {"species_id":"haunter"}
	_reject_unchanged(service, c.instance_id, "temporary battle creature rejected"); c.battle_transform_original.clear()
	service.owner.inventory.set_quantity(&"linking_cord", 0); _reject_unchanged(service, c.instance_id, "missing item")
	c = _make(&"kadabra", 30); c.held_item_id = &"everstone"; service = _service(c, &"linking_cord")
	check("modern Kadabra exception", service.use_item(&"linking_cord", c.instance_id).accepted)
	# A newly conditioned canonical edge must still be respected by the adapter.
	var species := catalogs.species(&"haunter"); var record: EvolutionRecord = species.evolutions[0]
	var conditions := record.conditions.duplicate(true); record.conditions = {"trade_species":"shelmet"}
	c = _make(&"haunter", 30); service = _service(c, &"linking_cord")
	_reject_unchanged(service, c.instance_id, "unknown extra condition not ignored")
	record.conditions = conditions


func _map_evolve(source: StringName) -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	# Applying demo configuration deliberately resets the party. Set the fixture
	# before evolving, never between the evolution and its battle handoff.
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100; config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection(); var id: StringName = owner.party.get_creatures()[0].instance_id
	check("map source setup", owner.replace_owned_same_identity(_make(source, 50, {}, "hardy", id)))
	owner.inventory.add(&"linking_cord", 3); owner.inventory.add(&"master_ball", 2)
	var bridge = scene._native_battles; bridge.save_path = V24 + ("gpu_" if capture else "headless_") + String(source) + ".json"
	check("before evolution save/load", bridge.save_game() and await bridge.load_game())
	check("map bag opens", scene.toggle_item_bag()); var bag: Control = scene._item_bag; _select(bag, "linking_cord")
	var result: Dictionary = bag._apply("use")
	owner = scene.field_collection(); var target := StringName(ROUTES[String(source)])
	check("real bag evolves " + String(source), result.accepted and owner.owned_creature(id).species_id == target and owner.inventory.quantity(&"linking_cord") == 2)
	check("evolution message", bag._result.text.contains("evolucionado"))
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("evolution screenshot", root.get_texture().get_image().save_png(V24 + String(source) + "_evolved.png") == OK)
	bag.hide(); await process_frame
	check("evolved field save/load", bridge.save_game() and await bridge.load_game())
	owner = scene.field_collection(); check("evolved ID persists", owner.owned_creature(id).species_id == target)
	scene.player.global_position = Vector2(420,150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view; var ready: bool = view.session != null and view.session.battle_state() != null
	check("evolved creature enters native", ready)
	if ready:
		view._playback.set_process(false)
		check("native evolved ID", view.session.battle_state().creature(id).species_id == target)
		check("evolved combat save/load", bridge.save_game() and await bridge.load_game())
		view = bridge.view; view._playback.set_process(false)
		check("capture settles evolved creature", (await view.adventure_command("master")).accepted)
		await _drain_view(view); await bridge.leave_battle()
		owner = scene.field_collection()
		check("settlement does not restore old species or item", owner.owned_creature(id).species_id == target and owner.inventory.quantity(&"linking_cord") == 2)
		if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame


func _passive_hints() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var owner: PlayerCollection = scene.field_collection()
	for id: StringName in [&"cleanse_tag", &"pure_incense"]: owner.inventory.add(id, 2)
	check("passive bag opens", scene.toggle_item_bag()); var bag: Control = scene._item_bag
	for id: StringName in [&"cleanse_tag", &"pure_incense"]:
		_select(bag, String(id)); var before := snapshot(bag.service)
		var result: Dictionary = bag._apply("use")
		check("passive-use hint not pending " + String(id), not result.accepted and result.reason == "equip_for_passive_effect" and bag._result.text.contains("equipado") and not bag._result.text.contains("pendiente"))
		check("hint never spends or mutates " + String(id), snapshot(bag.service) == before)
		if capture:
			await process_frame; await process_frame; await RenderingServer.frame_post_draw
			check("passive hint screenshot " + String(id), root.get_texture().get_image().save_png(V24 + String(id) + "_hint.png") == OK)
	scene.queue_free(); await process_frame
