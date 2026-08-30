class_name BattleSimulationFork
extends RefCounted

# Isolated counterfactual execution boundary for search/planning systems.
# A fork is rebuilt from BattleState's serialized snapshot, so its participants,
# sides, PP, statuses, stat stages and RNG continuation are detached from the live battle.
# Battle Core remains the only authority that executes/validates actions.

var server: AuthoritativeBattleServer = null
var source_battle_id: StringName = &""
var source_turn: int = 0

var _catalog: DefinitionCatalog = null
var _ruleset: BattleRuleset = null
var _registry: BattleEffectRegistry = null


static func from_state(
	state: BattleState,
	catalog: DefinitionCatalog,
	ruleset: BattleRuleset = null,
	registry: BattleEffectRegistry = null,
) -> BattleSimulationFork:
	if state == null or catalog == null:
		return null

	# Deep-duplicate the primitive snapshot before restoration so sibling forks made
	# from the same source cannot accidentally share nested snapshot dictionaries.
	var snapshot := state.to_dict().duplicate(true)
	var restored := BattleState.from_dict(snapshot)
	var fork := BattleSimulationFork.new()
	fork._catalog = catalog
	fork._ruleset = ruleset if ruleset != null else BattleRuleset.new()
	fork._registry = registry if registry != null else BattleEffectRegistry.new()
	fork.server = AuthoritativeBattleServer.new(
		restored,
		fork._catalog,
		fork._ruleset,
		fork._registry,
	)
	fork.source_battle_id = state.battle_id
	fork.source_turn = state.turn
	return fork


func state() -> BattleState:
	return server.state if server != null else null


func snapshot() -> Dictionary:
	return server.snapshot().duplicate(true) if server != null else {}


func submit_turn(actions: Array[BattleAction]) -> Array[BattleEvent]:
	if server == null:
		return []
	return server.submit_turn(actions)


func fork() -> BattleSimulationFork:
	if server == null:
		return null
	return BattleSimulationFork.from_state(
		server.state,
		_catalog,
		_ruleset,
		_registry,
	)
