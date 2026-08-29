class_name InventoryTestSuite
extends RefCounted

# FASE 9A: deterministic bag + capture-consumption bridge.
# The suite deliberately keeps CaptureSystem item-agnostic and tests the upper-layer transaction.

var _check: Callable
var _gd: GameData
var _catalog: DefinitionCatalog


func run(check_callback: Callable) -> void:
	_check = check_callback
	_gd = _import_pokeapi()
	_catalog = _gd.to_definition_catalog()
	var tests := [
		"_test_inventory_empty",
		"_test_inventory_add_remove",
		"_test_inventory_overflow_no_mutation",
		"_test_inventory_invalid_inputs",
		"_test_inventory_set_zero_removes",
		"_test_inventory_deterministic_order",
		"_test_inventory_roundtrip",
		"_test_inventory_corrupt_payloads",
		"_test_capture_missing_inventory_rejected_without_rng",
		"_test_capture_missing_ball_rejected_without_rng",
		"_test_capture_validation_precedes_inventory",
		"_test_capture_invalid_trainer_does_not_consume",
		"_test_capture_failure_consumes_one",
		"_test_capture_master_consumes_one_and_preserves_identity",
		"_test_capture_master_does_not_consume_rng",
		"_test_capture_full_party_consumes_and_requires_storage",
		"_test_capture_corrupt_inventory_rejected_without_rng",
	]
	for t in tests:
		print("INV_TEST %s" % t)
		self.call(t)


func _import_pokeapi() -> GameData:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	var res := DataImporter.new().import_dataset(raw, manifest)
	return res["game_data"]


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text()) as Dictionary


func _species(id: StringName) -> CreatureSpecies:
	return _catalog.species_catalog.get_by_id(id)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _wild(id: StringName, level: int, seed_value: int) -> CreatureInstance:
	return CreatureFactory.create(
		_species(id), level, _catalog, ProgressionRuleset.new(), _rng(seed_value), {}
	)


func _wild_context() -> CaptureBattleContext:
	var c := CaptureBattleContext.new()
	c.is_wild = true
	return c


func _trainer_context() -> CaptureBattleContext:
	var c := CaptureBattleContext.new()
	c.is_wild = false
	c.target_owner_trainer_id = &"trainer_b"
	return c


func _attempt(target: CreatureInstance, ball_id: StringName, ctx: CaptureBattleContext) -> CaptureAttempt:
	return CaptureAttempt.new(target, ball_id, ctx)


func _inventory_with(item_id: StringName, amount: int) -> PlayerInventory:
	var inv := PlayerInventory.new()
	inv.add(item_id, amount)
	return inv


func _test_inventory_empty() -> void:
	var inv := PlayerInventory.new()
	_check.call("inv_empty", inv.is_empty() and inv.item_count() == 0)
	_check.call("inv_empty_quantity", inv.quantity(&"poke_ball") == 0 and not inv.has(&"poke_ball"))


func _test_inventory_add_remove() -> void:
	var inv := PlayerInventory.new()
	_check.call("inv_add_first", inv.add(&"poke_ball", 2) and inv.quantity(&"poke_ball") == 2)
	_check.call("inv_add_accumulates", inv.add(&"poke_ball", 3) and inv.quantity(&"poke_ball") == 5)
	_check.call("inv_has_amount", inv.has(&"poke_ball", 5) and not inv.has(&"poke_ball", 6))
	_check.call("inv_remove_partial", inv.remove(&"poke_ball", 4) and inv.quantity(&"poke_ball") == 1)
	_check.call("inv_remove_last_erases", inv.remove(&"poke_ball", 1) and inv.is_empty())


func _test_inventory_overflow_no_mutation() -> void:
	var inv := PlayerInventory.new()
	inv.add(&"ultra_ball", InventoryRuleset.MAX_STACK)
	var before := inv.quantity(&"ultra_ball")
	_check.call("inv_overflow_rejected", not inv.add(&"ultra_ball", 1))
	_check.call("inv_overflow_unchanged", inv.quantity(&"ultra_ball") == before)


func _test_inventory_invalid_inputs() -> void:
	var inv := PlayerInventory.new()
	_check.call("inv_empty_id_rejected", not inv.add(&"", 1))
	_check.call("inv_zero_add_rejected", not inv.add(&"poke_ball", 0))
	_check.call("inv_negative_add_rejected", not inv.add(&"poke_ball", -1))
	_check.call("inv_remove_missing_rejected", not inv.remove(&"poke_ball", 1) and inv.is_empty())


