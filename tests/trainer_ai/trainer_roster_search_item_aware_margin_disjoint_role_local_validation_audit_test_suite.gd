class_name TrainerRosterSearchItemAwareMarginDisjointRoleLocalValidationAuditTestSuite
extends TrainerRosterSearchItemAwareDepth1SwitchScorePortabilityAuditTestSuite

# C3f-ad is strictly TEST/AUDIT-ONLY. It revalidates the SWITCH-only margin3000
# candidate policy on a deterministic role-local ItemAware corpus disjoint from
# C3f-ac and from the historical real-data selection/interpretation corpora.
# Every SWITCH score is recomputed with TrainerItemAwareSearch in the case's
# sanitized role-local context; no historical/base score is reused for behavior.

const AUDIT_ID_C3FAD := "c3f_ad_item_aware_margin_disjoint_role_local_validation_audit_v1"
const BOUNDARY_ID_C3FAD := "revalidate_margin3000_item_aware_candidate_preservation_on_disjoint_role_local_corpus_before_any_production_adapter"

const SAFE_DISJOINT_TEST_CORPUS := "SAFE_DISJOINT_TEST_CORPUS"
const NEEDS_POLICY_CHANGE_C3FAD := "NEEDS_POLICY_CHANGE"
const NEEDS_MORE_VALIDATION_C3FAD := "NEEDS_MORE_VALIDATION"
const BLOCKED_C3FAD := "BLOCKED"

const CORPUS_ID_C3FAD := "synthetic_role_local_itemaware_disjoint_v1"
const FIXTURE_COUNT_C3FAD := 3
const ROLE_CASE_COUNT_C3FAD := 9
const SIDE_A_C3FAD := &"side_a"
const SIDE_B_C3FAD := &"side_b"

const SETUP_A_C3FAD := &"c3fad_setup_a"
const SETUP_B_C3FAD := &"c3fad_setup_b"
const CHIP_A_C3FAD := &"c3fad_chip_a"
const CHIP_B_C3FAD := &"c3fad_chip_b"
const SPECIES_A_C3FAD := &"c3fad_species_a"
const SPECIES_B_C3FAD := &"c3fad_species_b"
const POTION_C3FAD := &"potion"
const HYPER_POTION_C3FAD := &"hyper_potion"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_item_aware_margin_disjoint_role_local_validation()


