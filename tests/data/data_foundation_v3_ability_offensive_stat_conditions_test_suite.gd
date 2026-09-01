class_name DataFoundationV3AbilityOffensiveStatConditionsTestSuite
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
	check.call(
		"data_v3_offensive_conditions_move_metadata",
		tackle != null and tackle.damage_class == "physical"
		and water_gun != null and water_gun.damage_class == "special",
	)

	# Defeatist is exact at the source boundary: <= 50% max HP halves the relevant
	# offensive stat, and 50% + 1 HP must be completely inert.
	var defeatist_physical := _server(9200, &"tackle", &"defeatist", &"", 120)
	var defeatist_physical_events := defeatist_physical.submit_turn(
		_actions(defeatist_physical.state, &"tackle")
	)
	var plain_physical := _server(9200, &"tackle", &"", &"", 120)
	var plain_physical_events := plain_physical.submit_turn(_actions(plain_physical.state, &"tackle"))
	check.call(
		"data_v3_defeatist_half_hp_physical",
		_damage_to(defeatist_physical_events, &"b") < _damage_to(plain_physical_events, &"b")
		and _source_triggered(defeatist_physical_events, "defeatist")
		and _damage_offensive_multiplier(defeatist_physical_events, &"b") == 5000,
	)

	var defeatist_special := _server(9201, &"water_gun", &"defeatist", &"", 120)
	var defeatist_special_events := defeatist_special.submit_turn(
		_actions(defeatist_special.state, &"water_gun")
	)
	var plain_special := _server(9201, &"water_gun", &"", &"", 120)
	var plain_special_events := plain_special.submit_turn(_actions(plain_special.state, &"water_gun"))
	check.call(
		"data_v3_defeatist_half_hp_special",
		_damage_to(defeatist_special_events, &"b") < _damage_to(plain_special_events, &"b")
		and _source_triggered(defeatist_special_events, "defeatist")
		and _damage_offensive_multiplier(defeatist_special_events, &"b") == 5000,
	)

	var defeatist_above := _server(9202, &"tackle", &"defeatist", &"", 121)
	var defeatist_above_events := defeatist_above.submit_turn(_actions(defeatist_above.state, &"tackle"))
	var plain_above := _server(9202, &"tackle", &"", &"", 121)
	var plain_above_events := plain_above.submit_turn(_actions(plain_above.state, &"tackle"))
	check.call(
		"data_v3_defeatist_above_half_hp_inert",
		_damage_to(defeatist_above_events, &"b") == _damage_to(plain_above_events, &"b")
		and not _source_triggered(defeatist_above_events, "defeatist")
		and _damage_offensive_multiplier(defeatist_above_events, &"b") == 10000,
	)

	# Guts partial runtime: poison variants are faithful Attack x1.5 transactions.
	# Burn is intentionally NOT registered because current DamageCalculator would
	# still apply the ordinary burn physical cut, contrary to the source contract.
	var guts_poison := _server(9203, &"tackle", &"guts", &"poison")
	var guts_poison_events := guts_poison.submit_turn(_actions(guts_poison.state, &"tackle"))
	var plain_poison := _server(9203, &"tackle", &"", &"poison")
	var plain_poison_events := plain_poison.submit_turn(_actions(plain_poison.state, &"tackle"))
	var guts_bad := _server(9203, &"tackle", &"guts", &"badly_poisoned")
	var guts_bad_events := guts_bad.submit_turn(_actions(guts_bad.state, &"tackle"))
	check.call(
		"data_v3_guts_poison_partial_subset",
		_damage_to(guts_poison_events, &"b") > _damage_to(plain_poison_events, &"b")
		and _damage_to(guts_bad_events, &"b") == _damage_to(guts_poison_events, &"b")
		and _source_triggered(guts_poison_events, "guts")
		and _source_triggered(guts_bad_events, "guts")
		and _damage_offensive_multiplier(guts_poison_events, &"b") == 15000,
	)

	var guts_burn := _server(9204, &"tackle", &"guts", &"burn")
	var guts_burn_events := guts_burn.submit_turn(_actions(guts_burn.state, &"tackle"))
	var plain_burn := _server(9204, &"tackle", &"", &"burn")
	var plain_burn_events := plain_burn.submit_turn(_actions(plain_burn.state, &"tackle"))
	check.call(
		"data_v3_guts_burn_gap_is_explicit",
		_damage_to(guts_burn_events, &"b") == _damage_to(plain_burn_events, &"b")
		and not _source_triggered(guts_burn_events, "guts")
		and _damage_offensive_multiplier(guts_burn_events, &"b") == 10000,
	)

	# Hustle partial runtime: regular physical damage is boosted, special is inert.
	# Its 0.8x accuracy requirement is intentionally outside this registered subset.
	var hustle_physical := _server(9205, &"tackle", &"hustle")
	var hustle_physical_events := hustle_physical.submit_turn(_actions(hustle_physical.state, &"tackle"))
	var hustle_plain := _server(9205, &"tackle", &"")
	var hustle_plain_events := hustle_plain.submit_turn(_actions(hustle_plain.state, &"tackle"))
	check.call(
		"data_v3_hustle_physical_damage_partial_subset",
		_damage_to(hustle_physical_events, &"b") > _damage_to(hustle_plain_events, &"b")
		and _source_triggered(hustle_physical_events, "hustle")
		and _damage_offensive_multiplier(hustle_physical_events, &"b") == 10000,
	)

	var hustle_special := _server(9206, &"water_gun", &"hustle")
	var hustle_special_events := hustle_special.submit_turn(_actions(hustle_special.state, &"water_gun"))
	var hustle_plain_special := _server(9206, &"water_gun", &"")
	var hustle_plain_special_events := hustle_plain_special.submit_turn(
		_actions(hustle_plain_special.state, &"water_gun")
	)
	check.call(
		"data_v3_hustle_special_inert",
		_damage_to(hustle_special_events, &"b") == _damage_to(hustle_plain_special_events, &"b")
		and not _source_triggered(hustle_special_events, "hustle"),
	)


func _server(
	seed: int,
	move_a: StringName,
	actor_ability: StringName,
	actor_status: StringName = &"",
	actor_hp: int = -1,
) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_offensive_conditions", [
		_creature(&"a", &"squirtle", [move_a], 30),
		_creature(&"b", &"eevee", [&"growl"], 20),
	], seed)
	state.creature(&"a").ability_id = actor_ability
	state.creature(&"a").status_state.persistent_id = actor_status
	if actor_hp >= 0:
		state.creature(&"a").current_hp = actor_hp
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
		StatBlock.new(240, 61, 55, speed, 63, 55),
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


func _damage_offensive_multiplier(events: Array[BattleEvent], target_id: StringName) -> int:
	for event in events:
		if event.kind == BattleEvent.DAMAGE_APPLIED and event.target_id == target_id:
			return int(event.metadata.get("offensive_stat_multiplier_basis_points", -1))
	return -1


func _source_triggered(events: Array[BattleEvent], source_id: String) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.ABILITY_TRIGGERED
			and event.actor_id == &"a"
			and event.metadata.get("source_id", "") == source_id
		):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
