extends "res://tests/gameplay/item_field_effects_v4.gd"

# Reuse only existing test fixtures/assertions, not the V4 execution or expectations.
# Expected amounts here are independently transcribed from the pinned reference.
const OUT_V5 := "res://.godot/item_field_v5/"
const HP_GAIN := {"fresh_water": 30, "soda_pop": 50, "lemonade": 70, "moomoo_milk": 100, "berry_juice": 20, "sweet_heart": 20, "oran_berry": 10, "sitrus_berry": -1}
const STATUS_BERRIES := {"cheri_berry": "paralysis", "chesto_berry": "sleep", "pecha_berry": "poison", "rawst_berry": "burn", "aspear_berry": "freeze"}
const ALL_CURES := ["lum_berry", "lava_cookie", "old_gateau", "casteliacone", "lumiose_galette", "shalour_sable", "big_malasada", "pewter_crunchies", "rage_candy_bar"]


func recovery_ids() -> Array:
	return HP_GAIN.keys() + STATUS_BERRIES.keys() + ALL_CURES + ["leppa_berry"]


func prepare_effect(c: CreatureInstance, id: String) -> void:
	if HP_GAIN.has(id): c.current_hp = 1
	elif id == "leppa_berry":
		c.moveset[0].current_pp = 3; c.moveset[0].max_pp = 56
		c.moveset[1].current_pp = 2
	else:
		status(c, StringName(STATUS_BERRIES.get(id, "sleep")))
		c.status_state.add_volatile(&"nightmare")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_V5)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("23 distinct IDs", recovery_ids().size() == 23)
	for id: String in recovery_ids(): test_recovery(id)
	test_cure_specificity()
	test_boundaries_and_caps()
	await test_real_bag()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "rows": rows, "gpu": capture}
	var file := FileAccess.open(OUT_V5 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_FIELD_V5 ", report.status, " checks=", checks, " cases=", rows.size(), " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func test_recovery(id: String) -> void:
	for location: String in ["PARTY", "STORAGE"]:
		var service := service_for()
		check("allowed canonical ID " + id, service.selection.content_allowed(StringName(id)) and catalogs.item(StringName(id)) != null)
		var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
		prepare_effect(c, id)
		service.sleep_clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2} if c.status_state.persistent_id == &"sleep" else {"unrelated": true}
		var before := c.to_dict()
		if location == "STORAGE": check("deposit " + id, service.owner.deposit(c.instance_id))
		check("inventory fixture " + id, service.owner.inventory.add(StringName(id), 2))
		var result: Dictionary = service.use_item(StringName(id), c.instance_id, 0 if id == "leppa_berry" else -1)
		check("effect applied " + id + location, result.accepted)
		var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
		check("exactly one consumed " + id, service.owner.inventory.quantity(StringName(id)) == 1)
		check("ownership retained " + id, after.instance_id == c.instance_id and service.owner.location_of(c.instance_id) == StringName(location))
		check("original not mutated " + id, c.to_dict() == before and after != c)
		check("stats and training retained " + id, after.stats.to_dict() == c.stats.to_dict() and after.evs == c.evs and after.ivs == c.ivs and after.friendship == c.friendship and after.nature_id == c.nature_id and after.ability_id == c.ability_id)
		check("held item retained " + id, after.held_item_id == c.held_item_id and after.held_item_consumed == c.held_item_consumed)
		if HP_GAIN.has(id):
			var gain: int = int(HP_GAIN[id]) if id != "sitrus_berry" else c.stats.max_hp / 4
			check("reference HP amount " + id, after.current_hp == 1 + gain)
			check("HP does not change status or PP " + id, after.status_state.to_dict() == c.status_state.to_dict() and after.moveset[0].current_pp == c.moveset[0].current_pp)
		elif id == "leppa_berry":
			check("Leppa selected boosted PP +10", after.moveset[0].current_pp == 13 and after.moveset[0].max_pp == 56 and after.moveset[1].current_pp == 2)
		else:
			check("cured counters " + id, after.status_state.persistent_id == &"" and after.status_ids.is_empty() and after.status_state.turns_remaining == 0 and not after.status_state.rest_sleep and not after.status_state.has_volatile(&"nightmare"))
			check("cure does not heal HP or PP " + id, after.current_hp == c.current_hp and after.moveset[0].current_pp == c.moveset[0].current_pp)
		if c.status_state.persistent_id == &"sleep": check("sleep clock removed " + id, service.sleep_clocks.is_empty())
		else: check("unrelated clock untouched " + id, service.sleep_clocks.has(String(c.instance_id)))
		rows.append({"id": id, "context": location, "status": "FIELD_RECOVERY_PASS"})
	var service := service_for(); service.owner.inventory.add(StringName(id), 2)
	reject_unchanged(service, StringName(id), "healthy no effect " + id, 0 if id == "leppa_berry" else -1)
	var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	prepare_effect(c, id)
	locked = true
	reject_unchanged(service, StringName(id), "locked " + id, 0 if id == "leppa_berry" else -1)
	locked = false
	reject_unchanged(service, StringName(id), "foreign " + id, 0 if id == "leppa_berry" else -1, &"foreign")
	if id != "leppa_berry": reject_unchanged(service, StringName(id), "unexpected slot " + id, 0)
	c.current_hp = 0
	reject_unchanged(service, StringName(id), "never revive " + id, 0 if id == "leppa_berry" else -1)
	c.current_hp = 1; c.battle_transform_original = {"species_id": "mew"}
	reject_unchanged(service, StringName(id), "temporary state " + id, 0 if id == "leppa_berry" else -1)


