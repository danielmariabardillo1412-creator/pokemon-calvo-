class_name TrainerTeamCompositionTestSuite
extends TrainerLoadoutsV2TestSuite

const TC_FIRE_A := &"team_fire_a"
const TC_FIRE_B := &"team_fire_b"
const TC_FIRE_C := &"team_fire_c"
const TC_WATER := &"team_water"
const TC_GRASS := &"team_grass"
const TC_ELECTRIC := &"team_electric"
const TC_GROUND := &"team_ground"

const TC_FIRE_PHYS := &"team_fire_phys"
const TC_FIRE_SPEC := &"team_fire_spec"
const TC_WATER_SPEC := &"team_water_spec"
const TC_GRASS_PHYS := &"team_grass_phys"
const TC_ELECTRIC_PHYS := &"team_electric_phys"
const TC_GROUND_PHYS := &"team_ground_phys"
const TC_SUPPORT := &"team_support"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_team_round_trip()
	_test_team_validator()
	_test_team_analysis()
	_test_team_composer()
	_test_team_materialization()


func _build_catalog() -> void:
	super._build_catalog()
	_add_team_move(TC_FIRE_PHYS, T_FIRE, "physical", 95, [])
	_add_team_move(TC_FIRE_SPEC, T_FIRE, "special", 90, [])
	_add_team_move(TC_WATER_SPEC, T_WATER, "special", 95, [])
	_add_team_move(TC_GRASS_PHYS, T_GRASS, "physical", 95, [])
	_add_team_move(TC_ELECTRIC_PHYS, T_ELECTRIC, "physical", 90, [])
	_add_team_move(TC_GROUND_PHYS, T_GROUND, "physical", 100, [])
	_add_team_move(TC_SUPPORT, T_NORMAL, "status", 0, [BattleEffectSpec.new(
		BattleEffectSpec.MODIFY_STAT_STAGE,
		BattleEffectSpec.OPPONENT,
		-1,
		0,
		10000,
		&"",
		StatStages.ATTACK,
	)])

	_add_team_species(TC_FIRE_A, T_FIRE, 95, 145, 85, 90, 85, 80, [TC_FIRE_PHYS, TC_FIRE_SPEC, TC_SUPPORT])
	_add_team_species(TC_FIRE_B, T_FIRE, 90, 155, 75, 105, 80, 75, [TC_FIRE_PHYS, TC_FIRE_SPEC, TC_SUPPORT])
	_add_team_species(TC_FIRE_C, T_FIRE, 105, 135, 100, 70, 90, 95, [TC_FIRE_PHYS, TC_FIRE_SPEC, TC_SUPPORT])
	_add_team_species(TC_WATER, T_WATER, 100, 80, 95, 85, 150, 110, [TC_WATER_SPEC, TC_SUPPORT])
	_add_team_species(TC_GRASS, T_GRASS, 110, 110, 125, 65, 85, 115, [TC_GRASS_PHYS, TC_SUPPORT])
	_add_team_species(TC_ELECTRIC, T_ELECTRIC, 80, 120, 70, 165, 105, 75, [TC_ELECTRIC_PHYS])
	_add_team_species(TC_GROUND, T_GROUND, 120, 125, 135, 55, 70, 100, [TC_GROUND_PHYS, TC_SUPPORT])


func _test_team_round_trip() -> void:
	var team := _balanced_authored_team()
	var restored := TrainerTeamDefinition.from_dict(JSON.parse_string(JSON.stringify(team.to_dict())))
	_check.call("team_roundtrip_signature", restored.signature() == team.signature())
	_check.call("team_roundtrip_size", restored.size() == 3)
	_check.call("team_roundtrip_lead", restored.lead_index == 2)
	_check.call("team_roundtrip_duplicate_policy", not restored.allow_duplicate_species)


