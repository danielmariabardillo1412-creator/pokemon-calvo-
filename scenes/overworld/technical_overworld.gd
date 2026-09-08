extends Node2D

# Asset-free executable integration map.
# This is the canonical human-test laboratory before art: movement, wild encounters,
# trainer AI battles, configurable rosters and black-box diagnostics all drive the real runtime.

const RUNTIME_DATA_PATH := "res://data/normalized/pokemon_api.json"
const TECHNICAL_TRAINER_ID := &"technical_trainer"
const TECHNICAL_ZONE_ID := &"technical_grass"
const DEFAULT_PLAYER_POSITION := Vector2(96, 180)

@onready var player: OverworldPlayer = $Player
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var battle_presentation: DiagnosticWildBattlePresentation = $CanvasLayer/BattlePresentation
@onready var trainer_battle_presentation: DiagnosticTrainerBattlePresentation = $CanvasLayer/TrainerBattlePresentation
@onready var test_panel: TechnicalTestPanel = $CanvasLayer/TechnicalTestPanel

var _director: OverworldEncounterDirector = null
var _session: WildAdventureSession = null
var _trainer_session: TrainerBattleSession = null
var _trainer_campaign_owner: TrainerCampaignRosterOwner = null
var _catalogs: DefinitionCatalog = null
var _capture_rng: RandomNumberGenerator = null
var _escape_rng: RandomNumberGenerator = null
var _trainer_profile_id: StringName = TrainerProfile.BALANCED
var _trainer_expertise_id: StringName = TrainerExpertise.FULL
var _active_config: Dictionary = {}
var _recorder := TechnicalTestRecorder.new()


func _ready() -> void:
	player.step_completed.connect(_on_player_step_completed)
	battle_presentation.battle_closed.connect(_on_battle_closed)
	trainer_battle_presentation.battle_closed.connect(_on_trainer_battle_closed)
	battle_presentation.diagnostic_event.connect(_on_wild_diagnostic_event)
	trainer_battle_presentation.diagnostic_event.connect(_on_trainer_diagnostic_event)
	test_panel.configuration_applied.connect(_on_configuration_applied)
	test_panel.export_report_requested.connect(_on_export_report_requested)
	test_panel.open_report_folder_requested.connect(_on_open_report_folder_requested)
	test_panel.panel_visibility_changed.connect(_on_test_panel_visibility_changed)

	var recorder_ok := _recorder.start_session({
		"project": "Pokemon Calvo",
		"godot": Engine.get_version_info(),
		"data_path": RUNTIME_DATA_PATH,
		"purpose": "asset_free_human_validation",
	})
	if recorder_ok:
		test_panel.set_report_status("Caja negra activa: %s" % _recorder.current_stream_global_path())
	else:
		test_panel.set_report_status("ERROR: no se pudo crear la carpeta de informes")

	if _bootstrap_demo(test_panel.current_configuration()):
		_configure_presentations()
		player.movement_enabled = true
		status_label.text = "LABORATORIO | Verde: salvaje | Azul: entrenador IA | Flechas/WASD para moverte"
		test_panel.set_runtime_status("LISTO — motor real, sin arte")
		_recorder.record(&"runtime", &"ready", _runtime_summary())
		print("TECHNICAL_TEST_READY species=%d moves=%d reports=%s" % [
			_catalogs.species_catalog.size(),
			_catalogs.move_catalog.size(),
			_recorder.report_directory_global_path(),
		])
	else:
		player.movement_enabled = false
		status_label.text = "No se ha podido iniciar el laboratorio técnico"
		test_panel.set_runtime_status("ERROR — revisa la configuración/datos")
		_recorder.record(&"runtime", &"bootstrap_failed", {"config": _active_config})


func is_demo_ready() -> bool:
	return (
		_director != null
		and _session != null
		and _trainer_session != null
		and _trainer_campaign_owner != null
		and _trainer_campaign_owner.is_ready()
		and _catalogs != null
		and _capture_rng != null
		and _escape_rng != null
		and battle_presentation != null
		and trainer_battle_presentation != null
	)


func has_active_demo_battle() -> bool:
	return _session != null and _session.has_active_battle()


