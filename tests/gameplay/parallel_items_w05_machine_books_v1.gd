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
	_fin()


func _fin() -> void:
	print("W05 CAMP_001/01: %d comprobaciones, %d errores" % [comprobaciones, errores.size()])
	quit(0 if errores.is_empty() else 2)
