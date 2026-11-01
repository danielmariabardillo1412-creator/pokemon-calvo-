extends "res://tests/gameplay/parallel_items_w03_capture_net_v1.gd"

# CAMP_001 / W03 / ITER_03: regresión Net con servicios reales y SaveGame V2.
# Este script NO cambia la fórmula de captura ni el RNG del juego.
# Un PASS aquí será solo un resultado de la ejecución real de Godot 4.7.
const NET_SAVE_PATH := "user://w03_camp001_net_save_v2.json"
const BallEffectsW03 = preload("res://modules/capture/capture_ball_effects.gd")
const NetBallPicker = preload("res://scenes/visual/capture_ball_picker.gd")


func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not raw is Dictionary:
		check("dataset Pokemon normalizado disponible", false)
		_terminar()
		return
	catalogs = GameData.from_dict(raw).to_definition_catalog()
	check("overlay regional de especies", Variants.apply(catalogs))
	check("Net registrada antes de prueba funcional", CaptureRuleset.new().is_known_ball(&"net_ball"))
	_probe_live_types() # Agua/Bicho/Normal: especies y encuentros reales.
	_probe_net_boundary() # Probabilidad y gasto para los tres tipos.
	_verify_valid_failure_and_persistence() # Control Poké Ball / Save V2.
	_verify_master_storage_and_persistence() # Control Master Ball / PC.
	_probar_doble_tipo()
	_probar_net_equipo_pc_guardado()
	_probar_net_fallo_y_rechazos()
	_probar_selector_y_descriptor()
	_terminar()


func _probar_doble_tipo() -> void:
	# Surskit es Bicho/Agua: exige UN SOLO factor 3,5, no 3,5 al cuadrado.
	var especie: CreatureSpecies = catalogs.species(&"surskit")
	check("especie real Surskit disponible", especie != null)
	if especie == null:
		return
	check("Surskit es Bicho y Agua en catálogo", especie.has_type(&"bug") and especie.has_type(&"water"))
	var objetivo := _mon(&"surskit", 12, &"w03_net_doble")
	var factor := BallEffectsW03.multiplier(&"net_ball", objetivo, especie)
	check("Net Agua+Bicho no acumula multiplicador", is_equal_approx(factor, EXPECTED_NET_FACTOR))
	var mochila := PlayerInventory.new()
	mochila.add(&"net_ball", 2)
	objetivo.current_hp = 1
	var esperado := CaptureRuleset.new().catch_probability(
		especie.capture_rate, EXPECTED_NET_FACTOR, 1.0,
		objetivo.stats.max_hp, objetivo.current_hp)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1403
	var resultado := CaptureInventoryService.resolve(
		CaptureAttempt.new(objetivo, &"net_ball", CaptureBattleContext.new()),
		rng, catalogs, CreatureParty.new(), mochila)
	check("Net doble tipo usa factor 3,5 una sola vez", resultado.result.status != CaptureResult.INVALID
		and is_equal_approx(resultado.result.probability, esperado)
		and resultado.result.consume_item and mochila.quantity(&"net_ball") == 1)