func _test_item_aware_margin_disjoint_role_local_validation() -> void:
	var report_a := _build_c3fad_report()
	var report_b := _build_c3fad_report()
	var cases := report_a.get("cases", []) as Array
	var status := String(report_a.get("tranche_status", ""))

	_check.call(
		"search_item_margin_disjoint_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FAD,
	)
	_check.call(
		"search_item_margin_disjoint_boundary_id_recorded",
		String(report_a.get("boundary_id", "")) == BOUNDARY_ID_C3FAD,
	)
	_check.call(
		"search_item_margin_disjoint_status_is_explicit_allowed_value",
		[
			SAFE_DISJOINT_TEST_CORPUS,
			NEEDS_POLICY_CHANGE_C3FAD,
			NEEDS_MORE_VALIDATION_C3FAD,
			BLOCKED_C3FAD,
		].has(status),
	)
	_check.call(
		"search_item_margin_disjoint_corpus_shape_is_fixed_and_role_complete",
		String(report_a.get("corpus_id", "")) == CORPUS_ID_C3FAD
		and int(report_a.get("fixture_count", 0)) == FIXTURE_COUNT_C3FAD
		and int(report_a.get("role_case_count", 0)) == ROLE_CASE_COUNT_C3FAD
		and cases.size() == ROLE_CASE_COUNT_C3FAD
		and _c3fad_role_histogram_complete(report_a.get("role_histogram", {}) as Dictionary),
	)
	_check.call(
		"search_item_margin_disjoint_fixture_and_historical_overlap_are_zero",
		int(report_a.get("c3fac_fixture_overlap_cases", -1)) == 0
		and int(report_a.get("historical_real_data_overlap_cases", -1)) == 0
		and not bool(report_a.get("c3fac_fixture_reused", true))
		and not bool(report_a.get("historical_selection_corpus_reused", true)),
	)
	_check.call(
		"search_item_margin_disjoint_selection_is_outcome_independent",
		String(report_a.get("corpus_selection_basis", "")) == "predeclared_synthetic_fixture_ids_and_role_matrix"
		and not bool(report_a.get("depth1_scores_used_for_case_selection", true))
		and not bool(report_a.get("depth2_scores_used_for_case_selection", true)),
	)
	_check.call(
		"search_item_margin_disjoint_side_specific_history_starts_at_battle_begin",
		int(report_a.get("memory_begin_failures", -1)) == 0,
	)
	_check.call(
		"search_item_margin_disjoint_branch_projection_uses_clones_only",
		int(report_a.get("branch_clone_failures", -1)) == 0
		and int(report_a.get("branch_projection_failures", -1)) == 0
		and int(report_a.get("live_state_mutation_cases", -1)) == 0
		and int(report_a.get("live_memory_mutation_cases", -1)) == 0,
	)
	_check.call(
		"search_item_margin_disjoint_role_contexts_are_side_matching_and_sanitized",
		int(report_a.get("context_failures", -1)) == 0
		and int(report_a.get("wrong_side_memory_acceptance_cases", -1)) == 0,
	)
	_check.call(
		"search_item_margin_disjoint_every_case_evaluates_all_legal_switches",
		_c3fad_all_cases_true(cases, "all_legal_switches_evaluated")
		and int(report_a.get("legal_switch_occurrences", 0)) == int(report_a.get("depth1_evaluations", -1))
		and int(report_a.get("legal_switch_occurrences", 0)) == int(report_a.get("depth2_evaluations", -1)),
	)
	_check.call(
		"search_item_margin_disjoint_scores_are_itemaware_role_local_only",
		String(report_a.get("score_source", "")) == "TrainerItemAwareSearch_role_local_recomputation"
		and not bool(report_a.get("historical_base_scores_reused", true))
		and not bool(report_a.get("base_search_used_for_candidate_selection", true))
		and _c3fad_all_cases_true(cases, "itemaware_metadata_valid"),
	)
	_check.call(
		"search_item_margin_disjoint_margin3000_is_switch_only",
		String(report_a.get("candidate_policy_id", "")) == CANDIDATE_POLICY_C3FAC
		and String(report_a.get("candidate_policy_scope", "")) == "switch_only"
		and int(report_a.get("candidate_margin", -1)) == CANDIDATE_MARGIN_C3FAC
		and _c3fad_all_cases_true(cases, "promoted_set_switch_only"),
	)
	_check.call(
		"search_item_margin_disjoint_records_per_case_scores_gap_sets_loss_and_cost",
		_c3fad_case_telemetry_complete(cases),
	)
	_check.call(
		"search_item_margin_disjoint_incomplete_cases_are_not_hidden",
		int(report_a.get("semantically_complete_cases", -1))
		+ int(report_a.get("incomplete_cases", -1))
		== ROLE_CASE_COUNT_C3FAD,
	)
	_check.call(
		"search_item_margin_disjoint_policy_loss_accounting_matches_cases",
		int(report_a.get("policy_loss_cases", -1)) == _c3fad_count_true(cases, "loses_global_best")
		and int(report_a.get("partial_global_best_tie_drop_cases", -1)) == _c3fad_count_true(cases, "drops_some_global_best_ties"),
	)
	_check.call(
		"search_item_margin_disjoint_status_matches_executed_evidence",
		_c3fad_status_matches_evidence(report_a),
	)
	_check.call(
		"search_item_margin_disjoint_global_safety_remains_false",
		not bool(report_a.get("candidate_strategy_proven_safe_globally", true)),
	)
	_check.call(
		"search_item_margin_disjoint_move_switch_item_remain_separate",
		String(report_a.get("action_kind_contract", "")) == "MOVE_SWITCH_ITEM_explicit_no_cross_kind_score"
		and not bool(report_a.get("cross_kind_score_model_defined", true))
		and _c3fad_all_cases_have_all_kinds(cases),
	)
	_check.call(
		"search_item_margin_disjoint_root_fanout_separate_from_inner_cap3",
		bool(report_a.get("root_fanout_all_legal_preserved", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_item_margin_disjoint_forbidden_fallbacks_absent",
		not bool(report_a.get("lexical_fallback_used", true))
		and not bool(report_a.get("frontier_fallback_used", true))
		and not bool(report_a.get("roster_value_fallback_used", true))
		and not bool(report_a.get("profile_tiebreak_used", true))
		and not bool(report_a.get("campaign_policy_used", true))
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true)),
	)
	_check.call(
		"search_item_margin_disjoint_scheduler_and_660_stay_closed",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("shared_scheduler_reexecuted", true))
		and not bool(report_a.get("shared_660_reopened", true)),
	)
	_check.call(
		"search_item_margin_disjoint_production_and_fase34_remain_closed",
		not bool(report_a.get("production_adapter_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("production_files_modified", true))
		and not bool(report_a.get("production_sampler_modified", true))
		and not bool(report_a.get("production_budget_modified", true))
		and not bool(report_a.get("fase34_open", true)),
	)
	_check.call(
		"search_item_margin_disjoint_safe_status_is_corpus_scoped_only",
		status != SAFE_DISJOINT_TEST_CORPUS
		or (
			int(report_a.get("policy_loss_cases", -1)) == 0
			and int(report_a.get("incomplete_cases", -1)) == 0
			and not bool(report_a.get("candidate_strategy_proven_safe_globally", true))
			and not bool(report_a.get("production_adapter_authorized", true))
		),
	)
	_check.call("search_item_margin_disjoint_report_deterministic", report_a == report_b)
	_check.call(
		"search_item_margin_disjoint_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH ITEMAWARE MARGIN3000 DISJOINT ROLE-LOCAL VALIDATION AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fad_report() -> Dictionary:
	var helper := TrainerItemActionsTestSuite.new()
	helper._build_catalog()
	helper._add_setup_move(SETUP_A_C3FAD, [])
	helper._add_setup_move(SETUP_B_C3FAD, [])
	helper._add_damage_move(CHIP_A_C3FAD, 35)
	helper._add_damage_move(CHIP_B_C3FAD, 45)
	helper._add_species(SPECIES_A_C3FAD, 85, 95, 75, 88, [SETUP_A_C3FAD, CHIP_A_C3FAD])
	helper._add_species(SPECIES_B_C3FAD, 90, 102, 78, 82, [SETUP_B_C3FAD, CHIP_B_C3FAD])
	var catalog := helper._catalog as DefinitionCatalog
	if catalog == null:
		return _c3fad_empty_report(BLOCKED_C3FAD)

	var all_cases: Array[Dictionary] = []
	var memory_begin_failures := 0
	var branch_clone_failures := 0
	var branch_projection_failures := 0
	var live_state_mutation_cases := 0
	var live_memory_mutation_cases := 0
	var context_failures := 0
	var wrong_side_memory_acceptance_cases := 0
	var fixture_overlap_cases := 0
	var historical_overlap_cases := 0

	for fixture in _c3fad_fixture_specs():
		var fixture_id := String(fixture.get("fixture_id", ""))
		var server := _c3fad_server(catalog, fixture)
		if server == null or server.state == null:
			context_failures += 3
			for role in [ROLE_ROOT_OPPONENT, ROLE_OWN_DEPTH2, ROLE_OPPONENT_DEPTH2]:
				all_cases.append(_c3fad_blocked_case(fixture_id, String(role)))
			continue

		var live_state_before := JSON.stringify(server.snapshot())
		var memory_a := TrainerBattleMemory.new()
		var memory_b := TrainerBattleMemory.new()
		var memory_a_begin_ok := memory_a.begin(server.state, SIDE_A_C3FAD)
		var memory_b_begin_ok := memory_b.begin(server.state, SIDE_B_C3FAD)
		if not memory_a_begin_ok:
			memory_begin_failures += 1
		if not memory_b_begin_ok:
			memory_begin_failures += 1

		var initial_a := _c3fac_initial_bundle(server, SIDE_A_C3FAD, memory_a, catalog)
		var initial_b := _c3fac_initial_bundle(server, SIDE_B_C3FAD, memory_b, catalog)
		var live_memory_a_before := JSON.stringify(memory_a.to_dict())
		var live_memory_b_before := JSON.stringify(memory_b.to_dict())
		var initial_wrong_side_rejected := TrainerObservationBuilder.build(
			server.state,
			SIDE_B_C3FAD,
			memory_a,
		) == null
		if not initial_wrong_side_rejected:
			wrong_side_memory_acceptance_cases += 1

		var initial_belief_a := initial_a.get("belief") as TrainerBeliefState
		var initial_belief_b := initial_b.get("belief") as TrainerBeliefState
		var branch_memory_a := TrainerBattleMemory.from_dict(memory_a.to_dict().duplicate(true))
		var branch_memory_b := TrainerBattleMemory.from_dict(memory_b.to_dict().duplicate(true))
		var branch_belief_a := TrainerBeliefState.from_dict(initial_belief_a.to_dict().duplicate(true)) if initial_belief_a != null else null
		var branch_belief_b := TrainerBeliefState.from_dict(initial_belief_b.to_dict().duplicate(true)) if initial_belief_b != null else null
		var clone_ok := branch_memory_a != null \
			and branch_memory_b != null \
			and branch_belief_a != null \
			and branch_belief_b != null \
			and branch_memory_a != memory_a \
			and branch_memory_b != memory_b \
			and branch_memory_a.observer_side_id == SIDE_A_C3FAD \
			and branch_memory_b.observer_side_id == SIDE_B_C3FAD
		if not clone_ok:
			branch_clone_failures += 1

		var fork := BattleSimulationFork.from_state(server.state, catalog)
		var branch_events: Array[BattleEvent] = []
		var branch_state: BattleState = null
		var branch_memory_a_observed := false
		var branch_memory_b_observed := false
		if clone_ok and fork != null and fork.server != null and fork.state() != null:
			branch_events = fork.submit_turn(_c3fad_branch_actions(fork.state()))
			branch_state = fork.state()
			if not _c3fac_has_rejection(branch_events) and branch_state != null:
				branch_memory_a_observed = branch_memory_a.observe_events(branch_events, branch_state)
				branch_memory_b_observed = branch_memory_b.observe_events(branch_events, branch_state)
		if not branch_memory_a_observed or not branch_memory_b_observed:
			branch_projection_failures += 1

		var previous_a := initial_a.get("observation") as TrainerObservation
		var previous_b := initial_b.get("observation") as TrainerObservation
		var branch_a: Dictionary = {}
		var branch_b: Dictionary = {}
		if clone_ok and fork != null and fork.server != null:
			branch_a = _c3fac_branch_bundle(
				fork.server,
				SIDE_A_C3FAD,
				branch_memory_a,
				branch_belief_a,
				previous_a,
				catalog,
			)
			branch_b = _c3fac_branch_bundle(
				fork.server,
				SIDE_B_C3FAD,
				branch_memory_b,
				branch_belief_b,
				previous_b,
				catalog,
			)

		var branch_wrong_side_rejected := branch_state != null and branch_memory_a != null and TrainerObservationBuilder.build(
			branch_state,
			SIDE_B_C3FAD,
			branch_memory_a,
		) == null
		if not branch_wrong_side_rejected:
			wrong_side_memory_acceptance_cases += 1

		if live_state_before != JSON.stringify(server.snapshot()):
			live_state_mutation_cases += 1
		if live_memory_a_before != JSON.stringify(memory_a.to_dict()):
			live_memory_mutation_cases += 1
		if live_memory_b_before != JSON.stringify(memory_b.to_dict()):
			live_memory_mutation_cases += 1

		var root_context := initial_b.get("context") as TrainerDecisionContext
		var own_context := branch_a.get("context") as TrainerDecisionContext
		var opponent_context := branch_b.get("context") as TrainerDecisionContext
		var role_contexts := {
			ROLE_ROOT_OPPONENT: root_context,
			ROLE_OWN_DEPTH2: own_context,
			ROLE_OPPONENT_DEPTH2: opponent_context,
		}
		for role in [ROLE_ROOT_OPPONENT, ROLE_OWN_DEPTH2, ROLE_OPPONENT_DEPTH2]:
			var context := role_contexts.get(role) as TrainerDecisionContext
			var expected_side := SIDE_A_C3FAD if role == ROLE_OWN_DEPTH2 else SIDE_B_C3FAD
			var expected_turn := 0 if role == ROLE_ROOT_OPPONENT else 1
			var role_case := _c3fad_role_case(
				fixture_id,
				String(role),
				expected_side,
				expected_turn,
				context,
				catalog,
			)
			if not bool(role_case.get("context_valid", false)):
				context_failures += 1
			for raw_id in role_case.get("all_legal_switch_ids", []) as Array:
				var switch_id := String(raw_id)
				if switch_id.begins_with("c3fac_"):
					fixture_overlap_cases += 1
				if switch_id.begins_with("structural_real_probe_"):
					historical_overlap_cases += 1
			all_cases.append(role_case)

	var complete_cases := 0
	var incomplete_cases := 0
	var policy_loss_cases := 0
	var partial_tie_drop_cases := 0
	var legal_switch_occurrences := 0
	var depth1_evaluations := 0
	var depth2_evaluations := 0
	var depth1_simulations_sum := 0
	var depth2_simulations_sum := 0
	var candidate_depth2_simulations_sum := 0
	var score_loss_sum := 0
	var score_loss_max := 0
	var role_histogram: Dictionary = {}

	for raw_case in all_cases:
		var case := raw_case as Dictionary
		var role := String(case.get("role", ""))
		role_histogram[role] = int(role_histogram.get(role, 0)) + 1
		legal_switch_occurrences += int(case.get("legal_switch_count", 0))
		depth1_evaluations += int(case.get("depth1_evaluation_count", 0))
		depth2_evaluations += int(case.get("depth2_evaluation_count", 0))
		depth1_simulations_sum += int(case.get("depth1_simulations", 0))
		depth2_simulations_sum += int(case.get("all_legal_depth2_simulations", 0))
		candidate_depth2_simulations_sum += int(case.get("candidate_depth2_simulations_from_reference", 0))
		var score_loss := int(case.get("candidate_best_depth2_score_loss", 0))
		score_loss_sum += score_loss
		score_loss_max = maxi(score_loss_max, score_loss)
		if bool(case.get("semantically_complete", false)):
			complete_cases += 1
		else:
			incomplete_cases += 1
		if bool(case.get("loses_global_best", false)):
			policy_loss_cases += 1
		if bool(case.get("drops_some_global_best_ties", false)):
			partial_tie_drop_cases += 1

	var status := SAFE_DISJOINT_TEST_CORPUS
	if memory_begin_failures > 0 \
		or branch_clone_failures > 0 \
		or branch_projection_failures > 0 \
		or context_failures > 0 \
		or wrong_side_memory_acceptance_cases > 0:
		status = BLOCKED_C3FAD
	elif incomplete_cases > 0:
		status = NEEDS_MORE_VALIDATION_C3FAD
	elif policy_loss_cases > 0:
		status = NEEDS_POLICY_CHANGE_C3FAD

	return {
		"audit_id": AUDIT_ID_C3FAD,
		"boundary_id": BOUNDARY_ID_C3FAD,
		"tranche_status": status,
		"corpus_id": CORPUS_ID_C3FAD,
		"corpus_selection_basis": "predeclared_synthetic_fixture_ids_and_role_matrix",
		"fixture_count": FIXTURE_COUNT_C3FAD,
		"role_case_count": all_cases.size(),
		"role_histogram": role_histogram,
		"c3fac_fixture_reused": false,
		"historical_selection_corpus_reused": false,
		"c3fac_fixture_overlap_cases": fixture_overlap_cases,
		"historical_real_data_overlap_cases": historical_overlap_cases,
		"depth1_scores_used_for_case_selection": false,
		"depth2_scores_used_for_case_selection": false,
		"score_source": "TrainerItemAwareSearch_role_local_recomputation",
		"historical_base_scores_reused": false,
		"base_search_used_for_candidate_selection": false,
		"candidate_policy_id": CANDIDATE_POLICY_C3FAC,
		"candidate_policy_scope": "switch_only",
		"candidate_margin": CANDIDATE_MARGIN_C3FAC,
		"candidate_strategy_proven_safe_globally": false,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit_no_cross_kind_score",
		"cross_kind_score_model_defined": false,
		"memory_begin_failures": memory_begin_failures,
		"branch_clone_failures": branch_clone_failures,
		"branch_projection_failures": branch_projection_failures,
		"live_state_mutation_cases": live_state_mutation_cases,
		"live_memory_mutation_cases": live_memory_mutation_cases,
		"context_failures": context_failures,
		"wrong_side_memory_acceptance_cases": wrong_side_memory_acceptance_cases,
		"semantically_complete_cases": complete_cases,
		"incomplete_cases": incomplete_cases,
		"policy_loss_cases": policy_loss_cases,
		"partial_global_best_tie_drop_cases": partial_tie_drop_cases,
		"legal_switch_occurrences": legal_switch_occurrences,
		"depth1_evaluations": depth1_evaluations,
		"depth2_evaluations": depth2_evaluations,
		"depth1_simulations_sum": depth1_simulations_sum,
		"all_legal_depth2_simulations_sum": depth2_simulations_sum,
		"candidate_depth2_simulations_from_reference_sum": candidate_depth2_simulations_sum,
		"candidate_best_depth2_score_loss_sum": score_loss_sum,
		"candidate_best_depth2_score_loss_max": score_loss_max,
		"cases": all_cases,
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"lexical_fallback_used": false,
		"frontier_fallback_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_scheduler_reexecuted": false,
		"shared_660_reopened": false,
		"production_adapter_authorized": false,
		"behavior_integration_authorized": false,
		"production_files_modified": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"fase34_open": false,
	}


func _c3fad_role_case(
	fixture_id: String,
	role: String,
	expected_side: StringName,
	expected_turn: int,
	context: TrainerDecisionContext,
	catalog: DefinitionCatalog,
) -> Dictionary:
	if context == null or context.observation == null:
		return _c3fad_blocked_case(fixture_id, role)

	var memory_side := String((context.memory_snapshot as Dictionary).get("observer_side_id", ""))
	var belief_side := String((context.belief_snapshot as Dictionary).get("observer_side_id", ""))
	var context_valid := String(context.observation.observer_side_id) == String(expected_side) \
		and context.observation.turn == expected_turn \
		and memory_side == String(expected_side) \
		and belief_side == String(expected_side)

	var switches := _c3fac_switch_actions(context.legal_actions)
	var all_switch_ids := _c3fac_sorted_switch_ids(switches)
	var depth1_budget := TrainerSearchBudget.constrained(1, 4, 220, INNER_ACTION_CAP)
	var depth2_budget := TrainerSearchBudget.constrained(2, 4, 220, INNER_ACTION_CAP)
	var depth1_search := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), depth1_budget)
	var depth2_search := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), depth2_budget)
	var depth1_scores: Dictionary = {}
	var depth2_scores: Dictionary = {}
	var depth1_costs: Dictionary = {}
	var depth2_costs: Dictionary = {}
	var depth1_complete := true
	var depth2_complete := true
	var metadata_valid := true

	for root_action in switches:
		var switch_id := String(root_action.switch_instance_id)
		var depth1_result := depth1_search.evaluate(context, root_action)
		var depth2_result := depth2_search.evaluate(context, root_action)
		var d1_ok := _c3fad_depth_result_complete(depth1_result, 1)
		var d2_ok := _c3fad_depth_result_complete(depth2_result, 2)
		depth1_complete = depth1_complete and d1_ok
		depth2_complete = depth2_complete and d2_ok
		depth1_scores[switch_id] = int(depth1_result.get("score", -2147483648))
		depth2_scores[switch_id] = int(depth2_result.get("score", -2147483648))
		var d1_metadata := depth1_result.get("metadata", {}) as Dictionary
		var d2_metadata := depth2_result.get("metadata", {}) as Dictionary
		depth1_costs[switch_id] = int(d1_metadata.get("simulations_used", 0))
		depth2_costs[switch_id] = int(d2_metadata.get("simulations_used", 0))
		metadata_valid = metadata_valid \
			and _c3fad_itemaware_metadata_valid(d1_metadata) \
			and _c3fad_itemaware_metadata_valid(d2_metadata)

	var promoted_ids := _c3fac_margin_membership(depth1_scores)
	var deep_best_ids: Array[String] = []
	if depth2_complete and not depth2_scores.is_empty():
		deep_best_ids = _c3fad_best_ids(depth2_scores)
	var promoted_switch_only := true
	for promoted_id in promoted_ids:
		if not all_switch_ids.has(promoted_id):
			promoted_switch_only = false

	var all_best_score := _c3fad_best_score(depth2_scores) if depth2_complete else -2147483648
	var candidate_best_score := -2147483648
	var candidate_depth2_cost := 0
	for promoted_id in promoted_ids:
		if depth2_scores.has(promoted_id):
			candidate_best_score = maxi(candidate_best_score, int(depth2_scores[promoted_id]))
			candidate_depth2_cost += int(depth2_costs.get(promoted_id, 0))

	var semantically_complete := context_valid \
		and not switches.is_empty() \
		and depth1_complete \
		and depth2_complete \
		and depth1_scores.size() == switches.size() \
		and depth2_scores.size() == switches.size() \
		and metadata_valid \
		and not promoted_ids.is_empty() \
		and not deep_best_ids.is_empty()

	var any_best_preserved := false
	var all_best_preserved := semantically_complete
	if semantically_complete:
		for best_id in deep_best_ids:
			if promoted_ids.has(best_id):
				any_best_preserved = true
			else:
				all_best_preserved = false
	else:
		all_best_preserved = false

	var loses_global_best := semantically_complete and not any_best_preserved
	var drops_some_global_best_ties := semantically_complete and any_best_preserved and not all_best_preserved
	var candidate_loss := 0
	if semantically_complete:
		candidate_loss = maxi(0, all_best_score - candidate_best_score)

	var best_depth1 := _c3fad_best_score(depth1_scores)
	var global_best_depth1_gap_max := 0
	if semantically_complete:
		for best_id in deep_best_ids:
			global_best_depth1_gap_max = maxi(
				global_best_depth1_gap_max,
				best_depth1 - int(depth1_scores.get(best_id, best_depth1)),
			)

	return {
		"case_id": "%s|%s" % [fixture_id, role],
		"fixture_id": fixture_id,
		"role": role,
		"side_id": String(context.observation.observer_side_id),
		"turn": context.observation.turn,
		"context_valid": context_valid,
		"memory_snapshot_side_id": memory_side,
		"belief_snapshot_side_id": belief_side,
		"legal_action_kind_histogram": _c3fac_action_kind_histogram(context.legal_actions),
		"legal_switch_count": switches.size(),
		"all_legal_switch_ids": all_switch_ids,
		"all_legal_switches_evaluated": depth1_scores.size() == switches.size() and depth2_scores.size() == switches.size(),
		"depth1_evaluation_count": depth1_scores.size(),
		"depth2_evaluation_count": depth2_scores.size(),
		"depth1_scores": depth1_scores,
		"depth2_all_legal_scores": depth2_scores,
		"depth1_simulations_by_switch": depth1_costs,
		"depth2_simulations_by_switch": depth2_costs,
		"depth1_simulations": _c3fad_sum_dictionary_ints(depth1_costs),
		"all_legal_depth2_simulations": _c3fad_sum_dictionary_ints(depth2_costs),
		"candidate_depth2_simulations_from_reference": candidate_depth2_cost,
		"candidate_margin": CANDIDATE_MARGIN_C3FAC,
		"promoted_switch_ids": promoted_ids,
		"promoted_set_switch_only": promoted_switch_only,
		"global_deep_best_ids": deep_best_ids,
		"global_best_depth1_gap_max": global_best_depth1_gap_max,
		"any_global_best_preserved": any_best_preserved,
		"all_global_best_ties_preserved": all_best_preserved,
		"loses_global_best": loses_global_best,
		"drops_some_global_best_ties": drops_some_global_best_ties,
		"promoted_not_global_best_ids": _c3fad_set_difference(promoted_ids, deep_best_ids),
		"global_best_not_promoted_ids": _c3fad_set_difference(deep_best_ids, promoted_ids),
		"all_legal_best_depth2_score": all_best_score,
		"candidate_best_depth2_score": candidate_best_score,
		"candidate_best_depth2_score_loss": candidate_loss,
		"depth1_complete": depth1_complete,
		"depth2_complete": depth2_complete,
		"itemaware_metadata_valid": metadata_valid,
		"semantically_complete": semantically_complete,
	}


