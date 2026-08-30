class_name TrainerLoadoutsV2TestSuite
extends TrainerLoadoutsTestSuite

# The original independence check compared Dictionary/Array values. In GDScript two
# independent containers with identical contents compare equal, so identity cannot be
# inferred from !=. Prove deep independence causally by mutating one materialization
# and verifying the other one is unchanged.
func _test_determinism_and_independence() -> void:
	var generator := TrainerRoleLoadoutGenerator.new(_catalog)
	var a := generator.generate(L_SPECIES, 30, TrainerPokemonLoadout.ROLE_SUPPORT, TrainerPokemonLoadout.QUALITY_TRAINED)
	var b := generator.generate(L_SPECIES, 30, TrainerPokemonLoadout.ROLE_SUPPORT, TrainerPokemonLoadout.QUALITY_TRAINED)
	_check.call("loadout_generation_is_deterministic", a != null and b != null and a.signature() == b.signature())
	if a == null or b == null:
		return
	a.evs["hp"] = 0
	a.move_ids.clear()
	_check.call("loadout_generated_values_are_independent", int(b.evs.get("hp", 0)) > 0 and not b.move_ids.is_empty())

	var factory := TrainerLoadoutFactory.new(_catalog)
	var c1 := factory.materialize(b, &"independent_1")
	var c2 := factory.materialize(b, &"independent_2")
	var independent := c1 != null and c2 != null
	if independent:
		var expected_iv_hp := int(c2.ivs.get("hp", -1))
		var expected_ev_hp := int(c2.evs.get("hp", -1))
		var expected_pp := -1
		if not c2.moveset.is_empty():
			expected_pp = (c2.moveset[0] as BattleMoveSlot).current_pp
		c1.ivs["hp"] = 0
		c1.evs["hp"] = 0
		if not c1.moveset.is_empty():
			(c1.moveset[0] as BattleMoveSlot).current_pp = 0
		independent = (
			int(c2.ivs.get("hp", -1)) == expected_iv_hp
			and int(c2.evs.get("hp", -1)) == expected_ev_hp
			and (
				expected_pp < 0
				or (c2.moveset[0] as BattleMoveSlot).current_pp == expected_pp
			)
		)
	_check.call("loadout_materializations_are_independent", independent)
