extends RefCounted

# Opt-in modern singles contract. Frozen canonical classification stays UNSUPPORTED.
# Rules reference: Pokemon Showdown sim/pokemon.ts, transformInto (2026-10-26).
const CRIT_VOLATILES: Array[StringName] = [&"focus_energy"]


static func supports(move: MoveDefinition) -> bool:
	return move != null and move.id == &"transform" and move.power == 0 and move.type_id == &"normal" \
		and move.damage_class == "status" and move.target == "selected-pokemon" and move.priority == 0 \
		and move.accuracy == -1 and move.effect_specs.is_empty()


static func apply(state: BattleState, actor: CreatureInstance, target: CreatureInstance,
	catalog: DefinitionCatalog, events: Array[BattleEvent]) -> bool:
	var reason := ""
	if actor == target or actor.is_knocked_out() or target.is_knocked_out(): reason = "invalid_target"
	elif not actor.battle_transform_original.is_empty(): reason = "already_transformed"
	elif not target.battle_transform_original.is_empty(): reason = "target_transformed"
	elif target.status_state.has_volatile(&"substitute"): reason = "target_substitute"
	else:
		for creature: CreatureInstance in [actor, target]:
			for marker: StringName in [&"illusion", &"dynamax", &"gigantamax", &"terastallized"]:
				if creature.status_state.has_volatile(marker): reason = "unsupported_form_context"
		if target.species_id == &"eternatus_eternamax": reason = "unsupported_form_context"
	if catalog.species(target.species_id) == null: reason = "unknown_species"
	for slot: BattleMoveSlot in target.moveset:
		if catalog.move(slot.move_id) == null: reason = "unknown_move"
	if not reason.is_empty():
		events.append(BattleEvent.new(BattleEvent.TRANSFORM_FAILED, state.turn,
			actor.instance_id, target.instance_id, &"transform", 0, {"reason": reason}))
		return false
	# Capture the user's original PP AFTER paying for Transform. The copied PP are
	# temporary and never overwrite this baseline when restoring the creature.
	var original_moves: Array[Dictionary] = []
	for slot: BattleMoveSlot in actor.moveset: original_moves.append(slot.to_dict())
	actor.battle_transform_original = {"species_id": String(actor.species_id),
		"stats": actor.stats.to_dict(), "ability_id": String(actor.ability_id), "moveset": original_moves,
		"is_shiny": actor.is_shiny}
	var copied_stats := target.stats.to_dict()
	copied_stats.max_hp = actor.stats.max_hp
	actor.stats = StatBlock.from_dict(copied_stats)
	actor.species_id = target.species_id
	actor.is_shiny = target.is_shiny
	actor.ability_id = target.ability_id
	actor.stat_stages = StatStages.from_dict(target.stat_stages.to_dict())
	actor.moveset.clear()
	actor.move_ids.clear()
	for slot: BattleMoveSlot in target.moveset:
		var pp := mini(5, catalog.move(slot.move_id).pp)
		actor.moveset.append(BattleMoveSlot.new(slot.move_id, pp, pp))
		actor.move_ids.append(slot.move_id)
	for id: StringName in CRIT_VOLATILES:
		actor.status_state.remove_volatile(id)
		if target.status_state.has_volatile(id): actor.status_state.add_volatile(id, target.status_state.volatile[id])
	events.append(BattleEvent.new(BattleEvent.TRANSFORMED, state.turn, actor.instance_id,
		target.instance_id, &"transform", 0, {"species_id": String(actor.species_id),
		"appearance_id": String(actor.appearance_id()),
		"original_species_id": String(actor.base_species_id()), "ability_id": String(actor.ability_id),
		"copied_moves": _move_ids(actor)}))
	return true


static func _move_ids(creature: CreatureInstance) -> Array[String]:
	var ids: Array[String] = []
	for slot: BattleMoveSlot in creature.moveset: ids.append(String(slot.move_id))
	return ids


static func restore(state: BattleState, creature: CreatureInstance, events: Array[BattleEvent], reason: String) -> void:
	if not creature.restore_battle_transform(): return
	events.append(BattleEvent.new(BattleEvent.TRANSFORM_REVERTED, state.turn, creature.instance_id,
		creature.instance_id, &"", 0, {"species_id": String(creature.species_id), "appearance_id": String(creature.appearance_id()), "reason": reason}))


static func restore_all(state: BattleState, events: Array[BattleEvent], reason: String) -> void:
	for id: StringName in state.participant_ids: restore(state, state.creature(id), events, reason)
