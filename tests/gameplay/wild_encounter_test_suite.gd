class_name WildEncounterTestSuite
extends RefCounted

var _check: Callable
var _catalog: DefinitionCatalog


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	var tests := [
		"_test_ruleset_contract",
		"_test_slot_validation",
		"_test_slot_rejects_bad_weight",
		"_test_slot_rejects_bad_levels",
		"_test_slot_rejects_unknown_species",
		"_test_table_validation",
		"_test_table_rejects_duplicate_slot_id",
		"_test_table_rejects_empty",
		"_test_table_rejects_bad_chance",
		"_test_table_roundtrip",
		"_test_table_hostile_shapes",
		"_test_invalid_table_consumes_no_rng",
		"_test_unknown_species_consumes_no_rng",
		"_test_zero_chance_none_and_no_rng",
		"_test_guaranteed_single_fixed_encounter",
		"_test_same_seed_reproduces_exact_encounter",
		"_test_sequential_encounters_get_different_ids",
		"_test_level_range_is_inclusive",
		"_test_weighted_selection_uses_declared_species",
		"_test_chance_miss_is_semantic_none",
		"_test_missing_dependencies_rejected",
		"_test_factory_traits_are_populated",
		"_test_result_semantic_serialization",
		"_test_encounter_to_capture_handoff",
	]
	for name in tests:
		print("ENC_TEST %s" % name)
		self.call(name)


func _import_pokeapi() -> GameData:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	return DataImporter.new().import_dataset(raw, manifest)["game_data"]


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text()) as Dictionary


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _slot(id: StringName, species: StringName, weight: int = 1, min_level: int = 5, max_level: int = 5) -> WildEncounterSlot:
	return WildEncounterSlot.new(id, species, weight, min_level, max_level)


func _table(chance_bp: int = 10000, p_slots: Array[WildEncounterSlot] = []) -> WildEncounterTable:
	var table := WildEncounterTable.new(&"test_grass", chance_bp)
	for slot in p_slots:
		table.add_slot(slot)
	return table


func _single(species: StringName = &"pikachu", chance_bp: int = 10000, min_level: int = 5, max_level: int = 5) -> WildEncounterTable:
	return _table(chance_bp, [_slot(&"slot_1", species, 1, min_level, max_level)])


func _test_ruleset_contract() -> void:
	_check.call("enc_ruleset_id", WildEncounterRuleset.ID == &"calvo_wild_encounters_v1")
	_check.call("enc_ruleset_schema", WildEncounterRuleset.SCHEMA_VERSION == 1)
	_check.call("enc_chance_bounds", WildEncounterRuleset.is_valid_chance_bp(0) and WildEncounterRuleset.is_valid_chance_bp(10000) and not WildEncounterRuleset.is_valid_chance_bp(10001))


func _test_slot_validation() -> void:
	var slot := _slot(&"common", &"pikachu", 60, 3, 7)
	_check.call("enc_slot_valid", slot.validate(_catalog).ok)
	_check.call("enc_slot_fields", slot.slot_id == &"common" and slot.species_id == &"pikachu" and slot.weight == 60 and slot.min_level == 3 and slot.max_level == 7)


func _test_slot_rejects_bad_weight() -> void:
	_check.call("enc_slot_zero_weight", not _slot(&"bad", &"pikachu", 0).validate(_catalog).ok)
	_check.call("enc_slot_negative_weight", not _slot(&"bad", &"pikachu", -1).validate(_catalog).ok)
	_check.call("enc_slot_huge_weight", not _slot(&"bad", &"pikachu", WildEncounterRuleset.MAX_SLOT_WEIGHT + 1).validate(_catalog).ok)


func _test_slot_rejects_bad_levels() -> void:
	_check.call("enc_slot_min_over_max", _slot(&"bad", &"pikachu", 1, 9, 3).validate(_catalog).reason == "invalid_level_range")
	_check.call("enc_slot_level_zero", _slot(&"bad", &"pikachu", 1, 0, 3).validate(_catalog).reason == "invalid_level_range")
	_check.call("enc_slot_level_over_cap", _slot(&"bad", &"pikachu", 1, 1, ProgressionRuleset.MAX_LEVEL + 1).validate(_catalog).reason == "invalid_level_range")


func _test_slot_rejects_unknown_species() -> void:
	var v := _slot(&"ghost", &"definitely_not_a_species", 1, 5, 5).validate(_catalog)
	_check.call("enc_slot_unknown_species", not v.ok and v.reason == "unknown_species")


func _test_table_validation() -> void:
	var table := _table(2500, [
		_slot(&"common", &"pikachu", 70, 3, 5),
		_slot(&"rare", &"bulbasaur", 30, 4, 6),
	])
	_check.call("enc_table_valid", table.validate(_catalog).ok)
	_check.call("enc_table_total_weight", table.total_weight() == 100)


