extends SceneTree

# IA5/W05 CAMP_002 ITER_02: ensena seis MT nuevas con FieldItemService.teach.
# Sin alterar servicio, datos, seleccion, partidas ni otros tests.
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const Contenido = preload("res://modules/gameplay/randomlock_content_policy.gd")
const FIXTURE := "res://tests/fixtures/parallel_items/w05_campaign_002.json"
const DATA := "res://data/normalized/pokemon_api.json"
const REPORTE := "user://w05_camp002_iter02_reporte.json"
const GUARDADO := "user://w05_camp002_iter02_temporal.json"
const ID_TEST := &"w05_camp002_pokemon"
var checks := 0
var errores: Array[String] = []
var filas: Array[Dictionary] = []
var catalogos: DefinitionCatalog
var contenido := Contenido.new()


func _initialize() -> void:
	call_deferred("_ejecutar")


func verificar(nombre: String, condicion: bool) -> void:
	checks += 1
	if not condicion:
		errores.append(nombre)
		push_error("W05 CAMP002 ITER02: " + nombre)


func instantanea(dueno: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(dueno.party, dueno.storage, dueno.inventory).to_dict())


func compatible(especie: CreatureSpecies, movimiento: StringName) -> bool:
	if especie == null:
		return false
	for entrada: LearnSetEntry in especie.learnset:
		if entrada.method == "machine" and String(entrada.version_group) == "scarlet-violet" and entrada.move_id == movimiento:
			return true
	return false


func escoger_parejas(fixture: Dictionary, perfil: Dictionary) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var elegidos := {}
	for candidato: Dictionary in fixture.sample.candidates:
		var id := String(candidato.item_id)
		if ["tm01", "tm02", "tm77"].has(id) or elegidos.has(id):
			continue
		var movimiento := String(perfil.get("machine_rows", {}).get(id, {}).get("scarlet-violet", ""))
		verificar(id + "/mapeo_sin_derivar_por_numero", movimiento == String(candidato.move_id))
		if movimiento != String(candidato.move_id) or not contenido.move_learnable(movimiento):
			continue
		var definicion: MoveDefinition = catalogos.move(StringName(movimiento))
		if definicion == null:
			continue
		verificar(id + "/tipo_fuente", String(definicion.type_id) == String(candidato.type_id))
		if String(definicion.type_id) != String(candidato.type_id):
			continue
		var especies: Array[String] = []
		for especie_id: StringName in catalogos.species_catalog.all_ids():
			if contenido.species_allowed(String(especie_id)) and compatible(catalogos.species(especie_id), StringName(movimiento)):
				especies.append(String(especie_id))
		especies.sort()
		if especies.is_empty():
			continue
		elegidos[id] = true
		resultado.append({"item_id": id, "move_id": movimiento, "species_id": especies[0]})
		if resultado.size() == 6:
			break
	return resultado


func servicio_para(especie_id: StringName) -> RefCounted:
	var especie: CreatureSpecies = catalogos.species(especie_id)
	verificar("especie_en_catalogo/" + String(especie_id), especie != null)
	if especie == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261102
	var pokemon: CreatureInstance = CreatureFactory.create(especie, 50, catalogos,
		ProgressionRuleset.new(), rng, {"instance_id": ID_TEST, "moves": ["tackle", "protect"]})
	verificar("creacion/" + String(especie_id), pokemon != null)
	if pokemon == null:
		return null
	pokemon.moveset.clear()
	pokemon.move_ids.clear()
	var dueno := PlayerCollection.new()
	verificar("alta_en_equipo/" + String(especie_id), dueno.party.add_creature(pokemon))
	var servicio := Servicio.new()
	verificar("configuracion/" + String(especie_id), servicio.configure(dueno, catalogos, func(): return true))
	return servicio


