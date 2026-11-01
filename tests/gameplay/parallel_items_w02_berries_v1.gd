extends "res://tests/gameplay/item_automation_v28.gd"

# Ensayos W02 exclusivamente: las reglas de batalla siguen en @pkmn/sim.
# Reutiliza las sesiones nativas, el guardado y las aserciones V28, sin callbacks nuevos.
const MATRIZ := "res://tests/fixtures/parallel_items/w02_berries_v1.json"
const RivalControlado = preload("res://tests/gameplay/item_automation_opponent_v28.gd")


func _initialize() -> void:
	capture = false
	call_deferred("_ejecutar_w02")
	create_timer(360.0).timeout.connect(func():
		if not done:
			push_error("W02: tiempo de prueba agotado")
			quit(2))


func _ejecutar_w02() -> void:
	destination = "res://.godot/parallel_items/w02_berries_v1"
	DirAccess.make_dir_recursive_absolute(destination)
	automation = JSON.parse_string(FileAccess.get_file_as_string(MATRIZ))
	if automation.is_empty():
		check("Matriz W02 legible", false)
		_terminar([])
		return
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Overlay regional existente", Variants.apply(catalogs))
	check("Formato nativo fijado", automation.format == "gen9calvounifiedv1")
	check("Los tres modos obligatorios", automation.variants == ["active", "none", "reserve"])
	check("Siete contratos acotados", automation.cases.size() == 7)
	var resultados: Array = []
	for caso: Dictionary in automation.cases:
		current_case = String(caso.scenario)
		var inicio: int = checks
		var fallos: int = errors.size()
		var modos := {}
		for modo: String in automation.variants:
			modos[modo] = await _ensayar(caso, modo)
		var valido: bool = modos.has("active") and modos.has("none") and modos.has("reserve")
		if valido:
			for modo: String in automation.variants:
				valido = valido and bool(modos[modo].get("valid", false))
		check("Tres modos ejecutados y válidos", valido)
		if valido:
			_comparar(caso, modos)
		resultados.append({"id": caso.id, "scenario": caso.scenario, "status": "PASS" if errors.size() == fallos and valido else "FAIL", "checks": checks - inicio, "observed": modos})
	_terminar(resultados)


func _comparar(caso: Dictionary, modos: Dictionary) -> void:
	var activo: Dictionary = modos.active
	var sin_objeto: Dictionary = modos.none
	var reserva: Dictionary = modos.reserve
	var activa: bool = bool(caso.consumes)
	check("El consumo sólo afecta al portador activo", activo.consumed == activa and not sin_objeto.consumed and not reserva.consumed)
	check("Cantidad total física exacta", activo.stock_total == (1 if activa else 2) and sin_objeto.stock_total == 2 and reserva.stock_total == 2)
	check("Mismo estado base en controles", sin_objeto.hp == reserva.hp and sin_objeto.status == reserva.status and sin_objeto.damage == reserva.damage)
	match String(caso.kind):
		"low_hp":
			check("Zidra: cura exactamente 1/4 de PS máximos", activo.hp - sin_objeto.hp == maxi(1, int(floor(float(activo.max_hp) / 4.0))))
			check("Zidra: curación no rebasa máximo", activo.hp <= activo.max_hp)
		"high_hp":
			check("Zidra: sin consumo por encima del umbral", activo.hp == sin_objeto.hp and not activo.consumed)
		"poison":
			check("Ziuela: elimina el veneno sólo del portador", activo.status == "" and sin_objeto.status == "poison" and reserva.status == "poison")
		"healthy":
			check("Ziuela: no se gasta sin estado", activo.status == "" and not activo.consumed)
		"super_dark":
			check("Dillo: Siniestro supereficaz causa menos daño", activo.damage > 0 and activo.damage < sin_objeto.damage and reserva.damage == sin_objeto.damage)
		"neutral_dark", "other_type":
			check("Dillo: no se consume ni protege sin supereficacia", activo.damage == sin_objeto.damage and not activo.consumed)
		_:
			check("Contrato desconocido", false)


