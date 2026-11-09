extends "res://tests/gameplay/parallel_items_w01_campaign_004.gd"

# IA1 W01 CAMPAÑA_005: pruebas nuevas de equipables por tipo.
# REUTILIZA el motor real y SaveV2 del runner CAMP004 certificado.
# No altera los 30 equipables antiguos ni sus pruebas.
const C005_FIXTURE := "res://tests/fixtures/parallel_items/w01_campaign_005.json"
const C005_PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W01/CAMP_005_PROGRESO.csv"
const C005_OUTPUT := "res://.godot/parallel_items/w01_campaign_005"
var c005_rows: Array = []
var c005_king_rock_activated: int = 0
var c005_king_rock_not_activated: int = 0
var c005_razor_claw_exclusive: int = 0
var c005_razor_claw_critical: int = 0
var c005_razor_fang_activated: int = 0
var c005_razor_fang_not_activated: int = 0
var c005_lax_missed: int = 0
var c005_lax_hit: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_w01_c005")
	create_timer(1260.0).timeout.connect(func():
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
	check("Bloques 01 a 10 de CAMPAÑA_005 autorizados", progress.size() == 10)
	if progress.size() != 10:
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
	check("Fila 05 autorizada por IA6", String(progress[4].block) == "05"
		and String(progress[4].ids) == "twisted_spoon;metal_coat;kings_rock")
	check("Fila 06 autorizada por IA6", String(progress[5].block) == "06"
		and String(progress[5].ids) == "deep_sea_scale;deep_sea_tooth;metal_powder")
	check("Fila 07 autorizada por IA6", String(progress[6].block) == "07"
		and String(progress[6].ids) == "quick_powder;razor_claw;razor_fang")
	check("Fila 08 autorizada por IA6", String(progress[7].block) == "08"
		and String(progress[7].ids) == "odd_incense;rock_incense;rose_incense")
	check("Fila 09 autorizada por IA6", String(progress[8].block) == "09"
		and String(progress[8].ids) == "sea_incense;full_incense;lax_incense")
	check("Fila 10 autorizada por IA6", String(progress[9].block) == "10"
		and String(progress[9].ids) == "normal_gem;fire_gem;water_gem")
	var stages: Array = fixture.get("blocks", [])
	check("Fixture contiene diez bloques reales", stages.size() == 10)
	if stages.size() != 10:
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
	check("Los tres ID del bloque 05 son exactos",
		stages[4].get("ids", []) == ["twisted_spoon", "metal_coat", "kings_rock"])
	check("Los tres ID del bloque 06 son exactos",
		stages[5].get("ids", []) == ["deep_sea_scale", "deep_sea_tooth", "metal_powder"])
	check("Los tres ID del bloque 07 son exactos",
		stages[6].get("ids", []) == ["quick_powder", "razor_claw", "razor_fang"])
	check("Los tres ID del bloque 08 son exactos",
		stages[7].get("ids", []) == ["odd_incense", "rock_incense", "rose_incense"])
	check("Los tres ID del bloque 09 son exactos",
		stages[8].get("ids", []) == ["sea_incense", "full_incense", "lax_incense"])
	check("Los tres ID del bloque 10 son exactos",
		stages[9].get("ids", []) == ["normal_gem", "fire_gem", "water_gem"])
	var cases: Array = fixture.get("cases", [])
	check("Noventa escenarios funcionales autorizados", cases.size() == 90)
	var names: Array = []
	for row: Dictionary in cases:
		check("Escenario pertenece a su bloque oficial",
			(String(row.block) == "01" and stages[0].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "02" and stages[1].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "03" and stages[2].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "04" and stages[3].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "05" and stages[4].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "06" and stages[5].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "07" and stages[6].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "08" and stages[7].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "09" and stages[8].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "10" and stages[9].get("ids", []).has(String(row.item_id))))
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
	check("Doscientos setenta y dos pares caso-semilla reales", c005_rows.size() == 272)
	check("Incienso Suave: fallo real de ataque por RNG", c005_lax_missed > 0)
	check("Incienso Suave: acierto natural de ataque por RNG", c005_lax_hit > 0)
	check("Garra Afilada registra crítico real nativo", c005_razor_claw_critical > 0)
	check("Garra Afilada aporta crítico exclusivo del portador", c005_razor_claw_exclusive > 0)
	check("Colmillo Agudo registra retroceso real nativo", c005_razor_fang_activated > 0)
	check("Colmillo Agudo registra rama RNG sin retroceso", c005_razor_fang_not_activated > 0)
	check("Roca del Rey: retroceso real observado con RNG", c005_king_rock_activated > 0)
	check("Roca del Rey: rama RNG sin retroceso observada", c005_king_rock_not_activated > 0)
	for item_id: String in ["black_glasses", "dragon_fang", "hard_stone",
		"miracle_seed", "mystic_water", "never_melt_ice",
		"poison_barb", "sharp_beak", "silk_scarf",
		"silver_powder", "soft_sand", "spell_tag",
		"twisted_spoon", "metal_coat", "kings_rock",
		"deep_sea_scale", "deep_sea_tooth", "metal_powder",
		"quick_powder", "razor_claw", "razor_fang",
		"odd_incense", "rock_incense", "rose_incense",
		"sea_incense", "full_incense", "lax_incense",
		"normal_gem", "fire_gem", "water_gem"]:
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
		var gem_trigger: bool = String(row.op) == "gem_matching" and mode == "active"
		check("Cantidad física correcta y consumo único " + mode,
			int(x.physical_units) == (1 if gem_trigger else 2))
	var a: Dictionary = observed.active
	var n: Dictionary = observed.none
	var r: Dictionary = observed.reserve
	var native_id: String = String(row.item_id).replace("_", "")
	check("El objeto conserva su identidad nativa según activación",
		(String(a.after.native_item).is_empty() and bool(a.after.own_consumed))
		if String(row.op) == "gem_matching" else
		(String(a.after.native_item) == native_id and not bool(a.after.own_consumed)))
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
				"spell_tag": "shadow_ball", "twisted_spoon": "psychic",
				"metal_coat": "flash_cannon",
				"odd_incense": "confusion", "rock_incense": "smack_down",
				"rose_incense": "energy_ball", "sea_incense": "water_gun"}
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
		"full_incense_last":
			check("Incienso Lento: Mew veloz actúa último a igual prioridad",
				String(a.after.first_move_actor) == "foe"
				and String(n.after.first_move_actor) == "own"
				and String(r.after.first_move_actor) == "own")
			check("Incienso Lento sin consumo ni movimiento ofensivo propio",
				a.damage == 0 and n.damage == 0 and r.damage == 0)
		"full_incense_priority":
			check("Ataque Rápido +1 conserva prioridad aun con Incienso Lento",
				String(a.after.first_move_actor) == "own"
				and String(n.after.first_move_actor) == "own"
				and String(r.after.first_move_actor) == "own")
			check("Incienso Lento no altera daño de Ataque Rápido",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		"full_incense_status":
			check("Incienso Lento retrasa Reflejo también frente a Amnesia",
				String(a.after.first_move_actor) == "foe"
				and String(n.after.first_move_actor) == "own"
				and String(r.after.first_move_actor) == "own")
			check("Controles de estado sin daño o consumo de Incienso Lento",
				a.damage == 0 and n.damage == 0 and r.damage == 0)
		"lax_incense_accuracy":
			check("Incienso Suave: Placaje no falla en ausencia ni en reserva",
				not bool(n.after.get("foe_missed", false))
				and not bool(r.after.get("foe_missed", false)))
			var a_loss: int = int(a.start.hp) - int(a.after.hp)
			var n_loss: int = int(n.start.hp) - int(n.after.hp)
			var r_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Incienso Suave no incrementa daño; controles iguales",
				n_loss > 0 and a_loss <= n_loss and n_loss == r_loss)
			if bool(a.after.get("foe_missed", false)):
				check("Incienso Suave: fallo nativo evita daño positivo",
					a_loss == 0 and n_loss > 0)
				c005_lax_missed += 1
			else:
				check("Incienso Suave: sin fallo no cambia el daño recibido",
					a_loss > 0 and a_loss == n_loss)
				c005_lax_hit += 1
		"lax_incense_never_miss":
			check("Incienso Suave no evita Golpe Aéreo infalible",
				not a.after.get("foe_missed", false)
				and not n.after.get("foe_missed", false)
				and not r.after.get("foe_missed", false))
			check("Golpe Aéreo causa daño real sin reducción artificial",
				int(a.after.hp) < int(a.start.hp)
				and int(a.after.hp) == int(n.after.hp)
				and int(n.after.hp) == int(r.after.hp))
		"lax_incense_status":
			check("Incienso Suave no induce fallo a Amnesia",
				not a.after.get("foe_missed", false)
				and not n.after.get("foe_missed", false)
				and not r.after.get("foe_missed", false))
			check("Ninguno recibe daño ni consume objeto ante Amnesia",
				a.after.hp == a.start.hp and n.after.hp == n.start.hp
				and r.after.hp == r.start.hp)
		"gem_matching":
			var move_by_gem: Dictionary = {"normal_gem": "tackle",
				"fire_gem": "fire_punch", "water_gem": "surf"}
			check("Gema: ataque del tipo correcto",
				String(row.own_move) == String(move_by_gem.get(String(row.item_id), "")))
			check("Gema: primer golpe potencia daño solo activa",
				a.damage > n.damage and n.damage > 0 and n.damage == r.damage)
			check("Gema: objeto gastado exactamente una vez por portador",
				bool(a.after.own_consumed) and a.physical_units == 1
				and not n.after.own_consumed and not r.after.reserve_consumed
				and n.physical_units == 2 and r.physical_units == 2)
			check("Gema: consumida primero y no reactivada en segundo golpe",
				bool(a.get("gem_first_consumed", false))
				and bool(a.get("gem_second_consumed", false))
				and String(a.get("gem_first_native_item", "")).is_empty()
				and String(a.get("gem_second_native_item", "")).is_empty()
				and int(a.get("gem_first_units", 0)) == 1
				and int(a.get("gem_second_units", 0)) == 1)
			check("Gema: dos ataques legítimos y SaveV2 en ambos puntos",
				int(a.get("second_damage", 0)) > 0
				and bool(a.get("gem_mid_save", false))
				and bool(a.get("gem_final_save", false))
				and bool(n.get("gem_mid_save", false))
				and bool(r.get("gem_final_save", false)))
		"gem_nonmatching":
			var wrong_by_gem: Dictionary = {"normal_gem": "water_gun",
				"fire_gem": "tackle", "water_gem": "tackle"}
			check("Gema: tipo equivocado no produce consumo",
				String(row.own_move) == String(wrong_by_gem.get(String(row.item_id), ""))
				and not a.after.own_consumed and a.physical_units == 2)
			check("Gema: daño del tipo equivocado idéntico a controles",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		"gem_status":
			var status_by_gem: Dictionary = {"normal_gem": "swords_dance",
				"fire_gem": "sunny_day", "water_gem": "rain_dance"}
			check("Gema: prueba estado del mismo tipo",
				String(row.own_move) == String(status_by_gem.get(String(row.item_id), "")))
			check("Gema: estado de su tipo no consume ni daña",
				a.damage == 0 and n.damage == 0 and r.damage == 0
				and not a.after.own_consumed and a.physical_units == 2)
		"kings_rock_flinch":
			check("Roca del Rey no potencia daño: Placaje daña al objetivo",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
			check("Roca del Rey no activa en ausencia o reserva",
				not n.get("flinched", false) and not r.get("flinched", false))
			if bool(a.get("flinched", false)):
				c005_king_rock_activated += 1
			else:
				c005_king_rock_not_activated += 1
		"kings_rock_immune":
			check("Roca del Rey no permite daño de Normal a Gengar",
				a.damage == 0 and n.damage == 0 and r.damage == 0)
			check("Roca del Rey no retrocede al objetivo inmune",
				not a.get("flinched", false) and not n.get("flinched", false)
				and not r.get("flinched", false))
		"kings_rock_status":
			check("Roca del Rey no retrocede ni causa daño con Reflejo",
				a.damage == 0 and n.damage == 0 and r.damage == 0
				and not a.get("flinched", false) and not n.get("flinched", false)
				and not r.get("flinched", false))
		"quick_powder_untransformed":
			check("Polvo Veloz: solo Ditto equipado adelanta a Gyarados en turno real",
				String(a.after.first_move_actor) == "own"
				and String(n.after.first_move_actor) == "foe"
				and String(r.after.first_move_actor) == "foe")
			check("Polvo Veloz no potencia Reflejo ni consume objeto",
				a.damage == 0 and n.damage == 0 and r.damage == 0
				and not a.after.own_consumed)
		"quick_powder_wrong_species":
			check("Polvo Veloz no altera orden en Mew ajeno a Ditto",
				a.after.first_move_actor == n.after.first_move_actor
				and n.after.first_move_actor == r.after.first_move_actor)
			check("Polvo Veloz no altera daño ni consume en portador equivocado",
				a.damage == 0 and n.damage == 0 and r.damage == 0)
		"quick_powder_transformed":
			check("Polvo Veloz: Transformación real restaurada en los tres modos",
				bool(a.after.get("native_transform_event", false))
				and bool(n.after.get("native_transform_event", false))
				and bool(r.after.get("native_transform_event", false)))
			check("Polvo Veloz no se consume al transformar; velocidad nativa la verifica B07",
				not a.after.own_consumed and a.physical_units == 2
				and n.physical_units == 2 and r.physical_units == 2)
		"razor_claw_focus_critical":
			check("Garra Afilada: Foco Energía y Placaje causan crítico nativo del portador",
				a.critical and a.damage > 0 and a.damage >= n.damage)
			check("Garra Afilada: controles sin objeto y reserva son idénticos",
				n.critical == r.critical and n.damage == r.damage)
			if a.critical:
				c005_razor_claw_critical += 1
			if a.critical and not n.critical and not r.critical:
				c005_razor_claw_exclusive += 1
		"razor_claw_immune":
			check("Garra Afilada no permite crítico ni daño de Placaje a Gengar",
				a.damage == 0 and n.damage == 0 and r.damage == 0
				and not a.critical and not n.critical and not r.critical)
		"razor_claw_status":
			check("Garra Afilada no produce crítico en Reflejo",
				a.damage == 0 and n.damage == 0 and r.damage == 0
				and not a.critical and not n.critical and not r.critical)
		"razor_fang_flinch":
			check("Colmillo Agudo no aumenta daño real de Placaje",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
			check("Colmillo Agudo solo puede hacer retroceder en portador activo",
				not n.get("flinched", false) and not r.get("flinched", false))
			if bool(a.get("flinched", false)):
				c005_razor_fang_activated += 1
			else:
				c005_razor_fang_not_activated += 1
		"razor_fang_immune":
			check("Colmillo Agudo no causa daño ni retroceso a Gengar inmune",
				a.damage == 0 and n.damage == 0 and r.damage == 0
				and not a.get("flinched", false) and not n.get("flinched", false)
				and not r.get("flinched", false))
		"razor_fang_status":
			check("Colmillo Agudo no causa daño ni retroceso con Reflejo",
				a.damage == 0 and n.damage == 0 and r.damage == 0
				and not a.get("flinched", false) and not n.get("flinched", false)
				and not r.get("flinched", false))
		"holder_special_defense":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var no_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Escama Marina Clamperl: menos daño especial realmente recibido",
				no_loss > 0 and active_loss >= 0 and active_loss < no_loss)
			check("Escama Marina: sin objeto y reserva reciben el mismo daño",
				no_loss == reserve_loss)
		"physical_damage_control":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var no_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Escama Marina no reduce daño físico",
				no_loss > 0 and active_loss == no_loss and no_loss == reserve_loss)
		"wrong_species_defense":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var no_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Escama Marina solo protege a Clamperl, nunca a Mew",
				no_loss > 0 and active_loss == no_loss and no_loss == reserve_loss)
		"holder_special_attack":
			check("Diente Marino Clamperl duplica potencia estadística especial real",
				a.damage > n.damage and n.damage > 0 and n.damage == r.damage)
		"physical_attack_control":
			check("Diente Marino no aumenta daño físico",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		"wrong_species_attack":
			check("Diente Marino no aumenta daño especial de Mew",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		"holder_physical_defense":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var no_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Polvo Metálico Ditto sin transformar reduce daño físico real",
				no_loss > 0 and active_loss >= 0 and active_loss < no_loss)
			check("Polvo Metálico en reserva no protege al portador",
				no_loss == reserve_loss)
		"special_damage_control":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var no_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Polvo Metálico no reduce daño especial",
				no_loss > 0 and active_loss == no_loss and no_loss == reserve_loss)
		"transformed_no_boost":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var no_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Ditto ejecutó Transformación realmente en tres carriles",
				bool(a.after.get("native_transform_event", false))
				and bool(n.after.get("native_transform_event", false))
				and bool(r.after.get("native_transform_event", false)))
			check("Polvo Metálico deja de proteger a Ditto transformado",
				no_loss > 0 and active_loss == no_loss and no_loss == reserve_loss)
		"status_control":
			check("Movimiento de estado no inflige daño",
				String(row.own_move) == "reflect"
				and a.damage == 0 and n.damage == 0 and r.damage == 0)
			check("Movimiento de estado no consume objeto",
				not a.after.own_consumed and a.physical_units == 2)
		_:
			check("Operación no autorizada", false)

