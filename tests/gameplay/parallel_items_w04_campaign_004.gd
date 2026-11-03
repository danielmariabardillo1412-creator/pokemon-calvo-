extends SceneTree
# W04 CAMP004: pruebas de runtime. Un PASS negativo NO certifica evolucion positiva.
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const BLOQUE_01 := [&"berry_sweet", &"clover_sweet", &"flower_sweet"]
const BLOQUE_02 := [&"love_sweet", &"ribbon_sweet", &"star_sweet"]
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

func _negativo(catalogo: DefinitionCatalog, item: StringName, especie: StringName) -> void:
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
	var evolucion: Dictionary = servicio.evolve(item, ID, &"alcremie")
	verificar(not evolucion.get("accepted", false) and _estado(pc) == antes and pc.inventory.quantity(item) == 2, String(item) + "/" + String(especie) + "/evolucion_forzada_rechazada")
	if servicio.holdable(item):
		var equipar: Dictionary = servicio.equip(item, ID)
		verificar(equipar.get("accepted", false) and pc.inventory.quantity(item) == 1 and pc.owned_creature(ID).held_item_id == item, String(item) + "/" + String(especie) + "/equipar_sin_evolucion")
		if equipar.get("accepted", false):
			_persistencia(pc, item, String(especie) + "_equipado", 1, especie, item)
			var equipado_antes := _estado(pc)
			var con_equipamiento: Dictionary = servicio.evolve(item, ID, &"alcremie")
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
	for item: StringName in BLOQUE_01 + BLOQUE_02:
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
	_finalizar()

func _finalizar() -> void:
	if terminado:
		return
	terminado = true
	if errores.is_empty():
		print("CAMP004_W04_GODOT PASS blocks=2 checks=", checks)
	else:
		print("CAMP004_W04_GODOT FAIL errors=", JSON.stringify(errores))
	quit(0 if errores.is_empty() else 1)