func _test_inventory_set_zero_removes() -> void:
	var inv := PlayerInventory.new()
	_check.call("inv_set_quantity", inv.set_quantity(&"great_ball", 7) and inv.quantity(&"great_ball") == 7)
	_check.call("inv_set_zero_erases", inv.set_quantity(&"great_ball", 0) and not inv.has(&"great_ball") and inv.item_count() == 0)


func _test_inventory_deterministic_order() -> void:
	var inv := PlayerInventory.new()
	inv.add(&"ultra_ball", 1)
	inv.add(&"great_ball", 1)
	inv.add(&"poke_ball", 1)
	_check.call("inv_sorted_ids", inv.all_item_ids() == [&"great_ball", &"poke_ball", &"ultra_ball"])


func _test_inventory_roundtrip() -> void:
	var inv := PlayerInventory.new()
	inv.add(&"poke_ball", 12)
	inv.add(&"master_ball", 1)
	var restored := PlayerInventory.from_dict(JSON.parse_string(JSON.stringify(inv.to_dict())) as Dictionary)
	_check.call("inv_roundtrip_not_corrupt", not restored.corrupted)
	_check.call("inv_roundtrip_quantities", restored.quantity(&"poke_ball") == 12 and restored.quantity(&"master_ball") == 1)
	_check.call("inv_roundtrip_stable", JSON.stringify(restored.to_dict()) == JSON.stringify(inv.to_dict()))


func _test_inventory_corrupt_payloads() -> void:
	var missing_schema := PlayerInventory.from_dict({"ruleset_id": "calvo_inventory_v1", "quantities": {}})
	var future := PlayerInventory.from_dict({"schema_version": 2, "ruleset_id": "calvo_inventory_v1", "quantities": {}})
	var wrong_ruleset := PlayerInventory.from_dict({"schema_version": 1, "ruleset_id": "other", "quantities": {}})
	var wrong_type := PlayerInventory.from_dict({"schema_version": 1, "ruleset_id": "calvo_inventory_v1", "quantities": []})
	var negative := PlayerInventory.from_dict({"schema_version": 1, "ruleset_id": "calvo_inventory_v1", "quantities": {"poke_ball": -1}})
	var fraction := PlayerInventory.from_dict({"schema_version": 1, "ruleset_id": "calvo_inventory_v1", "quantities": {"poke_ball": 1.5}})
	_check.call("inv_corrupt_missing_schema", missing_schema.corrupted and missing_schema.corruption_reason == "missing_schema")
	_check.call("inv_corrupt_future_schema", future.corrupted and future.corruption_reason == "unsupported_schema")
	_check.call("inv_corrupt_ruleset", wrong_ruleset.corrupted and wrong_ruleset.corruption_reason == "unsupported_ruleset")
	_check.call("inv_corrupt_quantities_type", wrong_type.corrupted and wrong_type.corruption_reason == "invalid_quantities_type")
	_check.call("inv_corrupt_negative", negative.corrupted and negative.corruption_reason == "invalid_quantity")
	_check.call("inv_corrupt_fraction", fraction.corrupted and fraction.corruption_reason == "invalid_quantity_fraction")


