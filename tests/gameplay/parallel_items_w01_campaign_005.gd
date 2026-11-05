extends "res://tests/gameplay/parallel_items_w01_campaign_004.gd"

# IA1 W01 CAMPAÑA_005: pruebas nuevas de equipables por tipo.
# REUTILIZA el motor real y SaveV2 del runner CAMP004 certificado.
# No altera los 30 equipables antiguos ni sus pruebas.
const C005_FIXTURE := "res://tests/fixtures/parallel_items/w01_campaign_005.json"
const C005_PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W01/CAMP_005_PROGRESO.csv"
const C005_OUTPUT := "res://.godot/parallel_items/w01_campaign_005"
var c005_rows: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_w01_c005")
	create_timer(800.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP005 timeout nativo")
			quit(2))

func _progress_c005() -> Array:
	var file: FileAccess = FileAccess.open(C005_PROGRESS, FileAccess.READ)
	check("CSV de CAMP005 disponible", file != null)
	if file == null:
		return []
	var header: PackedStringArray = file.get_csv_line()
	check("CSV de CAMP005 conserva seis columnas", header.size() == 6 and header[0] == "bloque")
	var result: Array = []
	while not file.eof_reached():
		var cols: PackedStringArray = file.get_csv_line()
		if cols.size() == 1 and cols[0].is_empty():
			continue
		check("Progreso W01 tiene seis columnas", cols.size() == 6)
		if cols.size() == 6:
			result.append({"block": String(cols[0]), "ids": String(cols[1]),
				"status": String(cols[2])})
	file.close()
	return result

func _run_w01_c005() -> void:
	destination = C005_OUTPUT
	DirAccess.make_dir_recursive_absolute(destination)
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(C005_FIXTURE))
	check("Fixture JSON válido", value is Dictionary)
	if not value is Dictionary:
		quit(2)
		return
	var fixture: Dictionary = value
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Variantes regionales disponibles", Variants.apply(catalogs))
	check("Identidad W01 y formato nativo", fixture.get("schema_version") == 1
		and fixture.get("worker") == "W01" and fixture.get("campaign") == "CAMP_005"
		and fixture.get("kind") == "NEW_IDS" and fixture.get("format") == "gen9calvounifiedv1")
	check("Tres modalidades sin omisiones", fixture.get("variants") == ["active", "none", "reserve"])
	var progress: Array = _progress_c005()
	check("Bloques 01, 02, 03 y 04 de CAMPAÑA_005 autorizados", progress.size() == 4)
	if progress.size() != 4:
		quit(2)
		return
	check("Fila 01 autorizada por IA6", String(progress[0].block) == "01"
		and String(progress[0].ids) == "black_glasses;dragon_fang;hard_stone")
	check("Fila 02 autorizada por IA6", String(progress[1].block) == "02"
		and String(progress[1].ids) == "miracle_seed;mystic_water;never_melt_ice")
	check("Fila 03 autorizada por IA6", String(progress[2].block) == "03"
		and String(progress[2].ids) == "poison_barb;sharp_beak;silk_scarf")
	check("Fila 04 autorizada por IA6", String(progress[3].block) == "04"
		and String(progress[3].ids) == "silver_powder;soft_sand;spell_tag")
	var stages: Array = fixture.get("blocks", [])
	check("Fixture contiene cuatro bloques reales", stages.size() == 4)
	if stages.size() != 4:
		quit(2)
		return
	check("Los tres ID del bloque 01 son exactos",
		stages[0].get("ids", []) == ["black_glasses", "dragon_fang", "hard_stone"])
	check("Los tres ID del bloque 02 son exactos",
		stages[1].get("ids", []) == ["miracle_seed", "mystic_water", "never_melt_ice"])
	check("Los tres ID del bloque 03 son exactos",
		stages[2].get("ids", []) == ["poison_barb", "sharp_beak", "silk_scarf"])
	check("Los tres ID del bloque 04 son exactos",
		stages[3].get("ids", []) == ["silver_powder", "soft_sand", "spell_tag"])
	var cases: Array = fixture.get("cases", [])
	check("Treinta y seis escenarios funcionales autorizados", cases.size() == 36)
	var names: Array = []
	for row: Dictionary in cases:
		check("Escenario pertenece a su bloque oficial",
			(String(row.block) == "01" and stages[0].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "02" and stages[1].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "03" and stages[2].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "04" and stages[3].get("ids", []).has(String(row.item_id))))
		check("ID único del escenario", not names.has(String(row.id)))
		names.append(String(row.id))
		for seed_value: Variant in row.seeds:
			check("Semilla entera positiva", (seed_value is int or seed_value is float)
				and float(seed_value) == float(int(seed_value))
				and int(seed_value) >= 1 and int(seed_value) <= 65535)
			current_case = String(row.id) + "/" + str(int(seed_value))
			var previous_errors: int = errors.size()
			var previous_checks: int = checks
			var observed: Dictionary = {}
			# Los carriles no comparten sesión ni propietario y conservan SaveV2.
			# Se reutiliza la concurrencia verificada de CAMP004.
			for mode: String in ["active", "none", "reserve"]:
				call_deferred("_w01_c004_probe_lane", row, int(seed_value), mode, observed)
			while observed.size() < 3:
				await process_frame
			_compare_c005(row, observed)
			c005_rows.append({"block": String(row.block), "id": String(row.id),
				"item_id": String(row.item_id), "seed": int(seed_value),
				"checks": checks - previous_checks,
				"status": "PASS" if errors.size() == previous_errors else "FAIL",
				"observed": observed})
	check("Cuarenta y ocho pares caso-semilla reales", c005_rows.size() == 48)
	for item_id: String in ["black_glasses", "dragon_fang", "hard_stone",
		"miracle_seed", "mystic_water", "never_melt_ice",
		"poison_barb", "sharp_beak", "silk_scarf",
		"silver_powder", "soft_sand", "spell_tag"]:
		check("Tres contextos distintos para cada ID " + item_id, cases.filter(
			func(c): return String(c.item_id) == item_id).size() == 3)
	var report: Dictionary = {"schema_version": 1, "campaign": "CAMP_005",
		"worker": "W01", "blocks": progress.size(), "checks": checks,
		"cases": c005_rows, "errors": errors,
		"limits": ["Godot headless no prueba GPU/UI",
			"No afirma integración en main/V28 ni mapa",
			"Requiere regresión CAMP004 por workflow para certificar bloque 01"]}
	var output: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Informe nativo CAMP005 puede escribirse", output != null)
	if output != null:
		output.store_string(JSON.stringify(report, "  "))
		output.close()
	done = true
	if errors.is_empty():
		print("CAMP005_W01_GODOT PASS blocks=", progress.size(), " checks=", checks)
		quit(0)
	else:
		print("CAMP005_W01_GODOT FAIL blocks=", progress.size(),
			" checks=", checks, " errors=", errors.size())
		quit(1)

