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
					"heal_flavor", "lum_held", "heal_quarter_held", "inert_held":
						observations[mode] = await _probe_berry(spec, mode)
					"field_ev_training":
						observations[mode] = _probe_field_ev(spec, mode)
					"field_pp", "field_lum", "field_heal", "field_unsupported", "field_medicine":
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
					"heal_quarter_held":
						_compare_quarter_held(spec, observations)
					"inert_held":
						_compare_inert_held(spec, observations)
					"field_ev_training":
						_compare_field_ev(spec, observations)
					"field_pp", "field_lum", "field_heal", "field_unsupported", "field_medicine":
						_compare_field_use(spec, observations)
			results.append({"block": block.block, "id": spec.id, "scenario": spec.scenario,
				"status": "PASS" if complete and errors.size() == errors_before else "FAIL",
				"checks": checks - checks_before, "observed": observations})
	_finish_camp004(results)



# Sitrus: 1/4 del maximo de HP, umbral de 1/2. Se compara con
# el mismo turno nativo SIN baya y con otra unidad en la reserva.
func _compare_quarter_held(spec: Dictionary, observed: Dictionary) -> void:
	var active: Dictionary = observed.active
	var absent: Dictionary = observed.none
	var storage: Dictionary = observed.reserve
	var consume: bool = bool(spec.consumes)
	var amount: int = int(floor(float(active.max_hp) / 4.0)) if consume else 0
	check("Sitrus 1/4 HP real tras cruzar umbral", 
		int(active.hp) == mini(int(active.max_hp), int(absent.hp) + amount))
	check("Sitrus no afecta testigo ni reserva",
		int(absent.hp) == int(storage.hp)
		and String(active.status) == String(absent.status)
		and String(absent.status) == String(storage.status))
	check("Sitrus consume exactamente una sola si procede",
		bool(active.consumed) == consume and not bool(absent.consumed)
		and not bool(storage.consumed)
		and int(active.total) == (1 if consume else 2)
		and int(absent.total) == 2 and int(storage.total) == 2)
	check("Sitrus no provoca confusion",
		not bool(active.confusion) and not bool(absent.confusion)
		and not bool(storage.confusion))
	_verify_held_receipts(spec, observed)


