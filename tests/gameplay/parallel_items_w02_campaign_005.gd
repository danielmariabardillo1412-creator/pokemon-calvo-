extends "res://tests/gameplay/parallel_items_w02_campaign_004.gd"

# W02 CAMPAÑA_005: reutiliza utilidades reales de propietario, SaveV2 y recibos.
# No ejecuta _run_camp004 ni modifica los contratos de campañas previas.
const SOURCE_005 := "res://tests/fixtures/parallel_items/w02_campaign_005.json"
const MOCHI_STATS_005 := {"health_mochi": "hp", "muscle_mochi": "attack",
	"resist_mochi": "defense", "genius_mochi": "special_attack",
	"clever_mochi": "special_defense", "swift_mochi": "speed"}


func _initialize() -> void:
	capture = false
	call_deferred("_run_camp005")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("CAMP005 W02 watchdog")
			quit(2))


func _training_creature(spec: Dictionary) -> CreatureInstance:
	var species: StringName = &"growlithe" if String(spec.kind) == "ability" else &"mew"
	var ability: StringName = StringName(spec.get("ability", "intimidate")) if String(spec.kind) == "ability" else &"synchronize"
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var level: int = int(spec.get("level", 50))
	var c: CreatureInstance = CreatureFactory.create(catalogs.species(species), level,
		catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "ability_id": ability, "nature_id": String(spec.get("nature", "hardy")),
		"moves": ["growl", "protect"]})
	if spec.has("exp_until_next"):
		var curve: String = String(catalogs.species(c.species_id).growth_rate)
		c.experience = ProgressionRuleset.experience_for_level(curve, c.level + 1) - int(spec.exp_until_next)
	if String(spec.kind) == "mochi_reset":
		var reset_evs: Dictionary = spec.get("reset_evs", {})
		for stat: Variant in c.evs:
			c.evs[stat] = int(reset_evs.get(String(stat), 0))
		c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new())
	c.friendship = int(spec.get("start_friendship", 99))
	if String(spec.kind) in ["vitamin", "wing", "mochi"]:
		var stat: String = String(spec.stat)
		c.evs[stat] = int(spec.get("start_ev", 0))
		var other_stats: Array[String] = ["hp", "attack", "defense",
			"special_attack", "special_defense", "speed"]
		other_stats.erase(stat)
		var left: int = int(spec.get("other_ev_total", 0))
		for key: String in other_stats:
			var amount: int = mini(252, left)
			c.evs[key] = amount
			left -= amount
		c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new())
	c.current_hp = maxi(1, c.stats.max_hp - 9)
	c.status_state.persistent_id = &"poison"
	c.status_ids.assign([&"poison"])
	if String(spec.kind) == "pp":
		var index: int = int(spec.get("slot", 0))
		if index < 0 or index >= c.moveset.size(): index = 0
		var target: BattleMoveSlot = c.moveset[index]
		var base: int = catalogs.move(target.move_id).pp
		var boosts: int = int(spec.get("boosts", 0))
		target.max_pp = base + base * boosts / 5
		target.current_pp = mini(target.max_pp, int(spec.get("start_pp", base)))
	return c


