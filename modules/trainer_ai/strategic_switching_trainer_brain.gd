class_name StrategicSwitchingTrainerBrain
extends ItemAwareTrainerBrain

const STRATEGIC_SWITCH_BRAIN_MODEL := "trainer_move_switch_item_strategic_switching_v2"


func _init(
	catalog: DefinitionCatalog,
	p_profile: TrainerProfile = null,
	p_budget: TrainerSearchBudget = null,
) -> void:
	super(catalog, p_profile, p_budget)
	brain_id = &"strategic_switching_trainer_brain_v2"
	_tactical = TrainerStrategicSwitchTacticalEvaluator.new(_catalog, profile)


func choose_action(context: TrainerDecisionContext) -> BattleAction:
	var selected := super.choose_action(context)
	if last_trace != null:
		last_trace.metadata["strategic_switch_brain_model"] = STRATEGIC_SWITCH_BRAIN_MODEL
		last_trace.metadata["strategic_switch_model"] = TrainerStrategicSwitchEvaluatorV2.MODEL_ID
		last_trace.metadata["strategic_switch_tactical_model"] = TrainerStrategicSwitchTacticalEvaluator.MODEL_ID
	return selected
