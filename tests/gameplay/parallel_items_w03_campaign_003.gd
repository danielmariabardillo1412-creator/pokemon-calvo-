extends "res://tests/gameplay/item_capture_v11.gd"

# CAMP003 / IA3-W03: sólo pruebas acumulativas. No editar captura o catálogo.
const CAMP003_W03_FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_003.json"
const CAMP003_W03_TURN_EFFECTS = preload("res://modules/capture/capture_context_ball_effects.gd")
const CAMP003_W03_BASIC_EFFECTS = preload("res://modules/capture/capture_ball_effects.gd")


func _initialize() -> void:
	call_deferred("_run_campaign")
	create_timer(180).timeout.connect(func():
		if not done:
			push_error("CAMP003_W03_TIMEOUT")
			quit(2)
	)


func _run_campaign() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not raw is Dictionary:
		check("Existe catálogo normalizado", false)
		_terminar_campania(0)
		return
	catalogs = GameData.from_dict(raw).to_definition_catalog()
	check("Overlay regional disponible", Variants.apply(catalogs))
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMP003_W03_FIXTURE))
	if not decoded is Dictionary:
		check("Fixture de campaña válido", false)
		_terminar_campania(0)
		return
	var fixture: Dictionary = decoded
	var bloques: Array = fixture.get("blocks", [])
	check("Fixture W03 y al menos un bloque", fixture.get("worker", "") == "W03" and not bloques.is_empty())
	var numero := 0
	for bloque: Dictionary in bloques:
		numero += 1
		match String(bloque.get("bloque", "")):
			"01": _block_01(bloque)
			"02": _block_02(bloque)
			"03": _block_03(bloque)
			"04": _block_04(bloque)
			"05": _block_05(bloque)
			"06": _block_06(bloque)
			"07": _block_07(bloque)
			"08": _block_08(bloque)
			"09": _block_09(bloque)
			_: check("Bloque aún sin suite funcional " + str(numero), false)
	_terminar_campania(numero)


func _block_01(bloque: Dictionary) -> void:
	var reglas := CaptureRuleset.new()
	var bolas: Array = bloque.get("balls", [])
	var casos: Array = bloque.get("cases", [])
	check("Bloque 01 contiene dos bolas y tres especies", bolas.size() == 2 and casos.size() == 3)
	for fila: Dictionary in bolas:
		var id: StringName = StringName(String(fila.get("id", "")))
		var definition: CaptureBallDefinition = reglas.ball(id)
		check("Definición canónica de " + String(id), definition != null)
		if definition == null:
			continue
		check("Multiplicador y garantía canónicos " + String(id),
			is_equal_approx(definition.base_multiplier, float(fila.get("multiplier", -1.0)))
			and not definition.guaranteed and reglas.is_known_ball(id))
	for caso: Dictionary in casos:
		var sid: StringName = StringName(String(caso.get("species_id", "")))
		var especie: CreatureSpecies = catalogs.species(sid)
		check("Especie de catálogo " + String(sid), especie != null)
		if especie == null:
			continue
		for modo: String in bloque.get("health_modes", []):
			var probabilidades: Dictionary = {}
			for fila: Dictionary in bolas:
				var id: StringName = StringName(String(fila.get("id", "")))
				var factor: float = float(fila.get("multiplier", -1.0))
				var objetivo: CreatureInstance = _mon(sid, int(caso.get("level", 12)),
					StringName("w03_c003_01_" + String(sid) + "_" + modo + "_" + String(id)))
				objetivo.current_hp = objetivo.stats.max_hp if modo == "full" else 1
				var antes: Dictionary = objetivo.to_dict()
				var esperado: float = clampf(
					(float(especie.capture_rate) / 255.0) * factor *
					float(3 * objetivo.stats.max_hp - 2 * objetivo.current_hp) /
					float(3 * objetivo.stats.max_hp), 0.0, 1.0)
				var esperado_reglas: float = reglas.catch_probability(
					especie.capture_rate, factor, 1.0,
					objetivo.stats.max_hp, objetivo.current_hp)
				check("Probabilidad independiente calvo_capture_v1 " + String(sid) + String(id) + modo,
					is_equal_approx(esperado, esperado_reglas))
				var mochila := PlayerInventory.new()
				mochila.add(id, 2)
				var equipo := CreatureParty.new()
				var rng := RandomNumberGenerator.new()
				rng.seed = int(caso.get("seed", 801))
				var control := RandomNumberGenerator.new()
				control.state = rng.state
				var tirada := control.randf()
				var capturado: bool = tirada < esperado
				var res := CaptureInventoryService.resolve(
					CaptureAttempt.new(objetivo, id, CaptureBattleContext.new()),
					rng, catalogs, equipo, mochila)
				check("Una bola, un RNG, resultado determinista " + String(sid) + String(id) + modo,
					is_equal_approx(res.result.probability, esperado)
					and res.result.consume_item and mochila.quantity(id) == 1
					and rng.state == control.state
					and (res.result.status == CaptureResult.SUCCESS) == capturado)
				check("Identidad equipo/fallo sin mutación " + String(sid) + String(id) + modo,
					(is_same(res.captured, objetivo) and equipo.contains_instance_id(objetivo.instance_id)
					and equipo.size() == 1) if capturado else
					(res.result.status == CaptureResult.FAILED and equipo.is_empty()
					and objetivo.to_dict() == antes))
				probabilidades[String(id)] = res.result.probability
			if probabilidades.has("poke_ball") and probabilidades.has("great_ball"):
				var p_normal: float = probabilidades["poke_ball"]
				var p_grande: float = probabilidades["great_ball"]
				check("Gran Ball no empeora la captura en igual encuentro " + String(sid) + modo,
					p_grande >= p_normal and p_grande <= 1.0)
	for fila: Dictionary in bolas:
		var id: StringName = StringName(String(fila.get("id", "")))
		for caso: String in bloque.get("invalid_cases", []):
			var objetivo: CreatureInstance = _mon(&"mew", 30,
				StringName("w03_c003_01_invalida_" + String(id) + "_" + caso))
			var contexto := CaptureBattleContext.new()
			var mochila := PlayerInventory.new()
			mochila.add(id, 2)
			if caso == "trainer_battle_not_capturable":
				contexto.is_wild = false
			elif caso == "item_not_owned":
				mochila.remove(id, 2)
			var inventario_antes: Dictionary = mochila.to_dict()
			var criatura_antes: Dictionary = objetivo.to_dict()
			var equipo := CreatureParty.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = 3103
			var estado_rng := rng.state
			var res := CaptureInventoryService.resolve(
				CaptureAttempt.new(objetivo, id, contexto), rng, catalogs, equipo, mochila)
			check("Rechazo conserva inventario/RNG/objetivo " + String(id) + caso,
				res.result.status == CaptureResult.INVALID
				and res.result.reason == caso and not res.result.consume_item
				and mochila.to_dict() == inventario_antes
				and objetivo.to_dict() == criatura_antes
				and rng.state == estado_rng and equipo.is_empty())


