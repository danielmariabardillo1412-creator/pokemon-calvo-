extends "res://tests/gameplay/parallel_items_w02_campaign_003.gd"

# W02 V2, five previously untested-in-CAMP003 held berries.
# Reuses CAMP003 native @pkmn/sim battle with PARTY/none/reserve, checkpoint
# restore, physical settlement and SaveV2. Does not modify combat code.
const SOURCE_HELD05 := "res://tests/fixtures/parallel_items/w02_continuous_v2_held05.json"
const IDS := ["cheri_berry", "chesto_berry", "pecha_berry", "rawst_berry", "oran_berry"]


func _initialize() -> void:
	capture = false
	call_deferred("_run_held05")
	create_timer(540.0).timeout.connect(func():
		if not done:
			push_error("W02 V2 HELD05 watchdog")
			quit(2))


func _run_held05() -> void:
	destination = "res://.godot/parallel_items/w02_continuous_v2_held05"
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_HELD05))
	if not parsed is Dictionary:
		push_error("W02 V2 HELD05 invalid fixture")
		quit(2)
		return
	automation = parsed
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("HELD05: regional overlay", Variants.apply(catalogs))
	check("HELD05: campaign and scope",
		String(automation.campaign) == "W02_CONTINUOUS_V2"
		and String(automation.block) == "01"
		and String(automation.proof_scope) == "held_native_battle_only")
	check("HELD05: five exact IDs", automation.item_ids == IDS)
	check("HELD05: three owner modes", automation.modes == ["active", "none", "reserve"])
	check("HELD05: ten cases", automation.cases.size() == 10)
	var seen: Dictionary = {}
	var results: Array = []
	for spec: Dictionary in automation.cases:
		current_case = String(spec.scenario)
		var before_checks: int = checks
		var before_errors: int = errors.size()
		var id: String = String(spec.id)
		check("HELD05: authorized item", IDS.has(id)
			and catalogs.item(StringName(id)) != null)
		seen[id] = int(seen.get(id, 0)) + 1
		var observed: Dictionary = {}
		for mode: String in automation.modes:
			observed[mode] = await _probe_berry(spec, mode)
		var complete: bool = observed.size() == 3
		for mode: String in automation.modes:
			complete = complete and bool(observed[mode].get("valid", false))
		check("HELD05: active/none/reserve native complete", complete)
		if complete:
			var a: Dictionary = observed.active
			var n: Dictionary = observed.none
			var s: Dictionary = observed.reserve
			var consumes: bool = bool(spec.consumes)
			check("HELD05: active consumes only when effect triggers",
				bool(a.consumed) == consumes and not bool(n.consumed)
				and not bool(s.consumed))
			check("HELD05: physical stock after settlement",
				int(a.total) == (1 if consumes else 2)
				and int(n.total) == 2 and int(s.total) == 2)
			check("HELD05: absent versus reserved control",
				int(n.hp) == int(s.hp) and String(n.status) == String(s.status))
			check("HELD05: restored and persisted",
				bool(a.save_v2) and bool(n.save_v2) and bool(s.save_v2)
				and bool(a.restored) and bool(n.restored) and bool(s.restored)
				and bool(a.settled_once) and bool(n.settled_once)
				and bool(s.settled_once))
			if String(spec.kind) == "status_cure":
				check("HELD05: precise status cure only on active bearer",
					String(a.status) == ("" if consumes else String(spec.status))
					and String(n.status) == String(spec.status)
					and String(s.status) == String(spec.status))
			elif String(spec.kind) == "heal_fixed10":
				var expected_hp: int = mini(int(a.max_hp), int(n.hp) + (10 if consumes else 0))
				check("HELD05: Oran restores exactly ten HP if activated",
					int(a.hp) == expected_hp and int(n.hp) == int(s.hp)
					and String(a.status) == String(n.status))
			else:
				check("HELD05: contract family known", false)
			for mode: String in automation.modes:
				var receipt: Dictionary = observed[mode]
				var file: String = destination + "/" + String(receipt.evidence)
				check("HELD05: each native receipt authenticated",
					FileAccess.file_exists(file)
					and FileAccess.get_sha256(file) == String(receipt.sha256))
		results.append({"id": id, "scenario": String(spec.scenario),
			"status": "PASS" if complete and errors.size() == before_errors else "FAIL",
			"checks": checks - before_checks})
	check("HELD05: ten completed cases", results.size() == 10)
	check("HELD05: five distinct IDs", seen.size() == IDS.size())
	for id: String in IDS:
		check("HELD05: two cases per ID", int(seen.get(id, 0)) == 2)
	var valid: bool = results.size() == 10
	for row: Dictionary in results:
		valid = valid and String(row.status) == "PASS"
	check("HELD05: no partial or missing case", valid)
	var passed: bool = valid and errors.is_empty()
	var report: Dictionary = {
		"status": "PASS" if passed else "FAIL", "family": "W02_CONTINUOUS_V2_HELD05",
		"checks": checks, "cases": results, "errors": automation_errors,
		"native_held_positive": 5, "native_held_negative": 5,
		"new_production_objects": 0, "scope": "held_native_battle_only"
	}
	var outfile := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if outfile == null:
		push_error("HELD05: report not writable")
		quit(2)
		return
	outfile.store_string(JSON.stringify(report, "  "))
	outfile.close()
	done = true
	print("W02_CONTINUOUS_V2_HELD05_GODOT ", report.status,
		" positive=5 negative=5 checks=", checks)
	quit(0 if passed else 1)