# Solo en CAMP005 se añade evidencia de Transformación desde el log de motor.
# El runner histórico CAMP004 no se modifica.
func _frame_c003(session: RefCounted, id: StringName) -> Dictionary:
	var frame: Dictionary = super._frame_c003(session, id)
	var log: Array = session._checkpoint.get("snapshot", {}).get("native", {}).get("log", [])
	var transform_seen: bool = false
	var foe_missed: bool = false
	for entry: String in log:
		if entry.begins_with("|-transform|p1a:"):
			transform_seen = true
		if entry.begins_with("|-miss|p2a:"):
			foe_missed = true
	frame["native_transform_event"] = transform_seen
	frame["foe_missed"] = foe_missed
	return frame

# En W01 la Roca del Rey se comprueba por retroceso observado en log nativo.
# El harness original de CAMPAÑA_004 se mantiene intacto para las 4 filas previas.
func _probe_w01_c004(row: Dictionary, seed: int, mode: String) -> Dictionary:
	if String(row.op) == "gem_matching":
		return await _probe_c005_gem_matching(row, seed, mode)
	if String(row.op) in ["transformed_no_boost", "quick_powder_transformed"] and String(row.item_id) in ["metal_powder", "quick_powder"]:
		return await _probe_c005_transformed_stable(row, seed, mode)
	if String(row.item_id) in ["kings_rock", "razor_fang"]:
		return await _probe_c005_king_rock(row, seed, mode)
	return await super._probe_w01_c004(row, seed, mode)

