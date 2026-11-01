extends "res://tests/gameplay/item_automation_v28.gd"

# W01 CAMP_001: solo observación del simulador nativo; no implementar efectos aquí.
# Los casos nuevos se añaden al fixture únicamente en el microbloque autorizado.
const CAMPAIGN_DESCRIPTOR := "res://tests/fixtures/parallel_items/w01_campaign_001.json"
const CAMPAIGN_OUT := "res://.godot/parallel_items/w01_campaign_001"
var campaign_rows: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_campaign")
	create_timer(480.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP_001 timeout")
			quit(2))

func _run_campaign() -> void:
	destination = CAMPAIGN_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMPAIGN_DESCRIPTOR))
	if not parsed is Dictionary:
		push_error("W01 descriptor no es un diccionario JSON")
		quit(2)
		return
	var fixture: Dictionary = parsed
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay regional cargado", Variants.apply(catalogs))
	check("contrato de campaña", fixture.get("schema_version") == 1 and fixture.get("family") == "held_campaign_w01" and fixture.get("format") == "gen9calvounifiedv1")
	check("propiedad en tres variantes", fixture.get("variants") == ["active", "none", "reserve"])
	for row: Dictionary in fixture.get("cases", []):
		for seed: int in row.get("seeds", []):
			current_case = String(row.id) + "/" + str(seed)
			var start: int = checks
			var failures: int = errors.size()
			var observed: Dictionary = {}
			for mode: String in fixture.variants:
				observed[mode] = await _campaign_probe(row, seed, mode)
			_campaign_assert(row, observed)
			campaign_rows.append({
				"id": String(row.id), "stage": String(row.stage), "item_id": String(row.item_id),
				"op": String(row.op), "seed": seed, "checks": checks - start,
				"status": "PASS" if errors.size() == failures else "FAIL",
				"observed": observed
			})
	var report := {
		"schema_version": 1, "family": "held_campaign_w01",
		"execution_mode": "godot_4_7_native",
		"descriptor_sha256": FileAccess.get_sha256(CAMPAIGN_DESCRIPTOR),
		"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks,
		"errors": errors, "rows": campaign_rows,
		"limits": [
			"Headless sin GPU ni UI manual",
			"Estado de batalla/restauracion SaveV2; no asentamiento final en mapa",
			"Semillas fijadas: no prueba exhaustiva de RNG, supresion ni cambios de portador",
			"Los hooks los ejecuta @pkmn/sim fijado; no hay implementacion local"
		]
	}
	var output := FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	if output == null:
		push_error("W01 no pudo escribir reporte")
		quit(2)
		return
	output.store_string(JSON.stringify(report, "  "))
	output.close()
	done = true
	print("W01_CAMP_001 ", report.status, " checks=", checks, " rows=", campaign_rows.size(), " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)

func _campaign_probe(row: Dictionary, seed: int, mode: String) -> Dictionary:
	automation = {
		"actor_species": String(row.actor_species), "level": int(row.level),
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4],
		"variants": ["active", "none", "reserve"],
		"physical_move": String(row.own_move), "special_move": "water_gun",
		"damage_target": String(row.foe_species), "speed_target": String(row.foe_species)
	}
	var prepared: Dictionary = _fixture({"id": row.item_id}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	actor.moveset.clear()
	actor.move_ids.clear()
	check(mode + " movimiento propio existe", actor.add_move(StringName(row.own_move), catalogs))
	if row.hp == "half":
		actor.current_hp = int(actor.stats.max_hp / 2)
	prepared.foe = _mon(StringName(row.foe_species), int(row.level), &"foe", [String(row.foe_move)])
	var item := StringName(row.item_id)
	check(mode + " dos unidades fisicas al inicio", _units(owner, item) == 2)
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check(mode + " se abre sesion real", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var key := String(row.id) + "_" + str(seed) + "_" + mode
	var saved_before: Dictionary = await _restore_probe(session, owner, key + "_initial", mode)
	if not saved_before.get("valid", false):
		return {"valid": false}
	owner = saved_before.owner
	session = saved_before.session
	var frozen: String = JSON.stringify(_owner_data(owner))
	var snapshot_before: Dictionary = session.snapshot()
	var p_before: CreatureInstance = session.battle_state().creature(&"own")
	var foe_before: CreatureInstance = session.battle_state().creature(&"foe")
	var hp_before: int = p_before.current_hp
	var foe_hp_before: int = foe_before.current_hp
	var own_status_before: String = String(p_before.status_state.persistent_id)
	var stale: Dictionary = await session.submit("move 1", session.revision + 1)
	check(mode + " revision obsoleta no muta", not stale.get("accepted", false) and session.snapshot() == snapshot_before)
	var result: Dictionary = await session.submit("move 1", session.revision)
	var accepted: bool = result.get("accepted", false)
	check(mode + " comando nativo aceptado", accepted)
	if not accepted:
		await session.close()
		return {"valid": false}
	var own_after: CreatureInstance = session.battle_state().creature(&"own")
	var foe_after: CreatureInstance = session.battle_state().creature(&"foe")
	var reserve_after: CreatureInstance = session.battle_state().creature(&"reserve")
	var hp_after: int = own_after.current_hp
	var foe_hp_after: int = foe_after.current_hp
	var own_status_after: String = String(own_after.status_state.persistent_id)
	var own_has_item: bool = own_after.held_item_id == item
	var reserve_has_item: bool = reserve_after.held_item_id == item
	var own_consumed: bool = own_after.held_item_consumed
	var reserve_consumed: bool = reserve_after.held_item_consumed
	var stock: int = owner.inventory.quantity(item)
	for creature: CreatureInstance in [own_after, reserve_after]:
		if creature.held_item_id == item and not creature.held_item_consumed:
			stock += 1
	var owner_unchanged: bool = JSON.stringify(_owner_data(owner)) == frozen
	check(mode + " propietario de campaña intacto antes del cierre", owner_unchanged)
	check(mode + " equipo no se clona", not (own_has_item and reserve_has_item))
	check(mode + " inventario fisico mantiene dos unidades", stock == 2)
	var saved_after: Dictionary = await _restore_probe(session, owner, key + "_after", mode)
	if not saved_after.get("valid", false):
		return {"valid": false}
	owner = saved_after.owner
	session = saved_after.session
	var projection: CreatureInstance = session.battle_state().creature(&"own")
	check(mode + " PS restaurados", projection.current_hp == hp_after)
	check(mode + " equipo restaurado", (projection.held_item_id == item) == own_has_item)
	check(mode + " consumo restaurado", projection.held_item_consumed == own_consumed)
	check(mode + " estado restaurado", String(projection.status_state.persistent_id) == own_status_after)
	check(mode + " dueno SaveV2 restaurado", JSON.stringify(_owner_data(owner)) == frozen)
	var payload: Dictionary = {
		"id": String(row.id), "seed": seed, "mode": mode,
		"before": snapshot_before, "after": session.snapshot(),
		"hp_before": hp_before, "hp_after": hp_after,
		"foe_hp_before": foe_hp_before, "foe_hp_after": foe_hp_after,
		"own_status_before": own_status_before, "own_status_after": own_status_after,
		"own_has_item": own_has_item, "reserve_has_item": reserve_has_item,
		"own_consumed": own_consumed, "reserve_consumed": reserve_consumed,
		"physical_units": stock, "owner_unchanged": owner_unchanged
	}
	var evidence_hash: String = _write_evidence(key, payload)
	await session.close()
	return {
		"valid": true, "restored": true, "evidence": key + ".json", "sha256": evidence_hash,
		"hp_before": hp_before, "hp_after": hp_after,
		"foe_hp_before": foe_hp_before, "foe_hp_after": foe_hp_after,
		"own_status_before": own_status_before, "own_status_after": own_status_after,
		"own_has_item": own_has_item, "reserve_has_item": reserve_has_item,
		"own_consumed": own_consumed, "reserve_consumed": reserve_consumed,
		"physical_units": stock, "owner_unchanged": owner_unchanged
	}

func _campaign_assert(row: Dictionary, observed: Dictionary) -> void:
	if not observed.has_all(["active", "none", "reserve"]):
		check("faltan variantes", false)
		return
	for mode: String in ["active", "none", "reserve"]:
		var o: Dictionary = observed[mode]
		check("ejecucion y restauracion " + mode, o.get("valid", false) and o.get("restored", false))
		if not o.get("valid", false):
			return
		check("equipo pertenece a actor/reserva " + mode,
			bool(o.own_has_item) == (mode == "active") and bool(o.reserve_has_item) == (mode == "reserve"))
		check("equipo retenido " + mode, not o.own_consumed and not o.reserve_consumed and o.physical_units == 2)
		check("propietario sin cambios prematuros " + mode, o.owner_unchanged)
	var a: Dictionary = observed.active
	var n: Dictionary = observed.none
	var r: Dictionary = observed.reserve
	var delta_a: int = int(a.hp_after) - int(a.hp_before)
	var delta_n: int = int(n.hp_after) - int(n.hp_before)
	var delta_r: int = int(r.hp_after) - int(r.hp_before)
	var foe_loss_a: int = int(a.foe_hp_before) - int(a.foe_hp_after)
	var foe_loss_n: int = int(n.foe_hp_before) - int(n.foe_hp_after)
	var foe_loss_r: int = int(r.foe_hp_before) - int(r.foe_hp_after)
	check("mismo estado inicial de comparacion", a.hp_before == n.hp_before and n.hp_before == r.hp_before)
	check("efecto solo en portador activo: reserva igual al control", delta_r == delta_n)
	check("dano al rival igual entre control y reserva", foe_loss_n == foe_loss_r)
	if String(row.op) != "super_effective":
		check("dano al rival no modificado", foe_loss_a == foe_loss_n)
	check("estado inicial igual en tres variantes",
		a.own_status_before == n.own_status_before and n.own_status_before == r.own_status_before)
	match String(row.op):
		"poison_heal":
			check("Lodo Negro cura al tipo Veneno danado", delta_a > 0 and delta_n == 0)
		"poison_full":
			check("Lodo Negro no cura por encima del maximo", delta_a == 0 and delta_n == 0)
		"nonpoison_damage":
			check("Lodo Negro dana al portador no Veneno", delta_a < 0 and delta_n == 0)
		"damage_heal":
			check("Campana Concha cura al causar dano", foe_loss_n > 0 and delta_a > delta_n and delta_n == 0)
		"no_hit", "immune_no_heal":
			check("Campana Concha no cura sin dano efectivo", foe_loss_n == 0 and delta_a == 0 and delta_n == 0)
		"drain_boost":
			check("Raiz Grande potencia drenaje real", foe_loss_n > 0 and delta_a > delta_n and delta_n > 0)
		"no_drain":
			check("Raiz Grande no cura sin movimiento drenante", delta_a == 0 and delta_n == 0)
		"eviolite_resist":
			var damage_a: int = int(a.hp_before) - int(a.hp_after)
			var damage_n: int = int(n.hp_before) - int(n.hp_after)
			check("Mineral Evolutivo protege una especie evolucionable",
				damage_n > 0 and damage_a >= 0 and damage_a < damage_n)
		"eviolite_final":
			check("Mineral Evolutivo no protege forma final", delta_n < 0 and delta_a == delta_n)
		"super_effective":
			check("Cinta Experto aumenta dano supereficaz sin saturar PS",
				foe_loss_n > 0 and foe_loss_a > foe_loss_n and foe_loss_a < int(a.foe_hp_before))
			check("Cinta Experto no altera PS de atacante", delta_a == delta_n)
		"neutral_control":
			check("Cinta Experto no aumenta dano neutro", foe_loss_n > 0 and foe_loss_a == foe_loss_n)
		"powder_immunity":
			check("Espora duerme control y reserva pero no al portador",
				a.own_status_after == "" and n.own_status_after == "sleep" and r.own_status_after == "sleep")
			check("Polvo no altera PS", delta_a == 0 and delta_n == 0)
		"weather_immunity":
			check("Gafas impiden dano de tormenta de arena",
				delta_n < 0 and delta_a == 0 and delta_r == delta_n)
		"irrelevant_control":
			check("Sin polvo ni clima las gafas no cambian efectos",
				delta_a == 0 and delta_n == 0 and a.own_status_after == "" and n.own_status_after == "")
		_:
			check("operacion declarativa no autorizada", false)
