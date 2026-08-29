class_name DamageCalculator
extends RefCounted


func calculate(
	attacker: CreatureInstance,
	defender: CreatureInstance,
	move: MoveDefinition,
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
) -> Dictionary:
	if move.power <= 0:
		return {"amount": 0, "stab_basis_points": 10000, "effectiveness_basis_points": 10000}
	var attacker_species := catalog.species(attacker.species_id)
	var defender_species := catalog.species(defender.species_id)
	assert(attacker_species != null and defender_species != null, "Battle creature species must exist")
	var stab_bp := 15000 if attacker_species.has_type(move.type_id) else 10000
	var eff := 1.0
	for defender_type_id in defender_species.type_ids_resolved():
		eff *= catalog.type(move.type_id).multiplier_against(defender_type_id)
	var effectiveness_bp := int(round(eff * 10000.0))
	var random_bp := rng.damage_factor_basis_points()
	var level_term: int = (2 * attacker.level) / 5 + 2
	var base_damage: int = (
		((level_term * move.power * attacker.stats.attack) / defender.stats.defense) / 50 + 2
	)
	# Keep all modifiers integer-based so replays do not depend on floating-point rounding.
	var modified: int = base_damage * stab_bp
	modified = modified * effectiveness_bp / 10000
	modified = modified * random_bp / 10000
	var damage := maxi(1, modified / 10000)
	return {
		"amount": damage,
		"stab_basis_points": stab_bp,
		"effectiveness_basis_points": effectiveness_bp,
		"random_basis_points": random_bp,
	}
