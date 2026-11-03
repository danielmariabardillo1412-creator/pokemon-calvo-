extends SceneTree
# W04 CAMP005: contrato de transición trade+held_item -> nivel APROBADO+held_item.
# No simular un umbral sin decisión canónica. PASS técnico no equivale a evolución implementada.
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const FIXTURE := "res://tests/fixtures/parallel_items/w04_campaign_005.json"
const TRADE_POLICY := "res://docs/current/ITEM_TRADE_RESTORATION_V27.json"
const EARLIER_SCOPE := "res://docs/current/ITEM_SCOPE_V25.json"
const ID := &"w04_c005_01"
var checks := 0
var errores: Array[String] = []
var cerrado := false

func _initialize() -> void:
	create_timer(110.0).timeout.connect(func():
		if not cerrado:
			comprobar(false, "timeout")
			_finalizar())
	call_deferred("_ejecutar")

func comprobar(ok: bool, nombre: String) -> void:
	checks += 1
	if not ok:
		errores.append(nombre)
		push_error(nombre)

func _abrir(path: String) -> Dictionary:
	var valor: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	comprobar(valor is Dictionary, path + "/json_valido")
	return valor as Dictionary if valor is Dictionary else {}

func _crear(catalogo: DefinitionCatalog, source: StringName) -> PlayerCollection:
	var especie := catalogo.species(source)
	if especie == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261103
	var pokemon := CreatureFactory.create(especie, 40, catalogo, ProgressionRuleset.new(), rng,
		{"instance_id": ID, "nature_id": &"hardy", "moves": ["tackle", "protect"]})
	if pokemon == null:
		return null
	var pc := PlayerCollection.new()
	if not pc.party.add_creature(pokemon):
		return null
	return pc

func _estado(pc: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict())

