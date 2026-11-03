extends "res://tests/gameplay/item_automation_v28.gd"

# CAMPAÑA_003 W01: harness acumulativo; usa el simulador existente sin añadir reglas.
const W01_C003_DESCRIPTOR := "res://tests/fixtures/parallel_items/w01_campaign_003.json"
const W01_C003_OUTPUT := "res://.godot/parallel_items/w01_campaign_003"
const W01_C003_PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W01/CAMP_003_PROGRESO.csv"
var w01_c003_rows: Array = []
var w01_c003_band_survivals: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_w01_c003")
	create_timer(500.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP003 timeout")
			quit(2))

func _progress_blocks() -> Array:
	var f := FileAccess.open(W01_C003_PROGRESS, FileAccess.READ)
	if f == null:
		check("progreso presente", false)
		return []
	var header: PackedStringArray = f.get_csv_line()
	check("cabecera del progreso", header.size() == 6 and header[0] == "bloque" and header[1] == "ids")
	var rows: Array = []
	while not f.eof_reached():
		var columns: PackedStringArray = f.get_csv_line()
		if columns.size() == 1 and columns[0].is_empty():
			continue
		check("una fila valida CSV", columns.size() == 6)
		if columns.size() == 6:
			rows.append({"block": String(columns[0]), "ids": String(columns[1])})
	f.close()
	return rows

