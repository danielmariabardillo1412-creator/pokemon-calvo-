class_name TrainerSimultaneousSearch
extends RefCounted

const SEARCH_MODEL_ID := "simultaneous_one_turn_robust_v1"

var _catalog: DefinitionCatalog
var _profile: TrainerProfile
var _world_factory: TrainerPlausibleWorldFactory


func _init(
	catalog: DefinitionCatalog,
	profile: TrainerProfile = null,
) -> void:
	_catalog = catalog
	_profile = profile if profile != null else TrainerProfile.balanced()
	_world_factory = TrainerPlausibleWorldFactory.new(_catalog)


func evaluate(
	context: TrainerDecisionContext,
	action: BattleAction,
) -> Dictionary:
	if context == null or context.observation == null or action == null or _catalog == null:
		return _result(-100000, 0, 0, 0, [], ["invalid_search_input"])
	var worlds := _world_factory.build(context)
	if worlds.is_empty():
		return _result(0, 0, 0, 0, [], ["no_plausible_worlds"])
	var scenario_scores: Array[int] = []
	var scenario_records: Array[Dictionary] = []
	var weighted_sum := 0
	var weighted_denominator := 0
	for world in worlds:
		var opponent_actions := TrainerOpponentActionSpace.from_world(world, context, _catalog)
		if opponent_actions.is_empty():
			continue
		var per_world_scores: Array[int] = []
		for opponent_action in opponent_actions:
			var fork := BattleSimulationFork.from_state(world.state, _catalog)
			if fork == null or fork.state() == null:
				continue
			var own_copy := _action_for_world(action, fork.state(), context.observation, true)
			var opponent_copy := _action_for_world(opponent_action, fork.state(), context.observation, false)
			var before := BattleState.from_dict(fork.snapshot())
			var actions: Array[BattleAction] = [own_copy, opponent_copy]
			var events := fork.submit_turn(actions)
			if _was_rejected(events):
				continue
			var evaluated := TrainerSearchStateEvaluator.evaluate(
				before,
				fork.state(),
				context.observation.observer_side_id,
			)
			var score := int(evaluated.get("score", 0))
			per_world_scores.append(score)
			scenario_scores.append(score)
			scenario_records.append({
				"world_id": String(world.world_id),
				"opponent_action": opponent_copy.to_dict(),
				"score": score,
				"reasons": (evaluated.get("reasons", []) as Array).duplicate(),
			})
		if per_world_scores.is_empty():
			continue
		var world_mean := _mean(per_world_scores)
		var world_worst := _minimum(per_world_scores)
		var world_score := _robust_score(world_mean, world_worst)
		weighted_sum += world_score * world.weight_basis_points
		weighted_denominator += world.weight_basis_points
	if scenario_scores.is_empty() or weighted_denominator <= 0:
		return _result(0, 0, 0, 0, scenario_records, ["no_valid_scenarios"])
	var aggregate := weighted_sum / weighted_denominator
	var mean_score := _mean(scenario_scores)
	var worst_score := _minimum(scenario_scores)
	var reasons: Array[String] = ["simultaneous_response_matrix"]
	if worst_score < 0:
		reasons.append("downside_risk_observed")
	if aggregate > 0:
		reasons.append("positive_robust_expectation")
	elif aggregate < 0:
		reasons.append("negative_robust_expectation")
	return _result(
		aggregate,
		mean_score,
		worst_score,
		scenario_scores.size(),
		scenario_records,
		reasons,
		worlds.size(),
	)


func _action_for_world(
	action: BattleAction,
	state: BattleState,
	observation: TrainerObservation,
	is_own: bool,
) -> BattleAction:
	var copy := BattleAction.from_dict(action.to_dict())
	copy.turn = state.turn + 1
	copy.side_id = observation.observer_side_id if is_own else observation.opponent_side_id
	if copy.action_type == BattleAction.MOVE:
		var target_side := observation.opponent_side_id if is_own else observation.observer_side_id
		var target := state.active_for_side(target_side)
		copy.target_id = target.instance_id if target != null else &""
	return copy


func _was_rejected(events: Array[BattleEvent]) -> bool:
	for event in events:
		if event.kind == BattleEvent.ACTION_REJECTED:
			return true
	return false


func _robust_score(mean_score: int, worst_score: int) -> int:
	var risk_bp := _risk_weight_basis_points()
	return mean_score * (10000 - risk_bp) / 10000 + worst_score * risk_bp / 10000


func _risk_weight_basis_points() -> int:
	match _profile.profile_id:
		TrainerProfile.AGGRESSIVE:
			return 2500
		TrainerProfile.CAUTIOUS:
			return 6500
		TrainerProfile.TECHNICAL:
			return 5000
		_:
			return 4000


func _mean(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var total := 0
	for value in values:
		total += value
	return total / values.size()


func _minimum(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var result := values[0]
	for value in values:
		result = mini(result, value)
	return result


func _result(
	score: int,
	mean_score: int,
	worst_score: int,
	scenario_count: int,
	scenarios: Array[Dictionary],
	reasons: Array[String],
	world_count: int = 0,
) -> Dictionary:
	return {
		"score": score,
		"confidence_basis_points": _confidence(world_count, scenario_count),
		"reasons": reasons,
		"metadata": {
			"search_model": SEARCH_MODEL_ID,
			"world_count": world_count,
			"scenario_count": scenario_count,
			"mean_score": mean_score,
			"worst_score": worst_score,
			"risk_weight_basis_points": _risk_weight_basis_points(),
			"scenarios": scenarios.duplicate(true),
		},
	}


func _confidence(world_count: int, scenario_count: int) -> int:
	if world_count <= 0 or scenario_count <= 0:
		return 0
	return clampi(4500 + world_count * 180 + mini(2500, scenario_count * 80), 0, 9000)
