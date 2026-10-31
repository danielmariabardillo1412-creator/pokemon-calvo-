extends "res://tests/gameplay/item_field_effects_v4.gd"

const OUT_V8 := "res://.godot/item_field_v8/"
# Independent expected totals, not the implementation formula or its helper.
const PP_TOTALS := {5: [5, 6, 7, 8], 10: [10, 12, 14, 16], 15: [15, 18, 21, 24],
	20: [20, 24, 28, 32], 25: [25, 30, 35, 40], 30: [30, 36, 42, 48],
	35: [35, 42, 49, 56], 40: [40, 48, 56, 64]}
var catalog_ids: Array[String] = []
var catalog_cases := 0

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_V8)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	_test_catalog()
	for id: StringName in [&"pp_up", &"pp_max"]:
		for location: String in ["PARTY", "STORAGE"]:
			for slot in 4:
				for friendship: int in [0, 99, 100, 199, 200, 254, 255]:
					for bell in 3: _test_owned(id, location, slot, friendship, bell)
		_test_boundaries_pp()
	await _test_real_pp()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"rows": rows, "catalog_move_ids": catalog_ids, "catalog_cases": catalog_cases, "gpu": capture}
	var file := FileAccess.open(OUT_V8 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_FIELD_V8 ", report.status, " checks=", checks, " contexts=", rows.size(), " catalog_cases=", catalog_cases, " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)

func _test_catalog() -> void:
	var policy: RefCounted = service_for().content
	var c: CreatureInstance = create()
	for move_id: StringName in catalogs.move_catalog.all_ids():
		var definition := catalogs.move(move_id)
		if not policy.move_learnable(String(move_id)) or definition.pp < 5: continue
		check("base PP has independent oracle/" + String(move_id), PP_TOTALS.has(definition.pp))
		if not PP_TOTALS.has(definition.pp): continue
		catalog_ids.append(String(move_id))
		c.move_ids[0] = move_id; c.moveset[0].move_id = move_id
		for stage in 4:
			for id: StringName in [&"pp_up", &"pp_max"]:
				for remaining in 3:
					var old_max: int = PP_TOTALS[definition.pp][stage]
					var old_pp: int = 0 if remaining == 0 else old_max / 2 if remaining == 1 else old_max
					c.moveset[0].max_pp = old_max; c.moveset[0].current_pp = old_pp; c.friendship = 99
					var expected := c.to_dict()
					var next_stage := 3 if id == &"pp_max" else mini(3, stage + 1)
					var expected_max: int = PP_TOTALS[definition.pp][next_stage]
					if stage < 3:
						expected.moveset[0].max_pp = expected_max
						expected.moveset[0].current_pp = old_pp + expected_max - old_max
						expected.friendship = 104
					var result := Effects.apply(c, id, 0, catalogs)
					check("catalog accepted/capped " + String(move_id), result.accepted == (stage < 3))
					check("catalog PP/spent/friendship and unrelated state " + String(move_id), c.to_dict() == expected)
					catalog_cases += 1
	check("whole learned catalog covered", catalog_ids.size() > 750 and catalog_cases == catalog_ids.size() * 24)

func _four_slots(c: CreatureInstance) -> void:
	c.moveset.clear(); c.move_ids.clear()
	for id: StringName in [&"tackle", &"reflect", &"growl", &"protect"]: c.add_move(id, catalogs)

func _test_owned(id: StringName, location: String, selected: int, friendship: int, bell: int) -> void:
	var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	_four_slots(c); c.friendship = friendship; c.current_hp = 100
	status(c, &"sleep"); c.status_state.add_volatile(&"confusion", {"turns": 2})
	service.sleep_clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
	if bell > 0: c.held_item_id = &"soothe_bell"; c.held_item_consumed = bell == 2
	var base_pp := catalogs.move(c.moveset[selected].move_id).pp
	var old_stage := selected % 3
	var old_max: int = PP_TOTALS[base_pp][old_stage]
	var old_pp: int = old_max if bell == 0 else old_max / 2 if bell == 1 else 0
	c.moveset[selected].max_pp = old_max; c.moveset[selected].current_pp = old_pp
	if location == "STORAGE": check("deposit PP target", service.owner.deposit(c.instance_id))
	check("canonical PP item and inventory", catalogs.item(id) != null and service.selection.content_allowed(id) and service.owner.inventory.add(id, 2))
	var before := c.to_dict(); var clocks: Dictionary = service.sleep_clocks.duplicate(true)
	var result: Dictionary = service.use_item(id, c.instance_id, selected)
	var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
	var next_stage := 3 if id == &"pp_max" else old_stage + 1
	var expected_max: int = PP_TOTALS[base_pp][next_stage]
	var expected := before.duplicate(true)
	expected.moveset[selected].max_pp = expected_max
	expected.moveset[selected].current_pp = old_pp + expected_max - old_max
	var friend_gain: int = [5, 3, 2][mini(2, friendship / 100)]
	if bell == 1: friend_gain = friend_gain * 3 / 2
	expected.friendship = mini(255, friendship + friend_gain)
	check("PP item applied to chosen slot", result.accepted and result.action == "pp_boost" and result.move_slot == selected and result.boosts == next_stage)
	check("only allowed fields changed/PP/spent/friendship", after.to_dict() == expected)
	check("one PP item consumed", service.owner.inventory.quantity(id) == 1)
	check("identity and location preserved", after.instance_id == c.instance_id and service.owner.location_of(c.instance_id) == StringName(location))
	check("staged source not mutated", not is_same(after, c) and c.to_dict() == before)
	check("sleep clock unchanged", service.sleep_clocks == clocks)
	rows.append({"id": String(id), "location": location, "slot": selected, "old_stage": old_stage, "new_stage": next_stage, "friendship": friendship, "bell": bell})

