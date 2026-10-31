class_name TurnExecutor
extends RefCounted

const Transform = preload("res://modules/battle/application/transform_rules.gd")
const SwitchMoves = preload("res://modules/battle/application/switch_move_rules.gd")
const Substitute = preload("res://modules/battle/application/substitute_rules.gd")
const Weather = preload("res://modules/battle/application/weather_rules.gd")
const StageMoves = preload("res://modules/battle/application/stat_stage_move_rules.gd")
const FixedMoves = preload("res://modules/battle/application/fixed_damage_move_rules.gd")
const VariableMoves = preload("res://modules/battle/application/variable_power_move_rules.gd")
const Bindings = preload("res://modules/battle/application/binding_move_rules.gd")
const HealingMoves = preload("res://modules/battle/application/healing_move_rules.gd")

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
	return _run_remaining_actions(state, ordered_actions, catalog, rng, events)


func _run_remaining_actions(state: BattleState, actions: Array[BattleAction], catalog: DefinitionCatalog,
	rng: SeededRandomSource, events: Array[BattleEvent]) -> Array[BattleEvent]:
	for i in actions.size():
		if state.phase == BattleState.FINISHED:
			break
		_execute_action(actions[i], state, catalog, rng, events)
		if state.phase == BattleState.WAITING_FOR_SWITCH:
			state.remaining_turn_actions.clear()
			for next in range(i + 1, actions.size()):
				state.remaining_turn_actions.append(BattleAction.from_dict(actions[next].to_dict()))
			state.rng_state = rng.state()
			return events
	return _complete_turn(state, catalog, rng, events)


