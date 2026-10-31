extends "res://tests/gameplay/item_field_effects_v4.gd"

# Identical probe injected into isolated copies only; no source project mutations.
const TRACE_OUT := "res://.godot/comparator_trace/"
var trace: Array = []
var bridge: Node
var view: Control


func owner() -> PlayerCollection:
	return scene.field_collection() if scene.has_method("field_collection") else scene._session.player


func record(label: String, extra: Dictionary = {}) -> void:
	var party := []; var storage := []
	for c: CreatureInstance in owner().party.get_creatures(): party.append(c.to_dict())
	for c: CreatureInstance in owner().storage.get_all_creatures(): storage.append(c.to_dict())
	var state := {"party": party, "storage": storage, "inventory": owner().inventory.to_dict(), "clocks": bridge.clocks.duplicate(true), "rng": str(scene._director._encounter_rng.state), "next_seed": scene._director._next_battle_seed, "position": [scene.player.global_position.x, scene.player.global_position.y], "extra": extra}
	trace.append({"label": label, "state": JSON.parse_string(JSON.stringify(state))})


func drain_trace() -> void:
	var frames := 0
	while view._playback.is_playing() and frames < 2000:
		view._playback.advance(0.25); frames += 1
	await process_frame; await process_frame; view._refresh_view()
	check("playback completes", not view._playback.is_playing())