func has_active_demo_trainer_battle() -> bool:
	return _trainer_session != null and _trainer_session.has_active_battle()


func is_battle_presentation_visible() -> bool:
	return battle_presentation != null and battle_presentation.is_presenting_battle()


func is_trainer_battle_presentation_visible() -> bool:
	return trainer_battle_presentation != null and trainer_battle_presentation.is_presenting_battle()


func demo_inventory_quantity(item_id: StringName) -> int:
	if _session == null or _session.player == null or _session.player.inventory == null:
		return 0
	return _session.player.inventory.quantity(item_id)


func demo_party_size() -> int:
	return _session.player.party.size() if _session != null and _session.player != null else 0


func demo_storage_contains(instance_id: StringName) -> bool:
	return (
		_session != null
		and _session.player != null
		and _session.player.storage != null
		and _session.player.storage.contains_instance_id(instance_id)
	)


func zone_at_position(world_position: Vector2) -> StringName:
	for node in get_tree().get_nodes_in_group("encounter_zones"):
		var zone := node as OverworldEncounterZone
		if zone != null and zone.contains_world_point(world_position):
			return zone.zone_id
	return &""


func trainer_trigger_contains(world_position: Vector2) -> bool:
	var trigger := get_node_or_null("TrainerTrigger") as Area2D
	if trigger == null:
		return false
	var collision := trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null or not (collision.shape is RectangleShape2D):
		return false
	var rectangle := collision.shape as RectangleShape2D
	var local := trigger.to_local(world_position)
	var half := rectangle.size * 0.5
	return absf(local.x) <= half.x and absf(local.y) <= half.y


func start_demo_trainer_battle() -> bool:
	if _trainer_session == null or _trainer_campaign_owner == null or not _trainer_campaign_owner.is_ready() or trainer_battle_presentation == null:
		return false
	if _session != null and _session.has_active_battle():
		return false
	if _trainer_session.has_active_battle():
		return false
	if _trainer_session.status == TrainerBattleSession.COMPLETED:
		if not _trainer_session.reset_after_completion():
			return false
	var trainer_roster := _trainer_campaign_owner.roster_for_battle()
	if trainer_roster.is_empty():
		return false
	if not _trainer_session.begin_battle(
		TECHNICAL_TRAINER_ID,
		trainer_roster,
		12007,
		_trainer_profile_id,
		_trainer_expertise_id,
	):
		status_label.text = "No se ha podido iniciar el combate de entrenador: %s" % _trainer_session.last_error
		_recorder.record(&"trainer", &"battle_start_failed", {"error": _trainer_session.last_error})
		return false

	player.movement_enabled = false
	status_label.text = "¡ENTRENADOR! | Rival técnico"
	_recorder.record(&"trainer", &"battle_started", {
		"profile_id": String(_trainer_profile_id),
		"expertise_id": String(_trainer_expertise_id),
		"state": _trainer_session.battle_state().to_dict(),
	})
	_record_state_validation(&"trainer", _trainer_session.battle_state())
	if not trainer_battle_presentation.open_for_active_battle():
		status_label.text = "El combate de entrenador ha empezado, pero no se ha podido abrir la pantalla"
		_recorder.record(&"trainer", &"presentation_open_failed")
		return false
	return true


# P1-D explicit inter-battle campaign action. It is deliberately unavailable while
# either battle seam is active or while the trainer session is waiting for its
# completion/reset boundary. Nothing invokes recovery automatically after settlement.
func recover_demo_trainer_full() -> bool:
	if _trainer_campaign_owner == null or not _trainer_campaign_owner.is_ready():
		return false
	if _session != null and _session.has_active_battle():
		return false
	if _trainer_session != null and _trainer_session.status != TrainerBattleSession.READY:
		return false
	var trainer_roster := _trainer_campaign_owner.roster_for_battle()
	if trainer_roster.is_empty():
		return false
	for creature in trainer_roster:
		if creature == null or not _trainer_campaign_owner.recover_creature_full(creature.instance_id):
			return false
	status_label.text = "Rival técnico recuperado | Revancha disponible"
	_recorder.record(&"trainer", &"roster_recovered")
	return true


