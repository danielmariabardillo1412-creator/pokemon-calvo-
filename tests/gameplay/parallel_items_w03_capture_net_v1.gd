extends "res://tests/gameplay/item_capture_v11.gd"

# W03 / LOTE_002: caracterización de captura, sin alterar producción.
# PASS aquí significa que la frontera ACTUAL y los controles funcionan;
# NO implica que net_ball esté conectada. --require-net exige el contrato futuro.
const W03_PATH := "user://parallel_items_w03_capture_net_v1.json"
const EXPECTED_NET_FACTOR := 3.5
const CASES := [
	{"species": &"magikarp", "type": &"water", "factor": 3.5},
	{"species": &"caterpie", "type": &"bug", "factor": 3.5},
	{"species": &"pidgey", "type": &"normal", "factor": 1.0},
]
var w03_result := "NO_EJECUTADO"


func _initialize() -> void:
	call_deferred("_run")
	create_timer(180).timeout.connect(func():
		if not done:
			push_error("W03_TIMEOUT")
			quit(2)
	)


func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not raw is Dictionary:
		print("W03_CAPTURE FAIL: normalized dataset missing")
		quit(2)
		return
	catalogs = GameData.from_dict(raw).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	_probe_live_types()
	_probe_net_boundary()
	_verify_valid_failure_and_persistence()
	_verify_master_storage_and_persistence()
	var net_connected := CaptureRuleset.new().is_known_ball(&"net_ball")
	w03_result = "NET_CONECTADA_CONTRATO_COMPROBADO" if net_connected else "BLOQUEADO_NET_BALL_NO_REGISTRADA"
	if "--require-net" in OS.get_cmdline_user_args() and not net_connected:
		check("net_ball obligatoria en modo rojo", false)
	var state := "FAIL" if not errors.is_empty() else "CARACTERIZACION_PASS"
	var summary := {"status": state, "net_ball": w03_result, "funcional_certificado": false,
		"checks": checks, "errors": errors, "godot": Engine.get_version_info().get("string", ""),
		"nota": "No declara PASS funcional de Malla Ball; el bloqueo no se oculta."}
	print("W03_CAPTURE_NET ", JSON.stringify(summary))
	done = true
	quit(1 if not errors.is_empty() else 0)


func _probe_live_types() -> void:
	# Usa la sesión de encuentros real, no un diccionario de tipos inventado.
	for row: Dictionary in CASES:
		var sid: StringName = row.species
		var species: CreatureSpecies = catalogs.species(sid)
		check("especie en catálogo " + String(sid), species != null)
		if species == null:
			continue
		check("API has_type real " + String(sid), species.has_type(row.type))
		var owner := PlayerCollection.new()
		owner.party.add_creature(_mon(&"mew", 50, &"w03_entrenador"))
		var slots := WildEncounterTable.new(&"w03_sitio")
		check("tabla de encuentro válida " + String(sid),
			slots.add_slot(WildEncounterSlot.new(&"w03_slot", sid, 1, 5, 5)))
		var encounter_rng := RandomNumberGenerator.new()
		encounter_rng.seed = 301
		var session := WildAdventureSession.new(owner, catalogs, ProgressionRuleset.new())
		var outcome := session.begin_encounter(slots, encounter_rng)
		check("encuentro real " + String(sid), outcome.status == WildEncounterResult.ENCOUNTER)
		if outcome.status != WildEncounterResult.ENCOUNTER:
			continue
		var target: CreatureInstance = session.current_wild()
		check("tipo accesible desde objetivo de encuentro " + String(sid),
			target != null and catalogs.species(target.base_species_id()).has_type(row.type))
		if target != null:
			var context := CaptureBattleContext.new()
			check("Poké Ball usa objetivo real " + String(sid),
				CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"poke_ball", context), catalogs) == "")


func _probe_net_boundary() -> void:
	var connected := CaptureRuleset.new().is_known_ball(&"net_ball")
	for row: Dictionary in CASES:
		var c := _mon(row.species, 5, &"w03_net_objetivo")
		c.current_hp = 1
		var inventory := PlayerInventory.new()
		inventory.add(&"net_ball", 2)
		var before := c.to_dict()
		var rng := RandomNumberGenerator.new()
		rng.seed = 51
		var state := rng.state
		var result := CaptureInventoryService.resolve(
			CaptureAttempt.new(c, &"net_ball", CaptureBattleContext.new()),
			rng, catalogs, CreatureParty.new(), inventory)
		if not connected:
			check("Net rechazada sin consumo ni RNG " + String(row.species),
				result.result.status == CaptureResult.INVALID
				and result.result.reason == "unknown_ball"
				and not result.result.consume_item and inventory.quantity(&"net_ball") == 2
				and rng.state == state and c.to_dict() == before)
			continue
		# Solo se ejecuta cuando IA6 autorice conectar Net: expectativa externa,
		# comparada con el servicio real, nunca con un multiplicador de test inyectado.
		var species: CreatureSpecies = catalogs.species(row.species)
		var expected := CaptureRuleset.new().catch_probability(
			species.capture_rate, float(row.factor), 1.0,
			c.stats.max_hp, c.current_hp)
		check("Net multiplicador efectivo " + String(row.species),
			is_equal_approx(result.result.probability, expected))
		check("Net uso válido gasta una unidad " + String(row.species),
			result.result.status != CaptureResult.INVALID
			and result.result.consume_item and inventory.quantity(&"net_ball") == 1)


