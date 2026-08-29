class_name StorageTestSuite
extends RefCounted

# FASE 8A tests: Storage Core V1 + capture STORAGE_REQUIRED routing.
# Ownership by instance_id: party and storage never hold two different CreatureInstances
# with the same instance_id.

var _check: Callable
var _catalog: DefinitionCatalog


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	var t := [
		"_test_storage_empty", "_test_storage_add", "_test_storage_identity_preserved",
		"_test_storage_duplicate_rejected", "_test_storage_remove", "_test_storage_slot_order",
		"_test_storage_move_same_box", "_test_storage_move_between_boxes", "_test_storage_swap",
		"_test_storage_invalid_move_no_mutation", "_test_storage_auto_new_box",
		"_test_storage_capacity_30", "_test_storage_locate",
		"_test_party_to_storage", "_test_party_to_storage_same_instance",
		"_test_storage_to_party", "_test_storage_to_party_same_instance",
		"_test_storage_to_full_party_rejected", "_test_party_storage_no_duplicate_instance_id",
		"_test_capture_full_party_routes_to_storage", "_test_capture_storage_same_instance",
		"_test_capture_storage_preserves_iv", "_test_capture_storage_preserves_nature",
		"_test_capture_storage_preserves_ability", "_test_capture_storage_preserves_moves_pp",
	]
	for name in t:
		print("ST_TEST %s" % name)
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


func _test_storage_empty() -> void:
	var st := CreatureStorage.new()
	_check.call("storage_empty_boxes", st.box_count() == 0)
	_check.call("storage_empty_contains", not st.contains_instance_id(&"x"))


func _test_storage_add() -> void:
	var st := CreatureStorage.new()
	var c := _wild(&"bulbasaur", 5, 1)
	_check.call("storage_add", st.add_creature(c) and st.contains_instance_id(c.instance_id))
	_check.call("storage_add_get", st.get_creature(c.instance_id) == c)


func _test_storage_identity_preserved() -> void:
	var st := CreatureStorage.new()
	var c := _wild(&"bulbasaur", 5, 1)
	st.add_creature(c)
	_check.call("storage_identity", st.get_creature(c.instance_id) == c)


func _test_storage_duplicate_rejected() -> void:
	var st := CreatureStorage.new()
	var c := _wild(&"bulbasaur", 5, 1)
	st.add_creature(c)
	_check.call("storage_dup_rejected", st.add_creature(c) == false and st.get_all_creatures().size() == 1)


func _test_storage_remove() -> void:
	var st := CreatureStorage.new()
	var c := _wild(&"bulbasaur", 5, 1)
	st.add_creature(c)
	_check.call("storage_remove", st.remove_creature(c.instance_id) and not st.contains_instance_id(c.instance_id))


func _test_storage_slot_order() -> void:
	var st := CreatureStorage.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var d := _wild(&"squirtle", 5, 3)
	st.add_creature(a); st.add_creature(b); st.add_creature(d)
	var box := st.get_box(0)
	_check.call("storage_slot_0", box.creature_at(0) == a)
	_check.call("storage_slot_1", box.creature_at(1) == b)
	_check.call("storage_slot_2", box.creature_at(2) == d)
	var loc := st.locate(a.instance_id)
	_check.call("storage_locate_a", loc.box_index == 0 and loc.slot == 0)


func _test_storage_move_same_box() -> void:
	var st := CreatureStorage.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var d := _wild(&"squirtle", 5, 3)
	st.add_creature(a); st.add_creature(b); st.add_creature(d)
	var ok := st.move_between_boxes(a.instance_id, 0, 5)
	var box := st.get_box(0)
	_check.call("storage_move_same", ok and box.creature_at(0) == null and box.creature_at(5) == a and box.creature_at(2) == d)


func _test_storage_move_between_boxes() -> void:
	var st := CreatureStorage.new()
	for i in range(31):
		st.add_creature(_wild(&"bulbasaur", 5, 100 + i))
	_check.call("storage_two_boxes", st.box_count() == 2)
	var first := st.get_box(0).creature_at(0)
	var ok := st.move_between_boxes(first.instance_id, 1, 5)
	_check.call("storage_cross_move", ok and st.get_box(0).creature_at(0) == null and st.get_box(1).creature_at(5) == first)


func _test_storage_swap() -> void:
	var st := CreatureStorage.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	st.add_creature(a); st.add_creature(b)
	var ok := st.swap_slots(0, 0, 0, 1)
	var box := st.get_box(0)
	_check.call("storage_swap", ok and box.creature_at(0) == b and box.creature_at(1) == a)


func _test_storage_invalid_move_no_mutation() -> void:
	var st := CreatureStorage.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	st.add_creature(a); st.add_creature(b)
	var ok := st.move_between_boxes(a.instance_id, 0, 1)
	_check.call("storage_invalid_move", ok == false and st.get_box(0).creature_at(0) == a and st.get_box(0).creature_at(1) == b)


func _test_storage_auto_new_box() -> void:
	var st := CreatureStorage.new()
	for i in range(31):
		st.add_creature(_wild(&"bulbasaur", 5, 200 + i))
	_check.call("storage_auto_box_count", st.box_count() == 2)
	_check.call("storage_auto_box_has_all", st.get_all_creatures().size() == 31)


func _test_storage_capacity_30() -> void:
	var rs := StorageRuleset.new()
	_check.call("storage_cap_const", rs.BOX_CAPACITY == 30)
	var st := CreatureStorage.new()
	for i in range(30):
		st.add_creature(_wild(&"bulbasaur", 5, 300 + i))
	_check.call("storage_box_full", st.get_box(0).is_full() and st.get_box(0).capacity == 30)


