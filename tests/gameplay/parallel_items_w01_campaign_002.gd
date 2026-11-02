extends "res://tests/gameplay/item_automation_v28.gd"

# W01 CAMP_002 ITER_02: observacion del motor nativo ya existente; ningun efecto aqui.
# Usa _fixture / FieldItemService y _restore_probe, NO reproduce hooks de items.
const SPEC := "res://tests/fixtures/parallel_items/w01_campaign_002.json"
const W01_C002_OUTPUT := "res://.godot/parallel_items/w01_campaign_002"
var campaign_rows: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_w01_campaign_002")
	create_timer(480.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP002 timeout")
			quit(2))

func _run_w01_campaign_002() -> void:
	destination = W01_C002_OUTPUT
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	if not parsed is Dictionary:
		push_error("W01 CAMP002 fixture no es un Dictionary")
		quit(2)
		return
	var fixture: Dictionary = parsed
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay regional", Variants.apply(catalogs))
	check("contrato de campaña", fixture.get("schema_version") == 1 and fixture.get("campaign") == "CAMP_002" and fixture.get("worker") == "W01")
	check("expectativas no resultados falsos", fixture.get("execution_state") == "EXPECTED_ONLY_NO_RUNTIME")
	check("modos aislados", fixture.get("variants") == ["active", "none", "reserve"])
	var seen: Array = []
	for row: Dictionary in fixture.get("cases", []):
		check("ID nuevo en sobre autorizado", String(row.item_id) in ["ability_shield", "absorb_bulb", "adrenaline_orb"])
		check("escenario no duplicado", not seen.has(String(row.id)))
		seen.append(String(row.id))
		for value: Variant in row.get("seeds", []):
			if not (value is int or value is float) or int(value) < 0 or int(value) > 65535 or float(value) != float(int(value)):
				check("semilla invalida", false)
				continue
			var seed: int = int(value)
			current_case = String(row.id) + "/" + str(seed)
			var before_checks: int = checks
			var before_errors: int = errors.size()
			var observed: Dictionary = {}
			for mode: String in ["active", "none", "reserve"]:
				observed[mode] = await _w01_observe(row, seed, mode)
			_w01_compare(row, observed)
			campaign_rows.append({
				"id": String(row.id), "item_id": String(row.item_id),
				"seed": seed, "checks": checks - before_checks,
				"status": "PASS" if errors.size() == before_errors else "FAIL",
				"observed": observed
			})
	check("7 casos", seen.size() == 7)
	check("10 pares caso-semilla", campaign_rows.size() == 10)
	var summary := {
		"schema_version": 1, "campaign": "CAMP_002", "worker": "W01",
		"execution_mode": "godot_4_7_native", "descriptor_sha256": FileAccess.get_sha256(SPEC),
		"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks,
		"errors": errors, "rows": campaign_rows,
		"limits": ["Comparaciones de entrada y primer turno con semillas fijas",
			"Sin GPU/UI ni asentamiento final de campana", "Sin pruebas completas de Trick ni supresion global",
			"Los hooks nativos siguen en @pkmn/sim 0.10.11"]
	}
	var f := FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	if f == null:
		push_error("No puede escribir report.json")
		quit(2)
		return
	f.store_string(JSON.stringify(summary, "  "))
	f.close()
	done = true
	print("W01_CAMP002_GODOT ", summary.status, " checks=", checks, " runs=", campaign_rows.size(), " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)

func _native_row(session: RefCounted, side_id: String, instance: String) -> Dictionary:
	var rosters: Array = session._checkpoint.get("roster", [])
	for side: Dictionary in rosters:
		if String(side.get("id", "")) != side_id:
			continue
		for entry: Dictionary in side.get("pokemon", []):
			if String(entry.get("instance_id", "")) == instance:
				return entry
	return {}

func _frame(session: RefCounted, item: StringName) -> Dictionary:
	var own: CreatureInstance = session.battle_state().creature(&"own")
	var bench: CreatureInstance = session.battle_state().creature(&"reserve")
	var native: Dictionary = _native_row(session, "p1", "own")
	var bench_native: Dictionary = _native_row(session, "p1", "reserve")
	var props: Dictionary = native.get("boosts", {})
	var log_lines: Array = session._checkpoint.get("snapshot", {}).get("native", {}).get("log", [])
	var last_log: Array = []
	for line: String in log_lines:
		if line.begins_with("|move|") or line.begins_with("|-start|") or line.begins_with("|-block|") or line.begins_with("|-activate|") or line.begins_with("|-boost|") or line.begins_with("|-enditem|"):
			last_log.append(line)
	return {
		"valid": native.has("boosts") and bench_native.has("boosts"),
		"hp": own.current_hp,
		"spe": int(props.get("spe", 0)),
		"spa": int(props.get("spa", 0)),
		"atk": int(props.get("atk", 0)),
		"ability": String(native.get("ability", "")),
		"gastro_acid": native.get("volatiles", []).has("gastroacid"),
		"native_item": String(native.get("item", "")),
		"native_bench_item": String(bench_native.get("item", "")),
		"active_has_item": own.held_item_id == item,
		"reserve_has_item": bench.held_item_id == item,
		"consumed": own.held_item_consumed,
		"reserve_consumed": bench.held_item_consumed,
		"log_markers": last_log
	}

func _w01_observe(row: Dictionary, seed: int, mode: String) -> Dictionary:
	automation = {
		"actor_species": String(row.actor_species), "level": 100,
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4],
		"physical_move": String(row.own_move), "special_move": "water_gun",
		"speed_target": String(row.foe_species), "damage_target": String(row.foe_species)
	}
	var prepared: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	_set_effect_moves(actor, String(row.own_move))
	if not String(row.actor_ability).is_empty():
		actor.ability_id = StringName(row.actor_ability)
	var bench: CreatureInstance = owner.owned_creature(&"reserve")
	if not String(row.actor_ability).is_empty():
		bench.ability_id = StringName(row.actor_ability)
	prepared.foe = _mon(StringName(row.foe_species), 100, &"foe", [String(row.foe_move)])
	if not String(row.foe_ability).is_empty():
		prepared.foe.ability_id = StringName(row.foe_ability)
	var id := StringName(row.item_id)
	check(mode + " inventario de inicio igual a 2", _units(owner, id) == 2)
	var frozen: String = JSON.stringify(_owner_data(owner))
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check(mode + " abre batalla nativa", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var start: Dictionary = _frame(session, id)
	check(mode + " snapshot nativo de inicio", start.valid)
	if not start.valid:
		await session.close()
		return {"valid": false}
	var original: Dictionary = session.snapshot()
	var stale: Dictionary = await session.submit("move 1", session.revision + 1)
	check(mode + " revision invalida no muta", not stale.get("accepted", false) and session.snapshot() == original)
	var moved: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " turno aceptado por motor", moved.get("accepted", false))
	if not moved.get("accepted", false):
		await session.close()
		return {"valid": false}
	var after: Dictionary = _frame(session, id)
	check(mode + " snapshot nativo post turno", after.valid)
	var physical: int = owner.inventory.quantity(id)
	for c: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if c.held_item_id == id and not c.held_item_consumed:
			physical += 1
	var owner_unchanged: bool = JSON.stringify(_owner_data(owner)) == frozen
	check(mode + " el propietario no publica cambios antes de cerrar", owner_unchanged)
	check(mode + " solo uno activo o reserva porta item", not (after.active_has_item and after.reserve_has_item))
	var key: String = String(row.id) + "_" + str(seed) + "_" + mode
	var final_snapshot: Dictionary = session.snapshot()
	# SaveV2 real: grabar propietario y checkpoint, cerrar sesion, decodificar,
	# restaurar con el motor nativo y comparar el estado exacto tras el turno.
	var restore_key: String = key + "_savev2"
	var reloaded: Dictionary = await _restore_probe(session, owner, restore_key, mode + " SaveV2")
	if not reloaded.get("valid", false):
		return {"valid": false}
	owner = reloaded.owner
	session = reloaded.session
	var restored_frame: Dictionary = _frame(session, id)
	var restored_checkpoint_equal: bool = session.snapshot() == final_snapshot
	var restored_owner_unchanged: bool = JSON.stringify(_owner_data(owner)) == frozen
	var restored_frame_equal: bool = restored_frame == after
	var restored_stock: int = owner.inventory.quantity(id)
	for restored_creature: CreatureInstance in [session.battle_state().creature(&"own"), session.battle_state().creature(&"reserve")]:
		if restored_creature.held_item_id == id and not restored_creature.held_item_consumed:
			restored_stock += 1
	check(mode + " SaveV2 snapshot exacto", restored_checkpoint_equal)
	check(mode + " SaveV2 mismo fotograma nativo", restored_frame_equal)
	check(mode + " SaveV2 propietario intacto", restored_owner_unchanged)
	check(mode + " SaveV2 stock sin duplicacion", restored_stock == physical)
	var restore_hash: String = FileAccess.get_sha256(destination + "/" + restore_key + ".json")
	check(mode + " SaveV2 recibo escrito", restore_hash.length() == 64)
	var proof: Dictionary = {
		"id": String(row.id), "item_id": String(row.item_id), "seed": seed, "mode": mode,
		"start": start, "after": after, "initial": original, "final": final_snapshot,
		"owner_unchanged": owner_unchanged, "physical_units": physical,
		"restore_valid": true, "restore_exact": restored_checkpoint_equal,
		"restored_frame_equal": restored_frame_equal,
		"restored_frame": restored_frame, "restored_checkpoint": session.snapshot(),
		"restored_owner_unchanged": restored_owner_unchanged,
		"restored_physical_units": restored_stock,
		"restore_evidence": restore_key + ".json", "restore_sha256": restore_hash
	}
	var hash: String = _write_evidence(key, proof)
	await session.close()
	return {
		"valid": true, "start": start, "after": after,
		"owner_unchanged": owner_unchanged, "physical_units": physical,
		"restore_valid": true, "restore_exact": restored_checkpoint_equal,
		"restored_frame_equal": restored_frame_equal,
		"restored_frame": restored_frame,
		"restored_owner_unchanged": restored_owner_unchanged,
		"restored_physical_units": restored_stock,
		"restore_evidence": restore_key + ".json", "restore_sha256": restore_hash,
		"evidence": key + ".json", "sha256": hash
	}