func _reject_pp(service: RefCounted, label: String, slot := 0, id: StringName = &"pp_up", reason := "") -> void:
	var before := snapshot(service)
	var result: Dictionary = service.use_item(id, &"field_item_target", slot)
	check(label, not result.accepted and snapshot(service) == before and (reason.is_empty() or result.reason == reason))

func _test_boundaries_pp() -> void:
	for id: StringName in [&"pp_up", &"pp_max"]:
		var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
		_reject_pp(service, "missing PP item", 0, id, "item_not_owned")
		service.owner.inventory.add(id, 8)
		for slot: int in [-2, -1, 2, 10]: _reject_pp(service, "move selection required", slot, id, "move_slot_required")
		c.moveset[0].max_pp = 56; c.moveset[0].current_pp = 0
		_reject_pp(service, "capped empty PP does not consume or give friendship", 0, id, "item_has_no_effect")
		for maximum: int in [-1, 0, 34, 36, 55, 57]:
			c.moveset[0].max_pp = maximum
			_reject_pp(service, "invalid PP max not repaired", 0, id, "invalid_pp_state")
		c.moveset[0].max_pp = 35
		for current: int in [-1, 36]:
			c.moveset[0].current_pp = current
			_reject_pp(service, "invalid remaining PP not repaired", 0, id, "invalid_pp_state")
		c.moveset[0].current_pp = 0
		for friendship: int in [-1, 256]:
			c.friendship = friendship; _reject_pp(service, "invalid friendship", 0, id, "invalid_training_state")
		c.friendship = 0; locked = true; _reject_pp(service, "locked PP use", 0, id, "field_locked"); locked = false
		reject_unchanged(service, id, "foreign PP target", 0, &"foreign")
		c.current_hp = 0; _reject_pp(service, "PP item cannot revive", 0, id, "creature_knocked_out"); c.current_hp = 1
		c.battle_transform_original = {"species_id": "ditto"}
		_reject_pp(service, "temporary form rejects PP item", 0, id, "temporary_battle_state"); c.battle_transform_original.clear()
		service.owner.inventory.corrupted = true; _reject_pp(service, "corrupt bag", 0, id, "invalid_inventory"); service.owner.inventory.corrupted = false
		for move: StringName in [&"sketch", &"struggle", &"max_flare", &"splash"]:
			c.moveset[0] = BattleMoveSlot.new(move, catalogs.move(move).pp, 0); c.move_ids[0] = move
			_reject_pp(service, "unboostable or nonlearnable move " + String(move), 0, id)
		c.moveset[0] = BattleMoveSlot.new(&"tackle", 35, 0); c.move_ids[0] = &"tackle"
		var bad_slot: BattleMoveSlot = c.moveset[1]; var before_bag: Dictionary = service.owner.inventory.to_dict()
		c.moveset[1] = null
		var rejected: Dictionary = service.use_item(id, c.instance_id, 0)
		check("null unselected slot rejected before serialization", not rejected.accepted and rejected.reason == "invalid_pp_state" and is_same(service.owner.owned_creature(c.instance_id), c) and c.moveset[1] == null and service.owner.inventory.to_dict() == before_bag)
		c.moveset[1] = bad_slot; c.move_ids[0] = &"reflect"
		_reject_pp(service, "inconsistent move identity", 0, id, "invalid_pp_state")
		c.move_ids[0] = &"tackle"
		check("pure helper rejects unknown item", not Effects.PPBoost.apply(c, &"rare_candy", 0, catalogs).accepted)
		check("pure helper rejects missing definitions", not Effects.PPBoost.apply(c, id, 0, null).accepted)
		check("pure helper rejects missing creature", not Effects.PPBoost.apply(null, id, 0, catalogs).accepted)
		check("fresh move resets PP upgrades", c.replace_move(&"tackle", &"ember", catalogs) and c.moveset[0].max_pp == 25 and c.moveset[0].current_pp == 25)
		check("relearned move starts first PP stage", service.use_item(id, c.instance_id, 0).accepted and service.owner.owned_creature(c.instance_id).moveset[0].max_pp == (40 if id == &"pp_max" else 30))

