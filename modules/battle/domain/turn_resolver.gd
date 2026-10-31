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
	var first_speed := live_effective_speed(state.creature(first.actor_id), active_ruleset) if state.live_moves_enabled else _effective_speed(state.creature(first.actor_id), active_ruleset)
	var second_speed := live_effective_speed(state.creature(second.actor_id), active_ruleset) if state.live_moves_enabled else _effective_speed(state.creature(second.actor_id), active_ruleset)
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


static func live_effective_speed(creature: CreatureInstance, ruleset: BattleRuleset) -> int:
	# Exact rational stages avoid e.g. floor(3*6666/10000)=1 instead of 2.
	# Preserve legacy ordering/RNG when live_moves_enabled is false.
	if creature == null or creature.stats == null: return 1
	var stage := creature.stat_stages.get_stage(StatStages.SPEED)
	var speed: int = creature.stats.speed * (2 + stage) / 2 if stage >= 0 else creature.stats.speed * 2 / (2 - stage)
	if creature.status_state.persistent_id == &"paralysis":
		speed = speed * ruleset.paralysis_speed_multiplier_basis_points / 10000
	return clampi(speed, 0, 10000)


func _pair(first: BattleAction, second: BattleAction) -> Array[BattleAction]:
	var ordered: Array[BattleAction] = []
	ordered.append(first)
	ordered.append(second)
	return ordered


func resolve_multi_order(actions: Array[BattleAction], state: BattleState,
	catalog: DefinitionCatalog, rng: SeededRandomSource, ruleset: BattleRuleset = null) -> Array[BattleAction]:
	# Explicit doubles adapter only; the historical two-action entry point above
	# retains its ordering and RNG contract. Canonicalize packet order before ties.
	var active_ruleset := ruleset if ruleset != null else BattleRuleset.new()
	var ordered: Array[BattleAction] = actions.duplicate()
	ordered.sort_custom(func(a: BattleAction, b: BattleAction):
		var pa := _priority(a, catalog, active_ruleset)
		var pb := _priority(b, catalog, active_ruleset)
		if pa != pb: return pa > pb
		var sa := _effective_speed(state.creature(a.actor_id), active_ruleset)
		var sb := _effective_speed(state.creature(b.actor_id), active_ruleset)
		return sa > sb if sa != sb else String(a.actor_id) < String(b.actor_id))
	var start := 0
	while start < ordered.size():
		var end := start + 1
		while end < ordered.size() and _priority(ordered[start], catalog, active_ruleset) == _priority(ordered[end], catalog, active_ruleset) and _effective_speed(state.creature(ordered[start].actor_id), active_ruleset) == _effective_speed(state.creature(ordered[end].actor_id), active_ruleset):
			end += 1
		for index in range(end - 1, start, -1):
			var picked := start + rng.next_index(index - start + 1)
			var previous := ordered[index]
			ordered[index] = ordered[picked]
			ordered[picked] = previous
		start = end
	return ordered
