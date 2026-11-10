extends SceneTree

# W05 AUTORUN V2 — one real PanelContainer + FieldItemService flow per canonical MT.
# The pilot01/02 runner and CAMP006 tests remain independent, unchanged and mandatory.
# Headless checks do NOT certify manual appearance, artwork, graphics or GPU.
const PanelClass = preload("res://scenes/visual/field_machine_book_panel.gd")
const ServiceClass = preload("res://modules/inventory/field_item_service.gd")
const ContentClass = preload("res://modules/gameplay/randomlock_content_policy.gd")
const Presentation = preload("res://modules/inventory/field_machine_book_profile.gd")
const SOURCE := "res://data/normalized/pokemon_api.json"
const FIXTURE := "res://tests/fixtures/parallel_items/w05_book_ui_autorun_v2.json"
const SAVE := "user://w05_books_autorun_v2_only.json"
const POKEMON := &"w05_books_autorun_v2_owned"

var catalogs: DefinitionCatalog
var policy := ContentClass.new()
var checks := 0
var failures: Array[String] = []
var outcomes: Array[Dictionary] = []
var functional := 0
var blocked := 0


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("W05 BOOKS AUTORUN: " + label)


func state(owner: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(owner.party, owner.storage, owner.inventory).to_dict())


func compatible(species: CreatureSpecies, move_id: StringName) -> bool:
	if species == null:
		return false
	for entry: LearnSetEntry in species.learnset:
		if entry.method == "machine" and String(entry.version_group) == "scarlet-violet" and entry.move_id == move_id:
			return true
	return false


func four_moves(species: CreatureSpecies, new_move: StringName) -> Array[StringName]:
	var found: Array[StringName] = []
	if species == null:
		return found
	for entry: LearnSetEntry in species.learnset:
		var mid: StringName = entry.move_id
		if mid == new_move or found.has(mid):
			continue
		if catalogs.move(mid) == null or not policy.move_learnable(String(mid)):
			continue
		found.append(mid)
		if found.size() == ProgressionRuleset.MOVE_SLOTS_MAX:
			break
	return found


func choose_species(move_id: StringName, should_match: bool, want_four := false) -> StringName:
	var available: Array[String] = []
	for id: StringName in catalogs.species_catalog.all_ids():
		if not policy.species_allowed(String(id)):
			continue
		var species: CreatureSpecies = catalogs.species(id)
		if species == null or compatible(species, move_id) != should_match:
			continue
		if want_four and four_moves(species, move_id).size() < ProgressionRuleset.MOVE_SLOTS_MAX:
			continue
		if not should_match:
			var has_sv := false
			for entry: LearnSetEntry in species.learnset:
				if entry.method == "machine" and String(entry.version_group) == "scarlet-violet":
					has_sv = true
					break
			if not has_sv:
				continue
		available.append(String(id))
	available.sort()
	return StringName(available[0]) if not available.is_empty() else &""


func new_service(species_id: StringName, new_move: StringName, fill_four: bool) -> Variant:
	var species: CreatureSpecies = catalogs.species(species_id)
	check("species exists " + String(species_id), species != null)
	if species == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261110
	var creature: CreatureInstance = CreatureFactory.create(species, 50, catalogs,
		ProgressionRuleset.new(), rng, {"instance_id": POKEMON, "moves": ["tackle", "protect"]})
	check("creature generated " + String(species_id), creature != null)
	if creature == null:
		return null
	creature.moveset.clear()
	creature.move_ids.clear()
	if fill_four:
		var choices := four_moves(species, new_move)
		check("four canonical moves available " + String(species_id),
			choices.size() == ProgressionRuleset.MOVE_SLOTS_MAX)
		for mid: StringName in choices:
			check("four-move setup " + String(mid), creature.add_move(mid, catalogs))
	var owner := PlayerCollection.new()
	check("party owns creature " + String(species_id), owner.party.add_creature(creature))
	var svc := ServiceClass.new()
	check("original service configured " + String(species_id),
		svc.configure(owner, catalogs, func(): return true))
	return svc


func mount(service: Variant) -> Variant:
	var panel := PanelClass.new()
	root.add_child(panel)
	check("bind original live service", panel.bind_existing_service(service))
	return panel


func clear_save() -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var filename := SAVE + suffix
		if FileAccess.file_exists(filename):
			check("remove W05 test save", DirAccess.remove_absolute(ProjectSettings.globalize_path(filename)) == OK)


