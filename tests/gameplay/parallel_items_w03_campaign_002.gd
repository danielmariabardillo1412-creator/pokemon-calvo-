extends "res://tests/gameplay/item_capture_v11.gd"

# IA3/W03 CAMP_002 / ITER_02 — caracterización NEGATIVA de tres bolas.
# No calcula factores ni agrega contexto inventado: lo normativo vive en el
# fixture y la prueba de Python; aquí se ejecuta el servicio ACTUAL.
const CAMP_002_W03_FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_002.json"
const CAMP_002_W03_BALL_EFFECTS = preload("res://modules/capture/capture_ball_effects.gd")


func _initialize() -> void:
	call_deferred("_run")
	create_timer(120).timeout.connect(func():
		if not done:
			push_error("CAMP_002_W03_TIMEOUT")
			quit(2)
	)


func _run() -> void:
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMP_002_W03_FIXTURE))
	if not decoded is Dictionary:
		check("W03 fixture JSON válido", false)
		_finish()
		return
	var fixture: Dictionary = decoded
	var registros: Array = fixture.get("records", [])
	check("Fixture contiene exactamente tres bolas", registros.size() == 3)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not raw is Dictionary:
		check("Catálogo Pokémon disponible", false)
		_finish()
		return
	catalogs = GameData.from_dict(raw).to_definition_catalog()
	check("Overlay regional de especies", Variants.apply(catalogs))
	var reglas := CaptureRuleset.new()
	check("Net anterior sigue registrada", reglas.is_known_ball(&"net_ball"))
	check("Poke Ball anterior sigue registrada", reglas.is_known_ball(&"poke_ball"))
	for registro: Dictionary in registros:
		_test_bola(registro, reglas)
	_test_regresiones_net_v11_v15(reglas, fixture)
	_finish()


func _test_bola(registro: Dictionary, reglas: CaptureRuleset) -> void:
	var id: StringName = StringName(String(registro.get("id", "")))
	check("ID permitido en fixture " + String(id),
		id in [&"dusk_ball", &"repeat_ball", &"dive_ball"])
	check("Fixture solo documenta comportamiento actual " + String(id),
		registro.get("current_expected_status", "") == "unknown_ball"
		and not bool(registro.get("functional_implementation_authorized", true)))
	check("Bola seleccionada todavía no conectada " + String(id),
		not reglas.is_known_ball(id) and reglas.ball(id) == null
		and not CaptureRuleset.ordered_ball_ids().has(id))
	check("Bola existe en catálogo sin inferir un efecto " + String(id), catalogs.item(id) != null)

	# Dos contextos legales del motor: sin datos de turno y con turno/nivel.
	# Ninguno aporta noche/cueva, Pokédex previa o situación subacuática.
	for modo in 2:
		var objetivo: CreatureInstance = _mon(&"mew", 50,
			StringName("w03_camp002_" + String(id) + "_" + str(modo)))
		objetivo.current_hp = objetivo.stats.max_hp
		var contexto := CaptureBattleContext.new()
		if modo == 1:
			contexto.completed_turns = 0
			contexto.catcher_level = 50
		var intento := CaptureAttempt.new(objetivo, id, contexto)
		check("Validación mantiene unknown_ball " + String(id) + " modo=" + str(modo),
			CaptureSystem.validate_attempt(intento, catalogs) == "unknown_ball")
		var mochila := PlayerInventory.new()
		mochila.add(id, 2)
		var equipo := CreatureParty.new()
		var antes_mochila := mochila.to_dict()
		var antes_objetivo := objetivo.to_dict()
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026 + modo
		var antes_rng := rng.state
		var resultado := CaptureInventoryService.resolve(
			intento, rng, catalogs, equipo, mochila)
		check("Unknown ball no consume, no RNG, no mutación " + String(id) + " modo=" + str(modo),
			resultado.result.status == CaptureResult.INVALID
			and resultado.result.reason == "unknown_ball"
			and not resultado.result.consume_item
			and mochila.to_dict() == antes_mochila
			and mochila.quantity(id) == 2
			and rng.state == antes_rng
			and objetivo.to_dict() == antes_objetivo
			and equipo.is_empty())

	# La precedencia de los rechazos generales no debe alterarse.
	for escenario in 3:
		var salvaje: CreatureInstance = _mon(&"mew", 40,
			StringName("w03_camp002_neg_" + String(id) + "_" + str(escenario)))
		var contexto_negativo := CaptureBattleContext.new()
		match escenario:
			0: contexto_negativo.is_wild = false
			1: contexto_negativo.battle_finished = true
			2: salvaje.current_hp = 0
		var razones := ["trainer_battle_not_capturable", "battle_finished", "target_knocked_out"]
		var mochila := PlayerInventory.new()
		mochila.add(id, 1)
		var antes := mochila.to_dict()
		var antes_pokemon := salvaje.to_dict()
		var rng := RandomNumberGenerator.new()
		rng.seed = 501 + escenario
		var estado := rng.state
		var resultado := CaptureInventoryService.resolve(
			CaptureAttempt.new(salvaje, id, contexto_negativo),
			rng, catalogs, CreatureParty.new(), mochila)
		check("Negativo general sin gasto " + String(id) + " " + str(escenario),
			resultado.result.status == CaptureResult.INVALID
			and resultado.result.reason == razones[escenario]
			and not resultado.result.consume_item
			and mochila.to_dict() == antes
			and salvaje.to_dict() == antes_pokemon
			and rng.state == estado)



