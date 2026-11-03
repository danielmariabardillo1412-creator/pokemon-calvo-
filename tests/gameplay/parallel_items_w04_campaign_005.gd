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

func _tiene_destino_03(records: Array, destino: StringName) -> bool:
	for record in records:
		if record is EvolutionRecord and record.species_id == destino:
			return true
	return false

func _auditar_condicion_03(catalogo: DefinitionCatalog, fila: Dictionary) -> void:
	var item := StringName(fila.get("item_id", ""))
	var origen := StringName(fila.get("source", ""))
	var destino := StringName(fila.get("target", ""))
	var trig := StringName(String(fila.get("trigger", "")).replace("-", "_"))
	var key := String(fila.get("key", ""))
	var spec: CreatureSpecies = catalogo.species(origen)
	comprobar(catalogo.item(item) != null and spec != null and catalogo.species(destino) != null, String(item) + "/" + String(origen) + "/catálogo")
	if spec == null:
		return
	var encontrados := 0
	var relevante: EvolutionRecord = null
	for ev: EvolutionRecord in spec.evolutions:
		if ev.species_id != destino or ev.trigger != trig:
			continue
		if trig == EvolutionSystem.TRIGGER_USE_ITEM and ev.item_id != item:
			continue
		if trig == EvolutionSystem.TRIGGER_LEVEL_UP and StringName(str(ev.conditions.get("held_item", ""))) != item:
			continue
		encontrados += 1
		relevante = ev
	comprobar(encontrados == 1 and relevante != null, String(item) + "/" + String(origen) + "/registro_específico")
	if relevante == null:
		return
	comprobar(EvolutionSystem.classify_record(relevante, catalogo, origen) == EvolutionSystem.DATA_ONLY, String(item) + "/" + String(origen) + "/condicion_no_degradable")
	comprobar(relevante.min_level == 0 and relevante.conditions.has(key), String(item) + "/" + String(origen) + "/requisito_original")
	var valor: Variant = relevante.conditions.get(key)
	var esperado: Variant = fila.get("required")
	var coincide := int(valor) == int(esperado) if key == "gender" else String(valor).replace("-", "_") == String(esperado).replace("-", "_")
	comprobar(coincide, String(item) + "/" + String(origen) + "/valor_condicion")
	if fila.has("additional_key"):
		var extra := String(fila["additional_key"])
		comprobar(String(relevante.conditions.get(extra, "")).replace("-", "_") == String(fila.get("additional_value", "")).replace("-", "_"), String(item) + "/" + String(origen) + "/día_y_objeto")
	var contexto: Dictionary = {"level": 100, "item_id": item, "held_item_id": item, "gender": fila.get("required"), "time_of_day": "full-moon", "moon_phase": "full"}
	comprobar(not _tiene_destino_03(EvolutionSystem.evolution_candidates(spec, contexto, catalogo), destino), String(item) + "/" + String(origen) + "/no_ignora_condiciones")
	var pc := _crear(catalogo, origen)
	comprobar(pc != null, String(item) + "/" + String(origen) + "/criatura")
	if pc == null:
		return
	var criatura := pc.owned_creature(ID)
	comprobar(not criatura.to_dict().has("gender"), String(item) + "/" + String(origen) + "/sexo_no_persistido")
	var nivel_contexto := EvolutionSystem.level_up_context(criatura)
	comprobar(not nivel_contexto.has("gender") and not nivel_contexto.has("time_of_day") and not nivel_contexto.has("held_item_id"), String(item) + "/" + String(origen) + "/contexto_sin_requisitos")
	var svc := Servicio.new()
	comprobar(svc.configure(pc, catalogo, func(): return true), String(item) + "/" + String(origen) + "/servicio")
	comprobar(svc.holdable(item) == bool(fila.get("equippable", false)), String(item) + "/" + String(origen) + "/perfil_equipamiento")
	comprobar(pc.inventory.add(item, 2), String(item) + "/" + String(origen) + "/inventario")
	var antes := _estado(pc)
	comprobar(svc.evolution_options(item, ID).is_empty(), String(item) + "/" + String(origen) + "/sin_opciones_directas")
	var uso := svc.use_item(item, ID)
	comprobar(not uso.get("accepted", false) and _estado(pc) == antes, String(item) + "/" + String(origen) + "/uso_rechazado_sin_gasto")
	var evolucion := svc.evolve(item, ID, destino)
	comprobar(not evolucion.get("accepted", false) and _estado(pc) == antes, String(item) + "/" + String(origen) + "/evolucion_rechazada")
	var ajeno := svc.use_item(item, &"w04_ajeno")
	comprobar(not ajeno.get("accepted", false) and _estado(pc) == antes, String(item) + "/" + String(origen) + "/propietario_ajeno")
	var equipamiento := svc.equip(item, ID)
	var se_equipa := bool(fila.get("equippable", false))
	comprobar(bool(equipamiento.get("accepted", false)) == se_equipa, String(item) + "/" + String(origen) + "/equipar_segun_perfil")
	comprobar(criatura.species_id == origen and pc.inventory.quantity(item) == (1 if se_equipa else 2) and criatura.held_item_id == (item if se_equipa else &""), String(item) + "/" + String(origen) + "/identidad_inventario_y_objeto")
	var guardado := SaveGameRepository.new()
	var ruta := "user://w04_c005_03_" + String(item) + "_" + String(origen) + ".json"
	var resp: SaveResult = guardado.save_collection(ruta, pc)
	comprobar(resp.ok, String(item) + "/" + String(origen) + "/guardar_savev2")
	if resp.ok:
		var loaded: LoadResult = guardado.load(ruta)
		comprobar(loaded.ok and loaded.schema_version == 2, String(item) + "/" + String(origen) + "/leer_savev2")
		if loaded.ok:
			var restaurada := loaded.party.get_creature(ID)
			comprobar(restaurada != null and restaurada.instance_id == ID and restaurada.species_id == origen and restaurada.held_item_id == (item if se_equipa else &"") and loaded.inventory.quantity(item) == (1 if se_equipa else 2), String(item) + "/" + String(origen) + "/estado_savev2_integro")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	if se_equipa:
		var quitar := svc.unequip(ID)
		comprobar(quitar.get("accepted", false) and _estado(pc) == antes, String(item) + "/" + String(origen) + "/retirada_sin_perdida")
	else:
		comprobar(_estado(pc) == antes, String(item) + "/" + String(origen) + "/no_equipable_sin_gasto")
	print("CAMP005_W04_ITEM id=", String(item), " status=DEPENDENCIA_CONDICIONES source=", String(origen), " target=", String(destino), " trigger=", String(trig), " key=", key, " value=", str(valor))

