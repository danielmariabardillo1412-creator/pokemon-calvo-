extends "res://tests/gameplay/parallel_items_w02_campaign_006_block07.gd"

const Ev08 = preload("res://modules/creatures/progression/battle_ev_rewards.gd")
const Friend08 = preload("res://modules/inventory/field_friendship_effects.gd")
const SPEC08 := "res://tests/fixtures/parallel_items/w02_campaign_006_block08.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run08")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("W02 block08 watchdog")
			quit(2)
	)

func _make08() -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var c: CreatureInstance = CreatureFactory.create(
		catalogs.species(&"mew"), 50, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": ["growl"]})
	if c != null: c.friendship = 99
	return c

func _own08(c: CreatureInstance, mode: String) -> PlayerCollection:
	var p := PlayerCollection.new()
	check(mode + " ownership PARTY", p.party.add_creature(c))
	if mode == "reserve": check(mode + " ownership STORAGE", p.deposit(&"own"))
	return p

func _reload08(p: PlayerCollection, label: String) -> PlayerCollection:
	var r: LoadResult = SaveGameRepository.new().decode_snapshot(_owner_data(p))
	check(label + " SaveV2 reload", r.ok)
	if not r.ok: return null
	var out := PlayerCollection.new()
	out.party = r.party
	out.storage = r.storage
	out.inventory = r.inventory
	return out

func _foe08() -> BattleOutcome:
	var o := BattleOutcome.new()
	o.winner_side_id = &"side_a"
	o.defeated = [{"species_id": "magikarp", "base_experience": 10, "level": 5}]
	return o

func _run08() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_006"
	DirAccess.make_dir_recursive_absolute(destination)
	var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEC08))
	if not f is Dictionary:
		push_error("W02 block08 missing fixture")
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("08 real overlay", Variants.apply(catalogs))
	check("08 identity", f.worker == "W02" and f.block == "08"
		and f.ids == ["macho_brace", "soothe_bell"])
	check("08 Magikarp yields one speed EV", int(catalogs.species(&"magikarp").ev_yield.get("speed", 0)) == 1)
	var positive := 0
	var negative := 0
	for mode: String in f.modes:
		for spec: Dictionary in f.cases:
			current_case = String(spec.id) + "_" + mode
			var start_error: int = errors.size()
			if spec.id == "macho_brace": _macho08(spec, mode)
			else: _soothe08(spec, mode)
			if errors.size() == start_error:
				if mode == "none": negative += 1
				else: positive += 1
	var ok: bool = errors.is_empty() and positive == 4 and negative == 2
	done = true
	print("CAMP006_W02_HELD08 ", "PASS" if ok else "FAIL",
		" block=08 positive=", positive, " negative=", negative, " checks=", checks)
	quit(0 if ok else 1)

