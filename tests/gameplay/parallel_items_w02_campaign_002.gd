extends "res://tests/gameplay/parallel_items_w02_berries_v1.gd"

# CAMP_002 W02: reutiliza prueba de batalla nativa YA verificada por IA6.
# No altera simulador, PlayerCollection, SaveV2, ni la lógica de consumo.
const FIXTURE_C002 := "res://tests/fixtures/parallel_items/w02_campaign_002.json"


func _initialize() -> void:
	capture = false
	call_deferred("_run_c002")
	create_timer(360.0).timeout.connect(func():
		if not done:
			push_error("CAMP_002_W02 timeout")
			quit(2))


func _run_c002() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_002"
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_C002))
	if not parsed is Dictionary:
		push_error("CAMP_002_W02: fixture JSON no es Dictionary")
		quit(2)
		return
	automation = parsed
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay ya disponible", Variants.apply(catalogs))
	check("formato nativo fijado", String(automation.format) == "gen9calvounifiedv1")
	check("alcance autorizado ITER_01+02",
		automation.item_ids == ["sitrus_berry", "lum_berry", "leppa_berry", "figy_berry"]
		and automation.completed_iterations is Array
		and automation.completed_iterations.size() == 2
		and (automation.completed_iterations[0] is int or automation.completed_iterations[0] is float)
		and (automation.completed_iterations[1] is int or automation.completed_iterations[1] is float)
		and float(automation.completed_iterations[0]) == 1.0
		and float(automation.completed_iterations[1]) == 2.0
		and automation.cases.size() == 9)
	check("modos de propiedad", automation.variants == ["active", "none", "reserve"])
	check("campo no ejecutado en este bloque", automation.field_scope == "NOT_TESTED_ITER_02")
	var expected_seed: Array = [23, 19, 29, 43]
	var seed_ok: bool = automation.seed is Array and automation.seed.size() == expected_seed.size()
	if seed_ok:
		for i in expected_seed.size():
			seed_ok = seed_ok and (automation.seed[i] is float or automation.seed[i] is int)
			seed_ok = seed_ok and float(automation.seed[i]) == float(expected_seed[i])
	check("semilla fija sin error de JSON float", seed_ok)
	var rows: Array = []
	for spec: Dictionary in automation.cases:
		current_case = String(spec.scenario)
		var initial: int = checks
		var failed: int = errors.size()
		check("ID pertenece al microbloque", automation.item_ids.has(String(spec.id)))
		check("objeto presente en catálogo", catalogs.item(StringName(spec.id)) != null)
		var observed := {}
		for mode: String in automation.variants:
			if spec.id in ["leppa_berry", "figy_berry"]:
				observed[mode] = await _ensayar_especial(spec, mode)
			else:
				observed[mode] = await _ensayar(spec, mode)
		var valid: bool = observed.size() == 3
		for mode: String in automation.variants:
			valid = valid and observed[mode].get("valid", false)
		check("tres variantes nativas completadas", valid)
		if valid:
			if spec.id in ["leppa_berry", "figy_berry"]:
				_comparar_especial(spec, observed)
			else:
				_comparar(spec, observed)
			for mode: String in automation.variants:
				_verify_receipt(spec, mode, observed[mode])
		rows.append({"id": spec.id, "scenario": spec.scenario,
			"status": "PASS" if valid and errors.size() == failed else "FAIL",
			"checks": checks - initial, "observed": observed})
	_finish_c002(rows)



