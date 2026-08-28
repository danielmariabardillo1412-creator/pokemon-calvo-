class_name TurnResolver
extends RefCounted


func resolve_order(
	actions: Array[BattleAction],
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
) -> Array[BattleAction]:
	assert(actions.size() == 2, "Foundation resolver expects two actions")
	var first := actions[0]
	var second := actions[1]
	var first_move := catalog.move(first.move_id)
	var second_move := catalog.move(second.move_id)
	if first_move.priority != second_move.priority:
		return _pair(first, second) if first_move.priority > second_move.priority else _pair(second, first)
	var first_speed := state.creature(first.actor_id).stats.speed
	var second_speed := state.creature(second.actor_id).stats.speed
	if first_speed != second_speed:
		return _pair(first, second) if first_speed > second_speed else _pair(second, first)
	return _pair(first, second) if rng.next_index(2) == 0 else _pair(second, first)


func _pair(first: BattleAction, second: BattleAction) -> Array[BattleAction]:
	var ordered: Array[BattleAction] = []
	ordered.append(first)
	ordered.append(second)
	return ordered
