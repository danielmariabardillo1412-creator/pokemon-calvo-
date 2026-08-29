class_name CapturePartyTestSuite
extends RefCounted

# FASE 7 tests: persistent Party roster + deterministic Capture Core (calvo_capture_v1).
# Covers: party ops/serialization, capture rules, ball definitions, status bonus,
# wild/trainer restriction, identity preservation, determinism, and battle->capture->party integration.

var _check: Callable
var _gd: GameData
var _catalog: DefinitionCatalog


func run(check_callback: Callable) -> void:
	_check = check_callback
	_gd = _import_pokeapi()
	_catalog = _gd.to_definition_catalog()
	var tests := [
		# --- Party ---
		"_test_party_empty", "_test_party_add", "_test_party_max_six",
		"_test_party_reject_seventh", "_test_party_duplicate_id", "_test_party_remove",
		"_test_party_swap", "_test_party_reorder", "_test_party_serialization",
		"_test_party_creature_fidelity",
		"_test_party_reorder_rejects_duplicate_longer",
		"_test_party_reorder_rejects_duplicate_same_length",
		"_test_party_reorder_failure_preserves_original_order",
		"_test_party_from_dict_deduplicates_order",
		"_test_party_from_dict_no_duplicate_instances",
		"_test_party_from_dict_order_by_id_consistency",
		"_test_party_from_dict_corrupt_order_respects_max_six",
		# --- Capture ---
		"_test_capture_valid_attempt", "_test_capture_invalid_target_null",
		"_test_capture_trainer_rejected", "_test_capture_unknown_ball",
		"_test_capture_full_hp_harder", "_test_capture_status_bonus",
		"_test_capture_poke_ball_prob", "_test_capture_great_ball_prob",
		"_test_capture_ultra_ball_prob", "_test_capture_master_ball_guaranteed",
		"_test_capture_master_ball_no_rng", "_test_capture_deterministic_seed",
		"_test_capture_preserves_identity", "_test_capture_iv_preserved",
		"_test_capture_nature_preserved", "_test_capture_ability_preserved",
		"_test_capture_moves_preserved", "_test_capture_pp_preserved",
		"_test_capture_failed_no_ownership", "_test_capture_full_party_storage_required",
		"_test_capture_successful_party_add", "_test_capture_item_consumption_semantic",
		"_test_capture_non_guaranteed_not_auto_success",
		"_test_capture_null_party_semantics", "_test_capture_null_party_no_fake_party_added",
		"_test_capture_normal_party_still_added", "_test_capture_full_party_still_storage_required",
		# --- Integration ---
		"_test_integration_factory_battle_capture_party",
		# --- Golden ---
		"_test_golden_pikachu_poke_ball", "_test_golden_status_bonus", "_test_golden_master_ball",
	]
	for t in tests:
		print("CAP_TEST %s" % t)
		self.call(t)


func _import_pokeapi() -> GameData:
	return _probe_import()


func _probe_import() -> GameData:
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


func _prs() -> ProgressionRuleset:
	return ProgressionRuleset.new()


func _crs() -> CaptureRuleset:
	return CaptureRuleset.new()


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _wild(id: StringName, level: int, seed: int, overrides: Dictionary = {}) -> CreatureInstance:
	return CreatureFactory.create(_species(id), level, _catalog, _prs(), _rng(seed), overrides)


func _wild_context(finished: bool = false) -> CaptureBattleContext:
	var c := CaptureBattleContext.new()
	c.is_wild = true
	c.battle_finished = finished
	return c


func _attempt(target: CreatureInstance, ball: StringName, ctx: CaptureBattleContext) -> CaptureAttempt:
	return CaptureAttempt.new(target, ball, ctx)


# --- Party -----------------------------------------------------------------

func _test_party_empty() -> void:
	var p := CreatureParty.new()
	_check.call("party_empty", p.is_empty() and p.size() == 0)
	_check.call("party_not_full", not p.is_full())


func _test_party_add() -> void:
	var p := CreatureParty.new()
	var c := _wild(&"bulbasaur", 5, 1)
	_check.call("party_add_ok", p.add_creature(c) and p.size() == 1)
	_check.call("party_contains", p.contains_instance_id(c.instance_id))
	_check.call("party_get", p.get_creature(c.instance_id) == c)


