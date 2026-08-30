class_name TrainerAdaptiveBranchingSearch
extends TrainerMultiTurnSearch

const BRANCHING_SELECTOR_MODEL := "threat_ordered_kind_stratified_v1"


func _init(
	catalog: DefinitionCatalog,
	profile: TrainerProfile = null,
	budget: TrainerSearchBudget = null,
) -> void:
	super(catalog, profile, budget)
	_world_factory = TrainerThreatOrderedWorldFactory.new(catalog)


func evaluate(context: TrainerDecisionContext, root_action: BattleAction) -> Dictionary:
	var result := super.evaluate(context, root_action)
	var metadata := result.get("metadata", {}) as Dictionary
	metadata["branching_selector_model"] = BRANCHING_SELECTOR_MODEL
	metadata["plausible_move_ordering_model"] = TrainerThreatOrderedWorldFactory.ORDERING_MODEL
	metadata["max_actions_per_side_preserved"] = true
	result["metadata"] = metadata
	return result
