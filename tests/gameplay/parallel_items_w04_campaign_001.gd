extends SceneTree

# CAMP_001 W04. Un runner parametrizado para tres microbloques.
# ITER_01: Fire/Water/Thunder; ITER_02 y 03 solo tras nueva "p".
# Godot 4.7 --headless --path . --script res://tests/gameplay/parallel_items_w04_campaign_001.gd
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const Contenido = preload("res://modules/gameplay/randomlock_content_policy.gd")
const ID := &"camp_001_w04"
const CASOS_01 := [
	{"objeto": "fire_stone", "origen": "eevee", "alternativo": "water_stone"},
	{"objeto": "fire_stone", "origen": "growlithe", "alternativo": "water_stone"},
	{"objeto": "water_stone", "origen": "eevee", "alternativo": "thunder_stone"},
	{"objeto": "water_stone", "origen": "shellder", "alternativo": "thunder_stone"},
	{"objeto": "thunder_stone", "origen": "eevee", "alternativo": "fire_stone"},
	{"objeto": "thunder_stone", "origen": "pikachu", "alternativo": "fire_stone"},
]
const CASOS_02 := [
	{"objeto": "leaf_stone", "origen": "eevee"},
	{"objeto": "leaf_stone", "origen": "gloom"},
	{"objeto": "ice_stone", "origen": "eevee"},
	{"objeto": "moon_stone", "origen": "clefairy"},
	{"objeto": "moon_stone", "origen": "jigglypuff"},
]
var catalogos: DefinitionCatalog
var politica := Contenido.new()
var bloqueado := false
var pruebas := 0
var errores: Array[String] = []
var resultados: Array[Dictionary] = []
var cerrado := false


func _initialize() -> void:
	create_timer(100.0).timeout.connect(func():
		if not cerrado:
			comprobar("tiempo_maximo", false)
			finalizar())
	call_deferred("_ejecutar")


func comprobar(etiqueta: String, condicion: bool) -> void:
	pruebas += 1
	if not condicion:
		errores.append(etiqueta)
		push_error("CAMP_001_W04: " + etiqueta)


func instantanea(propietario: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(propietario.party, propietario.storage, propietario.inventory).to_dict())


func iniciar(especie: StringName) -> RefCounted:
	var definicion := catalogos.species(especie)
	comprobar("existe_especie/" + String(especie), definicion != null)
	if definicion == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261101
	var criatura := CreatureFactory.create(definicion, 40, catalogos, ProgressionRuleset.new(), rng,
		{"instance_id": ID, "moves": ["tackle", "protect"], "nature_id": &"hardy"})
	for habilidad: StringName in definicion.ability_ids:
		if politica.ability_allowed(String(habilidad)):
			criatura.ability_id = habilidad
			break
	var propietario := PlayerCollection.new()
	comprobar("registrar_especie/" + String(especie), propietario.party.add_creature(criatura))
	var servicio := Servicio.new()
	comprobar("iniciar_servicio/" + String(especie), servicio.configure(propietario, catalogos,
		func(): return not bloqueado))
	return servicio


