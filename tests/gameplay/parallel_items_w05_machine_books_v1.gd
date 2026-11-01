extends SceneTree

# W05 CAMP_001/01: prueba de lectura del adaptador de libros de movimientos.
# Solo consulta el perfil canónico, sin modificar aprendizaje, inventario ni guardados.
const Libros = preload("res://modules/inventory/field_machine_book_profile.gd")
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const Contenido = preload("res://modules/gameplay/randomlock_content_policy.gd")
const ID_TEST := &"w05_libro_prueba"
const PERFIL = "res://modules/inventory/item_connections_v1.json"
const DATOS = "res://data/normalized/pokemon_api.json"
var comprobaciones := 0
var errores: Array[String] = []
var acceso_bloqueado := false


func _initialize() -> void:
	call_deferred("_verificar")


func _check(etiqueta: String, condicion: bool) -> void:
	comprobaciones += 1
	if not condicion:
		errores.append(etiqueta)
		push_error("W05 MACHINE FAIL: " + etiqueta)


func _verificar() -> void:
	var perfil_bruto: Variant = JSON.parse_string(FileAccess.get_file_as_string(PERFIL))
	var datos_brutos: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATOS))
	_check("Perfil legible", perfil_bruto is Dictionary)
	_check("Catálogo legible", datos_brutos is Dictionary)
	if not (perfil_bruto is Dictionary and datos_brutos is Dictionary):
		_fin()
		return
	var perfil: Dictionary = perfil_bruto
	var catalogos: DefinitionCatalog = GameData.from_dict(datos_brutos).to_definition_catalog()
	_check("Catálogo construido", catalogos != null)
	if catalogos == null:
		_fin()
		return
	_check("Perfil versión activa", perfil.get("active_machine_version") == "scarlet-violet")
	_check("Perfil identificador esperado", perfil.get("profile_id") == "calvo_item_connections_v1")
	var filas: Dictionary = perfil.get("machine_rows", {})

	# Contraste contra mapeo realmente presente: no inferir el movimiento por número de MT.
	for id: String in ["tm01", "tm02"]:
		var registro: Dictionary = filas.get(id, {})
		var esperado: String = registro.get("scarlet-violet", "")
		_check(id + " presente en versión activa", not esperado.is_empty())
		var respuesta: Dictionary = Libros.consultar(StringName(id), perfil, catalogos)
		_check(id + " consulta disponible", respuesta.get("disponible", false))
		_check(id + " movimiento canónico", respuesta.get("move_id", "") == esperado)
		var definicion: MoveDefinition = catalogos.move(StringName(esperado))
		if definicion == null:
			_check(id + " definición de movimiento presente", false)
		else:
			_check(id + " tipo original", respuesta.get("type_id", "") == String(definicion.type_id))

	# Una MO histórica no queda habilitada por contar con mapeos de generaciones anteriores.
	var antigua: Dictionary = Libros.consultar(&"hm01", perfil, catalogos)
	_check("MO histórica no activada", not antigua.get("disponible", false))
	_check("MO histórica motivo explícito", antigua.get("motivo", "") == "machine_not_in_active_version")
	_check("ID inexistente rechazado", not Libros.consultar(&"libro_inexistente", perfil, catalogos).get("disponible", false))
	var otra_version := perfil.duplicate(true)
	otra_version["active_machine_version"] = "sword-shield"
	_check("Versiones anteriores rechazadas", Libros.consultar(&"tm01", otra_version, catalogos).get("motivo", "") == "machine_profile_rules_pending")
	_check("Catálogo nulo rechazado", Libros.consultar(&"tm01", perfil, null).get("motivo", "") == "catalogo_no_disponible")
	# CAMP_001/02: revisar exclusivamente las máquinas seleccionadas, no los
	# 338 mapeos globales. Los textos solo dependen del tipo y movimiento reales.
	var seleccion := FileAccess.open("res://docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv", FileAccess.READ)
	_check("Alcance de selección legible", seleccion != null)
	if seleccion != null:
		seleccion.get_csv_line() # cabecera: id,nombre_es,familia,procedencia,estado_contenido,...
		var seleccionadas := 0
		var activas := 0
		var heredadas := 0
		var mapa_tipos: Dictionary = {}
		var imagen_perfil := JSON.stringify(perfil)
		while not seleccion.eof_reached():
			var fila: PackedStringArray = seleccion.get_csv_line()
			if fila.size() < 5 or fila[2] != "MACHINE" or fila[4] != "SELECCIONADO":
				continue
			var id_maquina := String(fila[0])
			seleccionadas += 1
			var version_map: Dictionary = filas.get(id_maquina, {})
			var esperado := String(version_map.get("scarlet-violet", ""))
			var descripcion: Dictionary = Libros.presentacion(StringName(id_maquina), perfil, catalogos)
			if esperado.is_empty():
				heredadas += 1
				_check(id_maquina + "/heredada_no_presentada", not descripcion.get("disponible", false)
					and descripcion.get("motivo", "") == "machine_not_in_active_version"
					and not descripcion.has("etiqueta"))
				continue
			activas += 1
			var definicion: MoveDefinition = catalogos.move(StringName(esperado))
			_check(id_maquina + "/movimiento_definido", definicion != null)
			if definicion == null:
				continue
			var original := String(definicion.type_id)
			mapa_tipos[original] = true
			_check(id_maquina + "/movimiento_y_tipo_originales",
				descripcion.get("disponible", false) and descripcion.get("move_id", "") == esperado
				and descripcion.get("type_id", "") == original
				and descripcion.get("clasificacion_tipo", "") == original)
			_check(id_maquina + "/nombre_tipo",
				descripcion.get("nombre_tipo", "") == SpanishGameText.type_name(definicion.type_id))
			_check(id_maquina + "/etiqueta_libro",
				descripcion.get("categoria_presentacion", "") == "LIBRO_MOVIMIENTO"
				and descripcion.get("etiqueta", "") == "Libro de movimiento · " + SpanishGameText.move_name(StringName(esperado), catalogos)
				and not descripcion.has("modelo_arte"))
		seleccion.close()
		_check("248_seleccionadas", seleccionadas == 248)
		_check("229_activas_con_etiqueta", activas == 229)
		_check("19_heredadas_sin_activar", heredadas == 19)
		_check("tipos_observados_no_vacios", not mapa_tipos.is_empty())
		_check("perfil_sin_mutacion_02", JSON.stringify(perfil) == imagen_perfil)
	_probar_ensenanza(perfil, catalogos)
	_fin()


