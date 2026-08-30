class_name TrainerBeliefInferenceGateTestSuite
extends TrainerBeliefInferenceTestSuite

# CI specialization of the base suite. The base fixture originally searched the whole
# DecisionContext for IV/EV keys, but own-side data is intentionally complete. This
# override checks only the opponent observation plus the belief snapshot, which is the
# actual anti-cheat boundary under test.

func _test_same_priority_turn_order_refines_speed_range() -> void:
	var player_moves: Array[StringName] = [MOVE_SECRET]
	var trainer_moves: Array[StringName] = [MOVE_OWN]
	var player := _creature(
		PLAYER_SPECIES, &"speed_player", 30, player_moves, 5,
		{
			"ivs": {"speed": 31},
			"evs": {"speed": 100},
			"nature_id": &"timid",
		}
	)
	var trainer := _creature(
		TRAINER_SPECIES, &"speed_trainer", 30, trainer_moves, 6,
		{
			"ivs": {"speed": 0},
			"evs": {"speed": 0},
			"nature_id": &"hardy",
		}
	)
	var state := _state(player, trainer, 99)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var controller := TrainerIntelligenceController.new(&"side_b", TrainerBrain.new(), _catalog)
	_check.call("belief_speed_controller_begin", controller.begin(server))
	var before := controller.belief.range_for(player.instance_id, TrainerBeliefState.DOMAIN_SPEED)
	_check.call("belief_speed_prior_seeded", not before.is_empty())
	controller.choose_action(server)
	_check.call("belief_speed_previous_context_captured", controller.last_context != null)

	var player_action := _client.request_move(
		state.turn + 1, player.instance_id, MOVE_SECRET, trainer.instance_id, &"side_a"
	)
	var trainer_action := _client.request_move(
		state.turn + 1, trainer.instance_id, MOVE_OWN, player.instance_id, &"side_b"
	)
	var actions: Array[BattleAction] = [player_action, trainer_action]
	var events := server.submit_turn(actions)
	var first_actor: StringName = &""
	for event in events:
		if event.kind == BattleEvent.ACTION_USED:
			first_actor = event.actor_id
			break
	_check.call("belief_speed_fixture_opponent_really_faster", first_actor == player.instance_id)
	_check.call("belief_speed_controller_observe", controller.observe(events, server))
	var after := controller.belief.range_for(player.instance_id, TrainerBeliefState.DOMAIN_SPEED)
	_check.call(
		"belief_speed_range_refined",
		int(after.get("min_value", 0)) > int(before.get("min_value", 0))
		and int(after.get("max_value", 0)) <= int(before.get("max_value", 0)),
	)
	_check.call(
		"belief_speed_hidden_actual_stays_inside_public_bound",
		player.stats.speed >= int(after.get("min_value", 0))
		and player.stats.speed <= int(after.get("max_value", 0)),
	)
	_check.call(
		"belief_speed_order_provenance",
		_has_provenance(after, TrainerBeliefInference.PROVENANCE_ORDER),
	)

	var opponent_view: Dictionary = {}
	if controller.last_context != null and not controller.last_context.observation.observed_opponents.is_empty():
		opponent_view = controller.last_context.observation.observed_opponents[0]
	var belief_json := JSON.stringify(controller.last_context.belief_snapshot)
	_check.call(
		"belief_speed_context_still_no_hidden_opponent_stats",
		not opponent_view.has("stats")
		and not opponent_view.has("ivs")
		and not opponent_view.has("evs")
		and not opponent_view.has("nature_id")
		and not belief_json.contains("rng_state")
		and not belief_json.contains("\"ivs\"")
		and not belief_json.contains("\"evs\"")
		and not belief_json.contains("nature_id"),
	)
