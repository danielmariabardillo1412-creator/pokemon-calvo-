extends Node2D

# Asset-free technical map for FASE 12. It proves the runtime seam:
# physical movement -> collision-aware step -> encounter zone -> WildAdventureSession -> Battle.
# There is intentionally no battle UI yet; once the logical Battle starts, movement freezes and the
# status label exposes the transition for local/manual validation.

@onready var player: OverworldPlayer = $Player
@onready var status_label: Label = $CanvasLayer/StatusLabel

var _director: OverworldEncounterDirector = null
var _session: WildAdventureSession = null


func _ready() -> void:
	player.step_completed.connect(_on_player_step_completed)
	if _bootstrap_demo():
		status_label.text = "FASE 12 technical overworld | Arrow keys to move | Walk into the grass"
	else:
		player.movement_enabled = false
		status_label.text = "Overworld bootstrap failed"


func is_demo_ready() -> bool:
	return _director != null and _session != null


func has_active_demo_battle() -> bool:
	return _session != null and _session.has_active_battle()


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
		status_label.text = "ENCOUNTER -> BATTLE ACTIVE | %s Lv.%d | Battle UI is next phase" % [label, level]
	elif outcome.rolled and outcome.encounter != null and outcome.encounter.status == WildEncounterResult.NONE:
		status_label.text = "Encounter zone step: no encounter this time"


func _bootstrap_demo() -> bool:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest_data := _load_json("res://data/manifests/pokemon_api_manifest.json")
	if raw.is_empty() or manifest_data.is_empty():
		return false
	var manifest := DatasetManifest.from_dict(manifest_data)
	var imported := DataImporter.new().import_dataset(raw, manifest)
	var game_data := imported.get("game_data", null) as GameData
	if game_data == null:
		return false
	var catalogs := game_data.to_definition_catalog()
	var rules := ProgressionRuleset.new()
	var starter_species := catalogs.species_catalog.get_by_id(&"bulbasaur")
	if starter_species == null:
		return false
	var starter_rng := RandomNumberGenerator.new()
	starter_rng.seed = 12001
	var starter := CreatureFactory.create(
		starter_species,
		5,
		catalogs,
		rules,
		starter_rng,
		{"instance_id": &"technical_starter"},
	)
	if starter == null:
		return false
	var collection := PlayerCollection.new()
	if not collection.party.add_creature(starter):
		return false
	_session = WildAdventureSession.new(collection, catalogs, rules)
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
