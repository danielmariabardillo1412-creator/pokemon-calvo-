class_name SavegameV2TestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var tests := [
		"_test_v2_build_contract",
		"_test_v2_inventory_roundtrip",
		"_test_save_collection_uses_inventory",
		"_test_save_state_default_empty_inventory",
		"_test_save_rejects_corrupt_live_inventory",
		"_test_v2_missing_inventory_rejected",
		"_test_v2_wrong_inventory_type_rejected",
		"_test_v2_corrupt_quantity_rejected",
		"_test_v2_inventory_schema_rejected",
		"_test_v1_migrates_to_empty_inventory",
		"_test_v1_migration_preserves_party",
		"_test_v1_migration_preserves_storage",
		"_test_v1_does_not_trust_injected_inventory",
		"_test_migration_does_not_mutate_source",
		"_test_v1_reports_migration_metadata",
		"_test_v1_load_does_not_rewrite_file",
		"_test_resave_after_v1_migration_writes_v2",
		"_test_current_v2_reports_no_migration",
		"_test_mixed_v1_format_v2_schema_rejected",
		"_test_mixed_v2_format_v1_schema_rejected",
		"_test_future_v2_schema_rejected",
		"_test_inventory_failure_publishes_nothing",
		"_test_inventory_max_stack_roundtrip",
		"_test_inventory_serialization_stable",
	]
	for name in tests:
		print("SGV2_TEST %s" % name)
		self.call(name)


func _collection() -> PlayerCollection:
	return PlayerCollection.new()


func _creature(id: StringName, species: StringName = &"bulbasaur") -> CreatureInstance:
	return CreatureInstance.new(id, species, 5, StatBlock.new(20, 10, 10, 10, 10, 10), [])


func _write_dict(filename: String, d: Dictionary) -> String:
	var dir := "user://save_v2_suite"
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + "/" + filename
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return path


func _legacy_v1_from(pc: PlayerCollection) -> Dictionary:
	var d := SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict()
	d["schema_version"] = 1
	d["format_id"] = "calvo_save_v1"
	d.erase("inventory")
	return d


func _load_dict(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _test_v2_build_contract() -> void:
	var data := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new())
	var d := data.to_dict()
	_check.call("sgv2_version", data.schema_version == 2)
	_check.call("sgv2_format", data.format_id == &"calvo_save_v2")
	_check.call("sgv2_inventory_present", d.has("inventory") and d["inventory"] is Dictionary)
	_check.call("sgv2_valid", data.validate().ok)


func _test_v2_inventory_roundtrip() -> void:
	var pc := _collection()
	pc.inventory.add(&"poke_ball", 17)
	pc.inventory.add(&"great_ball", 4)
	var path := "user://save_v2_roundtrip.json"
	var repo := SaveGameRepository.new()
	var sr := repo.save_collection(path, pc)
	var lr := repo.load(path)
	_check.call("sgv2_roundtrip_save", sr.ok)
	_check.call("sgv2_roundtrip_load", lr.ok)
	_check.call("sgv2_roundtrip_poke", lr.inventory != null and lr.inventory.quantity(&"poke_ball") == 17)
	_check.call("sgv2_roundtrip_great", lr.inventory != null and lr.inventory.quantity(&"great_ball") == 4)


func _test_save_collection_uses_inventory() -> void:
	var pc := _collection()
	pc.inventory.add(&"ultra_ball", 8)
	var path := "user://save_v2_collection.json"
	var repo := SaveGameRepository.new()
	_check.call("sgv2_collection_save", repo.save_collection(path, pc).ok)
	var d := _load_dict(path)
	_check.call("sgv2_collection_inventory_written", int(d.get("inventory", {}).get("quantities", {}).get("ultra_ball", 0)) == 8)


func _test_save_state_default_empty_inventory() -> void:
	var path := "user://save_v2_state_default.json"
	var repo := SaveGameRepository.new()
	_check.call("sgv2_state_default_save", repo.save_state(path, CreatureParty.new(), CreatureStorage.new()).ok)
	var lr := repo.load(path)
	_check.call("sgv2_state_default_empty", lr.ok and lr.inventory != null and lr.inventory.is_empty())


