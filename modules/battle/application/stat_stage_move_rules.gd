extends RefCounted

# Live singles extension over the frozen canonical data. Direct assignments are
# distinct from ordinary boosts: swapping/resetting stages must not activate
# Contrary, Simple, Clear Body or retaliation abilities as if they were drops.
# Reference: smogon/pokemon-showdown data/moves.ts SHA256
# 43b516fdc01721f53f01de555479dd3d248e5e29d2a6f5072a7bd4a3585a5027.
const TYPES := {&"haze": &"ice", &"topsy_turvy": &"dark", &"heart_swap": &"psychic",
	&"power_swap": &"psychic", &"guard_swap": &"psychic", &"acupressure": &"normal",
	&"clear_smog": &"poison", &"spectral_thief": &"ghost"}
const STATUS_IDS: Array[StringName] = [&"haze", &"topsy_turvy", &"heart_swap", &"power_swap", &"guard_swap", &"acupressure"]


static func supports(move: MoveDefinition) -> bool:
	if move == null or not TYPES.has(move.id): return false
	var power := 50 if move.id == &"clear_smog" else (90 if move.id == &"spectral_thief" else 0)
	var target := "entire-field" if move.id == &"haze" else ("user-or-ally" if move.id == &"acupressure" else "selected-pokemon")
	var category := "special" if move.id == &"clear_smog" else ("physical" if move.id == &"spectral_thief" else "status")
	return move.power == power and move.type_id == TYPES[move.id] and move.target == target \
		and move.damage_class == category and move.priority == 0 and move.effect_specs.is_empty() \
		and move.accuracy == (100 if move.id == &"spectral_thief" else -1)


static func execution_move(move: MoveDefinition) -> MoveDefinition:
	if move.id != &"spectral_thief": return move
	var local := MoveDefinition.from_dict(move.to_dict())
	local.makes_contact = true
	return local


static func apply_status(state: BattleState, actor: CreatureInstance, target: CreatureInstance,
	move: MoveDefinition, rng: SeededRandomSource, events: Array[BattleEvent]) -> void:
	if move.id == &"haze":
		for id: StringName in state.active_ids:
			var active := state.creature(id)
			if not active.is_knocked_out(): _assign(state, actor, active, move, StatStages.new().to_dict(), "clear", events)
		return
	if move.id == &"acupressure":
		var candidates: Array[StringName] = []
		for id: StringName in StatStages.ALL:
			if actor.stat_stages.get_stage(id) < 6: candidates.append(id)
		if candidates.is_empty():
			_fail(state, actor, actor, move, "all_stages_maximized", events)
			return
		var chosen := candidates[rng.next_index(candidates.size())]
		_boost(state, actor, actor, move, chosen, 2, events)
		return
	if move.id == &"topsy_turvy":
		var source := actor
		var recipient := target
		if target.ability_id == &"magic_bounce":
			source = target
			recipient = actor
			events.append(BattleEvent.new(BattleEvent.MOVE_REFLECTED, state.turn, target.instance_id, actor.instance_id, move.id))
		if state.substitute_rules_enabled and recipient.status_state.has_volatile(&"substitute") and source.ability_id != &"infiltrator":
			events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_BLOCKED, state.turn, source.instance_id, recipient.instance_id, move.id))
			return
		var after := recipient.stat_stages.to_dict()
		var changed := false
		for id: String in after:
			if int(after[id]) != 0: changed = true
			after[id] = -int(after[id])
		if changed: _assign(state, source, recipient, move, after, "invert", events)
		else: _fail(state, source, recipient, move, "no_modified_stages", events)
		return
	var ids: Array[StringName] = StatStages.ALL.duplicate()
	if move.id == &"power_swap": ids.assign([StatStages.ATTACK, StatStages.SPECIAL_ATTACK])
	elif move.id == &"guard_swap": ids.assign([StatStages.DEFENSE, StatStages.SPECIAL_DEFENSE])
	var own := actor.stat_stages.to_dict()
	var other := target.stat_stages.to_dict()
	for id: StringName in ids:
		own[String(id)] = target.stat_stages.get_stage(id)
		other[String(id)] = actor.stat_stages.get_stage(id)
	_assign(state, actor, actor, move, own, "swap", events)
	_assign(state, actor, target, move, other, "swap", events)


static func steal(context: BattleEffectContext) -> void:
	var before := context.target.stat_stages.to_dict()
	var cleared := before.duplicate(true)
	var has_positive := false
	for id: StringName in StatStages.ALL:
		var amount := int(before[String(id)])
		if amount <= 0: continue
		has_positive = true
		_boost(context.state, context.actor, context.actor, context.move, id, amount, context.events)
		cleared[String(id)] = 0
	if has_positive: _assign(context.state, context.actor, context.target, context.move, cleared, "steal", context.events)


static func clear_smog(context: BattleEffectContext) -> void:
	if context.last_damage <= 0 or context.last_hit_substitute: return
	_assign(context.state, context.actor, context.target, context.move, StatStages.new().to_dict(), "clear", context.events)


static func _boost(state: BattleState, actor: CreatureInstance, recipient: CreatureInstance,
	move: MoveDefinition, id: StringName, amount: int, events: Array[BattleEvent]) -> void:
	var before := recipient.stat_stages.get_stage(id)
	if recipient.ability_id == &"contrary": amount = -amount
	elif recipient.ability_id == &"simple": amount *= 2
	var changed := recipient.stat_stages.change(id, amount)
	events.append(BattleEvent.new(BattleEvent.STAT_STAGE_CHANGED, state.turn, actor.instance_id, recipient.instance_id, move.id, changed,
		{"stat_id": String(id), "before": before, "after": recipient.stat_stages.get_stage(id)}))


static func _assign(state: BattleState, actor: CreatureInstance, recipient: CreatureInstance,
	move: MoveDefinition, after: Dictionary, operation: String, events: Array[BattleEvent]) -> void:
	var before := recipient.stat_stages.to_dict()
	recipient.stat_stages = StatStages.from_dict(after)
	var count := 0
	for id: String in before:
		if before[id] != after[id]: count += 1
	events.append(BattleEvent.new(BattleEvent.STAT_STAGES_REASSIGNED, state.turn,
		actor.instance_id, recipient.instance_id, move.id, count,
		{"operation": operation, "before": before, "after": recipient.stat_stages.to_dict()}))


static func _fail(state: BattleState, actor: CreatureInstance, target: CreatureInstance,
	move: MoveDefinition, reason: String, events: Array[BattleEvent]) -> void:
	events.append(BattleEvent.new(BattleEvent.MOVE_EFFECT_FAILED, state.turn, actor.instance_id, target.instance_id, move.id, 0, {"reason": reason}))
