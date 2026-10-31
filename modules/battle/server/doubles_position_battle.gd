extends RefCounted

# Narrow, explicit four-participant adapter. Reuses the existing battle entities,
# status/damage/effect engines; never sends a four-action turn to the singles API.
# No reserves, abilities/items, spread moves, capture, rewards or trainer AI yet.
const FORMAT := "doubles_position_pilot_v1"
const SCHEMA := 1
const DAMAGE_CONTRACTS := {
	&"tackle": [40, &"normal", "physical", 0],
	&"water_gun": [40, &"water", "special", 0],
	&"quick_attack": [40, &"normal", "physical", 1],
	&"extreme_speed": [80, &"normal", "physical", 2]}
var state: BattleState
var slots: Dictionary = {}
var _stall: Dictionary = {}
var _fainted: Array[String] = []
var _catalog: DefinitionCatalog
var _rng: SeededRandomSource
var _rules := BattleRuleset.new()
var _effects := BattleEffectExecutor.new()
var _registry := BattleEffectRegistry.new()
var _statuses := StatusSystem.new()
var _resolver := TurnResolver.new()


func _init(p_state: BattleState, p_catalog: DefinitionCatalog, p_slots: Dictionary = {}) -> void:
	state = p_state
	_catalog = p_catalog
	_rng = SeededRandomSource.new(state.rng_state)
	slots = p_slots.duplicate(true)
	if slots.is_empty():
		for side: BattleSide in state.sides:
			var ids: Array[String] = []
			for id: StringName in side.party_ids: ids.append(String(id))
			slots[String(side.side_id)] = ids
	if configuration_error().is_empty():
		_sync_slots()
		for id: StringName in state.participant_ids: state.creature(id).initialize_move_pp(_catalog)


static func supports_ally_switch(move: MoveDefinition) -> bool:
	return move != null and move.id == &"ally_switch" and move.power == 0 and move.type_id == &"psychic" \
		and move.damage_class == "status" and move.priority == 2 and move.accuracy == -1 \
		and move.target == "user" and move.effect_specs.is_empty()


func supports_damage(move: MoveDefinition) -> bool:
	if move == null or not DAMAGE_CONTRACTS.has(move.id): return false
	var contract: Array = DAMAGE_CONTRACTS[move.id]
	var effects: Array[BattleEffectSpec] = _registry.effects_for_move(move)
	if effects.size() != 1 or effects[0].kind != BattleEffectSpec.DAMAGE or effects[0].target != BattleEffectSpec.OPPONENT or not effects[0].children.is_empty(): return false
	return move.power == contract[0] and move.type_id == contract[1] and move.damage_class == contract[2] \
		and move.priority == contract[3] and move.accuracy == 100 and move.target == "selected-pokemon"


func configuration_error() -> String:
	if state == null or _catalog == null or state.sides.size() != 2 or slots.size() != 2 or state.participant_ids.size() != 4: return "requires_two_active_per_side"
	if state.switch_move_rules_enabled or state.weather_rules_enabled or state.substitute_rules_enabled or state.transform_rules_enabled: return "other_pilots_not_supported"
	if not state.side_item_inventories.is_empty(): return "items_not_supported"
	var seen := {}
	for side: BattleSide in state.sides:
		var row: Variant = slots.get(String(side.side_id), [])
		if side.party_ids.size() != 2 or not row is Array or row.size() != 2: return "requires_two_active_per_side"
		for value: Variant in row:
			if not value is String and not value is StringName: return "invalid_position_layout"
			var id := StringName(value)
			var creature := state.creature(id)
			if seen.has(id) or not side.owns(id) or creature == null: return "invalid_position_layout"
			seen[id] = true
			if _catalog.species(creature.species_id) == null: return "unknown_species"
			if creature.ability_id != &"" or creature.held_item_id != &"": return "ability_items_not_supported"
			if not creature.battle_transform_original.is_empty(): return "transformation_not_supported"
			for marker: Variant in creature.status_state.volatile:
				if String(marker) != "flinch": return "volatile_not_supported"
	return ""


func position_of(id: StringName) -> Dictionary:
	for side: String in slots:
		var position: int = slots[side].find(String(id))
		if position >= 0: return {"side_id": side, "slot": position}
	return {}


func at_position(side: String, position: int) -> CreatureInstance:
	if not slots.has(side) or position < 0 or position >= slots[side].size(): return null
	return state.creature(StringName(slots[side][position]))


func living_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for side: BattleSide in state.sides:
		for id: String in slots[String(side.side_id)]:
			if not state.creature(StringName(id)).is_knocked_out(): result.append(StringName(id))
	return result


func _sync_slots() -> void:
	state.active_ids.clear()
	for side: BattleSide in state.sides:
		side.active_id = StringName(slots[String(side.side_id)][0])
		for id: String in slots[String(side.side_id)]: state.active_ids.append(StringName(id))


