class_name TrainerItemActionsTestSuite
extends TrainerPublicCoverageBeliefsTestSuite

const ITEM_IDLE := &"item_idle"
const ITEM_CHIP := &"item_chip"
const ITEM_PRESSURE := &"item_pressure"
const ITEM_FINISH := &"item_finish"
const ITEM_OWN_SPECIES := &"item_own_species"
const ITEM_FOE_SPECIES := &"item_foe_species"

const POTION := &"potion"
const SUPER_POTION := &"super_potion"
const HYPER_POTION := &"hyper_potion"
const MAX_POTION := &"max_potion"
const FULL_RESTORE := &"full_restore"
const REVIVE := &"revive"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_registry_contract()
	_test_item_action_round_trip()
	_test_finite_inventory_snapshot_and_fork()
	_test_authoritative_item_execution()
	_test_item_validation_and_targeting()
	_test_observation_privacy_and_world_resources()
	_test_item_aware_brain_decisions()


func _build_catalog() -> void:
	super._build_catalog()
	_add_setup_move(ITEM_IDLE, [])
	_add_damage_move(ITEM_CHIP, 25)
	_add_damage_move(ITEM_PRESSURE, 90)
	_add_damage_move(ITEM_FINISH, 130)
	_add_species(ITEM_OWN_SPECIES, 70, 90, 60, 40, [ITEM_CHIP, ITEM_FINISH])
	_add_species(ITEM_FOE_SPECIES, 70, 100, 60, 100, [ITEM_IDLE, ITEM_PRESSURE])
	for item_id in [POTION, SUPER_POTION, HYPER_POTION, MAX_POTION, FULL_RESTORE, REVIVE]:
		_catalog.add_item(ItemDefinition.new(item_id, String(item_id), "", &"medicine"))


func _test_registry_contract() -> void:
	var registry := BattleEffectRegistry.new()
	var supported := registry.runtime_supported_trainer_item_ids()
	_check.call("item_registry_has_five_enabled_bag_items", supported.size() == 5)
	for item_id in [POTION, SUPER_POTION, HYPER_POTION, MAX_POTION, FULL_RESTORE]:
		_check.call("item_registry_supports_%s" % String(item_id), registry.is_trainer_item_supported(item_id))
		_check.call(
			"item_registry_%s_targets_alive" % String(item_id),
			registry.trainer_item_target_mode(item_id) == BattleEffectRegistry.TRAINER_ITEM_TARGET_ALIVE,
		)
	_check.call("item_registry_revive_not_enabled", not registry.is_trainer_item_supported(REVIVE))
	_check.call("item_registry_revive_primitive_reserved", BattleEffectSpec.REVIVE == &"revive")
	_check.call("item_registry_held_items_remain_separate", registry.runtime_supported_item_ids() == [&"leftovers", &"sitrus_berry"])


func _test_item_action_round_trip() -> void:
	var action := _item_action(3, &"a", &"bench", HYPER_POTION, &"side_a")
	var restored := BattleAction.from_dict(JSON.parse_string(JSON.stringify(action.to_dict())))
	_check.call("item_action_type_round_trip", restored.action_type == BattleAction.ITEM)
	_check.call("item_action_id_round_trip", restored.item_id == HYPER_POTION)
	_check.call("item_action_target_round_trip", restored.target_id == &"bench")
	_check.call("item_action_side_round_trip", restored.side_id == &"side_a")


func _test_finite_inventory_snapshot_and_fork() -> void:
	var server := _item_server({HYPER_POTION: 1, POTION: 2}, false)
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