func check_save(owner: PlayerCollection, item_id: StringName, move_id: StringName, old_move: StringName) -> void:
	clear_save()
	var repo := SaveGameRepository.new()
	var write: SaveResult = repo.save_collection(SAVE, owner)
	check(String(item_id) + " SaveV2 created", write.ok)
	if write.ok:
		var read: LoadResult = repo.load(SAVE)
		check(String(item_id) + " SaveV2 read", read.ok)
		if read.ok:
			var mon: CreatureInstance = read.party.get_creature(POKEMON)
			var def: MoveDefinition = catalogs.move(move_id)
			var slot: BattleMoveSlot = mon.move_slot(move_id) if mon != null else null
			check(String(item_id) + " SaveV2 same owner", mon != null
				and mon.instance_id == POKEMON and read.storage.get_creature(POKEMON) == null)
			check(String(item_id) + " SaveV2 four moves", mon != null
				and mon.moveset.size() == ProgressionRuleset.MOVE_SLOTS_MAX)
			check(String(item_id) + " SaveV2 replacement", mon != null
				and mon.moveset[1].move_id == move_id and not mon.has_move(old_move))
			check(String(item_id) + " SaveV2 PP", slot != null and def != null
				and slot.current_pp == def.pp and slot.max_pp == def.pp)
			check(String(item_id) + " SaveV2 stock one", read.inventory.quantity(item_id) == 1)
	clear_save()


func test_incompatible(item_id: StringName, move_id: StringName) -> bool:
	var species_id := choose_species(move_id, false)
	if species_id == &"":
		return false
	var svc: Variant = new_service(species_id, move_id, false)
	if svc == null:
		return false
	check(String(item_id) + " negative stock created", svc.owner.inventory.add(item_id, 1))
	var panel: Variant = mount(svc)
	check(String(item_id) + " negative book selected", panel.select_book(item_id))
	check(String(item_id) + " negative party selected", panel.select_creature(POKEMON))
	check(String(item_id) + " incompatible preview", panel.compatibility_label.text.contains("Incompatible")
		and panel.teach_button.disabled)
	var before := state(svc.owner)
	panel.teach_button.pressed.emit()
	check(String(item_id) + " incompatible rejects with no spend",
		not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "machine_incompatible"
		and state(svc.owner) == before)
	panel.queue_free()
	return true


func test_book(item: Dictionary, block: String) -> bool:
	var item_id := StringName(item.get("item_id", ""))
	var move_id := StringName(item.get("move_id", ""))
	var label := block + "/" + String(item_id)
	var errors_before := failures.size()
	var presentation: Dictionary = Presentation.presentacion(item_id,
		JSON.parse_string(FileAccess.get_file_as_string(ServiceClass.PROFILE)), catalogs)
	check(label + " presentation available", presentation.get("disponible", false))
	check(label + " active canonical move", presentation.get("move_id", "") == String(move_id)
		and presentation.get("version", "") == "scarlet-violet")
	check(label + " Spanish type and textual label", String(presentation.get("nombre_tipo", "")).length() > 0
		and String(presentation.get("nombre_movimiento", "")).length() > 0
		and String(presentation.get("etiqueta", "")).begins_with("Libro de movimiento"))
	var compatible_id := choose_species(move_id, true, true)
	if compatible_id == &"":
		outcomes.append({"block": block, "item_id": String(item_id),
			"status": "BLOQUEADO", "reason": "no_eligible_species_with_4_moves_from_canonical_learnset"})
		return false
	var svc: Variant = new_service(compatible_id, move_id, true)
	if svc == null:
		outcomes.append({"block": block, "item_id": String(item_id),
			"status": "BLOQUEADO", "reason": "creature_creation_or_service"})
		return false
	check(label + " two books", svc.owner.inventory.add(item_id, 2))
	var panel: Variant = mount(svc)
	check(label + " real selected book", panel.select_book(item_id))
	check(label + " real selected party", panel.select_creature(POKEMON))
	var expected_name := String(presentation.get("nombre_movimiento", ""))
	if move_id == &"pain_split":
		expected_name = "Divide Dolor"
	elif move_id == &"metal_claw":
		expected_name = "Garra Metal"
	check(label + " book label Spanish from presentation",
		panel.book_label.text.contains(expected_name) and panel.books.get_item_text(panel.books.selected).contains(expected_name))
	check(label + " Spanish type from presentation",
		panel.type_label.text.contains(String(presentation.get("nombre_tipo", ""))))
	check(label + " real machine learnset", compatible(catalogs.species(compatible_id), move_id))
	check(label + " four moves require replacement", panel.teach_button.disabled
		and panel.compatibility_label.text.contains("elige"))
	var before := state(svc.owner)
	panel.teach_button.pressed.emit()
	check(label + " no replacement cannot spend", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "move_replacement_required" and state(svc.owner) == before)
	# Simulate the inventory being consumed elsewhere while the UI is still visible.
	check(label + " remove stale stock", svc.owner.inventory.remove(item_id, 2))
	panel._refresh_compatibility()
	check(label + " no-stock button disabled", panel.teach_button.disabled
		and panel.compatibility_label.text.contains("Sin existencias"))
	before = state(svc.owner)
	panel.teach_button.pressed.emit()
	check(label + " no-stock no mutation", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "item_not_owned" and state(svc.owner) == before)
	check(label + " restore books", svc.owner.inventory.add(item_id, 2))
	panel.refresh()
	check(label + " select refreshed book", panel.select_book(item_id))
	check(label + " select refreshed pokemon", panel.select_creature(POKEMON))
	# Existing service guard is authoritative for session/context lock.
	svc.guard = func(): return false
	panel._refresh_compatibility()
	check(label + " locked button", panel.teach_button.disabled
		and panel.compatibility_label.text.contains("No puedes enseñar"))
	before = state(svc.owner)
	panel.teach_button.pressed.emit()
	check(label + " locked cannot spend", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "field_locked" and state(svc.owner) == before)
	svc.guard = func(): return true
	panel._refresh_compatibility()
	check(label + " choose replacement index", panel.select_replacement_slot(1))
	check(label + " approved preview enabled", not panel.teach_button.disabled)
	var original: CreatureInstance = svc.owner.owned_creature(POKEMON)
	var old_move: StringName = original.moveset[1].move_id
	panel.teach_button.pressed.emit()
	var current: CreatureInstance = svc.owner.owned_creature(POKEMON)
	var slot: BattleMoveSlot = current.move_slot(move_id) if current != null else null
	var definition: MoveDefinition = catalogs.move(move_id)
	check(label + " one real teach via button", panel.last_result.get("accepted", false)
		and panel.last_result.get("action", "") == "teach" and panel.last_result.get("move_id", "") == String(move_id))
	check(label + " exactly one book consumed", svc.owner.inventory.quantity(item_id) == 1)
	check(label + " identity and party stable", current != null and current.instance_id == POKEMON
		and svc.owner.location_of(POKEMON) == &"PARTY")
	check(label + " replaced exact slot", current != null
		and current.moveset.size() == ProgressionRuleset.MOVE_SLOTS_MAX
		and current.moveset[1].move_id == move_id and not current.has_move(old_move))
	check(label + " PP canonical", slot != null and definition != null
		and slot.current_pp == definition.pp and slot.max_pp == definition.pp)
	check(label + " learned Spanish confirmation", panel.result_label.text.contains(expected_name))
	check(label + " known move disabled", panel.teach_button.disabled
		and panel.compatibility_label.text.contains("Ya conoce"))
	before = state(svc.owner)
	panel.teach_button.pressed.emit()
	check(label + " no repeat spend", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "move_already_known" and state(svc.owner) == before)
	check_save(svc.owner, item_id, move_id, old_move)
	panel.queue_free()
	var negative_found := test_incompatible(item_id, move_id)
	if not negative_found:
		outcomes.append({"block": block, "item_id": String(item_id),
			"status": "BLOQUEADO", "reason": "no_permitted_incompatible_species_with_SV_context"})
		return false
	var is_pass := failures.size() == errors_before
	outcomes.append({"block": block, "item_id": String(item_id),
		"move_id": String(move_id), "species_id": String(compatible_id),
		"status": "CERTIFICABLE" if is_pass else "FAIL"})
	return is_pass


