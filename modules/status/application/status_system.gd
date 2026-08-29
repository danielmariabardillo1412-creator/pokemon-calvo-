class_name StatusSystem
extends RefCounted

const BURN := &"burn"
const POISON := &"poison"
const BADLY_POISONED := &"badly_poisoned"
const PARALYSIS := &"paralysis"
const SLEEP := &"sleep"
const FREEZE := &"freeze"
const FLINCH := &"flinch"
const CONFUSION := &"confusion"
const PERSISTENT: Array[StringName] = [BURN, POISON, BADLY_POISONED, PARALYSIS, SLEEP, FREEZE]


func try_apply(
	state: BattleState,
	source: CreatureInstance,
	target: CreatureInstance,
	status_id: StringName,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
) -> BattleEffectResult:
	if status_id == FLINCH or status_id == CONFUSION:
		if target.status_state.has_volatile(status_id):
			_emit_failed(state, source, target, status_id, &"already_present", events)
			return BattleEffectResult.new(false, 0, &"already_present")
		target.status_state.add_volatile(status_id)
		_emit_applied(state, source, target, status_id, true, events)
		return BattleEffectResult.new(true)
	if not PERSISTENT.has(status_id):
		_emit_failed(state, source, target, status_id, &"unsupported_status", events)
		return BattleEffectResult.new(false, 0, &"unsupported_status")
	_sync_legacy_status(target)
	if target.status_state.persistent_id != &"":
		_emit_failed(state, source, target, status_id, &"persistent_status_present", events)
		return BattleEffectResult.new(false, 0, &"persistent_status_present")
	var immunity := _immunity_reason(target, status_id, catalog)
	if immunity != &"":
		_emit_failed(state, source, target, status_id, immunity, events)
		return BattleEffectResult.new(false, 0, immunity)
	target.status_state.persistent_id = status_id
	if status_id == SLEEP:
		target.status_state.turns_remaining = 1 + rng.next_index(3)
	if status_id == BADLY_POISONED:
		target.status_state.toxic_counter = 0
	target.status_ids.clear()
	target.status_ids.append(status_id)
	_emit_applied(state, source, target, status_id, false, events)
	return BattleEffectResult.new(true)


func cure_persistent(
	state: BattleState,
	source: CreatureInstance,
	target: CreatureInstance,
	events: Array[BattleEvent],
) -> BattleEffectResult:
	_sync_legacy_status(target)
	if target.status_state.persistent_id == &"":
		return BattleEffectResult.new(false, 0, &"no_status")
	var removed := target.status_state.clear_persistent()
	target.status_ids.clear()
	events.append(BattleEvent.new(
		BattleEvent.STATUS_CURED,
		state.turn,
		source.instance_id,
		target.instance_id,
		&"",
		0,
		{"status_id": String(removed)},
	))
	return BattleEffectResult.new(true)


func can_act(
	state: BattleState,
	creature: CreatureInstance,
	rng: SeededRandomSource,
	events: Array[BattleEvent],
	ruleset: BattleRuleset = null,
) -> bool:
	var active_ruleset := ruleset if ruleset != null else BattleRuleset.new()
	_sync_legacy_status(creature)
	if creature.status_state.has_volatile(FLINCH):
		creature.status_state.remove_volatile(FLINCH)
		_emit_prevented(state, creature, FLINCH, events)
		return false
	match creature.status_state.persistent_id:
		SLEEP:
			if creature.status_state.turns_remaining > 0:
				creature.status_state.turns_remaining -= 1
				_emit_prevented(state, creature, SLEEP, events)
				return false
			cure_persistent(state, creature, creature, events)
		PARALYSIS:
			if rng.roll_basis_points(active_ruleset.paralysis_skip_chance_basis_points):
				_emit_prevented(state, creature, PARALYSIS, events)
				return false
		FREEZE:
			# calvo_v1: 20% deterministic thaw before the action.
			if rng.roll_basis_points(2000):
				cure_persistent(state, creature, creature, events)
			else:
				_emit_prevented(state, creature, FREEZE, events)
				return false
	return true


