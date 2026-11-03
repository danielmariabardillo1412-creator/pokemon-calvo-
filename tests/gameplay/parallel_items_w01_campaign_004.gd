extends "res://tests/gameplay/parallel_items_w01_campaign_003.gd"

# W01 CAMPAÑA_004: nuevo runner de equipables por especie, sin editar CAMP003.
# Hereda infraestructura probada: _fixture, _frame_c003, _restore_probe, SaveV2.
const C004_FIXTURE := "res://tests/fixtures/parallel_items/w01_campaign_004.json"
const C004_PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W01/CAMP_004_PROGRESO.csv"
const C004_OUTPUT := "res://.godot/parallel_items/w01_campaign_004"
var c004_rows: Array = []
var c004_lucky_exclusive: int = 0
var c004_lucky_hits: int = 0
var c004_dice_baseline_short: int = 0
var c004_dice_four: int = 0
var c004_dice_five: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_w01_c004")
	create_timer(800.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP004 timeout de pruebas nativas")
			quit(2))

func _progress_c004() -> Array:
	var file := FileAccess.open(C004_PROGRESS, FileAccess.READ)
	if file == null:
		check("Progreso CAMP004 existe", false)
		return []
	var header: PackedStringArray = file.get_csv_line()
	check("Cabecera CAMP004 seis columnas", header.size() == 6 and header[0] == "bloque")
	var rows: Array = []
	while not file.eof_reached():
		var cols: PackedStringArray = file.get_csv_line()
		if cols.size() == 1 and cols[0].is_empty():
			continue
		check("CSV CAMP004 fila de seis columnas", cols.size() == 6)
		if cols.size() == 6:
			rows.append({"block": String(cols[0]), "ids": String(cols[1]), "status": String(cols[2])})
	file.close()
	return rows

