extends SceneTree

# IA5/W05 CAMP_002 ITER_03: doce MT nuevas y 19 negativos legacy.
# Mantiene regresion de ITER_02 y el servicio nativo de ensenanza.
# Sin alterar servicio, datos, seleccion, partidas ni otros tests.
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const Contenido = preload("res://modules/gameplay/randomlock_content_policy.gd")
const FIXTURE := "res://tests/fixtures/parallel_items/w05_campaign_002.json"
const DATA := "res://data/normalized/pokemon_api.json"
const REPORTE := "user://w05_camp002_iter03_reporte.json"
const GUARDADO := "user://w05_camp002_iter03_temporal.json"
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
		push_error("W05 CAMP002 ITER03: " + nombre)


func instantanea(dueno: PlayerCollection) -> String:
	return JSON.stringify(SaveGameData.build(dueno.party, dueno.storage, dueno.inventory).to_dict())


func compatible(especie: CreatureSpecies, movimiento: StringName) -> bool:
	if especie == null:
		return false
	for entrada: LearnSetEntry in especie.learnset:
		if entrada.method == "machine" and String(entrada.version_group) == "scarlet-violet" and entrada.move_id == movimiento:
			return true
	return false


func leer_seleccion() -> Dictionary:
	var ids := {}
	var archivo := FileAccess.open("res://docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv", FileAccess.READ)
	verificar("csv_seleccion_legible", archivo != null)
	if archivo == null:
		return ids
	archivo.get_csv_line()
	while not archivo.eof_reached():
		var fila: PackedStringArray = archivo.get_csv_line()
		if fila.size() < 5 or fila[2] != "MACHINE" or fila[4] != "SELECCIONADO":
			continue
		var item_id := String(fila[0])
		verificar(item_id + "/no_duplicado_en_seleccion", not ids.has(item_id))
		ids[item_id] = true
	archivo.close()
	verificar("censo_248_seleccionadas", ids.size() == 248)
	return ids


func escoger_parejas(fixture: Dictionary, perfil: Dictionary, dataset: Dictionary,
		seleccion: Dictionary) -> Array[Dictionary]:
	# Orden determinista identico al selector Python: fixture y despues
	# restantes activas por tipo, clase e ID; nunca habilitar legacy.
	var candidaturas: Array[Dictionary] = []
	var usados := {}
	for candidato: Dictionary in fixture.sample.candidates:
		candidaturas.append(candidato)
		usados[String(candidato.item_id)] = true
	var adicionales: Array[Dictionary] = []
	var mapa: Dictionary = perfil.get("machine_rows", {})
	var movimientos: Dictionary = dataset.get("moves", {})
	for id: String in mapa:
		if usados.has(id) or not seleccion.has(id):
			continue
		var mov := String(mapa[id].get("scarlet-violet", ""))
		if mov.is_empty() or not movimientos.has(mov):
			continue
		var m: Dictionary = movimientos[mov]
		adicionales.append({"item_id": id, "move_id": mov,
			"type_id": String(m.get("type_id", "")),
			"damage_class": String(m.get("damage_class", ""))})
	adicionales.sort_custom(func(a: Dictionary, b: Dictionary):
		var clave_a: String = String(a.type_id) + "|" + String(a.damage_class) + "|" + String(a.item_id)
		var clave_b: String = String(b.type_id) + "|" + String(b.damage_class) + "|" + String(b.item_id)
		return clave_a < clave_b)
	candidaturas.append_array(adicionales)
	var elegidos := {}
	var resultado: Array[Dictionary] = []
	for candidato: Dictionary in candidaturas:
		var id := String(candidato.item_id)
		if fixture.sample.exclude_already_tested.has(id) or elegidos.has(id):
			continue
		if not seleccion.has(id):
			verificar(id + "/fuera_de_seleccion", false)
			continue
		var movimiento := String(mapa.get(id, {}).get("scarlet-violet", ""))
		verificar(id + "/mapeo_sin_derivar_por_numero", movimiento == String(candidato.move_id))
		if movimiento != String(candidato.move_id) or not contenido.move_learnable(movimiento):
			continue
		if not movimientos.has(movimiento):
			verificar(id + "/movimiento_en_datos", false)
			continue
		var bruto: Dictionary = movimientos[movimiento]
		var definicion: MoveDefinition = catalogos.move(StringName(movimiento))
		if definicion == null:
			verificar(id + "/movimiento_en_catalogo", false)
			continue
		verificar(id + "/tipo_fuente", String(definicion.type_id) == String(candidato.type_id)
			and String(bruto.get("type_id", "")) == String(candidato.type_id))
		verificar(id + "/clase_fuente", String(bruto.get("damage_class", "")) == String(candidato.damage_class))
		if String(definicion.type_id) != String(candidato.type_id) or String(bruto.get("damage_class", "")) != String(candidato.damage_class):
			continue
		var especies: Array[String] = []
		for especie_id: StringName in catalogos.species_catalog.all_ids():
			if contenido.species_allowed(String(especie_id)) and compatible(catalogos.species(especie_id), StringName(movimiento)):
				especies.append(String(especie_id))
		especies.sort()
		if especies.is_empty():
			continue
		elegidos[id] = true
		resultado.append({"item_id": id, "move_id": movimiento,
			"species_id": especies[0], "type_id": String(candidato.type_id)})
		if resultado.size() == 12:
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


