extends "res://tests/gameplay/item_automation_v28.gd"

# W01: tests declarativos, sin mecanicas propias ni cambios de producción.
# Hereda los helpers _fixture/_restore_probe/_write_evidence de V28.
const W01_DESCRIPTOR := "res://tests/fixtures/parallel_items/w01_held_v1.json"
const W01_OUT := "res://.godot/parallel_items/w01_held_v1"
var w01_rows: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_w01")
	create_timer(480.0).timeout.connect(func():
		if not done:
			push_error("PARALLEL_ITEMS_W01 timeout")
			quit(2))

func _run_w01() -> void:
	destination = W01_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(W01_DESCRIPTOR))
	if not document is Dictionary:
		push_error("W01 descriptor invalido"); quit(2); return
	var fixture: Dictionary = document
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	check("family/version", fixture.get("schema_version") == 1 and fixture.get("family") == "held_combat_w01" and fixture.get("format") == "gen9calvounifiedv1")
	check("variantes compartidas", fixture.get("variants") == ["active", "none", "reserve"])
	for row: Dictionary in fixture.get("cases", []):
		for seed: int in row.get("seeds", []):
			current_case = String(row.id) + "/" + str(seed)
			var start := checks
			var failures := errors.size()
			var observed := {}
			for mode: String in fixture.variants:
				observed[mode] = await _w01_probe(row, seed, mode)
			_w01_assert(row, observed)
			w01_rows.append({"id": row.id, "item_id": row.item_id, "op": row.op, "seed": seed,
				"checks": checks - start, "status": "PASS" if errors.size() == failures else "FAIL", "observed": observed})
	var report := {"schema_version": 1, "family": "held_combat_w01", "execution_mode": "godot_4_7_native",
		"descriptor_sha256": FileAccess.get_sha256(W01_DESCRIPTOR),
		"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks,
		"errors": errors, "rows": w01_rows,
		"limits": ["Entorno headless: sin GPU ni UI manual", "Snapshot nativo + propietario SaveV2, no asentamiento de victoria en campaña", "Semillas fijas: no certificado porcentaje estadistico de multigolpe", "No certifica supresion, Trick ni interacciones exhaustivas"]}
	var file := FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	if file == null:
		push_error("W01 no puede escribir reporte"); quit(2); return
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true
	print("PARALLEL_ITEMS_W01 ", report.status, " checks=", checks, " rows=", w01_rows.size(), " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)

func _w01_probe(row: Dictionary, seed: int, mode: String) -> Dictionary:
	# _fixture prepara la propiedad fisica con FieldItemService, no equipa via simulador.
	automation = {"actor_species": row.actor_species, "level": row.actor_level,
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4], "variants": ["active", "none", "reserve"],
		"physical_move": row.own_moves[0], "special_move": "water_gun", "speed_target": "mew", "damage_target": row.foe_species}
	var f: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = f.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	actor.moveset.clear(); actor.move_ids.clear()
	for move: String in row.own_moves:
		check("movimiento de fixture disponible " + move, actor.add_move(StringName(move), catalogs))
	if row.hp == "minus_one": actor.current_hp = actor.stats.max_hp - 1
	f.foe = _mon(StringName(row.foe_species), int(row.foe_level), &"foe", [String(row.foe_move)])
	var frozen := JSON.stringify(_owner_data(owner))
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, f.foe, automation.seed)
	check(mode + " inicia combate nativo", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var key := String(row.id) + "_" + str(seed) + "_" + mode
	var restored: Dictionary = await _restore_probe(session, owner, key + "_initial", mode)
	if not restored.get("valid", false): return {"valid": false}
	owner = restored.owner; session = restored.session
	frozen = JSON.stringify(_owner_data(owner))
	var snapshot_before: Dictionary = session.snapshot()
	var actor_before: CreatureInstance = session.battle_state().creature(&"own")
	var foe_before: CreatureInstance = session.battle_state().creature(&"foe")
	var hp_before := actor_before.current_hp
	var foe_hp_before := foe_before.current_hp
	var request_moves: Array = session._checkpoint.get("views", {}).get("p1", {}).get("request", {}).get("active", [{}])[0].get("moves", [])
	var disabled: bool = request_moves.size() > 1 and bool(request_moves[1].get("disabled", false))
	var rejected_unchanged := true
	if row.op == "status_gate":
		var bad: Dictionary = await session.submit("move 2", session.revision)
		rejected_unchanged = not bad.get("accepted", false) and session.snapshot() == snapshot_before
		if mode == "active": check("chaleco rechaza estado sin publicar", rejected_unchanged)
		else: check("sin chaleco activo se permite estado", bad.get("accepted", false))
	var turn_ok := true
	if row.op != "status_gate" or mode == "active":
		var turn: Dictionary = await session.submit("move 1", session.revision)
		turn_ok = turn.get("accepted", false)
		check(mode + " publica turno", turn_ok)
	if not turn_ok:
		await session.close()
		return {"valid": false}
	var after: CreatureInstance = session.battle_state().creature(&"own")
	var reserve: CreatureInstance = session.battle_state().creature(&"reserve")
	var foe_after: CreatureInstance = session.battle_state().creature(&"foe")
	var hp_after := after.current_hp
	var foe_hp_after := foe_after.current_hp
	var hit_count := 0
	for entry: String in session._checkpoint.get("snapshot", {}).get("native", {}).get("log", []):
		if entry.begins_with("|-hitcount|"):
			var parts := entry.split("|")
			if parts.size() > 0: hit_count = int(parts[-1])
	var consumed := after.held_item_consumed
	var bench_consumed := reserve.held_item_consumed
	var native_units := owner.inventory.quantity(StringName(row.item_id))
	for c: CreatureInstance in [after, reserve]:
		if c.held_item_id == StringName(row.item_id) and not c.held_item_consumed: native_units += 1
	var owner_unchanged := JSON.stringify(_owner_data(owner)) == frozen
	check(mode + " sin escritura prematura a campana", owner_unchanged)
	check(mode + " solo uno de dos portadores puede tener objeto", not (after.held_item_id == StringName(row.item_id) and reserve.held_item_id == StringName(row.item_id)))
	check(mode + " inventario fisico nunca se duplica", native_units <= 2 and native_units >= 1)
	var restored_after: Dictionary = await _restore_probe(session, owner, key + "_after", mode)
	if not restored_after.get("valid", false): return {"valid": false}
	owner = restored_after.owner; session = restored_after.session
	var projected := session.battle_state().creature(&"own")
	check(mode + " PS tras restaurar", projected.current_hp == hp_after)
	check(mode + " consumo tras restaurar", projected.held_item_consumed == consumed)
	check(mode + " inventario del propietario restaurado", JSON.stringify(_owner_data(owner)) == frozen)
	var payload := {"before": snapshot_before, "after": session.snapshot(),
		"item_id": String(row.item_id), "id": String(row.id), "seed": seed, "mode": mode,
		"hp_before": hp_before, "hp_after": hp_after, "foe_hp_before": foe_hp_before, "foe_hp_after": foe_hp_after,
		"hit_count": hit_count, "disabled": disabled, "consumed": consumed, "bench_consumed": bench_consumed,
		"native_units": native_units, "owner_unchanged": owner_unchanged, "rejected_unchanged": rejected_unchanged}
	var evidence_hash := _write_evidence(key, payload)
	await session.close()
	return {"valid": true, "restored": true, "evidence": key + ".json", "sha256": evidence_hash,
		"hp_before": hp_before, "hp_after": hp_after, "foe_hp_before": foe_hp_before, "foe_hp_after": foe_hp_after,
		"hit_count": hit_count, "disabled": disabled, "consumed": consumed, "bench_consumed": bench_consumed,
		"native_units": native_units, "owner_unchanged": owner_unchanged, "rejected_unchanged": rejected_unchanged}

func _w01_assert(row: Dictionary, observed: Dictionary) -> void:
	if not observed.has_all(["active", "none", "reserve"]):
		check("variantes ausentes", false); return
	for mode: String in ["active", "none", "reserve"]:
		var o: Dictionary = observed[mode]
		check("variante ejecutada y restaurada " + mode, o.get("valid", false) and o.get("restored", false))
		if not o.get("valid", false): return
		check("propiedad intacta " + mode, o.owner_unchanged)
		check("reserva nunca consume " + mode, not o.bench_consumed)
	var a: Dictionary = observed.active
	var b: Dictionary = observed.none
	var r: Dictionary = observed.reserve
	match String(row.op):
		"status_gate":
			check("prohibicion pertenece al activo", a.disabled and not b.disabled and not r.disabled)
			check("rechazo sin mutacion", a.rejected_unchanged)
			check("chaleco retenido", not a.consumed and a.native_units == 2)
		"special_resistance":
			var damage := int(a.hp_before) - int(a.hp_after)
			var plain := int(b.hp_before) - int(b.hp_after)
			check("ataque especial produce dano", plain > 0)
			check("chaleco reduce dano especial", damage < plain)
			check("reserva no protege otro portador", int(r.hp_before) - int(r.hp_after) == plain)
			check("chaleco no se consume", not a.consumed and a.native_units == 2)
		"physical_control":
			check("chaleco no altera dano fisico", int(a.hp_before)-int(a.hp_after) == int(b.hp_before)-int(b.hp_after) and int(r.hp_before)-int(r.hp_after) == int(b.hp_before)-int(b.hp_after))
			check("chaleco se retiene", not a.consumed and a.native_units == 2)
		"multihit_variable":
			check("dado fuerza cuatro o cinco golpes", a.hit_count in [4, 5])
			check("reserva no modifica dados del activo", r.hit_count == b.hit_count)
			check("dado no se consume", not a.consumed and a.native_units == 2)
		"fixed_multihit_control":
			check("movimiento fijo conserva dos impactos", a.hit_count == 2 and b.hit_count == 2 and r.hit_count == 2)
			check("no consumo con dos impactos", not a.consumed)
		"single_hit_control":
			check("dado no amplifica golpe simple", a.foe_hp_before - a.foe_hp_after == b.foe_hp_before - b.foe_hp_after and r.foe_hp_before - r.foe_hp_after == b.foe_hp_before - b.foe_hp_after)
			check("dado no consumido en golpe simple", not a.consumed)
		"lethal_full":
			check("sash deja exactamente un PS", a.hp_after == 1)
			check("sin sash activo el mismo golpe noquea", b.hp_after == 0 and r.hp_after == 0)
			check("consumo fisico de una unidad", a.consumed and a.native_units == 1 and not r.bench_consumed)
		"lethal_partial":
			check("sash no protege con PS reducidos", a.hp_after == 0 and b.hp_after == 0 and r.hp_after == 0)
			check("sash no se gasta sin activar", not a.consumed and a.native_units == 2)
		"nonlethal_control":
			check("golpe inocuo no activa sash", a.hp_after > 0 and a.hp_after < a.hp_before)
			check("ningun modo gasta sash", not a.consumed and a.native_units == 2 and not r.bench_consumed)
		_: check("operacion declarativa no reconocida", false)