# Solo regresiones breves del motor EXISTENTE; no reejecutar miles de casos V11/V15.
# No se habilita Ocaso/Acopio/Buceo ni se inventan señales de contexto.
func _test_regresiones_net_v11_v15(reglas: CaptureRuleset, fixture: Dictionary) -> void:
	var etapa: Dictionary = fixture.get("phase_03", {})
	check("ITER03 contrato de decisiones y regresiones presente",
		etapa.get("permission", "") == "NO_PRODUCTION_CHANGES_NO_NEW_CAPTURE_CONTEXT")
	check("Net no duplicada en selector",
		reglas.is_known_ball(&"net_ball")
		and CaptureRuleset.ordered_ball_ids().count(&"net_ball") == 1)
	# Confirmar que siguen existiendo las pruebas anteriores, sin modificarlas.
	var v11 := FileAccess.get_file_as_string("res://tests/gameplay/item_capture_v11.gd")
	var v15 := FileAccess.get_file_as_string("res://tests/gameplay/item_capture_v15.gd")
	var no_soportadas_v11 := ""
	var no_soportadas_v15 := ""
	for linea in v11.split("\n"):
		if linea.contains("for unsupported:"):
			no_soportadas_v11 = linea
			break
	for linea in v15.split("\n"):
		if linea.contains("for unsupported:"):
			no_soportadas_v15 = linea
			break
	check("V11 mantiene negativos sin volver a excluir Net",
		not no_soportadas_v11.is_empty() and not no_soportadas_v11.contains("net_ball")
		and no_soportadas_v11.contains("luxury_ball")
		and v11.contains("Net registered through shared ball adapter"))
	check("V15 sigue rechazando Acopio y admitiendo Net",
		not no_soportadas_v15.is_empty() and no_soportadas_v15.contains("repeat_ball")
		and no_soportadas_v15.contains("luxury_ball")
		and not no_soportadas_v15.contains("net_ball")
		and v15.contains("Net species-based probability"))
	# Comprobar el efecto REAL de Malla sin modificar fórmulas o semillas.
	for caso: Dictionary in etapa.get("regression_cases", []):
		var sid: StringName = StringName(String(caso.get("species_id", "")))
		var especie: CreatureSpecies = catalogs.species(sid)
		check("Net especie real presente " + String(sid), especie != null)
		if especie == null:
			continue
		var esperado_factor: float = float(caso.get("expected_factor", -1))
		var objetivo: CreatureInstance = _mon(sid, 12, StringName("w03_c002_net_" + String(sid)))
		objetivo.current_hp = 1
		var efectivo: float = CAMP_002_W03_BALL_EFFECTS.multiplier(&"net_ball", objetivo, especie)
		check("Net factor canónico sin dobles premios " + String(sid),
			is_equal_approx(efectivo, esperado_factor))
		if sid == &"surskit":
			check("Surskit confirma ambos tipos de especie",
				especie.has_type(&"water") and especie.has_type(&"bug"))
		var esperado_p: float = reglas.catch_probability(
			especie.capture_rate, esperado_factor, 1.0,
			objetivo.stats.max_hp, objetivo.current_hp)
		var mochila := PlayerInventory.new()
		mochila.add(&"net_ball", 2)
		var equipo := CreatureParty.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 2303
		var rng_antes := rng.state
		var resultado := CaptureInventoryService.resolve(
			CaptureAttempt.new(objetivo, &"net_ball", CaptureBattleContext.new()),
			rng, catalogs, equipo, mochila)
		check("Net probabilidad, consumo y RNG " + String(sid),
			resultado.result.status != CaptureResult.INVALID
			and resultado.result.consume_item
			and is_equal_approx(resultado.result.probability, esperado_p)
			and mochila.quantity(&"net_ball") == 1
			and rng.state != rng_antes)
		check("Net identidad y equipo si captura " + String(sid),
			resultado.result.status != CaptureResult.SUCCESS
			or (is_same(resultado.captured, objetivo)
				and equipo.contains_instance_id(objetivo.instance_id)))


func _finish() -> void:
	var resultado := {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"checks": checks,
		"errors": errors,
		"scope": "NEGATIVE_CURRENT_BEHAVIOR_ONLY",
		"new_balls_functional": false,
		"godot": Engine.get_version_info().get("string", "")
	}
	print("CAMP_002_W03_NEGATIVE ", JSON.stringify(resultado))
	done = true
	quit(0 if errors.is_empty() else 1)
