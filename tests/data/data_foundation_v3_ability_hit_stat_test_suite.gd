class_name DataFoundationV3AbilityHitStatTestSuite
extends RefCounted

var _catalog: DefinitionCatalog
var _client := BattleClient.new()


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(
		_load_json("res://data/manifests/pokemon_api_manifest.json")
	)
	var imported := DataImporter.new().import_dataset(raw, manifest)
	var game_data: GameData = imported.get("game_data")
	_catalog = game_data.to_definition_catalog()

	# Positive runtime slice: an ordinary damaging move that the owner survives
	# must fire Stamina exactly once and raise Defense by one stage.
	var hit_server := _server(7901, &"tackle", &"growl")
	hit_server.state.creature(&"b").ability_id = &"stamina"
	var hit_events := hit_server.submit_turn(_actions(hit_server.state, &"tackle", &"growl"))
	check.call(
		"data_v3_stamina_real_battle_surviving_hit",
		_damage_to(hit_events, &"b") > 0
		and hit_server.state.creature(&"b").stat_stages.get_stage(StatStages.DEFENSE) == 1
		and _source_triggered(hit_events, "stamina"),
	)

	# A non-damaging move must not satisfy the AFTER_DAMAGE transaction.
	var status_server := _server(7902, &"growl", &"tackle")
	status_server.state.creature(&"b").ability_id = &"stamina"
	var status_events := status_server.submit_turn(_actions(status_server.state, &"growl", &"tackle"))
	check.call(
		"data_v3_stamina_no_trigger_without_damage",
		status_server.state.creature(&"b").stat_stages.get_stage(StatStages.DEFENSE) == 0
		and not _source_triggered(status_events, "stamina"),
	)


func _server(seed: int, move_a: StringName, move_b: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_stamina", [
		_creature(&"a", &"charmander", [move_a], 30),
		_creature(&"b", &"squirtle", [move_b], 20),
	], seed)
	return AuthoritativeBattleServer.new(state, _catalog)


func _creature(
	id: StringName,
	species_id: StringName,
	moves: Array[StringName],
	speed: int,
) -> CreatureInstance:
	return CreatureInstance.new(
		id,
		species_id,
		30,
		StatBlock.new(160, 60, 55, speed, 60, 55),
		moves,
	)


func _actions(
	state: BattleState,
	move_a: StringName,
	move_b: StringName,
) -> Array[BattleAction]:
	return [
		_client.request_move(
			state.turn + 1, &"a", move_a, state.opponent_of(&"a").instance_id, &"side_a"
		),
		_client.request_move(
			state.turn + 1, &"b", move_b, state.opponent_of(&"b").instance_id, &"side_b"
		),
	]


func _damage_to(events: Array[BattleEvent], target_id: StringName) -> int:
	for event in events:
		if event.kind == BattleEvent.DAMAGE_APPLIED and event.target_id == target_id:
			return event.amount
	return 0


func _source_triggered(events: Array[BattleEvent], source_id: String) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.ABILITY_TRIGGERED
			and event.metadata.get("source_id", "") == source_id
		):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
