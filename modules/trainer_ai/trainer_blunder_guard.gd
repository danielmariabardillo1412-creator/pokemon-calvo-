class_name TrainerBlunderGuard
extends RefCounted

# Conservative post-evaluation guard. It blocks only facts that are certain from
# legitimate observation; it must not become a second strategy engine.


static func inspect(
	context: TrainerDecisionContext,
	action: BattleAction,
	catalog: DefinitionCatalog,
) -> Dictionary:
	if context == null or context.observation == null or action == null or catalog == null:
		return {"blocked": true, "reason": "invalid_guard_input"}
	if action.action_type == BattleAction.MOVE:
		return _inspect_move(context.observation, action, catalog)
	if action.action_type == BattleAction.SWITCH:
		return _inspect_switch(context.observation, action)
	return {"blocked": true, "reason": "unsupported_action_type"}


static func _inspect_move(
	observation: TrainerObservation,
	action: BattleAction,
	catalog: DefinitionCatalog,
) -> Dictionary:
	var move := catalog.move(action.move_id)
	if move == null:
		return {"blocked": true, "reason": "unknown_move_definition"}
	var own := _view_by_id(observation.own_party, action.actor_id)
	if own.is_empty():
		return {"blocked": true, "reason": "actor_not_observed"}
	var slot := _move_slot(own, action.move_id)
	if slot.is_empty() or int(slot.get("current_pp", 0)) <= 0:
		return {"blocked": true, "reason": "move_without_pp"}
	var opponent := _view_by_id(observation.observed_opponents, observation.opponent_active_id)
	if opponent.is_empty():
		return {"blocked": false, "reason": ""}
	if move.power > 0:
		var defender := catalog.species(StringName(opponent.get("species_id", "")))
		if defender != null and _type_effectiveness_bp(move.type_id, defender, catalog) == 0:
			return {"blocked": true, "reason": "known_type_immunity"}
	return {"blocked": false, "reason": ""}


static func _inspect_switch(observation: TrainerObservation, action: BattleAction) -> Dictionary:
	var incoming := _view_by_id(observation.own_party, action.switch_instance_id)
	if incoming.is_empty():
		return {"blocked": true, "reason": "switch_target_not_owned"}
	if int(incoming.get("current_hp", 0)) <= 0 or bool(incoming.get("is_knocked_out", false)):
		return {"blocked": true, "reason": "switch_target_knocked_out"}
	if StringName(incoming.get("instance_id", "")) == observation.own_active_id:
		return {"blocked": true, "reason": "switch_target_already_active"}
	return {"blocked": false, "reason": ""}


static func _view_by_id(views: Array[Dictionary], creature_id: StringName) -> Dictionary:
	for view in views:
		if StringName(view.get("instance_id", "")) == creature_id:
			return view
	return {}


static func _move_slot(view: Dictionary, move_id: StringName) -> Dictionary:
	for value in view.get("moveset", []):
		var slot := value as Dictionary
		if StringName(slot.get("move_id", "")) == move_id:
			return slot
	return {}


static func _type_effectiveness_bp(
	attack_type_id: StringName,
	defender: CreatureSpecies,
	catalog: DefinitionCatalog,
) -> int:
	var multiplier := 1.0
	for defender_type_id in defender.type_ids_resolved():
		multiplier *= catalog.type_multiplier(attack_type_id, defender_type_id)
	return int(round(multiplier * 10000.0))
