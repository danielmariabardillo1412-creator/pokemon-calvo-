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
		return [first, second] if first_move.priority > second_move.priority else [second, first]
	var first_speed := state.creature(first.actor_id).stats.speed
	var second_speed := state.creature(second.actor_id).stats.speed
	if first_speed != second_speed:
		return [first, second] if first_speed > second_speed else [second, first]
	return [first, second] if rng.next_index(2) == 0 else [second, first]

