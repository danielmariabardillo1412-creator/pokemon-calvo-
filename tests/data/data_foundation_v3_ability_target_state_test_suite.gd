class_name DataFoundationV3AbilityTargetStateTestSuite
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

	var merciless_source := _load_json("res://data/api/v2/ability/196/index.json")
	var merciless_text := _english_effect_text(merciless_source.get("effect_entries", []))
	check.call(
		"data_v3_merciless_source_contract",
		bool(merciless_source.get("is_main_series", false))
		and str((merciless_source.get("generation", {}) as Dictionary).get("name", "")) == "generation-vii"
		and merciless_text.contains("critical hit")
		and merciless_text.contains("poisoned targets")
		and (merciless_source.get("effect_changes", []) as Array).is_empty(),
	)

	var rivalry_source := _load_json("res://data/api/v2/ability/79/index.json")
	var rivalry_text := _english_effect_text(rivalry_source.get("effect_entries", []))
	check.call(
		"data_v3_rivalry_source_contract",
		bool(rivalry_source.get("is_main_series", false))
		and str((rivalry_source.get("generation", {}) as Dictionary).get("name", "")) == "generation-iv"
		and rivalry_text.contains("1.25× as much regular damage")
		and rivalry_text.contains("same gender")
		and rivalry_text.contains("0.75× as much regular damage")
		and rivalry_text.contains("opposite gender")
		and rivalry_text.contains("genderless")
		and (rivalry_source.get("effect_changes", []) as Array).is_empty(),
	)

	var stakeout_source := _load_json("res://data/api/v2/ability/198/index.json")
	var stakeout_text := _english_effect_text(stakeout_source.get("effect_entries", []))
	check.call(
		"data_v3_stakeout_source_contract",
		bool(stakeout_source.get("is_main_series", false))
		and str((stakeout_source.get("generation", {}) as Dictionary).get("name", "")) == "generation-vii"
		and stakeout_text.contains("double power")
		and stakeout_text.contains("switched in this turn")
		and (stakeout_source.get("effect_changes", []) as Array).is_empty(),
	)

	var merciless_specs := registry.triggers_for_ability(&"merciless", BattleTriggerSpec.MODIFY_DAMAGE)
	var merciless_ok := merciless_specs.size() == 1
	if merciless_ok:
		var merciless: BattleTriggerSpec = merciless_specs[0]
		merciless_ok = (
			merciless.source_kind == &"ability"
			and merciless.source_id == &"merciless"
			and String(merciless.conditions.get("damage_role", "")) == "actor"
			and merciless.conditions.get("required_target_persistent_status_ids", [])
				== ["poison", "badly_poisoned"]
			and bool(merciless.conditions.get("force_critical", false))
			and not merciless.conditions.has("multiplier_bp")
			and not merciless.conditions.has("offensive_stat_multiplier_bp")
			and merciless.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_merciless_structural_target_status_exact", merciless_ok)

	# Natural critical chance is zero in these probes, so CRITICAL_HIT can only be
	# produced by Merciless. Both poison representations must satisfy the source.
	for pair in [[StatusSystem.POISON, "poison"], [StatusSystem.BADLY_POISONED, "badly_poisoned"]]:
		var status_id: StringName = pair[0]
		var label := String(pair[1])
		var server := _server(9601, &"merciless")
		server.state.creature(&"b").status_state.persistent_id = status_id
		var events := server.submit_turn(_actions(server.state))
		check.call(
			"data_v3_merciless_real_battle_%s_forces_critical" % label,
			_event_count(events, BattleEvent.CRITICAL_HIT, &"a") == 1
			and _source_trigger_count(events, "merciless", &"a") == 1,
		)

	# Healthy and unrelated-status targets must remain inert when natural crit chance
	# is zero. This proves the new predicate is not a blanket critical switch.
	for pair in [[&"", "healthy"], [StatusSystem.BURN, "burned"]]:
		var status_id: StringName = pair[0]
		var label := String(pair[1])
		var server := _server(9602, &"merciless")
		server.state.creature(&"b").status_state.persistent_id = status_id
		var events := server.submit_turn(_actions(server.state))
		check.call(
			"data_v3_merciless_real_battle_%s_target_inert" % label,
			_event_count(events, BattleEvent.CRITICAL_HIT, &"a") == 0
			and _source_trigger_count(events, "merciless", &"a") == 0,
		)

	check.call(
		"data_v3_merciless_classification_full",
		str((by_id.get("merciless", {}) as Dictionary).get("classification", "")) == "RUNTIME_SUPPORTED",
	)

	# Rivalry needs user/target gender data and comparison semantics. Stakeout needs
	# target switch-history state for the current turn. Neither is implied by the new
	# persistent-status predicate, so both remain deliberately non-executable.
	var adjacent_blockers_safe := true
	for ability_id in ["rivalry", "stakeout"]:
		adjacent_blockers_safe = adjacent_blockers_safe and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE).is_empty()
		)
	check.call("data_v3_target_state_adjacent_blockers_stay_data_only", adjacent_blockers_safe)


func _server(seed: int, actor_ability: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_target_state", [
		_creature(&"a", &"toxapex", [&"tackle"], 30),
		_creature(&"b", &"squirtle", [&"growl"], 20),
	], seed)
	state.creature(&"a").ability_id = actor_ability
	var ruleset := BattleRuleset.new()
	ruleset.critical_chance_numerator = 0
	return AuthoritativeBattleServer.new(state, _catalog, ruleset)


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
		StatBlock.new(240, 70, 60, speed, 60, 60),
		moves,
	)


func _actions(state: BattleState) -> Array[BattleAction]:
	return [
		_client.request_move(
			state.turn + 1, &"a", &"tackle", state.opponent_of(&"a").instance_id, &"side_a"
		),
		_client.request_move(
			state.turn + 1, &"b", &"growl", state.opponent_of(&"b").instance_id, &"side_b"
		),
	]


func _event_count(events: Array[BattleEvent], kind: StringName, actor_id: StringName) -> int:
	var count := 0
	for event in events:
		if event.kind == kind and event.actor_id == actor_id:
			count += 1
	return count


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
