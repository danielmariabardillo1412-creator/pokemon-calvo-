extends "res://tests/gameplay/ia6_books_bag_20261109.gd"

# IA6 staging W05 V4: REAL demo, REAL FieldItemBag, REAL FieldItemService.
# No second book panel. Cuerda Huida is exercised by the existing IA6
# native integration smoke in the same CI; W03 repelentes remain pending IA6.
const ES_SAMPLES := {"tm01": "Derribo", "tm75": "Pantalla de Luz",
	"tm202": "Divide Dolor", "tm229": "Palma Rauda"}


func _snapshot(collection: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(
		collection.party, collection.storage, collection.inventory).to_dict())


func _choose_four_move_species(defs: DefinitionCatalog) -> Dictionary:
	var all_ids: Array[String] = []
	for sid: StringName in defs.species_catalog.all_ids():
		all_ids.append(String(sid))
	all_ids.sort()
	for raw: String in all_ids:
		var sid := StringName(raw)
		var species: CreatureSpecies = defs.species(sid)
		if not _compatible(species):
			continue
		var other_moves: Array[StringName] = []
		for entry: LearnSetEntry in species.learnset:
			var mid: StringName = entry.move_id
			if mid == &"metal_claw" or other_moves.has(mid) or defs.move(mid) == null:
				continue
			other_moves.append(mid)
			if other_moves.size() == 4:
				return {"species": species, "moves": other_moves}
	return {}


func _select_book(bag: Variant, id: StringName) -> bool:
	for i in range(bag._items.item_count):
		if StringName(bag._items.get_item_metadata(i)) == id:
			bag._items.select(i)
			bag._items.item_selected.emit(i)
			return true
	return false


func _select_owner(bag: Variant, id: StringName) -> bool:
	for i in range(bag._targets.item_count):
		if StringName(bag._targets.get_item_metadata(i)) == id:
			bag._targets.select(i)
			bag._targets.item_selected.emit(i)
			return true
	return false


