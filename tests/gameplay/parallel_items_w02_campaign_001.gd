extends "res://tests/gameplay/item_automation_v28.gd"

# Campaña W02: solo arnés de prueba; la autoridad de efectos es FieldItemService/@pkmn/sim.
# Los tres microbloques amplían una matriz declarativa; nunca escriben producción.
const MATRIX := "res://tests/fixtures/parallel_items/w02_campaign_001.json"
const Controlled := preload("res://tests/gameplay/item_automation_opponent_v28.gd")


func _initialize() -> void:
	capture = false
	call_deferred("_run_campaign")
	create_timer(360.0).timeout.connect(func():
		if not done:
			push_error("CAMP_001_W02: watchdog")
			quit(2))


func _run_campaign() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_001"
	DirAccess.make_dir_recursive_absolute(destination)
	automation = JSON.parse_string(FileAccess.get_file_as_string(MATRIX))
	if typeof(automation) != TYPE_DICTIONARY or automation.is_empty():
		check("matriz JSON W02 legible", false)
		_finish_campaign([])
		return
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay existente", Variants.apply(catalogs))
	check("formato fijado", String(automation.format) == "gen9calvounifiedv1")
	check("semilla reproducible", automation.seed == [23, 19, 29, 43])
	check("control dueño activo, ausente y reserva", automation.variants == ["active", "none", "reserve"])
	check("dos ubicaciones de mochila", automation.locations == ["PARTY", "STORAGE"])
	var rows: Array = []
	for spec: Dictionary in automation.cases:
		current_case = String(spec.scenario)
		var initial: int = checks
		var failures: int = errors.size()
		var held := {}
		for mode: String in automation.variants:
			held[mode] = await _native_case(spec, mode)
		var full: bool = held.size() == 3
		for mode: String in automation.variants:
			full = full and bool(held.get(mode, {}).get("valid", false))
		check("tres ejecuciones de combate válidas", full)
		if full:
			_compare_native(spec, held)
		var field := {}
		for place: String in automation.locations:
			field[place] = _field_case(spec, place)
		var field_ok: bool = field.size() == 2
		for place: String in automation.locations:
			field_ok = field_ok and bool(field.get(place, {}).get("valid", false))
		check("mochila PARTY/STORAGE comprobadas", field_ok)
		rows.append({"id": spec.id, "scenario": spec.scenario,
			"checks": checks - initial, "status": "PASS" if errors.size() == failures and full and field_ok else "FAIL",
			"native": held, "field": field})
	_finish_campaign(rows)


func _prepare(spec: Dictionary, creature: CreatureInstance, for_field: bool = false) -> void:
	if spec.initial == "quarter":
		creature.current_hp = maxi(1, int(floor(float(creature.stats.max_hp) / 4.0)))
	var initial_status: String = String(spec.get("field_status", spec.status)) if for_field else String(spec.status)
	if not initial_status.is_empty():
		creature.status_state.persistent_id = StringName(initial_status)
		creature.status_ids.assign([StringName(initial_status)])
		if initial_status == "sleep":
			creature.status_state.turns_remaining = 2
	if for_field and bool(spec.get("field_confusion", false)):
		creature.status_state.add_volatile(&"confusion", {"turns": 3})


func _compare_native(spec: Dictionary, held: Dictionary) -> void:
	var active: Dictionary = held.active
	var plain: Dictionary = held.none
	var reserve: Dictionary = held.reserve
	var should_consume: bool = bool(spec.consumes)
	check("consumo único solo si objeto activo y trigger correcto",
		active.consumed == should_consume and not plain.consumed and not reserve.consumed)
	check("stock global después de combatir",
		active.units == (1 if should_consume else 2) and plain.units == 2 and reserve.units == 2)
	check("reserva no altera al activo",
		plain.hp == reserve.hp and plain.status == reserve.status and plain.confused == reserve.confused)
	if String(spec.kind) == "confusion":
		check("Persim elimina confusión únicamente en portador activo",
			active.confused == not should_consume and plain.confused == should_consume
			and reserve.confused == should_consume)
		check("Persim no cura estado persistente ajeno",
			active.status == String(spec.status) and plain.status == String(spec.status))
	elif String(spec.kind) == "hp":
		check("Aranja cura +10 PS equipados o no se activa",
			active.hp == mini(active.max_hp, plain.hp + (int(spec.heal) if should_consume else 0)))
		check("Aranja no altera estado", active.status == plain.status)
	else:
		check("Baya de estado no altera PS fuera de controles de turno",
			active.hp == plain.hp or active.hp > plain.hp)
		var required_status: String = String(spec.get("native_expected_status", spec.status))
		check("Estado de control esperado",
			plain.status == required_status and reserve.status == required_status)
		check("Cura solamente estado específico",
			active.status == ("" if should_consume else required_status))
		check("Las bayas específicas no curan confusión",
			not active.confused and not plain.confused and not reserve.confused)


