extends "res://tests/gameplay/item_capture_v11.gd"

# CAMP003 / IA3-W03: sólo pruebas acumulativas. No editar captura o catálogo.
const CAMP003_W03_FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_003.json"
const CAMP003_W03_TURN_EFFECTS = preload("res://modules/capture/capture_context_ball_effects.gd")


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


func _terminar_campania(bloques: int) -> void:
	done = true
	if errors.is_empty() and bloques > 0 and checks > 0:
		print("CAMP003_W03_GODOT PASS blocks=" + str(bloques) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP003_W03_GODOT FAIL blocks=" + str(bloques) +
			" checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
