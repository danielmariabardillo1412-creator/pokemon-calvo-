class_name TrainerDecisionContext
extends RefCounted

# Safe input contract for every future trainer brain. It intentionally contains no
# BattleState, CreatureInstance or RNG object from the authoritative battle.

var observation: TrainerObservation = null
var belief_snapshot: Dictionary = {}
var memory_snapshot: Dictionary = {}
var legal_actions: Array[BattleAction] = []


static func create(
	p_observation: TrainerObservation,
	belief: TrainerBeliefState,
	memory: TrainerBattleMemory,
	p_legal_actions: Array[BattleAction] = [],
) -> TrainerDecisionContext:
	if p_observation == null or belief == null or memory == null:
		return null
	var context := TrainerDecisionContext.new()
	context.observation = p_observation
	context.belief_snapshot = belief.to_dict().duplicate(true)
	context.memory_snapshot = memory.to_dict().duplicate(true)
	for action in p_legal_actions:
		if action != null:
			context.legal_actions.append(BattleAction.from_dict(action.to_dict()))
	return context


func to_dict() -> Dictionary:
	var actions: Array[Dictionary] = []
	for action in legal_actions:
		actions.append(action.to_dict())
	return {
		"observation": observation.to_dict() if observation != null else {},
		"belief": belief_snapshot.duplicate(true),
		"memory": memory_snapshot.duplicate(true),
		"legal_actions": actions,
	}
