extends SceneTree

# Prueba parametrizada W04: solo usa APIs existentes, no cambia mecanicas.
# Ejecutar con Godot 4.7:
# godot --headless --path . --script res://tests/gameplay/parallel_items_w04_evolution_v1.gd
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const Contenido = preload("res://modules/gameplay/randomlock_content_policy.gd")
const CASOS := [
	{"objeto": "auspicious_armor", "origen": "charcadet", "destino": "armarouge", "incorrecto": "ceruledge"},
	{"objeto": "malicious_armor", "origen": "charcadet", "destino": "ceruledge", "incorrecto": "armarouge"},
	{"objeto": "black_augurite", "origen": "scyther", "destino": "kleavor", "incorrecto": "scizor"},
]
const ID := &"w04_evolucion"
var catalogos: DefinitionCatalog
var contenido := Contenido.new()
var bloqueado := false
var comprobaciones := 0
var errores: Array[String] = []
var completado := false


func _initialize() -> void:
	create_timer(90.0).timeout.connect(func():
		if not completado:
			verificar("watchdog_timeout", false)
			finalizar())
	call_deferred("_ejecutar")


func verificar(nombre: String, correcto: bool) -> void:
	comprobaciones += 1
	if not correcto:
		errores.append(nombre)
		push_error("W04 EVOLUTION FAIL: " + nombre)


func instantanea(propietario: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(propietario.party, propietario.storage, propietario.inventory).to_dict())


func crear_servicio(especie: StringName) -> RefCounted:
	var definicion := catalogos.species(especie)
	if definicion == null:
		verificar("especie_origen_ausente_" + String(especie), false)
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 401
	var pokemon := CreatureFactory.create(definicion, 50, catalogos, ProgressionRuleset.new(), rng,
		{"instance_id": ID, "moves": ["tackle", "protect"], "nature_id": &"hardy"})
	if pokemon == null:
		verificar("creacion_ausente_" + String(especie), false)
		return null
	# Igual que item_connections_test_runner: seleccionar una habilidad permitida.
	for habilidad: StringName in definicion.ability_ids:
		if contenido.ability_allowed(String(habilidad)):
			pokemon.ability_id = habilidad
			break
	var propietario := PlayerCollection.new()
	verificar("anadir_especie_" + String(especie), propietario.party.add_creature(pokemon))
	var servicio := Servicio.new()
	verificar("configurar_servicio_" + String(especie), servicio.configure(propietario, catalogos, func(): return not bloqueado))
	return servicio