func _test_table_rejects_duplicate_slot_id() -> void:
	var table := WildEncounterTable.new(&"dup_zone", 10000)
	# Bypass add_slot intentionally to test hostile/authored table validation.
	table.slots.append(_slot(&"same", &"pikachu", 1))
	table.slots.append(_slot(&"same", &"bulbasaur", 1))
	var v := table.validate(_catalog)
	_check.call("enc_table_duplicate_slot", not v.ok and v.reason == "duplicate_slot_id")


func _test_table_rejects_empty() -> void:
	var v := WildEncounterTable.new(&"empty_zone", 10000).validate(_catalog)
	_check.call("enc_table_empty_rejected", not v.ok and v.reason == "empty_encounter_table")


func _test_table_rejects_bad_chance() -> void:
	var table := _single()
	table.encounter_chance_bp = 10001
	_check.call("enc_table_bad_chance", table.validate(_catalog).reason == "invalid_encounter_chance")


func _test_table_roundtrip() -> void:
	var original := _table(3750, [
		_slot(&"a", &"pikachu", 3, 2, 4),
		_slot(&"b", &"bulbasaur", 1, 7, 7),
	])
	var encoded := JSON.stringify(original.to_dict())
	var restored := WildEncounterTable.from_dict(JSON.parse_string(encoded) as Dictionary)
	_check.call("enc_roundtrip_not_corrupt", not restored.corrupted and restored.validate(_catalog).ok)
	_check.call("enc_roundtrip_stable", JSON.stringify(restored.to_dict()) == encoded)
	_check.call("enc_roundtrip_order", restored.slots[0].slot_id == &"a" and restored.slots[1].slot_id == &"b")


func _test_table_hostile_shapes() -> void:
	var base := _single().to_dict()
	var bad_slots := base.duplicate(true)
	bad_slots["slots"] = {}
	var t := WildEncounterTable.from_dict(bad_slots)
	_check.call("enc_hostile_slots_type", t.corrupted and t.corruption_reason == "invalid_slots_type")
	var bad_chance := base.duplicate(true)
	bad_chance["encounter_chance_bp"] = "often"
	t = WildEncounterTable.from_dict(bad_chance)
	_check.call("enc_hostile_chance_type", t.corrupted and t.corruption_reason == "invalid_encounter_chance_bp_type")
	var bad_species := base.duplicate(true)
	bad_species["slots"][0]["species_id"] = []
	t = WildEncounterTable.from_dict(bad_species)
	_check.call("enc_hostile_species_type", t.corrupted and t.corruption_reason == "slot_invalid_species_id_type")


