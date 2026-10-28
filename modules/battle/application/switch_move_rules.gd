extends RefCounted

# Opt-in singles mechanics pilot. Never rewrite frozen MoveDefinitions to enable it.
const PIVOTS: Array[StringName] = [&"u_turn", &"volt_switch", &"flip_turn"]
const PHAZES: Array[StringName] = [&"circle_throw", &"dragon_tail"]
const STATUS_PHAZES: Array[StringName] = [&"roar", &"whirlwind"]
const STATUS_PIVOTS: Array[StringName] = [&"teleport", &"baton_pass", &"parting_shot"]
const STATUS_TYPES := {&"roar": &"normal", &"whirlwind": &"normal", &"teleport": &"psychic",
	&"baton_pass": &"normal", &"parting_shot": &"dark"}
# Effects actually represented by the current status core. Do not invent a
# future volatile's transfer semantics just because it has a dictionary key.
const PASSABLE_VOLATILES: Array[StringName] = [&"confusion", &"focus_energy", &"ingrain", &"substitute", &"partial_trap"]
const POWERS := {&"u_turn": 70, &"volt_switch": 70, &"flip_turn": 60,
	&"circle_throw": 60, &"dragon_tail": 60}
const TYPES := {&"u_turn": &"bug", &"volt_switch": &"electric", &"flip_turn": &"water",
	&"circle_throw": &"fighting", &"dragon_tail": &"dragon"}


static func supports(move: MoveDefinition) -> bool:
	if supports_status(move):
		return true
	return move != null and POWERS.has(move.id) and move.power == POWERS[move.id] \
		and move.effect_specs.is_empty() and move.target == "selected-pokemon" \
		and move.type_id == TYPES[move.id] \
		and move.damage_class == ("special" if move.id == &"volt_switch" else "physical") \
		and move.priority == (-6 if move.id in PHAZES else 0)


static func supports_status(move: MoveDefinition) -> bool:
	if move == null or not STATUS_TYPES.has(move.id):
		return false
	var self_target := move.id in [&"teleport", &"baton_pass"]
	return move.power == 0 and move.damage_class == "status" and move.effect_specs.is_empty() \
		and move.type_id == STATUS_TYPES[move.id] \
		and move.target == ("user" if self_target else "selected-pokemon") \
		and move.priority == (-6 if move.id in STATUS_PHAZES or move.id == &"teleport" else 0) \
		and move.accuracy == (100 if move.id == &"parting_shot" else -1)


static func execution_move(move: MoveDefinition) -> MoveDefinition:
	# Frozen data marks all five as non-contact. The four physical moves do make
	# contact: use a detached definition only inside this opt-in mechanic so existing
	# contact retaliation can KO the user BEFORE a pivot/phaze is requested.
	var local := MoveDefinition.from_dict(move.to_dict())
	local.makes_contact = POWERS.has(move.id) and move.id != &"volt_switch"
	return local


static func replacements(state: BattleState, side_id: StringName) -> Array[String]:
	var ids: Array[String] = []
	var active := state.active_for_side(side_id)
	if active == null:
		return ids
	var side := state.side_for_creature(active.instance_id)
	for id: StringName in side.party_ids:
		var candidate := state.creature(id)
		if id != side.active_id and candidate != null and not candidate.is_knocked_out():
			ids.append(String(id))
	return ids


static func phaze_blocker(actor: CreatureInstance, target: CreatureInstance, move_id: StringName = &"", bypass_substitute: bool = false) -> String:
	# Suppression/Mold Breaker-family interactions are not certified in this pilot.
	if target.ability_id in [&"suction_cups", &"guard_dog"]:
		return String(target.ability_id)
	if move_id == &"roar" and target.ability_id == &"soundproof":
		return "soundproof"
	for status: StringName in [&"ingrain", &"substitute", &"dynamax", &"gigantamax"]:
		if status == &"substitute" and (move_id in STATUS_PHAZES or bypass_substitute):
			continue # Both status phazes bypass the substitute; damaging phazes do not.
		if target.status_state.has_volatile(status):
			return String(status)
	return ""


static func baton_payload(actor: CreatureInstance) -> Dictionary:
	var volatiles := {}
	for id: StringName in PASSABLE_VOLATILES:
		if actor.status_state.has_volatile(id):
			volatiles[String(id)] = actor.status_state.volatile[id].duplicate(true)
	return {"stat_stages": actor.stat_stages.to_dict(), "volatile": volatiles}
