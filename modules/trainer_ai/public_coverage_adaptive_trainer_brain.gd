class_name PublicCoverageAdaptiveTrainerBrain
extends AdaptiveBranchingTrainerBrain

const COVERAGE_SOURCE_ID := &"public_coverage_adaptive_depth_search_v1"


func _init(
	catalog: DefinitionCatalog,
	p_profile: TrainerProfile = null,
	p_budget: TrainerSearchBudget = null,
) -> void:
	super(catalog, p_profile, p_budget)
	brain_id = &"public_coverage_adaptive_trainer_brain_v1"
	_search = TrainerPublicCoverageAdaptiveSearch.new(_catalog, profile, budget)


func choose_action(context: TrainerDecisionContext) -> BattleAction:
	var selected := super.choose_action(context)
	if last_trace != null:
		last_trace.metadata["coverage_search_model"] = TrainerPublicCoverageAdaptiveSearch.COVERAGE_MODEL
		last_trace.metadata["coverage_selection_model"] = TrainerCoverageAwareWorldFactory.COVERAGE_SELECTION_MODEL
		last_trace.metadata["coverage_prior_model"] = TrainerPublicCoverageBeliefInference.COVERAGE_PRIOR_MODEL
	return selected