func _test_invalid_table_consumes_no_rng() -> void:
	var table := WildEncounterTable.new(&"bad", 10000)
	var rng := _rng(100)
	var control := _rng(100)
	var res := WildEncounterSystem.resolve(table, rng, _catalog)
	_check.call("enc_invalid_status", res.status == WildEncounterResult.INVALID and res.reason == "empty_encounter_table")
	_check.call("enc_invalid_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_unknown_species_consumes_no_rng() -> void:
	var table := _table(10000, [_slot(&"unknown", &"not_real", 1)])
	var rng := _rng(101)
	var control := _rng(101)
	var res := WildEncounterSystem.resolve(table, rng, _catalog)
	_check.call("enc_unknown_rejected", res.status == WildEncounterResult.INVALID and res.reason == "slot_unknown_species")
	_check.call("enc_unknown_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_zero_chance_none_and_no_rng() -> void:
	var rng := _rng(102)
	var control := _rng(102)
	var res := WildEncounterSystem.resolve(_single(&"pikachu", 0), rng, _catalog)
	_check.call("enc_zero_none", res.status == WildEncounterResult.NONE and res.reason == "chance_miss" and res.creature == null)
	_check.call("enc_zero_no_rng", is_equal_approx(rng.randf(), control.randf()))


func _test_guaranteed_single_fixed_encounter() -> void:
	var res := WildEncounterSystem.resolve(_single(&"pikachu", 10000, 9, 9), _rng(200), _catalog)
	_check.call("enc_guaranteed_status", res.status == WildEncounterResult.ENCOUNTER)
	_check.call("enc_guaranteed_species", res.species_id == &"pikachu" and res.creature.species_id == &"pikachu")
	_check.call("enc_guaranteed_level", res.level == 9 and res.creature.level == 9)


func _test_same_seed_reproduces_exact_encounter() -> void:
	var table := _table(6500, [
		_slot(&"pika", &"pikachu", 7, 3, 8),
		_slot(&"bulba", &"bulbasaur", 3, 4, 9),
	])
	# Pick a guaranteed table here: this test is about deterministic selection/spawn, not chance miss.
	table.encounter_chance_bp = 10000
	var a := WildEncounterSystem.resolve(table, _rng(123456), _catalog)
	var b := WildEncounterSystem.resolve(table, _rng(123456), _catalog)
	var same_traits := a.creature != null and b.creature != null \
		and a.creature.instance_id == b.creature.instance_id \
		and a.creature.ivs == b.creature.ivs \
		and a.creature.nature_id == b.creature.nature_id \
		and a.creature.ability_id == b.creature.ability_id
	_check.call("enc_seed_same_semantics", a.status == b.status and a.slot_id == b.slot_id and a.species_id == b.species_id and a.level == b.level)
	_check.call("enc_seed_same_creature", same_traits)


func _test_sequential_encounters_get_different_ids() -> void:
	var rng := _rng(555)
	var table := _single(&"pikachu", 10000, 5, 5)
	var a := WildEncounterSystem.resolve(table, rng, _catalog)
	var b := WildEncounterSystem.resolve(table, rng, _catalog)
	_check.call("enc_sequential_both", a.status == WildEncounterResult.ENCOUNTER and b.status == WildEncounterResult.ENCOUNTER)
	_check.call("enc_sequential_unique_id", a.creature.instance_id != b.creature.instance_id)


func _test_level_range_is_inclusive() -> void:
	var table := _single(&"pikachu", 10000, 3, 5)
	var in_range := true
	var seen := {}
	for seed_value in range(1, 80):
		var res := WildEncounterSystem.resolve(table, _rng(seed_value), _catalog)
		if res.level < 3 or res.level > 5:
			in_range = false
		seen[res.level] = true
	_check.call("enc_level_range", in_range)
	_check.call("enc_level_inclusive_seen", seen.has(3) and seen.has(5))


func _test_weighted_selection_uses_declared_species() -> void:
	var table := _table(10000, [
		_slot(&"common", &"pikachu", 9, 5, 5),
		_slot(&"rare", &"bulbasaur", 1, 5, 5),
	])
	var valid_only := true
	var seen_pika := false
	var seen_bulba := false
	for seed_value in range(1, 120):
		var res := WildEncounterSystem.resolve(table, _rng(seed_value), _catalog)
		if res.species_id == &"pikachu":
			seen_pika = true
		elif res.species_id == &"bulbasaur":
			seen_bulba = true
		else:
			valid_only = false
	_check.call("enc_weighted_declared_only", valid_only)
	_check.call("enc_weighted_both_reachable", seen_pika and seen_bulba)


func _test_chance_miss_is_semantic_none() -> void:
	var found_miss := false
	for seed_value in range(1, 40):
		var res := WildEncounterSystem.resolve(_single(&"pikachu", 1), _rng(seed_value), _catalog)
		if res.status == WildEncounterResult.NONE:
			found_miss = res.reason == "chance_miss" and res.creature == null
			break
	_check.call("enc_chance_miss", found_miss)


func _test_missing_dependencies_rejected() -> void:
	var table := _single()
	_check.call("enc_missing_table", WildEncounterSystem.resolve(null, _rng(1), _catalog).reason == "missing_table")
	_check.call("enc_missing_rng", WildEncounterSystem.resolve(table, null, _catalog).reason == "missing_rng")
	_check.call("enc_missing_catalog", WildEncounterSystem.resolve(table, _rng(1), null).reason == "missing_catalog")


func _test_factory_traits_are_populated() -> void:
	var res := WildEncounterSystem.resolve(_single(&"pikachu", 10000, 12, 12), _rng(999), _catalog)
	var c := res.creature
	_check.call("enc_factory_creature", c != null and c.instance_id != &"" and c.species_id == &"pikachu")
	_check.call("enc_factory_stats", c.stats.max_hp > 0 and c.current_hp == c.stats.max_hp)
	_check.call("enc_factory_nature", ProgressionRuleset.is_valid_nature(c.nature_id))
	_check.call("enc_factory_ivs", c.ivs.size() == ProgressionRuleset.STAT_KEYS.size())


func _test_result_semantic_serialization() -> void:
	var res := WildEncounterSystem.resolve(_single(&"bulbasaur", 10000, 6, 6), _rng(444), _catalog)
	var d := res.to_dict()
	_check.call("enc_result_status", d["status"] == "ENCOUNTER")
	_check.call("enc_result_zone", d["zone_id"] == "test_grass" and d["slot_id"] == "slot_1")
	_check.call("enc_result_identity", d["species_id"] == "bulbasaur" and d["creature_instance_id"] == String(res.creature.instance_id))


func _test_encounter_to_capture_handoff() -> void:
	var encounter := WildEncounterSystem.resolve(_single(&"pikachu", 10000, 5, 5), _rng(777), _catalog)
	var target := encounter.creature
	target.current_hp = 1
	var context := CaptureBattleContext.new()
	context.is_wild = true
	var attempt := CaptureAttempt.new(target, &"master_ball", context)
	var inventory := PlayerInventory.new()
	inventory.add(&"master_ball", 1)
	var party := CreatureParty.new()
	var capture := CaptureInventoryService.resolve(attempt, _rng(888), _catalog, party, inventory)
	_check.call("enc_capture_success", capture.result.status == CaptureResult.SUCCESS)
	_check.call("enc_capture_same_identity", party.contains_instance_id(target.instance_id) and capture.captured == target)
	_check.call("enc_capture_ball_consumed", inventory.quantity(&"master_ball") == 0)
