class_name TrainerActionSpace
extends RefCounted

# Trusted adapter between Battle Core and trainer intelligence. It may inspect the
# authoritative state only to enumerate possibilities, then asks Battle Core's own
# validator to approve every candidate. Brains receive detached copies afterwards.


static func from_server(
	server: AuthoritativeBattleServer,
	side_id: StringName,
) -> Array[BattleAction]:
	var out: Array[BattleAction] = []
	if server == null or server.state == null:
		return out
	var state := server.state
	if state.phase != BattleState.WAITING_FOR_ACTIONS:
		return out
	var actor := state.active_for_side(side_id)
	if actor == null:
		return out
	var actor_side := state.side_for_creature(actor.instance_id)
	var opponent := state.opponent_of(actor.instance_id)
	if actor_side == null or opponent == null:
		return out
	var opponent_side := state.side_for_creature(opponent.instance_id)
	if opponent_side == null:
		return out

	for slot in actor.moveset:
		var move_slot := slot as BattleMoveSlot
		var move_action := BattleAction.new(
			state.turn + 1,
			actor.instance_id,
			move_slot.move_id,
			opponent.instance_id,
			BattleAction.MOVE,
			side_id,
		)
		if server.validate_reaction_action(move_action, opponent_side.side_id).is_empty():
			out.append(BattleAction.from_dict(move_action.to_dict()))

	for creature_id in actor_side.party_ids:
		var switch_action := BattleAction.new(
			state.turn + 1,
			actor.instance_id,
			&"",
			&"",
			BattleAction.SWITCH,
			side_id,
			creature_id,
		)
		if server.validate_reaction_action(switch_action, opponent_side.side_id).is_empty():
			out.append(BattleAction.from_dict(switch_action.to_dict()))
	return out
