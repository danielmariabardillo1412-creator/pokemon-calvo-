class_name TrainerItemActionsV2TestSuite
extends TrainerItemActionsTestSuite

# V2 corrects two fixture assumptions discovered by the first CI run.
# Production behavior was correct: a heal at full HP must be rejected, and the
# observation intentionally carries the serialized BattleSideItemInventory shape.


func _test_finite_inventory_snapshot_and_fork() -> void:
	var server := _item_server({HYPER_POTION: 1, POTION: 2}, false)
	# A trainer item is legal only when it has a real effect. The original fixture
	# attempted Hyper Potion at full HP, so the authoritative server correctly
	# rejected it. Give the fork a genuinely healable state instead of weakening
	# production validation.
	server.state.creature(&"item_a").current_hp = 40
	var snapshot := JSON.stringify(server.snapshot())
	var restored := BattleState.from_dict(JSON.parse_string(snapshot))
	var restored_inventory := restored.item_inventory_for_side(&"side_a")
	_check.call("item_snapshot_preserves_hyper", restored_inventory != null and restored_inventory.quantity(HYPER_POTION) == 1)
	_check.call("item_snapshot_preserves_potion_count", restored_inventory != null and restored_inventory.quantity(POTION) == 2)
	_check.call("item_snapshot_round_trip_deterministic", snapshot == JSON.stringify(restored.to_dict()))

	var fork := BattleSimulationFork.from_state(server.state, _catalog)
	var fork_actions: Array[BattleAction] = [
		_item_action(1, &"item_a", &"item_a", HYPER_POTION, &"side_a"),
		_move_action(1, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	var live_before := JSON.stringify(server.snapshot())
	var fork_events := fork.submit_turn(fork_actions)
	_check.call("item_fork_executes_without_rejection", not _has_event(fork_events, BattleEvent.ACTION_REJECTED))
	_check.call("item_fork_consumes_own_copy", fork.state().item_inventory_for_side(&"side_a").quantity(HYPER_POTION) == 0)
	_check.call("item_fork_does_not_mutate_live_state", live_before == JSON.stringify(server.snapshot()))
	_check.call("item_fork_live_inventory_still_one", server.state.item_inventory_for_side(&"side_a").quantity(HYPER_POTION) == 1)


func _test_observation_privacy_and_world_resources() -> void:
	var server := _item_server({HYPER_POTION: 1}, false)
	var rival_inventory := BattleSideItemInventory.new()
	rival_inventory.set_quantity(MAX_POTION, 3)
	server.state.set_item_inventory_for_side(&"side_b", rival_inventory)
	var memory := TrainerBattleMemory.new()
	_check.call("item_memory_begin", memory.begin(server.state, &"side_a"))
	var belief := TrainerBeliefState.new()
	_check.call("item_belief_begin", belief.begin(memory))
	var observation := TrainerObservationBuilder.build(server.state, &"side_a", memory)
	_check.call("item_observation_created", observation != null)
	var observed_quantities: Dictionary = {}
	if observation != null:
		observed_quantities = observation.own_item_inventory.get("quantities", {}) as Dictionary
	_check.call(
		"item_observation_own_hyper_visible",
		observation != null and int(observed_quantities.get(String(HYPER_POTION), 0)) == 1,
	)
	var observation_json := JSON.stringify(observation.to_dict())
	_check.call("item_observation_rival_bag_hidden", not observation_json.contains(String(MAX_POTION)))
	var legal := TrainerActionSpace.from_server(server, &"side_a")
	var context := TrainerDecisionContext.create(observation, belief, memory, legal)
	var worlds := TrainerItemAwareWorldFactory.new(_catalog).build(context, 1)
	_check.call("item_world_created", worlds.size() == 1)
	if worlds.is_empty():
		return
	var world := worlds[0] as TrainerPlausibleWorld
	var own_inventory := world.state.item_inventory_for_side(&"side_a")
	_check.call("item_world_copies_own_inventory", own_inventory != null and own_inventory.quantity(HYPER_POTION) == 1)
	_check.call("item_world_does_not_copy_rival_inventory", world.state.item_inventory_for_side(&"side_b") == null)
	_check.call("item_world_records_resource_model", String(world.metadata.get("battle_item_resource_model", "")) == TrainerItemAwareWorldFactory.RESOURCE_MODEL)
