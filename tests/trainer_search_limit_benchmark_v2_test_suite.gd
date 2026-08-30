class_name TrainerSearchLimitBenchmarkV2TestSuite
extends RefCounted

const H_SPEED_SETUP := &"limit_h_speed_then_focus"
const H_ATTACK_SETUP := &"limit_h_focus"
const H_STRIKE := &"limit_h_strike"
const H_CHIP := &"limit_h_chip"

const B_STRIKE := &"limit_b_strike"
const B_DEBUFF := &"limit_b_attack_break"
const B_WEAK_A := &"limit_b_a_weak"
const B_WEAK_B := &"limit_b_b_weak"
const B_WEAK_C := &"limit_b_c_weak"
const B_NUKE := &"limit_b_z_nuke"

const U_STRIKE := &"limit_u_strike"
const U_WEAK := &"limit_u_public_weak"
const U_HIDDEN_NUKE := &"limit_u_hidden_nuke"

const H_CANDIDATE_SPECIES := &"limit_h_candidate_species"
const H_REFERENCE_SPECIES := &"limit_h_reference_species"
const B_CANDIDATE_SPECIES := &"limit_b_candidate_species"
const B_REFERENCE_SPECIES := &"limit_b_reference_species"
const U_CANDIDATE_SPECIES := &"limit_u_candidate_species"
const U_REFERENCE_SPECIES := &"limit_u_reference_species"

var _check: Callable
var _catalog := DefinitionCatalog.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_build_catalog()
	_test_contract()
	_test_benchmark()


func _build_catalog() -> void:
	var normal := TypeDefinition.new("Normal")
	normal.id = &"normal"
	_catalog.add_type(normal)

	_add_setup_move(H_SPEED_SETUP, [
		BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.SELF, 4, 0, 10000, &"", StatStages.SPEED),
		BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.SELF, 1, 0, 10000, &"", StatStages.ATTACK),
	])
	_add_setup_move(H_ATTACK_SETUP, [
		BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.SELF, 3, 0, 10000, &"", StatStages.ATTACK),
	])
	_add_damage_move(H_STRIKE, 90)
	_add_damage_move(H_CHIP, 70)

	_add_damage_move(B_STRIKE, 100)
	_add_setup_move(B_DEBUFF, [
		BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.OPPONENT, -6, 0, 10000, &"", StatStages.ATTACK),
	])
	_add_damage_move(B_WEAK_A, 10)
	_add_damage_move(B_WEAK_B, 10)
	_add_damage_move(B_WEAK_C, 10)
	_add_damage_move(B_NUKE, 120)

	_add_damage_move(U_STRIKE, 100)
	_add_damage_move(U_WEAK, 10)
	_add_damage_move(U_HIDDEN_NUKE, 120)

	_add_species(H_CANDIDATE_SPECIES, 40, 90, 70, 10, [H_SPEED_SETUP, H_ATTACK_SETUP, H_STRIKE])
	_add_species(H_REFERENCE_SPECIES, 56, 110, 70, 100, [H_CHIP])
	_add_species(B_CANDIDATE_SPECIES, 40, 130, 50, 70, [B_STRIKE, B_DEBUFF])
	_add_species(B_REFERENCE_SPECIES, 50, 170, 70, 60, [B_WEAK_A, B_WEAK_B, B_WEAK_C, B_NUKE])
	_add_species(U_CANDIDATE_SPECIES, 40, 130, 50, 70, [U_STRIKE])
	# Hidden coverage is real in the live moveset but deliberately absent from public level-up data.
	_add_species(U_REFERENCE_SPECIES, 50, 170, 70, 60, [U_WEAK])

	_check.call("limit_v2_normal_type_available", _catalog.type(&"normal") != null)
	_check.call("limit_v2_branch_nuke_is_public_prior", _species_learnset_has(B_REFERENCE_SPECIES, B_NUKE))
	_check.call("limit_v2_hidden_nuke_not_public_prior", not _species_learnset_has(U_REFERENCE_SPECIES, U_HIDDEN_NUKE))


