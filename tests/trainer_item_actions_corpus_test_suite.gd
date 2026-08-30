class_name TrainerItemActionsCorpusTestSuite
extends TrainerEvaluationCorpusTestSuite


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return ItemAwareTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 32, 3),
	)
