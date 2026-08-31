class_name TurnExecutor
extends RefCounted

var _resolver := TurnResolver.new()
var _status_system := StatusSystem.new()
var _effect_executor := BattleEffectExecutor.new()
var _trigger_system := BattleTriggerSystem.new()
var _ruleset: BattleRuleset
var _registry: BattleEffectRegistry


func _init(p_ruleset: BattleRuleset = null, p_registry: BattleEffectRegistry = null) -> void:
	_ruleset = p_ruleset if p_ruleset != null else BattleRuleset.new()
	_registry = p_registry if p_registry != null else BattleEffectRegistry.new()


func execute(
	state: BattleState,
	actions: Array[BattleAction],
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
) -> Array[BattleEvent]:
	state.turn += 1
	var events: Array[BattleEvent] = []
	_begin_turn(state, catalog, rng, events)
	var ordered_actions := _resolver.resolve_order(actions, state, catalog, rng, _ruleset)
	for action in ordered_actions:
		if state.phase == BattleState.FINISHED:
			break
		_execute_action(action, state, catalog, rng, events)
	return _complete_turn(state, catalog, rng, events)


# Executes the response side of a turn whose other side has already spent its command outside the
# move/switch executor (for example, a failed capture attempt). This is intentionally not a general
# "free action" API: AuthoritativeBattleServer validates the responder and skipped side before this
# method is called. End-turn status/triggers still run exactly once and the battle turn advances once.
func execute_reaction(
	state: BattleState,
	action: BattleAction,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
) -> Array[BattleEvent]:
	state.turn += 1
	var events: Array[BattleEvent] = []
	_begin_turn(state, catalog, rng, events)
	if state.phase != BattleState.FINISHED:
		_execute_action(action, state, catalog, rng, events)
	return _complete_turn(state, catalog, rng, events)