func _on_player_step_completed(world_position: Vector2) -> void:
	if (_trainer_session != null and _trainer_session.has_active_battle()) or (_session != null and _session.has_active_battle()):
		return
	var zone_id := zone_at_position(world_position)
	var trainer_hit := trainer_trigger_contains(world_position)
	_recorder.record(&"overworld", &"step_completed", {
		"x": world_position.x,
		"y": world_position.y,
		"zone_id": String(zone_id),
		"trainer_trigger": trainer_hit,
	})
	if trainer_hit and start_demo_trainer_battle():
		return
	if _director == null:
		return
	var outcome := _director.on_step(zone_id)
	if outcome.rolled:
		var encounter_payload := {
			"zone_id": String(zone_id),
			"battle_started": outcome.battle_started,
			"reason": outcome.reason,
		}
		if outcome.encounter != null:
			encounter_payload["encounter_status"] = String(outcome.encounter.status)
			encounter_payload["species_id"] = String(outcome.encounter.species_id)
			encounter_payload["level"] = outcome.encounter.level
			encounter_payload["slot_id"] = String(outcome.encounter.slot_id)
		_recorder.record(&"encounter", &"roll_resolved", encounter_payload)
	if outcome.battle_started:
		player.movement_enabled = false
		var wild := _session.current_wild()
		var label := SpanishGameText.species_name(wild.species_id, _catalogs) if wild != null else "desconocido"
		var level := wild.level if wild != null else 0
		status_label.text = "¡ENCUENTRO! | %s salvaje Nv.%d" % [label, level]
		_recorder.record(&"wild", &"battle_started", {
			"species_id": String(wild.species_id) if wild != null else "",
			"level": level,
			"state": _session.battle_state().to_dict() if _session.battle_state() != null else {},
		})
		_record_state_validation(&"wild", _session.battle_state())
		if not battle_presentation.open_for_active_battle():
			status_label.text = "El combate ha empezado, pero no se ha podido abrir la pantalla"
			_recorder.record(&"wild", &"presentation_open_failed")
	elif outcome.rolled and outcome.encounter != null and outcome.encounter.status == WildEncounterResult.NONE:
		status_label.text = "No ha aparecido ningún Pokémon esta vez"


func _on_battle_closed(reason: StringName) -> void:
	player.movement_enabled = not test_panel.is_panel_open()
	status_label.text = "Combate terminado: %s | Exploración reanudada" % SpanishGameText.completion_reason(reason)
	_recorder.record(&"wild", &"battle_closed", {
		"reason": String(reason),
		"party_size": demo_party_size(),
	})
	_auto_export_after_battle("wild", reason)


func _on_trainer_battle_closed(reason: StringName) -> void:
	player.movement_enabled = not test_panel.is_panel_open()
	status_label.text = "Combate de entrenador terminado: %s | Exploración reanudada" % SpanishGameText.completion_reason(reason)
	_recorder.record(&"trainer", &"battle_closed", {"reason": String(reason)})
	_auto_export_after_battle("trainer", reason)


func _on_wild_diagnostic_event(entry: Dictionary) -> void:
	_recorder.record(&"wild_ui", StringName(entry.get("event", "diagnostic")), entry)
	if _session != null:
		_record_state_validation(&"wild", _session.battle_state())


func _on_trainer_diagnostic_event(entry: Dictionary) -> void:
	_recorder.record(&"trainer_ui", StringName(entry.get("event", "diagnostic")), entry)
	if _trainer_session != null:
		_record_state_validation(&"trainer", _trainer_session.battle_state())


func _on_configuration_applied(config: Dictionary) -> void:
	if has_active_demo_battle() or has_active_demo_trainer_battle():
		test_panel.set_runtime_status("No se puede reconfigurar durante un combate")
		return
	player.movement_enabled = false
	player.position = DEFAULT_PLAYER_POSITION
	_recorder.record(&"configuration", &"apply_requested", config)
	if _bootstrap_demo(config):
		_configure_presentations()
		player.movement_enabled = true
		status_label.text = "Configuración aplicada | Camina al verde o al azul"
		test_panel.set_runtime_status("CONFIGURACIÓN OK")
		_recorder.record(&"configuration", &"applied", _runtime_summary())
	else:
		player.movement_enabled = false
		status_label.text = "Configuración rechazada: revisa IDs/niveles"
		test_panel.set_runtime_status("ERROR DE CONFIGURACIÓN")
		_recorder.record(&"configuration", &"rejected", config)