func resume_switch(state: BattleState, incoming_id: StringName, catalog: DefinitionCatalog,
	rng: SeededRandomSource) -> Array[BattleEvent]:
	# Ownership/turn/eligibility are checked atomically by the server before entry.
	var request := state.pending_switch.duplicate(true)
	var actions := state.remaining_turn_actions.duplicate()
	state.pending_switch.clear()
	state.remaining_turn_actions.clear()
	state.phase = BattleState.WAITING_FOR_ACTIONS
	var events: Array[BattleEvent] = []
	_execute_switch(BattleAction.new(state.turn, StringName(request.actor_id), &"", &"",
		BattleAction.SWITCH, StringName(request.side_id), incoming_id), state, catalog, rng,
		events, false, StringName(request.move_id), &"pivot", request.get("transfer", {}))
	_handle_knockouts(state, catalog, rng, events)
	return _run_remaining_actions(state, actions, catalog, rng, events)


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
	if state.phase == BattleState.WAITING_FOR_SWITCH:
		state.remaining_turn_actions.clear()
		state.rng_state = rng.state()
		return events
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
	if not state.active_ids.has(action.actor_id):
		return # A forced-out actor cannot execute its previously queued command.
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
	var residual_ids: Array[StringName] = []
	if state.weather_rules_enabled:
		residual_ids.assign(state.active_ids)
		Weather.end_turn(state, catalog, events)
		_handle_knockouts(state, catalog, rng, events)
		if state.phase == BattleState.FINISHED:
			state.rng_state = rng.state()
			return events
	events.append_array(_status_system.process_end_turn(state, catalog, _ruleset, residual_ids))
	_handle_knockouts(state, catalog, rng, events)
	if state.phase == BattleState.FINISHED:
		state.rng_state = rng.state()
		return events
	for creature_id in state.active_ids.duplicate():
		if not residual_ids.is_empty() and creature_id not in residual_ids:
			continue
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
		Bindings.end_turn(state, catalog, events, residual_ids)
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
	var fixed_damage: bool = state.live_moves_enabled and FixedMoves.supports(move)
	if state.switch_move_rules_enabled and SwitchMoves.supports(move):
		move = SwitchMoves.execution_move(move)
	if state.live_moves_enabled and StageMoves.supports(move): move = StageMoves.execution_move(move)
	if fixed_damage: move = FixedMoves.execution_move(move)
	if state.live_moves_enabled and Bindings.supports(move): move = Bindings.execution_move(move)
	var forced: bool = state.live_moves_enabled and move.id == &"struggle" and preload("res://modules/battle/application/live_move_profile.gd").forced_struggle(actor, catalog)
	var slot := BattleMoveSlot.new(&"struggle", 1, 1) if forced else actor.move_slot(action.move_id)
	if forced:
		move = MoveDefinition.from_dict(move.to_dict())
		move.accuracy = -1
		move.makes_contact = true
		move.effect_specs.assign([BattleEffectSpec.new(BattleEffectSpec.DAMAGE), BattleEffectSpec.new(BattleEffectSpec.FIXED_DAMAGE, BattleEffectSpec.SELF, maxi(1, roundi(actor.stats.max_hp / 4.0)))])
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
	if move.target != "user" and not (state.live_moves_enabled and HealingMoves.supports(move)) and not (state.live_moves_enabled and StageMoves.supports(move) and move.id in [&"acupressure", &"haze"]):
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
	if state.live_moves_enabled and HealingMoves.supports(move):
		HealingMoves.apply(state, actor, target, move, catalog, events)
		return
	if state.transform_rules_enabled and Transform.supports(move):
		if Transform.apply(state, actor, target, catalog, events):
			_execute_triggers(BattleTriggerSpec.ON_SWITCH_IN, actor, target, move, state, catalog, rng, events, true)
		return
	if state.substitute_rules_enabled and Substitute.supports(move):
		if Substitute.create(state, actor, move, events) and move.id == &"shed_tail":
			_request_pivot(actor, move, state, events)
		return
	if state.weather_rules_enabled and Weather.supports(move):
		# Snow must be established before a Chilly Reception replacement request.
		if move.id == &"chilly_reception" and not state.switch_move_rules_enabled:
			_switch_effect_failed(actor, actor, move, state, events, "switch_rules_required")
			return
		var changed := Weather.start(state, actor, move, events)
		if move.id == &"chilly_reception":
			if not changed and not SwitchMoves.replacements(state, state.side_for_creature(actor.instance_id).side_id).is_empty():
				events.append(BattleEvent.new(BattleEvent.MOVE_EFFECT_RESOLVED, state.turn,
					actor.instance_id, actor.instance_id, move.id))
			_request_pivot(actor, move, state, events)
		return
	if state.switch_move_rules_enabled and SwitchMoves.supports_status(move):
		_execute_status_switch(actor, target, move, state, catalog, rng, events)
		return
	if state.live_moves_enabled and StageMoves.supports(move) and move.id in StageMoves.STATUS_IDS:
		StageMoves.apply_status(state, actor, target, move, rng, events)
		return
	var context := BattleEffectContext.new(
		state, actor, target, move, catalog, _ruleset, rng, events
	)
	if state.live_moves_enabled and VariableMoves.supports(move):
		move = VariableMoves.execution_move(move, actor, target, _ruleset)
		context.move = move
	if fixed_damage:
		FixedMoves.apply(context)
	else:
		_effect_executor.execute_all(_registry.effects_for_move(move), context, _registry)
	if (context.body_damage > 0 if state.substitute_rules_enabled else context.last_damage > 0) and not target.is_knocked_out():
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
	if state.switch_move_rules_enabled and SwitchMoves.supports(move):
		_handle_knockouts(state, catalog, rng, events)
		if context.last_damage > 0 and state.phase != BattleState.FINISHED and not actor.is_knocked_out():
			if state.substitute_rules_enabled and context.substitute_intercepted and move.id in SwitchMoves.PHAZES:
				_switch_effect_failed(actor, target, move, state, events, "substitute")
			else:
				_apply_switch_move(actor, target, move, state, catalog, rng, events)


func _apply_switch_move(actor: CreatureInstance, target: CreatureInstance, move: MoveDefinition,
	state: BattleState, catalog: DefinitionCatalog, rng: SeededRandomSource,
	events: Array[BattleEvent]) -> void:
	if move.id in SwitchMoves.PIVOTS or move.id in SwitchMoves.STATUS_PIVOTS:
		_request_pivot(actor, move, state, events)
		return
	if target.is_knocked_out() or not state.active_ids.has(target.instance_id):
		return # KO replacement is not a second phaze.
	var failure := SwitchMoves.phaze_blocker(actor, target, move.id, state.substitute_rules_enabled and actor.ability_id == &"infiltrator")
	if not failure.is_empty():
		events.append(BattleEvent.new(BattleEvent.SWITCH_EFFECT_FAILED, state.turn,
			actor.instance_id, target.instance_id, move.id, 0, {"reason": failure}))
		return
	if state.battle_kind == &"wild":
		if actor.level < target.level:
			events.append(BattleEvent.new(BattleEvent.SWITCH_EFFECT_FAILED, state.turn,
				actor.instance_id, target.instance_id, move.id, 0, {"reason": "wild_level"}))
			return
		_status_effect_resolved(actor, target, move, state, events)
		_end_wild_encounter(actor, target, move, state, events, "phaze")
		return
	var side := state.side_for_creature(target.instance_id)
	var candidates := SwitchMoves.replacements(state, side.side_id)
	if candidates.is_empty():
		if move.id in SwitchMoves.STATUS_PHAZES:
			_switch_effect_failed(actor, target, move, state, events, "no_reserve")
		return
	var incoming := StringName(candidates[rng.next_index(candidates.size())])
	_status_effect_resolved(actor, target, move, state, events)
	_execute_switch(BattleAction.new(state.turn, target.instance_id, &"", &"", BattleAction.SWITCH,
		side.side_id, incoming), state, catalog, rng, events, true, move.id, &"phaze")


