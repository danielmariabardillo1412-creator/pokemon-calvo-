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
	var double_kick := _catalog.move(&"double_kick")
	check.call(
		"data_v3_defensive_damage_move_metadata",
		tackle != null and tackle.damage_class == "physical"
		and water_gun != null and water_gun.damage_class == "special"
		and ember != null and ember.type_id == &"fire"
		and ice_beam != null and ice_beam.type_id == &"ice"
		and _is_fixed_two_hit(double_kick),
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

	# Ice Scales is the exact special-category mirror of Fur Coat.
	var ice_special := _server(8110, &"water_gun", &"ice_scales")
	var ice_special_events := ice_special.submit_turn(_actions(ice_special.state, &"water_gun"))
	var ice_plain_special := _server(8110, &"water_gun", &"")
	var ice_plain_special_events := ice_plain_special.submit_turn(
		_actions(ice_plain_special.state, &"water_gun")
	)
	check.call(
		"data_v3_ice_scales_real_battle_special_reduction",
		_damage_to(ice_special_events, &"b") > 0
		and _damage_to(ice_special_events, &"b") < _damage_to(ice_plain_special_events, &"b")
		and _source_triggered(ice_special_events, "ice_scales", &"b"),
	)

	var ice_physical := _server(8111, &"tackle", &"ice_scales")
	var ice_physical_events := ice_physical.submit_turn(_actions(ice_physical.state, &"tackle"))
	var ice_plain_physical := _server(8111, &"tackle", &"")
	var ice_plain_physical_events := ice_plain_physical.submit_turn(
		_actions(ice_plain_physical.state, &"tackle")
	)
	check.call(
		"data_v3_ice_scales_real_battle_physical_inert",
		_damage_to(ice_physical_events, &"b") == _damage_to(ice_plain_physical_events, &"b")
		and not _source_triggered(ice_physical_events, "ice_scales", &"b"),
	)

	# Multiscale must apply at exact full HP and disappear immediately after any
	# prior damage. The same seed makes the no-ability control deterministic.
	var multi_full := _server(8112, &"tackle", &"multiscale")
	var multi_full_events := multi_full.submit_turn(_actions(multi_full.state, &"tackle"))
	var multi_plain_full := _server(8112, &"tackle", &"")
	var multi_plain_full_events := multi_plain_full.submit_turn(
		_actions(multi_plain_full.state, &"tackle")
	)
	check.call(
		"data_v3_multiscale_real_battle_full_hp_reduction",
		_damage_to(multi_full_events, &"b") > 0
		and _damage_to(multi_full_events, &"b") < _damage_to(multi_plain_full_events, &"b")
		and _source_trigger_count(multi_full_events, "multiscale", &"b") == 1,
	)

	var multi_damaged := _server(8113, &"tackle", &"multiscale", 1)
	var multi_damaged_events := multi_damaged.submit_turn(_actions(multi_damaged.state, &"tackle"))
	var multi_plain_damaged := _server(8113, &"tackle", &"", 1)
	var multi_plain_damaged_events := multi_plain_damaged.submit_turn(
		_actions(multi_plain_damaged.state, &"tackle")
	)
	check.call(
		"data_v3_multiscale_real_battle_missing_hp_inert",
		_damage_to(multi_damaged_events, &"b") == _damage_to(multi_plain_damaged_events, &"b")
		and _source_trigger_count(multi_damaged_events, "multiscale", &"b") == 0,
	)

	# Canonical Double Kick is a fixed two-hit RUNTIME_SUPPORTED move. Each hit goes
	# through _damage() independently, therefore Multiscale must halve only hit one.
	var multi_two_hit := _server(8114, &"double_kick", &"multiscale")
	var multi_two_hit_events := multi_two_hit.submit_turn(
		_actions(multi_two_hit.state, &"double_kick")
	)
	var multi_plain_two_hit := _server(8114, &"double_kick", &"")
	var multi_plain_two_hit_events := multi_plain_two_hit.submit_turn(
		_actions(multi_plain_two_hit.state, &"double_kick")
	)
	var guarded_hits := _damages_to(multi_two_hit_events, &"b")
	var plain_hits := _damages_to(multi_plain_two_hit_events, &"b")
	check.call(
		"data_v3_multiscale_real_battle_multihit_first_only",
		guarded_hits.size() == 2 and plain_hits.size() == 2
		and guarded_hits[0] < plain_hits[0]
		and guarded_hits[1] == plain_hits[1]
		and _source_trigger_count(multi_two_hit_events, "multiscale", &"b") == 1,
	)

	# Heatproof's Fire-move subset is exact, but burn residual is intentionally not
	# routed through MODIFY_DAMAGE yet; this is why its data contract is PARTIAL.
	var heat_fire := _server(8115, &"ember", &"heatproof")
	var heat_fire_events := heat_fire.submit_turn(_actions(heat_fire.state, &"ember"))
	var heat_plain_fire := _server(8115, &"ember", &"")
	var heat_plain_fire_events := heat_plain_fire.submit_turn(
		_actions(heat_plain_fire.state, &"ember")
	)
	check.call(
		"data_v3_heatproof_real_battle_fire_reduction",
		_damage_to(heat_fire_events, &"b") > 0
		and _damage_to(heat_fire_events, &"b") < _damage_to(heat_plain_fire_events, &"b")
		and _source_triggered(heat_fire_events, "heatproof", &"b"),
	)

	var heat_other := _server(8116, &"water_gun", &"heatproof")
	var heat_other_events := heat_other.submit_turn(_actions(heat_other.state, &"water_gun"))
	var heat_plain_other := _server(8116, &"water_gun", &"")
	var heat_plain_other_events := heat_plain_other.submit_turn(
		_actions(heat_plain_other.state, &"water_gun")
	)
	check.call(
		"data_v3_heatproof_real_battle_non_fire_inert",
		_damage_to(heat_other_events, &"b") == _damage_to(heat_plain_other_events, &"b")
		and not _source_triggered(heat_other_events, "heatproof", &"b"),
	)

	var heat_burn_damage := _burn_residual_damage(&"heatproof")
	var plain_burn_damage := _burn_residual_damage(&"")
	check.call(
		"data_v3_heatproof_burn_residual_gap_is_explicit",
		heat_burn_damage > 0 and heat_burn_damage == plain_burn_damage,
	)


func _server(
	seed: int,
	move_a: StringName,
	target_ability: StringName,
	pre_damage: int = 0,
) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_defensive_damage", [
		_creature(&"a", &"charmander", [move_a], 30),
		_creature(&"b", &"squirtle", [&"growl"], 20),
	], seed)
	state.creature(&"b").ability_id = target_ability
	if pre_damage > 0:
		state.creature(&"b").apply_damage(pre_damage)
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


