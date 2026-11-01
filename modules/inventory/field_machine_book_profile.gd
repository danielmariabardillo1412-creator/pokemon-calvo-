extends RefCounted

# CAMP_001_W05 / microbloque 01: consulta pura para libros de movimientos.
# No habilita máquinas, no consulta ni modifica mochila, criaturas o guardados.
# Las reglas de aprendizaje y consumo siguen exclusivamente en FieldItemService.teach().
const VERSION_ACTIVA := "scarlet-violet"
const PERFIL_ID := "calvo_item_connections_v1"


static func _rechazo(item_id: StringName, motivo: String) -> Dictionary:
	return {"disponible": false, "estado": "NO_DISPONIBLE",
		"item_id": String(item_id), "motivo": motivo}


# Acepta el perfil ya cargado por FieldItemService y el catálogo de definiciones.
# Una consulta exitosa NO garantiza compatibilidad de especie ni autorización de uso.
static func consultar(item_id: StringName, perfil: Dictionary, catalogos: DefinitionCatalog) -> Dictionary:
	if catalogos == null:
		return _rechazo(item_id, "catalogo_no_disponible")
	if perfil.get("schema_version") != 1 or perfil.get("profile_id") != PERFIL_ID:
		return _rechazo(item_id, "perfil_maquinas_invalido")
	var versiones_maquinas: Variant = perfil.get("machine_rows")
	if not versiones_maquinas is Dictionary:
		return _rechazo(item_id, "perfil_maquinas_invalido")
	var version: Variant = perfil.get("active_machine_version", "")
	# No adjudicar reglas ni consumo de MT a ningún perfil histórico.
	if version != VERSION_ACTIVA:
		return _rechazo(item_id, "machine_profile_rules_pending")
	var id := String(item_id)
	var versiones: Variant = versiones_maquinas.get(id)
	if not versiones is Dictionary:
		return _rechazo(item_id, "not_a_machine")
	var movimiento: Variant = versiones.get(String(version), "")
	if not movimiento is String or String(movimiento).is_empty():
		return _rechazo(item_id, "machine_not_in_active_version")
	# El mapa activo no convierte un objeto ausente del catálogo en uno jugable.
	if catalogos.item(item_id) == null:
		return _rechazo(item_id, "item_not_in_catalog")
	var definicion: MoveDefinition = catalogos.move(StringName(movimiento))
	if definicion == null:
		return _rechazo(item_id, "move_not_in_catalog")
	var tipo: StringName = definicion.type_id
	if tipo == &"" or catalogos.type(tipo) == null:
		return _rechazo(item_id, "move_type_not_in_catalog")
	return {"disponible": true, "estado": "ACTIVA", "item_id": id,
		"move_id": String(movimiento), "type_id": String(tipo),
		"version": String(version)}