# Ultra normal y Master garantizada: probar API canónica, nunca simular captura.
func _block_02(bloque: Dictionary) -> void:
	var reglas := CaptureRuleset.new()
	var bolas: Array = bloque.get("balls", [])
	var casos: Array = bloque.get("cases", [])
	check("Bloque02 dos bolas y tres especies", bolas.size() == 2 and casos.size() == 3)
	for fila: Dictionary in bolas:
		var id: StringName = StringName(String(fila.get("id", "")))
		var definicion: CaptureBallDefinition = reglas.ball(id)
		check("Bola02 registrada " + String(id), definicion != null)
		if definicion != null:
			check("Bola02 factor/garantia canónicos " + String(id),
				is_equal_approx(definicion.base_multiplier, float(fila.get("multiplier", -1)))
				and definicion.guaranteed == bool(fila.get("guaranteed", false)))
	for caso: Dictionary in casos:
		var sid: StringName = StringName(String(caso.get("species_id", "")))
		var sp: CreatureSpecies = catalogs.species(sid)
		check("Especie02 de catálogo " + String(sid), sp != null)
		if sp == null:
			continue
		for modo: String in bloque.get("health_modes", []):
			for fila: Dictionary in bolas:
				var id: StringName = StringName(String(fila.get("id", "")))
				var guarantee: bool = bool(fila.get("guaranteed", false))
				var factor: float = float(fila.get("multiplier", 1))
				var target: CreatureInstance = _mon(sid, int(caso.get("level", 12)),
					StringName("c003_02_" + String(sid) + modo + String(id)))
				target.current_hp = target.stats.max_hp if modo == "full" else 1
				var before := target.to_dict()
				var inv := PlayerInventory.new()
				inv.add(id, 2)
				var party := CreatureParty.new()
				var rng := RandomNumberGenerator.new()
				rng.seed = int(caso.get("seed", 2201))
				var before_rng: int = rng.state
				var probe := RandomNumberGenerator.new()
				probe.state = rng.state
				var probability: float = clampf(float(sp.capture_rate) / 255.0 * factor
					* float(3 * target.stats.max_hp - 2 * target.current_hp)
					/ float(3 * target.stats.max_hp), 0.0, 1.0)
				check("Bola02 fórmula independiente " + String(id) + String(sid) + modo,
					is_equal_approx(probability, reglas.catch_probability(
						sp.capture_rate, factor, 1.0, target.stats.max_hp, target.current_hp)))
				var expected_success: bool = true
				if not guarantee:
					expected_success = probe.randf() < probability
				var result: CaptureResolution = CaptureInventoryService.resolve(
					CaptureAttempt.new(target, id, CaptureBattleContext.new()),
					rng, catalogs, party, inv)
				if guarantee:
					check("Master éxito, coste 1 y cero RNG " + String(sid) + modo,
						result.result.status == CaptureResult.SUCCESS
						and result.result.consume_item and inv.quantity(id) == 1
						and rng.state == before_rng
						and is_zero_approx(result.result.probability))
					check("Master identidad en equipo " + String(sid) + modo,
						is_same(result.captured, target)
						and party.contains_instance_id(target.instance_id)
						and party.size() == 1)
				else:
					check("Ultra factor x2 y única tirada/coste " + String(sid) + modo,
						is_equal_approx(result.result.probability, probability)
						and result.result.consume_item and inv.quantity(id) == 1
						and rng.state == probe.state
						and (result.result.status == CaptureResult.SUCCESS) == expected_success)
					check("Ultra identidad éxito y sin alteración en fracaso " + String(sid) + modo,
						(is_same(result.captured, target)
						and party.contains_instance_id(target.instance_id)
						and party.size() == 1) if expected_success else
						(result.result.status == CaptureResult.FAILED
						and party.is_empty() and target.to_dict() == before))
	for fila: Dictionary in bolas:
		var id: StringName = StringName(String(fila.get("id", "")))
		for razon: String in bloque.get("invalid_cases", []):
			var target := _mon(&"mew", 50, StringName("c003_02_invalid_" + String(id) + razon))
			var ctx := CaptureBattleContext.new()
			var inv := PlayerInventory.new()
			inv.add(id, 2)
			match razon:
				"trainer_battle_not_capturable": ctx.is_wild = false
				"item_not_owned": inv.remove(id, 2)
				"target_knocked_out": target.current_hp = 0
			var before_target := target.to_dict()
			var before_inv := inv.to_dict()
			var party := CreatureParty.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = 777
			var before_rng: int = rng.state
			var result: CaptureResolution = CaptureInventoryService.resolve(
				CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inv)
			check("Bola02 inválida sin gasto/tiro/cambio " + String(id) + razon,
				result.result.status == CaptureResult.INVALID
				and result.result.reason == razon and not result.result.consume_item
				and inv.to_dict() == before_inv and target.to_dict() == before_target
				and rng.state == before_rng and party.is_empty())
	# En equipo lleno Master debe encaminarse a PC sin consumir RNG.
	var full_party := CreatureParty.new()
	for i in 6:
		full_party.add_creature(_mon(&"pidgey", 10, StringName("c003_02_full_" + str(i))))
	var wild := _mon(&"mew", 45, &"c003_02_master_pc")
	var bag := PlayerInventory.new()
	bag.add(&"master_ball")
	var rng_pc := RandomNumberGenerator.new()
	rng_pc.seed = 915
	var state_pc: int = rng_pc.state
	var resolution: CaptureResolution = CaptureInventoryService.resolve(
		CaptureAttempt.new(wild, &"master_ball", CaptureBattleContext.new()),
		rng_pc, catalogs, full_party, bag)
	check("Master llena equipo y exige PC", resolution.result.status == CaptureResult.SUCCESS
		and resolution.disposition == CaptureDisposition.STORAGE_REQUIRED
		and is_same(resolution.captured, wild)
		and full_party.size() == 6 and not full_party.contains_instance_id(wild.instance_id)
		and bag.quantity(&"master_ball") == 0 and rng_pc.state == state_pc)
	var storage := CreatureStorage.new()
	var routed := CaptureOwnershipRouter.new().route(resolution, full_party, storage)
	check("Master PC propiedad única y referencia", routed.routed and routed.stored
		and storage.contains_instance_id(wild.instance_id)
		and is_same(storage.get_creature(wild.instance_id), wild)
		and not full_party.contains_instance_id(wild.instance_id))


