class_name TurnResolver
extends RefCounted


func resolve_order(
	actions: Array[BattleAction],
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	ruleset: BattleRuleset = null,
) -> Array[BattleAction]:
	assert(actions.size() == 2, "Foundation resolver expects two actions")
	var first := actions[0]
	var second := actions[1]
	var active_ruleset := ruleset if ruleset != null else BattleRuleset.new()
	var first_priority := _priority(first, catalog, active_ruleset)
	var second_priority := _priority(second, catalog, active_ruleset)
	if first_priority != second_priority:
		return _pair(first, second) if first_priority > second_priority else _pair(second, first)
	var first_speed := _effective_speed(state.creature(first.actor_id), active_ruleset)
	var second_speed := _effective_speed(state.creature(second.actor_id), active_ruleset)
	if first_speed != second_speed:
		return _pair(first, second) if first_speed > second_speed else _pair(second, first)
	return _pair(first, second) if rng.next_index(2) == 0 else _pair(second, first)


func _priority(action: BattleAction, catalog: DefinitionCatalog, ruleset: BattleRuleset) -> int:
	if action.action_type == BattleAction.SWITCH:
		return ruleset.switch_priority
	if action.action_type == BattleAction.ITEM:
		return ruleset.trainer_item_priority
	var move := catalog.move(action.move_id)
	return move.priority if move != null else -100


func _effective_speed(creature: CreatureInstance, ruleset: BattleRuleset) -> int:
	if creature == null or creature.stats == null:
		return 1
	var speed := creature.stats.speed * ruleset.stat_multiplier_basis_points(
		creature.stat_stages.get_stage(StatStages.SPEED)
	) / 10000
	if creature.status_state.persistent_id == &"paralysis":
		speed = speed * ruleset.paralysis_speed_multiplier_basis_points / 10000
	return maxi(1, speed)


func _pair(first: BattleAction, second: BattleAction) -> Array[BattleAction]:
	var ordered: Array[BattleAction] = []
	ordered.append(first)
	ordered.append(second)
	return ordered
