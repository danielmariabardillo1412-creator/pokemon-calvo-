extends SceneTree

# W05 CAMP004: prueba acumulativa SOLO de los bloques aprobados en progreso.
# Reutiliza FieldItemService.teach, PlayerCollection y SaveGameRepository.
const Service = preload("res://modules/inventory/field_item_service.gd")
const Content = preload("res://modules/gameplay/randomlock_content_policy.gd")
const FIXTURE := "res://tests/fixtures/parallel_items/w05_campaign_004.json"
const SOURCE := "res://data/normalized/pokemon_api.json"
const PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv"
const QUEUE := "res://docs/coordination/items_parallel_v1/CAMPAIGN_004_W05_QUEUE_APPROVED.csv"
const SAVE := "user://w05_camp004_test_only.json"
const REPORT := "user://w05_camp004_report_only.json"
const POKEMON := &"w05_camp004_pokemon"

var catalogs: DefinitionCatalog
var content := Content.new()
var checks := 0
var errors: Array[String] = []
var results: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_execute")


func check(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		errors.append(label)
		push_error("CAMP004 W05: " + label)


func snapshot(owner: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(owner.party, owner.storage, owner.inventory).to_dict())


func is_compatible(species: CreatureSpecies, move_id: StringName) -> bool:
	if species == null:
		return false
	for entry: LearnSetEntry in species.learnset:
		if entry.method == "machine" and String(entry.version_group) == "scarlet-violet" and entry.move_id == move_id:
			return true
	return false


func first_compatible(move_id: StringName) -> StringName:
	var found: Array[String] = []
	for id: StringName in catalogs.species_catalog.all_ids():
		if content.species_allowed(String(id)) and is_compatible(catalogs.species(id), move_id):
			found.append(String(id))
	found.sort()
	return StringName(found[0]) if not found.is_empty() else &""


func first_incompatible(move_id: StringName) -> StringName:
	for id: StringName in catalogs.species_catalog.all_ids():
		if not content.species_allowed(String(id)):
			continue
		var species: CreatureSpecies = catalogs.species(id)
		if species == null or is_compatible(species, move_id):
			continue
		for entry: LearnSetEntry in species.learnset:
			if entry.method == "machine" and String(entry.version_group) == "scarlet-violet":
				return id
	return &""


func service_for(species_id: StringName) -> RefCounted:
	var species: CreatureSpecies = catalogs.species(species_id)
	check(String(species_id) + "/species_defined", species != null)
	if species == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261103
	var creature: CreatureInstance = CreatureFactory.create(species, 50, catalogs,
		ProgressionRuleset.new(), rng, {"instance_id": POKEMON, "moves": ["tackle", "protect"]})
	check(String(species_id) + "/creature_created", creature != null)
	if creature == null:
		return null
	creature.moveset.clear()
	creature.move_ids.clear()
	var owner := PlayerCollection.new()
	check(String(species_id) + "/party_owns", owner.party.add_creature(creature))
	var service := Service.new()
	check(String(species_id) + "/configured", service.configure(owner, catalogs, func(): return true))
	return service


func cleanup_save() -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var p := SAVE + suffix
		if FileAccess.file_exists(p):
			check("delete_temporary_save/" + suffix,
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p)) == OK)


func read_csv(path: String) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file := FileAccess.open(path, FileAccess.READ)
	check(path + "/readable", file != null)
	if file == null:
		return rows
	file.get_csv_line()
	while not file.eof_reached():
		var fields := file.get_csv_line()
		if fields.size() > 1 and not String(fields[0]).is_empty():
			rows.append(fields)
	file.close()
	return rows


func authorized() -> Array[Dictionary]:
	var queued := read_csv(QUEUE)
	var progressed := read_csv(PROGRESS)
	var own: Array[PackedStringArray] = []
	for row: PackedStringArray in queued:
		if row.size() >= 4 and row[1] == "W05":
			own.append(row)
	check("ten_blocks_in_approved_queue", own.size() == 10)
	check("between_1_and_10_progress", progressed.size() >= 1 and progressed.size() <= 10)
	var approved: Array[Dictionary] = []
	for i in range(progressed.size()):
		if i >= own.size():
			break
		var row: PackedStringArray = progressed[i]
		var assignment: PackedStringArray = own[i]
		var block := "%02d" % (i + 1)
		check(block + "/progress_columns", row.size() >= 6)
		if row.size() < 6:
			continue
		check(block + "/progress_exact_approval", row[0] == block
			and assignment[0] == block and row[1] == assignment[3])
		var ids: Array = []
		for id: String in String(assignment[3]).split(";"):
			ids.append(id)
		check(block + "/exactly_six_ids", ids.size() == 6)
		approved.append({"block": block, "ids": ids})
	return approved


