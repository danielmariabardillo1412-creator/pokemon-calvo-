extends "res://tests/gameplay/item_capture_v11.gd"

# W03 CAMP005: contrato NUEVO del productor de contexto; no repetir
# la matriz unknown_ball de CAMP004 ni inventar señales de mundo/Pokédex.
const FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_005.json"

func _initialize() -> void:
	call_deferred("_run_campaign")
	create_timer(180).timeout.connect(func():
		if not done:
			push_error("CAMP005_W03_TIMEOUT")
			quit(2)
	)

func _run_campaign() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))
	if not raw is Dictionary:
		check("Catálogo real presente", false)
		_finish(0)
		return
	catalogs = GameData.from_dict(raw).to_definition_catalog()
	check("Overlay regional real", Variants.apply(catalogs))
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not decoded is Dictionary:
		check("Fixture CAMP005 legible", false)
		_finish(0)
		return
	var blocks: Array = decoded.get("blocks", [])
	check("CAMP005 identidad y progreso", decoded.get("campaign") == "CAMP_005"
		and decoded.get("worker") == "W03" and blocks.size() > 0)
	var n := 0
	for block: Dictionary in blocks:
		n += 1
		match String(block.get("bloque", "")):
			"01": _block_01(block)
			_: check("Bloque sin prueba propia " + str(n), false)
	_finish(n)

func _block_01(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Cola exacta W03", ids == ["dive_ball", "dusk_ball", "repeat_ball"])
	check("No se afirma efecto nuevo", block.get("current_state") == "DEPENDENCIA_CONCRETA"
		and not bool(block.get("functional_effect_certified", true)))
	var ctx := CaptureBattleContext.new()
	var property_names: Array[String] = []
	for descriptor: Dictionary in ctx.get_property_list():
		property_names.append(String(descriptor.get("name", "")))
	for producer: Dictionary in block.get("required_producers", []):
		var id := StringName(String(producer.get("id", "")))
		check("Existe definición canónica de bola pendiente " + String(id),
			catalogs.item(id) != null)
		for field: String in producer.get("missing_fields", []):
			check("Falta productor explícito " + String(id) + " " + field,
				not property_names.has(field))
	check("Los campos de contexto operativos son legibles",
		property_names.has("completed_turns") and property_names.has("catcher_level")
		and property_names.has("is_wild") and property_names.has("battle_finished"))
	# Ejemplo positivo del contrato que SÍ tiene productor: turno/nivel.
	# No pasa ninguno de esos valores por equivalencia con día, ubicación o historial.
	ctx.is_wild = true
	ctx.completed_turns = 0
	ctx.catcher_level = 50
	var target: CreatureInstance = _mon(&"mew", 25, &"camp005_context_target")
	var species: CreatureSpecies = catalogs.species(&"mew")
	check("Fuente de turno admite Quick Ball real",
		CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"quick_ball", ctx), catalogs) == ""
		and is_equal_approx(CaptureRuleset.ContextBallEffects.multiplier(
			&"quick_ball", target, species, ctx), 5.0))
	check("Fuente de turno admite Timer Ball real",
		CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"timer_ball", ctx), catalogs) == ""
		and is_equal_approx(CaptureRuleset.ContextBallEffects.multiplier(
			&"timer_ball", target, species, ctx), 1.0))
	check("Fuente de nivel admite Level Ball real",
		CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"level_ball", ctx), catalogs) == ""
		and is_equal_approx(CaptureRuleset.ContextBallEffects.multiplier(
			&"level_ball", target, species, ctx), 4.0))
	# El contexto no puede garantizar bonificaciones geográficas/registro
	# con estos dos únicos datos de origen. No forzar RNG ni consumo.
	var before: Array = [target.to_dict(), ctx.completed_turns, ctx.catcher_level]
	check("No se muta criatura ni contexto durante sondeo",
		target.to_dict() == before[0] and ctx.completed_turns == before[1]
		and ctx.catcher_level == before[2])

func _finish(n: int) -> void:
	done = true
	if errors.is_empty() and n > 0 and checks > 0:
		print("CAMP005_W03_GODOT PASS blocks=" + str(n) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP005_W03_GODOT FAIL blocks=" + str(n) + " checks=" + str(checks)
			+ " errors=" + JSON.stringify(errors))
		quit(1)
