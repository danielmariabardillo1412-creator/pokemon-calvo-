extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 TANDA04/row01. Genuine inventory -> FieldItemService -> FieldNativeSession
# -> native Leftovers onResidual -> battle settlement -> SaveV2 disk reload.
# This supplements, not overwrites, any prior engine pilot tests.
const V4_OUT := "res://.godot/parallel_items/w01_autorun_v4"
const V4_FIXTURE := "res://tests/fixtures/parallel_items/w01_autorun_v4.json"
var v4_passed: int = 0
var v4_rows: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_w01_v4")
	create_timer(500.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 Leftovers L3 timeout")
			quit(2))

func _probe_leftovers(mode: String) -> Dictionary:
	var before_errors: int = errors.size()
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["reflect", "tackle"])
	var bench := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.current_hp = own.stats.max_hp if mode == "full" else int(own.stats.max_hp / 2)
	check("Leftovers L3 independent owned creatures " + mode,
		owner.party.add_creature(own) and owner.party.add_creature(bench))
	check("Leftovers L3 actual bag stock " + mode,
		owner.inventory.add(&"leftovers", 1))
	var service := ItemService.new()
	check("Leftovers L3 configured real field service " + mode,
		service.configure(owner, catalogs, func(): return true) and service.holdable(&"leftovers"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		var equipped: Dictionary = service.equip(&"leftovers", target)
		check("Leftovers real equip " + mode, equipped.get("accepted", false)
			and owner.inventory.quantity(&"leftovers") == 0
			and owner.owned_creature(target).held_item_id == &"leftovers")
	var pre := _roundtrip(owner, "leftovers_" + mode + "_pre")
	if not pre.valid:
		return {"valid": false, "mode": mode}
	owner = pre.owner
	var hp_before: int = owner.owned_creature(&"own").current_hp
	var maximum: int = owner.owned_creature(&"own").stats.max_hp
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self,
		_mon(&"caterpie", 1, &"foe", ["growl"]), [19, 2, 3, 4])
	check("Leftovers real field session opens " + mode, opened)
	if not opened:
		await session.close()
		return {"valid": false, "mode": mode}
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Leftovers genuine non-damaging turn accepted " + mode,
		first.get("accepted", false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var delta: int = live.current_hp - hp_before
	var expected: int = maxi(1, maximum / 16) if mode == "active" else 0
	check("Leftovers native exact end-turn heal and controls " + mode,
		delta == expected)
	check("Leftovers does not burn item or owner identity " + mode,
		not live.held_item_consumed
		and (live.held_item_id == &"leftovers") == (mode == "active" or mode == "full")
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"leftovers" if mode == "reserve" else &""))
	var second: Dictionary = await session.submit("move 2", session.revision)
	check("Leftovers real finisher accepted " + mode, second.get("accepted", false))
	check("Leftovers ends genuine wild encounter " + mode,
		session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Leftovers authoritative settlement once " + mode,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var after := _roundtrip(owner, "leftovers_" + mode + "_post")
	if after.valid:
		var saved: PlayerCollection = after.owner
		var own_saved: CreatureInstance = saved.owned_creature(&"own")
		var bench_saved: CreatureInstance = saved.owned_creature(&"reserve")
		check("Leftovers L3 exact conserved stock+held no consumption " + mode,
			saved.inventory.quantity(&"leftovers") == (1 if mode == "none" else 0)
			and own_saved.held_item_id == (&"leftovers" if mode == "active" or mode == "full" else &"")
			and bench_saved.held_item_id == (&"leftovers" if mode == "reserve" else &"")
			and not own_saved.held_item_consumed and not bench_saved.held_item_consumed
			and own_saved.current_hp >= hp_before + expected
			and own_saved.current_hp <= maximum)
	await session.close()
	return {"valid": errors.size() == before_errors and after.valid, "mode": mode,
		"heal": delta, "expected": expected, "savev2": after.valid}

func _run_w01_v4() -> void:
	destination = V4_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(V4_FIXTURE))
	check("V4 fixture loads", data is Dictionary)
	if not data is Dictionary:
		quit(2)
		return
	check("V4 source and pilot identity",
		data.get("tanda") == "04" and data.get("worker") == "W01"
		and data.get("stage01", {}).get("id") == "leftovers")
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("V4 effective canonical species and move catalog", Variants.apply(catalogs))
	for mode in ["active", "none", "reserve", "full"]:
		current_case = "V4_01_leftovers_" + mode
		var result: Dictionary = await _probe_leftovers(mode)
		v4_rows.append(result)
		if result.get("valid", false):
			v4_passed += 1
	check("V4 leftovers four independent positive/negative routes", v4_passed == 4)
	var report: Dictionary = {"tanda": "04", "worker": "W01", "row": "01",
		"id": "leftovers", "checks": checks, "errors": errors, "variants": v4_rows,
		"limitations": ["headless integration via real FieldNativeSession; no UI scene",
			"existing native Leftovers effect audited; not new implementation",
			"future competitive objects remain untested"]}
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("V4 Leftovers evidence writable", file != null)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	done = true
	if errors.is_empty() and v4_passed == 4:
		print("W01_V4_L3_ROW PASS row=01 id=leftovers variants=4 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=01 id=leftovers variants=", v4_passed,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