func _verify_valid_failure_and_persistence() -> void:
	var owner := PlayerCollection.new()
	owner.party.add_creature(_mon(&"pidgey", 5, &"w03_propio"))
	owner.inventory.add(&"poke_ball", 2)
	var c := _mon(&"mew", 100, &"w03_salvaje_fallo")
	c.current_hp = c.stats.max_hp
	var ctx := CaptureBattleContext.new()
	var rate: int = catalogs.species(c.base_species_id()).capture_rate
	var probability := CaptureRuleset.new().catch_probability(
		rate, 1.0, 1.0, c.stats.max_hp, c.current_hp)
	var chosen := -1
	var control := RandomNumberGenerator.new()
	for seed_value in range(1, 1025):
		control.seed = seed_value
		if control.randf() > probability:
			chosen = seed_value
			break
	check("existe semilla reproducible de fallo", chosen != -1)
	if chosen == -1:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = chosen
	var res := CaptureInventoryService.resolve(
		CaptureAttempt.new(c, &"poke_ball", ctx), rng, catalogs,
		owner.party, owner.inventory)
	check("lanzamiento válido fallido consume una", res.result.status == CaptureResult.FAILED
		and res.result.consume_item and owner.inventory.quantity(&"poke_ball") == 1
		and rng.state == control.state and owner.party.size() == 1)
	var before := owner.inventory.to_dict()
	var no_ball := CaptureInventoryService.resolve(
		CaptureAttempt.new(c, &"net_ball", ctx), rng, catalogs,
		owner.party, owner.inventory)
	if not CaptureRuleset.new().is_known_ball(&"net_ball"):
		check("Net inválida nunca gasta bolsa", no_ball.result.status == CaptureResult.INVALID
			and not no_ball.result.consume_item and owner.inventory.to_dict() == before)
	var trainer_ctx := CaptureBattleContext.new()
	trainer_ctx.is_wild = false
	var state := rng.state
	var rejected := CaptureInventoryService.resolve(
		CaptureAttempt.new(c, &"poke_ball", trainer_ctx), rng, catalogs,
		owner.party, owner.inventory)
	check("entrenador rechazado antes de consumo", rejected.result.status == CaptureResult.INVALID
		and not rejected.result.consume_item and rng.state == state
		and owner.inventory.to_dict() == before)
	var save := SaveGameRepository.new()
	var written := save.save_collection(W03_PATH, owner)
	check("save tras lanzamiento fallido", written.ok)
	if written.ok:
		var loaded := save.load(W03_PATH)
		check("load mantiene gasto e identidad", loaded.ok and loaded.inventory.quantity(&"poke_ball") == 1
			and loaded.party.contains_instance_id(&"w03_propio") and loaded.party.size() == 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(W03_PATH))


func _verify_master_storage_and_persistence() -> void:
	var owner := PlayerCollection.new()
	for i in 6:
		owner.party.add_creature(_mon(&"pidgey", 10, StringName("w03_party_" + str(i))))
	owner.inventory.add(&"master_ball", 1)
	var target := _mon(&"caterpie", 5, &"w03_capturado_pc")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var res := CaptureInventoryService.resolve(
		CaptureAttempt.new(target, &"master_ball", CaptureBattleContext.new()),
		rng, catalogs, owner.party, owner.inventory)
	check("captura de éxito con equipo lleno", res.result.status == CaptureResult.SUCCESS
		and res.disposition == CaptureDisposition.STORAGE_REQUIRED
		and owner.inventory.quantity(&"master_ball") == 0)
	var routed := CaptureOwnershipRouter.new().route(res, owner.party, owner.storage)
	check("PC conserva propietario e identidad", routed.routed and routed.stored
		and owner.storage.contains_instance_id(target.instance_id)
		and is_same(owner.storage.get_creature(target.instance_id), target))
	var save := SaveGameRepository.new()
	var written := save.save_collection(W03_PATH, owner)
	check("save después de captura PC", written.ok)
	if written.ok:
		var loaded := save.load(W03_PATH)
		check("load conserva PC, equipo y coste", loaded.ok
			and loaded.storage.contains_instance_id(target.instance_id)
			and loaded.party.size() == 6 and loaded.inventory.quantity(&"master_ball") == 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(W03_PATH))
