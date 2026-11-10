extends "res://tests/gameplay/parallel_items_w01_campaign_005.gd"

# IA1/W01 — AUTORUN V2 TANDA02. New isolated real Godot + SaveV2 cases.
# Inherited CAMPAÑA_005 code and all historical fixtures remain unchanged.
const V2_FIXTURE := "res://tests/fixtures/parallel_items/w01_autorun_v2.json"
const V2_PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V2_PROGRESS.csv"
const V2_OUTPUT := "res://.godot/parallel_items/w01_autorun_v2"
var v2_results: Array = []
var v2_positive_pairs: int = 0
var v2_negative_pairs: int = 0
var v2_functional_rows: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_autorun_v2")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("W01 V2 timeout real SaveV2")
			quit(2))

func _run_autorun_v2() -> void:
	destination = V2_OUTPUT
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(V2_FIXTURE))
	check("W01 V2 fixture is dictionary", parsed is Dictionary)
	if not parsed is Dictionary:
		quit(2)
		return
	var manifest: Dictionary = parsed
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("W01 V2 canonical overlays", Variants.apply(catalogs))
	check("W01 V2 identity and battle format",
		manifest.get("schema_version") == 1
		and manifest.get("worker") == "W01"
		and manifest.get("kind") == "AUTORUN_V2_W01_GEMS"
		and manifest.get("tanda") == "02"
		and manifest.get("format") == "gen9calvounifiedv1")
	check("W01 V2 three independently restored modes",
		manifest.get("modes") == ["active", "none", "reserve"])
	var gem_cases: Array = manifest.get("items", [])
	check("W01 V2 exactly five new gem objects", gem_cases.size() == 5)
	if gem_cases.size() != 5:
		quit(2)
		return
	var progress_file: FileAccess = FileAccess.open(V2_PROGRESS, FileAccess.READ)
	check("W01 V2 progress manifest is readable", progress_file != null)
	if progress_file == null:
		quit(2)
		return
	var header: PackedStringArray = progress_file.get_csv_line()
	check("W01 V2 CSV eight columns", header.size() == 8
		and String(header[0]) == "fila" and String(header[1]) == "hito")
	var progress: Array = []
	while not progress_file.eof_reached():
		var fields: PackedStringArray = progress_file.get_csv_line()
		if fields.size() == 1 and fields[0].is_empty():
			continue
		check("W01 V2 progress entry eight fields", fields.size() == 8)
		if fields.size() == 8:
			progress.append({"row": String(fields[0]), "id": String(fields[1]),
				"status": String(fields[2])})
	progress_file.close()
	check("W01 V2 exactly ten milestones", progress.size() == 10)
	if progress.size() != 10:
		quit(2)
		return
	for i in gem_cases.size():
		var entry: Dictionary = gem_cases[i]
		var id: String = String(entry.id)
		var row_id: String = "%02d" % (i + 1)
		check("W01 V2 first five milestones mirror IDs",
			String(entry.row) == row_id and String(progress[i].row) == row_id
			and String(progress[i].id) == id)
		check("W01 V2 item status is a permitted gate",
			["PENDIENTE", "EN_CI_AUTOMATICA", "CERTIFICADO", "BLOQUEADO", "NO_APLICA", "DIFERIDO"].has(
				String(progress[i].status)))
		var first_errors: int = errors.size()
		var evidence: Array = []
		var plans: Array = entry.get("cases", [])
		check("W01 V2 3 control operations", plans.size() == 3)
		for plan: Dictionary in plans:
			var operation: String = String(plan.op)
			check("W01 V2 only matching, negative type and status operations",
				["matching", "wrong_type", "status_same_type"].has(operation))
			var op: String = ("gem_matching" if operation == "matching"
				else "gem_nonmatching" if operation == "wrong_type" else "gem_status")
			var case: Dictionary = {"id": id + "_" + operation, "block": row_id,
				"item_id": id, "actor_species": "mew", "foe_species": "mew",
				"own_move": String(plan.move), "foe_move": "amnesia", "op": op}
			for seed_value: Variant in plan.seeds:
				var seed: int = int(seed_value)
				check("W01 V2 bounded integer seed", seed >= 1 and seed <= 65535)
				current_case = id + "/" + operation + "/" + str(seed)
				var saved_errors: int = errors.size()
				var saved_checks: int = checks
				var modes: Dictionary = {}
				for mode: String in ["active", "none", "reserve"]:
					call_deferred("_w01_c004_probe_lane", case, seed, mode, modes)
				while modes.size() < 3:
					await process_frame
				_compare_v2(case, modes)
				if operation == "matching":
					v2_positive_pairs += 1
				else:
					v2_negative_pairs += 1
				evidence.append({"case": current_case, "pass": errors.size() == saved_errors,
					"checks": checks - saved_checks, "modes": modes})
		var positive: bool = errors.size() == first_errors
		if positive:
			v2_functional_rows += 1
			print("W01_V2_GODOT_ROW PASS row=", row_id, " id=", id,
				" SaveV2=twice owner=3 genuine_damage=1")
		else:
			print("W01_V2_GODOT_ROW FAIL row=", row_id, " id=", id)
		v2_results.append({"row": row_id, "id": id, "status": "PASS" if positive else "FAIL",
			"evidence": evidence})
	check("W01 V2 two real positive seeds per Gem", v2_positive_pairs == 10)
	check("W01 V2 negative context pairs total", v2_negative_pairs == 10)
	check("W01 V2 every five Gem has a verified real positive effect", v2_functional_rows == 5)
	var report: Dictionary = {"version": 2, "tanda": "02", "worker": "W01",
		"checks": checks, "positive_rows": v2_functional_rows,
		"positive_pairs": v2_positive_pairs, "negative_pairs": v2_negative_pairs,
		"results": v2_results, "errors": errors,
		"limits": ["Headless is not manual UI/GPU verification",
			"Native Transform and miss/immune diagnostics are separate explicit tests",
			"No integrated main/V28 claim"]}
	var output: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("W01 V2 report can be written", output != null)
	if output != null:
		output.store_string(JSON.stringify(report, "  "))
		output.close()
	done = true
	if errors.is_empty():
		print("W01_V2_GODOT PASS rows=", v2_functional_rows, " checks=", checks)
		quit(0)
	else:
		print("W01_V2_GODOT FAIL rows=", v2_functional_rows,
			" checks=", checks, " errors=", errors.size())
		quit(1)