# Quick/Timer usan completed_turns de batalla, no turnos del calendario.
# Se contrasta fórmula independiente, adaptador real, coste, RNG y rechazos.
func _block_03(bloque: Dictionary) -> void:
	var reglas := CaptureRuleset.new()
	var bolas: Array = bloque.get("balls", [])
	var casos: Array = bloque.get("cases", [])
	check("Turno03 sólo Quick y Timer y dos especies",
		bolas.size() == 2 and casos.size() == 2)
	for fila: Dictionary in bolas:
		var id: StringName = StringName(String(fila.get("id", "")))
		var definition: CaptureBallDefinition = reglas.ball(id)
		check("Quick/Timer registradas sin garantía " + String(id),
			definition != null and reglas.is_known_ball(id)
			and not definition.guaranteed and is_equal_approx(definition.base_multiplier, 1.0))
	for caso: Dictionary in casos:
		var sid: StringName = StringName(String(caso.get("species_id", "")))
		var species: CreatureSpecies = catalogs.species(sid)
		check("Especie03 real de catálogo " + String(sid), species != null)
		if species == null:
			continue
		for turn_variant: Variant in bloque.get("completed_turns", []):
			var turnos: int = int(turn_variant)
			for hp_mode: String in bloque.get("hp_modes", []):
				for fila: Dictionary in bolas:
					var id: StringName = StringName(String(fila.get("id", "")))
					var factor: float = (5.0 if turnos == 0 else 1.0) if id == &"quick_ball" else minf(1.0 + 0.3 * turnos, 4.0)
					var target: CreatureInstance = _mon(sid, int(caso.get("level", 12)),
						StringName("c003_03_" + String(sid) + "_" + str(turnos) + hp_mode + String(id)))
					target.current_hp = target.stats.max_hp if hp_mode == "full" else 1
					var before := target.to_dict()
					var ctx := CaptureBattleContext.new()
					ctx.completed_turns = turnos
					var actual_factor: float = CAMP003_W03_TURN_EFFECTS.multiplier(id, target, species, ctx)
					check("Quick/Timer factor exacto turno " + String(id) + str(turnos),
						is_equal_approx(actual_factor, factor))
					var p_expected: float = clampf(float(species.capture_rate) / 255.0 * factor
						* float(3 * target.stats.max_hp - 2 * target.current_hp)
						/ float(3 * target.stats.max_hp), 0.0, 1.0)
					check("Quick/Timer probabilidad independiente " + String(id) + str(turnos) + hp_mode,
						is_equal_approx(p_expected, reglas.catch_probability(
							species.capture_rate, factor, 1.0, target.stats.max_hp, target.current_hp)))
					var inv := PlayerInventory.new()
					inv.add(id, 2)
					var party := CreatureParty.new()
					var rng := RandomNumberGenerator.new()
					rng.seed = int(caso.get("seed", 3301)) + turnos
					var control := RandomNumberGenerator.new()
					control.state = rng.state
					var success_expected: bool = control.randf() < p_expected
					var result: CaptureResolution = CaptureInventoryService.resolve(
						CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inv)
					check("Turno válido gasta una bola y una tirada " + String(id) + str(turnos) + hp_mode,
						result.result.status != CaptureResult.INVALID
						and result.result.consume_item and inv.quantity(id) == 1
						and is_equal_approx(result.result.probability, p_expected)
						and rng.state == control.state
						and (result.result.status == CaptureResult.SUCCESS) == success_expected)
					check("Turno válido conserva propiedad/objetivo " + String(id) + str(turnos) + hp_mode,
						(is_same(result.captured, target) and party.contains_instance_id(target.instance_id)
						and party.size() == 1) if success_expected else
						(result.result.status == CaptureResult.FAILED
						and party.is_empty() and target.to_dict() == before))
	# El valor por defecto -1 y valores negativos no se deben tratar como turno 0.
	for fila: Dictionary in bolas:
		var id: StringName = StringName(String(fila.get("id", "")))
		for value: Variant in bloque.get("invalid_context_turns", []):
			var turnos: int = int(value)
			var target: CreatureInstance = _mon(&"mew", 45,
				StringName("c003_03_ctx_" + String(id) + str(turnos)))
			var ctx := CaptureBattleContext.new()
			ctx.completed_turns = turnos
			check("Sin turnos fiables, validación rechaza " + String(id) + str(turnos),
				CaptureSystem.validate_attempt(CaptureAttempt.new(target, id, ctx), catalogs)
				== "capture_turn_context_missing")
			var bag := PlayerInventory.new()
			bag.add(id, 2)
			var before_target := target.to_dict()
			var before_bag := bag.to_dict()
			var party := CreatureParty.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = 53
			var before_rng: int = rng.state
			var result := CaptureInventoryService.resolve(
				CaptureAttempt.new(target, id, ctx), rng, catalogs, party, bag)
			check("Sin contexto nunca hay consumo o RNG " + String(id) + str(turnos),
				result.result.status == CaptureResult.INVALID
				and result.result.reason == "capture_turn_context_missing"
				and not result.result.consume_item
				and bag.to_dict() == before_bag and target.to_dict() == before_target
				and rng.state == before_rng and party.is_empty())
		for reason: String in bloque.get("other_rejections", []):
			var target: CreatureInstance = _mon(&"mew", 45,
				StringName("c003_03_invalid_" + String(id) + reason))
			var ctx := CaptureBattleContext.new()
			ctx.completed_turns = 0
			var bag := PlayerInventory.new()
			bag.add(id, 2)
			if reason == "trainer_battle_not_capturable":
				ctx.is_wild = false
			if reason == "item_not_owned":
				bag.remove(id, 2)
			var before_target := target.to_dict()
			var before_bag := bag.to_dict()
			var party := CreatureParty.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = 59
			var before_rng: int = rng.state
			var result := CaptureInventoryService.resolve(
				CaptureAttempt.new(target, id, ctx), rng, catalogs, party, bag)
			check("Rechazo en contexto válido no gasta " + String(id) + reason,
				result.result.status == CaptureResult.INVALID
				and result.result.reason == reason and not result.result.consume_item
				and bag.to_dict() == before_bag and target.to_dict() == before_target
				and rng.state == before_rng and party.is_empty())


