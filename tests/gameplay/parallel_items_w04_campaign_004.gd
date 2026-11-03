extends SceneTree
# W04 CAMP004: pruebas de runtime. Un PASS negativo NO certifica evolucion positiva.
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const BLOQUE_01 := [&"berry_sweet", &"clover_sweet", &"flower_sweet"]
const BLOQUE_02 := [&"love_sweet", &"ribbon_sweet", &"star_sweet"]
const BLOQUE_03 := [&"strawberry_sweet", &"whipped_dream", &"leaders_crest"]
const BLOQUE_04 := [&"adamant_crystal", &"blue_orb", &"catching_charm"]
const BLOQUE_05 := [&"dna_splicers", &"exp_charm", &"gracidea"]
const BLOQUE_06 := [&"griseous_core", &"lustrous_globe", &"meteorite"]
const BLOQUE_07 := [&"rage_candy_bar", &"red_orb", &"reins_of_unity"]
const ID := &"w04_c004_01"
var checks := 0
var errores: Array[String] = []
var terminado := false

func _initialize() -> void:
	create_timer(110.0).timeout.connect(func():
		if not terminado:
			verificar(false, "timeout")
			_finalizar())
	call_deferred("_ejecutar")

func verificar(condicion: bool, nombre: String) -> void:
	checks += 1
	if not condicion:
		errores.append(nombre)
		push_error(nombre)

func _crear(catalogo: DefinitionCatalog, especie: StringName) -> PlayerCollection:
	var definicion := catalogo.species(especie)
	if definicion == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261103
	var pokemon := CreatureFactory.create(definicion, 40, catalogo, ProgressionRuleset.new(), rng, {"instance_id": ID, "nature_id": &"hardy", "moves": ["tackle", "protect"]})
	var pc := PlayerCollection.new()
	if not pc.party.add_creature(pokemon):
		return null
	return pc

func _estado(pc: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict())

func _persistencia(pc: PlayerCollection, item: StringName, etiqueta: String, cantidad: int, especie: StringName, equipado: StringName) -> void:
	var repo := SaveGameRepository.new()
	var ruta := "user://w04_c004_" + String(item) + "_" + etiqueta + ".json"
	var guardado: SaveResult = repo.save_collection(ruta, pc)
	verificar(guardado.ok, String(item) + "/" + etiqueta + "/guardar")
	if guardado.ok:
		var cargado: LoadResult = repo.load(ruta)
		verificar(cargado.ok and cargado.schema_version == 2, String(item) + "/" + etiqueta + "/cargar_v2")
		if cargado.ok:
			var poke := cargado.party.get_creature(ID)
			verificar(poke != null and poke.species_id == especie and poke.held_item_id == equipado and cargado.inventory.quantity(item) == cantidad, String(item) + "/" + etiqueta + "/savev2_identidad_stock")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))

