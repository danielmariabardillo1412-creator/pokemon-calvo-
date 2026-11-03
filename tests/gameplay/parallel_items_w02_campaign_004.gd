extends "res://tests/gameplay/parallel_items_w02_campaign_003.gd"

# W02 CAMPAÑA_004. Hereda únicamente verificadores reales de CAMPAÑA_003;
# esta entrada ejecuta su propia fixture y no reejecuta los bloques 001-010.
const SOURCE_004 := "res://tests/fixtures/parallel_items/w02_campaign_004.json"


func _initialize() -> void:
	capture = false
	call_deferred("_run_camp004")
	create_timer(540.0).timeout.connect(func():
		if not done:
			push_error("CAMP004 W02 watchdog")
			quit(2))


func _run_camp004() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_004"
	DirAccess.make_dir_recursive_absolute(destination)
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_004))
	if not loaded is Dictionary:
		push_error("CAMP004 W02 fixture invalida")
		quit(2)
		return
	automation = loaded
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay regional activo", Variants.apply(catalogs))
	check("formato de combate canónico", String(automation.format) == "gen9calvounifiedv1")
	check("modos tres propietarios", automation.modes == ["active", "none", "reserve"])
	check("campaña correcta", String(automation.campaign) == "CAMP_004_W02")
	check("bloques contiguos", automation.blocks.size() == automation.completed_blocks.size())
	var results: Array = []
	for index: int in automation.blocks.size():
		var block: Dictionary = automation.blocks[index]
		check("orden exacto de campaña", String(block.block) == "%02d" % (index + 1)
			and int(automation.completed_blocks[index]) == index + 1)
		for spec: Dictionary in block.cases:
			current_case = String(spec.scenario)
			var checks_before: int = checks
			var errors_before: int = errors.size()
			check("item pertenece a fila autorizada", block.ids.has(String(spec.id)))
			check("item existe en catálogo vigente", catalogs.item(StringName(spec.id)) != null)
			var observations: Dictionary = {}
			for mode: String in automation.modes:
				match String(spec.kind):
					"heal_flavor", "lum_held":
						observations[mode] = await _probe_berry(spec, mode)
					"field_ev_training":
						observations[mode] = _probe_field_ev(spec, mode)
					"field_pp", "field_lum":
						observations[mode] = _probe_field_use(spec, mode)
					_:
						check("tipo de ensayo desconocido", false)
						observations[mode] = {"valid": false}
			var complete: bool = observations.size() == 3
			for mode: String in automation.modes:
				complete = complete and bool(observations[mode].get("valid", false))
			check("tres variantes de propiedad verificables", complete)
			if complete:
				match String(spec.kind):
					"heal_flavor":
						_compare_berry(spec, observations)
					"lum_held":
						_compare_lum_held(spec, observations)
					"field_ev_training":
						_compare_field_ev(spec, observations)
					"field_pp", "field_lum":
						_compare_field_use(spec, observations)
			results.append({"block": block.block, "id": spec.id, "scenario": spec.scenario,
				"status": "PASS" if complete and errors.size() == errors_before else "FAIL",
				"checks": checks - checks_before, "observed": observations})
	_finish_camp004(results)


func _compare_lum_held(spec: Dictionary, observed: Dictionary) -> void:
	var active: Dictionary = observed.active
	var none: Dictionary = observed.none
	var reserve: Dictionary = observed.reserve
	var spent: bool = bool(spec.consumes)
	check("Lum equipada: consume solo si elimina estado",
		bool(active.consumed) == spent and not bool(none.consumed) and not bool(reserve.consumed))
	check("Lum equipada: stock físico y reserva",
		int(active.total) == (1 if spent else 2)
		and int(none.total) == 2 and int(reserve.total) == 2)
	check("Lum equipada: limpia en titular, no limpia ausente/reserva",
		String(active.status) == ("" if spent else String(spec.status))
		and String(none.status) == String(spec.status)
		and String(reserve.status) == String(spec.status))
	check("Lum equipada: reserva no altera HP ni status",
		int(none.hp) == int(reserve.hp) and String(none.status) == String(reserve.status))
	_verify_held_receipts(spec, observed)


