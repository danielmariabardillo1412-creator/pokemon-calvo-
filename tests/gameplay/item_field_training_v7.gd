extends "res://tests/gameplay/item_field_effects_v4.gd"

const OUT_V7 := "res://.godot/item_field_v7/"
# Independent reference mapping and expected effects; not derived from runtime tables.
const TRAIN_ITEMS := {"hp_up": ["hp", 10], "protein": ["attack", 10], "iron": ["defense", 10], "calcium": ["special_attack", 10], "zinc": ["special_defense", 10], "carbos": ["speed", 10], "health_wing": ["hp", 1], "muscle_wing": ["attack", 1], "resist_wing": ["defense", 1], "genius_wing": ["special_attack", 1], "clever_wing": ["special_defense", 1], "swift_wing": ["speed", 1]}
const STATS := ["hp", "attack", "defense", "speed", "special_attack", "special_defense"]


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_V7)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for id: String in TRAIN_ITEMS:
		for location: String in ["PARTY", "STORAGE"]:
			for friendship: int in [0, 99, 100, 199, 200, 254, 255]:
				for bell: int in [0, 1, 2]: test_training(id, location, friendship, bell)
		test_limits(id)
	test_raw_validation()
	await test_real_training()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "rows": rows, "gpu": capture}
	var file := FileAccess.open(OUT_V7 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_FIELD_V7 ", report.status, " checks=", checks, " cases=", rows.size(), " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func test_training(id: String, location: String, friendship: int, bell: int) -> void:
	var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	c.friendship = friendship; c.current_hp = 100
	c.status_state.add_volatile(&"substitute", {"hp": 10}); status(c, &"sleep")
	service.sleep_clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
	if bell > 0: c.held_item_id = &"soothe_bell"; c.held_item_consumed = bell == 2
	if location == "STORAGE": check("deposit training fixture", service.owner.deposit(c.instance_id))
	var before := c.to_dict()
	check("canonical allowed item " + id, service.selection.content_allowed(StringName(id)) and catalogs.item(StringName(id)) != null)
	check("training inventory setup", service.owner.inventory.add(StringName(id), 2))
	var result: Dictionary = service.use_item(StringName(id), c.instance_id)
	var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
	var stat: String = TRAIN_ITEMS[id][0]; var gain: int = TRAIN_ITEMS[id][1]
	check("training accepted " + id, result.accepted and result.get("ev_added") == gain and result.get("stat_id") == stat)
	var expected_evs := c.evs.duplicate(); expected_evs[stat] = gain
	check("only chosen EV increases " + id, after.evs == expected_evs)
	var stat_key := "max_hp" if stat == "hp" else stat
	var expected_stats := c.stats.to_dict(); expected_stats[stat_key] = (341 if stat == "hp" else 236) + gain / 4
	check("independent level100 Hardy Mew formula " + id, after.stats.to_dict() == expected_stats)
	var friend_gain: int = ([5, 3, 2] if gain == 10 else [3, 2, 1])[mini(2, friendship / 100)]
	if bell == 1: friend_gain = friend_gain * 3 / 2
	check("base friendship and bell rounding " + id, after.friendship == mini(255, friendship + friend_gain))
	check("HP deficit conserved " + id, after.current_hp == 100 + gain / 4 if stat == "hp" else after.current_hp == 100)
	check("one consumed " + id, service.owner.inventory.quantity(StringName(id)) == 1)
	check("identity/location preserved " + id, after.instance_id == c.instance_id and service.owner.location_of(c.instance_id) == StringName(location))
	check("staged source untouched " + id, after != c and c.to_dict() == before)
	check("nature ability IV moves experience held item retained " + id, after.nature_id == c.nature_id and after.ability_id == c.ability_id and after.ivs == c.ivs and after.experience == c.experience and after.move_ids == c.move_ids and after.moveset[0].current_pp == c.moveset[0].current_pp and after.held_item_id == c.held_item_id and after.held_item_consumed == c.held_item_consumed)
	check("status and sleep clock retained " + id, after.status_state.to_dict() == c.status_state.to_dict() and service.sleep_clocks.has(String(c.instance_id)))
	rows.append({"id": id, "context": location, "friendship": friendship, "bell": bell, "status": "EV_TRAINING_BASE_FRIENDSHIP_PASS"})


func test_limits(id: String) -> void:
	var stat: String = TRAIN_ITEMS[id][0]
	var others: Array = STATS.duplicate(); others.erase(stat)
	var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	service.owner.inventory.add(StringName(id), 5)
	c.evs[stat] = 251; c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new()); c.current_hp = 1
	check("252 cap allows partial gain " + id, service.use_item(StringName(id), c.instance_id).accepted and service.owner.owned_creature(c.instance_id).evs[stat] == 252)
	check("HP minimum retained " + id, service.owner.owned_creature(c.instance_id).current_hp >= 1)
	reject_unchanged(service, StringName(id), "stat capped no friendship-only consumption " + id)
	c = service.owner.owned_creature(c.instance_id); c.evs[stat] = 0; c.evs[others[0]] = 252; c.evs[others[1]] = 252; c.evs[others[2]] = 5
	c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new())
	check("510 cap allows partial gain " + id, service.use_item(StringName(id), c.instance_id).accepted and service.owner.owned_creature(c.instance_id).evs[stat] == 1)
	reject_unchanged(service, StringName(id), "total capped no consumption " + id)
	c = service.owner.owned_creature(c.instance_id)
	for key: String in STATS: c.evs[key] = 0
	c.evs[stat] = 100; c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new())
	check("modern vitamin exceeds legacy100 " + id, service.use_item(StringName(id), c.instance_id).accepted and service.owner.owned_creature(c.instance_id).evs[stat] == 100 + int(TRAIN_ITEMS[id][1]))
	reject_unchanged(service, StringName(id), "unexpected training move slot " + id, 0)
	reject_unchanged(service, StringName(id), "foreign training target " + id, -1, &"foreign")
	locked = true; reject_unchanged(service, StringName(id), "locked training " + id); locked = false
	c = service.owner.owned_creature(c.instance_id); c.current_hp = 0
	reject_unchanged(service, StringName(id), "training cannot revive " + id)
	c.current_hp = 1; c.battle_transform_original = {"species_id": "mew"}
	reject_unchanged(service, StringName(id), "temporary form training rejected " + id)