func _run_w01_c004() -> void:
	destination = C004_OUTPUT
	DirAccess.make_dir_recursive_absolute(destination)
	var descriptor: Variant = JSON.parse_string(FileAccess.get_file_as_string(C004_FIXTURE))
	if not descriptor is Dictionary:
		push_error("W01 CAMP004 descriptor inválido")
		quit(2)
		return
	var fixture: Dictionary = descriptor
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Variantes regionales aplicadas", Variants.apply(catalogs))
	check("Identidad CAMP004/W01 correcta", fixture.get("schema_version") == 1
		and fixture.get("campaign") == "CAMP_004" and fixture.get("worker") == "W01"
		and fixture.get("format") == "gen9calvounifiedv1")
	check("Tres controles de equipamiento", fixture.get("variants") == ["active", "none", "reserve"])
	var progress: Array = _progress_c004()
	var completed: int = progress.size()
	check("Bloques W01 01 a 03 autorizados", completed == 3)
	if completed != 3:
		quit(2)
		return
	check("Fila 01 e IDs exactos de árbitra", String(progress[0].block) == "01"
		and String(progress[0].ids) == "light_ball;lucky_punch;thick_club")
	check("Fila 02 e IDs exactos de árbitra", String(progress[1].block) == "02"
		and String(progress[1].ids) == "damp_rock;float_stone;icy_rock")
	check("Fila 03 e IDs exactos de árbitra", String(progress[2].block) == "03"
		and String(progress[2].ids) == "loaded_dice;misty_seed;power_herb")
	var ids_for_block: Dictionary = {}
	var ids: PackedStringArray = PackedStringArray()
	for row_progress: Dictionary in progress:
		ids_for_block[String(row_progress.block)] = String(row_progress.ids).split(";")
		ids.append_array(ids_for_block[String(row_progress.block)])
	var cases: Array = fixture.get("cases", [])
	check("Veinte escenarios autorizados", cases.size() == 20)
	var names: Array = []
	for row: Dictionary in cases:
		check("Escenario pertenece a bloque autorizado",
			ids_for_block.has(String(row.block))
			and ids_for_block.get(String(row.block), PackedStringArray()).has(String(row.item_id)))
		check("Escenario único", not names.has(String(row.id)))
		names.append(String(row.id))
		for value: Variant in row.seeds:
			check("Semilla válida", (value is int or value is float)
				and float(value) == float(int(value)) and int(value) >= 1 and int(value) <= 65535)
			current_case = String(row.id) + "/" + str(int(value))
			var before_checks: int = checks
			var before_errors: int = errors.size()
			# Las sesiones se cierran/restauran antes del siguiente modo:
			# cero estado de simulador compartido, misma semilla en los tres.
			var observed: Dictionary = {}
			for mode: String in ["active", "none", "reserve"]:
				observed[mode] = await _probe_w01_c004(row, int(value), mode)
			_compare_c004(row, observed)
			c004_rows.append({"block": String(row.block), "id": String(row.id),
				"item_id": String(row.item_id),
				"seed": int(value), "checks": checks - before_checks,
				"status": "PASS" if errors.size() == before_errors else "FAIL",
				"observed": observed})
	check("Matriz exacta de 62 pares caso-semilla", c004_rows.size() == 62)
	for id: String in ids:
		check("ID cubierto " + id, cases.any(func(case): return String(case.item_id) == id))
	check("Puño Suerte demuestra al menos un crítico específico de Chansey", c004_lucky_exclusive > 0)
	check("Puño Suerte registra críticos reales con Chansey", c004_lucky_hits > 0)
	check("Dado Trucado: al menos una semilla sin equipar tiene dos o tres golpes",
		c004_dice_baseline_short > 0)
	check("Dado Trucado: el simulador muestra tanto cuatro como cinco golpes",
		c004_dice_four > 0 and c004_dice_five > 0)
	var report := {"schema_version": 1, "campaign": "CAMP_004", "worker": "W01",
		"blocks": completed, "checks": checks, "errors": errors,
		"lucky_punch_exclusive_critical_witnesses": c004_lucky_exclusive,
		"loaded_dice_baseline_short_witnesses": c004_dice_baseline_short,
		"loaded_dice_four_hits": c004_dice_four, "loaded_dice_five_hits": c004_dice_five,
		"cases": c004_rows,
		"limits": ["Godot headless sin prueba visual/GPU", "Solo especies y semillas declaradas",
			"Sin certificación de integración global a main, V28 o mapa"]}
	var file := FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Informe de evidencia abrible", file != null)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	done = true
	if errors.is_empty():
		print("CAMP004_W01_GODOT PASS blocks=", completed, " checks=", checks)
		quit(0)
	else:
		print("CAMP004_W01_GODOT FAIL blocks=", completed, " checks=", checks,
			" errors=", errors.size())
		quit(1)