func _fin() -> void:
	print("W05 CAMP_001/03: %d comprobaciones, %d errores" % [comprobaciones, errores.size()])
	quit(0 if errores.is_empty() else 2)


# CAMP_001/03: integración del servicio existente, sin implementar teach de nuevo.
# El adaptador y la prueba no modifican reglas de consumo, inventario ni guardados.
func _instantanea(propietario: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(propietario.party, propietario.storage, propietario.inventory).to_dict())


func _especie_compatible(catalogos: DefinitionCatalog, contenido, movimiento: StringName) -> StringName:
	var opciones: Array[StringName] = [&"mew"]
	opciones.append_array(catalogos.species_catalog.all_ids())
	for id: StringName in opciones:
		if not contenido.species_allowed(String(id)):
			continue
		var especie: CreatureSpecies = catalogos.species(id)
		if especie == null:
			continue
		for entrada: LearnSetEntry in especie.learnset:
			if entrada.method == "machine" and String(entrada.version_group) == "scarlet-violet" and entrada.move_id == movimiento:
				return id
	return &""


func _servicio_para(catalogos: DefinitionCatalog, especie_id: StringName) -> RefCounted:
	var especie: CreatureSpecies = catalogos.species(especie_id)
	_check("03/especie_presente/" + String(especie_id), especie != null)
	if especie == null:
		return null
	var generador := RandomNumberGenerator.new()
	generador.seed = 805
	var criatura: CreatureInstance = CreatureFactory.create(especie, 50, catalogos,
		ProgressionRuleset.new(), generador, {"instance_id": ID_TEST, "moves": ["tackle", "protect"]})
	_check("03/creatura_creada/" + String(especie_id), criatura != null)
	if criatura == null:
		return null
	var propietario := PlayerCollection.new()
	var agregada: bool = propietario.party.add_creature(criatura)
	_check("03/propiedad/" + String(especie_id), agregada)
	if not agregada:
		return null
	var servicio := Servicio.new()
	var configurado: bool = servicio.configure(propietario, catalogos, func(): return not acceso_bloqueado)
	_check("03/configuracion/" + String(especie_id), configurado)
	return servicio if configurado else null


