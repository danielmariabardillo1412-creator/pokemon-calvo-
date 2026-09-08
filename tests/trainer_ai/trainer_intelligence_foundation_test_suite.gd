class_name TrainerIntelligenceFoundationTestSuite
extends RefCounted

const TEST_HIT := &"trainer_intel_test_hit"
const TEST_IDLE := &"trainer_intel_test_idle"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	var tests := [
		"_test_simulation_fork_isolation",
		"_test_simulation_fork_determinism",
		"_test_memory_visibility_and_reveals",
		"_test_belief_state_separates_inference_from_reveal",
		"_test_observation_hides_unrevealed_information",
		"_test_decision_context_is_detached",
		"_test_decision_context_campaign_snapshot_is_detached",
		"_test_decision_trace_is_serializable",
		"_test_brain_contract_has_no_default_policy",
	]
	for name in tests:
		print("TRAINER_INTELLIGENCE_TEST %s" % name)
		self.call(name)


func _import_pokeapi() -> GameData:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	return DataImporter.new().import_dataset(raw, manifest)["game_data"]


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _add_test_moves() -> void:
	if not _catalog.move_catalog.has(TEST_HIT):
		var hit := MoveDefinition.new()
		hit.id = TEST_HIT
		hit.display_name = "Trainer Intelligence Test Hit"
		hit.power = 20
		hit.type_id = &"normal"
		hit.priority = 0
		hit.damage_class = "physical"
		hit.accuracy = -1
		hit.pp = 30
		_catalog.add_move(hit)
	if not _catalog.move_catalog.has(TEST_IDLE):
		var idle := MoveDefinition.new()
		idle.id = TEST_IDLE
		idle.display_name = "Trainer Intelligence Test Idle"
		idle.power = 0
		idle.type_id = &"normal"
		idle.priority = 0
		idle.damage_class = "status"
		idle.accuracy = -1
		idle.pp = 40
		_catalog.add_move(idle)


func _creature(
	species_id: StringName,
	seed_value: int,
	instance_id: StringName,
	move_ids: Array[StringName],
) -> CreatureInstance:
	var creature := CreatureFactory.create(
		_catalog.species_catalog.get_by_id(species_id),
		10,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	)
	for move_id in move_ids:
		if not creature.has_move(move_id):
			creature.add_move(move_id, _catalog)
	return creature


func _battle_state(seed_value: int = 123) -> BattleState:
	var player := _creature(&"bulbasaur", 1, &"intel_player", [TEST_HIT, TEST_IDLE])
	var player_bench := _creature(&"squirtle", 2, &"intel_player_bench", [TEST_IDLE])
	var trainer := _creature(&"charmander", 3, &"intel_trainer", [TEST_HIT, TEST_IDLE])
	var trainer_bench := _creature(&"pikachu", 4, &"intel_trainer_bench", [TEST_IDLE])
	return BattleState.create_with_parties(
		&"trainer_intelligence_test",
		[player, player_bench],
		[trainer, trainer_bench],
		seed_value,
	)


func _move_actions(state: BattleState, move_a: StringName, move_b: StringName) -> Array[BattleAction]:
	var a := state.active_for_side(&"side_a")
	var b := state.active_for_side(&"side_b")
	var actions: Array[BattleAction] = [
		_client.request_move(state.turn + 1, a.instance_id, move_a, b.instance_id, &"side_a"),
		_client.request_move(state.turn + 1, b.instance_id, move_b, a.instance_id, &"side_b"),
	]
	return actions


