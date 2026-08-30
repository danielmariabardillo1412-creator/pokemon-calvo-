class_name TrainerStrategicSwitchingV2CorpusTestSuite
extends TrainerEvaluationCorpusTestSuite


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return StrategicSwitchingTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 32, 3),
	)
