class_name DamageCalculator
extends RefCounted


func calculate(
	attacker: CreatureInstance,
	defender: CreatureInstance,
	move: MoveDefinition,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
	ruleset: BattleRuleset = null,
	damage_multiplier_basis_points: int = 10000,
	force_critical: int = -1,
	offensive_stat_multiplier_basis_points: int = 10000,
) -> Dictionary:
	if move.power <= 0:
		return {"amount": 0, "stab_basis_points": 10000, "effectiveness_basis_points": 10000, "critical": false}
	var active_ruleset := ruleset if ruleset != null else BattleRuleset.new()
	var attacker_species := catalog.species(attacker.species_id)
	var defender_species := catalog.species(defender.species_id)
	assert(attacker_species != null and defender_species != null, "Battle creature species must exist")
	var stab_bp := 15000 if attacker_species.has_type(move.type_id) else 10000
	var eff := 1.0
	for defender_type_id in defender_species.type_ids_resolved():
		eff *= catalog.type(move.type_id).multiplier_against(defender_type_id)
	var effectiveness_bp := int(round(eff * 10000.0))
	if effectiveness_bp == 0:
		return {
			"amount": 0,
			"stab_basis_points": stab_bp,
			"effectiveness_basis_points": 0,
			"random_basis_points": 10000,
			"critical": false,
			"critical_basis_points": 10000,
		}
	var crit_threshold := active_ruleset.critical_threshold_basis_points()
	if move != null:
		crit_threshold += move.crit_rate_bp
	var critical := (
		force_critical == 1
		or (force_critical < 0 and rng.roll_basis_points(crit_threshold))
	)
	var critical_bp := active_ruleset.critical_multiplier_basis_points if critical else 10000
	var random_bp := rng.damage_factor_basis_points()
	var physical := move.damage_class == "physical"
	var attack_stat := attacker.stats.attack if physical else attacker.stats.special_attack
	var defense_stat := defender.stats.defense if physical else defender.stats.special_defense
	var attack_stage_id := StatStages.ATTACK if physical else StatStages.SPECIAL_ATTACK
	var defense_stage_id := StatStages.DEFENSE if physical else StatStages.SPECIAL_DEFENSE
	attack_stat = attack_stat * active_ruleset.stat_multiplier_basis_points(
		attacker.stat_stages.get_stage(attack_stage_id)
	) / 10000
	attack_stat = attack_stat * offensive_stat_multiplier_basis_points / 10000
	defense_stat = defense_stat * active_ruleset.stat_multiplier_basis_points(
		defender.stat_stages.get_stage(defense_stage_id)
	) / 10000
	var level_term: int = (2 * attacker.level) / 5 + 2
	var base_damage: int = (
		((level_term * move.power * maxi(1, attack_stat)) / maxi(1, defense_stat)) / 50 + 2
	)
	# Keep all modifiers integer-based so replays do not depend on floating-point rounding.
	var modified: int = base_damage * stab_bp
	modified = modified * effectiveness_bp / 10000
	modified = modified * critical_bp / 10000
	modified = modified * damage_multiplier_basis_points / 10000
	if physical and attacker.status_state.persistent_id == &"burn":
		modified = modified * active_ruleset.burn_physical_multiplier_basis_points / 10000
	modified = modified * random_bp / 10000
	var damage := maxi(1, modified / 10000)
	return {
		"amount": damage,
		"stab_basis_points": stab_bp,
		"effectiveness_basis_points": effectiveness_bp,
		"random_basis_points": random_bp,
		"critical": critical,
		"critical_basis_points": critical_bp,
		"damage_class": move.damage_class,
		"offensive_stat_multiplier_basis_points": offensive_stat_multiplier_basis_points,
	}
