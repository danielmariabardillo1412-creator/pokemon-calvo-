class_name TrainerEvaluationCorpusTestSuite
extends RefCounted

const H_GREEDY := &"corpus_h_greedy"
const H_SETUP := &"corpus_h_setup"
const H_HEAVY := &"corpus_h_heavy"
const KO_STRIKE := &"corpus_ko_strike"
const KO_REPLY := &"corpus_ko_reply"
const PRIORITY_STRIKE := &"corpus_priority_strike"
const PRIORITY_REPLY := &"corpus_priority_reply"
const IMMUNE_NORMAL := &"corpus_immune_normal"
const COVERAGE_FIRE := &"corpus_coverage_fire"
const GHOST_REPLY := &"corpus_ghost_reply"
const CONTROL_STRIKE := &"corpus_control_strike"
const CONTROL_SETUP := &"corpus_control_setup"
const CONTROL_REPLY := &"corpus_control_reply"

var _check: Callable
var _catalog := DefinitionCatalog.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_build_catalog()
	_test_wilson_contract()
	_test_corpus_has_distinct_families()
	_test_sixty_match_statistical_corpus()


func _build_catalog() -> void:
	var normal := TypeDefinition.new("Normal", {"ghost": 0.0})
	normal.id = &"normal"
	_catalog.add_type(normal)
	var fire := TypeDefinition.new("Fire")
	fire.id = &"fire"
	_catalog.add_type(fire)
	var ghost := TypeDefinition.new("Ghost")
	ghost.id = &"ghost"
	_catalog.add_type(ghost)

	_add_damage_move(H_GREEDY, &"normal", 80, 0)
	_add_setup_move(H_SETUP, 4, 2)
	_add_damage_move(H_HEAVY, &"normal", 85, 0)
	_add_damage_move(KO_STRIKE, &"normal", 180, 0)
	_add_damage_move(KO_REPLY, &"normal", 45, 0)
	_add_damage_move(PRIORITY_STRIKE, &"normal", 180, 1)
	_add_damage_move(PRIORITY_REPLY, &"normal", 120, 0)
	_add_damage_move(IMMUNE_NORMAL, &"normal", 220, 0)
	_add_damage_move(COVERAGE_FIRE, &"fire", 180, 0)
	_add_damage_move(GHOST_REPLY, &"ghost", 45, 0)
	_add_damage_move(CONTROL_STRIKE, &"normal", 180, 0)
	_add_setup_move(CONTROL_SETUP, 4, 2)
	_add_damage_move(CONTROL_REPLY, &"normal", 45, 0)

	_add_species(&"corpus_h_candidate", &"normal", 50, 220, 50, 10, [H_GREEDY, H_SETUP])
	_add_species(&"corpus_h_reference", &"normal", 50, 120, 80, 100, [H_HEAVY])
	_add_species(&"corpus_ko_candidate", &"normal", 50, 220, 70, 70, [KO_STRIKE])
	_add_species(&"corpus_ko_reference", &"normal", 35, 80, 50, 30, [KO_REPLY])
	_add_species(&"corpus_priority_candidate", &"normal", 50, 220, 70, 10, [PRIORITY_STRIKE])
	_add_species(&"corpus_priority_reference", &"normal", 35, 120, 50, 110, [PRIORITY_REPLY])
	_add_species(&"corpus_coverage_candidate", &"normal", 50, 220, 70, 60, [IMMUNE_NORMAL, COVERAGE_FIRE])
	_add_species(&"corpus_coverage_reference", &"ghost", 35, 80, 50, 40, [GHOST_REPLY])
	_add_species(&"corpus_control_candidate", &"normal", 50, 220, 70, 60, [CONTROL_STRIKE, CONTROL_SETUP])
	_add_species(&"corpus_control_reference", &"normal", 35, 80, 50, 30, [CONTROL_REPLY])

	_check.call("corpus_types_available", _catalog.type(&"normal") != null and _catalog.type(&"fire") != null and _catalog.type(&"ghost") != null)
	_check.call("corpus_normal_immunity_is_zero", _catalog.type_multiplier(&"normal", &"ghost") == 0.0)