func _c3fad_empty_report(status: String) -> Dictionary:
	return {
		"audit_id": AUDIT_ID_C3FAD,
		"boundary_id": BOUNDARY_ID_C3FAD,
		"tranche_status": status,
		"corpus_id": CORPUS_ID_C3FAD,
		"fixture_count": 0,
		"role_case_count": 0,
		"role_histogram": {},
		"cases": [],
		"candidate_strategy_proven_safe_globally": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_scheduler_reexecuted": false,
		"shared_660_reopened": false,
		"production_adapter_authorized": false,
		"behavior_integration_authorized": false,
		"production_files_modified": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"fase34_open": false,
	}


func _c3fad_blocked_case(fixture_id: String, role: String) -> Dictionary:
	return {
		"case_id": "%s|%s" % [fixture_id, role],
		"fixture_id": fixture_id,
		"role": role,
		"context_valid": false,
		"legal_action_kind_histogram": {"MOVE": 0, "SWITCH": 0, "ITEM": 0},
		"legal_switch_count": 0,
		"all_legal_switch_ids": [],
		"all_legal_switches_evaluated": false,
		"depth1_evaluation_count": 0,
		"depth2_evaluation_count": 0,
		"depth1_scores": {},
		"depth2_all_legal_scores": {},
		"depth1_simulations_by_switch": {},
		"depth2_simulations_by_switch": {},
		"depth1_simulations": 0,
		"all_legal_depth2_simulations": 0,
		"candidate_depth2_simulations_from_reference": 0,
		"candidate_margin": CANDIDATE_MARGIN_C3FAC,
		"promoted_switch_ids": [],
		"promoted_set_switch_only": true,
		"global_deep_best_ids": [],
		"global_best_depth1_gap_max": 0,
		"any_global_best_preserved": false,
		"all_global_best_ties_preserved": false,
		"loses_global_best": false,
		"drops_some_global_best_ties": false,
		"promoted_not_global_best_ids": [],
		"global_best_not_promoted_ids": [],
		"all_legal_best_depth2_score": -2147483648,
		"candidate_best_depth2_score": -2147483648,
		"candidate_best_depth2_score_loss": 0,
		"depth1_complete": false,
		"depth2_complete": false,
		"itemaware_metadata_valid": false,
		"semantically_complete": false,
	}