func _test_party_max_six() -> void:
	var p := CreatureParty.new()
	for i in range(6):
		var c := _wild(&"bulbasaur", 5, 100 + i)
		p.add_creature(c)
	_check.call("party_six_full", p.size() == 6 and p.is_full())


func _test_party_reject_seventh() -> void:
	var p := CreatureParty.new()
	for i in range(6):
		p.add_creature(_wild(&"bulbasaur", 5, 200 + i))
	var extra := _wild(&"bulbasaur", 5, 999)
	_check.call("party_reject_seventh", p.add_creature(extra) == false and p.size() == 6)
	_check.call("party_extra_not_added", not p.contains_instance_id(extra.instance_id))


func _test_party_duplicate_id() -> void:
	var p := CreatureParty.new()
	var c := _wild(&"bulbasaur", 5, 1)
	p.add_creature(c)
	var dup := _wild(&"bulbasaur", 5, 1)  # same seed -> same instance_id from factory
	# Force same instance_id explicitly to simulate a duplicate.
	dup.instance_id = c.instance_id
	_check.call("party_duplicate_rejected", p.add_creature(dup) == false and p.size() == 1)


func _test_party_remove() -> void:
	var p := CreatureParty.new()
	var c := _wild(&"bulbasaur", 5, 1)
	p.add_creature(c)
	_check.call("party_remove_ok", p.remove_creature(c.instance_id) and p.size() == 0)
	_check.call("party_remove_missing", p.remove_creature(c.instance_id) == false)


func _test_party_swap() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	p.add_creature(a)
	p.add_creature(b)
	var ok := p.swap(a.instance_id, b.instance_id)
	var ids := p.get_ordered_ids()
	_check.call("party_swap_ok", ok and ids[0] == b.instance_id and ids[1] == a.instance_id)


func _test_party_reorder() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var c := _wild(&"squirtle", 5, 3)
	p.add_creature(a)
	p.add_creature(b)
	p.add_creature(c)
	var ok := p.reorder([c.instance_id, a.instance_id, b.instance_id])
	_check.call("party_reorder_ok", ok and p.get_ordered_ids() == [c.instance_id, a.instance_id, b.instance_id])
	var bad := p.reorder([a.instance_id, b.instance_id])  # missing c
	_check.call("party_reorder_rejects_subset", bad == false)


func _test_party_serialization() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 7, 1)
	var b := _wild(&"pikachu", 9, 2)
	p.add_creature(a)
	p.add_creature(b)
	var d := p.to_dict()
	var restored := CreatureParty.from_dict(d)
	_check.call("party_ser_size", restored.size() == 2)
	_check.call("party_ser_order", restored.get_ordered_ids() == p.get_ordered_ids())
	_check.call("party_ser_ids", restored.contains_instance_id(a.instance_id) and restored.contains_instance_id(b.instance_id))


func _test_party_creature_fidelity() -> void:
	var p := CreatureParty.new()
	var c := _wild(&"pikachu", 12, 5, {"nature_id": &"adamant", "ivs": {"attack": 31, "speed": 30}})
	p.add_creature(c)
	var restored := CreatureParty.from_dict(p.to_dict())
	var rc := restored.get_creature(c.instance_id)
	_check.call("party_fid_species", rc.species_id == &"pikachu")
	_check.call("party_fid_level", rc.level == 12)
	_check.call("party_fid_nature", rc.nature_id == &"adamant")
	_check.call("party_fid_ivs", rc.ivs == c.ivs)
	_check.call("party_fid_moves", rc.moveset.size() == c.moveset.size())


func _test_party_reorder_rejects_duplicate_longer() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var c := _wild(&"squirtle", 5, 3)
	p.add_creature(a); p.add_creature(b); p.add_creature(c)
	var before := p.get_ordered_ids()
	_check.call("reorder_dup_longer", p.reorder([a.instance_id, b.instance_id, c.instance_id, a.instance_id]) == false)
	_check.call("reorder_dup_longer_order_unchanged", p.get_ordered_ids() == before)


func _test_party_reorder_rejects_duplicate_same_length() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var c := _wild(&"squirtle", 5, 3)
	p.add_creature(a); p.add_creature(b); p.add_creature(c)
	var before := p.get_ordered_ids()
	_check.call("reorder_dup_same_len", p.reorder([a.instance_id, a.instance_id, b.instance_id]) == false)
	_check.call("reorder_dup_same_len_order_unchanged", p.get_ordered_ids() == before)