func _probe_c005_king_rock(row: Dictionary, seed: int, mode: String) -> Dictionary:
	automation = {"actor_species": String(row.actor_species), "level": 100,
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4],
		"physical_move": String(row.own_move), "special_move": "water_gun",
		"speed_target": String(row.foe_species), "damage_target": String(row.foe_species)}
	var prepared: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	actor.moveset.clear()
	actor.move_ids.clear()
	check(mode + " Roca del Rey movimiento real", actor.add_move(StringName(row.own_move), catalogs))
	var second: String = "tackle" if String(row.own_move) == "reflect" else "reflect"
	check(mode + " Roca del Rey movimiento de control", actor.add_move(StringName(second), catalogs))
	prepared.foe = _mon(StringName(row.foe_species), 100, &"foe", [String(row.foe_move)])
	var id := StringName(row.item_id)
	var original_owner: String = JSON.stringify(_owner_data(owner))
	check(mode + " Roca del Rey dos unidades iniciales", _units(owner, id) == 2)
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check(mode + " Roca del Rey batalla real iniciada", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var before: Dictionary = _frame_c003(session, id)
	check(mode + " Roca del Rey estado inicial", before.valid)
	var command: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " Roca del Rey movimiento aceptado", command.get("accepted", false))
	if not command.get("accepted", false):
		await session.close()
		return {"valid": false}
	var after: Dictionary = _frame_c003(session, id)
	check(mode + " Roca del Rey estado final", after.valid)
	var log: Array = session._checkpoint.get("snapshot", {}).get("native", {}).get("log", [])
	var flinched: bool = false
	for entry: String in log:
		if entry.contains("|flinch") and entry.contains("p2a:"):
			flinched = true
	check(mode + " retroceso solo si Tackle golpeó antes",
		not flinched or (String(row.op) in ["kings_rock_flinch", "razor_fang_flinch"]
			and int(after.foe_hp) < int(before.foe_hp)))
	if String(row.op) in ["kings_rock_flinch", "razor_fang_flinch"]:
		check(mode + " Mew mueve primero frente a Snorlax",
			String(after.first_move_actor) == "own")
	var before_restore: Dictionary = session.snapshot()
	var frozen: bool = JSON.stringify(_owner_data(owner)) == original_owner
	check(mode + " Roca del Rey propietario intacto", frozen)
	var physical: int = owner.inventory.quantity(id)
	for creature: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if creature.held_item_id == id and not creature.held_item_consumed:
			physical += 1
	var key: String = String(row.id) + "_" + str(seed) + "_" + mode
	var persisted: Dictionary = await _restore_probe(session, owner, key + "_savev2", mode + " Roca del Rey SaveV2")
	if not persisted.get("valid", false):
		return {"valid": false}
	session = persisted.session
	owner = persisted.owner
	var restored: Dictionary = _frame_c003(session, id)
	check(mode + " Roca del Rey proyección SaveV2 idéntica", restored == after)
	check(mode + " Roca del Rey snapshot SaveV2 idéntico", session.snapshot() == before_restore)
	check(mode + " Roca del Rey dueño SaveV2 idéntico", JSON.stringify(_owner_data(owner)) == original_owner)
	var restored_physical: int = owner.inventory.quantity(id)
	for creature: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if creature.held_item_id == id and not creature.held_item_consumed:
			restored_physical += 1
	check(mode + " Roca del Rey unidades SaveV2 iguales", restored_physical == physical)
	await session.close()
	return {"valid": true, "start": before, "after": after,
		"damage": int(before.foe_hp) - int(after.foe_hp), "flinched": flinched,
		"physical_units": physical, "restored": restored == after,
		"owner_unchanged": frozen, "save_equal": restored_physical == physical}