func _test_team_validator() -> void:
	var validator := TrainerTeamValidator.new(_catalog)
	var valid := _balanced_authored_team()
	_check.call("team_validator_accepts_valid_team", bool(validator.validate(valid).get("valid", false)))

	var empty := TrainerTeamDefinition.new()
	empty.team_id = &"empty"
	_check.call("team_validator_rejects_empty", _team_error(validator.validate(empty), "team_empty"))

	var too_large := TrainerTeamDefinition.new()
	too_large.team_id = &"too_large"
	for i in range(PartyRuleset.MAX_PARTY + 1):
		too_large.loadouts.append(_generated(TC_FIRE_A, TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER))
	too_large.allow_duplicate_species = true
	_check.call("team_validator_rejects_more_than_six", _team_error(validator.validate(too_large), "team_too_large"))

	var bad_lead := TrainerTeamDefinition.from_dict(valid.to_dict())
	bad_lead.lead_index = 9
	_check.call("team_validator_rejects_bad_lead", _team_error(validator.validate(bad_lead), "lead_index_out_of_range"))

	var duplicate := TrainerTeamDefinition.new()
	duplicate.team_id = &"duplicate"
	duplicate.loadouts = [
		_generated(TC_FIRE_A, TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER),
		_generated(TC_FIRE_A, TrainerPokemonLoadout.ROLE_SUPPORT),
	]
	_check.call("team_validator_rejects_duplicate_species_by_default", _team_error_prefix(validator.validate(duplicate), "duplicate_species:"))
	duplicate.allow_duplicate_species = true
	_check.call("team_validator_can_allow_duplicate_species", bool(validator.validate(duplicate).get("valid", false)))

	var bad_member := TrainerTeamDefinition.from_dict(valid.to_dict())
	bad_member.loadouts[1].ivs["speed"] = 99
	var bad_result := validator.validate(bad_member)
	_check.call("team_validator_surfaces_member_errors", not (bad_result.get("member_errors", {}) as Dictionary).is_empty())

	var no_id := TrainerTeamDefinition.from_dict(valid.to_dict())
	no_id.team_id = &""
	_check.call("team_validator_rejects_empty_team_id", _team_error(validator.validate(no_id), "team_id_empty"))


func _test_team_analysis() -> void:
	var analyzer := TrainerTeamAnalyzer.new(_catalog)
	var redundant := TrainerTeamDefinition.new()
	redundant.team_id = &"redundant_fire"
	redundant.loadouts = [
		_generated(TC_FIRE_A, TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER),
		_generated(TC_FIRE_B, TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER),
		_generated(TC_FIRE_C, TrainerPokemonLoadout.ROLE_SUPPORT),
	]
	var redundant_analysis := analyzer.analyze(redundant)
	_check.call("team_analysis_counts_members", int(redundant_analysis.get("member_count", 0)) == 3)
	_check.call("team_analysis_detects_three_water_weak", int((redundant_analysis.get("weakness_counts", {}) as Dictionary).get(String(T_WATER), 0)) >= 3)
	_check.call("team_analysis_marks_shared_water_weakness", (redundant_analysis.get("shared_weaknesses", []) as Array).has(String(T_WATER)))
	_check.call("team_analysis_marks_uncovered_water_weakness", (redundant_analysis.get("uncovered_shared_weaknesses", []) as Array).has(String(T_WATER)))

	var balanced_analysis := analyzer.analyze(_balanced_authored_team())
	_check.call("team_analysis_balanced_counts_members", int(balanced_analysis.get("member_count", 0)) == 3)
	_check.call("team_analysis_balanced_has_three_attack_types", (balanced_analysis.get("attack_type_counts", {}) as Dictionary).size() >= 3)
	_check.call("team_analysis_balanced_has_role_diversity", (balanced_analysis.get("role_counts", {}) as Dictionary).size() >= 3)
	_check.call("team_analysis_balanced_scores_above_redundant", int(balanced_analysis.get("synergy_score", 0)) > int(redundant_analysis.get("synergy_score", 0)))


func _test_team_composer() -> void:
	var composer := TrainerTeamComposer.new(_catalog)
	var pool: Array[StringName] = [TC_FIRE_A, TC_FIRE_B, TC_WATER, TC_GRASS, TC_ELECTRIC, TC_GROUND]
	var team := composer.compose(&"composed", pool, 30, 4, TrainerPokemonLoadout.QUALITY_EXPERT)
	_check.call("team_composer_builds_team", team != null)
	if team == null:
		return
	_check.call("team_composer_hits_target_size", team.size() == 4)
	_check.call("team_composer_result_valid", bool(TrainerTeamValidator.new(_catalog).validate(team).get("valid", false)))
	_check.call("team_composer_uses_unique_species", _unique_species_count(team) == 4)
	var analysis := TrainerTeamAnalyzer.new(_catalog).analyze(team)
	_check.call("team_composer_has_role_diversity", (analysis.get("role_counts", {}) as Dictionary).size() >= 3)
	_check.call("team_composer_has_attack_type_diversity", (analysis.get("attack_type_counts", {}) as Dictionary).size() >= 3)
	var repeat := composer.compose(&"composed", pool, 30, 4, TrainerPokemonLoadout.QUALITY_EXPERT)
	_check.call("team_composer_is_deterministic", repeat != null and repeat.signature() == team.signature())
	_check.call("team_composer_selects_valid_lead", team.lead_index >= 0 and team.lead_index < team.size())
	_check.call("team_composer_rejects_invalid_target_size", composer.compose(&"bad", pool, 30, 7, TrainerPokemonLoadout.QUALITY_EXPERT) == null)
	var tiny: Array[StringName] = [TC_FIRE_A, TC_WATER]
	_check.call("team_composer_rejects_impossible_unique_target", composer.compose(&"tiny", tiny, 30, 3, TrainerPokemonLoadout.QUALITY_EXPERT, false) == null)
	var duplicates := composer.compose(&"dups", tiny, 30, 3, TrainerPokemonLoadout.QUALITY_EXPERT, true)
	_check.call("team_composer_can_fill_when_duplicates_allowed", duplicates != null and duplicates.size() == 3)
	_check.call("team_composer_records_source", team.source_id == &"greedy_composed_v1")