func _negativo(catalogo: DefinitionCatalog, item: StringName, especie: StringName, destino_objetivo: StringName = &"alcremie") -> void:
	var pc := _crear(catalogo, especie)
	verificar(pc != null, String(item) + "/" + String(especie) + "/creacion")
	if pc == null:
		return
	var servicio := Servicio.new()
	verificar(servicio.configure(pc, catalogo, func(): return true), String(item) + "/" + String(especie) + "/servicio")
	verificar(pc.inventory.add(item, 2), String(item) + "/" + String(especie) + "/stock")
	var antes := _estado(pc)
	var opciones := servicio.evolution_options(item, ID)
	verificar(opciones.is_empty(), String(item) + "/" + String(especie) + "/sin_opcion_directa")
	var directo: Dictionary = servicio.use_item(item, ID)
	verificar(not directo.get("accepted", false) and _estado(pc) == antes and pc.inventory.quantity(item) == 2, String(item) + "/" + String(especie) + "/uso_directo_rechazado_sin_consumo")
	var evolucion: Dictionary = servicio.evolve(item, ID, destino_objetivo)
	verificar(not evolucion.get("accepted", false) and _estado(pc) == antes and pc.inventory.quantity(item) == 2, String(item) + "/" + String(especie) + "/evolucion_forzada_rechazada")
	if servicio.holdable(item):
		var equipar: Dictionary = servicio.equip(item, ID)
		verificar(equipar.get("accepted", false) and pc.inventory.quantity(item) == 1 and pc.owned_creature(ID).held_item_id == item, String(item) + "/" + String(especie) + "/equipar_sin_evolucion")
		if equipar.get("accepted", false):
			_persistencia(pc, item, String(especie) + "_equipado", 1, especie, item)
			var equipado_antes := _estado(pc)
			var con_equipamiento: Dictionary = servicio.evolve(item, ID, destino_objetivo)
			verificar(not con_equipamiento.get("accepted", false) and _estado(pc) == equipado_antes and servicio.evolution_options(item, ID).is_empty(), String(item) + "/" + String(especie) + "/equipar_no_simula_giro")
			var quitar: Dictionary = servicio.unequip(ID)
			verificar(quitar.get("accepted", false) and pc.inventory.quantity(item) == 2 and pc.owned_creature(ID).held_item_id == &"", String(item) + "/" + String(especie) + "/devolver_equipamiento")
	else:
		var rechazado: Dictionary = servicio.equip(item, ID)
		verificar(not rechazado.get("accepted", false) and _estado(pc) == antes, String(item) + "/" + String(especie) + "/sin_equipamiento_inventado")
	verificar(_estado(pc) == antes, String(item) + "/" + String(especie) + "/estado_final_intacto")
	_persistencia(pc, item, String(especie) + "_final", 2, especie, &"")

func _positivo(catalogo: DefinitionCatalog, item: StringName, origen: StringName, destino: StringName) -> void:
	var pc := _crear(catalogo, origen)
	verificar(pc != null, String(item) + "/origen_positivo")
	if pc == null: return
	var servicio := Servicio.new()
	verificar(servicio.configure(pc, catalogo, func(): return true), String(item) + "/servicio_positivo")
	verificar(pc.inventory.add(item, 2), String(item) + "/stock_positivo")
	verificar(servicio.evolution_options(item, ID).has(destino), String(item) + "/opcion_positiva")
	var original := pc.owned_creature(ID)
	var iv := original.ivs.duplicate(true)
	var ev := original.evs.duplicate(true)
	var amistad := original.friendship
	var experiencia := original.experience
	var movimientos := original.move_ids.duplicate()
	var previo := _estado(pc)
	var errado: Dictionary = servicio.evolve(item, &"otro_id", destino)
	verificar(not errado.get("accepted", false) and _estado(pc) == previo, String(item) + "/propietario_invalido")
	var evolucion: Dictionary = servicio.evolve(item, ID, destino)
	var nuevo := pc.owned_creature(ID)
	verificar(evolucion.get("accepted", false) and nuevo != null and nuevo.species_id == destino and pc.inventory.quantity(item) == 1, String(item) + "/positivo_consumo_unico")
	if nuevo != null:
		verificar(nuevo.instance_id == ID and nuevo.ivs == iv and nuevo.evs == ev and nuevo.friendship == amistad and nuevo.experience == experiencia and nuevo.move_ids == movimientos, String(item) + "/atributos_conservados")
		_persistencia(pc, item, "evolucion", 1, destino, nuevo.held_item_id)
		var posterior := _estado(pc)
		var repeticion: Dictionary = servicio.evolve(item, ID, destino)
		verificar(not repeticion.get("accepted", false) and posterior == _estado(pc), String(item) + "/sin_doble_gasto")

