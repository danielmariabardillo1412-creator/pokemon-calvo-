extends RefCounted

# Live singles extension over frozen move data. Reference: @pkmn/sim@0.10.11,
# data/moves.js (dragonrage/sonicboom/seismictoss/nightshade/superfang/
# naturesmadness/ruination). Fixed damage has type immunities, but no STAB,
# effectiveness scaling, criticals, burn or offensive/defensive stat scaling.
const Substitute = preload("res://modules/battle/application/substitute_rules.gd")
const CONTRACTS := {
	&"dragon_rage": [&"dragon", "special", 100, 10, 0, false],
	&"sonic_boom": [&"normal", "special", 90, 20, 0, false],
	&"seismic_toss": [&"fighting", "physical", 100, 20, 0, true],
	&"night_shade": [&"ghost", "special", 100, 15, 0, false],
	&"super_fang": [&"normal", "physical", 90, 10, 0, false],
	&"natures_madness": [&"fairy", "special", 90, 10, 0, false],
	# Canonical Ruination is frozen at power 1. Its live effect uses current HP.
	&"ruination": [&"dark", "special", 90, 10, 1, false],
}


static func supports(move: MoveDefinition) -> bool:
	if move == null or not CONTRACTS.has(move.id): return false
	var row: Array = CONTRACTS[move.id]
	return move.type_id == row[0] and move.damage_class == row[1] and move.accuracy == row[2] \
		and move.pp == row[3] and move.power == row[4] and move.makes_contact == row[5] \
		and move.target == "selected-pokemon" and move.priority == 0 and move.crit_rate_bp == 0 \
		and move.effect_specs.is_empty()


static func execution_move(move: MoveDefinition) -> MoveDefinition:
	if move.id != &"super_fang": return move
	var local := MoveDefinition.from_dict(move.to_dict())
	local.makes_contact = true
	return local


static func apply(context: BattleEffectContext) -> void:
	for type: StringName in context.catalog.species(context.target.species_id).type_ids_resolved():
		if context.catalog.type(context.move.type_id).multiplier_against(type) == 0:
			context.events.append(BattleEvent.new(BattleEvent.TYPE_EFFECTIVENESS, context.state.turn,
				context.actor.instance_id, context.target.instance_id, context.move.id, 0,
				{"category": "immune", "multiplier_basis_points": 0}))
			return
	var requested := context.actor.level
	var mode := "level"
	if context.move.id == &"dragon_rage":
		requested = 40
		mode = "constant"
	elif context.move.id == &"sonic_boom":
		requested = 20
		mode = "constant"
	elif context.move.id in [&"super_fang", &"natures_madness", &"ruination"]:
		requested = maxi(1, context.target.current_hp / 2)
		mode = "half_current_hp"
	context.last_damage = Substitute.damage(context, context.target, requested,
		{"fixed": true, "fixed_mode": mode, "requested": requested})