func _test_storage_locate() -> void:
	var st := CreatureStorage.new()
	var c := _wild(&"bulbasaur", 5, 1)
	st.add_creature(c)
	var loc := st.locate(c.instance_id)
	_check.call("storage_locate_ok", loc.box_index == 0 and loc.slot == 0)


func _test_party_to_storage() -> void:
	var pc := PlayerCollection.new()
	var c := _wild(&"bulbasaur", 5, 1)
	pc.party.add_creature(c)
	_check.call("party_deposit", pc.deposit(c.instance_id))
	_check.call("party_deposit_left", not pc.party.contains_instance_id(c.instance_id))
	_check.call("party_deposit_loc", pc.location_of(c.instance_id) == &"STORAGE")


func _test_party_to_storage_same_instance() -> void:
	var pc := PlayerCollection.new()
	var c := _wild(&"bulbasaur", 5, 1)
	pc.party.add_creature(c)
	pc.deposit(c.instance_id)
	_check.call("party_deposit_same_instance", pc.storage.get_creature(c.instance_id) == c)


func _test_storage_to_party() -> void:
	var pc := PlayerCollection.new()
	var c := _wild(&"bulbasaur", 5, 1)
	pc.storage.add_creature(c)
	_check.call("storage_withdraw", pc.withdraw(c.instance_id))
	_check.call("storage_withdraw_in_party", pc.party.contains_instance_id(c.instance_id))
	_check.call("storage_withdraw_loc", pc.location_of(c.instance_id) == &"PARTY")


func _test_storage_to_party_same_instance() -> void:
	var pc := PlayerCollection.new()
	var c := _wild(&"bulbasaur", 5, 1)
	pc.storage.add_creature(c)
	pc.withdraw(c.instance_id)
	_check.call("storage_withdraw_same_instance", pc.party.get_creature(c.instance_id) == c)


func _test_storage_to_full_party_rejected() -> void:
	var pc := PlayerCollection.new()
	for i in range(6):
		pc.party.add_creature(_wild(&"bulbasaur", 5, 400 + i))
	var c := _wild(&"pikachu", 5, 1)
	pc.storage.add_creature(c)
	_check.call("storage_withdraw_full_rejected", pc.withdraw(c.instance_id) == false)
	_check.call("storage_withdraw_full_stays", pc.storage.contains_instance_id(c.instance_id) and not pc.party.contains_instance_id(c.instance_id))


func _test_party_storage_no_duplicate_instance_id() -> void:
	var pc := PlayerCollection.new()
	var c := _wild(&"bulbasaur", 5, 1)
	pc.party.add_creature(c)
	pc.deposit(c.instance_id)
	_check.call("no_double_ownership", not (pc.party.contains_instance_id(c.instance_id) and pc.storage.contains_instance_id(c.instance_id)))


func _full_party(seed_base: int) -> CreatureParty:
	var p := CreatureParty.new()
	for i in range(6):
		p.add_creature(_wild(&"bulbasaur", 5, seed_base + i))
	return p


func _test_capture_full_party_routes_to_storage() -> void:
	var party := _full_party(500)
	var storage := CreatureStorage.new()
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	_check.call("cap_full_disposition", res.disposition == CaptureDisposition.STORAGE_REQUIRED)
	_check.call("cap_full_party_unchanged", party.size() == 6 and not party.contains_instance_id(wild.instance_id))
	var rr := CaptureOwnershipRouter.new().route(res, party, storage)
	_check.call("cap_full_routed", rr.routed and rr.stored)
	_check.call("cap_full_in_storage", storage.contains_instance_id(wild.instance_id))


func _test_capture_storage_same_instance() -> void:
	var party := _full_party(600)
	var storage := CreatureStorage.new()
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	CaptureOwnershipRouter.new().route(res, party, storage)
	_check.call("cap_storage_same_instance", storage.get_creature(wild.instance_id) == wild)


func _capture_preserves(overrides: Dictionary) -> Dictionary:
	var party := _full_party(700)
	var storage := CreatureStorage.new()
	var wild := _wild(&"pikachu", 30, 1, overrides)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	CaptureOwnershipRouter.new().route(res, party, storage)
	return {"wild": wild, "stored": storage.get_creature(wild.instance_id)}


func _test_capture_storage_preserves_iv() -> void:
	var r := _capture_preserves({"ivs": {"attack": 31, "speed": 17}})
	_check.call("cap_storage_ivs", r.wild.ivs == r.stored.ivs)


func _test_capture_storage_preserves_nature() -> void:
	var r := _capture_preserves({"nature_id": &"jolly"})
	_check.call("cap_storage_nature", r.wild.nature_id == r.stored.nature_id)


func _test_capture_storage_preserves_ability() -> void:
	var r := _capture_preserves({"ability_id": &"static"})
	_check.call("cap_storage_ability", r.wild.ability_id == r.stored.ability_id)


func _test_capture_storage_preserves_moves_pp() -> void:
	var r := _capture_preserves({})
	_check.call("cap_storage_moves", r.stored.moveset.size() == r.wild.moveset.size())
	var same := true
	for i in r.wild.moveset.size():
		if r.stored.moveset[i].move_id != r.wild.moveset[i].move_id or r.stored.moveset[i].current_pp != r.wild.moveset[i].current_pp:
			same = false
	_check.call("cap_storage_pp", same)
