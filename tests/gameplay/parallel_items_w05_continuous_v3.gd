extends "res://tests/gameplay/parallel_items_w05_book_ui_autorun_v3.gd"

# V3 actual FieldItemBag node plus authentic FieldItemService and panel.
# FakeField supplies only FieldDemo's binding/session facade. Never mocks
# FieldItemBag, PlayerCollection, Service.teach, save or creature moves.
const BagClass = preload("res://scenes/visual/field_item_bag.gd")

class FieldFacade:
	extends Node2D
	var owner: PlayerCollection
	var definitions: DefinitionCatalog
	var unlocked := true
	var opens := 0
	var hud_updates := 0

	func field_can_open_item_bag() -> bool:
		return true

	func field_bind_item_service(bound: RefCounted) -> bool:
		return bound.configure(owner, definitions, func(): return unlocked)

	func field_item_service_is_current(bound: RefCounted) -> bool:
		return bound != null and is_same(bound.get("owner"), owner) \
			and is_same(bound.get("catalogs"), definitions)

	func field_definitions() -> DefinitionCatalog:
		return definitions

	func field_item_bag_opened() -> void:
		opens += 1

	func field_refresh_hud() -> void:
		hud_updates += 1


func mount_real_bag(svc: Variant) -> Dictionary:
	var facade := FieldFacade.new()
	facade.owner = svc.owner
	facade.definitions = catalogs
	root.add_child(facade)
	var bag: Variant = BagClass.new()
	bag.field = facade
	root.add_child(bag)
	check("real bag opened with FieldDemo facade", bag.open_bag())
	check("same real service owner is bound", is_same(bag.service.owner, svc.owner))
	check("native child exists exactly once", bag._machine_panel != null
		and bag._machine_panel.get_parent() == bag.get_child(0))
	check("single native callback", bag._machine_panel.teaching_finished.get_connections().size() == 1)
	return {"bag": bag, "facade": facade}


func select_bag_id(bag: Variant, id: StringName) -> bool:
	for i in range(bag._items.item_count):
		if StringName(bag._items.get_item_metadata(i)) == id:
			bag._items.select(i)
			bag._items.item_selected.emit(i)
			return true
	return false


func select_bag_owner(bag: Variant, owner_id: StringName) -> bool:
	for i in range(bag._targets.item_count):
		if StringName(bag._targets.get_item_metadata(i)) == owner_id:
			bag._targets.select(i)
			bag._targets.item_selected.emit(i)
			return true
	return false


func destroy_bag(d: Dictionary) -> void:
	var bag: Variant = d.bag
	bag.hide()
	bag.queue_free()
	d.facade.queue_free()


func check_slots() -> void:
	for slot in range(4):
		var species_id: StringName = choose_species(&"metal_claw", true, true)
		check("real four-slot SV species exists", species_id != &"")
		if species_id == &"":
			continue
		var svc: Variant = new_service(species_id, &"metal_claw", true)
		if svc == null:
			continue
		check("stock of two books for slot", svc.owner.inventory.add(&"tm31", 2))
		var d := mount_real_bag(svc)
		var bag: Variant = d.bag
		check("select real inventory MT", select_bag_id(bag, &"tm31"))
		check("select real Party owner", select_bag_owner(bag, POKEMON))
		check("panel truly visible inside bag", bag._machine_panel.visible
			and is_same(bag._machine_panel.service, bag.service))
		check("global use disabled for book", bag._use.disabled)
		var untouched: String = state(svc.owner)
		var direct_use: Dictionary = bag._apply("use")
		check("global use never double-consumes MT",
			not direct_use.get("accepted", false)
			and direct_use.get("reason", "") == "machine_panel_required"
			and state(svc.owner) == untouched)
		var old_move: StringName = svc.owner.owned_creature(POKEMON).moveset[slot].move_id
		bag._moves.select(slot + 1)
		bag._moves.item_selected.emit(slot + 1)
		check("bag replacement slot transmitted to panel", bag._machine_panel._slot() == slot
			and not bag._machine_panel.teach_button.disabled)
		var callbacks := {"accepted": 0, "all": 0}
		bag._machine_panel.teaching_finished.connect(func(result: Dictionary):
			callbacks["all"] += 1
			if result.get("accepted", false): callbacks["accepted"] += 1)
		bag._machine_panel.teach_button.pressed.emit()
		var actual: CreatureInstance = svc.owner.owned_creature(POKEMON)
		var def: MoveDefinition = catalogs.move(&"metal_claw")
		var moved: BattleMoveSlot = actual.move_slot(&"metal_claw") if actual != null else null
		check("native bag book click learns exactly once",
			bag._machine_panel.last_result.get("accepted", false)
			and callbacks["accepted"] == 1 and callbacks["all"] == 1
			and svc.owner.inventory.quantity(&"tm31") == 1)
		check("actual owner and replacement intact",
			actual != null and actual.instance_id == POKEMON
			and actual.moveset[slot].move_id == &"metal_claw"
			and not actual.has_move(old_move)
			and svc.owner.location_of(POKEMON) == &"PARTY")
		check("PP canonical after bag click", moved != null and def != null
			and moved.current_pp == def.pp and moved.max_pp == def.pp)
		if slot == 1:
			check_save(svc.owner, &"tm31", &"metal_claw", old_move)
		var after_once: String = state(svc.owner)
		bag._machine_panel.teach_button.pressed.emit()
		check("second click rejected and no extra consumption",
			not bag._machine_panel.last_result.get("accepted", false)
			and callbacks["accepted"] == 1
			and callbacks["all"] == 2
			and state(svc.owner) == after_once)
		bag.hide()
		check("reopen same real bag", bag.open_bag())
		check("still one panel and callback on reopen",
			bag._machine_panel.get_parent() == bag.get_child(0)
			and bag._machine_panel.teaching_finished.get_connections().size() == 2)
		destroy_bag(d)