func _w01_compare(row: Dictionary, observed: Dictionary) -> void:
	if not observed.has_all(["active", "none", "reserve"]):
		check("faltan variantes de control", false)
		return
	for mode: String in ["active", "none", "reserve"]:
		var o: Dictionary = observed[mode]
		check("variante nativa disponible " + mode, o.get("valid", false))
		if not o.get("valid", false):
			return
		var at_start: Dictionary = o.start
		var after: Dictionary = o.after
		check("solo titular correcto en entrada " + mode,
			bool(at_start.active_has_item) == (mode == "active") and bool(at_start.reserve_has_item) == (mode == "reserve"))
		check("dueno no modificado " + mode, o.owner_unchanged)
		check("reserva sin consumo " + mode, not after.reserve_consumed)
		var expected_consumed: bool = bool(row.expected[mode].consumed)
		check("consumo segun activacion de motor " + mode, after.consumed == expected_consumed)
		check("propiedad despues del turno " + mode,
			after.reserve_has_item == (mode == "reserve"))
		check("ninguna duplicacion fisica " + mode,
			int(o.physical_units) == (1 if expected_consumed else 2))
		check("SaveV2 exacto y propietario autentico " + mode,
			o.get("restore_valid", false) and o.get("restore_exact", false)
			and o.get("restored_frame_equal", false) and o.get("restored_owner_unchanged", false))
		check("SaveV2 preserva tenencia y consumo " + mode,
			o.restored_frame == after and int(o.restored_physical_units) == int(o.physical_units))
	var active: Dictionary = observed.active
	var plain: Dictionary = observed.none
	var reserve: Dictionary = observed.reserve
	var a: Dictionary = active.after
	var n: Dictionary = plain.after
	var r: Dictionary = reserve.after
	match String(row.mechanic):
		"ability_suppression":
			check("escudo no cambia habilidad base", a.ability == "synchronize" and n.ability == "synchronize")
			if String(row.trigger) == "ability_suppression_attempt":
				check("Gastro Acid suprime control y no portador",
					not a.gastro_acid and n.gastro_acid and r.gastro_acid)
			else:
				check("sin ataque de supresion ninguno recibe Gastro Acid",
					not a.gastro_acid and not n.gastro_acid and not r.gastro_acid)
		"water_hit_stat_boost":
			if String(row.trigger) == "damaging_water_hit":
				check("Tuberculo sube AtEsp solo al portador",
					a.spa == 1 and n.spa == 0 and r.spa == 0)
				check("impacto de Agua real", a.hp < active.start.hp and n.hp < plain.start.hp)
			else:
				check("Tuberculo no aumenta AtEsp sin impacto de Agua",
					a.spa == 0 and n.spa == 0 and r.spa == 0)
		"intimidate_speed_boost":
			if String(row.trigger) == "opposing_intimidate":
				check("Nerviosfera activa +1 Velocidad al entrar",
					active.start.spe == 1 and plain.start.spe == 0 and reserve.start.spe == 0)
				check("Nerviosfera mantiene +1 tras primer turno",
					a.spe == 1 and n.spe == 0 and r.spe == 0)
			else:
				check("Sin intimidacion no hay bonificacion de Nerviosfera",
					a.spe == 0 and n.spe == 0 and r.spe == 0)
		_:
			check("mecanica no autorizada en CAMPAÑA_002", false)
