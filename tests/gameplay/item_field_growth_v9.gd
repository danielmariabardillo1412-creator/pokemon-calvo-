extends "res://tests/gameplay/item_field_effects_v4.gd"

const Growth = preload("res://modules/inventory/field_growth_effects.gd")
const Flow = preload("res://modules/inventory/field_growth_transaction.gd")
const Variants = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const V9 := "res://.godot/item_field_v9/"
const XP := {"exp_candy_xs": 100, "exp_candy_s": 800, "exp_candy_m": 3000, "exp_candy_l": 10000, "exp_candy_xl": 30000}
var matrix_cases := 0
var tables: Dictionary

func _make(species_id: StringName, level: int, identity: StringName = &"growth_target") -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 78
	var c := CreatureFactory.create(catalogs.species(species_id), level, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": identity, "nature_id": "hardy", "ivs": {"hp": 0, "attack": 0, "defense": 0, "speed": 0, "special_attack": 0, "special_defense": 0},
		"moves": ["tackle", "growl", "reflect", "protect"]})
	c.friendship = 99
	return c

func _service(c: CreatureInstance, item: StringName = &"rare_candy") -> RefCounted:
	var collection := PlayerCollection.new(); collection.party.add_creature(c); collection.inventory.add(item, 3)
	var service := Service.new(); service.configure(collection, catalogs, func(): return not locked)
	return service

func _resolve(source: CreatureInstance, item: StringName, policy: RefCounted) -> Dictionary:
	var decisions: Dictionary = {}
	for attempt in 120:
		var result := Growth.plan(source, item, catalogs, policy, decisions)
		if result.status != "NEEDS_CONTEXT": return result
		decisions[result.prompt.key] = -1 if result.prompt.kind == "move" else ""
	return {"accepted": false, "status": "REJECTED", "reason": "test_decision_loop"}