func verificar_cobertura_y_legadas(perfil: Dictionary, seleccion: Dictionary,
		parejas: Array[Dictionary]) -> Dictionary:
	var ids_probados := {}
	for par: Dictionary in parejas:
		var id := String(par.item_id)
		verificar(id + "/sin_duplicados_muestra", not ids_probados.has(id))
		ids_probados[id] = true
	var probadas: Array[String] = []
	var solo_metadatos: Array[String] = []
	var legadas: Array[String] = []
	for id: String in seleccion:
		var por_version: Dictionary = perfil.get("machine_rows", {}).get(id, {})
		if String(por_version.get("scarlet-violet", "")).is_empty():
			legadas.append(id)
			verificar(id + "/legacy_fuera_muestra", not ids_probados.has(id))
		elif ids_probados.has(id):
			probadas.append(id)
		else:
			solo_metadatos.append(id)
	probadas.sort()
	solo_metadatos.sort()
	legadas.sort()
	verificar("12_probado_en_ensenanza", probadas.size() == 12)
	verificar("217_solo_metadatos", solo_metadatos.size() == 217)
	verificar("19_legacy_sin_activar", legadas.size() == 19)
	verificar("censo_248_sin_perdidas",
		probadas.size() + solo_metadatos.size() + legadas.size() == 248)
	# Reutilizar el servicio real, como en CAMP_001; solo negativos, sin
	# reimplementar sus reglas ni 248 pruebas individuales.
	if not legadas.is_empty():
		var servicio := servicio_para(&"mew")
		if servicio == null:
			verificar("servicio_legacy_disponible", false)
		else:
			for id: String in legadas:
				var id_mt := StringName(id)
				verificar(id + "/legacy_stock", servicio.owner.inventory.add(id_mt))
				var antes := instantanea(servicio.owner)
				var rechazo: Dictionary = servicio.teach(id_mt, ID_TEST)
				verificar(id + "/legacy_rechazo", not rechazo.get("accepted", false)
					and rechazo.get("reason", "") == "machine_not_in_active_version"
					and instantanea(servicio.owner) == antes)
				verificar(id + "/legacy_sin_movimiento_activo", servicio.machine_move(id_mt) == &"")
	return {"probado_en_ensenanza": probadas, "solo_metadatos": solo_metadatos,
		"legacy_negativos": legadas, "total_activas": probadas.size() + solo_metadatos.size(),
		"ensayadas": probadas.size(), "solo_metadatos_count": solo_metadatos.size(),
		"legacy_count": legadas.size()}

func _ejecutar() -> void:
	var cobertura: Dictionary = {}
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
			var seleccion := leer_seleccion()
			var parejas := escoger_parejas(fixture, perfil, dataset, seleccion)
			verificar("doce_parejas_distintas", parejas.size() == 12)
			for par: Dictionary in parejas:
				_caso(par)
			verificar("doce_casos_ejecutados", filas.size() == 12)
			cobertura = verificar_cobertura_y_legadas(perfil, seleccion, parejas)
	var informe := {"campaign": "CAMP_002_W05", "iteration": 3,
		"status": "PASS" if errores.is_empty() else "FAIL",
		"checks": checks, "errors": errores, "cases": filas, "coverage_matrix": cobertura,
		"scope": "12_MT_NUEVAS_Y_19_LEGACY_NEGATIVOS", "gpu_tested": false}
	var archivo := FileAccess.open(REPORTE, FileAccess.WRITE)
	verificar("reporte_escribible", archivo != null)
	if archivo != null:
		informe["status"] = "PASS" if errores.is_empty() else "FAIL"
		informe["checks"] = checks
		informe["errors"] = errores
		archivo.store_string(JSON.stringify(informe, "  "))
		archivo.close()
	print("W05_CAMP002_ITER03 ", informe.status, " checks=", checks, " cases=", filas.size())
	quit(0 if errores.is_empty() else 2)