func _c3fad_server(catalog: DefinitionCatalog, fixture: Dictionary) -> AuthoritativeBattleServer:
	var fixture_id := String(fixture.get("fixture_id", ""))
	var a_stats := fixture.get("a_stats", []) as Array
	var b_stats := fixture.get("b_stats", []) as Array
	var a_hp := fixture.get("a_hp", []) as Array
	var b_hp := fixture.get("b_hp", []) as Array
	if a_stats.size() != 3 or b_stats.size() != 3 or a_hp.size() != 3 or b_hp.size() != 3:
		return null

	var party_a: Array[CreatureInstance] = []
	var party_b: Array[CreatureInstance] = []
	for index in range(3):
		var a_moves: Array[StringName] = [SETUP_A_C3FAD, CHIP_A_C3FAD]
		var b_moves: Array[StringName] = [SETUP_B_C3FAD, CHIP_B_C3FAD]
		party_a.append(_c3fad_creature(
			StringName("%s_a%d" % [fixture_id, index]),
			SPECIES_A_C3FAD,
			_c3fad_stat_block(a_stats[index] as Array),
			a_moves,
			catalog,
			int(a_hp[index]),
		))
		party_b.append(_c3fad_creature(
			StringName("%s_b%d" % [fixture_id, index]),
			SPECIES_B_C3FAD,
			_c3fad_stat_block(b_stats[index] as Array),
			b_moves,
			catalog,
			int(b_hp[index]),
		))

	var state := BattleState.create_with_parties(
		StringName("c3fad_%s" % fixture_id),
		party_a,
		party_b,
		int(fixture.get("seed", 1)),
	)
	var inventory_a := BattleSideItemInventory.new()
	inventory_a.set_quantity(POTION_C3FAD, int(fixture.get("a_potion", 1)))
	inventory_a.set_quantity(HYPER_POTION_C3FAD, int(fixture.get("a_hyper", 1)))
	var inventory_b := BattleSideItemInventory.new()
	inventory_b.set_quantity(POTION_C3FAD, int(fixture.get("b_potion", 1)))
	inventory_b.set_quantity(HYPER_POTION_C3FAD, int(fixture.get("b_hyper", 1)))
	state.set_item_inventory_for_side(SIDE_A_C3FAD, inventory_a)
	state.set_item_inventory_for_side(SIDE_B_C3FAD, inventory_b)
	return AuthoritativeBattleServer.new(state, catalog)