func _request_pivot(actor: CreatureInstance, move: MoveDefinition, state: BattleState,
	events: Array[BattleEvent]) -> void:
	var side := state.side_for_creature(actor.instance_id)
	var candidates := SwitchMoves.replacements(state, side.side_id)
	if candidates.is_empty():
		if move.id == &"parting_shot":
			_status_effect_resolved(actor, actor, move, state, events)
		elif SwitchMoves.supports_status(move):
			_switch_effect_failed(actor, actor, move, state, events, "no_reserve")
		return
	state.pending_switch = {"side_id": String(side.side_id), "actor_id": String(actor.instance_id),
		"move_id": String(move.id), "candidate_ids": candidates}
	if move.id == &"baton_pass":
		state.pending_switch["transfer"] = SwitchMoves.baton_payload(actor)
	elif move.id == &"shed_tail" and state.substitute_rules_enabled:
		state.pending_switch["transfer"] = {"volatile": {"substitute": Substitute.record(actor)}}
	_status_effect_resolved(actor, actor, move, state, events)
	state.phase = BattleState.WAITING_FOR_SWITCH
	events.append(BattleEvent.new(BattleEvent.SWITCH_REQUESTED, state.turn, actor.instance_id,
		&"", move.id, 0, state.pending_switch))


func _execute_status_switch(actor: CreatureInstance, target: CreatureInstance, move: MoveDefinition,
	state: BattleState, catalog: DefinitionCatalog, rng: SeededRandomSource,
	events: Array[BattleEvent]) -> void:
	var source := actor
	var recipient := target
	if move.id in SwitchMoves.STATUS_PHAZES or move.id == &"parting_shot":
		if target.ability_id == &"magic_bounce":
			source = target
			recipient = actor
			events.append(BattleEvent.new(BattleEvent.MOVE_REFLECTED, state.turn,
				source.instance_id, recipient.instance_id, move.id))
	if move.id == &"parting_shot":
		if recipient.ability_id == &"soundproof" or recipient.status_state.has_volatile(&"protect"):
			_switch_effect_failed(source, recipient, move, state, events, "blocked")
			return
		if not _parting_shot_stages(source, recipient, move, state, events):
			_switch_effect_failed(source, recipient, move, state, events, "no_stat_change")
			return
		_request_pivot(source, move, state, events)
	elif move.id == &"teleport" and state.battle_kind == &"wild" and state.side_for_creature(actor.instance_id).side_id == &"side_b":
		# Modern rules: the player's Teleport pivots; only the wild user's ends it.
		_status_effect_resolved(actor, actor, move, state, events)
		_end_wild_encounter(actor, actor, move, state, events, "teleport")
	else:
		_apply_switch_move(source, recipient, move, state, catalog, rng, events)


func _parting_shot_stages(actor: CreatureInstance, target: CreatureInstance, move: MoveDefinition,
	state: BattleState, events: Array[BattleEvent]) -> bool:
	var recipient := actor if target.ability_id == &"mirror_armor" else target
	var mirrored := recipient == actor
	var changed_any := false
	for stat: StringName in [StatStages.ATTACK, StatStages.SPECIAL_ATTACK]:
		var blocked := recipient.ability_id in [&"clear_body", &"white_smoke", &"full_metal_body"] \
			or (recipient.ability_id == &"hyper_cutter" and stat == StatStages.ATTACK)
		if blocked:
			continue
		var delta := 1 if recipient.ability_id == &"contrary" else (-2 if recipient.ability_id == &"simple" else -1)
		var before := recipient.stat_stages.get_stage(stat)
		var changed := recipient.stat_stages.change(stat, delta)
		if changed == 0:
			continue
		changed_any = true
		var instigator := target if mirrored else actor
		_stage_event(instigator, recipient, move, state, events, stat, before, changed)
		if changed < 0 and recipient.ability_id in [&"defiant", &"competitive"]:
			var boosted_stat := StatStages.ATTACK if recipient.ability_id == &"defiant" else StatStages.SPECIAL_ATTACK
			before = recipient.stat_stages.get_stage(boosted_stat)
			changed = recipient.stat_stages.change(boosted_stat, 2)
			_stage_event(recipient, recipient, move, state, events, boosted_stat, before, changed)
	return changed_any or mirrored


