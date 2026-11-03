extends "res://tests/gameplay/item_automation_v28.gd"

# W02 CAMP003: pruebas, nunca lógica de producción. Hereda owner/SaveV2 nativos.
const SOURCE := "res://tests/fixtures/parallel_items/w02_campaign_003.json"
const Controlled := preload("res://tests/gameplay/item_automation_opponent_v28.gd")


func _initialize() -> void:
	capture = false
	call_deferred("_run_w02")
	create_timer(520.0).timeout.connect(func():
		if not done:
			push_error("CAMP003 W02 watchdog")
			quit(2))


func _run_w02() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_003"
	DirAccess.make_dir_recursive_absolute(destination)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not parsed is Dictionary:
		push_error("CAMP003 W02: fixture no es JSON Dictionary")
		quit(2)
		return
	automation = parsed
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay regional ya existente", Variants.apply(catalogs))
	check("versión nativa fijada", automation.format == "gen9calvounifiedv1")
	check("modos exactos de propiedad", automation.modes == ["active", "none", "reserve"])
	check("campo expresamente excluido", automation.field_scope == "NOT_TESTED")
	var valid_blocks: bool = automation.completed_blocks is Array
	valid_blocks = valid_blocks and automation.completed_blocks.size() == automation.blocks.size()
	for i in automation.blocks.size():
		var row: Dictionary = automation.blocks[i]
		valid_blocks = valid_blocks and (automation.completed_blocks[i] is int or automation.completed_blocks[i] is float)
		valid_blocks = valid_blocks and float(automation.completed_blocks[i]) == float(i + 1)
		valid_blocks = valid_blocks and String(row.block) == "%02d" % (i + 1)
	check("bloques acumulativos contiguos", valid_blocks)
	var results: Array = []
	for block: Dictionary in automation.blocks:
		var expected: Array = block.ids
		for spec: Dictionary in block.cases:
			current_case = String(spec.scenario)
			var count_before: int = checks
			var fails_before: int = errors.size()
			check("ID reservado dentro del bloque", expected.has(String(spec.id)))
			check("efecto pertenece a catálogo", catalogs.item(StringName(spec.id)) != null)
			var observed: Dictionary = {}
			for mode: String in automation.modes:
				observed[mode] = await _probe_berry(spec, mode)
			var complete: bool = observed.size() == 3
			for mode: String in automation.modes:
				complete = complete and bool(observed[mode].get("valid", false))
			check("activo/ausente/reserva válidos", complete)
			if complete:
				_compare_berry(spec, observed)
			results.append({"block": block.block, "id": spec.id, "scenario": spec.scenario,
				"status": "PASS" if complete and errors.size() == fails_before else "FAIL",
				"checks": checks - count_before, "observed": observed})
	_finish_w02(results)