func _test_save_rejects_corrupt_live_inventory() -> void:
	var pc := _collection()
	pc.inventory = PlayerInventory.from_dict({
		"schema_version": InventoryRuleset.SCHEMA_VERSION,
		"ruleset_id": String(InventoryRuleset.ID),
		"quantities": {"poke_ball": -1},
	})
	var sr := SaveGameRepository.new().save_collection("user://save_v2_corrupt_live.json", pc)
	_check.call("sgv2_corrupt_live_rejected", not sr.ok and sr.reason == "inventory_invalid_quantity")


func _test_v2_missing_inventory_rejected() -> void:
	var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
	d.erase("inventory")
	var lr := SaveGameRepository.new().load(_write_dict("missing_inventory.json", d))
	_check.call("sgv2_missing_inventory", not lr.ok and lr.reason == "invalid_inventory_type")


func _test_v2_wrong_inventory_type_rejected() -> void:
	var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
	d["inventory"] = []
	var lr := SaveGameRepository.new().load(_write_dict("wrong_inventory_type.json", d))
	_check.call("sgv2_wrong_inventory_type", not lr.ok and lr.reason == "invalid_inventory_type")


func _test_v2_corrupt_quantity_rejected() -> void:
	var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
	d["inventory"]["quantities"] = {"poke_ball": -2}
	var lr := SaveGameRepository.new().load(_write_dict("bad_quantity.json", d))
	_check.call("sgv2_bad_quantity", not lr.ok and lr.reason == "inventory_invalid_quantity")


func _test_v2_inventory_schema_rejected() -> void:
	var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
	d["inventory"]["schema_version"] = 999
	var lr := SaveGameRepository.new().load(_write_dict("bad_inventory_schema.json", d))
	_check.call("sgv2_bad_inventory_schema", not lr.ok and lr.reason == "inventory_unsupported_schema")


func _test_v1_migrates_to_empty_inventory() -> void:
	var d := _legacy_v1_from(_collection())
	var lr := SaveGameRepository.new().load(_write_dict("legacy_empty.json", d))
	_check.call("sgv2_v1_loads", lr.ok)
	_check.call("sgv2_v1_empty_inventory", lr.inventory != null and lr.inventory.is_empty())


func _test_v1_migration_preserves_party() -> void:
	var pc := _collection()
	pc.party.add_creature(_creature(&"legacy_party"))
	var lr := SaveGameRepository.new().load(_write_dict("legacy_party.json", _legacy_v1_from(pc)))
	_check.call("sgv2_v1_party_preserved", lr.ok and lr.party.contains_instance_id(&"legacy_party"))


func _test_v1_migration_preserves_storage() -> void:
	var pc := _collection()
	pc.storage.add_creature(_creature(&"legacy_storage", &"pikachu"))
	var lr := SaveGameRepository.new().load(_write_dict("legacy_storage.json", _legacy_v1_from(pc)))
	_check.call("sgv2_v1_storage_preserved", lr.ok and lr.storage.contains_instance_id(&"legacy_storage"))


func _test_v1_does_not_trust_injected_inventory() -> void:
	var d := _legacy_v1_from(_collection())
	d["inventory"] = {
		"schema_version": 1,
		"ruleset_id": "calvo_inventory_v1",
		"quantities": {"master_ball": 999},
	}
	var lr := SaveGameRepository.new().load(_write_dict("legacy_injected_inventory.json", d))
	_check.call("sgv2_v1_injected_inventory_ignored", lr.ok and lr.inventory.is_empty())


func _test_migration_does_not_mutate_source() -> void:
	var d := _legacy_v1_from(_collection())
	var before := d.duplicate(true)
	var result := SaveGameMigration.normalize(d)
	_check.call("sgv2_migration_ok", result.ok)
	_check.call("sgv2_migration_source_unchanged", d == before and not d.has("inventory"))


func _test_v1_reports_migration_metadata() -> void:
	var lr := SaveGameRepository.new().load(_write_dict("legacy_metadata.json", _legacy_v1_from(_collection())))
	_check.call("sgv2_migration_from_one", lr.ok and lr.schema_version == 2 and lr.migrated_from_version == 1)