func _auditar_forma_04(catalogo: DefinitionCatalog, fila: Dictionary) -> void:
	var item := StringName(fila.get("item_id", ""))
	var origen := StringName(fila.get("source", ""))
	var destino := StringName(fila.get("target", ""))
	var especie: CreatureSpecies = catalogo.species(origen)
	comprobar(catalogo.item(item) != null and especie != null and catalogo.species(destino) != null, String(item) + "/04_catalogo")
	if especie == null:
		return
	var registros: Array[EvolutionRecord] = []
	for ev: EvolutionRecord in especie.evolutions:
		if ev.species_id == destino and ev.trigger == EvolutionSystem.TRIGGER_USE_ITEM and ev.item_id == item:
			registros.append(ev)
	comprobar(registros.size() == 1, String(item) + "/04_registro_por_objeto")
	if registros.size() != 1:
		return
	var registro: EvolutionRecord = registros[0]
	comprobar(String(registro.version_group).replace("_", "-") == String(fila.get("version", "")), String(item) + "/04_version_importada")
	comprobar(String(registro.conditions.get("evolved_form", "")).replace("_", "-") == String(fila.get("evolved_form", "")), String(item) + "/04_forma_destino")
	if fila.has("base_form"):
		comprobar(String(registro.conditions.get("base_form", "")).replace("_", "-") == String(fila.get("base_form", "")), String(item) + "/04_base_regional")
	else:
		comprobar(not registro.conditions.has("base_form"), String(item) + "/04_sin_restriccion_regional_artificial")
	comprobar(EvolutionSystem.classify_record(registro, catalogo, origen) == EvolutionSystem.DATA_ONLY, String(item) + "/04_condicion_forma_no_degradable")
	var opciones := EvolutionSystem.evolution_candidates(especie, {"level": 100, "item_id": item, "base_form": fila.get("base_form", ""), "evolved_form": fila.get("evolved_form", "")}, catalogo)
	comprobar(not opciones.has(registro), String(item) + "/04_eligibilidad_no_ignora_forma")
	if item == &"galarica_cuff":
		comprobar(_tiene_destino_03(opciones, &"slowbro"), "galarica_cuff/04_evolucion_normal_nivel_sigue_disponible")
	var pc := _crear(catalogo, origen)
	comprobar(pc != null, String(item) + "/04_criatura")
	if pc == null:
		return
	var criatura := pc.owned_creature(ID)
	comprobar(not criatura.to_dict().has("form_id") and not criatura.to_dict().has("regional_form_id"), String(item) + "/04_forma_persistente_no_contratada")
	var svc := Servicio.new()
	comprobar(svc.configure(pc, catalogo, func(): return true), String(item) + "/04_servicio")
	var equipado_admitido := bool(fila.get("equippable", false))
	comprobar(svc.holdable(item) == equipado_admitido, String(item) + "/04_perfil_equipamiento")
	comprobar(pc.inventory.add(item, 2), String(item) + "/04_stock")
	var antes := _estado(pc)
	comprobar(svc.evolution_options(item, ID).is_empty(), String(item) + "/04_sin_opcion_sin_forma")
	var uso: Dictionary = svc.use_item(item, ID)
	comprobar(not uso.get("accepted", false) and _estado(pc) == antes, String(item) + "/04_no_uso_incondicional")
	var invocacion: Dictionary = svc.evolve(item, ID, destino)
	comprobar(not invocacion.get("accepted", false) and _estado(pc) == antes, String(item) + "/04_no_destino_sin_forma")
	var ajeno: Dictionary = svc.use_item(item, &"w04_c005_ajeno")
	comprobar(not ajeno.get("accepted", false) and _estado(pc) == antes, String(item) + "/04_no_propietario_ajeno")
	var equipar: Dictionary = svc.equip(item, ID)
	comprobar(bool(equipar.get("accepted", false)) == equipado_admitido, String(item) + "/04_equipamiento_segun_perfil")
	comprobar(criatura.species_id == origen and criatura.instance_id == ID and criatura.held_item_id == (item if equipado_admitido else &"") and pc.inventory.quantity(item) == (1 if equipado_admitido else 2), String(item) + "/04_identidad_inventario")
	var ruta := "user://w04_c005_04_" + String(item) + ".json"
	var repo := SaveGameRepository.new()
	var save: SaveResult = repo.save_collection(ruta, pc)
	comprobar(save.ok, String(item) + "/04_guardar_savev2")
	if save.ok:
		var load: LoadResult = repo.load(ruta)
		comprobar(load.ok and load.schema_version == 2, String(item) + "/04_cargar_savev2")
		if load.ok:
			var restaurada := load.party.get_creature(ID)
			comprobar(restaurada != null and restaurada.instance_id == ID and restaurada.species_id == origen and restaurada.held_item_id == (item if equipado_admitido else &"") and load.inventory.quantity(item) == (1 if equipado_admitido else 2), String(item) + "/04_forma_no_inventada_savev2")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	if equipado_admitido:
		var quitar := svc.unequip(ID)
		comprobar(quitar.get("accepted", false) and _estado(pc) == antes, String(item) + "/04_retira_y_restaura")
	else:
		comprobar(_estado(pc) == antes, String(item) + "/04_no_equipable_sin_mutacion")
	print("CAMP005_W04_ITEM id=", String(item), " status=DEPENDENCIA_FORMA source=", String(origen),
		" target=", String(destino), " evolved_form=", String(fila.get("evolved_form", "")), " need=owner_form_and_form_target")

