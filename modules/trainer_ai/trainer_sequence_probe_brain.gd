class_name TrainerSequenceProbeBrain
extends TrainerBrain

# Diagnostic-only brain used by search-limit benchmarks. It never invents actions:
# every requested step must match an action already present in the safe legal-action
# context. When a requested step is unavailable it falls back deterministically.

var steps: Array[Dictionary] = []


func _init(p_steps: Array[Dictionary] = []) -> void:
	brain_id = &"trainer_sequence_probe_brain_v1"
	for step in p_steps:
		steps.append((step as Dictionary).duplicate(true))


func choose_action(context: TrainerDecisionContext) -> BattleAction:
	if context == null or context.observation == null or context.legal_actions.is_empty():
		return null
	var index := maxi(0, context.observation.turn)
	if index < steps.size():
		var requested := steps[index]
		var matched := _match_step(context.legal_actions, requested)
		if matched != null:
			return BattleAction.from_dict(matched.to_dict())
	return _deterministic_fallback(context.legal_actions)


func _match_step(actions: Array[BattleAction], step: Dictionary) -> BattleAction:
	var kind := StringName(step.get("kind", "move"))
	if kind == BattleAction.SWITCH:
		var target := StringName(step.get("switch_instance_id", ""))
		for action in actions:
			if (
				action != null
				and action.action_type == BattleAction.SWITCH
				and action.switch_instance_id == target
			):
				return action
		return null
	var move_id := StringName(step.get("move_id", ""))
	for action in actions:
		if (
			action != null
			and action.action_type == BattleAction.MOVE
			and action.move_id == move_id
		):
			return action
	return null


func _deterministic_fallback(actions: Array[BattleAction]) -> BattleAction:
	var best: BattleAction = null
	var best_key := ""
	for action in actions:
		if action == null:
			continue
		var key := _action_key(action)
		if best == null or key < best_key:
			best = action
			best_key = key
	return BattleAction.from_dict(best.to_dict()) if best != null else null


func _action_key(action: BattleAction) -> String:
	if action.action_type == BattleAction.SWITCH:
		return "1:switch:%s" % String(action.switch_instance_id)
	return "0:move:%s" % String(action.move_id)