func _event_dicts(events: Array[BattleEvent]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event in events:
		out.append(event.to_dict())
	return out


func _opponent_view(observation: TrainerObservation, creature_id: StringName) -> Dictionary:
	for view in observation.observed_opponents:
		if StringName(view.get("instance_id", "")) == creature_id:
			return view
	return {}


func _test_simulation_fork_isolation() -> void:
	var live_state := _battle_state(91)
	var live_server := AuthoritativeBattleServer.new(live_state, _catalog)
	var live_player := live_state.creature(&"intel_player")
	var live_pp := live_player.move_slot(TEST_HIT).current_pp
	var live_hp := live_player.current_hp
	var fork := BattleSimulationFork.from_state(live_server.state, _catalog)
	var fork_state := fork.state()
	var fork_player := fork_state.creature(&"intel_player")

	_check.call("intel_fork_created", fork != null and fork_state != null)
	_check.call("intel_fork_state_detached", fork_state != live_state)
	_check.call("intel_fork_creature_detached", fork_player != live_player)
	_check.call("intel_fork_side_detached", fork_state.sides[0] != live_state.sides[0])
	_check.call("intel_fork_status_detached", fork_player.status_state != live_player.status_state)
	_check.call("intel_fork_stages_detached", fork_player.stat_stages != live_player.stat_stages)
	_check.call("intel_fork_move_slot_detached", fork_player.move_slot(TEST_HIT) != live_player.move_slot(TEST_HIT))

	fork_player.current_hp = 1
	fork_player.move_slot(TEST_HIT).current_pp -= 1
	fork_player.stat_stages.change(StatStages.ATTACK, 3)
	fork_player.status_state.add_volatile(&"intel_test_volatile", {"turns": 2})
	fork_state.switch_active(&"side_a", &"intel_player_bench")
	_check.call("intel_fork_hp_no_live_mutation", live_player.current_hp == live_hp)
	_check.call("intel_fork_pp_no_live_mutation", live_player.move_slot(TEST_HIT).current_pp == live_pp)
	_check.call("intel_fork_stage_no_live_mutation", live_player.stat_stages.get_stage(StatStages.ATTACK) == 0)
	_check.call("intel_fork_status_no_live_mutation", not live_player.status_state.has_volatile(&"intel_test_volatile"))
	_check.call("intel_fork_switch_no_live_mutation", live_state.active_for_side(&"side_a").instance_id == &"intel_player")


func _test_simulation_fork_determinism() -> void:
	var live_state := _battle_state(31415)
	var live_server := AuthoritativeBattleServer.new(live_state, _catalog)
	live_server.submit_turn(_move_actions(live_state, TEST_HIT, TEST_HIT))
	var live_turn_before := live_state.turn
	var live_snapshot_before := JSON.stringify(live_server.snapshot())
	var first := BattleSimulationFork.from_state(live_state, _catalog)
	var second := BattleSimulationFork.from_state(live_state, _catalog)
	var first_events := first.submit_turn(_move_actions(first.state(), TEST_HIT, TEST_HIT))
	var second_events := second.submit_turn(_move_actions(second.state(), TEST_HIT, TEST_HIT))

	_check.call(
		"intel_fork_same_events",
		JSON.stringify(_event_dicts(first_events)) == JSON.stringify(_event_dicts(second_events)),
	)
	_check.call(
		"intel_fork_same_result",
		JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot()),
	)
	_check.call("intel_fork_does_not_advance_live", live_state.turn == live_turn_before)
	_check.call("intel_fork_does_not_change_live_snapshot", JSON.stringify(live_server.snapshot()) == live_snapshot_before)
	var child := first.fork()
	_check.call("intel_nested_fork_created", child != null and child.state() != first.state())
	_check.call("intel_nested_fork_same_start", JSON.stringify(child.snapshot()) == JSON.stringify(first.snapshot()))


func _test_memory_visibility_and_reveals() -> void:
	var state := _battle_state(22)
	AuthoritativeBattleServer.new(state, _catalog)
	var memory := TrainerBattleMemory.new()
	_check.call("intel_memory_begin", memory.begin(state, &"side_b"))
	_check.call("intel_memory_initial_active_seen", memory.has_seen(&"intel_player"))
	_check.call("intel_memory_initial_bench_hidden", not memory.has_seen(&"intel_player_bench"))

	var events: Array[BattleEvent] = [
		BattleEvent.new(BattleEvent.ACTION_USED, 1, &"intel_player", &"intel_trainer", TEST_HIT),
		BattleEvent.new(BattleEvent.ABILITY_TRIGGERED, 1, &"intel_player", &"intel_trainer", &"", 0, {"source_id": "overgrow"}),
		BattleEvent.new(BattleEvent.ITEM_TRIGGERED, 1, &"intel_player", &"intel_trainer", &"", 0, {"source_id": "leftovers"}),
		BattleEvent.new(BattleEvent.SWITCHED, 1, &"intel_player", &"intel_player_bench"),
	]
	_check.call("intel_memory_observe", memory.observe_events(events, state))
	_check.call("intel_memory_move_revealed", memory.revealed_move_ids(&"intel_player").has(TEST_HIT))
	_check.call("intel_memory_ability_revealed", memory.revealed_ability_id(&"intel_player") == &"overgrow")
	_check.call("intel_memory_item_revealed", memory.revealed_item_id(&"intel_player") == &"leftovers")
	_check.call("intel_memory_switch_reveals_bench", memory.has_seen(&"intel_player_bench"))
	_check.call("intel_memory_event_log", memory.event_log.size() == 4)
	var restored := TrainerBattleMemory.from_dict(JSON.parse_string(JSON.stringify(memory.to_dict())))
	_check.call("intel_memory_round_trip", JSON.stringify(restored.to_dict()) == JSON.stringify(memory.to_dict()))


