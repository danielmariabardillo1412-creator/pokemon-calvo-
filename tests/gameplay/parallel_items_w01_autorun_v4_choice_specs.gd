extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"
# T04/03 FieldItemService -> FieldNativeSession choice lock/switch -> settle -> SaveV2.
const SPECS_OUT := "res://.godot/parallel_items/w01_v4_choice_specs"
var specs_rows: Array = []
var specs_passed: int = 0
func _initialize() -> void:
	capture = false
	call_deferred("_run_specs")
	create_timer(650.0).timeout.connect(func():
		if not done:
			push_error("W01 Choice Specs pilot timed out")
			quit(2))

func _one_specs(mode: String) -> Dictionary:
	var before_errors: int = errors.size()
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["water_gun", "shadow_ball"])
	var reserve := _mon(&"mew", 100, &"reserve", ["reflect"])
	check("Choice Specs actual party " + mode,
		owner.party.add_creature(own) and owner.party.add_creature(reserve))
	check("Choice Specs actual bag item " + mode, owner.inventory.add(&"choice_specs", 1))
	var service := ItemService.new()
	check("Choice Specs field service policy " + mode,
		service.configure(owner, catalogs, func(): return true) and service.holdable(&"choice_specs"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Choice Specs actual equip " + mode,
			service.equip(&"choice_specs", target).get("accepted", false)
			and owner.inventory.quantity(&"choice_specs") == 0)
	var first_save := _roundtrip(owner, "specs_" + mode + "_pre")
	if not first_save.valid: return {"valid": false}
	owner = first_save.owner
	var foe := _mon(&"mew", 100, &"foe", ["amnesia"])
	foe.current_hp = 160
	var s := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await s.begin_wild(self, foe, [19, 2, 3, 4])
	check("Choice Specs native field session opens " + mode, opened)
	if not opened:
		await s.close()
		return {"valid": false}
	var hp_before: int = s.battle_state().creature(&"foe").current_hp
	var attack: Dictionary = await s.submit("move 1", s.revision)
	check("Choice Specs native first attack accepted " + mode, attack.get("accepted", false))
	var damage: int = hp_before - s.battle_state().creature(&"foe").current_hp
	check("Choice Specs first special damage positive " + mode, damage > 0)
	if mode == "active":
		var revision_before: int = s.revision
		var foe_before: int = s.battle_state().creature(&"foe").current_hp
		var rejected: Dictionary = await s.submit("move 2", s.revision)
		check("Choice Specs native rejects second move while locked",
			not rejected.get("accepted", false) and s.revision == revision_before
			and s.battle_state().creature(&"foe").current_hp == foe_before)
	var switched: Dictionary = await s.submit(_switch_choice(s, &"reserve"), s.revision)
	check("Choice Specs real switch to bench " + mode, switched.get("accepted", false)
		and s.battle_state().active_for_side(&"side_a").instance_id == &"reserve")
	var returned: Dictionary = await s.submit(_switch_choice(s, &"own"), s.revision)
	check("Choice Specs real switch back to owner " + mode, returned.get("accepted", false)
		and s.battle_state().active_for_side(&"side_a").instance_id == &"own")
	var unlocked: Dictionary = await s.submit("move 2", s.revision)
	check("Choice Specs different move unlocked after switch " + mode,
		unlocked.get("accepted", false))
	var loops: int = 0
	while s.phase() != "finished" and loops < 7:
		var step: Dictionary = await s.submit("move 2", s.revision)
		check("Choice Specs actual finisher " + mode, step.get("accepted", false))
		loops += 1
	check("Choice Specs genuine natural victory " + mode, s.phase() == "finished")
	var settled: Dictionary = s.settle_finished_battle()
	check("Choice Specs real native settlement " + mode,
		settled.get("accepted", false) and s.completion_reason == "VICTORY")
	var saved := _roundtrip(owner, "specs_" + mode + "_post")
	if saved.valid:
		check("Choice Specs SaveV2 actual owner and no consumption " + mode,
			saved.owner.inventory.quantity(&"choice_specs") == (1 if mode == "none" else 0)
			and saved.owner.owned_creature(&"own").held_item_id ==
				(&"choice_specs" if mode == "active" else &"")
			and saved.owner.owned_creature(&"reserve").held_item_id ==
				(&"choice_specs" if mode == "reserve" else &"")
			and not saved.owner.owned_creature(&"own").held_item_consumed
			and not saved.owner.owned_creature(&"reserve").held_item_consumed)
	await s.close()
	return {"mode": mode, "valid": errors.size() == before_errors and saved.valid, "damage": damage}

func _run_specs() -> void:
	destination = SPECS_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Choice Specs catalog and policies", Variants.apply(catalogs))
	for mode in ["active", "none", "reserve"]:
		current_case = "T04_04_choice_specs_" + mode
		var row: Dictionary = await _one_specs(mode)
		specs_rows.append(row)
		if row.get("valid", false): specs_passed += 1
	check("Choice Specs all three ownership cases", specs_passed == 3)
	if specs_rows.size() == 3:
		check("Choice Specs special boost exclusively to active owner",
			int(specs_rows[0].damage) > int(specs_rows[1].damage)
			and int(specs_rows[1].damage) == int(specs_rows[2].damage))
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Choice Specs evidence writable", file != null)
	if file != null:
		file.store_string(JSON.stringify({"worker":"W01", "row":"03", "checks":checks,
			"rows":specs_rows, "errors":errors}, "  "))
		file.close()
	done = true
	if errors.is_empty() and specs_passed == 3:
		print("W01_V4_L3_ROW PASS row=04 id=choice_specs modes=3 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=04 id=choice_specs modes=", specs_passed,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
