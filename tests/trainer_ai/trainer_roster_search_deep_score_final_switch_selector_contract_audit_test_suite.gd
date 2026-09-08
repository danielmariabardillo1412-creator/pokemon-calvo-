class_name TrainerRosterSearchDeepScoreFinalSwitchSelectorContractAuditTestSuite
extends TrainerRosterSearchFinalSwitchSelectorContractAuditTestSuite

# C3f-ah is strictly TEST/AUDIT/CONTRACT-ONLY. It validates the documentary
# 26.55 direction: margin3000 remains the SWITCH candidate screen, while final
# single-SWITCH resolution may only use a deepest fully-completed common
# ItemAware score. Exact deep ties remain explicitly unresolved.

const AUDIT_ID_C3FAH := "c3f_ah_deep_score_final_switch_selector_contract_audit_v1"
const BOUNDARY_ID_C3FAH := "validate_deepest_complete_itemaware_score_inside_margin3000_with_exact_ties_unresolved"
const DEEP_SCORE_SELECTOR_CONTRACT_VALIDATED := "DEEP_SCORE_SELECTOR_CONTRACT_VALIDATED"
const DEEP_SCORE_SELECTOR_VALIDATED_WITH_UNRESOLVED_TIES := "DEEP_SCORE_SELECTOR_VALIDATED_WITH_UNRESOLVED_TIES"
const NEEDS_POLICY_DECISION_C3FAH := "NEEDS_POLICY_DECISION"
const NEEDS_MORE_VALIDATION_C3FAH := "NEEDS_MORE_VALIDATION"
const BLOCKED_C3FAH := "BLOCKED"
const SINGLE_SWITCH_CONTRACT := "SINGLE_SWITCH_CONTRACT"
const TIE_UNRESOLVED := "TIE_UNRESOLVED"
const INCOMPLETE_COMMON_DEPTH := "INCOMPLETE_COMMON_DEPTH"
const REQUIRED_DEEP_DEPTH := 2

var _cached_c3fag_report: Dictionary = {}


# Virtual dispatch lets the inherited C3f-ag check build its expensive report
# exactly once. C3f-ah reuses that executed evidence instead of recomputing the
# C3f-ad corpus a second time inside the same FASE33 process.
func _build_c3fag_report() -> Dictionary:
	if not _cached_c3fag_report.is_empty():
		return _cached_c3fag_report.duplicate(true)
	var report := super._build_c3fag_report()
	_cached_c3fag_report = report.duplicate(true)
	return report


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_deep_score_final_switch_selector_contract()


