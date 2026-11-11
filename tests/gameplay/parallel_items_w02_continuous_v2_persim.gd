extends "res://tests/gameplay/parallel_items_w02_campaign_003.gd"

# W02 CONTINUOUS_V2 Persim L3: real Gengar Confuse Ray, held berry,
# native volatile projection, owner settlement, recovery and SaveV2.
# No native engine modifications or claims about direct field use.
const SOURCE_PERSIM := "res://tests/fixtures/parallel_items/w02_continuous_v2_persim.json"


func _initialize() -> void:
	capture = false
	call_deferred("_run_persim")
	create_timer(540.0).timeout.connect(func():
		if not done:
			push_error("W02 V2 PERSIM watchdog")
			quit(2))


func _native_confusion(session: RefCounted) -> bool:
	var roster: Variant = session._checkpoint.get("roster", [])
	if not roster is Array or roster.is_empty(): return false
	var mons: Variant = roster[0].get("pokemon", [])
	if not mons is Array or mons.is_empty(): return false
	var effects: Variant = mons[0].get("volatiles", [])
	return effects is Array and effects.has("confusion")


func _native_confusion_event(session: RefCounted) -> bool:
	var source: Dictionary = session.snapshot().get("native", {}).get("native", {})
	for entry: Variant in source.get("log", []):
		var line: String = String(entry).to_lower()
		if line.begins_with("|-start|") and line.contains("|confusion"):
			return true
	return false


func _probe_persim(spec: Dictionary, mode: String) -> Dictionary:
	var item: StringName = &"persim_berry"
	var own: CreatureInstance = _mon(&"mew", int(automation.level), &"own", ["reflect"])
	var spare: CreatureInstance = _mon(&"mew", int(automation.level), &"reserve", ["reflect"])
	var foe: CreatureInstance = _mon(StringName(spec.foe_species), int(automation.level),
		&"foe", [String(spec.foe_move)])
	var owner := PlayerCollection.new()
	check(mode + ": party inicial", owner.party.add_creature(own))
	check(mode + ": reserva inicial", owner.party.add_creature(spare))
	check(mode + ": dos unidades Persim", owner.inventory.add(item, 2))
	check(mode + ": poke doll de salida", owner.inventory.add(&"poke_doll", 1))
	var service := Service.new()
	check(mode + ": servicio existente", service.configure(owner, catalogs, func(): return true))
	if mode != "none":
		check(mode + ": equipamiento propio",
			service.equip(item, &"own" if mode == "active" else &"reserve").accepted)
	check(mode + ": dos unidades físicas antes", _units(owner, item) == 2)
	var battle := Controlled.new(catalogs, owner, String(automation.format))
	var opened: bool = await battle.begin_wild(self, foe, automation.seed)
	check(mode + ": combate nativo abierto", opened)
	if not opened:
		await battle.close()
		return {"valid": false}
	battle.scripted_foe_choice = "move 1"
	var prior: Dictionary = battle.snapshot()
	var stale: Dictionary = await battle.submit("move 1", battle.revision + 1)
	check(mode + ": revisión obsoleta sin mutación", not stale.accepted and battle.snapshot() == prior)
	var owner_before: String = JSON.stringify(_owner_data(owner))
	var played: Dictionary = await battle.submit("move 1", battle.revision)
	check(mode + ": turno nativo aceptado", played.accepted)
	if not played.accepted:
		await battle.close()
		return {"valid": false}
	var native_own: CreatureInstance = battle.battle_state().creature(&"own")
	check(mode + ": Pokemon de batalla sigue existiendo", native_own != null)
	if native_own == null:
		await battle.close()
		return {"valid": false}
	var consumed: bool = native_own.held_item_consumed
	var confused: bool = _native_confusion(battle)
	var confusion_event: bool = _native_confusion_event(battle)
	var hp: int = native_own.current_hp
	var pp: int = native_own.moveset[0].current_pp
	check(mode + ": efecto registrado por fuente nativa",
		confusion_event if bool(spec.triggers) else not confusion_event)
	check(mode + ": no publicación prematura al dueño",
		JSON.stringify(_owner_data(owner)) == owner_before and _units(owner, item) == 2)
	var name: String = String(spec.scenario) + "_" + mode
	var restored: Dictionary = await _restore_probe(battle, owner,
		name + "_checkpoint", mode, Controlled)
	if not bool(restored.get("valid", false)):
		return {"valid": false}
	battle = restored.session
	owner = restored.owner
	var after_restore: CreatureInstance = battle.battle_state().creature(&"own")
	check(mode + ": volatile, consumo y PS restaurados",
		after_restore != null and _native_confusion(battle) == confused
		and after_restore.held_item_consumed == consumed
		and after_restore.current_hp == hp and after_restore.moveset[0].current_pp == pp)
	var fled: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + ": cierre FLED válido", fled.accepted and battle.completion_reason == "FLED")
	if not fled.accepted:
		await battle.close()
		return {"valid": false}
	var saved: Dictionary = _owner_data(owner)
	check(mode + ": consumo publicado exactamente una vez",
		owner.owned_creature(&"own").held_item_consumed == consumed)
	var duplicate: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + ": no doble settlement", not duplicate.accepted and _owner_data(owner) == saved)
	var loaded: LoadResult = SaveGameRepository.new().decode_snapshot(saved)
	check(mode + ": SaveV2 decodifica", loaded.ok)
	if not loaded.ok:
		await battle.close()
		return {"valid": false}
	var reconstructed := PlayerCollection.new()
	reconstructed.party = loaded.party
	reconstructed.storage = loaded.storage
	reconstructed.inventory = loaded.inventory
	var restored_own: CreatureInstance = reconstructed.owned_creature(&"own")
	var stock: int = _units(reconstructed, item)
	check(mode + ": propiedad, PS y consumo guardados",
		restored_own != null and restored_own.instance_id == &"own"
		and restored_own.current_hp == hp
		and restored_own.held_item_consumed == consumed and stock == (1 if consumed else 2))
	if mode == "reserve":
		check(mode + ": reserva conserva Persim",
			reconstructed.owned_creature(&"reserve").held_item_id == item
			and not reconstructed.owned_creature(&"reserve").held_item_consumed)
	await battle.close()
	var record: Dictionary = {"scenario": String(spec.scenario), "mode": mode,
		"native_confusion_event": confusion_event, "native_confused": confused,
		"consumed": consumed, "stock_after": stock, "hp": hp,
		"save_v2": loaded.ok, "owner": saved}
	var digest: String = _write_evidence(name, record)
	check(mode + ": recibo SHA256 propio", not digest.is_empty()
		and FileAccess.get_sha256(destination + "/" + name + ".json") == digest)
	return {"valid": true, "consumed": consumed, "confused": confused,
		"event": confusion_event, "stock": stock, "hp": hp,
		"save_v2": loaded.ok, "sha256": digest}


