class_name TrainerIntelligenceController
extends RefCounted

# Trusted orchestration seam. It owns perspective memory/beliefs, builds the safe
# observation/context and asks a replaceable brain for one action. The brain itself
# never receives BattleState, RNG or mutable CreatureInstance references.

var side_id: StringName
var memory := TrainerBattleMemory.new()
var belief := TrainerBeliefState.new()
var brain: TrainerBrain
var catalog: DefinitionCatalog = null
var inference: TrainerBeliefInference = null
var last_context: TrainerDecisionContext = null


func _init(
	p_side_id: StringName,
	p_brain: TrainerBrain,
	p_catalog: DefinitionCatalog = null,
) -> void:
	side_id = p_side_id
	brain = p_brain
	catalog = p_catalog
	if catalog != null:
		inference = TrainerBeliefInference.new(catalog)


func begin(server: AuthoritativeBattleServer) -> bool:
	last_context = null
	if server == null or server.state == null or brain == null:
		return false
	if not memory.begin(server.state, side_id):
		return false
	if not belief.begin(memory):
		return false
	if inference != null:
		var observation := TrainerObservationBuilder.build(server.state, side_id, memory)
		if observation != null:
			inference.seed_from_observation(belief, observation)
	return true


func observe(
	events: Array[BattleEvent],
	server: AuthoritativeBattleServer,
) -> bool:
	if server == null or server.state == null:
		return false
	var previous_observation: TrainerObservation = null
	if last_context != null:
		previous_observation = last_context.observation
	if not memory.observe_events(events, server.state):
		return false
	if not belief.sync_revealed(memory):
		return false
	if inference != null:
		var current_observation := TrainerObservationBuilder.build(
			server.state,
			side_id,
			memory,
		)
		if current_observation != null:
			inference.update_after_observation(
				belief,
				previous_observation,
				memory,
				current_observation,
			)
	return true


func choose_action(server: AuthoritativeBattleServer) -> BattleAction:
	if server == null or server.state == null or brain == null:
		return null
	var observation := TrainerObservationBuilder.build(server.state, side_id, memory)
	if observation == null:
		return null
	if inference != null:
		inference.seed_from_observation(belief, observation)
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