func _drain_pp(view: Control) -> void:
	var count := 0
	while view._playback.is_playing() and count < 2000:
		view._playback.advance(0.25); count += 1
	await process_frame; await process_frame
	check("PP native playback completes", not view._playback.is_playing())

func _test_real_pp() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100; config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var c: CreatureInstance = create(owner.party.get_creatures()[0].instance_id); _four_slots(c)
	c.moveset[0].current_pp = 0; c.friendship = 99; c.ability_id = &""
	check("real PP target setup", owner.replace_owned_same_identity(c))
	for id: StringName in [&"pp_up", &"pp_max", &"max_ether", &"master_ball"]: owner.inventory.add(id, 3)
	check("real PP bag opens", scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	_select(bag, "pp_up")
	check("PP UI asks upgrade destination", bag._moves.visible and bag._moves.item_count == 5 and bag._moves.get_item_text(0).contains("máximos") and bag._description.text.contains("máximos"))
	var before := snapshot(bag.service)
	check("placeholder consumes nothing", not bag._apply("use").accepted and snapshot(bag.service) == before)
	bag._moves.select(1)
	check("PP Up real UI succeeds", bag._apply("use").accepted and owner.owned_creature(c.instance_id).moveset[0].max_pp == 42 and owner.owned_creature(c.instance_id).moveset[0].current_pp == 7)
	check("PP UI does not say it taught a move", bag._result.text.contains("PP máximos") and not bag._result.text.contains("aprendido"))
	_select(bag, "pp_max"); bag._moves.select(1)
	check("PP Max real UI preserves spent PP", bag._apply("use").accepted and owner.owned_creature(c.instance_id).moveset[0].max_pp == 56 and owner.owned_creature(c.instance_id).moveset[0].current_pp == 21)
	bag._moves.select(1); before = snapshot(bag.service)
	check("maxed UI action keeps bag and friendship", not bag._apply("use").accepted and snapshot(bag.service) == before and bag._result.text.contains("conserva"))
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("PP bag fits viewport", bag.position.x >= 0 and bag.position.y >= 0 and bag.position.x+bag.size.x <= root.size.x and bag.position.y+bag.size.y <= root.size.y)
		check("PP bag GPU capture", root.get_texture().get_image().save_png(OUT_V8+"pp_boost_bag.png") == OK)
	bag.hide(); await process_frame
	var bridge = scene._native_battles
	var save_path := "user://item_field_v8_gpu_test_only.json" if capture else "user://item_field_v8_test_only.json"
	bridge.save_path = save_path
	check("PP persistent field save", bridge.save_game())
	check("PP persistent field load", await bridge.load_game())
	check("PP ownership reload and UI rebind", scene.toggle_item_bag() and snapshot(bag.service) == before)
	bag.hide(); await process_frame
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view
	view._playback.set_process(false)
	check("boosted PP enters native battle", view.session != null and view.session.has_active_battle())
	if view.session != null:
		var active: CreatureInstance = view.session.battle_state().creature(c.instance_id)
		check("native receives exact current and max PP", active != null and active.moveset[0].max_pp == 56 and active.moveset[0].current_pp == 21)
		_reject_pp_real(bag.service, c.instance_id)
		check("native spends exactly one boosted PP", (await view.choose("move 1")).accepted)
		await _drain_pp(view)
		active = view.session.battle_state().creature(c.instance_id)
		check("native spent PP is retained", active.moveset[0].max_pp == 56 and active.moveset[0].current_pp == 20)
		check("active PP checkpoint saves", bridge.save_game())
		var saved: Dictionary = view.session.snapshot()
		check("active PP checkpoint loads", await bridge.load_game())
		view._playback.set_process(false)
		check("active PP checkpoint exact replay state", view.session.snapshot() == saved)
		check("capture settles PP state", (await view.adventure_command("master")).accepted)
		await _drain_pp(view)
		var settled: CreatureInstance = scene.field_collection().owned_creature(c.instance_id)
		check("settlement preserves boosted PP", settled.moveset[0].max_pp == 56 and settled.moveset[0].current_pp == 20)
		await bridge.leave_battle()
		check("settled PP save and reload", bridge.save_game() and await bridge.load_game())
		check("settled PP survives field restore", scene.toggle_item_bag() and bag.service.owner.owned_creature(c.instance_id).moveset[0].max_pp == 56 and bag.service.owner.owned_creature(c.instance_id).moveset[0].current_pp == 20)
		_select(bag, "max_ether"); bag._moves.select(1)
		check("PP restoration uses upgraded maximum", bag._apply("use").accepted and bag.service.owner.owned_creature(c.instance_id).moveset[0].current_pp == 56)
		bag.hide(); await process_frame
		if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func _reject_pp_real(service: RefCounted, id: StringName) -> void:
	var before := snapshot(service)
	var result: Dictionary = service.use_item(&"pp_up", id, 1)
	check("PP item locked during battle", not result.accepted and result.reason == "field_locked" and snapshot(service) == before)
