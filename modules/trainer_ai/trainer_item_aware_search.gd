class_name TrainerItemAwareSearch
extends TrainerPublicCoverageAdaptiveSearch

const ITEM_SEARCH_MODEL := "finite_item_depth_search_v1"
const ITEM_ACTION_SAMPLING_MODEL := "move_switch_item_stratified_round_robin_v1"


func _init(
	catalog: DefinitionCatalog,
	profile: TrainerProfile = null,
	budget: TrainerSearchBudget = null,
) -> void:
	super(catalog, profile, budget)
	_world_factory = TrainerItemAwareWorldFactory.new(catalog)


func evaluate(context: TrainerDecisionContext, root_action: BattleAction) -> Dictionary:
	var result := super.evaluate(context, root_action)
	var metadata := result.get("metadata", {}) as Dictionary
	metadata["item_search_model"] = ITEM_SEARCH_MODEL
	metadata["item_action_sampling_model"] = ITEM_ACTION_SAMPLING_MODEL
	metadata["battle_item_resource_model"] = TrainerItemAwareWorldFactory.RESOURCE_MODEL
	result["metadata"] = metadata
	return result


func _bounded_actions(actions: Array[BattleAction], limit: int) -> Array[BattleAction]:
	var moves: Array[BattleAction] = []
	var switches: Array[BattleAction] = []
	var items: Array[BattleAction] = []
	for action in actions:
		var clone := BattleAction.from_dict(action.to_dict())
		match action.action_type:
			BattleAction.SWITCH:
				switches.append(clone)
			BattleAction.ITEM:
				items.append(clone)
			_:
				moves.append(clone)
	var out: Array[BattleAction] = []
	var index := 0
	while out.size() < limit:
		var added := false
		for group in [moves, switches, items]:
			if index < group.size() and out.size() < limit:
				out.append(group[index])
				added = true
		if not added:
			break
		index += 1
	return out


func _normalize_action(
	action: BattleAction,
	state: BattleState,
	side_id: StringName,
) -> BattleAction:
	if action == null or state == null:
		return null
	if action.action_type != BattleAction.ITEM:
		return super._normalize_action(action, state, side_id)
	var actor := state.active_for_side(side_id)
	if actor == null or actor.is_knocked_out():
		return null
	var target := state.creature(action.target_id)
	var side := state.side_for_creature(actor.instance_id)
	if side == null or target == null or not side.owns(target.instance_id):
		return null
	return BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		&"",
		target.instance_id,
		BattleAction.ITEM,
		side_id,
		&"",
		action.item_id,
	)


func _action_key(action: BattleAction) -> String:
	if action == null:
		return "null"
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	return super._action_key(action)
