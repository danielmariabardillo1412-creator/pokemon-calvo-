class_name TrainerIntelligenceController
extends RefCounted

# Trusted orchestration seam. It owns perspective memory/beliefs, builds the safe
# observation/context and asks a replaceable brain for one action. The brain itself
# never receives BattleState, RNG or mutable CreatureInstance references.

var side_id: StringName
var memory := TrainerBattleMemory.new()
var belief := TrainerBeliefState.new()
var brain: TrainerBrain
var last_context: TrainerDecisionContext = null


func _init(
	p_side_id: StringName,
	p_brain: TrainerBrain,
) -> void:
	side_id = p_side_id
	brain = p_brain


func begin(server: AuthoritativeBattleServer) -> bool:
	last_context = null
	if server == null or server.state == null or brain == null:
		return false
	if not memory.begin(server.state, side_id):
		return false
	return belief.begin(memory)


func observe(
	events: Array[BattleEvent],
	server: AuthoritativeBattleServer,
) -> bool:
	if server == null or server.state == null:
		return false
	if not memory.observe_events(events, server.state):
		return false
	belief.sync_revealed(memory)
	return true


func choose_action(server: AuthoritativeBattleServer) -> BattleAction:
	if server == null or server.state == null or brain == null:
		return null
	var observation := TrainerObservationBuilder.build(server.state, side_id, memory)
	if observation == null:
		return null
	var legal_actions := TrainerActionSpace.from_server(server, side_id)
	last_context = TrainerDecisionContext.create(
		observation,
		belief,
		memory,
		legal_actions,
	)
	if last_context == null:
		return null
	return brain.choose_action(last_context)
