extends "res://tests/gameplay/item_capture_v11.gd"

# IA3/W03 CAMP_002 / ITER_02 — caracterización NEGATIVA de tres bolas.
# No calcula factores ni agrega contexto inventado: lo normativo vive en el
# fixture y la prueba de Python; aquí se ejecuta el servicio ACTUAL.
const CAMP_002_W03_FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_002.json"


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