func _test_deep_score_final_switch_selector_contract() -> void:
	var report := _build_c3fah_report()
	var reference_probes := report.get("reference_probes", []) as Array
	var lifecycle_probes := report.get("lifecycle_probes", []) as Array
	var tie_probe := report.get("synthetic_tie_probe", {}) as Dictionary
	var incomplete_probe := report.get("synthetic_incomplete_probe", {}) as Dictionary
	var status := String(report.get("tranche_status", ""))

	_check.call("deep_switch_selector_audit_id_recorded", String(report.get("audit_id", "")) == AUDIT_ID_C3FAH)
	_check.call("deep_switch_selector_boundary_id_recorded", String(report.get("boundary_id", "")) == BOUNDARY_ID_C3FAH)
	_check.call(
		"deep_switch_selector_status_is_explicit_allowed_value",
		[
			DEEP_SCORE_SELECTOR_CONTRACT_VALIDATED,
			DEEP_SCORE_SELECTOR_VALIDATED_WITH_UNRESOLVED_TIES,
			NEEDS_POLICY_DECISION_C3FAH,
			NEEDS_MORE_VALIDATION_C3FAH,
			BLOCKED_C3FAH,
		].has(status),
	)
	_check.call(
		"deep_switch_selector_margin3000_remains_membership_only",
		String(report.get("candidate_policy_id", "")) == TrainerItemAwareShadowProbe.CANDIDATE_POLICY_ID
		and int(report.get("candidate_margin", -1)) == TrainerItemAwareShadowProbe.CANDIDATE_MARGIN
		and String(report.get("candidate_policy_scope", "")) == "switch_only"
		and not bool(report.get("margin_membership_redefined_as_single_action", true)),
	)
	_check.call(
		"deep_switch_selector_reference_reuses_certified_disjoint_corpus",
		String(report.get("reference_corpus_id", "")) == CORPUS_ID_C3FAD
		and int(report.get("reference_case_count", -1)) == ROLE_CASE_COUNT_C3FAD
		and reference_probes.size() == ROLE_CASE_COUNT_C3FAD,
	)
	_check.call(
		"deep_switch_selector_reference_all_cases_semantically_complete",
		int(report.get("reference_complete_cases", -1)) == ROLE_CASE_COUNT_C3FAD
		and int(report.get("reference_incomplete_cases", -1)) == 0,
	)
	_check.call(
		"deep_switch_selector_reference_all_candidate_sets_are_multi_switch",
		int(report.get("reference_multi_candidate_cases", -1)) == ROLE_CASE_COUNT_C3FAD
		and _c3fah_all_true(reference_probes, "candidate_set_ambiguous"),
	)
	_check.call(
		"deep_switch_selector_reference_uses_depth2_only_after_complete_common_depth",
		_c3fah_all_true(reference_probes, "deep_input_complete")
		and _c3fah_all_int(reference_probes, "common_fully_completed_depth", REQUIRED_DEEP_DEPTH),
	)
	_check.call(
		"deep_switch_selector_reference_candidate_best_matches_all_legal_deep_best",
		int(report.get("reference_global_mismatch_cases", -1)) == 0
		and _c3fah_all_true(reference_probes, "candidate_best_matches_all_legal_best"),
	)
	_check.call(
		"deep_switch_selector_reference_unique_and_tie_accounting_complete",
		int(report.get("reference_unique_cases", 0)) + int(report.get("reference_tie_cases", 0))
		== ROLE_CASE_COUNT_C3FAD,
	)
	_check.call(
		"deep_switch_selector_reference_unique_selection_only_hits_global_deep_best",
		int(report.get("reference_unique_mismatch_cases", -1)) == 0
		and _c3fah_reference_unique_cases_match_global(reference_probes),
	)
	_check.call(
		"deep_switch_selector_reference_exact_ties_never_choose_hidden_winner",
		_c3fah_reference_ties_unresolved(reference_probes),
	)
	_check.call(
		"deep_switch_selector_reference_is_input_order_invariant",
		int(report.get("reference_order_invariance_failures", -1)) == 0
		and _c3fah_all_true(reference_probes, "order_invariant"),
	)
	_check.call(
		"deep_switch_selector_lifecycle_covers_current_and_branch_both_sides",
		lifecycle_probes.size() == 4
		and int(report.get("lifecycle_context_count", -1)) == 4,
	)
	_check.call(
		"deep_switch_selector_lifecycle_contexts_are_side_matching_detached",
		_c3fah_all_true(lifecycle_probes, "context_side_matching")
		and _c3fah_all_true(lifecycle_probes, "memory_snapshot_detached"),
	)
	_check.call(
		"deep_switch_selector_lifecycle_candidate_sets_come_from_certified_shadow",
		_c3fah_all_true(lifecycle_probes, "candidate_set_from_c3fag_shadow")
		and _c3fah_all_true(lifecycle_probes, "candidate_set_ambiguous"),
	)
	_check.call(
		"deep_switch_selector_lifecycle_evaluates_every_candidate_at_depth2",
		int(report.get("lifecycle_deep_complete_contexts", -1)) == 4
		and _c3fah_all_true(lifecycle_probes, "deep_evaluation_complete"),
	)
	_check.call(
		"deep_switch_selector_lifecycle_uses_common_completed_depth2",
		_c3fah_all_int(lifecycle_probes, "common_fully_completed_depth", REQUIRED_DEEP_DEPTH)
		and _c3fah_all_true(lifecycle_probes, "all_candidates_share_required_depth"),
	)
	_check.call(
		"deep_switch_selector_lifecycle_move_switch_item_accounting_remains_explicit",
		_c3fah_lifecycle_all_kinds_present(lifecycle_probes),
	)
	_check.call(
		"deep_switch_selector_lifecycle_unique_and_tie_accounting_complete",
		int(report.get("lifecycle_unique_contexts", 0)) + int(report.get("lifecycle_tie_contexts", 0)) == 4,
	)
	_check.call(
		"deep_switch_selector_lifecycle_ties_are_unresolved",
		_c3fah_lifecycle_ties_unresolved(lifecycle_probes),
	)
	_check.call(
		"deep_switch_selector_lifecycle_is_input_order_invariant",
		int(report.get("lifecycle_order_invariance_failures", -1)) == 0
		and _c3fah_all_true(lifecycle_probes, "order_invariant"),
	)
	_check.call(
		"deep_switch_selector_lifecycle_deep_eval_does_not_mutate_live_state",
		bool(report.get("live_state_unchanged", false)),
	)
	_check.call(
		"deep_switch_selector_lifecycle_deep_eval_does_not_mutate_live_memories",
		bool(report.get("live_memories_unchanged", false)),
	)
	_check.call(
		"deep_switch_selector_synthetic_exact_tie_is_explicitly_unresolved",
		String(tie_probe.get("outcome", "")) == TIE_UNRESOLVED
		and String(tie_probe.get("selected_switch_id", "")) == ""
		and (tie_probe.get("deep_best_ids", []) as Array).size() == 2,
	)
	_check.call(
		"deep_switch_selector_synthetic_incomplete_common_depth_fails_closed",
		String(incomplete_probe.get("outcome", "")) == INCOMPLETE_COMMON_DEPTH
		and String(incomplete_probe.get("selected_switch_id", "")) == "",
	)
	_check.call(
		"deep_switch_selector_never_uses_depth1_as_deep_tiebreak",
		not bool(report.get("depth1_tiebreak_used", true))
		and not bool(report.get("depth1_tiebreak_authorized", true)),
	)
	_check.call(
		"deep_switch_selector_no_order_sampler_lexical_or_rng_tiebreak",
		not bool(report.get("input_order_tiebreak_used", true))
		and not bool(report.get("lexical_tiebreak_used", true))
		and not bool(report.get("current_sampler_tiebreak_used", true))
		and not bool(report.get("live_rng_used", true)),
	)
	_check.call(
		"deep_switch_selector_no_frontier_roster_profile_or_campaign_fallbacks",
		not bool(report.get("frontier_fallback_used", true))
		and not bool(report.get("pareto_tiebreak_used", true))
		and not bool(report.get("roster_value_fallback_used", true))
		and not bool(report.get("profile_tiebreak_used", true))
		and not bool(report.get("campaign_policy_used", true))
		and not bool(report.get("recovery_policy_used", true))
		and not bool(report.get("replacement_policy_used", true))
		and not bool(report.get("hidden_belief_fallback_used", true)),
	)
	_check.call(
		"deep_switch_selector_move_switch_item_stay_separate",
		String(report.get("action_kind_contract", "")) == "MOVE_SWITCH_ITEM_explicit_no_cross_kind_deep_selector"
		and not bool(report.get("cross_kind_score_model_defined", true)),
	)
	_check.call(
		"deep_switch_selector_root_all_legal_stays_separate_from_inner_cap3",
		bool(report.get("root_fanout_all_legal_preserved", false))
		and int(report.get("inner_max_actions_per_side", -1)) == TrainerItemAwareShadowProbe.INNER_ACTION_CAP,
	)
	_check.call(
		"deep_switch_selector_scheduler_shared_budget_and_660_remain_closed",
		report.get("selected_strategy_id", "sentinel") == null
		and report.get("selected_scheduler_id", "sentinel") == null
		and report.get("selected_shared_budget", "sentinel") == null
		and not bool(report.get("shared_660_reopened", true)),
	)
	_check.call(
		"deep_switch_selector_behavior_and_action_substitution_remain_closed",
		not bool(report.get("behavior_integration_authorized", true))
		and not bool(report.get("action_substitution_authorized", true))
		and not bool(report.get("margin3000_behavior_enabled", true)),
	)
	_check.call(
		"deep_switch_selector_production_surfaces_untouched",
		not bool(report.get("production_files_modified", true))
		and not bool(report.get("brains_modified", true))
		and not bool(report.get("production_sampler_modified", true))
		and not bool(report.get("production_budget_modified", true))
		and not bool(report.get("phase_logic_modified", true)),
	)
	_check.call("deep_switch_selector_fase34_stays_closed", not bool(report.get("fase34_open", true)))
	_check.call("deep_switch_selector_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER ROSTER SEARCH DEEP-SCORE FINAL SWITCH SELECTOR CONTRACT AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fah_report() -> Dictionary:
	var base_report := _cached_c3fag_report.duplicate(true)
	if base_report.is_empty():
		base_report = _build_c3fag_report()

	var reference_probes: Array[Dictionary] = []
	var reference_complete_cases := 0
	var reference_incomplete_cases := 0
	var reference_multi_candidate_cases := 0
	var reference_unique_cases := 0
	var reference_tie_cases := 0
	var reference_global_mismatch_cases := 0
	var reference_unique_mismatch_cases := 0
	var reference_order_invariance_failures := 0
	for raw_probe in base_report.get("corpus_probes", []) as Array:
		var probe := _c3fah_reference_probe(raw_probe as Dictionary)
		reference_probes.append(probe)
		if bool(probe.get("deep_input_complete", false)):
			reference_complete_cases += 1
		else:
			reference_incomplete_cases += 1
		if bool(probe.get("candidate_set_ambiguous", false)):
			reference_multi_candidate_cases += 1
		if String(probe.get("outcome", "")) == SINGLE_SWITCH_CONTRACT:
			reference_unique_cases += 1
			if not bool(probe.get("selected_is_global_deep_best", false)):
				reference_unique_mismatch_cases += 1
		elif String(probe.get("outcome", "")) == TIE_UNRESOLVED:
			reference_tie_cases += 1
		if not bool(probe.get("candidate_best_matches_all_legal_best", false)):
			reference_global_mismatch_cases += 1
		if not bool(probe.get("order_invariant", false)):
			reference_order_invariance_failures += 1

	var lifecycle := _c3fah_build_lifecycle_probes(base_report)
	var lifecycle_probes := lifecycle.get("probes", []) as Array
	var lifecycle_deep_complete_contexts := _c3fah_count_true(lifecycle_probes, "deep_evaluation_complete")
	var lifecycle_unique_contexts := _c3fah_count_outcome(lifecycle_probes, SINGLE_SWITCH_CONTRACT)
	var lifecycle_tie_contexts := _c3fah_count_outcome(lifecycle_probes, TIE_UNRESOLVED)
	var lifecycle_order_invariance_failures := _c3fah_count_false(lifecycle_probes, "order_invariant")

	var tie_probe := _c3fah_resolve_deep_scores(
		["tie_a", "tie_b"],
		{"tie_a": 1234, "tie_b": 1234},
		{"tie_a": REQUIRED_DEEP_DEPTH, "tie_b": REQUIRED_DEEP_DEPTH},
		REQUIRED_DEEP_DEPTH,
	)
	var incomplete_probe := _c3fah_resolve_deep_scores(
		["depth_a", "depth_b"],
		{"depth_a": 2222, "depth_b": 1111},
		{"depth_a": REQUIRED_DEEP_DEPTH, "depth_b": 1},
		REQUIRED_DEEP_DEPTH,
	)

	var hard_blocked := (
		String(base_report.get("tranche_status", "")) != NEEDS_POLICY_DECISION_C3FAG
		or reference_probes.size() != ROLE_CASE_COUNT_C3FAD
		or not bool(lifecycle.get("session_ready", false))
		or not bool(lifecycle.get("branch_events_valid", false))
		or lifecycle_probes.size() != 4
		or _c3fah_count_false(lifecycle_probes, "context_side_matching") > 0
	)
	var incomplete := (
		reference_incomplete_cases > 0
		or lifecycle_deep_complete_contexts != lifecycle_probes.size()
		or _c3fah_count_false(lifecycle_probes, "all_candidates_share_required_depth") > 0
	)
	var semantic_mismatch := reference_global_mismatch_cases > 0 or reference_unique_mismatch_cases > 0
	var observed_ties := reference_tie_cases + lifecycle_tie_contexts
	var status := DEEP_SCORE_SELECTOR_CONTRACT_VALIDATED
	if hard_blocked:
		status = BLOCKED_C3FAH
	elif incomplete:
		status = NEEDS_MORE_VALIDATION_C3FAH
	elif semantic_mismatch:
		status = NEEDS_POLICY_DECISION_C3FAH
	elif observed_ties > 0:
		status = DEEP_SCORE_SELECTOR_VALIDATED_WITH_UNRESOLVED_TIES

	return {
		"audit_id": AUDIT_ID_C3FAH,
		"boundary_id": BOUNDARY_ID_C3FAH,
		"tranche_status": status,
		"candidate_policy_id": TrainerItemAwareShadowProbe.CANDIDATE_POLICY_ID,
		"candidate_margin": TrainerItemAwareShadowProbe.CANDIDATE_MARGIN,
		"candidate_policy_scope": "switch_only",
		"candidate_membership_rule": "switch_depth1_score_gte_best_switch_depth1_score_minus_3000",
		"margin_membership_redefined_as_single_action": false,
		"deep_selector_rule": "unique_max_at_common_fully_completed_itemaware_depth_else_tie_unresolved",
		"required_deep_depth": REQUIRED_DEEP_DEPTH,
		"reference_corpus_id": String(base_report.get("reference_corpus_id", "")),
		"reference_case_count": reference_probes.size(),
		"reference_complete_cases": reference_complete_cases,
		"reference_incomplete_cases": reference_incomplete_cases,
		"reference_multi_candidate_cases": reference_multi_candidate_cases,
		"reference_unique_cases": reference_unique_cases,
		"reference_tie_cases": reference_tie_cases,
		"reference_global_mismatch_cases": reference_global_mismatch_cases,
		"reference_unique_mismatch_cases": reference_unique_mismatch_cases,
		"reference_order_invariance_failures": reference_order_invariance_failures,
		"reference_probes": reference_probes,
		"lifecycle_context_count": lifecycle_probes.size(),
		"lifecycle_deep_complete_contexts": lifecycle_deep_complete_contexts,
		"lifecycle_unique_contexts": lifecycle_unique_contexts,
		"lifecycle_tie_contexts": lifecycle_tie_contexts,
		"lifecycle_order_invariance_failures": lifecycle_order_invariance_failures,
		"lifecycle_probes": lifecycle_probes,
		"live_state_unchanged": bool(lifecycle.get("live_state_unchanged", false)),
		"live_memories_unchanged": bool(lifecycle.get("live_memories_unchanged", false)),
		"synthetic_tie_probe": tie_probe,
		"synthetic_incomplete_probe": incomplete_probe,
		"candidate_strategy_proven_safe_globally": false,
		"deep_selector_proven_safe_globally": false,
		"depth1_tiebreak_authorized": false,
		"depth1_tiebreak_used": false,
		"input_order_tiebreak_used": false,
		"lexical_tiebreak_used": false,
		"current_sampler_tiebreak_used": false,
		"live_rng_used": false,
		"frontier_fallback_used": false,
		"pareto_tiebreak_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"hidden_belief_fallback_used": false,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit_no_cross_kind_deep_selector",
		"cross_kind_score_model_defined": false,
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": TrainerItemAwareShadowProbe.INNER_ACTION_CAP,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"behavior_integration_authorized": false,
		"action_substitution_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_files_modified": false,
		"brains_modified": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"phase_logic_modified": false,
		"fase34_open": false,
	}


func _c3fah_reference_probe(base_probe: Dictionary) -> Dictionary:
	var candidates := _c3fag_string_array(base_probe.get("candidate_ids", []) as Array)
	var depth2_scores := base_probe.get("depth2_all_legal_scores", {}) as Dictionary
	var global_best_ids := _c3fag_string_array(base_probe.get("global_deep_best_ids", []) as Array)
	var completed_depths: Dictionary = {}
	for candidate_id in candidates:
		completed_depths[candidate_id] = REQUIRED_DEEP_DEPTH if bool(base_probe.get("semantically_complete", false)) else 0
	var resolution := _c3fah_resolve_deep_scores(candidates, depth2_scores, completed_depths, REQUIRED_DEEP_DEPTH)
	var all_legal_ids: Array[String] = []
	for raw_id in depth2_scores.keys():
		all_legal_ids.append(String(raw_id))
	var all_legal_best_ids := _c3fag_max_score_ids(depth2_scores, all_legal_ids)
	var candidate_best_ids := _c3fag_string_array(resolution.get("deep_best_ids", []) as Array)
	var candidate_best_matches := not candidate_best_ids.is_empty()
	for candidate_id in candidate_best_ids:
		if not all_legal_best_ids.has(candidate_id):
			candidate_best_matches = false
	var selected_id := String(resolution.get("selected_switch_id", ""))
	return {
		"case_id": String(base_probe.get("case_id", "")),
		"role": String(base_probe.get("role", "")),
		"side_id": String(base_probe.get("side_id", "")),
		"candidate_ids": candidates,
		"candidate_count": candidates.size(),
		"candidate_set_ambiguous": candidates.size() > 1,
		"depth2_candidate_scores": _c3fah_score_subset(depth2_scores, candidates),
		"depth2_all_legal_scores": depth2_scores.duplicate(true),
		"global_deep_best_ids": global_best_ids,
		"all_legal_best_ids_recomputed": all_legal_best_ids,
		"deep_input_complete": String(resolution.get("outcome", "")) != INCOMPLETE_COMMON_DEPTH,
		"common_fully_completed_depth": int(resolution.get("common_fully_completed_depth", 0)),
		"outcome": String(resolution.get("outcome", "")),
		"selected_switch_id": selected_id,
		"deep_best_ids": candidate_best_ids,
		"candidate_best_matches_all_legal_best": candidate_best_matches,
		"selected_is_global_deep_best": selected_id.is_empty() or global_best_ids.has(selected_id),
		"order_invariant": bool(resolution.get("order_invariant", false)),
	}


func _c3fah_build_lifecycle_probes(base_report: Dictionary) -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return {"session_ready": false, "branch_events_valid": false, "probes": []}
	var candidate_map: Dictionary = {}
	for raw_probe in base_report.get("shadow_probes", []) as Array:
		var probe := raw_probe as Dictionary
		candidate_map[String(probe.get("label", ""))] = _c3fag_string_array(probe.get("candidate_ids", []) as Array)

	var session := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	if session == null or session.battle_state() == null:
		return {"session_ready": false, "branch_events_valid": false, "probes": []}
	var state_before := JSON.stringify(session.battle_state().to_dict())
	var memory_a_before := _memory_json(session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
	var memory_b_before := _memory_json(session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
	var probes: Array[Dictionary] = []
	probes.append(_c3fah_lifecycle_probe(
		"current_side_a",
		session.battle_state(),
		SIDE_A_C3FAF,
		session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF),
		candidate_map.get("current_side_a", []) as Array,
		catalog,
	))
	probes.append(_c3fah_lifecycle_probe(
		"current_side_b",
		session.battle_state(),
		SIDE_B_C3FAF,
		session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF),
		candidate_map.get("current_side_b", []) as Array,
		catalog,
	))

	var fork := BattleSimulationFork.from_state(session.battle_state(), catalog)
	var branch_events: Array[BattleEvent] = []
	var branch_state: BattleState = null
	if fork != null and fork.state() != null:
		var actions := _c3fae_actions(fork.state())
		if actions.size() == 2:
			branch_events = fork.submit_turn(actions)
			branch_state = fork.state()
	var branch_events_valid := branch_state != null and not branch_events.is_empty() and not _c3faf_has_rejection(branch_events)
	if branch_events_valid:
		probes.append(_c3fah_lifecycle_probe(
			"branch_side_a",
			branch_state,
			SIDE_A_C3FAF,
			session.trainer_branch_memory_snapshot_for_side(SIDE_A_C3FAF, branch_events, branch_state),
			candidate_map.get("branch_side_a", []) as Array,
			catalog,
		))
		probes.append(_c3fah_lifecycle_probe(
			"branch_side_b",
			branch_state,
			SIDE_B_C3FAF,
			session.trainer_branch_memory_snapshot_for_side(SIDE_B_C3FAF, branch_events, branch_state),
			candidate_map.get("branch_side_b", []) as Array,
			catalog,
		))

	return {
		"session_ready": true,
		"branch_events_valid": branch_events_valid,
		"probes": probes,
		"live_state_unchanged": state_before == JSON.stringify(session.battle_state().to_dict()),
		"live_memories_unchanged": (
			memory_a_before == _memory_json(session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
			and memory_b_before == _memory_json(session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
		),
	}


func _c3fah_lifecycle_probe(
	label: String,
	state: BattleState,
	side_id: StringName,
	memory: TrainerBattleMemory,
	candidate_values: Array,
	catalog: DefinitionCatalog,
) -> Dictionary:
	var candidates := _c3fag_string_array(candidate_values)
	var deep := _c3fah_evaluate_deep_candidates(state, side_id, memory, candidates, catalog)
	deep["label"] = label
	deep["candidate_set_from_c3fag_shadow"] = not candidates.is_empty()
	deep["candidate_set_ambiguous"] = candidates.size() > 1
	return deep


func _c3fah_evaluate_deep_candidates(
	state: BattleState,
	side_id: StringName,
	memory: TrainerBattleMemory,
	candidate_ids: Array[String],
	catalog: DefinitionCatalog,
) -> Dictionary:
	var blocked := _c3fah_deep_blocked(candidate_ids, "missing_input")
	if state == null or memory == null or catalog == null:
		return blocked
	if memory.observer_side_id != side_id or memory.battle_id != state.battle_id:
		blocked["blocked_reason"] = "memory_or_battle_side_mismatch"
		return blocked
	var state_clone := BattleState.from_dict(state.to_dict().duplicate(true))
	var memory_clone := TrainerBattleMemory.from_dict(memory.to_dict().duplicate(true))
	if state_clone == null or memory_clone == null:
		blocked["blocked_reason"] = "snapshot_clone_failed"
		return blocked
	var observation := TrainerObservationBuilder.build(state_clone, side_id, memory_clone)
	if observation == null or observation.observer_side_id != side_id:
		blocked["blocked_reason"] = "observation_not_sanitizable"
		return blocked
	var belief := TrainerBeliefState.new()
	if not belief.begin(memory_clone):
		blocked["blocked_reason"] = "belief_begin_failed"
		return blocked
	var inference := TrainerBeliefInference.new(catalog)
	if not inference.seed_from_observation(belief, observation):
		blocked["blocked_reason"] = "belief_seed_failed"
		return blocked
	var server := AuthoritativeBattleServer.new(state_clone, catalog)
	if server == null or server.state == null:
		blocked["blocked_reason"] = "shadow_server_failed"
		return blocked
	var legal_actions := TrainerActionSpace.from_server(server, side_id)
	var context := TrainerDecisionContext.create(observation, belief, memory_clone, legal_actions)
	if context == null:
		blocked["blocked_reason"] = "context_build_failed"
		return blocked
	var context_side_matching := (
		String((context.memory_snapshot as Dictionary).get("observer_side_id", "")) == String(side_id)
		and String((context.belief_snapshot as Dictionary).get("observer_side_id", "")) == String(side_id)
	)
	if not context_side_matching:
		blocked["blocked_reason"] = "context_side_mismatch"
		return blocked

	var switch_by_id: Dictionary = {}
	var legal_switch_count := 0
	for action in legal_actions:
		if action != null and action.action_type == BattleAction.SWITCH:
			legal_switch_count += 1
			switch_by_id[String(action.switch_instance_id)] = BattleAction.from_dict(action.to_dict())
	if candidate_ids.is_empty():
		blocked["blocked_reason"] = "empty_candidate_set"
		return blocked
	for candidate_id in candidate_ids:
		if not switch_by_id.has(candidate_id):
			blocked["blocked_reason"] = "candidate_not_legal_switch"
			return blocked

	var scores: Dictionary = {}
	var completed_depths: Dictionary = {}
	var complete_flags: Dictionary = {}
	var simulations_by_candidate: Dictionary = {}
	var all_complete := true
	var runtime_models_match := true
	for candidate_id in candidate_ids:
		var budget := TrainerSearchBudget.constrained(
			REQUIRED_DEEP_DEPTH,
			4,
			220,
			TrainerItemAwareShadowProbe.INNER_ACTION_CAP,
		)
		var search := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget)
		var result := search.evaluate(context, switch_by_id[candidate_id] as BattleAction)
		var metadata := result.get("metadata", {}) as Dictionary
		var complete := _c3fad_depth_result_complete(result, REQUIRED_DEEP_DEPTH)
		var models_match := _c3fad_itemaware_metadata_valid(metadata)
		all_complete = all_complete and complete
		runtime_models_match = runtime_models_match and models_match
		scores[candidate_id] = int(result.get("score", -2147483648))
		completed_depths[candidate_id] = int(metadata.get("fully_completed_depth", 0))
		complete_flags[candidate_id] = complete
		simulations_by_candidate[candidate_id] = int(metadata.get("simulations_used", 0))

	var resolution := _c3fah_resolve_deep_scores(candidate_ids, scores, completed_depths, REQUIRED_DEEP_DEPTH)
	return {
		"blocked_reason": "" if all_complete and runtime_models_match else "deep_evaluation_incomplete",
		"context_side_matching": context_side_matching,
		"memory_snapshot_detached": memory_clone != memory,
		"observer_side_id": String(side_id),
		"candidate_ids": candidate_ids.duplicate(),
		"candidate_count": candidate_ids.size(),
		"legal_switch_count": legal_switch_count,
		"candidate_set_is_all_legal_switches": candidate_ids.size() == legal_switch_count,
		"legal_action_kind_histogram": _c3fah_action_kind_histogram(legal_actions),
		"deep_scores": scores,
		"completed_depths": completed_depths,
		"complete_flags": complete_flags,
		"simulations_by_candidate": simulations_by_candidate,
		"runtime_models_match": runtime_models_match,
		"deep_evaluation_complete": all_complete and runtime_models_match and String(resolution.get("outcome", "")) != INCOMPLETE_COMMON_DEPTH,
		"all_candidates_share_required_depth": bool(resolution.get("all_candidates_share_required_depth", false)),
		"common_fully_completed_depth": int(resolution.get("common_fully_completed_depth", 0)),
		"outcome": String(resolution.get("outcome", "")),
		"selected_switch_id": String(resolution.get("selected_switch_id", "")),
		"deep_best_ids": resolution.get("deep_best_ids", []),
		"order_invariant": bool(resolution.get("order_invariant", false)),
		"depth1_tiebreak_used": false,
		"fallback_used": false,
	}


func _c3fah_resolve_deep_scores(
	candidate_values: Array,
	scores: Dictionary,
	completed_depths: Dictionary,
	required_depth: int,
) -> Dictionary:
	var candidates := _c3fag_string_array(candidate_values)
	if candidates.is_empty():
		return {
			"outcome": INCOMPLETE_COMMON_DEPTH,
			"selected_switch_id": "",
			"deep_best_ids": [],
			"common_fully_completed_depth": 0,
			"all_candidates_share_required_depth": false,
			"order_invariant": false,
		}
	for candidate_id in candidates:
		if not scores.has(candidate_id) or int(completed_depths.get(candidate_id, 0)) != required_depth:
			return {
				"outcome": INCOMPLETE_COMMON_DEPTH,
				"selected_switch_id": "",
				"deep_best_ids": [],
				"common_fully_completed_depth": 0,
				"all_candidates_share_required_depth": false,
				"order_invariant": false,
			}
	var forward_best := _c3fag_max_score_ids(scores, candidates)
	var reverse := candidates.duplicate()
	reverse.reverse()
	var reverse_best := _c3fag_max_score_ids(scores, reverse)
	var order_invariant := forward_best == reverse_best
	if forward_best.size() == 1:
		return {
			"outcome": SINGLE_SWITCH_CONTRACT,
			"selected_switch_id": forward_best[0],
			"deep_best_ids": forward_best,
			"common_fully_completed_depth": required_depth,
			"all_candidates_share_required_depth": true,
			"order_invariant": order_invariant,
		}
	return {
		"outcome": TIE_UNRESOLVED,
		"selected_switch_id": "",
		"deep_best_ids": forward_best,
		"common_fully_completed_depth": required_depth,
		"all_candidates_share_required_depth": true,
		"order_invariant": order_invariant,
	}


func _c3fah_deep_blocked(candidate_ids: Array[String], reason: String) -> Dictionary:
	return {
		"blocked_reason": reason,
		"context_side_matching": false,
		"memory_snapshot_detached": false,
		"candidate_ids": candidate_ids.duplicate(),
		"candidate_count": candidate_ids.size(),
		"candidate_set_is_all_legal_switches": false,
		"legal_action_kind_histogram": {"MOVE": 0, "SWITCH": 0, "ITEM": 0},
		"deep_scores": {},
		"completed_depths": {},
		"complete_flags": {},
		"simulations_by_candidate": {},
		"runtime_models_match": false,
		"deep_evaluation_complete": false,
		"all_candidates_share_required_depth": false,
		"common_fully_completed_depth": 0,
		"outcome": INCOMPLETE_COMMON_DEPTH,
		"selected_switch_id": "",
		"deep_best_ids": [],
		"order_invariant": false,
		"depth1_tiebreak_used": false,
		"fallback_used": false,
	}


func _c3fah_score_subset(scores: Dictionary, candidate_ids: Array[String]) -> Dictionary:
	var out: Dictionary = {}
	for candidate_id in candidate_ids:
		if scores.has(candidate_id):
			out[candidate_id] = int(scores[candidate_id])
	return out


func _c3fah_action_kind_histogram(actions: Array[BattleAction]) -> Dictionary:
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


func _c3fah_count_true(probes: Array, key: String) -> int:
	var count := 0
	for raw_probe in probes:
		if bool((raw_probe as Dictionary).get(key, false)):
			count += 1
	return count


func _c3fah_count_false(probes: Array, key: String) -> int:
	var count := 0
	for raw_probe in probes:
		if not bool((raw_probe as Dictionary).get(key, false)):
			count += 1
	return count


func _c3fah_count_outcome(probes: Array, outcome: String) -> int:
	var count := 0
	for raw_probe in probes:
		if String((raw_probe as Dictionary).get("outcome", "")) == outcome:
			count += 1
	return count


func _c3fah_all_true(probes: Array, key: String) -> bool:
	if probes.is_empty():
		return false
	return _c3fah_count_true(probes, key) == probes.size()


func _c3fah_all_int(probes: Array, key: String, expected: int) -> bool:
	if probes.is_empty():
		return false
	for raw_probe in probes:
		if int((raw_probe as Dictionary).get(key, -1)) != expected:
			return false
	return true


func _c3fah_reference_unique_cases_match_global(probes: Array) -> bool:
	for raw_probe in probes:
		var probe := raw_probe as Dictionary
		if String(probe.get("outcome", "")) == SINGLE_SWITCH_CONTRACT \
			and not bool(probe.get("selected_is_global_deep_best", false)):
			return false
	return true


func _c3fah_reference_ties_unresolved(probes: Array) -> bool:
	for raw_probe in probes:
		var probe := raw_probe as Dictionary
		if String(probe.get("outcome", "")) == TIE_UNRESOLVED \
			and not String(probe.get("selected_switch_id", "")).is_empty():
			return false
	return true


func _c3fah_lifecycle_ties_unresolved(probes: Array) -> bool:
	for raw_probe in probes:
		var probe := raw_probe as Dictionary
		if String(probe.get("outcome", "")) == TIE_UNRESOLVED \
			and not String(probe.get("selected_switch_id", "")).is_empty():
			return false
	return true


func _c3fah_lifecycle_all_kinds_present(probes: Array) -> bool:
	if probes.size() != 4:
		return false
	for raw_probe in probes:
		var histogram := (raw_probe as Dictionary).get("legal_action_kind_histogram", {}) as Dictionary
		if int(histogram.get("MOVE", 0)) <= 0 \
			or int(histogram.get("SWITCH", 0)) <= 0 \
			or int(histogram.get("ITEM", 0)) <= 0:
			return false
	return true
