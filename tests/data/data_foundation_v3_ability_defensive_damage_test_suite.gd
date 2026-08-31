class_name DataFoundationV3AbilityDefensiveDamageTestSuite
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
	var water_gun := _catalog.move(&"water_gun")
	var ember := _catalog.move(&"ember")
	var ice_beam := _catalog.move(&"ice_beam")
	check.call(
		"data_v3_defensive_damage_move_metadata",
		tackle != null and tackle.damage_class == "physical"
		and water_gun != null and water_gun.damage_class == "special"
		and ember != null and ember.type_id == &"fire"
		and ice_beam != null and ice_beam.type_id == &"ice",
	)

	# Fur Coat: same seed/state/move, only target ability differs. Physical damage
	# must be reduced and the target-owned ability must emit its trigger.
	var fur_physical := _server(8101, &"tackle", &"fur_coat")
	var fur_physical_events := fur_physical.submit_turn(_actions(fur_physical.state, &"tackle"))
	var plain_physical := _server(8101, &"tackle", &"")
	var plain_physical_events := plain_physical.submit_turn(_actions(plain_physical.state, &"tackle"))
	check.call(
		"data_v3_fur_coat_real_battle_physical_reduction",
		_damage_to(fur_physical_events, &"b") > 0
		and _damage_to(fur_physical_events, &"b") < _damage_to(plain_physical_events, &"b")
		and _source_triggered(fur_physical_events, "fur_coat", &"b"),
	)

	# Special damage is outside Fur Coat's contract and must remain identical.
	var fur_special := _server(8102, &"water_gun", &"fur_coat")
	var fur_special_events := fur_special.submit_turn(_actions(fur_special.state, &"water_gun"))
	var plain_special := _server(8102, &"water_gun", &"")
	var plain_special_events := plain_special.submit_turn(_actions(plain_special.state, &"water_gun"))
	check.call(
		"data_v3_fur_coat_real_battle_special_inert",
		_damage_to(fur_special_events, &"b") == _damage_to(plain_special_events, &"b")
		and not _source_triggered(fur_special_events, "fur_coat", &"b"),
	)

	# Thick Fat: Fire and Ice are two mutually exclusive 0.5x target-side rules.
	for case in [
		[8103, &"ember", "data_v3_thick_fat_real_battle_fire_reduction"],
		[8104, &"ice_beam", "data_v3_thick_fat_real_battle_ice_reduction"],
	]:
		var guarded := _server(int(case[0]), StringName(case[1]), &"thick_fat")
		var guarded_events := guarded.submit_turn(_actions(guarded.state, StringName(case[1])))
		var plain := _server(int(case[0]), StringName(case[1]), &"")
		var plain_events := plain.submit_turn(_actions(plain.state, StringName(case[1])))
		check.call(
			str(case[2]),
			_damage_to(guarded_events, &"b") > 0
			and _damage_to(guarded_events, &"b") < _damage_to(plain_events, &"b")
			and _source_triggered(guarded_events, "thick_fat", &"b"),
		)

	# A non-Fire/non-Ice move must be behaviorally inert under Thick Fat.
	var thick_other := _server(8105, &"water_gun", &"thick_fat")
	var thick_other_events := thick_other.submit_turn(_actions(thick_other.state, &"water_gun"))
	var plain_other := _server(8105, &"water_gun", &"")
	var plain_other_events := plain_other.submit_turn(_actions(plain_other.state, &"water_gun"))
	check.call(
		"data_v3_thick_fat_real_battle_other_type_inert",
		_damage_to(thick_other_events, &"b") == _damage_to(plain_other_events, &"b")
		and not _source_triggered(thick_other_events, "thick_fat", &"b"),
	)


func _server(seed: int, move_a: StringName, target_ability: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_defensive_damage", [
		_creature(&"a", &"charmander", [move_a], 30),
		_creature(&"b", &"squirtle", [&"growl"], 20),
	], seed)
	state.creature(&"b").ability_id = target_ability
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
		StatBlock.new(240, 60, 55, speed, 60, 55),
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


func _source_triggered(
	events: Array[BattleEvent],
	source_id: String,
	owner_id: StringName,
) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.ABILITY_TRIGGERED
			and event.source_id == owner_id
			and event.metadata.get("source_id", "") == source_id
		):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