func battle_view() -> Dictionary:
	return {"checkpoint": view.session.snapshot(), "phase": view.session.phase()}


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(TRACE_OUT)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	check("actual field ready", scene.is_demo_ready())
	bridge = scene._native_battles; view = bridge.view
	bridge.save_path = TRACE_OUT + "checkpoint.json"
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "pidgey"; config.wild_min_level = 5; config.wild_max_level = 5; config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var current := owner(); current.party = CreatureParty.new()
	var c := create(&"compare_owned")
	c.moveset.clear(); c.move_ids.clear()
	for id: StringName in [&"reflect", &"recover", &"tackle", &"thunderbolt"]: c.add_move(id, catalogs)
	c.evs.hp = 20; c.recalculate_stats(catalogs.species(&"mew"), ProgressionRuleset.new()); c.current_hp = 100; c.friendship = 100
	c.moveset[0].current_pp = 0; status(c, &"sleep")
	check("actual party fixture", current.party.add_creature(c))
	bridge.clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
	for id: StringName in [&"potion", &"awakening", &"ether", &"pomeg_berry", &"leftovers", &"master_ball", &"fire_stone"]: current.inventory.add(id, 2)
	scene._director._encounter_rng.seed = 1234; scene._director._next_battle_seed = 12345
	scene._capture_rng.seed = 77; scene._escape_rng.seed = 88
	scene.player.global_position = Vector2(420, 150)
	record("field_initial")
	check("actual bag opens", scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	for id: String in ["awakening", "potion", "ether", "pomeg_berry"]:
		_select(bag,id)
		if id == "ether": bag._moves.select(1)
		check("common field action " + id, bag._apply("use").accepted)
		record("use_"+id)
	check("independent HP/EV/PP/status/friendship expectations", owner().owned_creature(&"compare_owned").current_hp == 117 and owner().owned_creature(&"compare_owned").evs.hp == 10 and owner().owned_creature(&"compare_owned").moveset[0].current_pp == 10 and owner().owned_creature(&"compare_owned").friendship == 105 and owner().owned_creature(&"compare_owned").status_state.persistent_id == &"")
	check("equip common object", bag.service.equip(&"leftovers", &"compare_owned").accepted)
	record("equipped")
	check("unequip common object", bag.service.unequip(&"compare_owned").accepted)
	check("deposit common identity", owner().deposit(&"compare_owned"))
	record("in_storage")
	check("withdraw common identity", owner().withdraw(&"compare_owned"))
	record("withdrawn")
	var random := RandomNumberGenerator.new(); random.seed = 22
	var eevee := CreatureFactory.create(catalogs.species(&"eevee"), 10, catalogs, ProgressionRuleset.new(), random, {"instance_id": "compare_eevee", "moves": ["tackle"], "nature_id": "hardy"})
	check("evolution owned fixture", owner().party.add_creature(eevee))
	check("common stone evolution", bag.service.evolve(&"fire_stone", &"compare_eevee", &"flareon").accepted)
	check("independent evolution identity", owner().owned_creature(&"compare_eevee").species_id == &"flareon")
	record("evolved")
	var grow := CreatureFactory.create(catalogs.species(&"bulbasaur"), 5, catalogs, ProgressionRuleset.new(), random, {"instance_id":"compare_progression","moves":["tackle"],"nature_id":"hardy"})
	var events: Array = ProgressionSystem.gain_experience(grow, 500, catalogs.species(&"bulbasaur"), catalogs, ProgressionRuleset.new())
	var serialized_events := []
	for e: ProgressionEvent in events: serialized_events.append({"kind": e.kind, "creature_id": String(e.creature_id), "data": e.data})
	check("common progression gains levels", grow.level > 5 and events.size() > 0)
	record("progression", {"creature":grow.to_dict(),"events":serialized_events})
	bag.hide(); await process_frame
	check("field checkpoint saves", bridge.save_game())
	var field_bytes := FileAccess.get_file_as_bytes(bridge.save_path)
	check("field checkpoint loads", await bridge.load_game())
	record("field_restored")
	await scene._on_player_step_completed(scene.player.global_position)
	check("wild native battle starts", view.session != null and view.session.has_active_battle())
	if view.session != null:
		view._playback.set_process(false)
		record("wild_started", battle_view())
		check("battle checkpoint saves", bridge.save_game())
		check("common reflect action", (await view.choose("move 1")).accepted); await drain_trace()
		var first := JSON.stringify(battle_view(), "", true)
		record("wild_turn", battle_view())
		check("battle checkpoint restores", await bridge.load_game())
		view._playback.set_process(false)
		check("common replay action", (await view.choose("move 1")).accepted); await drain_trace()
		check("independent checkpoint replay identical", JSON.stringify(battle_view(), "", true) == first)
		record("wild_replayed", battle_view())
		check("common native capture", (await view.adventure_command("master")).accepted); await drain_trace()
		check("independent capture settles", view.session.completion_reason == "CAPTURED")
		record("wild_captured", {"reason":view.session.completion_reason})
		await bridge.leave_battle()
	# Restore the earlier field to test the trainer route with a stable roster.
	var file := FileAccess.open(bridge.save_path, FileAccess.WRITE); file.store_buffer(field_bytes); file.close()
	check("field returns before trainer", await bridge.load_game())
	var opponent := CreatureFactory.create(catalogs.species(&"caterpie"), 5, catalogs, ProgressionRuleset.new(), random, {"instance_id":"compare_trainer","moves":["tackle"]})
	check("trainer roster fixture", scene._trainer_campaign_owner.configure(scene.TECHNICAL_TRAINER_ID,[opponent] as Array[CreatureInstance]))
	check("native trainer begins", scene.start_demo_trainer_battle())
	while bridge.busy: await process_frame
	view._playback.set_process(false)
	check("trainer forbids capture", not (await view.session.capture(&"master_ball",view.session.revision)).accepted)
	record("trainer_started", battle_view())
	check("trainer attack", (await view.choose("move 4")).accepted); await drain_trace()
	check("trainer victory", view.session.completion_reason == "VICTORY")
	record("trainer_victory", {"reason":view.session.completion_reason})
	check("settled trainer save", bridge.save_game())
	await bridge.leave_battle()
	check("settled trainer load", await bridge.load_game())
	record("trainer_restored")
	if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame
	var report := {"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors,"trace":trace}
	file = FileAccess.open(TRACE_OUT+"trace.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  ",true));file.close()
	print("COMPARATOR_STATE_TRACE ",report.status," checks=",checks," states=",trace.size())
	done=true;quit(0 if errors.is_empty() else 1)