func _compare_v2(row: Dictionary, observed: Dictionary) -> void:
	check("W01 V2 actual three native combat modes",
		observed.has_all(["active", "none", "reserve"]))
	if not observed.has_all(["active", "none", "reserve"]):
		return
	var positive: bool = String(row.op) == "gem_matching"
	for mode: String in ["active", "none", "reserve"]:
		var x: Dictionary = observed[mode]
		check(mode + " W01 V2 real battle and SaveV2 restore",
			x.get("valid", false) and x.get("restored", false)
			and x.get("owner_unchanged", false) and x.get("save_equal", false))
		if not x.get("valid", false):
			return
		check(mode + " W01 V2 exclusive holder",
			bool(x.start.own_has_item) == (mode == "active")
			and bool(x.start.reserve_has_item) == (mode == "reserve"))
		check(mode + " W01 V2 reserve cannot consume",
			not bool(x.after.reserve_consumed))
		check(mode + " W01 V2 exact physical stock",
			int(x.physical_units) == (1 if positive and mode == "active" else 2))
	var a: Dictionary = observed.active
	var n: Dictionary = observed.none
	var r: Dictionary = observed.reserve
	check("W01 V2 none and reserve must not activate",
		not bool(n.after.own_consumed) and not bool(r.after.own_consumed))
	if positive:
		check("W01 V2 native matching-type real damage increases only for own holder",
			a.damage > n.damage and n.damage > 0 and n.damage == r.damage)
		check("W01 V2 only one actual Gem consumed and spent flag retained",
			bool(a.after.own_consumed)
			and String(a.after.native_item).is_empty() and int(a.physical_units) == 1)
		check("W01 V2 consumption persists across two legal attacks",
			bool(a.get("gem_first_consumed", false))
			and bool(a.get("gem_second_consumed", false))
			and String(a.get("gem_first_native_item", "")).is_empty()
			and String(a.get("gem_second_native_item", "")).is_empty()
			and int(a.get("gem_first_units", 0)) == 1
			and int(a.get("gem_second_units", 0)) == 1
			and int(a.get("second_damage", 0)) > 0)
		check("W01 V2 SaveV2 saved between attacks and after second",
			bool(a.get("gem_mid_save", false)) and bool(a.get("gem_final_save", false))
			and bool(n.get("gem_mid_save", false)) and bool(r.get("gem_final_save", false)))
	else:
		check("W01 V2 negative Gem remains equipped and is not consumed",
			not bool(a.after.own_consumed)
			and String(a.after.native_item) == String(row.item_id).replace("_", "")
			and int(a.physical_units) == 2)
		if String(row.op) == "gem_nonmatching":
			check("W01 V2 wrong-type damage unchanged in active, none and reserve",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		else:
			check("W01 V2 same-type status never deals direct foe damage",
				a.damage == 0 and n.damage == 0 and r.damage == 0)