func _auditar_contexto_04(catalogo: DefinitionCatalog, item: StringName, origen: StringName) -> void:
	verificar(catalogo.item(item) != null, String(item) + "/" + String(origen) + "/catalogo")
	var pc := _crear(catalogo, origen)
	verificar(pc != null, String(item) + "/" + String(origen) + "/especie")
	if pc == null:
		return
	var servicio := Servicio.new()
	verificar(servicio.configure(pc, catalogo, func(): return true), String(item) + "/servicio_forma")
	verificar(pc.inventory.add(item, 2), String(item) + "/inventario_forma")
	var previo := _estado(pc)
	var opciones := servicio.evolution_options(item, ID)
	verificar(opciones.is_empty(), String(item) + "/no_evolucion_por_objeto")
	var campo: Dictionary = servicio.use_item(item, ID)
	verificar(not campo.get("accepted", false) and _estado(pc) == previo and pc.inventory.quantity(item) == 2, String(item) + "/sin_transformacion_por_uso")
	var evolucion: Dictionary = servicio.evolve(item, ID)
	verificar(not evolucion.get("accepted", false) and _estado(pc) == previo, String(item) + "/sin_evolucion_falsa")
	var ajeno: Dictionary = servicio.use_item(item, &"id_ajeno")
	verificar(not ajeno.get("accepted", false) and _estado(pc) == previo, String(item) + "/propietario_ajeno_intacto")
	if item == &"catching_charm":
		verificar(not servicio.holdable(item), String(item) + "/sin_equipamiento_ajeno")
		var equipar_invalido: Dictionary = servicio.equip(item, ID)
		verificar(not equipar_invalido.get("accepted", false) and _estado(pc) == previo, String(item) + "/amuleto_no_es_equipable")
	else:
		verificar(servicio.holdable(item), String(item) + "/equipamiento_registrado")
		if servicio.holdable(item):
			var equipado: Dictionary = servicio.equip(item, ID)
			var criatura := pc.owned_creature(ID)
			verificar(equipado.get("accepted", false) and criatura != null and criatura.species_id == origen and criatura.held_item_id == item and pc.inventory.quantity(item) == 1, String(item) + "/equipar_sin_cambiar_forma")
			if equipado.get("accepted", false):
				_persistencia(pc, item, String(origen) + "_equipado", 1, origen, item)
				var estado_equipado := _estado(pc)
				var uso_equipado: Dictionary = servicio.use_item(item, ID)
				var evolucion_equipada: Dictionary = servicio.evolve(item, ID)
				verificar(not uso_equipado.get("accepted", false) and not evolucion_equipada.get("accepted", false) and servicio.evolution_options(item, ID).is_empty() and _estado(pc) == estado_equipado, String(item) + "/equipar_no_activa_forma_o_reversion")
				var retirar: Dictionary = servicio.unequip(ID)
				verificar(retirar.get("accepted", false) and pc.inventory.quantity(item) == 2 and pc.owned_creature(ID).held_item_id == &"" and pc.owned_creature(ID).species_id == origen, String(item) + "/retirar_sin_transformacion")
	verificar(_estado(pc) == previo, String(item) + "/estado_forma_final_intacto")
	_persistencia(pc, item, String(origen) + "_final", 2, origen, &"")

