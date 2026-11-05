extends "res://tests/gameplay/parallel_items_w02_campaign_006.gd"

# W02 block06: tests live post-battle EV awards; never mocks BattleEvRewards.
const BattleEvRewards = preload("res://modules/creatures/progression/battle_ev_rewards.gd")
const EV06 := "res://tests/fixtures/parallel_items/w02_campaign_006_block06.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run_ev06")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("CAMP006 W02 EV06 watchdog")
			quit(2)
	)

func _run_ev06() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_006"
	DirAccess.make_dir_recursive_absolute(destination)
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(EV06))
	if not fixture is Dictionary:
		push_error("EV06 invalid fixture")
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("EV06 overlay", Variants.apply(catalogs))
	check("EV06 exact worker and items", fixture.worker == "W02" and fixture.block == "06"
		and fixture.ids == ["power_anklet", "power_band", "power_belt"])
	check("EV06 real foe has EV yield", catalogs.species(&"magikarp") != null)
	var positive := 0
	for spec: Dictionary in fixture.cases:
		for mode: String in fixture.modes:
			current_case = String(spec.id) + "_" + mode
			var prior: int = errors.size()
			_probe_ev06(spec, mode)
			if errors.size() == prior: positive += 1
	var success: bool = errors.is_empty() and positive == 9
	done = true
	print("CAMP006_W02_EV06 ", "PASS" if success else "FAIL",
		" block=06 positive=", positive, " checks=", checks)
	quit(0 if success else 1)

func _probe_ev06(spec: Dictionary, mode: String) -> void:
	var id: StringName = StringName(spec.id)
	var stat: String = String(spec.stat)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var c: CreatureInstance = CreatureFactory.create(
		catalogs.species(&"mew"), 50, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": ["growl"]})
	check(mode + " EV06 creature", c != null)
	if c == null: return
	var owner := PlayerCollection.new()
	check(mode + " EV06 party", owner.party.add_creature(c))
	if mode == "reserve": check(mode + " EV06 storage", owner.deposit(&"own"))
	if mode != "none": check(mode + " EV06 inventory", owner.inventory.add(id, 2))
	var svc := Service.new()
	check(mode + " EV06 FieldItemService", svc.configure(owner, catalogs, func(): return true))
	var start: Dictionary = _owner_data(owner)
	var equip: Dictionary = svc.equip(id, &"own")
	var active: bool = mode != "none"
	check(mode + " EV06 equip", bool(equip.get("accepted", false)) == active)
	if not active:
		check(mode + " EV06 no-stock rollback",
			String(equip.get("reason", "")) == "item_not_owned" and _owner_data(owner) == start)
		return
	check(mode + " EV06 exactly one spent", owner.inventory.quantity(id) == 1)
	var loaded: LoadResult = SaveGameRepository.new().decode_snapshot(_owner_data(owner))
	check(mode + " EV06 SaveV2 equipped", loaded.ok)
	if not loaded.ok: return
	var restored := PlayerCollection.new()
	restored.party = loaded.party
	restored.storage = loaded.storage
	restored.inventory = loaded.inventory
	var now: CreatureInstance = restored.owned_creature(&"own")
	check(mode + " EV06 identity/owner/item after load", now != null
		and restored.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY")
		and now.held_item_id == id)
	if now == null: return
	var initial_evs: Dictionary = now.evs.duplicate(true)
	var base_yield: Dictionary = catalogs.species(&"magikarp").ev_yield
	var defeated: Array = [{"species_id": "magikarp", "base_experience": 10, "level": 5}]
	var old_xp: int = now.experience
	var starting: Dictionary = {String(now.instance_id): String(id)}
	var outcome := BattleOutcome.new()
	outcome.winner_side_id = &"side_a"
	outcome.defeated = defeated
	var events: Array = ProgressionSystem.reconcile_battle_result(
		[now], outcome, catalogs, ProgressionRuleset.new(), starting)
	var expected: int = int(base_yield.get(stat, 0)) + 8
	check(mode + " EV06 actual post-battle bonus +8 in " + stat,
		int(now.evs.get(stat, -1)) == int(initial_evs.get(stat, 0)) + expected
		and not events.is_empty() and now.experience > old_xp)
	for key: String in ProgressionRuleset.STAT_KEYS:
		if key != stat:
			check(mode + " EV06 unrelated stat unchanged except native yield " + key,
				int(now.evs.get(key, -1)) == int(initial_evs.get(key, 0)) + int(base_yield.get(key, 0)))
	check(mode + " EV06 equipped item not consumed", now.held_item_id == id
		and not now.held_item_consumed and restored.inventory.quantity(id) == 1)
	var after: LoadResult = SaveGameRepository.new().decode_snapshot(_owner_data(restored))
	check(mode + " EV06 SaveV2 preserves EV", after.ok)
	if after.ok:
		var persisted := PlayerCollection.new()
		persisted.party = after.party
		persisted.storage = after.storage
		check(mode + " EV06 persisted stats and EV/item",
			persisted.owned_creature(&"own") != null
			and persisted.owned_creature(&"own").evs == now.evs
			and persisted.owned_creature(&"own").held_item_id == id)
	# Unit-test both caps on a detached real CreatureInstance, not an approximation.
	var capped: CreatureInstance = CreatureInstance.from_dict(now.to_dict())
	check(mode + " EV06 cap copy", capped != null)
	if capped == null: return
	for key: String in ProgressionRuleset.STAT_KEYS: capped.evs[key] = 0
	capped.evs[stat] = 250
	var filler: String = "hp" if stat != "hp" else "attack"
	capped.evs[filler] = 252
	var filler2: String = "attack" if stat != "attack" and filler != "attack" else "special_attack"
	capped.evs[filler2] = 8
	capped.recalculate_stats(catalogs.species(capped.species_id), ProgressionRuleset.new())
	var before_caps: Dictionary = capped.evs.duplicate(true)
	var cap_result: Dictionary = BattleEvRewards.award(
		capped, defeated, catalogs, ProgressionRuleset.new(), starting)
	check(mode + " EV06 cap510 rejects all grants", capped.evs == before_caps
		and cap_result.is_empty())
	capped.evs[filler2] = 6
	var near: int = int(capped.evs[stat])
	var near_result: Dictionary = BattleEvRewards.award(
		capped, defeated, catalogs, ProgressionRuleset.new(), starting)
	check(mode + " EV06 cap252 and cap510 clamp bonus to two", 
		int(capped.evs[stat]) == near + 2 and int(near_result.get(stat, -1)) == 2)
