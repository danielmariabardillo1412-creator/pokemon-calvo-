extends RefCounted

# Pinned reference: @pkmn/sim@0.10.11 data/moves.js. Canonical DATA V3 stays
# frozen. Resolve at execution time, after PP payment and prior to normal damage.
const CONTRACTS := {
	&"electro_ball": [&"electric", "special", 100, 10],
	&"gyro_ball": [&"steel", "physical", 100, 5],
	&"flail": [&"normal", "physical", 100, 15],
	&"reversal": [&"fighting", "physical", 100, 15],
	&"crush_grip": [&"normal", "physical", 100, 5],
	&"wring_out": [&"normal", "special", 100, 5],
	&"hard_press": [&"steel", "physical", 100, 10],
	&"return": [&"normal", "physical", 100, 20],
	&"frustration": [&"normal", "physical", 100, 20],
	&"trump_card": [&"normal", "special", -1, 5],
	&"punishment": [&"dark", "physical", 100, 5],
}


static func supports(move: MoveDefinition) -> bool:
	if move == null or not CONTRACTS.has(move.id): return false
	var row: Array = CONTRACTS[move.id]
	return move.power == 0 and move.type_id == row[0] and move.damage_class == row[1] \
		and move.accuracy == row[2] and move.pp == row[3] and move.priority == 0 \
		and move.target == "selected-pokemon" and move.crit_rate_bp == 0 \
		and not move.makes_contact and move.effect_specs.is_empty()


static func execution_move(move: MoveDefinition, actor: CreatureInstance, target: CreatureInstance,
	ruleset: BattleRuleset) -> MoveDefinition:
	var local := MoveDefinition.from_dict(move.to_dict())
	local.power = power(move.id, actor, target, ruleset)
	local.makes_contact = move.id != &"electro_ball"
	return local


static func power(id: StringName, actor: CreatureInstance, target: CreatureInstance, ruleset: BattleRuleset) -> int:
	match id:
		&"electro_ball":
			var other := TurnResolver.live_effective_speed(target, ruleset)
			var ratio := 0 if other == 0 else TurnResolver.live_effective_speed(actor, ruleset) / other
			return [40, 60, 80, 120, 150][mini(4, ratio)]
		&"gyro_ball":
			var own := TurnResolver.live_effective_speed(actor, ruleset)
			return 1 if own == 0 else mini(150, 25 * TurnResolver.live_effective_speed(target, ruleset) / own + 1)
		&"flail", &"reversal":
			var ratio := maxi(1, actor.current_hp * 48 / actor.stats.max_hp)
			if ratio < 2: return 200
			if ratio < 5: return 150
			if ratio < 10: return 100
			if ratio < 17: return 80
			if ratio < 33: return 40
			return 20
		&"crush_grip", &"wring_out", &"hard_press":
			var maximum := 100 if id == &"hard_press" else 120
			var fraction: int = target.current_hp * 4096 / target.stats.max_hp
			return maxi(1, ((maximum * (100 * fraction) + 2047) / 4096) / 100)
		&"return": return maxi(1, clampi(actor.friendship, 0, 255) * 10 / 25)
		&"frustration": return maxi(1, (255 - clampi(actor.friendship, 0, 255)) * 10 / 25)
		&"trump_card":
			var pp: int = actor.move_slot(id).current_pp
			return [200, 80, 60, 50][pp] if pp < 4 else 40
		&"punishment":
			var positive := 0
			for stat: StringName in StatStages.ALL: positive += maxi(0, target.stat_stages.get_stage(stat))
			return mini(200, 60 + 20 * positive)
	return 0
