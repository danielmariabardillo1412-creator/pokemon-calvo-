class_name DataFoundationV3AbilityEndTurnOpponentTestSuite
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

	var bad_source := _load_json("res://data/api/v2/ability/123/index.json")
	var bad_text := _english_effect_text(bad_source.get("effect_entries", []))
	check.call(
		"data_v3_bad_dreams_source_contract",
		bool(bad_source.get("is_main_series", false))
		and str((bad_source.get("generation", {}) as Dictionary).get("name", "")) == "generation-iv"
		and bad_text.contains("1/8 of their maximum hp")
		and bad_text.contains("after each turn")
		and bad_text.contains("while they are asleep")
		and (bad_source.get("effect_changes", []) as Array).is_empty(),
	)

	var rain_source := _load_json("res://data/api/v2/ability/44/index.json")
	var rain_text := _english_effect_text(rain_source.get("effect_entries", []))
	check.call(
		"data_v3_rain_dish_source_contract",
		bool(rain_source.get("is_main_series", false))
		and str((rain_source.get("generation", {}) as Dictionary).get("name", "")) == "generation-iii"
		and rain_text.contains("1/16 of its maximum hp")
		and rain_text.contains("after each turn during rain")
		and (rain_source.get("effect_changes", []) as Array).is_empty(),
	)

	var ice_source := _load_json("res://data/api/v2/ability/115/index.json")
	var ice_text := _english_effect_text(ice_source.get("effect_entries", []))
	check.call(
		"data_v3_ice_body_source_contract",
		bool(ice_source.get("is_main_series", false))
		and str((ice_source.get("generation", {}) as Dictionary).get("name", "")) == "generation-iv"
		and ice_text.contains("1/16 of its maximum hp")
		and ice_text.contains("after each turn during hail")
		and ice_text.contains("does not take hail damage")
		and (ice_source.get("effect_changes", []) as Array).is_empty(),
	)

	# Weather remains outside current battle state. Target-status support must not be
	# misused to install unconditional Rain Dish or Ice Body healing.
	var weather_blockers_safe := true
	for ability_id in ["rain_dish", "ice_body"]:
		weather_blockers_safe = weather_blockers_safe and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.END_TURN).is_empty()
		)
	check.call("data_v3_end_turn_weather_blockers_stay_data_only", weather_blockers_safe)

	# Owner-state and target-state conditions are distinct contracts. The historical
	# predicate remains owner-local while the new predicate explicitly reads target.
	var owner := _creature(&"probe_owner", &"darkrai", [&"growl"], 30)
	var target_probe := _creature(&"probe_target", &"squirtle", [&"growl"], 20)
	var owner_probe := BattleTriggerSpec.new(
		BattleTriggerSpec.END_TURN,
		&"ability",
		&"owner_probe",
		BattleEffectSpec.new(BattleEffectSpec.MAX_HP_DAMAGE, BattleEffectSpec.OPPONENT, 0, 1250),
		0,
		{"required_persistent_status_ids": ["sleep"]},
	)
	var target_status_probe := BattleTriggerSpec.new(
		BattleTriggerSpec.END_TURN,
		&"ability",
		&"target_probe",
		BattleEffectSpec.new(BattleEffectSpec.MAX_HP_DAMAGE, BattleEffectSpec.OPPONENT, 0, 1250),
		0,
		{"required_target_persistent_status_ids": ["sleep"]},
	)
	var trigger_system := BattleTriggerSystem.new()
	target_probe.status_state.persistent_id = StatusSystem.SLEEP
	check.call(
		"data_v3_target_status_predicate_subjects_explicit",
		not trigger_system.conditions_met(owner_probe, owner, null, target_probe)
		and trigger_system.conditions_met(target_status_probe, owner, null, target_probe),
	)

	# Structural contract: Bad Dreams is exactly one sleeping-target END_TURN 1/8
	# max-HP transaction. No owner-status gate or unconditional damage is present.
	var bad_specs := registry.triggers_for_ability(&"bad_dreams", BattleTriggerSpec.END_TURN)
	var bad_spec_ok := bad_specs.size() == 1
	if bad_spec_ok:
		var bad: BattleTriggerSpec = bad_specs[0]
		bad_spec_ok = (
			bad.source_kind == &"ability"
			and bad.source_id == &"bad_dreams"
			and bad.conditions.get("required_target_persistent_status_ids", []) == ["sleep"]
			and not bad.conditions.has("required_persistent_status_ids")
			and bad.effect.kind == BattleEffectSpec.MAX_HP_DAMAGE
			and bad.effect.target == BattleEffectSpec.OPPONENT
			and bad.effect.ratio_basis_points == 1250
		)
	check.call("data_v3_bad_dreams_structural_target_status_exact", bad_spec_ok)

	# Real battle: a sleeping opponent loses exactly 1/8 max HP at end turn and the
	# ability emits exactly once. Sleep itself has no end-turn HP transaction.
	var bad_server := _server(9501, &"bad_dreams")
	var sleeping_target := bad_server.state.creature(&"b")
	sleeping_target.status_state.persistent_id = StatusSystem.SLEEP
	sleeping_target.status_state.turns_remaining = 3
	var hp_before := sleeping_target.current_hp
	var bad_events := bad_server.submit_turn(_actions(bad_server.state))
	check.call(
		"data_v3_bad_dreams_real_battle_sleeping_target",
		sleeping_target.current_hp == hp_before - 30
		and sleeping_target.status_state.persistent_id == StatusSystem.SLEEP
		and _source_trigger_count(bad_events, "bad_dreams", &"a") == 1,
	)

	# Same seed/state without sleep must be inert: no residual damage and no event.
	var awake_server := _server(9501, &"bad_dreams")
	var awake_target := awake_server.state.creature(&"b")
	var awake_hp_before := awake_target.current_hp
	var awake_events := awake_server.submit_turn(_actions(awake_server.state))
	check.call(
		"data_v3_bad_dreams_real_battle_awake_target_inert",
		awake_target.current_hp == awake_hp_before
		and _source_trigger_count(awake_events, "bad_dreams", &"a") == 0,
	)

	check.call(
		"data_v3_bad_dreams_classification_full",
		str((by_id.get("bad_dreams", {}) as Dictionary).get("classification", "")) == "RUNTIME_SUPPORTED",
	)

	var counts := {"RUNTIME_SUPPORTED": 0, "PARTIAL_RUNTIME": 0, "DATA_ONLY": 0}
	for ability in raw.get("abilities", []):
		if ability is Dictionary:
			var classification := str(ability.get("classification", ""))
			if counts.has(classification):
				counts[classification] = int(counts[classification]) + 1
	check.call(
		"data_v3_target_state_promotions_update_counts",
		int(counts["RUNTIME_SUPPORTED"]) == 21
		and int(counts["PARTIAL_RUNTIME"]) == 14
		and int(counts["DATA_ONLY"]) == 338,
	)


func _server(seed: int, actor_ability: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_end_turn_opponent", [
		_creature(&"a", &"darkrai", [&"growl"], 30),
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


func _english_effect_text(entries: Array) -> String:
	var parts: Array[String] = []
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var language: Dictionary = entry.get("language", {})
		if str(language.get("name", "")) != "en":
			continue
		parts.append(str(entry.get("effect", "")))
		parts.append(str(entry.get("short_effect", "")))
	return " ".join(parts).to_lower()


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