func _fronteras_regionales_04(catalogo: DefinitionCatalog, casos: Array) -> void:
	var slowpoke: CreatureSpecies = catalogo.species(&"slowpoke")
	var kubfu: CreatureSpecies = catalogo.species(&"kubfu")
	comprobar(slowpoke != null and kubfu != null, "04_dos_origenes")
	if slowpoke == null or kubfu == null:
		return
	var variantes: Dictionary = {}
	var estilos: Dictionary = {}
	for caso: Dictionary in casos:
		var item := StringName(caso["item_id"])
		var spec: CreatureSpecies = catalogo.species(StringName(caso["source"]))
		var found := false
		for record: EvolutionRecord in spec.evolutions:
			if record.item_id != item or record.trigger != EvolutionSystem.TRIGGER_USE_ITEM:
				continue
			found = true
			if String(caso["source"]) == "slowpoke":
				variantes[String(item)] = String(record.conditions.get("base_form", "")) + ":" + String(record.conditions.get("evolved_form", ""))
			else:
				estilos[String(item)] = String(record.conditions.get("evolved_form", ""))
		comprobar(found, String(item) + "/04_ruta_presente")
	comprobar(variantes.size() == 2 and variantes["galarica_cuff"] != variantes["galarica_wreath"], "04_galar_regional_dos_destinos")
	comprobar(estilos.size() == 2 and estilos["scroll_of_darkness"] != estilos["scroll_of_waters"], "04_urshifu_estilos_distintos_igual_especie")
	var torre_oscura := 0
	var torre_agua := 0
	for rec: EvolutionRecord in kubfu.evolutions:
		if rec.species_id != &"urshifu":
			continue
		if rec.trigger == &"tower_of_darkness":
			torre_oscura += 1
			comprobar(EvolutionSystem.classify_record(rec, catalogo, &"kubfu") == EvolutionSystem.UNSUPPORTED, "04_torre_sombras_no_simplificada")
		if rec.trigger == &"tower_of_waters":
			torre_agua += 1
			comprobar(EvolutionSystem.classify_record(rec, catalogo, &"kubfu") == EvolutionSystem.UNSUPPORTED, "04_torre_agua_no_simplificada")
	comprobar(torre_oscura == 1 and torre_agua == 1, "04_dos_torres_procedencia")
	print("CAMP005_W04_FORM_CONTRACT Galar=2 distinct_targets Urshifu=2 distinct_forms same_target=urshifu towers=2 unsupported")

