class_name TrainerPublicCoverageAdaptiveSearch
extends TrainerAdaptiveBranchingSearch

const COVERAGE_MODEL := "public_coverage_adaptive_search_v1"


func _init(
	catalog: DefinitionCatalog,
	profile: TrainerProfile = null,
	budget: TrainerSearchBudget = null,
) -> void:
	super(catalog, profile, budget)
	_world_factory = TrainerCoverageAwareWorldFactory.new(catalog)


func evaluate(context: TrainerDecisionContext, root_action: BattleAction) -> Dictionary:
	var result := super.evaluate(context, root_action)
	var metadata := result.get("metadata", {}) as Dictionary
	metadata["coverage_search_model"] = COVERAGE_MODEL
	metadata["coverage_selection_model"] = TrainerCoverageAwareWorldFactory.COVERAGE_SELECTION_MODEL
	metadata["coverage_prior_model"] = TrainerPublicCoverageBeliefInference.COVERAGE_PRIOR_MODEL
	result["metadata"] = metadata
	return result
