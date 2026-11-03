extends "res://tests/gameplay/item_capture_v11.gd"

# CAMP003 / IA3-W03: sólo pruebas acumulativas. No editar captura o catálogo.
const CAMP003_W03_FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_003.json"


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


func _terminar_campania(bloques: int) -> void:
	done = true
	if errors.is_empty() and bloques > 0 and checks > 0:
		print("CAMP003_W03_GODOT PASS blocks=" + str(bloques) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP003_W03_GODOT FAIL blocks=" + str(bloques) +
			" checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