func _auditar_confite_05(catalogo: DefinitionCatalog, caso: Dictionary) -> void:
	var item := StringName(caso.get("item_id", ""))
	var origen := StringName(caso.get("source", ""))
	var destino := StringName(caso.get("target", ""))
	var especie: CreatureSpecies = catalogo.species(origen)
	comprobar(catalogo.item(item) != null and especie != null and catalogo.species(destino) != null, String(item) + "/05_catalogo")
	if especie == null:
		return
	var giros: Array[EvolutionRecord] = []
	for registro: EvolutionRecord in especie.evolutions:
		if registro.trigger == &"spin" and registro.species_id == destino:
			giros.append(registro)
	comprobar(giros.size() == 1, String(item) + "/05_ruta_spin_real_unica")
	if giros.size() != 1:
		return
	var giro: EvolutionRecord = giros[0]
	comprobar(giro.item_id == &"" and giro.min_level == 0, String(item) + "/05_sin_item_directo_ni_nivel_inventado")
	comprobar(String(giro.version_group).replace("_", "-") == "sword-shield", String(item) + "/05_version_original")
	comprobar(EvolutionSystem.classify_record(giro, catalogo, origen) == EvolutionSystem.UNSUPPORTED, String(item) + "/05_giro_no_disfrazado_de_use_item")
	var candidatos: Array = EvolutionSystem.evolution_candidates(especie, {"level": 100, "item_id": item, "held_item_id": item, "spin": true}, catalogo)
	comprobar(not candidatos.has(giro), String(item) + "/05_spin_no_aparece_en_candidatos")
	var pc := _crear(catalogo, origen)
	comprobar(pc != null, String(item) + "/05_criatura")
	if pc == null:
		return
	var servicio := Servicio.new()
	comprobar(servicio.configure(pc, catalogo, func(): return true), String(item) + "/05_servicio")
	comprobar(servicio.holdable(item), String(item) + "/05_confite_equipable")
	comprobar(pc.inventory.add(item, 2), String(item) + "/05_dos_confites")
	var original := _estado(pc)
	comprobar(servicio.evolution_options(item, ID).is_empty(), String(item) + "/05_sin_opcion_de_mochila")
	var uso: Dictionary = servicio.use_item(item, ID)
	comprobar(not uso.get("accepted", false) and _estado(pc) == original, String(item) + "/05_uso_rechazado_sin_gasto")
	var intento: Dictionary = servicio.evolve(item, ID, destino)
	comprobar(not intento.get("accepted", false) and _estado(pc) == original, String(item) + "/05_evolve_no_sustituye_giro")
	var ajeno: Dictionary = servicio.use_item(item, &"w04_c005_ajeno")
	comprobar(not ajeno.get("accepted", false) and _estado(pc) == original, String(item) + "/05_ajeno_sin_gasto")
	var equipado: Dictionary = servicio.equip(item, ID)
	comprobar(equipado.get("accepted", false), String(item) + "/05_equipar")
	if not equipado.get("accepted", false):
		return
	var pokemon := pc.owned_creature(ID)
	comprobar(pokemon != null and pokemon.instance_id == ID and pokemon.species_id == origen and pokemon.held_item_id == item and pc.inventory.quantity(item) == 1, String(item) + "/05_identidad_y_consumo_no_anticipado")
	var equipado_antes := _estado(pc)
	comprobar(servicio.evolution_options(item, ID).is_empty(), String(item) + "/05_equipar_no_activacion")
	var falso: Dictionary = servicio.use_item(item, ID)
	comprobar(not falso.get("accepted", false) and _estado(pc) == equipado_antes, String(item) + "/05_sin_consumo_tras_equipar")
	var falso_destino: Dictionary = servicio.evolve(item, ID, destino)
	comprobar(not falso_destino.get("accepted", false) and _estado(pc) == equipado_antes, String(item) + "/05_sin_forma_por_evolve")
	comprobar(not pokemon.to_dict().has("form_id") and not pokemon.to_dict().has("decoration_id"), String(item) + "/05_identidad_forma_no_inventada")
	var ruta := "user://w04_c005_05_" + String(item) + ".json"
	var repo := SaveGameRepository.new()
	var save: SaveResult = repo.save_collection(ruta, pc)
	comprobar(save.ok, String(item) + "/05_guardar_savev2")
	if save.ok:
		var load: LoadResult = repo.load(ruta)
		comprobar(load.ok and load.schema_version == 2, String(item) + "/05_cargar_savev2")
		if load.ok:
			var restaurada := load.party.get_creature(ID)
			comprobar(restaurada != null and restaurada.instance_id == ID and restaurada.species_id == origen and restaurada.held_item_id == item and load.inventory.quantity(item) == 1, String(item) + "/05_identidad_confite_savev2")
			if restaurada != null:
				var antes := pokemon.to_dict()
				var despues := restaurada.to_dict()
				comprobar(antes.get("ivs") == despues.get("ivs") and antes.get("evs") == despues.get("evs") and antes.get("move_ids") == despues.get("move_ids") and antes.get("experience") == despues.get("experience") and antes.get("friendship") == despues.get("friendship"), String(item) + "/05_atributos_savev2")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	var retirar: Dictionary = servicio.unequip(ID)
	comprobar(retirar.get("accepted", false) and pc.inventory.quantity(item) == 2 and pc.owned_creature(ID).held_item_id == &"" and _estado(pc) == original, String(item) + "/05_retirada_restaurada")
	print("CAMP005_W04_ITEM id=", String(item), " status=DEPENDENCIA_GIRO_FORMA source=", String(origen), " target=", String(destino), " trigger=spin need=spin_event+alcremie_form+savev2")


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
	comprobar(blocks.size() == 5 and [blocks[0].get("block"), blocks[1].get("block"), blocks[2].get("block"), blocks[3].get("block"), blocks[4].get("block")] == ["01", "02", "03", "04", "05"], "bloques_01_a_05_secuenciales")
	if blocks.size() != 5:
		_finalizar()
		return
	for index in range(2):
		var pairs: Array = blocks[index].get("pairs", [])
		comprobar(pairs.size() == (4 if index == 0 else 5), "tamano_bloque_" + str(index + 1))
		for pareja: Dictionary in pairs:
			_auditar_pareja(catalogo, pareja, policy)
	_casos_de_version_y_etapas_02(catalogo)
	var condicionadas: Array = blocks[2].get("cases", [])
	comprobar(condicionadas.size() == 4, "cuatro_rutas_condicionadas_03")
	for caso: Dictionary in condicionadas:
		_auditar_condicion_03(catalogo, caso)
	var formas: Array = blocks[3].get("cases", [])
	comprobar(formas.size() == 4, "cuatro_rutas_forma_04")
	for caso: Dictionary in formas:
		_auditar_forma_04(catalogo, caso)
	_fronteras_regionales_04(catalogo, formas)
	var confites: Array = blocks[4].get("cases", [])
	comprobar(confites.size() == 7, "05_siete_confites_exactos")
	for caso: Dictionary in confites:
		_auditar_confite_05(catalogo, caso)
	_finalizar()

func _finalizar() -> void:
	if cerrado:
		return
	cerrado = true
	if errores.is_empty():
		print("CAMP005_W04_GODOT PASS blocks=5 checks=", checks)
	else:
		print("CAMP005_W04_GODOT FAIL errors=", JSON.stringify(errores))
	quit(0 if errores.is_empty() else 1)
