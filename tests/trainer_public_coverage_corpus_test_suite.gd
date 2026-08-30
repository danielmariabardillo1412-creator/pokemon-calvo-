class_name TrainerPublicCoverageCorpusTestSuite
extends TrainerEvaluationCorpusTestSuite


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return PublicCoverageAdaptiveTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 32, 3),
	)
