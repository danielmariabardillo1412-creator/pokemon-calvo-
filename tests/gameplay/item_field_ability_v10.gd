extends "res://tests/gameplay/item_field_effects_v4.gd"

const Abilities = preload("res://modules/inventory/field_ability_effects.gd")
const Variants = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Native = preload("res://modules/gameplay/showdown_adventure_session.gd")
const V10 := "res://.godot/item_field_v10/"
const TRANSITIONS := {"ability_capsule": {1: 2, 2: 1}, "ability_patch": {1: 3, 2: 3, 3: 1}}
var matrix_cases := 0
var outcomes: Dictionary = {}
var native_rows: Array = []

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done: push_error("ITEM_FIELD_V10 timeout"); quit(2))

func _make(species: StringName = &"growlithe", ability: StringName = &"intimidate", id: StringName = &"ability_target") -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 179
	return CreatureFactory.create(catalogs.species(species), 50, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": id, "ability_id": ability, "nature_id": "hardy", "moves": ["growl", "protect"]})

func _service(c: CreatureInstance, item: StringName = &"ability_capsule", local_catalog: DefinitionCatalog = null) -> RefCounted:
	var owner := PlayerCollection.new(); owner.party.add_creature(c); owner.inventory.add(item, 3)
	var service := Service.new(); service.configure(owner, catalogs if local_catalog == null else local_catalog, func(): return not locked)
	return service

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V10)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay for abilities", Variants.apply(catalogs))
	_matrix()
	_owned()
	_negative()
	await _native_control()
	await _real_bag()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"matrix_cases": matrix_cases, "outcomes": outcomes, "native_rows": native_rows, "gpu": capture}
	var file := FileAccess.open(V10 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true
	print("ITEM_FIELD_V10 ", report.status, " checks=", checks, " cases=", matrix_cases, " GPU=", capture)
	quit(0 if errors.is_empty() else 1)

func _matrix() -> void:
	for sid: String in catalogs.variant_allowed_species:
		var species := catalogs.species(StringName(sid))
		var slots: Dictionary = {}
		for row: Dictionary in species.ability_slots: slots[int(row.slot)] = String(row.ability_id)
		var unique: Dictionary = {}
		for id: StringName in species.ability_ids: unique[String(id)] = true
		for ability: String in unique:
			var matches: Array[int] = []
			for index: int in slots:
				if slots[index] == ability: matches.append(index)
			for item: String in TRANSITIONS:
				var c := _make(StringName(sid), StringName(ability))
				var service := _service(c, StringName(item))
				var before := c.to_dict()
				var destination := ""
				if matches.size() == 1 and TRANSITIONS[item].has(matches[0]):
					destination = slots.get(TRANSITIONS[item][matches[0]], "")
				var expected_change: bool = destination != "" and destination != ability and destination != "zen_mode" and service.content.ability_allowed(destination)
				var result: Dictionary = service.use_item(StringName(item), c.instance_id)
				var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
				var expected := before.duplicate(true)
				if expected_change: expected.ability_id = destination
				check("catalog result " + sid + "/" + item + "/" + ability, result.accepted == expected_change)
				check("only ability changed " + sid, after.to_dict() == expected)
				check("atomic item/source " + sid, service.owner.inventory.quantity(StringName(item)) == (2 if expected_change else 3) and c.to_dict() == before)
				var key := item + "/" + ("APPLIED" if result.accepted else String(result.status) + "/" + String(result.reason))
				outcomes[key] = int(outcomes.get(key, 0)) + 1
				matrix_cases += 1
	check("all eligible species in ability matrix", catalogs.variant_allowed_species.size() == 1076 and matrix_cases > 4000)

func _owned() -> void:
	for pair: Array in [["ability_capsule", "intimidate", "flash_fire"], ["ability_capsule", "flash_fire", "intimidate"],
		["ability_patch", "flash_fire", "justified"], ["ability_patch", "justified", "intimidate"]]:
		for stored in [false, true]:
			var c := _make(&"growlithe", StringName(pair[1])); c.friendship = 199; c.current_hp -= 20
			c.moveset[0].max_pp = 64; c.moveset[0].current_pp = 13
			c.held_item_id = &"soothe_bell"; status(c, &"sleep"); c.is_shiny = true
			var service := _service(c, StringName(pair[0]))
			service.sleep_clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
			if stored: service.owner.deposit(c.instance_id)
			var before := c.to_dict(); var clocks: Dictionary = service.sleep_clocks.duplicate(true)
			var preview: Dictionary = service.ability_preview(StringName(pair[0]), c.instance_id)
			check("preview exact route", preview.accepted and preview.ability_id == pair[2] and c.to_dict() == before)
			var result: Dictionary = service.use_item(StringName(pair[0]), c.instance_id, -1, &"", preview.stamp)
			var expected := before.duplicate(true); expected.ability_id = pair[2]
			var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
			check("whole state remains except ability", result.accepted and after.to_dict() == expected and not is_same(c, after))
			check("no source/clock/location mutation", c.to_dict() == before and service.sleep_clocks == clocks and service.owner.location_of(c.instance_id) == (&"STORAGE" if stored else &"PARTY"))
			check("single consumed", service.owner.inventory.quantity(StringName(pair[0])) == 2)

func _reject(service: RefCounted, reason: String, item: StringName = &"ability_capsule") -> void:
	var before := snapshot(service)
	var result: Dictionary = service.use_item(item, &"ability_target")
	check("reject " + reason, not result.accepted and result.reason == reason and snapshot(service) == before)

func _negative() -> void:
	for row: Array in [["darmanitan", "sheer_force"], ["darmanitan_galar_standard", "gorilla_tactics"]]:
		var target := _make(StringName(row[0]), StringName(row[1]))
		var pending := _service(target, &"ability_patch")
		_reject(pending, "ability_form_route_pending", &"ability_patch")
		target = _make(StringName(row[0]), &"zen_mode"); pending = _service(target, &"ability_patch")
		check("existing form ability can revert without enabling a form route", pending.use_item(&"ability_patch", target.instance_id).accepted and pending.owner.owned_creature(target.instance_id).ability_id == StringName(row[1]))
	var c := _make(&"machop", &"guts"); var service := _service(c)
	_reject(service, "ability_not_permitted")
	c = _make(&"growlithe", &"justified"); service = _service(c); _reject(service, "item_has_no_effect")
	c = _make(&"gengar", &"cursed_body"); service = _service(c, &"ability_patch"); _reject(service, "item_has_no_effect", &"ability_patch")
	c = _make(); c.ability_id = &"own_tempo"; service = _service(c); _reject(service, "ability_source_not_in_slots")
	c = _make(); service = _service(c); c.current_hp = 0; _reject(service, "creature_knocked_out")
	c.current_hp = 1; c.battle_transform_original = {"species_id": "ditto"}; _reject(service, "temporary_battle_state")
	c.battle_transform_original.clear(); locked = true; _reject(service, "field_locked"); locked = false
	c.ivs["attack"] = -1; _reject(service, "invalid_ability_state"); c.ivs["attack"] = 0
	var saved: BattleMoveSlot = c.moveset[0]; c.moveset[0] = null
	check("null slot rejected without serialization", service.use_item(&"ability_capsule", c.instance_id).reason == "invalid_pp_state" and service.owner.inventory.quantity(&"ability_capsule") == 3)
	c.moveset[0] = saved
	service.owner.inventory.remove(&"ability_capsule", 3); _reject(service, "item_not_owned")
	service.owner.inventory.add(&"ability_capsule", 3); service.owner.inventory.corrupted = true
	_reject(service, "invalid_inventory"); service.owner.inventory.corrupted = false
	var foreign_before := snapshot(service)
	check("foreign creature no mutation", service.use_item(&"ability_capsule", &"foreign").reason == "creature_not_owned" and snapshot(service) == foreign_before)
	for mutation in 5:
		c = _make(); service = _service(c)
		var preview: Dictionary = service.ability_preview(&"ability_capsule", c.instance_id)
		match mutation:
			0: c.friendship += 1
			1: service.owner.inventory.add(&"potion")
			2: service.owner.replace_owned_same_identity(CreatureInstance.from_dict(c.to_dict()))
			3: service.configure(service.owner, catalogs, func(): return true, service.sleep_clocks)
			4: service.owner.inventory = PlayerInventory.from_dict(service.owner.inventory.to_dict())
		var before := snapshot(service)
		var rejected: Dictionary = service.use_item(&"ability_capsule", c.instance_id, -1, &"", preview.stamp)
		check("stale preview no mutation " + str(mutation), not rejected.accepted and rejected.reason == "ability_state_changed" and snapshot(service) == before)
	# Isolated metadata fixtures share read-only catalogs, never canonical species.
	for mode in 6:
		var local := DefinitionCatalog.new(); local.move_catalog = catalogs.move_catalog; local.ability_catalog = catalogs.ability_catalog
		var sp := CreatureSpecies.from_dict(catalogs.species(&"growlithe").to_dict())
		match mode:
			0: sp.ability_slots.clear()
			1: sp.ability_slots[1].slot = 1
			2: sp.ability_slots[0].is_hidden = true
			3: sp.ability_slots[0].slot = 1.5
			4: sp.ability_slots[2].ability_id = "intimidate"; sp.ability_ids.erase(&"justified")
			5: sp.ability_slots[1].ability_id = "intimidate"; sp.ability_ids.erase(&"flash_fire")
		local.add_species(sp); c = _make(); service = _service(c, &"ability_capsule", local)
		var before := snapshot(service); var rejected: Dictionary = service.use_item(&"ability_capsule", c.instance_id)
		check("ambiguous/missing/bad metadata no consume " + str(mode), not rejected.accepted and snapshot(service) == before)
		if mode == 5:
			service.owner.inventory.add(&"ability_patch")
			var patched: Dictionary = service.use_item(&"ability_patch", c.instance_id)
			check("duplicated normal IDs still permit unambiguous hidden destination", patched.accepted and service.owner.owned_creature(c.instance_id).ability_id == &"justified")

func _native_control() -> void:
	for route: String in ["control", "capsule", "patch"]:
		var flash := route == "capsule"
		var c := _make(); c.moveset.resize(1); c.move_ids.resize(1)
		var service := _service(c, &"ability_patch" if route == "patch" else &"ability_capsule")
		if flash: check("native control obtains Flash Fire using capsule", service.use_item(&"ability_capsule", c.instance_id).accepted)
		if route == "patch": check("native control obtains hidden ability using patch", service.use_item(&"ability_patch", c.instance_id).accepted)
		var enemy := _make(&"vulpix", &"flash_fire", &"ability_enemy")
		enemy.moveset.clear(); enemy.move_ids.clear(); enemy.add_move(&"ember", catalogs)
		var session := Native.new(catalogs, service.owner, "gen9calvounifiedv1")
		var opened: bool = await session.begin_wild(self, enemy, [23, 19, 29, 43])
		check("native ability control begins", opened)
		if opened:
			var initial: int = session.battle_state().creature(c.instance_id).current_hp
			var result: Dictionary = await session.submit("move 1", session.revision)
			var active: CreatureInstance = session.battle_state().creature(c.instance_id)
			var damage := initial - active.current_hp
			check("native ability actually changes fire immunity", result.accepted and (damage == 0 if flash else damage > 0))
			check("native mirror retains selected ability", active.ability_id == (&"flash_fire" if flash else &"justified" if route == "patch" else &"intimidate"))
			native_rows.append({"route": route, "flash_fire": flash, "damage_received": damage, "ability": String(active.ability_id)})
		await session.close()
	# Known missing form route: prove why the item must defer Zen Mode instead
	# of consuming a Patch whose automatic battle transition cannot settle.
	var zen := _make(&"darmanitan", &"zen_mode")
	zen.current_hp = int(zen.stats.max_hp / 2.0); zen.moveset.resize(1); zen.move_ids.resize(1)
	var pending := _service(zen, &"ability_patch")
	var foe := _make(&"vulpix", &"flash_fire", &"zen_enemy")
	foe.moveset.resize(1); foe.move_ids.resize(1)
	var session := Native.new(catalogs, pending.owner, "gen9calvounifiedv1")
	var before := snapshot(pending)
	var opened: bool = await session.begin_wild(self, foe, [23, 19, 29, 43])
	check("known Zen Mode boundary starts", opened)
	if opened:
		var rejected: Dictionary = await session.submit("move 1", session.revision)
		check("native Zen form route explicitly unsupported", not rejected.accepted and session.last_error == "temporary_form_not_supported" and snapshot(pending) == before)
		native_rows.append({"route": "zen_mode_dependency", "native_error": session.last_error, "campaign_unchanged": snapshot(pending) == before})
	await session.close()

func _drain(view: Control) -> void:
	for attempt in 2000:
		if not view._playback.is_playing(): break
		view._playback.advance(0.25)
	await process_frame

func _real_bag() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100; config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection(); var id := owner.party.get_creatures()[0].instance_id
	var c := _make(&"growlithe", &"intimidate", id)
	check("real ability target", owner.replace_owned_same_identity(c))
	for item: StringName in [&"ability_capsule", &"ability_patch", &"master_ball"]: owner.inventory.add(item, 4)
	check("real ability bag opens", scene.toggle_item_bag())
	var bag = scene._item_bag; _select(bag, "ability_capsule")
	check("UI previews actual ability", bag._description.text.contains("Intimidación") and bag._description.text.contains("Absorbe Fuego"))
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("ability bag fits viewport", bag.position.y >= 0 and bag.position.y + bag.size.y <= root.size.y)
		check("ability bag capture", root.get_texture().get_image().save_png(V10+"ability_bag.png") == OK)
	var real_bridge = scene._native_battles
	var clocks_before := snapshot(bag.service)
	real_bridge.clocks = real_bridge.clocks.duplicate(true)
	check("replaced equal-content clocks invalidate the UI binding", not bag._apply("use").accepted and snapshot(bag.service) == clocks_before)
	check("refresh explicitly rebinds clocks", is_same(bag.service.sleep_clocks, real_bridge.clocks))
	check("real capsule succeeds", bag._apply("use").accepted and owner.owned_creature(id).ability_id == &"flash_fire" and bag._result.text.contains("Absorbe Fuego"))
	_select(bag, "ability_patch"); check("real patch forward", bag._apply("use").accepted and owner.owned_creature(id).ability_id == &"justified")
	check("real patch reverse to first normal", bag._apply("use").accepted and owner.owned_creature(id).ability_id == &"intimidate")
	_select(bag, "ability_capsule"); c = owner.owned_creature(id); c.friendship += 1
	var before := snapshot(bag.service)
	check("UI refuses stale destination", not bag._apply("use").accepted and snapshot(bag.service) == before)
	check("new explicit use applies refreshed destination", bag._apply("use").accepted and owner.owned_creature(id).ability_id == &"flash_fire")
	c = owner.owned_creature(id); c.ability_id = &"justified"; bag._refresh_choices()
	check("hidden capsule preview has no destination", bag._ability_stamp.is_empty())
	c.ability_id = &"intimidate"; before = snapshot(bag.service)
	check("invalid preview becoming valid needs explicit review", not bag._apply("use").accepted and snapshot(bag.service) == before)
	check("reviewed formerly invalid preview applies", bag._apply("use").accepted and owner.owned_creature(id).ability_id == &"flash_fire")
	var old_service: RefCounted = bag.service
	bag.hide(); await process_frame
	var bridge = scene._native_battles
	bridge.save_path = "user://ability_v10_gpu_only.json" if capture else "user://ability_v10_test_only.json"
	check("ability field save", bridge.save_game())
	check("ability field load", await bridge.load_game())
	check("retired service stays locked", old_service.use_item(&"ability_capsule", id).reason == "field_locked")
	owner = scene.field_collection(); check("ability retained through save", owner.owned_creature(id).ability_id == &"flash_fire")
	check("bag rebinds", scene.toggle_item_bag()); bag = scene._item_bag; bag.hide(); await process_frame
	scene.player.global_position = Vector2(420, 150); await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view; view._playback.set_process(false)
	check("field native receives changed ability", view.session != null and view.session.has_active_battle() and view.session.battle_state().creature(id).ability_id == &"flash_fire")
	if view.session != null and view.session.has_active_battle():
		check("battle blocks ability item", bag.service.use_item(&"ability_capsule", id).reason == "field_locked")
		check("ability battle checkpoint saves", bridge.save_game())
		check("ability battle checkpoint restores", await bridge.load_game())
		view._playback.set_process(false)
		check("ability after checkpoint", view.session.battle_state().creature(id).ability_id == &"flash_fire")
		check("capture after ability change", (await view.adventure_command("master")).accepted)
		await _drain(view); await bridge.leave_battle()
		check("settled ability survives", scene.field_collection().owned_creature(id).ability_id == &"flash_fire")
		if view.session != null: await view.session.close()
	var path: String = ProjectSettings.globalize_path(bridge.save_path)
	scene.queue_free(); await process_frame
	if path.begins_with(ProjectSettings.globalize_path("user://")): DirAccess.remove_absolute(path)
