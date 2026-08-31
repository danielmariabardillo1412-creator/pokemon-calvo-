class_name DataFoundationV3AbilityContactDamageTestSuite
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

	var tackle := _catalog.move(&"tackle")
	var earthquake := _catalog.move(&"earthquake")
	check.call(
		"data_v3_tough_claws_move_contact_metadata",
		tackle != null and tackle.makes_contact
		and earthquake != null and not earthquake.makes_contact,
	)

	# Contact path: same seed/state/move, only ability differs. Tough Claws must
	# increase damage and emit the ability trigger.
	var boosted_contact := _server(8001, &"tackle")
	boosted_contact.state.creature(&"a").ability_id = &"tough_claws"
	var boosted_contact_events := boosted_contact.submit_turn(
		_actions(boosted_contact.state, &"tackle")
	)
	var plain_contact := _server(8001, &"tackle")
	var plain_contact_events := plain_contact.submit_turn(
		_actions(plain_contact.state, &"tackle")
	)
	check.call(
		"data_v3_tough_claws_real_battle_contact_boost",
		_damage_to(boosted_contact_events, &"b") > _damage_to(plain_contact_events, &"b")
		and _source_triggered(boosted_contact_events, "tough_claws"),
	)

	# Non-contact path: the ability must be behaviorally inert, not merely produce a
	# smaller boost. Same damage and no trigger is the required regression contract.
	var boosted_non_contact := _server(8002, &"earthquake")
	boosted_non_contact.state.creature(&"a").ability_id = &"tough_claws"
	var boosted_non_contact_events := boosted_non_contact.submit_turn(
		_actions(boosted_non_contact.state, &"earthquake")
	)
	var plain_non_contact := _server(8002, &"earthquake")
	var plain_non_contact_events := plain_non_contact.submit_turn(
		_actions(plain_non_contact.state, &"earthquake")
	)
	check.call(
		"data_v3_tough_claws_real_battle_non_contact_inert",
		_damage_to(boosted_non_contact_events, &"b") == _damage_to(plain_non_contact_events, &"b")
		and not _source_triggered(boosted_non_contact_events, "tough_claws"),
	)


func _server(seed: int, move_a: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_tough_claws", [
		_creature(&"a", &"charmander", [move_a], 30),
		_creature(&"b", &"squirtle", [&"growl"], 20),
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


func _actions(state: BattleState, move_a: StringName) -> Array[BattleAction]:
	return [
		_client.request_move(
			state.turn + 1, &"a", move_a, state.opponent_of(&"a").instance_id, &"side_a"
		),
		_client.request_move(
			state.turn + 1, &"b", &"growl", state.opponent_of(&"b").instance_id, &"side_b"
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