# El estado TRANSFORMADO se observa y compara en el primer turno. El SaveV2
# compartido NO restaura un checkpoint con Transform activo (CI #42233251445);
# W01 NO modifica SaveV2: primero realiza el cambio real de Pokémon para
# estabilizar la batalla y solo después ejecuta la restauración. La limitación
# del snapshot intermedio queda documentada para IA6, no se declara corregida.
func _probe_c005_transformed_stable(row: Dictionary, seed: int, mode: String) -> Dictionary:
	automation = {"actor_species": "ditto", "level": 100,
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4],
		"physical_move": "transform", "special_move": "water_gun",
		"speed_target": "snorlax", "damage_target": "snorlax"}
	var prepared: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	actor.moveset.clear()
	actor.move_ids.clear()
	check(mode + " Ditto dispone de Transformación", actor.add_move(&"transform", catalogs))
	check(mode + " Ditto conserva movimiento de control", actor.add_move(&"reflect", catalogs))
	prepared.foe = _mon(&"snorlax", 100, &"foe", ["tackle"])
	var id: StringName = StringName(row.item_id)
	var frozen: String = JSON.stringify(_owner_data(owner))
	check(mode + " Polvo Metálico mantiene dos unidades", _units(owner, id) == 2)
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check(mode + " Ditto inicia combate real", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var before: Dictionary = _frame_c003(session, id)
	check(mode + " Ditto no está transformado inicialmente",
		before.valid and not bool(before.get("native_transform_event", false)))
	var transform_action: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " Transformación real aceptada", transform_action.get("accepted", false))
	if not transform_action.get("accepted", false):
		await session.close()
		return {"valid": false}
	var transformed: Dictionary = _frame_c003(session, id)
	check(mode + " transformación confirmada en log nativo",
		transformed.valid and bool(transformed.get("native_transform_event", false)))
	check(mode + " Polvo Metálico sin consumo tras transformar",
		not bool(transformed.own_consumed))
	var damage_taken: int = int(before.hp) - int(transformed.hp)
	check(mode + " Snorlax inflige daño en turno transformado", damage_taken > 0)
	# Gate IA6: restaurar el snapshot INTERMEDIO con Ditto transformado,
	# antes de cambiar a reserva. No sustituir este control por guardado tardío.
	var transformed_checkpoint: Dictionary = session.snapshot()
	var mid_key: String = String(row.id) + "_" + str(seed) + "_" + mode + "_transformed"
	var mid: Dictionary = await _restore_probe(
		session, owner, mid_key + "_savev2", mode + " Ditto transformado SaveV2")
	if not mid.get("valid", false):
		return {"valid": false}
	session = mid.session
	owner = mid.owner
	var transformed_restored: Dictionary = _frame_c003(session, id)
	check(mode + " estado nativo Transformado idéntico tras SaveV2",
		transformed_restored == transformed and session.snapshot() == transformed_checkpoint)
	check(mode + " dueño y equipos conservados tras SaveV2 transformado",
		JSON.stringify(_owner_data(owner)) == frozen)
	var restored_roster: Array = session._checkpoint.get("roster", [])
	check(mode + " Ditto sigue transformado tras restaurar, sin cambio de especie original",
		not restored_roster.is_empty() and restored_roster[0].get("pokemon", []).size() == 2
		and bool(restored_roster[0].pokemon[0].get("transformed", false))
		and String(restored_roster[0].pokemon[0].get("species_id", "")) == "snorlax")
	# El daño real del primer turno queda congelado; el cambio siguiente
	# verifica de forma adicional que el backend acepta una orden legal.
	var choice: String = _switch_choice(session, &"reserve")
	var switch_action: Dictionary = await session.submit(choice, session.revision)
	if not switch_action.get("accepted", false):
		# Diagnóstico W01 de contrato, sin modificar el backend:
		# la evidencia debe ofrecer el motivo devuelto por submit(), no una
		# inferencia de que Transformación prohíbe el cambio.
		var request_data: Dictionary = session._checkpoint.get("views", {}).get("p1", {}).get("request", {})
		var state_roster: Array = session._checkpoint.get("roster", [])
		var roster_p1: Dictionary = state_roster[0] if not state_roster.is_empty() else {}
		var proof: Dictionary = {
			"case": String(row.id), "seed": seed, "mode": mode, "choice": choice,
			"error": String(switch_action.get("error", "")),
			"backend_last_error": String(session.last_error),
			"phase": String(session.phase()),
			"revision": session.revision,
			"request_wait": request_data.get("wait", null),
			"request_force_switch": request_data.get("forceSwitch", null),
			"request_side": request_data.get("side", {}),
			"roster_active_id": roster_p1.get("active_id", ""),
			"roster_pokemon": roster_p1.get("pokemon", [])
		}
		print("W01_CAMP005_BLOCK06_SWITCH_DIAGNOSTIC ", JSON.stringify(proof))
	check(mode + " cambio real a reserva tras Transformación",
		switch_action.get("accepted", false))
	if not switch_action.get("accepted", false):
		await session.close()
		return {"valid": false}
	var stable: Dictionary = _frame_c003(session, id)
	check(mode + " checkpoint estable con Ditto transformado fuera del campo",
		stable.valid and String(stable.active_id) == "reserve")
	var stable_snapshot: Dictionary = session.snapshot()
	check(mode + " dueño intacto antes del asentamiento",
		JSON.stringify(_owner_data(owner)) == frozen)
	var physical: int = owner.inventory.quantity(id)
	for creature: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if creature.held_item_id == id and not creature.held_item_consumed:
			physical += 1
	check(mode + " dos unidades físicas conservadas", physical == 2)
	var key: String = String(row.id) + "_" + str(seed) + "_" + mode + "_stable"
	var persisted: Dictionary = await _restore_probe(
		session, owner, key + "_savev2", mode + " Ditto SaveV2 tras cambio estable")
	if not persisted.get("valid", false):
		return {"valid": false}
	session = persisted.session
	owner = persisted.owner
	var stable_restored: Dictionary = _frame_c003(session, id)
	check(mode + " Ditto estado estable idéntico al restaurar",
		stable_restored == stable and session.snapshot() == stable_snapshot)
	check(mode + " Ditto dueño igual después de guardar",
		JSON.stringify(_owner_data(owner)) == frozen)
	var physical_restored: int = owner.inventory.quantity(id)
	for creature: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if creature.held_item_id == id and not creature.held_item_consumed:
			physical_restored += 1
	check(mode + " inventario y equipos iguales tras SaveV2", physical_restored == physical)
	await session.close()
	return {"valid": true, "start": before, "after": transformed,
		"damage": int(before.foe_hp) - int(transformed.foe_hp),
		"physical_units": physical, "restored": stable_restored == stable,
		"owner_unchanged": JSON.stringify(_owner_data(owner)) == frozen,
		"save_equal": physical_restored == physical, "save_scope": "transform_and_post_switch_stable"}