func _test_authoritative_item_execution() -> void:
	var server := _item_server({POTION: 1}, false)
	server.state.creature(&"item_a").current_hp = 40
	var actions: Array[BattleAction] = [
		_item_action(1, &"item_a", &"item_a", POTION, &"side_a"),
		_move_action(1, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	var events := server.submit_turn(actions)
	_check.call("item_potion_turn_accepted", not _has_event(events, BattleEvent.ACTION_REJECTED))
	_check.call("item_potion_consumed_once", server.state.item_inventory_for_side(&"side_a").quantity(POTION) == 0)
	_check.call("item_potion_heals_twenty", server.state.creature(&"item_a").current_hp == 60)
	var used := _first_event(events, BattleEvent.TRAINER_ITEM_USED)
	_check.call("item_used_event_present", used != null)
	_check.call("item_used_event_records_id", used != null and String(used.metadata.get("item_id", "")) == String(POTION))
	_check.call("item_used_event_records_zero_remaining", used != null and int(used.metadata.get("remaining_quantity", -1)) == 0)
	_check.call("item_hp_recovered_event_present", _first_event(events, BattleEvent.HP_RECOVERED) != null)
	_check.call("item_action_spends_turn", server.state.turn == 1)

	var second_actions: Array[BattleAction] = [
		_item_action(2, &"item_a", &"item_a", POTION, &"side_a"),
		_move_action(2, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	var second := server.submit_turn(second_actions)
	_check.call("item_exhausted_rejected", _rejection_reason(second) == "item_unavailable")
	_check.call("item_rejection_does_not_advance_turn", server.state.turn == 1)


func _test_item_validation_and_targeting() -> void:
	var full_hp := _item_server({POTION: 1}, false)
	var full_actions: Array[BattleAction] = [
		_item_action(1, &"item_a", &"item_a", POTION, &"side_a"),
		_move_action(1, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	_check.call("item_full_hp_rejected", _rejection_reason(full_hp.submit_turn(full_actions)) == "item_no_effect")
	_check.call("item_full_hp_not_consumed", full_hp.state.item_inventory_for_side(&"side_a").quantity(POTION) == 1)

	var bench_server := _item_server({SUPER_POTION: 1}, true)
	bench_server.state.creature(&"item_bench").current_hp = 20
	var bench_actions: Array[BattleAction] = [
		_item_action(1, &"item_a", &"item_bench", SUPER_POTION, &"side_a"),
		_move_action(1, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	var bench_events := bench_server.submit_turn(bench_actions)
	_check.call("item_can_target_living_bench", not _has_event(bench_events, BattleEvent.ACTION_REJECTED))
	_check.call("item_bench_healed", bench_server.state.creature(&"item_bench").current_hp == 80)

	var restore := _item_server({FULL_RESTORE: 1}, false)
	restore.state.creature(&"item_a").current_hp = 10
	restore.state.creature(&"item_a").status_state.persistent_id = StatusSystem.POISON
	var restore_actions: Array[BattleAction] = [
		_item_action(1, &"item_a", &"item_a", FULL_RESTORE, &"side_a"),
		_move_action(1, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	var restore_events := restore.submit_turn(restore_actions)
	_check.call("item_full_restore_heals_full", restore.state.creature(&"item_a").current_hp == restore.state.creature(&"item_a").stats.max_hp)
	_check.call("item_full_restore_cures_status", restore.state.creature(&"item_a").status_state.persistent_id == &"")
	_check.call("item_full_restore_emits_status_cured", _has_event(restore_events, BattleEvent.STATUS_CURED))

	var revive_block := _item_server({REVIVE: 1}, true)
	revive_block.state.creature(&"item_bench").current_hp = 0
	var revive_actions: Array[BattleAction] = [
		_item_action(1, &"item_a", &"item_bench", REVIVE, &"side_a"),
		_move_action(1, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	var revive_events := revive_block.submit_turn(revive_actions)
	_check.call("item_revive_disabled_rejected", _rejection_reason(revive_events) == "item_not_battle_usable")
	_check.call("item_revive_disabled_keeps_target_fainted", revive_block.state.creature(&"item_bench").is_knocked_out())
	_check.call("item_revive_disabled_not_consumed", revive_block.state.item_inventory_for_side(&"side_a").quantity(REVIVE) == 1)

	var held := _item_server({POTION: 1}, false)
	held.state.creature(&"item_a").held_item_id = &"leftovers"
	held.state.creature(&"item_a").current_hp = 50
	var held_actions: Array[BattleAction] = [
		_item_action(1, &"item_a", &"item_a", POTION, &"side_a"),
		_move_action(1, &"item_b", ITEM_IDLE, &"item_a", &"side_b"),
	]
	held.submit_turn(held_actions)
	_check.call("item_bag_use_does_not_consume_held_item", not held.state.creature(&"item_a").held_item_consumed)
	_check.call("item_bag_use_preserves_held_item_id", held.state.creature(&"item_a").held_item_id == &"leftovers")


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
	_check.call("item_observation_own_hyper_visible", observation != null and int(observation.own_item_inventory.get(String(HYPER_POTION), 0)) == 1)
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


func _test_item_aware_brain_decisions() -> void:
	var danger := _item_server({HYPER_POTION: 1}, false, ITEM_PRESSURE)
	danger.state.creature(&"item_a").current_hp = 1
	var danger_before := JSON.stringify(danger.snapshot())
	var brain := ItemAwareTrainerBrain.new(
		_catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("item_brain_begin_danger", controller.begin(danger))
	var danger_action := controller.choose_action(danger)
	_check.call("item_brain_search_does_not_mutate_live", danger_before == JSON.stringify(danger.snapshot()))
	_check.call("item_brain_heals_when_attack_line_dies", danger_action != null and danger_action.action_type == BattleAction.ITEM)
	_check.call("item_brain_uses_available_hyper", danger_action != null and danger_action.item_id == HYPER_POTION)
	_check.call("item_brain_targets_active_in_danger", danger_action != null and danger_action.target_id == &"item_a")

	var finish := _item_server({POTION: 1}, false, ITEM_IDLE)
	finish.state.creature(&"item_a").current_hp = 90
	finish.state.creature(&"item_b").current_hp = 20
	var finish_brain := ItemAwareTrainerBrain.new(
		_catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)
	var finish_controller := TrainerIntelligenceController.new(&"side_a", finish_brain, _catalog)
	_check.call("item_brain_begin_finish", finish_controller.begin(finish))
	var finish_action := finish_controller.choose_action(finish)
	_check.call("item_brain_prefers_winning_move_over_heal", finish_action != null and finish_action.action_type == BattleAction.MOVE and finish_action.move_id == ITEM_FINISH)

	var efficient := _item_server({POTION: 1, HYPER_POTION: 1}, false, ITEM_IDLE)
	efficient.state.creature(&"item_a").current_hp = 85
	var efficient_brain := ItemAwareTrainerBrain.new(
		_catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(1, 1, 64, 3),
	)
	var efficient_controller := TrainerIntelligenceController.new(&"side_a", efficient_brain, _catalog)
	_check.call("item_brain_begin_efficiency", efficient_controller.begin(efficient))
	var efficient_context_action := efficient_controller.choose_action(efficient)
	var potion_score := _candidate_score(brain.last_trace if false else efficient_brain.last_trace, POTION)
	var hyper_score := _candidate_score(efficient_brain.last_trace, HYPER_POTION)
	_check.call("item_brain_smaller_heal_scores_higher_when_effect_equal", potion_score > hyper_score)
	_check.call("item_brain_efficiency_does_not_choose_hyper", efficient_context_action == null or efficient_context_action.item_id != HYPER_POTION)


func _item_server(
	items: Dictionary,
	with_bench: bool,
	opponent_move: StringName = ITEM_IDLE,
) -> AuthoritativeBattleServer:
	var a := CreatureInstance.new(
		&"item_a", ITEM_OWN_SPECIES, 30,
		StatBlock.new(100, 100, 70, 40, 80, 80),
		[ITEM_CHIP, ITEM_FINISH],
	)
	a.initialize_move_pp(_catalog)
	var party_a: Array[CreatureInstance] = [a]
	if with_bench:
		var bench := CreatureInstance.new(
			&"item_bench", ITEM_OWN_SPECIES, 30,
			StatBlock.new(100, 90, 70, 30, 80, 80),
			[ITEM_CHIP],
		)
		bench.initialize_move_pp(_catalog)
		party_a.append(bench)
	var b := CreatureInstance.new(
		&"item_b", ITEM_FOE_SPECIES, 30,
		StatBlock.new(100, 120, 70, 100, 80, 80),
		[opponent_move],
	)
	b.initialize_move_pp(_catalog)
	var party_b: Array[CreatureInstance] = [b]
	var state := BattleState.create_with_parties(&"item_test", party_a, party_b, 1777)
	var inventory := BattleSideItemInventory.new()
	for raw_id in items.keys():
		inventory.set_quantity(StringName(raw_id), int(items[raw_id]))
	state.set_item_inventory_for_side(&"side_a", inventory)
	return AuthoritativeBattleServer.new(state, _catalog)


func _item_action(
	turn: int,
	actor_id: StringName,
	target_id: StringName,
	item_id: StringName,
	side_id: StringName,
) -> BattleAction:
	return BattleAction.new(turn, actor_id, &"", target_id, BattleAction.ITEM, side_id, &"", item_id)


func _move_action(
	turn: int,
	actor_id: StringName,
	move_id: StringName,
	target_id: StringName,
	side_id: StringName,
) -> BattleAction:
	return BattleAction.new(turn, actor_id, move_id, target_id, BattleAction.MOVE, side_id)


func _has_event(events: Array[BattleEvent], kind: StringName) -> bool:
	return _first_event(events, kind) != null


func _first_event(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event.kind == kind:
			return event
	return null


func _rejection_reason(events: Array[BattleEvent]) -> String:
	var event := _first_event(events, BattleEvent.ACTION_REJECTED)
	return String(event.metadata.get("reason", "")) if event != null else ""


func _candidate_score(trace: TrainerDecisionTrace, item_id: StringName) -> int:
	if trace == null:
		return -2147483648
	for raw in trace.candidates:
		var candidate := raw as Dictionary
		var action := candidate.get("action", {}) as Dictionary
		if StringName(action.get("action_type", BattleAction.MOVE)) == BattleAction.ITEM and StringName(action.get("item_id", "")) == item_id:
			return int(candidate.get("score", -2147483648))
	return -2147483648
