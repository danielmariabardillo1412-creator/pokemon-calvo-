extends "res://tests/gameplay/parallel_items_w02_mint_pilot_20261109.gd"

# IA6 MINT-L3 pilot02; independent runner. Pilot01 remains unchanged.
const DATA02 := "res://tests/fixtures/parallel_items/w02_mint_pilot02_20261109.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run_mint02")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("W02 MINT-L3 pilot02 watchdog")
			quit(2)
	)

func _run_mint02() -> void:
	destination = "res://.godot/parallel_items/w02_mint_pilot02_20261109"
	DirAccess.make_dir_recursive_absolute(destination)
	var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA02))
	if not f is Dictionary:
		push_error("W02 MINT-L3 pilot02 fixture invalid")
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("pilot02 catalog overlay", Variants.apply(catalogs))
	check("pilot02 exact authorized case IDs", f.worker == "W02"
		and f.block == "02" and f.ids == ["adamant_mint", "modest_mint", "timid_mint"]
		and f.origin.pilot01_run == 42696681590)
	var positives: int = 0
	var negatives: int = 0
	for spec: Dictionary in f.cases:
		for mode: String in f.modes:
			current_case = String(spec.id) + "_" + mode
			var before_errors: int = errors.size()
			_probe_pilot02(spec, mode)
			if errors.size() == before_errors:
				if mode == "none": negatives += 1
				else: positives += 1
	for spec: Dictionary in f.cases:
		current_case = String(spec.id) + "_level100"
		_probe_level100_02(spec)
	current_case = "lonely_to_modest"
	_probe_replacement02(f.sequential)
	var passed: bool = errors.is_empty() and positives == 6 and negatives == 3
	done = true
	print("W02_MINT_PILOT02_20261109_GODOT ", "PASS" if passed else "FAIL", " checks=", checks)
	quit(0 if passed else 1)

