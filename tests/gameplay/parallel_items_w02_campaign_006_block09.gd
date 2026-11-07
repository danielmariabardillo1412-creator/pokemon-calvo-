extends "res://tests/gameplay/parallel_items_w02_campaign_006_block08.gd"

# Native W02 block09: existing ability adapter + own mint helper, live inventory
# ownership, consumptions, stamped ability transaction, stat changes and SaveV2.
const FIXTURE09 := "res://tests/fixtures/parallel_items/w02_campaign_006_block09.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run09")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("CAMP006 W02 block09 watchdog")
			quit(2)
	)

func _run09() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_006"
	DirAccess.make_dir_recursive_absolute(destination)
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE09))
	if not fixture is Dictionary:
		push_error("CAMP006 block09 fixture invalid")
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("block09 overlay", Variants.apply(catalogs))
	check("block09 identity", fixture.worker == "W02" and fixture.block == "09"
		and fixture.ids == ["ability_capsule", "ability_patch", "gentle_mint"])
	var positives: int = 0
	var negatives: int = 0
	for spec: Dictionary in fixture.cases:
		for mode: String in fixture.modes:
			current_case = String(spec.id) + "_" + mode
			var count_before: int = errors.size()
			_probe09(spec, mode)
			if errors.size() == count_before:
				if mode == "none": negatives += 1
				else: positives += 1
	var passed: bool = errors.is_empty() and positives == 6 and negatives == 3
	done = true
	print("CAMP006_W02_TRAIN09 ", "PASS" if passed else "FAIL",
		" block=09 positive=", positives, " negative=", negatives, " checks=", checks)
	quit(0 if passed else 1)

