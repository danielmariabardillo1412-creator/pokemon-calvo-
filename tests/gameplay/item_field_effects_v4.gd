extends SceneTree

const Service = preload("res://modules/inventory/field_item_service.gd")
const Effects = preload("res://modules/inventory/field_item_effects.gd")
const Saves = preload("res://modules/save/field_native_save.gd")
const OUT := "res://.godot/item_field_v4/"
const HEAL := {"potion": 20, "super_potion": 60, "hyper_potion": 120, "max_potion": 9999, "full_restore": 9999}
const CURE := {"antidote": "badly_poisoned", "burn_heal": "burn", "ice_heal": "freeze", "awakening": "sleep", "paralyze_heal": "paralysis", "full_heal": "poison", "full_restore": "poison"}
const BERRIES := {"pomeg_berry": "hp", "kelpsy_berry": "attack", "qualot_berry": "defense", "hondew_berry": "special_attack", "grepa_berry": "special_defense", "tamato_berry": "speed"}
var catalogs: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var locked := false
var rows: Array = []
var scene: Node2D
var capture := false
var done := false


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(180).timeout.connect(func():
		if not done: push_error("ITEM_FIELD_V4 watchdog"); quit(2))


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)


func create(id: StringName = &"field_item_target") -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 37
	return CreatureFactory.create(catalogs.species(&"mew"), 100, catalogs, ProgressionRuleset.new(), rng, {"instance_id": id, "nature_id": "hardy", "ivs": {"hp": 31, "attack": 31, "defense": 31, "special_attack": 31, "special_defense": 31, "speed": 31}, "moves": ["tackle", "reflect"]})


func service_for() -> RefCounted:
	var owner := PlayerCollection.new(); owner.party.add_creature(create())
	var service := Service.new()
	check("configure field service", service.configure(owner, catalogs, func(): return not locked))
	return service


func snapshot(service: RefCounted) -> String:
	var creatures: Array = []
	for c: CreatureInstance in service.owner.party.get_creatures() + service.owner.storage.get_all_creatures(): creatures.append(c.to_dict())
	return JSON.stringify({"creatures": creatures, "bag": service.owner.inventory.to_dict(), "clocks": service.sleep_clocks})


func status(creature: CreatureInstance, id: StringName) -> void:
	creature.status_state.persistent_id = id; creature.status_ids.assign([id])
	creature.status_state.turns_remaining = 2 if id == &"sleep" else 0
	creature.status_state.toxic_counter = 3 if id == &"badly_poisoned" else 0
	creature.status_state.rest_sleep = id == &"sleep"


