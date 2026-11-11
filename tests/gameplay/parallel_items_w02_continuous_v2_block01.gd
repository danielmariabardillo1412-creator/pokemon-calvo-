extends "res://tests/gameplay/parallel_items_w02_campaign_004.gd"

# W02 CONTINUOUS_V2: first native field-only berry preflight.
# Inherits the established CAMP004 real-inventory, PARTY/STORAGE, rollback,
# SaveV2 and SHA256 evidence probes. Does NOT certify held battle activation.
const SOURCE_V2_B01 := "res://tests/fixtures/parallel_items/w02_continuous_v2_block01.json"
const EXPECTED_IDS := [
	"cheri_berry", "chesto_berry", "pecha_berry",
	"rawst_berry", "aspear_berry", "oran_berry"
]


func _initialize() -> void:
	capture = false
	call_deferred("_run_continuous_v2_b01")
	create_timer(540.0).timeout.connect(func():
		if not done:
			push_error("W02 CONTINUOUS_V2 B01 watchdog")
			quit(2))


func _run_continuous_v2_b01() -> void:
	destination = "res://.godot/parallel_items/w02_continuous_v2_b01"
	DirAccess.make_dir_recursive_absolute(destination)
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_V2_B01))
	if not loaded is Dictionary:
		push_error("W02 V2 B01: fixture JSON invalida")
		quit(2)
		return
	automation = loaded
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("W02 V2: overlay regional activo", Variants.apply(catalogs))
	check("W02 V2: campaña y bloque correctos",
		String(automation.campaign) == "W02_CONTINUOUS_V2" and String(automation.block) == "01")
	check("W02 V2: sólo uso de campo", String(automation.proof_scope) == "field_use_only_no_held_combat_claim")
	check("W02 V2: tres modos", automation.modes == ["active", "none", "reserve"])
	check("W02 V2: doce escenarios", automation.cases.size() == 12)
	check("W02 V2: seis IDs explícitos", automation.item_ids == EXPECTED_IDS)
	var seen: Dictionary = {}
	var results: Array = []
	for spec: Dictionary in automation.cases:
		current_case = String(spec.scenario)
		var checks_before: int = checks
		var errors_before: int = errors.size()
		var id: String = String(spec.id)
		seen[id] = int(seen.get(id, 0)) + 1
		check("W02 V2: ID autorizado y existente", EXPECTED_IDS.has(id)
			and catalogs.item(StringName(id)) != null)
		check("W02 V2: sólo familia field_medicine",
			String(spec.kind) == "field_medicine")
		var observed: Dictionary = {}
		for mode: String in automation.modes:
			observed[mode] = _probe_field_use(spec, mode)
		var complete: bool = observed.size() == 3
		for mode: String in automation.modes:
			complete = complete and bool(observed[mode].get("valid", false))
		check("W02 V2: PARTY, no stock y STORAGE completos", complete)
		if complete:
			_compare_field_use(spec, observed)
		results.append({"id": id, "scenario": String(spec.scenario),
			"kind": "field_only", "positive": bool(spec.applies),
			"status": "PASS" if complete and errors.size() == errors_before else "FAIL",
			"checks": checks - checks_before})
	check("W02 V2: ningún escenario omitido", results.size() == 12)
	check("W02 V2: dos escenarios por cada una de seis bayas", seen.size() == EXPECTED_IDS.size())
	for id: String in EXPECTED_IDS:
		check("W02 V2: positivas y negativas por ID", int(seen.get(id, 0)) == 2)
	var all_pass: bool = results.size() == 12
	for row: Dictionary in results:
		all_pass = all_pass and row.status == "PASS"
	check("W02 V2: casos reales sin fallos", all_pass)
	var passed: bool = errors.is_empty() and all_pass
	var report: Dictionary = {
		"campaign": "W02_CONTINUOUS_V2", "block": "01", "scope": "field_only",
		"status": "PASS" if passed else "FAIL", "cases": results,
		"checks": checks, "errors": errors,
		"positive_field_cases": 6, "negative_field_cases": 6,
		"held_combat_certified": false, "new_mechanics_claimed": 0
	}
	var file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if file == null:
		push_error("W02 V2: no se pudo guardar reporte")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("W02_CONTINUOUS_V2_B01_GODOT ", report.status,
		" positive=6 negative=6 checks=", checks)
	quit(0 if passed else 1)
