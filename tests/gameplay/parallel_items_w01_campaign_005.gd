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
	check("Bloques 01 a 05 de CAMPAÑA_005 autorizados", progress.size() == 5)
	if progress.size() != 5:
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
	var stages: Array = fixture.get("blocks", [])
	check("Fixture contiene cinco bloques reales", stages.size() == 5)
	if stages.size() != 5:
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
	var cases: Array = fixture.get("cases", [])
	check("Cuarenta y cinco escenarios funcionales autorizados", cases.size() == 45)
	var names: Array = []
	for row: Dictionary in cases:
		check("Escenario pertenece a su bloque oficial",
			(String(row.block) == "01" and stages[0].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "02" and stages[1].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "03" and stages[2].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "04" and stages[3].get("ids", []).has(String(row.item_id)))
			or (String(row.block) == "05" and stages[4].get("ids", []).has(String(row.item_id))))
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
	check("Ciento veintidós pares caso-semilla reales", c005_rows.size() == 122)
	check("Roca del Rey: retroceso real observado con RNG", c005_king_rock_activated > 0)
	check("Roca del Rey: rama RNG sin retroceso observada", c005_king_rock_not_activated > 0)
	for item_id: String in ["black_glasses", "dragon_fang", "hard_stone",
		"miracle_seed", "mystic_water", "never_melt_ice",
		"poison_barb", "sharp_beak", "silk_scarf",
		"silver_powder", "soft_sand", "spell_tag",
		"twisted_spoon", "metal_coat", "kings_rock"]:
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
				"spell_tag": "shadow_ball", "twisted_spoon": "psychic",
				"metal_coat": "flash_cannon"}
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
		"status_control":
			check("Movimiento de estado no inflige daño",
				String(row.own_move) == "reflect"
				and a.damage == 0 and n.damage == 0 and r.damage == 0)
			check("Movimiento de estado no consume objeto",
				not a.after.own_consumed and a.physical_units == 2)
		_:
			check("Operación no autorizada", false)

# En W01 la Roca del Rey se comprueba por retroceso observado en log nativo.
# El harness original de CAMPAÑA_004 se mantiene intacto para las 4 filas previas.
func _probe_w01_c004(row: Dictionary, seed: int, mode: String) -> Dictionary:
	if String(row.item_id) != "kings_rock":
		return await super._probe_w01_c004(row, seed, mode)
	return await _probe_c005_king_rock(row, seed, mode)

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
		not flinched or (String(row.op) == "kings_rock_flinch"
			and int(after.foe_hp) < int(before.foe_hp)))
	if String(row.op) == "kings_rock_flinch":
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
