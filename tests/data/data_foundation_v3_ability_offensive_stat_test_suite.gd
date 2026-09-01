class_name DataFoundationV3AbilityOffensiveStatTestSuite
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
		"data_v3_offensive_stat_move_metadata",
		tackle != null and tackle.damage_class == "physical"
		and water_gun != null and water_gun.damage_class == "special",
	)

	# Preserve the historical positional calculator API. The eighth argument remains
	# force_critical; the new offensive-stat multiplier is appended as argument nine.
	var direct_attacker := _creature(&"calc_a", &"squirtle", [&"tackle"], 30)
	var direct_defender := _creature(&"calc_b", &"eevee", [&"growl"], 20)
	var calculator := DamageCalculator.new()
	var legacy := calculator.calculate(
		direct_attacker,
		direct_defender,
		tackle,
		_catalog,
		SeededRandomSource.new(9000),
		BattleRuleset.new(),
		10000,
		0,
	)
	var explicit_default := calculator.calculate(
		direct_attacker,
		direct_defender,
		tackle,
		_catalog,
		SeededRandomSource.new(9000),
		BattleRuleset.new(),
		10000,
		0,
		10000,
	)
	check.call(
		"data_v3_offensive_stat_calculator_positional_compatibility",
		int(legacy.amount) == int(explicit_default.amount)
		and not bool(legacy.critical)
		and int(explicit_default.offensive_stat_multiplier_basis_points) == 10000,
	)

	# Attack is deliberately odd (61). Multiplying Attack by two before the base
	# formula is not equivalent to multiplying final damage by two because integer
	# floors occur inside the base formula. This pins the semantic distinction.
	var stat_doubled := calculator.calculate(
		direct_attacker,
		direct_defender,
		tackle,
		_catalog,
		SeededRandomSource.new(9001),
		BattleRuleset.new(),
		10000,
		0,
		20000,
	)
	var final_damage_doubled := calculator.calculate(
		direct_attacker,
		direct_defender,
		tackle,
		_catalog,
		SeededRandomSource.new(9001),
		BattleRuleset.new(),
		20000,
		0,
		10000,
	)
	check.call(
		"data_v3_offensive_stat_is_not_final_damage_multiplier",
		int(stat_doubled.amount) > 0
		and int(final_damage_doubled.amount) > 0
		and int(stat_doubled.amount) != int(final_damage_doubled.amount)
		and int(stat_doubled.offensive_stat_multiplier_basis_points) == 20000,
	)

	# Huge Power: exact Attack x2 on physical damage; special damage is inert.
	var huge_physical := _server(9002, &"tackle", &"huge_power")
	var huge_physical_events := huge_physical.submit_turn(_actions(huge_physical.state, &"tackle"))
	var plain_physical := _server(9002, &"tackle", &"")
	var plain_physical_events := plain_physical.submit_turn(_actions(plain_physical.state, &"tackle"))
	check.call(
		"data_v3_huge_power_real_battle_physical_attack_double",
		_damage_to(huge_physical_events, &"b") > _damage_to(plain_physical_events, &"b")
		and _source_triggered(huge_physical_events, "huge_power")
		and _damage_offensive_multiplier(huge_physical_events, &"b") == 20000,
	)

	var huge_special := _server(9003, &"water_gun", &"huge_power")
	var huge_special_events := huge_special.submit_turn(_actions(huge_special.state, &"water_gun"))
	var plain_special := _server(9003, &"water_gun", &"")
	var plain_special_events := plain_special.submit_turn(_actions(plain_special.state, &"water_gun"))
	check.call(
		"data_v3_huge_power_real_battle_special_inert",
		_damage_to(huge_special_events, &"b") == _damage_to(plain_special_events, &"b")
		and not _source_triggered(huge_special_events, "huge_power")
		and _damage_offensive_multiplier(huge_special_events, &"b") == 10000,
	)

	# Pure Power is source-identical and must produce the same physical transaction.
	var pure_physical := _server(9004, &"tackle", &"pure_power")
	var pure_physical_events := pure_physical.submit_turn(_actions(pure_physical.state, &"tackle"))
	var huge_same_seed := _server(9004, &"tackle", &"huge_power")
	var huge_same_seed_events := huge_same_seed.submit_turn(_actions(huge_same_seed.state, &"tackle"))
	check.call(
		"data_v3_pure_power_matches_huge_power",
		_damage_to(pure_physical_events, &"b") == _damage_to(huge_same_seed_events, &"b")
		and _source_triggered(pure_physical_events, "pure_power")
		and _damage_offensive_multiplier(pure_physical_events, &"b") == 20000,
	)

	# Toxic Boost accepts either persistent poison representation, but no other state.
	var toxic_poison := _server(9005, &"tackle", &"toxic_boost", &"poison")
	var toxic_poison_events := toxic_poison.submit_turn(_actions(toxic_poison.state, &"tackle"))
	var plain_poison := _server(9005, &"tackle", &"", &"poison")
	var plain_poison_events := plain_poison.submit_turn(_actions(plain_poison.state, &"tackle"))
	var toxic_bad := _server(9005, &"tackle", &"toxic_boost", &"badly_poisoned")
	var toxic_bad_events := toxic_bad.submit_turn(_actions(toxic_bad.state, &"tackle"))
	check.call(
		"data_v3_toxic_boost_poison_variants",
		_damage_to(toxic_poison_events, &"b") > _damage_to(plain_poison_events, &"b")
		and _damage_to(toxic_bad_events, &"b") == _damage_to(toxic_poison_events, &"b")
		and _source_triggered(toxic_poison_events, "toxic_boost")
		and _source_triggered(toxic_bad_events, "toxic_boost")
		and _damage_offensive_multiplier(toxic_poison_events, &"b") == 15000,
	)

	var toxic_clean := _server(9006, &"tackle", &"toxic_boost")
	var toxic_clean_events := toxic_clean.submit_turn(_actions(toxic_clean.state, &"tackle"))
	var plain_clean := _server(9006, &"tackle", &"")
	var plain_clean_events := plain_clean.submit_turn(_actions(plain_clean.state, &"tackle"))
	var toxic_special := _server(9007, &"water_gun", &"toxic_boost", &"poison")
	var toxic_special_events := toxic_special.submit_turn(_actions(toxic_special.state, &"water_gun"))
	var plain_poison_special := _server(9007, &"water_gun", &"", &"poison")
	var plain_poison_special_events := plain_poison_special.submit_turn(
		_actions(plain_poison_special.state, &"water_gun")
	)
	check.call(
		"data_v3_toxic_boost_inert_boundaries",
		_damage_to(toxic_clean_events, &"b") == _damage_to(plain_clean_events, &"b")
		and not _source_triggered(toxic_clean_events, "toxic_boost")
		and _damage_to(toxic_special_events, &"b") == _damage_to(plain_poison_special_events, &"b")
		and not _source_triggered(toxic_special_events, "toxic_boost"),
	)

	# Flare Boost is the special-stat mirror: burn + special activates; clean or
	# physical does not. Physical burn penalty remains the normal ruleset behavior.
	var flare_burn := _server(9008, &"water_gun", &"flare_boost", &"burn")
	var flare_burn_events := flare_burn.submit_turn(_actions(flare_burn.state, &"water_gun"))
	var plain_burn := _server(9008, &"water_gun", &"", &"burn")
	var plain_burn_events := plain_burn.submit_turn(_actions(plain_burn.state, &"water_gun"))
	check.call(
		"data_v3_flare_boost_burn_special",
		_damage_to(flare_burn_events, &"b") > _damage_to(plain_burn_events, &"b")
		and _source_triggered(flare_burn_events, "flare_boost")
		and _damage_offensive_multiplier(flare_burn_events, &"b") == 15000,
	)

	var flare_clean := _server(9009, &"water_gun", &"flare_boost")
	var flare_clean_events := flare_clean.submit_turn(_actions(flare_clean.state, &"water_gun"))
	var plain_clean_special := _server(9009, &"water_gun", &"")
	var plain_clean_special_events := plain_clean_special.submit_turn(
		_actions(plain_clean_special.state, &"water_gun")
	)
	var flare_physical := _server(9010, &"tackle", &"flare_boost", &"burn")
	var flare_physical_events := flare_physical.submit_turn(_actions(flare_physical.state, &"tackle"))
	var plain_burn_physical := _server(9010, &"tackle", &"", &"burn")
	var plain_burn_physical_events := plain_burn_physical.submit_turn(
		_actions(plain_burn_physical.state, &"tackle")
	)
	check.call(
		"data_v3_flare_boost_inert_boundaries",
		_damage_to(flare_clean_events, &"b") == _damage_to(plain_clean_special_events, &"b")
		and not _source_triggered(flare_clean_events, "flare_boost")
		and _damage_to(flare_physical_events, &"b") == _damage_to(plain_burn_physical_events, &"b")
		and not _source_triggered(flare_physical_events, "flare_boost"),
	)


func _server(
	seed: int,
	move_a: StringName,
	actor_ability: StringName,
	actor_status: StringName = &"",
) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_offensive_stat", [
		_creature(&"a", &"squirtle", [move_a], 30),
		_creature(&"b", &"eevee", [&"growl"], 20),
	], seed)
	state.creature(&"a").ability_id = actor_ability
	state.creature(&"a").status_state.persistent_id = actor_status
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
