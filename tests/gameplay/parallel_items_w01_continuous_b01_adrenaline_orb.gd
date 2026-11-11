extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 CONTINUOUS_V2/B01-03 Adrenaline Orb genuine Intimidate -> Speed -> consume,
# FieldItemService -> native battle -> settlement -> SaveV2.
const ORB_OUT := "res://.godot/parallel_items/w01_continuous_b01_adrenaline_orb"
var orb_rows: Array = []
var orb_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_orb")
	create_timer(850.0).timeout.connect(func():
		if not done:
			push_error("Adrenaline Orb L3 watchdog")
			quit(2))

func _orb_case(mode: String) -> Dictionary:
	var old_errors: int = errors.size()
	var neutral: bool = mode == "neutral"
	var own_held: bool = mode == "active" or neutral
	var consume: bool = mode == "active"
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["reflect", "thunder_shock"])
	var reserve := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.ability_id = &"synchronize"
	check("Adrenaline Orb real owner party",
		owner.party.add_creature(own) and owner.party.add_creature(reserve))
	check("Adrenaline Orb real item stock", owner.inventory.add(&"adrenaline_orb", 1))
	var service := ItemService.new()
	check("Adrenaline Orb selected holdability",
		service.configure(owner, catalogs, func(): return true)
		and service.holdable(&"adrenaline_orb"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Adrenaline Orb real bag equip",
			service.equip(&"adrenaline_orb", target).get("accepted", false)
			and owner.inventory.quantity(&"adrenaline_orb") == 0)
	var pre := _roundtrip(owner, "b01_orb_" + mode + "_pre")
	if not pre.valid: return {"valid": false}
	owner = pre.owner
	var foe := _mon(&"mew" if neutral else &"gyarados", 100, &"foe", ["tackle"])
	foe.ability_id = &"synchronize" if neutral else &"intimidate"
	foe.current_hp = 65
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Adrenaline Orb genuine wild session starts", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Adrenaline Orb native turn accepted", first.get("accepted", false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	check("Adrenaline Orb actual Intimidate lowering Attack",
		live.stat_stages.get_stage(&"attack") == (0 if neutral else -1))
	check("Adrenaline Orb native Speed boost from Intimidate only",
		live.stat_stages.get_stage(&"speed") == (1 if consume else 0))
	check("Adrenaline Orb consumed once by correct holder",
		live.held_item_id == (&"adrenaline_orb" if own_held else &"")
		and live.held_item_consumed == consume
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"adrenaline_orb" if mode == "reserve" else &"")
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("Adrenaline Orb campaign unaffected before settlement",
		not owner.owned_creature(&"own").held_item_consumed
		and owner.owned_creature(&"own").stat_stages.get_stage(&"speed") == 0)
	var steps: int = 0
	while session.phase() != "finished" and steps < 6:
		var result: Dictionary = await session.submit("move 2", session.revision)
		check("Adrenaline Orb natural victory attacking turn", result.get("accepted", false))
		steps += 1
	check("Adrenaline Orb actual victory", session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Adrenaline Orb battle settlement", settled.get("accepted", false)
		and session.completion_reason == "VICTORY")
	var saved := _roundtrip(owner, "b01_orb_" + mode + "_post")
	if saved.valid:
		var p: CreatureInstance = saved.owner.owned_creature(&"own")
		check("Adrenaline Orb SaveV2 spent state and temporary boosts cleared",
			saved.owner.inventory.quantity(&"adrenaline_orb") == (1 if mode == "none" else 0)
			and p.held_item_id == (&"adrenaline_orb" if own_held else &"")
			and p.held_item_consumed == consume
			and p.stat_stages.get_stage(&"speed") == 0
			and saved.owner.owned_creature(&"reserve").held_item_id ==
				(&"adrenaline_orb" if mode == "reserve" else &""))
	await session.close()
	return {"mode":mode,"valid":errors.size() == old_errors and saved.valid,
		"consumed":consume,"boost":1 if consume else 0}

func _run_orb() -> void:
	destination = ORB_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Adrenaline Orb canonical catalog", Variants.apply(catalogs))
	for mode in ["active", "none", "reserve", "neutral"]:
		current_case = "W01_B01_03_orb_" + mode
		var row: Dictionary = await _orb_case(mode)
		orb_rows.append(row)
		if row.get("valid", false): orb_passes += 1
	check("Adrenaline Orb four true L3 variants", orb_passes == 4)
	var f: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Adrenaline Orb evidence output", f != null)
	if f != null:
		f.store_string(JSON.stringify({"block":"B01","row":"03",
			"results":orb_rows,"checks":checks,"errors":errors},"  "))
		f.close()
	done = true
	if errors.is_empty() and orb_passes == 4:
		print("W01_B01_L3_ROW PASS row=03 id=adrenaline_orb modes=4 checks=", checks)
		quit(0)
	else:
		print("W01_B01_L3_ROW FAIL row=03 id=adrenaline_orb modes=", orb_passes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