func _auditar_pareja(catalogo: DefinitionCatalog, fila: Dictionary, policy: Dictionary) -> void:
	var item := StringName(fila.get("item_id", ""))
	var source := StringName(fila.get("source", ""))
	var target := StringName(fila.get("target", ""))
	var especie: CreatureSpecies = catalogo.species(source)
	comprobar(catalogo.item(item) != null and especie != null and catalogo.species(target) != null, String(item) + "/catalogo_pareja")
	if especie == null:
		return
	var trade_records := 0
	var specific: EvolutionRecord = null
	for record: EvolutionRecord in especie.evolutions:
		if record.trigger == EvolutionSystem.TRIGGER_TRADE and record.species_id == target and StringName(str(record.conditions.get("held_item", ""))) == item:
			trade_records += 1
			specific = record
	comprobar(trade_records == 1 and specific != null, String(item) + "/ruta_trade_y_held_item_unica")
	if specific != null:
		comprobar(EvolutionSystem.classify_record(specific, catalogo, source) == EvolutionSystem.DATA_ONLY, String(item) + "/trade_condicionado_no_ejecutable")
		comprobar(specific.min_level == 0 and specific.conditions.has("held_item"), String(item) + "/sin_umbral_original")
	comprobar(fila.get("approved_level") == null and policy.get("level_values_selected") == null, String(item) + "/nivel_sin_aprobar")
	var hipotetica := EvolutionRecord.new(target, 0, EvolutionSystem.TRIGGER_LEVEL_UP, &"", &"", true, {"held_item": String(item)})
	comprobar(EvolutionSystem.classify_record(hipotetica, catalogo, source) == EvolutionSystem.DATA_ONLY, String(item) + "/nivel_mas_item_aun_no_soportado")
	var sin_nivel: Array = EvolutionSystem.evolution_candidates(especie, {"level": 100, "block_level_evolution": false}, catalogo)
	var con_objeto: Array = EvolutionSystem.evolution_candidates(especie, {"level": 100, "held_item_id": item, "block_level_evolution": false}, catalogo)
	var invencion := false
	for rec in sin_nivel + con_objeto:
		if rec is EvolutionRecord and rec.species_id == target:
			invencion = true
	comprobar(not invencion, String(item) + "/sin_evolucion_por_nivel_inventado")
	var pc := _crear(catalogo, source)
	comprobar(pc != null, String(item) + "/criatura_propiedad")
	if pc == null:
		return
	var service := Servicio.new()
	comprobar(service.configure(pc, catalogo, func(): return true), String(item) + "/servicio")
	comprobar(service.holdable(item), String(item) + "/objeto_original_equipable")
	comprobar(pc.inventory.add(item, 2), String(item) + "/stock")
	var antes := _estado(pc)
	var uso: Dictionary = service.use_item(item, ID)
	comprobar(not uso.get("accepted", false) and _estado(pc) == antes, String(item) + "/mochila_no_es_intercambio")
	var equipo: Dictionary = service.equip(item, ID)
	comprobar(equipo.get("accepted", false) and pc.inventory.quantity(item) == 1 and pc.owned_creature(ID).held_item_id == item and pc.owned_creature(ID).species_id == source, String(item) + "/equipamiento_positivo_sin_evolucion")
	if not equipo.get("accepted", false):
		return
	var contexto: Dictionary = EvolutionSystem.level_up_context(pc.owned_creature(ID))
	comprobar(not contexto.has("held_item_id") and not contexto.has("held_item"), String(item) + "/productor_no_transporta_objeto")
	var equipado_antes := _estado(pc)
	var falso: Dictionary = service.evolve(item, ID, target)
	comprobar(not falso.get("accepted", false) and _estado(pc) == equipado_antes, String(item) + "/sin_evolucion_por_bolsa_equipada")
	var repo := SaveGameRepository.new()
	var ruta := "user://w04_c005_" + String(item) + "_trade_held.json"
	var guardado: SaveResult = repo.save_collection(ruta, pc)
	comprobar(guardado.ok, String(item) + "/guardar_savev2")
	if guardado.ok:
		var cargado: LoadResult = repo.load(ruta)
		comprobar(cargado.ok and cargado.schema_version == 2, String(item) + "/leer_savev2")
		if cargado.ok:
			var restaurado := cargado.party.get_creature(ID)
			comprobar(restaurado != null and restaurado.species_id == source and restaurado.instance_id == ID and restaurado.held_item_id == item and cargado.inventory.quantity(item) == 1, String(item) + "/identidad_item_savev2")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	var quitar: Dictionary = service.unequip(ID)
	comprobar(quitar.get("accepted", false) and pc.inventory.quantity(item) == 2 and pc.owned_creature(ID).held_item_id == &"" and _estado(pc) == antes, String(item) + "/retirada_preserva_estado")
	print("CAMP005_W04_ITEM id=", String(item), " status=BLOQUEADO_POR_CONTRATO source=", String(source), " target=", String(target),
		" required=approved_level+held_item producer=level_up_context consumer=evolution_candidates")