func _test_party_reorder_failure_preserves_original_order() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var c := _wild(&"squirtle", 5, 3)
	p.add_creature(a); p.add_creature(b); p.add_creature(c)
	var before := p.get_ordered_ids()
	_check.call("reorder_unknown_rejected", p.reorder([a.instance_id, b.instance_id, &"ghost"]) == false)
	_check.call("reorder_failure_preserves_order", p.get_ordered_ids() == before)


func _test_party_from_dict_deduplicates_order() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var c := _wild(&"squirtle", 5, 3)
	p.add_creature(a); p.add_creature(b); p.add_creature(c)
	var d := p.to_dict()
	var o: Array = Array(d["ordered_instance_ids"])
	o.append(String(a.instance_id))  # duplicate first id
	d["ordered_instance_ids"] = o
	var restored := CreatureParty.from_dict(d)
	_check.call("from_dict_dedup_order", restored.get_ordered_ids() == [a.instance_id, b.instance_id, c.instance_id])


func _test_party_from_dict_no_duplicate_instances() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var c := _wild(&"squirtle", 5, 3)
	p.add_creature(a); p.add_creature(b); p.add_creature(c)
	var d := p.to_dict()
	var o: Array = Array(d["ordered_instance_ids"])
	o.append(String(a.instance_id))
	d["ordered_instance_ids"] = o
	var restored := CreatureParty.from_dict(d)
	_check.call("from_dict_no_dup_instances", restored.get_ordered_ids().size() == restored.size() and restored.size() == 3)


func _test_party_from_dict_order_by_id_consistency() -> void:
	var p := CreatureParty.new()
	var a := _wild(&"bulbasaur", 5, 1)
	var b := _wild(&"charmander", 5, 2)
	var c := _wild(&"squirtle", 5, 3)
	p.add_creature(a); p.add_creature(b); p.add_creature(c)
	var d := p.to_dict()
	var o: Array = Array(d["ordered_instance_ids"])
	o.append(String(a.instance_id))
	d["ordered_instance_ids"] = o
	var restored := CreatureParty.from_dict(d)
	var consistent := true
	for id in restored.get_ordered_ids():
		if restored.get_creature(id) == null:
			consistent = false
	_check.call("from_dict_order_by_id_consistent", consistent and restored.get_ordered_ids().size() == restored.get_creatures().size())


func _test_party_from_dict_corrupt_order_respects_max_six() -> void:
	var creatures: Array[CreatureInstance] = []
	var ids: Array[StringName] = [&"a1", &"a2", &"a3", &"a4", &"a5", &"a6", &"a7", &"a8"]
	for i in range(8):
		creatures.append(_mk_creature(100 + i, ids[i]))
	var d := _dict_from_creatures(creatures, ids)
	var restored := CreatureParty.from_dict(d)
	_check.call("from_dict_max_six_size", restored.size() == 6 and restored.is_full())
	_check.call("from_dict_max_six_invariant", restored.get_ordered_ids().size() == restored.size())


# --- Capture ---------------------------------------------------------------

func _test_capture_valid_attempt() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var rng := _rng(123)
	var res := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), rng, _catalog, CreatureParty.new())
	_check.call("capture_valid_not_invalid", res.result.status != CaptureResult.INVALID)
	_check.call("capture_valid_consumes", res.result.consume_item == true)
	var r2 := _rng(123)
	var res2 := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), r2, _catalog, CreatureParty.new())
	_check.call("capture_valid_deterministic", res.result.status == res2.result.status and res.result.shake_count == res2.result.shake_count)