func snapshot() -> Dictionary:
	return BattleState._canonical_switch_snapshot({"schema_version": SCHEMA, "format": FORMAT,
		"battle": state.to_dict(), "slots": slots.duplicate(true), "ally_switch_stall": _stall.duplicate(true),
		"fainted_ids": _fainted.duplicate()})


static func from_snapshot(data: Dictionary, catalog: DefinitionCatalog):
	if data.get("schema_version") != SCHEMA or data.get("format") != FORMAT or not data.get("battle") is Dictionary or not data.get("slots") is Dictionary: return null
	var restored = load("res://modules/battle/server/doubles_position_battle.gd").new(BattleState.from_dict(data.battle), catalog, data.slots)
	if not restored.configuration_error().is_empty(): return null
	if not data.get("ally_switch_stall", {}) is Dictionary or not data.get("fainted_ids", []) is Array: return null
	for id: Variant in data.get("ally_switch_stall", {}):
		var entry: Variant = data.ally_switch_stall[id]
		if restored.state.creature(StringName(id)) == null or not entry is Dictionary: return null
		var counter := int(entry.get("counter", 0))
		var last_turn := int(entry.get("last_turn", -1))
		if counter not in [3, 9, 27, 81, 243, 729] or last_turn < 1 or last_turn > restored.state.turn: return null
		restored._stall[String(id)] = {"counter": counter, "last_turn": last_turn}
	for id: Variant in data.get("fainted_ids", []):
		var creature: CreatureInstance = restored.state.creature(StringName(id))
		if creature == null or not creature.is_knocked_out() or String(id) in restored._fainted: return null
		restored._fainted.append(String(id))
	if restored.snapshot() != BattleState._canonical_switch_snapshot(data): return null
	return restored


func _validate(actions: Array[BattleAction]) -> String:
	var reason := configuration_error()
	if not reason.is_empty(): return reason
	if state.phase != BattleState.WAITING_FOR_ACTIONS: return "battle_finished"
	if actions.size() != living_ids().size(): return "wrong_action_count"
	var seen := {}
	for action: BattleAction in actions:
		if action == null: return "missing_action"
		if action.turn != state.turn + 1: return "wrong_turn"
		if action.actor_id in seen: return "duplicate_actor"
		if action.actor_id not in living_ids(): return "invalid_actor"
		var side := state.side_for_creature(action.actor_id)
		if side.side_id != action.side_id: return "wrong_participant"
		if action.action_type != BattleAction.MOVE: return "action_not_supported"
		var move := _catalog.move(action.move_id)
		if not supports_ally_switch(move) and not supports_damage(move): return "move_not_supported"
		var slot := state.creature(action.actor_id).move_slot(action.move_id)
		if slot == null or slot.current_pp <= 0: return "move_unavailable"
		var target := state.creature(action.target_id)
		if supports_ally_switch(move):
			if action.target_id != action.actor_id: return "invalid_self_target"
		elif target == null or action.target_id not in living_ids() or side.owns(action.target_id): return "invalid_target"
		seen[action.actor_id] = true
	return ""


func submit_turn(actions: Array[BattleAction]) -> Array[BattleEvent]:
	var reason := _validate(actions)
	if not reason.is_empty(): return [BattleEvent.new(BattleEvent.ACTION_REJECTED, state.turn, &"", &"", &"", 0, {"reason": reason})]
	var commands: Array[BattleAction] = []
	var targets := {}
	for action: BattleAction in actions:
		commands.append(BattleAction.from_dict(action.to_dict()))
		targets[action.actor_id] = position_of(action.target_id).duplicate(true)
	var ordered := _resolver.resolve_multi_order(commands, state, _catalog, _rng, _rules)
	state.turn += 1
	state.battle_started = true
	var events: Array[BattleEvent] = []
	for action: BattleAction in ordered:
		if state.phase == BattleState.FINISHED: break
		_execute(action, targets[action.actor_id], events)
		_knockouts(events)
	if state.phase != BattleState.FINISHED:
		events.append_array(_statuses.process_end_turn(state, _catalog, _rules))
		_knockouts(events)
		if state.phase != BattleState.FINISHED: events.append(BattleEvent.new(BattleEvent.TURN_ENDED, state.turn))
	for id: String in _stall.keys():
		if int(_stall[id].last_turn) < state.turn: _stall.erase(id)
	state.rng_state = _rng.state()
	return events