func _on_export_report_requested() -> void:
	var path := _recorder.export_report(_runtime_summary())
	if path.is_empty():
		test_panel.set_report_status("ERROR: no se pudo exportar el informe")
		return
	test_panel.set_report_status("Informe listo: %s" % path)
	status_label.text = "Informe exportado. Pulsa ABRIR CARPETA DE INFORMES para enviarlo."


func _on_open_report_folder_requested() -> void:
	var path := _recorder.report_directory_global_path()
	if path.is_empty():
		return
	OS.shell_open(path)
	test_panel.set_report_status("Carpeta: %s" % path)


func _on_test_panel_visibility_changed(open: bool) -> void:
	if has_active_demo_battle() or has_active_demo_trainer_battle():
		return
	player.movement_enabled = not open


func _auto_export_after_battle(scope: String, reason: StringName) -> void:
	var path := _recorder.export_report({
		"auto_export": true,
		"last_battle_scope": scope,
		"last_battle_reason": String(reason),
		"runtime": _runtime_summary(),
	})
	if not path.is_empty():
		test_panel.set_report_status("Informe actualizado automáticamente: %s" % path)


func _configure_presentations() -> void:
	battle_presentation.configure(_session, _catalogs, _capture_rng, _escape_rng)
	trainer_battle_presentation.configure(_trainer_session, _catalogs)


func _bootstrap_demo(config: Dictionary) -> bool:
	_active_config = config.duplicate(true)
	var normalized := _load_json(RUNTIME_DATA_PATH)
	if normalized.is_empty():
		return false
	var game_data := GameData.from_dict(normalized)
	if game_data == null or game_data.manifest == null or not game_data.manifest.is_valid():
		return false
	var type_validation := PokemonTypeChart.validate_catalog(game_data.type_catalog)
	if not bool(type_validation.get("valid", false)):
		push_error("Canonical Pokemon type chart is incomplete: %s" % str(type_validation))
		return false
	_catalogs = game_data.to_definition_catalog()
	var rules := ProgressionRuleset.new()
	var collection := PlayerCollection.new()
	var player_rows: Array = config.get("player_team", [])
	var trainer_rows: Array = config.get("trainer_team", [])
	if player_rows.is_empty() or trainer_rows.is_empty():
		return false

	for index in range(player_rows.size()):
		var row := player_rows[index] as Dictionary
		var creature := _build_creature(
			StringName(String(row.get("species_id", ""))),
			int(row.get("level", 1)),
			"player",
			index,
			rules,
		)
		if creature == null or not collection.party.add_creature(creature):
			return false

	var trainer_roster: Array[CreatureInstance] = []
	for index in range(trainer_rows.size()):
		var row := trainer_rows[index] as Dictionary
		var creature := _build_creature(
			StringName(String(row.get("species_id", ""))),
			int(row.get("level", 1)),
			"trainer",
			index,
			rules,
		)
		if creature == null:
			return false
		trainer_roster.append(creature)

	# Preserve the established technical-scene inventory contract used by capture regressions.
	if not collection.inventory.add(&"poke_ball", 3):
		return false
	if not collection.inventory.add(&"great_ball", 1):
		return false
	if not collection.inventory.add(&"master_ball", 1):
		return false

	_trainer_campaign_owner = TrainerCampaignRosterOwner.new()
	if not _trainer_campaign_owner.configure(TECHNICAL_TRAINER_ID, trainer_roster):
		return false

	_session = WildAdventureSession.new(collection, _catalogs, rules)
	_trainer_session = TrainerBattleSession.new(collection, _catalogs, rules)
	_trainer_profile_id = StringName(String(config.get("trainer_profile_id", "balanced")))
	_trainer_expertise_id = StringName(String(config.get("trainer_expertise_id", "full")))

	var encounter_rng := RandomNumberGenerator.new()
	encounter_rng.seed = 12002
	_director = OverworldEncounterDirector.new(_session, encounter_rng, 12003)
	_capture_rng = RandomNumberGenerator.new()
	_capture_rng.seed = 12004
	_escape_rng = RandomNumberGenerator.new()
	_escape_rng.seed = 12006

	var wild_species_id := StringName(String(config.get("wild_species_id", "pikachu")))
	var wild_min := clampi(int(config.get("wild_min_level", 4)), 1, 100)
	var wild_max := clampi(int(config.get("wild_max_level", 4)), 1, 100)
	if wild_max < wild_min:
		var swap := wild_min
		wild_min = wild_max
		wild_max = swap
	if _catalogs.species_catalog.get_by_id(wild_species_id) == null:
		return false
	var chance_percent := clampi(int(config.get("encounter_chance_percent", 100)), 0, 100)
	var table := WildEncounterTable.new(TECHNICAL_ZONE_ID, chance_percent * 100)
	if not table.add_slot(WildEncounterSlot.new(&"technical_wild_slot", wild_species_id, 1, wild_min, wild_max)):
		return false
	if not _director.register_zone(table):
		return false
	return true