# Level Ball: umbrales de niveles reales y tasa modificada limitada a 255.
# Nest Ball: nivel del OBJETIVO, sin exigir catcher_level.
func _block_04(bloque: Dictionary) -> void:
	var reglas := CaptureRuleset.new()
	var level: Dictionary = bloque.get("level_ball", {})
	var nest: Dictionary = bloque.get("nest_ball", {})
	var casos: Array = bloque.get("species_cases", [])
	check("Bola04 exactamente Level y Nest", bloque.get("ids", []) == ["level_ball", "nest_ball"])
	check("Bola04 ambas registradas sin garantía",
		reglas.is_known_ball(&"level_ball") and reglas.is_known_ball(&"nest_ball")
		and not reglas.ball(&"level_ball").guaranteed and not reglas.ball(&"nest_ball").guaranteed)
	var target_level: int = int(level.get("target_level", 10))
	var catcher_levels: Array = level.get("catcher_levels", [])
	var boundary_factors: Array = level.get("independent_multipliers", [])
	check("Level incluye ocho fronteras", catcher_levels.size() == 8 and boundary_factors.size() == 8)
	for caso: Dictionary in casos:
		var sid: StringName = StringName(String(caso.get("species_id", "")))
		var species: CreatureSpecies = catalogs.species(sid)
		check("Especie real para contexto nivel " + String(sid),
			species != null and species.capture_rate >= 1)
		if species == null or species.capture_rate < 1:
			continue
		for i in catcher_levels.size():
			var active_level: int = int(catcher_levels[i])
			var expected_base: float = 1.0
			if active_level >= target_level * 4:
				expected_base = 8.0
			elif active_level >= target_level * 2:
				expected_base = 4.0
			elif active_level > target_level:
				expected_base = 2.0
			check("Level umbral independiente " + str(active_level),
				is_equal_approx(expected_base, float(boundary_factors[i])))
			var factor: float = minf(expected_base, 255.0 / float(species.capture_rate))
			var target: CreatureInstance = _mon(sid, target_level,
				StringName("c003_04_level_factor_" + String(sid) + "_" + str(active_level)))
			var ctx := CaptureBattleContext.new()
			ctx.catcher_level = active_level
			check("Level adaptador con límite 255/rate " + String(sid) + str(active_level),
				is_equal_approx(CAMP003_W03_TURN_EFFECTS.multiplier(
					&"level_ball", target, species, ctx), factor))
			for mode: String in bloque.get("hp_modes", []):
				_check_block04_capture(&"level_ball", sid, target_level, active_level,
					factor, mode, int(caso.get("seed", 4401)) + active_level)
		var nest_levels: Array = nest.get("target_levels", [])
		var nest_factors: Array = nest.get("independent_multipliers", [])
		check("Nest incluye cinco fronteras", nest_levels.size() == 5 and nest_factors.size() == 5)
		for i in nest_levels.size():
			var wild_level: int = int(nest_levels[i])
			var factor: float = maxf((41.0 - float(wild_level)) / 10.0, 1.0)
			check("Nest umbral independiente " + str(wild_level),
				is_equal_approx(factor, float(nest_factors[i])))
			var wild: CreatureInstance = _mon(sid, wild_level,
				StringName("c003_04_nest_factor_" + String(sid) + "_" + str(wild_level)))
			check("Nest factor real por nivel objetivo " + String(sid) + str(wild_level),
				is_equal_approx(CAMP003_W03_BASIC_EFFECTS.multiplier(
					&"nest_ball", wild, species), factor))
			for mode: String in bloque.get("hp_modes", []):
				_check_block04_capture(&"nest_ball", sid, wild_level, -1,
					factor, mode, int(caso.get("seed", 4401)) + wild_level)
	# Level: contexto por defecto -1, cero y >100 deben rechazar sin gasto.
	for value: Variant in level.get("missing_catcher_levels", []):
		var active_level: int = int(value)
		var target: CreatureInstance = _mon(&"mew", 10,
			StringName("c003_04_missing_" + str(active_level)))
		var ctx := CaptureBattleContext.new()
		ctx.catcher_level = active_level
		check("Level sin nivel activo invalida", CaptureSystem.validate_attempt(
			CaptureAttempt.new(target, &"level_ball", ctx), catalogs)
			== "capture_active_level_context_missing")
		_check_block04_reject(&"level_ball", "capture_active_level_context_missing", active_level)
	# Con contexto válido, los rechazos de trainer o inventario no gastan.
	for id: StringName in [&"level_ball", &"nest_ball"]:
		for reason: String in bloque.get("invalid_cases", []):
			_check_block04_reject(id, reason, 40)


func _check_block04_capture(id: StringName, sid: StringName, target_level: int,
		catcher_level: int, factor: float, mode: String, seed_value: int) -> void:
	var species: CreatureSpecies = catalogs.species(sid)
	var target: CreatureInstance = _mon(sid, target_level,
		StringName("c003_04_capture_" + String(id) + "_" + String(sid)
		+ "_" + str(target_level) + "_" + str(catcher_level) + "_" + mode))
	target.current_hp = target.stats.max_hp if mode == "full" else 1
	var target_before: Dictionary = target.to_dict()
	var ctx := CaptureBattleContext.new()
	ctx.catcher_level = catcher_level
	var inv := PlayerInventory.new()
	inv.add(id, 2)
	var party := CreatureParty.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var control := RandomNumberGenerator.new()
	control.state = rng.state
	var expected: float = clampf(float(species.capture_rate) / 255.0 * factor
		* float(3 * target.stats.max_hp - 2 * target.current_hp)
		/ float(3 * target.stats.max_hp), 0.0, 1.0)
	var expected_success: bool = control.randf() < expected
	var result: CaptureResolution = CaptureInventoryService.resolve(
		CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inv)
	check("Nivel04 probabilidad y gasto/RNG " + String(id) + String(sid)
			+ str(target_level) + str(catcher_level) + mode,
		result.result.status != CaptureResult.INVALID and result.result.consume_item
		and is_equal_approx(result.result.probability, expected)
		and inv.quantity(id) == 1 and rng.state == control.state
		and (result.result.status == CaptureResult.SUCCESS) == expected_success)
	check("Nivel04 propiedad única o fallo intacto " + String(id) + String(sid)
			+ str(target_level) + str(catcher_level) + mode,
		(is_same(result.captured, target) and party.contains_instance_id(target.instance_id)
		and party.size() == 1) if expected_success else
		(result.result.status == CaptureResult.FAILED and party.is_empty()
		and target.to_dict() == target_before))


func _check_block04_reject(id: StringName, reason: String, active_level: int) -> void:
	var target: CreatureInstance = _mon(&"mew", 10,
		StringName("c003_04_reject_" + String(id) + "_" + reason + "_" + str(active_level)))
	var ctx := CaptureBattleContext.new()
	ctx.catcher_level = active_level
	var inv := PlayerInventory.new()
	inv.add(id, 2)
	if reason == "trainer_battle_not_capturable":
		ctx.is_wild = false
	if reason == "item_not_owned":
		inv.remove(id, 2)
	var inventory_before: Dictionary = inv.to_dict()
	var target_before: Dictionary = target.to_dict()
	var party := CreatureParty.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var rng_before: int = rng.state
	var result: CaptureResolution = CaptureInventoryService.resolve(
		CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inv)
	check("Nivel04 rechazo previo al consumo/RNG " + String(id) + reason,
		result.result.status == CaptureResult.INVALID
		and result.result.reason == reason and not result.result.consume_item
		and inv.to_dict() == inventory_before and target.to_dict() == target_before
		and rng.state == rng_before and party.is_empty())