func _c3fad_creature(
	instance_id: StringName,
	species_id: StringName,
	stats: StatBlock,
	moves: Array[StringName],
	catalog: DefinitionCatalog,
	current_hp: int,
) -> CreatureInstance:
	var creature := CreatureInstance.new(instance_id, species_id, 30, stats, moves)
	creature.initialize_move_pp(catalog)
	creature.current_hp = clampi(current_hp, 1, stats.max_hp)
	return creature


func _c3fad_stat_block(values: Array) -> StatBlock:
	if values.size() != 6:
		return StatBlock.new(100, 80, 80, 80, 80, 80)
	return StatBlock.new(
		int(values[0]),
		int(values[1]),
		int(values[2]),
		int(values[3]),
		int(values[4]),
		int(values[5]),
	)


func _c3fad_branch_actions(state: BattleState) -> Array[BattleAction]:
	var out: Array[BattleAction] = []
	if state == null:
		return out
	var a := state.active_for_side(SIDE_A_C3FAD)
	var b := state.active_for_side(SIDE_B_C3FAD)
	if a == null or b == null:
		return out
	out.append(BattleAction.new(
		state.turn + 1,
		a.instance_id,
		SETUP_A_C3FAD,
		b.instance_id,
		BattleAction.MOVE,
		SIDE_A_C3FAD,
	))
	out.append(BattleAction.new(
		state.turn + 1,
		b.instance_id,
		SETUP_B_C3FAD,
		a.instance_id,
		BattleAction.MOVE,
		SIDE_B_C3FAD,
	))
	return out


