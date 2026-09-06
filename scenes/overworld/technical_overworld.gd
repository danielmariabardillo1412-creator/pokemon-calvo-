extends Node2D

# Asset-free executable integration map.
# Wild battles keep their original WildAdventureSession/presentation seam.
# Trainer battles use a separate TrainerBattleSession + TrainerBattlePresentationController seam.

const RUNTIME_DATA_PATH := "res://data/normalized/pokemon_api.json"
const TECHNICAL_TRAINER_ID := &"technical_trainer"

@onready var player: OverworldPlayer = $Player
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var battle_presentation: BattlePresentationController = $CanvasLayer/BattlePresentation
@onready var trainer_battle_presentation: TrainerBattlePresentationController = $CanvasLayer/TrainerBattlePresentation

var _director: OverworldEncounterDirector = null
var _session: WildAdventureSession = null
var _trainer_session: TrainerBattleSession = null
var _trainer_roster: Array[CreatureInstance] = []
var _trainer_demo_completed: bool = false
var _catalogs: DefinitionCatalog = null
var _capture_rng: RandomNumberGenerator = null
var _escape_rng: RandomNumberGenerator = null


func _ready() -> void:
	player.step_completed.connect(_on_player_step_completed)
	battle_presentation.battle_closed.connect(_on_battle_closed)
	trainer_battle_presentation.battle_closed.connect(_on_trainer_battle_closed)
	if _bootstrap_demo():
		battle_presentation.configure(_session, _catalogs, _capture_rng, _escape_rng)
		trainer_battle_presentation.configure(_trainer_session, _catalogs)
		status_label.text = "Mundo técnico | Salvaje: mover/cambiar/capturar/huir | Entrenador: mover/cambiar + IA"
	else:
		player.movement_enabled = false
		status_label.text = "No se ha podido iniciar el mundo"


func is_demo_ready() -> bool:
	return (
		_director != null
		and _session != null
		and _trainer_session != null
		and not _trainer_roster.is_empty()
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
	if _trainer_demo_completed:
		return false
	if _trainer_session == null or _trainer_roster.is_empty() or trainer_battle_presentation == null:
		return false
	if _session != null and _session.has_active_battle():
		return false
	if _trainer_session.has_active_battle():
		return false
	if _trainer_session.status == TrainerBattleSession.COMPLETED:
		if not _trainer_session.reset_after_completion():
			return false
	if not _trainer_session.begin_battle(TECHNICAL_TRAINER_ID, _trainer_roster, 12007):
		status_label.text = "No se ha podido iniciar el combate de entrenador: %s" % _trainer_session.last_error
		return false

	player.movement_enabled = false
	status_label.text = "¡ENTRENADOR! | Rival técnico"
	if not trainer_battle_presentation.open_for_active_battle():
		status_label.text = "El combate de entrenador ha empezado, pero no se ha podido abrir la pantalla"
		return false
	return true


func _on_player_step_completed(world_position: Vector2) -> void:
	# A single apply_motion() can cross multiple step boundaries. Once either seam starts a battle,
	# ignore any remaining step signals from that same physical movement.
	if (_trainer_session != null and _trainer_session.has_active_battle()) or (_session != null and _session.has_active_battle()):
		return
	if trainer_trigger_contains(world_position) and start_demo_trainer_battle():
		return
	if _director == null:
		return
	var zone_id := zone_at_position(world_position)
	var outcome := _director.on_step(zone_id)
	if outcome.battle_started:
		player.movement_enabled = false
		var wild := _session.current_wild()
		var label := SpanishGameText.species_name(wild.species_id, _catalogs) if wild != null else "desconocido"
		var level := wild.level if wild != null else 0
		status_label.text = "¡ENCUENTRO! | %s salvaje Nv.%d" % [label, level]
		if not battle_presentation.open_for_active_battle():
			status_label.text = "El combate ha empezado, pero no se ha podido abrir la pantalla"
	elif outcome.rolled and outcome.encounter != null and outcome.encounter.status == WildEncounterResult.NONE:
		status_label.text = "No ha aparecido ningún Pokémon esta vez"


func _on_battle_closed(reason: StringName) -> void:
	player.movement_enabled = true
	status_label.text = "Combate terminado: %s | Exploración reanudada" % SpanishGameText.completion_reason(reason)


func _on_trainer_battle_closed(reason: StringName) -> void:
	_trainer_demo_completed = true
	player.movement_enabled = true
	status_label.text = "Combate de entrenador terminado: %s | Exploración reanudada" % SpanishGameText.completion_reason(reason)


func _bootstrap_demo() -> bool:
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
	var starter_species := _catalogs.species_catalog.get_by_id(&"bulbasaur")
	var bench_species := _catalogs.species_catalog.get_by_id(&"charmander")
	var trainer_species := _catalogs.species_catalog.get_by_id(&"squirtle")
	if starter_species == null or bench_species == null or trainer_species == null:
		return false

	var starter_rng := RandomNumberGenerator.new()
	starter_rng.seed = 12001
	var starter := CreatureFactory.create(
		starter_species,
		5,
		_catalogs,
		rules,
		starter_rng,
		{"instance_id": &"technical_starter"},
	)
	var bench_rng := RandomNumberGenerator.new()
	bench_rng.seed = 12005
	var bench := CreatureFactory.create(
		bench_species,
		5,
		_catalogs,
		rules,
		bench_rng,
		{"instance_id": &"technical_bench"},
	)
	var trainer_rng := RandomNumberGenerator.new()
	trainer_rng.seed = 12008
	var trainer_creature := CreatureFactory.create(
		trainer_species,
		4,
		_catalogs,
		rules,
		trainer_rng,
		{"instance_id": &"technical_trainer_squirtle"},
	)
	if starter == null or bench == null or trainer_creature == null:
		return false
	if _catalogs.move(&"tackle") == null:
		return false
	var trainer_slots: Array[BattleMoveSlot] = [BattleMoveSlot.new(&"tackle", 35, 35)]
	var trainer_move_ids: Array[StringName] = [&"tackle"]
	trainer_creature.moveset = trainer_slots
	trainer_creature.move_ids = trainer_move_ids
	_trainer_roster.clear()
	_trainer_roster.append(trainer_creature)

	var collection := PlayerCollection.new()
	if not collection.party.add_creature(starter):
		return false
	# Second technical party member exists only to exercise elective Switch in the executable slice.
	if not collection.party.add_creature(bench):
		return false
	# Small technical inventory belongs only to the Wild seam.
	if not collection.inventory.add(&"poke_ball", 3):
		return false
	if not collection.inventory.add(&"great_ball", 1):
		return false
	if not collection.inventory.add(&"master_ball", 1):
		return false

	_session = WildAdventureSession.new(collection, _catalogs, rules)
	_trainer_session = TrainerBattleSession.new(collection, _catalogs, rules)
	var encounter_rng := RandomNumberGenerator.new()
	encounter_rng.seed = 12002
	_director = OverworldEncounterDirector.new(_session, encounter_rng, 12003)
	_capture_rng = RandomNumberGenerator.new()
	_capture_rng.seed = 12004
	_escape_rng = RandomNumberGenerator.new()
	_escape_rng.seed = 12006

	var table := WildEncounterTable.new(&"technical_grass", 10000)
	if not table.add_slot(WildEncounterSlot.new(&"technical_pikachu", &"pikachu", 1, 4, 4)):
		return false
	return _director.register_zone(table)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