func _ensayar(caso: Dictionary, modo: String) -> Dictionary:
	var item := StringName(caso.id)
	var propio: CreatureInstance = _mon(StringName(caso.actor_species), int(automation.level), &"own", ["amnesia"])
	var suplente: CreatureInstance = _mon(&"mew", int(automation.level), &"reserve", ["amnesia"])
	var rival: CreatureInstance = _mon(&"mew", int(automation.level), &"foe", [String(caso.foe_move)])
	if caso.kind == "low_hp":
		propio.current_hp = maxi(1, int(floor(float(propio.stats.max_hp) / 4.0)))
	elif caso.kind == "high_hp":
		propio.current_hp = propio.stats.max_hp - 1
	elif caso.kind == "poison":
		propio.status_state.persistent_id = &"poison"
		propio.status_ids.assign([&"poison"])
	var propietario := PlayerCollection.new()
	check(modo + " dueño activo creado", propietario.party.add_creature(propio))
	check(modo + " suplente creado", propietario.party.add_creature(suplente))
	check(modo + " unidades iniciales añadidas", propietario.inventory.add(item, 2))
	propietario.inventory.add(&"poke_doll", 1)
	var servicio := Service.new()
	check(modo + " servicio de propiedad existente", servicio.configure(propietario, catalogs, func(): return true))
	if modo != "none":
		check(modo + " equipamiento por servicio", servicio.equip(item, &"own" if modo == "active" else &"reserve").accepted)
	check(modo + " dos unidades físicas iniciales", _units(propietario, item) == 2)
	var entrada_hp: int = propio.current_hp
	var partida := RivalControlado.new(catalogs, propietario, automation.format)
	var abierta: bool = await partida.begin_wild(self, rival, automation.seed)
	check(modo + " combate nativo real abierto", abierta)
	if not abierta:
		await partida.close()
		return {"valid": false}
	partida.scripted_foe_choice = "move 1"
	var antes: Dictionary = partida.snapshot()
	var obsoleta: Dictionary = await partida.submit("move 1", partida.revision + 1)
	check(modo + " rechazo sin publicar turno obsoleto", not obsoleta.accepted and partida.snapshot() == antes)
	var congelado: String = JSON.stringify(_owner_data(propietario))
	var accion: Dictionary = await partida.submit("move 1", partida.revision)
	check(modo + " turno real aceptado", accion.accepted)
	if not accion.accepted:
		await partida.close()
		return {"valid": false}
	var criatura: CreatureInstance = partida.battle_state().creature(&"own")
	var hp: int = criatura.current_hp
	var estado: String = String(criatura.status_state.persistent_id)
	var consumida: bool = criatura.held_item_consumed
	check(modo + " no se publica consumo antes del cierre", JSON.stringify(_owner_data(propietario)) == congelado and _units(propietario, item) == 2)
	var nombre: String = String(caso.scenario) + "_" + modo
	var restaurada: Dictionary = await _restore_probe(partida, propietario, nombre + "_restauracion", modo, RivalControlado)
	if not restaurada.get("valid", false):
		return {"valid": false}
	partida = restaurada.session
	propietario = restaurada.owner
	var criatura_repuesta: CreatureInstance = partida.battle_state().creature(&"own")
	check(modo + " estado nativo restaurado", criatura_repuesta.current_hp == hp and String(criatura_repuesta.status_state.persistent_id) == estado and criatura_repuesta.held_item_consumed == consumida)
	var retirada: Dictionary = await partida.use_item(&"poke_doll", &"own", partida.revision)
	check(modo + " cierre real de combate FLED", retirada.accepted and partida.completion_reason == "FLED")
	if not retirada.accepted:
		await partida.close()
		return {"valid": false}
	var publicado: Dictionary = _owner_data(propietario)
	check(modo + " consumo publicado al dueño", propietario.owned_creature(&"own").held_item_consumed == consumida)
	var segunda: Dictionary = await partida.use_item(&"poke_doll", &"own", partida.revision)
	check(modo + " cierre duplicado sin cambio", not segunda.accepted and _owner_data(propietario) == publicado)
	var guardado: Dictionary = SaveGameRepository.new().decode_snapshot(publicado)
	check(modo + " SaveV2 decodifica al dueño", guardado.ok)
	if not guardado.ok:
		await partida.close()
		return {"valid": false}
	var nuevo := PlayerCollection.new()
	nuevo.party = guardado.party
	nuevo.storage = guardado.storage
	nuevo.inventory = guardado.inventory
	check(modo + " HP/estado/consumo guardados", nuevo.owned_creature(&"own").current_hp == hp and String(nuevo.owned_creature(&"own").status_state.persistent_id) == estado and nuevo.owned_creature(&"own").held_item_consumed == consumida)
	check(modo + " stock único tras recarga", _units(propietario, item) == _units(nuevo, item) and nuevo.inventory.quantity(item) == (2 if modo == "none" else 1))
	if modo == "reserve":
		check("El suplente conserva su baya", nuevo.owned_creature(&"reserve").held_item_id == item and not nuevo.owned_creature(&"reserve").held_item_consumed)
	await partida.close()
	var bruto := {"scenario": caso.scenario, "mode": modo, "before": antes, "owner_after": publicado, "native_hp": hp, "native_status": estado, "native_consumed": consumida, "stock_total": _units(nuevo, item)}
	var evidencia: String = nombre + ".json"
	var firma: String = _write_evidence(nombre, bruto)
	return {"valid": true, "hp": hp, "max_hp": criatura_repuesta.stats.max_hp,
		"status": estado, "damage": entrada_hp - hp,
		"consumed": consumida, "stock_total": _units(nuevo, item),
		"bag": nuevo.inventory.quantity(item), "evidence": evidencia, "sha256": firma,
		"restored": true, "settled_once": true, "save_v2": true}


func _terminar(resultados: Array) -> void:
	var completos: bool = resultados.size() == 7
	for fila: Dictionary in resultados:
		completos = completos and fila.status == "PASS"
	check("Matriz completa sin omisiones", completos)
	var informe := {"schema_version": 1, "family": "consumable_held_berries",
		"status": "PASS" if errors.is_empty() and completos else "FAIL",
		"checks": checks, "errors": automation_errors, "cases": resultados,
		"full_item_certification": false, "gpu": false,
		"limits": ["Sólo combate individual y FLED", "No se certifican inmunidades ni dobles", "No sustituye revisión visual/GPU"]}
	var fichero := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if fichero == null:
		push_error("W02: no se pudo escribir informe")
		quit(2)
		return
	fichero.store_string(JSON.stringify(informe, "  "))
	fichero.close()
	done = true
	print("PARALLEL_ITEMS_W02 ", informe.status, " checks=", checks, " casos=", resultados.size())
	quit(0 if informe.status == "PASS" else 1)
