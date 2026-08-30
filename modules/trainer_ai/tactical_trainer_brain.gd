class_name TacticalTrainerBrain
extends TrainerBrain

const SOURCE_ID := &"tactical_composite_v1"

var profile: TrainerProfile
var last_trace: TrainerDecisionTrace = null

var _catalog: DefinitionCatalog
var _tactical: TrainerTacticalEvaluator
var _strategic: TrainerTeamStrategicEvaluator
var _switch_strategy: TrainerStrategicSwitchEvaluator


func _init(
	catalog: DefinitionCatalog,
	p_profile: TrainerProfile = null,
) -> void:
	_catalog = catalog
	profile = p_profile if p_profile != null else TrainerProfile.balanced()
	brain_id = &"tactical_trainer_brain_v1"
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
	var best_blocked_action: BattleAction = null
	var best_blocked_score := -2147483648
	var best_reason := ""

	for action in context.legal_actions:
		if action == null:
			continue
		var tactical := _tactical.evaluate(context, action)
		var strategic := _strategic.evaluate(context, action)
		var switch_strategy := _switch_strategy.evaluate(context, action)
		var guard := TrainerBlunderGuard.inspect(context, action, _catalog)
		var score := (
			int(tactical.get("score", 0))
			+ int(strategic.get("score", 0))
			+ int(switch_strategy.get("score", 0))
		)
		var reasons: Array[String] = []
		for reason in tactical.get("reasons", []):
			reasons.append(String(reason))
		for reason in strategic.get("reasons", []):
			reasons.append(String(reason))
		for reason in switch_strategy.get("reasons", []):
			reasons.append(String(reason))
		var blocked := bool(guard.get("blocked", false))
		if blocked:
			reasons.append("guard:%s" % String(guard.get("reason", "blocked")))
		var metadata := {
			"blocked": blocked,
			"guard_reason": String(guard.get("reason", "")),
			"tactical": (tactical.get("metadata", {}) as Dictionary).duplicate(true),
			"strategic": (strategic.get("metadata", {}) as Dictionary).duplicate(true),
			"switch_strategy": (switch_strategy.get("metadata", {}) as Dictionary).duplicate(true),
		}
		last_trace.add_candidate(
			action,
			SOURCE_ID,
			score,
			int(tactical.get("confidence_basis_points", 0)),
			reasons,
			metadata,
		)
		if blocked:
			if best_blocked_action == null or score > best_blocked_score:
				best_blocked_action = action
				best_blocked_score = score
			continue
		if best_action == null or score > best_score:
			best_action = action
			best_score = score
			best_reason = reasons[0] if not reasons.is_empty() else "highest_composite_score"

	if best_action == null:
		best_action = best_blocked_action
		best_reason = "all_candidates_guarded_fallback"
	if best_action == null:
		last_trace.selected_reason = "no_candidate_selected"
		return null
	last_trace.select(best_action, best_reason)
	last_trace.metadata["selected_score"] = best_score if best_score > -2147483648 else best_blocked_score
	last_trace.metadata["candidate_count"] = context.legal_actions.size()
	last_trace.metadata["switch_strategy_model"] = TrainerStrategicSwitchEvaluator.MODEL_ID
	return BattleAction.from_dict(best_action.to_dict())


func _new_trace(context: TrainerDecisionContext) -> TrainerDecisionTrace:
	var trace := TrainerDecisionTrace.new()
	trace.brain_id = brain_id
	trace.profile_id = profile.profile_id
	if context != null and context.observation != null:
		trace.battle_id = context.observation.battle_id
		trace.turn = context.observation.turn + 1
	return trace
