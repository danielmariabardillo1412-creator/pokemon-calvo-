extends SceneTree

# W05 CAMP_001/01: prueba de lectura del adaptador de libros de movimientos.
# Solo consulta el perfil canónico, sin modificar aprendizaje, inventario ni guardados.
const Libros = preload("res://modules/inventory/field_machine_book_profile.gd")
const PERFIL = "res://modules/inventory/item_connections_v1.json"
const DATOS = "res://data/normalized/pokemon_api.json"
var comprobaciones := 0
var errores: Array[String] = []


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
	_fin()


func _fin() -> void:
	print("W05 CAMP_001/01: %d comprobaciones, %d errores" % [comprobaciones, errores.size()])
	quit(0 if errores.is_empty() else 2)