func test_raw_validation() -> void:
	for raw: Variant in [-1, 253, 1.5, "10", true, INF, NAN]:
		var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
		c.evs.attack = raw; service.owner.inventory.add(&"protein")
		var before := var_to_bytes(c.evs); var bag_before: Dictionary = service.owner.inventory.to_dict()
		var result: Dictionary = service.use_item(&"protein", c.instance_id)
		check("raw invalid EV rejected before serialization " + str(raw), not result.accepted and result.reason == "invalid_training_state")
		check("raw invalid EV untouched " + str(raw), is_same(service.owner.owned_creature(c.instance_id), c) and before == var_to_bytes(c.evs) and bag_before == service.owner.inventory.to_dict())
	var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	service.owner.inventory.add(&"hp_up")
	c.evs.hp = 252; c.evs.attack = 252; c.evs.defense = 7
	reject_unchanged(service, &"hp_up", "already overflowing total rejected")
	c.evs.defense = 0; c.friendship = -1
	reject_unchanged(service, &"hp_up", "invalid friendship rejected")
	c.friendship = 0; c.evs["unknown_stat"] = 1
	reject_unchanged(service, &"hp_up", "unknown EV key rejected")


func test_real_training() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var c := create(owner.party.get_creatures()[0].instance_id); c.current_hp = 100; c.friendship = 100
	check("real training owned fixture", owner.replace_owned_same_identity(c))
	for id: StringName in [&"hp_up", &"protein", &"health_wing", &"muscle_wing"]: owner.inventory.add(id, 2)
	check("real training bag opens", scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	for id: String in ["hp_up", "protein", "health_wing", "muscle_wing"]:
		_select(bag, id)
		check("training UI description " + id, bag._description.text.contains("esfuerzo") and not bag._moves.visible)
		check("real training UI action " + id, bag._apply("use").accepted)
	var after: CreatureInstance = owner.owned_creature(c.instance_id)
	check("real training EV and derived stats", after.evs.hp == 11 and after.evs.attack == 11 and after.stats.max_hp == 343 and after.stats.attack == 238 and after.current_hp == 102 and after.friendship == 110)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("training GPU capture", root.get_texture().get_image().save_png(OUT_V7 + "training_bag.png") == OK)
	bag.hide(); await process_frame
	var path := "user://item_field_v7_gpu_test_only.json" if capture else "user://item_field_v7_test_only.json"
	scene._native_battles.save_path = path
	var before := snapshot(bag.service)
	check("real training saves", scene._native_battles.save_game())
	check("real training loads", await scene._native_battles.load_game())
	check("real training survives load and rebinds", scene.toggle_item_bag() and snapshot(bag.service) == before)
	bag.hide(); await process_frame
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var native: RefCounted = scene._native_battles.view.session
	check("training enters native session", native != null and native.has_active_battle())
	if native != null:
		var active: CreatureInstance = native.battle_state().creature(c.instance_id)
		check("native receives trained EV and friendship", active != null and active.evs.hp == 11 and active.evs.attack == 11 and active.current_hp == 102 and active.stats.max_hp == 343 and active.stats.attack == 238 and active.friendship == 110)
		reject_unchanged(bag.service, &"hp_up", "training locked during native battle", -1, c.instance_id)
		await native.close()
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