func _casos_de_version_y_etapas_02(catalogo: DefinitionCatalog) -> void:
	var feebas: CreatureSpecies = catalogo.species(&"feebas")
	comprobar(feebas != null, "prism_scale/feebas_definicion")
	if feebas != null:
		var alternativas := 0
		var condicionadas := 0
		for record: EvolutionRecord in feebas.evolutions:
			if record.species_id != &"milotic":
				continue
			if record.trigger == EvolutionSystem.TRIGGER_LEVEL_UP and record.conditions.has("min_beauty"):
				alternativas += 1
				if EvolutionSystem.classify_record(record, catalogo, &"feebas") == EvolutionSystem.DATA_ONLY:
					condicionadas += 1
		comprobar(alternativas > 0 and alternativas == condicionadas, "prism_scale/belleza_legacy_no_degradada")
		print("CAMP005_W04_ALT id=prism_scale source=feebas target=milotic min_beauty=170 routes=", alternativas, " status=DATA_ONLY")
	var porygon: CreatureSpecies = catalogo.species(&"porygon")
	var porygon2: CreatureSpecies = catalogo.species(&"porygon2")
	comprobar(porygon != null and porygon2 != null, "up_grade/dos_etapas_porygon")
	if porygon == null or porygon2 == null:
		return
	var primero := 0
	var segundo := 0
	var equivocado := 0
	for record: EvolutionRecord in porygon.evolutions:
		if record.trigger == EvolutionSystem.TRIGGER_TRADE and record.species_id == &"porygon2" and StringName(str(record.conditions.get("held_item", ""))) == &"up_grade":
			primero += 1
	for record: EvolutionRecord in porygon2.evolutions:
		if record.trigger == EvolutionSystem.TRIGGER_TRADE and record.species_id == &"porygon_z" and StringName(str(record.conditions.get("held_item", ""))) == &"dubious_disc":
			segundo += 1
		if record.conditions.get("held_item", "") == "up_grade":
			equivocado += 1
	comprobar(primero == 1 and segundo == 1 and equivocado == 0, "up_grade/dos_objetos_dos_etapas")
	var pc := _crear(catalogo, &"porygon2")
	comprobar(pc != null, "up_grade/propietario_etapa_incorrecta")
	if pc == null:
		return
	var service := Servicio.new()
	comprobar(service.configure(pc, catalogo, func(): return true), "up_grade/servicio_etapa_incorrecta")
	comprobar(pc.inventory.add(&"up_grade", 2), "up_grade/stock_etapa_incorrecta")
	var antes := _estado(pc)
	comprobar(service.evolution_options(&"up_grade", ID).is_empty(), "up_grade/porygon2_sin_opcion")
	var forzado: Dictionary = service.evolve(&"up_grade", ID, &"porygon_z")
	comprobar(not forzado.get("accepted", false) and _estado(pc) == antes, "up_grade/porygon2_no_evoluciona")
	var equipado: Dictionary = service.equip(&"up_grade", ID)
	comprobar(equipado.get("accepted", false) and pc.owned_creature(ID).species_id == &"porygon2" and pc.inventory.quantity(&"up_grade") == 1, "up_grade/equipamiento_no_salta_etapa")
	if equipado.get("accepted", false):
		var durante := _estado(pc)
		var otra: Dictionary = service.use_item(&"up_grade", ID)
		comprobar(not otra.get("accepted", false) and _estado(pc) == durante, "up_grade/porygon2_con_objeto_no_salta_etapa")
		var retirada: Dictionary = service.unequip(ID)
		comprobar(retirada.get("accepted", false) and _estado(pc) == antes, "up_grade/porygon2_retirada_sin_mutacion")
	print("CAMP005_W04_STAGE item=up_grade porygon_to_porygon2=1 porygon2_to_porygon_z=dubious_disc wrong_stage_rejected=true")

func _ejecutar() -> void:
	var fixture := _abrir(FIXTURE)
	var policy := _abrir(TRADE_POLICY)
	var earlier := _abrir(EARLIER_SCOPE)
	var data := _abrir("res://data/normalized/pokemon_api.json")
	if data.is_empty() or fixture.is_empty() or policy.is_empty():
		_finalizar()
		return
	var catalogo: DefinitionCatalog = GameData.from_dict(data).to_definition_catalog()
	comprobar(fixture.get("campaign") == "CAMP_005" and fixture.get("worker") == "W04", "identidad_camp005")
	comprobar(policy.get("future_evolution_implementation") == "DEFERRED" and policy.get("level_values_selected") == null, "regla_V27_aplazada")
	comprobar(earlier.get("trade_level_conversion", {}).get("levels_selected") == null, "V25_sin_niveles")
	comprobar(String(policy.get("correct_future_rule", "")).contains("original equipped evolution item"), "conservar_objeto_equipado")
	var blocks: Array = fixture.get("blocks", [])
	comprobar(blocks.size() == 2 and blocks[0].get("block") == "01" and blocks[1].get("block") == "02", "bloques_01_y_02_secuenciales")
	if blocks.size() != 2:
		_finalizar()
		return
	for index in range(blocks.size()):
		var pairs: Array = blocks[index].get("pairs", [])
		comprobar(pairs.size() == (4 if index == 0 else 5), "tamano_bloque_" + str(index + 1))
		for pareja: Dictionary in pairs:
			_auditar_pareja(catalogo, pareja, policy)
	_casos_de_version_y_etapas_02(catalogo)
	_finalizar()

func _finalizar() -> void:
	if cerrado:
		return
	cerrado = true
	if errores.is_empty():
		print("CAMP005_W04_GODOT PASS blocks=2 checks=", checks)
	else:
		print("CAMP005_W04_GODOT FAIL errors=", JSON.stringify(errores))
	quit(0 if errores.is_empty() else 1)