func _test_belief_state_separates_inference_from_reveal() -> void:
	var state := _battle_state(23)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	var belief := TrainerBeliefState.new()
	_check.call("intel_belief_begin", belief.begin(memory))
	belief.set_candidate(&"intel_player", TrainerBeliefState.DOMAIN_MOVE, &"solar_beam", 3500)
	_check.call(
		"intel_belief_inferred_confidence",
		belief.confidence_basis_points(&"intel_player", TrainerBeliefState.DOMAIN_MOVE, &"solar_beam") == 3500,
	)
	_check.call(
		"intel_belief_inferred_marked",
		belief.evidence_for(&"intel_player", TrainerBeliefState.DOMAIN_MOVE, &"solar_beam") == TrainerBeliefState.EVIDENCE_INFERRED,
	)
	memory.reveal_move(&"intel_player", TEST_HIT)
	memory.reveal_ability(&"intel_player", &"overgrow")
	belief.sync_revealed(memory)
	_check.call(
		"intel_belief_revealed_move_certain",
		belief.confidence_basis_points(&"intel_player", TrainerBeliefState.DOMAIN_MOVE, TEST_HIT) == 10000,
	)
	_check.call(
		"intel_belief_revealed_marked",
		belief.evidence_for(&"intel_player", TrainerBeliefState.DOMAIN_MOVE, TEST_HIT) == TrainerBeliefState.EVIDENCE_REVEALED,
	)
	_check.call(
		"intel_belief_single_reveal",
		belief.candidates(&"intel_player", TrainerBeliefState.DOMAIN_ABILITY).size() == 1,
	)
	var restored := TrainerBeliefState.from_dict(JSON.parse_string(JSON.stringify(belief.to_dict())))
	_check.call("intel_belief_round_trip", JSON.stringify(restored.to_dict()) == JSON.stringify(belief.to_dict()))


func _test_observation_hides_unrevealed_information() -> void:
	var state := _battle_state(24)
	var player := state.creature(&"intel_player")
	player.ability_id = &"overgrow"
	player.held_item_id = &"leftovers"
	player.ivs["attack"] = 31
	player.evs["attack"] = 252
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	var observation := TrainerObservationBuilder.build(state, &"side_b", memory)
	var data := observation.to_dict()
	var player_view := _opponent_view(observation, &"intel_player")

	_check.call("intel_observation_created", observation != null)
	_check.call("intel_observation_no_rng", not data.has("rng_state") and not data.has("rng_algorithm"))
	_check.call("intel_observation_no_raw_roster", not data.has("participant_ids") and not data.has("participants"))
	_check.call("intel_observation_unseen_bench_absent", observation.observed_opponents.size() == 1)
	_check.call("intel_observation_hidden_moves_absent", not player_view.has("moveset") and not player_view.has("move_ids"))
	_check.call("intel_observation_hidden_stats_absent", not player_view.has("stats") and not player_view.has("ivs") and not player_view.has("evs") and not player_view.has("nature_id"))
	_check.call("intel_observation_exact_hp_absent", not player_view.has("current_hp") and player_view.has("hp_ratio_basis_points"))
	_check.call("intel_observation_ability_hidden", player_view.get("revealed_ability_id", "") == "")
	_check.call("intel_observation_item_hidden", player_view.get("revealed_item_id", "") == "")
	_check.call("intel_observation_move_hidden", (player_view.get("revealed_move_ids", []) as Array).is_empty())
	_check.call("intel_observation_own_party_full", observation.own_party.size() == 2 and observation.own_party[0].has("moveset") and observation.own_party[0].has("stats"))

	memory.reveal_move(&"intel_player", TEST_HIT)
	memory.reveal_ability(&"intel_player", &"overgrow")
	memory.reveal_item(&"intel_player", &"leftovers")
	memory.mark_seen(&"intel_player_bench")
	observation = TrainerObservationBuilder.build(state, &"side_b", memory)
	player_view = _opponent_view(observation, &"intel_player")
	_check.call("intel_observation_seen_bench_appears", observation.observed_opponents.size() == 2)
	_check.call("intel_observation_revealed_move_only", (player_view.get("revealed_move_ids", []) as Array).has(String(TEST_HIT)))
	_check.call("intel_observation_revealed_ability", player_view.get("revealed_ability_id", "") == "overgrow")
	_check.call("intel_observation_revealed_item", player_view.get("revealed_item_id", "") == "leftovers")