func _probe_berry(spec: Dictionary, mode: String) -> Dictionary:
	var item := StringName(spec.id)
	# Movimientos de control neutrales; Micle prueba el siguiente movimiento real.
	var own_move: String = String(spec.get("own_move", "swords_dance"))
	var own_moves: Array = spec.get("own_moves", [own_move])
	var own: CreatureInstance = _mon(StringName(spec.get("actor_species", "mew")),
		int(automation.level), &"own", own_moves)
	var reserve: CreatureInstance = _mon(&"mew", int(automation.level), &"reserve", ["swords_dance"])
	var foe: CreatureInstance = _mon(StringName(spec.foe_species), int(automation.level),
		&"foe", [String(spec.foe_move)])
	own.nature_id = StringName(spec.nature)
	own.recalculate_stats(catalogs.species(own.species_id), ProgressionRuleset.new())
	match String(spec.start):
		"fifth": own.current_hp = maxi(1, int(floor(float(own.stats.max_hp) / 5.0)))
		"near_full": own.current_hp = own.stats.max_hp - 1
		"full": own.current_hp = own.stats.max_hp
		_: check("estado inicial conocido", false)
	if not String(spec.status).is_empty():
		own.status_state.persistent_id = StringName(spec.status)
		own.status_ids.assign([StringName(spec.status)])
	var initial_hp: int = own.current_hp
	var owner := PlayerCollection.new()
	check(mode + " dueño activo", owner.party.add_creature(own))
	check(mode + " reserva", owner.party.add_creature(reserve))
	check(mode + " dos unidades iniciales", owner.inventory.add(item, 2))
	check(mode + " Poké Muñeco", owner.inventory.add(&"poke_doll", 1))
	var service := Service.new()
	check(mode + " servicio existente", service.configure(owner, catalogs, func(): return true))
	if mode != "none":
		check(mode + " equipamiento válido",
			service.equip(item, &"own" if mode == "active" else &"reserve").accepted)
	check(mode + " stock físico antes de batalla", _units(owner, item) == 2)
	var battle := Controlled.new(catalogs, owner, automation.format)
	var opened: bool = await battle.begin_wild(self, foe, automation.seed)
	check(mode + " inicio real @pkmn/sim", opened)
	if not opened:
		await battle.close()
		return {"valid": false}
	battle.scripted_foe_choice = "move 1"
	var before: Dictionary = battle.snapshot()
	var stale: Dictionary = await battle.submit("move 1", battle.revision + 1)
	check(mode + " revisión obsoleta rechazable", not stale.accepted and battle.snapshot() == before)
	var frozen: String = JSON.stringify(_owner_data(owner))
	var action: Dictionary = await battle.submit("move 1", battle.revision)
	check(mode + " turno nativo ejecutado", action.accepted)
	if not action.accepted:
		await battle.close()
		return {"valid": false}
	var live: CreatureInstance = battle.battle_state().creature(&"own")
	var hp: int = live.current_hp
	var status: String = String(live.status_state.persistent_id)
	var spent: bool = live.held_item_consumed
	# Jaboca: registrar daño causado al rival real, no inferirlo del consumo.
	var foe_live: CreatureInstance = battle.battle_state().creature(&"foe")
	check(mode + " rival nativo presente para contraste", foe_live != null)
	var foe_hp: int = foe_live.current_hp if foe_live != null else -1
	var foe_max_hp: int = foe_live.stats.max_hp if foe_live != null else -1
	var raw_native: Dictionary = battle.snapshot().get("native", {}).get("native", {})
	var confusion: bool = false
	var boost_spd: bool = false
	var boost_def: bool = false
	var boost_atk: bool = false
	var focus_energy: bool = false
	var first_move_seen: bool = false
	var first_move_is_own: bool = false
	var native_events: Array[String] = []
	for value: Variant in raw_native.get("log", []):
		var line: String = String(value).to_lower()
		if line.begins_with("|-start|") and line.contains("|confusion"):
			confusion = true
			native_events.append(String(value))
		if line.begins_with("|-boost|p1a:") and line.contains("|spd|"):
			boost_spd = true
			native_events.append(String(value))
		if line.begins_with("|-boost|p1a:") and line.contains("|def|"):
			boost_def = true
			native_events.append(String(value))
		if line.begins_with("|-boost|p1a:") and line.contains("|atk|"):
			boost_atk = true
			native_events.append(String(value))
		if line.begins_with("|-start|p1a:") and (line.contains("focusenergy") or line.contains("focus energy")):
			focus_energy = true
			native_events.append(String(value))
		if line.begins_with("|move|") and not first_move_seen:
			first_move_seen = true
			first_move_is_own = line.begins_with("|move|p1a:")
			native_events.append(String(value))
	# Proyección de VOLATILES del checkpoint nativo real; no del nombre del objeto.
	var micle_pending_before_restore: bool = false
	if String(spec.kind) == "accuracy_next_move":
		micle_pending_before_restore = _native_volatile(battle, &"own", String(spec.expected_volatile))
	check(mode + " dueño inmutable antes de settlement",
		JSON.stringify(_owner_data(owner)) == frozen and _units(owner, item) == 2)
	var file_name: String = String(spec.scenario) + "_" + mode
	var restored: Dictionary = await _restore_probe(battle, owner, file_name + "_snapshot", mode, Controlled)
	if not bool(restored.get("valid", false)):
		return {"valid": false}
	battle = restored.session
	owner = restored.owner
	var replay: CreatureInstance = battle.battle_state().creature(&"own")
	if String(spec.kind) == "retaliate_physical":
		var foe_replayed: CreatureInstance = battle.battle_state().creature(&"foe")
		check(mode + " restauracion rival tras Jaboca",
			foe_replayed != null and foe_replayed.current_hp == foe_hp)
	check(mode + " restauración HP/status/consumo",
		replay.current_hp == hp and String(replay.status_state.persistent_id) == status
		and replay.held_item_consumed == spent)
	var micle_restored: bool = false
	var micle_after_next: bool = false
	var micle_used_next: bool = false
	if String(spec.kind) == "accuracy_next_move":
		micle_restored = _native_volatile(battle, &"own", String(spec.expected_volatile))
		check(mode + " Micle volatile idéntico tras checkpoint restaurado",
			micle_restored == micle_pending_before_restore)
		var next_turn: Dictionary = await battle.submit("move %d" % int(spec.next_move_slot), battle.revision)
		check(mode + " Micle segundo turno nativo ejecutado", next_turn.accepted)
		if not next_turn.accepted:
			await battle.close()
			return {"valid": false}
		micle_after_next = _native_volatile(battle, &"own", String(spec.expected_volatile))
		var second_native: Dictionary = battle.snapshot().get("native", {}).get("native", {})
		for entry: Variant in second_native.get("log", []):
			var line: String = String(entry).to_lower()
			if line.begins_with("|move|p1a:") and line.contains("|hydro pump|"):
				micle_used_next = true
		check(mode + " Micle Hydro Pump real fue lanzado", micle_used_next)
		var still: CreatureInstance = battle.battle_state().creature(&"own")
		check(mode + " Micle dos turnos mantienen PS/estado/consumo",
			still != null and still.current_hp == hp
			and String(still.status_state.persistent_id) == status
			and still.held_item_consumed == spent)
	var ending: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + " FLED real", ending.accepted and battle.completion_reason == "FLED")
	if not ending.accepted:
		await battle.close()
		return {"valid": false}
	var published: Dictionary = _owner_data(owner)
	check(mode + " consumo publicado al dueño", owner.owned_creature(&"own").held_item_consumed == spent)
	var second: Dictionary = await battle.use_item(&"poke_doll", &"own", battle.revision)
	check(mode + " no doble cierre", not second.accepted and _owner_data(owner) == published)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(published)
	check(mode + " LoadResult SaveV2", decoded.ok)
	if not decoded.ok:
		await battle.close()
		return {"valid": false}
	var saved := PlayerCollection.new()
	saved.party = decoded.party
	saved.storage = decoded.storage
	saved.inventory = decoded.inventory
	var actual_bag: int = saved.inventory.quantity(item)
	var total: int = _units(saved, item)
	check(mode + " dueño guardado PS/status y consumo",
		saved.owned_creature(&"own").current_hp == hp
		and String(saved.owned_creature(&"own").status_state.persistent_id) == status
		and saved.owned_creature(&"own").held_item_consumed == spent)
	check(mode + " inventario SaveV2 exacto",
		actual_bag == (2 if mode == "none" else 1) and total == (1 if spent else 2))
	if mode == "reserve":
		check(mode + " objeto reservado intacto",
			saved.owned_creature(&"reserve").held_item_id == item
			and not saved.owned_creature(&"reserve").held_item_consumed)
	await battle.close()
	var raw: Dictionary = {"block": spec.get("block", "01"), "scenario": spec.scenario,
		"mode": mode, "before": before, "owner_after": published,
		"native_hp": hp, "native_status": status, "native_consumed": spent,
		"native_events": native_events, "native_confusion": confusion,
		"native_boost_spd": boost_spd, "native_boost_def": boost_def,
		"native_boost_atk": boost_atk, "native_focus_energy": focus_energy,
		"native_first_move_seen": first_move_seen, "native_first_own": first_move_is_own,
		"native_foe_hp": foe_hp, "native_foe_max_hp": foe_max_hp,
		"native_micle_pending": micle_pending_before_restore,
		"native_micle_restored": micle_restored,
		"native_micle_after_next": micle_after_next,
		"native_micle_used_next": micle_used_next,
		"physical_total": total}
	var digest: String = _write_evidence(file_name, raw)
	return {"valid": true, "hp": hp, "max_hp": replay.stats.max_hp,
		"status": status, "consumed": spent, "total": total, "bag": actual_bag,
		"damage": initial_hp - hp, "confusion": confusion, "boost_spd": boost_spd,
		"boost_def": boost_def, "boost_atk": boost_atk, "focus_energy": focus_energy,
		"first_move_seen": first_move_seen, "first_own": first_move_is_own,
		"foe_hp": foe_hp, "foe_max_hp": foe_max_hp,
		"micle_pending": micle_pending_before_restore, "micle_restored": micle_restored,
		"micle_after_next": micle_after_next, "micle_used_next": micle_used_next,
		"save_v2": true, "restored": true, "settled_once": true,
		"evidence": file_name + ".json", "sha256": digest}