func _probe09(spec: Dictionary, mode: String) -> void:
	var item: StringName = StringName(spec.id)
	var is_mint: bool = String(spec.kind) == "mint"
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var factory_args: Dictionary = {"instance_id": &"own", "nature_id": &"hardy",
		"moves": ["growl", "protect"]}
	if not is_mint: factory_args["ability_id"] = StringName(spec.starting_ability)
	var c: CreatureInstance = CreatureFactory.create(
		catalogs.species(StringName(spec.species)), 50, catalogs,
		ProgressionRuleset.new(), rng, factory_args)
	check(mode + " training09 real creature", c != null)
	if c == null: return
	var owner := PlayerCollection.new()
	check(mode + " training09 own party", owner.party.add_creature(c))
	if mode == "reserve": check(mode + " training09 storage", owner.deposit(&"own"))
	if mode != "none": check(mode + " training09 inventory", owner.inventory.add(item, 2))
	var service := Service.new()
	check(mode + " training09 native service", service.configure(owner, catalogs, func(): return true))
	var original: Dictionary = c.to_dict()
	var before: Dictionary = _owner_data(owner)
	var wanted_stats: Dictionary = {}
	if is_mint:
		wanted_stats = StatCalculator.compute(
			catalogs.species(c.species_id).base_stat_block(),
			c.ivs, c.evs, StringName(spec.target_nature), c.level).to_dict()
		check(mode + " gentle_mint actual stat variation",
			wanted_stats != c.stats.to_dict()
			and int(wanted_stats.get("defense", 0)) < int(c.stats.to_dict().get("defense", 0))
			and int(wanted_stats.get("special_defense", 0)) > int(c.stats.to_dict().get("special_defense", 0)))
		var illegal: Dictionary = service.use_item(item, &"own", 0)
		check(mode + " gentle_mint illegal slot rollback",
			not bool(illegal.get("accepted", true))
			and String(illegal.get("reason", "")) == "unexpected_mint_target"
			and _owner_data(owner) == before)
	var stamp: String = ""
	var amount_before: int = owner.inventory.quantity(item)
	if not is_mint and mode != "none":
		var preview: Dictionary = service.ability_preview(item, &"own")
		check(mode + " ability preview actual slot target",
			bool(preview.get("accepted", false))
			and String(preview.get("ability_id", "")) == String(spec.target_ability))
		stamp = String(preview.get("stamp", ""))
		check(mode + " ability preview produces stamp", not stamp.is_empty())
		# A change in the inventory invalidates a stale ability preview.
		check(mode + " ability touch stock", owner.inventory.add(item, 1))
		var changed: Dictionary = _owner_data(owner)
		var stale: Dictionary = service.use_item(item, &"own", -1, &"", stamp)
		check(mode + " ability stale stamp atomic rejection",
			not bool(stale.get("accepted", true))
			and String(stale.get("reason", "")) == "ability_state_changed"
			and _owner_data(owner) == changed)
		var fresh: Dictionary = service.ability_preview(item, &"own")
		check(mode + " ability fresh preview after stock change", bool(fresh.get("accepted", false))
			and String(fresh.get("ability_id", "")) == String(spec.target_ability))
		stamp = String(fresh.get("stamp", ""))
	var result: Dictionary = service.use_item(item, &"own", -1, &"", stamp)
	var positive: bool = mode != "none"
	check(mode + " training09 acceptance", bool(result.get("accepted", false)) == positive)
	var now: CreatureInstance = owner.owned_creature(&"own")
	check(mode + " training09 ownership and identity", now != null and now.instance_id == &"own"
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	if now == null: return
	check(mode + " training09 initial object unchanged", c.to_dict() == original)
	if not positive:
		check(mode + " training09 no stock rollback", result.get("reason", "") == "item_not_owned"
			and _owner_data(owner) == before and owner.inventory.quantity(item) == 0)
		return
	check(mode + " training09 exactly one consumed",
		owner.inventory.quantity(item) == amount_before + (0 if is_mint else 1) - 1)
	if is_mint:
		check(mode + " gentle_mint replaces effective not original nature",
			now.nature_id == &"hardy" and now.effective_nature_id == &"gentle"
			and now.stats.to_dict() == wanted_stats
			and String(result.get("action", "")) == "effective_nature")
		check(mode + " gentle_mint preserves HP identity and other stats",
			now.stats.max_hp == c.stats.max_hp and now.current_hp == c.current_hp
			and now.ability_id == c.ability_id and now.ivs == c.ivs and now.evs == c.evs
			and now.friendship == c.friendship)
		var after: Dictionary = _owner_data(owner)
		var repeated: Dictionary = service.use_item(item, &"own")
		check(mode + " gentle_mint repeat no-effect atomic",
			not bool(repeated.get("accepted", true)) and repeated.get("reason", "") == "item_has_no_effect"
			and _owner_data(owner) == after)
	else:
		var expected: Dictionary = original.duplicate(true)
		expected["ability_id"] = String(spec.target_ability)
		check(mode + " real ability only expected field changed",
			now.to_dict() == expected
			and String(result.get("action", "")) == "ability_change"
			and String(result.get("ability_id", "")) == String(spec.target_ability))
		var wrong_slot_before: Dictionary = _owner_data(owner)
		var wrong_slot: Dictionary = service.use_item(item, &"own", 0)
		check(mode + " ability wrong slot atomic",
			not bool(wrong_slot.get("accepted", true))
			and _owner_data(owner) == wrong_slot_before)
	var loaded: LoadResult = SaveGameRepository.new().decode_snapshot(_owner_data(owner))
	check(mode + " training09 SaveV2 decode", loaded.ok)
	if loaded.ok:
		var restored := PlayerCollection.new()
		restored.party = loaded.party
		restored.storage = loaded.storage
		restored.inventory = loaded.inventory
		var saved: CreatureInstance = restored.owned_creature(&"own")
		check(mode + " training09 SaveV2 preserves effect and bag",
			saved != null and saved.to_dict() == now.to_dict()
			and restored.location_of(&"own") == owner.location_of(&"own")
			and restored.inventory.quantity(item) == owner.inventory.quantity(item))
	if is_mint:
		var legacy: LoadResult = SaveGameRepository.new().decode_snapshot(before)
		check(mode + " gentle_mint old SaveV2 still loads", legacy.ok)