func _test_contract() -> void:
	var scenarios := _scenarios()
	var families: Dictionary = {}
	var planner_matches := 0
	var oracle_matches := 0
	for scenario in scenarios:
		families[String(scenario.get("family", ""))] = true
		var matches := (scenario.get("seeds", []) as Array).size() * 2
		planner_matches += matches
		var oracle_factory := scenario.get("oracle_factory", Callable()) as Callable
		if oracle_factory.is_valid():
			oracle_matches += matches
	_check.call("limit_v2_has_four_scenarios", scenarios.size() == 4)
	_check.call("limit_v2_has_four_distinct_families", families.size() == 4)
	_check.call("limit_v2_runs_24_planner_matches", planner_matches == 24)
	_check.call("limit_v2_runs_12_oracle_matches", oracle_matches == 12)


func _test_benchmark() -> void:
	var first := TrainerSearchLimitBenchmark.run(
		_catalog,
		_scenarios(),
		Callable(self, "_planner_factory"),
	)
	var second := TrainerSearchLimitBenchmark.run(
		_catalog,
		_scenarios(),
		Callable(self, "_planner_factory"),
	)
	var totals := first.get("totals", {}) as Dictionary
	_check.call("limit_v2_model_id", String(first.get("evaluation_model", "")) == TrainerSearchLimitBenchmark.MODEL_ID)
	_check.call("limit_v2_reports_four_scenarios", int(first.get("scenario_count", 0)) == 4)
	_check.call("limit_v2_planner_has_24_matches", int(totals.get("planner_matches", 0)) == 24)
	_check.call("limit_v2_oracle_has_12_matches", int(totals.get("oracle_matches", 0)) == 12)
	_check.call("limit_v2_no_planner_invalid", int(totals.get("planner_invalid", -1)) == 0)
	_check.call("limit_v2_no_oracle_invalid", int(totals.get("oracle_invalid", -1)) == 0)
	_check.call("limit_v2_signature_present", not String(first.get("signature", "")).is_empty())
	_check.call("limit_v2_is_deterministic", JSON.stringify(first) == JSON.stringify(second))

	var by_id := _scenario_map(first.get("scenarios", []) as Array)
	_test_receding_horizon_control(by_id)
	_test_isolated_horizon_limit(by_id)
	_test_branching_limit(by_id)
	_test_hidden_information_limit(by_id)


func _test_receding_horizon_control(by_id: Dictionary) -> void:
	var record := by_id.get("three_turn_replanning_control", {}) as Dictionary
	var planner := record.get("planner", {}) as Dictionary
	_check.call("limit_replan_control_planner_wins_all", int(planner.get("wins", -1)) == 6 and int(planner.get("losses", -1)) == 0)
	_check.call("limit_replan_control_has_no_oracle", not bool(record.get("oracle_available", true)))
	var result := _first_result(record, "planner_matches")
	_check.call("limit_replan_control_opens_focus", _candidate_move_at(result, 0) == H_ATTACK_SETUP)
	_check.call("limit_replan_control_speed_setup_second", _candidate_move_at(result, 1) == H_SPEED_SETUP)
	_check.call("limit_replan_control_strikes_third", _candidate_move_at(result, 2) == H_STRIKE)
	_check.call("limit_replan_control_finishes_in_three_turns", int(result.get("turn_count", 0)) == 3)
	var trace_json := JSON.stringify(_first_candidate_trace(result))
	_check.call("limit_replan_control_depth_two_complete", trace_json.contains("\"fully_completed_depth\":2"))
	_check.call("limit_replan_control_not_budget_exhausted", trace_json.contains("\"budget_exhausted\":false"))


