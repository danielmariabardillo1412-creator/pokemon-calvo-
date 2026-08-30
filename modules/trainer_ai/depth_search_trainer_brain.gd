class_name DepthSearchTrainerBrain
extends TrainerBrain

const SOURCE_ID := &"depth_budget_search_composite_v1"

var profile: TrainerProfile
var budget: TrainerSearchBudget
var last_trace: TrainerDecisionTrace = null

var _catalog: DefinitionCatalog
var _search: TrainerMultiTurnSearch
var _tactical: TrainerTacticalEvaluator
var _strategic: TrainerTeamStrategicEvaluator
var _switch_strategy: TrainerStrategicSwitchEvaluator


func _init(
	catalog: DefinitionCatalog,
	p_profile: TrainerProfile = null,
	p_budget: TrainerSearchBudget = null,
) -> void:
	_catalog = catalog
	profile = p_profile if p_profile != null else TrainerProfile.balanced()
	budget = p_budget.duplicate_budget() if p_budget != null else TrainerSearchBudget.depth_two_default()
	brain_id = &"depth_search_trainer_brain_v1"
	_search = TrainerMultiTurnSearch.new(_catalog, profile, budget)
	_tactical = TrainerTacticalEvaluator.new(_catalog, profile)
	_strategic = TrainerTeamStrategicEvaluator.new(_catalog, profile)
	_switch_strategy = TrainerStrategicSwitchEvaluator.new(_catalog, profile)


func choose_action(context: TrainerDecisionContext) -> BattleAction:
	last_trace = _new_trace(context)
	if context == null or context.observation == null or context.legal_actions.is_empty():
		if last_trace != null:
			last_trace.selected_reason = "no_legal_actions"
		return null
	var best_action: BattleAction = null
	var best_score := -2147483648
	for action in context.legal_actions:
		if action == null:
			continue
		var guard := TrainerBlunderGuard.inspect(context, action, _catalog)
		var tactical := _tactical.evaluate(context, action)
		var strategic := _strategic.evaluate(context, action)
		var switch_strategy := _switch_strategy.evaluate(context, action)
		var search := _search.evaluate(context, action)
		var baseline_score := (
			int(tactical.get("score", 0))
			+ int(strategic.get("score", 0))
			+ int(switch_strategy.get("score", 0))
		)
		var search_confidence := int(search.get("confidence_basis_points", 0))
		var score := baseline_score if search_confidence <= 0 else int(search.get("score", 0)) + baseline_score / 4
		var reasons: Array[String] = []
		for reason in search.get("reasons", []):
			reasons.append("search:%s" % String(reason))
		for reason in tactical.get("reasons", []):
			reasons.append("tactical:%s" % String(reason))
		for reason in strategic.get("reasons", []):
			reasons.append("strategic:%s" % String(reason))
		for reason in switch_strategy.get("reasons", []):
			reasons.append("switch:%s" % String(reason))
		var blocked := bool(guard.get("blocked", false))
		if blocked:
			reasons.append("guard:%s" % String(guard.get("reason", "blocked")))
		last_trace.add_candidate(
			action,
			SOURCE_ID,
			score,
			search_confidence if search_confidence > 0 else int(tactical.get("confidence_basis_points", 0)),
			reasons,
			{
				"blocked": blocked,
				"guard_reason": String(guard.get("reason", "")),
				"baseline_score": baseline_score,
				"search": (search.get("metadata", {}) as Dictionary).duplicate(true),
				"tactical": (tactical.get("metadata", {}) as Dictionary).duplicate(true),
				"strategic": (strategic.get("metadata", {}) as Dictionary).duplicate(true),
				"switch_strategy": (switch_strategy.get("metadata", {}) as Dictionary).duplicate(true),
			},
		)
		if blocked:
			continue
		if best_action == null or score > best_score or (score == best_score and _action_key(action) < _action_key(best_action)):
			best_action = action
			best_score = score
	if best_action == null:
		last_trace.selected_reason = "all_candidates_guarded"
		return null
	last_trace.select(best_action, "highest_bounded_depth_search_score")
	last_trace.metadata["selected_score"] = best_score
	last_trace.metadata["search_model"] = TrainerMultiTurnSearch.SEARCH_MODEL_ID
	last_trace.metadata["switch_strategy_model"] = TrainerStrategicSwitchEvaluator.MODEL_ID
	last_trace.metadata["budget"] = budget.to_dict()
	last_trace.metadata["candidate_count"] = context.legal_actions.size()
	return BattleAction.from_dict(best_action.to_dict())


func _new_trace(context: TrainerDecisionContext) -> TrainerDecisionTrace:
	var trace := TrainerDecisionTrace.new()
	trace.brain_id = brain_id
	trace.profile_id = profile.profile_id
	if context != null and context.observation != null:
		trace.battle_id = context.observation.battle_id
		trace.turn = context.observation.turn + 1
	return trace


func _action_key(action: BattleAction) -> String:
	if action.action_type == BattleAction.SWITCH:
		return "1:switch:%s" % String(action.switch_instance_id)
	return "0:move:%s" % String(action.move_id)