# 05: Fast usa velocidad BASE y limita tasa; Dream distingue sueño persistente de Bostezo.
func _block_05(bloque: Dictionary) -> void:
	var rules := CaptureRuleset.new()
	check("Bloque05 IDs y registro", bloque.get("ids", []) == ["fast_ball", "dream_ball"]
		and rules.is_known_ball(&"fast_ball") and rules.is_known_ball(&"dream_ball"))
	for row: Dictionary in bloque.get("fast_cases", []):
		var sid: StringName = StringName(String(row.get("species_id", "")))
		var species: CreatureSpecies = catalogs.species(sid)
		check("Fast especie auténtica " + String(sid), species != null)
		if species == null:
			continue
		check("Fast datos base originales " + String(sid),
			species.base_speed == int(row.get("base_speed", -1))
			and species.capture_rate == int(row.get("capture_rate", -1)))
		var factor: float = minf(4.0, 255.0 / float(species.capture_rate)) if species.base_speed >= 100 else 1.0
		check("Fast frontera 100 y cap 255 " + String(sid),
			is_equal_approx(factor, float(row.get("expected_factor", -1.0))))
		var sample: CreatureInstance = _mon(sid, 35, StringName("c003_05_fast_" + String(sid)))
		check("Fast adaptador real " + String(sid),
			is_equal_approx(CAMP003_W03_BASIC_EFFECTS.multiplier(&"fast_ball", sample, species), factor))
		for mode: String in bloque.get("hp_modes", []):
			_block05_capture(&"fast_ball", sid, "none", factor, 1.0,
				mode, int(row.get("seed", 5501)))
	for sid_text: String in bloque.get("dream_species", []):
		var sid: StringName = StringName(sid_text)
		var species: CreatureSpecies = catalogs.species(sid)
		check("Dream especie auténtica " + sid_text, species != null)
		if species == null:
			continue
		for row: Dictionary in bloque.get("dream_states", []):
			for mode: String in bloque.get("hp_modes", []):
				_block05_capture(&"dream_ball", sid, String(row.get("state", "")),
					float(row.get("expected_factor", -1.0)),
					float(row.get("status_bonus", -1.0)), mode,
					5601 + (17 if sid == &"caterpie" else 0))
	for id: StringName in [&"fast_ball", &"dream_ball"]:
		for reason: String in bloque.get("invalid_cases", []):
			_block05_reject(id, reason)


func _block05_capture(id: StringName, sid: StringName, state: String,
		factor: float, bonus: float, mode: String, seed_value: int) -> void:
	var species: CreatureSpecies = catalogs.species(sid)
	var target: CreatureInstance = _mon(sid, 35,
		StringName("c003_05_" + String(id) + "_" + String(sid) + "_" + state + "_" + mode))
	target.current_hp = target.stats.max_hp if mode == "full" else 1
	if state == "sleep":
		status(target, &"sleep")
	elif state == "yawn":
		target.status_state.add_volatile(&"yawn")
	var expected_status: StringName = &"sleep" if state == "sleep" else &""
	check("Dream Bostezo no es sueño persistente " + String(sid) + state,
		target.status_state.persistent_id == expected_status)
	check("Fast/Dream factor " + String(id) + String(sid) + state,
		is_equal_approx(CAMP003_W03_BASIC_EFFECTS.multiplier(id, target, species), factor))
	check("Fast/Dream bonus estado independiente " + String(id) + String(sid) + state,
		is_equal_approx(CaptureRuleset.new().status_bonus(
			target.status_state.persistent_id), bonus))
	var expected: float = clampf(float(species.capture_rate) / 255.0 * factor * bonus
		* float(3 * target.stats.max_hp - 2 * target.current_hp)
		/ float(3 * target.stats.max_hp), 0.0, 1.0)
	check("Fast/Dream probabilidad independiente " + String(id) + String(sid) + state,
		is_equal_approx(CaptureRuleset.new().catch_probability(
			species.capture_rate, factor, bonus,
			target.stats.max_hp, target.current_hp), expected))
	var before_target: Dictionary = target.to_dict()
	var inv := PlayerInventory.new()
	inv.add(id, 2)
	var party := CreatureParty.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var control := RandomNumberGenerator.new()
	control.state = rng.state
	var expected_success: bool = control.randf() < expected
	var result: CaptureResolution = CaptureInventoryService.resolve(
		CaptureAttempt.new(target, id, CaptureBattleContext.new()), rng, catalogs, party, inv)
	check("Fast/Dream una bola y RNG " + String(id) + String(sid) + state + mode,
		result.result.status != CaptureResult.INVALID
		and result.result.consume_item and inv.quantity(id) == 1
		and rng.state == control.state
		and is_equal_approx(result.result.probability, expected)
		and (result.result.status == CaptureResult.SUCCESS) == expected_success)
	check("Fast/Dream identidad y estado sin efectos extra " + String(id) + String(sid) + state + mode,
		(is_same(result.captured, target) and party.contains_instance_id(target.instance_id)
		and party.size() == 1 and target.to_dict() == before_target) if expected_success else
		(result.result.status == CaptureResult.FAILED and party.is_empty()
		and target.to_dict() == before_target))


func _block05_reject(id: StringName, reason: String) -> void:
	var target: CreatureInstance = _mon(&"mew", 35,
		StringName("c003_05_bad_" + String(id) + "_" + reason))
	status(target, &"sleep")
	var ctx := CaptureBattleContext.new()
	var inv := PlayerInventory.new()
	inv.add(id, 2)
	if reason == "trainer_battle_not_capturable":
		ctx.is_wild = false
	elif reason == "item_not_owned":
		inv.remove(id, 2)
	elif reason == "target_knocked_out":
		target.current_hp = 0
	var before_target: Dictionary = target.to_dict()
	var before_inv: Dictionary = inv.to_dict()
	var party := CreatureParty.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	var before_rng: int = rng.state
	var result: CaptureResolution = CaptureInventoryService.resolve(
		CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inv)
	check("Fast/Dream rechazo sin bola ni tirada " + String(id) + reason,
		result.result.status == CaptureResult.INVALID and result.result.reason == reason
		and not result.result.consume_item and inv.to_dict() == before_inv
		and target.to_dict() == before_target and rng.state == before_rng and party.is_empty())