func _begin_turn(
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> void:
	if state.battle_started:
		return
	state.battle_started = true
	for creature_id in state.active_ids.duplicate():
		_execute_triggers(
			BattleTriggerSpec.ON_SWITCH_IN,
			state.creature(creature_id),
			state.opponent_of(creature_id),
			null,
			state,
			catalog,
			rng,
			events,
		)


func _execute_action(
	action: BattleAction,
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> void:
	if action.action_type == BattleAction.SWITCH:
		_execute_switch(action, state, catalog, rng, events, false)
		return
	if action.action_type == BattleAction.ITEM:
		_execute_trainer_item(action, state, catalog, rng, events)
		_handle_knockouts(state, catalog, rng, events)
		return
	_execute_move(action, state, catalog, rng, events)
	_handle_knockouts(state, catalog, rng, events)


func _complete_turn(
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> Array[BattleEvent]:
	state.rng_state = rng.state()
	if state.phase == BattleState.FINISHED:
		return events
	events.append_array(_status_system.process_end_turn(state, catalog, _ruleset))
	_handle_knockouts(state, catalog, rng, events)
	if state.phase == BattleState.FINISHED:
		state.rng_state = rng.state()
		return events
	for creature_id in state.active_ids.duplicate():
		var owner := state.creature(creature_id)
		_execute_triggers(
			BattleTriggerSpec.END_TURN,
			owner,
			state.opponent_of(owner.instance_id),
			null,
			state,
			catalog,
			rng,
			events,
		)
	_handle_knockouts(state, catalog, rng, events)
	if state.phase != BattleState.FINISHED:
		events.append(BattleEvent.new(BattleEvent.TURN_ENDED, state.turn))
	state.rng_state = rng.state()
	return events


func _execute_move(
	action: BattleAction,
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> void:
	var actor := state.creature(action.actor_id)
	if actor == null or actor.is_knocked_out() or not state.active_ids.has(actor.instance_id):
		return
	var target := state.opponent_of(actor.instance_id)
	if target == null or target.is_knocked_out():
		return
	if not _status_system.can_act(state, actor, rng, events, _ruleset):
		return
	var move := catalog.move(action.move_id)
	var slot := actor.move_slot(action.move_id)
	if move == null or slot == null or not slot.consume():
		return
	events.append(BattleEvent.new(
		BattleEvent.ACTION_USED, state.turn, actor.instance_id, target.instance_id, move.id
	))
	events.append(BattleEvent.new(
		BattleEvent.PP_CHANGED,
		state.turn,
		actor.instance_id,
		actor.instance_id,
		move.id,
		-1,
		{"current_pp": slot.current_pp, "max_pp": slot.max_pp},
	))
	# Moves that can only target the user do not make the normal accuracy/evasion
	# check against the opposing Pokemon. Move-specific failure conditions remain
	# separate mechanics and must be enforced by their own effect contracts.
	if move.target != "user":
		var accuracy_threshold := _ruleset.accuracy_threshold_basis_points(
			move.accuracy,
			actor.stat_stages.get_stage(StatStages.ACCURACY),
			target.stat_stages.get_stage(StatStages.EVASION),
		)
		if not rng.roll_basis_points(accuracy_threshold):
			events.append(BattleEvent.new(
				BattleEvent.MOVE_MISSED,
				state.turn,
				actor.instance_id,
				target.instance_id,
				move.id,
				0,
				{"accuracy_basis_points": accuracy_threshold},
			))
			return
	var context := BattleEffectContext.new(
		state, actor, target, move, catalog, _ruleset, rng, events
	)
	_effect_executor.execute_all(_registry.effects_for_move(move), context, _registry)
	if context.last_damage > 0 and not target.is_knocked_out():
		_execute_triggers(
			BattleTriggerSpec.AFTER_DAMAGE,
			target,
			actor,
			move,
			state,
			catalog,
			rng,
			events,
		)


func _execute_trainer_item(
	action: BattleAction,
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> void:
	var actor := state.creature(action.actor_id)
	var actor_side := state.side_for_creature(action.actor_id)
	var target := state.creature(action.target_id)
	if actor == null or actor_side == null or target == null:
		return
	var inventory := state.item_inventory_for_side(actor_side.side_id)
	if inventory == null or not inventory.consume(action.item_id):
		return
	events.append(BattleEvent.new(
		BattleEvent.TRAINER_ITEM_USED,
		state.turn,
		actor.instance_id,
		target.instance_id,
		&"",
		1,
		{
			"item_id": String(action.item_id),
			"side_id": String(actor_side.side_id),
			"remaining_quantity": inventory.quantity(action.item_id),
		},
	))
	var context := BattleEffectContext.new(
		state, actor, target, null, catalog, _ruleset, rng, events
	)
	_effect_executor.execute_all(
		_registry.effects_for_trainer_item(action.item_id),
		context,
		_registry,
	)


func _execute_switch(
	action: BattleAction,
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
	forced: bool,
) -> void:
	var side := state.side_for_creature(action.actor_id)
	if side == null:
		return
	var outgoing := state.creature(side.active_id)
	var incoming := state.creature(action.switch_instance_id)
	if incoming == null or not state.switch_active(side.side_id, incoming.instance_id):
		return
	outgoing.stat_stages = StatStages.new()
	outgoing.status_state.volatile.clear()
	events.append(BattleEvent.new(
		BattleEvent.SWITCHED,
		state.turn,
		outgoing.instance_id,
		incoming.instance_id,
		&"",
		0,
		{"side_id": String(side.side_id), "forced": forced},
	))
	_execute_triggers(
		BattleTriggerSpec.ON_SWITCH_IN,
		incoming,
		state.opponent_of(incoming.instance_id),
		null,
		state,
		catalog,
		rng,
		events,
	)


func _execute_triggers(
	trigger: StringName,
	owner: CreatureInstance,
	target: CreatureInstance,
	move: MoveDefinition,
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> void:
	if owner == null or owner.is_knocked_out():
		return
	var context := BattleEffectContext.new(
		state, owner, target, move, catalog, _ruleset, rng, events
	)
	for spec in _trigger_system.specs_for_creature(owner, trigger, _registry):
		if not _trigger_system.conditions_met(spec, owner, move):
			continue
		_trigger_system.emit_source_triggered(context, spec, owner)
		var result := _effect_executor.execute(spec.effect, context, _registry)
		if spec.consume_source and result.applied:
			owner.held_item_consumed = true


func _handle_knockouts(
	state: BattleState,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> void:
	var knocked_out_sides: Array[BattleSide] = []
	for side in state.sides:
		var active := state.creature(side.active_id)
		if active == null or not active.is_knocked_out():
			continue
		if not _has_event_for_target(events, BattleEvent.KNOCKED_OUT, active.instance_id):
			events.append(BattleEvent.new(
				BattleEvent.KNOCKED_OUT, state.turn, &"", active.instance_id
			))
		var replacement := _first_available_replacement(side, state)
		if replacement != null:
			var forced_action := BattleAction.new(
				state.turn,
				active.instance_id,
				&"",
				&"",
				BattleAction.SWITCH,
				side.side_id,
				replacement.instance_id,
			)
			_execute_switch(forced_action, state, catalog, rng, events, true)
		else:
			knocked_out_sides.append(side)
	if knocked_out_sides.is_empty():
		return
	state.phase = BattleState.FINISHED
	state.winner_id = &""
	if knocked_out_sides.size() == 1:
		for side in state.sides:
			if side != knocked_out_sides[0]:
				state.winner_id = side.active_id
	events.append(BattleEvent.new(BattleEvent.BATTLE_ENDED, state.turn, state.winner_id))


func _first_available_replacement(side: BattleSide, state: BattleState) -> CreatureInstance:
	for creature_id in side.party_ids:
		if creature_id == side.active_id:
			continue
		var candidate := state.creature(creature_id)
		if candidate != null and not candidate.is_knocked_out():
			return candidate
	return null


func _has_event_for_target(
	events: Array[BattleEvent], kind: StringName, target_id: StringName
) -> bool:
	for event in events:
		if event.kind == kind and event.target_id == target_id:
			return true
	return false