func _probar_ensenanza(perfil: Dictionary, catalogos: DefinitionCatalog) -> void:
	var contenido := Contenido.new()
	_check("03/politica_cargada", contenido.load_local())
	if not contenido.valid:
		return
	var casos := ["tm01", "tm02", "tm77"]
	for id: String in casos:
		var libro: Dictionary = Libros.presentacion(StringName(id), perfil, catalogos)
		_check("03/libro_activo/" + id, libro.get("disponible", false))
		if not libro.get("disponible", false):
			continue
		var movimiento := StringName(libro.get("move_id", ""))
		_check("03/movimiento_aprendible/" + id, contenido.move_learnable(String(movimiento)))
		if not contenido.move_learnable(String(movimiento)):
			continue
		var especie_id := _especie_compatible(catalogos, contenido, movimiento)
		_check("03/especie_compatible/" + id, especie_id != &"")
		if especie_id == &"":
			continue
		var servicio := _servicio_para(catalogos, especie_id)
		if servicio == null:
			continue
		var original: CreatureInstance = servicio.owner.owned_creature(ID_TEST)
		original.moveset.clear()
		original.move_ids.clear()
		_check("03/perfil_servicio/" + id, servicio.machine_move(StringName(id)) == movimiento)
		var sin_stock := _instantanea(servicio.owner)
		var rechazo: Dictionary = servicio.teach(StringName(id), ID_TEST)
		_check("03/sin_stock_no_consumir/" + id, not rechazo.get("accepted", false)
			and rechazo.get("reason", "") == "item_not_owned" and _instantanea(servicio.owner) == sin_stock)
		_check("03/agrega_dos/" + id, servicio.owner.inventory.add(StringName(id), 2))
		var antes := _instantanea(servicio.owner)
		var ajeno: Dictionary = servicio.teach(StringName(id), &"w05_no_propietario")
		_check("03/ajeno_no_muta/" + id, not ajeno.get("accepted", false)
			and ajeno.get("reason", "") == "creature_not_owned" and _instantanea(servicio.owner) == antes)
		acceso_bloqueado = true
		var bloqueado: Dictionary = servicio.teach(StringName(id), ID_TEST)
		acceso_bloqueado = false
		_check("03/bloqueo_no_muta/" + id, not bloqueado.get("accepted", false)
			and bloqueado.get("reason", "") == "field_locked" and _instantanea(servicio.owner) == antes)
		var resultado: Dictionary = servicio.teach(StringName(id), ID_TEST)
		var actual: CreatureInstance = servicio.owner.owned_creature(ID_TEST)
		_check("03/ensenanza_real/" + id, resultado.get("accepted", false) and resultado.get("action", "") == "teach"
			and resultado.get("move_id", "") == String(movimiento) and resultado.get("version", "") == "scarlet-violet")
		_check("03/consumo_unico/" + id, servicio.owner.inventory.quantity(StringName(id)) == 1)
		_check("03/identidad_conservada/" + id, actual != null and actual.instance_id == ID_TEST
			and servicio.owner.location_of(ID_TEST) == &"PARTY")
		if actual != null:
			var aprendido: BattleMoveSlot = actual.move_slot(movimiento)
			var definicion: MoveDefinition = catalogos.move(movimiento)
			_check("03/movimiento_correcto/" + id, aprendido != null and actual.moveset.size() == 1)
			_check("03/pp_correctos/" + id, aprendido != null and definicion != null
				and aprendido.current_pp == definicion.pp and aprendido.max_pp == definicion.pp)
		var tras_aprender := _instantanea(servicio.owner)
		var repetido: Dictionary = servicio.teach(StringName(id), ID_TEST)
		_check("03/repetido_sin_gasto/" + id, not repetido.get("accepted", false)
			and repetido.get("reason", "") == "move_already_known" and _instantanea(servicio.owner) == tras_aprender)
		if id == "tm01" and resultado.get("accepted", false):
			_probar_persistencia(servicio.owner, movimiento, catalogos)

	# Todas las heredadas del catálogo seleccionado deben conservar stock y Pokémon.
	var archivo := FileAccess.open("res://docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv", FileAccess.READ)
	_check("03/catalogo_legacy_legible", archivo != null)
	if archivo == null:
		return
	archivo.get_csv_line()
	var heredadas := 0
	var servicio_legacy := _servicio_para(catalogos, &"mew")
	if servicio_legacy == null:
		archivo.close()
		return
	while not archivo.eof_reached():
		var fila: PackedStringArray = archivo.get_csv_line()
		if fila.size() < 5 or fila[2] != "MACHINE" or fila[4] != "SELECCIONADO":
			continue
		var id := String(fila[0])
		var por_version: Dictionary = perfil.get("machine_rows", {}).get(id, {})
		if not String(por_version.get("scarlet-violet", "")).is_empty():
			continue
		heredadas += 1
		_check("03/stock_legacy/" + id, servicio_legacy.owner.inventory.add(StringName(id)))
		var antes := _instantanea(servicio_legacy.owner)
		var denegado: Dictionary = servicio_legacy.teach(StringName(id), ID_TEST)
		_check("03/legacy_rechazada/" + id, not denegado.get("accepted", false)
			and denegado.get("reason", "") == "machine_not_in_active_version"
			and _instantanea(servicio_legacy.owner) == antes)
		_check("03/legacy_sin_mapeo_activo/" + id,
			servicio_legacy.machine_move(StringName(id)) == &""
			and not Libros.presentacion(StringName(id), perfil, catalogos).get("disponible", false))
	archivo.close()
	_check("03/19_heredadas_rechazadas", heredadas == 19)
	# Una única implementación de reglas de enseñanza y gasto: FieldItemService.teach.
	_check("03/servicio_unico", Servicio.PROFILE == "res://modules/inventory/item_connections_v1.json")


func _probar_persistencia(propietario: PlayerCollection, movimiento: StringName, catalogos: DefinitionCatalog) -> void:
	var ruta := "user://w05_machine_books_camp001_test_only.json"
	var repositorio := SaveGameRepository.new()
	var resultado: SaveResult = repositorio.save_collection(ruta, propietario)
	_check("03/guardado_test_exitoso", resultado.ok)
	if resultado.ok:
		var cargado: LoadResult = repositorio.load(ruta)
		_check("03/carga_test_exitosa", cargado.ok)
		if cargado.ok:
			var criatura: CreatureInstance = cargado.party.get_creature(ID_TEST)
			var mov: BattleMoveSlot = criatura.move_slot(movimiento) if criatura != null else null
			var definicion: MoveDefinition = catalogos.move(movimiento)
			_check("03/persistencia_movimiento_y_pp", criatura != null and mov != null
				and definicion != null and mov.current_pp == definicion.pp)
			_check("03/persistencia_stock", cargado.inventory.quantity(&"tm01") == 1)
			_check("03/persistencia_propiedad", cargado.party.get_creature(ID_TEST) != null
				and cargado.storage.get_creature(ID_TEST) == null)
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
