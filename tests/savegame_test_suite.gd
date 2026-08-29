class_name SavegameTestSuite
extends RefCounted

# FASE 8B tests: Savegame V1 (canonical creature registry + references) with
# atomic save and transactional load. No full-creature duplication; party/storage
# reference the same CreatureInstance through instance_id.

var _check: Callable
var _catalog: DefinitionCatalog


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	var t := [
		"_test_save_empty_state", "_test_save_party_only", "_test_save_storage_only",
		"_test_save_party_and_storage", "_test_save_roundtrip", "_test_save_roundtrip_same_instance_ids",
		"_test_save_roundtrip_party_order", "_test_save_roundtrip_storage_box_slot_order",
		"_test_save_creature_fidelity", "_test_save_iv_fidelity", "_test_save_nature_fidelity",
		"_test_save_ability_fidelity", "_test_save_moves_fidelity", "_test_save_pp_fidelity",
		"_test_save_current_hp_fidelity", "_test_save_status_fidelity", "_test_save_level_xp_fidelity",
		"_test_load_json_corrupt_rejected", "_test_load_missing_schema_rejected",
		"_test_load_future_schema_rejected", "_test_load_missing_creature_reference_rejected",
		"_test_load_duplicate_creature_id_rejected", "_test_load_party_storage_double_ownership_rejected",
		"_test_load_invalid_storage_slot_rejected", "_test_load_failure_does_not_publish_partial_state",
		"_test_save_file_write_read", "_test_save_atomic_replacement",
		"_test_end_to_end_capture_storage_save_load", "_test_end_to_end_capture_party_save_load",
		"_test_property_repeated_deposit_withdraw", "_test_property_repeated_save_load",
		# FASE 8C: protected save replacement (BUG 1)
		"_test_save_safe_first_write", "_test_save_safe_replace_success", "_test_save_safe_replace_preserves_latest",
		"_test_save_tmp_clean_after_success", "_test_save_backup_clean_after_success",
		"_test_save_failure_does_not_destroy_previous_save", "_test_save_restore_previous_on_replace_failure",
		# FASE 8C: corrupt party / format id rejection (BUG 2)
		"_test_load_party_duplicate_id_rejected", "_test_load_party_over_capacity_rejected",
		"_test_load_party_empty_id_rejected", "_test_load_party_rebuild_failure_not_published",
		"_test_load_wrong_format_id_rejected", "_test_load_missing_format_id_rejected",
		"_test_load_failure_party_is_null", "_test_load_failure_storage_is_null",
		# FASE 8C: extra invariants
		"_test_save_empty_creature_instance_id_rejected",
		"_test_load_creatures_wrong_type_rejected", "_test_load_party_wrong_type_rejected",
		"_test_load_storage_wrong_type_rejected", "_test_load_boxes_wrong_type_rejected",
	]
	for name in t:
		print("SG_TEST %s" % name)
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


func _species(id: StringName) -> CreatureSpecies:
	return _catalog.species_catalog.get_by_id(id)


func _wild(id: StringName, level: int, seed: int, overrides: Dictionary = {}) -> CreatureInstance:
	return CreatureFactory.create(_species(id), level, _catalog, ProgressionRuleset.new(), _rng(seed), overrides)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _wild_context() -> CaptureBattleContext:
	var c := CaptureBattleContext.new()
	c.is_wild = true
	return c


func _attempt(target: CreatureInstance, ball: StringName, ctx: CaptureBattleContext) -> CaptureAttempt:
	return CaptureAttempt.new(target, ball, ctx)


func _collection_with(party_members: int, storage_members: int, seed_base: int) -> PlayerCollection:
	var pc := PlayerCollection.new()
	for i in range(party_members):
		pc.party.add_creature(_wild(&"bulbasaur", 5, seed_base + i))
	for i in range(storage_members):
		pc.storage.add_creature(_wild(&"charmander", 5, seed_base + 100 + i))
	return pc