func reject_unchanged(service: RefCounted, id: StringName, label: String, slot := -1, target := &"field_item_target") -> void:
	var before := snapshot(service)
	var result: Dictionary = service.use_item(id, target, slot)
	check(label, not result.accepted and snapshot(service) == before)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	_test_medicines()
	_test_status_matrix()
	_test_berries()
	_test_boundaries()
	await _test_real_bag_and_save()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "rows": rows, "gpu": capture}
	var file := FileAccess.open(OUT + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_FIELD_V4 ", report.status, " checks=", checks, " cases=", rows.size(), " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func _test_medicines() -> void:
	var ids: Array = HEAL.keys() + ["antidote", "burn_heal", "ice_heal", "awakening", "paralyze_heal", "full_heal", "ether", "max_ether", "elixir", "max_elixir"]
	check("15 medicine IDs", ids.size() == 15)
	for raw_id: String in ids:
		var id := StringName(raw_id)
		for location: String in ["PARTY", "STORAGE"]:
			var service := service_for()
			var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
			if HEAL.has(raw_id): c.current_hp -= 150
			if CURE.has(raw_id): status(c, StringName(CURE[raw_id])); c.status_state.add_volatile(&"nightmare")
			if raw_id == "awakening": service.sleep_clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
			var is_pp: bool = raw_id in ["ether", "max_ether", "elixir", "max_elixir"]
			if is_pp:
				c.moveset[0].current_pp = 0; c.moveset[1].current_pp = 2
				# Existing boosted PP must remain the authority.
				c.moveset[0].max_pp = 56
			var before := c.to_dict()
			var old_hp := c.current_hp
			if location == "STORAGE": check("deposit test target", service.owner.deposit(c.instance_id))
			service.owner.inventory.add(id, 2)
			var slot := 0 if raw_id in ["ether", "max_ether"] else -1
			check("medicine applies " + raw_id + location, service.use_item(id, c.instance_id, slot).accepted)
			var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
			check("consume one/owned identity " + raw_id + location, service.owner.inventory.quantity(id) == 1 and after != c and after.instance_id == c.instance_id and service.owner.location_of(c.instance_id) == StringName(location))
			check("staged source not mutated " + raw_id, c.to_dict() == before)
			check("persistent stats unchanged " + raw_id, after.stats.to_dict() == c.stats.to_dict() and after.ivs == c.ivs and after.evs == c.evs and after.nature_id == c.nature_id and after.friendship == c.friendship and after.ability_id == c.ability_id)
			if HEAL.has(raw_id): check("HP amount " + raw_id, after.current_hp == mini(c.stats.max_hp, old_hp + int(HEAL[raw_id])))
			if CURE.has(raw_id): check("status counters cured " + raw_id, after.status_state.persistent_id == &"" and after.status_ids.is_empty() and after.status_state.turns_remaining == 0 and after.status_state.toxic_counter == 0 and not after.status_state.rest_sleep and not after.status_state.has_volatile(&"nightmare"))
			if raw_id == "awakening": check("native sleep clock removed", service.sleep_clocks.is_empty())
			if is_pp:
				var full: bool = raw_id.begins_with("max_")
				check("PP amount/boosted maximum " + raw_id, after.moveset[0].current_pp == (56 if full else 10) and after.moveset[0].max_pp == 56)
				check("one/all slot isolation " + raw_id, after.moveset[1].current_pp == (c.moveset[1].max_pp if full else mini(c.moveset[1].max_pp, 12)) if raw_id in ["elixir", "max_elixir"] else after.moveset[1].current_pp == 2)
			rows.append({"id": raw_id, "context": location, "status": "FIELD_EFFECT_AND_CONSUMPTION_PASS"})
		# Healthy/no-op target never spends the item.
		var service := service_for(); service.owner.inventory.add(id)
		reject_unchanged(service, id, "no effect preserves " + raw_id, 0 if raw_id in ["ether", "max_ether"] else -1)
		if raw_id in ["ether", "max_ether"]:
			service.owner.owned_creature(&"field_item_target").moveset[0].current_pp = 0
			for invalid: int in [-2, -1, 2, 999]: reject_unchanged(service, id, "invalid PP target " + str(invalid), invalid)
		else: reject_unchanged(service, id, "unexpected PP selection " + raw_id, 0)
		service.owner.owned_creature(&"field_item_target").current_hp = 0
		reject_unchanged(service, id, "never revive " + raw_id, 0 if raw_id in ["ether", "max_ether"] else -1)
		service.owner.owned_creature(&"field_item_target").current_hp = 1
		locked = true; reject_unchanged(service, id, "locked field " + raw_id); locked = false
		reject_unchanged(service, id, "foreign target " + raw_id, -1, &"foreign")


func _test_status_matrix() -> void:
	for item_id: String in CURE:
		for condition: String in ["burn", "poison", "badly_poisoned", "paralysis", "sleep", "freeze"]:
			var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
			status(c, StringName(condition)); c.status_state.add_volatile(&"substitute", {"hp": 10})
			service.owner.inventory.add(StringName(item_id))
			var before := snapshot(service)
			var expected: bool = item_id in ["full_heal", "full_restore"] or condition == CURE[item_id] or item_id == "antidote" and condition == "poison"
			var result: Dictionary = service.use_item(StringName(item_id), c.instance_id)
			check("cure specificity " + item_id + condition, result.accepted == expected)
			if expected:
				var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
				check("unrelated volatile retained " + item_id + condition, after.status_state.persistent_id == &"" and after.status_state.has_volatile(&"substitute"))
			else: check("wrong cure atomic " + item_id + condition, snapshot(service) == before)
	for item_id: String in ["full_heal", "full_restore"]:
		var service := service_for(); service.owner.inventory.add(StringName(item_id))
		service.owner.owned_creature(&"field_item_target").status_state.add_volatile(&"confusion", {"turns": 3})
		check("confusion-only effect " + item_id, service.use_item(StringName(item_id), &"field_item_target").accepted and not service.owner.owned_creature(&"field_item_target").status_state.has_volatile(&"confusion"))


func _test_berries() -> void:
	for raw_id: String in BERRIES:
		var stat: String = BERRIES[raw_id]
		for friendship: int in [0, 99, 100, 199, 200, 254, 255]:
			for ev: int in [0, 7, 10, 252]:
				var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
				c.friendship = friendship; c.evs[stat] = ev; c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new()); c.current_hp = c.stats.max_hp
				var before := c.to_dict(); service.owner.inventory.add(StringName(raw_id), 2)
				var old := snapshot(service)
				var result: Dictionary = service.use_item(StringName(raw_id), c.instance_id)
				var expected: bool = ev > 0 or friendship < 255
				check("berry eligibility " + raw_id + str(friendship) + "/" + str(ev), result.accepted == expected)
				if not expected:
					check("capped no-op preserves berry", snapshot(service) == old); continue
				var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
				check("berry EV -10 lower bound " + raw_id, after.evs[stat] == maxi(0, ev - 10))
				var stat_key := "max_hp" if stat == "hp" else stat
				var golden_stat: int = (341 if stat == "hp" else 236) + maxi(0, ev - 10) / 4
				check("level-100 Hardy Mew golden stat " + raw_id, int(after.stats.to_dict()[stat_key]) == golden_stat)
				var gain := 10 if friendship < 100 else 5 if friendship < 200 else 2
				check("berry friendship thresholds " + raw_id, after.friendship == mini(255, friendship + gain))
				check("berry consumes exactly one " + raw_id, service.owner.inventory.quantity(StringName(raw_id)) == 1)
				var expected_evs: Dictionary = c.evs.duplicate(); expected_evs[stat] = maxi(0, ev - 10)
				check("only selected EV changed " + raw_id, after.evs == expected_evs and after.ivs == c.ivs and after.level == c.level and after.nature_id == c.nature_id and after.move_ids == c.move_ids and after.ability_id == c.ability_id)
				check("full health follows new maximum", after.current_hp == after.stats.max_hp and c.to_dict() == before)
				rows.append({"id": raw_id, "context": "EV_%d_FRIENDSHIP_%d" % [ev, friendship], "status": "FIELD_TRAINING_PASS"})
		var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
		c.held_item_id = &"soothe_bell"; c.friendship = 100
		service.owner.inventory.add(StringName(raw_id), 3)
		check("Soothe Bell applies floor multiplier", service.use_item(StringName(raw_id), c.instance_id).accepted and service.owner.owned_creature(c.instance_id).friendship == 107)
		service.owner.owned_creature(c.instance_id).held_item_consumed = true
		check("consumed bell gives no bonus", service.use_item(StringName(raw_id), c.instance_id).accepted and service.owner.owned_creature(c.instance_id).friendship == 112)
		service.owner.owned_creature(c.instance_id).current_hp = 0
		reject_unchanged(service, StringName(raw_id), "training cannot revive")
	for hp: int in [1, 2, 200]:
		var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
		c.evs.hp = 252; c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new()); c.current_hp = hp
		service.owner.inventory.add(&"pomeg_berry")
		check("Pomeg application", service.use_item(&"pomeg_berry", c.instance_id).accepted)
		check("Pomeg HP deficit without KO " + str(hp), service.owner.owned_creature(c.instance_id).current_hp == maxi(1, hp - 3))