func _ensayar_especial(spec: Dictionary, mode: String) -> Dictionary:
	var item := StringName(spec.id)
	var own: CreatureInstance = _mon(&"mew", int(automation.level), &"own",
		["tackle", "reflect"] if spec.id == "leppa_berry" else ["amnesia"])
	var reserve: CreatureInstance = _mon(&"mew", int(automation.level), &"reserve", ["amnesia"])
	var foe: CreatureInstance = _mon(&"mew", int(automation.level), &"foe", ["amnesia"])
	var start_hp: int = own.current_hp
	var start_pp: int = -1
	var command: String = "move 1"
	if spec.id == "leppa_berry":
		start_pp = int(spec.first_move_pp)
		own.moveset[0].current_pp = start_pp
		command = String(spec.own_choice)
	else:
		own.nature_id = StringName(spec.actor_nature)
		# Restablecer paridad estricta: el motor nativo recalcula los stats de la naturaleza.
		own.recalculate_stats(catalogs.species(own.species_id), ProgressionRuleset.new())
		if String(spec.hp_state) == "fifth":
			own.current_hp = maxi(1, int(floor(float(own.stats.max_hp) / 5.0)))
		else:
			own.current_hp = own.stats.max_hp - 1
		start_hp = own.current_hp
	var player := PlayerCollection.new()
	check(mode + " propietario", player.party.add_creature(own))
	check(mode + " reserva", player.party.add_creature(reserve))
	check(mode + " mochila dos bayas", player.inventory.add(item, 2))
	check(mode + " Poké Muñeco", player.inventory.add(&"poke_doll", 1))
	var service := Service.new()
	check(mode + " FieldItemService", service.configure(player, catalogs, func(): return true))
	if mode != "none":
		check(mode + " equipamiento nativo",
			service.equip(item, &"own" if mode == "active" else &"reserve").accepted)
	check(mode + " stock antes combate", _units(player, item) == 2)
	var battle := RivalControlado.new(catalogs, player, automation.format)
	var opened: bool = await battle.begin_wild(self, foe, automation.seed)
	if not opened:
		print("IA6_W02_START_DIAG scenario=", String(spec.scenario), " mode=", mode,
			" nature=", String(own.nature_id), " level=", own.level,
			" status=", String(own.status_state.persistent_id),
			" hp=", own.current_hp, " error=", battle.last_error)
	check(mode + " inicia combate", opened)
	if not opened:
		await battle.close()
		return {"valid": false}
	battle.scripted_foe_choice = "move 1"
	var before: Dictionary = battle.snapshot()
	var stale: Dictionary = await battle.submit(command, battle.revision + 1)
	check(mode + " revision obsoleta inmutable", not stale.accepted and battle.snapshot() == before)
	var frozen: String = JSON.stringify(_owner_data(player))
	var action: Dictionary = await battle.submit(command, battle.revision)
	check(mode + " turno valido", action.accepted)
	if not action.accepted:
		await battle.close()
		return {"valid": false}
	var actual: CreatureInstance = battle.battle_state().creature(&"own")
	var hp: int = actual.current_hp
	var status: String = String(actual.status_state.persistent_id)
	var spent: bool = actual.held_item_consumed
	var actual_pp: int = actual.moveset[0].current_pp
	var nature: String = String(actual.nature_id)
	var native: Dictionary = battle.snapshot().get("native", {}).get("native", {})
	var confused_by_native: bool = false
	var native_confusion_events: Array[String] = []
	for entry: Variant in native.get("log", []):
		var line: String = String(entry).to_lower()
		if line.begins_with("|-start|") and line.contains("|confusion"):
			native_confusion_events.append(String(entry))
			confused_by_native = true
	check(mode + " propietario sin publicación prematura",
		JSON.stringify(_owner_data(player)) == frozen and _units(player, item) == 2)
	var name: String = String(spec.scenario) + "_" + mode
	var restored: Dictionary = await _restore_probe(battle, player, name + "_checkpoint", mode, RivalControlado)
	if not bool(restored.get("valid", false)):
		return {"valid": false}
	battle = restored.session
	player = restored.owner
	var replay: CreatureInstance = battle.battle_state().creature(&"own")
	check(mode + " restauración PP HP estado y consumo",
		replay.current_hp == hp and replay.moveset[0].current_pp == actual_pp
		and String(replay.nature_id) == nature and replay.held_item_consumed == spent
		and String(replay.status_state.persistent_id) == status)
	var end: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + " cierre FLED", end.accepted and battle.completion_reason == "FLED")
	if not end.accepted:
		await battle.close()
		return {"valid": false}
	var published: Dictionary = _owner_data(player)
	check(mode + " consumo publicado una vez", player.owned_creature(&"own").held_item_consumed == spent)
	var second: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + " segundo cierre rechazado", not second.accepted and _owner_data(player) == published)
	var loaded: LoadResult = SaveGameRepository.new().decode_snapshot(published)
	check(mode + " SaveV2 válido", loaded.ok)
	if not loaded.ok:
		await battle.close()
		return {"valid": false}
	var owner := PlayerCollection.new()
	owner.party = loaded.party
	owner.storage = loaded.storage
	owner.inventory = loaded.inventory
	var saved: CreatureInstance = owner.owned_creature(&"own")
	var expected_bag: int = 2 if mode == "none" else 1
	var expected_stock: int = 1 if spent else 2
	check(mode + " stock tras guardar",
		owner.inventory.quantity(item) == expected_bag and _units(owner, item) == expected_stock)
	check(mode + " identidad naturaleza PP y consumo tras guardar",
		saved.current_hp == hp and saved.moveset[0].current_pp == actual_pp
		and String(saved.nature_id) == nature and saved.held_item_consumed == spent)
	if mode == "reserve":
		check(mode + " reserva conserva objeto",
			owner.owned_creature(&"reserve").held_item_id == item
			and not owner.owned_creature(&"reserve").held_item_consumed)
	await battle.close()
	var raw: Dictionary = {"scenario": spec.scenario, "mode": mode, "before": before,
		"owner_after": published, "native_hp": hp, "native_status": status,
		"native_consumed": spent, "stock_total": _units(owner, item),
		"initial_hp": start_hp, "initial_pp": start_pp, "native_pp": actual_pp,
		"nature": nature, "native_confusion": confused_by_native,
		"native_confusion_events": native_confusion_events}
	var digest: String = _write_evidence(name, raw)
	return {"valid": true, "hp": hp, "max_hp": replay.stats.max_hp,
		"status": status, "damage": start_hp - hp, "consumed": spent,
		"stock_total": _units(owner, item), "bag": owner.inventory.quantity(item),
		"restored": true, "settled_once": true, "save_v2": true,
		"initial_hp": start_hp, "initial_pp": start_pp, "first_move_pp": actual_pp,
		"nature": nature, "native_confusion": confused_by_native,
		"evidence": name + ".json", "sha256": digest}


