class_name TrainerRosterSearchItemAwareDepth1SwitchScorePortabilityAuditTestSuite
extends TrainerRosterSearchSymmetricPublicHistoryBranchPerspectiveAuditTestSuite

# C3f-ac is strictly TEST/AUDIT-ONLY. It validates whether the SWITCH depth-1
# score source can be ported by RECOMPUTING it with the real TrainerItemAwareSearch
# on role-local sanitized contexts. Historical base-search scores are telemetry only
# and are never reused as ItemAware scores or as evidence of global safety.

const AUDIT_ID_C3FAC := "c3f_ac_item_aware_depth1_switch_score_portability_role_local_audit_v1"
const BOUNDARY_ID_C3FAC := "validate_item_aware_depth1_switch_score_portability_on_role_local_sanitized_context_before_any_production_adapter"
const PORTABLE_TEST_CONTRACT := "PORTABLE_TEST_CONTRACT"
const NEEDS_ITEM_AWARE_SCORE_API := "NEEDS_ITEM_AWARE_SCORE_API"
const NEEDS_MORE_VALIDATION := "NEEDS_MORE_VALIDATION"
const BLOCKED := "BLOCKED"

const CANDIDATE_POLICY_C3FAC := "depth1_margin_3000_all_legal"
const CANDIDATE_MARGIN_C3FAC := 3000
const SIDE_A_C3FAC := &"side_a"
const SIDE_B_C3FAC := &"side_b"
const ITEM_IDLE_C3FAC := &"item_idle"
const ITEM_CHIP_C3FAC := &"item_chip"
const ITEM_PRESSURE_C3FAC := &"item_pressure"
const ITEM_FINISH_C3FAC := &"item_finish"
const ITEM_OWN_SPECIES_C3FAC := &"item_own_species"
const ITEM_FOE_SPECIES_C3FAC := &"item_foe_species"
const POTION_C3FAC := &"potion"
const HYPER_POTION_C3FAC := &"hyper_potion"
const NEXT_BOUNDARY_C3FAC := "revalidate_margin3000_item_aware_candidate_preservation_on_disjoint_role_local_corpus_before_any_production_adapter"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_item_aware_depth1_switch_score_portability()