func caso_clasico(fila: Dictionary) -> void:
	var objeto := StringName(fila.objeto)
	var origen := StringName(fila.origen)
	var otro_objeto := StringName(fila.alternativo)
	var etiqueta := String(objeto) + "/" + String(origen) + "/"
	var servicio := iniciar(origen)
	if servicio == null:
		return
	var propietario: PlayerCollection = servicio.owner
	var criatura: CreatureInstance = propietario.owned_creature(ID)
	comprobar(etiqueta + "objeto_catalogado_y_permitido",
		catalogos.item(objeto) != null and servicio.selection.content_allowed(objeto))
	comprobar(etiqueta + "origen_permitido", politica.species_allowed(String(origen)))
	var opciones: Array[StringName] = servicio.evolution_options(objeto, ID)
	# El destino se obtiene del catálogo real, sin imponer el de otras versiones.
	comprobar(etiqueta + "opcion_unica", opciones.size() == 1)
	if opciones.is_empty():
		resultados.append({"item_id": String(objeto), "source": String(origen),
			"status": "NO_RUNTIME_ELIGIBLE_TARGET"})
		return
	var destino: StringName = opciones[0]
	comprobar(etiqueta + "destino_catalogado_permitido",
		catalogos.species(destino) != null and politica.species_allowed(String(destino)))
	var respaldado := false
	for record: EvolutionRecord in catalogos.species(origen).evolutions:
		if record.trigger == EvolutionSystem.TRIGGER_USE_ITEM and record.item_id == objeto \
				and record.species_id == destino and \
				EvolutionSystem.classify_record(record, catalogos, origen) == EvolutionSystem.RUNTIME_SUPPORTED:
			respaldado = true
	comprobar(etiqueta + "opcion_derivada_de_regla_valida", respaldado)
	comprobar(etiqueta + "sin_stock", propietario.inventory.quantity(objeto) == 0)
	var antes := instantanea(propietario)
	var sin_stock: Dictionary = servicio.evolve(objeto, ID, destino)
	comprobar(etiqueta + "rechazo_sin_stock", not sin_stock.get("accepted", false)
		and sin_stock.get("reason", "") == "item_not_owned" and instantanea(propietario) == antes)
	comprobar(etiqueta + "stock_dos", propietario.inventory.add(objeto, 2))
	comprobar(etiqueta + "stock_alternativo", propietario.inventory.add(otro_objeto))
	antes = instantanea(propietario)
	var ajeno: Dictionary = servicio.evolve(objeto, &"criatura_de_otra_persona", destino)
	comprobar(etiqueta + "no_propietario", not ajeno.get("accepted", false)
		and ajeno.get("reason", "") == "creature_not_owned" and instantanea(propietario) == antes)
	var falso: Dictionary = servicio.evolve(objeto, ID, &"mewtwo")
	comprobar(etiqueta + "destino_inventado", not falso.get("accepted", false)
		and falso.get("reason", "") == "invalid_evolution_target" and instantanea(propietario) == antes)
	var cruzado: Dictionary = servicio.evolve(otro_objeto, ID, destino)
	comprobar(etiqueta + "piedra_equivocada", not cruzado.get("accepted", false)
		and instantanea(propietario) == antes)
	bloqueado = true
	var ocupado: Dictionary = servicio.evolve(objeto, ID, destino)
	bloqueado = false
	comprobar(etiqueta + "campo_bloqueado", not ocupado.get("accepted", false)
		and ocupado.get("reason", "") == "field_locked" and instantanea(propietario) == antes)
	var no_elegible := iniciar(&"mew")
	if no_elegible != null:
		comprobar(etiqueta + "stock_especie_incorrecta", no_elegible.owner.inventory.add(objeto))
		var antes_incorrecta := instantanea(no_elegible.owner)
		var respuesta: Dictionary = no_elegible.evolve(objeto, ID, destino)
		comprobar(etiqueta + "especie_incorrecta_sin_gasto",
			not respuesta.get("accepted", false)
			and respuesta.get("reason", "") == "no_eligible_evolution"
			and instantanea(no_elegible.owner) == antes_incorrecta)
	var ivs: Dictionary = criatura.ivs.duplicate(true)
	var evs: Dictionary = criatura.evs.duplicate(true)
	var movimientos: Array = criatura.move_ids.duplicate()
	var experiencia := criatura.experience
	var amistad := criatura.friendship
	var aceptada: Dictionary = servicio.evolve(objeto, ID, destino)
	var final: CreatureInstance = propietario.owned_creature(ID)
	comprobar(etiqueta + "acepta_evolucion", aceptada.get("accepted", false)
		and aceptada.get("species_id", "") == String(destino)
		and final != null and final.species_id == destino)
	comprobar(etiqueta + "consumo_unico", propietario.inventory.quantity(objeto) == 1
		and propietario.inventory.quantity(otro_objeto) == 1)
	if final != null:
		comprobar(etiqueta + "identidad_y_equipo", final.instance_id == ID
			and propietario.location_of(ID) == &"PARTY" and propietario.party.size() == 1)
		comprobar(etiqueta + "datos_persistentes", final.ivs == ivs and final.evs == evs
			and final.move_ids == movimientos and final.experience == experiencia
			and final.friendship == amistad)
	antes = instantanea(propietario)
	var repetida: Dictionary = servicio.evolve(objeto, ID, destino)
	comprobar(etiqueta + "no_doble_uso", not repetida.get("accepted", false)
		and instantanea(propietario) == antes)
	resultados.append({"item_id": String(objeto), "source": String(origen),
		"target_from_catalog": String(destino), "status": "ASSERTED" if final != null \
		and final.species_id == destino else "FAILED"})



