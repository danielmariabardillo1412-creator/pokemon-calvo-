class_name TrainerSelfPlayEvaluationTestSuite
extends RefCounted

const GREEDY_MOVE := &"selfplay_greedy_hit"
const SETUP_MOVE := &"selfplay_agility_focus"
const HEAVY_MOVE := &"selfplay_heavy_hit"
const CANDIDATE_SPECIES := &"selfplay_candidate_species"
const REFERENCE_SPECIES := &"selfplay_reference_species"

var _check: Callable
var _catalog := DefinitionCatalog.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_build_catalog()
	var tests := [
		"_test_baseline_full_match_loses_horizon_race",
		"_test_planner_full_match_wins_horizon_race",
		"_test_planner_mirror_is_side_neutral",
		"_test_match_runner_is_deterministic_and_input_isolated",
		"_test_paired_evaluation_detects_empirical_improvement",
		"_test_blunder_analyzer_records_only_objective_signatures",
	]
	for test_name in tests:
		print("TRAINER_SELF_PLAY_TEST %s" % test_name)
		self.call(test_name)


func _build_catalog() -> void:
	var normal := TypeDefinition.new("Normal")
	normal.id = &"normal"
	_catalog.add_type(normal)
	_check.call("selfplay_fixture_normal_type_available", _catalog.type(&"normal") != null)

	_add_damage_move(GREEDY_MOVE, 80, 0, 20)
	_add_setup_move()
	_add_damage_move(HEAVY_MOVE, 85, 0, 20)

	var candidate := _species(CANDIDATE_SPECIES, 50, 220, 50, 10, 50)
	candidate.learnset.append(LearnSetEntry.new(1, GREEDY_MOVE, LearnsetSystem.LEVEL_UP))
	candidate.learnset.append(LearnSetEntry.new(1, SETUP_MOVE, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(candidate)

	# Keep the actual speed 90 inside the public species/level speed envelope. The AI
	# may infer that this species is fast; it still never receives the hidden exact 90.
	var reference := _species(REFERENCE_SPECIES, 50, 120, 80, 100, 70)
	reference.learnset.append(LearnSetEntry.new(1, HEAVY_MOVE, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(reference)
	_check.call("selfplay_fixture_setup_has_two_effects", _catalog.move(SETUP_MOVE).effect_specs.size() == 2)


func _test_baseline_full_match_loses_horizon_race() -> void:
	var candidate := _candidate_roster()
	var reference := _reference_roster()
	var initial_candidate := JSON.stringify(candidate[0].to_dict())
	var initial_reference := JSON.stringify(reference[0].to_dict())
	var runner := TrainerSelfPlayMatch.new(6)
	var result := runner.run(
		_catalog,
		candidate,
		SearchTrainerBrain.new(_catalog, TrainerProfile.balanced()),
		reference,
		TacticalTrainerBrain.new(_catalog, TrainerProfile.balanced()),
		101,
		&"selfplay_baseline_single",
	)
	_check.call("selfplay_baseline_match_ok", bool(result.get("ok", false)))
	_check.call("selfplay_baseline_match_completed", String(result.get("termination", "")) == TrainerSelfPlayMatch.COMPLETED)
	_check.call("selfplay_baseline_reference_wins", String(result.get("winner_side_id", "")) == "side_b")
	_check.call("selfplay_baseline_finishes_in_two_turns", int(result.get("turn_count", 0)) == 2)
	var turns := result.get("turns", []) as Array
	_check.call("selfplay_baseline_has_two_turn_records", turns.size() == 2)
	if turns.size() >= 2:
		var first := turns[0] as Dictionary
		var second := turns[1] as Dictionary
		_check.call("selfplay_baseline_first_action_is_greedy", String((first.get("side_a_action", {}) as Dictionary).get("move_id", "")) == String(GREEDY_MOVE))
		_check.call("selfplay_baseline_second_turn_reference_acts", _events_contain_move(second.get("events", []) as Array, HEAVY_MOVE))
		_check.call("selfplay_baseline_trace_recorded", not (first.get("side_a_trace", {}) as Dictionary).is_empty())
	else:
		_check.call("selfplay_baseline_first_action_is_greedy", false)
		_check.call("selfplay_baseline_second_turn_reference_acts", false)
		_check.call("selfplay_baseline_trace_recorded", false)
	_check.call("selfplay_baseline_no_rejection_signature", _blunder_count(result, TrainerBlunderAnalyzer.ACTION_REJECTED) == 0)
	_check.call("selfplay_baseline_candidate_input_unchanged", JSON.stringify(candidate[0].to_dict()) == initial_candidate)
	_check.call("selfplay_baseline_reference_input_unchanged", JSON.stringify(reference[0].to_dict()) == initial_reference)


func _test_planner_full_match_wins_horizon_race() -> void:
	var runner := TrainerSelfPlayMatch.new(6)
	var result := runner.run(
		_catalog,
		_candidate_roster(),
		_planner_factory(_catalog),
		_reference_roster(),
		_reference_factory(_catalog),
		202,
		&"selfplay_planner_single",
	)
	_check.call("selfplay_planner_match_ok", bool(result.get("ok", false)))
	_check.call("selfplay_planner_match_completed", String(result.get("termination", "")) == TrainerSelfPlayMatch.COMPLETED)
	_check.call("selfplay_planner_candidate_wins", String(result.get("winner_side_id", "")) == "side_a")
	_check.call("selfplay_planner_finishes_in_two_turns", int(result.get("turn_count", 0)) == 2)
	var turns := result.get("turns", []) as Array
	_check.call("selfplay_planner_has_two_turn_records", turns.size() == 2)
	if turns.size() >= 2:
		var first := turns[0] as Dictionary
		var second := turns[1] as Dictionary
		_check.call("selfplay_planner_opens_with_setup", String((first.get("side_a_action", {}) as Dictionary).get("move_id", "")) == String(SETUP_MOVE))
		_check.call("selfplay_planner_turn_two_uses_greedy", String((second.get("side_a_action", {}) as Dictionary).get("move_id", "")) == String(GREEDY_MOVE))
		var trace_json := JSON.stringify(first.get("side_a_trace", {}))
		_check.call("selfplay_planner_trace_uses_depth_model", trace_json.contains(TrainerMultiTurnSearch.SEARCH_MODEL_ID))
	else:
		_check.call("selfplay_planner_opens_with_setup", false)
		_check.call("selfplay_planner_turn_two_uses_greedy", false)
		_check.call("selfplay_planner_trace_uses_depth_model", false)
	_check.call("selfplay_planner_no_rejection_signature", _blunder_count(result, TrainerBlunderAnalyzer.ACTION_REJECTED) == 0)
	_check.call("selfplay_planner_no_null_decision", _blunder_count(result, TrainerBlunderAnalyzer.DECISION_NULL) == 0)


func _test_planner_mirror_is_side_neutral() -> void:
	var runner := TrainerSelfPlayMatch.new(6)
	var result := runner.run(
		_catalog,
		_reference_roster(),
		_reference_factory(_catalog),
		_candidate_roster(),
		_planner_factory(_catalog),
		303,
		&"selfplay_planner_mirror",
	)
	_check.call("selfplay_mirror_match_ok", bool(result.get("ok", false)))
	_check.call("selfplay_mirror_candidate_side_b_wins", String(result.get("winner_side_id", "")) == "side_b")
	var turns := result.get("turns", []) as Array
	if not turns.is_empty():
		var first := turns[0] as Dictionary
		_check.call("selfplay_mirror_candidate_opens_setup", String((first.get("side_b_action", {}) as Dictionary).get("move_id", "")) == String(SETUP_MOVE))
		_check.call("selfplay_mirror_candidate_trace_recorded", not (first.get("side_b_trace", {}) as Dictionary).is_empty())
	else:
		_check.call("selfplay_mirror_candidate_opens_setup", false)
		_check.call("selfplay_mirror_candidate_trace_recorded", false)


func _test_match_runner_is_deterministic_and_input_isolated() -> void:
	var candidate := _candidate_roster()
	var reference := _reference_roster()
	var before_candidate := JSON.stringify(candidate[0].to_dict())
	var before_reference := JSON.stringify(reference[0].to_dict())
	var runner := TrainerSelfPlayMatch.new(6)
	var first := runner.run(
		_catalog,
		candidate,
		_planner_factory(_catalog),
		reference,
		_reference_factory(_catalog),
		404,
		&"selfplay_deterministic",
	)
	var second := runner.run(
		_catalog,
		candidate,
		_planner_factory(_catalog),
		reference,
		_reference_factory(_catalog),
		404,
		&"selfplay_deterministic",
	)
	_check.call("selfplay_match_deterministic", JSON.stringify(first) == JSON.stringify(second))
	_check.call("selfplay_match_candidate_roster_isolated", JSON.stringify(candidate[0].to_dict()) == before_candidate)
	_check.call("selfplay_match_reference_roster_isolated", JSON.stringify(reference[0].to_dict()) == before_reference)
	_check.call("selfplay_match_records_authoritative_events", _total_event_count(first) > 0)
	_check.call("selfplay_match_has_no_action_rejection", not JSON.stringify(first.get("turns", [])).contains("action_rejected"))


func _test_paired_evaluation_detects_empirical_improvement() -> void:
	var seeds: Array[int] = [101, 202, 303]
	var first := TrainerSelfPlayEvaluation.compare_against_reference(
		_catalog,
		_candidate_roster(),
		_reference_roster(),
		Callable(self, "_baseline_factory"),
		Callable(self, "_planner_factory"),
		Callable(self, "_reference_factory"),
		seeds,
		6,
	)
	var second := TrainerSelfPlayEvaluation.compare_against_reference(
		_catalog,
		_candidate_roster(),
		_reference_roster(),
		Callable(self, "_baseline_factory"),
		Callable(self, "_planner_factory"),
		Callable(self, "_reference_factory"),
		seeds,
		6,
	)
	var baseline := first.get("baseline", {}) as Dictionary
	var planner := first.get("planner", {}) as Dictionary
	_check.call("selfplay_eval_model_id", String(first.get("evaluation_model", "")) == "paired_mirrored_reference_v1")
	_check.call("selfplay_eval_three_seeds", int(first.get("seed_count", 0)) == 3)
	_check.call("selfplay_eval_six_matches_per_candidate", int(first.get("matches_per_candidate", 0)) == 6)
	_check.call("selfplay_eval_baseline_loses_all", int(baseline.get("wins", -1)) == 0 and int(baseline.get("losses", -1)) == 6)
	_check.call("selfplay_eval_planner_wins_all", int(planner.get("wins", -1)) == 6 and int(planner.get("losses", -1)) == 0)
	_check.call("selfplay_eval_no_invalid_matches", int(baseline.get("invalid", -1)) == 0 and int(planner.get("invalid", -1)) == 0)
	_check.call("selfplay_eval_records_six_improvements", int(first.get("paired_improvements", 0)) == 6)
	_check.call("selfplay_eval_records_zero_regressions", int(first.get("paired_regressions", -1)) == 0)
	_check.call("selfplay_eval_signature_present", not String(first.get("signature", "")).is_empty())
	_check.call("selfplay_eval_deterministic", JSON.stringify(first) == JSON.stringify(second))


func _test_blunder_analyzer_records_only_objective_signatures() -> void:
	var analyzer := TrainerBlunderAnalyzer.new()
	var action := BattleAction.new(1, &"actor", GREEDY_MOVE, &"target", BattleAction.MOVE, &"side_a")
	var trace := TrainerDecisionTrace.new()
	trace.add_candidate(
		action,
		&"test",
		0,
		10000,
		[],
		{"tactical": {"type_effectiveness_basis_points": 0}},
	)
	trace.select(action, "test")
	analyzer.inspect_decision(&"side_a", action, trace, 1)
	analyzer.inspect_decision(&"side_b", null, null, 1)
	var rejection: Array[BattleEvent] = [BattleEvent.new(
		BattleEvent.ACTION_REJECTED,
		1,
		&"",
		&"",
		&"",
		0,
		{"reason": "test_rejection"},
	)]
	analyzer.inspect_events(rejection, 1)
	analyzer.mark_turn_limit(4)
	var report := analyzer.report()
	_check.call("selfplay_blunder_known_immunity_recorded", analyzer.count(TrainerBlunderAnalyzer.SELECTED_KNOWN_IMMUNITY) == 1)
	_check.call("selfplay_blunder_null_decision_recorded", analyzer.count(TrainerBlunderAnalyzer.DECISION_NULL) == 1)
	_check.call("selfplay_blunder_rejection_recorded", analyzer.count(TrainerBlunderAnalyzer.ACTION_REJECTED) == 1)
	_check.call("selfplay_blunder_turn_limit_recorded", analyzer.count(TrainerBlunderAnalyzer.TURN_LIMIT) == 1)
	_check.call("selfplay_blunder_report_serializable", not JSON.stringify(report).is_empty())
	_check.call("selfplay_blunder_no_unearned_stall_label", analyzer.count(TrainerBlunderAnalyzer.NO_PROGRESS_WINDOW) == 0)


func _baseline_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return SearchTrainerBrain.new(catalog, TrainerProfile.balanced())


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return DepthSearchTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 32, 3),
	)


func _reference_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return TacticalTrainerBrain.new(catalog, TrainerProfile.balanced())


func _candidate_roster() -> Array[CreatureInstance]:
	var creature := CreatureInstance.new(
		&"selfplay_candidate",
		CANDIDATE_SPECIES,
		30,
		StatBlock.new(110, 250, 80, 40, 80, 80),
		[GREEDY_MOVE, SETUP_MOVE],
	)
	creature.initialize_move_pp(_catalog)
	var out: Array[CreatureInstance] = [creature]
	return out


func _reference_roster() -> Array[CreatureInstance]:
	var creature := CreatureInstance.new(
		&"selfplay_reference",
		REFERENCE_SPECIES,
		30,
		StatBlock.new(110, 150, 110, 90, 100, 100),
		[HEAVY_MOVE],
	)
	creature.initialize_move_pp(_catalog)
	var out: Array[CreatureInstance] = [creature]
	return out


func _species(
	id: StringName,
	hp: int,
	attack: int,
	defense: int,
	speed: int,
	special: int,
) -> CreatureSpecies:
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
	species.base_special_attack = special
	species.base_special_defense = special
	return species


func _add_damage_move(id: StringName, power: int, priority: int, pp: int) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.power = power
	move.type_id = &"normal"
	move.priority = priority
	move.damage_class = "physical"
	move.accuracy = 100
	move.pp = pp
	_catalog.add_move(move)


func _add_setup_move() -> void:
	var move := MoveDefinition.new()
	move.id = SETUP_MOVE
	move.display_name = String(SETUP_MOVE)
	move.power = 0
	move.type_id = &"normal"
	move.priority = 0
	move.damage_class = "status"
	move.accuracy = 100
	move.pp = 1
	move.effect_specs.append(BattleEffectSpec.new(
		BattleEffectSpec.MODIFY_STAT_STAGE,
		BattleEffectSpec.SELF,
		4,
		0,
		10000,
		&"",
		StatStages.SPEED,
	))
	move.effect_specs.append(BattleEffectSpec.new(
		BattleEffectSpec.MODIFY_STAT_STAGE,
		BattleEffectSpec.SELF,
		2,
		0,
		10000,
		&"",
		StatStages.ATTACK,
	))
	_catalog.add_move(move)


func _events_contain_move(events: Array, move_id: StringName) -> bool:
	for value in events:
		var event := value as Dictionary
		if String(event.get("move_id", "")) == String(move_id):
			return true
	return false


func _blunder_count(result: Dictionary, signature_id: String) -> int:
	var report := result.get("blunders", {}) as Dictionary
	var counts := report.get("counts", {}) as Dictionary
	return int(counts.get(signature_id, 0))


func _total_event_count(result: Dictionary) -> int:
	var total := 0
	for turn_value in result.get("turns", []):
		var turn := turn_value as Dictionary
		total += (turn.get("events", []) as Array).size()
	return total
