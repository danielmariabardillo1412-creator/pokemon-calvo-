class_name TrainerAdaptiveBranchingCorpusTestSuite
extends TrainerEvaluationCorpusTestSuite


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return AdaptiveBranchingTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 32, 3),
	)
