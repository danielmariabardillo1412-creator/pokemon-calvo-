class_name AuthoritativeBattleServer
extends RefCounted

var state: BattleState
var _catalog: DefinitionCatalog
var _rng: SeededRandomSource
var _executor := TurnExecutor.new()


func _init(p_state: BattleState, p_catalog: DefinitionCatalog) -> void:
	state = p_state
	_catalog = p_catalog
	_rng = SeededRandomSource.new(state.rng_state)


func submit_turn(actions: Array[BattleAction]) -> Array[BattleEvent]:
	var error_code := _validate(actions)
	if not error_code.is_empty():
		return [BattleEvent.new(
			BattleEvent.ACTION_REJECTED,
			state.turn,
			&"",
			&"",
			&"",
			0,
			{"reason": error_code},
		)]
	return _executor.execute(state, actions, _catalog, _rng)


func snapshot() -> Dictionary:
	return state.to_dict()


func _validate(actions: Array[BattleAction]) -> String:
	if state.phase != BattleState.WAITING_FOR_ACTIONS:
		return "battle_finished"
	if actions.size() != state.active_ids.size():
		return "wrong_action_count"
	var seen_actors: Dictionary = {}
	for action in actions:
		if action.turn != state.turn + 1:
			return "wrong_turn"
		if not state.active_ids.has(action.actor_id) or seen_actors.has(action.actor_id):
			return "invalid_actor"
		seen_actors[action.actor_id] = true
		var actor := state.creature(action.actor_id)
		if actor == null or actor.is_knocked_out():
			return "actor_unavailable"
		if not actor.move_ids.has(action.move_id) or _catalog.move(action.move_id) == null:
			return "invalid_move"
		var expected_target := state.opponent_of(action.actor_id)
		if expected_target == null or expected_target.instance_id != action.target_id:
			return "invalid_target"
	return ""