func _run_persim() -> void:
	destination = "res://.godot/parallel_items/w02_continuous_v2_persim"
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_PERSIM))
	if not parsed is Dictionary:
		push_error("W02 V2 PERSIM: fixture invalida")
		quit(2)
		return
	automation = parsed
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Persim: overlay regional", Variants.apply(catalogs))
	check("Persim: campaña e ID",
		String(automation.campaign) == "W02_CONTINUOUS_V2"
		and String(automation.block) == "01" and String(automation.item_id) == "persim_berry")
	check("Persim: modos propios", automation.modes == ["active", "none", "reserve"])
	check("Persim: dos escenarios", automation.cases.size() == 2)
	var results: Array = []
	for spec: Dictionary in automation.cases:
		current_case = String(spec.scenario)
		var initial_checks: int = checks
		var initial_errors: int = errors.size()
		var observed: Dictionary = {}
		for mode: String in automation.modes:
			observed[mode] = await _probe_persim(spec, mode)
		var complete: bool = observed.size() == 3
		for mode: String in automation.modes:
			complete = complete and bool(observed[mode].get("valid", false))
		check("Persim: tres modos completos", complete)
		if complete:
			var trigger: bool = bool(spec.triggers)
			check("Persim: consumo del activo únicamente si hay confusión",
				bool(observed.active.consumed) == trigger
				and not bool(observed.none.consumed) and not bool(observed.reserve.consumed))
			check("Persim: confusión purgada por baya o mantenida sin baya",
				not bool(observed.active.confused)
				and bool(observed.none.confused) == trigger
				and bool(observed.reserve.confused) == trigger)
			check("Persim: stock real exacto",
				int(observed.active.stock) == (1 if trigger else 2)
				and int(observed.none.stock) == 2 and int(observed.reserve.stock) == 2)
			check("Persim: SaveV2 para todos los testigos",
				bool(observed.active.save_v2) and bool(observed.none.save_v2)
				and bool(observed.reserve.save_v2))
		results.append({"scenario": String(spec.scenario),
			"status": "PASS" if complete and errors.size() == initial_errors else "FAIL",
			"checks": checks - initial_checks})
	var complete_all: bool = results.size() == 2
	for row: Dictionary in results:
		complete_all = complete_all and row.status == "PASS"
	check("Persim: dos escenarios positivos/negativos completos", complete_all)
	var success: bool = errors.is_empty() and complete_all
	var report: Dictionary = {"campaign": "W02_CONTINUOUS_V2", "id": "persim_berry",
		"scope": "native_held_Persim_only", "status": "PASS" if success else "FAIL",
		"checks": checks, "results": results, "errors": errors,
		"new_item_objects": 0, "field_use_claimed": false}
	var file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if file == null:
		push_error("Persim: reporte no escribible")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("W02_CONTINUOUS_V2_PERSIM_GODOT ", report.status, " cases=2 checks=", checks)
	quit(0 if success else 1)