func _probe_pilot02(spec: Dictionary, mode: String) -> void:
	var item: StringName = StringName(spec.id)
	var target: StringName = StringName(spec.target_nature)
	var c: CreatureInstance = _pilot_creature()
	check(mode + " pilot02 real creature and mint in catalog", c != null
		and catalogs.item(item) != null)
	if c == null: return
	var owner: PlayerCollection = _pilot_owner(c, mode)
	if mode != "none": check(mode + " pilot02 inventory stock", owner.inventory.add(item, 2))
	var svc := Service.new()
	check(mode + " pilot02 FieldItemService", svc.configure(owner, catalogs, func(): return true))
	var start: Dictionary = _owner_data(owner)
	var original: Dictionary = c.to_dict()
	var old_stats: Dictionary = c.stats.to_dict()
	var desired: Dictionary = StatCalculator.compute(
		catalogs.species(c.species_id).base_stat_block(), c.ivs, c.evs,
		target, c.level).to_dict()
	check(mode + " pilot02 positive nature profile independent",
		ProgressionRuleset.is_valid_nature(target)
		and desired != old_stats
		and int(desired.get(String(spec.up), 0)) > int(old_stats.get(String(spec.up), 0))
		and int(desired.get(String(spec.down), 0)) < int(old_stats.get(String(spec.down), 0))
		and int(desired.max_hp) == int(old_stats.max_hp))
	var wrong: Dictionary = svc.use_item(item, &"own", 0)
	check(mode + " pilot02 invalid slot atomic rollback",
		not bool(wrong.get("accepted", true))
		and String(wrong.get("reason", "")) == "unexpected_mint_target"
		and _owner_data(owner) == start)
	var wrong_species: Dictionary = svc.use_item(item, &"own", -1, &"mew")
	check(mode + " pilot02 wrong species target atomic rollback",
		not bool(wrong_species.get("accepted", true))
		and String(wrong_species.get("reason", "")) == "unexpected_mint_target"
		and _owner_data(owner) == start)
	if mode != "none":
		var hp_before: int = c.current_hp
		c.current_hp = 0
		var faint_before: Dictionary = _owner_data(owner)
		var fainted: Dictionary = svc.use_item(item, &"own")
		check(mode + " pilot02 fainted rejected without inventory change",
			not bool(fainted.get("accepted", true))
			and String(fainted.get("reason", "")) == "creature_knocked_out"
			and _owner_data(owner) == faint_before)
		c.current_hp = hp_before
		c.battle_transform_original = {"original_species_id": "mew"}
		var combat_before: Dictionary = _owner_data(owner)
		var combat: Dictionary = svc.use_item(item, &"own")
		check(mode + " pilot02 temporary battle state rejected atomically",
			not bool(combat.get("accepted", true))
			and String(combat.get("reason", "")) == "temporary_battle_state"
			and _owner_data(owner) == combat_before)
		c.battle_transform_original.clear()
		c.stats.attack += 1
		var incoherent_before: Dictionary = _owner_data(owner)
		var incoherent: Dictionary = svc.use_item(item, &"own")
		check(mode + " pilot02 invalid live stats rejected atomically",
			not bool(incoherent.get("accepted", true))
			and String(incoherent.get("reason", "")) == "invalid_mint_state"
			and _owner_data(owner) == incoherent_before)
		c.stats.attack -= 1
	check(mode + " pilot02 original reset after adversarial states", c.to_dict() == original)
	var effect: Dictionary = svc.use_item(item, &"own")
	var expected: bool = mode != "none"
	check(mode + " pilot02 effect acceptance", bool(effect.get("accepted", false)) == expected)
	var now: CreatureInstance = owner.owned_creature(&"own")
	check(mode + " pilot02 same owned identity and location",
		now != null and now.instance_id == &"own"
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	if now == null: return
	if expected:
		check(mode + " pilot02 effective nature actual and original retained",
			now.nature_id == &"hardy" and now.effective_nature_id == target
			and String(effect.get("action", "")) == "effective_nature"
			and String(effect.get("effective_nature_id", "")) == String(target)
			and String(effect.get("original_nature_id", "")) == "hardy")
		var only_allowed: Dictionary = original.duplicate(true)
		only_allowed["effective_nature_id"] = String(target)
		only_allowed["stats"] = desired
		check(mode + " pilot02 all remaining stats HP IV EV PP untouched",
			now.to_dict() == only_allowed and now.stats.to_dict() == desired
			and now.current_hp == c.current_hp and now.stats.max_hp == c.stats.max_hp
			and now.ivs == c.ivs and now.evs == c.evs and now.experience == c.experience
			and now.friendship == c.friendship
			and now.moveset[0].to_dict() == c.moveset[0].to_dict()
			and now.moveset[1].to_dict() == c.moveset[1].to_dict())
		check(mode + " pilot02 exactly one mint consumed", owner.inventory.quantity(item) == 1)
		var after: Dictionary = _owner_data(owner)
		var duplicate: Dictionary = svc.use_item(item, &"own")
		check(mode + " pilot02 repeated mint no effect no second deduction",
			not bool(duplicate.get("accepted", true))
			and String(duplicate.get("reason", "")) == "item_has_no_effect"
			and _owner_data(owner) == after)
	else:
		check(mode + " pilot02 no stock rollback and no consumption",
			String(effect.get("reason", "")) == "item_not_owned"
			and owner.inventory.quantity(item) == 0 and _owner_data(owner) == start)
	check(mode + " pilot02 original candidate object remains untouched", c.to_dict() == original)
	var snapshot: Dictionary = _owner_data(owner)
	var restored: LoadResult = SaveGameRepository.new().decode_snapshot(snapshot)
	check(mode + " pilot02 SaveV2 round trip", restored.ok)
	if restored.ok:
		var loaded := PlayerCollection.new()
		loaded.party = restored.party
		loaded.storage = restored.storage
		loaded.inventory = restored.inventory
		var saved: CreatureInstance = loaded.owned_creature(&"own")
		check(mode + " pilot02 SaveV2 effective nature persists",
			saved != null and saved.to_dict() == now.to_dict()
			and loaded.inventory.quantity(item) == owner.inventory.quantity(item)
			and loaded.location_of(&"own") == owner.location_of(&"own"))
	var legacy: LoadResult = SaveGameRepository.new().decode_snapshot(start)
	check(mode + " pilot02 legacy snapshot still loads", legacy.ok)
	if legacy.ok:
		var old_owner := PlayerCollection.new()
		old_owner.party = legacy.party
		old_owner.storage = legacy.storage
		var old_creature: CreatureInstance = old_owner.owned_creature(&"own")
		check(mode + " pilot02 legacy original nature and HP", old_creature != null
			and old_creature.nature_id == &"hardy"
			and old_creature.effective_nature_id == &""
			and old_creature.stats.to_dict() == old_stats
			and old_creature.current_hp == c.current_hp)
	if expected:
		var corrupt: Dictionary = snapshot.duplicate(true)
		for record: Dictionary in corrupt.get("creatures", []):
			if String(record.get("instance_id", "")) == "own":
				record["effective_nature_id"] = "invalid_mint_20261109"
		var denied: LoadResult = SaveGameRepository.new().decode_snapshot(corrupt)
		check(mode + " pilot02 corrupt effective nature rejected",
			not denied.ok and String(denied.reason) == "invalid_creature_id")

func _probe_level100_02(spec: Dictionary) -> void:
	var item: StringName = StringName(spec.id)
	var nature: StringName = StringName(spec.target_nature)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var c: CreatureInstance = CreatureFactory.create(
		catalogs.species(&"mew"), 100, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": ["growl", "protect"]})
	check("pilot02 level100 real creature " + String(item), c != null)
	if c == null: return
	var owner := _pilot_owner(c, "active")
	check("pilot02 level100 item in inventory", owner.inventory.add(item, 1))
	var svc := Service.new()
	check("pilot02 level100 real service", svc.configure(owner, catalogs, func(): return true))
	var initial: Dictionary = c.to_dict()
	var target: Dictionary = StatCalculator.compute(
		catalogs.species(c.species_id).base_stat_block(), c.ivs, c.evs,
		nature, c.level).to_dict()
	var outcome: Dictionary = svc.use_item(item, &"own")
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("pilot02 level100 nature stats actually change " + String(item),
		bool(outcome.get("accepted", false)) and now != null
		and now.level == 100 and now.nature_id == &"hardy"
		and now.effective_nature_id == nature and now.stats.to_dict() == target
		and now.experience == c.experience
		and now.current_hp == c.current_hp and now.stats.max_hp == c.stats.max_hp
		and owner.inventory.quantity(item) == 0)
	if now != null:
		var desired: Dictionary = initial.duplicate(true)
		desired["effective_nature_id"] = String(nature)
		desired["stats"] = target
		check("pilot02 level100 only derived stats changed", now.to_dict() == desired)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(_owner_data(owner))
	check("pilot02 level100 SaveV2 persists", decoded.ok)
	if decoded.ok:
		var loaded := PlayerCollection.new()
		loaded.party = decoded.party
		var saved: CreatureInstance = loaded.owned_creature(&"own")
		check("pilot02 level100 SaveV2 nature and original remain", saved != null
			and saved.nature_id == &"hardy" and saved.effective_nature_id == nature
			and saved.stats.to_dict() == target)

func _probe_replacement02(spec: Dictionary) -> void:
	var c: CreatureInstance = _pilot_creature()
	check("pilot02 sequence real creature", c != null)
	if c == null: return
	var owner := _pilot_owner(c, "active")
	var initial: Dictionary = c.to_dict()
	var first: StringName = StringName(spec.first)
	var second: StringName = StringName(spec.second)
	check("pilot02 sequence first mint stock", owner.inventory.add(first, 2))
	check("pilot02 sequence second mint stock", owner.inventory.add(second, 2))
	var svc := Service.new()
	check("pilot02 sequence real FieldItemService", svc.configure(owner, catalogs, func(): return true))
	var old_hp: int = c.current_hp
	var first_out: Dictionary = svc.use_item(first, &"own")
	var once: CreatureInstance = owner.owned_creature(&"own")
	check("pilot02 sequence pilot01 mint applies first",
		bool(first_out.get("accepted", false)) and once != null
		and once.effective_nature_id == StringName(spec.first_effective)
		and owner.inventory.quantity(first) == 1 and owner.inventory.quantity(second) == 2)
	var after_first: Dictionary = _owner_data(owner)
	var second_out: Dictionary = svc.use_item(second, &"own")
	var now: CreatureInstance = owner.owned_creature(&"own")
	var expected: Dictionary = StatCalculator.compute(
		catalogs.species(now.species_id).base_stat_block(), now.ivs, now.evs,
		StringName(spec.last_effective), now.level).to_dict()
	check("pilot02 sequence different effective nature replaces previous",
		bool(second_out.get("accepted", false)) and now != null
		and now.nature_id == StringName(spec.original_nature)
		and now.effective_nature_id == StringName(spec.last_effective)
		and now.stats.to_dict() == expected and now.current_hp == old_hp)
	check("pilot02 sequence one unit for each, no phantom double spending",
		owner.inventory.quantity(first) == 1 and owner.inventory.quantity(second) == 1
		and after_first != _owner_data(owner))
	var snapshot: Dictionary = _owner_data(owner)
	var load: LoadResult = SaveGameRepository.new().decode_snapshot(snapshot)
	check("pilot02 sequence SaveV2 round trip", load.ok)
	if load.ok:
		var reloaded := PlayerCollection.new()
		reloaded.party = load.party
		reloaded.storage = load.storage
		reloaded.inventory = load.inventory
		var saved: CreatureInstance = reloaded.owned_creature(&"own")
		check("pilot02 sequence stored final nature and owner inventory",
			saved != null and saved.to_dict() == now.to_dict()
			and reloaded.inventory.quantity(first) == 1 and reloaded.inventory.quantity(second) == 1)
	check("pilot02 sequence original birth nature and object retained", c.to_dict() == initial)
