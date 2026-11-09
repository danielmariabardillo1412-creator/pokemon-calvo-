extends SceneTree

# UI en Godot headless y FieldItemService real: NO certifica GPU.
const BookPanel = preload("res://scenes/visual/field_machine_book_panel.gd")
const Service = preload("res://modules/inventory/field_item_service.gd")
const Content = preload("res://modules/gameplay/randomlock_content_policy.gd")
const BookProfile = preload("res://modules/inventory/field_machine_book_profile.gd")
const SOURCE := "res://data/normalized/pokemon_api.json"
const SAVE := "user://w05_books_ui_pilot_only.json"
const MON := &"w05_books_pilot_mon"
var catalogs: DefinitionCatalog
var content := Content.new()
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("W05 BOOK UI: " + label)


func snapshot(owner: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(owner.party, owner.storage, owner.inventory).to_dict())


func compatible(species: CreatureSpecies, move_id: StringName) -> bool:
	if species == null:
		return false
	for entry: LearnSetEntry in species.learnset:
		if entry.method == "machine" and String(entry.version_group) == "scarlet-violet" and entry.move_id == move_id:
			return true
	return false


func find_species(move_id: StringName, should_match: bool) -> StringName:
	var ids: Array[String] = []
	for sid: StringName in catalogs.species_catalog.all_ids():
		if not content.species_allowed(String(sid)):
			continue
		var sp: CreatureSpecies = catalogs.species(sid)
		if sp == null or compatible(sp, move_id) != should_match:
			continue
		if not should_match:
			var has_sv := false
			for entry: LearnSetEntry in sp.learnset:
				if entry.method == "machine" and String(entry.version_group) == "scarlet-violet":
					has_sv = true
					break
			if not has_sv:
				continue
		ids.append(String(sid))
	ids.sort()
	return StringName(ids[0]) if not ids.is_empty() else &""


func make_service(species_id: StringName, need_four := false) -> Variant:
	var sp: CreatureSpecies = catalogs.species(species_id)
	check("species real " + String(species_id), sp != null)
	if sp == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261109
	var mon: CreatureInstance = CreatureFactory.create(sp, 50, catalogs,
		ProgressionRuleset.new(), rng, {"instance_id": MON, "moves": ["tackle", "protect"]})
	check("pokemon generated", mon != null)
	if mon == null:
		return null
	mon.moveset.clear()
	mon.move_ids.clear()
	if need_four:
		var four: Array[StringName] = []
		for entry: LearnSetEntry in sp.learnset:
			if entry.move_id == &"metal_claw" or four.has(entry.move_id):
				continue
			if catalogs.move(entry.move_id) == null or not content.move_learnable(String(entry.move_id)):
				continue
			four.append(entry.move_id)
			if four.size() == 4:
				break
		check("four real learnset slots", four.size() == 4)
		for move_id: StringName in four:
			check("initial move " + String(move_id), mon.add_move(move_id, catalogs))
	var owner := PlayerCollection.new()
	check("own creature", owner.party.add_creature(mon))
	var svc := Service.new()
	check("service configured", svc.configure(owner, catalogs, func(): return true))
	return svc


func mount(svc: Variant) -> Variant:
	var panel := BookPanel.new()
	root.add_child(panel)
	check("existing service bound", panel.bind_existing_service(svc))
	return panel


func clean() -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var path := SAVE + suffix
		if FileAccess.file_exists(path):
			check("remove temporary save " + suffix,
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)


func save_v2(owner: PlayerCollection, move_id: StringName, item_id: StringName, moves: int) -> void:
	clean()
	var repo := SaveGameRepository.new()
	var write: SaveResult = repo.save_collection(SAVE, owner)
	check("SaveV2 written", write.ok)
	if write.ok:
		var read: LoadResult = repo.load(SAVE)
		check("SaveV2 restored", read.ok)
		if read.ok:
			var mon: CreatureInstance = read.party.get_creature(MON)
			var slot: BattleMoveSlot = mon.move_slot(move_id) if mon != null else null
			var def: MoveDefinition = catalogs.move(move_id)
			check("SaveV2 identity party", mon != null and mon.instance_id == MON and read.storage.get_creature(MON) == null)
			check("SaveV2 retained move count", mon != null and mon.moveset.size() == moves)
			check("SaveV2 correct move PP", slot != null and def != null
				and slot.current_pp == def.pp and slot.max_pp == def.pp)
			check("SaveV2 stock exactly one", read.inventory.quantity(item_id) == 1)
	clean()