func _c3fad_fixture_specs() -> Array[Dictionary]:
	return [
		{
			"fixture_id": "c3fad_alpha",
			"seed": 841101,
			"a_stats": [
				[112, 98, 82, 74, 88, 91],
				[128, 84, 116, 62, 105, 58],
				[96, 121, 67, 93, 72, 111],
			],
			"b_stats": [
				[118, 101, 84, 96, 86, 89],
				[132, 79, 119, 68, 108, 55],
				[94, 126, 64, 112, 70, 109],
			],
			"a_hp": [76, 104, 61],
			"b_hp": [83, 110, 58],
			"a_potion": 1,
			"a_hyper": 1,
			"b_potion": 1,
			"b_hyper": 1,
		},
		{
			"fixture_id": "c3fad_beta",
			"seed": 841202,
			"a_stats": [
				[105, 88, 78, 104, 82, 99],
				[138, 76, 124, 60, 114, 51],
				[101, 132, 69, 79, 77, 117],
			],
			"b_stats": [
				[121, 92, 91, 109, 80, 86],
				[114, 117, 75, 71, 96, 102],
				[142, 73, 129, 65, 120, 48],
			],
			"a_hp": [54, 132, 72],
			"b_hp": [49, 88, 135],
			"a_potion": 2,
			"a_hyper": 1,
			"b_potion": 1,
			"b_hyper": 2,
		},
		{
			"fixture_id": "c3fad_gamma",
			"seed": 841303,
			"a_stats": [
				[126, 110, 88, 72, 93, 74],
				[109, 72, 95, 127, 103, 83],
				[99, 118, 73, 106, 69, 122],
			],
			"b_stats": [
				[108, 83, 79, 124, 97, 94],
				[136, 111, 113, 57, 102, 60],
				[103, 129, 71, 89, 74, 116],
			],
			"a_hp": [93, 78, 47],
			"b_hp": [72, 121, 64],
			"a_potion": 1,
			"a_hyper": 2,
			"b_potion": 2,
			"b_hyper": 1,
		},
	]


