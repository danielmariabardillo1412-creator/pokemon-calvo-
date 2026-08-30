class_name TrainerLoadoutsTestSuite
extends TrainerStrategicSwitchingV2TestSuite

const L_PHYS := &"loadout_phys"
const L_SPEC := &"loadout_spec"
const L_STATUS := &"loadout_status"
const L_MACHINE := &"loadout_machine"
const L_SPECIAL := &"loadout_special_method"
const L_FOREIGN := &"loadout_foreign"
const L_SPECIES := &"loadout_species"
const L_PLAIN_SPECIES := &"loadout_plain_species"
const L_UNSUPPORTED_ABILITY := &"pressure"
const L_UNSUPPORTED_ITEM := &"choice_band"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_loadout_round_trip()
	_test_validator_contract()
	_test_role_generation()
	_test_materialization()
	_test_determinism_and_independence()


func _build_catalog() -> void:
	super._build_catalog()
	_catalog.add_ability(AbilityDefinition.new(&"intimidate", "Intimidate"))
	_catalog.add_ability(AbilityDefinition.new(&"levitate", "Levitate"))
	_catalog.add_ability(AbilityDefinition.new(L_UNSUPPORTED_ABILITY, "Pressure"))
	_catalog.add_item(ItemDefinition.new(&"leftovers", "Leftovers", "", &"held"))
	_catalog.add_item(ItemDefinition.new(&"sitrus_berry", "Sitrus Berry", "", &"held"))
	_catalog.add_item(ItemDefinition.new(L_UNSUPPORTED_ITEM, "Choice Band", "", &"held"))
	_add_loadout_move(L_PHYS, "physical", 95, [])
	_add_loadout_move(L_SPEC, "special", 90, [])
	_add_loadout_move(L_STATUS, "status", 0, [BattleEffectSpec.new(
		BattleEffectSpec.MODIFY_STAT_STAGE,
		BattleEffectSpec.OPPONENT,
		-1,
		0,
		10000,
		&"",
		StatStages.ATTACK,
	)])
	_add_loadout_move(L_MACHINE, "physical", 80, [])
	_add_loadout_move(L_SPECIAL, "special", 70, [])
	_add_loadout_move(L_FOREIGN, "physical", 100, [])

	var species := CreatureSpecies.new()
	species.id = L_SPECIES
	species.display_name = "Loadout Species"
	species.primary_type_id = T_NORMAL
	species.type_ids = [T_NORMAL]
	species.base_hp = 90
	species.base_attack = 120
	species.base_defense = 85
	species.base_speed = 100
	species.base_special_attack = 115
	species.base_special_defense = 90
	species.ability_ids = [&"intimidate", L_UNSUPPORTED_ABILITY]
	species.learnset.append(LearnSetEntry.new(1, L_PHYS, LearnsetSystem.LEVEL_UP))
	species.learnset.append(LearnSetEntry.new(1, L_SPEC, LearnsetSystem.LEVEL_UP))
	species.learnset.append(LearnSetEntry.new(10, L_STATUS, LearnsetSystem.LEVEL_UP))
	species.learnset.append(LearnSetEntry.new(1, L_MACHINE, TrainerPublicCoverageBeliefInference.METHOD_MACHINE))
	species.learnset.append(LearnSetEntry.new(1, L_SPECIAL, "special"))
	_catalog.add_species(species)

	var plain := CreatureSpecies.new()
	plain.id = L_PLAIN_SPECIES
	plain.display_name = "Plain Species"
	plain.primary_type_id = T_NORMAL
	plain.type_ids = [T_NORMAL]
	plain.base_hp = 80
	plain.base_attack = 80
	plain.base_defense = 80
	plain.base_speed = 80
	plain.base_special_attack = 80
	plain.base_special_defense = 80
	plain.ability_ids = [L_UNSUPPORTED_ABILITY]
	plain.learnset.append(LearnSetEntry.new(1, L_PHYS, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(plain)


func _test_loadout_round_trip() -> void:
	var source := _authored_loadout()
	var restored := TrainerPokemonLoadout.from_dict(JSON.parse_string(JSON.stringify(source.to_dict())))
	_check.call("loadout_roundtrip_signature", source.signature() == restored.signature())
	_check.call("loadout_roundtrip_role", restored.role_id == TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER)
	_check.call("loadout_roundtrip_moves", restored.move_ids == [L_PHYS, L_MACHINE])
	_check.call("loadout_schema_v1", int(restored.to_dict().get("schema_version", 0)) == 1)


func _test_validator_contract() -> void:
	var validator := TrainerLoadoutValidator.new(_catalog)
	var valid := _authored_loadout()
	_check.call("loadout_valid_authored", bool(validator.validate(valid).get("valid", false)))

	var bad_iv := TrainerPokemonLoadout.from_dict(valid.to_dict())
	bad_iv.ivs["attack"] = 32
	_check.call("loadout_rejects_iv_over_31", _has_validation_error(validator.validate(bad_iv), "iv_out_of_range:attack"))

	var bad_ev := TrainerPokemonLoadout.from_dict(valid.to_dict())
	bad_ev.evs["attack"] = 253
	_check.call("loadout_rejects_ev_over_252", _has_validation_error(validator.validate(bad_ev), "ev_out_of_range:attack"))

	var bad_total := TrainerPokemonLoadout.from_dict(valid.to_dict())
	bad_total.evs = {"hp": 252, "attack": 252, "defense": 252}
	_check.call("loadout_rejects_ev_total_over_510", _has_validation_error(validator.validate(bad_total), "ev_total_exceeded"))

	var bad_nature := TrainerPokemonLoadout.from_dict(valid.to_dict())
	bad_nature.nature_id = &"invented_nature"
	_check.call("loadout_rejects_unknown_nature", _has_validation_error(validator.validate(bad_nature), "nature_unknown"))

	var duplicate := TrainerPokemonLoadout.from_dict(valid.to_dict())
	duplicate.move_ids = [L_PHYS, L_PHYS]
	_check.call("loadout_rejects_duplicate_move", _validation_contains_prefix(validator.validate(duplicate), "duplicate_move:"))

	var too_many := TrainerPokemonLoadout.from_dict(valid.to_dict())
	too_many.move_ids = [L_PHYS, L_SPEC, L_STATUS, L_MACHINE, L_FOREIGN]
	_check.call("loadout_rejects_more_than_four_moves", _has_validation_error(validator.validate(too_many), "moveset_too_large"))

	var foreign := TrainerPokemonLoadout.from_dict(valid.to_dict())
	foreign.move_ids = [L_FOREIGN]
	_check.call("loadout_rejects_foreign_move", _validation_contains_prefix(validator.validate(foreign), "move_not_species_compatible:"))

	var special_method := TrainerPokemonLoadout.from_dict(valid.to_dict())
	special_method.move_ids = [L_SPECIAL]
	_check.call("loadout_rejects_unsupported_learn_method", _validation_contains_prefix(validator.validate(special_method), "move_not_species_compatible:"))

	var bad_ability := TrainerPokemonLoadout.from_dict(valid.to_dict())
	bad_ability.ability_id = L_UNSUPPORTED_ABILITY
	_check.call("loadout_rejects_runtime_unsupported_ability", _has_validation_error(validator.validate(bad_ability), "ability_not_runtime_supported"))

	var incompatible_ability := TrainerPokemonLoadout.from_dict(valid.to_dict())
	incompatible_ability.ability_id = &"levitate"
	_check.call("loadout_rejects_species_incompatible_ability", _has_validation_error(validator.validate(incompatible_ability), "ability_not_species_compatible"))

	var bad_item := TrainerPokemonLoadout.from_dict(valid.to_dict())
	bad_item.held_item_id = L_UNSUPPORTED_ITEM
	_check.call("loadout_rejects_runtime_unsupported_held_item", _has_validation_error(validator.validate(bad_item), "held_item_not_runtime_supported"))

	var machine_ok := TrainerPokemonLoadout.from_dict(valid.to_dict())
	machine_ok.move_ids = [L_MACHINE]
	_check.call("loadout_accepts_public_machine_compatibility", bool(validator.validate(machine_ok).get("valid", false)))


func _test_role_generation() -> void:
	var generator := TrainerRoleLoadoutGenerator.new(_catalog)
	var physical := generator.generate(
		L_SPECIES, 30,
		TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER,
		TrainerPokemonLoadout.QUALITY_EXPERT,
	)
	_check.call("loadout_physical_generated", physical != null)
	_check.call("loadout_physical_adamant", physical != null and physical.nature_id == &"adamant")
	_check.call("loadout_physical_attack_252", physical != null and int(physical.evs.get("attack", 0)) == 252)
	_check.call("loadout_physical_speed_252", physical != null and int(physical.evs.get("speed", 0)) == 252)
	_check.call("loadout_physical_all_31_ivs", physical != null and _all_stats_equal(physical.ivs, 31))
	_check.call("loadout_physical_prioritizes_physical_move", physical != null and not physical.move_ids.is_empty() and physical.move_ids[0] == L_PHYS)
	_check.call("loadout_physical_selects_supported_ability", physical != null and physical.ability_id == &"intimidate")
	_check.call("loadout_physical_selects_sitrus", physical != null and physical.held_item_id == &"sitrus_berry")
	_check.call("loadout_physical_generated_valid", physical != null and bool(TrainerLoadoutValidator.new(_catalog).validate(physical).get("valid", false)))

	var special := generator.generate(
		L_SPECIES, 30,
		TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER,
		TrainerPokemonLoadout.QUALITY_EXPERT,
	)
	_check.call("loadout_special_modest", special != null and special.nature_id == &"modest")
	_check.call("loadout_special_spa_252", special != null and int(special.evs.get("special_attack", 0)) == 252)
	_check.call("loadout_special_prioritizes_special_move", special != null and not special.move_ids.is_empty() and special.move_ids[0] == L_SPEC)

	var support := generator.generate(
		L_SPECIES, 30,
		TrainerPokemonLoadout.ROLE_SUPPORT,
		TrainerPokemonLoadout.QUALITY_EXPERT,
	)
	_check.call("loadout_support_prioritizes_utility", support != null and not support.move_ids.is_empty() and support.move_ids[0] == L_STATUS)
	_check.call("loadout_support_uses_leftovers", support != null and support.held_item_id == &"leftovers")
	_check.call("loadout_support_ev_total_legal", support != null and _stat_total(support.evs) <= ProgressionRuleset.EV_TOTAL_MAX)

	var basic := generator.generate(
		L_PLAIN_SPECIES, 20,
		TrainerPokemonLoadout.ROLE_BALANCED,
		TrainerPokemonLoadout.QUALITY_BASIC,
	)
	_check.call("loadout_basic_uses_15_ivs", basic != null and _all_stats_equal(basic.ivs, 15))
	_check.call("loadout_basic_has_zero_evs", basic != null and _stat_total(basic.evs) == 0)
	_check.call("loadout_generator_drops_unsupported_ability", basic != null and basic.ability_id == &"")


func _test_materialization() -> void:
	var generator := TrainerRoleLoadoutGenerator.new(_catalog)
	var loadout := generator.generate(
		L_SPECIES, 30,
		TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER,
		TrainerPokemonLoadout.QUALITY_EXPERT,
	)
	var factory := TrainerLoadoutFactory.new(_catalog)
	var creature := factory.materialize(loadout, &"loadout_instance")
	_check.call("loadout_materializes_creature", creature != null)
	if creature == null:
		return
	_check.call("loadout_materialized_identity", creature.instance_id == &"loadout_instance" and creature.species_id == L_SPECIES)
	_check.call("loadout_materialized_nature", creature.nature_id == loadout.nature_id)
	_check.call("loadout_materialized_ability_item", creature.ability_id == loadout.ability_id and creature.held_item_id == loadout.held_item_id)
	_check.call("loadout_materialized_moves", creature.move_ids == loadout.move_ids)
	var expected := StatCalculator.compute(
		_catalog.species(L_SPECIES).base_stat_block(),
		loadout.ivs,
		loadout.evs,
		loadout.nature_id,
		loadout.level,
	)
	_check.call("loadout_materialized_stats_match_canonical_formula", creature.stats.to_dict() == expected.to_dict())
	_check.call("loadout_materialized_full_hp", creature.current_hp == creature.stats.max_hp)
	var pp_ok := true
	for slot in creature.moveset:
		pp_ok = pp_ok and (slot as BattleMoveSlot).max_pp > 0 and (slot as BattleMoveSlot).current_pp == (slot as BattleMoveSlot).max_pp
	_check.call("loadout_materialized_pp_initialized", pp_ok)

	var invalid := TrainerPokemonLoadout.from_dict(loadout.to_dict())
	invalid.evs["attack"] = 999
	_check.call("loadout_factory_rejects_invalid_instead_of_clamping", factory.materialize(invalid, &"invalid") == null)


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
	_check.call("loadout_materializations_are_independent", c1 != null and c2 != null and c1.ivs != c2.ivs and c1.evs != c2.evs and c1.moveset != c2.moveset)


func _authored_loadout() -> TrainerPokemonLoadout:
	var loadout := TrainerPokemonLoadout.new()
	loadout.species_id = L_SPECIES
	loadout.level = 30
	loadout.role_id = TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER
	loadout.quality_id = TrainerPokemonLoadout.QUALITY_EXPERT
	loadout.nature_id = &"adamant"
	for key in ProgressionRuleset.STAT_KEYS:
		loadout.ivs[key] = 31
		loadout.evs[key] = 0
	loadout.evs["attack"] = 252
	loadout.evs["speed"] = 252
	loadout.evs["hp"] = 4
	loadout.ability_id = &"intimidate"
	loadout.held_item_id = &"sitrus_berry"
	loadout.move_ids = [L_PHYS, L_MACHINE]
	loadout.source_id = &"test_authored"
	return loadout


func _add_loadout_move(
	id: StringName,
	damage_class: String,
	power: int,
	effects: Array[BattleEffectSpec],
) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.type_id = T_NORMAL
	move.damage_class = damage_class
	move.power = power
	move.accuracy = 100
	move.pp = 20
	move.crit_rate_bp = -10000
	for effect in effects:
		move.effect_specs.append(effect)
	_catalog.add_move(move)


func _has_validation_error(result: Dictionary, expected: String) -> bool:
	return (result.get("errors", []) as Array).has(expected)


func _validation_contains_prefix(result: Dictionary, prefix: String) -> bool:
	for raw_error in result.get("errors", []):
		if String(raw_error).begins_with(prefix):
			return true
	return false


func _all_stats_equal(values: Dictionary, expected: int) -> bool:
	for key in ProgressionRuleset.STAT_KEYS:
		if int(values.get(key, -1)) != expected:
			return false
	return true


func _stat_total(values: Dictionary) -> int:
	var total := 0
	for key in ProgressionRuleset.STAT_KEYS:
		total += int(values.get(key, 0))
	return total