func _expected_level(curve: String, experience: int) -> int:
	var values: Array = tables[curve].levels_1_to_100
	var level := 1
	for i in 100:
		if int(values[i]) <= experience: level = i + 1
	return level

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V9)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay for candy matrix", Variants.apply(catalogs))
	tables = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/progression_growth_curves/reference_contract.json")).tables
	_matrix()
	_owned_matrix()
	_boundaries()
	_decisions()
	await _real_ui()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"matrix_cases": matrix_cases, "gpu": capture}
	var file := FileAccess.open(V9 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true
	print("ITEM_FIELD_V9 ", report.status, " checks=", checks, " cases=", matrix_cases, " GPU=", capture)
	quit(0 if errors.is_empty() else 1)

func _matrix() -> void:
	var policy: RefCounted = _service(_make(&"mew", 50)).content
	for id: String in catalogs.variant_allowed_species:
		var c := _make(StringName(id), 50)
		c.experience += 17; c.current_hp -= 9
		c.moveset[0].max_pp = 56; c.moveset[0].current_pp = 13
		var before := JSON.stringify(c.to_dict())
		var values: Array = tables[catalogs.species(c.species_id).growth_rate].levels_1_to_100
		for item: String in XP.keys() + ["rare_candy"]:
			var expected_xp := mini(int(values[99]), c.experience + int(XP.get(item, 0))) if item != "rare_candy" else int(values[50])
			var result := _resolve(c, StringName(item), policy)
			check("matrix applies " + id + "/" + item, result.accepted)
			if not result.accepted: continue
			var after: CreatureInstance = result.candidate
			check("independent XP/level table " + id + "/" + item, after.experience == expected_xp and after.level == _expected_level(catalogs.species(c.species_id).growth_rate, expected_xp))
			check("no source mutation " + id, JSON.stringify(c.to_dict()) == before)
			check("HP deficit and friendship " + id, after.stats.max_hp - after.current_hp == 9 and after.friendship == 104)
			check("PP/identity/shiny/IV/EV unchanged " + id, after.moveset[0].to_dict() == c.moveset[0].to_dict() and after.instance_id == c.instance_id and after.ivs == c.ivs and after.evs == c.evs and after.is_shiny == c.is_shiny)
			matrix_cases += 1
	check("all eligible species and six items", matrix_cases == 1076 * 6)

func _boundaries() -> void:
	var seen: Dictionary = {}
	for id: StringName in catalogs.species_catalog.all_ids():
		var curve := catalogs.species(id).growth_rate
		if seen.has(curve) or not catalogs.variant_allowed_species.has(String(id)): continue
		seen[curve] = true
		for level: int in [1, 99, 100]:
			for item: String in XP.keys() + ["rare_candy"]:
				var c := _make(id, level); c.held_item_id = &"everstone"
				var service := _service(c, StringName(item)); var before := snapshot(service)
				var result := _resolve(c, StringName(item), service.content)
				check("cap eligibility " + curve + item, result.accepted == (level < 100))
				check("pure boundary no changes", snapshot(service) == before)
				if result.accepted:
					var after: CreatureInstance = result.candidate
					var values: Array = tables[curve].levels_1_to_100
					var expected_xp := int(values[level]) if item == "rare_candy" else mini(int(values[99]), int(values[level-1]) + int(XP[item]))
					check("cap/oracle " + curve + item, after.experience == expected_xp and after.level == _expected_level(curve, expected_xp))
	var c := _make(&"mew", 50); var service := _service(c)
	c.experience = 0
	check("reject mismatched XP", service.use_item(&"rare_candy", c.instance_id).get("reason") == "inconsistent_level_experience")
	c.experience = ProgressionRuleset.experience_for_level(catalogs.species(&"mew").growth_rate, 50)
	check("inventory used once", service.use_item(&"rare_candy", c.instance_id).accepted and service.owner.inventory.quantity(&"rare_candy") == 2)
	var owned: CreatureInstance = service.owner.owned_creature(c.instance_id); owned.current_hp = 0
	var before := snapshot(service)
	check("no revival", not service.use_item(&"rare_candy", c.instance_id).accepted and snapshot(service) == before)
	owned.current_hp = 1; locked = true; before = snapshot(service)
	check("locked no consume", service.use_item(&"rare_candy", c.instance_id).reason == "field_locked" and snapshot(service) == before)
	locked = false
	c = _make(&"mew", 50); service = _service(c)
	var slot: BattleMoveSlot = c.moveset[0]; c.moveset[0] = null
	check("null slot rejected before serialization", service.use_item(&"rare_candy", c.instance_id).reason == "invalid_pp_state" and service.owner.inventory.quantity(&"rare_candy") == 3)
	c.moveset[0] = slot; c.ivs["attack"] = -1
	check("IV not silently repaired", not service.use_item(&"rare_candy", c.instance_id).accepted and c.ivs.attack == -1)
	c = _make(&"eevee", 100); service = _service(c)
	before = snapshot(service)
	check("conditional evolution deferred explicitly", service.use_item(&"rare_candy", c.instance_id).status == "DEPENDENCY_MISSING" and snapshot(service) == before)

func _owned_matrix() -> void:
	for item: String in XP.keys() + ["rare_candy"]:
		for stored: bool in [false, true]:
			for friendship: int in [0, 99, 100, 199, 200, 254, 255]:
				for bell in 3:
					var c := _make(&"mew", 50); c.friendship = friendship; c.current_hp -= 3
					status(c, &"sleep")
					if bell > 0: c.held_item_id = &"soothe_bell"; c.held_item_consumed = bell == 2
					var service := _service(c, StringName(item))
					service.sleep_clocks[String(c.instance_id)] = {"start_time": 3, "time": 2, "version": "0.10.11"}
					var clocks: Dictionary = service.sleep_clocks.duplicate(true)
					if stored: service.owner.deposit(c.instance_id)
					var before := c.to_dict()
					var result: Dictionary = service.use_item(StringName(item), c.instance_id)
					check("owned growth applies " + item, result.accepted)
					var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
					var gain: int = [5, 3, 2][mini(2, friendship / 100)]
					if bell == 1: gain = gain * 3 / 2
					check("friendship thresholds/bell " + item, after.friendship == mini(255, friendship + gain))
					check("one item and staged ownership " + item, service.owner.inventory.quantity(StringName(item)) == 2 and not is_same(c, after) and c.to_dict() == before)
					check("sleep clock/PP/location persist " + item, service.sleep_clocks == clocks and after.moveset[0].to_dict() == c.moveset[0].to_dict() and service.owner.location_of(c.instance_id) == (&"STORAGE" if stored else &"PARTY"))

func _decisions() -> void:
	var c := _make(&"bulbasaur", 11); var service := _service(c)
	var flow := Flow.new(); var before := snapshot(service)
	var pending: Dictionary = flow.begin(service, &"rare_candy", c.instance_id)
	check("learning prompt has actual slots", pending.status == "NEEDS_CONTEXT" and pending.prompt.kind == "move" and pending.prompt.move_id == "razor_leaf" and pending.prompt.slots.size() == 4)
	check("pending does not publish", snapshot(service) == before)
	flow.cancel(); check("cancel preserves everything", snapshot(service) == before)
	flow.begin(service, &"rare_candy", c.instance_id)
	var result: Dictionary = flow.choose(1)
	var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
	check("chosen slot replaced, XP and item published once", result.accepted and after.level == 12 and after.move_ids[1] == &"razor_leaf" and after.moveset[1].current_pp == catalogs.move(&"razor_leaf").pp and service.owner.inventory.quantity(&"rare_candy") == 2)
	check("original candidate stays untouched", c.level == 11 and c.move_ids[1] == &"growl")
	check("completed flow cannot replay", not flow.choose(0).accepted and service.owner.inventory.quantity(&"rare_candy") == 2)
	for mutation in 7:
		c = _make(&"bulbasaur", 11); service = _service(c); flow.begin(service, &"rare_candy", c.instance_id)
		match mutation:
			0: service.owner.inventory.add(&"potion")
			1: c.friendship += 1
			2: service.owner.replace_owned_same_identity(CreatureInstance.from_dict(c.to_dict()))
			3: service.configure(service.owner, catalogs, func(): return true, service.sleep_clocks)
			4: service.sleep_clocks = {}
			5: service.owner.deposit(c.instance_id)
			6: service.owner.inventory = PlayerInventory.from_dict(service.owner.inventory.to_dict())
		before = snapshot(service)
		check("stale pending rejects without mutation " + str(mutation), not flow.choose(0).accepted and snapshot(service) == before)
	c = _make(&"bulbasaur", 15); service = _service(c); before = snapshot(service)
	pending = flow.begin(service, &"rare_candy", c.instance_id)
	check("evolution explicit", pending.status == "NEEDS_CONTEXT" and pending.prompt.kind == "evolution" and pending.prompt.targets == ["ivysaur"])
	result = flow.choose("")
	check("decline evolution keeps earned level", result.accepted and service.owner.owned_creature(c.instance_id).species_id == &"bulbasaur" and service.owner.owned_creature(c.instance_id).level == 16)
	c = _make(&"bulbasaur", 100); service = _service(c); before = snapshot(service)
	pending = flow.begin(service, &"rare_candy", c.instance_id)
	check("level 100 rare candy can offer level evolution", pending.status == "NEEDS_CONTEXT")
	result = flow.choose("")
	check("level 100 decline has no effect", not result.accepted and result.reason == "item_has_no_effect" and snapshot(service) == before)
	flow.begin(service, &"rare_candy", c.instance_id); result = flow.choose("ivysaur")
	for attempt in 20:
		if result.status != "NEEDS_CONTEXT": break
		result = flow.choose(-1)
	check("level 100 evolution and no free friendship", result.accepted and service.owner.owned_creature(c.instance_id).species_id == &"ivysaur" and service.owner.owned_creature(c.instance_id).friendship == 99)
	c = _make(&"bulbasaur", 11); service = _service(c); flow.begin(service, &"rare_candy", c.instance_id); before = snapshot(service)
	check("invalid choice no consume", not flow.choose(99).accepted and snapshot(service) == before)
	c = _make(&"tyrogue", 19); c.current_hp -= 3; service = _service(c); before = snapshot(service)
	pending = flow.begin(service, &"rare_candy", c.instance_id)
	check("Tyrogue exact equal-stat branch", pending.status == "NEEDS_CONTEXT" and pending.prompt.targets == ["hitmontop"])
	result = flow.choose("hitmontop")
	check("evolution-specific level-zero move asks replacement", result.status == "NEEDS_CONTEXT" and result.prompt.kind == "move" and result.prompt.move_id == "triple_kick" and snapshot(service) == before)
	result = flow.choose(2); after = service.owner.owned_creature(c.instance_id)
	check("whole evolution transaction publishes once", result.accepted and after.species_id == &"hitmontop" and after.move_ids[2] == &"triple_kick" and after.stats.max_hp - after.current_hp == 3 and after.friendship == 104 and service.owner.inventory.quantity(&"rare_candy") == 2)
	c = _make(&"bulbasaur", 11); service = _service(c, &"exp_candy_xl"); before = snapshot(service)
	pending = flow.begin(service, &"exp_candy_xl", c.instance_id)
	var prompts := 0
	while pending.status == "NEEDS_CONTEXT" and prompts < 100:
		check("multi-level pending stays atomic", snapshot(service) == before)
		pending = flow.choose(-1 if pending.prompt.kind == "move" else "")
		prompts += 1
	check("large candy crosses levels with explicit choices", pending.accepted and prompts > 3 and service.owner.owned_creature(c.instance_id).experience == c.experience + 30000 and service.owner.inventory.quantity(&"exp_candy_xl") == 2)

func _real_ui() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100; config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var identity := owner.party.get_creatures()[0].instance_id
	check("real growth target", owner.replace_owned_same_identity(_make(&"bulbasaur", 11, identity)))
	owner.inventory.add(&"rare_candy", 4); owner.inventory.add(&"exp_candy_xs", 2); owner.inventory.add(&"master_ball", 2)
	check("real growth bag opens", scene.toggle_item_bag())
	var bag = scene._item_bag
	_select(bag, "rare_candy")
	var before := snapshot(bag.service)
	var result: Dictionary = bag._apply("use")
	check("real UI decision visible and source unchanged", result.status == "NEEDS_CONTEXT" and bag._growth_choices.visible and snapshot(bag.service) == before and bag._use.disabled)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("growth UI fits screen", bag.position.x >= 0 and bag.position.y >= 0 and bag.position.y + bag.size.y <= root.size.y)
		check("growth prompt capture", root.get_texture().get_image().save_png(V9+"growth_choice.png") == OK)
	bag._growth_choices.cancelled.emit()
	check("UI cancel preserves source", snapshot(bag.service) == before and not bag._growth_choices.visible)
	bag._apply("use")
	bag._growth_choices._options.select(3); bag._growth_choices._options.item_selected.emit(3)
	bag._growth_choices._confirm.pressed.emit()
	check("UI actual selected replacement", owner.owned_creature(identity).level == 12 and owner.owned_creature(identity).move_ids[1] == &"razor_leaf")
	var bridge = scene._native_battles
	bag.hide(); await process_frame
	bridge.save_path = "user://item_growth_v9_gpu_only.json" if capture else "user://item_growth_v9_test_only.json"
	check("growth native save", bridge.save_game())
	check("growth native load", await bridge.load_game())
	owner = scene.field_collection()
	check("growth state persisted", owner.owned_creature(identity).level == 12 and owner.owned_creature(identity).move_ids[1] == &"razor_leaf")
	check("reopen after rebinding", scene.toggle_item_bag())
	bag = scene._item_bag; _select(bag, "exp_candy_xs")
	var old_xp := owner.owned_creature(identity).experience
	result = bag._apply("use")
	check("EXP candy through real bag", result.accepted and owner.owned_creature(identity).experience == old_xp + 100)
	bag.hide(); await process_frame
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view
	view._playback.set_process(false)
	check("grown creature reaches native worker", view.session != null and view.session.has_active_battle() and view.session.battle_state().creature(identity).level == 12)
	if view.session != null and view.session.has_active_battle():
		check("native checkpoint after growth", bridge.save_game())
		check("native checkpoint restore after growth", await bridge.load_game())
		view._playback.set_process(false)
		check("native capture after growth", (await view.adventure_command("master")).accepted)
		for attempt in 2000:
			if not view._playback.is_playing(): break
			view._playback.advance(0.25)
		await process_frame; await bridge.leave_battle()
		check("post-capture growth state saves", bridge.save_game() and await bridge.load_game())
		if view.session != null: await view.session.close()
	var path: String = ProjectSettings.globalize_path(bridge.save_path)
	scene.queue_free(); await process_frame
	if path.begins_with(ProjectSettings.globalize_path("user://")): DirAccess.remove_absolute(path)
