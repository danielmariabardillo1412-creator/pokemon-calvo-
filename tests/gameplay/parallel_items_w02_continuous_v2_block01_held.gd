extends "res://tests/gameplay/parallel_items_w02_campaign_004.gd"

# W02 CONTINUOUS_V2: native held flavor berries, not a field-use claim.
# Inherited CAMP003/CAMP004 probes enforce a real @pkmn/sim turn,
# active/none/reserve, settled inventory, restore checkpoint and SaveV2.
const SOURCE_V2_HELD := "res://tests/fixtures/parallel_items/w02_continuous_v2_block01_held.json"
const EXPECTED_IDS := ["aguav_berry", "iapapa_berry", "mago_berry"]


func _initialize() -> void:
	capture = false
	call_deferred("_run_continuous_v2_held")
	create_timer(540.0).timeout.connect(func():
		if not done:
			push_error("W02 CONTINUOUS_V2 B01 HELD watchdog")
			quit(2))


func _run_continuous_v2_held() -> void:
	destination = "res://.godot/parallel_items/w02_continuous_v2_b01_held"
	DirAccess.make_dir_recursive_absolute(destination)
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_V2_HELD))
	if not loaded is Dictionary:
		push_error("W02 V2 held: fixture invalida")
		quit(2)
		return
	automation = loaded
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("W02 V2 held: overlay regional", Variants.apply(catalogs))
	check("W02 V2 held: misión y bloque",
		String(automation.campaign) == "W02_CONTINUOUS_V2" and String(automation.block) == "01")
	check("W02 V2 held: alcance nativo exclusivo",
		String(automation.proof_scope) == "held_native_battle_only")
	check("W02 V2 held: tres controles", automation.modes == ["active", "none", "reserve"])
	check("W02 V2 held: nueve escenarios", automation.cases.size() == 9)
	check("W02 V2 held: tres IDs", automation.item_ids == EXPECTED_IDS)
	var seen: Dictionary = {}
	var results: Array = []
	for spec: Dictionary in automation.cases:
		current_case = String(spec.scenario)
		var checks_before: int = checks
		var errors_before: int = errors.size()
		var id: String = String(spec.id)
		seen[id] = int(seen.get(id, 0)) + 1
		check("W02 V2 held: ID del catálogo",
			EXPECTED_IDS.has(id) and catalogs.item(StringName(id)) != null)
		check("W02 V2 held: efecto flavor", String(spec.kind) == "heal_flavor")
		var observations: Dictionary = {}
		for mode: String in automation.modes:
			observations[mode] = await _probe_berry(spec, mode)
		var complete: bool = observations.size() == 3
		for mode: String in automation.modes:
			complete = complete and bool(observations[mode].get("valid", false))
		check("W02 V2 held: tres modos de combate", complete)
		if complete:
			_compare_berry(spec, observations)
		results.append({
			"id": id, "scenario": String(spec.scenario),
			"status": "PASS" if complete and errors.size() == errors_before else "FAIL",
			"checks": checks - checks_before,
			"active_consumes": bool(spec.consumes), "expected_confusion": bool(spec.confuses)
		})
	check("W02 V2 held: resultados completos", results.size() == 9)
	check("W02 V2 held: ID no omitido", seen.size() == EXPECTED_IDS.size())
	for id: String in EXPECTED_IDS:
		check("W02 V2 held: tres escenarios por ID", int(seen.get(id, 0)) == 3)
	var all_pass: bool = results.size() == 9
	for row: Dictionary in results:
		all_pass = all_pass and String(row.status) == "PASS"
	check("W02 V2 held: sin fallos reales", all_pass)
	var passed: bool = errors.is_empty() and all_pass
	var report: Dictionary = {
		"campaign": "W02_CONTINUOUS_V2", "block": "01", "scope": "held_native_battle",
		"status": "PASS" if passed else "FAIL", "cases": results,
		"checks": checks, "errors": errors,
		"held_battle_certified": passed, "persim_certified": false,
		"field_use_certified_by_this_runner": false
	}
	var file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if file == null:
		push_error("W02 V2 held: no se pudo guardar reporte")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("W02_CONTINUOUS_V2_B01_HELD_GODOT ", report.status,
		" cases=9 checks=", checks)
	quit(0 if passed else 1)