func _probe_w01_c004(row: Dictionary, seed: int, mode: String) -> Dictionary:
	automation = {"actor_species": String(row.actor_species), "level": 100,
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4],
		"physical_move": String(row.own_move), "special_move": "water_gun",
		"speed_target": String(row.foe_species), "damage_target": String(row.foe_species)}
	var prepared: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	actor.moveset.clear()
	actor.move_ids.clear()
	check(mode + " movimiento principal disponible", actor.add_move(StringName(row.own_move), catalogs))
	var second: String = String(row.get("follow_move", "reflect"))
	if second.is_empty():
		second = "reflect"
	# Evitar un slot duplicado de Reflejo en los controles sin clima.
	if second == String(row.own_move):
		second = "tackle"
	check(mode + " movimiento de control disponible", actor.add_move(StringName(second), catalogs))
	prepared.foe = _mon(StringName(row.foe_species), 100, &"foe", [String(row.foe_move)])
	var id := StringName(row.item_id)
	var original_owner: String = JSON.stringify(_owner_data(owner))
	check(mode + " dos unidades físicas antes del combate", _units(owner, id) == 2)
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check(mode + " abre combate nativo", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var before: Dictionary = _frame_c003(session, id)
	check(mode + " estado inicial nativo", before.valid)
	if not before.valid:
		await session.close()
		return {"valid": false}
	var action: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " primer comando realmente aceptado", action.get("accepted", false))
	if not action.get("accepted", false):
		await session.close()
		return {"valid": false}
	if row.has("follow_move"):
		var follow: Dictionary = await session.submit("move 2", session.revision)
		check(mode + " segundo turno real de crítico aceptado", follow.get("accepted", false))
		if not follow.get("accepted", false):
			await session.close()
			return {"valid": false}
	# Un movimiento de carga sin Hierba Única conserva su fase intermedia
	# tras el primer turno. Primero comprobar esa observación real; después
	# completar el segundo turno antes de evaluar SaveV2 de un estado estable.
	# No se elimina ningún control de snapshot ni de proyección restaurada.
	var first_turn: Dictionary = _frame_c003(session, id)
	check(mode + " primer turno nativo válido", first_turn.valid)
	var first_turn_damage: int = int(before.foe_hp) - int(first_turn.foe_hp)
	if String(row.op) == "power_herb_skip_charge" and mode != "active":
		check(mode + " Rayo Solar sin Hierba Única no daña en turno de carga",
			first_turn_damage == 0)
		var finish_charge: Dictionary = await session.submit("move 1", session.revision)
		check(mode + " segundo turno real de Rayo Solar aceptado",
			finish_charge.get("accepted", false))
		if not finish_charge.get("accepted", false):
			await session.close()
			return {"valid": false}
	var after: Dictionary = _frame_c003(session, id)
	check(mode + " estado final nativo", after.valid)
	if String(row.op) == "power_herb_skip_charge" and mode != "active":
		check(mode + " segundo turno termina carga y golpea",
			int(before.foe_hp) > int(after.foe_hp))
	var battle_log: Array = session._checkpoint.get("snapshot", {}).get("native", {}).get("log", [])
	var critical: bool = false
	var hit_count: int = 0
	for entry: String in battle_log:
		if entry.begins_with("|-hitcount|") and entry.contains("p2a:"):
			var pieces: PackedStringArray = entry.split("|")
			if pieces.size() >= 4:
				hit_count = int(pieces[pieces.size() - 1])
		if entry.begins_with("|-crit|p2a:"):
			critical = true
	# Las comparaciones de Hierba Única se refieren siempre al PRIMER turno:
	# el control completa el ataque al segundo solo para guardar estado estable.
	var foe_damage: int = first_turn_damage if String(row.op) == "power_herb_skip_charge" else (
		int(before.foe_hp) - int(after.foe_hp))
	var frozen: bool = JSON.stringify(_owner_data(owner)) == original_owner
	check(mode + " propietario no asentado anticipadamente", frozen)
	var physical: int = owner.inventory.quantity(id)
	for c: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if c.held_item_id == id and not c.held_item_consumed:
			physical += 1
	var snapshot: Dictionary = session.snapshot()
	var key: String = String(row.id) + "_" + str(seed) + "_" + mode
	var persisted: Dictionary = await _restore_probe(session, owner, key + "_savev2", mode + " SaveV2")
	if not persisted.get("valid", false):
		return {"valid": false}
	session = persisted.session
	owner = persisted.owner
	var restored_frame: Dictionary = _frame_c003(session, id)
	check(mode + " proyección idéntica después SaveV2", restored_frame == after)
	check(mode + " snapshot idéntico después SaveV2", session.snapshot() == snapshot)
	check(mode + " propietario idéntico después SaveV2",
		JSON.stringify(_owner_data(owner)) == original_owner)
	var restored_physical: int = owner.inventory.quantity(id)
	for c: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if c.held_item_id == id and not c.held_item_consumed:
			restored_physical += 1
	check(mode + " unidades físicas idénticas tras SaveV2", restored_physical == physical)
	await session.close()
	return {"valid": true, "start": before, "after": after,
		"damage": foe_damage, "critical": critical, "hit_count": hit_count,
		"physical_units": physical,
		"restored": restored_frame == after, "owner_unchanged": frozen,
		"save_equal": restored_physical == physical}

