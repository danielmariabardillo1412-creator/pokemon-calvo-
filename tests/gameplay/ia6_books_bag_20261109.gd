extends SceneTree

# IA6: W05 book panel mounted inside the REAL FieldItemBag of the demo.
# Verifies one call to the existing teach service, stock, identity and SaveV2.
var checks := 0
var failures: Array[String] = []
var done := false
const SAVE := "user://ia6_books_bag_20261109.json"

func _initialize() -> void:
	call_deferred("_run")
	create_timer(200.0).timeout.connect(func():
		if not done:
			push_error("IA6_BOOK_BAG timeout")
			quit(2)
	)

func check(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("IA6_BOOK_BAG_FAIL " + label)

func _compatible(species: CreatureSpecies) -> bool:
	if species == null: return false
	for entry: LearnSetEntry in species.learnset:
		if entry.method == "machine" and String(entry.version_group) == "scarlet-violet" and entry.move_id == &"metal_claw":
			return true
	return false

func _finish(scene: Node2D) -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var p := SAVE + suffix
		if FileAccess.file_exists(p): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if scene != null:
		scene.queue_free()
		await process_frame
	done = true
	if failures.is_empty():
		print("IA6_BOOK_BAG PASS checks=", checks, " features=real_bag,w05_panel,one_teach,savev2")
		quit(0)
	else:
		print("IA6_BOOK_BAG FAIL checks=", checks, " errors=", JSON.stringify(failures))
		quit(1)

func _run() -> void:
	var scene: Node2D = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check("demo_ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish(scene)
		return
	scene.player.set_physics_process(false)
	var owner: PlayerCollection = scene.field_collection()
	var defs: DefinitionCatalog = scene.field_definitions()
	var bag: Control = scene._item_bag
	check("demo_collection", owner != null and defs != null and bag != null)
	if owner == null or defs == null or bag == null:
		await _finish(scene)
		return
	var recipient: CreatureInstance = null
	for c: CreatureInstance in owner.party.get_creatures():
		if _compatible(defs.species(c.species_id)) and not c.has_move(&"metal_claw"):
			recipient = c
			break
	if recipient == null:
		var selected: StringName = &""
		for sid: StringName in defs.species_catalog.all_ids():
			if _compatible(defs.species(sid)):
				selected = sid
				break
		check("metal_claw_compatible_species", selected != &"")
		if selected != &"":
			var rng := RandomNumberGenerator.new()
			rng.seed = 1412
			var new_mon: CreatureInstance = CreatureFactory.create(defs.species(selected), 50, defs,
				ProgressionRuleset.new(), rng,
				{"instance_id": &"ia6_books_mon", "moves": ["tackle", "protect"]})
			check("created_compatible_pokemon", new_mon != null)
			if new_mon != null:
				check("added_to_real_party", owner.party.add_creature(new_mon))
				recipient = owner.owned_creature(&"ia6_books_mon")
	check("eligible_target", recipient != null)
	if recipient == null:
		await _finish(scene)
		return
	var creature_id: StringName = recipient.instance_id
	check("add_real_book_stock", owner.inventory.add(&"tm31", 2))
	check("open_real_field_bag", bag.open_bag() and bag.visible)
	var index := -1
	for i in bag._items.item_count:
		if String(bag._items.get_item_metadata(i)) == "tm31": index = i
	check("tm31_in_real_bag", index >= 0)
	if index < 0:
		await _finish(scene)
		return
	bag._items.select(index)
	bag._refresh_choices()
	check("book_open_action_available", not bag._books_button.disabled)
	bag._books_button.pressed.emit()
	var panel: PanelContainer = bag._books_panel
	check("panel_mounted_visible", panel != null and panel.visible and panel.is_inside_tree())
	check("same_authoritative_service", panel != null and is_same(panel.service, bag.service))
	check("tm31_selected_from_real_bag", panel != null and panel._selected(panel.books) == &"tm31")
	check("choose_real_pokemon", panel.select_creature(creature_id))
	check("real_book_name", panel.book_label.text.contains("Garra Metal"))
	var old_qty: int = owner.inventory.quantity(&"tm31")
	panel.teach_button.pressed.emit()
	var taught: CreatureInstance = owner.owned_creature(creature_id)
	check("button_calls_existing_teach_once", panel.last_result.get("accepted", false)
		and panel.last_result.get("move_id", "") == "metal_claw"
		and taught != null and taught.has_move(&"metal_claw"))
	check("exactly_one_book_consumed", owner.inventory.quantity(&"tm31") == old_qty - 1)
	check("identity_and_owner", taught != null and taught.instance_id == creature_id and owner.location_of(creature_id) == &"PARTY")
	var move: BattleMoveSlot = taught.move_slot(&"metal_claw") if taught != null else null
	var definition: MoveDefinition = defs.move(&"metal_claw")
	check("authentic_move_pp", move != null and definition != null and move.current_pp == definition.pp and move.max_pp == definition.pp)
	panel.teach_button.pressed.emit()
	check("repeat_does_not_consume", not panel.last_result.get("accepted", true)
		and owner.inventory.quantity(&"tm31") == old_qty - 1)
	bag.hide()
	var save: Node = scene._native_battles
	save.save_path = SAVE
	for suffix: String in ["", ".tmp", ".bak"]:
		var p := SAVE + suffix
		if FileAccess.file_exists(p): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	check("real_manual_save", save.save_game())
	var loaded: bool = await save.load_game()
	var after: PlayerCollection = scene.field_collection()
	var persisted: CreatureInstance = after.owned_creature(creature_id) if after != null else null
	check("real_savev2_reloads_one_spend", loaded and after != null
		and after.inventory.quantity(&"tm31") == old_qty - 1)
	check("real_savev2_reloads_taught_move", loaded and persisted != null
		and persisted.instance_id == creature_id and persisted.has_move(&"metal_claw"))
	await _finish(scene)
