extends SceneTree
const Servicio = preload("res://modules/inventory/field_item_service.gd")
const BLOQUE_01 := [&"dawn_stone", &"dusk_stone", &"shiny_stone"]
const BLOQUE_02 := [&"sun_stone", &"oval_stone", &"black_augurite"]
const BLOQUE_03 := [&"dragon_scale", &"dubious_disc", &"electirizer"]
const BLOQUE_04 := [&"magmarizer", &"protector", &"reaper_cloth"]
const BLOQUE_05 := [&"prism_scale", &"sachet", &"up_grade"]
const BLOQUE_06 := [&"auspicious_armor", &"malicious_armor", &"metal_alloy"]
const ID := &"w04_c003_01"
var checks := 0
var fallos: Array[String] = []
var cerrado := false

func _initialize() -> void:
	create_timer(110.0).timeout.connect(func():
		if not cerrado:
			validar(false, "timeout")
			terminar())
	call_deferred("_ejecutar")

func validar(ok: bool, nombre: String) -> void:
	checks += 1
	if not ok:
		fallos.append(nombre)
		push_error(nombre)

func _crear(catalogo: DefinitionCatalog, origen: StringName) -> PlayerCollection:
	var sp := catalogo.species(origen)
	if sp == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261103
	var poke := CreatureFactory.create(sp, 40, catalogo, ProgressionRuleset.new(), rng, {"instance_id": ID, "nature_id": &"hardy", "moves": ["tackle", "protect"]})
	var pc := PlayerCollection.new()
	if not pc.party.add_creature(poke):
		return null
	return pc