func test_teach(block: String, record: Dictionary) -> void:
	var item_id := StringName(record.get("item_id", ""))
	var move_id := StringName(record.get("move_id", ""))
	var label := block + "/" + String(item_id)
	var start_errors := errors.size()
	var species_id := first_compatible(move_id)
	check(label + "/learnset_scarlet_violet", species_id != &"")
	if species_id == &"":
		results.append({"block": block, "item_id": String(item_id), "status": "SIN_LEARNSET"})
		return
	var service := service_for(species_id)
	if service == null:
		results.append({"block": block, "item_id": String(item_id), "status": "FAIL_SERVICE"})
		return
	var owner: PlayerCollection = service.owner
	check(label + "/profile_mapping", service.machine_move(item_id) == move_id)
	check(label + "/compatible_real", is_compatible(catalogs.species(species_id), move_id))
	check(label + "/allowed_move", content.move_learnable(String(move_id)))
	var before := snapshot(owner)
	var rejected: Dictionary = service.teach(item_id, POKEMON)
	check(label + "/no_stock", not rejected.get("accepted", false)
		and rejected.get("reason", "") == "item_not_owned" and snapshot(owner) == before)
	check(label + "/add_two", owner.inventory.add(item_id, 2))
	before = snapshot(owner)
	rejected = service.teach(item_id, &"w05_camp004_not_owned")
	check(label + "/wrong_owner", not rejected.get("accepted", false)
		and rejected.get("reason", "") == "creature_not_owned" and snapshot(owner) == before)
	var incompatible_id := first_incompatible(move_id)
	check(label + "/negative_species_found", incompatible_id != &"")
	if incompatible_id != &"":
		var invalid := service_for(incompatible_id)
		if invalid != null:
			check(label + "/negative_stock", invalid.owner.inventory.add(item_id, 2))
			var negative_before := snapshot(invalid.owner)
			var denied: Dictionary = invalid.teach(item_id, POKEMON)
			check(label + "/incompatible_rejected_without_mutation",
				not denied.get("accepted", false)
				and denied.get("reason", "") == "machine_incompatible"
				and snapshot(invalid.owner) == negative_before)
	var answer: Dictionary = service.teach(item_id, POKEMON)
	var current: CreatureInstance = owner.owned_creature(POKEMON)
	check(label + "/service_teach", answer.get("accepted", false)
		and answer.get("action", "") == "teach" and answer.get("move_id", "") == String(move_id)
		and answer.get("version", "") == "scarlet-violet")
	check(label + "/one_consumed", owner.inventory.quantity(item_id) == 1)
	check(label + "/identity_and_party", current != null
		and current.instance_id == POKEMON and owner.location_of(POKEMON) == &"PARTY")
	var definition: MoveDefinition = catalogs.move(move_id)
	check(label + "/move_definition", definition != null)
	if current != null and definition != null:
		var slot: BattleMoveSlot = current.move_slot(move_id)
		check(label + "/correct_pp", slot != null and current.moveset.size() == 1
			and slot.current_pp == definition.pp and slot.max_pp == definition.pp)
	before = snapshot(owner)
	rejected = service.teach(item_id, POKEMON)
	check(label + "/known_move_no_double_cost", not rejected.get("accepted", false)
		and rejected.get("reason", "") == "move_already_known" and snapshot(owner) == before)
	cleanup_save()
	var saves := SaveGameRepository.new()
	var write: SaveResult = saves.save_collection(SAVE, owner)
	check(label + "/save_v2_written", write.ok)
	if write.ok:
		var read: LoadResult = saves.load(SAVE)
		check(label + "/save_v2_readable", read.ok)
		if read.ok:
			var restored: CreatureInstance = read.party.get_creature(POKEMON)
			var restored_slot: BattleMoveSlot = restored.move_slot(move_id) if restored != null else null
			check(label + "/save_v2_same_instance_and_owner", restored != null
				and restored.instance_id == POKEMON and read.storage.get_creature(POKEMON) == null)
			check(label + "/save_v2_move_and_pp", restored_slot != null and definition != null
				and restored_slot.current_pp == definition.pp and restored_slot.max_pp == definition.pp)
			check(label + "/save_v2_one_item_left", read.inventory.quantity(item_id) == 1)
	cleanup_save()
	results.append({"block": block, "item_id": String(item_id), "move_id": String(move_id),
		"species_id": String(species_id), "status": "PASS" if errors.size() == start_errors else "FAIL"})