func _probar_net_equipo_pc_guardado() -> void:
	# Agua, captura garantizada POR LA PROBABILIDAD REAL (no Master Ball).
	var owner := PlayerCollection.new()
	owner.inventory.add(&"net_ball", 2)
	var objetivo := _mon(&"magikarp", 5, &"w03_net_equipo")
	objetivo.current_hp = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	var control := RandomNumberGenerator.new()
	control.state = rng.state
	control.randf()
	var r := CaptureInventoryService.resolve(
		CaptureAttempt.new(objetivo, &"net_ball", CaptureBattleContext.new()),
		rng, catalogs, owner.party, owner.inventory)
	check("Net Agua al equipo consume una y un RNG", r.result.status == CaptureResult.SUCCESS
		and r.result.consume_item and owner.inventory.quantity(&"net_ball") == 1
		and owner.party.contains_instance_id(objetivo.instance_id) and rng.state == control.state)
	var routed := CaptureOwnershipRouter.new().route(r, owner.party, owner.storage)
	check("Net Agua confirma propiedad de equipo", routed.routed and not routed.stored
		and owner.location_of(objetivo.instance_id) == &"PARTY"
		and is_same(owner.owned_creature(objetivo.instance_id), objetivo))
	# Bicho, captura por reglas reales con equipo lleno: debe acabar en PC.
	var completo := PlayerCollection.new()
	for i in 6:
		completo.party.add_creature(_mon(&"pidgey", 10, StringName("w03_net_miembro_" + str(i))))
	completo.inventory.add(&"net_ball", 1)
	var bicho := _mon(&"caterpie", 5, &"w03_net_en_pc")
	bicho.current_hp = 1
	var rng_pc := RandomNumberGenerator.new()
	rng_pc.seed = 2718
	var res := CaptureInventoryService.resolve(
		CaptureAttempt.new(bicho, &"net_ball", CaptureBattleContext.new()),
		rng_pc, catalogs, completo.party, completo.inventory)
	check("Net Bicho equipo completo pide PC y consume una", res.result.status == CaptureResult.SUCCESS
		and res.disposition == CaptureDisposition.STORAGE_REQUIRED and completo.party.size() == 6
		and completo.inventory.quantity(&"net_ball") == 0)
	var salida := CaptureOwnershipRouter.new().route(res, completo.party, completo.storage)
	check("Net Bicho tiene dueño exclusivo en PC", salida.routed and salida.stored
		and completo.location_of(bicho.instance_id) == &"STORAGE"
		and completo.storage.contains_instance_id(bicho.instance_id)
		and not completo.party.contains_instance_id(bicho.instance_id)
		and is_same(completo.owned_creature(bicho.instance_id), bicho))
	var repositorio := SaveGameRepository.new()
	var escrito := repositorio.save_collection(NET_SAVE_PATH, completo)
	check("Net Bicho PC se guarda en Save V2", escrito.ok)
	if escrito.ok:
		var cargado := repositorio.load(NET_SAVE_PATH)
		check("Net Bicho PC mantiene propietario y consumo tras carga", cargado.ok
			and cargado.storage.contains_instance_id(bicho.instance_id)
			and not cargado.party.contains_instance_id(bicho.instance_id)
			and cargado.party.size() == 6 and cargado.inventory.quantity(&"net_ball") == 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(NET_SAVE_PATH))


