class_name TrainerItemTacticalEvaluator
extends TrainerTacticalEvaluator

const ITEM_EVALUATION_MODEL := "finite_heal_resource_value_v1"

var _item_registry := BattleEffectRegistry.new()


func evaluate(context: TrainerDecisionContext, action: BattleAction) -> Dictionary:
	if action == null or action.action_type != BattleAction.ITEM:
		return super.evaluate(context, action)
	return _evaluate_item(context, action)


func _evaluate_item(context: TrainerDecisionContext, action: BattleAction) -> Dictionary:
	if context == null or context.observation == null:
		return _result(-1000000, 0, ["invalid_item_context"])
	var target := _view_by_id(context.observation.own_party, action.target_id)
	if target.is_empty() or _catalog.item(action.item_id) == null:
		return _result(-1000000, 0, ["invalid_item_target"])
	var stats := target.get("stats", {}) as Dictionary
	var max_hp := maxi(1, int(stats.get("max_hp", 1)))
	var current_hp := clampi(int(target.get("current_hp", 0)), 0, max_hp)
	var missing_hp := maxi(0, max_hp - current_hp)
	var healed_hp := 0
	var requested_hp := 0
	var status_value := 0
	for spec in _item_registry.effects_for_trainer_item(action.item_id):
		if spec.kind == BattleEffectSpec.HEAL:
			var requested := spec.value
			if spec.ratio_basis_points > 0:
				requested = max_hp * spec.ratio_basis_points / 10000
			requested_hp = maxi(requested_hp, maxi(0, requested))
			healed_hp = maxi(healed_hp, mini(missing_hp, maxi(0, requested)))
		elif spec.kind == BattleEffectSpec.CURE_STATUS:
			var status_state := target.get("status_state", {}) as Dictionary
			if not String(status_state.get("persistent_id", "")).is_empty():
				status_value = 1400 * _profile.status_weight_bp / 10000

	var heal_ratio_bp := healed_hp * 10000 / max_hp
	var score := heal_ratio_bp * _profile.preservation_weight_bp / 10000
	score += status_value
	var waste_hp := maxi(0, requested_hp - missing_hp)
	var waste_ratio_bp := waste_hp * 10000 / max_hp
	score -= waste_ratio_bp / 4
	var resource_cost := _resource_cost(action.item_id)
	score -= resource_cost
	var reasons: Array[String] = ["finite_item_resource_cost"]
	if healed_hp > 0:
		reasons.append("recover_known_hp")
	if status_value > 0:
		reasons.append("cure_known_status")
	if waste_hp > 0:
		reasons.append("overheal_waste")
	return _result(
		score,
		10000,
		reasons,
		{
			"item_evaluation_model": ITEM_EVALUATION_MODEL,
			"item_id": String(action.item_id),
			"target_id": String(action.target_id),
			"healed_hp_if_uninterrupted": healed_hp,
			"heal_ratio_basis_points": heal_ratio_bp,
			"overheal_waste_hp": waste_hp,
			"resource_cost": resource_cost,
		},
	)


func _resource_cost(item_id: StringName) -> int:
	# V1 opportunity costs are intentionally explicit heuristics, not claimed optimal
	# values. FASE36 will calibrate them against counterfactual win probability.
	match item_id:
		&"potion":
			return 250
		&"super_potion":
			return 500
		&"hyper_potion":
			return 900
		&"max_potion":
			return 1200
		&"full_restore":
			return 1400
		_:
			return 1000
