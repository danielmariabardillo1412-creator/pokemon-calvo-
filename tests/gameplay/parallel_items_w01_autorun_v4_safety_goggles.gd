extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01/08: real field inventory, true Showdown powder/weather effect, terminal settlement and SaveV2.
const GOG_OUT := "res://.godot/parallel_items/w01_v4_safety_goggles"
var goggles_cases: Array = []
var goggles_passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_goggles")
	create_timer(1000.0).timeout.connect(func():
		if not done:
			push_error("W01 Safety Goggles L3 time limit")
			quit(2))

func _goggles_probe(effect: String, mode: String) -> Dictionary:
	var err_before: int = errors.size()
	var player := PlayerCollection.new()
	var own_mon := _mon(&"mew", 100, &"own", ["reflect", "psychic"])
	var bench := _mon(&"mew", 100, &"reserve", ["psychic"])
	check("Safety Goggles independent real party " + effect + "/" + mode,
		player.party.add_creature(own_mon) and player.party.add_creature(bench))
	check("Safety Goggles physical bag item " + effect + "/" + mode,
		player.inventory.add(&"safety_goggles", 1))
	var service := ItemService.new()
	check("Safety Goggles real field service holdability",
		service.configure(player, catalogs, func(): return true)
		and service.holdable(&"safety_goggles"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Safety Goggles equip removes exact one item from bag",
			service.equip(&"safety_goggles", target).get("accepted", false)
			and player.inventory.quantity(&"safety_goggles") == 0)
	var pre := _roundtrip(player, "goggles_" + effect + "_" + mode + "_pre")
	if not pre.valid: return {"valid": false}
	player = pre.owner
	var foe_species: StringName = &"breloom" if effect == "powder" else &"mew"
	var foe_move: String = "spore" if effect == "powder" else "sandstorm" if effect == "weather" else "amnesia"
	var foe := _mon(foe_species, 100 if effect == "powder" else 20, &"foe", [foe_move])
	foe.current_hp = 65
	var session := FieldSession.new(catalogs, player, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	if not opened:
		print("W01_GOGGLES_OPEN_DIAG effect=", effect, " mode=", mode, " error=", session.last_error)
	check("Safety Goggles genuine field session opens", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var before_hp: int = session.battle_state().creature(&"own").current_hp
	var initial_status: String = String(session.battle_state().creature(&"own").status_state.persistent_id)
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Safety Goggles real status/weather turn accepted", first.get("accepted", false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var delta: int = live.current_hp - before_hp
	var status: String = String(live.status_state.persistent_id)
	check("Safety Goggles powder immunity vs actual Spore",
		(status == ("sleep" if mode != "active" else "") and initial_status == "")
		if effect == "powder" else status == initial_status)
	check("Safety Goggles sandstorm residual only for unprotected active",
		(delta == 0 if mode == "active" else delta < 0) if effect == "weather" else delta == 0)
	check("Safety Goggles live item still belongs to original owner",
		live.held_item_id == (&"safety_goggles" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"safety_goggles" if mode == "reserve" else &"")
		and not live.held_item_consumed)
	var used_bench: bool = false
	if effect == "powder" and mode != "active":
		var swapped: Dictionary = await session.submit(_switch_choice(session, &"reserve"), session.revision)
		check("Goggles genuine bench swap after sleep", swapped.get("accepted", false))
		used_bench = swapped.get("accepted", false)
	var turns: int = 0
	while session.phase() != "finished" and turns < 18:
		var move_index: String = "move 1" if used_bench else "move 2"
		var result: Dictionary = await session.submit(move_index, session.revision)
		check("Goggles real victory attempt " + effect + "/" + mode + "/" + str(turns),
			result.get("accepted", false))
		turns += 1
	check("Goggles actual wild encounter ends naturally", session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Goggles authoritative battle settlement",
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var post := _roundtrip(player, "goggles_" + effect + "_" + mode + "_post")
	if post.valid:
		check("Safety Goggles no phantom stock, correct SaveV2 owner",
			post.owner.inventory.quantity(&"safety_goggles") == (1 if mode == "none" else 0)
			and post.owner.owned_creature(&"own").held_item_id ==
				(&"safety_goggles" if mode == "active" else &"")
			and post.owner.owned_creature(&"reserve").held_item_id ==
				(&"safety_goggles" if mode == "reserve" else &"")
			and not post.owner.owned_creature(&"own").held_item_consumed
			and not post.owner.owned_creature(&"reserve").held_item_consumed)
	await session.close()
	return {"valid": errors.size() == err_before and post.valid,
		"effect": effect, "mode": mode, "delta": delta, "status": status, "turns": turns}

func _run_goggles() -> void:
	destination = GOG_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Safety Goggles game catalog", Variants.apply(catalogs))
	for effect in ["powder", "weather", "neutral"]:
		for mode in (["active", "none"] if effect == "neutral" else ["active", "none", "reserve"]):
			current_case = "T04_08_goggles_" + effect + "_" + mode
			var record: Dictionary = await _goggles_probe(effect, mode)
			goggles_cases.append(record)
			if record.get("valid", false): goggles_passed += 1
	check("Safety Goggles 8 full real field sessions", goggles_passed == 8)
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Safety Goggles final report output writable", file != null)
	if file != null:
		file.store_string(JSON.stringify({"row":"08", "worker":"W01",
			"cases":goggles_cases,"checks":checks,"errors":errors},"  "))
		file.close()
	done = true
	if errors.is_empty() and goggles_passed == 8:
		print("W01_V4_L3_ROW PASS row=08 id=safety_goggles modes=8 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=08 id=safety_goggles modes=", goggles_passed,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
