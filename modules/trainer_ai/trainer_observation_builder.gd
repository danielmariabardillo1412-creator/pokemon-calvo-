class_name TrainerObservationBuilder
extends RefCounted

# Builds the only battle-state view intended for trainer brains.
# Own-side data is complete, including the trainer's own finite battle-item bag.
# Opponent data is restricted to creatures already seen and facts revealed through
# battle events. Internal RNG state, unrevealed roster/inventory, IV/EV/nature,
# exact opponent stats, hidden moves, ability and item never cross this boundary.


static func build(
	state: BattleState,
	observer_side_id: StringName,
	memory: TrainerBattleMemory,
) -> TrainerObservation:
	if state == null or memory == null:
		return null
	if memory.battle_id != state.battle_id or memory.observer_side_id != observer_side_id:
		return null
	var own_side := _side(state, observer_side_id)
	var opponent_side := _other_side(state, observer_side_id)
	if own_side == null or opponent_side == null:
		return null

	var observation := TrainerObservation.new()
	observation.battle_id = state.battle_id
	observation.turn = state.turn
	observation.phase = state.phase
	observation.observer_side_id = observer_side_id
	observation.opponent_side_id = opponent_side.side_id
	observation.own_active_id = own_side.active_id
	observation.opponent_active_id = opponent_side.active_id
	var own_inventory := state.item_inventory_for_side(observer_side_id)
	if own_inventory != null:
		observation.own_item_inventory = own_inventory.to_dict().duplicate(true)

	for creature_id in own_side.party_ids:
		var creature := state.creature(creature_id)
		if creature != null:
			observation.own_party.append(_own_creature_view(creature, creature_id == own_side.active_id))

	for creature_id in opponent_side.party_ids:
		if creature_id != opponent_side.active_id and not memory.has_seen(creature_id):
			continue
		var creature := state.creature(creature_id)
		if creature != null:
			observation.observed_opponents.append(
				_opponent_creature_view(
					creature,
					creature_id == opponent_side.active_id,
					memory,
				)
			)
	return observation


static func _own_creature_view(creature: CreatureInstance, is_active: bool) -> Dictionary:
	var out := creature.to_dict().duplicate(true)
	out["is_active"] = is_active
	return out


static func _opponent_creature_view(
	creature: CreatureInstance,
	is_active: bool,
	memory: TrainerBattleMemory,
) -> Dictionary:
	var revealed_moves: Array[String] = []
	for move_id in memory.revealed_move_ids(creature.instance_id):
		revealed_moves.append(String(move_id))
	var revealed_ability := memory.revealed_ability_id(creature.instance_id)
	var revealed_item := memory.revealed_item_id(creature.instance_id)
	return {
		"instance_id": String(creature.instance_id),
		"species_id": String(creature.species_id),
		"level": creature.level,
		"is_active": is_active,
		"is_knocked_out": creature.is_knocked_out(),
		"hp_ratio_basis_points": _hp_ratio_basis_points(creature),
		"persistent_status_id": String(creature.status_state.persistent_id),
		"volatile_statuses": _volatile_status_ids(creature),
		"stat_stages": creature.stat_stages.to_dict(),
		"revealed_move_ids": revealed_moves,
		"revealed_ability_id": String(revealed_ability),
		"revealed_item_id": String(revealed_item),
		"revealed_item_consumed": (
			creature.held_item_consumed if revealed_item != &"" else false
		),
	}


static func _hp_ratio_basis_points(creature: CreatureInstance) -> int:
	if creature.stats == null or creature.stats.max_hp <= 0:
		return 0
	return clampi(creature.current_hp * 10000 / creature.stats.max_hp, 0, 10000)


static func _volatile_status_ids(creature: CreatureInstance) -> Array[String]:
	var out: Array[String] = []
	for status_id in creature.status_state.volatile.keys():
		out.append(String(status_id))
	out.sort()
	return out


static func _side(state: BattleState, side_id: StringName) -> BattleSide:
	for side in state.sides:
		if side.side_id == side_id:
			return side
	return null


static func _other_side(state: BattleState, side_id: StringName) -> BattleSide:
	for side in state.sides:
		if side.side_id != side_id:
			return side
	return null
