extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 T04/07 genuine Eviolite Pidgeotto vs Pidgeot with real field inventory.
const EVI_OUT := "res://.godot/parallel_items/w01_v4_eviolite"
var evi_cases: Array = []
var evi_passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_eviolite")
	create_timer(1000.0).timeout.connect(func():
		if not done:
			push_error("Eviolite L3 watchdog")
			quit(2))

func _eviolite_case(species: StringName, attack: String, mode: String) -> Dictionary:
	var before_errors: int = errors.size()
	var owner := PlayerCollection.new()
	var own := _mon(species, 100, &"own", ["growl", "aerial_ace"])
	var reserve := _mon(&"mew", 100, &"reserve", ["reflect"])
	check("Eviolite two real owned creatures", owner.party.add_creature(own)
		and owner.party.add_creature(reserve))
	check("Eviolite bag has real one physical unit", owner.inventory.add(&"eviolite", 1))
	var service := ItemService.new()
	check("Eviolite real field service uses selected policy",
		service.configure(owner, catalogs, func(): return true)
		and service.holdable(&"eviolite"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Eviolite real equip without duplication",
			service.equip(&"eviolite", target).get("accepted", false)
			and owner.inventory.quantity(&"eviolite") == 0)
	var pre := _roundtrip(owner, "eviolite_" + String(species) + "_" + attack + "_" + mode + "_pre")
	if not pre.valid: return {"valid": false}
	owner = pre.owner
	var foe := _mon(&"mew", 70, &"foe", [attack])
	foe.current_hp = 80
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Eviolite live battle begins", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var hp_before: int = session.battle_state().creature(&"own").current_hp
	var turn: Dictionary = await session.submit("move 1", session.revision)
	check("Eviolite actual native opponent attack processed", turn.get("accepted", false))
	var damage: int = hp_before - session.battle_state().creature(&"own").current_hp
	check("Eviolite actual incoming damage", damage > 0)
	var active: CreatureInstance = session.battle_state().creature(&"own")
	check("Eviolite live held ownership unchanged",
		active.held_item_id == (&"eviolite" if mode == "active" else &"")
		and not active.held_item_consumed
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"eviolite" if mode == "reserve" else &""))
	var attempts: int = 0
	while session.phase() != "finished" and attempts < 8:
		var result: Dictionary = await session.submit("move 2", session.revision)
		check("Eviolite real field finisher", result.get("accepted", false))
		attempts += 1
	check("Eviolite real natural field battle terminal", session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Eviolite native settlement complete",
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var post := _roundtrip(owner, "eviolite_" + String(species) + "_" + attack + "_" + mode + "_post")
	if post.valid:
		check("Eviolite persists exact owner and inventory after SaveV2",
			post.owner.inventory.quantity(&"eviolite") == (1 if mode == "none" else 0)
			and post.owner.owned_creature(&"own").held_item_id ==
				(&"eviolite" if mode == "active" else &"")
			and post.owner.owned_creature(&"reserve").held_item_id ==
				(&"eviolite" if mode == "reserve" else &"")
			and not post.owner.owned_creature(&"own").held_item_consumed
			and not post.owner.owned_creature(&"reserve").held_item_consumed)
	await session.close()
	return {"valid": errors.size() == before_errors and post.valid,
		"species": String(species), "move": attack, "mode": mode, "damage": damage}

func _run_eviolite() -> void:
	destination = EVI_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Eviolite canonical species", Variants.apply(catalogs))
	for attack in ["tackle", "psychic"]:
		var pre: Array = []
		for mode in ["active", "none", "reserve"]:
			current_case = "T04_07_pidgeotto_" + attack + "_" + mode
			var record: Dictionary = await _eviolite_case(&"pidgeotto", attack, mode)
			evi_cases.append(record)
			pre.append(record)
			if record.get("valid", false): evi_passed += 1
		check("Eviolite Pidgeotto defense and SpD positive",
			int(pre[0].damage) < int(pre[1].damage)
			and int(pre[1].damage) == int(pre[2].damage))
		var final: Array = []
		for mode in ["active", "none"]:
			current_case = "T04_07_pidgeot_" + attack + "_" + mode
			var result: Dictionary = await _eviolite_case(&"pidgeot", attack, mode)
			evi_cases.append(result)
			final.append(result)
			if result.get("valid", false): evi_passed += 1
		check("Eviolite fully evolved Pidgeot no defensive boost",
			int(final[0].damage) == int(final[1].damage))
	check("Eviolite ten genuine L3 sessions", evi_passed == 10)
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Eviolite native evidence file", file != null)
	if file != null:
		file.store_string(JSON.stringify({"row":"07","worker":"W01",
			"sessions":evi_cases,"checks":checks,"errors":errors},"  "))
		file.close()
	done = true
	if errors.is_empty() and evi_passed == 10:
		print("W01_V4_L3_ROW PASS row=07 id=eviolite modes=10 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=07 id=eviolite modes=", evi_passed,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