func _test_v1_load_does_not_rewrite_file() -> void:
	var d := _legacy_v1_from(_collection())
	var path := _write_dict("legacy_no_rewrite.json", d)
	var before := SaveGameRepository.new()._serializer.read_raw(path)
	var lr := SaveGameRepository.new().load(path)
	var after := SaveGameRepository.new()._serializer.read_raw(path)
	_check.call("sgv2_v1_no_rewrite_load_ok", lr.ok)
	_check.call("sgv2_v1_no_rewrite", before == after)


func _test_resave_after_v1_migration_writes_v2() -> void:
	var lr := SaveGameRepository.new().load(_write_dict("legacy_resave_src.json", _legacy_v1_from(_collection())))
	var pc := PlayerCollection.new()
	pc.party = lr.party
	pc.storage = lr.storage
	pc.inventory = lr.inventory
	pc.inventory.add(&"poke_ball", 3)
	var dest := "user://legacy_resaved_v2.json"
	var repo := SaveGameRepository.new()
	var sr := repo.save_collection(dest, pc)
	var d := _load_dict(dest)
	_check.call("sgv2_resave_ok", sr.ok)
	_check.call("sgv2_resave_current", int(d.get("schema_version", 0)) == 2 and String(d.get("format_id", "")) == "calvo_save_v2")
	_check.call("sgv2_resave_inventory", int(d.get("inventory", {}).get("quantities", {}).get("poke_ball", 0)) == 3)


func _test_current_v2_reports_no_migration() -> void:
	var pc := _collection()
	var path := "user://current_v2_metadata.json"
	var repo := SaveGameRepository.new()
	repo.save_collection(path, pc)
	var lr := repo.load(path)
	_check.call("sgv2_current_no_migration", lr.ok and lr.migrated_from_version == 0)


func _test_mixed_v1_format_v2_schema_rejected() -> void:
	var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
	d["format_id"] = "calvo_save_v1"
	var lr := SaveGameRepository.new().load(_write_dict("mixed_old_format.json", d))
	_check.call("sgv2_mixed_old_format", not lr.ok and lr.reason == "unsupported_schema")


func _test_mixed_v2_format_v1_schema_rejected() -> void:
	var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
	d["schema_version"] = 1
	var lr := SaveGameRepository.new().load(_write_dict("mixed_old_schema.json", d))
	_check.call("sgv2_mixed_old_schema", not lr.ok and lr.reason == "unsupported_schema")


func _test_future_v2_schema_rejected() -> void:
	var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
	d["schema_version"] = 999
	var lr := SaveGameRepository.new().load(_write_dict("future_v2.json", d))
	_check.call("sgv2_future_rejected", not lr.ok and lr.reason == "unsupported_schema")


func _test_inventory_failure_publishes_nothing() -> void:
	var pc := _collection()
	pc.party.add_creature(_creature(&"dont_publish"))
	var d := SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict()
	d["inventory"]["quantities"] = {"poke_ball": -1}
	var lr := SaveGameRepository.new().load(_write_dict("transaction_inventory.json", d))
	_check.call("sgv2_transaction_failed", not lr.ok)
	_check.call("sgv2_transaction_party_null", lr.party == null)
	_check.call("sgv2_transaction_storage_null", lr.storage == null)
	_check.call("sgv2_transaction_inventory_null", lr.inventory == null)


func _test_inventory_max_stack_roundtrip() -> void:
	var pc := _collection()
	pc.inventory.add(&"poke_ball", InventoryRuleset.MAX_STACK)
	var path := "user://v2_max_stack.json"
	var repo := SaveGameRepository.new()
	var sr := repo.save_collection(path, pc)
	var lr := repo.load(path)
	_check.call("sgv2_max_stack", sr.ok and lr.ok and lr.inventory.quantity(&"poke_ball") == InventoryRuleset.MAX_STACK)


func _test_inventory_serialization_stable() -> void:
	var pc := _collection()
	pc.inventory.add(&"ultra_ball", 2)
	pc.inventory.add(&"great_ball", 3)
	pc.inventory.add(&"poke_ball", 4)
	var a := SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict()
	var b := SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict()
	_check.call("sgv2_inventory_stable", JSON.stringify(a["inventory"]) == JSON.stringify(b["inventory"]))
