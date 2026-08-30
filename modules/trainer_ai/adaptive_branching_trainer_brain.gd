class_name AdaptiveBranchingTrainerBrain
extends DepthSearchTrainerBrain

const ADAPTIVE_SOURCE_ID := &"adaptive_branching_depth_search_v1"


func _init(
	catalog: DefinitionCatalog,
	p_profile: TrainerProfile = null,
	p_budget: TrainerSearchBudget = null,
) -> void:
	super(catalog, p_profile, p_budget)
	brain_id = &"adaptive_branching_trainer_brain_v1"
	_search = TrainerAdaptiveBranchingSearch.new(_catalog, profile, budget)


func choose_action(context: TrainerDecisionContext) -> BattleAction:
	var selected := super.choose_action(context)
	if last_trace != null:
		last_trace.metadata["branching_selector_model"] = TrainerAdaptiveBranchingSearch.BRANCHING_SELECTOR_MODEL
		last_trace.metadata["plausible_move_ordering_model"] = TrainerThreatOrderedWorldFactory.ORDERING_MODEL
	return selected