func _ejecutar() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not data is Dictionary:
		validar(false, "catalogo_no_disponible")
		terminar()
		return
	var catalogo: DefinitionCatalog = GameData.from_dict(data).to_definition_catalog()
	for item: StringName in BLOQUE_01 + BLOQUE_02 + BLOQUE_03 + BLOQUE_04 + BLOQUE_05 + BLOQUE_06:
		var compatibles: Array[Dictionary] = []
		var dependientes := 0
		var primer_dependiente: Dictionary = {}
		for sid: StringName in catalogo.species_catalog.all_ids():
			var sp: CreatureSpecies = catalogo.species(sid)
			for rec: EvolutionRecord in sp.evolutions:
				if rec.item_id != item:
					continue
				if rec.trigger == EvolutionSystem.TRIGGER_USE_ITEM and EvolutionSystem.classify_record(rec, catalogo, sid) == EvolutionSystem.RUNTIME_SUPPORTED:
					compatibles.append({"source": sid, "target": rec.species_id})
				else:
					dependientes += 1
					if primer_dependiente.is_empty():
						primer_dependiente = {"source": sid, "target": rec.species_id, "trigger": String(rec.trigger), "classification": EvolutionSystem.classify_record(rec, catalogo, sid)}
		validar(catalogo.item(item) != null, String(item) + "/objeto_catalogado")
		if compatibles.is_empty() and dependientes == 0:
			print("CAMP003_W04_DEPENDENCIA item=", String(item), " reason=sin_regla_catalogada")
		if compatibles.is_empty():
			print("CAMP003_W04_DEPENDENCIA item=", String(item), " records=", dependientes, " example=", JSON.stringify(primer_dependiente))
			if (item in BLOQUE_03 or item in BLOQUE_04 or item in BLOQUE_05 or item in BLOQUE_06) and not primer_dependiente.is_empty():
				var propietario_condicionado := _crear(catalogo, primer_dependiente.source as StringName)
				validar(propietario_condicionado != null, String(item) + "/creacion_condicionada")
				if propietario_condicionado != null:
					var servicio_condicionado := Servicio.new()
					validar(servicio_condicionado.configure(propietario_condicionado, catalogo, func(): return true), String(item) + "/configuracion_condicionada")
					validar(propietario_condicionado.inventory.add(item, 2), String(item) + "/stock_condicionado")
					var antes_condicionado := JSON.stringify(SaveGameData.build(propietario_condicionado.party, propietario_condicionado.storage, propietario_condicionado.inventory).to_dict())
					var opciones_condicionadas := servicio_condicionado.evolution_options(item, ID)
					var intento_condicionado: Dictionary = servicio_condicionado.evolve(item, ID, primer_dependiente.target as StringName)
					validar(opciones_condicionadas.is_empty() and not intento_condicionado.get("accepted", false) and propietario_condicionado.inventory.quantity(item) == 2 and JSON.stringify(SaveGameData.build(propietario_condicionado.party, propietario_condicionado.storage, propietario_condicionado.inventory).to_dict()) == antes_condicionado, String(item) + "/intercambio_no_degradado_a_uso_directo")
			continue
		var elegido: Dictionary = compatibles[0]
		var pc := _crear(catalogo, elegido.source as StringName)
		validar(pc != null, String(item) + "/creacion")
		if pc == null:
			continue
		var servicio := Servicio.new()
		validar(servicio.configure(pc, catalogo, func(): return true), String(item) + "/configurar")
		var destino: StringName = elegido.target
		var opciones := servicio.evolution_options(item, ID)
		validar(opciones.has(destino), String(item) + "/elegibilidad")
		validar(pc.inventory.add(item, 2), String(item) + "/inventario")
		var previo := JSON.stringify(SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict())
		var ajeno: Dictionary = servicio.evolve(item, &"id_ajeno", destino)
		validar(not ajeno.get("accepted", false) and JSON.stringify(SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict()) == previo, String(item) + "/rechazo_ajeno")
		var falso: Dictionary = servicio.evolve(item, ID, &"mewtwo")
		validar(not falso.get("accepted", false) and JSON.stringify(SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict()) == previo, String(item) + "/rechazo_destino")
		var original: CreatureInstance = pc.owned_creature(ID)
		var iv := original.ivs.duplicate(true)
		var ev := original.evs.duplicate(true)
		var exp := original.experience
		var amistad := original.friendship
		var mov := original.move_ids.duplicate()
		var exito: Dictionary = servicio.evolve(item, ID, destino)
		var nuevo: CreatureInstance = pc.owned_creature(ID)
		validar(exito.get("accepted", false) and nuevo != null and nuevo.species_id == destino and pc.inventory.quantity(item) == 1, String(item) + "/evolucion_consumo")
		if nuevo == null:
			continue
		validar(nuevo.instance_id == ID and nuevo.ivs == iv and nuevo.evs == ev and nuevo.experience == exp and nuevo.friendship == amistad and nuevo.move_ids == mov, String(item) + "/identidad_atributos")
		var despues := JSON.stringify(SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict())
		var segunda: Dictionary = servicio.evolve(item, ID, destino)
		validar(not segunda.get("accepted", false) and JSON.stringify(SaveGameData.build(pc.party, pc.storage, pc.inventory).to_dict()) == despues, String(item) + "/sin_segundo_consumo")
		var repo := SaveGameRepository.new()
		var ruta := "user://w04_camp003_" + String(item) + "_test.json"
		var guardado: SaveResult = repo.save_collection(ruta, pc)
		validar(guardado.ok, String(item) + "/guardar")
		if guardado.ok:
			var cargado: LoadResult = repo.load(ruta)
			validar(cargado.ok and cargado.schema_version == 2, String(item) + "/recargar")
			if cargado.ok:
				validar(cargado.inventory.quantity(item) == 1 and cargado.party.get_creature(ID) != null and cargado.party.get_creature(ID).species_id == destino, String(item) + "/persistencia")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
		print("CAMP003_W04_VERIFICADO item=", String(item), " source=", String(elegido.source), " target=", String(destino))
	terminar()

func terminar() -> void:
	if cerrado:
		return
	cerrado = true
	if fallos.is_empty():
		print("CAMP003_W04_GODOT PASS blocks=6 checks=", checks)
	else:
		print("CAMP003_W04_GODOT FAIL errors=", JSON.stringify(fallos))
	quit(0 if fallos.is_empty() else 1)
