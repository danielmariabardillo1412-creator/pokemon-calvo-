extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 TANDA04 row02 Life Orb, real L3 trace, no production modifications.
# Compatible independent controls (active, none, reserve, immune).
const V4_LIFE_OUT := "res://.godot/parallel_items/w01_autorun_v4_life_orb"
var v4_life_passes: int = 0
var v4_life_evidence: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_life_orb")
	create_timer(650.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 Life Orb L3 bounded timeout")
			quit(2))

func _life_orb_cycle(mode: String) -> Dictionary:
	var err_start: int = errors.size()
	var collection := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["tackle", "close_combat", "shadow_ball", "reflect"])
	var bench := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.current_hp = 250
	check("Life Orb real initial owned team " + mode,
		collection.party.add_creature(own) and collection.party.add_creature(bench))
	check("Life Orb stock added to real inventory " + mode,
		collection.inventory.add(&"life_orb", 1))
	var service := ItemService.new()
	check("Life Orb real service configuration " + mode,
		service.configure(collection, catalogs, func(): return true)
		and service.holdable(&"life_orb"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		var equipped: Dictionary = service.equip(&"life_orb", target)
		check("Life Orb service equips sole owner " + mode,
			equipped.get("accepted", false)
			and collection.inventory.quantity(&"life_orb") == 0)
	var pre := _roundtrip(collection, "life_" + mode + "_pre")
	if not pre.valid:
		return {"valid": false, "mode": mode}
	collection = pre.owner
	var initial_hp: int = collection.owned_creature(&"own").current_hp
	var max_hp: int = collection.owned_creature(&"own").stats.max_hp
	var foe := _mon(&"gengar", 100, &"foe", ["amnesia"]) if mode == "immune" else _mon(&"mew", 100, &"foe", ["amnesia"])
	foe.current_hp = 120 if mode == "immune" else 170
	var session := FieldSession.new(catalogs, collection, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Life Orb actual field native session " + mode, opened)
	if not opened:
		await session.close()
		return {"valid": false, "mode": mode}
	var before_foe: int = session.battle_state().creature(&"foe").current_hp
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Life Orb native first tackle turn accepted " + mode,
		first.get("accepted", false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var after_foe: int = session.battle_state().creature(&"foe").current_hp
	var damage: int = before_foe - after_foe
	var recoil: int = initial_hp - live.current_hp
	var expected: int = maxi(1, max_hp / 10) if mode == "active" else 0
	check("Life Orb live recoil exactly one tenth on damaging hit only " + mode,
		recoil == expected)
	check("Life Orb immunity and legal damaging hit " + mode,
		damage == 0 if mode == "immune" else damage > 0)
	check("Life Orb real native item remains equipped after hit " + mode,
		live.held_item_id == (&"life_orb" if mode == "active" or mode == "immune" else &"")
		and not live.held_item_consumed
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"life_orb" if mode == "reserve" else &""))
	check("Life Orb item/HP not published to campaign before settlement " + mode,
		collection.owned_creature(&"own").current_hp == initial_hp
		and not collection.owned_creature(&"own").held_item_consumed)
	var steps: int = 0
	while session.phase() != "finished" and steps < 7:
		var command: String = "move 3" if mode == "immune" else "move 2"
		var outcome: Dictionary = await session.submit(command, session.revision)
		check("Life Orb real battle finisher accepted " + mode + "/" + str(steps),
			outcome.get("accepted", false))
		steps += 1
	check("Life Orb genuine wild victory, no forced completion " + mode,
		session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Life Orb actual victory settlement publishes state " + mode,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var post := _roundtrip(collection, "life_" + mode + "_post")
	if post.valid:
		var own_saved: CreatureInstance = post.owner.owned_creature(&"own")
		var reserve_saved: CreatureInstance = post.owner.owned_creature(&"reserve")
		check("Life Orb V2 preserves original property, no spent copies " + mode,
			post.owner.inventory.quantity(&"life_orb") == (1 if mode == "none" else 0)
			and own_saved.held_item_id == (&"life_orb" if mode == "active" or mode == "immune" else &"")
			and reserve_saved.held_item_id == (&"life_orb" if mode == "reserve" else &"")
			and not own_saved.held_item_consumed and not reserve_saved.held_item_consumed
			and own_saved.current_hp <= initial_hp)
	await session.close()
	return {"mode": mode, "valid": errors.size() == err_start and post.valid,
		"first_damage": damage, "first_recoil": recoil,
		"expected_recoil": expected, "savev2": post.valid}

func _run_life_orb() -> void:
	destination = V4_LIFE_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Life Orb canonical catalog ready", Variants.apply(catalogs))
	for mode in ["active", "none", "reserve", "immune"]:
		current_case = "V4_02_life_orb_" + mode
		var r: Dictionary = await _life_orb_cycle(mode)
		v4_life_evidence.append(r)
		if r.get("valid", false):
			v4_life_passes += 1
	check("Life Orb exact four L3 cases passed", v4_life_passes == 4)
	if v4_life_evidence.size() == 4:
		var a: Dictionary = v4_life_evidence[0]
		var n: Dictionary = v4_life_evidence[1]
		var reserve: Dictionary = v4_life_evidence[2]
		var immune: Dictionary = v4_life_evidence[3]
		check("Life Orb only active holder increases real physical damage",
			int(a.first_damage) > int(n.first_damage)
			and int(n.first_damage) == int(reserve.first_damage)
			and int(a.first_recoil) > 0
			and int(immune.first_damage) == 0 and int(immune.first_recoil) == 0)
	var report: Dictionary = {"worker": "W01", "tanda": "04", "row": "02",
		"id": "life_orb", "cases": v4_life_evidence, "checks": checks, "errors": errors,
		"limitations": ["Actual field session and SaveV2, no screen UI",
			"No production modification; pinned native Showdown effects",
			"Missing physical miss scenario: native immune and status are covered"]}
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Life Orb evidence file created", file != null)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	done = true
	if errors.is_empty() and v4_life_passes == 4:
		print("W01_V4_L3_ROW PASS row=02 id=life_orb variants=4 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=02 id=life_orb variants=", v4_life_passes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