func _auditar_contexto_05(catalogo: DefinitionCatalog, item: StringName, origen: StringName) -> void:
	verificar(catalogo.item(item) != null, String(item) + "/" + String(origen) + "/definicion")
	var pc := _crear(catalogo, origen)
	verificar(pc != null, String(item) + "/" + String(origen) + "/especie_catalogada")
	if pc == null:
		return
	var servicio := Servicio.new()
	verificar(servicio.configure(pc, catalogo, func(): return true), String(item) + "/" + String(origen) + "/servicio")
	verificar(pc.inventory.add(item, 2), String(item) + "/" + String(origen) + "/inventario")
	var antes := _estado(pc)
	verificar(not servicio.holdable(item), String(item) + "/" + String(origen) + "/no_equipable")
	var equipar: Dictionary = servicio.equip(item, ID)
	verificar(not equipar.get("accepted", false) and _estado(pc) == antes, String(item) + "/" + String(origen) + "/equipamiento_no_soportado")
	var opciones := servicio.evolution_options(item, ID)
	verificar(opciones.is_empty(), String(item) + "/" + String(origen) + "/no_evolucion_directa")
	var usar: Dictionary = servicio.use_item(item, ID)
	verificar(not usar.get("accepted", false) and _estado(pc) == antes and pc.inventory.quantity(item) == 2, String(item) + "/" + String(origen) + "/uso_sin_contrato_rechazado")
	var evolucion: Dictionary = servicio.evolve(item, ID)
	verificar(not evolucion.get("accepted", false) and _estado(pc) == antes and pc.inventory.quantity(item) == 2, String(item) + "/" + String(origen) + "/evolucion_no_inventada")
	var ajeno: Dictionary = servicio.use_item(item, &"id_ajeno")
	verificar(not ajeno.get("accepted", false) and _estado(pc) == antes, String(item) + "/" + String(origen) + "/propietario_invalido_rechazado")
	verificar(pc.owned_creature(ID).species_id == origen and pc.owned_creature(ID).held_item_id == &"" and _estado(pc) == antes, String(item) + "/" + String(origen) + "/forma_y_estado_inalterados")
	_persistencia(pc, item, String(origen) + "_sin_contexto", 2, origen, &"")

func _recuperacion_07(catalogo: DefinitionCatalog, item: StringName) -> void:
	verificar(catalogo.item(item) != null, String(item) + "/catalogo_medicina")
	var sano := _crear(catalogo, &"eevee")
	verificar(sano != null, String(item) + "/control_sano")
	if sano == null:
		return
	var servicio_sano := Servicio.new()
	verificar(servicio_sano.configure(sano, catalogo, func(): return true), String(item) + "/servicio_sano")
	verificar(sano.inventory.add(item, 2), String(item) + "/inventario_sano")
	var antes_sano := _estado(sano)
	verificar(not servicio_sano.holdable(item), String(item) + "/sin_equipamiento")
	verificar(servicio_sano.evolution_options(item, ID).is_empty(), String(item) + "/no_evolucion_medicina")
	var sin_efecto: Dictionary = servicio_sano.use_item(item, ID)
	verificar(not sin_efecto.get("accepted", false) and sano.inventory.quantity(item) == 2 and _estado(sano) == antes_sano, String(item) + "/sano_sin_consumo")
	var no_evolucion: Dictionary = servicio_sano.evolve(item, ID)
	verificar(not no_evolucion.get("accepted", false) and _estado(sano) == antes_sano, String(item) + "/sin_transformacion_medicina")
	var ajeno: Dictionary = servicio_sano.use_item(item, &"desconocido")
	verificar(not ajeno.get("accepted", false) and _estado(sano) == antes_sano, String(item) + "/ajeno_no_consume")
	_persistencia(sano, item, "sano_sin_cambio", 2, &"eevee", &"")
	var afectado := _crear(catalogo, &"eevee")
	verificar(afectado != null, String(item) + "/control_estado")
	if afectado == null:
		return
	var pokemon := afectado.owned_creature(ID)
	pokemon.status_state.persistent_id = &"burn"
	pokemon.status_ids.append(&"burn")
	var servicio := Servicio.new()
	verificar(servicio.configure(afectado, catalogo, func(): return true), String(item) + "/servicio_estado")
	verificar(afectado.inventory.add(item, 2), String(item) + "/stock_estado")
	var estampilla := _estado(afectado)
	var curacion: Dictionary = servicio.use_item(item, ID)
	verificar(curacion.get("accepted", false) and afectado.inventory.quantity(item) == 1, String(item) + "/curacion_consumo_unico")
	verificar(pokemon.species_id == &"eevee" and pokemon.status_state.persistent_id == &"" and pokemon.status_ids.is_empty(), String(item) + "/cura_sin_evolucion")
	verificar(_estado(afectado) != estampilla and afectado.owned_creature(ID).instance_id == ID, String(item) + "/mismo_id_y_estado_curado")
	_persistencia(afectado, item, "estado_curado", 1, &"eevee", &"")
	var ya_curado := _estado(afectado)
	var segundo: Dictionary = servicio.use_item(item, ID)
	verificar(not segundo.get("accepted", false) and _estado(afectado) == ya_curado and afectado.inventory.quantity(item) == 1, String(item) + "/sin_segunda_consumicion")