func _run_w01_c003() -> void:
	destination = W01_C003_OUTPUT
	DirAccess.make_dir_recursive_absolute(destination)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(W01_C003_DESCRIPTOR))
	if not raw is Dictionary:
		push_error("W01 CAMP003 fixture invalido")
		quit(2)
		return
	var fixture: Dictionary = raw
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay regional real", Variants.apply(catalogs))
	check("cabecera correcta", fixture.get("schema_version") == 1 and fixture.get("campaign") == "CAMP_003" and fixture.get("worker") == "W01" and fixture.get("format") == "gen9calvounifiedv1")
	check("modos equivalentes", fixture.get("variants") == ["active", "none", "reserve"])
	var stages: Array = _progress_blocks()
	var completed: int = stages.size()
	check("1 a 10 bloques entregados", completed >= 1 and completed <= 10)
	var ids_for_block: Dictionary = {}
	for index in completed:
		check("bloque secuencial " + str(index + 1), String(stages[index].block) == "%02d" % (index + 1))
		ids_for_block[String(stages[index].block)] = String(stages[index].ids).split(";")
	var seen: Array = []
	for row: Dictionary in fixture.get("cases", []):
		var stage: String = String(row.block)
		check("caso tiene bloque autorizado", ids_for_block.has(stage) and String(row.item_id) in ids_for_block.get(stage, []))
		check("caso sin duplicados", not seen.has(String(row.id)))
		seen.append(String(row.id))
		for value: Variant in row.get("seeds", []):
			check("semilla entera", (value is int or value is float) and float(value) == float(int(value)) and int(value) >= 0 and int(value) <= 65535)
			current_case = String(row.id) + "/" + str(int(value))
			var checks_before: int = checks
			var errors_before: int = errors.size()
			var observed: Dictionary = {}
			for mode: String in ["active", "none", "reserve"]:
				observed[mode] = await _probe_c003(row, int(value), mode)
			_compare_c003(row, observed)
			if String(row.op) == "random_lethal_survival" and observed.get("active", {}).get("valid", false):
				if int(observed.active.after.hp) == 1:
					w01_c003_band_survivals += 1
			w01_c003_rows.append({"block": stage, "id": String(row.id), "item_id": String(row.item_id),
				"seed": int(value), "checks": checks - checks_before,
				"status": "PASS" if errors.size() == errors_before else "FAIL", "observed": observed})
	if ids_for_block.has("04"):
		check("Cinta Aguante debe demostrar al menos una supervivencia REAL", w01_c003_band_survivals > 0)
	for stage in ids_for_block:
		for id: String in ids_for_block[stage]:
			var count: int = 0
			for case: Dictionary in fixture.cases:
				if String(case.block) == stage and String(case.item_id) == id:
					count += 1
			check("objeto cubierto " + id, count > 0)
	var output := {
		"schema_version": 1, "worker": "W01", "campaign": "CAMP_003",
		"blocks": completed, "descriptor_sha256": FileAccess.get_sha256(W01_C003_DESCRIPTOR),
		"checks": checks, "focus_band_witnessed_survivals": w01_c003_band_survivals,
		"status": "PASS" if errors.is_empty() else "FAIL",
		"errors": errors, "rows": w01_c003_rows,
		"limits": ["Sin GPU/UI", "No certifica asentamiento de combate ni regreso al mapa",
			"Solo escenarios fijados por semillas; motor @pkmn/sim sin modificar"]
	}
	var f := FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	if f == null:
		push_error("No pudo escribir informe de evidencias")
		quit(2)
		return
	f.store_string(JSON.stringify(output, "  "))
	f.close()
	done = true
	if errors.is_empty():
		print("CAMP003_W01_GODOT PASS blocks=", completed, " checks=", checks)
	else:
		print("CAMP003_W01_GODOT FAIL blocks=", completed, " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)

func _native_item(session: RefCounted, instance: String) -> Dictionary:
	for side: Dictionary in session._checkpoint.get("roster", []):
		if String(side.get("id", "")) != "p1":
			continue
		for entry: Dictionary in side.get("pokemon", []):
			if String(entry.get("instance_id", "")) == instance:
				return entry
	return {}

func _frame_c003(session: RefCounted, id: StringName) -> Dictionary:
	var own: CreatureInstance = session.battle_state().creature(&"own")
	var bench: CreatureInstance = session.battle_state().creature(&"reserve")
	var foe: CreatureInstance = session.battle_state().creature(&"foe")
	var native: Dictionary = _native_item(session, "own")
	var log: Array = session._checkpoint.get("snapshot", {}).get("native", {}).get("log", [])
	var missed: bool = false
	var band_activated: bool = false
	var trap_ticks: int = 0
	var first_move_actor: String = ""
	for entry: String in log:
		if entry.begins_with("|move|") and first_move_actor.is_empty():
			first_move_actor = "own" if entry.contains("|p1a:") else "foe"
		if entry.begins_with("|-miss|") and entry.contains("p1a:"):
			missed = true
		if entry.begins_with("|-activate|") and entry.contains("Focus Band"):
			band_activated = true
		if entry.begins_with("|-damage|") and entry.contains("[from] move: Infestation"):
			trap_ticks += 1
	var native_snapshot: Dictionary = session._checkpoint.get("snapshot", {}).get("native", {})
	var weather_state: Variant = native_snapshot.get("field", {}).get("weatherState", {})
	var sun_duration: int = int(weather_state.get("duration", 0)) if weather_state is Dictionary else 0
	var sides: Array = native_snapshot.get("sides", [])
	var own_hazards: Dictionary = sides[0].get("sideConditions", {}) if sides.size() > 0 else {}
	var rock_on_side: bool = own_hazards.has("stealthrock")
	var reflect_state: Variant = own_hazards.get("reflect", {})
	var reflect_duration: int = int(reflect_state.get("duration", 0)) if reflect_state is Dictionary else 0
	var request: Dictionary = session._checkpoint.get("views", {}).get("p1", {}).get("request", {})
	var active_requests: Array = request.get("active", [])
	var moves: Array = active_requests[0].get("moves", []) if active_requests.size() > 0 else []
	var force_flags: Array = request.get("forceSwitch", [])
	var forcing: bool = force_flags.has(true)
	return {
		"valid": native.has("boosts"), "hp": own.current_hp, "max_hp": own.stats.max_hp, "foe_hp": foe.current_hp,
		"foe_max_hp": foe.stats.max_hp, "reserve_hp": bench.current_hp, "reserve_max_hp": bench.stats.max_hp,
		"status_move_disabled": moves.size() > 1 and bool(moves[1].get("disabled", false)),
		"own_has_item": own.held_item_id == id, "reserve_has_item": bench.held_item_id == id,
		"own_consumed": own.held_item_consumed, "reserve_consumed": bench.held_item_consumed,
		"native_item": String(native.get("item", "")),
		"boosts": native.get("boosts", {}).duplicate(true),
		"attack_stage": int(native.get("boosts", {}).get("atk", 0)),
		"defense_stage": int(native.get("boosts", {}).get("def", 0)),
		"speed_stage": int(native.get("boosts", {}).get("spe", 0)),
		"status_id": String(own.status_state.persistent_id),
		"forced_switch": forcing,
		"active_id": String(session._checkpoint.get("roster", [])[0].get("active_id", "")),
		"native_ability": String(native.get("ability", "")),
		"native_volatiles": native.get("volatiles", []).duplicate(true),
		"missed": missed,
		"focus_band_activated": band_activated,
		"trap_ticks": trap_ticks, "sun_duration": sun_duration, "stealth_rock": rock_on_side,
		"first_move_actor": first_move_actor, "reflect_duration": reflect_duration
	}

func _probe_c003(row: Dictionary, seed: int, mode: String) -> Dictionary:
	automation = {"actor_species": String(row.actor_species), "level": int(row.get("actor_level", 100)), "format": "gen9calvounifiedv1",
		"seed": [seed, 2, 3, 4], "physical_move": String(row.own_move),
		"special_move": "water_gun", "speed_target": String(row.foe_species), "damage_target": String(row.foe_species)}
	var prepared: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	actor.moveset.clear()
	actor.move_ids.clear()
	check(mode + " own move existe", actor.add_move(StringName(row.own_move), catalogs))
	check(mode + " control status existe", actor.add_move(&"reflect" if row.own_move != "reflect" else &"tackle", catalogs))
	if row.has("actor_hp") and String(row.actor_hp) == "one":
		actor.current_hp = 1
	elif row.has("actor_hp") and String(row.actor_hp) == "minus_one":
		actor.current_hp = actor.stats.max_hp - 1
	check(mode + " actor PS de fixture válidos", actor.current_hp > 0 and actor.current_hp <= actor.stats.max_hp)
	if row.has("actor_ability") and not String(row.actor_ability).is_empty():
		actor.ability_id = StringName(row.actor_ability)
	prepared.foe = _mon(StringName(row.foe_species), int(row.get("foe_level", 100)), &"foe", [String(row.foe_move)])
	var id := StringName(row.item_id)
	check(mode + " dos unidades antes", _units(owner, id) == 2)
	var owner_frozen: String = JSON.stringify(_owner_data(owner))
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check(mode + " sesion nativa activa", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var start: Dictionary = _frame_c003(session, id)
	check(mode + " estado inicial nativo", start.valid)
	if not start.valid:
		await session.close()
		return {"valid": false}
	var initial_snapshot: Dictionary = session.snapshot()
	if String(row.op) == "status_lock" and mode == "active":
		var rejected: Dictionary = await session.submit("move 2", session.revision)
		check(mode + " chaleco rechaza estado sin mutar", not rejected.get("accepted", false) and session.snapshot() == initial_snapshot)
	var action: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " comando aceptado", action.get("accepted", false))
	if not action.get("accepted", false):
		await session.close()
		return {"valid": false}
	# Los objetos de duración y peligros de entrada necesitan más de un turno.
	# Se usan únicamente comandos legítimos del motor; nunca se simulan efectos.
	if String(row.op) == "trap_extended_duration":
		for turn in 6:
			var continuation: Dictionary = await session.submit("move 2", session.revision)
			check(mode + " atrapamiento turno " + str(turn + 2) + " aceptado", continuation.get("accepted", false))
			if not continuation.get("accepted", false):
				await session.close()
				return {"valid": false}
	elif String(row.op) in ["boots_rock_reentry", "boots_no_rock_control"]:
		for move: String in ["switch 2", "switch 1"]:
			var switched: Dictionary = await session.submit(move, session.revision)
			check(mode + " cambio de batalla " + move + " aceptado", switched.get("accepted", false))
			if not switched.get("accepted", false):
				await session.close()
				return {"valid": false}
	var after: Dictionary = _frame_c003(session, id)
	check(mode + " estado final nativo", after.valid)
	var units: int = owner.inventory.quantity(id)
	for c: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if c.held_item_id == id and not c.held_item_consumed:
			units += 1
	var frozen: bool = JSON.stringify(_owner_data(owner)) == owner_frozen
	check(mode + " sin asentamiento anticipado", frozen)
	var key: String = String(row.id) + "_" + str(seed) + "_" + mode
	var terminal_snapshot: Dictionary = session.snapshot()
	var restored: Dictionary = await _restore_probe(session, owner, key + "_savev2", mode + " SaveV2")
	if not restored.get("valid", false):
		return {"valid": false}
	session = restored.session
	owner = restored.owner
	var restored_frame: Dictionary = _frame_c003(session, id)
	var snapshot_equal: bool = session.snapshot() == terminal_snapshot
	check(mode + " checkpoint SaveV2 exacto", snapshot_equal)
	check(mode + " proyeccion igual tras restore", restored_frame == after)
	check(mode + " propietario SaveV2 sin cambios", JSON.stringify(_owner_data(owner)) == owner_frozen)
	var restored_units: int = owner.inventory.quantity(id)
	for c: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if c.held_item_id == id and not c.held_item_consumed:
			restored_units += 1
	check(mode + " SaveV2 sin duplicacion", units == restored_units)
	var evidence: Dictionary = {
		"id": String(row.id), "block": String(row.block), "item_id": String(row.item_id),
		"seed": seed, "mode": mode, "start": start, "after": after,
		"initial": initial_snapshot, "final": terminal_snapshot,
		"snapshot_equal": snapshot_equal, "restore_frame_equal": restored_frame == after,
		"restored_units": restored_units, "physical_units": units, "owner_unchanged": frozen
	}
	var hash: String = _write_evidence(key, evidence)
	await session.close()
	return {"valid": true, "start": start, "after": after, "restored": snapshot_equal and restored_frame == after,
		"owner_unchanged": frozen, "physical_units": units, "sha256": hash, "evidence": key + ".json"}

func _compare_c003(row: Dictionary, obs: Dictionary) -> void:
	if not obs.has_all(["active", "none", "reserve"]):
		check("tres variantes exigidas", false)
		return
	for mode: String in ["active", "none", "reserve"]:
		var x: Dictionary = obs[mode]
		check("probe real, SaveV2 y propietario " + mode, x.get("valid", false) and x.get("restored", false) and x.get("owner_unchanged", false))
		if not x.get("valid", false):
			return
		check("propiedad exclusiva " + mode,
			bool(x.start.own_has_item) == (mode == "active") and bool(x.start.reserve_has_item) == (mode == "reserve"))
		check("reserva nunca consume " + mode, not x.after.reserve_consumed)
		check("stock 1 o 2 " + mode, x.physical_units in [1, 2])
	var a: Dictionary = obs.active
	var n: Dictionary = obs.none
	var r: Dictionary = obs.reserve
	var da: int = int(a.start.hp) - int(a.after.hp)
	var dn: int = int(n.start.hp) - int(n.after.hp)
	var dr: int = int(r.start.hp) - int(r.after.hp)
	var fa: int = int(a.start.foe_hp) - int(a.after.foe_hp)
	var fn: int = int(n.start.foe_hp) - int(n.after.foe_hp)
	var fr: int = int(r.start.foe_hp) - int(r.after.foe_hp)
	check("reserva igual al control (PS actor)", dr == dn)
	if String(row.op) not in ["trap_residual", "trap_extended_duration"]:
		check("dano rival sin cambio no autorizado", fa == fn and fn == fr)
	match String(row.op):
		"ground_immunity":
			check("Globo es inmune al ataque de tierra", da == 0 and dn > 0 and dr == dn)
			check("Globo retenido si no es alcanzado", not a.after.own_consumed and a.physical_units == 2)
		"normal_hit_pops":
			check("Globo explota tras impacto normal", da > 0 and da == dn and a.after.own_consumed and a.physical_units == 1)
			check("Globo en reserva permanece intacto", not r.after.reserve_consumed and r.physical_units == 2)
		"no_hit_retained":
			check("Sin ataque no explota Globo", da == 0 and dn == 0 and not a.after.own_consumed and a.physical_units == 2)
		"status_lock":
			check("Chaleco bloquea movimiento de estado solo en portador",
				a.start.status_move_disabled and not n.start.status_move_disabled and not r.start.status_move_disabled)
			check("Chaleco retenido", not a.after.own_consumed and a.physical_units == 2)
		"physical_control":
			check("Chaleco no reduce golpe fisico", da > 0 and da == dn and not a.after.own_consumed)
		"trap_residual":
			check("Banda Atadura incrementa residual con trampa real", fa > fn and fn == fr and fn > 0)
			check("Banda no consumida", not a.after.own_consumed and a.physical_units == 2)
		"non_trap_control":
			check("Banda no cambia ataque simple", fa > 0 and fa == fn and fn == fr)
			check("Banda conservada", not a.after.own_consumed and a.physical_units == 2)
		"accuracy_miss_trigger":
			check("Seguro Fallo: misma tirada de precision", a.after.missed == n.after.missed and n.after.missed == r.after.missed)
			var miss: bool = bool(a.after.missed)
			check("Seguro Fallo: +2 Vel solo al fallar de verdad",
				a.after.speed_stage == (2 if miss else 0) and n.after.speed_stage == 0 and r.after.speed_stage == 0)
			check("Seguro Fallo: consumo solo por fallo real",
				a.after.own_consumed == miss and a.physical_units == (1 if miss else 2) and not r.after.reserve_consumed)
		"accuracy_control":
			check("Ataque de precision 100 no dispara Seguro Fallo",
				not a.after.missed and a.after.speed_stage == 0 and not a.after.own_consumed and a.physical_units == 2)
		"paradox_activation":
			var ability: String = String(row.actor_ability).replace("_", "")
			check("Energia Potenciadora: habilidad autentica",
				a.start.native_ability == ability and n.start.native_ability == ability)
			check("Energia Potenciadora: volátil causal al entrar",
				a.start.native_volatiles.has(ability) and not n.start.native_volatiles.has(ability) and not r.start.native_volatiles.has(ability))
			check("Energia Potenciadora: gasto de una unidad al entrar",
				a.start.own_consumed and a.after.own_consumed and a.physical_units == 1 and not n.after.own_consumed and not r.after.reserve_consumed)
		"wrong_ability_control":
			check("Energia Potenciadora sin habilidad correcta no activa",
				not a.start.own_consumed and not a.after.own_consumed and a.physical_units == 2
				and a.start.native_volatiles == n.start.native_volatiles)
		"electric_damage_boost":
			check("Pila da +1 At solo al portador tras impacto eléctrico",
				a.after.attack_stage == 1 and n.after.attack_stage == 0 and r.after.attack_stage == 0
				and da > 0 and dn > 0 and dr == dn)
			check("Pila se consume al activarse", a.after.own_consumed and a.physical_units == 1 and not r.after.reserve_consumed)
		"opponent_drop_block":
			check("Amuleto Puro: Charm reduce Ataque solo sin amuleto",
				a.after.attack_stage == 0 and n.after.attack_stage < 0 and r.after.attack_stage == n.after.attack_stage)
			check("Amuleto Puro no se consume", not a.after.own_consumed and a.physical_units == 2)
		"no_drop_control":
			check("Amuleto Puro: sin bajada enemiga no cambia estadisticas",
				a.after.attack_stage == 0 and n.after.attack_stage == 0 and r.after.attack_stage == 0)
			check("Amuleto Puro retenido en control", not a.after.own_consumed and a.physical_units == 2)
		"secondary_status_block":
			check("Capa Furtiva: Nuzzle hace dano incluso con capa",
				da > 0 and da == dn and dr == dn)
			check("Capa Furtiva: evita la paralisis secundaria",
				a.after.status_id.is_empty() and n.after.status_id == "paralysis" and r.after.status_id == "paralysis")
			check("Capa Furtiva no consumida", not a.after.own_consumed and a.physical_units == 2)
		"normal_damage_control":
			check("Capa Furtiva no altera golpe normal ni su estado",
				da > 0 and da == dn and dr == dn and a.after.status_id == n.after.status_id and n.after.status_id == r.after.status_id)
			check("Capa Furtiva retenida", not a.after.own_consumed and a.physical_units == 2)
		"hit_forces_switch":
			check("Boton Escape: impacto real comprobado en los tres modos", da > 0 and da == dn and dn == dr)
			check("Boton Escape: solo portador solicita cambio forzado",
				a.after.forced_switch and not n.after.forced_switch and not r.after.forced_switch)
			check("Boton Escape: un objeto consumido y reserva intacta",
				a.after.own_consumed and a.physical_units == 1 and not r.after.reserve_consumed and r.physical_units == 2)
		"no_hit_no_switch":
			check("Boton Escape: sin recibir dano no se fuerza cambio",
				da == 0 and dn == 0 and not a.after.forced_switch and not n.after.forced_switch and not r.after.forced_switch)
			check("Boton Escape: sin golpe conserva item",
				not a.after.own_consumed and a.physical_units == 2)
		"non_electric_control", "no_hit_control":
			check("Pila no dispara si falta impacto eléctrico",
				a.after.attack_stage == 0 and n.after.attack_stage == 0 and r.after.attack_stage == 0
				and not a.after.own_consumed and a.physical_units == 2)
		"own_stat_drop_forces_switch":
			check("Mochila Escape: Close Combat reduce stats del actor en los tres modos",
				a.after.defense_stage < 0 and n.after.defense_stage < 0 and r.after.defense_stage < 0 and fa > 0)
			check("Mochila Escape: solo portador recibe peticion de cambio",
				a.after.forced_switch and not n.after.forced_switch and not r.after.forced_switch)
			check("Mochila Escape: solo activo consume y reserva intacta",
				a.after.own_consumed and a.physical_units == 1 and not n.after.own_consumed
				and not r.after.reserve_consumed and r.physical_units == 2)
		"own_no_drop_control":
			check("Mochila Escape sin bajada propia no pide cambio",
				a.after.defense_stage == 0 and not a.after.forced_switch and not n.after.forced_switch
				and not r.after.forced_switch)
			check("Mochila Escape se retiene sin activacion",
				not a.after.own_consumed and a.physical_units == 2)
		"electric_field_defense":
			check("Semilla Electro +1 Defensa solo en portador tras Campo Electrico",
				a.after.defense_stage == 1 and n.after.defense_stage == 0 and r.after.defense_stage == 0)
			check("Semilla Electro se consume al entrar campo",
				a.after.own_consumed and a.physical_units == 1 and not n.after.own_consumed
				and not r.after.reserve_consumed and r.physical_units == 2)
		"non_electric_field", "no_terrain_control":
			check("Semilla Electro no activa con campo ajeno o ausente",
				a.after.defense_stage == 0 and n.after.defense_stage == 0 and r.after.defense_stage == 0)
			check("Semilla Electro se retiene en control negativo",
				not a.after.own_consumed and a.physical_units == 2)
		"random_lethal_survival":
			check("Cinta Aguante: mismo golpe letal de Seismic Toss en controles",
				a.start.hp == 1 and n.start.hp == 1 and r.start.hp == 1
				and n.after.hp == 0 and r.after.hp == 0)
			check("Cinta Aguante: la supervivencia aleatoria deja exactamente 1 PS, o 0",
				a.after.hp in [0, 1] and (a.after.hp != 1 or a.after.focus_band_activated))
			check("Cinta Aguante: el objeto nunca se consume incluso si se activa",
				not a.after.own_consumed and a.physical_units == 2 and not r.after.reserve_consumed)
		"nonlethal_control":
			check("Cinta Aguante: golpe no letal no activa efecto",
				da > 0 and da < a.start.hp and da == dn and dn == dr
				and not a.after.focus_band_activated)
			check("Cinta Aguante: no se consume con golpe no letal",
				not a.after.own_consumed and a.physical_units == 2)
		"end_turn_burn":
			check("Llamasfera quema al portador al final de turno",
				a.after.status_id == "burn" and n.after.status_id.is_empty() and r.after.status_id.is_empty())
			check("Llamasfera no se consume por quemadura",
				not a.after.own_consumed and a.physical_units == 2 and not r.after.reserve_consumed)
		"fire_type_immunity":
			check("Llamasfera no puede quemar al tipo Fuego",
				a.after.status_id.is_empty() and n.after.status_id.is_empty() and r.after.status_id.is_empty())
			check("Llamasfera en tipo Fuego se conserva",
				not a.after.own_consumed and a.physical_units == 2)
		"focus_sash_full_hp":
			check("Banda Aguante: golpe letal desde PS máximos deja 1 PS solo al portador",
				a.start.hp == a.start.max_hp and a.start.hp > 1 and a.after.hp == 1 and n.after.hp == 0 and r.after.hp == 0)
			check("Banda Aguante: consumo físico solo cuando evita KO",
				a.after.own_consumed and a.physical_units == 1 and not r.after.reserve_consumed and r.physical_units == 2)
		"focus_sash_not_full":
			check("Banda Aguante: sin PS máximos no impide el KO",
				a.start.hp > 0 and a.start.hp < a.start.max_hp and a.after.hp == 0 and n.after.hp == 0 and r.after.hp == 0)
			check("Banda Aguante: sin activarse conserva objeto",
				not a.after.own_consumed and a.physical_units == 2)
		"focus_sash_nonlethal":
			check("Banda Aguante: golpe no letal no dispara efecto",
				da > 0 and da < a.start.hp and a.after.hp > 0 and da == dn and dn == dr)
			check("Banda Aguante: no se consume ante daño no letal",
				not a.after.own_consumed and a.physical_units == 2 and not r.after.reserve_consumed)
		"grassy_field_defense":
			check("Semilla Hierba: Campo Hierba concede +1 Defensa exclusivamente al portador",
				a.after.defense_stage == 1 and n.after.defense_stage == 0 and r.after.defense_stage == 0)
			check("Semilla Hierba: consumo único, ninguna activación en reserva",
				a.after.own_consumed and a.physical_units == 1 and not n.after.own_consumed
				and not r.after.reserve_consumed and r.physical_units == 2)
		"grassy_wrong_terrain", "grassy_no_terrain":
			check("Semilla Hierba: campo distinto o inexistente no concede Defensa",
				a.after.defense_stage == 0 and n.after.defense_stage == 0 and r.after.defense_stage == 0)
			check("Semilla Hierba: sin Campo Hierba se conserva",
				not a.after.own_consumed and a.physical_units == 2)
		"trap_extended_duration":
			check("Garra Garfio: prolonga Infestacion durante siete turnos de dano nativo",
				a.after.trap_ticks in [7, 14] and a.after.trap_ticks > n.after.trap_ticks
				and n.after.trap_ticks == r.after.trap_ticks and n.after.trap_ticks <= 10)
			check("Garra Garfio: residual adicional real frente a controles",
				fa > fn and fn == fr and not a.after.own_consumed and a.physical_units == 2)
		"trap_no_activation":
			check("Garra Garfio: Tackle no crea Infestacion",
				a.after.trap_ticks == 0 and n.after.trap_ticks == 0 and r.after.trap_ticks == 0
				and fa == fn and fn == fr)
			check("Garra Garfio se retiene sin efecto", not a.after.own_consumed and a.physical_units == 2)
		"sun_eight_turns":
			check("Roca Calor: Dia Soleado dura tres turnos mas solo con portador",
				a.after.sun_duration > 0 and a.after.sun_duration == n.after.sun_duration + 3
				and n.after.sun_duration == r.after.sun_duration)
			check("Roca Calor no se gasta", not a.after.own_consumed and a.physical_units == 2)
		"no_sunny_day":
			check("Sin Dia Soleado no hay duracion artificial",
				a.after.sun_duration == 0 and n.after.sun_duration == 0 and r.after.sun_duration == 0)
			check("Roca Calor sin activar se conserva", not a.after.own_consumed and a.physical_units == 2)
		"boots_rock_reentry":
			check("Botas Gruesas: Trampa Rocas existe en los tres combates", 
				a.after.stealth_rock and n.after.stealth_rock and r.after.stealth_rock)
			check("Botas Gruesas: portador activo vuelve sin perder PS",
				a.after.active_id == "own" and n.after.active_id == "own" and r.after.active_id == "own"
				and a.after.hp == a.start.hp and n.after.hp < n.start.hp
				and r.after.hp == n.after.hp)
			check("Botas Gruesas: reserva protegida solo cuando las lleva",
				r.after.reserve_hp == r.after.reserve_max_hp
				and n.after.reserve_hp < n.start.reserve_hp
				and a.after.reserve_hp == n.after.reserve_hp)
			check("Botas Gruesas no se consumen", not a.after.own_consumed and a.physical_units == 2)
		"boots_no_rock_control":
			check("Botas Gruesas: sin peligro, cambios no causan dano",
				not a.after.stealth_rock and not n.after.stealth_rock and not r.after.stealth_rock
				and a.after.hp == a.start.hp and n.after.hp == n.start.hp and r.after.hp == r.start.hp)
			check("Botas Gruesas sin peligro siguen equipadas",
				not a.after.own_consumed and a.physical_units == 2)
		"flying_grounded_by_iron_ball":
			check("Bola Ferrea: Charizard volador pierde inmunidad a Tierra solo si la porta",
				da > 0 and dn == 0 and dr == 0)
			check("Bola Ferrea: objeto persistente, sin consumo",
				not a.after.own_consumed and a.physical_units == 2 and not r.after.reserve_consumed)
		"iron_ball_speed_order":
			check("Bola Ferrea: Gengar pasa a moverse tras Garchomp a misma prioridad",
				a.after.first_move_actor == "foe" and n.after.first_move_actor == "own"
				and r.after.first_move_actor == "own")
			check("Bola Ferrea: conserva item y reserva no altera turno",
				not a.after.own_consumed and a.physical_units == 2 and not r.after.reserve_consumed)
		"lagging_tail_last":
			check("Cola Plumbea: mismo nivel de prioridad, portador mueve ultimo",
				a.after.first_move_actor == "foe" and n.after.first_move_actor == "own"
				and r.after.first_move_actor == "own")
			check("Cola Plumbea: sin consumo", not a.after.own_consumed and a.physical_units == 2)
		"priority_not_overridden":
			check("Cola Plumbea: Ataque Rapido +1 respeta prioridad ante Tackle",
				a.after.first_move_actor == "own" and n.after.first_move_actor == "own"
				and r.after.first_move_actor == "own")
			check("Cola Plumbea: prioridad no consume objeto",
				not a.after.own_consumed and a.physical_units == 2)
		"reflect_duration_plus_three":
			check("Refleluz: Reflejo gana 3 turnos solo para el portador",
				a.after.reflect_duration > 0 and
				a.after.reflect_duration == n.after.reflect_duration + 3
				and n.after.reflect_duration == r.after.reflect_duration)
			check("Refleluz: pantalla prolongada sin consumo",
				not a.after.own_consumed and a.physical_units == 2 and not r.after.reserve_consumed)
		"no_screen_control":
			check("Refleluz sin pantalla no inventa duracion",
				a.after.reflect_duration == 0 and n.after.reflect_duration == 0
				and r.after.reflect_duration == 0)
			check("Refleluz sin pantalla conservado",
				not a.after.own_consumed and a.physical_units == 2)
		_:
			check("Operacion no autorizada", false)
