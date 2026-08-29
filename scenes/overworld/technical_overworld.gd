extends Node2D

# Asset-free technical map for FASE 13. It proves the runtime seam:
# physical movement -> collision-aware step -> encounter -> real Battle -> visual Battle adapter
# -> authoritative turn resolution -> settlement -> return to exploration.
# Runtime consumes normalized canonical data; import remains build/QA only.

const RUNTIME_DATA_PATH := "res://data/normalized/pokemon_api.json"

@onready var player: OverworldPlayer = $Player
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var battle_presentation: BattlePresentationController = $CanvasLayer/BattlePresentation

var _director: OverworldEncounterDirector = null
var _session: WildAdventureSession = null
var _catalogs: DefinitionCatalog = null


func _ready() -> void:
	player.step_completed.connect(_on_player_step_completed)
	battle_presentation.battle_closed.connect(_on_battle_closed)
	if _bootstrap_demo():
		battle_presentation.configure(_session, _catalogs)
		status_label.text = "FASE 13 technical overworld | Arrow keys to move | Walk into the grass"
	else:
		player.movement_enabled = false
		status_label.text = "Overworld bootstrap failed"


func is_demo_ready() -> bool:
	return _director != null and _session != null and _catalogs != null


func has_active_demo_battle() -> bool:
	return _session != null and _session.has_active_battle()


func is_battle_presentation_visible() -> bool:
	return battle_presentation != null and battle_presentation.is_presenting_battle()


func zone_at_position(world_position: Vector2) -> StringName:
	for node in get_tree().get_nodes_in_group("encounter_zones"):
		var zone := node as OverworldEncounterZone
		if zone != null and zone.contains_world_point(world_position):
			return zone.zone_id
	return &""


func _on_player_step_completed(world_position: Vector2) -> void:
	if _director == null:
		return
	var zone_id := zone_at_position(world_position)
	var outcome := _director.on_step(zone_id)
	if outcome.battle_started:
		player.movement_enabled = false
		var wild := _session.current_wild()
		var label := String(wild.species_id) if wild != null else "unknown"
		var level := wild.level if wild != null else 0
		status_label.text = "ENCOUNTER -> BATTLE ACTIVE | %s Lv.%d" % [label, level]
		if not battle_presentation.open_for_active_battle():
			status_label.text = "Battle started, but presentation failed to open"
	elif outcome.rolled and outcome.encounter != null and outcome.encounter.status == WildEncounterResult.NONE:
		status_label.text = "Encounter zone step: no encounter this time"


func _on_battle_closed(reason: StringName) -> void:
	player.movement_enabled = true
	status_label.text = "BATTLE COMPLETE: %s | Exploration resumed" % String(reason)


func _bootstrap_demo() -> bool:
	var normalized := _load_json(RUNTIME_DATA_PATH)
	if normalized.is_empty():
		return false
	var game_data := GameData.from_dict(normalized)
	if game_data == null or game_data.manifest == null or not game_data.manifest.is_valid():
		return false
	_catalogs = game_data.to_definition_catalog()
	var rules := ProgressionRuleset.new()
	var starter_species := _catalogs.species_catalog.get_by_id(&"bulbasaur")
	if starter_species == null:
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
	if starter == null:
		return false
	var collection := PlayerCollection.new()
	if not collection.party.add_creature(starter):
		return false
	_session = WildAdventureSession.new(collection, _catalogs, rules)
	var encounter_rng := RandomNumberGenerator.new()
	encounter_rng.seed = 12002
	_director = OverworldEncounterDirector.new(_session, encounter_rng, 12003)

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