func _test_wilson_contract() -> void:
	var perfect := TrainerWilsonInterval.calculate(60, 60)
	var baseline := TrainerWilsonInterval.calculate(48, 60)
	var none := TrainerWilsonInterval.calculate(0, 0)
	_check.call("corpus_wilson_method_id", String(perfect.get("method", "")) == "wilson_score_v1")
	_check.call("corpus_wilson_perfect_estimate", int(perfect.get("estimate_basis_points", 0)) == 10000)
	_check.call("corpus_wilson_perfect_lower_is_conservative", int(perfect.get("lower_basis_points", 0)) > 9300 and int(perfect.get("lower_basis_points", 0)) < 10000)
	_check.call("corpus_wilson_baseline_estimate", int(baseline.get("estimate_basis_points", 0)) == 8000)
	_check.call("corpus_wilson_baseline_upper_below_perfect_lower", int(baseline.get("upper_basis_points", 10000)) < int(perfect.get("lower_basis_points", 0)))
	_check.call("corpus_wilson_empty_is_uninformative", int(none.get("lower_basis_points", -1)) == 0 and int(none.get("upper_basis_points", -1)) == 10000)


func _test_corpus_has_distinct_families() -> void:
	var scenarios := _scenarios()
	var families: Dictionary = {}
	var matches := 0
	for scenario in scenarios:
		families[String(scenario.get("family", ""))] = true
		matches += (scenario.get("seeds", []) as Array).size() * 2
	_check.call("corpus_has_five_scenarios", scenarios.size() == 5)
	_check.call("corpus_has_five_distinct_families", families.size() == 5)
	_check.call("corpus_contract_is_sixty_matches_per_candidate", matches == 60)


func _test_sixty_match_statistical_corpus() -> void:
	var first := TrainerEvaluationCorpus.run(
		_catalog,
		_scenarios(),
		Callable(self, "_baseline_factory"),
		Callable(self, "_planner_factory"),
	)
	var second := TrainerEvaluationCorpus.run(
		_catalog,
		_scenarios(),
		Callable(self, "_baseline_factory"),
		Callable(self, "_planner_factory"),
	)
	var totals := first.get("totals", {}) as Dictionary
	var statistics := first.get("statistics", {}) as Dictionary
	var baseline_interval := statistics.get("baseline_win_interval", {}) as Dictionary
	var planner_interval := statistics.get("planner_win_interval", {}) as Dictionary
	var improvement_interval := statistics.get("improvement_interval", {}) as Dictionary
	var regression_interval := statistics.get("regression_interval", {}) as Dictionary

	_check.call("corpus_model_id", String(first.get("evaluation_model", "")) == TrainerEvaluationCorpus.MODEL_ID)
	_check.call("corpus_reports_five_scenarios", int(first.get("scenario_count", 0)) == 5)
	_check.call("corpus_runs_sixty_matches_per_candidate", int(totals.get("matches_per_candidate", 0)) == 60)
	_check.call("corpus_baseline_record_is_48_12", int(totals.get("baseline_wins", -1)) == 48 and int(totals.get("baseline_losses", -1)) == 12)
	_check.call("corpus_planner_record_is_60_0", int(totals.get("planner_wins", -1)) == 60 and int(totals.get("planner_losses", -1)) == 0)
	_check.call("corpus_no_draws", int(totals.get("baseline_draws", -1)) == 0 and int(totals.get("planner_draws", -1)) == 0)
	_check.call("corpus_no_invalid_matches", int(totals.get("baseline_invalid", -1)) == 0 and int(totals.get("planner_invalid", -1)) == 0)
	_check.call("corpus_has_twelve_paired_improvements", int(totals.get("paired_improvements", -1)) == 12)
	_check.call("corpus_has_zero_paired_regressions", int(totals.get("paired_regressions", -1)) == 0)
	_check.call("corpus_has_48_equal_pairs", int(totals.get("paired_equal", -1)) == 48)
	_check.call("corpus_planner_interval_estimate_100_percent", int(planner_interval.get("estimate_basis_points", 0)) == 10000)
	_check.call("corpus_baseline_interval_estimate_80_percent", int(baseline_interval.get("estimate_basis_points", 0)) == 8000)
	_check.call("corpus_win_intervals_do_not_overlap", int(planner_interval.get("lower_basis_points", 0)) > int(baseline_interval.get("upper_basis_points", 10000)))
	_check.call("corpus_directional_improvement_interval_is_positive", int(improvement_interval.get("lower_basis_points", 0)) > 7000)
	_check.call("corpus_directional_regression_estimate_zero", int(regression_interval.get("estimate_basis_points", -1)) == 0)
	_check.call("corpus_signature_present", not String(first.get("signature", "")).is_empty())
	_check.call("corpus_is_deterministic", JSON.stringify(first) == JSON.stringify(second))

	var by_id := _scenario_map(first.get("scenarios", []) as Array)
	_check.call("corpus_horizon_baseline_loses_all", _scenario_wins(by_id, "horizon_setup", "baseline") == 0)
	_check.call("corpus_horizon_planner_wins_all", _scenario_wins(by_id, "horizon_setup", "planner") == 12)
	_check.call("corpus_horizon_has_12_improvements", int((by_id.get("horizon_setup", {}) as Dictionary).get("paired_improvements", -1)) == 12)
	_check.call("corpus_immediate_ko_control_equal", _scenario_equal_all(by_id, "immediate_ko"))
	_check.call("corpus_priority_control_equal", _scenario_equal_all(by_id, "priority_finish"))
	_check.call("corpus_immunity_control_equal", _scenario_equal_all(by_id, "known_immunity_coverage"))
	_check.call("corpus_no_unnecessary_setup_control_equal", _scenario_equal_all(by_id, "avoid_unneeded_setup"))
	_check.call("corpus_all_control_planners_win", _scenario_wins(by_id, "immediate_ko", "planner") == 12 and _scenario_wins(by_id, "priority_finish", "planner") == 12 and _scenario_wins(by_id, "known_immunity_coverage", "planner") == 12 and _scenario_wins(by_id, "avoid_unneeded_setup", "planner") == 12)


