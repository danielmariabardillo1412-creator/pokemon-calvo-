class_name TrainerStrategicSwitchTacticalEvaluator
extends TrainerItemTacticalEvaluator

const MODEL_ID := "item_tactical_plus_strategic_switching_v2"

var _switch_strategy: TrainerStrategicSwitchEvaluatorV2


func _init(catalog: DefinitionCatalog, profile: TrainerProfile = null) -> void:
	super(catalog, profile)
	_switch_strategy = TrainerStrategicSwitchEvaluatorV2.new(catalog, profile)


func evaluate(context: TrainerDecisionContext, action: BattleAction) -> Dictionary:
	var base := super.evaluate(context, action)
	var switching := _switch_strategy.evaluate(context, action)
	var reasons: Array[String] = []
	for raw_reason in base.get("reasons", []):
		reasons.append(String(raw_reason))
	for raw_reason in switching.get("reasons", []):
		reasons.append("switch:%s" % String(raw_reason))
	var metadata := (base.get("metadata", {}) as Dictionary).duplicate(true)
	metadata["strategic_switching"] = (switching.get("metadata", {}) as Dictionary).duplicate(true)
	metadata["strategic_switch_model"] = TrainerStrategicSwitchEvaluatorV2.MODEL_ID
	return {
		"score": int(base.get("score", 0)) + int(switching.get("score", 0)),
		"confidence_basis_points": maxi(
			int(base.get("confidence_basis_points", 0)),
			int(switching.get("confidence_basis_points", 0)),
		),
		"reasons": reasons,
		"metadata": metadata,
	}