func _test_isolated_horizon_limit(by_id: Dictionary) -> void:
	var record := by_id.get("isolated_three_turn_horizon", {}) as Dictionary
	var planner := record.get("planner", {}) as Dictionary
	var oracle := record.get("oracle", {}) as Dictionary
	_check.call("limit_horizon_isolated_planner_loses_all", int(planner.get("wins", -1)) == 0 and int(planner.get("losses", -1)) == 6)
	_check.call("limit_horizon_isolated_oracle_wins_all", int(oracle.get("wins", -1)) == 6 and int(oracle.get("losses", -1)) == 0)
	var planner_result := _first_result(record, "planner_matches")
	var oracle_result := _first_result(record, "oracle_matches")
	_check.call("limit_horizon_isolated_planner_opens_damage", _candidate_move_at(planner_result, 0) == H_STRIKE)
	_check.call("limit_horizon_isolated_oracle_opens_speed_setup", _candidate_move_at(oracle_result, 0) == H_SPEED_SETUP)
	_check.call("limit_horizon_isolated_oracle_focus_second", _candidate_move_at(oracle_result, 1) == H_ATTACK_SETUP)
	_check.call("limit_horizon_isolated_oracle_strikes_third", _candidate_move_at(oracle_result, 2) == H_STRIKE)
	var trace := _first_candidate_trace(planner_result)
	var trace_json := JSON.stringify(trace)
	_check.call("limit_horizon_isolated_uses_probe_profile", String(trace.get("profile_id", "")) == "search_only_horizon_probe")
	_check.call("limit_horizon_isolated_depth_two_complete", trace_json.contains("\"fully_completed_depth\":2"))
	_check.call("limit_horizon_isolated_not_budget_exhausted", trace_json.contains("\"budget_exhausted\":false"))


func _test_branching_limit(by_id: Dictionary) -> void:
	var record := by_id.get("known_fourth_response", {}) as Dictionary
	var planner := record.get("planner", {}) as Dictionary
	var oracle := record.get("oracle", {}) as Dictionary
	_check.call("limit_branch_planner_loses_all", int(planner.get("wins", -1)) == 0 and int(planner.get("losses", -1)) == 6)
	_check.call("limit_branch_oracle_wins_all", int(oracle.get("wins", -1)) == 6 and int(oracle.get("losses", -1)) == 0)
	var planner_result := _first_result(record, "planner_matches")
	var oracle_result := _first_result(record, "oracle_matches")
	_check.call("limit_branch_planner_opens_strike", _candidate_move_at(planner_result, 0) == B_STRIKE)
	_check.call("limit_branch_oracle_opens_debuff", _candidate_move_at(oracle_result, 0) == B_DEBUFF)
	_check.call("limit_branch_actual_reference_uses_nuke", _first_events_contain_move(planner_result, B_NUKE))
	var trace_json := JSON.stringify(_first_candidate_trace(planner_result))
	_check.call("limit_branch_trace_omits_fourth_nuke", not trace_json.contains(String(B_NUKE)))
	_check.call("limit_branch_trace_records_action_cap_three", trace_json.contains("\"max_actions_per_side\":3"))
	_check.call("limit_branch_search_not_simulation_exhausted", trace_json.contains("\"budget_exhausted\":false"))


func _test_hidden_information_limit(by_id: Dictionary) -> void:
	var record := by_id.get("unmodeled_hidden_coverage", {}) as Dictionary
	var planner := record.get("planner", {}) as Dictionary
	_check.call("limit_hidden_planner_loses_all", int(planner.get("wins", -1)) == 0 and int(planner.get("losses", -1)) == 6)
	_check.call("limit_hidden_has_no_oracle", not bool(record.get("oracle_available", true)))
	var result := _first_result(record, "planner_matches")
	_check.call("limit_hidden_planner_opens_strike", _candidate_move_at(result, 0) == U_STRIKE)
	_check.call("limit_hidden_actual_reference_reveals_nuke", _first_events_contain_move(result, U_HIDDEN_NUKE))
	var trace_json := JSON.stringify(_first_candidate_trace(result))
	_check.call("limit_hidden_trace_does_not_cheat", not trace_json.contains(String(U_HIDDEN_NUKE)))
	_check.call("limit_hidden_search_not_budget_exhausted", trace_json.contains("\"budget_exhausted\":false"))