func _compare_c005(row: Dictionary, observed: Dictionary) -> void:
	check("Tres controles reales de equipamiento", observed.has_all(["active", "none", "reserve"]))
	if not observed.has_all(["active", "none", "reserve"]):
		return
	for mode: String in ["active", "none", "reserve"]:
		var x: Dictionary = observed[mode]
		check("Modo " + mode + " batalla funcional y restauración SaveV2",
			x.get("valid", false) and x.get("restored", false)
			and x.get("owner_unchanged", false) and x.get("save_equal", false))
		if not x.get("valid", false):
			return
		check("Propietario exclusivo del equipamiento " + mode,
			bool(x.start.own_has_item) == (mode == "active")
			and bool(x.start.reserve_has_item) == (mode == "reserve"))
		check("Reserva sin activación ni consumo " + mode,
			not bool(x.after.reserve_consumed))
		check("Conservación física de dos unidades " + mode,
			int(x.physical_units) == 2)
	var a: Dictionary = observed.active
	var n: Dictionary = observed.none
	var r: Dictionary = observed.reserve
	var native_id: String = String(row.item_id).replace("_", "")
	check("El objeto existe en el portador activo sin consumo",
		String(a.after.native_item) == native_id and not a.after.own_consumed)
	check("El objeto en reserva no altera al portador",
		not bool(n.after.own_consumed) and not bool(r.after.own_consumed)
		and n.physical_units == 2 and r.physical_units == 2)
	match String(row.op):
		"matching_type_boost":
			var expected_moves: Dictionary = {"black_glasses": "dark_pulse",
				"dragon_fang": "dragon_pulse", "hard_stone": "smack_down",
				"miracle_seed": "energy_ball", "mystic_water": "surf",
				"never_melt_ice": "ice_beam", "poison_barb": "sludge_bomb",
				"sharp_beak": "aerial_ace", "silk_scarf": "tackle",
				"silver_powder": "bug_buzz", "soft_sand": "earth_power",
				"spell_tag": "shadow_ball"}
			check("Tipo del ataque positivo autorizado",
				String(row.own_move) == String(expected_moves.get(String(row.item_id), "")))
			check("Potenciador de tipo aumenta daño real solo al portador",
				a.damage > n.damage and n.damage > 0 and n.damage == r.damage)
			check("Sin equipo y con reserva, resultado idéntico", n.damage == r.damage)
		"nonmatching_control":
			check("Ataque de tipo distinto al objeto causa daño real",
				String(row.own_move) == ("water_gun" if String(row.item_id) == "silk_scarf" else "tackle")
				and a.damage > 0)
			check("Ataque de tipo diferente no recibe potencia",
				a.damage == n.damage and n.damage == r.damage)
		"status_control":
			check("Movimiento de estado no inflige daño",
				String(row.own_move) == "reflect"
				and a.damage == 0 and n.damage == 0 and r.damage == 0)
			check("Movimiento de estado no consume objeto",
				not a.after.own_consumed and a.physical_units == 2)
		_:
			check("Operación no autorizada", false)