func _macho08(spec: Dictionary, mode: String) -> void:
	var c: CreatureInstance = _make08()
	check(mode + " macho creature", c != null)
	if c == null: return
	var p := _own08(c, mode)
	if mode != "none": check(mode + " macho stock", p.inventory.add(&"macho_brace", 2))
	var svc := Service.new()
	check(mode + " macho service", svc.configure(p, catalogs, func(): return true))
	var before: Dictionary = _owner_data(p)
	var equip: Dictionary = svc.equip(&"macho_brace", &"own")
	check(mode + " macho equip", bool(equip.get("accepted", false)) == (mode != "none"))
	if mode == "none":
		check(mode + " macho no stock rollback", equip.get("reason", "") == "item_not_owned"
			and _owner_data(p) == before)
		return
	check(mode + " macho spent one on equip", p.inventory.quantity(&"macho_brace") == 1)
	var loaded := _reload08(p, mode + " macho equip")
	if loaded == null: return
	var mon: CreatureInstance = loaded.owned_creature(&"own")
	check(mode + " macho identity", mon != null and mon.held_item_id == &"macho_brace"
		and loaded.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	if mon == null: return
	var base: CreatureInstance = CreatureInstance.from_dict(mon.to_dict())
	base.held_item_id = &""
	var mismatch: CreatureInstance = CreatureInstance.from_dict(mon.to_dict())
	var start_ev: int = int(mon.evs.get("speed", 0))
	var start_xp: int = mon.experience
	var snapshot: Dictionary = {String(mon.instance_id): String(mon.held_item_id)}
	var events: Array = ProgressionSystem.reconcile_battle_result(
		[mon], _foe08(), catalogs, ProgressionRuleset.new(), snapshot)
	var base_events: Array = ProgressionSystem.reconcile_battle_result(
		[base], _foe08(), catalogs, ProgressionRuleset.new())
	check(mode + " macho EV two vs one from real KO",
		int(mon.evs.get("speed", 0)) - start_ev == int(spec.expected_yield)
		and int(base.evs.get("speed", 0)) - start_ev == int(spec.base_yield))
	check(mode + " macho no XP distortion",
		not events.is_empty() and not base_events.is_empty()
		and mon.experience > start_xp and mon.experience == base.experience)
	check(mode + " macho item not consumed", mon.held_item_id == &"macho_brace"
		and not mon.held_item_consumed and loaded.inventory.quantity(&"macho_brace") == 1)
	var wrong: Dictionary = Ev08.award(mismatch, _foe08().defeated,
		catalogs, ProgressionRuleset.new(), {String(mismatch.instance_id): "wrong_held"})
	check(mode + " macho changed start snapshot cancels multiplier",
		int(wrong.get("speed", 0)) == 1)
	var cap: CreatureInstance = CreatureInstance.from_dict(mon.to_dict())
	for stat: String in ProgressionRuleset.STAT_KEYS: cap.evs[stat] = 0
	cap.evs["speed"] = 251
	var g: Dictionary = Ev08.award(cap, _foe08().defeated, catalogs, ProgressionRuleset.new(), snapshot)
	check(mode + " macho cap252", int(cap.evs["speed"]) == 252 and int(g.get("speed", 0)) == 1)
	cap.evs["speed"] = 250
	cap.evs["hp"] = 252
	cap.evs["attack"] = 8
	var full: Dictionary = cap.evs.duplicate(true)
	var gain_full: Dictionary = Ev08.award(cap, _foe08().defeated, catalogs, ProgressionRuleset.new(), snapshot)
	check(mode + " macho cap510", cap.evs == full and gain_full.is_empty())
	var saved := _reload08(loaded, mode + " macho after")
	if saved != null:
		var actual: CreatureInstance = saved.owned_creature(&"own")
		check(mode + " macho SaveV2 preserves EV/held",
			actual != null and actual.evs == mon.evs and actual.held_item_id == &"macho_brace"
			and saved.inventory.quantity(&"macho_brace") == 1)

func _soothe08(spec: Dictionary, mode: String) -> void:
	var c: CreatureInstance = _make08()
	check(mode + " soothe creature", c != null)
	if c == null: return
	var p := _own08(c, mode)
	check(mode + " soothe protein stock", p.inventory.add(&"protein", 2))
	if mode != "none": check(mode + " soothe bell stock", p.inventory.add(&"soothe_bell", 2))
	var svc := Service.new()
	check(mode + " soothe service", svc.configure(p, catalogs, func(): return true))
	var before: Dictionary = _owner_data(p)
	var equip: Dictionary = svc.equip(&"soothe_bell", &"own")
	check(mode + " soothe equip", bool(equip.get("accepted", false)) == (mode != "none"))
	if mode == "none":
		check(mode + " soothe no stock rollback",
			equip.get("reason", "") == "item_not_owned" and _owner_data(p) == before)
	var loaded := _reload08(p, mode + " soothe equipped")
	if loaded == null: return
	var mon: CreatureInstance = loaded.owned_creature(&"own")
	check(mode + " soothe ownership",
		mon != null and loaded.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	if mon == null: return
	var bare: CreatureInstance = CreatureInstance.from_dict(mon.to_dict())
	bare.held_item_id = &""
	bare.held_item_consumed = false
	var baseline := _own08(bare, mode)
	check(mode + " soothe baseline protein stock", baseline.inventory.add(&"protein", 2))
	var plain := Service.new()
	check(mode + " soothe baseline service", plain.configure(baseline, catalogs, func(): return true))
	var plain_result: Dictionary = plain.use_item(&"protein", &"own")
	check(mode + " soothe baseline +5 through real field",
		bool(plain_result.get("accepted", false))
		and baseline.owned_creature(&"own").friendship == 104)
	var active := Service.new()
	check(mode + " soothe rebound service", active.configure(loaded, catalogs, func(): return true))
	var before_direct: Dictionary = _owner_data(loaded)
	var denied: Dictionary = active.use_item(&"soothe_bell", &"own")
	check(mode + " soothe passive direct use rejected atomically",
		not bool(denied.get("accepted", true)) and _owner_data(loaded) == before_direct)
	var applied_result: Dictionary = active.use_item(&"protein", &"own")
	var after: CreatureInstance = loaded.owned_creature(&"own")
	var gain: int = int(spec.held_gain) if mode != "none" else int(spec.base_gain)
	check(mode + " soothe protein + friendship native",
		bool(applied_result.get("accepted", false))
		and after != null and after.friendship == 99 + gain)
	if after == null: return
	check(mode + " soothe EV10, protein consumed, bell retained",
		int(after.evs.get("attack", 0)) == 10
		and loaded.inventory.quantity(&"protein") == 1
		and loaded.inventory.quantity(&"soothe_bell") == (1 if mode != "none" else 0)
		and after.held_item_id == (&"soothe_bell" if mode != "none" else &"")
		and not after.held_item_consumed)
	var reloaded := _reload08(loaded, mode + " soothe after protein")
	if reloaded != null:
		var saved: CreatureInstance = reloaded.owned_creature(&"own")
		check(mode + " soothe SaveV2 friendship/EV/held",
			saved != null and saved.friendship == after.friendship
			and saved.evs == after.evs and saved.held_item_id == after.held_item_id)
	if mode != "none":
		var cap: CreatureInstance = CreatureInstance.from_dict(after.to_dict())
		cap.friendship = 254
		var delta: int = Friend08.increase(cap, [5, 3, 2])
		check(mode + " soothe cap255", delta == 1 and cap.friendship == 255)
		var consumed: CreatureInstance = CreatureInstance.from_dict(after.to_dict())
		consumed.friendship = 99
		consumed.held_item_consumed = true
		var base_gain: int = Friend08.increase(consumed, [5, 3, 2])
		check(mode + " soothe consumed flag bypass", base_gain == 5 and consumed.friendship == 104)
