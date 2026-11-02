extends "res://tests/gameplay/parallel_items_w02_berries_v1.gd"

# CAMP_002 W02: reutiliza prueba de batalla nativa YA verificada por IA6.
# No altera simulador, PlayerCollection, SaveV2, ni la lógica de consumo.
const FIXTURE_C002 := "res://tests/fixtures/parallel_items/w02_campaign_002.json"


func _initialize() -> void:
	capture = false
	call_deferred("_run_c002")
	create_timer(360.0).timeout.connect(func():
		if not done:
			push_error("CAMP_002_W02 timeout")
			quit(2))


func _run_c002() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_002"
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_C002))
	if not parsed is Dictionary:
		check("fixture C002 legible", false)
		_finish_c002([])
		return
	automation = parsed
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay ya disponible", Variants.apply(catalogs))
	check("formato nativo fijado", String(automation.format) == "gen9calvounifiedv1")
	check("alcance exclusivo de ITER_01",
		automation.item_ids == ["sitrus_berry", "lum_berry"]
		and automation.completed_iterations == [1] and automation.cases.size() == 4)
	check("modos de propiedad", automation.variants == ["active", "none", "reserve"])
	check("campo no ejecutado en este bloque", automation.field_scope == "NOT_TESTED_ITER_01")
	var expected_seed: Array = [23, 19, 29, 43]
	var seed_ok: bool = automation.seed is Array and automation.seed.size() == expected_seed.size()
	if seed_ok:
		for i in expected_seed.size():
			seed_ok = seed_ok and (automation.seed[i] is float or automation.seed[i] is int)
			seed_ok = seed_ok and float(automation.seed[i]) == float(expected_seed[i])
	check("semilla fija sin error de JSON float", seed_ok)
	var rows: Array = []
	for spec: Dictionary in automation.cases:
		current_case = String(spec.scenario)
		var initial: int = checks
		var failed: int = errors.size()
		check("ID pertenece al microbloque", automation.item_ids.has(String(spec.id)))
		check("objeto presente en catálogo", catalogs.item(StringName(spec.id)) != null)
		var observed := {}
		for mode: String in automation.variants:
			observed[mode] = await _ensayar(spec, mode)
		var valid: bool = observed.size() == 3
		for mode: String in automation.variants:
			valid = valid and observed[mode].get("valid", false)
		check("tres variantes nativas completadas", valid)
		if valid:
			_comparar(spec, observed)
			for mode: String in automation.variants:
				_verify_receipt(spec, mode, observed[mode])
		rows.append({"id": spec.id, "scenario": spec.scenario,
			"status": "PASS" if valid and errors.size() == failed else "FAIL",
			"checks": checks - initial, "observed": observed})
	_finish_c002(rows)


func _verify_receipt(spec: Dictionary, mode: String, observed: Dictionary) -> void:
	var path: String = destination + "/" + String(observed.evidence)
	var integrity: bool = FileAccess.file_exists(path)
	if integrity:
		integrity = FileAccess.get_sha256(path) == String(observed.sha256)
	check(mode + " SHA256 de evidencia auténtico", integrity)
	if not integrity:
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		check(mode + " JSON de evidencia válido", false)
		return
	check(mode + " frontera de motor nativo incluida",
		raw.get("before", {}) is Dictionary and raw.before.has("native"))
	check(mode + " espejo de estado nativo/propiedad",
		String(raw.get("scenario", "")) == String(spec.scenario)
		and String(raw.get("mode", "")) == mode
		and int(raw.get("native_hp", -1)) == int(observed.hp)
		and String(raw.get("native_status", "")) == String(observed.status)
		and bool(raw.get("native_consumed", false)) == bool(observed.consumed)
		and int(raw.get("stock_total", -1)) == int(observed.stock_total))
	check(mode + " restauración FLED y SaveV2",
		observed.restored and observed.settled_once and observed.save_v2)


func _finish_c002(rows: Array) -> void:
	var complete: bool = automation.get("cases", []).size() == 4 and rows.size() == 4
	var coverage: Dictionary = {}
	for item: String in ["sitrus_berry", "lum_berry"]:
		var relevant: Array = rows.filter(func(x: Dictionary): return String(x.id) == item)
		var positive: Array = automation.coverage_matrix[item].positive
		var negative: Array = automation.coverage_matrix[item].negative
		var names := {}
		var good: bool = relevant.size() == positive.size() + negative.size()
		for row: Dictionary in relevant:
			names[String(row.scenario)] = true
			good = good and row.status == "PASS"
		for scenario: String in positive + negative:
			good = good and names.has(scenario)
		check(item + " cobertura individual sin atribución ajena", good)
		complete = complete and good
		coverage[item] = {"status": "PASS" if good else "FAIL", "cases": relevant.size()}
	check("matriz C002 completa y exclusiva", complete)
	var report := {"schema_version": 1, "campaign": "CAMP_002",
		"family": "held_berry_revalidation", "status": "PASS" if complete and errors.is_empty() else "FAIL",
		"checks": checks, "errors": automation_errors, "cases": rows,
		"per_item": coverage, "field_scope": "NOT_TESTED_ITER_01",
		"full_item_certification": false, "gpu": false}
	var file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if file == null:
		push_error("C002 W02 no pudo escribir godot.json")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("PARALLEL_ITEMS_W02_CAMP002 ", report.status, " checks=", checks, " cases=", rows.size())
	quit(0 if report.status == "PASS" else 1)