func process_end_turn(
	state: BattleState,
	catalog: DefinitionCatalog,
	ruleset: BattleRuleset = null,
) -> Array[BattleEvent]:
	var active_ruleset := ruleset if ruleset != null else BattleRuleset.new()
	var events: Array[BattleEvent] = []
	for creature_id in state.active_ids:
		var creature := state.creature(creature_id)
		if creature.is_knocked_out():
			continue
		_sync_legacy_status(creature)
		var status_id := creature.status_state.persistent_id
		var damage := 0
		match status_id:
			POISON:
				damage = maxi(1, creature.stats.max_hp / active_ruleset.poison_max_hp_divisor)
			BADLY_POISONED:
				creature.status_state.toxic_counter += 1
				damage = maxi(1, (
					creature.stats.max_hp * creature.status_state.toxic_counter
				) / active_ruleset.badly_poisoned_max_hp_divisor)
			BURN:
				damage = maxi(1, creature.stats.max_hp / active_ruleset.burn_max_hp_divisor)
		if damage <= 0:
			continue
		var applied := creature.apply_damage(damage)
		events.append(BattleEvent.new(
			BattleEvent.STATUS_DAMAGE,
			state.turn,
			creature.instance_id,
			creature.instance_id,
			&"",
			applied,
			{"status_id": String(status_id)},
		))
		if creature.is_knocked_out():
			events.append(BattleEvent.new(
				BattleEvent.KNOCKED_OUT,
				state.turn,
				&"",
				creature.instance_id,
				&"",
				0,
				{"cause": "status", "status_id": String(status_id)},
			))
			return events
	return events


func _sync_legacy_status(creature: CreatureInstance) -> void:
	if creature.status_state.persistent_id == &"" and not creature.status_ids.is_empty():
		creature.status_state.persistent_id = creature.status_ids[0]


func _immunity_reason(
	target: CreatureInstance,
	status_id: StringName,
	catalog: DefinitionCatalog,
) -> StringName:
	var species := catalog.species(target.species_id)
	if species == null:
		return &""
	if status_id == BURN and species.has_type(&"fire"):
		return &"type_immunity"
	if (status_id == POISON or status_id == BADLY_POISONED) and (
		species.has_type(&"poison") or species.has_type(&"steel")
	):
		return &"type_immunity"
	if status_id == PARALYSIS and species.has_type(&"electric"):
		return &"type_immunity"
	return &""


func _emit_applied(
	state: BattleState,
	source: CreatureInstance,
	target: CreatureInstance,
	status_id: StringName,
	volatile_status: bool,
	events: Array[BattleEvent],
) -> void:
	events.append(BattleEvent.new(
		BattleEvent.STATUS_APPLIED,
		state.turn,
		source.instance_id,
		target.instance_id,
		&"",
		0,
		{"status_id": String(status_id), "volatile": volatile_status},
	))


func _emit_failed(
	state: BattleState,
	source: CreatureInstance,
	target: CreatureInstance,
	status_id: StringName,
	reason: StringName,
	events: Array[BattleEvent],
) -> void:
	events.append(BattleEvent.new(
		BattleEvent.STATUS_FAILED,
		state.turn,
		source.instance_id,
		target.instance_id,
		&"",
		0,
		{"status_id": String(status_id), "reason": String(reason)},
	))


func _emit_prevented(
	state: BattleState,
	creature: CreatureInstance,
	status_id: StringName,
	events: Array[BattleEvent],
) -> void:
	events.append(BattleEvent.new(
		BattleEvent.ACTION_PREVENTED,
		state.turn,
		creature.instance_id,
		creature.instance_id,
		&"",
		0,
		{"status_id": String(status_id)},
	))