# Sólo inspecciona la proyección verificada de las volátiles en el checkpoint nativo.
func _native_volatile(session: RefCounted, cid: StringName, effect: String) -> bool:
	var teams: Variant = session._checkpoint.get("roster", [])
	if not teams is Array:
		return false
	for side: Variant in teams:
		if not side is Dictionary:
			continue
		for monster: Variant in side.get("pokemon", []):
			if monster is Dictionary and String(monster.get("instance_id", "")) == String(cid):
				var effects: Variant = monster.get("volatiles", [])
				return effects is Array and effects.has(effect)
	return false


func _compare_berry(spec: Dictionary, observed: Dictionary) -> void:
	var active: Dictionary = observed.active
	var none: Dictionary = observed.none
	var reserve: Dictionary = observed.reserve
	var consume: bool = bool(spec.consumes)
	check("solo consume el titular activo y cuando corresponde",
		active.consumed == consume and not none.consumed and not reserve.consumed)
	check("stock total único en todas las variantes",
		active.total == (1 if consume else 2) and none.total == 2 and reserve.total == 2)
	check("la reserva no modifica HP/estado activo",
		none.hp == reserve.hp and none.status == reserve.status)
	match String(spec.kind):
		"heal_flavor":
			var delta: int = int(floor(float(active.max_hp) / 3.0)) if consume else 0
			check("Aguav e Iapapa curan 1/3 del máximo sólo con umbral",
				active.hp == mini(active.max_hp, none.hp + delta))
			check("Baya de sabor confunde sólo naturaleza que la rechaza",
				active.confusion == bool(spec.confuses) and not none.confusion and not reserve.confusion)
		"boost_spd", "boost_def", "boost_atk", "reactive_def":
			var key: String = "boost_atk" if String(spec.kind) == "boost_atk" else ("boost_spd" if String(spec.kind) == "boost_spd" else "boost_def")
			check("baya mejora solo la estadistica del portador cuando se activa",
				bool(active[key]) == consume and not bool(none[key]) and not bool(reserve[key]))
			check("baya de estadistica no altera daño de este turno ni estado",
				active.hp == none.hp and active.status == none.status)
		"critical_focus":
			check("Lansat aplica enfoque critico real solo con PS bajos",
				bool(active.focus_energy) == consume
				and not bool(none.focus_energy) and not bool(reserve.focus_energy))
			check("Lansat no modifica HP ni estado de los testigos",
				active.hp == none.hp and none.hp == reserve.hp
				and active.status == none.status and none.status == reserve.status)
		"cure_freeze":
			check("Aspear cura congelación sólo al portador",
				active.status == ("" if consume else String(spec.status))
				and none.status == String(spec.status) and reserve.status == String(spec.status))
		"resist_steel", "resist_type":
			if consume:
				check("baya del titular reduce daño del tipo autorizado", active.damage > 0
					and active.damage < none.damage and reserve.damage == none.damage)
			else:
				check("tipo no coincidente, ninguna reducción ni consumo",
					active.damage == none.damage and reserve.damage == none.damage)
		"priority_order":
			check("custap tiene eventos move reales de ambos testigos",
				active.first_move_seen and none.first_move_seen and reserve.first_move_seen)
			check("custap actua primero solo con HP bajos y titular equipado",
				active.first_own == bool(spec.expected_first)
				and not none.first_own and not reserve.first_own)
			check("custap no cura ni cambia estado", active.hp == none.hp
				and reserve.hp == none.hp and active.status == none.status)
		"heal_super_effective":
			var heal: int = int(floor(float(active.max_hp) / float(spec.heal_denominator))) if consume else 0
			check("enigma cura cuarto de HP solo tras ataque supereficaz",
				active.hp == mini(active.max_hp, none.hp + heal)
				and none.hp == reserve.hp)
			check("enigma conserva estado", active.status == none.status and none.status == reserve.status)
		"accuracy_next_move":
			check("Micle activa volatile del titular al cruzar umbral",
				active.micle_pending == consume
				and not none.micle_pending and not reserve.micle_pending)
			check("Micle mantiene volatile tras salvar y restaurar checkpoint",
				active.micle_restored == consume
				and not none.micle_restored and not reserve.micle_restored)
			check("Micle se retira después del siguiente movimiento",
				active.micle_used_next and none.micle_used_next and reserve.micle_used_next
				and not active.micle_after_next and not none.micle_after_next
				and not reserve.micle_after_next)
			check("Micle no altera HP ni estado por sí sola",
				active.hp == none.hp and none.hp == reserve.hp
				and active.status == none.status and none.status == reserve.status)
		"retaliate_physical":
			var retaliation: int = int(floor(float(active.foe_max_hp) / float(spec.retaliation_denominator))) if consume else 0
			check("Jaboca: testigos de rival nativo con HP maximo igual",
				active.foe_max_hp > 0
				and active.foe_max_hp == none.foe_max_hp
				and none.foe_max_hp == reserve.foe_max_hp)
			check("Jaboca: daño 1/8 del maximo al atacante solo en contacto fisico",
				active.foe_hp == none.foe_hp - retaliation
				and none.foe_hp == reserve.foe_hp
				and active.foe_hp > 0)
			check("Jaboca no reduce daño ni altera estado al portador",
				active.hp == none.hp and reserve.hp == none.hp
				and active.status == none.status and none.status == reserve.status)
		_:
			check("familia desconocida", false)
	for mode: String in automation.modes:
		var rec: Dictionary = observed[mode]
		var path: String = destination + "/" + String(rec.evidence)
		var authenticated: bool = FileAccess.file_exists(path)
		if authenticated:
			authenticated = FileAccess.get_sha256(path) == String(rec.sha256)
		check(mode + " SHA256 recibo real", authenticated)
		if authenticated:
			var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			check(mode + " prueba frontera nativa y dueño",
				receipt is Dictionary and receipt.has("before") and receipt.has("owner_after")
				and String(receipt.scenario) == String(spec.scenario)
				and int(receipt.native_hp) == int(rec.hp) and receipt.native_consumed == rec.consumed
				and int(receipt.native_foe_hp) == int(rec.foe_hp)
				and int(receipt.native_foe_max_hp) == int(rec.foe_max_hp)
				and bool(receipt.native_micle_pending) == bool(rec.micle_pending)
				and bool(receipt.native_micle_after_next) == bool(rec.micle_after_next))


