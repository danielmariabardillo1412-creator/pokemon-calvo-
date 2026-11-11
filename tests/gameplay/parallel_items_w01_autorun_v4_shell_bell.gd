extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 TANDA04/06 genuine held item L3. No new recovery rule or fake settlement.
const BELL_OUT := "res://.godot/parallel_items/w01_v4_shell_bell"
var bell_rows: Array = []
var bell_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_bell")
	create_timer(650.0).timeout.connect(func():
		if not done:
			push_error("W01 Shell Bell L3 timed out")
			quit(2))

func _shell_bell_case(mode: String) -> Dictionary:
	var before_errors: int = errors.size()
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["tackle", "shadow_ball"])
	var reserve := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.current_hp = 150
	check("Shell Bell real owned party " + mode,
		owner.party.add_creature(own) and owner.party.add_creature(reserve))
	check("Shell Bell real inventory receives item " + mode,
		owner.inventory.add(&"shell_bell", 1))
	var service := ItemService.new()
	check("Shell Bell real FieldItemService allows selected held item " + mode,
		service.configure(owner, catalogs, func(): return true)
		and service.holdable(&"shell_bell"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Shell Bell equip transfers real bag stock " + mode,
			service.equip(&"shell_bell", target).get("accepted", false)
			and owner.inventory.quantity(&"shell_bell") == 0)
	var pre := _roundtrip(owner, "shell_" + mode + "_pre")
	if not pre.valid: return {"valid": false}
	owner = pre.owner
	var foe := _mon(&"gengar", 100, &"foe", ["amnesia"]) if mode == "immune" else _mon(&"mew", 100, &"foe", ["amnesia"])
	foe.current_hp = 140
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Shell Bell real FieldNativeSession starts " + mode, opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var before_hp: int = session.battle_state().creature(&"own").current_hp
	var before_foe: int = session.battle_state().creature(&"foe").current_hp
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Shell Bell native attack accepted " + mode, first.get("accepted", false))
	var active: CreatureInstance = session.battle_state().creature(&"own")
	var dealt: int = before_foe - session.battle_state().creature(&"foe").current_hp
	var healed: int = active.current_hp - before_hp
	var has_item: bool = mode == "active" or mode == "immune"
	var expected: int = maxi(1, int(floor(float(dealt) / 8.0))) if has_item and dealt > 0 else 0
	check("Shell Bell native proportional healing, immune/none controls " + mode,
		healed == expected
		and (dealt == 0 if mode == "immune" else dealt > 0))
	check("Shell Bell no consumption or wrong ownership " + mode,
		active.held_item_id == (&"shell_bell" if has_item else &"")
		and not active.held_item_consumed
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"shell_bell" if mode == "reserve" else &""))
	var moves: int = 0
	while session.phase() != "finished" and moves < 8:
		var result: Dictionary = await session.submit("move 2", session.revision)
		check("Shell Bell native real finishing attack " + mode, result.get("accepted", false))
		moves += 1
	check("Shell Bell finished by natural encounter " + mode, session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Shell Bell actual field settlement publishes collection " + mode,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var save := _roundtrip(owner, "shell_" + mode + "_post")
	if save.valid:
		check("Shell Bell SaveV2 preserves exactly one owned item " + mode,
			save.owner.inventory.quantity(&"shell_bell") == (1 if mode == "none" else 0)
			and save.owner.owned_creature(&"own").held_item_id ==
				(&"shell_bell" if has_item else &"")
			and save.owner.owned_creature(&"reserve").held_item_id ==
				(&"shell_bell" if mode == "reserve" else &"")
			and not save.owner.owned_creature(&"own").held_item_consumed
			and not save.owner.owned_creature(&"reserve").held_item_consumed)
	await session.close()
	return {"mode": mode, "valid": errors.size() == before_errors and save.valid,
		"dealt": dealt, "healed": healed, "expected": expected}

func _run_bell() -> void:
	destination = BELL_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Shell Bell canonical catalog", Variants.apply(catalogs))
	for mode in ["active", "none", "reserve", "immune"]:
		current_case = "T04_06_shell_bell_" + mode
		var result: Dictionary = await _shell_bell_case(mode)
		bell_rows.append(result)
		if result.get("valid", false): bell_passes += 1
	check("Shell Bell four true L3 routes", bell_passes == 4)
	if bell_rows.size() == 4:
		check("Shell Bell only active portador heals from actual damage",
			int(bell_rows[0].healed) > 0
			and int(bell_rows[1].healed) == 0
			and int(bell_rows[2].healed) == 0
			and int(bell_rows[3].healed) == 0
			and int(bell_rows[0].dealt) == int(bell_rows[1].dealt)
			and int(bell_rows[1].dealt) == int(bell_rows[2].dealt))
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Shell Bell evidence report writable", file != null)
	if file != null:
		file.store_string(JSON.stringify({"worker":"W01", "row":"06", "rows":bell_rows,
			"checks":checks, "errors":errors},"  "))
		file.close()
	done = true
	if errors.is_empty() and bell_passes == 4:
		print("W01_V4_L3_ROW PASS row=06 id=shell_bell modes=4 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=06 id=shell_bell modes=", bell_passes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