func _test_team_materialization() -> void:
	var team := _balanced_authored_team()
	var before := team.signature()
	var factory := TrainerTeamFactory.new(_catalog)
	var roster := factory.materialize(team)
	_check.call("team_factory_materializes_all_members", roster.size() == 3)
	if roster.size() != 3:
		return
	_check.call("team_factory_puts_selected_lead_first", roster[0].species_id == team.loadouts[team.lead_index].species_id)
	var ids: Dictionary = {}
	for creature in roster:
		ids[String(creature.instance_id)] = true
	_check.call("team_factory_instance_ids_are_unique", ids.size() == 3)
	_check.call("team_factory_does_not_mutate_definition", before == team.signature())
	_check.call("team_factory_members_have_stats_and_moves", roster[0].stats.max_hp > 0 and not roster[0].moveset.is_empty())

	var invalid := TrainerTeamDefinition.from_dict(team.to_dict())
	invalid.loadouts[0].evs["attack"] = 999
	_check.call("team_factory_rejects_invalid_team", factory.materialize(invalid).is_empty())

	var original_iv := int(team.loadouts[team.lead_index].ivs.get("hp", -1))
	roster[0].ivs["hp"] = 0
	_check.call("team_factory_materialization_is_independent", int(team.loadouts[team.lead_index].ivs.get("hp", -1)) == original_iv)


func _balanced_authored_team() -> TrainerTeamDefinition:
	var team := TrainerTeamDefinition.new()
	team.team_id = &"balanced_authored"
	team.lead_index = 2
	team.loadouts = [
		_generated(TC_FIRE_A, TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER),
		_generated(TC_WATER, TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER),
		_generated(TC_GRASS, TrainerPokemonLoadout.ROLE_SUPPORT),
	]
	return team


func _generated(species_id: StringName, role_id: StringName) -> TrainerPokemonLoadout:
	return TrainerRoleLoadoutGenerator.new(_catalog).generate(
		species_id,
		30,
		role_id,
		TrainerPokemonLoadout.QUALITY_EXPERT,
	)


func _add_team_move(
	id: StringName,
	type_id: StringName,
	damage_class: String,
	power: int,
	effects: Array[BattleEffectSpec],
) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.type_id = type_id
	move.damage_class = damage_class
	move.power = power
	move.accuracy = 100
	move.pp = 20
	move.crit_rate_bp = -10000
	for effect in effects:
		move.effect_specs.append(effect)
	_catalog.add_move(move)


func _add_team_species(
	id: StringName,
	type_id: StringName,
	hp: int,
	attack: int,
	defense: int,
	speed: int,
	special_attack: int,
	special_defense: int,
	moves: Array[StringName],
) -> void:
	var species := CreatureSpecies.new()
	species.id = id
	species.display_name = String(id)
	species.primary_type_id = type_id
	species.type_ids = [type_id]
	species.base_hp = hp
	species.base_attack = attack
	species.base_defense = defense
	species.base_speed = speed
	species.base_special_attack = special_attack
	species.base_special_defense = special_defense
	for move_id in moves:
		species.learnset.append(LearnSetEntry.new(1, move_id, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(species)


func _team_error(result: Dictionary, expected: String) -> bool:
	return (result.get("errors", []) as Array).has(expected)


func _team_error_prefix(result: Dictionary, prefix: String) -> bool:
	for raw in result.get("errors", []):
		if String(raw).begins_with(prefix):
			return true
	return false


func _unique_species_count(team: TrainerTeamDefinition) -> int:
	var seen: Dictionary = {}
	for loadout in team.loadouts:
		seen[String(loadout.species_id)] = true
	return seen.size()