func _finish_w02(results: Array) -> void:
	var block_ok: int = 0
	var complete: bool = true
	for block: Dictionary in automation.blocks:
		var relevant: Array = results.filter(func(r: Dictionary): return r.block == block.block)
		var seen := {}
		var ok: bool = relevant.size() == block.cases.size()
		for row: Dictionary in relevant:
			ok = ok and row.status == "PASS" and not seen.has(String(row.scenario))
			seen[String(row.scenario)] = true
		for spec: Dictionary in block.cases:
			ok = ok and seen.has(String(spec.scenario))
		check("matriz íntegra bloque " + String(block.block), ok)
		if ok:
			block_ok += 1
		complete = complete and ok
	var status: String = "PASS" if complete and errors.is_empty() and block_ok > 0 else "FAIL"
	var output: Dictionary = {"status": status, "campaign": "CAMP_003",
		"blocks": block_ok, "checks": checks, "rows": results,
		"errors": automation_errors, "fixture_sha256": FileAccess.get_sha256(SOURCE),
		"field_tested": false, "gpu_tested": false}
	var report := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if report == null:
		push_error("CAMP003 W02 missing report")
		quit(2)
		return
	report.store_string(JSON.stringify(output, "  "))
	report.close()
	done = true
	if status == "PASS":
		print("CAMP003_W02_GODOT PASS blocks=", block_ok, " checks=", checks)
		quit(0)
	else:
		print("CAMP003_W02_GODOT FAIL blocks=", block_ok, " checks=", checks)
		quit(1)