func _caso(par: Dictionary) -> void:
	var id := StringName(par.item_id)
	var movimiento := StringName(par.move_id)
	var especie := StringName(par.species_id)
	var errores_antes := errores.size()
	var servicio := servicio_para(especie)
	if servicio == null:
		filas.append({"item_id": String(id), "status": "FAIL", "reason": "service_not_constructed"})
		return
	var dueno: PlayerCollection = servicio.owner
	verificar(String(id) + "/mapeo_servicio", servicio.machine_move(id) == movimiento)
	verificar(String(id) + "/compatibilidad", compatible(catalogos.species(especie), movimiento))
	var sin_stock := instantanea(dueno)
	var rechazo: Dictionary = servicio.teach(id, ID_TEST)
	verificar(String(id) + "/sin_stock", not rechazo.get("accepted", false)
		and rechazo.get("reason", "") == "item_not_owned" and instantanea(dueno) == sin_stock)
	verificar(String(id) + "/stock_dos", dueno.inventory.add(id, 2))
	var antes := instantanea(dueno)
	rechazo = servicio.teach(id, &"w05_ajeno")
	verificar(String(id) + "/sin_propiedad", not rechazo.get("accepted", false)
		and rechazo.get("reason", "") == "creature_not_owned" and instantanea(dueno) == antes)
	# Un ejemplar propio de otra especie con contexto SV pero sin este movimiento.
	# La imposibilidad de hallar un negativo compatible en version se comunica como fallo.
	var no_compatible := &""
	for especie_id: StringName in catalogos.species_catalog.all_ids():
		if not contenido.species_allowed(String(especie_id)):
			continue
		var candidata: CreatureSpecies = catalogos.species(especie_id)
		if candidata == null or compatible(candidata, movimiento):
			continue
		var tiene_sv := false
		for entrada: LearnSetEntry in candidata.learnset:
			if entrada.method == "machine" and String(entrada.version_group) == "scarlet-violet":
				tiene_sv = true
				break
		if tiene_sv:
			no_compatible = especie_id
			break
	verificar(String(id) + "/negativo_disponible", no_compatible != &"")
	if no_compatible != &"":
		var ajeno := servicio_para(no_compatible)
		if ajeno != null:
			verificar(String(id) + "/stock_incompatible", ajeno.owner.inventory.add(id, 2))
			var estado := instantanea(ajeno.owner)
			rechazo = ajeno.teach(id, ID_TEST)
			verificar(String(id) + "/incompatible", not rechazo.get("accepted", false)
				and rechazo.get("reason", "") == "machine_incompatible"
				and instantanea(ajeno.owner) == estado)
	var resultado: Dictionary = servicio.teach(id, ID_TEST)
	var actual: CreatureInstance = dueno.owned_creature(ID_TEST)
	verificar(String(id) + "/teach_real", resultado.get("accepted", false)
		and resultado.get("action", "") == "teach" and resultado.get("move_id", "") == String(movimiento))
	verificar(String(id) + "/consumo_2_a_1", dueno.inventory.quantity(id) == 1)
	verificar(String(id) + "/propiedad_e_identidad", actual != null
		and actual.instance_id == ID_TEST and dueno.location_of(ID_TEST) == &"PARTY")
	if actual != null:
		var slot: BattleMoveSlot = actual.move_slot(movimiento)
		var definicion: MoveDefinition = catalogos.move(movimiento)
		verificar(String(id) + "/pp_max_y_actual", slot != null and definicion != null
			and slot.current_pp == definicion.pp and slot.max_pp == definicion.pp)
	var despues := instantanea(dueno)
	rechazo = servicio.teach(id, ID_TEST)
	verificar(String(id) + "/repeticion_sin_consumo", not rechazo.get("accepted", false)
		and rechazo.get("reason", "") == "move_already_known" and instantanea(dueno) == despues)
	# Persistencia real de coleccion SaveV2, ruta temporal y limpieza obligatoria.
	var repositorio := SaveGameRepository.new()
	var guardado: SaveResult = repositorio.save_collection(GUARDADO, dueno)
	verificar(String(id) + "/save_v2", guardado.ok)
	if guardado.ok:
		var carga: LoadResult = repositorio.load(GUARDADO)
		verificar(String(id) + "/load_v2", carga.ok)
		if carga.ok:
			var restaurado: CreatureInstance = carga.party.get_creature(ID_TEST)
			var slot_cargado: BattleMoveSlot = restaurado.move_slot(movimiento) if restaurado != null else null
			verificar(String(id) + "/persistencia_instancia", restaurado != null
				and restaurado.instance_id == ID_TEST and carga.storage.get_creature(ID_TEST) == null)
			verificar(String(id) + "/persistencia_movimiento_pp", slot_cargado != null
				and slot_cargado.current_pp == catalogos.move(movimiento).pp
				and slot_cargado.max_pp == catalogos.move(movimiento).pp)
			verificar(String(id) + "/persistencia_stock", carga.inventory.quantity(id) == 1)
	for sufijo: String in ["", ".tmp", ".bak"]:
		var ruta := GUARDADO + sufijo
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	filas.append({"item_id": String(id), "move_id": String(movimiento),
		"species_id": String(especie), "status": "PASS" if errores.size() == errores_antes else "FAIL"})


func _ejecutar() -> void:
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var dataset: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var perfil: Variant = JSON.parse_string(FileAccess.get_file_as_string(Servicio.PROFILE))
	verificar("fixture_valido", fixture is Dictionary)
	verificar("dataset_valido", dataset is Dictionary)
	verificar("perfil_valido", perfil is Dictionary)
	if fixture is Dictionary and dataset is Dictionary and perfil is Dictionary:
		verificar("campana_correcta", fixture.get("campaign", "") == "CAMP_002_W05")
		verificar("version_scarlet_violet", perfil.get("active_machine_version", "") == "scarlet-violet")
		verificar("politica_cargada", contenido.load_local())
		catalogos = GameData.from_dict(dataset).to_definition_catalog()
		if contenido.valid and catalogos != null:
			var parejas := escoger_parejas(fixture, perfil)
			verificar("seis_parejas_distintas", parejas.size() == 6)
			for par: Dictionary in parejas:
				_caso(par)
			verificar("seis_casos_ejecutados", filas.size() == 6)
	var informe := {"campaign": "CAMP_002_W05", "iteration": 2,
		"status": "PASS" if errores.is_empty() else "FAIL",
		"checks": checks, "errors": errores, "cases": filas,
		"scope": "6_MT_NUEVAS_FIELD_ITEM_SERVICE_TEACH", "gpu_tested": false}
	var archivo := FileAccess.open(REPORTE, FileAccess.WRITE)
	verificar("reporte_escribible", archivo != null)
	if archivo != null:
		informe["status"] = "PASS" if errores.is_empty() else "FAIL"
		informe["checks"] = checks
		informe["errors"] = errores
		archivo.store_string(JSON.stringify(informe, "  "))
		archivo.close()
	print("W05_CAMP002_ITER02 ", informe.status, " checks=", checks, " cases=", filas.size())
	quit(0 if errores.is_empty() else 2)
