class_name SimpleBattleOpponentPolicy
extends RefCounted

# Minimal deterministic opponent policy for the technical Battle Presentation slice.
# It owns no battle rules and never mutates state: it only selects the first currently
# usable move exposed by the active creature and builds a normal BattleAction.


static func choose_move_action(
	state: BattleState,
	side_id: StringName,
	catalog: DefinitionCatalog,
) -> BattleAction:
	if state == null or catalog == null:
		return null
	if state.phase != BattleState.WAITING_FOR_ACTIONS:
		return null
	var actor := state.active_for_side(side_id)
	if actor == null or actor.is_knocked_out():
		return null
	var target := state.opponent_of(actor.instance_id)
	if target == null:
		return null
	for slot_variant in actor.moveset:
		var slot := slot_variant as BattleMoveSlot
		if slot == null or slot.current_pp <= 0:
			continue
		if catalog.move(slot.move_id) == null:
			continue
		return BattleAction.new(
			state.turn + 1,
			actor.instance_id,
			slot.move_id,
			target.instance_id,
			BattleAction.MOVE,
			side_id,
		)
	return null