func _ejecutar() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not data is Dictionary:
		verificar(false, "catalogo_ilegible")
		_finalizar()
		return
	var catalogo: DefinitionCatalog = GameData.from_dict(data).to_definition_catalog()
	var milcery := catalogo.species(&"milcery")
	verificar(milcery != null and catalogo.species(&"eevee") != null, "especies_control_catalogadas")
	if milcery != null:
		for record: EvolutionRecord in milcery.evolutions:
			if record.trigger == &"spin":
				verificar(EvolutionSystem.classify_record(record, catalogo, &"milcery") == EvolutionSystem.UNSUPPORTED, "spin_no_degradado_a_use_item")
	for item: StringName in BLOQUE_01 + BLOQUE_02 + [BLOQUE_03[0]]:
		verificar(catalogo.item(item) != null, String(item) + "/item_catalogado")
		var positivos: Array[Dictionary] = []
		var total_registros := 0
		var condicionados := 0
		for sid: StringName in catalogo.species_catalog.all_ids():
			var sp: CreatureSpecies = catalogo.species(sid)
			for rec: EvolutionRecord in sp.evolutions:
				if rec.item_id != item:
					continue
				total_registros += 1
				var clasificacion := EvolutionSystem.classify_record(rec, catalogo, sid)
				if rec.trigger == EvolutionSystem.TRIGGER_USE_ITEM and clasificacion == EvolutionSystem.RUNTIME_SUPPORTED:
					positivos.append({"origen": sid, "destino": rec.species_id})
				else:
					condicionados += 1
					verificar(not EvolutionSystem.evolution_candidates(sp, {"level": 40, "item_id": item}, catalogo).has(rec), String(item) + "/condicion_no_ignorada")
		_negativo(catalogo, item, &"eevee")
		if not positivos.any(func(p): return p.origen == &"milcery"):
			_negativo(catalogo, item, &"milcery")
		if positivos.is_empty():
			print("CAMP004_W04_ITEM id=", String(item), " status=DEPENDENCIA records=", total_registros, " conditioned=", condicionados, " reason=sin_evolucion_directa_runtime;giro_y_forma_no_implementados")
		else:
			for ruta: Dictionary in positivos:
				_positivo(catalogo, item, ruta.origen as StringName, ruta.destino as StringName)
			print("CAMP004_W04_ITEM id=", String(item), " status=FUNCIONAL_VERIFICADO runtime_routes=", positivos.size(), " conditioned=", condicionados)
	# Dos contratos especiales autorizados de este bloque. No mutar los triggers.
	verificar(EvolutionSystem.UNSUPPORTED_TRIGGERS.has(&"three_defeated_bisharp"), "bisharp_derrotas_trigger_no_ejecutable")
	for item: StringName in [BLOQUE_03[1], BLOQUE_03[2]]:
		verificar(catalogo.item(item) != null, String(item) + "/item_catalogado")
		var origen: StringName = &"swirlix" if item == &"whipped_dream" else &"bisharp"
		var destino: StringName = &"slurpuff" if item == &"whipped_dream" else &"kingambit"
		verificar(catalogo.species(origen) != null and catalogo.species(destino) != null, String(item) + "/especies_catalogadas")
		var positivos: Array[Dictionary] = []
		var n_registros := 0
		var dependencias := 0
		for sid: StringName in catalogo.species_catalog.all_ids():
			var especie_actual: CreatureSpecies = catalogo.species(sid)
			for rec: EvolutionRecord in especie_actual.evolutions:
				if rec.item_id != item:
					continue
				n_registros += 1
				var clasificacion := EvolutionSystem.classify_record(rec, catalogo, sid)
				if rec.trigger == EvolutionSystem.TRIGGER_USE_ITEM and clasificacion == EvolutionSystem.RUNTIME_SUPPORTED:
					positivos.append({"origen": sid, "destino": rec.species_id})
				else:
					dependencias += 1
					verificar(not EvolutionSystem.evolution_candidates(especie_actual, {"level": 40, "item_id": item, "traded": false}, catalogo).has(rec), String(item) + "/mecanica_condicionada_no_degradada")
		_negativo(catalogo, item, &"eevee", destino)
		if not positivos.any(func(p): return p.origen == origen):
			_negativo(catalogo, item, origen, destino)
		if positivos.is_empty():
			print("CAMP004_W04_ITEM id=", String(item), " status=DEPENDENCIA records=", n_registros, " conditioned=", dependencias, " reason=intercambio_equipado_o_derrotas_requieren_contexto")
		else:
			for ruta: Dictionary in positivos:
				_positivo(catalogo, item, ruta.origen as StringName, ruta.destino as StringName)
			print("CAMP004_W04_ITEM id=", String(item), " status=FUNCIONAL_VERIFICADO runtime_routes=", positivos.size())
	for item: StringName in BLOQUE_04:
		var origen: StringName = &"dialga" if item == &"adamant_crystal" else &"kyogre" if item == &"blue_orb" else &"eevee"
		_auditar_contexto_04(catalogo, item, origen)
		if item != &"catching_charm":
			_auditar_contexto_04(catalogo, item, &"eevee")
		print("CAMP004_W04_ITEM id=", String(item), " status=", "AUDITORIA_DE_DATOS" if item == &"catching_charm" else "DEPENDENCIA", " reason=", "captura_pertenece_W03_no_certificada" if item == &"catching_charm" else "objeto_equipable_sin_ruta_forma_en_field_item_service")
	for item: StringName in BLOQUE_05:
		var origen: StringName = &"kyurem" if item == &"dna_splicers" else &"shaymin" if item == &"gracidea" else &"eevee"
		verificar(catalogo.item(item) != null, String(item) + "/catalogado")
		var registros := 0
		var pendientes := 0
		var rutas: Array[Dictionary] = []
		for sid: StringName in catalogo.species_catalog.all_ids():
			var especie_actual: CreatureSpecies = catalogo.species(sid)
			for record: EvolutionRecord in especie_actual.evolutions:
				if record.item_id != item:
					continue
				registros += 1
				var clasificacion := EvolutionSystem.classify_record(record, catalogo, sid)
				if record.trigger == EvolutionSystem.TRIGGER_USE_ITEM and clasificacion == EvolutionSystem.RUNTIME_SUPPORTED:
					rutas.append({"origen": sid, "destino": record.species_id})
				else:
					pendientes += 1
					verificar(not EvolutionSystem.evolution_candidates(especie_actual, {"level": 40, "item_id": item}, catalogo).has(record), String(item) + "/modalidad_no_ejecutable")
		if rutas.is_empty():
			_auditar_contexto_05(catalogo, item, origen)
			if origen != &"eevee":
				_auditar_contexto_05(catalogo, item, &"eevee")
			print("CAMP004_W04_ITEM id=", String(item), " status=DEPENDENCIA records=", registros, " conditioned=", pendientes, " reason=", "fusion_kyurem_no_implementada" if item == &"dna_splicers" else "bono_experiencia_fuera_del_servicio_W04" if item == &"exp_charm" else "forma_shaymin_necesita_contexto")
		else:
			_auditar_contexto_05(catalogo, item, &"eevee")
			for ruta: Dictionary in rutas:
				_positivo(catalogo, item, ruta.origen as StringName, ruta.destino as StringName)
			print("CAMP004_W04_ITEM id=", String(item), " status=FUNCIONAL_VERIFICADO runtime_routes=", rutas.size())
	for item: StringName in BLOQUE_06:
		var origen: StringName = &"giratina" if item == &"griseous_core" else &"palkia" if item == &"lustrous_globe" else &"deoxys"
		verificar(catalogo.item(item) != null, String(item) + "/definicion_bloque06")
		verificar(catalogo.species(origen) != null, String(item) + "/especie_control_bloque06")
		var registros := 0
		var condicionados := 0
		var rutas: Array[Dictionary] = []
		for sid: StringName in catalogo.species_catalog.all_ids():
			var especie_actual: CreatureSpecies = catalogo.species(sid)
			for record: EvolutionRecord in especie_actual.evolutions:
				if record.item_id != item:
					continue
				registros += 1
				var clasificacion := EvolutionSystem.classify_record(record, catalogo, sid)
				if record.trigger == EvolutionSystem.TRIGGER_USE_ITEM and clasificacion == EvolutionSystem.RUNTIME_SUPPORTED:
					rutas.append({"origen": sid, "destino": record.species_id})
				else:
					condicionados += 1
					verificar(not EvolutionSystem.evolution_candidates(especie_actual, {"level": 40, "item_id": item}, catalogo).has(record), String(item) + "/ruta_forma_no_degradada")
		if rutas.is_empty():
			if item == &"meteorite":
				_auditar_contexto_05(catalogo, item, origen)
				_auditar_contexto_05(catalogo, item, &"eevee")
			else:
				_auditar_contexto_04(catalogo, item, origen)
				_auditar_contexto_04(catalogo, item, &"eevee")
			print("CAMP004_W04_ITEM id=", String(item), " status=DEPENDENCIA records=", registros, " conditioned=", condicionados, " reason=", "forma_deoxys_meteorito_sin_servicio" if item == &"meteorite" else "equipamiento_verificado_sin_ruta_forma_certificada")
		else:
			if item == &"meteorite":
				_auditar_contexto_05(catalogo, item, &"eevee")
			else:
				_auditar_contexto_04(catalogo, item, &"eevee")
			for ruta: Dictionary in rutas:
				_positivo(catalogo, item, ruta.origen as StringName, ruta.destino as StringName)
			print("CAMP004_W04_ITEM id=", String(item), " status=FUNCIONAL_VERIFICADO runtime_routes=", rutas.size(), " condicionados=", condicionados)
	for item: StringName in BLOQUE_07:
		verificar(catalogo.item(item) != null, String(item) + "/item_bloque07")
		var registros := 0
		for sid: StringName in catalogo.species_catalog.all_ids():
			var especie_actual: CreatureSpecies = catalogo.species(sid)
			for record: EvolutionRecord in especie_actual.evolutions:
				if record.item_id != item:
					continue
				registros += 1
				verificar(EvolutionSystem.classify_record(record, catalogo, sid) != EvolutionSystem.RUNTIME_SUPPORTED or record.trigger == EvolutionSystem.TRIGGER_USE_ITEM, String(item) + "/forma_contextual_no_degradada")
		if item == &"rage_candy_bar":
			_recuperacion_07(catalogo, item)
			print("CAMP004_W04_ITEM id=", String(item), " status=RECUPERACION_VERIFICADA records=", registros, " reason=efecto_cura_real_sin_evolucion")
		elif item == &"red_orb":
			_auditar_contexto_04(catalogo, item, &"groudon")
			_auditar_contexto_04(catalogo, item, &"eevee")
			print("CAMP004_W04_ITEM id=", String(item), " status=DEPENDENCIA records=", registros, " reason=orbe_equipable_primal_no_certificado")
		else:
			_auditar_contexto_05(catalogo, item, &"calyrex")
			_auditar_contexto_05(catalogo, item, &"eevee")
			print("CAMP004_W04_ITEM id=", String(item), " status=DEPENDENCIA records=", registros, " reason=union_calyrex_fusion_no_conectada")
	_finalizar()

func _finalizar() -> void:
	if terminado:
		return
	terminado = true
	if errores.is_empty():
		print("CAMP004_W04_GODOT PASS blocks=7 checks=", checks)
	else:
		print("CAMP004_W04_GODOT FAIL errors=", JSON.stringify(errores))
	quit(0 if errores.is_empty() else 1)