# Normalize an IV/EV map to String-keyed int values so equality checks ignore the
# StringName-vs-String key representation that JSON round-tripping introduces.
func _stat_norm(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d.keys():
		out[String(k)] = int(d[k])
	return out


func _save_and_load(pc: PlayerCollection) -> LoadResult:
	var repo := SaveGameRepository.new()
	var sr := repo.save_collection("user://f8_suite.json", pc)
	_check.call("sg_save_ok", sr.ok)
	var lr := repo.load("user://f8_suite.json")
	_check.call("sg_load_ok", lr.ok)
	return lr


func _test_save_empty_state() -> void:
	var pc := PlayerCollection.new()
	var data := SaveGameData.build(pc.party, pc.storage)
	_check.call("sg_empty_version", data.schema_version == SaveGameData.CURRENT_VERSION)
	_check.call("sg_empty_creatures", data.creatures.is_empty())
	_check.call("sg_empty_valid", data.validate().ok)


func _test_save_party_only() -> void:
	var pc := _collection_with(2, 0, 1)
	var data := SaveGameData.build(pc.party, pc.storage)
	_check.call("sg_party_only", data.creatures.size() == 2 and data.party_layout.get("ordered_instance_ids", []).size() == 2 and data.storage_layout.get("boxes", []).is_empty())


func _test_save_storage_only() -> void:
	var pc := _collection_with(0, 3, 1)
	var data := SaveGameData.build(pc.party, pc.storage)
	_check.call("sg_storage_only", data.creatures.size() == 3 and data.party_layout.get("ordered_instance_ids", []).is_empty() and data.storage_layout.get("boxes", []).size() == 1)


func _test_save_party_and_storage() -> void:
	var pc := _collection_with(2, 3, 1)
	var data := SaveGameData.build(pc.party, pc.storage)
	_check.call("sg_both_creatures", (data.creatures.size() == 5) == true)
	_check.call("sg_both_no_dup", data.creatures.size() == 5)


func _test_save_roundtrip() -> void:
	var pc := _collection_with(2, 3, 1)
	var lr := _save_and_load(pc)
	_check.call("sg_roundtrip_size", lr.party.size() == 2 and lr.storage.get_all_creatures().size() == 3)


func _test_save_roundtrip_same_instance_ids() -> void:
	var pc := _collection_with(2, 3, 1)
	var lr := _save_and_load(pc)
	var same := true
	for c in pc.party.get_creatures():
		if not lr.party.contains_instance_id(c.instance_id):
			same = false
	for c in pc.storage.get_all_creatures():
		if not lr.storage.contains_instance_id(c.instance_id):
			same = false
	_check.call("sg_roundtrip_ids", same)


func _test_save_roundtrip_party_order() -> void:
	var pc := _collection_with(3, 0, 1)
	var before: Array = []
	for c in pc.party.get_creatures():
		before.append(c.instance_id)
	var lr := _save_and_load(pc)
	var after: Array = []
	for c in lr.party.get_creatures():
		after.append(c.instance_id)
	_check.call("sg_roundtrip_party_order", after == before)


func _test_save_roundtrip_storage_box_slot_order() -> void:
	var pc := _collection_with(3, 4, 1)
	for i in range(4):
		pc.storage.add_creature(_wild(&"squirtle", 5, 900 + i))
	var lr := _save_and_load(pc)
	var ok := true
	for bi in pc.storage.box_count():
		var before_ids: Array = []
		for c in pc.storage.get_box(bi).slots():
			before_ids.append(c.instance_id if c != null else &"")
		var after_ids: Array = []
		for c in lr.storage.get_box(bi).slots():
			after_ids.append(c.instance_id if c != null else &"")
		if before_ids != after_ids:
			ok = false
	_check.call("sg_roundtrip_box_order", ok)


func _test_save_creature_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	var before: CreatureInstance = pc.party.get_creatures()[0]
	var lr := _save_and_load(pc)
	var after: CreatureInstance = lr.party.get_creatures()[0]
	_check.call("sg_fidelity_species", after.species_id == before.species_id)
	_check.call("sg_fidelity_level", after.level == before.level)
	_check.call("sg_fidelity_xp", after.experience == before.experience)


func _test_save_iv_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	pc.party.get_creatures()[0].ivs = {"attack": 31, "defense": 30, "speed": 29}
	var before: Dictionary = _stat_norm(pc.party.get_creatures()[0].ivs)
	var lr := _save_and_load(pc)
	_check.call("sg_iv_fidelity", _stat_norm(lr.party.get_creatures()[0].ivs) == before)


func _test_save_nature_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	pc.party.get_creatures()[0].nature_id = &"jolly"
	var lr := _save_and_load(pc)
	_check.call("sg_nature_fidelity", lr.party.get_creatures()[0].nature_id == &"jolly")


func _test_save_ability_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	pc.party.get_creatures()[0].ability_id = &"overgrow"
	var lr := _save_and_load(pc)
	_check.call("sg_ability_fidelity", lr.party.get_creatures()[0].ability_id == &"overgrow")


func _test_save_moves_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	var before: Array = []
	for m in pc.party.get_creatures()[0].moveset:
		before.append(m.move_id)
	var lr := _save_and_load(pc)
	var after: Array = []
	for m in lr.party.get_creatures()[0].moveset:
		after.append(m.move_id)
	_check.call("sg_moves_fidelity", after == before)


func _test_save_pp_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	var before: Array = []
	for m in pc.party.get_creatures()[0].moveset:
		before.append(m.current_pp)
	var lr := _save_and_load(pc)
	var after: Array = []
	for m in lr.party.get_creatures()[0].moveset:
		after.append(m.current_pp)
	_check.call("sg_pp_fidelity", after == before)


func _test_save_current_hp_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	pc.party.get_creatures()[0].current_hp = 5
	var lr := _save_and_load(pc)
	_check.call("sg_hp_fidelity", lr.party.get_creatures()[0].current_hp == 5)


func _test_save_status_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	pc.party.get_creatures()[0].status_state.persistent_id = &"poison"
	pc.party.get_creatures()[0].status_state.turns_remaining = 3
	var lr := _save_and_load(pc)
	var after: CreatureInstance = lr.party.get_creatures()[0]
	_check.call("sg_status_fidelity", after.status_state.persistent_id == &"poison" and after.status_state.turns_remaining == 3)


func _test_save_level_xp_fidelity() -> void:
	var pc := _collection_with(1, 0, 1)
	pc.party.get_creatures()[0].experience = 1234
	var lr := _save_and_load(pc)
	_check.call("sg_xp_fidelity", lr.party.get_creatures()[0].experience == 1234)


func _write_dict(dir: String, filename: String, d: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + "/" + filename
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return path


func _write_raw(dir: String, filename: String, content: String) -> String:
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + "/" + filename
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(content)
	f.close()
	return path


func _test_load_json_corrupt_rejected() -> void:
	var path := _write_raw("user://f8_corrupt", "c.json", "{not valid json")
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_corrupt_rejected", lr.ok == false and lr.reason == "json_parse_error")


func _test_load_missing_schema_rejected() -> void:
	# Valid legacy format id, but no schema_version -> schema check must fire first.
	var path := _write_dict("user://f8_schema", "m.json", {"format_id": "calvo_save_v1", "creatures": []})
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_missing_schema_rejected", lr.ok == false and lr.reason == "missing_schema")


func _test_load_future_schema_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["schema_version"] = 999
	var path := _write_dict("user://f8_schema", "f.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_future_schema_rejected", lr.ok == false and lr.reason == "unsupported_schema")


func _test_load_missing_creature_reference_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["party"] = {"schema_version": 2, "ordered_instance_ids": ["ghost_id"], "slots": [{"instance_id": "ghost_id"}]}
	var path := _write_dict("user://f8_ref", "r.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_missing_ref_rejected", lr.ok == false and lr.reason == "missing_creature_reference")


func _test_load_duplicate_creature_id_rejected() -> void:
	var pc := _collection_with(1, 0, 1)
	var d := SaveGameData.build(pc.party, CreatureStorage.new()).to_dict()
	var first_id: String = d["party"]["ordered_instance_ids"][0]
	d["creatures"].append(d["creatures"][0].duplicate(true))
	d["creatures"][-1]["instance_id"] = first_id
	var path := _write_dict("user://f8_dup", "d.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_dup_creature_rejected", lr.ok == false and lr.reason == "duplicate_creature_id")


func _test_load_party_storage_double_ownership_rejected() -> void:
	var pc := _collection_with(1, 0, 1)
	var d := SaveGameData.build(pc.party, CreatureStorage.new()).to_dict()
	var first_id: String = d["party"]["ordered_instance_ids"][0]
	d["storage"] = {"schema_version": 2, "boxes": [{"box_id": "box_0", "name": "Box 1", "capacity": 1, "slots": [String(first_id)]}]}
	var path := _write_dict("user://f8_dbl", "b.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_double_ownership_rejected", lr.ok == false and lr.reason == "double_ownership")


func _test_load_invalid_storage_slot_rejected() -> void:
	var pc := _collection_with(1, 0, 1)
	var d := SaveGameData.build(pc.party, CreatureStorage.new()).to_dict()
	d["storage"] = {"schema_version": 2, "boxes": [{"box_id": "box_0", "name": "Box 1", "slots": [null]}]}
	var path := _write_dict("user://f8_slot", "s.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_invalid_slot_rejected", lr.ok == false and lr.reason == "invalid_storage_slot")


func _test_load_failure_does_not_publish_partial_state() -> void:
	var pc := _collection_with(1, 0, 1)
	var d := SaveGameData.build(pc.party, CreatureStorage.new()).to_dict()
	d["schema_version"] = 999
	var path := _write_dict("user://f8_partial", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("sg_no_partial_party", lr.party == null)
	_check.call("sg_no_partial_storage", lr.storage == null)


func _test_save_file_write_read() -> void:
	var pc := _collection_with(2, 2, 1)
	var repo := SaveGameRepository.new()
	var sr := repo.save_collection("user://f8_file.json", pc)
	_check.call("sg_file_write_ok", sr.ok and FileAccess.file_exists("user://f8_file.json"))
	var raw := repo._serializer.read_raw("user://f8_file.json")
	var parsed = JSON.parse_string(raw)
	_check.call("sg_file_read_raw", typeof(parsed) == TYPE_DICTIONARY and parsed.has("creatures"))


func _test_save_atomic_replacement() -> void:
	var a := _collection_with(1, 0, 9001)
	var b := _collection_with(0, 1, 9002)
	var repo := SaveGameRepository.new()
	_check.call("sg_atomic_first", repo.save_collection("user://f8_atom.json", a).ok)
	_check.call("sg_atomic_second", repo.save_collection("user://f8_atom.json", b).ok)
	_check.call("sg_atomic_no_tmp", not FileAccess.file_exists("user://f8_atom.json.tmp"))
	var lr := repo.load("user://f8_atom.json")
	_check.call("sg_atomic_loaded", lr.ok and lr.storage.get_all_creatures().size() == 1 and lr.party.size() == 0)


func _make_capture(party: CreatureParty, storage: CreatureStorage, id: StringName, seed: int) -> CreatureInstance:
	var wild := _wild(id, 30, seed)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	CaptureOwnershipRouter.new().route(res, party, storage)
	return wild


func _test_end_to_end_capture_storage_save_load() -> void:
	var pc := PlayerCollection.new()
	for i in range(6):
		pc.party.add_creature(_wild(&"bulbasaur", 5, 2000 + i))
	var captured := _make_capture(pc.party, pc.storage, &"pikachu", 1)
	var lr := _save_and_load(pc)
	var loaded := lr.storage.get_creature(captured.instance_id)
	_check.call("e2e_storage_saved", loaded != null)
	_check.call("e2e_storage_same_id", loaded.instance_id == captured.instance_id)
	_check.call("e2e_storage_iv", _stat_norm(loaded.ivs) == _stat_norm(captured.ivs))
	_check.call("e2e_storage_nature", loaded.nature_id == captured.nature_id)
	_check.call("e2e_storage_ability", loaded.ability_id == captured.ability_id)
	_check.call("e2e_storage_not_in_party", not lr.party.contains_instance_id(captured.instance_id))


func _test_end_to_end_capture_party_save_load() -> void:
	var pc := PlayerCollection.new()
	pc.party.add_creature(_wild(&"bulbasaur", 5, 2100))
	var captured := _make_capture(pc.party, pc.storage, &"pikachu", 2)
	var lr := _save_and_load(pc)
	var loaded := lr.party.get_creature(captured.instance_id)
	_check.call("e2e_party_saved", loaded != null)
	_check.call("e2e_party_same_id", loaded.instance_id == captured.instance_id)
	_check.call("e2e_party_iv", _stat_norm(loaded.ivs) == _stat_norm(captured.ivs))
	_check.call("e2e_party_moves", loaded.moveset.size() == captured.moveset.size())


func _test_property_repeated_deposit_withdraw() -> void:
	var pc := PlayerCollection.new()
	var c := _wild(&"pikachu", 5, 2300)
	pc.party.add_creature(c)
	var ok := true
	for i in range(20):
		if not pc.deposit(c.instance_id):
			ok = false
		if not pc.withdraw(c.instance_id):
			ok = false
		if pc.party.contains_instance_id(c.instance_id) and pc.storage.contains_instance_id(c.instance_id):
			ok = false
			ok = false
		if pc.party.contains_instance_id(c.instance_id) and pc.storage.contains_instance_id(c.instance_id):
			ok = false
	_check.call("prop_deposit_withdraw", ok)


func _test_property_repeated_save_load() -> void:
	var pc := _collection_with(3, 4, 1)
	var ok := true
	for i in range(15):
		if not SaveGameRepository.new().save_collection("user://f8_prop.json", pc).ok:
			ok = false
		var lr := SaveGameRepository.new().load("user://f8_prop.json")
		if not lr.ok or lr.party.size() != 3 or lr.storage.get_all_creatures().size() != 4:
			ok = false
	_check.call("prop_deposit_withdraw", ok)


# ---------------------------------------------------------------------------
# FASE 8C: protected save replacement (BUG 1) - last known good save preserved
# ---------------------------------------------------------------------------

func _test_save_safe_first_write() -> void:
	var repo := SaveGameRepository.new()
	var sr := repo.save_collection("user://f8c_save.json", _collection_with(1, 0, 1))
	_check.call("save_safe_first_write", sr.ok and FileAccess.file_exists("user://f8c_save.json"))


func _test_save_safe_replace_success() -> void:
	var repo := SaveGameRepository.new()
	_check.call("save_safe_replace_first", repo.save_collection("user://f8c_repl.json", _collection_with(1, 0, 1)).ok)
	var sr := repo.save_collection("user://f8c_repl.json", _collection_with(0, 2, 2))
	_check.call("save_safe_replace_success", sr.ok)


func _test_save_safe_replace_preserves_latest() -> void:
	var repo := SaveGameRepository.new()
	_check.call("save_safe_latest_first", repo.save_collection("user://f8c_latest.json", _collection_with(1, 0, 1)).ok)
	_check.call("save_safe_latest_second", repo.save_collection("user://f8c_latest.json", _collection_with(0, 2, 2)).ok)
	var lr := repo.load("user://f8c_latest.json")
	_check.call("save_safe_latest_reflects_new", lr.ok and lr.party.size() == 0 and lr.storage.get_all_creatures().size() == 2)


func _test_save_tmp_clean_after_success() -> void:
	var repo := SaveGameRepository.new()
	_check.call("save_tmp_clean_ok", repo.save_collection("user://f8c_tmp.json", _collection_with(1, 1, 1)).ok)
	_check.call("save_tmp_clean_no_tmp", not FileAccess.file_exists("user://f8c_tmp.json.tmp"))
	_check.call("save_tmp_clean_no_bak", not FileAccess.file_exists("user://f8c_tmp.json.bak"))


func _test_save_backup_clean_after_success() -> void:
	var repo := SaveGameRepository.new()
	_check.call("save_backup_clean_first", repo.save_collection("user://f8c_bak.json", _collection_with(1, 0, 1)).ok)
	_check.call("save_backup_clean_repl", repo.save_collection("user://f8c_bak.json", _collection_with(0, 1, 2)).ok)
	_check.call("save_backup_clean_no_bak", not FileAccess.file_exists("user://f8c_bak.json.bak"))


func _test_save_failure_does_not_destroy_previous_save() -> void:
	var repo := SaveGameRepository.new()
	_check.call("save_fail_first", repo.save_collection("user://f8c_fail.json", _collection_with(1, 0, 1)).ok)
	# Simulate a failed publish (tmp -> target rename fails after the backup was taken).
	var save_path := "user://f8c_fail.json"
	var tmp_path := save_path + ".tmp"
	repo._serializer.rename_failure_inject = func(from: String, to: String) -> int:
		if from == tmp_path:
			return FAILED
		return OK
	var sr := repo.save_collection(save_path, _collection_with(0, 3, 9))
	_check.call("save_fail_reported", sr.ok == false and sr.reason == "replace_failed_restored")


func _test_save_restore_previous_on_replace_failure() -> void:
	var repo := SaveGameRepository.new()
	_check.call("save_restore_first", repo.save_collection("user://f8c_restore.json", _collection_with(1, 0, 1)).ok)
	var save_path := "user://f8c_restore.json"
	var tmp_path := save_path + ".tmp"
	repo._serializer.rename_failure_inject = func(from: String, to: String) -> int:
		if from == tmp_path:
			return FAILED
		return OK
	var sr := repo.save_collection(save_path, _collection_with(0, 5, 9))
	_check.call("save_restore_failed", sr.ok == false)
	var lr := repo.load(save_path)
	# The previous good save (1 party creature) must be the one that survived.
	_check.call("save_restore_survived", lr.ok and lr.party.size() == 1 and lr.storage.get_all_creatures().size() == 0)


# ---------------------------------------------------------------------------
# FASE 8C: corrupt party / format id rejection (BUG 2)
# ---------------------------------------------------------------------------

func _test_load_party_duplicate_id_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	var first_id: String = d["party"]["ordered_instance_ids"][0]
	d["party"]["ordered_instance_ids"] = [first_id, first_id]
	var path := _write_dict("user://f8c_pdup", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_party_dup_rejected", lr.ok == false and lr.reason == "duplicate_party_instance_id")


func _test_load_party_over_capacity_rejected() -> void:
	var pc := _collection_with(6, 0, 1)
	var d := SaveGameData.build(pc.party, CreatureStorage.new()).to_dict()
	# Hand-add two extra registry creatures and push the party beyond the cap (registry is valid,
	# only the party layout is over capacity) to exercise the over-capacity guard.
	for i in range(2):
		var cd: Dictionary = d["creatures"][0].duplicate(true)
		cd["instance_id"] = "extra_%d" % i
		d["creatures"].append(cd)
		d["party"]["ordered_instance_ids"].append("extra_%d" % i)
	var path := _write_dict("user://f8c_pcap", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_party_over_cap_rejected", lr.ok == false and lr.reason == "party_over_capacity")


func _test_load_party_empty_id_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["party"]["ordered_instance_ids"][0] = ""
	var path := _write_dict("user://f8c_pempty", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_party_empty_id_rejected", lr.ok == false and lr.reason == "empty_party_instance_id")


func _test_load_party_rebuild_failure_not_published() -> void:
	var d := SaveGameData.build(_collection_with(6, 0, 1).party, CreatureStorage.new()).to_dict()
	# Over-capacity party layout: load must abort and publish NOTHING (no partial party object).
	for i in range(2):
		var cd: Dictionary = d["creatures"][0].duplicate(true)
		cd["instance_id"] = "extra_%d" % i
		d["creatures"].append(cd)
		d["party"]["ordered_instance_ids"].append("extra_%d" % i)
	var path := _write_dict("user://f8c_preb", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_party_rebuild_no_publish", lr.ok == false and lr.party == null and lr.storage == null)


func _test_load_wrong_format_id_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	# calvo_save_v2 is now the current format; use a genuinely foreign id for the invariant.
	d["format_id"] = "calvo_save_foreign"
	var path := _write_dict("user://f8c_fmt", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_wrong_format_rejected", lr.ok == false and lr.reason == "unsupported_format")


func _test_load_missing_format_id_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d.erase("format_id")
	var path := _write_dict("user://f8c_fmtm", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_missing_format_rejected", lr.ok == false and lr.reason == "missing_format_id")


func _test_load_failure_party_is_null() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["schema_version"] = 999
	var path := _write_dict("user://f8c_nullp", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_failure_party_null", lr.ok == false and lr.party == null)


func _test_load_failure_storage_is_null() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["schema_version"] = 999
	var path := _write_dict("user://f8c_nulls", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_failure_storage_null", lr.ok == false and lr.storage == null)


# ---------------------------------------------------------------------------
# FASE 8C: extra invariants
# ---------------------------------------------------------------------------

func _test_save_empty_creature_instance_id_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["creatures"].append({"instance_id": "", "species_id": "bulbasaur", "level": 5})
	var path := _write_dict("user://f8c_cemp", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("save_empty_creature_id_rejected", lr.ok == false and lr.reason == "empty_creature_instance_id")


func _test_load_creatures_wrong_type_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["creatures"] = {}
	var path := _write_dict("user://f8c_wct", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_creatures_wrong_type", lr.ok == false and lr.reason == "invalid_creatures_type")


func _test_load_party_wrong_type_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["party"] = []
	var path := _write_dict("user://f8c_wpt", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_party_wrong_type", lr.ok == false and lr.reason == "invalid_party_type")


func _test_load_storage_wrong_type_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["storage"] = []
	var path := _write_dict("user://f8c_wst", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_storage_wrong_type", lr.ok == false and lr.reason == "invalid_storage_type")


func _test_load_boxes_wrong_type_rejected() -> void:
	var d := SaveGameData.build(_collection_with(1, 0, 1).party, CreatureStorage.new()).to_dict()
	d["storage"] = {"schema_version": 2, "boxes": {}}
	var path := _write_dict("user://f8c_wbt", "p.json", d)
	var lr := SaveGameRepository.new().load(path)
	_check.call("load_boxes_wrong_type", lr.ok == false and lr.reason == "invalid_boxes_type")