func _scenarios() -> Array[Dictionary]:
	var seeds: Array[int] = [101, 202, 303, 404, 505, 606]
	return [
		_scenario("horizon_setup", "two_turn_setup_horizon", _horizon_candidate(), _horizon_reference(), seeds, 6),
		_scenario("immediate_ko", "obvious_terminal_attack", _ko_candidate(), _ko_reference(), seeds, 4),
		_scenario("priority_finish", "priority_speed_control", _priority_candidate(), _priority_reference(), seeds, 4),
		_scenario("known_immunity_coverage", "guarded_type_coverage", _coverage_candidate(), _coverage_reference(), seeds, 4),
		_scenario("avoid_unneeded_setup", "setup_restraint_control", _control_candidate(), _control_reference(), seeds, 4),
	]


func _scenario(
	id: String,
	family: String,
	candidate: Array[CreatureInstance],
	reference: Array[CreatureInstance],
	seeds: Array[int],
	max_turns: int,
) -> Dictionary:
	return {
		"id": id,
		"family": family,
		"candidate_roster": candidate,
		"reference_roster": reference,
		"reference_factory": Callable(self, "_reference_factory"),
		"seeds": seeds.duplicate(),
		"max_turns": max_turns,
	}


func _baseline_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return SearchTrainerBrain.new(catalog, TrainerProfile.balanced())


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return DepthSearchTrainerBrain.new(catalog, TrainerProfile.balanced(), TrainerSearchBudget.constrained(2, 2, 32, 3))


func _reference_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return TacticalTrainerBrain.new(catalog, TrainerProfile.balanced())


func _horizon_candidate() -> Array[CreatureInstance]:
	return _roster(&"corpus_h_candidate_i", &"corpus_h_candidate", StatBlock.new(110, 250, 80, 40, 80, 80), [H_GREEDY, H_SETUP])


func _horizon_reference() -> Array[CreatureInstance]:
	return _roster(&"corpus_h_reference_i", &"corpus_h_reference", StatBlock.new(110, 150, 110, 90, 100, 100), [H_HEAVY])


func _ko_candidate() -> Array[CreatureInstance]:
	return _roster(&"corpus_ko_candidate_i", &"corpus_ko_candidate", StatBlock.new(120, 250, 100, 100, 80, 80), [KO_STRIKE])


