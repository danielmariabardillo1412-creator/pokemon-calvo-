class_name DataFoundationV3AbilityMovePropertyTestSuite
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

	var double_edge := _catalog.move(&"double_edge")
	var tackle := _catalog.move(&"tackle")
	var jump_kick := _catalog.move(&"jump_kick")
	check.call(
		"data_v3_reckless_structured_move_metadata",
		double_edge != null
		and _move_has_effect_kind(double_edge, BattleEffectSpec.RECOIL)
		and tackle != null
		and not _move_has_effect_kind(tackle, BattleEffectSpec.RECOIL)
		and jump_kick != null
		and not _move_has_effect_kind(jump_kick, BattleEffectSpec.RECOIL),
	)

	# Faithful subset: a canonical structured-recoil move gets the 1.2x multiplier.
	# Matched seeds/stats ensure the only intended damage difference is Reckless.
	var boosted := _server(8301, &"double_edge", &"reckless")
	var boosted_events := boosted.submit_turn(_actions(boosted.state, &"double_edge"))
	var plain := _server(8301, &"double_edge", &"")
	var plain_events := plain.submit_turn(_actions(plain.state, &"double_edge"))
	check.call(
		"data_v3_reckless_real_battle_recoil_boost",
		_damage_to(boosted_events, &"b") > _damage_to(plain_events, &"b")
		and _damage_to(plain_events, &"b") > 0
		and _source_triggered(boosted_events, "reckless", &"a")
		and _recoil_to(boosted_events, &"a") > 0
		and _recoil_to(boosted_events, &"a") >= _recoil_to(plain_events, &"a"),
	)

	# Ordinary non-recoil damage must be bit-for-bit equivalent and emit no ability
	# trigger under the same seed.
	var inert := _server(8302, &"tackle", &"reckless")
	var inert_events := inert.submit_turn(_actions(inert.state, &"tackle"))
	var inert_plain := _server(8302, &"tackle", &"")
	var inert_plain_events := inert_plain.submit_turn(_actions(inert_plain.state, &"tackle"))
	check.call(
		"data_v3_reckless_real_battle_non_recoil_inert",
		_damage_to(inert_events, &"b") == _damage_to(inert_plain_events, &"b")
		and _damage_to(inert_events, &"b") > 0
		and not _source_triggered(inert_events, "reckless", &"a"),
	)

	# Explicit partial boundary: Jump Kick is a source-defined crash move for
	# Reckless, but current DATA V3 does not encode crash-on-miss as RECOIL. Find a
	# deterministic seed where it lands, then prove Reckless currently stays inert.
	var jump_seed := -1
	var jump_plain_damage := 0
	for seed in range(1, 301):
		var candidate := _server(seed, &"jump_kick", &"")
		var candidate_events := candidate.submit_turn(_actions(candidate.state, &"jump_kick"))
		var candidate_damage := _damage_to(candidate_events, &"b")
		if candidate_damage > 0:
			jump_seed = seed
			jump_plain_damage = candidate_damage
			break
	var crash_boundary_ok := jump_seed > 0
	if crash_boundary_ok:
		var jump_reckless := _server(jump_seed, &"jump_kick", &"reckless")
		var jump_reckless_events := jump_reckless.submit_turn(
			_actions(jump_reckless.state, &"jump_kick")
		)
		crash_boundary_ok = (
			_damage_to(jump_reckless_events, &"b") == jump_plain_damage
			and not _source_triggered(jump_reckless_events, "reckless", &"a")
		)
	check.call("data_v3_reckless_crash_move_partial_boundary", crash_boundary_ok)

	# The audited neighboring abilities remain non-executable. This suite does not
	# infer punch/bite/pulse/slicing categories from names or prose.
	var by_id := _ability_by_id(raw.get("abilities", []))
	var blockers_safe := true
	for ability_id in [
		"long_reach", "technician", "iron_fist", "strong_jaw", "mega_launcher", "sharpness",
	]:
		blockers_safe = blockers_safe and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
		)
	check.call("data_v3_move_property_adjacent_blockers_data_only", blockers_safe)


func _server(seed: int, move_a: StringName, attacker_ability: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_move_property", [
		_creature(&"a", &"charmander", [move_a], 30),
		_creature(&"b", &"squirtle", [&"growl"], 20),
	], seed)
	state.creature(&"a").ability_id = attacker_ability
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


func _recoil_to(events: Array[BattleEvent], target_id: StringName) -> int:
	for event in events:
		if event.kind == BattleEvent.RECOIL_DAMAGE and event.target_id == target_id:
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
			and event.actor_id == owner_id
			and event.metadata.get("source_id", "") == source_id
		):
			return true
	return false


func _move_has_effect_kind(move: MoveDefinition, wanted_kind: StringName) -> bool:
	if move == null:
		return false
	for spec in move.effect_specs:
		if _effect_spec_has_kind(spec, wanted_kind):
			return true
	return false


func _effect_spec_has_kind(spec: BattleEffectSpec, wanted_kind: StringName) -> bool:
	if spec.kind == wanted_kind:
		return true
	for child in spec.children:
		if _effect_spec_has_kind(child, wanted_kind):
			return true
	return false


func _ability_by_id(records: Array) -> Dictionary:
	var result := {}
	for record in records:
		if record is Dictionary:
			result[str(record.get("id", ""))] = record
	return result


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