# Razz no tiene efecto competitivo activo. PASS aqui significa
# prueba NEGATIVA (no efecto / no consumo), NO implementacion de uso.
func _compare_inert_held(spec: Dictionary, observed: Dictionary) -> void:
	var active: Dictionary = observed.active
	var absent: Dictionary = observed.none
	var storage: Dictionary = observed.reserve
	check("Razz equipada permanece inerte",
		not bool(active.consumed) and not bool(absent.consumed)
		and not bool(storage.consumed))
	check("Razz no altera HP ni estado contra testigos",
		int(active.hp) == int(absent.hp) and int(absent.hp) == int(storage.hp)
		and String(active.status) == String(absent.status)
		and String(absent.status) == String(storage.status))
	check("Razz inerte mantiene todas las unidades",
		int(active.total) == 2 and int(absent.total) == 2 and int(storage.total) == 2)
	_verify_held_receipts(spec, observed)

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
	creature.friendship = int(spec.get("start_friendship", 100))
	if spec.has("pp_gain"):
		for index: int in range(2):
			var starting: Variant = spec.get("pp%d_start" % index, "full")
			creature.moveset[index].current_pp = (
				creature.moveset[index].max_pp if starting is String else int(starting))
	if String(spec.kind) in ["field_heal", "field_medicine"]:
		match String(spec.get("start_hp", "full")):
			"half":
				creature.current_hp = maxi(1, int(creature.stats.max_hp / 2))
			"missing_7":
				creature.current_hp = maxi(1, creature.stats.max_hp - 7)
			"full":
				pass
			_:
				check("campo medicina: HP inicial desconocido", false)
	if String(spec.kind) == "field_pp":
		creature.moveset[0].current_pp = creature.moveset[0].max_pp if spec.pp_start is String else int(spec.pp_start)
	else:
		if String(spec.get("status", "")) != "":
			creature.status_state.persistent_id = StringName(spec.status)
			creature.status_ids.assign([StringName(spec.status)])
			if String(spec.status) == "sleep":
				creature.status_state.turns_remaining = 2
				creature.status_state.rest_sleep = true
				creature.status_state.add_volatile(&"nightmare")
			elif String(spec.status) == "badly_poisoned":
				creature.status_state.toxic_counter = 3
		if bool(spec.get("confused", false)):
			creature.status_state.add_volatile(&"confusion", {"turns": 3})
	var start: Dictionary = creature.to_dict()
	var start_pp: int = creature.moveset[0].current_pp
	var start_pp_second: int = creature.moveset[1].current_pp
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
	var sleep_clocks: Dictionary = {}
	if String(spec.get("status", "")) == "sleep":
		sleep_clocks["own"] = {"version": "0.10.11", "start_time": 3, "time": 2}
	var can_use: Callable = func(): return true
	check(mode + " campo: servicio de inventario real",
		service.configure(collection, catalogs, can_use, sleep_clocks))
	var original: CreatureInstance = collection.owned_creature(&"own")
	var before: Dictionary = _owner_data(collection)
	var slot: int = int(spec.get("slot", -1))
	var reply: Dictionary = service.use_item(item, &"own", slot)
	var expected_acceptance: bool = bool(spec.applies) and mode != "none"
	check(mode + " campo: admisión y rechazo correctos",
		bool(reply.get("accepted", false)) == expected_acceptance)
	if String(spec.kind) == "field_unsupported":
		check(mode + " Razz sin conexion: rechazo, no prueba positiva",
			not bool(reply.get("accepted", false))
			and String(reply.get("status", "")) in ["DEPENDENCY_MISSING", "REJECTED"])
	if String(spec.kind) == "field_medicine" and expected_acceptance:
		var expected_action: String = "bitter_medicine" if String(spec.id) == "energy_powder" else "medicine"
		check(mode + " medicina usa el servicio existente y su subfamilia",
			String(reply.get("action", "")) == expected_action)
	var updated: CreatureInstance = collection.owned_creature(&"own")
	if updated == null:
		check(mode + " campo: Pokemon no desaparece", false)
		return {"valid": false}
	var now_pp: int = updated.moveset[0].current_pp
	var now_status: String = String(updated.status_state.persistent_id)
	var now_confusion: bool = updated.status_state.has_volatile(&"confusion")
	var pp_gain: int = int(spec.get("pp_gain", 0)) if expected_acceptance else 0
	var expected_pp: int = start_pp
	if String(spec.kind) == "field_pp":
		expected_pp = mini(updated.moveset[0].max_pp,
			start_pp + (int(spec.expected_delta) if expected_acceptance else 0))
	elif String(spec.kind) == "field_medicine" and spec.has("pp_gain"):
		expected_pp = mini(updated.moveset[0].max_pp, start_pp + pp_gain)
	var expected_pp_second: int = start_pp_second
	if String(spec.kind) == "field_medicine" and spec.has("pp_gain"):
		expected_pp_second = mini(updated.moveset[1].max_pp, start_pp_second + pp_gain)
	check(mode + " campo: PP por slot estrictos, sin propagacion incorrecta",
		now_pp == expected_pp
		and updated.moveset[1].current_pp == expected_pp_second)
	var cures_status: bool = expected_acceptance and (
		String(spec.kind) == "field_lum" or
		(String(spec.kind) == "field_medicine" and bool(spec.get("cures_status", false))))
	var cures_confusion: bool = expected_acceptance and (
		String(spec.kind) == "field_lum" or
		(String(spec.kind) == "field_medicine" and bool(spec.get("cures_confusion", false))))
	check(mode + " campo: estado y confusión según contrato",
		now_status == ("" if cures_status else start_status)
		and now_confusion == (false if cures_confusion else start_confusion))
	if String(spec.kind) == "field_medicine":
		check(mode + " medicina respeta contador/status y sueño",
			(not cures_status or (updated.status_ids.is_empty()
			and updated.status_state.turns_remaining == 0
			and updated.status_state.toxic_counter == 0
			and not updated.status_state.rest_sleep
			and not updated.status_state.has_volatile(&"nightmare")))
			and (not bool(spec.get("expect_sleep_clock_clear", false)) or
			((service.sleep_clocks.is_empty() if expected_acceptance else service.sleep_clocks.has("own")))))
	var expected_hp: int = start_hp
	if String(spec.kind) == "field_heal" and expected_acceptance:
		expected_hp = mini(updated.stats.max_hp,
			start_hp + maxi(1, int(updated.stats.max_hp / int(spec.heal_denominator))))
	elif String(spec.kind) == "field_medicine" and expected_acceptance:
		expected_hp = mini(updated.stats.max_hp,
			start_hp + int(spec.get("heal_amount", 0)))
	var expected_friendship: int = start_friend
	if String(spec.kind) == "field_medicine" and expected_acceptance and spec.has("friendship_loss"):
		expected_friendship = maxi(0, start_friend - int(spec.friendship_loss))
	check(mode + " campo: PS y amistad segun contrato, EV intactos",
		updated.current_hp == expected_hp and updated.friendship == expected_friendship
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
			and restored_mon.moveset[1].current_pp == expected_pp_second
			and String(restored_mon.status_state.persistent_id) == now_status
			and restored_mon.status_state.has_volatile(&"confusion") == now_confusion
			and restored_mon.friendship == expected_friendship
			and restored_mon.current_hp == expected_hp
			and restored_mon.evs == updated.evs)
	var name: String = String(spec.scenario) + "_" + mode
	var evidence: Dictionary = {"scenario": spec.scenario, "mode": mode, "item": String(item),
		"kind": spec.kind, "before": before, "after": state, "accepted": bool(reply.get("accepted", false)),
		"pp": now_pp, "pp_max": updated.moveset[0].max_pp,
		"pp_second": updated.moveset[1].current_pp, "pp_second_max": updated.moveset[1].max_pp,
		"friendship": updated.friendship, "hp": updated.current_hp, "max_hp": updated.stats.max_hp,
		"status": now_status, "confusion": now_confusion, "bag": count,
		"location": String(collection.location_of(&"own")), "save_v2": decoded.ok}
	var sha: String = _write_evidence(name, evidence)
	check(mode + " campo: recibo SHA256",
		not sha.is_empty() and FileAccess.get_sha256(destination + "/" + name + ".json") == sha)
	return {"valid": true, "accepted": bool(reply.get("accepted", false)),
		"pp": now_pp, "pp_max": updated.moveset[0].max_pp,
		"pp_second": updated.moveset[1].current_pp, "pp_second_max": updated.moveset[1].max_pp,
		"friendship": updated.friendship, "hp": updated.current_hp, "max_hp": updated.stats.max_hp,
		"status": now_status, "confusion": now_confusion, "bag": count,
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
	check("campo: PP adicional y amistad consistentes entre equipo y PC",
		int(a.pp_second) == int(s.pp_second) and int(a.friendship) == int(s.friendship))
	check("campo: SaveV2 los tres modos íntegros",
		bool(a.save_v2) and bool(n.save_v2) and bool(s.save_v2))
	if String(spec.kind) == "field_heal":
		var quarter: int = maxi(1, int(n.max_hp / int(spec.heal_denominator)))
		check("Sitrus en bolsa cura exactamente 1/4 PS con limite",
			int(a.hp) == mini(int(a.max_hp), int(n.hp) + (quarter if expected else 0))
			and int(s.hp) == int(a.hp))
	if String(spec.kind) == "field_unsupported":
		check("Razz en bolsa se rechaza en todos los modos sin mutar HP",
			not bool(a.accepted) and not bool(n.accepted)
			and not bool(s.accepted)
			and int(a.hp) == int(n.hp) and int(n.hp) == int(s.hp))
	if String(spec.kind) == "field_medicine":
		var should_cure_status: bool = expected and bool(spec.get("cures_status", false))
		var should_cure_confusion: bool = expected and bool(spec.get("cures_confusion", false))
		var expected_healed_hp: int = mini(int(a.max_hp),
			int(n.hp) + (int(spec.heal_amount) if expected else 0))
		check("medicina cura PS exactos o mantiene PS al curar estado",
			int(a.hp) == expected_healed_hp and int(s.hp) == expected_healed_hp)
		check("medicina solo cura estado especificado si se consume",
			String(n.status) == String(spec.status)
			and String(a.status) == ("" if should_cure_status else String(spec.status))
			and String(s.status) == String(a.status))
		check("medicina conserva confusion ajena cuando no aplica",
			bool(a.confusion) == (false if should_cure_confusion else bool(spec.confused))
			and bool(s.confusion) == bool(a.confusion)
			and bool(n.confusion) == bool(spec.confused))
		if spec.has("pp_gain"):
			var gain: int = int(spec.pp_gain) if expected else 0
			check("Elixir aplica la ganancia en ambos slots sin seleccionar movimiento",
				int(a.pp) == mini(int(a.pp_max), int(n.pp) + gain)
				and int(a.pp_second) == mini(int(a.pp_second_max), int(n.pp_second) + gain)
				and int(s.pp) == int(a.pp) and int(s.pp_second) == int(a.pp_second))
		if spec.has("friendship_loss"):
			var expected_friend: int = maxi(0, int(n.friendship) -
				(int(spec.friendship_loss) if expected else 0))
			check("Polvo Energia amarga: amistad solo baja si cura",
				int(a.friendship) == expected_friend and int(s.friendship) == expected_friend)
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
