extends "res://tests/gameplay/parallel_items_w02_campaign_006_block09.gd"

# IA6 authorised pilot MINT-L3 01. No edits to shared SaveV2/battle/stats.
const PILOT_DATA := "res://tests/fixtures/parallel_items/w02_mint_pilot_20261109.json"
const MintPilot = preload("res://modules/inventory/field_mint_effects.gd")

func _initialize() -> void:
	capture = false
	call_deferred("_run_mint_l3")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("W02 MINT-L3 pilot 01 watchdog")
			quit(2)
	)

func _run_mint_l3() -> void:
	destination = "res://.godot/parallel_items/w02_mint_pilot_20261109"
	DirAccess.make_dir_recursive_absolute(destination)
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(PILOT_DATA))
	if not fixture is Dictionary:
		push_error("W02 MINT-L3 fixture missing")
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("MINT-L3 catalog overlay", Variants.apply(catalogs))
	check("MINT-L3 exact pilot IDs", fixture.worker == "W02" and fixture.block == "01"
		and fixture.ids == ["lonely_mint", "mild_mint", "naive_mint"]
		and fixture.base_gate.run_id == 42690004814)
	var positive := 0
	var negative := 0
	for spec: Dictionary in fixture.cases:
		for mode: String in fixture.modes:
			current_case = String(spec.id) + "_" + mode
			var before_errors: int = errors.size()
			_probe_mint_l3(spec, mode)
			if errors.size() == before_errors:
				if mode == "none": negative += 1
				else: positive += 1
	current_case = "gentle_to_lonely"
	var cross_start: int = errors.size()
	_probe_gentle_to_lonely()
	check("MINT-L3 inherited gentle mint sequential integration",
		errors.size() == cross_start)
	var success: bool = errors.is_empty() and positive == 6 and negative == 3
	done = true
	print("W02_MINT_PILOT_20261109_GODOT ", "PASS" if success else "FAIL",
		" checks=", checks)
	quit(0 if success else 1)

