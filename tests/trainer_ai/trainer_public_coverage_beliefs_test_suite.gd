class_name TrainerPublicCoverageBeliefsTestSuite
extends TrainerAdaptiveBranchingTestSuite

const B_WEAK_D := &"limit_b_d_weak"
const COVERAGE_MACHINE := &"coverage_machine_probe"
const COVERAGE_TUTOR := &"coverage_tutor_probe"
const COVERAGE_EGG := &"coverage_egg_probe"
const COVERAGE_SPECIAL := &"coverage_special_probe"
const COVERAGE_INCOMPATIBLE := &"coverage_incompatible_probe"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_public_coverage_prior_contract()
	_test_coverage_slot_is_causal()


func _build_catalog() -> void:
	super._build_catalog()

	# Turn the FASE28 branching nuke into a low-confidence public machine
	# compatibility while adding a fourth high-confidence level-up decoy. The old
	# world factory therefore knows about the nuke in beliefs but prunes it before
	# search; the FASE29 factory must rescue it based on threat without widening caps.
	_add_damage_move(B_WEAK_D, 10)
	var branching_species := _catalog.species(B_REFERENCE_SPECIES)
	if branching_species != null:
		for index in range(branching_species.learnset.size() - 1, -1, -1):
			var raw_entry = branching_species.learnset[index]
			if raw_entry is LearnSetEntry and (raw_entry as LearnSetEntry).move_id == B_NUKE:
				branching_species.learnset.remove_at(index)
		branching_species.learnset.append(
			LearnSetEntry.new(1, B_WEAK_D, LearnsetSystem.LEVEL_UP)
		)
		branching_species.learnset.append(
			LearnSetEntry.new(0, B_NUKE, TrainerPublicCoverageBeliefInference.METHOD_MACHINE)
		)

	# Synthetic compatibility probes exercise all deliberately supported methods and
	# one excluded special method. None of these are the actual hidden nuke used by
	# the hidden-information control scenario.
	_add_damage_move(COVERAGE_MACHINE, 5)
	_add_damage_move(COVERAGE_TUTOR, 5)
	_add_damage_move(COVERAGE_EGG, 5)
	_add_damage_move(COVERAGE_SPECIAL, 5)
	_add_damage_move(COVERAGE_INCOMPATIBLE, 5)
	var hidden_species := _catalog.species(U_REFERENCE_SPECIES)
	if hidden_species != null:
		hidden_species.learnset.append(
			LearnSetEntry.new(0, COVERAGE_MACHINE, TrainerPublicCoverageBeliefInference.METHOD_MACHINE)
		)
		hidden_species.learnset.append(
			LearnSetEntry.new(0, COVERAGE_TUTOR, TrainerPublicCoverageBeliefInference.METHOD_TUTOR)
		)
		hidden_species.learnset.append(
			LearnSetEntry.new(0, COVERAGE_EGG, TrainerPublicCoverageBeliefInference.METHOD_EGG)
		)
		hidden_species.learnset.append(
			LearnSetEntry.new(0, COVERAGE_SPECIAL, "form_change")
		)


func _planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return PublicCoverageAdaptiveTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)


func _search_only_horizon_planner_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	var profile := TrainerProfile.balanced()
	profile.profile_id = &"search_only_horizon_probe"
	profile.setup_weight_bp = 0
	return PublicCoverageAdaptiveTrainerBrain.new(
		catalog,
		profile,
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)


func _test_branching_limit(by_id: Dictionary) -> void:
	super._test_branching_limit(by_id)
	var record := by_id.get("known_fourth_response", {}) as Dictionary
	var planner_result := _first_result(record, "planner_matches")
	var trace_json := JSON.stringify(_first_candidate_trace(planner_result))
	_check.call(
		"coverage_branch_trace_records_prior_model",
		trace_json.contains(TrainerPublicCoverageBeliefInference.COVERAGE_PRIOR_MODEL),
	)
	_check.call(
		"coverage_branch_trace_records_slot_model",
		trace_json.contains(TrainerCoverageAwareWorldFactory.COVERAGE_SELECTION_MODEL),
	)
	_check.call(
		"coverage_branch_machine_nuke_survives_four_move_cap",
		trace_json.contains(String(B_NUKE)),
	)
	_check.call(
		"coverage_branch_fourth_levelup_decoy_not_searched",
		not trace_json.contains(String(B_WEAK_D)),
	)