# Microbloque 02: mismas APIs reales, comprobación de equipo, PC y cantidad.
func caso_secundario(fila: Dictionary) -> void:
	var objeto := StringName(fila.objeto)
	var origen := StringName(fila.origen)
	var etiqueta := String(objeto) + "/" + String(origen) + "/"
	var equipo := iniciar(origen)
	var pc := iniciar(origen)
	if equipo == null or pc == null:
		comprobar(etiqueta + "servicios_existentes", false)
		return
	comprobar(etiqueta + "deposito_pc", pc.owner.deposit(ID)
		and pc.owner.location_of(ID) == &"STORAGE")
	var opciones_equipo: Array[StringName] = equipo.evolution_options(objeto, ID)
	var opciones_pc: Array[StringName] = pc.evolution_options(objeto, ID)
	comprobar(etiqueta + "destino_único_compartido", opciones_equipo.size() == 1
		and opciones_pc == opciones_equipo)
	if opciones_equipo.size() != 1:
		resultados.append({"item_id": String(objeto), "source": String(origen),
			"status": "NO_RUNTIME_ELIGIBLE_TARGET", "iteration": 2})
		return
	var destino: StringName = opciones_equipo[0]
	var fuente_valida := false
	for record: EvolutionRecord in catalogos.species(origen).evolutions:
		if record.item_id == objeto and record.species_id == destino \
				and record.trigger == EvolutionSystem.TRIGGER_USE_ITEM \
				and EvolutionSystem.classify_record(record, catalogos, origen) == EvolutionSystem.RUNTIME_SUPPORTED:
			fuente_valida = true
	comprobar(etiqueta + "registro_elegible", fuente_valida)
	for servicio: RefCounted in [equipo, pc]:
		var propietario: PlayerCollection = servicio.owner
		var lugar: StringName = propietario.location_of(ID)
		var prefijo := etiqueta + String(lugar) + "/"
		var pokemon: CreatureInstance = propietario.owned_creature(ID)
		var antes := instantanea(propietario)
		comprobar(prefijo + "sin_stock", propietario.inventory.quantity(objeto) == 0)
		var sin_stock: Dictionary = servicio.evolve(objeto, ID, destino)
		comprobar(prefijo + "rechazo_sin_stock", not sin_stock.get("accepted", false)
			and sin_stock.get("reason", "") == "item_not_owned"
			and instantanea(propietario) == antes)
		comprobar(prefijo + "añadir_dos", propietario.inventory.add(objeto, 2))
		antes = instantanea(propietario)
		var ajeno: Dictionary = servicio.evolve(objeto, &"no_propietario", destino)
		comprobar(prefijo + "rechazo_ajeno_sin_consumo", not ajeno.get("accepted", false)
			and ajeno.get("reason", "") == "creature_not_owned"
			and instantanea(propietario) == antes)
		var invalido: Dictionary = servicio.evolve(objeto, ID, &"mewtwo")
		comprobar(prefijo + "rechazo_destino_invalido", not invalido.get("accepted", false)
			and invalido.get("reason", "") == "invalid_evolution_target"
			and instantanea(propietario) == antes)
		var ivs: Dictionary = pokemon.ivs.duplicate(true)
		var evs: Dictionary = pokemon.evs.duplicate(true)
		var anterior_movimientos: Array = pokemon.move_ids.duplicate()
		var anterior_experiencia := pokemon.experience
		var anterior_amistad := pokemon.friendship
		var aplicado: Dictionary = servicio.evolve(objeto, ID, destino)
		var final: CreatureInstance = propietario.owned_creature(ID)
		comprobar(prefijo + "aceptado_y_consumo_unico", aplicado.get("accepted", false)
			and aplicado.get("species_id", "") == String(destino)
			and propietario.inventory.quantity(objeto) == 1)
		comprobar(prefijo + "propiedad_y_especie", final != null
			and final.instance_id == ID and final.species_id == destino
			and propietario.location_of(ID) == lugar)
		if final != null:
			comprobar(prefijo + "datos_originales", final.ivs == ivs and final.evs == evs
				and final.move_ids == anterior_movimientos
				and final.experience == anterior_experiencia
				and final.friendship == anterior_amistad)
		antes = instantanea(propietario)
		var repetido: Dictionary = servicio.evolve(objeto, ID, destino)
		comprobar(prefijo + "no_segunda_evolucion", not repetido.get("accepted", false)
			and instantanea(propietario) == antes and propietario.inventory.quantity(objeto) == 1)
	resultados.append({"item_id": String(objeto), "source": String(origen),
		"target_from_catalog": String(destino), "iteration": 2,
		"locations": ["PARTY", "STORAGE"], "status": "ASSERTED"})