func _run() -> void:
	# Every slot uses a separate real technical field session.
	for index in range(4):
		var scene: Node2D = load("res://scenes/visual/field_demo.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		await physics_frame
		check("real demo ready slot " + str(index), scene.is_demo_ready())
		if not scene.is_demo_ready():
			scene.queue_free()
			await process_frame
			continue
		scene.player.set_physics_process(false)
		var collection: PlayerCollection = scene.field_collection()
		var defs: DefinitionCatalog = scene.field_definitions()
		var bag: Variant = scene._item_bag
		check("real player, definitions, bag slot " + str(index),
			collection != null and defs != null and bag != null)
		if collection == null or defs == null or bag == null:
			scene.queue_free()
			await process_frame
			continue
		var selected: Dictionary = _choose_four_move_species(defs)
		check("4-slot compatible species " + str(index), not selected.is_empty())
		if selected.is_empty():
			scene.queue_free()
			await process_frame
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261111 + index
		var instance_id := StringName("w05_v4_real_slot_%d" % index)
		var pokemon: CreatureInstance = CreatureFactory.create(
			selected.species, 50, defs, ProgressionRuleset.new(), rng,
			{"instance_id": instance_id, "moves": ["tackle", "protect"]})
		check("real creature created " + str(index), pokemon != null)
		if pokemon == null:
			scene.queue_free()
			await process_frame
			continue
		pokemon.moveset.clear()
		pokemon.move_ids.clear()
		for mid: StringName in selected.moves:
			check("native move setup " + String(mid),
				pokemon.add_move(mid, defs))
		check("four actual moves installed", pokemon.moveset.size() == 4)
		check("party owns real V4 creature", collection.party.add_creature(pokemon))
		check("book stock x2", collection.inventory.add(&"tm31", 2))
		if index == 0:
			var profile: Dictionary = JSON.parse_string(
				FileAccess.get_file_as_string("res://modules/inventory/item_connections_v1.json"))
			var n := 0
			for i in range(1, 230):
				var item_id := StringName("tm%02d" % i)
				if profile.get("machine_rows", {}).has(String(item_id)):
					if not collection.inventory.has(item_id):
						check("add source-backed machine", collection.inventory.add(item_id, 1))
					n += 1
			check("exact 229 SV books in real collection", n == 229)
		check("open the real bag", bag.open_bag() and bag.visible)
		check("real chosen machine", _select_book(bag, &"tm31"))
		check("explicit Party target ID", _select_owner(bag, instance_id))
		check("single book-open route", not bag._books_button.disabled)
		check("global Usar disabled on MT", bag._use.disabled)
		var before_global := _snapshot(collection)
		var refused: Dictionary = await bag._apply("use")
		check("global Use cannot double spend",
			not refused.get("accepted", false)
			and refused.get("reason", "") == "machine_panel_required"
			and _snapshot(collection) == before_global)
		bag._books_button.pressed.emit()
		var panel: Variant = bag._books_panel
		check("one actual child panel visible", panel != null and panel.visible
			and panel.get_parent() == bag.get_child(0))
		check("same FieldItemService, no second engine", is_same(panel.service, bag.service))
		check("single callback", panel.teaching_finished.get_connections().size() == 1)
		check("real inventory selection by ID", panel._selected(panel.books) == &"tm31")
		check("real Party selection by ID", panel._selected(panel.targets) == instance_id)
		if index == 0:
			check("229 books in one REAL FieldItemBag panel", panel.books.item_count == 229)
			for item: String in ES_SAMPLES:
				check("sample sourced book " + item, panel.select_book(StringName(item)))
				check("authentic Spanish shown " + item,
					panel.book_label.text.contains(String(ES_SAMPLES[item])))
			check("restore original MT", panel.select_book(&"tm31"))
		var before_cancel := _snapshot(collection)
		panel.select_replacement_slot(-1)
		panel.teach_button.pressed.emit()
		check("cancel with four moves, conserve state",
			not panel.last_result.get("accepted", false)
			and panel.last_result.get("reason", "") == "move_replacement_required"
			and _snapshot(collection) == before_cancel)
		bag._moves.select(index + 1)
		bag._moves.item_selected.emit(index + 1)
		check("real slot transmitted 0-3", panel._slot() == index
			and not panel.teach_button.disabled)
		var previous: StringName = collection.owned_creature(instance_id).moveset[index].move_id
		var old_qty: int = collection.inventory.quantity(&"tm31")
		var signals := {"all": 0, "applied": 0}
		panel.teaching_finished.connect(func(result: Dictionary):
			signals["all"] += 1
			if result.get("accepted", false): signals["applied"] += 1)
		panel.teach_button.pressed.emit()
		var current: CreatureInstance = collection.owned_creature(instance_id)
		var move: BattleMoveSlot = current.move_slot(&"metal_claw") if current != null else null
		var def: MoveDefinition = defs.move(&"metal_claw")
		check("one real MT learning", panel.last_result.get("accepted", false)
			and signals.applied == 1 and signals.all == 1
			and collection.inventory.quantity(&"tm31") == old_qty - 1)
		check("same owner and replaced exact move", current != null
			and current.instance_id == instance_id
			and current.moveset[index].move_id == &"metal_claw"
			and not current.has_move(previous)
			and collection.location_of(instance_id) == &"PARTY")
		check("canonical new move PP", move != null and def != null
			and move.current_pp == def.pp and move.max_pp == def.pp)
		var after_one := _snapshot(collection)
		panel.teach_button.pressed.emit()
		check("repeat event no second expense", not panel.last_result.get("accepted", false)
			and signals.applied == 1 and signals.all == 2
			and _snapshot(collection) == after_one)
		if index == 0:
			check("party to Storage", collection.deposit(instance_id))
			var before_storage := _snapshot(collection)
			panel.teach_button.pressed.emit()
			check("Storage target cannot consume",
				not panel.last_result.get("accepted", false)
				and _snapshot(collection) == before_storage)
			check("selected owner invalidated after deposit",
				panel._selected(panel.targets) == &"")
		if index == 1:
			# The only persisted data change is the explicit manual save.
			var saver: Node = scene._native_battles
			saver.save_path = SAVE
			for suffix: String in ["", ".tmp", ".bak"]:
				var p := SAVE + suffix
				if FileAccess.file_exists(p):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
			check("no automatic SaveV2 write", not FileAccess.file_exists(SAVE))
			bag.hide()
			check("manual SaveV2 writes", saver.save_game())
			var loaded: bool = await saver.load_game()
			var restored: PlayerCollection = scene.field_collection()
			var mon: CreatureInstance = restored.owned_creature(instance_id) if restored != null else null
			check("SaveV2 restored exact stock", loaded and restored != null
				and restored.inventory.quantity(&"tm31") == old_qty - 1)
			check("SaveV2 restored owner, move and PP", mon != null
				and mon.instance_id == instance_id
				and mon.moveset[index].move_id == &"metal_claw"
				and mon.move_slot(&"metal_claw").current_pp == def.pp)
			for suffix: String in ["", ".tmp", ".bak"]:
				var p := SAVE + suffix
				if FileAccess.file_exists(p):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
		if index == 2:
			bag.service.guard = func(): return false
			var before_lock := _snapshot(collection)
			panel.teach_button.pressed.emit()
			check("real session lock refuses without mutation",
				not panel.last_result.get("accepted", false)
				and _snapshot(collection) == before_lock)
			bag.service.guard = func(): return true
		if index == 3:
			check("second distinct item exists", collection.inventory.add(&"tm01", 1))
			check("external TM stock removal", collection.inventory.remove(&"tm31", 1))
			var before_stale := _snapshot(collection)
			panel.teach_button.pressed.emit()
			check("stale or removed book cannot mutate",
				not panel.last_result.get("accepted", false)
				and _snapshot(collection) == before_stale)
			panel.refresh()
			check("stale book does not silently select alternate",
				panel._selected(panel.books) != &"tm01")
		bag.hide()
		if index != 1:
			check("reopen real bag, no duplicate UI", bag.open_bag() and
				panel.teaching_finished.get_connections().size() == 2 and
				panel.get_parent() == bag.get_child(0))
		scene.queue_free()
		await process_frame
	done = true
	if failures.is_empty():
		print("W05_V4_REAL_FIELD_BAG PASS slots=4 es=229 one_panel=1 "
			+ "no_double_spend=1 stale=1 party_storage=1 savev2=1 "
			+ "no_autosave=1 rope_preserved=IA6_SMOKE checks=%d" % checks)
		quit(0)
	else:
		print("W05_V4_REAL_FIELD_BAG FAIL checks=%d errors=%s" %
			[checks, JSON.stringify(failures)])
		quit(1)