# 06: Amigo fija amistad a 200, Sana repone PS/PP/estado SOLO después de captura.
# Regresión complementaria V11: amistad superior a 200, fallo y rechazo sin efectos.
func _block_06(bloque: Dictionary) -> void:
	var rules := CaptureRuleset.new()
	check("Bloque06 IDs exactos y bolas conocidas",
		bloque.get("ids", []) == ["friend_ball", "heal_ball"]
		and rules.is_known_ball(&"friend_ball") and rules.is_known_ball(&"heal_ball"))
	var bounds: Array = bloque.get("seed_search_range", [])
	check("Semillas de prueba deterministas acotadas", bounds.size() == 2
		and int(bounds[0]) == 1 and int(bounds[1]) == 4096)
	for entry: Dictionary in bloque.get("friend_cases", []):
		_block06_capture(&"friend_ball", &"mew", int(entry.get("friendship", -99)),
			"sleep", 3, 64, String(entry.get("outcome", "")) == "success", false, bounds)
	for entry: Dictionary in bloque.get("heal_cases", []):
		_block06_capture(&"heal_ball", StringName(String(entry.get("species_id", ""))), 117,
			String(entry.get("status", "none")), int(entry.get("pp_current", 3)),
			int(entry.get("pp_max", 64)), String(entry.get("outcome", "")) == "success",
			false, bounds)
	for id: StringName in [&"friend_ball", &"heal_ball"]:
		_block06_capture(id, &"mew", 240, "sleep", 1, 64, true, true, bounds)
		for reason: String in bloque.get("invalid_cases", []):
			_block06_reject(id, reason, 117, 3, 64)
	for value: Variant in bloque.get("invalid_friendship", []):
		_block06_reject(&"friend_ball", "invalid_ball_friendship_state", int(value), 3, 64)
	for entry: Dictionary in bloque.get("invalid_pp", []):
		_block06_reject(&"heal_ball", "invalid_ball_pp_state", 117,
			int(entry.get("pp_current", -99)), int(entry.get("pp_max", -99)))


func _block06_seed_for(probability: float, want_success: bool, bounds: Array) -> int:
	for candidate in range(int(bounds[0]), int(bounds[1]) + 1):
		var trial := RandomNumberGenerator.new()
		trial.seed = candidate
		if (trial.randf() < probability) == want_success:
			return candidate
	return -1


func _block06_capture(id: StringName, sid: StringName, friendship_value: int,
		persistent: String, current_pp: int, maximum_pp: int,
		want_success: bool, to_pc: bool, bounds: Array) -> void:
	var species: CreatureSpecies = catalogs.species(sid)
	check("Postcaptura especie real " + String(id) + String(sid), species != null)
	if species == null:
		return
	var target: CreatureInstance = _mon(sid, 35, StringName(
		"c003_06_" + String(id) + "_" + String(sid) + "_" + str(friendship_value)
		+ "_" + persistent + "_" + str(current_pp) + "_"
		+ ("success" if want_success else "failure") + ("_pc" if to_pc else "_party")))
	target.friendship = friendship_value
	target.current_hp = maxi(1, int(target.stats.max_hp / 2.0))
	target.moveset[0].max_pp = maximum_pp
	target.moveset[0].current_pp = current_pp
	if persistent == "sleep":
		status(target, &"sleep")
	elif persistent == "poison":
		status(target, &"poison")
	var before: Dictionary = target.to_dict()
	var rules := CaptureRuleset.new()
	var factor: float = CAMP003_W03_BASIC_EFFECTS.multiplier(id, target, species)
	var bonus: float = rules.status_bonus(target.status_state.persistent_id)
	var expected_p: float = rules.catch_probability(species.capture_rate, factor, bonus,
		target.stats.max_hp, target.current_hp)
	check("Postcaptura efecto sólo sobre captura, no probabilidad " + String(id),
		is_equal_approx(factor, 1.0) and expected_p > 0.0 and expected_p <= 1.0)
	var seed_value: int = _block06_seed_for(expected_p, want_success, bounds)
	check("Postcaptura existe semilla real para éxito/fallo " + String(id)
		+ String(sid) + persistent, seed_value > 0)
	if seed_value < 1:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var control := RandomNumberGenerator.new()
	control.state = rng.state
	check("Semilla seleccionada reproduce resultado " + String(id),
		(control.randf() < expected_p) == want_success)
	var inv := PlayerInventory.new()
	inv.add(id, 2)
	var party := CreatureParty.new()
	if to_pc:
		for i in 6:
			party.add_creature(_mon(&"pidgey", 10, StringName(
				"c003_06_owned_" + String(id) + "_" + str(i))))
	var result: CaptureResolution = CaptureInventoryService.resolve(
		CaptureAttempt.new(target, id, CaptureBattleContext.new()),
		rng, catalogs, party, inv)
	var label: String = (String(id) + String(sid) + persistent + "_" + str(friendship_value)
		+ ("_success" if want_success else "_failure") + ("_pc" if to_pc else ""))
	check("Postcaptura un RNG, una bola, probabilidad canónica " + label,
		result.result.status != CaptureResult.INVALID
		and result.result.consume_item and inv.quantity(id) == 1
		and rng.state == control.state
		and is_equal_approx(result.result.probability, expected_p)
		and (result.result.status == CaptureResult.SUCCESS) == want_success)
	if not want_success:
		check("Postcaptura fallo no aplica amistad, sanación ni cambia equipo " + label,
			result.result.status == CaptureResult.FAILED and result.captured == null
			and target.to_dict() == before and party.is_empty())
		return
	var expected: Dictionary = before.duplicate(true)
	if id == &"friend_ball":
		expected["friendship"] = 200
	elif id == &"heal_ball":
		expected["current_hp"] = target.stats.max_hp
		expected["status_ids"] = []
		expected["status_state"] = BattleStatusState.new().to_dict()
		for slot: Dictionary in expected.moveset:
			slot.current_pp = slot.max_pp
	check("Friend fija amistad 200 o Heal repone sin alterar nada más " + label,
		target.to_dict() == expected and is_same(result.captured, target))
	if id == &"friend_ball":
		check("Friend también reduce amistad superior a 200 " + label,
			target.friendship == 200 and target.status_state.persistent_id == &"sleep"
			and target.moveset[0].current_pp == current_pp
			and target.moveset[0].max_pp == maximum_pp)
	else:
		check("Heal restaura PS, estado persistente y PP máximo ampliado " + label,
			target.current_hp == target.stats.max_hp and target.status_ids.is_empty()
			and target.status_state.persistent_id == &""
			and target.moveset[0].current_pp == maximum_pp
			and target.moveset[0].max_pp == maximum_pp
			and target.friendship == friendship_value)
	if to_pc:
		check("Postcaptura con equipo completo requiere PC " + label,
			result.disposition == CaptureDisposition.STORAGE_REQUIRED
			and party.size() == 6 and not party.contains_instance_id(target.instance_id))
		var storage := CreatureStorage.new()
		var routing := CaptureOwnershipRouter.new().route(result, party, storage)
		check("Postcaptura tras PC mantiene identidad y efecto " + label,
			routing.routed and routing.stored
			and storage.contains_instance_id(target.instance_id)
			and is_same(storage.get_creature(target.instance_id), target)
			and target.to_dict() == expected
			and not party.contains_instance_id(target.instance_id))
	else:
		check("Postcaptura en equipo tiene un propietario " + label,
			result.disposition == CaptureDisposition.PARTY
			and party.size() == 1 and party.contains_instance_id(target.instance_id))