func _test_decision_context_is_detached() -> void:
	var state := _battle_state(25)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	var belief := TrainerBeliefState.new()
	belief.begin(memory)
	var observation := TrainerObservationBuilder.build(state, &"side_b", memory)
	var actor := state.active_for_side(&"side_b")
	var target := state.active_for_side(&"side_a")
	var action := _client.request_move(state.turn + 1, actor.instance_id, TEST_HIT, target.instance_id, &"side_b")
	var actions: Array[BattleAction] = [action]
	var context := TrainerDecisionContext.create(observation, belief, memory, actions)
	var original_move := context.legal_actions[0].move_id
	action.move_id = TEST_IDLE
	memory.reveal_move(&"intel_player", &"solar_beam")

	_check.call("intel_context_created", context != null)
	_check.call("intel_context_action_detached", context.legal_actions[0] != action and context.legal_actions[0].move_id == original_move)
	_check.call("intel_context_memory_detached", not JSON.stringify(context.memory_snapshot).contains("solar_beam"))
	_check.call("intel_context_default_campaign_empty", context.campaign_snapshot.is_empty())
	var data := context.to_dict()
	_check.call("intel_context_campaign_serialized_empty", data.has("campaign") and (data.get("campaign", {}) as Dictionary).is_empty())
	_check.call("intel_context_no_battle_state", not data.has("state") and not data.has("battle_state"))
	_check.call("intel_context_no_rng", not JSON.stringify(data).contains("rng_state"))


func _test_decision_context_campaign_snapshot_is_detached() -> void:
	var state := _battle_state(251)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	var belief := TrainerBeliefState.new()
	belief.begin(memory)
	var observation := TrainerObservationBuilder.build(state, &"side_b", memory)
	var actions: Array[BattleAction] = []
	var campaign := {
		"schema_version": 1,
		"round_index": 2,
		"own_roster": {
			"alive_instance_ids": ["intel_trainer", "intel_trainer_bench"],
		},
		"policies": {
			"permadeath": true,
		},
	}
	var context := TrainerDecisionContext.create(observation, belief, memory, actions, campaign)
	_check.call("intel_context_campaign_created", context != null)
	if context == null:
		return
	campaign["round_index"] = 99
	var source_roster := campaign.get("own_roster", {}) as Dictionary
	var source_alive := source_roster.get("alive_instance_ids", []) as Array
	source_alive.append("source_leak")
	_check.call("intel_context_campaign_top_level_detached", int(context.campaign_snapshot.get("round_index", 0)) == 2)
	var stored_roster := context.campaign_snapshot.get("own_roster", {}) as Dictionary
	var stored_alive := stored_roster.get("alive_instance_ids", []) as Array
	_check.call("intel_context_campaign_nested_detached", not stored_alive.has("source_leak") and stored_alive.size() == 2)
	var data := context.to_dict()
	var serialized_campaign := data.get("campaign", {}) as Dictionary
	var serialized_roster := serialized_campaign.get("own_roster", {}) as Dictionary
	var serialized_alive := serialized_roster.get("alive_instance_ids", []) as Array
	serialized_alive.append("serialized_leak")
	_check.call("intel_context_campaign_serialized_detached", not stored_alive.has("serialized_leak"))
	var json_text := JSON.stringify(data)
	var parsed: Variant = JSON.parse_string(json_text)
	_check.call(
		"intel_context_campaign_json_serializable",
		parsed is Dictionary and (parsed as Dictionary).has("campaign") and json_text.contains("intel_trainer_bench"),
	)


func _test_decision_trace_is_serializable() -> void:
	var state := _battle_state(26)
	var actor := state.active_for_side(&"side_b")
	var target := state.active_for_side(&"side_a")
	var action := _client.request_move(1, actor.instance_id, TEST_HIT, target.instance_id, &"side_b")
	var trace := TrainerDecisionTrace.new()
	trace.battle_id = state.battle_id
	trace.turn = 1
	trace.brain_id = &"test_brain"
	trace.profile_id = &"patient"
	var reasons: Array[String] = ["pressure", "safe_damage"]
	trace.add_candidate(action, &"damage_expert", 120, 7600, reasons, {"depth": 2})
	trace.select(action, "best_expected_value")
	var data := trace.to_dict()
	_check.call("intel_trace_candidate_recorded", trace.candidates.size() == 1)
	_check.call("intel_trace_selected_recorded", data.get("selected_reason", "") == "best_expected_value")
	_check.call("intel_trace_json_serializable", JSON.stringify(data).contains("damage_expert"))


func _test_brain_contract_has_no_default_policy() -> void:
	var brain := TrainerBrain.new()
	_check.call("intel_brain_base_returns_no_action", brain.choose_action(null) == null)
	_check.call("intel_brain_not_simple_policy", brain.brain_id == &"trainer_brain_base")
