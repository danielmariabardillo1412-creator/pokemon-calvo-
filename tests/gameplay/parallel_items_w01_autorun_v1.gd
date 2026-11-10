extends "res://tests/gameplay/parallel_items_w01_campaign_005.gd"

# IA1/W01 AUTORUN V1, TANDA 01. New tests only: CAMP005 remains frozen.
# Positive cases reuse the proven native two-turn Gem + interstitial SaveV2 probe;
# negative cases reuse CAMP004's three-mode real session and SaveV2 probe.
const V1_FIXTURE := "res://tests/fixtures/parallel_items/w01_autorun_v1.json"
const V1_PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V1_PROGRESS.csv"
const V1_OUTPUT := "res://.godot/parallel_items/w01_autorun_v1"
var v1_results: Array = []
var v1_positive_pairs: int = 0
var v1_negative_pairs: int = 0
var v1_functional_rows: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_autorun_v1")
	create_timer(1500.0).timeout.connect(func():
		if not done:
			push_error("W01 AUTORUN V1 timeout")
			quit(2))

func _run_autorun_v1() -> void:
	destination = V1_OUTPUT
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(V1_FIXTURE))
	check("AUTORUN fixture must be JSON object", parsed is Dictionary)
	if not parsed is Dictionary:
		quit(2)
		return
	var manifest: Dictionary = parsed
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("AUTORUN canonical overlays load", Variants.apply(catalogs))
	check("AUTORUN W01 identity", manifest.get("schema_version") == 1
		and manifest.get("worker") == "W01" and manifest.get("kind") == "AUTORUN_V1_W01_GEMS"
		and manifest.get("tanda") == "01" and manifest.get("format") == "gen9calvounifiedv1")
	check("AUTORUN three ownership modes", manifest.get("modes") == ["active", "none", "reserve"])
	var items: Array = manifest.get("items", [])
	check("AUTORUN exactly ten authorized rows", items.size() == 10)
	if items.size() != 10:
		quit(2)
		return
	var progress_file: FileAccess = FileAccess.open(V1_PROGRESS, FileAccess.READ)
	check("AUTORUN progress readable", progress_file != null)
	if progress_file == null:
		quit(2)
		return
	var columns: PackedStringArray = progress_file.get_csv_line()
	check("AUTORUN progress columns", columns.size() == 8
		and String(columns[0]) == "fila" and String(columns[2]) == "estado")
	var progress: Array = []
	while not progress_file.eof_reached():
		var fields: PackedStringArray = progress_file.get_csv_line()
		if fields.size() == 1 and fields[0].is_empty():
			continue
		check("AUTORUN progress row schema", fields.size() == 8)
		if fields.size() == 8:
			progress.append({"row": String(fields[0]), "id": String(fields[1]),
				"status": String(fields[2])})
	progress_file.close()
	check("AUTORUN exactly ten progress rows", progress.size() == 10)
	if progress.size() != 10:
		quit(2)
		return
	for i in items.size():
		var entry: Dictionary = items[i]
		var id: String = String(entry.id)
		var row_id: String = "%02d" % (i + 1)
		check("AUTORUN row identity and order " + row_id, String(entry.row) == row_id
			and String(progress[i].row) == row_id and String(progress[i].id) == id)
		check("AUTORUN item status allowed " + id,
			["PENDIENTE", "EN_CI_AUTOMATICA", "CERTIFICADO", "BLOQUEADO", "NO_APLICA", "DIFERIDO"].has(
				String(progress[i].status)))
		var row_before: int = errors.size()
		var row_evidence: Array = []
		var plans: Array = entry.get("cases", [])
		check("AUTORUN positive, wrong type, same-type status all present " + id,
			plans.size() == 3)
		for plan: Dictionary in plans:
			var operation: String = String(plan.op)
			var op: String = ("gem_matching" if operation == "matching"
				else "gem_nonmatching" if operation == "wrong_type" else "gem_status")
			check("AUTORUN only authorized operation " + id,
				["matching", "wrong_type", "status_same_type"].has(operation))
			var row: Dictionary = {"id": id + "_" + operation, "block": row_id,
				"item_id": id, "actor_species": "mew", "foe_species": "mew",
				"own_move": String(plan.move), "foe_move": "amnesia", "op": op}
			for seed_value: Variant in plan.seeds:
				var seed: int = int(seed_value)
				check("AUTORUN seed within trusted range", seed >= 1 and seed <= 65535)
				current_case = id + "/" + operation + "/" + str(seed)
				var previous_err: int = errors.size()
				var previous_checks: int = checks
				var observed: Dictionary = {}
				for mode: String in ["active", "none", "reserve"]:
					call_deferred("_w01_c004_probe_lane", row, seed, mode, observed)
				while observed.size() < 3:
					await process_frame
				_compare_autorun_v1(row, observed)
				if operation == "matching":
					v1_positive_pairs += 1
				else:
					v1_negative_pairs += 1
				row_evidence.append({"case": current_case, "checks": checks - previous_checks,
					"passed": errors.size() == previous_err, "observed": observed})
		var passed: bool = errors.size() == row_before
		if passed:
			v1_functional_rows += 1
			print("AUTORUN_W01_ROW_PASS row=", row_id, " id=", id,
				" cases=3 modes=3 SaveV2=verified")
		else:
			print("AUTORUN_W01_ROW_FAIL row=", row_id, " id=", id)
		v1_results.append({"row": row_id, "id": id, "status": "PASS" if passed else "FAIL",
			"evidence": row_evidence})
	check("AUTORUN positive seed pairs", v1_positive_pairs == 20)
	check("AUTORUN negative seed pairs", v1_negative_pairs == 20)
	check("AUTORUN ten individually functional rows", v1_functional_rows == 10)
	var report: Dictionary = {"schema_version": 1, "worker": "W01", "tanda": "01",
		"checks": checks, "functional_rows": v1_functional_rows,
		"positive_pairs": v1_positive_pairs, "negative_pairs": v1_negative_pairs,
		"rows": v1_results, "errors": errors,
		"limitations": ["Headless no GPU/UI", "No main integration",
			"Type/status provenance validated in native Showdown and Python preflight"]}
	var output: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("AUTORUN report output can be written", output != null)
	if output != null:
		output.store_string(JSON.stringify(report, "  "))
		output.close()
	done = true
	if errors.is_empty():
		print("W01_AUTORUN_GODOT PASS rows=", v1_functional_rows, " checks=", checks)
		quit(0)
	else:
		print("W01_AUTORUN_GODOT FAIL rows=", v1_functional_rows,
			" checks=", checks, " errors=", errors.size())
		quit(1)

