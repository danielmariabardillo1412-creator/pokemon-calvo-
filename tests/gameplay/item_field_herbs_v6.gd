extends "res://tests/gameplay/item_field_effects_v4.gd"

const OUT_V6 := "res://.godot/item_field_v6/"
const HERBS := {"energy_powder": [60, 5, 10], "energy_root": [120, 10, 15], "heal_powder": [0, 5, 10]}


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_V6)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for id: String in HERBS:
		for location: String in ["PARTY", "STORAGE"]:
			for friendship: int in [0, 1, 5, 99, 100, 199, 200, 255]:
				for bell: int in [0, 1, 2]: test_herb(id, location, friendship, bell)
		test_rejections(id)
	await test_real_herbs()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "rows": rows, "gpu": capture}
	var file := FileAccess.open(OUT_V6 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_FIELD_V6 ", report.status, " checks=", checks, " cases=", rows.size(), " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func test_herb(id: String, location: String, friendship: int, bell: int) -> void:
	var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	c.current_hp = 1; c.friendship = friendship
	if id == "heal_powder": status(c, &"sleep"); service.sleep_clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
	if bell > 0: c.held_item_id = &"soothe_bell"; c.held_item_consumed = bell == 2
	if location == "STORAGE": check("deposit herb fixture", service.owner.deposit(c.instance_id))
	var before := c.to_dict()
	check("herb allowed", service.selection.content_allowed(StringName(id)))
	check("herb inventory setup", service.owner.inventory.add(StringName(id), 2))
	var result: Dictionary = service.use_item(StringName(id), c.instance_id)
	var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
	check("herb effect " + id, result.accepted)
	check("herb consumes exactly one " + id, service.owner.inventory.quantity(StringName(id)) == 1)
	check("source remains staged " + id, c.to_dict() == before and after != c)
	check("owner and location " + id, after.instance_id == c.instance_id and service.owner.location_of(c.instance_id) == StringName(location))
	var loss: int = HERBS[id][2] if friendship >= 200 else HERBS[id][1]
	check("reference friendship loss unaffected by bell " + id, after.friendship == maxi(0, friendship - loss))
	check("HP effect only " + id, after.current_hp == 1 + int(HERBS[id][0]))
	check("stats moves and training intact " + id, after.stats.to_dict() == c.stats.to_dict() and after.moveset[0].current_pp == c.moveset[0].current_pp and after.evs == c.evs and after.ivs == c.ivs and after.nature_id == c.nature_id and after.ability_id == c.ability_id)
	check("held item not consumed " + id, after.held_item_id == c.held_item_id and after.held_item_consumed == c.held_item_consumed)
	if id == "heal_powder": check("heal powder cures sleep and clears clock", after.status_state.persistent_id == &"" and after.status_ids.is_empty() and not after.status_state.rest_sleep and service.sleep_clocks.is_empty())
	rows.append({"id": id, "context": location, "friendship_before": friendship, "bell_context": bell, "status": "BITTER_MEDICINE_PASS"})


func test_rejections(id: String) -> void:
	var service := service_for(); service.owner.inventory.add(StringName(id), 2)
	var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	c.friendship = 255
	reject_unchanged(service, StringName(id), "healthy herb never lowers friendship " + id)
	c.current_hp = 1
	if id == "heal_powder": status(c, &"poison")
	for bad: int in [-1, 256]:
		c.friendship = bad; reject_unchanged(service, StringName(id), "invalid friendship " + id)
	c.friendship = 200
	reject_unchanged(service, StringName(id), "unexpected herb slot " + id, 0)
	reject_unchanged(service, StringName(id), "foreign herb target " + id, -1, &"foreign")
	locked = true; reject_unchanged(service, StringName(id), "locked herb " + id); locked = false
	c.current_hp = 0; reject_unchanged(service, StringName(id), "herb cannot revive " + id)
	c.current_hp = c.stats.max_hp - 1
	if id != "heal_powder": check("herb HP cap", service.use_item(StringName(id), c.instance_id).accepted and service.owner.owned_creature(c.instance_id).current_hp == c.stats.max_hp)
	for revival: StringName in [&"revive", &"max_revive", &"revival_herb", &"sacred_ash"]:
		check("revival stays banned " + String(revival), not service.selection.content_allowed(revival) and not Effects.supports(revival))


func test_real_herbs() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var c := create(owner.party.get_creatures()[0].instance_id); c.current_hp = 100; c.friendship = 200; status(c, &"sleep")
	check("real herb owned setup", owner.replace_owned_same_identity(c))
	scene._native_battles.clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
	for id: String in HERBS: owner.inventory.add(StringName(id), 2)
	check("real herbs bag opens", scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	_select(bag, "energy_powder")
	check("UI explains friendship penalty", bag._description.text.contains("amistad"))
	check("bag energy powder", bag._apply("use").accepted and owner.owned_creature(c.instance_id).current_hp == 160 and owner.owned_creature(c.instance_id).friendship == 190)
	_select(bag, "energy_root")
	check("bag energy root", bag._apply("use").accepted and owner.owned_creature(c.instance_id).current_hp == 280 and owner.owned_creature(c.instance_id).friendship == 180)
	_select(bag, "heal_powder")
	check("bag heal powder", bag._apply("use").accepted and owner.owned_creature(c.instance_id).friendship == 175 and owner.owned_creature(c.instance_id).status_state.persistent_id == &"" and scene._native_battles.clocks.is_empty())
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("herb GPU capture", root.get_texture().get_image().save_png(OUT_V6 + "herbs_bag.png") == OK)
	bag.hide(); await process_frame
	var path := "user://item_field_v6_gpu_test_only.json" if capture else "user://item_field_v6_test_only.json"
	scene._native_battles.save_path = path
	var before := snapshot(bag.service)
	check("real herb save", scene._native_battles.save_game())
	check("real herb load", await scene._native_battles.load_game())
	check("real herb state survives and rebinds", scene.toggle_item_bag() and snapshot(bag.service) == before)
	bag.hide(); await process_frame
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var native: RefCounted = scene._native_battles.view.session
	check("herb enters native session", native != null and native.has_active_battle())
	if native != null:
		var active: CreatureInstance = native.battle_state().creature(c.instance_id)
		check("native sees herb HP friendship and status", active != null and active.current_hp == 280 and active.friendship == 175 and active.status_state.persistent_id == &"")
		reject_unchanged(bag.service, &"energy_root", "herb locked during native battle", -1, c.instance_id)
		await native.close()
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
