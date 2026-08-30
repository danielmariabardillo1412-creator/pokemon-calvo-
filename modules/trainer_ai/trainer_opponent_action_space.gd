class_name TrainerOpponentActionSpace
extends RefCounted


static func from_world(
	world: TrainerPlausibleWorld,
	context: TrainerDecisionContext,
	catalog: DefinitionCatalog,
) -> Array[BattleAction]:
	var out: Array[BattleAction] = []
	if world == null or world.state == null or context == null or context.observation == null or catalog == null:
		return out
	var state := world.state
	var observation := context.observation
	var active := state.active_for_side(observation.opponent_side_id)
	var target := state.active_for_side(observation.observer_side_id)
	if active == null or target == null or active.is_knocked_out():
		return out
	for slot in active.moveset:
		var move_slot := slot as BattleMoveSlot
		if move_slot.current_pp <= 0 or catalog.move(move_slot.move_id) == null:
			continue
		out.append(BattleAction.new(
			state.turn + 1,
			active.instance_id,
			move_slot.move_id,
			target.instance_id,
			BattleAction.MOVE,
			observation.opponent_side_id,
		))
	var side := state.side_for_creature(active.instance_id)
	if side != null:
		for creature_id in side.party_ids:
			if creature_id == side.active_id:
				continue
			var incoming := state.creature(creature_id)
			if incoming == null or incoming.is_knocked_out():
				continue
			out.append(BattleAction.new(
				state.turn + 1,
				active.instance_id,
				&"",
				&"",
				BattleAction.SWITCH,
				observation.opponent_side_id,
				creature_id,
			))
	out.sort_custom(func(a, b): return _action_key(a) < _action_key(b))
	return out


static func _action_key(action: BattleAction) -> String:
	if action.action_type == BattleAction.SWITCH:
		return "1:switch:%s" % String(action.switch_instance_id)
	return "0:move:%s" % String(action.move_id)
