class_name ItemAwareTrainerBrain
extends PublicCoverageAdaptiveTrainerBrain

const ITEM_BRAIN_MODEL := "trainer_move_switch_item_v1"


func _init(
	catalog: DefinitionCatalog,
	p_profile: TrainerProfile = null,
	p_budget: TrainerSearchBudget = null,
) -> void:
	super(catalog, p_profile, p_budget)
	brain_id = &"item_aware_trainer_brain_v1"
	_search = TrainerItemAwareSearch.new(_catalog, profile, budget)
	_tactical = TrainerItemTacticalEvaluator.new(_catalog, profile)


func choose_action(context: TrainerDecisionContext) -> BattleAction:
	var selected := super.choose_action(context)
	if last_trace != null:
		last_trace.metadata["item_brain_model"] = ITEM_BRAIN_MODEL
		last_trace.metadata["item_search_model"] = TrainerItemAwareSearch.ITEM_SEARCH_MODEL
		last_trace.metadata["item_evaluation_model"] = TrainerItemTacticalEvaluator.ITEM_EVALUATION_MODEL
	return selected


func _action_key(action: BattleAction) -> String:
	if action == null:
		return "null"
	if action.action_type == BattleAction.ITEM:
		return "2:item:%s:%s" % [String(action.item_id), String(action.target_id)]
	return super._action_key(action)