func probar_caso(caso: Dictionary) -> void:
	var objeto := StringName(caso.objeto)
	var origen := StringName(caso.origen)
	var destino := StringName(caso.destino)
	var incorrecto := StringName(caso.incorrecto)
	var prefijo := String(objeto) + "/"

	# Elegibilidad real y frontera: la otra evolucion de Charcadet NO es la seleccionada.
	var servicio := crear_servicio(origen)
	if servicio == null:
		return
	var propietario: PlayerCollection = servicio.owner
	var pokemon: CreatureInstance = propietario.owned_creature(ID)
	verificar(prefijo + "catalogo_objeto", catalogos.item(objeto) != null)
	verificar(prefijo + "politica_objeto", servicio.selection.content_allowed(objeto))
	verificar(prefijo + "catalogo_destino", catalogos.species(destino) != null and contenido.species_allowed(String(destino)))
	verificar(prefijo + "sin_stock", propietario.inventory.quantity(objeto) == 0)
	var antes := instantanea(propietario)
	var sin_stock: Dictionary = servicio.use_item(objeto, ID)
	verificar(prefijo + "rechazo_sin_stock", not sin_stock.get("accepted", false)
		and sin_stock.get("reason", "") == "item_not_owned" and instantanea(propietario) == antes)

	verificar(prefijo + "alta_dos_unidades", propietario.inventory.add(objeto, 2))
	antes = instantanea(propietario)
	var ajeno: Dictionary = servicio.evolve(objeto, &"w04_no_propietario", destino)
	verificar(prefijo + "identidad_ajena_sin_gasto", not ajeno.get("accepted", false)
		and ajeno.get("reason", "") == "creature_not_owned" and instantanea(propietario) == antes)
	var opciones: Array[StringName] = servicio.evolution_options(objeto, ID)
	verificar(prefijo + "solo_destino_correcto", opciones.size() == 1
		and opciones.has(destino) and not opciones.has(incorrecto))
	var incorrecta: Dictionary = servicio.evolve(objeto, ID, incorrecto)
	verificar(prefijo + "destino_alternativo_sin_gasto", not incorrecta.get("accepted", false)
		and incorrecta.get("reason", "") == "invalid_evolution_target"
		and instantanea(propietario) == antes)
	bloqueado = true
	var ocupado: Dictionary = servicio.use_item(objeto, ID)
	bloqueado = false
	verificar(prefijo + "campo_bloqueado_sin_gasto", not ocupado.get("accepted", false)
		and ocupado.get("reason", "") == "field_locked" and instantanea(propietario) == antes)

	var ivs := pokemon.ivs.duplicate(true)
	var evs := pokemon.evs.duplicate(true)
	var movimientos := pokemon.move_ids.duplicate()
	var amistad := pokemon.friendship
	var resultado: Dictionary = servicio.use_item(objeto, ID)
	var evolucionado: CreatureInstance = propietario.owned_creature(ID)
	verificar(prefijo + "evolucion_aplicada", resultado.get("accepted", false)
		and resultado.get("species_id", "") == String(destino)
		and evolucionado != null and evolucionado.species_id == destino)
	verificar(prefijo + "consumo_exactamente_una", propietario.inventory.quantity(objeto) == 1)
	if evolucionado != null:
		verificar(prefijo + "conserva_identidad_y_propietario", evolucionado.instance_id == ID
			and propietario.location_of(ID) == &"PARTY" and propietario.party.size() == 1)
		verificar(prefijo + "conserva_datos", evolucionado.ivs == ivs
			and evolucionado.evs == evs and evolucionado.move_ids == movimientos
			and evolucionado.friendship == amistad)
	antes = instantanea(propietario)
	var repetida: Dictionary = servicio.use_item(objeto, ID)
	verificar(prefijo + "sin_doble_evolucion_ni_gasto", not repetida.get("accepted", false)
		and instantanea(propietario) == antes and propietario.inventory.quantity(objeto) == 1)

	# Regresion KO: evolucionar no equivale a revivir.
	var ko := crear_servicio(origen)
	if ko != null:
		ko.owner.owned_creature(ID).current_hp = 0
		verificar(prefijo + "stock_ko", ko.owner.inventory.add(objeto))
		var resultado_ko: Dictionary = ko.use_item(objeto, ID)
		var pokemon_ko: CreatureInstance = ko.owner.owned_creature(ID)
		verificar(prefijo + "ko_sin_resurreccion", resultado_ko.get("accepted", false)
			and pokemon_ko != null and pokemon_ko.species_id == destino
			and pokemon_ko.current_hp == 0 and ko.owner.inventory.quantity(objeto) == 0)

	# Prueba nominal de PC, persistencia ANTES y DESPUES de evolucionar.
	var almacen := crear_servicio(origen)
	if almacen == null:
		return
	verificar(prefijo + "depositar_pc", almacen.owner.deposit(ID)
		and almacen.owner.location_of(ID) == &"STORAGE")
	verificar(prefijo + "stock_pc", almacen.owner.inventory.add(objeto, 2))
	var repositorio := SaveGameRepository.new()
	var ruta := "user://w04_evolution_" + String(objeto) + ".json"
	var guardado_previo: SaveResult = repositorio.save_collection(ruta, almacen.owner)
	verificar(prefijo + "guardar_antes", guardado_previo.ok)
	if guardado_previo.ok:
		var carga_previa: LoadResult = repositorio.load(ruta)
		verificar(prefijo + "cargar_antes", carga_previa.ok)
		if carga_previa.ok:
			verificar(prefijo + "pc_y_stock_antes", carga_previa.storage.get_creature(ID) != null
				and carga_previa.party.get_creature(ID) == null
				and carga_previa.inventory.quantity(objeto) == 2
				and carga_previa.storage.get_creature(ID).species_id == origen)
			var restaurado := PlayerCollection.new()
			restaurado.party = carga_previa.party
			restaurado.storage = carga_previa.storage
			restaurado.inventory = carga_previa.inventory
			var servicio_pc := Servicio.new()
			verificar(prefijo + "servicio_restaura_pc", servicio_pc.configure(restaurado, catalogos, func(): return not bloqueado))
			var resultado_pc: Dictionary = servicio_pc.use_item(objeto, ID)
			verificar(prefijo + "evolucion_pc", resultado_pc.get("accepted", false)
				and restaurado.location_of(ID) == &"STORAGE"
				and restaurado.owned_creature(ID).species_id == destino
				and restaurado.inventory.quantity(objeto) == 1)
			var guardado_final: SaveResult = repositorio.save_collection(ruta, restaurado)
			verificar(prefijo + "guardar_despues", guardado_final.ok)
			if guardado_final.ok:
				var carga_final: LoadResult = repositorio.load(ruta)
				verificar(prefijo + "cargar_despues", carga_final.ok)
				if carga_final.ok:
					verificar(prefijo + "pc_evolucion_y_stock_persistentes",
						carga_final.storage.get_creature(ID) != null
						and carga_final.storage.get_creature(ID).species_id == destino
						and carga_final.party.get_creature(ID) == null
						and carga_final.inventory.quantity(objeto) == 1)
	# Solo limpiar el guardado dedicado de ESTE test.
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _ejecutar() -> void:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not datos is Dictionary:
		verificar("datos_canonicos_invalidos", false)
		finalizar()
		return
	catalogos = GameData.from_dict(datos).to_definition_catalog()
	verificar("politica_de_contenido", contenido.load_local())
	for caso: Dictionary in CASOS:
		probar_caso(caso)
	finalizar()


func finalizar() -> void:
	if completado:
		return
	completado = true
	var resultado := {
		"status": "PASS" if errores.is_empty() else "FAIL",
		"checks": comprobaciones,
		"cases": CASOS.size(),
		"errors": errores,
		"scope": "W04_ITEM_EVOLUTIONS_BAG_PC_SAVE_NO_GPU"
	}
	print("PARALLEL_ITEMS_W04_EVOLUTION_V1 ", JSON.stringify(resultado))
	quit(0 if errores.is_empty() else 1)
