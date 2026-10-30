extends "res://tests/gameplay/item_field_effects_v4.gd"

const OUT_IMPORT := "res://.godot/item_import_v19_validation/"
const PERSISTENT := {"par": "paralysis", "brn": "burn", "frz": "freeze", "slp": "sleep", "psn": "poison", "tox": "badly_poisoned"}
var reference: Dictionary = {}


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_IMPORT)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	# Independent accepted contracts stay immutable; do not use the generated
	# manifest as the expected result for the runtime that consumes that manifest.
	reference = JSON.parse_string(FileAccess.get_file_as_string("res://modules/inventory/field_recovery_profile.json")).items
	reference.merge(JSON.parse_string(FileAccess.get_file_as_string("res://modules/inventory/battle_medicine_profile.json")).items)
	reference.merge({"energy_powder": {"heal": 60, "friendship_loss": [5, 5, 10]}, "energy_root": {"heal": 120, "friendship_loss": [10, 10, 15]}, "heal_powder": {"cure": "all", "confusion": true, "friendship_loss": [5, 5, 10]}, "blue_flute": {"cure": ["slp"]}})
	check("42 compiled runtime routes", Effects.imported_recovery_items().size() == 42 and reference.size() == 42)
	for id: String in reference:
		test_route(id)
		test_specificity(id)
	test_herb_tiers()
	for id: StringName in [&"red_flute", &"yellow_flute", &"persim_berry", &"revive", &"escape_rope", &"unknown_item"]:
		check("no inferred recovery " + String(id), not Effects.recovery_supports(id))
	var exposed := Effects.imported_recovery_items(); exposed["potion"].effect.heal = 999; exposed.clear()
	check("exposed copy cannot revoke runtime", Effects.supports(&"potion") and Effects.imported_recovery_items().potion.effect.heal == 20)
	await real_batch()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "ids": reference.keys(), "gpu": capture}
	var file := FileAccess.open(OUT_IMPORT + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_IMPORT_V19 ", report.status, " checks=", checks, " ids=", reference.size(), " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func prepare(c: CreatureInstance, id: String) -> void:
	var spec: Dictionary = reference[id]
	if spec.has("heal"): c.current_hp = 1
	if spec.has("cure"):
		var condition: String = "sleep" if spec.cure is String else PERSISTENT[spec.cure[0]]
		status(c, StringName(condition)); c.status_state.add_volatile(&"nightmare")
	if spec.get("confusion", false): c.status_state.add_volatile(&"confusion", {"turns": 3})
	if spec.has("pp"):
		for move: BattleMoveSlot in c.moveset: move.current_pp = 0
	c.friendship = 205


func check_effect(id: String, before: CreatureInstance, after: CreatureInstance) -> void:
	var spec: Dictionary = reference[id]
	var hp: int = before.current_hp
	if spec.has("heal"):
		var amount: int = before.stats.max_hp if spec.heal is String else int(spec.heal)
		if spec.heal is String and spec.heal == "quarter": amount = maxi(1, before.stats.max_hp / 4)
		hp = mini(before.stats.max_hp, hp + amount)
	check("exact reference HP " + id, after.current_hp == hp)
	check("exact reference status " + id, after.status_state.persistent_id == (&"" if spec.has("cure") else before.status_state.persistent_id))
	check("exact reference confusion " + id, after.status_state.has_volatile(&"confusion") == (before.status_state.has_volatile(&"confusion") and not spec.get("confusion", false)))
	for i: int in before.moveset.size():
		var pp: int = before.moveset[i].current_pp
		if spec.has("pp") and (spec.scope == "all" or i == 0): pp = mini(before.moveset[i].max_pp, pp + (before.moveset[i].max_pp if spec.pp is String else int(spec.pp)))
		check("exact reference PP " + id + str(i), after.moveset[i].current_pp == pp and after.moveset[i].max_pp == before.moveset[i].max_pp)
	var expected_friendship: int = before.friendship - (int(spec.friendship_loss[2]) if spec.has("friendship_loss") else 0)
	check("exact reference friendship " + id, after.friendship == expected_friendship)
	var unchanged_before := before.to_dict(); var unchanged_after := after.to_dict()
	for key: String in ["current_hp", "status_state", "status_ids", "moveset", "friendship"]:
		unchanged_before.erase(key); unchanged_after.erase(key)
	check("all unrelated persistent fields " + id, unchanged_before == unchanged_after)


func test_route(id: String) -> void:
	for storage: bool in [false, true]:
		var service := service_for(); var c: CreatureInstance = service.owner.owned_creature(&"field_item_target")
		prepare(c, id); var before := c.to_dict()
		service.sleep_clocks[String(c.instance_id)] = {"version": "0.10.11", "start_time": 3, "time": 2} if c.status_state.persistent_id == &"sleep" else {"unrelated": true}
		if storage: check("storage fixture " + id, service.owner.deposit(c.instance_id))
		service.owner.inventory.add(StringName(id), 2)
		var result: Dictionary = service.use_item(StringName(id), c.instance_id, 0 if reference[id].get("scope") == "one" else -1)
		check("accepted staged route " + id, result.accepted)
		var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
		check("original retained " + id, c.to_dict() == before and c != after)
		check("ownership retained " + id, service.owner.location_of(c.instance_id) == (&"STORAGE" if storage else &"PARTY"))
		check("consumption from source " + id, service.owner.inventory.quantity(StringName(id)) == (2 if id == "blue_flute" else 1))
		check_effect(id, c, after)
		check("sleep clock lifetime " + id, service.sleep_clocks.is_empty() if c.status_state.persistent_id == &"sleep" else service.sleep_clocks.has(String(c.instance_id)))
	var service := service_for(); service.owner.inventory.add(StringName(id), 2)
	var slot: int = 0 if reference[id].get("scope") == "one" else -1
	reject_unchanged(service, StringName(id), "no effect keeps bag " + id, slot)
	var c: CreatureInstance = service.owner.owned_creature(&"field_item_target"); prepare(c, id)
	locked = true; reject_unchanged(service, StringName(id), "live guard " + id, slot); locked = false
	reject_unchanged(service, StringName(id), "foreign owner " + id, slot, &"foreign")
	reject_unchanged(service, StringName(id), "invalid slot " + id, 999)
	c.current_hp = 0; reject_unchanged(service, StringName(id), "never revive " + id, slot)
	c.current_hp = 1; c.battle_transform_original = {"species_id": "mew"}
	reject_unchanged(service, StringName(id), "temporary state " + id, slot)
	c.battle_transform_original = {}; service.owner.inventory.remove(StringName(id), 2)
	reject_unchanged(service, StringName(id), "no item " + id, slot)


func test_specificity(id: String) -> void:
	var spec: Dictionary = reference[id]
	if not spec.has("cure"): return
	for code: String in PERSISTENT:
		var service := service_for(); service.owner.inventory.add(StringName(id))
		var c: CreatureInstance = service.owner.owned_creature(&"field_item_target"); status(c, StringName(PERSISTENT[code]))
		c.status_state.add_volatile(&"substitute", {"hp": 10}); var before := snapshot(service)
		var expected: bool = spec.cure is String or code in spec.cure
		var result: Dictionary = service.use_item(StringName(id), c.instance_id)
		check("specific status " + id + code, result.accepted == expected)
		if expected:
			check("substitute retained " + id, service.owner.owned_creature(c.instance_id).status_state.has_volatile(&"substitute"))
		else: check("wrong status atomic " + id, snapshot(service) == before)


func test_herb_tiers() -> void:
	for id: String in ["energy_powder", "energy_root", "heal_powder"]:
		for friendship: int in [0, 1, 99, 100, 199, 200, 255]:
			var service := service_for(); service.owner.inventory.add(StringName(id))
			var c: CreatureInstance = service.owner.owned_creature(&"field_item_target"); prepare(c, id); c.friendship = friendship
			var tier: int = 0 if friendship < 100 else 1 if friendship < 200 else 2
			check("herb tier applied " + id, service.use_item(StringName(id), c.instance_id).accepted)
			check("herb loss clamped " + id, service.owner.owned_creature(c.instance_id).friendship == maxi(0, friendship - int(reference[id].friendship_loss[tier])))


func real_batch() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	check("real scene ready", scene.is_demo_ready())
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var target: StringName = owner.party.get_creatures()[0].instance_id
	for id: String in reference: owner.inventory.add(StringName(id), 2)
	check("real bag opens", scene.toggle_item_bag()); var bag: Control = scene._item_bag
	for id: String in reference:
		var c := create(target); prepare(c, id); check("real staged fixture " + id, owner.replace_owned_same_identity(c))
		if c.status_state.persistent_id == &"sleep": scene._native_battles.clocks[String(target)] = {"version": "0.10.11", "start_time": 3, "time": 2}
		bag.refresh(); _select(bag, id)
		if reference[id].get("scope") == "one": bag._moves.select(1)
		check("real UI route " + id, bag._apply("use").accepted)
		check_effect(id, c, owner.owned_creature(target))
		check("real UI inventory " + id, owner.inventory.quantity(StringName(id)) == (2 if id == "blue_flute" else 1))
		if id == "blue_flute":
			check("reusable description", bag._description.text.contains("no se consume"))
			var after := snapshot(bag.service)
			check("repeat flute no effect", not bag._apply("use").accepted and snapshot(bag.service) == after)
			status(owner.owned_creature(target), &"sleep"); bag.refresh(); _select(bag, id)
			check("same flute reused", bag._apply("use").accepted and owner.inventory.quantity(&"blue_flute") == 2)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("GPU screenshot", root.get_texture().get_image().save_png(OUT_IMPORT + "import_bag.png") == OK)
	bag.hide(); await process_frame
	var path := "user://item_import_v19_gpu_test_only.json" if capture else "user://item_import_v19_test_only.json"
	scene._native_battles.save_path = path
	var saved := snapshot(bag.service)
	check("real batch save", scene._native_battles.save_game())
	check("real batch load", await scene._native_battles.load_game())
	check("real batch restored", scene.toggle_item_bag() and snapshot(bag.service) == saved)
	bag.hide(); await process_frame
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var native: RefCounted = scene._native_battles.view.session
	check("native battle after batch", native != null and native.has_active_battle())
	if native != null:
		var active: CreatureInstance = native.battle_state().creature(target)
		check("native restored state", active != null and active.status_state.persistent_id == &"" and active.current_hp == scene.field_collection().owned_creature(target).current_hp)
		reject_unchanged(bag.service, &"blue_flute", "flute locked in combat", -1, target)
		await native.close()
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