func _c3fad_depth_result_complete(result: Dictionary, depth: int) -> bool:
	if result.is_empty():
		return false
	var metadata := result.get("metadata", {}) as Dictionary
	var world_count := int(metadata.get("world_count", 0))
	return world_count > 0 \
		and int(metadata.get("complete_world_count", -1)) == world_count \
		and int(metadata.get("world_coverage_basis_points", 0)) == 10000 \
		and int(metadata.get("fully_completed_depth", 0)) == depth \
		and not bool(metadata.get("budget_exhausted", true))


func _c3fad_itemaware_metadata_valid(metadata: Dictionary) -> bool:
	return String(metadata.get("item_search_model", "")) == TrainerItemAwareSearch.ITEM_SEARCH_MODEL \
		and String(metadata.get("item_action_sampling_model", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL \
		and String(metadata.get("battle_item_resource_model", "")) == TrainerItemAwareWorldFactory.RESOURCE_MODEL


func _c3fad_best_ids(scores: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if scores.is_empty():
		return out
	var best := _c3fad_best_score(scores)
	for raw_key in scores.keys():
		var key := String(raw_key)
		if int(scores[raw_key]) == best:
			out.append(key)
	out.sort()
	return out


func _c3fad_best_score(scores: Dictionary) -> int:
	var best := -2147483648
	for value in scores.values():
		best = maxi(best, int(value))
	return best


func _c3fad_set_difference(left: Array, right: Array) -> Array[String]:
	var out: Array[String] = []
	for raw_value in left:
		var value := String(raw_value)
		if not right.has(value):
			out.append(value)
	out.sort()
	return out


func _c3fad_sum_dictionary_ints(values: Dictionary) -> int:
	var total := 0
	for value in values.values():
		total += int(value)
	return total


func _c3fad_all_cases_true(cases: Array, key: String) -> bool:
	if cases.size() != ROLE_CASE_COUNT_C3FAD:
		return false
	for raw_case in cases:
		if not bool((raw_case as Dictionary).get(key, false)):
			return false
	return true


func _c3fad_all_cases_have_all_kinds(cases: Array) -> bool:
	if cases.size() != ROLE_CASE_COUNT_C3FAD:
		return false
	for raw_case in cases:
		var histogram := (raw_case as Dictionary).get("legal_action_kind_histogram", {}) as Dictionary
		if int(histogram.get("MOVE", 0)) <= 0 \
			or int(histogram.get("SWITCH", 0)) <= 0 \
			or int(histogram.get("ITEM", 0)) <= 0:
			return false
	return true


func _c3fad_count_true(cases: Array, key: String) -> int:
	var count := 0
	for raw_case in cases:
		if bool((raw_case as Dictionary).get(key, false)):
			count += 1
	return count


func _c3fad_role_histogram_complete(histogram: Dictionary) -> bool:
	return histogram.size() == 3 \
		and int(histogram.get(ROLE_ROOT_OPPONENT, 0)) == FIXTURE_COUNT_C3FAD \
		and int(histogram.get(ROLE_OWN_DEPTH2, 0)) == FIXTURE_COUNT_C3FAD \
		and int(histogram.get(ROLE_OPPONENT_DEPTH2, 0)) == FIXTURE_COUNT_C3FAD


func _c3fad_case_telemetry_complete(cases: Array) -> bool:
	if cases.size() != ROLE_CASE_COUNT_C3FAD:
		return false
	for raw_case in cases:
		var case := raw_case as Dictionary
		if not case.has("depth1_scores") \
			or not case.has("depth2_all_legal_scores") \
			or not case.has("global_best_depth1_gap_max") \
			or not case.has("promoted_switch_ids") \
			or not case.has("global_deep_best_ids") \
			or not case.has("candidate_best_depth2_score_loss") \
			or not case.has("depth1_simulations") \
			or not case.has("all_legal_depth2_simulations"):
			return false
	return true


func _c3fad_status_matches_evidence(report: Dictionary) -> bool:
	var status := String(report.get("tranche_status", ""))
	var blockers := int(report.get("memory_begin_failures", 0)) \
		+ int(report.get("branch_clone_failures", 0)) \
		+ int(report.get("branch_projection_failures", 0)) \
		+ int(report.get("context_failures", 0)) \
		+ int(report.get("wrong_side_memory_acceptance_cases", 0))
	var incomplete := int(report.get("incomplete_cases", 0))
	var losses := int(report.get("policy_loss_cases", 0))
	if blockers > 0:
		return status == BLOCKED_C3FAD
	if incomplete > 0:
		return status == NEEDS_MORE_VALIDATION_C3FAD
	if losses > 0:
		return status == NEEDS_POLICY_CHANGE_C3FAD
	return status == SAFE_DISJOINT_TEST_CORPUS