func _build_creature(
	species_id: StringName,
	level: int,
	side: String,
	slot_index: int,
	rules: ProgressionRuleset,
) -> CreatureInstance:
	if species_id == &"" or level < 1 or level > 100:
		return null
	var species := _catalogs.species_catalog.get_by_id(species_id)
	if species == null:
		push_error("Technical test: unknown species %s" % String(species_id))
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 880000 + slot_index + (100 if side == "trainer" else 0)
	var instance_id := StringName("technical_%s_%d_%s" % [side, slot_index + 1, String(species_id)])
	# Preserve the stable slot identities used by the original technical scene and its
	# integration tests. They stay slot-based even when the tester selects another species.
	if side == "player" and slot_index == 0:
		instance_id = &"technical_starter"
	elif side == "player" and slot_index == 1:
		instance_id = &"technical_bench"
	elif side == "trainer" and slot_index == 0:
		instance_id = &"technical_trainer_squirtle"
	var creature := CreatureFactory.create(
		species,
		level,
		_catalogs,
		rules,
		rng,
		{"instance_id": instance_id},
	)
	if creature == null:
		return null
	if creature.moveset.is_empty():
		push_error("Technical test: %s Nv.%d has no usable moves" % [String(species_id), level])
		return null
	return creature


func _record_state_validation(scope: StringName, state: BattleState) -> void:
	if state == null:
		return
	var issues: Array[String] = []
	for instance_id in state.participant_ids:
		var creature := state.creature(instance_id)
		if creature == null:
			issues.append("participant_missing:%s" % String(instance_id))
			continue
		if creature.current_hp < 0:
			issues.append("negative_hp:%s:%d" % [String(instance_id), creature.current_hp])
		if creature.current_hp > creature.stats.max_hp:
			issues.append("hp_above_max:%s:%d/%d" % [String(instance_id), creature.current_hp, creature.stats.max_hp])
	for side in state.sides:
		if side.active_id == &"" or not side.owns(side.active_id) or state.creature(side.active_id) == null:
			issues.append("invalid_active:%s:%s" % [String(side.side_id), String(side.active_id)])
	_recorder.record(scope, &"state_snapshot", {
		"validation_ok": issues.is_empty(),
		"issues": issues,
		"state": state.to_dict(),
	})


func _runtime_summary() -> Dictionary:
	return {
		"config": _active_config.duplicate(true),
		"data_path": RUNTIME_DATA_PATH,
		"species_count": _catalogs.species_catalog.size() if _catalogs != null else 0,
		"move_count": _catalogs.move_catalog.size() if _catalogs != null else 0,
		"player_party_size": demo_party_size(),
		"trainer_profile_id": String(_trainer_profile_id),
		"trainer_expertise_id": String(_trainer_expertise_id),
		"report_stream": _recorder.current_stream_global_path(),
		"report_entries": _recorder.entry_count(),
	}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