func _test_capture_missing_inventory_rejected_without_rng() -> void:
	var target := _wild(&"pikachu", 5, 100)
	var attempt := _attempt(target, &"poke_ball", _wild_context())
	var rng := _rng(42)
	var control := _rng(42)
	var party := CreatureParty.new()
	var res := CaptureInventoryService.resolve(attempt, rng, _catalog, party, null)
	_check.call("inv_capture_null_inventory_rejected", res.result.status == CaptureResult.INVALID and res.result.reason == "inventory_required")
	_check.call("inv_capture_null_inventory_no_party_mutation", party.is_empty())
	_check.call("inv_capture_null_inventory_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_capture_missing_ball_rejected_without_rng() -> void:
	var target := _wild(&"pikachu", 5, 101)
	var rng := _rng(43)
	var control := _rng(43)
	var inv := PlayerInventory.new()
	var party := CreatureParty.new()
	var res := CaptureInventoryService.resolve(_attempt(target, &"great_ball", _wild_context()), rng, _catalog, party, inv)
	_check.call("inv_capture_missing_ball_rejected", res.result.status == CaptureResult.INVALID and res.result.reason == "item_not_owned")
	_check.call("inv_capture_missing_ball_no_mutation", party.is_empty() and inv.is_empty())
	_check.call("inv_capture_missing_ball_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_capture_validation_precedes_inventory() -> void:
	var target := _wild(&"pikachu", 5, 102)
	var rng := _rng(44)
	var control := _rng(44)
	var res := CaptureInventoryService.resolve(_attempt(target, &"not_a_ball", _wild_context()), rng, _catalog, CreatureParty.new(), PlayerInventory.new())
	_check.call("inv_capture_unknown_ball_precedence", res.result.status == CaptureResult.INVALID and res.result.reason == "unknown_ball")
	_check.call("inv_capture_unknown_ball_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_capture_invalid_trainer_does_not_consume() -> void:
	var target := _wild(&"pikachu", 5, 103)
	var inv := _inventory_with(&"poke_ball", 2)
	var rng := _rng(45)
	var control := _rng(45)
	var res := CaptureInventoryService.resolve(_attempt(target, &"poke_ball", _trainer_context()), rng, _catalog, CreatureParty.new(), inv)
	_check.call("inv_capture_trainer_rejected", res.result.status == CaptureResult.INVALID and res.result.reason == "trainer_battle_not_capturable")
	_check.call("inv_capture_trainer_item_kept", inv.quantity(&"poke_ball") == 2)
	_check.call("inv_capture_trainer_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_capture_failure_consumes_one() -> void:
	var found := false
	for seed_value in range(1, 100):
		var target := _wild(&"mewtwo", 70, 2000 + seed_value)
		var inv := _inventory_with(&"poke_ball", 2)
		var res := CaptureInventoryService.resolve(
			_attempt(target, &"poke_ball", _wild_context()), _rng(seed_value), _catalog, CreatureParty.new(), inv
		)
		if res.result.status == CaptureResult.FAILED:
			found = true
			_check.call("inv_capture_fail_consumes_one", inv.quantity(&"poke_ball") == 1 and res.result.consume_item)
			break
	_check.call("inv_capture_fail_case_found", found)


func _test_capture_master_consumes_one_and_preserves_identity() -> void:
	var target := _wild(&"mewtwo", 70, 3001)
	var inv := _inventory_with(&"master_ball", 2)
	var party := CreatureParty.new()
	var res := CaptureInventoryService.resolve(_attempt(target, &"master_ball", _wild_context()), _rng(51), _catalog, party, inv)
	_check.call("inv_capture_master_success", res.result.status == CaptureResult.SUCCESS and res.disposition == CaptureDisposition.PARTY)
	_check.call("inv_capture_master_consumes_one", inv.quantity(&"master_ball") == 1)
	_check.call("inv_capture_master_same_instance", res.captured == target and party.get_creature(target.instance_id) == target)


func _test_capture_master_does_not_consume_rng() -> void:
	var target := _wild(&"mewtwo", 70, 3002)
	var inv := _inventory_with(&"master_ball", 1)
	var rng := _rng(52)
	var control := _rng(52)
	CaptureInventoryService.resolve(_attempt(target, &"master_ball", _wild_context()), rng, _catalog, CreatureParty.new(), inv)
	_check.call("inv_capture_master_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_capture_full_party_consumes_and_requires_storage() -> void:
	var party := CreatureParty.new()
	for i in range(6):
		party.add_creature(_wild(&"bulbasaur", 5, 4000 + i))
	var target := _wild(&"pikachu", 5, 5000)
	var inv := _inventory_with(&"master_ball", 1)
	var res := CaptureInventoryService.resolve(_attempt(target, &"master_ball", _wild_context()), _rng(53), _catalog, party, inv)
	_check.call("inv_capture_full_storage_required", res.result.status == CaptureResult.SUCCESS and res.disposition == CaptureDisposition.STORAGE_REQUIRED)
	_check.call("inv_capture_full_item_consumed", inv.quantity(&"master_ball") == 0)
	_check.call("inv_capture_full_party_unchanged", party.size() == 6 and not party.contains_instance_id(target.instance_id))


func _test_capture_corrupt_inventory_rejected_without_rng() -> void:
	var inv := PlayerInventory.from_dict({"schema_version": 1, "ruleset_id": "calvo_inventory_v1", "quantities": {"poke_ball": -1}})
	var target := _wild(&"pikachu", 5, 6000)
	var rng := _rng(54)
	var control := _rng(54)
	var res := CaptureInventoryService.resolve(_attempt(target, &"poke_ball", _wild_context()), rng, _catalog, CreatureParty.new(), inv)
	_check.call("inv_capture_corrupt_inventory_rejected", res.result.status == CaptureResult.INVALID and res.result.reason == "inventory_corrupted")
	_check.call("inv_capture_corrupt_inventory_no_rng", is_equal_approx(rng.randf(), control.randf()))