func _pilot_creature() -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var creature: CreatureInstance = CreatureFactory.create(
		catalogs.species(&"mew"), 50, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": ["growl", "protect"]})
	if creature != null:
		creature.friendship = 99
		creature.current_hp = maxi(1, creature.stats.max_hp - 9)
	return creature

func _pilot_owner(creature: CreatureInstance, mode: String) -> PlayerCollection:
	var collection := PlayerCollection.new()
	check(mode + " mint pilot real party", collection.party.add_creature(creature))
	if mode == "reserve": check(mode + " mint pilot real storage", collection.deposit(&"own"))
	return collection

func _probe_mint_l3(spec: Dictionary, mode: String) -> void:
	var item: StringName = StringName(spec.id)
	var target: StringName = StringName(spec.target_nature)
	var c: CreatureInstance = _pilot_creature()
	check(mode + " mint pilot creature and catalog item",
		c != null and catalogs.item(item) != null)
	if c == null: return
	var owner := _pilot_owner(c, mode)
	if mode != "none":
		check(mode + " mint pilot stock", owner.inventory.add(item, 2))
	var svc := Service.new()
	check(mode + " mint pilot live FieldItemService", svc.configure(owner, catalogs, func(): return true))
	var before: Dictionary = _owner_data(owner)
	var creature_before: Dictionary = c.to_dict()
	var desired: Dictionary = StatCalculator.compute(
		catalogs.species(c.species_id).base_stat_block(), c.ivs, c.evs, target, c.level).to_dict()
	var old_stats: Dictionary = c.stats.to_dict()
	check(mode + " mint pilot independent positive stat profile",
		ProgressionRuleset.is_valid_nature(target)
		and desired != old_stats
		and int(desired.get(String(spec.up), 0)) > int(old_stats.get(String(spec.up), 0))
		and int(desired.get(String(spec.down), 0)) < int(old_stats.get(String(spec.down), 0))
		and int(desired.get("max_hp", 0)) == int(old_stats.get("max_hp", 0)))
	var wrong: Dictionary = svc.use_item(item, &"own", 0)
	check(mode + " mint pilot wrong target rejected without mutation",
		not bool(wrong.get("accepted", true))
		and String(wrong.get("reason", "")) == "unexpected_mint_target"
		and _owner_data(owner) == before)
	# Temporary battle transformation is an invalid mint target.
	var transformed: CreatureInstance = CreatureInstance.from_dict(c.to_dict())
	check(mode + " mint pilot transformed candidate", transformed != null)
	if transformed != null:
		transformed.battle_transform_original = {"original_species_id": "mew"}
		var transformed_before: Dictionary = transformed.to_dict()
		var transformed_result: Dictionary = MintPilot.apply(transformed, item, catalogs)
		check(mode + " mint pilot temporary battle transformation rejected",
			not bool(transformed_result.get("accepted", true))
			and String(transformed_result.get("reason", "")) == "temporary_battle_state"
			and transformed.to_dict() == transformed_before)
	var applied: Dictionary = svc.use_item(item, &"own")
	var expected_positive: bool = mode != "none"
	check(mode + " mint pilot actual acceptance", bool(applied.get("accepted", false)) == expected_positive)
	var now: CreatureInstance = owner.owned_creature(&"own")
	check(mode + " mint pilot identity and party/storage location",
		now != null and now.instance_id == &"own"
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	if now == null: return
	check(mode + " mint pilot immutable original candidate", c.to_dict() == creature_before)
	if expected_positive:
		check(mode + " mint pilot one unit spent and action identified",
			owner.inventory.quantity(item) == 1
			and String(applied.get("action", "")) == "effective_nature"
			and String(applied.get("effective_nature_id", "")) == String(target))
		var expected_creature: Dictionary = creature_before.duplicate(true)
		expected_creature["effective_nature_id"] = String(target)
		expected_creature["stats"] = desired
		check(mode + " mint pilot only effective nature and derived stats changed",
			now.to_dict() == expected_creature
			and now.nature_id == &"hardy" and now.effective_nature_id == target
			and now.stats.to_dict() == desired
			and now.current_hp == c.current_hp)
		check(mode + " mint pilot unchanged identity PS IV EV PP and other fields",
			now.species_id == c.species_id and now.experience == c.experience
			and now.friendship == c.friendship and now.ivs == c.ivs and now.evs == c.evs
			and now.ability_id == c.ability_id and now.moveset[0].to_dict() == c.moveset[0].to_dict()
			and now.moveset[1].to_dict() == c.moveset[1].to_dict()
			and now.stats.max_hp == c.stats.max_hp)
		var repeat_before: Dictionary = _owner_data(owner)
		var repeat: Dictionary = svc.use_item(item, &"own")
		check(mode + " mint pilot duplicate no-effect atomic rollback",
			not bool(repeat.get("accepted", true))
			and String(repeat.get("reason", "")) == "item_has_no_effect"
			and _owner_data(owner) == repeat_before)
	else:
		check(mode + " mint pilot no stock is a complete rollback",
			String(applied.get("reason", "")) == "item_not_owned"
			and owner.inventory.quantity(item) == 0 and _owner_data(owner) == before)
	var serialized: Dictionary = _owner_data(owner)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(serialized)
	check(mode + " mint pilot real SaveV2 decoder", decoded.ok)
	if decoded.ok:
		var loaded := PlayerCollection.new()
		loaded.party = decoded.party
		loaded.storage = decoded.storage
		loaded.inventory = decoded.inventory
		var persisted: CreatureInstance = loaded.owned_creature(&"own")
		check(mode + " mint pilot SaveV2 effective nature and bag",
			persisted != null and persisted.to_dict() == now.to_dict()
			and loaded.inventory.quantity(item) == owner.inventory.quantity(item)
			and loaded.location_of(&"own") == owner.location_of(&"own"))
	var legacy: LoadResult = SaveGameRepository.new().decode_snapshot(before)
	check(mode + " mint pilot legacy snapshot no nature field", legacy.ok)
	if legacy.ok:
		var unminted := PlayerCollection.new()
		unminted.party = legacy.party
		unminted.storage = legacy.storage
		var old: CreatureInstance = unminted.owned_creature(&"own")
		check(mode + " mint pilot legacy keeps original statistics",
			old != null and old.nature_id == &"hardy" and old.effective_nature_id == &""
			and old.stats.to_dict() == old_stats and old.current_hp == c.current_hp)
	if expected_positive:
		var invalid: Dictionary = serialized.duplicate(true)
		for entry: Dictionary in invalid.get("creatures", []):
			if String(entry.get("instance_id", "")) == "own":
				entry["effective_nature_id"] = "not_a_real_nature"
		var invalid_load: LoadResult = SaveGameRepository.new().decode_snapshot(invalid)
		check(mode + " mint pilot rejects corrupt effective nature SaveV2",
			not invalid_load.ok and String(invalid_load.reason) == "invalid_creature_id")

func _probe_gentle_to_lonely() -> void:
	var c: CreatureInstance = _pilot_creature()
	check("gentle to lonely real source", c != null)
	if c == null: return
	var owner := _pilot_owner(c, "active")
	check("gentle to lonely stock gentle", owner.inventory.add(&"gentle_mint", 1))
	check("gentle to lonely stock lonely", owner.inventory.add(&"lonely_mint", 1))
	var svc := Service.new()
	check("gentle to lonely live item service", svc.configure(owner, catalogs, func(): return true))
	var gentle: Dictionary = svc.use_item(&"gentle_mint", &"own")
	check("gentle to lonely previously certified gentle still applies",
		bool(gentle.get("accepted", false))
		and owner.owned_creature(&"own").effective_nature_id == &"gentle"
		and owner.inventory.quantity(&"gentle_mint") == 0)
	var old_hp: int = owner.owned_creature(&"own").current_hp
	var second: Dictionary = svc.use_item(&"lonely_mint", &"own")
	var now: CreatureInstance = owner.owned_creature(&"own")
	var wanted: Dictionary = StatCalculator.compute(
		catalogs.species(now.species_id).base_stat_block(), now.ivs, now.evs,
		&"lonely", now.level).to_dict()
	check("gentle to lonely second effective nature supersedes previous",
		bool(second.get("accepted", false))
		and now.nature_id == &"hardy" and now.effective_nature_id == &"lonely"
		and now.stats.to_dict() == wanted and now.current_hp == old_hp
		and owner.inventory.quantity(&"lonely_mint") == 0)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(_owner_data(owner))
	check("gentle to lonely SaveV2 second transition", decoded.ok)
	if decoded.ok:
		var restored := PlayerCollection.new()
		restored.party = decoded.party
		restored.storage = decoded.storage
		check("gentle to lonely after restart persisted",
			restored.owned_creature(&"own") != null
			and restored.owned_creature(&"own").effective_nature_id == &"lonely"
			and restored.owned_creature(&"own").nature_id == &"hardy")