func check_rejections() -> void:
	var own := setup()
	if own.is_empty(): return
	var d := mount_real_bag(own.service)
	var bag: Variant = d.bag
	check("choose TM for owner transition", select_bag_id(bag, &"tm202")
		and select_bag_owner(bag, POKEMON))
	var panel: Variant = bag._machine_panel
	check("deposit selected creature", own.service.owner.deposit(POKEMON))
	var before: String = state(own.service.owner)
	panel.teach_button.pressed.emit()
	check("Storage owner no spend", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "creature_not_in_party"
		and state(own.service.owner) == before)
	destroy_bag(d)

	var locked := setup()
	if locked.is_empty(): return
	d = mount_real_bag(locked.service)
	bag = d.bag
	check("choose locked TM", select_bag_id(bag, &"tm202")
		and select_bag_owner(bag, POKEMON))
	d.facade.unlocked = false
	before = state(locked.service.owner)
	bag._machine_panel.teach_button.pressed.emit()
	check("field lock keeps entire save state",
		not bag._machine_panel.last_result.get("accepted", false)
		and bag._machine_panel.last_result.get("reason", "") == "field_locked"
		and state(locked.service.owner) == before)
	destroy_bag(d)

	var missing := setup()
	if missing.is_empty(): return
	d = mount_real_bag(missing.service)
	bag = d.bag
	check("choose stale TM", select_bag_id(bag, &"tm202")
		and select_bag_owner(bag, POKEMON))
	check("add alternate stock", missing.service.owner.inventory.add(&"tm31", 1))
	check("remove chosen stock externally", missing.service.owner.inventory.remove(&"tm202", 2))
	before = state(missing.service.owner)
	bag._machine_panel.teach_button.pressed.emit()
	check("no-stock rejected without touching other book",
		not bag._machine_panel.last_result.get("accepted", false)
		and state(missing.service.owner) == before
		and missing.service.owner.inventory.quantity(&"tm31") == 1)
	bag.refresh()
	check("stale book never silently switches to another selected item",
		not bag._machine_panel.visible or bag._machine_panel._selected(bag._machine_panel.books) != &"tm31")
	destroy_bag(d)


func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	check("normalized source for real bag", raw is Dictionary)
	if raw is Dictionary:
		catalogs = GameData.from_dict(raw).to_definition_catalog()
		check("real definitions for native bag", catalogs != null)
		check("field policy available", policy.load_local())
		if catalogs != null and policy.valid:
			check_slots()
			check_rejections()
	if failures.is_empty():
		print("W05_V3_NATIVE_BAG_GODOT PASS slots=4 real_bag=1 owner=1 "
			+ "spent_once=1 double_spend=0 storage=1 stale=1 lock=1 "
			+ "savev2=1 signals=1 checks=%d" % checks)
		quit(0)
	else:
		print("W05_V3_NATIVE_BAG_GODOT FAIL checks=%d errors=%s" % [checks, str(failures)])
		quit(1)