func _ko_reference() -> Array[CreatureInstance]:
	return _roster(&"corpus_ko_reference_i", &"corpus_ko_reference", StatBlock.new(80, 90, 60, 40, 70, 70), [KO_REPLY])


func _priority_candidate() -> Array[CreatureInstance]:
	return _roster(&"corpus_priority_candidate_i", &"corpus_priority_candidate", StatBlock.new(120, 250, 100, 30, 80, 80), [PRIORITY_STRIKE])


func _priority_reference() -> Array[CreatureInstance]:
	return _roster(&"corpus_priority_reference_i", &"corpus_priority_reference", StatBlock.new(80, 150, 60, 120, 80, 80), [PRIORITY_REPLY])


func _coverage_candidate() -> Array[CreatureInstance]:
	return _roster(&"corpus_coverage_candidate_i", &"corpus_coverage_candidate", StatBlock.new(120, 270, 100, 90, 80, 80), [IMMUNE_NORMAL, COVERAGE_FIRE])


func _coverage_reference() -> Array[CreatureInstance]:
	return _roster(&"corpus_coverage_reference_i", &"corpus_coverage_reference", StatBlock.new(80, 90, 60, 50, 70, 70), [GHOST_REPLY])


func _control_candidate() -> Array[CreatureInstance]:
	return _roster(&"corpus_control_candidate_i", &"corpus_control_candidate", StatBlock.new(120, 250, 100, 100, 80, 80), [CONTROL_STRIKE, CONTROL_SETUP])


func _control_reference() -> Array[CreatureInstance]:
	return _roster(&"corpus_control_reference_i", &"corpus_control_reference", StatBlock.new(80, 90, 60, 40, 70, 70), [CONTROL_REPLY])


func _roster(id: StringName, species_id: StringName, stats: StatBlock, moves: Array[StringName]) -> Array[CreatureInstance]:
	var creature := CreatureInstance.new(id, species_id, 30, stats, moves)
	creature.initialize_move_pp(_catalog)
	var out: Array[CreatureInstance] = [creature]
	return out


func _add_species(id: StringName, type_id: StringName, hp: int, attack: int, defense: int, speed: int, moves: Array[StringName]) -> void:
	var species := CreatureSpecies.new()
	species.id = id
	species.display_name = String(id)
	species.primary_type_id = type_id
	var types: Array[StringName] = [type_id]
	species.type_ids = types
	species.base_hp = hp
	species.base_attack = attack
	species.base_defense = defense
	species.base_speed = speed
	species.base_special_attack = attack
	species.base_special_defense = defense
	for move_id in moves:
		species.learnset.append(LearnSetEntry.new(1, move_id, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(species)


func _add_damage_move(id: StringName, type_id: StringName, power: int, priority: int) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.power = power
	move.type_id = type_id
	move.priority = priority
	move.damage_class = "physical"
	move.accuracy = 100
	move.pp = 20
	_catalog.add_move(move)


func _add_setup_move(id: StringName, speed_stages: int, attack_stages: int) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.power = 0
	move.type_id = &"normal"
	move.damage_class = "status"
	move.accuracy = 100
	move.pp = 1
	move.effect_specs.append(BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.SELF, speed_stages, 0, 10000, &"", StatStages.SPEED))
	move.effect_specs.append(BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.SELF, attack_stages, 0, 10000, &"", StatStages.ATTACK))
	_catalog.add_move(move)


func _scenario_map(records: Array) -> Dictionary:
	var out: Dictionary = {}
	for value in records:
		var record := value as Dictionary
		out[String(record.get("id", ""))] = record
	return out


func _scenario_wins(by_id: Dictionary, id: String, side: String) -> int:
	var record := by_id.get(id, {}) as Dictionary
	var summary := record.get(side, {}) as Dictionary
	return int(summary.get("wins", -1))


func _scenario_equal_all(by_id: Dictionary, id: String) -> bool:
	var record := by_id.get(id, {}) as Dictionary
	return int(record.get("paired_improvements", -1)) == 0 and int(record.get("paired_regressions", -1)) == 0 and int(record.get("paired_equal", -1)) == 12 and _scenario_wins(by_id, id, "baseline") == 12 and _scenario_wins(by_id, id, "planner") == 12
