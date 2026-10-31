extends RefCounted

# Local singles extension; canonical datasets remain frozen. Rules checked against
# @pkmn/sim 0.10.11 data/moves (Showdown). No external engine code is imported.
# type, PP, canonical target; compound canonical effects are checked below.
const CONTRACTS := {
	&"aromatherapy": [&"grass", 5, "user-and-allies"],
	&"heal_bell": [&"normal", 5, "user-and-allies"],
	&"refresh": [&"normal", 20, "user"],
	&"life_dew": [&"water", 10, "user-and-allies"],
	&"jungle_healing": [&"grass", 10, "user-and-allies"],
	&"lunar_blessing": [&"psychic", 5, "all-allies"],
	&"purify": [&"poison", 20, "selected-pokemon"],
	&"rest": [&"psychic", 5, "user"],
}
const HEALING: Array[StringName] = [&"life_dew", &"jungle_healing", &"lunar_blessing", &"purify", &"rest"]


static func supports(move: MoveDefinition) -> bool:
	if move == null or not CONTRACTS.has(move.id): return false
	var row: Array = CONTRACTS[move.id]
	if move.type_id != row[0] or move.pp != row[1] or move.target != row[2] \
		or move.accuracy != -1 or move.power != 0 or move.priority != 0 \
		or move.damage_class != "status" or move.makes_contact or move.crit_rate_bp != 0: return false
	var expected: Array[BattleEffectSpec] = []
	if move.id in [&"life_dew", &"jungle_healing"]:
		expected.append(BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.SELF, 0, 2500))
	if move.id == &"jungle_healing": expected.append(BattleEffectSpec.new(BattleEffectSpec.CURE_STATUS, BattleEffectSpec.SELF))
	if move.effect_specs.size() != expected.size(): return false
	for i in expected.size():
		if move.effect_specs[i].to_dict() != expected[i].to_dict(): return false
	return true


static func apply(state: BattleState, actor: CreatureInstance, target: CreatureInstance,
	move: MoveDefinition, catalog: DefinitionCatalog, events: Array[BattleEvent]) -> void:
	if move.id in HEALING and actor.status_state.has_volatile(&"heal_block"):
		_fail(state, actor, move, events, "heal_block")
		return
	var changed := false
	match move.id:
		&"aromatherapy", &"heal_bell":
			var side := state.side_for_creature(actor.instance_id)
			for id: StringName in side.party_ids:
				var ally := state.creature(id)
				if ally.is_knocked_out(): continue
				# Modern singles: reserve abilities are inactive; the user's own
				# Soundproof/Sap Sipper/Good as Gold does not stop its party cure.
				changed = _cure(state, actor, ally, move, events) or changed
		&"refresh":
			if _status(actor) in [&"burn", &"poison", &"badly_poisoned", &"paralysis"]:
				changed = _cure(state, actor, actor, move, events)
		&"life_dew", &"jungle_healing", &"lunar_blessing":
			# Singles: only the active user is on the field. Reserves are not allies
			# targeted by these moves, unlike the two party-wide cures above.
			# Life Dew uses the generic heal ratio (halves up); Jungle Healing
			# and Lunar Blessing use the native modifier (halves down).
			var rounding := 2 if move.id == &"life_dew" else 1
			changed = _heal(state, actor, actor, move, (actor.stats.max_hp + rounding) / 4, events)
			if move.id != &"life_dew": changed = _cure(state, actor, actor, move, events) or changed
		&"purify":
			var source := actor
			var recipient := target
			if target.ability_id == &"magic_bounce":
				source = target
				recipient = actor
				events.append(BattleEvent.new(BattleEvent.MOVE_REFLECTED, state.turn, target.instance_id, actor.instance_id, move.id))
			if recipient.ability_id == &"good_as_gold" or recipient.status_state.has_volatile(&"protect"):
				_fail(state, source, move, events, "target_protected")
				return
			if state.substitute_rules_enabled and recipient.status_state.has_volatile(&"substitute") and source.ability_id != &"infiltrator":
				events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_BLOCKED, state.turn, source.instance_id, recipient.instance_id, move.id))
				return
			changed = _cure(state, source, recipient, move, events)
			if changed: _heal(state, source, source, move, (source.stats.max_hp + 1) / 2, events)
		&"rest":
			var blocked := actor.ability_id in [&"insomnia", &"vital_spirit", &"comatose", &"sweet_veil", &"purifying_salt"]
			if actor.ability_id == &"leaf_guard" and preload("res://modules/battle/application/weather_rules.gd").effective(state) == &"sun": blocked = true
			if blocked or _status(actor) == &"sleep" or actor.current_hp == actor.stats.max_hp:
				_fail(state, actor, move, events, "rest_unavailable")
				return
			_cure(state, actor, actor, move, events)
			actor.status_state.persistent_id = &"sleep"
			actor.status_state.turns_remaining = 2
			actor.status_state.rest_sleep = true
			actor.status_ids.assign([&"sleep"])
			events.append(BattleEvent.new(BattleEvent.STATUS_APPLIED, state.turn, actor.instance_id, actor.instance_id, move.id, 0, {"status_id": "sleep", "rest": true}))
			changed = _heal(state, actor, actor, move, actor.stats.max_hp, events)
	if not changed: _fail(state, actor, move, events, "no_effect")


static func _status(creature: CreatureInstance) -> StringName:
	if creature.status_state.persistent_id != &"": return creature.status_state.persistent_id
	return creature.status_ids[0] if not creature.status_ids.is_empty() else &""


static func _cure(state: BattleState, source: CreatureInstance, target: CreatureInstance,
	move: MoveDefinition, events: Array[BattleEvent]) -> bool:
	var status := _status(target)
	if status == &"" or target.is_knocked_out(): return false
	target.status_state.clear_persistent()
	target.status_ids.clear()
	events.append(BattleEvent.new(BattleEvent.STATUS_CURED, state.turn, source.instance_id, target.instance_id, move.id, 0, {"status_id": String(status)}))
	return true


static func _heal(state: BattleState, source: CreatureInstance, target: CreatureInstance,
	move: MoveDefinition, requested: int, events: Array[BattleEvent]) -> bool:
	if target.is_knocked_out(): return false
	var restored := target.recover_hp(requested)
	if restored > 0:
		events.append(BattleEvent.new(BattleEvent.HP_RECOVERED, state.turn, source.instance_id, target.instance_id, move.id, restored))
	return restored > 0


static func _fail(state: BattleState, actor: CreatureInstance, move: MoveDefinition,
	events: Array[BattleEvent], reason: String) -> void:
	events.append(BattleEvent.new(BattleEvent.MOVE_EFFECT_FAILED, state.turn, actor.instance_id, actor.instance_id, move.id, 0, {"reason": reason}))