func _run() -> void:
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	check("fixture exists", fixture is Dictionary)
	check("normalized data exists", data is Dictionary)
	if fixture is Dictionary and data is Dictionary:
		catalogs = GameData.from_dict(data).to_definition_catalog()
		check("live catalogs", catalogs != null)
		check("content policy", policy.load_local())
		check("fixture 10 rows", fixture.get("schema_version", 0) == 1
			and fixture.get("worker", "") == "W05" and fixture.get("campaign", "") == "AUTORUN_V2"
			and fixture.get("active_version", "") == "scarlet-violet")
		var blocks: Array = fixture.get("blocks", [])
		check("10 groups present", blocks.size() == 10)
		var seen: Dictionary = {}
		if catalogs != null and policy.valid and blocks.size() == 10:
			for i in range(blocks.size()):
				var group: Dictionary = blocks[i]
				var block := "%02d" % (i + 1)
				check("exact ordered group " + block, group.get("block", "") == block)
				var items: Array = group.get("items", [])
				check("group quota " + block, items.size() == 18)
				var positives := 0
				var blocks_pending := 0
				var start_checks := checks
				for raw: Variant in items:
					var item: Dictionary = raw
					var item_id := String(item.get("item_id", ""))
					check("unique id " + item_id, not seen.has(item_id))
					seen[item_id] = true
					if test_book(item, block):
						positives += 1
						functional += 1
					else:
						blocks_pending += 1
						blocked += 1
				print("W05_BOOKS_AUTORUN_V2_GROUP block=%s status=%s ids=%d functional=%d blocked=%d checks=%d" %
					[block, "CERTIFICABLE" if blocks_pending == 0 else "BLOQUEADO",
					items.size(), positives, blocks_pending, checks - start_checks])
		check("exactly 49 distinct IDs", seen.size() == 49)
	if failures.is_empty():
		print("W05_BOOKS_AUTORUN_V2_GODOT PASS blocks=10 ids=49 functional=%d blocked=%d checks=%d" %
			[functional, blocked, checks])
		quit(0)
	else:
		print("W05_BOOKS_AUTORUN_V2_GODOT FAIL blocks=10 ids=49 functional=%d blocked=%d checks=%d errors=%s" %
			[functional, blocked, checks, str(failures)])
		quit(1)