func _test_capture_invalid_target_null() -> void:
	var res := CaptureSystem.resolve(CaptureAttempt.new(null, &"poke_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_invalid_target", res.result.status == CaptureResult.INVALID and res.result.consume_item == false)


func _test_capture_trainer_rejected() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	var ctx := CaptureBattleContext.new()
	ctx.is_wild = false
	ctx.target_owner_trainer_id = &"rival"
	var res := CaptureSystem.resolve(_attempt(wild, &"poke_ball", ctx), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_trainer_rejected", res.result.status == CaptureResult.INVALID and res.result.reason == "trainer_battle_not_capturable")


func _test_capture_unknown_ball() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	var res := CaptureSystem.resolve(_attempt(wild, &"banana_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_unknown_ball", res.result.status == CaptureResult.INVALID and res.result.reason == "unknown_ball")


func _test_capture_full_hp_harder() -> void:
	var sp := _species(&"pikachu")
	var crs := _crs()
	var full := crs.catch_probability(sp.capture_rate, 1.0, 1.0, 100, 100)
	var low := crs.catch_probability(sp.capture_rate, 1.0, 1.0, 100, 1)
	_check.call("capture_full_hp_harder", low > full and full > 0.0)


func _test_capture_status_bonus() -> void:
	var sp := _species(&"pikachu")
	var crs := _crs()
	var none := crs.catch_probability(sp.capture_rate, 1.0, 1.0, 100, 100)
	var sleep := crs.catch_probability(sp.capture_rate, 1.0, crs.status_bonus(&"sleep"), 100, 100)
	_check.call("capture_status_bonus", sleep > none and abs(sleep - none * 2.0) < 0.001)


func _test_capture_poke_ball_prob() -> void:
	var sp := _species(&"pikachu")  # capture_rate 190
	var crs := _crs()
	var p := crs.catch_probability(sp.capture_rate, crs.ball(&"poke_ball").base_multiplier, 1.0, 100, 100)
	# expected ~ (190/255) * 1 * (1/3) = 0.248366
	_check.call("capture_poke_prob", abs(p - 0.2483) < 0.002)


func _test_capture_great_ball_prob() -> void:
	var sp := _species(&"pikachu")
	var crs := _crs()
	var poke := crs.catch_probability(sp.capture_rate, crs.ball(&"poke_ball").base_multiplier, 1.0, 100, 100)
	var great := crs.catch_probability(sp.capture_rate, crs.ball(&"great_ball").base_multiplier, 1.0, 100, 100)
	_check.call("capture_great_ratio", abs(great - poke * 1.5) < 1e-6)


func _test_capture_ultra_ball_prob() -> void:
	var sp := _species(&"pikachu")
	var crs := _crs()
	var poke := crs.catch_probability(sp.capture_rate, crs.ball(&"poke_ball").base_multiplier, 1.0, 100, 100)
	var ultra := crs.catch_probability(sp.capture_rate, crs.ball(&"ultra_ball").base_multiplier, 1.0, 100, 100)
	_check.call("capture_ultra_ratio", abs(ultra - poke * 2.0) < 1e-6)


func _test_capture_master_ball_guaranteed() -> void:
	var crs := _crs()
	_check.call("master_is_guaranteed", crs.ball(&"master_ball").guaranteed == true)
	for seed in [1, 7, 42, 123, 999]:
		var wild := _wild(&"mewtwo", 50, seed)  # lowest rate (3)
		wild.current_hp = wild.stats.max_hp          # worst case
		var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(seed), _catalog, CreatureParty.new())
		if res.result.status != CaptureResult.SUCCESS:
			_check.call("master_ball_guaranteed", false)
			return
	_check.call("master_ball_guaranteed", true)


func _test_capture_master_ball_no_rng() -> void:
	var wild := _wild(&"pikachu", 50, 1)
	var rng := _rng(999)
	var s0 = rng.state
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), rng, _catalog, CreatureParty.new())
	var s1 = rng.state
	_check.call("master_ball_no_rng", res.result.status == CaptureResult.SUCCESS and s0 == s1)


func _test_capture_deterministic_seed() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var r1 := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), _rng(555), _catalog, CreatureParty.new())
	var r2 := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), _rng(555), _catalog, CreatureParty.new())
	_check.call("capture_seed_deterministic",
		r1.result.status == r2.result.status and r1.result.shake_count == r2.result.shake_count and _event_kinds(r1) == _event_kinds(r2))


func _event_kinds(res: CaptureResolution) -> Array:
	var out := []
	for e in res.events:
		out.append(String(e.kind))
	return out


func _has_event(res: CaptureResolution, kind: StringName) -> bool:
	for e in res.events:
		if e.kind == kind:
			return true
	return false


func _mk_creature(seed: int, id: StringName) -> CreatureInstance:
	var c := _wild(&"bulbasaur", 5, seed)
	c.instance_id = id
	return c


func _dict_from_creatures(creatures: Array[CreatureInstance], order: Array[StringName]) -> Dictionary:
	var cds := []
	for c in creatures:
		cds.append(c.to_dict())
	var oids := []
	for x in order:
		oids.append(String(x))
	return {
		"schema_version": 2,
		"ruleset_id": "calvo_party_v1",
		"ordered_instance_ids": oids,
		"creatures": cds,
	}