func _comparar_especial(spec: Dictionary, observed: Dictionary) -> void:
	var active: Dictionary = observed.active
	var plain: Dictionary = observed.none
	var reserve: Dictionary = observed.reserve
	var consumes: bool = bool(spec.consumes)
	check("solo titular consume una unidad",
		active.consumed == consumes and not plain.consumed and not reserve.consumed)
	check("stock global sin doble gasto",
		active.stock_total == (1 if consumes else 2) and plain.stock_total == 2
		and reserve.stock_total == 2)
	check("reserva no cambia PP, HP ni naturaleza",
		reserve.first_move_pp == plain.first_move_pp
		and reserve.hp == plain.hp and reserve.nature == plain.nature)
	if String(spec.id) == "leppa_berry":
		var expected_pp: int = int(spec.first_move_pp) + (10 if consumes else 0)
		check("Zanama restaura solo el primer movimiento agotado",
			active.first_move_pp == expected_pp
			and plain.first_move_pp == int(spec.first_move_pp)
			and reserve.first_move_pp == int(spec.first_move_pp))
		check("Zanama no cura PS ni estado", active.hp == plain.hp and active.status == plain.status)
	else:
		var delta: int = int(floor(float(active.max_hp) / float(spec.heal_denominator))) if consumes else 0
		check("Higog cura un tercio sólo bajo umbral",
			active.hp == mini(active.max_hp, plain.hp + delta)
			and plain.hp == reserve.hp)
		check("naturaleza especificada preservada",
			active.nature == String(spec.actor_nature) and plain.nature == String(spec.actor_nature))
		check("Higog causa confusion nativa solo si sabor rechazado y consumida",
			active.native_confusion == (consumes and bool(spec.disliked))
			and not plain.native_confusion and not reserve.native_confusion)

func _verify_receipt(spec: Dictionary, mode: String, observed: Dictionary) -> void:
	var path: String = destination + "/" + String(observed.evidence)
	var integrity: bool = FileAccess.file_exists(path)
	if integrity:
		integrity = FileAccess.get_sha256(path) == String(observed.sha256)
	check(mode + " SHA256 de evidencia auténtico", integrity)
	if not integrity:
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		check(mode + " JSON de evidencia válido", false)
		return
	check(mode + " frontera de motor nativo incluida",
		raw.get("before", {}) is Dictionary and raw.before.has("native"))
	check(mode + " espejo de estado nativo/propiedad",
		String(raw.get("scenario", "")) == String(spec.scenario)
		and String(raw.get("mode", "")) == mode
		and int(raw.get("native_hp", -1)) == int(observed.hp)
		and String(raw.get("native_status", "")) == String(observed.status)
		and bool(raw.get("native_consumed", false)) == bool(observed.consumed)
		and int(raw.get("stock_total", -1)) == int(observed.stock_total))
	check(mode + " restauración FLED y SaveV2",
		observed.restored and observed.settled_once and observed.save_v2)


func _finish_c002(rows: Array) -> void:
	var complete: bool = automation.get("cases", []).size() == 9 and rows.size() == 9
	var coverage: Dictionary = {}
	for item: String in ["sitrus_berry", "lum_berry", "leppa_berry", "figy_berry"]:
		var relevant: Array = rows.filter(func(x: Dictionary): return String(x.id) == item)
		var positive: Array = automation.coverage_matrix[item].positive
		var negative: Array = automation.coverage_matrix[item].negative
		var names := {}
		var good: bool = relevant.size() == positive.size() + negative.size()
		for row: Dictionary in relevant:
			names[String(row.scenario)] = true
			good = good and row.status == "PASS"
		for scenario: String in positive + negative:
			good = good and names.has(scenario)
		check(item + " cobertura individual sin atribución ajena", good)
		complete = complete and good
		coverage[item] = {"status": "PASS" if good else "FAIL", "cases": relevant.size()}
	check("matriz C002 completa y exclusiva", complete)
	var report := {"schema_version": 1, "campaign": "CAMP_002",
		"family": "held_berry_revalidation", "status": "PASS" if complete and errors.is_empty() else "FAIL",
		"checks": checks, "errors": automation_errors, "cases": rows,
		"per_item": coverage, "field_scope": "NOT_TESTED_ITER_02",
		"full_item_certification": false, "gpu": false}
	var file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if file == null:
		push_error("C002 W02 no pudo escribir godot.json")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("PARALLEL_ITEMS_W02_CAMP002 ", report.status, " checks=", checks, " cases=", rows.size())
	quit(0 if report.status == "PASS" else 1)