func _scenarios() -> Array[Dictionary]:
	var seeds: Array[int] = [101, 202, 303]
	return [
		{
			"id": "three_turn_replanning_control",
			"family": "receding_horizon_positive_control",
			"expected_limit": "depth_two_can_chain_three_turn_plan_via_replanning",
			"candidate_roster": _horizon_candidate(),
			"reference_roster": _horizon_reference(),
			"reference_factory": Callable(self, "_reference_factory"),
			"seeds": seeds.duplicate(),
			"max_turns": 6,
		},
		{
			"id": "isolated_three_turn_horizon",
			"family": "horizon_beyond_depth_two_without_tactical_setup_prior",
			"expected_limit": "depth_turns_cap_2",
			"candidate_roster": _horizon_candidate(),
			"reference_roster": _horizon_reference(),
			"reference_factory": Callable(self, "_reference_factory"),
			"planner_factory": Callable(self, "_search_only_horizon_planner_factory"),
			"oracle_factory": Callable(self, "_horizon_oracle_factory"),
			"seeds": seeds.duplicate(),
			"max_turns": 6,
		},
		{
			"id": "known_fourth_response",
			"family": "known_response_branching_cap",
			"expected_limit": "max_actions_per_side_3",
			"candidate_roster": _branch_candidate(),
			"reference_roster": _branch_reference(),
			"reference_factory": Callable(self, "_reference_factory"),
			"oracle_factory": Callable(self, "_branch_oracle_factory"),
			"seeds": seeds.duplicate(),
			"max_turns": 6,
		},
		{
			"id": "unmodeled_hidden_coverage",
			"family": "legitimate_hidden_information_surprise",
			"expected_limit": "public_prior_does_not_include_non_learnset_move",
			"candidate_roster": _hidden_candidate(),
			"reference_roster": _hidden_reference(),
			"reference_factory": Callable(self, "_reference_factory"),
			"seeds": seeds.duplicate(),
			"max_turns": 4,
		},
	]


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return DepthSearchTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)


func _search_only_horizon_planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	var profile := TrainerProfile.balanced()
	profile.profile_id = &"search_only_horizon_probe"
	# Diagnostic isolation only: removes immediate tactical reward for stat setup.
	# Search rules, depth, legal actions and information boundaries remain unchanged.
	profile.setup_weight_bp = 0
	return DepthSearchTrainerBrain.new(
		catalog,
		profile,
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)


func _reference_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return TacticalTrainerBrain.new(catalog, TrainerProfile.balanced())


func _horizon_oracle_factory(_catalog_arg: DefinitionCatalog) -> TrainerBrain:
	return TrainerSequenceProbeBrain.new([
		{"kind": "move", "move_id": String(H_SPEED_SETUP)},
		{"kind": "move", "move_id": String(H_ATTACK_SETUP)},
		{"kind": "move", "move_id": String(H_STRIKE)},
	])


func _branch_oracle_factory(_catalog_arg: DefinitionCatalog) -> TrainerBrain:
	return TrainerSequenceProbeBrain.new([
		{"kind": "move", "move_id": String(B_DEBUFF)},
		{"kind": "move", "move_id": String(B_STRIKE)},
		{"kind": "move", "move_id": String(B_STRIKE)},
	])


func _horizon_candidate() -> Array[CreatureInstance]:
	return _roster(&"limit_h_candidate", H_CANDIDATE_SPECIES, StatBlock.new(100, 120, 100, 40, 80, 80), [H_SPEED_SETUP, H_ATTACK_SETUP, H_STRIKE])


func _horizon_reference() -> Array[CreatureInstance]:
	return _roster(&"limit_h_reference", H_REFERENCE_SPECIES, StatBlock.new(116, 140, 100, 90, 80, 80), [H_CHIP])


