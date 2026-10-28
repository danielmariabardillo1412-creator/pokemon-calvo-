extends SceneTree

const Service = preload("res://modules/inventory/field_item_service.gd")
const OUT := "res://.godot/field_api_checks/"
const SAVE_PATH := OUT + "integration_save.json"
const LOCK_TEXT := "Espera a terminar el combate o el desplazamiento."

var scene: Node2D
var bridge: Node
var view: Control
var bag: Control
var checks := 0
var errors: Array[String] = []
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)


func finish() -> void:
	if done: return
	done = true
	var report := {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"profile": "native",
		"checks": checks,
		"errors": errors,
		"source_sha256": {
			"field_demo": FileAccess.get_sha256("res://scenes/visual/field_demo.gd"),
			"field_item_bag": FileAccess.get_sha256("res://scenes/visual/field_item_bag.gd"),
			"test_runner": FileAccess.get_sha256("res://tests/gameplay/field_api_integration_test_runner.gd"),
		},
	}
	var file := FileAccess.open(OUT + "integration.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_API_INTEGRATION ", report.status, " checks=", checks, " errors=", errors.size())
	if scene != null and is_instance_valid(scene): scene.queue_free()
	quit(0 if errors.is_empty() else 1)


func mon(id: String, species: String, level: int, moves: Array) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var creature := CreatureFactory.create(scene._catalogs.species(StringName(species)), level, scene._catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	if creature != null: creature.ability_id = &""
	return creature


func owned(collection: PlayerCollection, id: StringName) -> CreatureInstance:
	return collection.owned_creature(id) if collection != null else null


func quantity(collection: PlayerCollection, id: StringName) -> int:
	return collection.inventory.quantity(id) if collection != null and collection.inventory != null else -1


func collection_state(collection: PlayerCollection) -> Dictionary:
	var party := []
	if collection != null:
		for creature: CreatureInstance in collection.party.get_creatures(): party.append(creature.to_dict())
	return {
		"inventory": JSON.stringify(collection.inventory.to_dict()) if collection != null else "",
		"party": JSON.stringify(party),
	}


func expect_collection(label: String, collection: PlayerCollection, snapshot: Dictionary) -> void:
	check(label + " inventory unchanged", collection_state(collection).inventory == snapshot.inventory)
	check(label + " party unchanged", collection_state(collection).party == snapshot.party)


func clocks_view(clocks: Dictionary) -> String:
	var keys := clocks.keys(); keys.sort()
	var rows := []
	for key: Variant in keys:
		var row: Dictionary = clocks[key]
		rows.append([String(key), String(row.get("version", "")), int(row.get("start_time", -1)), int(row.get("time", -1))])
	return JSON.stringify(rows)


func sleep_fixture(collection: PlayerCollection, id: StringName) -> void:
	var creature := owned(collection, id)
	creature.status_state.clear_persistent()
	creature.status_state.persistent_id = &"sleep"
	creature.status_state.turns_remaining = 2
	bridge.clocks[String(id)] = {"version": "0.10.11", "start_time": 3, "time": 2}


func select_item(id: StringName) -> bool:
	for index in bag._items.item_count:
		if StringName(bag._items.get_item_metadata(index)) == id:
			bag._items.select(index); bag._refresh_choices(); return true
	return false


func select_target(id: StringName) -> bool:
	for index in bag._targets.item_count:
		if StringName(bag._targets.get_item_metadata(index)) == id:
			bag._targets.select(index); bag._refresh_choices(); return true
	return false


func select_move(slot: int) -> bool:
	if bag._moves.item_count <= slot + 1: return false
	bag._moves.select(slot + 1); return true


func close_bag() -> void:
	bag.hide()
	await process_frame


func push_key(keycode: int) -> void:
	root.gui_release_focus()
	var event := InputEventKey.new()
	event.keycode = keycode; event.physical_keycode = keycode; event.pressed = true
	root.push_input(event)
	await process_frame


func end_real_battle() -> void:
	if view != null and view._playback != null: view._playback.cancel()
	if view != null and view.session != null: await view.session.close()
	if view != null:
		view.hide(); view._working = false
	bridge.busy = false; bridge.kind = ""
	bridge._unlock_world()
	await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(300).timeout.connect(func():
		if not done:
			check("watchdog", false); finish())
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	bag = scene._item_bag
	check("native bridge available", bridge != null)
	if bridge == null:
		finish(); return
	view = bridge.view
	bridge.save_path = SAVE_PATH
	check("scene ready", scene.is_demo_ready())
	check("bag available", bag != null)
	var collection: PlayerCollection = scene.field_collection()
	check("collection current", collection != null and is_same(collection, scene._session.player))
	if collection == null or bag == null or collection.party.size() < 2:
		check("two-creature fixture", false); finish(); return

	await step_one_bag_real(collection)
	await step_two_load_identity()
	await step_three_reset_identity()
	await step_four_equal_clocks()
	await step_six_activity_blocks()
	await step_seven_invalid_load()
	await step_eight_keys_selection_hud()
	finish()


func step_one_bag_real(collection: PlayerCollection) -> void:
	check("fixture adds items",
		collection.inventory.add(&"potion", 4) and collection.inventory.add(&"ether", 2)
		and collection.inventory.add(&"awakening", 2) and collection.inventory.add(&"oran_berry", 2))
	var starter := owned(collection, &"technical_starter")
	var bench := owned(collection, &"technical_bench")
	check("fixture creatures exist", starter != null and bench != null)
	starter.current_hp = maxi(1, starter.stats.max_hp - 5)
	starter.moveset[0].current_pp = maxi(0, starter.moveset[0].max_pp - 3)
	sleep_fixture(collection, &"technical_bench")
	var clocks_ref: Dictionary = bridge.clocks
	check("fixture clock present", clocks_ref.has("technical_bench"))

	check("bag opens real", bag.open_bag() and bag.visible)
	check("bag locks movement", not scene.player.movement_enabled)
	check("bag owner current", is_same(bag.service.owner, collection))
	check("bag catalog current", is_same(bag.service.catalogs, scene.field_definitions()))
	check("bag clocks current", is_same(bag.service.sleep_clocks, clocks_ref))
	check("bag service current", scene.field_item_service_is_current(bag.service))

	check("select potion", select_item(&"potion"))
	check("select starter", select_target(&"technical_starter"))
	check("potion enabled", not bag._use.disabled)
	var potions := quantity(collection, &"potion")
	var hp_before := starter.current_hp
	var result: Dictionary = bag._apply("use")
	starter = owned(collection, &"technical_starter")
	check("potion accepted", bool(result.get("accepted", false)))
	check("potion consumed once", quantity(collection, &"potion") == potions - 1)
	check("potion heals destination", starter.current_hp == mini(starter.stats.max_hp, hp_before + 20))
	check("potion result text", bag._result.text == "Objeto utilizado.")
	check("potion keeps owner identity", is_same(bag.service.owner, collection))

	var move := starter.moveset[0]
	move.current_pp = maxi(0, move.max_pp - 10)
	var pp_max := move.max_pp
	var pp_before := move.current_pp
	check("select ether", select_item(&"ether"))
	check("select starter again", select_target(&"technical_starter"))
	check("ether exposes move slots", bag._moves.visible and bag._moves.item_count >= 2)
	check("select ether move", select_move(0))
	var ethers := quantity(collection, &"ether")
	result = bag._apply("use")
	starter = owned(collection, &"technical_starter")
	check("ether accepted", bool(result.get("accepted", false)))
	check("ether consumed once", quantity(collection, &"ether") == ethers - 1)
	check("ether restores chosen slot", starter.moveset[0].current_pp == mini(pp_max, pp_before + 10))

	check("select oran", select_item(&"oran_berry"))
	check("select bench", select_target(&"technical_bench"))
	check("oran equip enabled", not bag._equip.disabled)
	var berries := quantity(collection, &"oran_berry")
	result = bag._apply("equip")
	bench = owned(collection, &"technical_bench")
	check("oran equipped", bool(result.get("accepted", false)) and bench.held_item_id == &"oran_berry" and not bench.held_item_consumed)
	check("oran consumed once", quantity(collection, &"oran_berry") == berries - 1)
	check("equip result text", bag._result.text == "Objeto equipado.")
	result = bag._apply("unequip")
	bench = owned(collection, &"technical_bench")
	check("oran unequipped", bool(result.get("accepted", false)) and bench.held_item_id == &"")
	check("oran returned", quantity(collection, &"oran_berry") == berries)
	check("unequip result text", bag._result.text == "Objeto retirado.")

	check("select awakening", select_item(&"awakening"))
	check("select sleeping bench", select_target(&"technical_bench"))
	bench = owned(collection, &"technical_bench")
	check("bench sleeping before cure", bench.status_state.persistent_id == &"sleep")
	var awakenings := quantity(collection, &"awakening")
	result = bag._apply("use")
	bench = owned(collection, &"technical_bench")
	check("awakening accepted", bool(result.get("accepted", false)))
	check("awakening consumed once", quantity(collection, &"awakening") == awakenings - 1)
	check("awakening clears sleep", bench.status_state.persistent_id == &"")
	check("awakening erases same clock dictionary", is_same(bridge.clocks, clocks_ref) and not clocks_ref.has("technical_bench"))
	check("awakening keeps service clocks identity", is_same(bag.service.sleep_clocks, bridge.clocks))

	await close_bag()
	check("bag hidden", not bag.visible)
	check("bag close restores movement", scene.player.movement_enabled)


func step_two_load_identity() -> void:
	var c0: PlayerCollection = scene.field_collection()
	var service0: RefCounted = bag.service
	var starter0 := owned(c0, &"technical_starter")
	starter0.current_hp = maxi(1, starter0.stats.max_hp - 15)
	sleep_fixture(c0, &"technical_bench")
	var clocks0: Dictionary = bridge.clocks
	var clocks0_view := clocks_view(clocks0)
	var c0_state := collection_state(c0)
	check("service current before save", scene.field_item_service_is_current(service0))

	check("real save accepted", bridge.save_game())
	check("save consumes no inventory", collection_state(c0).inventory == c0_state.inventory)
	check("save changes no creature", collection_state(c0).party == c0_state.party)
	check("save keeps clock content", clocks_view(clocks0) == clocks0_view)

	var loaded: bool = await bridge.load_game()
	check("real load accepted", loaded)
	var c1: PlayerCollection = scene.field_collection()
	check("getter publishes loaded collection", c1 != null and not is_same(c1, c0) and is_same(c1, scene._session.player))
	check("catalog identity survives load", is_same(scene.field_definitions(), scene._catalogs))
	check("clocks replaced by load", not is_same(bridge.clocks, clocks0))
	check("clocks keep equal content after load", clocks_view(bridge.clocks) == clocks0_view)
	check("retired clocks untouched by load", clocks_view(clocks0) == clocks0_view)
	expect_collection("retired collection after load", c0, c0_state)
	check("load publishes saved inventory", c1.inventory.to_dict() == c0.inventory.to_dict())
	check("load consumes no potion", quantity(c1, &"potion") == quantity(c0, &"potion"))
	var saved_potions := quantity(c1, &"potion")
	var saved_hp := owned(c1, &"technical_starter").current_hp

	check("old service rejects after load", not scene.field_item_service_is_current(service0))
	check("old guard rejects after load", service0._boundary() == "field_locked")
	var c1_state := collection_state(c1)
	var denied: Dictionary = service0.use_item(&"awakening", &"technical_bench")
	check("stale use denied field_locked", not bool(denied.get("accepted", true)) and String(denied.get("reason", "")) == "field_locked" and String(denied.get("status", "")) == "REJECTED")
	check("stale equip denied field_locked", String(service0.equip(&"oran_berry", &"technical_starter").get("reason", "")) == "field_locked")
	expect_collection("stale service old collection", c0, c0_state)
	expect_collection("stale service new collection", c1, c1_state)
	check("stale service retired clocks", clocks_view(clocks0) == clocks0_view)

	check("explicit rebind accepted", scene.field_bind_item_service(service0))
	check("rebind owner loaded", is_same(service0.owner, c1))
	check("rebind catalog current", is_same(service0.catalogs, scene.field_definitions()))
	check("rebind clocks loaded", is_same(service0.sleep_clocks, bridge.clocks))
	check("rebind service current", scene.field_item_service_is_current(service0))

	var loaded_clocks: Dictionary = bridge.clocks
	var loaded_clocks_view := clocks_view(loaded_clocks)
	var wake: Dictionary = service0.use_item(&"awakening", &"technical_bench")
	check("loaded awakening accepted", bool(wake.get("accepted", false)))
	check("loaded awakening clears sleep", owned(c1, &"technical_bench").status_state.persistent_id == &"")
	check("loaded awakening erases same dictionary", is_same(bridge.clocks, loaded_clocks) and not loaded_clocks.has("technical_bench"))
	check("loaded clock change only on current dict", clocks_view(loaded_clocks) != loaded_clocks_view and clocks_view(clocks0) == clocks0_view)

	var c0_potions := quantity(c0, &"potion")
	var c0_hp := owned(c0, &"technical_starter").current_hp
	check("bag reopens on loaded collection", bag.open_bag() and bag.visible)
	check("reopened owner loaded", is_same(bag.service.owner, c1))
	check("select loaded potion", select_item(&"potion"))
	check("select loaded starter", select_target(&"technical_starter"))
	var current_hp := owned(c1, &"technical_starter").current_hp
	var current_potions := quantity(c1, &"potion")
	var applied: Dictionary = bag._apply("use")
	check("loaded potion accepted", bool(applied.get("accepted", false)))
	check("loaded potion consumed on current", quantity(c1, &"potion") == current_potions - 1)
	check("loaded potion heals current", owned(c1, &"technical_starter").current_hp == mini(owned(c1, &"technical_starter").stats.max_hp, current_hp + 20))
	check("loaded potion leaves old inventory", quantity(c0, &"potion") == c0_potions)
	check("loaded potion leaves old creature", owned(c0, &"technical_starter").current_hp == c0_hp)
	check("loaded potion leaves old clocks", clocks_view(clocks0) == clocks0_view)
	await close_bag()

	var c1_after := collection_state(c1)
	var c2_loaded: bool = await bridge.load_game()
	check("second real load accepted", c2_loaded)
	var c2: PlayerCollection = scene.field_collection()
	check("second load publishes new collection", c2 != null and not is_same(c2, c1) and is_same(c2, scene._session.player))
	expect_collection("second load leaves retired collection", c1, c1_after)
	check("second load keeps old retired clocks", clocks_view(clocks0) == clocks0_view)
	check("second load publishes saved inventory", c2.inventory.to_dict() == c0.inventory.to_dict())
	check("second load consumes no potion", quantity(c2, &"potion") == quantity(c0, &"potion"))
	check("bag service stale after second load", not scene.field_item_service_is_current(bag.service))

	var c2_state := collection_state(c2)
	var c2_clocks := clocks_view(bridge.clocks)
	var stale: Dictionary = bag._apply("use")
	check("stale UI apply rejected", not bool(stale.get("accepted", true)) and String(stale.get("reason", "")) == "field_locked" and String(stale.get("status", "")) == "REJECTED")
	check("stale UI keeps standard text", bag._result.text == LOCK_TEXT)
	expect_collection("stale UI retired collection", c1, c1_after)
	expect_collection("stale UI current collection", c2, c2_state)
	check("stale UI keeps current clocks", clocks_view(bridge.clocks) == c2_clocks)
	check("stale UI refresh rebinds", scene.field_item_service_is_current(bag.service) and is_same(bag.service.owner, c2))
	check("stale UI does not replay pending action", quantity(c2, &"potion") == saved_potions and owned(c2, &"technical_starter").current_hp == saved_hp)


func step_three_reset_identity() -> void:
	var c2: PlayerCollection = scene.field_collection()
	var clocks2: Dictionary = bridge.clocks
	var c2_state := collection_state(c2)
	check("configuration reset idle", scene.field_can_configure() and not bag.visible)
	scene.restart_field_run()
	var c3: PlayerCollection = scene.field_collection()
	check("configuration reset publishes new collection", c3 != null and not is_same(c3, c2) and is_same(c3, scene._session.player))
	check("configuration reset keeps clocks identity", is_same(bridge.clocks, clocks2))
	check("configuration reset clears current clocks", clocks2.is_empty())
	expect_collection("configuration reset leaves retired collection", c2, c2_state)
	check("configuration reset leaves service stale", not scene.field_item_service_is_current(bag.service))
	check("configuration reset stale guard", bag.service._boundary() == "field_locked")
	var c3_state := collection_state(c3)
	var denied: Dictionary = bag.service.use_item(&"potion", &"technical_starter")
	check("configuration reset stale use denied", String(denied.get("reason", "")) == "field_locked")
	expect_collection("configuration reset stale use current", c3, c3_state)
	expect_collection("configuration reset stale use retired", c2, c2_state)

	c3.inventory.add(&"potion", 2)
	c3.inventory.add(&"ether", 2)
	c3.inventory.add(&"awakening", 1)
	c3.inventory.add(&"oran_berry", 2)
	check("rebind after configuration reset", scene.field_bind_item_service(bag.service))
	check("rebind after reset owner", is_same(bag.service.owner, c3))
	check("rebind after reset clocks", is_same(bag.service.sleep_clocks, bridge.clocks))
	check("rebind after reset current", scene.field_item_service_is_current(bag.service))


func step_four_equal_clocks() -> void:
	var c3: PlayerCollection = scene.field_collection()
	sleep_fixture(c3, &"technical_bench")
	var current_clocks: Dictionary = bridge.clocks
	var current_view := clocks_view(current_clocks)
	check("equal fixture bound to current clocks", is_same(bag.service.sleep_clocks, current_clocks))
	var equal: Dictionary = current_clocks.duplicate(true)
	check("equal fixture equal content", equal == current_clocks)
	check("equal fixture distinct identity", not is_same(equal, current_clocks))
	check("equal fixture non-empty", not equal.is_empty())
	bridge.clocks = equal
	check("equal fixture replaces current clocks", is_same(bridge.clocks, equal))
	check("equal content rejects stale link", not scene.field_item_service_is_current(bag.service))
	check("equal content guard rejects", bag.service._boundary() == "field_locked")
	var equal_view := clocks_view(equal)
	var denied: Dictionary = bag.service.use_item(&"awakening", &"technical_bench")
	check("equal content use denied", String(denied.get("reason", "")) == "field_locked")
	check("equal content old dict untouched", clocks_view(current_clocks) == current_view)
	check("equal content new dict untouched", clocks_view(equal) == equal_view)
	check("equal content creature still sleeping", owned(c3, &"technical_bench").status_state.persistent_id == &"sleep")

	check("equal content explicit rebind", scene.field_bind_item_service(bag.service))
	check("equal content rebind identity", is_same(bag.service.sleep_clocks, equal))
	check("equal content rebind current", scene.field_item_service_is_current(bag.service))
	var wake: Dictionary = bag.service.use_item(&"awakening", &"technical_bench")
	check("equal content awakening accepted", bool(wake.get("accepted", false)))
	check("equal content erases current dict", is_same(bridge.clocks, equal) and not equal.has("technical_bench"))
	check("equal content leaves old dict", clocks_view(current_clocks) == current_view and current_clocks.has("technical_bench"))


func step_six_activity_blocks() -> void:
	var c3: PlayerCollection = scene.field_collection()
	var service: RefCounted = bag.service
	var starter := owned(c3, &"technical_starter")
	starter.current_hp = maxi(1, starter.stats.max_hp - 10)
	c3.inventory.add(&"potion", 2)
	check("activity fixture service current", scene.field_item_service_is_current(service))

	var wild := mon("integration_wild", "pidgey", 5, ["tackle"])
	check("activity fixture wild creature", wild != null)
	bridge.busy = true; bridge.kind = "wild"
	await bridge._open(wild, -1)
	check("real native battle occupied", bridge.occupied() and scene.has_active_demo_battle())
	check("activity snapshot sees battle", bool(scene.field_activity_snapshot().native_occupied))
	view._playback.set_process(false)
	var c3_state := collection_state(c3)
	var clocks_before := clocks_view(bridge.clocks)
	check("battle blocks bag open", not scene.field_can_open_item_bag() and not bag.open_bag() and not bag.visible)
	check("battle blocks item use", not scene.field_can_use_items())
	check("battle live guard rejects", service._boundary() == "field_locked")
	var denied_battle: Dictionary = service.use_item(&"potion", &"technical_starter")
	check("battle service use denied", String(denied_battle.get("reason", "")) == "field_locked")
	var ui_denied: Dictionary = bag._apply("use")
	check("battle UI use denied", String(ui_denied.get("reason", "")) == "field_locked" and bag._result.text == LOCK_TEXT)
	expect_collection("battle blocked collection", c3, c3_state)
	check("battle blocked clocks", clocks_view(bridge.clocks) == clocks_before)
	await end_real_battle()
	check("battle cleanup releases world", not bridge.occupied() and scene.field_can_use_items())
	check("battle cleanup keeps service", scene.field_item_service_is_current(service))
	check("battle cleanup live guard", service._boundary() == "")
	var potions := quantity(c3, &"potion")
	var hp := owned(c3, &"technical_starter").current_hp
	var healed: Dictionary = service.use_item(&"potion", &"technical_starter")
	check("post-battle service applies", bool(healed.get("accepted", false)))
	check("post-battle quantity", quantity(c3, &"potion") == potions - 1)
	check("post-battle destination", owned(c3, &"technical_starter").current_hp == mini(owned(c3, &"technical_starter").stats.max_hp, hp + 20))

	sleep_fixture(c3, &"technical_bench")
	var panel_clocks: Dictionary = bridge.clocks
	var panel_view := clocks_view(panel_clocks)
	check("panel fixture bound", is_same(service.sleep_clocks, panel_clocks))
	scene.test_panel._open_config()
	check("panel open observed", scene.test_panel.is_panel_open())
	check("panel blocks bag open", not scene.field_can_open_item_bag() and not bag.open_bag())
	check("panel blocks item use", not scene.field_can_use_items())
	check("panel live guard rejects", service._boundary() == "field_locked")
	var panel_equal := panel_clocks.duplicate(true)
	check("panel equal clocks fixture", panel_equal == panel_clocks and not is_same(panel_equal, panel_clocks))
	bridge.clocks = panel_equal
	var panel_state := collection_state(c3)
	check("panel stale binding rejected", not bag._ensure_binding())
	bag.refresh()
	check("panel stale UI clears items", bag._items.item_count == 0 and bag._targets.item_count == 0)
	check("panel stale UI disables actions", bag._use.disabled and bag._equip.disabled and bag._description.text == "")
	expect_collection("panel stale UI collection", c3, panel_state)
	check("panel stale UI clocks", clocks_view(panel_clocks) == panel_view)
	bridge.clocks = panel_clocks
	scene.test_panel._close_config()
	check("panel close recovers guard", scene.field_can_use_items() and service._boundary() == "")
	check("panel close keeps identity", scene.field_item_service_is_current(service))

	scene.toggle_pokemon_gallery()
	check("gallery overlay observed", scene._pokemon_gallery.visible)
	check("gallery blocks bag open", not scene.field_can_open_item_bag() and not bag.open_bag())
	check("gallery blocks item use", not scene.field_can_use_items())
	check("gallery live guard rejects", service._boundary() == "field_locked")
	var gallery_state := collection_state(c3)
	var gallery_clocks := clocks_view(bridge.clocks)
	check("gallery service use denied", String(service.use_item(&"awakening", &"technical_bench").get("reason", "")) == "field_locked")
	expect_collection("gallery blocked collection", c3, gallery_state)
	check("gallery blocked clocks", clocks_view(bridge.clocks) == gallery_clocks)
	scene.toggle_pokemon_gallery()
	check("gallery close recovers", scene.field_can_use_items() and scene.field_item_service_is_current(service) and service._boundary() == "")


func step_seven_invalid_load() -> void:
	var c3: PlayerCollection = scene.field_collection()
	var service: RefCounted = bag.service
	check("invalid fixture idle", scene.field_can_configure() and not bag.visible)
	var good := FileAccess.get_file_as_bytes(SAVE_PATH)
	check("invalid fixture has good save", not good.is_empty())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("{\"format\": \"bogus\", \"schema\": 1, \"payload\": {}}"); file.close()
	var state_before := collection_state(c3)
	var clocks_before := clocks_view(bridge.clocks)
	var loaded: bool = await bridge.load_game()
	check("invalid save rejected", not loaded)
	check("invalid save reports error", bridge.last_error.begins_with("No se pudo cargar: "))
	check("invalid save keeps collection", is_same(scene.field_collection(), c3))
	check("invalid save keeps service", scene.field_item_service_is_current(service))
	check("invalid save keeps guard", service._boundary() == "")
	expect_collection("invalid save collection", c3, state_before)
	check("invalid save keeps clocks", clocks_view(bridge.clocks) == clocks_before)
	var potions := quantity(c3, &"potion")
	owned(c3, &"technical_starter").current_hp = maxi(1, owned(c3, &"technical_starter").stats.max_hp - 5)
	var healed: Dictionary = service.use_item(&"potion", &"technical_starter")
	check("invalid save link still applies", bool(healed.get("accepted", false)) and quantity(c3, &"potion") == potions - 1)
	file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_buffer(good); file.close()


func step_eight_keys_selection_hud() -> void:
	var c3: PlayerCollection = scene.field_collection()
	var service: RefCounted = bag.service
	c3.inventory.add(&"ether", 2)
	c3.inventory.add(&"oran_berry", 2)
	var starter := owned(c3, &"technical_starter")
	starter.moveset[0].current_pp = maxi(0, starter.moveset[0].max_pp - 10)
	var pp_max := starter.moveset[0].max_pp
	var pp_before := starter.moveset[0].current_pp
	check("key fixture idle", scene.field_can_use_items() and not bag.visible)
	await push_key(KEY_B)
	check("B opens bag", bag.visible and not scene.player.movement_enabled)
	check("B opening uses public identity", is_same(bag.service.owner, c3) and scene.field_item_service_is_current(service))
	check("open bag blocks reconfigure", not scene.field_can_open_item_bag())
	check("select HUD ether", select_item(&"ether"))
	check("select HUD starter", select_target(&"technical_starter"))
	check("HUD ether exposes moves", bag._moves.visible and select_move(0))
	scene._grass_walking_seconds = 12.5
	var ethers := quantity(c3, &"ether")
	var used: Dictionary = bag._apply("use")
	starter = owned(c3, &"technical_starter")
	check("HUD ether accepted", bool(used.get("accepted", false)))
	check("HUD ether destination", starter.moveset[0].current_pp == mini(pp_max, pp_before + 10))
	check("HUD ether consumed", quantity(c3, &"ether") == ethers - 1)
	check("HUD refresh after accepted", scene._observed_label.text.contains("12.5 s andando"))

	check("select HUD potion", select_item(&"potion"))
	check("select HUD starter full", select_target(&"technical_starter"))
	scene._grass_walking_seconds = 13.5
	var potions := quantity(c3, &"potion")
	var no_effect: Dictionary = bag._apply("use")
	check("HUD no-effect rejected", not bool(no_effect.get("accepted", true)) and String(no_effect.get("reason", "")) == "item_has_no_effect")
	check("HUD no-effect text", bag._result.text == "No tendría efecto. El objeto se conserva.")
	check("HUD no-effect keeps item", quantity(c3, &"potion") == potions)
	check("HUD refresh after rejected", scene._observed_label.text.contains("13.5 s andando"))

	check("select HUD oran", select_item(&"oran_berry"))
	check("select HUD bench", select_target(&"technical_bench"))
	var berries := quantity(c3, &"oran_berry")
	var equipped: Dictionary = bag._apply("equip")
	check("HUD equip accepted", bool(equipped.get("accepted", false)) and owned(c3, &"technical_bench").held_item_id == &"oran_berry")
	check("HUD equip quantity", quantity(c3, &"oran_berry") == berries - 1)
	var unequipped: Dictionary = bag._apply("unequip")
	check("HUD unequip accepted", bool(unequipped.get("accepted", false)) and owned(c3, &"technical_bench").held_item_id == &"")
	check("HUD unequip quantity", quantity(c3, &"oran_berry") == berries)

	await push_key(KEY_B)
	check("B closes open bag", not bag.visible and scene.player.movement_enabled)
	await push_key(KEY_B)
	check("B reopens bag", bag.visible)
	await push_key(KEY_ESCAPE)
	check("Escape closes bag", not bag.visible and scene.player.movement_enabled)
	check("keys leave live service", scene.field_item_service_is_current(service) and service._boundary() == "")