func _damages_to(events: Array[BattleEvent], target_id: StringName) -> Array[int]:
	var out: Array[int] = []
	for event in events:
		if event.kind == BattleEvent.DAMAGE_APPLIED and event.target_id == target_id:
			out.append(event.amount)
	return out


func _source_triggered(
	events: Array[BattleEvent],
	source_id: String,
	owner_id: StringName,
) -> bool:
	return _source_trigger_count(events, source_id, owner_id) > 0


func _source_trigger_count(
	events: Array[BattleEvent],
	source_id: String,
	owner_id: StringName,
) -> int:
	var count := 0
	for event in events:
		if (
			event.kind == BattleEvent.ABILITY_TRIGGERED
			and event.actor_id == owner_id
			and event.metadata.get("source_id", "") == source_id
		):
			count += 1
	return count


func _burn_residual_damage(target_ability: StringName) -> int:
	var server := _server(8117, &"growl", target_ability)
	var target := server.state.creature(&"b")
	target.status_state.persistent_id = StatusSystem.BURN
	var events := StatusSystem.new().process_end_turn(server.state, _catalog)
	for event in events:
		if event.kind == BattleEvent.STATUS_DAMAGE and event.target_id == &"b":
			return event.amount
	return 0


func _is_fixed_two_hit(move: MoveDefinition) -> bool:
	if move == null or move.id != &"double_kick" or move.damage_class != "physical":
		return false
	for spec in move.effect_specs:
		if (
			spec.kind == BattleEffectSpec.MULTI_HIT
			and spec.min_hits == 2
			and spec.max_hits == 2
		):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
