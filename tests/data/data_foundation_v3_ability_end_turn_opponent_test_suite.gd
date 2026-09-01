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

	# Immutable source guards. These are intentionally test-side provenance checks:
	# this tranche makes no adapter/runtime classification change.
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

	# All three remain non-executable. Bad Dreams needs target-status gating; Rain
	# Dish and Ice Body need weather state, and Ice Body additionally needs hail
	# residual immunity. Do not install an unconditional END_TURN approximation.
	var blockers_stay_data_only := true
	for ability_id in ["bad_dreams", "rain_dish", "ice_body"]:
		blockers_stay_data_only = blockers_stay_data_only and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.END_TURN).is_empty()
		)
	check.call("data_v3_end_turn_opponent_blockers_stay_data_only", blockers_stay_data_only)

	# The only persistent-status predicate currently available is explicitly owner-
	# local. A sleeping opponent cannot satisfy it for an awake ability holder.
	var owner := _creature(&"probe_owner", &"darkrai", [&"growl"], 30)
	var probe := BattleTriggerSpec.new(
		BattleTriggerSpec.END_TURN,
		&"ability",
		&"bad_dreams_probe",
		BattleEffectSpec.new(
			BattleEffectSpec.MAX_HP_DAMAGE,
			BattleEffectSpec.OPPONENT,
			0,
			1250,
		),
		0,
		{"required_persistent_status_ids": ["sleep"]},
	)
	var trigger_system := BattleTriggerSystem.new()
	var awake_owner_rejected := not trigger_system.conditions_met(probe, owner, null)
	owner.status_state.persistent_id = StatusSystem.SLEEP
	var sleeping_owner_accepted := trigger_system.conditions_met(probe, owner, null)
	check.call(
		"data_v3_bad_dreams_existing_status_predicate_is_owner_local",
		awake_owner_rejected and sleeping_owner_accepted,
	)

	# Real battle boundary: even with the opponent asleep, Bad Dreams must not emit
	# a false unconditional trigger or damage until target-status semantics exist.
	var bad_server := _server(9501, &"bad_dreams")
	var target := bad_server.state.creature(&"b")
	target.status_state.persistent_id = StatusSystem.SLEEP
	target.status_state.turns_remaining = 3
	var hp_before := target.current_hp
	var bad_events := bad_server.submit_turn(_actions(bad_server.state))
	check.call(
		"data_v3_bad_dreams_sleeping_target_gap_explicit",
		target.current_hp == hp_before
		and target.status_state.persistent_id == StatusSystem.SLEEP
		and _source_trigger_count(bad_events, "bad_dreams", &"a") == 0,
	)

	# Negative tranche: canonical coverage must remain exactly the certified #89
	# partition. Any movement here requires a deliberate follow-up implementation.
	var counts := {"RUNTIME_SUPPORTED": 0, "PARTIAL_RUNTIME": 0, "DATA_ONLY": 0}
	for ability in raw.get("abilities", []):
		if ability is Dictionary:
			var classification := str(ability.get("classification", ""))
			if counts.has(classification):
				counts[classification] = int(counts[classification]) + 1
	check.call(
		"data_v3_end_turn_opponent_negative_audit_preserves_counts",
		int(counts["RUNTIME_SUPPORTED"]) == 19
		and int(counts["PARTIAL_RUNTIME"]) == 14
		and int(counts["DATA_ONLY"]) == 340,
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