func _test_capture_preserves_identity() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_identity", res.captured == wild and res.captured.instance_id == wild.instance_id)


func _test_capture_iv_preserved() -> void:
	var wild := _wild(&"pikachu", 30, 1, {"ivs": {"attack": 31, "speed": 17}})
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_iv_preserved", res.captured.ivs == wild.ivs)


func _test_capture_nature_preserved() -> void:
	var wild := _wild(&"pikachu", 30, 1, {"nature_id": &"jolly"})
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_nature_preserved", res.captured.nature_id == &"jolly")


func _test_capture_ability_preserved() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_ability_preserved", res.captured.ability_id == wild.ability_id)


func _test_capture_moves_preserved() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("capture_moves_preserved", res.captured.moveset.size() == wild.moveset.size())
	var same := true
	for i in wild.moveset.size():
		if res.captured.moveset[i].move_id != wild.moveset[i].move_id:
			same = false
	_check.call("capture_move_ids_preserved", same)


func _test_capture_pp_preserved() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	var same := true
	for i in wild.moveset.size():
		if res.captured.moveset[i].current_pp != wild.moveset[i].current_pp:
			same = false
	_check.call("capture_pp_preserved", same)


func _test_capture_failed_no_ownership() -> void:
	var wild := _wild(&"mewtwo", 50, 1)  # lowest capture rate (3)
	wild.current_hp = wild.stats.max_hp        # worst case for capture
	var found := false
	for seed in range(1, 40):
		var party := CreatureParty.new()
		var res := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), _rng(seed), _catalog, party)
		if res.result.status == CaptureResult.FAILED:
			found = true
			_check.call("capture_failed_no_ownership", not party.contains_instance_id(wild.instance_id))
			break
	_check.call("capture_failed_case_found", found)


func _test_capture_full_party_storage_required() -> void:
	var party := CreatureParty.new()
	for i in range(6):
		party.add_creature(_wild(&"bulbasaur", 5, 300 + i))
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	_check.call("capture_full_storage", res.disposition == CaptureDisposition.STORAGE_REQUIRED)
	_check.call("capture_full_party_unchanged", party.size() == 6 and not party.contains_instance_id(wild.instance_id))
	_check.call("capture_full_returns_creature", res.captured != null)


func _test_capture_successful_party_add() -> void:
	var party := CreatureParty.new()
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	_check.call("capture_success_add", res.disposition == CaptureDisposition.PARTY and party.size() == 1 and party.contains_instance_id(wild.instance_id))


func _test_capture_item_consumption_semantic() -> void:
	var wild := _wild(&"mewtwo", 50, 1)
	wild.current_hp = wild.stats.max_hp
	var fail := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), _rng(3), _catalog, CreatureParty.new())
	_check.call("capture_consume_on_fail", fail.result.consume_item == true)
	var invalid := CaptureSystem.resolve(_attempt(wild, &"banana_ball", _wild_context()), _rng(3), _catalog, CreatureParty.new())
	_check.call("capture_no_consume_on_invalid", invalid.result.consume_item == false)


func _test_capture_non_guaranteed_not_auto_success() -> void:
	# A low-probability (non-guaranteed) wild capture must NOT auto-succeed: the outcome is computed
	# from the probability + RNG. This proves the result is not hardcoded true (no implicit "auto win").
	# NOTE: this is NOT a client/server antiforgery test - CaptureSystem is pure logic.
	var wild := _wild(&"mewtwo", 50, 1)
	wild.current_hp = wild.stats.max_hp
	var any_failed := false
	for seed in range(1, 40):
		var res := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), _rng(seed), _catalog, CreatureParty.new())
		if res.result.status == CaptureResult.FAILED:
			any_failed = true
			break
	_check.call("capture_non_guaranteed_not_auto_success", any_failed)


func _test_capture_null_party_semantics() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, null)
	_check.call("null_party_success", res.result.status == CaptureResult.SUCCESS)
	_check.call("null_party_captured", res.captured == wild)
	_check.call("null_party_disposition_unrouted", res.disposition == CaptureDisposition.UNROUTED)
	_check.call("null_party_not_party", res.disposition != CaptureDisposition.PARTY)


func _test_capture_null_party_no_fake_party_added() -> void:
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, null)
	_check.call("null_party_no_fake_add", not _has_event(res, CaptureEvent.PARTY_ADDED))