func test_cure_specificity() -> void:
	for id: String in STATUS_BERRIES.keys() + ALL_CURES:
		for condition: String in ["burn", "poison", "badly_poisoned", "paralysis", "sleep", "freeze"]:
			var service := service_for(); service.owner.inventory.add(StringName(id))
			var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
			status(c, StringName(condition)); c.status_state.add_volatile(&"substitute", {"hp": 10})
			var before := snapshot(service)
			var expected: bool = id in ALL_CURES or condition == STATUS_BERRIES.get(id) or id == "pecha_berry" and condition == "badly_poisoned"
			var result: Dictionary = service.use_item(StringName(id), c.instance_id)
			check("specific cure " + id + condition, result.accepted == expected)
			if expected:
				var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
				check("unrelated volatile retained " + id, after.status_state.has_volatile(&"substitute") and after.status_state.toxic_counter == 0)
			else: check("wrong cure atomic " + id, snapshot(service) == before)
	for id: String in ALL_CURES:
		var service := service_for(); service.owner.inventory.add(StringName(id))
		service.owner.owned_creature(&"field_item_target").status_state.add_volatile(&"confusion", {"turns": 3})
		check("full cure convention confusion " + id, service.use_item(StringName(id), &"field_item_target").accepted and not service.owner.owned_creature(&"field_item_target").status_state.has_volatile(&"confusion"))


func test_boundaries_and_caps() -> void:
	for id: String in HP_GAIN:
		var service := service_for(); service.owner.inventory.add(StringName(id))
		var c: CreatureInstance = service.owner.owned_creature(&"field_item_target"); c.current_hp -= 1
		check("HP cap " + id, service.use_item(StringName(id), c.instance_id).accepted and service.owner.owned_creature(c.instance_id).current_hp == c.stats.max_hp)
	var service := service_for(); service.owner.inventory.add(&"leppa_berry", 2)
	var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	c.moveset[0].current_pp = c.moveset[0].max_pp - 1
	for slot: int in [-2, -1, 2, 100]: reject_unchanged(service, &"leppa_berry", "Leppa invalid slot " + str(slot), slot)
	check("Leppa PP cap", service.use_item(&"leppa_berry", c.instance_id, 0).accepted and service.owner.owned_creature(c.instance_id).moveset[0].current_pp == c.moveset[0].max_pp)
	var exposed: Dictionary = Effects.recovery_items(); exposed.clear()
	check("profile return is isolated", Effects.recovery_supports(&"fresh_water"))
	for id: StringName in [&"revive", &"max_revive", &"revival_herb", &"sacred_ash", &"energy_powder", &"health_feather", &"escape_rope"]:
		check("unsupported not accidentally advertised " + String(id), not Effects.recovery_supports(id))


func test_real_bag() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	check("real field ready", scene.is_demo_ready())
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var first: CreatureInstance = owner.party.get_creatures()[0]
	var c := create(first.instance_id); c.current_hp = 100; status(c, &"sleep"); c.moveset[0].current_pp = 0
	check("real owned setup", owner.replace_owned_same_identity(c))
	scene._native_battles.clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
	for id: StringName in [&"chesto_berry", &"fresh_water", &"sitrus_berry", &"leppa_berry"]: owner.inventory.add(id, 2)
	check("B opens real bag", scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	_select(bag, "chesto_berry")
	check("real bag Chesto cures sleep", bag._apply("use").accepted and scene._native_battles.clocks.is_empty())
	_select(bag, "fresh_water")
	check("real bag Water heals 30 and updates text", bag._apply("use").accepted and owner.owned_creature(c.instance_id).current_hp == 130 and bag._targets.get_item_text(0).contains("PS 130/"))
	_select(bag, "sitrus_berry")
	check("real bag Sitrus", bag._apply("use").accepted)
	var expected_hp: int = 130 + c.stats.max_hp / 4
	check("real bag Sitrus quarter HP", owner.owned_creature(c.instance_id).current_hp == expected_hp)
	_select(bag, "leppa_berry")
	var before := snapshot(bag.service)
	check("Leppa requires explicit move in UI", bag._moves.visible and not bag._apply("use").accepted and snapshot(bag.service) == before)
	bag._moves.select(1)
	check("Leppa UI PP +10", bag._apply("use").accepted and owner.owned_creature(c.instance_id).moveset[0].current_pp == 10)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("bag fits viewport", bag.position.x >= 0 and bag.position.y >= 0 and bag.position.x + bag.size.x <= scene.get_viewport_rect().size.x and bag.position.y + bag.size.y <= scene.get_viewport_rect().size.y)
		check("GPU screenshot", root.get_texture().get_image().save_png(OUT_V5 + "recovery_bag.png") == OK)
	bag.hide(); await process_frame
	var path := "user://item_field_v5_gpu_test_only.json" if capture else "user://item_field_v5_test_only.json"
	scene._native_battles.save_path = path
	before = snapshot(bag.service)
	check("real save", scene._native_battles.save_game())
	check("real load", await scene._native_battles.load_game())
	check("real rebind after load", scene.toggle_item_bag() and snapshot(bag.service) == before)
	bag.hide(); await process_frame
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var native: RefCounted = scene._native_battles.view.session
	check("real encounter native session", native != null and native.has_active_battle())
	if native != null:
		var active: CreatureInstance = native.battle_state().creature(c.instance_id)
		check("native sees edited HP PP and status", active != null and active.current_hp == expected_hp and active.moveset[0].current_pp == 10 and active.status_state.persistent_id == &"")
		reject_unchanged(bag.service, &"fresh_water", "recovery locked during battle", -1, c.instance_id)
		await native.close()
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
