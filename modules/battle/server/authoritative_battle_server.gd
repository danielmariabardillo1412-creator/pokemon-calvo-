class_name AuthoritativeBattleServer
extends RefCounted

var state: BattleState
var _catalog: DefinitionCatalog
var _rng: SeededRandomSource
var _ruleset: BattleRuleset
var _executor: TurnExecutor
var _registry: BattleEffectRegistry


func _init(
	p_state: BattleState,
	p_catalog: DefinitionCatalog,
	p_ruleset: BattleRuleset = null,
	p_registry: BattleEffectRegistry = null,
) -> void:
	state = p_state
	_catalog = p_catalog
	_ruleset = p_ruleset if p_ruleset != null else BattleRuleset.new()
	_registry = p_registry if p_registry != null else BattleEffectRegistry.new()
	_executor = TurnExecutor.new(_ruleset, _registry)
	_rng = SeededRandomSource.new(state.rng_state)
	for creature_id in state.participant_ids:
		state.creature(creature_id).initialize_move_pp(_catalog)


func submit_turn(actions: Array[BattleAction]) -> Array[BattleEvent]:
	var error_code := _validate(actions)
	if not error_code.is_empty():
		return [_rejection(error_code)]
	return _executor.execute(state, actions, _catalog, _rng)


func validate_reaction_action(action: BattleAction, skipped_side_id: StringName) -> String:
	if state.phase != BattleState.WAITING_FOR_ACTIONS:
		return "battle_finished"
	if skipped_side_id == &"" or state.active_for_side(skipped_side_id) == null:
		return "invalid_skipped_side"
	if action == null:
		return "missing_reaction_action"
	var actor_side := state.side_for_creature(action.actor_id)
	if actor_side == null:
		return "actor_not_found"
	if actor_side.side_id == skipped_side_id:
		return "reaction_same_side"
	return _validate_action(action)


func submit_reaction_turn(
	action: BattleAction,
	skipped_side_id: StringName,
) -> Array[BattleEvent]:
	var error_code := validate_reaction_action(action, skipped_side_id)
	if not error_code.is_empty():
		return [_rejection(error_code)]
	return _executor.execute_reaction(state, action, _catalog, _rng)


func snapshot() -> Dictionary:
	return state.to_dict()


func _validate(actions: Array[BattleAction]) -> String:
	if state.phase != BattleState.WAITING_FOR_ACTIONS:
		return "battle_finished"
	if actions.size() != state.active_ids.size():
		return "wrong_action_count"
	var seen_actors: Dictionary = {}
	for action in actions:
		if action == null:
			return "missing_action"
		if seen_actors.has(action.actor_id):
			return "invalid_actor"
		var error_code := _validate_action(action)
		if not error_code.is_empty():
			return error_code
		seen_actors[action.actor_id] = true
	return ""


func _validate_action(action: BattleAction) -> String:
	if action.turn != state.turn + 1:
		return "wrong_turn"
	if state.creature(action.actor_id) == null:
		return "actor_not_found"
	if not state.active_ids.has(action.actor_id):
		return "invalid_actor"
	var actor := state.creature(action.actor_id)
	var actor_side := state.side_for_creature(action.actor_id)
	if action.side_id == &"":
		return "missing_participant"
	if actor_side == null or action.side_id != actor_side.side_id:
		return "wrong_participant"
	if actor == null or actor.is_knocked_out():
		return "actor_unavailable"
	if action.action_type == BattleAction.SWITCH:
		if not actor_side.owns(action.switch_instance_id):
			return "invalid_switch"
		if action.switch_instance_id == actor_side.active_id:
			return "already_active"
		var incoming := state.creature(action.switch_instance_id)
		if incoming == null or incoming.is_knocked_out():
			return "switch_target_unavailable"
	elif action.action_type == BattleAction.ITEM:
		return _validate_trainer_item_action(action, actor_side)
	elif action.action_type == BattleAction.MOVE:
		var slot := actor.move_slot(action.move_id)
		if slot == null or _catalog.move(action.move_id) == null:
			return "invalid_move"
		if slot.current_pp <= 0:
			return "no_pp"
		var expected_target := state.opponent_of(action.actor_id)
		if expected_target == null or expected_target.instance_id != action.target_id:
			return "invalid_target"
	else:
		return "invalid_action_type"
	return ""


func _validate_trainer_item_action(action: BattleAction, actor_side: BattleSide) -> String:
	if action.item_id == &"" or _catalog.item(action.item_id) == null:
		return "invalid_item"
	if not _registry.is_trainer_item_supported(action.item_id):
		return "item_not_battle_usable"
	var inventory := state.item_inventory_for_side(actor_side.side_id)
	if inventory == null or not inventory.has(action.item_id):
		return "item_unavailable"
	if action.target_id == &"" or not actor_side.owns(action.target_id):
		return "invalid_item_target"
	var target := state.creature(action.target_id)
	if target == null:
		return "item_target_unavailable"
	var target_mode := _registry.trainer_item_target_mode(action.item_id)
	if target_mode == BattleEffectRegistry.TRAINER_ITEM_TARGET_ALIVE and target.is_knocked_out():
		return "item_target_unavailable"
	if target_mode == BattleEffectRegistry.TRAINER_ITEM_TARGET_FAINTED and not target.is_knocked_out():
		return "item_requires_fainted_target"
	if not _trainer_item_has_effect(action.item_id, target):
		return "item_no_effect"
	return ""


func _trainer_item_has_effect(item_id: StringName, target: CreatureInstance) -> bool:
	for spec in _registry.effects_for_trainer_item(item_id):
		if spec.kind == BattleEffectSpec.HEAL and target.stats != null and target.current_hp < target.stats.max_hp:
			return true
		if spec.kind == BattleEffectSpec.CURE_STATUS and target.status_state.persistent_id != &"":
			return true
		if spec.kind == BattleEffectSpec.REVIVE and target.is_knocked_out() and target.stats != null and target.stats.max_hp > 0:
			return true
	return false


func _rejection(reason: String) -> BattleEvent:
	return BattleEvent.new(
		BattleEvent.ACTION_REJECTED,
		state.turn,
		&"",
		&"",
		&"",
		0,
		{"reason": reason},
	)