func _test_public_coverage_prior_contract() -> void:
	var observation := TrainerObservation.new()
	observation.battle_id = &"coverage_prior_probe_battle"
	observation.observer_side_id = &"side_a"
	observation.opponent_side_id = &"side_b"
	observation.own_active_id = &"coverage_own"
	observation.opponent_active_id = &"coverage_probe"
	observation.observed_opponents.append({
		"instance_id": "coverage_probe",
		"species_id": String(U_REFERENCE_SPECIES),
		"level": 30,
		"revealed_move_ids": [],
		"revealed_ability_id": "",
		"revealed_item_id": "",
	})
	var belief := TrainerBeliefState.new()
	var inference := TrainerPublicCoverageBeliefInference.new(_catalog)
	_check.call("coverage_prior_seed_succeeds", inference.seed_from_observation(belief, observation))

	var creature_id := &"coverage_probe"
	_check.call(
		"coverage_levelup_prior_unchanged",
		belief.confidence_basis_points(creature_id, TrainerBeliefState.DOMAIN_MOVE, U_WEAK)
		== TrainerBeliefInference.MOVE_RECENT_PRIOR_BP,
	)
	_check.call(
		"coverage_machine_prior_present",
		belief.confidence_basis_points(creature_id, TrainerBeliefState.DOMAIN_MOVE, COVERAGE_MACHINE)
		== TrainerPublicCoverageBeliefInference.MACHINE_PRIOR_BP,
	)
	_check.call(
		"coverage_tutor_prior_present",
		belief.confidence_basis_points(creature_id, TrainerBeliefState.DOMAIN_MOVE, COVERAGE_TUTOR)
		== TrainerPublicCoverageBeliefInference.TUTOR_PRIOR_BP,
	)
	_check.call(
		"coverage_egg_prior_present",
		belief.confidence_basis_points(creature_id, TrainerBeliefState.DOMAIN_MOVE, COVERAGE_EGG)
		== TrainerPublicCoverageBeliefInference.EGG_PRIOR_BP,
	)
	_check.call(
		"coverage_special_method_excluded",
		belief.confidence_basis_points(creature_id, TrainerBeliefState.DOMAIN_MOVE, COVERAGE_SPECIAL) == 0,
	)
	_check.call(
		"coverage_incompatible_move_absent",
		belief.confidence_basis_points(creature_id, TrainerBeliefState.DOMAIN_MOVE, COVERAGE_INCOMPATIBLE) == 0,
	)
	_check.call(
		"coverage_actual_hidden_incompatible_nuke_absent",
		belief.confidence_basis_points(creature_id, TrainerBeliefState.DOMAIN_MOVE, U_HIDDEN_NUKE) == 0,
	)
	var machine_provenance := belief.provenance_for(
		creature_id,
		TrainerBeliefState.DOMAIN_MOVE,
		COVERAGE_MACHINE,
	)
	_check.call(
		"coverage_machine_provenance_is_public_compatibility",
		machine_provenance.has(
			TrainerPublicCoverageBeliefInference.coverage_provenance(
				TrainerPublicCoverageBeliefInference.METHOD_MACHINE
			)
		),
	)
	var serialized := JSON.stringify(belief.to_dict())
	_check.call("coverage_belief_does_not_claim_version_group", not serialized.contains("version_group"))
	_check.call("coverage_belief_does_not_leak_hidden_nuke", not serialized.contains(String(U_HIDDEN_NUKE)))


func _test_coverage_slot_is_causal() -> void:
	var branch_scenario: Dictionary = {}
	for scenario in _scenarios():
		if String(scenario.get("id", "")) == "known_fourth_response":
			branch_scenario = scenario
			break
	_check.call("coverage_ab_branch_scenario_found", not branch_scenario.is_empty())
	if branch_scenario.is_empty():
		return
	var scenarios: Array[Dictionary] = [branch_scenario]
	var legacy := TrainerSearchLimitBenchmark.run(
		_catalog,
		scenarios,
		Callable(self, "_legacy_adaptive_factory"),
	)
	var legacy_map := _scenario_map(legacy.get("scenarios", []) as Array)
	var record := legacy_map.get("known_fourth_response", {}) as Dictionary
	var planner := record.get("planner", {}) as Dictionary
	_check.call(
		"coverage_ab_fase28_loses_when_coverage_is_pruned",
		int(planner.get("wins", -1)) == 0 and int(planner.get("losses", -1)) == 6,
	)
	var result := _first_result(record, "planner_matches")
	var trace_json := JSON.stringify(_first_candidate_trace(result))
	_check.call(
		"coverage_ab_fase28_belief_alone_does_not_reach_search",
		not trace_json.contains(String(B_NUKE)),
	)


func _legacy_adaptive_factory(catalog: DefinitionCatalog) -> TrainerBrain:
	return AdaptiveBranchingTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)