# Los contratos heredados de CAMPAÑA_003 ya verifican SHA256 de los recibos
# para Figy; Lum valida el mismo vínculo de identidad con el fichero propio.
func _verify_held_receipts(spec: Dictionary, observed: Dictionary) -> void:
	for mode: String in automation.modes:
		var rec: Dictionary = observed[mode]
		var path: String = destination + "/" + String(rec.evidence)
		var authentic: bool = FileAccess.file_exists(path)
		if authentic:
			authentic = FileAccess.get_sha256(path) == String(rec.sha256)
		check(mode + " evidencia Lum autenticada SHA256", authentic)
		if authentic:
			var content: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			check(mode + " Lum: dueño, efecto y stock reflejados en recibo",
				content is Dictionary and String(content.scenario) == String(spec.scenario)
				and bool(content.native_consumed) == bool(rec.consumed)
				and int(content.native_hp) == int(rec.hp)
				and int(content.physical_total) == int(rec.total))


# PP / curación de Lum en BOLSA, no inventar disparadores de combate para Leppa.
# active: PARTY con dos unidades; none: PARTY sin item; reserve: STORAGE con 2.
func _probe_field_use(spec: Dictionary, mode: String) -> Dictionary:
	var item: StringName = StringName(spec.id)
	var creature: CreatureInstance = _mon(&"mew", int(automation.level), &"own", ["tackle", "reflect"])
	creature.friendship = 100
	if String(spec.kind) == "field_pp":
		creature.moveset[0].current_pp = creature.moveset[0].max_pp if spec.pp_start is String else int(spec.pp_start)
	else:
		if String(spec.status) != "":
			creature.status_state.persistent_id = StringName(spec.status)
			creature.status_ids.assign([StringName(spec.status)])
		if bool(spec.confused):
			creature.status_state.add_volatile(&"confusion", {"turns": 3})
	var start: Dictionary = creature.to_dict()
	var start_pp: int = creature.moveset[0].current_pp
	var start_friend: int = creature.friendship
	var start_hp: int = creature.current_hp
	var start_status: String = String(creature.status_state.persistent_id)
	var start_confusion: bool = creature.status_state.has_volatile(&"confusion")
	var collection := PlayerCollection.new()
	check(mode + " campo: equipo con dueño propio", collection.party.add_creature(creature))
	if mode == "reserve":
		check(mode + " campo: propietario puede depositarse", collection.deposit(&"own"))
	if mode != "none":
		check(mode + " campo: dos unidades físicas", collection.inventory.add(item, 2))
	var service := Service.new()
	check(mode + " campo: servicio de inventario real",
		service.configure(collection, catalogs, func(): return true))
	var original: CreatureInstance = collection.owned_creature(&"own")
	var before: Dictionary = _owner_data(collection)
	var slot: int = int(spec.slot) if String(spec.kind) == "field_pp" else -1
	var reply: Dictionary = service.use_item(item, &"own", slot)
	var expected_acceptance: bool = bool(spec.applies) and mode != "none"
	check(mode + " campo: admisión y rechazo correctos",
		bool(reply.get("accepted", false)) == expected_acceptance)
	var updated: CreatureInstance = collection.owned_creature(&"own")
	if updated == null:
		check(mode + " campo: Pokemon no desaparece", false)
		return {"valid": false}
	var now_pp: int = updated.moveset[0].current_pp
	var now_status: String = String(updated.status_state.persistent_id)
	var now_confusion: bool = updated.status_state.has_volatile(&"confusion")
	var expected_pp: int = mini(updated.moveset[0].max_pp,
		start_pp + (int(spec.expected_delta) if expected_acceptance else 0)) if String(spec.kind) == "field_pp" else start_pp
	check(mode + " campo: PP estrictos y slot no contaminado", now_pp == expected_pp
		and updated.moveset[1].current_pp == creature.moveset[1].current_pp)
	check(mode + " campo: estado y confusión según contrato",
		now_status == ("" if expected_acceptance and String(spec.kind) == "field_lum" else start_status)
		and now_confusion == (false if expected_acceptance and String(spec.kind) == "field_lum" else start_confusion))
	check(mode + " campo: PS/amistad/EV fuera de objetivo intactos",
		updated.current_hp == start_hp and updated.friendship == start_friend
		and updated.evs == creature.evs)
	check(mode + " campo: identidad y depósito intactos",
		updated.instance_id == &"own"
		and collection.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	check(mode + " campo: copia de entrada sin mutación", original.to_dict() == start)
	if not expected_acceptance:
		check(mode + " campo: rechazo deja toda la colección idéntica",
			not bool(reply.get("accepted", false)) and _owner_data(collection) == before)
	var count: int = collection.inventory.quantity(item)
	check(mode + " campo: consumo de una sola unidad",
		count == (1 if expected_acceptance else (0 if mode == "none" else 2)))
	var state: Dictionary = _owner_data(collection)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(state)
	check(mode + " campo: SaveV2 decodificable", decoded.ok)
	if not decoded.ok:
		return {"valid": false}
	var restored := PlayerCollection.new()
	restored.party = decoded.party
	restored.storage = decoded.storage
	restored.inventory = decoded.inventory
	var restored_mon: CreatureInstance = restored.owned_creature(&"own")
	check(mode + " campo: SaveV2 item y propietario con identidad correcta",
		restored_mon != null and restored.location_of(&"own") == collection.location_of(&"own")
		and restored.inventory.quantity(item) == count)
	if restored_mon != null:
		check(mode + " campo: SaveV2 estado y PP exactos",
			restored_mon.moveset[0].current_pp == now_pp
			and String(restored_mon.status_state.persistent_id) == now_status
			and restored_mon.status_state.has_volatile(&"confusion") == now_confusion
			and restored_mon.friendship == start_friend)
	var name: String = String(spec.scenario) + "_" + mode
	var evidence: Dictionary = {"scenario": spec.scenario, "mode": mode, "item": String(item),
		"kind": spec.kind, "before": before, "after": state, "accepted": bool(reply.get("accepted", false)),
		"pp": now_pp, "status": now_status, "confusion": now_confusion, "bag": count,
		"location": String(collection.location_of(&"own")), "save_v2": decoded.ok}
	var sha: String = _write_evidence(name, evidence)
	check(mode + " campo: recibo SHA256",
		not sha.is_empty() and FileAccess.get_sha256(destination + "/" + name + ".json") == sha)
	return {"valid": true, "accepted": bool(reply.get("accepted", false)),
		"pp": now_pp, "status": now_status, "confusion": now_confusion, "bag": count,
		"location": String(collection.location_of(&"own")), "save_v2": decoded.ok,
		"evidence": name + ".json", "sha256": sha}


func _compare_field_use(spec: Dictionary, observed: Dictionary) -> void:
	var expected: bool = bool(spec.applies)
	var a: Dictionary = observed.active
	var n: Dictionary = observed.none
	var s: Dictionary = observed.reserve
	check("campo: efecto solo con objeto en bolsa, equipo/almacen",
		bool(a.accepted) == expected and not bool(n.accepted)
		and bool(s.accepted) == expected)
	check("campo: bolsa solo consume si efecto real",
		int(a.bag) == (1 if expected else 2)
		and int(n.bag) == 0 and int(s.bag) == (1 if expected else 2))
	check("campo: PC no altera PP/status/condición de aplicación",
		int(a.pp) == int(s.pp) and String(a.status) == String(s.status)
		and bool(a.confusion) == bool(s.confusion))
	check("campo: SaveV2 los tres modos íntegros",
		bool(a.save_v2) and bool(n.save_v2) and bool(s.save_v2))
	for mode: String in automation.modes:
		var rec: Dictionary = observed[mode]
		var path: String = destination + "/" + String(rec.evidence)
		check(mode + " campo: recibo usado realmente", FileAccess.file_exists(path)
			and FileAccess.get_sha256(path) == String(rec.sha256))


func _finish_camp004(results: Array) -> void:
	var verified_blocks: int = 0
	for block: Dictionary in automation.blocks:
		var seen := {}
		var pass_block: bool = results.filter(func(row: Dictionary): return row.block == block.block).size() == block.cases.size()
		for row: Dictionary in results:
			if row.block == block.block:
				pass_block = pass_block and String(row.status) == "PASS"
				pass_block = pass_block and not seen.has(String(row.scenario))
				seen[String(row.scenario)] = true
		for case: Dictionary in block.cases:
			pass_block = pass_block and seen.has(String(case.scenario))
		check("bloque " + String(block.block) + " íntegro", pass_block)
		if pass_block:
			verified_blocks += 1
	var ok: bool = errors.is_empty() and verified_blocks == automation.blocks.size()
	var report: Dictionary = {"status": "PASS" if ok else "FAIL", "worker": "W02",
		"campaign": "CAMP_004", "blocks": verified_blocks, "checks": checks,
		"results": results, "errors": automation_errors,
		"fixture_sha256": FileAccess.get_sha256(SOURCE_004),
		"gpu_tested": false, "ui_tested": false}
	var file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if file == null:
		push_error("CAMP004 W02 no se pudo publicar recibo")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("CAMP004_W02_GODOT ", "PASS" if ok else "FAIL",
		" blocks=", verified_blocks, " checks=", checks)
	quit(0 if ok else 1)