func _compare_autorun_v1(row: Dictionary, obs: Dictionary) -> void:
	check("AUTORUN three actual native combats", obs.has_all(["active", "none", "reserve"]))
	if not obs.has_all(["active", "none", "reserve"]):
		return
	var matching: bool = String(row.op) == "gem_matching"
	for mode: String in ["active", "none", "reserve"]:
		var x: Dictionary = obs[mode]
		check(mode + " real battle, SaveV2, stable owner",
			x.get("valid", false) and x.get("restored", false)
			and x.get("owner_unchanged", false) and x.get("save_equal", false))
		if not x.get("valid", false):
			return
		check(mode + " exclusive item holder",
			bool(x.start.own_has_item) == (mode == "active")
			and bool(x.start.reserve_has_item) == (mode == "reserve"))
		check(mode + " never consumes reserve", not bool(x.after.reserve_consumed))
		check(mode + " exactly one positive activation or full retained stock",
			int(x.physical_units) == (1 if matching and mode == "active" else 2))
	var a: Dictionary = obs.active
	var n: Dictionary = obs.none
	var r: Dictionary = obs.reserve
	check("No item may activate in none/reserve",
		not bool(n.after.own_consumed) and not bool(r.after.own_consumed))
	if matching:
		check("Matching Gem increased first real hit, only active holder",
			a.damage > n.damage and n.damage > 0 and n.damage == r.damage)
		check("Matching Gem removed native held item and decremented stock",
			bool(a.after.own_consumed) and String(a.after.native_item).is_empty()
			and int(a.physical_units) == 1)
		check("Consumed after first hit and still consumed after second hit",
			bool(a.get("gem_first_consumed", false))
			and bool(a.get("gem_second_consumed", false))
			and String(a.get("gem_first_native_item", "")).is_empty()
			and String(a.get("gem_second_native_item", "")).is_empty()
			and int(a.get("gem_first_units", 0)) == 1
			and int(a.get("gem_second_units", 0)) == 1)
		check("Two legal hits, SaveV2 immediately after spent and again after next hit",
			int(a.get("second_damage", 0)) > 0
			and bool(a.get("gem_mid_save", false)) and bool(a.get("gem_final_save", false))
			and bool(n.get("gem_mid_save", false))
			and bool(r.get("gem_final_save", false)))
	else:
		check("Negative Gem never consumes actual equipped holder",
			not bool(a.after.own_consumed)
			and String(a.after.native_item) == String(row.item_id).replace("_", "")
			and int(a.physical_units) == 2)
		if String(row.op) == "gem_nonmatching":
			check("Wrong type damages but never gains Gem boost",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		else:
			check("Same-type status cannot trigger Gem or inflict damage",
				a.damage == 0 and n.damage == 0 and r.damage == 0)