func _native_case(spec: Dictionary, mode: String) -> Dictionary:
	var item := StringName(spec.id)
	var player := PlayerCollection.new()
	var own: CreatureInstance = _mon(&"mew", int(automation.level), &"own", ["amnesia"])
	_prepare(spec, own)
	var backup: CreatureInstance = _mon(&"mew", int(automation.level), &"reserve", ["amnesia"])
	var foe: CreatureInstance = _mon(StringName(spec.get("foe_species", "mew")),
		int(automation.level), &"foe", [String(spec.get("foe_move", "amnesia"))])
	check(mode + " party own", player.party.add_creature(own))
	check(mode + " party reserve", player.party.add_creature(backup))
	check(mode + " dos bayas en mochila", player.inventory.add(item, 2))
	check(mode + " Poké Muñeco en mochila", player.inventory.add(&"poke_doll", 1))
	var service := Service.new()
	check(mode + " FieldItemService configurado", service.configure(player, catalogs, func(): return true))
	if mode != "none":
		check(mode + " equipamiento legal en dueño",
			service.equip(item, &"own" if mode == "active" else &"reserve").accepted)
	check(mode + " dos unidades iniciales", _units(player, item) == 2)
	var battle := Controlled.new(catalogs, player, automation.format)
	var opened: bool = await battle.begin_wild(self, foe, automation.seed)
	check(mode + " inicia motor nativo", opened)
	if not opened:
		await battle.close()
		return {"valid": false}
	var checkpoint: Dictionary = battle.snapshot()
	var old: Dictionary = await battle.submit("move 1", battle.revision + 1)
	check(mode + " revisión obsoleta rechazada", not old.accepted and battle.snapshot() == checkpoint)
	var frozen: String = JSON.stringify(_owner_data(player))
	battle.scripted_foe_choice = "move 1"
	var action: Dictionary = await battle.submit("move 1", battle.revision)
	check(mode + " turno aceptado", action.accepted)
	if not action.accepted:
		await battle.close()
		return {"valid": false}
	var observed: CreatureInstance = battle.battle_state().creature(&"own")
	var hp: int = observed.current_hp
	var status: String = String(observed.status_state.persistent_id)
	var confused: bool = observed.status_state.has_volatile(&"confusion")
	var spent: bool = observed.held_item_consumed
	check(mode + " campaña intacta antes del cierre",
		JSON.stringify(_owner_data(player)) == frozen and _units(player, item) == 2)
	var name: String = String(spec.scenario) + "_" + mode
	var restored: Dictionary = await _restore_probe(battle, player, name + "_checkpoint", mode, Controlled)
	if not bool(restored.get("valid", false)):
		return {"valid": false}
	battle = restored.session
	player = restored.owner
	var after_restore: CreatureInstance = battle.battle_state().creature(&"own")
	check(mode + " restauración PS/estado/confusión/consumo", after_restore.current_hp == hp
		and String(after_restore.status_state.persistent_id) == status
		and after_restore.status_state.has_volatile(&"confusion") == confused
		and after_restore.held_item_consumed == spent)
	var ending: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + " batalla terminada realmente FLED", ending.accepted and battle.completion_reason == "FLED")
	if not ending.accepted:
		await battle.close()
		return {"valid": false}
	var published: Dictionary = _owner_data(player)
	check(mode + " item/consumo publicado al dueño",
		player.owned_creature(&"own").held_item_consumed == spent)
	var second: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + " segundo cierre sin doble consumo", not second.accepted and _owner_data(player) == published)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(published)
	check(mode + " SaveV2 decodificado", decoded.ok)
	if not decoded.ok:
		await battle.close()
		return {"valid": false}
	var owner := PlayerCollection.new()
	owner.party = decoded.party
	owner.storage = decoded.storage
	owner.inventory = decoded.inventory
	var expected_bag: int = 2 if mode == "none" else 1
	var expected_stock: int = 1 if spent else 2
	check(mode + " inventario físico exacto y persistente",
		owner.inventory.quantity(item) == expected_bag and _units(owner, item) == expected_stock)
	check(mode + " propietario PS/status/consumo persistente",
		owner.owned_creature(&"own").current_hp == hp
		and String(owner.owned_creature(&"own").status_state.persistent_id) == status
		and owner.owned_creature(&"own").held_item_consumed == spent)
	if mode == "reserve":
		check(mode + " reserva retiene item", owner.owned_creature(&"reserve").held_item_id == item
			and not owner.owned_creature(&"reserve").held_item_consumed)
	await battle.close()
	var raw := {"scenario": spec.scenario, "mode": mode, "initial": checkpoint,
		"owner_after": published, "native_hp": hp, "native_status": status,
		"native_consumed": spent, "native_confused": confused, "units": _units(owner, item)}
	var evidence: String = name + ".json"
	var hash: String = _write_evidence(name, raw)
	return {"valid": true, "hp": hp, "max_hp": after_restore.stats.max_hp,
		"status": status, "confused": confused, "consumed": spent, "units": _units(owner, item),
		"bag": owner.inventory.quantity(item), "save": true, "evidence": evidence, "sha256": hash}