func _execute() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var profile: Variant = JSON.parse_string(FileAccess.get_file_as_string(Service.PROFILE))
	check("fixture_json", raw is Dictionary)
	check("normalized_json", data is Dictionary)
	check("profile_json", profile is Dictionary)
	if raw is Dictionary and data is Dictionary and profile is Dictionary:
		check("fixture_campaign", raw.get("campaign", "") == "CAMP_004_W05"
			and raw.get("schema_version", 0) == 1)
		check("scarlet_violet_only", raw.get("active_version", "") == "scarlet-violet"
			and profile.get("active_machine_version", "") == "scarlet-violet")
		check("policy_loaded", content.load_local())
		catalogs = GameData.from_dict(data).to_definition_catalog()
		check("catalog_created", catalogs != null)
		var blocks := authorized()
		var all_blocks: Array = raw.get("blocks", [])
		check("fixture_progress_same_size", blocks.size() == all_blocks.size())
		var seen := {}
		if content.valid and catalogs != null and blocks.size() == all_blocks.size():
			for i in range(blocks.size()):
				var assignment: Dictionary = blocks[i]
				var group: Dictionary = all_blocks[i]
				var block := String(assignment.block)
				check(block + "/fixture_block", group.get("block", "") == block)
				var items: Array = group.get("items", [])
				var ids: Array = assignment.ids
				check(block + "/six_cases", items.size() == 6)
				if items.size() != 6 or ids.size() != 6:
					continue
				for j in range(6):
					var record: Dictionary = items[j]
					var item_id := String(record.get("item_id", ""))
					var move_id := String(record.get("move_id", ""))
					check(block + "/exact_id_at_index_" + str(j), item_id == String(ids[j]))
					check(block + "/not_repeated_" + item_id, not seen.has(item_id))
					seen[item_id] = true
					check(block + "/catalog_item_" + item_id, catalogs.item(StringName(item_id)) != null)
					check(block + "/sv_mapping_" + item_id,
						String(profile.get("machine_rows", {}).get(item_id, {}).get("scarlet-violet", "")) == move_id
						and not move_id.is_empty())
					if item_id == String(ids[j]) and not move_id.is_empty():
						test_teach(block, record)
	check("all_six_per_block_exercised", results.size() == 6 * read_csv(PROGRESS).size())
	for row: Dictionary in results:
		check("teach_case_result_" + String(row.get("item_id", "")), row.get("status", "") == "PASS")
	var blocks_done := read_csv(PROGRESS).size()
	var report := {"campaign": "CAMP_004_W05", "status": "PASS" if errors.is_empty() else "FAIL",
		"blocks": blocks_done, "checks": checks, "cases": results,
		"errors": errors, "source": "FieldItemService.teach", "visual_gpu": false}
	var output := FileAccess.open(REPORT, FileAccess.WRITE)
	check("report_writable", output != null)
	if output != null:
		report["status"] = "PASS" if errors.is_empty() else "FAIL"
		report["checks"] = checks
		report["errors"] = errors
		output.store_string(JSON.stringify(report, "  "))
		output.close()
	if errors.is_empty() and blocks_done > 0:
		print("CAMP004_W05_GODOT PASS blocks=", blocks_done, " checks=", checks)
		quit(0)
	else:
		print("CAMP004_W05_GODOT FAIL blocks=", blocks_done, " checks=", checks, " errors=", errors.size())
		quit(2)