func test_book(item_id: StringName, move_id: StringName, spanish: String, type_es: String, replacement := false) -> void:
	var sid := find_species(move_id, true)
	check(String(item_id) + " species compatible", sid != &"")
	if sid == &"":
		return
	var svc: Variant = make_service(sid, replacement)
	if svc == null:
		return
	check(String(item_id) + " add 2 books", svc.owner.inventory.add(item_id, 2))
	var panel: Variant = mount(svc)
	check(String(item_id) + " selectable book", panel.select_book(item_id))
	check(String(item_id) + " selectable pokemon", panel.select_creature(MON))
	check(String(item_id) + " Spanish book title", panel.book_label.text.contains(spanish))
	check(String(item_id) + " Spanish book in bag", panel.books.get_item_text(panel.books.selected).contains(spanish))
	check(String(item_id) + " Spanish type", panel.type_label.text.contains(type_es))
	check(String(item_id) + " species learnset", compatible(catalogs.species(sid), move_id))
	check(String(item_id) + " positive preview", panel.compatibility_label.text.contains("Compatible"))
	var before := snapshot(svc.owner)
	if replacement:
		check("four existing moves", svc.owner.owned_creature(MON).moveset.size() == 4)
		panel.teach_button.pressed.emit()
		check("replacement mandatory no cost", not panel.last_result.get("accepted", false)
			and panel.last_result.get("reason", "") == "move_replacement_required" and snapshot(svc.owner) == before)
		check("select replacement index 1", panel.select_replacement_slot(1))
	else:
		check("stock deliberately removed", svc.owner.inventory.remove(item_id, 2))
		panel.teach_button.pressed.emit()
		check("stale UI no stock rejection", not panel.last_result.get("accepted", false)
			and panel.last_result.get("reason", "") == "item_not_owned" and svc.owner.inventory.quantity(item_id) == 0)
		check("stock replenished", svc.owner.inventory.add(item_id, 2))
		panel.refresh()
		check("reselect after refill", panel.select_book(item_id))
		check("reselect target after refill", panel.select_creature(MON))
	panel.teach_button.pressed.emit()
	var current: CreatureInstance = svc.owner.owned_creature(MON)
	var slot: BattleMoveSlot = current.move_slot(move_id) if current != null else null
	var def: MoveDefinition = catalogs.move(move_id)
	check(String(item_id) + " button teaches via original service",
		panel.last_result.get("accepted", false) and panel.last_result.get("action", "") == "teach"
		and panel.last_result.get("move_id", "") == String(move_id))
	check(String(item_id) + " consumed exactly one", svc.owner.inventory.quantity(item_id) == 1)
	check(String(item_id) + " same owner identity", current != null and current.instance_id == MON
		and svc.owner.location_of(MON) == &"PARTY")
	check(String(item_id) + " move PP", slot != null and def != null and slot.current_pp == def.pp and slot.max_pp == def.pp)
	check(String(item_id) + " correct move slots", current != null and current.moveset.size() == (4 if replacement else 1))
	check(String(item_id) + " result in Spanish", panel.result_label.text.contains(spanish))
	if replacement:
		check("slot 1 actually replaced", current != null and current.moveset[1].move_id == move_id)
	var after := snapshot(svc.owner)
	panel.teach_button.pressed.emit()
	check(String(item_id) + " known move no cost", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "move_already_known" and snapshot(svc.owner) == after)
	save_v2(svc.owner, move_id, item_id, 4 if replacement else 1)
	panel.queue_free()


func test_incompatible() -> void:
	var sid := find_species(&"pain_split", false)
	check("incompatible species exists", sid != &"")
	if sid == &"":
		return
	var svc: Variant = make_service(sid)
	if svc == null:
		return
	check("incompatible stock", svc.owner.inventory.add(&"tm202", 1))
	var panel: Variant = mount(svc)
	check("incompatible selected item", panel.select_book(&"tm202"))
	check("incompatible selected pokemon", panel.select_creature(MON))
	check("visible incompatible text", panel.compatibility_label.text.contains("Incompatible"))
	var before := snapshot(svc.owner)
	panel.teach_button.pressed.emit()
	check("incompatible service rejects", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "machine_incompatible")
	check("incompatible no state mutation", snapshot(svc.owner) == before)
	panel.queue_free()


func _run() -> void:
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	check("source available", source is Dictionary)
	if source is Dictionary:
		catalogs = GameData.from_dict(source).to_definition_catalog()
		check("catalogs loaded", catalogs != null)
		check("policy loaded", content.load_local())
		if catalogs != null and content.valid:
			var mapping: Variant = JSON.parse_string(FileAccess.get_file_as_string(Service.PROFILE))
			check("profile available", mapping is Dictionary)
			if mapping is Dictionary:
				for pair in [["tm202", "pain_split"], ["tm31", "metal_claw"]]:
					var p: Dictionary = BookProfile.presentacion(StringName(pair[0]), mapping, catalogs)
					check("presentacion real " + pair[0], p.get("disponible", false)
						and p.get("move_id", "") == pair[1] and String(p.get("nombre_tipo", "")).length() > 0)
				test_book(&"tm202", &"pain_split", "Divide Dolor", "Normal")
				test_book(&"tm31", &"metal_claw", "Garra Metal", "Acero", true)
				test_incompatible()
	if failures.is_empty():
		print("W05_BOOK_UI_PILOT_20261109_GODOT PASS checks=", checks)
		quit(0)
	else:
		print("W05_BOOK_UI_PILOT_20261109_GODOT FAIL checks=", checks, " failures=", failures)
		quit(1)
