class_name SavegameV2AdversarialTestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	_test_migration_metadata_shapes()
	_test_inventory_metadata_shapes()
	_test_repository_rejects_hostile_inventory_shapes()


func _test_migration_metadata_shapes() -> void:
	var base := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()

	var bad_format := base.duplicate(true)
	bad_format["format_id"] = {"not": "a string"}
	var r := SaveGameMigration.normalize(bad_format)
	_check.call("sgv2_adv_format_type", not r.ok and r.reason == "invalid_format_type")

	var bad_schema := base.duplicate(true)
	bad_schema["schema_version"] = {"not": "a number"}
	r = SaveGameMigration.normalize(bad_schema)
	_check.call("sgv2_adv_schema_type", not r.ok and r.reason == "invalid_schema_type")

	var fractional_schema := base.duplicate(true)
	fractional_schema["schema_version"] = 2.5
	r = SaveGameMigration.normalize(fractional_schema)
	_check.call("sgv2_adv_schema_fraction", not r.ok and r.reason == "invalid_schema_value")


func _test_inventory_metadata_shapes() -> void:
	var bad_schema := {
		"schema_version": {"bad": true},
		"ruleset_id": String(InventoryRuleset.ID),
		"quantities": {},
	}
	var inv := PlayerInventory.from_dict(bad_schema)
	_check.call("sgv2_adv_inv_schema_type", inv.corrupted and inv.corruption_reason == "invalid_schema_type")

	var bad_ruleset := {
		"schema_version": InventoryRuleset.SCHEMA_VERSION,
		"ruleset_id": ["bad"],
		"quantities": {},
	}
	inv = PlayerInventory.from_dict(bad_ruleset)
	_check.call("sgv2_adv_inv_ruleset_type", inv.corrupted and inv.corruption_reason == "invalid_ruleset_type")

	var bad_item_id := {
		"schema_version": InventoryRuleset.SCHEMA_VERSION,
		"ruleset_id": String(InventoryRuleset.ID),
		"quantities": {7: 1},
	}
	inv = PlayerInventory.from_dict(bad_item_id)
	_check.call("sgv2_adv_inv_item_id_type", inv.corrupted and inv.corruption_reason == "invalid_item_id_type")


func _test_repository_rejects_hostile_inventory_shapes() -> void:
	var dir := "user://save_v2_adversarial"
	DirAccess.make_dir_recursive_absolute(dir)

	var cases := [
		["inv_schema_type.json", "schema_version", {"bad": true}, "inventory_invalid_schema_type"],
		["inv_ruleset_type.json", "ruleset_id", ["bad"], "inventory_invalid_ruleset_type"],
	]

	for case in cases:
		var d := SaveGameData.build(CreatureParty.new(), CreatureStorage.new(), PlayerInventory.new()).to_dict()
		d["inventory"][case[1]] = case[2]
		var path := dir + "/" + case[0]
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(d))
		f.close()
		var lr := SaveGameRepository.new().load(path)
		_check.call("sgv2_adv_repo_%s" % case[1], not lr.ok and lr.reason == case[3] and lr.party == null and lr.storage == null and lr.inventory == null)