func _execute(action: BattleAction, bound: Dictionary, events: Array[BattleEvent]) -> void:
	var actor := state.creature(action.actor_id)
	if actor.is_knocked_out() or not _statuses.can_act(state, actor, _rng, events, _rules): return
	var move := _catalog.move(action.move_id)
	var target := actor if supports_ally_switch(move) else at_position(String(bound.side_id), int(bound.slot))
	var redirect_reason := "position_changed"
	if target != null and target.is_knocked_out():
		redirect_reason = "fainted_position"
		target = null
		for candidate: String in slots[String(bound.side_id)]:
			if not state.creature(StringName(candidate)).is_knocked_out(): target = state.creature(StringName(candidate))
	if target == null: return
	actor.move_slot(move.id).consume()
	events.append(BattleEvent.new(BattleEvent.ACTION_USED, state.turn, actor.instance_id, target.instance_id, move.id,
		0, {"selected_target_id": String(action.target_id), "target_position": bound.duplicate(true)}))
	var slot := actor.move_slot(move.id)
	events.append(BattleEvent.new(BattleEvent.PP_CHANGED, state.turn, actor.instance_id, actor.instance_id,
		move.id, -1, {"current_pp": slot.current_pp, "max_pp": slot.max_pp}))
	if supports_ally_switch(move):
		_swap(actor, events)
		return
	if target.instance_id != action.target_id:
		events.append(BattleEvent.new(BattleEvent.POSITION_TARGET_RESOLVED, state.turn, actor.instance_id, target.instance_id,
			move.id, 0, {"reason": redirect_reason, "selected_target_id": String(action.target_id), "target_position": bound.duplicate(true)}))
	var threshold := _rules.accuracy_threshold_basis_points(move.accuracy, actor.stat_stages.get_stage(StatStages.ACCURACY), target.stat_stages.get_stage(StatStages.EVASION))
	if not _rng.roll_basis_points(threshold):
		events.append(BattleEvent.new(BattleEvent.MOVE_MISSED, state.turn, actor.instance_id, target.instance_id, move.id))
		return
	var context := BattleEffectContext.new(state, actor, target, move, _catalog, _rules, _rng, events)
	_effects.execute_all(_registry.effects_for_move(move), context, _registry)


func _swap(actor: CreatureInstance, events: Array[BattleEvent]) -> void:
	# Gen 9: consecutive attempts use 1/3, 1/9 ... capped at 1/729. A failed
	# repeat removes the counter; skipping an attempt for a turn lets it expire.
	var key := String(actor.instance_id)
	var entry: Dictionary = _stall.get(key, {})
	var counter := int(entry.get("counter", 1)) if int(entry.get("last_turn", -2)) == state.turn - 1 else 1
	if counter > 1 and _rng.next_index(counter) != 0:
		_stall.erase(key)
		events.append(BattleEvent.new(BattleEvent.ALLY_SWITCH_FAILED, state.turn, actor.instance_id, actor.instance_id,
			&"ally_switch", 0, {"reason": "consecutive_attempt", "denominator": counter}))
		return
	_stall[key] = {"counter": mini(counter * 3, 729), "last_turn": state.turn}
	var position := position_of(actor.instance_id)
	var ally := at_position(String(position.side_id), 1 - int(position.slot))
	if ally == null or ally.is_knocked_out():
		events.append(BattleEvent.new(BattleEvent.ALLY_SWITCH_FAILED, state.turn, actor.instance_id, actor.instance_id,
			&"ally_switch", 0, {"reason": "no_living_ally"}))
		return
	var before: Array = slots[String(position.side_id)].duplicate()
	slots[String(position.side_id)].reverse()
	_sync_slots()
	events.append(BattleEvent.new(BattleEvent.ALLY_POSITIONS_SWAPPED, state.turn, actor.instance_id, ally.instance_id,
		&"ally_switch", 0, {"side_id": position.side_id, "before": before, "after": slots[String(position.side_id)].duplicate()}))


func _knockouts(events: Array[BattleEvent]) -> void:
	for id: StringName in state.participant_ids:
		if state.creature(id).is_knocked_out() and String(id) not in _fainted:
			_fainted.append(String(id))
			events.append(BattleEvent.new(BattleEvent.KNOCKED_OUT, state.turn, &"", id))
	var living_sides: Array[BattleSide] = []
	for side: BattleSide in state.sides:
		for id: String in slots[String(side.side_id)]:
			if not state.creature(StringName(id)).is_knocked_out():
				living_sides.append(side)
				break
	if living_sides.size() == 2: return
	state.phase = BattleState.FINISHED
	state.winner_id = &""
	if living_sides.size() == 1:
		for id: String in slots[String(living_sides[0].side_id)]:
			if not state.creature(StringName(id)).is_knocked_out():
				state.winner_id = StringName(id)
				break
	events.append(BattleEvent.new(BattleEvent.BATTLE_ENDED, state.turn, state.winner_id, &"", &"", 0,
		{"reason": "all_active_fainted", "format": FORMAT}))