func _test_item_aware_depth1_switch_score_portability() -> void:
	var report_a := _build_c3fac_report()
	var report_b := _build_c3fac_report()
	var roles := report_a.get("roles", {}) as Dictionary
	var root := roles.get(ROLE_ROOT_OPPONENT, {}) as Dictionary
	var own := roles.get(ROLE_OWN_DEPTH2, {}) as Dictionary
	var opponent := roles.get(ROLE_OPPONENT_DEPTH2, {}) as Dictionary
	var harness := report_a.get("dual_history_harness", {}) as Dictionary
	var semantics := report_a.get("score_semantics", {}) as Dictionary
	var source := report_a.get("source_contract", {}) as Dictionary

	_check.call(
		"search_item_portability_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FAC,
	)
	_check.call(
		"search_item_portability_boundary_id_recorded",
		String(report_a.get("boundary_id", "")) == BOUNDARY_ID_C3FAC,
	)
	_check.call(
		"search_item_portability_result_is_explicit_allowed_status",
		[PORTABLE_TEST_CONTRACT, NEEDS_ITEM_AWARE_SCORE_API, NEEDS_MORE_VALIDATION, BLOCKED].has(
			String(report_a.get("tranche_status", ""))
		),
	)
	_check.call(
		"search_item_portability_uses_exact_three_roles",
		roles.size() == 3
		and roles.has(ROLE_ROOT_OPPONENT)
		and roles.has(ROLE_OWN_DEPTH2)
		and roles.has(ROLE_OPPONENT_DEPTH2),
	)
	_check.call(
		"search_item_portability_dual_history_starts_at_battle_begin",
		bool(harness.get("memory_a_begin_ok", false))
		and bool(harness.get("memory_b_begin_ok", false))
		and String(harness.get("memory_a_side_id", "")) == String(SIDE_A_C3FAC)
		and String(harness.get("memory_b_side_id", "")) == String(SIDE_B_C3FAC),
	)
	_check.call(
		"search_item_portability_branch_uses_cloned_side_memories",
		bool(harness.get("branch_memory_a_cloned", false))
		and bool(harness.get("branch_memory_b_cloned", false))
		and bool(harness.get("branch_memory_a_observed", false))
		and bool(harness.get("branch_memory_b_observed", false)),
	)
	_check.call(
		"search_item_portability_same_branch_events_fanned_to_both_clones",
		bool(harness.get("branch_events_exist", false))
		and bool(harness.get("same_branch_event_count_projected", false)),
	)
	_check.call(
		"search_item_portability_branch_does_not_mutate_live_state_or_memory",
		bool(harness.get("live_state_unchanged", false))
		and bool(harness.get("live_memory_a_unchanged", false))
		and bool(harness.get("live_memory_b_unchanged", false)),
	)
	_check.call(
		"search_item_portability_rejects_observer_memory_for_opponent_initial",
		bool(harness.get("initial_wrong_side_memory_rejected", false)),
	)
	_check.call(
		"search_item_portability_rejects_observer_memory_for_opponent_branch",
		bool(harness.get("branch_wrong_side_memory_rejected", false)),
	)
	_check.call(
		"search_item_portability_role_contexts_are_side_matching_and_sanitized",
		_role_context_ok(root, SIDE_B_C3FAC, 0)
		and _role_context_ok(own, SIDE_A_C3FAC, 1)
		and _role_context_ok(opponent, SIDE_B_C3FAC, 1),
	)
	_check.call(
		"search_item_portability_all_roles_have_real_switch_roots",
		int(root.get("legal_switch_count", 0)) >= 2
		and int(own.get("legal_switch_count", 0)) >= 2
		and int(opponent.get("legal_switch_count", 0)) >= 2,
	)
	_check.call(
		"search_item_portability_evaluates_every_legal_switch_root",
		_all_roles_match_count(roles, "evaluated_switch_count", "legal_switch_count"),
	)
	_check.call(
		"search_item_portability_itemaware_depth1_executes_cleanly_all_roles",
		_all_roles_true(roles, "item_evaluations_complete"),
	)
	_check.call(
		"search_item_portability_base_depth1_is_telemetry_only_but_executes",
		_all_roles_true(roles, "base_evaluations_complete")
		and not bool(semantics.get("historical_base_scores_reused", true)),
	)
	_check.call(
		"search_item_portability_real_itemaware_metadata_present_all_roles",
		_all_roles_true(roles, "item_metadata_matches_runtime_models"),
	)
	_check.call(
		"search_item_portability_margin3000_applied_to_itemaware_scores_all_roles",
		_all_roles_true(roles, "item_margin_membership_nonempty")
		and String(report_a.get("candidate_policy_id", "")) == CANDIDATE_POLICY_C3FAC
		and int(report_a.get("candidate_margin", -1)) == CANDIDATE_MARGIN_C3FAC,
	)
	_check.call(
		"search_item_portability_candidate_remains_switch_only",
		String(report_a.get("candidate_policy_scope", "")) == "switch_only"
		and _all_roles_true(roles, "candidate_membership_switch_only"),
	)
	_check.call(
		"search_item_portability_historical_base_membership_not_used_for_item_selection",
		not bool(semantics.get("base_membership_used_for_item_behavior", true))
		and not bool(semantics.get("prior_c3fu_v_evidence_transferred", true)),
	)
	_check.call(
		"search_item_portability_does_not_claim_base_item_score_equivalence",
		not bool(semantics.get("base_item_score_equivalence_proven", true))
		and not bool(semantics.get("base_item_score_equivalence_required_for_port", true)),
	)
	_check.call(
		"search_item_portability_recompute_mode_is_explicit",
		String(semantics.get("portability_mode", "")) == "role_local_itemaware_recomputation_not_base_score_reuse",
	)
	_check.call(
		"search_item_portability_item_world_keeps_own_bag_and_hides_opponent_bag",
		_all_roles_true(roles, "item_world_own_inventory_present")
		and _all_roles_true(roles, "item_world_opponent_inventory_absent"),
	)
	_check.call(
		"search_item_portability_role_local_action_space_exercises_items",
		_all_roles_positive(roles, "role_local_legal_item_count"),
	)
	_check.call(
		"search_item_portability_actual_depth1_response_has_no_hidden_opponent_items",
		_all_roles_zero(roles, "actual_depth1_response_item_count")
		and _all_roles_zero(roles, "actual_depth1_bounded_response_item_count"),
	)
	_check.call(
		"search_item_portability_sampler_difference_is_observed_on_role_local_mix",
		_all_roles_true(roles, "role_local_sampler_signatures_differ")
		and String(source.get("item_sampling_model", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
	)
	_check.call(
		"search_item_portability_world_factory_difference_is_explicit",
		bool(source.get("base_world_factory_omits_battle_inventory", false))
		and bool(source.get("item_world_factory_copies_only_observer_inventory", false)),
	)
	_check.call(
		"search_item_portability_state_evaluator_is_shared_not_replaced",
		bool(source.get("multi_search_uses_shared_state_evaluator", false))
		and bool(source.get("item_search_delegates_evaluate_to_super", false))
		and not bool(source.get("item_search_replaces_state_evaluator", true)),
	)
	_check.call(
		"search_item_portability_branch_state_is_distinct_and_scores_recomputed",
		int(harness.get("branch_turn", -1)) == 1
		and bool(own.get("score_recomputed_for_role_context", false))
		and bool(opponent.get("score_recomputed_for_role_context", false)),
	)
	_check.call(
		"search_item_portability_move_switch_item_remain_explicit",
		String(report_a.get("action_kind_contract", "")) == "MOVE_SWITCH_ITEM_explicit"
		and _all_roles_true(roles, "action_kind_accounting_explicit"),
	)
	_check.call(
		"search_item_portability_root_fanout_remains_separate_from_inner_cap",
		bool(report_a.get("root_fanout_all_legal_preserved", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_item_portability_candidate_global_safety_stays_false",
		not bool(report_a.get("candidate_strategy_proven_safe_globally", true)),
	)
	_check.call(
		"search_item_portability_no_forbidden_semantic_fallbacks",
		not bool(report_a.get("lexical_fallback_used", true))
		and not bool(report_a.get("frontier_fallback_used", true))
		and not bool(report_a.get("roster_value_fallback_used", true))
		and not bool(report_a.get("profile_tiebreak_used", true))
		and not bool(report_a.get("campaign_policy_used", true))
		and not bool(report_a.get("recovery_policy_used", true))
		and not bool(report_a.get("replacement_policy_used", true)),
	)
	_check.call(
		"search_item_portability_no_scheduler_or_660_selection",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("shared_660_reopened", true)),
	)
	_check.call(
		"search_item_portability_production_and_fase34_remain_closed",
		not bool(report_a.get("production_adapter_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("production_files_modified", true))
		and not bool(report_a.get("fase34_open", true)),
	)
	_check.call(
		"search_item_portability_status_matches_runtime_evidence",
		_status_matches_evidence(report_a),
	)
	_check.call(
		"search_item_portability_portable_status_is_test_contract_only",
		String(report_a.get("tranche_status", "")) != PORTABLE_TEST_CONTRACT
		or (
			bool(report_a.get("test_contract_scope_only", false))
			and not bool(report_a.get("production_adapter_authorized", true))
			and String(report_a.get("recommended_next_boundary", "")) == NEXT_BOUNDARY_C3FAC
		),
	)
	_check.call("search_item_portability_report_deterministic", report_a == report_b)
	_check.call(
		"search_item_portability_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH ITEMAWARE DEPTH1 SWITCH SCORE PORTABILITY AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fac_report() -> Dictionary:
	var helper := TrainerItemActionsTestSuite.new()
	helper._build_catalog()
	var catalog := helper._catalog as DefinitionCatalog
	var source := _c3fac_source_contract()
	if catalog == null:
		return _c3fac_empty_report(NEEDS_ITEM_AWARE_SCORE_API, source)

	var server := _c3fac_server(catalog)
	if server == null or server.state == null:
		return _c3fac_empty_report(BLOCKED, source)

	var live_state_before := JSON.stringify(server.snapshot())
	var memory_a := TrainerBattleMemory.new()
	var memory_b := TrainerBattleMemory.new()
	var memory_a_begin := memory_a.begin(server.state, SIDE_A_C3FAC)
	var memory_b_begin := memory_b.begin(server.state, SIDE_B_C3FAC)
	if not memory_a_begin or not memory_b_begin:
		return _c3fac_empty_report(BLOCKED, source)

	var initial_a := _c3fac_initial_bundle(server, SIDE_A_C3FAC, memory_a, catalog)
	var initial_b := _c3fac_initial_bundle(server, SIDE_B_C3FAC, memory_b, catalog)
	var live_memory_a_before := JSON.stringify(memory_a.to_dict())
	var live_memory_b_before := JSON.stringify(memory_b.to_dict())
	var initial_wrong_side_rejected := TrainerObservationBuilder.build(
		server.state,
		SIDE_B_C3FAC,
		memory_a,
	) == null

	var branch_memory_a := TrainerBattleMemory.from_dict(memory_a.to_dict().duplicate(true))
	var branch_memory_b := TrainerBattleMemory.from_dict(memory_b.to_dict().duplicate(true))
	var branch_belief_a := TrainerBeliefState.from_dict(
		(initial_a.get("belief", TrainerBeliefState.new()) as TrainerBeliefState).to_dict().duplicate(true)
	)
	var branch_belief_b := TrainerBeliefState.from_dict(
		(initial_b.get("belief", TrainerBeliefState.new()) as TrainerBeliefState).to_dict().duplicate(true)
	)
	var fork := BattleSimulationFork.from_state(server.state, catalog)
	if fork == null or fork.server == null or fork.state() == null:
		return _c3fac_empty_report(BLOCKED, source)
	var branch_actions := _c3fac_branch_actions(fork.state())
	var branch_events: Array[BattleEvent] = fork.submit_turn(branch_actions)
	var branch_rejected := _c3fac_has_rejection(branch_events)
	var branch_state := fork.state()
	var branch_memory_a_observed := false
	var branch_memory_b_observed := false
	if not branch_rejected and branch_state != null:
		branch_memory_a_observed = branch_memory_a.observe_events(branch_events, branch_state)
		branch_memory_b_observed = branch_memory_b.observe_events(branch_events, branch_state)

	var previous_a := initial_a.get("observation") as TrainerObservation
	var previous_b := initial_b.get("observation") as TrainerObservation
	var branch_a := _c3fac_branch_bundle(
		fork.server,
		SIDE_A_C3FAC,
		branch_memory_a,
		branch_belief_a,
		previous_a,
		catalog,
	)
	var branch_b := _c3fac_branch_bundle(
		fork.server,
		SIDE_B_C3FAC,
		branch_memory_b,
		branch_belief_b,
		previous_b,
		catalog,
	)
	var branch_wrong_side_rejected := branch_state != null and TrainerObservationBuilder.build(
		branch_state,
		SIDE_B_C3FAC,
		branch_memory_a,
	) == null

	var roles: Dictionary = {
		ROLE_ROOT_OPPONENT: _c3fac_role_report(
			ROLE_ROOT_OPPONENT,
			initial_b.get("context") as TrainerDecisionContext,
			catalog,
		),
		ROLE_OWN_DEPTH2: _c3fac_role_report(
			ROLE_OWN_DEPTH2,
			branch_a.get("context") as TrainerDecisionContext,
			catalog,
		),
		ROLE_OPPONENT_DEPTH2: _c3fac_role_report(
			ROLE_OPPONENT_DEPTH2,
			branch_b.get("context") as TrainerDecisionContext,
			catalog,
		),
	}

	var context_contract_ok := _all_roles_true(roles, "context_valid")
	var item_api_ok := _all_roles_true(roles, "item_evaluations_complete") \
		and _all_roles_true(roles, "item_metadata_matches_runtime_models") \
		and _all_roles_true(roles, "item_margin_membership_nonempty")
	var boundary_ok := branch_memory_a_observed \
		and branch_memory_b_observed \
		and initial_wrong_side_rejected \
		and branch_wrong_side_rejected \
		and not branch_rejected
	var status := NEEDS_MORE_VALIDATION
	if not context_contract_ok or not boundary_ok:
		status = BLOCKED
	elif not item_api_ok:
		status = NEEDS_ITEM_AWARE_SCORE_API
	elif _all_roles_true(roles, "item_world_opponent_inventory_absent") \
		and _all_roles_zero(roles, "actual_depth1_response_item_count") \
		and _all_roles_true(roles, "candidate_membership_switch_only"):
		status = PORTABLE_TEST_CONTRACT

	var score_equal_total := 0
	var score_compared_total := 0
	var membership_match_roles := 0
	for raw_role in roles.values():
		var role_report := raw_role as Dictionary
		score_equal_total += int(role_report.get("base_item_equal_score_count", 0))
		score_compared_total += int(role_report.get("score_pair_count", 0))
		if bool(role_report.get("base_item_margin_membership_matches", false)):
			membership_match_roles += 1

	return {
		"audit_id": AUDIT_ID_C3FAC,
		"boundary_id": BOUNDARY_ID_C3FAC,
		"tranche_status": status,
		"test_contract_scope_only": true,
		"candidate_policy_id": CANDIDATE_POLICY_C3FAC,
		"candidate_policy_scope": "switch_only",
		"candidate_margin": CANDIDATE_MARGIN_C3FAC,
		"candidate_strategy_proven_safe_globally": false,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit",
		"source_contract": source,
		"dual_history_harness": {
			"memory_a_begin_ok": memory_a_begin,
			"memory_b_begin_ok": memory_b_begin,
			"memory_a_side_id": String(memory_a.observer_side_id),
			"memory_b_side_id": String(memory_b.observer_side_id),
			"branch_memory_a_cloned": branch_memory_a != memory_a and branch_memory_a.observer_side_id == memory_a.observer_side_id,
			"branch_memory_b_cloned": branch_memory_b != memory_b and branch_memory_b.observer_side_id == memory_b.observer_side_id,
			"branch_memory_a_observed": branch_memory_a_observed,
			"branch_memory_b_observed": branch_memory_b_observed,
			"branch_events_exist": not branch_events.is_empty(),
			"branch_event_count": branch_events.size(),
			"same_branch_event_count_projected": branch_memory_a.event_log.size() == branch_memory_b.event_log.size(),
			"branch_rejected": branch_rejected,
			"branch_turn": branch_state.turn if branch_state != null else -1,
			"live_state_unchanged": live_state_before == JSON.stringify(server.snapshot()),
			"live_memory_a_unchanged": live_memory_a_before == JSON.stringify(memory_a.to_dict()),
			"live_memory_b_unchanged": live_memory_b_before == JSON.stringify(memory_b.to_dict()),
			"initial_wrong_side_memory_rejected": initial_wrong_side_rejected,
			"branch_wrong_side_memory_rejected": branch_wrong_side_rejected,
		},
		"score_semantics": {
			"portability_mode": "role_local_itemaware_recomputation_not_base_score_reuse",
			"historical_base_scores_reused": false,
			"base_membership_used_for_item_behavior": false,
			"prior_c3fu_v_evidence_transferred": false,
			"base_item_score_equivalence_required_for_port": false,
			"base_item_score_equivalence_proven": false,
			"base_item_equal_score_pairs_observed": score_equal_total,
			"base_item_score_pairs_compared": score_compared_total,
			"base_item_margin_membership_match_roles": membership_match_roles,
			"equivalence_observations_are_fixture_telemetry_only": true,
			"role_local_recalculation_required": true,
			"itemaware_search_class": "TrainerItemAwareSearch",
			"base_search_class": "TrainerMultiTurnSearch",
		},
		"roles": roles,
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
		"shared_660_reopened": false,
		"production_adapter_authorized": false,
		"behavior_integration_authorized": false,
		"production_files_modified": false,
		"fase34_open": false,
		"recommended_next_boundary": NEXT_BOUNDARY_C3FAC if status == PORTABLE_TEST_CONTRACT else null,
	}


func _c3fac_empty_report(status: String, source: Dictionary) -> Dictionary:
	return {
		"audit_id": AUDIT_ID_C3FAC,
		"boundary_id": BOUNDARY_ID_C3FAC,
		"tranche_status": status,
		"test_contract_scope_only": true,
		"candidate_policy_id": CANDIDATE_POLICY_C3FAC,
		"candidate_policy_scope": "switch_only",
		"candidate_margin": CANDIDATE_MARGIN_C3FAC,
		"candidate_strategy_proven_safe_globally": false,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit",
		"source_contract": source,
		"dual_history_harness": {},
		"score_semantics": {
			"portability_mode": "role_local_itemaware_recomputation_not_base_score_reuse",
			"historical_base_scores_reused": false,
			"base_membership_used_for_item_behavior": false,
			"prior_c3fu_v_evidence_transferred": false,
			"base_item_score_equivalence_required_for_port": false,
			"base_item_score_equivalence_proven": false,
		},
		"roles": {},
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
		"shared_660_reopened": false,
		"production_adapter_authorized": false,
		"behavior_integration_authorized": false,
		"production_files_modified": false,
		"fase34_open": false,
		"recommended_next_boundary": null,
	}


func _c3fac_initial_bundle(
	server: AuthoritativeBattleServer,
	side_id: StringName,
	memory: TrainerBattleMemory,
	catalog: DefinitionCatalog,
) -> Dictionary:
	var observation := TrainerObservationBuilder.build(server.state, side_id, memory)
	var belief := TrainerBeliefState.new()
	var belief_begin_ok := belief.begin(memory)
	var inference := TrainerBeliefInference.new(catalog)
	var seed_ok := observation != null and inference.seed_from_observation(belief, observation)
	var legal := TrainerActionSpace.from_server(server, side_id)
	var context := TrainerDecisionContext.create(observation, belief, memory, legal)
	return {
		"observation": observation,
		"belief": belief,
		"context": context,
		"belief_begin_ok": belief_begin_ok,
		"seed_ok": seed_ok,
	}


func _c3fac_branch_bundle(
	server: AuthoritativeBattleServer,
	side_id: StringName,
	memory: TrainerBattleMemory,
	belief: TrainerBeliefState,
	previous_observation: TrainerObservation,
	catalog: DefinitionCatalog,
) -> Dictionary:
	var observation := TrainerObservationBuilder.build(server.state, side_id, memory)
	var inference := TrainerBeliefInference.new(catalog)
	var update_ok := observation != null and inference.update_after_observation(
		belief,
		previous_observation,
		memory,
		observation,
	)
	var legal := TrainerActionSpace.from_server(server, side_id)
	var context := TrainerDecisionContext.create(observation, belief, memory, legal)
	return {
		"observation": observation,
		"belief": belief,
		"context": context,
		"update_ok": update_ok,
	}


func _c3fac_role_report(
	role: String,
	context: TrainerDecisionContext,
	catalog: DefinitionCatalog,
) -> Dictionary:
	if context == null or context.observation == null:
		return {
			"role": role,
			"context_valid": false,
			"side_id": "",
			"turn": -1,
		}
	var side_id := context.observation.observer_side_id
	var switches := _c3fac_switch_actions(context.legal_actions)
	var budget := TrainerSearchBudget.constrained(1, 4, 220, INNER_ACTION_CAP)
	var base_search := TrainerMultiTurnSearch.new(catalog, TrainerProfile.balanced(), budget)
	var item_search := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget)
	var base_scores: Dictionary = {}
	var item_scores: Dictionary = {}
	var score_deltas: Dictionary = {}
	var base_complete := true
	var item_complete := true
	var item_metadata_ok := true
	var equal_scores := 0
	for root_action in switches:
		var key := String(root_action.switch_instance_id)
		var base_result := base_search.evaluate(context, root_action)
		var item_result := item_search.evaluate(context, root_action)
		var base_ok := _c3fac_depth1_result_complete(base_result)
		var item_ok := _c3fac_depth1_result_complete(item_result)
		base_complete = base_complete and base_ok
		item_complete = item_complete and item_ok
		var base_score := int(base_result.get("score", -2147483648))
		var item_score := int(item_result.get("score", -2147483648))
		base_scores[key] = base_score
		item_scores[key] = item_score
		score_deltas[key] = item_score - base_score
		if base_score == item_score:
			equal_scores += 1
		var metadata := item_result.get("metadata", {}) as Dictionary
		item_metadata_ok = item_metadata_ok \
			and String(metadata.get("item_search_model", "")) == TrainerItemAwareSearch.ITEM_SEARCH_MODEL \
			and String(metadata.get("item_action_sampling_model", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL \
			and String(metadata.get("battle_item_resource_model", "")) == TrainerItemAwareWorldFactory.RESOURCE_MODEL

	var base_margin_ids := _c3fac_margin_membership(base_scores)
	var item_margin_ids := _c3fac_margin_membership(item_scores)
	var all_switch_ids := _c3fac_sorted_switch_ids(switches)
	var item_membership_switch_only := true
	for selected_id in item_margin_ids:
		if not all_switch_ids.has(selected_id):
			item_membership_switch_only = false
	var probe := _c3fac_world_and_sampler_probe(context, catalog, budget)
	return {
		"role": role,
		"context_valid": true,
		"side_id": String(side_id),
		"turn": context.observation.turn,
		"memory_snapshot_side_id": String(
			(context.memory_snapshot as Dictionary).get("observer_side_id", "")
		),
		"belief_snapshot_side_id": String(
			(context.belief_snapshot as Dictionary).get("observer_side_id", "")
		),
		"legal_action_count": context.legal_actions.size(),
		"legal_action_kind_histogram": _c3fac_action_kind_histogram(context.legal_actions),
		"legal_switch_count": switches.size(),
		"evaluated_switch_count": item_scores.size(),
		"switch_ids_for_telemetry": all_switch_ids,
		"base_scores": base_scores,
		"item_scores": item_scores,
		"item_minus_base_score_delta": score_deltas,
		"score_pair_count": switches.size(),
		"base_item_equal_score_count": equal_scores,
		"base_evaluations_complete": base_complete and base_scores.size() == switches.size() and not switches.is_empty(),
		"item_evaluations_complete": item_complete and item_scores.size() == switches.size() and not switches.is_empty(),
		"item_metadata_matches_runtime_models": item_metadata_ok and not switches.is_empty(),
		"base_margin_membership_for_telemetry": base_margin_ids,
		"item_margin_membership": item_margin_ids,
		"base_item_margin_membership_matches": base_margin_ids == item_margin_ids,
		"item_margin_membership_nonempty": not item_margin_ids.is_empty(),
		"candidate_membership_switch_only": item_membership_switch_only,
		"score_recomputed_for_role_context": item_scores.size() == switches.size() and not switches.is_empty(),
		"action_kind_accounting_explicit": true,
		"role_local_legal_item_count": int(probe.get("role_local_legal_item_count", 0)),
		"role_local_sampler_signatures_differ": bool(probe.get("role_local_sampler_signatures_differ", false)),
		"role_local_base_sample_signature": probe.get("role_local_base_sample_signature", []),
		"role_local_item_sample_signature": probe.get("role_local_item_sample_signature", []),
		"item_world_own_inventory_present": bool(probe.get("item_world_own_inventory_present", false)),
		"item_world_opponent_inventory_absent": bool(probe.get("item_world_opponent_inventory_absent", false)),
		"actual_depth1_response_item_count": int(probe.get("actual_depth1_response_item_count", -1)),
		"actual_depth1_bounded_response_item_count": int(probe.get("actual_depth1_bounded_response_item_count", -1)),
		"actual_depth1_response_kind_histogram": probe.get("actual_depth1_response_kind_histogram", {}),
		"actual_depth1_bounded_response_kind_histogram": probe.get("actual_depth1_bounded_response_kind_histogram", {}),
	}


func _c3fac_world_and_sampler_probe(
	context: TrainerDecisionContext,
	catalog: DefinitionCatalog,
	budget: TrainerSearchBudget,
) -> Dictionary:
	var item_factory := TrainerItemAwareWorldFactory.new(catalog)
	var worlds := item_factory.build(context, 1)
	var base_search := TrainerMultiTurnSearch.new(catalog, TrainerProfile.balanced(), budget)
	var item_search := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget)
	var base_local_sample := base_search._bounded_actions(context.legal_actions, INNER_ACTION_CAP)
	var item_local_sample := item_search._bounded_actions(context.legal_actions, INNER_ACTION_CAP)
	var out := {
		"role_local_legal_item_count": _c3fac_count_kind(context.legal_actions, BattleAction.ITEM),
		"role_local_base_sample_signature": _c3fac_action_signature(base_local_sample),
		"role_local_item_sample_signature": _c3fac_action_signature(item_local_sample),
		"role_local_sampler_signatures_differ": _c3fac_action_signature(base_local_sample) != _c3fac_action_signature(item_local_sample),
		"item_world_own_inventory_present": false,
		"item_world_opponent_inventory_absent": false,
		"actual_depth1_response_item_count": -1,
		"actual_depth1_bounded_response_item_count": -1,
		"actual_depth1_response_kind_histogram": {},
		"actual_depth1_bounded_response_kind_histogram": {},
	}
	if worlds.is_empty():
		return out
	var world := worlds[0] as TrainerPlausibleWorld
	if world == null or world.state == null:
		return out
	var own_inventory := world.state.item_inventory_for_side(context.observation.observer_side_id)
	var opponent_inventory := world.state.item_inventory_for_side(context.observation.opponent_side_id)
	out["item_world_own_inventory_present"] = own_inventory != null and not own_inventory.is_empty()
	out["item_world_opponent_inventory_absent"] = opponent_inventory == null
	var world_fork := BattleSimulationFork.from_state(world.state, catalog)
	if world_fork == null or world_fork.server == null:
		return out
	var responses := TrainerActionSpace.from_server(
		world_fork.server,
		context.observation.opponent_side_id,
	)
	var bounded := item_search._bounded_actions(responses, INNER_ACTION_CAP)
	out["actual_depth1_response_item_count"] = _c3fac_count_kind(responses, BattleAction.ITEM)
	out["actual_depth1_bounded_response_item_count"] = _c3fac_count_kind(bounded, BattleAction.ITEM)
	out["actual_depth1_response_kind_histogram"] = _c3fac_action_kind_histogram(responses)
	out["actual_depth1_bounded_response_kind_histogram"] = _c3fac_action_kind_histogram(bounded)
	return out


func _c3fac_source_contract() -> Dictionary:
	var item_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_item_aware_search.gd")
	var item_world_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_item_aware_world_factory.gd")
	var base_world_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_plausible_world_factory.gd")
	var multi_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_multi_turn_search.gd")
	return {
		"all_sources_loaded": not item_source.is_empty()
		and not item_world_source.is_empty()
		and not base_world_source.is_empty()
		and not multi_source.is_empty(),
		"base_search_model": TrainerMultiTurnSearch.SEARCH_MODEL_ID,
		"item_search_model": TrainerItemAwareSearch.ITEM_SEARCH_MODEL,
		"base_sampling_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"item_sampling_model": TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
		"item_resource_model": TrainerItemAwareWorldFactory.RESOURCE_MODEL,
		"base_world_factory_omits_battle_inventory": not base_world_source.contains("set_item_inventory_for_side("),
		"item_world_factory_copies_only_observer_inventory": item_world_source.contains("observation.observer_side_id")
		and item_world_source.contains("own_item_inventory")
		and item_world_source.contains("opponent_battle_item_inventory_unmodeled"),
		"multi_search_uses_shared_state_evaluator": multi_source.contains("TrainerSearchStateEvaluator.evaluate("),
		"item_search_delegates_evaluate_to_super": item_source.contains("var result := super.evaluate(context, root_action)"),
		"item_search_replaces_state_evaluator": item_source.contains("TrainerSearchStateEvaluator.evaluate("),
		"item_search_replaces_world_factory": item_source.contains("_world_factory = TrainerItemAwareWorldFactory.new(catalog)"),
		"item_search_has_three_kind_sampler": item_source.contains("for group in [moves, switches, items]"),
	}


func _c3fac_server(catalog: DefinitionCatalog) -> AuthoritativeBattleServer:
	var a0 := _c3fac_creature(
		&"c3fac_a0", ITEM_OWN_SPECIES_C3FAC,
		StatBlock.new(100, 95, 70, 60, 70, 90),
		[ITEM_CHIP_C3FAC, ITEM_FINISH_C3FAC], catalog, 72,
	)
	var a1 := _c3fac_creature(
		&"c3fac_a1", ITEM_OWN_SPECIES_C3FAC,
		StatBlock.new(120, 82, 105, 50, 95, 62),
		[ITEM_CHIP_C3FAC], catalog, 86,
	)
	var a2 := _c3fac_creature(
		&"c3fac_a2", ITEM_OWN_SPECIES_C3FAC,
		StatBlock.new(92, 125, 58, 45, 62, 112),
		[ITEM_FINISH_C3FAC, ITEM_CHIP_C3FAC], catalog, 66,
	)
	var b0 := _c3fac_creature(
		&"c3fac_b0", ITEM_FOE_SPECIES_C3FAC,
		StatBlock.new(105, 108, 75, 92, 78, 96),
		[ITEM_IDLE_C3FAC, ITEM_PRESSURE_C3FAC], catalog, 78,
	)
	var b1 := _c3fac_creature(
		&"c3fac_b1", ITEM_FOE_SPECIES_C3FAC,
		StatBlock.new(118, 90, 104, 88, 96, 64),
		[ITEM_IDLE_C3FAC, ITEM_PRESSURE_C3FAC], catalog, 88,
	)
	var b2 := _c3fac_creature(
		&"c3fac_b2", ITEM_FOE_SPECIES_C3FAC,
		StatBlock.new(94, 126, 62, 110, 68, 108),
		[ITEM_PRESSURE_C3FAC, ITEM_IDLE_C3FAC], catalog, 69,
	)
	var party_a: Array[CreatureInstance] = [a0, a1, a2]
	var party_b: Array[CreatureInstance] = [b0, b1, b2]
	var state := BattleState.create_with_parties(&"c3fac_portability", party_a, party_b, 730031)
	var inventory_a := BattleSideItemInventory.new()
	inventory_a.set_quantity(POTION_C3FAC, 1)
	inventory_a.set_quantity(HYPER_POTION_C3FAC, 1)
	var inventory_b := BattleSideItemInventory.new()
	inventory_b.set_quantity(POTION_C3FAC, 1)
	inventory_b.set_quantity(HYPER_POTION_C3FAC, 1)
	state.set_item_inventory_for_side(SIDE_A_C3FAC, inventory_a)
	state.set_item_inventory_for_side(SIDE_B_C3FAC, inventory_b)
	return AuthoritativeBattleServer.new(state, catalog)


func _c3fac_creature(
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


func _c3fac_branch_actions(state: BattleState) -> Array[BattleAction]:
	var out: Array[BattleAction] = []
	if state == null:
		return out
	var a := state.active_for_side(SIDE_A_C3FAC)
	var b := state.active_for_side(SIDE_B_C3FAC)
	if a == null or b == null:
		return out
	out.append(BattleAction.new(
		state.turn + 1,
		a.instance_id,
		ITEM_CHIP_C3FAC,
		b.instance_id,
		BattleAction.MOVE,
		SIDE_A_C3FAC,
	))
	out.append(BattleAction.new(
		state.turn + 1,
		b.instance_id,
		ITEM_IDLE_C3FAC,
		a.instance_id,
		BattleAction.MOVE,
		SIDE_B_C3FAC,
	))
	return out


func _c3fac_depth1_result_complete(result: Dictionary) -> bool:
	if result.is_empty():
		return false
	var metadata := result.get("metadata", {}) as Dictionary
	var world_count := int(metadata.get("world_count", 0))
	return world_count > 0 \
		and int(metadata.get("complete_world_count", -1)) == world_count \
		and int(metadata.get("world_coverage_basis_points", 0)) == 10000 \
		and int(metadata.get("fully_completed_depth", 0)) == 1 \
		and not bool(metadata.get("budget_exhausted", true))


func _c3fac_switch_actions(actions: Array[BattleAction]) -> Array[BattleAction]:
	var out: Array[BattleAction] = []
	for action in actions:
		if action != null and action.action_type == BattleAction.SWITCH:
			out.append(BattleAction.from_dict(action.to_dict()))
	return out


func _c3fac_margin_membership(scores: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if scores.is_empty():
		return out
	var best := -2147483648
	for value in scores.values():
		best = maxi(best, int(value))
	for raw_key in scores.keys():
		var key := String(raw_key)
		if int(scores[raw_key]) >= best - CANDIDATE_MARGIN_C3FAC:
			out.append(key)
	# Sorting is telemetry canonicalization only; selection above is score/set based.
	out.sort()
	return out


func _c3fac_sorted_switch_ids(actions: Array[BattleAction]) -> Array[String]:
	var out: Array[String] = []
	for action in actions:
		out.append(String(action.switch_instance_id))
	out.sort()
	return out


func _c3fac_action_signature(actions: Array[BattleAction]) -> Array[String]:
	var out: Array[String] = []
	for action in actions:
		if action == null:
			continue
		match action.action_type:
			BattleAction.SWITCH:
				out.append("SWITCH:%s" % String(action.switch_instance_id))
			BattleAction.ITEM:
				out.append("ITEM:%s:%s" % [String(action.item_id), String(action.target_id)])
			_:
				out.append("MOVE:%s" % String(action.move_id))
	return out


func _c3fac_action_kind_histogram(actions: Array[BattleAction]) -> Dictionary:
	var out := {"MOVE": 0, "SWITCH": 0, "ITEM": 0}
	for action in actions:
		if action == null:
			continue
		match action.action_type:
			BattleAction.SWITCH:
				out["SWITCH"] = int(out["SWITCH"]) + 1
			BattleAction.ITEM:
				out["ITEM"] = int(out["ITEM"]) + 1
			_:
				out["MOVE"] = int(out["MOVE"]) + 1
	return out


func _c3fac_count_kind(actions: Array[BattleAction], kind: StringName) -> int:
	var count := 0
	for action in actions:
		if action != null and action.action_type == kind:
			count += 1
	return count


func _c3fac_has_rejection(events: Array[BattleEvent]) -> bool:
	for event in events:
		if event != null and event.kind == BattleEvent.ACTION_REJECTED:
			return true
	return false


func _role_context_ok(role_report: Dictionary, side_id: StringName, turn: int) -> bool:
	return bool(role_report.get("context_valid", false)) \
		and String(role_report.get("side_id", "")) == String(side_id) \
		and int(role_report.get("turn", -1)) == turn \
		and String(role_report.get("memory_snapshot_side_id", "")) == String(side_id) \
		and String(role_report.get("belief_snapshot_side_id", "")) == String(side_id)


func _all_roles_true(roles: Dictionary, key: String) -> bool:
	if roles.size() != 3:
		return false
	for raw_role in roles.values():
		if not bool((raw_role as Dictionary).get(key, false)):
			return false
	return true


func _all_roles_zero(roles: Dictionary, key: String) -> bool:
	if roles.size() != 3:
		return false
	for raw_role in roles.values():
		if int((raw_role as Dictionary).get(key, -1)) != 0:
			return false
	return true


func _all_roles_positive(roles: Dictionary, key: String) -> bool:
	if roles.size() != 3:
		return false
	for raw_role in roles.values():
		if int((raw_role as Dictionary).get(key, 0)) <= 0:
			return false
	return true


func _all_roles_match_count(roles: Dictionary, actual_key: String, expected_key: String) -> bool:
	if roles.size() != 3:
		return false
	for raw_role in roles.values():
		var role_report := raw_role as Dictionary
		if int(role_report.get(actual_key, -1)) != int(role_report.get(expected_key, -2)):
			return false
	return true


func _status_matches_evidence(report: Dictionary) -> bool:
	var roles := report.get("roles", {}) as Dictionary
	var status := String(report.get("tranche_status", ""))
	var harness := report.get("dual_history_harness", {}) as Dictionary
	var context_ok := _all_roles_true(roles, "context_valid")
	var item_api_ok := _all_roles_true(roles, "item_evaluations_complete") \
		and _all_roles_true(roles, "item_metadata_matches_runtime_models") \
		and _all_roles_true(roles, "item_margin_membership_nonempty")
	var boundary_ok := bool(harness.get("branch_memory_a_observed", false)) \
		and bool(harness.get("branch_memory_b_observed", false)) \
		and bool(harness.get("initial_wrong_side_memory_rejected", false)) \
		and bool(harness.get("branch_wrong_side_memory_rejected", false)) \
		and not bool(harness.get("branch_rejected", true))
	if status == BLOCKED:
		return not context_ok or not boundary_ok
	if status == NEEDS_ITEM_AWARE_SCORE_API:
		return context_ok and boundary_ok and not item_api_ok
	if status == PORTABLE_TEST_CONTRACT:
		return context_ok \
			and boundary_ok \
			and item_api_ok \
			and _all_roles_true(roles, "item_world_opponent_inventory_absent") \
			and _all_roles_zero(roles, "actual_depth1_response_item_count") \
			and _all_roles_true(roles, "candidate_membership_switch_only")
	return status == NEEDS_MORE_VALIDATION and context_ok and boundary_ok and item_api_ok