func _block06_reject(id: StringName, reason: String,
		friendship_value: int, current_pp: int, maximum_pp: int) -> void:
	var target: CreatureInstance = _mon(&"mew", 35,
		StringName("c003_06_reject_" + String(id) + "_" + reason
		+ "_" + str(friendship_value) + "_" + str(current_pp)
		+ "_" + str(maximum_pp)))
	target.current_hp = maxi(1, int(target.stats.max_hp / 2.0))
	status(target, &"sleep")
	target.friendship = friendship_value
	target.moveset[0].max_pp = maximum_pp
	target.moveset[0].current_pp = current_pp
	var ctx := CaptureBattleContext.new()
	var inv := PlayerInventory.new()
	inv.add(id, 2)
	if reason == "trainer_battle_not_capturable":
		ctx.is_wild = false
	elif reason == "item_not_owned":
		inv.remove(id, 2)
	elif reason == "target_knocked_out":
		target.current_hp = 0
	var attempt := CaptureAttempt.new(target, id, ctx)
	if reason != "item_not_owned":
		check("Postcaptura validación rechaza estado incoherente " + String(id) + reason,
			CaptureSystem.validate_attempt(attempt, catalogs) == reason)
	var before: Dictionary = target.to_dict()
	var inventory_before: Dictionary = inv.to_dict()
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	var rng_before: int = rng.state
	var party := CreatureParty.new()
	var result: CaptureResolution = CaptureInventoryService.resolve(
		attempt, rng, catalogs, party, inv)
	check("Postcaptura inválida sin efectos, gasto ni RNG " + String(id) + reason,
		result.result.status == CaptureResult.INVALID
		and result.result.reason == reason
		and not result.result.consume_item
		and target.to_dict() == before and inv.to_dict() == inventory_before
		and rng.state == rng_before and party.is_empty())


# 07: caracterizar factor actual x1.5, NO certificar entorno Safari/Concurso.
# No existen flags de zona fiables en CaptureBattleContext: comprobar neutralidad.
func _block_07(bloque: Dictionary) -> void:
	var rules := CaptureRuleset.new()
	check("Bloque07 solo Safari y Sport", bloque.get("ids", []) == ["safari_ball", "sport_ball"])
	for id: StringName in [&"safari_ball", &"sport_ball"]:
		var definition: CaptureBallDefinition = rules.ball(id)
		check("Safari/Sport registrados sin garantía " + String(id),
			definition != null and not definition.guaranteed
			and is_equal_approx(definition.base_multiplier, 1.0)
			and CaptureRuleset.ordered_ball_ids().count(id) == 1)
	check("Sin contexto de recinto no hay certificación de funcionalidad",
		not bool(bloque.get("context_effect_certified", true))
		and not bool(bloque.get("implementation_authorized", true)))
	for case: Dictionary in bloque.get("cases", []):
		var sid: StringName = StringName(String(case.get("species_id", "")))
		var species: CreatureSpecies = catalogs.species(sid)
		check("Safari/Sport especie real " + String(sid), species != null)
		if species == null:
			continue
		for environment: Dictionary in bloque.get("contexts", []):
			for mode: String in bloque.get("hp_modes", []):
				for status_name: String in bloque.get("statuses", []):
					var results: Dictionary = {}
					for id: StringName in [&"safari_ball", &"sport_ball"]:
						var target: CreatureInstance = _mon(sid, int(case.get("level", 12)),
							StringName("c003_07_" + String(id) + "_" + String(sid)
							+ "_" + String(environment.get("name", "")) + mode + status_name))
						target.current_hp = target.stats.max_hp if mode == "full" else 1
						if status_name == "sleep":
							status(target, &"sleep")
						var before: Dictionary = target.to_dict()
						var factor: float = CAMP003_W03_BASIC_EFFECTS.multiplier(id, target, species)
						check("Safari/Sport factor actual incondicional " + String(id),
							is_equal_approx(factor, float(bloque.get("current_multiplier", -1))))
						var ctx := CaptureBattleContext.new()
						ctx.completed_turns = int(environment.get("completed_turns", -1))
						ctx.catcher_level = int(environment.get("catcher_level", -1))
						var expected: float = clampf(float(species.capture_rate) / 255.0
							* float(bloque.get("current_multiplier", 1.0))
							* rules.status_bonus(target.status_state.persistent_id)
							* float(3 * target.stats.max_hp - 2 * target.current_hp)
							/ float(3 * target.stats.max_hp), 0.0, 1.0)
						var inventory := PlayerInventory.new()
						inventory.add(id, 2)
						var party := CreatureParty.new()
						var rng := RandomNumberGenerator.new()
						rng.seed = int(case.get("seed", 7701))
						var control := RandomNumberGenerator.new()
						control.state = rng.state
						var expected_success: bool = control.randf() < expected
						var res: CaptureResolution = CaptureInventoryService.resolve(
							CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inventory)
						check("Safari/Sport una tirada, un consumo, probabilidad " + String(id),
							res.result.status != CaptureResult.INVALID
							and res.result.consume_item and inventory.quantity(id) == 1
							and is_equal_approx(res.result.probability, expected)
							and rng.state == control.state
							and (res.result.status == CaptureResult.SUCCESS) == expected_success)
						check("Safari/Sport no modifican criatura al capturar " + String(id),
							target.to_dict() == before
							and ((is_same(res.captured, target)
								and party.contains_instance_id(target.instance_id)
								and party.size() == 1) if expected_success else
								(res.result.status == CaptureResult.FAILED and party.is_empty())))
						results[String(id)] = {
							"probability": res.result.probability,
							"status": res.result.status,
							"rng_state": rng.state,
						}
					if results.has("safari_ball") and results.has("sport_ball"):
						var safari: Dictionary = results["safari_ball"]
						var sport: Dictionary = results["sport_ball"]
						check("Safari/Sport resultados idénticos con misma semilla y objetivo",
							is_equal_approx(float(safari.probability), float(sport.probability))
							and safari.status == sport.status
							and safari.rng_state == sport.rng_state)
	for id: StringName in [&"safari_ball", &"sport_ball"]:
		for reason: String in bloque.get("invalid_cases", []):
			_block07_reject(id, reason)


func _block07_reject(id: StringName, reason: String) -> void:
	var target: CreatureInstance = _mon(&"mew", 35,
		StringName("c003_07_bad_" + String(id) + "_" + reason))
	var ctx := CaptureBattleContext.new()
	var bag := PlayerInventory.new()
	bag.add(id, 2)
	match reason:
		"trainer_battle_not_capturable": ctx.is_wild = false
		"item_not_owned": bag.remove(id, 2)
		"target_knocked_out": target.current_hp = 0
		"battle_finished": ctx.battle_finished = true
	var before_target: Dictionary = target.to_dict()
	var before_bag: Dictionary = bag.to_dict()
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	var before_rng: int = rng.state
	var party := CreatureParty.new()
	var res: CaptureResolution = CaptureInventoryService.resolve(
		CaptureAttempt.new(target, id, ctx), rng, catalogs, party, bag)
	check("Safari/Sport invalidez sin consumo/RNG/cambios " + String(id) + reason,
		res.result.status == CaptureResult.INVALID
		and res.result.reason == reason and not res.result.consume_item
		and target.to_dict() == before_target and bag.to_dict() == before_bag
		and rng.state == before_rng and party.is_empty())