func _probe_training(spec: Dictionary, mode: String) -> Dictionary:
	var item: StringName = StringName(spec.id)
	var c: CreatureInstance = _training_creature(spec)
	check(mode + " criatura real construida", c != null)
	if c == null: return {"valid": false}
	var owner := PlayerCollection.new()
	check(mode + " propiedad PARTY", owner.party.add_creature(c))
	if mode == "reserve": check(mode + " depósito real", owner.deposit(&"own"))
	if mode != "none": check(mode + " dos objetos de origen", owner.inventory.add(item, 2))
	var service := Service.new()
	check(mode + " servicio nativo configurado", service.configure(owner, catalogs, func(): return true))
	var original: Dictionary = c.to_dict()
	var before: Dictionary = _owner_data(owner)
	var start_level: int = c.level
	var start_hp_deficit: int = c.stats.max_hp - c.current_hp
	var start_friend: int = c.friendship
	var start_evs: Dictionary = c.evs.duplicate(true)
	var start_first: Dictionary = c.moveset[0].to_dict()
	var start_second: Dictionary = c.moveset[1].to_dict()
	var slot: int = int(spec.get("slot", -1))
	var stamp := ""
	if String(spec.kind) == "ability" and bool(spec.applies) and mode != "none":
		var preview: Dictionary = service.ability_preview(item, &"own")
		check(mode + " habilidad candidata real", bool(preview.get("accepted", false))
			and String(preview.get("ability_id", "")) == String(spec.expected_ability))
		stamp = String(preview.get("stamp", ""))
		check(mode + " sello de transición no vacío", not stamp.is_empty())
	var result: Dictionary = service.use_item(item, &"own", slot, &"", stamp)
	var expected: bool = bool(spec.applies) and mode != "none"
	check(mode + " aceptación contra contrato", bool(result.get("accepted", false)) == expected)
	var now: CreatureInstance = owner.owned_creature(&"own")
	if now == null:
		check(mode + " criatura sigue propia", false)
		return {"valid": false}
	var count: int = owner.inventory.quantity(item)
	check(mode + " bolsa y transacción", count == (1 if expected else (0 if mode == "none" else 2)))
	check(mode + " identidad y localización", now.instance_id == &"own"
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	check(mode + " origen no modificado", c.to_dict() == original)
	if String(spec.kind) == "mint_dependency":
		check(mode + " menta: dependencia explícita sin falsa aplicación",
			String(result.get("status", "")) == String(spec.expect_status)
			and String(result.get("reason", "")) == String(spec.expect_reason))
		check(mode + " menta: naturaleza original intacta",
			now.nature_id == c.nature_id and now.evs == c.evs
			and now.stats.to_dict() == c.stats.to_dict())
	if not expected:
		check(mode + " rechazo atómico", not bool(result.get("accepted", false))
			and _owner_data(owner) == before)
	elif String(spec.kind) == "ability":
		var expected_data: Dictionary = original.duplicate(true)
		expected_data["ability_id"] = String(spec.expected_ability)
		check(mode + " sólo cambia habilidad", now.to_dict() == expected_data)
		check(mode + " acción habilidad y destino", String(result.get("action", "")) == "ability_change"
			and String(result.get("ability_id", "")) == String(spec.expected_ability))
	elif String(spec.kind) == "growth":
		var curve: String = String(catalogs.species(c.species_id).growth_rate)
		var expected_exp: int
		var next_level: int
		if String(spec.id) == "rare_candy":
			next_level = int(spec.expected_level)
			expected_exp = ProgressionRuleset.experience_for_level(curve, next_level)
			check(mode + " Caramelo Raro sube exactamente un nivel",
				now.level == start_level + 1)
		else:
			var nominal_exp: int = int(spec.get("exp_amount", 100))
			var cap_exp: int = ProgressionRuleset.experience_for_level(curve, 100)
			expected_exp = mini(cap_exp, c.experience + nominal_exp)
			next_level = ProgressionRuleset.level_for_experience(curve, expected_exp)
			var gain_expected: int = expected_exp - c.experience
			check(mode + " Caramelo Exp: nominal y tope de experiencia",
				gain_expected > 0 and gain_expected <= nominal_exp
				and int(result.get("exp_gained", -1)) == gain_expected)
			if spec.has("exp_gain") or spec.has("expected_exp_gain"):
				check(mode + " Caramelo Exp: ganancia exacta en fixture",
					gain_expected == int(spec.get("expected_exp_gain", spec.get("exp_gain", -1))))
			if bool(spec.get("expect_cap", false)):
				check(mode + " Caramelo Exp llega exactamente al máximo nivel100",
					expected_exp == cap_exp and next_level == 100)
			if bool(spec.get("expect_level_up", false)):
				check(mode + " Caramelo Exp atraviesa umbral de nivel",
					next_level > start_level and now.level == next_level)
		check(mode + " crecimiento XP y nivel por curva real", now.level == next_level
			and now.experience == expected_exp)
		check(mode + " déficits PS y amistad", now.stats.max_hp - now.current_hp == start_hp_deficit
			and now.friendship == mini(255, start_friend + [5, 3, 2][mini(2, int(start_friend / 100))]))
		check(mode + " sin alterar naturaleza, EV, IV ni habilidades", now.ivs == c.ivs
			and now.evs == c.evs and now.nature_id == c.nature_id
			and now.ability_id == c.ability_id and now.species_id == c.species_id)
		check(mode + " PP previamente gastados conservados", now.moveset[0].to_dict() == start_first
			and now.moveset[1].to_dict() == start_second)
	elif String(spec.kind) == "pp":
		var selected: int = int(spec.slot)
		var before_slot: Dictionary = start_first if selected == 0 else start_second
		var after_slot: BattleMoveSlot = now.moveset[selected]
		var base_pp: int = catalogs.move(after_slot.move_id).pp
		var old_max: int = int(before_slot.max_pp)
		var new_max: int = base_pp + base_pp * int(spec.expected_boosts) / 5
		var gained: int = new_max - old_max
		check(mode + " sube máximo PP una etapa", after_slot.max_pp == new_max
			and after_slot.current_pp == int(before_slot.current_pp) + gained)
		check(mode + " PP del otro movimiento intactos",
			now.moveset[1 if selected == 0 else 0].to_dict() ==
			(start_second if selected == 0 else start_first))
		check(mode + " boost y amistad reales", String(result.get("action", "")) == "pp_boost"
			and int(result.get("boosts", -1)) == int(spec.expected_boosts)
			and now.friendship == mini(255, start_friend + 5))
		check(mode + " integridad de habilidad/experiencia/EV/IV", now.ability_id == c.ability_id
			and now.level == c.level and now.experience == c.experience
			and now.evs == c.evs and now.ivs == c.ivs)
	elif String(spec.kind) == "mochi_reset":
		var zero_evs: Dictionary = start_evs.duplicate(true)
		var removed: int = 0
		for key: Variant in zero_evs:
			removed += int(start_evs[key])
			zero_evs[key] = 0
		var reset_stats: Dictionary = StatCalculator.compute(
			catalogs.species(c.species_id).base_stat_block(), c.ivs,
			zero_evs, c.nature_id, c.level).to_dict()
		check(mode + " Mochi Reinicio borra exactamente seis EV", now.evs == zero_evs
			and removed > 0)
		check(mode + " Mochi Reinicio recalcula stats preservando deficit HP",
			now.stats.to_dict() == reset_stats
			and now.stats.max_hp - now.current_hp == start_hp_deficit)
		check(mode + " Mochi Reinicio operacion y EV retirados",
			String(result.get("action", "")) == "ev_reset"
			and int(result.get("ev_removed", -1)) == removed
			and int(result.get("ev_added", -1)) == 0)
		check(mode + " Mochi Reinicio sin cambios de amistad/PP/naturaleza/IV",
			now.friendship == start_friend
			and now.moveset[0].to_dict() == start_first
			and now.moveset[1].to_dict() == start_second
			and now.nature_id == c.nature_id and now.ivs == c.ivs
			and now.level == c.level and now.experience == c.experience
			and now.ability_id == c.ability_id)
	elif String(spec.kind) in ["vitamin", "wing", "mochi"]:
		var stat: String = String(spec.stat)
		var gain: int = int(spec.expected_ev_gain)
		if String(spec.kind) == "mochi":
			var real_stat: String = String(MOCHI_STATS_005.get(String(item), ""))
			var initial_total: int = 0
			for value: Variant in start_evs.values():
				initial_total += int(value)
			var native_gain: int = mini(10, mini(
				ProgressionRuleset.EV_PER_STAT_MAX - int(start_evs.get(real_stat, 0)),
				ProgressionRuleset.EV_TOTAL_MAX - initial_total))
			check(mode + " mochi ruta propia y +10 EV con ambos límites",
				real_stat == stat and gain == native_gain)
		var expected_evs: Dictionary = start_evs.duplicate(true)
		expected_evs[stat] = int(start_evs.get(stat, 0)) + gain
		var tier: int = mini(2, int(start_friend / 100))
		var friendship_added: int = (0 if String(spec.kind) == "mochi" else ([3, 2, 1] if String(spec.kind) == "wing" else [5, 3, 2])[tier])
		var expected_stats: Dictionary = StatCalculator.compute(
			catalogs.species(c.species_id).base_stat_block(), c.ivs,
			expected_evs, c.nature_id, c.level).to_dict()
		check(mode + " entrenamiento EV objetivo exacto sin afectar otras estadísticas",
			now.evs == expected_evs)
		var expected_total: int = 0
		for value: Variant in expected_evs.values():
			expected_total += int(value)
		check(mode + " entrenamiento total 510 y límite 252 respetados",
			int(expected_evs[stat]) <= 252 and expected_total <= 510)
		check(mode + " entrenamiento estadísticas recalculadas y déficit PS conservado",
			now.stats.to_dict() == expected_stats
			and now.stats.max_hp - now.current_hp == start_hp_deficit)
		check(mode + " entrenamiento amistad por tramo y tipo",
			now.friendship == mini(255, start_friend + friendship_added))
		check(mode + " entrenamiento acción y cantidad devuelta",
			String(result.get("action", "")) == "ev_training"
			and String(result.get("stat_id", "")) == stat
			and int(result.get("ev_added", -1)) == gain)
		check(mode + " entrenamiento PP/IV/experiencia y habilidad no contaminadas",
			now.moveset[0].to_dict() == start_first
			and now.moveset[1].to_dict() == start_second
			and now.ivs == c.ivs and now.nature_id == c.nature_id
			and now.ability_id == c.ability_id and now.level == c.level
			and now.experience == c.experience)
	var state: Dictionary = _owner_data(owner)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(state)
	check(mode + " SaveV2 descodifica", decoded.ok)
	if not decoded.ok: return {"valid": false}
	var restored := PlayerCollection.new()
	restored.party = decoded.party
	restored.storage = decoded.storage
	restored.inventory = decoded.inventory
	var saved: CreatureInstance = restored.owned_creature(&"own")
	check(mode + " SaveV2 mantiene dueño y stock", saved != null
		and restored.location_of(&"own") == owner.location_of(&"own")
		and restored.inventory.quantity(item) == count)
	if saved != null:
		check(mode + " SaveV2 nivel/exp/HP/amistad/PP/habilidad exactos",
			saved.level == now.level and saved.experience == now.experience
			and saved.current_hp == now.current_hp and saved.friendship == now.friendship
			and saved.ability_id == now.ability_id
			and saved.moveset[0].to_dict() == now.moveset[0].to_dict()
			and saved.moveset[1].to_dict() == now.moveset[1].to_dict())
		check(mode + " SaveV2 mantiene EV, IV, naturaleza y estado", saved.evs == now.evs
			and saved.ivs == now.ivs and saved.nature_id == now.nature_id
			and saved.status_state.persistent_id == now.status_state.persistent_id)
	var name: String = String(spec.scenario) + "_" + mode
	var evidence: Dictionary = {"scenario": spec.scenario, "mode": mode, "id": String(item),
		"before": before, "after": state, "accepted": bool(result.get("accepted", false)),
		"reason": String(result.get("reason", "")), "count": count,
		"saved": decoded.ok, "location": String(owner.location_of(&"own"))}
	var sha: String = _write_evidence(name, evidence)
	check(mode + " recibo SHA256 íntegro", not sha.is_empty()
		and FileAccess.get_sha256(destination + "/" + name + ".json") == sha)
	return {"valid": true, "accepted": bool(result.get("accepted", false)), "count": count,
		"level": now.level, "friendship": now.friendship,
		"ability": String(now.ability_id), "hp": now.current_hp,
		"pp0": now.moveset[0].current_pp, "pp1": now.moveset[1].current_pp,
		"max0": now.moveset[0].max_pp, "max1": now.moveset[1].max_pp,
		"save_v2": decoded.ok, "evidence": name + ".json", "sha256": sha}


func _run_camp005() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_005"
	DirAccess.make_dir_recursive_absolute(destination)
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_005))
	if not loaded is Dictionary:
		push_error("CAMP005 W02 fixture no es Dictionary")
		quit(2)
		return
	automation = loaded
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay regional real", Variants.apply(catalogs))
	check("identidad worker y campaña", automation.campaign == "CAMP_005" and automation.worker == "W02")
	check("formato nativo", automation.format == "gen9calvounifiedv1")
	check("tres modos", automation.modes == ["active", "none", "reserve"])
	check("bloques acumulados", automation.blocks.size() == automation.completed_blocks.size())
	var results: Array = []
	for index: int in automation.blocks.size():
		var block: Dictionary = automation.blocks[index]
		check("bloque exacto", block.block == "%02d" % (index + 1)
			and int(automation.completed_blocks[index]) == index + 1)
		for spec: Dictionary in block.cases:
			current_case = String(spec.scenario)
			var errors_before: int = errors.size()
			var checks_before: int = checks
			check("ID está reservado", block.ids.has(String(spec.id)))
			check("ID figura en catálogo", catalogs.item(StringName(spec.id)) != null)
			var observations: Dictionary = {}
			for mode: String in automation.modes:
				observations[mode] = _probe_training(spec, mode)
			var valid: bool = observations.size() == 3
			for mode: String in automation.modes:
				valid = valid and bool(observations[mode].get("valid", false))
			check("tres variantes completas", valid)
			if valid:
				var a: Dictionary = observations.active
				var n: Dictionary = observations.none
				var s: Dictionary = observations.reserve
				var should: bool = bool(spec.applies)
				check("efecto solo con stock en PARTY o STORAGE",
					bool(a.accepted) == should and not bool(n.accepted)
					and bool(s.accepted) == should)
				check("consumo idéntico entre propietarios",
					int(a.count) == (1 if should else 2)
					and int(n.count) == 0 and int(s.count) == (1 if should else 2))
				check("equipo y almacén misma mecánica",
					a.ability == s.ability and a.level == s.level
					and a.pp0 == s.pp0 and a.pp1 == s.pp1
					and a.friendship == s.friendship)
				check("entrenamiento y reserva comparten PS",
					int(a.hp) == int(s.hp))
			results.append({"block": block.block, "scenario": spec.scenario, "id": spec.id,
				"status": "PASS" if valid and errors.size() == errors_before else "FAIL",
				"checks": checks - checks_before, "observed": observations})
	var passed_blocks: int = 0
	for block: Dictionary in automation.blocks:
		var subset: Array = results.filter(func(row: Dictionary): return row.block == block.block)
		var names: Dictionary = {}
		var ok: bool = subset.size() == block.cases.size()
		for row: Dictionary in subset:
			ok = ok and row.status == "PASS" and not names.has(String(row.scenario))
			names[String(row.scenario)] = true
		for spec: Dictionary in block.cases:
			ok = ok and names.has(String(spec.scenario))
		check("bloque íntegro", ok)
		if ok: passed_blocks += 1
	var success: bool = errors.is_empty() and passed_blocks == automation.blocks.size()
	var report: Dictionary = {"worker": "W02", "campaign": "CAMP_005",
		"status": "PASS" if success else "FAIL", "blocks": passed_blocks,
		"checks": checks, "results": results, "errors": automation_errors,
		"fixture_sha256": FileAccess.get_sha256(SOURCE_005),
		"gpu_tested": false, "ui_tested": false}
	var file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if file == null:
		push_error("CAMP005 W02 no pudo escribir recibo")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("CAMP005_W02_GODOT ", "PASS" if success else "FAIL",
		" blocks=", passed_blocks, " checks=", checks)
	quit(0 if success else 1)