func _stage_event(actor: CreatureInstance, target: CreatureInstance, move: MoveDefinition,
	state: BattleState, events: Array[BattleEvent], stat: StringName, before: int, delta: int) -> void:
	events.append(BattleEvent.new(BattleEvent.STAT_STAGE_CHANGED, state.turn, actor.instance_id,
		target.instance_id, move.id, delta, {"stat_id": String(stat), "before": before,
		"after": target.stat_stages.get_stage(stat)}))


func _switch_effect_failed(actor: CreatureInstance, target: CreatureInstance, move: MoveDefinition,
	state: BattleState, events: Array[BattleEvent], reason: String) -> void:
	events.append(BattleEvent.new(BattleEvent.SWITCH_EFFECT_FAILED, state.turn,
		actor.instance_id, target.instance_id, move.id, 0, {"reason": reason}))


func _status_effect_resolved(actor: CreatureInstance, target: CreatureInstance, move: MoveDefinition,
	state: BattleState, events: Array[BattleEvent]) -> void:
	if SwitchMoves.supports_status(move):
		events.append(BattleEvent.new(BattleEvent.MOVE_EFFECT_RESOLVED, state.turn,
			actor.instance_id, target.instance_id, move.id))


func _end_wild_encounter(actor: CreatureInstance, leaving: CreatureInstance, move: MoveDefinition,
	state: BattleState, events: Array[BattleEvent], kind: String) -> void:
	state.phase = BattleState.FINISHED
	state.winner_id = &""
	state.end_reason = &"forced_escape"
	events.append(BattleEvent.new(BattleEvent.BATTLE_ENDED, state.turn, actor.instance_id,
		leaving.instance_id, move.id, 0, {"reason": "forced_escape", "no_rewards": true, "escape_kind": kind}))
	Transform.restore_all(state, events, "forced_escape")


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
	source_move: StringName = &"",
	cause: StringName = &"",
	transfer: Dictionary = {},
) -> void:
	var side := state.side_for_creature(action.actor_id)
	if side == null:
		return
	var outgoing := state.creature(side.active_id)
	var incoming := state.creature(action.switch_instance_id)
	if incoming == null or not state.switch_active(side.side_id, incoming.instance_id):
		return
	var restoration: Array[BattleEvent] = []
	Bindings.on_switch(state, outgoing, events)
	Transform.restore(state, outgoing, restoration, "switch")
	outgoing.stat_stages = StatStages.new()
	outgoing.status_state.volatile.clear()
	if not transfer.is_empty():
		incoming.stat_stages = StatStages.from_dict(transfer.get("stat_stages", {}))
		incoming.status_state.volatile = BattleStatusState.from_dict({"volatile": transfer.get("volatile", {})}).volatile
	var metadata := {"side_id": String(side.side_id), "forced": forced}
	if cause != &"":
		metadata["cause"] = String(cause)
	events.append(BattleEvent.new(
		BattleEvent.SWITCHED,
		state.turn,
		outgoing.instance_id,
		incoming.instance_id,
		source_move,
		0,
		metadata,
	))
	events.append_array(restoration)
	if state.substitute_rules_enabled and Substitute.hp(incoming) > 0:
		events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_TRANSFERRED, state.turn,
			outgoing.instance_id, incoming.instance_id, source_move, Substitute.hp(incoming), Substitute.record(incoming)))
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
	ability_only: bool = false,
) -> void:
	if owner == null or owner.is_knocked_out():
		return
	var context := BattleEffectContext.new(
		state, owner, target, move, catalog, _ruleset, rng, events
	)
	context.is_trigger = true
	for spec in _trigger_system.specs_for_creature(owner, trigger, _registry):
		if ability_only and spec.source_kind != &"ability": continue
		if not _trigger_system.conditions_met(spec, owner, move, target):
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
	Bindings.clear_invalid(state, events)
	for side in state.sides:
		var active := state.creature(side.active_id)
		if active == null or not active.is_knocked_out():
			continue
		if not _has_event_for_target(events, BattleEvent.KNOCKED_OUT, active.instance_id):
			events.append(BattleEvent.new(
				BattleEvent.KNOCKED_OUT, state.turn, &"", active.instance_id
			))
		Transform.restore(state, active, events, "knockout")
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
	Transform.restore_all(state, events, "battle_end")
	Bindings.clear_all(state, events)
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