func _probar_net_fallo_y_rechazos() -> void:
	# Normal/no aplicable: Mew no es Agua/Bicho. Elegir semilla que falla
	# por el mismo RNG inyectado que usa CaptureSystem, sin cambiar la probabilidad.
	var objetivo := _mon(&"mew", 100, &"w03_net_fallo")
	objetivo.current_hp = objetivo.stats.max_hp
	var especie: CreatureSpecies = catalogs.species(&"mew")
	check("Net Mew tiene factor neutro", is_equal_approx(
		BallEffectsW03.multiplier(&"net_ball", objetivo, especie), 1.0))
	var probabilidad := CaptureRuleset.new().catch_probability(
		especie.capture_rate, 1.0, 1.0, objetivo.stats.max_hp, objetivo.current_hp)
	var elegido := -1
	var predictor := RandomNumberGenerator.new()
	for valor in range(1, 1025):
		predictor.seed = valor
		if predictor.randf() >= probabilidad:
			elegido = valor
			break
	check("semilla de fracaso Net reproducible", elegido >= 0)
	if elegido >= 0:
		var owner := PlayerCollection.new()
		owner.inventory.add(&"net_ball", 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = elegido
		var resultado := CaptureInventoryService.resolve(
			CaptureAttempt.new(objetivo, &"net_ball", CaptureBattleContext.new()),
			rng, catalogs, owner.party, owner.inventory)
		check("Net fallo válido consume una y un RNG", resultado.result.status == CaptureResult.FAILED
			and resultado.result.consume_item and owner.inventory.quantity(&"net_ball") == 1
			and owner.party.is_empty() and rng.state == predictor.state)
		var repositorio := SaveGameRepository.new()
		var guardado := repositorio.save_collection(NET_SAVE_PATH, owner)
		check("Net fallo guarda inventario V2", guardado.ok)
		if guardado.ok:
			var cargado := repositorio.load(NET_SAVE_PATH)
			check("Net fallo conserva una restante tras carga", cargado.ok
				and cargado.inventory.quantity(&"net_ball") == 1 and cargado.party.is_empty())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(NET_SAVE_PATH))
	# Los intentos inválidos no gastan ni hacen avanzar el RNG.
	for modo in 4:
		var wild := _mon(&"pidgey", 12, StringName("w03_net_invalido_" + str(modo)))
		var contexto := CaptureBattleContext.new()
		var owner2 := PlayerCollection.new()
		if modo != 0:
			owner2.inventory.add(&"net_ball", 2)
		match modo:
			1: contexto.is_wild = false
			2: contexto.battle_finished = true
			3: wild.current_hp = 0
		var antes := owner2.inventory.to_dict()
		var criatura_antes := wild.to_dict()
		var semilla := RandomNumberGenerator.new()
		semilla.seed = 103 + modo
		var rng_antes := semilla.state
		var respuesta := CaptureInventoryService.resolve(
			CaptureAttempt.new(wild, &"net_ball", contexto),
			semilla, catalogs, owner2.party, owner2.inventory)
		var motivo: String = ["item_not_owned", "trainer_battle_not_capturable",
			"battle_finished", "target_knocked_out"][modo]
		check("Net intento inválido no consume ni modifica " + str(modo),
			respuesta.result.status == CaptureResult.INVALID
			and respuesta.result.reason == motivo
			and not respuesta.result.consume_item and owner2.inventory.to_dict() == antes
			and wild.to_dict() == criatura_antes
			and owner2.party.is_empty() and semilla.state == rng_antes)


func _probar_selector_y_descriptor() -> void:
	var item: ItemDefinition = catalogs.item(&"net_ball")
	check("Malla Ball existe en catálogo de descriptores", item != null)
	if item == null:
		return
	check("Malla Ball tiene nombre y descripción de catálogo",
		not item.display_name.strip_edges().is_empty()
		and not item.description.strip_edges().is_empty())
	var nombre := SpanishGameText.item_name(&"net_ball", catalogs)
	check("selector ofrece nombre localizado/fallback no vacío", not nombre.strip_edges().is_empty())
	var orden := CaptureRuleset.ordered_ball_ids()
	check("Net figura una única vez en selector de bolas", orden.count(&"net_ball") == 1)
	var mochila := PlayerInventory.new()
	mochila.add(&"net_ball", 2)
	var selector := NetBallPicker.new()
	selector.render_balls(mochila, catalogs, false)
	var localizada := false
	for indice in selector.item_count:
		if selector.get_item_metadata(indice) == "net_ball":
			localizada = true
			check("Net visible con nombre y dos unidades", selector.get_item_text(indice).contains(nombre)
				and selector.get_item_text(indice).contains("2")
				and not selector.is_item_disabled(indice))
	check("Net presente en selector visual de inventario", localizada)
	selector.free()


func _terminar() -> void:
	var resultado := {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"checks": checks, "errors": errors, "net_ball": "IMPLEMENTADA_PENDIENTE_CI",
		"gpu": false, "godot": Engine.get_version_info().get("string", ""),
		"nota": "La certificación depende del código de salida real y SHA de GitHub Actions."
	}
	print("CAMP_001_W03_NET ", JSON.stringify(resultado))
	done = true
	quit(0 if errors.is_empty() else 1)
