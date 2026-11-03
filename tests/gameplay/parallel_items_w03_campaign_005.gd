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
			"03": _block_03(block)
			"04": _block_04(block)
			"05": _block_05(block)
			"06": _block_06(block)
			"07": _block_07(block)
			"08": _block_08(block)
			"09": _block_09(block)
			"10": _block_10(block)
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

# 03: verificar evolución REAL por Piedra Lunar, sin inventar sexo individual.
func _block_03(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Reserva 03 exacta", ids == ["love_ball", "moon_ball"])
	check("Sin certificación de bonus ficticio", block.get("current_state") == "DEPENDENCIA_CONCRETA"
		and not bool(block.get("functional_effect_certified", true)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Catálogo y selección Love/Moon " + raw_id,
			catalogs.item(id) != null and service_for().selection.content_allowed(id))
		check("Motor de captura no registra Love/Moon " + raw_id,
			not CaptureRuleset.new().is_known_ball(id))
	var target: CreatureInstance = _mon(&"nidorino", 25, &"c005_03_genderless_contract")
	var saved: Dictionary = target.to_dict()
	var restored: CreatureInstance = CreatureInstance.from_dict(saved)
	check("Sexo individual ausente del Save criatura",
		not saved.has("gender") and not saved.has("gender_id")
		and not saved.has("sex") and not saved.has("individual_gender_id"))
	check("Identidad de especie real sin sexo inventado",
		restored.to_dict() == saved and target.base_species_id() == &"nidorino"
		and restored.base_species_id() == &"nidorino")
	check("Piedra Lunar presente en catálogo", catalogs.item(&"moon_stone") != null)
	var moon_records := 0
	var moon_candidates := 0
	var other_item_rejects := 0
	var conditioned_moon := 0
	for sid: StringName in catalogs.species_catalog.all_ids():
		var species: CreatureSpecies = catalogs.species(sid)
		if species == null:
			continue
		for record: EvolutionRecord in species.evolutions:
			if record.item_id != &"moon_stone":
				continue
			moon_records += 1
			var cls: String = EvolutionSystem.classify_record(record, catalogs, species.id)
			if cls == EvolutionSystem.RUNTIME_SUPPORTED:
				var context := {"level": 25, "item_id": &"moon_stone"}
				var possible: Array = EvolutionSystem.evolution_candidates(species, context, catalogs)
				check("Piedra Lunar activa ruta exacta para " + String(sid), possible.has(record))
				moon_candidates += 1
				var other: Array = EvolutionSystem.evolution_candidates(species,
					{"level": 25, "item_id": &"water_stone"}, catalogs)
				check("Piedra Agua no activa ruta Lunar " + String(sid), not other.has(record))
				other_item_rejects += 1
			else:
				conditioned_moon += 1
	check("Existen datos reales de evolución Lunar", moon_records > 0)
	check("Existen rutas reales activas para la Piedra Lunar", moon_candidates > 0)
	check("Los registros no se convierten a elegibles sin versión", moon_records >= moon_candidates
		and other_item_rejects == moon_candidates and conditioned_moon >= 0)
	for producer: Dictionary in block.get("required_producers", []):
		check("Frontera exacta de contexto " + String(producer.get("id", "")),
			ids.has(String(producer.get("id", ""))) and
			not String(producer.get("producer", "")).is_empty() and
			not String(producer.get("consumer", "")).is_empty())

# Block04: authoritatively available species metadata and pure capture rate,
# not fabricated weight or Ultra Beast classification.
func _block_04(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bolas autorizadas del bloque 04", ids == ["beast_ball", "heavy_ball"])
	check("No certificar efecto Beast/Heavy sin esquema",
		block.get("current_state") == "DEPENDENCIA_CONCRETA"
		and not bool(block.get("functional_effect_certified", true)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Catálogo y selección reales " + raw_id,
			catalogs.item(id) != null and service_for().selection.content_allowed(id))
		check("Sin registro de factor no autorizado " + raw_id,
			not CaptureRuleset.new().is_known_ball(id))
	var species: CreatureSpecies = catalogs.species(&"snorlax")
	check("Especie con captura válida", species != null
		and CaptureRuleset.is_valid_capture_rate(species.capture_rate))
	var original: Dictionary = species.to_dict()
	var restored: CreatureSpecies = CreatureSpecies.from_dict(original)
	check("Fuente canónica de especie guarda tasa y metadatos",
		restored.capture_rate == species.capture_rate
		and restored.source_metadata == species.source_metadata)
	var properties: Array[String] = []
	for prop: Dictionary in species.get_property_list():
		properties.append(String(prop.get("name", "")))
	check("Peso canónico no es campo normalizado de especie",
		not properties.has("weight_hectograms")
		and not properties.has("weight_kg"))
	check("Clase ultraente no es campo normalizado de especie",
		not properties.has("is_ultra_beast"))
	var rules := CaptureRuleset.new()
	var probability: float = rules.catch_probability(species.capture_rate, 1.0, 1.0, 100, 100)
	var expected: float = float(species.capture_rate) / 255.0 / 3.0
	check("Probabilidad existente determinista y finita",
		is_equal_approx(probability, expected)
		and probability > 0.0 and probability <= 1.0)
	check("Límites de captura protegen la tasa", not CaptureRuleset.is_valid_capture_rate(0)
		and not CaptureRuleset.is_valid_capture_rate(256))
	check("No alterar datos de especie en auditoría", species.to_dict() == original)
	for producer: Dictionary in block.get("required_producers", []):
		check("Frontera concreta Beast/Heavy " + String(producer.get("id", "")),
			ids.has(String(producer.get("id", ""))
			) and not String(producer.get("producer", "")).is_empty()
			and not String(producer.get("decision", "")).is_empty())

# 05: test REAL existing factor and demonstrate missing trusted zone.
# A green test must NOT be interpreted as successful special-zone gating.
func _block_05(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Reserva Safari/Sport exacta", ids == ["safari_ball", "sport_ball"])
	check("Bola con factor real pero zona no conectada",
		block.get("current_state") == "PARTIAL_EXISTING_EFFECT_UNGATED"
		and not bool(block.get("functional_effect_certified", true)))
	var ctx := CaptureBattleContext.new()
	var ctx_fields: Array[String] = []
	for property: Dictionary in ctx.get_property_list():
		ctx_fields.append(String(property.get("name", "")))
	for field: String in ["is_safari_zone", "safari_capture_mode",
		"is_bug_contest_zone", "contest_capture_mode"]:
		check("No hay fuente de zona fiable en contexto " + field,
			not ctx_fields.has(field))
	var target: CreatureInstance = _mon(&"caterpie", 12, &"c005_05_target")
	var species: CreatureSpecies = catalogs.species(&"caterpie")
	check("La especie origen tiene tasa legal", species != null and
		CaptureRuleset.is_valid_capture_rate(species.capture_rate))
	var before: Dictionary = target.to_dict()
	var rules := CaptureRuleset.new()
	var base_p: float = rules.catch_probability(species.capture_rate, 1.0, 1.0,
		target.stats.max_hp, target.current_hp)
	var bonus_p: float = rules.catch_probability(species.capture_rate, 1.5, 1.0,
		target.stats.max_hp, target.current_hp)
	check("Efecto de captura x1.5 sí altera probabilidad real",
		bonus_p > base_p and is_equal_approx(bonus_p, base_p * 1.5))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Bola presente y seleccionada " + raw_id,
			catalogs.item(id) != null and service_for().selection.content_allowed(id))
		check("Bola reconocida en motor real " + raw_id,
			rules.is_known_ball(id))
		check("Prevuelo de captura legítima " + raw_id,
			CaptureSystem.validate_attempt(CaptureAttempt.new(target, id, ctx),
				catalogs) == "")
		check("Factor real actual incondicional x1.5 " + raw_id,
			is_equal_approx(CaptureRuleset.BallEffects.multiplier(id, target, species), 1.5))
		check("No se altera el objetivo al consultar el factor " + raw_id,
			target.to_dict() == before)
	check("No marcar zonas como verificadas sin productor",
		ctx_fields.has("is_wild") and ctx.is_wild
		and not ctx_fields.has("is_safari_zone")
		and not ctx_fields.has("is_bug_contest_zone"))
	for producer: Dictionary in block.get("required_producers", []):
		check("Contrato de propietario y consumidor " + String(producer.get("id", "")),
			ids.has(String(producer.get("id", ""))) and
			not String(producer.get("producer", "")).is_empty() and
			not String(producer.get("consumer", "")).is_empty())

func _block_06(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Cola exacta bloque 06", ids == ["repel", "super_repel", "max_repel"])
	check("Pendiente productor mundo", block.get("current_state") == "DEPENDENCIA_COMPARTIDA"
		and not bool(block.get("functional_effect_certified", true)))
	var table := WildEncounterTable.new(&"zone_06", 0)
	check("Tabla válida con un slot", table.add_slot(WildEncounterSlot.new(
		&"slot_06", &"caterpie", 1, 8, 8)))
	var packed: Dictionary = table.to_dict()
	var restored := WildEncounterTable.from_dict(packed)
	check("Roundtrip tabla", not restored.corrupted and restored.to_dict() == packed)
	var rng := RandomNumberGenerator.new()
	rng.seed = 60606
	var previous_state: int = rng.state
	var missed := WildEncounterSystem.resolve(restored, rng, catalogs)
	check("Encuentro al cero: NONE y RNG intacto",
		missed.status == WildEncounterResult.NONE and
		missed.reason == "chance_miss" and rng.state == previous_state)
	var guaranteed := WildEncounterTable.new(&"zone_06", 10000)
	check("Slot de encuentro seguro", guaranteed.add_slot(
		WildEncounterSlot.new(&"slot_06", &"caterpie", 1, 8, 8)))
	var found := WildEncounterSystem.resolve(guaranteed, rng, catalogs)
	check("Encuentro real a nivel ocho", found.status == WildEncounterResult.ENCOUNTER
		and found.creature != null and found.level == 8)
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Repelente seleccionado " + raw_id,
			catalogs.item(id) != null and service_for().selection.content_allowed(id))
		var has_owner := false
		for producer: Dictionary in block.get("required_producers", []):
			if String(producer.get("id", "")) == raw_id:
				has_owner = String(producer.get("producer", "")) == "overworld_steps"
		check("Frontera del contador descrita " + raw_id, has_owner)

# 07: test an EXISTING field-rate modifier; no invented lure/flute effect.
func _block_07(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Cola 07 exacta", ids == ["black_flute", "white_flute",
		"lure", "super_lure", "max_lure"])
	check("No certificar efecto sin fuente mundo",
		block.get("current_state") == "DEPENDENCIA_COMPARTIDA"
		and not bool(block.get("functional_effect_certified", true)))
	var modifier := preload("res://modules/gameplay/encounter_item_modifiers.gd")
	check("Existe regla real de frecuencia Cleanse Tag",
		modifier.supports(&"cleanse_tag") and modifier.supports(&"pure_incense"))
	check("Regla real reduce 6000 a 4000",
		modifier.modified_chance_bp(6000) == 4000)
	check("Regla real respeta cero y límite de redondeo",
		modifier.modified_chance_bp(0) == 0
		and modifier.modified_chance_bp(1) >= 1)
	var table := WildEncounterTable.new(&"w03_zone_07", 6000)
	check("Tabla real de frecuencia admite slot",
		table.add_slot(WildEncounterSlot.new(&"w03_slot_07", &"caterpie", 1, 8, 8)))
	var packed: Dictionary = table.to_dict()
	var restored := WildEncounterTable.from_dict(packed)
	check("Roundtrip del contrato de frecuencia",
		not restored.corrupted and restored.to_dict() == packed)
	var reduced := WildEncounterTable.from_dict(packed)
	reduced.encounter_chance_bp = modifier.modified_chance_bp(table.encounter_chance_bp)
	check("Tabla de frecuencia adaptada es válida",
		reduced.validate(catalogs).ok and reduced.encounter_chance_bp == 4000)
	check("La tabla original y su RNG permanecen ajenos a la consulta",
		table.to_dict() == packed and restored.encounter_chance_bp == 6000)
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("ID aprobado y seleccionado " + raw_id,
			catalogs.item(id) != null and service_for().selection.content_allowed(id))
		check("No confundir objeto de campo con Cleanse Tag " + raw_id,
			not modifier.supports(id))
		var found := false
		for producer: Dictionary in block.get("required_producers", []):
			if producer.get("id", "") == raw_id:
				found = producer.get("producer", "") == "overworld_movement_encounter_scheduler"
		check("Contrato de productor identificado " + raw_id, found)

# 08: Blue Flute has a real field effect; Red/Yellow require battle volatile context.
func _block_08(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Reserva exacta flautas 08", ids == ["red_flute", "yellow_flute", "blue_flute"])
	check("Distinguir efecto Azul de dependencias volátiles",
		block.get("current_state") == "PARTIAL_BLUE_FIELD_FUNCTIONAL"
		and not bool(block.get("functional_effect_certified", true)))
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://modules/inventory/imported_recovery_v19.json"))
	var blue: Dictionary = profile.get("items", {}).get("blue_flute", {})
	check("Flauta Azul: fuente real no consumible y cura sueño",
		blue.get("consume", true) == false
		and blue.get("effect", {}).get("cure", []).has("slp"))
	for raw_id: String in ids:
		check("Flauta seleccionada " + raw_id,
			catalogs.item(StringName(raw_id)) != null
			and service_for().selection.content_allowed(StringName(raw_id)))
	var service := service_for()
	var target: CreatureInstance = service.owner.owned_creature(&"field_item_target")
	status(target, &"sleep")
	service.sleep_clocks[String(target.instance_id)] = {
		"version": "0.10.11", "start_time": 3, "time": 2}
	check("Mochila recibe Flauta Azul", service.owner.inventory.add(&"blue_flute", 2))
	var old_target: Dictionary = target.to_dict()
	var result: Dictionary = service.use_item(&"blue_flute", target.instance_id)
	var recovered: CreatureInstance = service.owner.owned_creature(target.instance_id)
	check("Flauta Azul cura sueño en servicio real",
		result.get("accepted", false) == true
		and recovered != null and recovered.status_state.persistent_id == &""
		and recovered.status_ids.is_empty())
	check("Flauta Azul se conserva y mantiene identidad",
		service.owner.inventory.quantity(&"blue_flute") == 2
		and recovered.instance_id == target.instance_id
		and target.to_dict() == old_target)
	check("Flauta Azul elimina reloj de sueño", service.sleep_clocks.is_empty())
	var no_effect_before: String = snapshot(service)
	var no_effect: Dictionary = service.use_item(&"blue_flute", recovered.instance_id)
	check("Flauta Azul sin efecto no muta ni consume",
		not bool(no_effect.get("accepted", false))
		and String(no_effect.get("reason", "")) == "item_has_no_effect"
		and snapshot(service) == no_effect_before)
	for id: StringName in [&"red_flute", &"yellow_flute"]:
		var other := service_for()
		check("Flauta de batalla añadida " + String(id),
			other.owner.inventory.add(id, 2))
		var own: CreatureInstance = other.owner.owned_creature(&"field_item_target")
		own.status_state.add_volatile(&"confusion")
		var before: String = snapshot(other)
		var denied: Dictionary = other.use_item(id, own.instance_id)
		check("No inventar curación de campo " + String(id),
			not bool(denied.get("accepted", false))
			and String(denied.get("reason", "")) == "field_effect_not_connected"
			and snapshot(other) == before)

func _block_09(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Cola 09 exacta", ids == ["escape_rope", "fluffy_tail"])
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://modules/inventory/battle_escape_profile.json"))
	var spec: Dictionary = profile.get("items", {}).get("fluffy_tail", {})
	check("Cola Esponjosa tiene huida garantizada sin RNG",
		spec.get("consume", 0) == 1 and spec.get("guaranteed", false)
		and spec.get("wild_only", false) and not spec.get("rng_consumed", true))
	for raw_id: String in ids:
		var service := service_for()
		var id := StringName(raw_id)
		check("Objeto seleccionado " + raw_id,
			catalogs.item(id) != null and service.selection.content_allowed(id))
		check("Mochila admite objeto " + raw_id,
			service.owner.inventory.add(id, 2))
		var before: String = snapshot(service)
		var result: Dictionary = service.use_item(id, &"field_item_target")
		check("Rechazo de campo no consume " + raw_id,
			not bool(result.get("accepted", false))
			and String(result.get("reason", "")) == "field_effect_not_connected"
			and snapshot(service) == before)

func _finish(n: int) -> void:
	done = true
	if errors.is_empty() and n > 0 and checks > 0:
		print("CAMP005_W03_GODOT PASS blocks=" + str(n) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP005_W03_GODOT FAIL blocks=" + str(n) + " checks=" + str(checks)
			+ " errors=" + JSON.stringify(errors))
		quit(1)