# B10: la gema se verifica en un doble turno con SaveV2 ENTRE los golpes.
# No modifica ni simula la autoridad nativa de consumo de objetos.
func _probe_c005_gem_matching(row: Dictionary, seed: int, mode: String) -> Dictionary:
	automation = {"actor_species": "mew", "level": 100,
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4],
		"physical_move": String(row.own_move), "special_move": "water_gun",
		"speed_target": "mew", "damage_target": "mew"}
	var prepared: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	actor.moveset.clear()
	actor.move_ids.clear()
	check(mode + " B10 ataque del tipo indicado existe",
		actor.add_move(StringName(row.own_move), catalogs))
	check(mode + " B10 movimiento auxiliar existe",
		actor.add_move(&"reflect", catalogs))
	prepared.foe = _mon(&"mew", 100, &"foe", ["amnesia"])
	var id: StringName = StringName(row.item_id)
	var frozen: String = JSON.stringify(_owner_data(owner))
	check(mode + " B10 dos unidades iniciales", _units(owner, id) == 2)
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check(mode + " B10 combate nativo iniciado", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var before: Dictionary = _frame_c003(session, id)
	check(mode + " B10 inicio correcto", before.valid)
	var first_action: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " B10 ataque real inicial aceptado",
		first_action.get("accepted", false))
	if not first_action.get("accepted", false):
		await session.close()
		return {"valid": false}
	var first: Dictionary = _frame_c003(session, id)
	check(mode + " B10 estado después del primer golpe", first.valid)
	var first_damage: int = int(before.foe_hp) - int(first.foe_hp)
	check(mode + " B10 primer golpe dañó al rival real", first_damage > 0)
	var first_units: int = _c005_gem_units(owner, session, id)
	check(mode + " B10 primer golpe no modifica propietario en vivo",
		JSON.stringify(_owner_data(owner)) == frozen)
	var mid_snapshot: Dictionary = session.snapshot()
	var key: String = String(row.id) + "_" + str(seed) + "_" + mode
	var mid: Dictionary = await _restore_probe(
		session, owner, key + "_gem_first_savev2", mode + " B10 SaveV2 tras primer golpe")
	if not mid.get("valid", false):
		return {"valid": false}
	session = mid.session
	owner = mid.owner
	var mid_frame: Dictionary = _frame_c003(session, id)
	var gem_mid_save: bool = mid_frame == first and session.snapshot() == mid_snapshot
	check(mode + " B10 SaveV2 conserva estado de primera activación",
		gem_mid_save and JSON.stringify(_owner_data(owner)) == frozen)
	var after_first_restore_units: int = _c005_gem_units(owner, session, id)
	check(mode + " B10 SaveV2 no duplica la gema consumida",
		first_units == after_first_restore_units)
	var second_action: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " B10 segundo golpe real tras SaveV2 aceptado",
		second_action.get("accepted", false))
	if not second_action.get("accepted", false):
		await session.close()
		return {"valid": false}
	var second: Dictionary = _frame_c003(session, id)
	check(mode + " B10 segundo estado válido", second.valid)
	var second_damage: int = int(first.foe_hp) - int(second.foe_hp)
	check(mode + " B10 segundo golpe causa daño y no es un simulacro",
		second_damage > 0)
	var second_units: int = _c005_gem_units(owner, session, id)
	check(mode + " B10 segunda acción no duplica ni recupera objetos",
		second_units == first_units)
	var final_snapshot: Dictionary = session.snapshot()
	var finish: Dictionary = await _restore_probe(
		session, owner, key + "_gem_second_savev2", mode + " B10 SaveV2 tras segundo golpe")
	if not finish.get("valid", false):
		return {"valid": false}
	session = finish.session
	owner = finish.owner
	var end_frame: Dictionary = _frame_c003(session, id)
	var gem_final_save: bool = end_frame == second and session.snapshot() == final_snapshot
	var final_units: int = _c005_gem_units(owner, session, id)
	check(mode + " B10 SaveV2 final conserva gasto e identidad",
		gem_final_save and final_units == second_units
		and JSON.stringify(_owner_data(owner)) == frozen)
	await session.close()
	return {"valid": true, "start": before, "after": second,
		"damage": first_damage, "second_damage": second_damage,
		"gem_first_consumed": bool(first.own_consumed),
		"gem_second_consumed": bool(second.own_consumed),
		"gem_first_native_item": String(first.native_item),
		"gem_second_native_item": String(second.native_item),
		"gem_first_units": first_units, "gem_second_units": second_units,
		"gem_mid_save": gem_mid_save, "gem_final_save": gem_final_save,
		"physical_units": final_units, "restored": gem_mid_save and gem_final_save,
		"owner_unchanged": JSON.stringify(_owner_data(owner)) == frozen,
		"save_equal": final_units == second_units}

func _c005_gem_units(owner: PlayerCollection, session: RefCounted, id: StringName) -> int:
	var physical: int = owner.inventory.quantity(id)
	for creature: CreatureInstance in [session.battle_state().creature(&"own"),
		session.battle_state().creature(&"reserve")]:
		if creature.held_item_id == id and not creature.held_item_consumed:
			physical += 1
	return physical