func _test_capture_normal_party_still_added() -> void:
	var party := CreatureParty.new()
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	_check.call("normal_party_added", res.disposition == CaptureDisposition.PARTY and party.contains_instance_id(wild.instance_id) and party.size() == 1)
	_check.call("normal_party_event", _has_event(res, CaptureEvent.PARTY_ADDED))


func _test_capture_full_party_still_storage_required() -> void:
	var party := CreatureParty.new()
	for i in range(6):
		party.add_creature(_wild(&"bulbasaur", 5, 400 + i))
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, party)
	_check.call("full_party_storage", res.disposition == CaptureDisposition.STORAGE_REQUIRED)
	_check.call("full_party_no_fake_add", not _has_event(res, CaptureEvent.PARTY_ADDED))
	_check.call("full_party_storage_event", _has_event(res, CaptureEvent.STORAGE_REQUIRED))
	_check.call("full_party_unchanged", party.size() == 6 and not party.contains_instance_id(wild.instance_id))


# --- Integration -----------------------------------------------------------

func _test_integration_factory_battle_capture_party() -> void:
	var player := _wild(&"bulbasaur", 50, 11)
	var wild := _wild(&"pikachu", 30, 22)
	wild.current_hp = 1
	wild.status_state.persistent_id = &"sleep"
	var state := BattleState.create_with_parties(&"player", [player], [wild])
	var ctx := CaptureBattleContext.new()
	ctx.is_wild = true
	ctx.target_side_id = &"side_b"
	var party := CreatureParty.new()
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", ctx), _rng(7), _catalog, party)
	_check.call("integration_success", res.result.status == CaptureResult.SUCCESS)
	_check.call("integration_added", party.contains_instance_id(wild.instance_id) and party.size() == 1)
	_check.call("integration_identity", res.captured == wild)
	var in_battle := state.creature(wild.instance_id)
	_check.call("integration_battle_same_ref", in_battle == wild)
	var restored := CreatureParty.from_dict(party.to_dict())
	var rc := restored.get_creature(wild.instance_id)
	_check.call("integration_roundtrip", rc != null and rc.species_id == &"pikachu" and rc.level == wild.level and rc.ivs == wild.ivs and rc.nature_id == wild.nature_id and rc.moveset.size() == wild.moveset.size())


# --- Golden ----------------------------------------------------------------

func _test_golden_pikachu_poke_ball() -> void:
	var crs := _crs()
	var sp := _species(&"pikachu")  # capture_rate 190
	var p := crs.catch_probability(sp.capture_rate, 1.0, 1.0, 100, 100)
	_check.call("golden_poke_prob", abs(p - 0.2483) < 0.002)
	var wild := _wild(&"pikachu", 30, 1)
	wild.current_hp = 1
	var r1 := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), _rng(314), _catalog, CreatureParty.new())
	var r2 := CaptureSystem.resolve(_attempt(wild, &"poke_ball", _wild_context()), _rng(314), _catalog, CreatureParty.new())
	_check.call("golden_deterministic", r1.result.status == r2.result.status and r1.result.shake_count == r2.result.shake_count)


func _test_golden_status_bonus() -> void:
	var crs := _crs()
	var sp := _species(&"pikachu")
	var none := crs.catch_probability(sp.capture_rate, 1.0, 1.0, 100, 100)
	var sleep := crs.catch_probability(sp.capture_rate, 1.0, crs.status_bonus(&"sleep"), 100, 100)
	var freeze := crs.catch_probability(sp.capture_rate, 1.0, crs.status_bonus(&"freeze"), 100, 100)
	var weak := crs.catch_probability(sp.capture_rate, 1.0, crs.status_bonus(&"paralysis"), 100, 100)
	_check.call("golden_sleep_eq_freeze", abs(sleep - freeze) < 1e-9)
	_check.call("golden_sleep_vs_weak", sleep > weak and abs(sleep - weak * (2.0 / 1.5)) < 0.001)


func _test_golden_master_ball() -> void:
	var crs := _crs()
	_check.call("golden_master_guaranteed", crs.ball(&"master_ball").guaranteed == true)
	var wild := _wild(&"mewtwo", 50, 1)
	wild.current_hp = wild.stats.max_hp
	var res := CaptureSystem.resolve(_attempt(wild, &"master_ball", _wild_context()), _rng(1), _catalog, CreatureParty.new())
	_check.call("golden_master_success", res.result.status == CaptureResult.SUCCESS)