func _field_case(spec: Dictionary, place: String) -> Dictionary:
	var item := StringName(spec.id)
	var player := PlayerCollection.new()
	var creature: CreatureInstance = _mon(&"mew", int(automation.level), &"own", ["amnesia"])
	_prepare(spec, creature, true)
	check(place + " propietario creado", player.party.add_creature(creature))
	if place == "STORAGE":
		check(place + " traslado a caja", player.deposit(&"own"))
	check(place + " inventario inicial", player.inventory.add(item, 2))
	var service := Service.new()
	check(place + " servicio campo configurado", service.configure(player, catalogs, func(): return true))
	var before: String = JSON.stringify(_owner_data(player))
	var previous: CreatureInstance = player.owned_creature(&"own")
	var hp_before: int = previous.current_hp
	var status_before: String = String(previous.status_state.persistent_id)
	var confusion_before: bool = previous.status_state.has_volatile(&"confusion")
	var result: Dictionary = service.use_item(item, &"own", -1)
	var apply: bool = bool(spec.field_applies)
	check(place + " aplica sólo si hay efecto correcto", result.accepted == apply)
	if apply:
		var after: CreatureInstance = player.owned_creature(&"own")
		check(place + " gasta exactamente una unidad", player.inventory.quantity(item) == 1)
		check(place + " cura exactamente el contrato de campo",
			after.current_hp == mini(after.stats.max_hp, hp_before + int(spec.heal))
			and String(after.status_state.persistent_id) == ("" if String(spec.kind) == "status" else status_before)
			and after.status_state.has_volatile(&"confusion") == confusion_before)
		check(place + " retiene identidad/ubicación",
			after.instance_id == &"own" and String(player.location_of(&"own")) == place)
	else:
		check(place + " control negativo inmutable",
			JSON.stringify(_owner_data(player)) == before and player.inventory.quantity(item) == 2)
	var published: Dictionary = _owner_data(player)
	var saved: LoadResult = SaveGameRepository.new().decode_snapshot(published)
	check(place + " SaveV2 válido", saved.ok)
	if not saved.ok:
		return {"valid": false}
	var again := PlayerCollection.new()
	again.party = saved.party
	again.storage = saved.storage
	again.inventory = saved.inventory
	var final: CreatureInstance = player.owned_creature(&"own")
	var restored: CreatureInstance = again.owned_creature(&"own")
	check(place + " persistencia campo HP/estado/bolsa",
		restored != null and restored.to_dict() == final.to_dict()
		and again.inventory.quantity(item) == (1 if apply else 2))
	var name: String = String(spec.scenario) + "_field_" + place.to_lower()
	var file: String = name + ".json"
	var confusion_after: bool = final.status_state.has_volatile(&"confusion")
	var hash: String = _write_evidence(name, {"scenario": spec.scenario, "location": place,
		"accepted": result.accepted, "owner_after": published, "initial_hp": hp_before,
		"initial_status": status_before, "initial_confused": confusion_before, "confused": confusion_after})
	return {"valid": true, "accepted": result.accepted, "hp": final.current_hp,
		"status": String(final.status_state.persistent_id), "confused": confusion_after,
		"bag": again.inventory.quantity(item),
		"save": true, "evidence": file, "sha256": hash}


func _finish_campaign(rows: Array) -> void:
	var valid: bool = rows.size() == automation.get("cases", []).size()
	for row: Dictionary in rows:
		valid = valid and row.status == "PASS"
	check("todos los escenarios de la matriz completos", valid)
	var output := {"schema_version": 1, "family": "berry_campaign_w02",
		"status": "PASS" if errors.is_empty() and valid else "FAIL",
		"checks": checks, "errors": automation_errors, "cases": rows,
		"full_item_certification": false, "gpu": false}
	var f := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if f == null:
		push_error("CAMP_001_W02: no se puede persistir reporte")
		quit(2)
		return
	f.store_string(JSON.stringify(output, "  "))
	f.close()
	done = true
	print("CAMP_001_W02 ", output.status, " checks=", checks, " cases=", rows.size())
	quit(0 if output.status == "PASS" else 1)
