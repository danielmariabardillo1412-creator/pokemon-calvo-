class_name DataFoundationV3AbilityEndTurnTestSuite
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
	var by_id := _by_id(raw.get("abilities", []))
	var registry := BattleEffectRegistry.new()

	var growl := _catalog.move(&"growl")
	check.call(
		"data_v3_end_turn_move_metadata",
		growl != null and growl.power == 0 and growl.damage_class == "status",
	)

	# Structural contract: Speed Boost is one unconditional END_TURN self Speed +1.
	var speed_specs := registry.triggers_for_ability(&"speed_boost", BattleTriggerSpec.END_TURN)
	var speed_spec_ok := speed_specs.size() == 1
	if speed_spec_ok:
		var speed: BattleTriggerSpec = speed_specs[0]
		speed_spec_ok = (
			speed.source_kind == &"ability"
			and speed.source_id == &"speed_boost"
			and speed.conditions.is_empty()
			and speed.effect.kind == BattleEffectSpec.MODIFY_STAT_STAGE
			and speed.effect.target == BattleEffectSpec.SELF
			and speed.effect.value == 1
			and speed.effect.stat_id == StatStages.SPEED
		)
	check.call("data_v3_speed_boost_structural_end_turn_exact", speed_spec_ok)

	# Real battle: the first completed turn raises Speed exactly one stage.
	var speed_server := _server(9401, &"speed_boost")
	var speed_turn_1 := speed_server.submit_turn(_actions(speed_server.state))
	check.call(
		"data_v3_speed_boost_real_battle_turn_one",
		speed_server.state.creature(&"a").stat_stages.get_stage(StatStages.SPEED) == 1
		and _source_trigger_count(speed_turn_1, "speed_boost", &"a") == 1,
	)

	# The next completed turn repeats the same transaction once, reaching +2.
	var speed_turn_2 := speed_server.submit_turn(_actions(speed_server.state))
	check.call(
		"data_v3_speed_boost_real_battle_turn_two",
		speed_server.state.creature(&"a").stat_stages.get_stage(StatStages.SPEED) == 2
		and _source_trigger_count(speed_turn_2, "speed_boost", &"a") == 1,
	)

	# Same state/actions/seed without the ability must not gain Speed.
	var plain_server := _server(9401, &"")
	var plain_turn := plain_server.submit_turn(_actions(plain_server.state))
	check.call(
		"data_v3_speed_boost_plain_control_inert",
		plain_server.state.creature(&"a").stat_stages.get_stage(StatStages.SPEED) == 0
		and _source_trigger_count(plain_turn, "speed_boost", &"a") == 0,
	)

	# Shed Skin remains DATA_ONLY. Its pinned source contains version-sensitive
	# activation probabilities, so there must be no universal END_TURN trigger.
	var shed_server := _server(9402, &"shed_skin")
	shed_server.state.creature(&"a").status_state.persistent_id = StatusSystem.BURN
	var shed_events := shed_server.submit_turn(_actions(shed_server.state))
	check.call(
		"data_v3_shed_skin_version_sensitive_blocker_explicit",
		str((by_id.get("shed_skin", {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
		and registry.triggers_for_ability(&"shed_skin", BattleTriggerSpec.END_TURN).is_empty()
		and shed_server.state.creature(&"a").status_state.persistent_id == StatusSystem.BURN
		and _source_trigger_count(shed_events, "shed_skin", &"a") == 0,
	)

	# Poison Heal requires replacement of poison residual, not a heal after residual.
	# Current TurnExecutor runs StatusSystem before END_TURN ability triggers; keeping
	# the ability non-executable is therefore safer than a superficially correct heal.
	var poison_heal_server := _server(9403, &"poison_heal")
	poison_heal_server.state.creature(&"a").status_state.persistent_id = StatusSystem.POISON
	var poison_heal_hp_before := poison_heal_server.state.creature(&"a").current_hp
	var poison_heal_events := poison_heal_server.submit_turn(_actions(poison_heal_server.state))
	var poison_heal_damage := _status_damage_to(poison_heal_events, &"a")

	var poison_plain_server := _server(9403, &"")
	poison_plain_server.state.creature(&"a").status_state.persistent_id = StatusSystem.POISON
	var poison_plain_events := poison_plain_server.submit_turn(_actions(poison_plain_server.state))
	var poison_plain_damage := _status_damage_to(poison_plain_events, &"a")
	check.call(
		"data_v3_poison_heal_residual_replacement_gap_explicit",
		str((by_id.get("poison_heal", {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
		and registry.triggers_for_ability(&"poison_heal", BattleTriggerSpec.END_TURN).is_empty()
		and poison_heal_damage > 0
		and poison_heal_damage == poison_plain_damage
		and poison_heal_server.state.creature(&"a").current_hp == poison_heal_hp_before - poison_heal_damage
		and _source_trigger_count(poison_heal_events, "poison_heal", &"a") == 0,
	)

	check.call(
		"data_v3_speed_boost_classification_full",
		str((by_id.get("speed_boost", {}) as Dictionary).get("classification", "")) == "RUNTIME_SUPPORTED",
	)


func _server(seed: int, actor_ability: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_end_turn", [
		_creature(&"a", &"torchic", [&"growl"], 30),
		_creature(&"b", &"squirtle", [&"growl"], 20),
	], seed)
	state.creature(&"a").ability_id = actor_ability
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


func _actions(state: BattleState) -> Array[BattleAction]:
	return [
		_client.request_move(
			state.turn + 1, &"a", &"growl", state.opponent_of(&"a").instance_id, &"side_a"
		),
		_client.request_move(
			state.turn + 1, &"b", &"growl", state.opponent_of(&"b").instance_id, &"side_b"
		),
	]


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


func _status_damage_to(events: Array[BattleEvent], target_id: StringName) -> int:
	var total := 0
	for event in events:
		if event.kind == BattleEvent.STATUS_DAMAGE and event.target_id == target_id:
			total += event.amount
	return total


func _by_id(records: Array) -> Dictionary:
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