func _test_boundaries() -> void:
	for id: StringName in [&"revive", &"max_revive", &"revival_herb", &"sacred_ash", &"wide_lens", &"bright_powder"]:
		var service := service_for(); service.owner.inventory.add(id)
		reject_unchanged(service, id, "excluded item cannot bypass policy " + String(id))
	var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target"); c.current_hp = 1
	reject_unchanged(service, &"potion", "missing item")
	service.owner.inventory.add(&"potion"); service.owner.inventory.corrupted = true
	reject_unchanged(service, &"potion", "corrupt inventory")
	service.owner.inventory.corrupted = false
	c.battle_transform_original = {"species_id": "eevee"}
	reject_unchanged(service, &"potion", "temporary battle overlay")
	c.battle_transform_original.clear(); service.owner.storage.add_creature(CreatureInstance.from_dict(c.to_dict()))
	reject_unchanged(service, &"potion", "ambiguous ownership")
	service = service_for(); service.owner.inventory.add(&"pomeg_berry")
	service.owner.owned_creature(&"field_item_target").friendship = -1
	reject_unchanged(service, &"pomeg_berry", "invalid friendship")


func _select(bag: Control, item_id: String) -> void:
	for index: int in bag._items.item_count:
		if bag._items.get_item_metadata(index) == item_id: bag._items.select(index); bag._refresh_choices(); return
	check("bag contains " + item_id, false)


