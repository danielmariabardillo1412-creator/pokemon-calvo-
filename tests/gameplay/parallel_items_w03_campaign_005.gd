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
			"02": _block_02(block)
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

# 02: Luxury Ball needs persistable capture-origin metadata; Lure Ball needs
# a trusted fishing producer. Test the existing REAL positive friendship path.
func _block_02(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Reserva bloque02 exacta", ids == ["luxury_ball", "lure_ball"])
	check("Contratos siguen pendientes", block.get("current_state") == "DEPENDENCIA_CONCRETA"
		and not bool(block.get("functional_effect_certified", true)))
	var context := CaptureBattleContext.new()
	var context_fields: Array[String] = []
	for prop: Dictionary in context.get_property_list():
		context_fields.append(String(prop.get("name", "")))
	var target: CreatureInstance = _mon(&"caterpie", 12, &"c005_02_target")
	var serialized: Dictionary = target.to_dict()
	var original_keys: Array[String] = []
	for k: Variant in serialized.keys():
		original_keys.append(String(k))
	var restored: CreatureInstance = CreatureInstance.from_dict(serialized)
	check("La criatura mantiene identidad y amistad tras reconstrucción",
		restored.to_dict() == serialized and restored.instance_id == target.instance_id
		and restored.friendship == target.friendship)
	var friendship_effects = preload("res://modules/inventory/field_friendship_effects.gd")
	restored.friendship = 0
	var baseline: int = friendship_effects.increase(restored, [5, 3, 2])
	check("Ganancia real de amistad ya funciona sin Luxury",
		baseline == 5 and restored.friendship == 5)
	restored.friendship = 0
	restored.held_item_id = &"soothe_bell"
	var bell_gain: int = friendship_effects.increase(restored, [5, 3, 2])
	check("Bonificación existente Campana Alivio funcional",
		bell_gain == 7 and restored.friendship == 7)
	check("No se debe confundir la captura Luxury con objeto equipado",
		restored.held_item_id == &"soothe_bell")
	check("Falta origen Ball serializado — integración de captura pendiente",
		not original_keys.has("original_capture_ball_id")
		and not original_keys.has("capture_ball_id"))
	check("Falta método de pesca en contexto de captura",
		not context_fields.has("encounter_method")
		and not context_fields.has("fishing_provenance"))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Objeto seleccionado y presente " + raw_id,
			catalogs.item(id) != null and service_for().selection.content_allowed(id))
		check("No registrar bola sin contexto fiable " + raw_id,
			not CaptureRuleset.new().is_known_ball(id))
	for producer: Dictionary in block.get("required_producers", []):
		check("Dependencia ligada a ID " + String(producer.get("id", "")),
			ids.has(String(producer.get("id", "")))
			and String(producer.get("producer", "")) != ""
			and String(producer.get("consumer", "")) != "")
	var unchanged: Dictionary = target.to_dict()
	check("Auditoría sin mutación accidental de Pokémon original",
		target.to_dict() == unchanged)

func _finish(n: int) -> void:
	done = true
	if errors.is_empty() and n > 0 and checks > 0:
		print("CAMP005_W03_GODOT PASS blocks=" + str(n) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP005_W03_GODOT FAIL blocks=" + str(n) + " checks=" + str(checks)
			+ " errors=" + JSON.stringify(errors))
		quit(1)