func _compare_c004(row: Dictionary, observed: Dictionary) -> void:
	check("Tres modalidades reales para objeto", observed.has_all(["active", "none", "reserve"]))
	if not observed.has_all(["active", "none", "reserve"]):
		return
	for mode: String in ["active", "none", "reserve"]:
		var x: Dictionary = observed[mode]
		check("Modo " + mode + " prueba combate y SaveV2",
			x.get("valid", false) and x.get("restored", false) and
			x.get("owner_unchanged", false) and x.get("save_equal", false))
		if not x.get("valid", false):
			return
		check("Propietario exclusivo " + mode,
			bool(x.start.own_has_item) == (mode == "active")
			and bool(x.start.reserve_has_item) == (mode == "reserve"))
		check("Reserva no consume " + mode, not x.after.reserve_consumed)
		var triggered_consumable: bool = (String(row.op) == "misty_seed_terrain"
			or String(row.op) == "power_herb_skip_charge")
		check("Unidades físicas coherentes con activación " + mode,
			x.physical_units == (1 if mode == "active" and triggered_consumable else 2))
	var a: Dictionary = observed.active
	var n: Dictionary = observed.none
	var r: Dictionary = observed.reserve
	var should_consume: bool = (String(row.op) == "misty_seed_terrain"
		or String(row.op) == "power_herb_skip_charge")
	check("Consumo exacto por activación, reserva y ausencia intactas",
		bool(a.after.own_consumed) == should_consume
		and not r.after.reserve_consumed
		and a.physical_units == (1 if should_consume else 2)
		and n.physical_units == 2 and r.physical_units == 2)
	match String(row.op):
		"damage_boost_compatible":
			check("Especie compatible: daño nativo aumenta exclusivamente en portador",
				a.damage > n.damage and n.damage > 0 and n.damage == r.damage)
			check("Ninguna transferencia desde la reserva altera el daño", r.damage == n.damage)
		"wrong_holder_no_damage_boost":
			check("Especie incompatible: sin bonificación de daño",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		"critical_ratio_compatible":
			check("Chansey con Puño Suerte: crítico tras Foco Energía",
				a.critical and a.damage > 0)
			check("Control sin objeto igual a control con reserva para críticos",
				n.critical == r.critical and n.damage == r.damage)
			check("El portador no causa menos daño que controles a mismas semillas",
				a.damage >= n.damage)
			if a.critical:
				c004_lucky_hits += 1
			if a.critical and not n.critical and not r.critical:
				c004_lucky_exclusive += 1
		"wrong_holder_no_critical_ratio":
			check("Puño Suerte en Mew no modifica probabilidades de crítico",
				a.critical == n.critical and n.critical == r.critical)
			check("Puño Suerte en Mew no modifica daño",
				a.damage == n.damage and n.damage == r.damage)
		"weather_duration":
			check("Roca climatica: duracion nativa ampliada tres turnos solo equipada",
				int(a.after.sun_duration) > 0
				and int(a.after.sun_duration) == int(n.after.sun_duration) + 3
				and int(n.after.sun_duration) == int(r.after.sun_duration))
			check("Roca climatica: ambos controles provocan el mismo clima nativo",
				int(n.after.sun_duration) > 0 and int(r.after.sun_duration) > 0)
			check("Roca climatica: no se consume por invocar el clima",
				not a.after.own_consumed and a.physical_units == 2 and r.physical_units == 2)
		"no_weather":
			check("Roca climatica: sin invocacion no aparece clima ni incremento",
				int(a.after.sun_duration) == 0 and int(n.after.sun_duration) == 0
				and int(r.after.sun_duration) == 0)
			check("Roca climatica: retencion en ausencia del disparador",
				not a.after.own_consumed and a.physical_units == 2 and r.physical_units == 2)
		"weight_damage_reduced":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var none_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Piedra Pomez: Hierba Lazo causa menos dano al portador",
				none_loss > 0 and active_loss >= 0 and active_loss < none_loss)
			check("Piedra Pomez: reserva no reduce el dano basado en peso",
				none_loss == reserve_loss)
			check("Piedra Pomez: no se consume al modificar el peso",
				not a.after.own_consumed and a.physical_units == 2 and r.physical_units == 2)
		"fixed_power_control":
			var active_loss: int = int(a.start.hp) - int(a.after.hp)
			var none_loss: int = int(n.start.hp) - int(n.after.hp)
			var reserve_loss: int = int(r.start.hp) - int(r.after.hp)
			check("Piedra Pomez: Placaje de potencia fija no cambia por peso",
				active_loss > 0 and active_loss == none_loss and none_loss == reserve_loss)
			check("Piedra Pomez: no consume en movimiento de potencia fija",
				not a.after.own_consumed and a.physical_units == 2 and r.physical_units == 2)
		"loaded_dice_multihit":
			check("Dado Trucado: contador de golpes nativo real del objetivo",
				int(a.hit_count) in [4, 5]
				and int(n.hit_count) in [2, 3, 4, 5]
				and int(r.hit_count) == int(n.hit_count))
			check("Dado Trucado: mismo movimiento y semilla sin alterar control",
				a.damage > 0 and n.damage > 0 and n.damage == r.damage)
			check("Dado Trucado: efecto retenido sin consumo",
				not a.after.own_consumed and a.physical_units == 2 and r.physical_units == 2)
			if int(n.hit_count) in [2, 3]:
				c004_dice_baseline_short += 1
			if int(a.hit_count) == 4:
				c004_dice_four += 1
			if int(a.hit_count) == 5:
				c004_dice_five += 1
		"loaded_dice_single_hit":
			check("Dado Trucado: Placaje no activa golpes multiples",
				int(a.hit_count) == 0 and int(n.hit_count) == 0 and int(r.hit_count) == 0
				and a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
		"misty_seed_terrain":
			check("Semilla Bruma: Campo de Niebla sube solo Defensa Especial del portador",
				int(a.after.special_defense_stage) == 1
				and int(n.after.special_defense_stage) == 0
				and int(r.after.special_defense_stage) == 0)
			check("Semilla Bruma: consumo unico solo al activar el terreno",
				a.after.own_consumed and a.physical_units == 1
				and not r.after.reserve_consumed and r.physical_units == 2)
		"misty_seed_no_trigger":
			check("Semilla Bruma: Campo Electrico no activa Defensa Especial",
				int(a.after.special_defense_stage) == 0
				and int(n.after.special_defense_stage) == 0
				and int(r.after.special_defense_stage) == 0)
			check("Semilla Bruma: no se consume en terreno equivocado",
				not a.after.own_consumed and a.physical_units == 2)
		"power_herb_skip_charge":
			check("Hierba Unica: Rayo Solar golpea en el primer turno solo equipado",
				a.damage > 0 and n.damage == 0 and r.damage == 0)
			check("Hierba Unica: consumida una sola vez en el portador",
				a.after.own_consumed and a.physical_units == 1
				and not r.after.reserve_consumed and r.physical_units == 2)
		"power_herb_no_charge_control":
			check("Hierba Unica: Placaje no usa efecto de carga",
				a.damage > 0 and a.damage == n.damage and n.damage == r.damage)
			check("Hierba Unica: no se consume con movimiento inmediato",
				not a.after.own_consumed and a.physical_units == 2)
		_:
			check("Operación fuera del contrato de bloque", false)