func _test_real_bag_and_save() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	check("real field ready", scene.is_demo_ready())
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene._session.player
	var first: CreatureInstance = owner.party.get_creatures()[0]
	var c := create(first.instance_id); c.evs.hp = 252; c.recalculate_stats(catalogs.species(&"mew"), ProgressionRuleset.new()); c.current_hp = 200
	status(c, &"sleep")
	check("UI owned setup", owner.replace_owned_same_identity(c))
	scene._native_battles.clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2}
	for id: StringName in [&"awakening", &"potion", &"ether", &"pomeg_berry"]: owner.inventory.add(id, 2)
	check("B opens existing bag", scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	_select(bag, "awakening")
	check("bag uses Awakening", bag._apply("use").accepted and scene._native_battles.clocks.is_empty())
	_select(bag, "potion")
	check("bag uses Potion with PS feedback", bag._apply("use").accepted and owner.owned_creature(c.instance_id).current_hp == 220 and bag._targets.get_item_text(0).contains("PS 220/"))
	owner.owned_creature(c.instance_id).moveset[0].current_pp = 0
	_select(bag, "ether")
	var before := snapshot(bag.service)
	check("bag Ether requires selected move", bag._moves.visible and not bag._apply("use").accepted and snapshot(bag.service) == before)
	bag._moves.select(1)
	check("bag Ether restores selected PP", bag._apply("use").accepted and owner.owned_creature(c.instance_id).moveset[0].current_pp == 10)
	_select(bag, "pomeg_berry")
	check("bag Pomeg updates persistent EV and HP", bag._apply("use").accepted and owner.owned_creature(c.instance_id).evs.hp == 242 and owner.owned_creature(c.instance_id).current_hp == 217)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("bag fits viewport", bag.position.x >= 0 and bag.position.y >= 0 and bag.position.x + bag.size.x <= scene.get_viewport_rect().size.x and bag.position.y + bag.size.y <= scene.get_viewport_rect().size.y)
		check("GPU screenshot", root.get_texture().get_image().save_png(OUT + "field_medicine_bag.png") == OK)
	bag.hide(); await process_frame
	var path := "user://item_field_v4_gpu_test_only.json" if capture else "user://item_field_v4_test_only.json"
	scene._native_battles.save_path = path
	before = snapshot(bag.service)
	check("real campaign save after field medicine/training", scene._native_battles.save_game())
	check("real campaign loads", await scene._native_battles.load_game())
	check("bag rebinds loaded owner/clocks", scene.toggle_item_bag() and bag.service.owner == scene._session.player and snapshot(bag.service) == before)
	bag.hide(); await process_frame
	# Start the actual map backend using the edited stats/PP and cured sleep state.
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	check("field-edited creature enters native battle", scene._native_battles.view.session != null and scene._native_battles.view.session.has_active_battle())
	if scene._native_battles.view.session != null:
		var native: RefCounted = scene._native_battles.view.session
		var active: CreatureInstance = native.battle_state().creature(c.instance_id)
		check("native receives corrected stats HP PP status", active != null and active.current_hp == 217 and active.evs.hp == 242 and active.moveset[0].current_pp == 10 and active.status_state.persistent_id == &"")
		reject_unchanged(bag.service, &"potion", "field medicine locked during native battle", -1, c.instance_id)
		await native.close()
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