# Una ruta regional condicionada NO puede degradarse a simple uso en Vulpix común.
# La cadena canónica 15 contiene ice-stone sobre vulpix-alola. El catálogo
# activo puede no exponerla; registrar explícitamente ese límite.
func comprobar_forma_condicionada() -> void:
	var servicio := iniciar(&"vulpix")
	if servicio == null:
		return
	var propietario: PlayerCollection = servicio.owner
	comprobar("hielo_vulpix/stock", propietario.inventory.add(&"ice_stone", 2))
	var condicionada := false
	for record: EvolutionRecord in catalogos.species(&"vulpix").evolutions:
		if record.item_id != &"ice_stone":
			continue
		if not record.conditions.is_empty() \
				and EvolutionSystem.classify_record(record, catalogos, &"vulpix") != EvolutionSystem.RUNTIME_SUPPORTED:
			condicionada = true
	var opciones: Array[StringName] = servicio.evolution_options(&"ice_stone", ID)
	var antes := instantanea(propietario)
	var respuesta: Dictionary = servicio.evolve(&"ice_stone", ID)
	comprobar("hielo_vulpix/rechazo_sin_consumo", opciones.is_empty()
		and not respuesta.get("accepted", false)
		and propietario.inventory.quantity(&"ice_stone") == 2
		and instantanea(propietario) == antes)
	if condicionada:
		comprobar("hielo_vulpix/requisito_adicional_conservado",
			respuesta.get("reason", "") == "evolution_requires_additional_mechanic")
		resultados.append({"item_id": "ice_stone", "source": "vulpix",
			"status": "CONDITIONAL_ROUTE_REJECTED", "iteration": 2})
	else:
		comprobar("hielo_vulpix/sin_ruta_ordinaria",
			respuesta.get("reason", "") == "no_eligible_evolution")
		resultados.append({"item_id": "ice_stone", "source": "vulpix",
			"status": "CONDITIONAL_ROUTE_NOT_IN_ACTIVE_CATALOG", "iteration": 2})


func comprobar_especie_erronea() -> void:
	for id: StringName in [&"leaf_stone", &"ice_stone", &"moon_stone"]:
		var servicio := iniciar(&"mew")
		if servicio == null:
			continue
		var propietario: PlayerCollection = servicio.owner
		comprobar(String(id) + "/especie_erronea_stock", propietario.inventory.add(id))
		var antes := instantanea(propietario)
		var respuesta: Dictionary = servicio.evolve(id, ID)
		comprobar(String(id) + "/especie_erronea_rechazada_sin_gasto",
			not respuesta.get("accepted", false) and respuesta.get("reason", "") == "no_eligible_evolution"
			and instantanea(propietario) == antes)

func _ejecutar() -> void:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not datos is Dictionary:
		comprobar("catalogo_invalido", false)
		finalizar()
		return
	catalogos = GameData.from_dict(datos).to_definition_catalog()
	comprobar("contenido_cargado", politica.load_local())
	for fila: Dictionary in CASOS_01:
		caso_clasico(fila)
	for fila: Dictionary in CASOS_02:
		caso_secundario(fila)
	comprobar_forma_condicionada()
	comprobar_especie_erronea()
	finalizar()


func finalizar() -> void:
	if cerrado:
		return
	cerrado = true
	var reporte := {"status": "PASS" if errores.is_empty() else "FAIL",
		"iteration": 2, "checks": pruebas, "cases": resultados.size(),
		"results": resultados, "errors": errores, "scope": "W04_CAMP_001_STONES_02"}
	print("PARALLEL_ITEMS_W04_CAMPAIGN_001 ", JSON.stringify(reporte))
	quit(0 if errores.is_empty() else 1)