# 08: auditoría de dependencia, no simulación de efecto funcional.
# Una bola no registrada debe rechazarse antes de consumir inventario o RNG.
func _block_08(bloque: Dictionary) -> void:
	check("Bloque08 reserva exacta Lujo/Cebo",
		bloque.get("ids", []) == ["luxury_ball", "lure_ball"]
		and not bool(bloque.get("functional_effect_certified", true)))
	var rules := CaptureRuleset.new()
	for id: StringName in [&"luxury_ball", &"lure_ball"]:
		check("Lujo/Cebo aún sin definición operativa " + String(id),
			not rules.is_known_ball(id) and rules.ball(id) == null
			and not CaptureRuleset.ordered_ball_ids().has(id))
	for case: Dictionary in bloque.get("cases", []):
		var sid: StringName = StringName(String(case.get("species_id", "")))
		check("Bloque08 especie real " + String(sid), catalogs.species(sid) != null)
		if catalogs.species(sid) == null:
			continue
		for mode: String in bloque.get("hp_modes", []):
			for environment: Dictionary in bloque.get("contexts", []):
				for id: StringName in [&"luxury_ball", &"lure_ball"]:
					var target: CreatureInstance = _mon(sid, int(case.get("level", 12)),
						StringName("c003_08_" + String(id) + String(sid) + mode
						+ String(environment.get("name", ""))))
					target.current_hp = target.stats.max_hp if mode == "full" else 1
					var ctx := CaptureBattleContext.new()
					ctx.completed_turns = int(environment.get("completed_turns", -1))
					ctx.catcher_level = int(environment.get("catcher_level", -1))
					var inv := PlayerInventory.new()
					inv.add(id, 2)
					var party := CreatureParty.new()
					var rng := RandomNumberGenerator.new()
					rng.seed = int(case.get("seed", 8801))
					var before_rng: int = rng.state
					var before_target: Dictionary = target.to_dict()
					var before_inv: Dictionary = inv.to_dict()
					var attempt := CaptureAttempt.new(target, id, ctx)
					check("Lujo/Cebo valida rechazo actual " + String(id),
						CaptureSystem.validate_attempt(attempt, catalogs) == "unknown_ball")
					var result: CaptureResolution = CaptureInventoryService.resolve(
						attempt, rng, catalogs, party, inv)
					check("Lujo/Cebo rechazo seguro sin pérdida ni captura " + String(id),
						result.result.status == CaptureResult.INVALID
						and result.result.reason == "unknown_ball"
						and not result.result.consume_item
						and result.captured == null and party.is_empty()
						and inv.to_dict() == before_inv
						and target.to_dict() == before_target and rng.state == before_rng)

# 09: Amor/Luna sin definición operativa ni contexto de sexo/evolución lunar.
# Verificar comportamiento real de rechazo y prioridad de validación.
func _block_09(bloque: Dictionary) -> void:
	check("Bloque09 reserva exacta Amor/Luna",
		bloque.get("ids", []) == ["love_ball", "moon_ball"]
		and not bool(bloque.get("functional_effect_certified", true)))
	var rules := CaptureRuleset.new()
	for id: StringName in [&"love_ball", &"moon_ball"]:
		check("Amor/Luna todavía desconocidas para reglas de captura " + String(id),
			not rules.is_known_ball(id) and rules.ball(id) == null
			and not CaptureRuleset.ordered_ball_ids().has(id))
	for case: Dictionary in bloque.get("cases", []):
		var sid: StringName = StringName(String(case.get("species_id", "")))
		check("Amor/Luna especie real " + String(sid), catalogs.species(sid) != null)
		if catalogs.species(sid) == null:
			continue
		for mode: String in bloque.get("hp_modes", []):
			for environment: Dictionary in bloque.get("contexts", []):
				for id: StringName in [&"love_ball", &"moon_ball"]:
					var target: CreatureInstance = _mon(sid, int(case.get("level", 12)),
						StringName("c003_09_" + String(id) + String(sid)
						+ mode + String(environment.get("name", ""))))
					target.current_hp = target.stats.max_hp if mode == "full" else 1
					var ctx := CaptureBattleContext.new()
					ctx.completed_turns = int(environment.get("completed_turns", -1))
					ctx.catcher_level = int(environment.get("catcher_level", -1))
					var inv := PlayerInventory.new()
					inv.add(id, 2)
					var party := CreatureParty.new()
					var rng := RandomNumberGenerator.new()
					rng.seed = int(case.get("seed", 9901))
					var before_rng: int = rng.state
					var before_target: Dictionary = target.to_dict()
					var before_inv: Dictionary = inv.to_dict()
					var attempt := CaptureAttempt.new(target, id, ctx)
					check("Amor/Luna sin regla deben devolver unknown_ball " + String(id),
						CaptureSystem.validate_attempt(attempt, catalogs) == "unknown_ball")
					var result: CaptureResolution = CaptureInventoryService.resolve(
						attempt, rng, catalogs, party, inv)
					check("Amor/Luna rechazo no gasta ni modifica estados " + String(id),
						result.result.status == CaptureResult.INVALID
						and result.result.reason == "unknown_ball"
						and not result.result.consume_item and result.captured == null
						and party.is_empty() and inv.to_dict() == before_inv
						and target.to_dict() == before_target and rng.state == before_rng)
	for id: StringName in [&"love_ball", &"moon_ball"]:
		for reason: String in bloque.get("invalid_cases", []):
			var target: CreatureInstance = _mon(&"mew", 35,
				StringName("c003_09_reject_" + String(id) + reason))
			var ctx := CaptureBattleContext.new()
			var inv := PlayerInventory.new()
			inv.add(id, 2)
			match reason:
				"trainer_battle_not_capturable": ctx.is_wild = false
				"target_knocked_out": target.current_hp = 0
				"battle_finished": ctx.battle_finished = true
			var before_target: Dictionary = target.to_dict()
			var before_inv: Dictionary = inv.to_dict()
			var rng := RandomNumberGenerator.new()
			rng.seed = 909
			var before_rng: int = rng.state
			var party := CreatureParty.new()
			var result: CaptureResolution = CaptureInventoryService.resolve(
				CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inv)
			check("Amor/Luna prioridad rechazo seguro " + String(id) + reason,
				result.result.status == CaptureResult.INVALID
				and result.result.reason == reason
				and not result.result.consume_item and result.captured == null
				and party.is_empty() and inv.to_dict() == before_inv
				and target.to_dict() == before_target and rng.state == before_rng)


func _terminar_campania(bloques: int) -> void:
	done = true
	if errors.is_empty() and bloques > 0 and checks > 0:
		print("CAMP003_W03_GODOT PASS blocks=" + str(bloques) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP003_W03_GODOT FAIL blocks=" + str(bloques) +
			" checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