func _branch_candidate() -> Array[CreatureInstance]:
	return _roster(&"limit_b_candidate", B_CANDIDATE_SPECIES, StatBlock.new(100, 160, 80, 100, 80, 80), [B_STRIKE, B_DEBUFF])


func _branch_reference() -> Array[CreatureInstance]:
	return _roster(&"limit_b_reference", B_REFERENCE_SPECIES, StatBlock.new(110, 200, 100, 70, 80, 80), [B_WEAK_A, B_WEAK_B, B_WEAK_C, B_NUKE])


func _hidden_candidate() -> Array[CreatureInstance]:
	return _roster(&"limit_u_candidate", U_CANDIDATE_SPECIES, StatBlock.new(100, 160, 80, 100, 80, 80), [U_STRIKE])


func _hidden_reference() -> Array[CreatureInstance]:
	return _roster(&"limit_u_reference", U_REFERENCE_SPECIES, StatBlock.new(110, 200, 100, 70, 80, 80), [U_WEAK, U_HIDDEN_NUKE])


func _roster(instance_id: StringName, species_id: StringName, stats: StatBlock, moves: Array[StringName]) -> Array[CreatureInstance]:
	var creature := CreatureInstance.new(instance_id, species_id, 30, stats, moves)
	creature.initialize_move_pp(_catalog)
	var out: Array[CreatureInstance] = [creature]
	return out


func _add_species(id: StringName, hp: int, attack: int, defense: int, speed: int, moves: Array[StringName]) -> void:
	var species := CreatureSpecies.new()
	species.id = id
	species.display_name = String(id)
	species.primary_type_id = &"normal"
	var types: Array[StringName] = [&"normal"]
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


func _add_damage_move(id: StringName, power: int) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.power = power
	move.type_id = &"normal"
	move.damage_class = "physical"
	move.accuracy = 100
	move.pp = 20
	move.crit_rate_bp = -10000
	_catalog.add_move(move)


func _add_setup_move(id: StringName, effects: Array[BattleEffectSpec]) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.power = 0
	move.type_id = &"normal"
	move.damage_class = "status"
	move.accuracy = 100
	move.pp = 20
	move.crit_rate_bp = -10000
	for effect in effects:
		move.effect_specs.append(effect)
	_catalog.add_move(move)


func _species_learnset_has(species_id: StringName, move_id: StringName) -> bool:
	var species := _catalog.species(species_id)
	if species == null:
		return false
	for raw_entry in species.learnset:
		if raw_entry is LearnSetEntry and (raw_entry as LearnSetEntry).move_id == move_id:
			return true
	return false


func _scenario_map(records: Array) -> Dictionary:
	var out: Dictionary = {}
	for value in records:
		var record := value as Dictionary
		out[String(record.get("id", ""))] = record
	return out


func _first_result(record: Dictionary, match_key: String) -> Dictionary:
	var matches := record.get(match_key, []) as Array
	if matches.is_empty():
		return {}
	return (matches[0] as Dictionary).get("result", {}) as Dictionary


func _candidate_move_at(result: Dictionary, turn_index: int) -> StringName:
	var turns := result.get("turns", []) as Array
	if turn_index < 0 or turn_index >= turns.size():
		return &""
	var action := (turns[turn_index] as Dictionary).get("side_a_action", {}) as Dictionary
	return StringName(action.get("move_id", ""))


func _first_candidate_trace(result: Dictionary) -> Dictionary:
	var turns := result.get("turns", []) as Array
	if turns.is_empty():
		return {}
	return (turns[0] as Dictionary).get("side_a_trace", {}) as Dictionary


func _first_events_contain_move(result: Dictionary, move_id: StringName) -> bool:
	var turns := result.get("turns", []) as Array
	if turns.is_empty():
		return false
	for raw_event in (turns[0] as Dictionary).get("events", []):
		var event := raw_event as Dictionary
		if StringName(event.get("move_id", "")) == move_id:
			return true
	return false
