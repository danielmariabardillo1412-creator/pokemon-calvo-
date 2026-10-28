extends RefCounted

# Pinned reference @pkmn/sim@0.10.11: partiallytrapped condition. Ordinary
# binding only; G-Max trapping/Dive and general suppression are separate work.
const KEY := &"partial_trap"
const CONTRACTS := {
	&"bind": [15, 85, &"normal", "physical", 20], &"wrap": [15, 90, &"normal", "physical", 20],
	&"fire_spin": [35, 85, &"fire", "special", 15], &"whirlpool": [35, 85, &"water", "special", 15],
	&"clamp": [35, 85, &"water", "physical", 15], &"sand_tomb": [35, 85, &"ground", "physical", 15],
	&"magma_storm": [100, 75, &"fire", "special", 5], &"infestation": [20, 100, &"bug", "special", 20],
	&"snap_trap": [35, 100, &"grass", "physical", 15], &"thunder_cage": [80, 90, &"electric", "special", 15],
}


static func supports(move: MoveDefinition) -> bool:
	if move == null or not CONTRACTS.has(move.id): return false
	var row: Array = CONTRACTS[move.id]
	return move.power == row[0] and move.accuracy == row[1] and move.type_id == row[2] \
		and move.damage_class == row[3] and move.pp == row[4] and move.priority == 0 \
		and move.target == "selected-pokemon" and move.crit_rate_bp == 0 \
		and not move.makes_contact and move.effect_specs.is_empty()


static func execution_move(move: MoveDefinition) -> MoveDefinition:
	var local := MoveDefinition.from_dict(move.to_dict())
	local.makes_contact = move.id in [&"bind", &"wrap", &"clamp", &"infestation", &"snap_trap"]
	return local


static func record(creature: CreatureInstance) -> Dictionary:
	return creature.status_state.volatile.get(KEY, {}).duplicate(true)


static func after_damage(context: BattleEffectContext) -> void:
	if context.body_damage <= 0 or context.last_hit_substitute or context.target.is_knocked_out() \
		or context.actor.is_knocked_out() or context.target.status_state.has_volatile(KEY): return
	var source := context.actor
	var duration := 8 if _item(source, &"grip_claw") else 5 + context.rng.next_index(2)
	context.target.status_state.add_volatile(KEY, {"source_id": String(source.instance_id), "move_id": String(context.move.id),
		"duration": duration, "divisor": 6 if _item(source, &"binding_band") else 8, "start_turn": context.state.turn})
	_event(context.state, context.target, context.events, "start", record(context.target))


static func switch_blocked(state: BattleState, creature: CreatureInstance, catalog: DefinitionCatalog) -> bool:
	if not state.live_moves_enabled or not creature.status_state.has_volatile(KEY): return false
	if catalog.species(creature.species_id).has_type(&"ghost") or _item(creature, &"shed_shell"): return false
	return _valid_source(state, record(creature))


static func end_turn(state: BattleState, catalog: DefinitionCatalog, events: Array[BattleEvent], eligible: Array[StringName]) -> void:
	if not state.live_moves_enabled: return
	clear_invalid(state, events)
	for id: StringName in state.active_ids.duplicate():
		if not eligible.is_empty() and id not in eligible: continue
		var target := state.creature(id)
		if target.is_knocked_out() or not target.status_state.has_volatile(KEY): continue
		var data := record(target)
		data.duration = int(data.get("duration", 1)) - 1
		if data.duration <= 0:
			_end(state, target, events)
			continue
		target.status_state.add_volatile(KEY, data)
		if target.ability_id == &"magic_guard": continue
		var applied := target.apply_damage(maxi(1, target.stats.max_hp / int(data.divisor)))
		if applied > 0:
			events.append(BattleEvent.new(BattleEvent.STATUS_DAMAGE, state.turn, target.instance_id,
				target.instance_id, StringName(data.move_id), applied, {"status_id": "binding", "binding": true}))


static func clear_invalid(state: BattleState, events: Array[BattleEvent]) -> void:
	if not state.live_moves_enabled: return
	for id: StringName in state.participant_ids:
		var creature := state.creature(id)
		if creature.status_state.has_volatile(KEY) and (creature.is_knocked_out() or not _valid_source(state, record(creature))):
			_end(state, creature, events)


static func on_switch(state: BattleState, outgoing: CreatureInstance, events: Array[BattleEvent]) -> void:
	if not state.live_moves_enabled: return
	for id: StringName in state.participant_ids:
		var creature := state.creature(id)
		if creature.status_state.has_volatile(KEY) and (creature == outgoing or record(creature).get("source_id") == String(outgoing.instance_id)):
			_end(state, creature, events)


static func clear_all(state: BattleState, events: Array[BattleEvent]) -> void:
	if not state.live_moves_enabled: return
	for id: StringName in state.participant_ids:
		var creature := state.creature(id)
		if creature.status_state.has_volatile(KEY): _end(state, creature, events)


static func public_estimate(state: BattleState, creature: CreatureInstance) -> Dictionary:
	if not state.live_moves_enabled or not creature.status_state.has_volatile(KEY): return {}
	var data := record(creature)
	# Source/move/start are announced facts. Never expose hidden duration/item.
	return {"source_id": data.get("source_id", ""), "move_id": data.get("move_id", ""),
		"start_turn": int(data.get("start_turn", state.turn)), "divisor": 8,
		"duration": maxi(1, 4 - (state.turn - int(data.get("start_turn", state.turn))))}


static func restore_estimates(state: BattleState, views: Dictionary) -> void:
	for id: String in views:
		var target := state.creature(StringName(id))
		if target == null: continue
		var data: Dictionary = views[id].duplicate(true)
		var source := state.creature(StringName(data.get("source_id", "")))
		if source != null:
			if _item(source, &"grip_claw"): data.duration = maxi(1, 7 - (state.turn - int(data.start_turn)))
			if _item(source, &"binding_band"): data.divisor = 6
		target.status_state.add_volatile(KEY, data)


static func _valid_source(state: BattleState, data: Dictionary) -> bool:
	if int(data.get("duration", 0)) not in range(1, 9) or int(data.get("divisor", 0)) not in [6, 8] or not CONTRACTS.has(StringName(data.get("move_id", ""))): return false
	var source := state.creature(StringName(data.get("source_id", "")))
	return source != null and not source.is_knocked_out() and source.instance_id in state.active_ids


static func _item(creature: CreatureInstance, id: StringName) -> bool:
	return creature.held_item_id == id and not creature.held_item_consumed


static func _end(state: BattleState, creature: CreatureInstance, events: Array[BattleEvent]) -> void:
	var data := record(creature)
	creature.status_state.remove_volatile(KEY)
	_event(state, creature, events, "end", data)


static func _event(state: BattleState, target: CreatureInstance, events: Array[BattleEvent], operation: String, data: Dictionary) -> void:
	events.append(BattleEvent.new(BattleEvent.MOVE_EFFECT_RESOLVED, state.turn,
		StringName(data.get("source_id", "")), target.instance_id, StringName(data.get("move_id", "")), 0, {"binding_op": operation}))
