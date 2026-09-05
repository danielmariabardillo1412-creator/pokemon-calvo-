class_name TrainerRosterSearchSimulatedPerspectiveSwitchScoreSourceAuditTestSuite
extends TrainerRosterSearchCrossKindCompositionPolicyAuditTestSuite

# C3f-aa is strictly TEST/AUDIT-ONLY. It maps the information and score sources
# required to apply the narrow C3f-z contract at the three real ItemAware
# continuation roles. It does not add an adapter, change search, or select a
# production policy/budget.

const AUDIT_ID_C3FAA := "c3f_aa_simulated_perspective_switch_score_source_mapping_audit_v1"
const TRANCHE_STATUS_C3FAA := "NO_PRODUCTION_ADAPTER_READY"

const STATUS_EXISTING_API_SUFFICIENT := "EXISTING_API_SUFFICIENT"
const STATUS_NEEDS_ADAPTER := "NEEDS_ADAPTER"
const STATUS_BLOCKED_INFORMATION := "BLOCKED_BY_INFORMATION_BOUNDARY"

const SCORE_SOURCE_STATUS_C3FAA := "AUDITED_BASE_DEPTH1_NOT_ITEM_AWARE_EQUIVALENT"
const NEXT_BOUNDARY_C3FAA := "design_test_only_symmetric_public_history_and_branch_local_context_contract_then_validate_item_aware_depth1_switch_score_portability"

const PATH_C3FAA_MULTI_SEARCH := "res://modules/trainer_ai/trainer_multi_turn_search.gd"
const PATH_C3FAA_ITEM_SEARCH := "res://modules/trainer_ai/trainer_item_aware_search.gd"
const PATH_C3FAA_OBSERVATION_BUILDER := "res://modules/trainer_ai/trainer_observation_builder.gd"
const PATH_MEMORY := "res://modules/trainer_ai/trainer_battle_memory.gd"
const PATH_BELIEF := "res://modules/trainer_ai/trainer_belief_state.gd"
const PATH_BELIEF_INFERENCE := "res://modules/trainer_ai/trainer_belief_inference.gd"
const PATH_CONTEXT := "res://modules/trainer_ai/trainer_decision_context.gd"
const PATH_C3FAA_DEPTH_BRAIN := "res://modules/trainer_ai/depth_search_trainer_brain.gd"
const PATH_STRATEGIC_SWITCH := "res://modules/trainer_ai/trainer_strategic_switch_evaluator_v2.gd"
const PATH_C3FT := "res://tests/trainer_ai/trainer_roster_search_all_legal_screen_budget_audit_test_suite.gd"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_simulated_perspective_and_switch_score_sources()


func _test_simulated_perspective_and_switch_score_sources() -> void:
	var report_a := _build_c3faa_report()
	var report_b := _build_c3faa_report()
	var roles := report_a.get("roles", {}) as Dictionary
	var root := roles.get(ROLE_ROOT_OPPONENT, {}) as Dictionary
	var own := roles.get(ROLE_OWN_DEPTH2, {}) as Dictionary
	var opponent := roles.get(ROLE_OPPONENT_DEPTH2, {}) as Dictionary
	var score_source := report_a.get("switch_score_source", {}) as Dictionary
	var source_contract := report_a.get("source_contract", {}) as Dictionary
	var memory_probe := report_a.get("memory_sanitization_probe", {}) as Dictionary

	_check.call(
		"search_simulated_perspective_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FAA,
	)
	_check.call(
		"search_simulated_perspective_reports_no_production_adapter_ready",
		String(report_a.get("tranche_status", "")) == TRANCHE_STATUS_C3FAA,
	)
	_check.call(
		"search_simulated_perspective_all_relevant_sources_loaded",
		bool(source_contract.get("all_sources_loaded", false)),
	)
	_check.call(
		"search_simulated_perspective_maps_exact_three_item_aware_roles",
		roles.size() == 3
		and roles.has(ROLE_ROOT_OPPONENT)
		and roles.has(ROLE_OWN_DEPTH2)
		and roles.has(ROLE_OPPONENT_DEPTH2)
		and int(source_contract.get("bounded_action_call_site_count", -1)) == 3,
	)
	_check.call(
		"search_simulated_perspective_bounded_selector_still_lacks_context_side_memory",
		not bool(source_contract.get("bounded_selector_accepts_context", true))
		and not bool(source_contract.get("bounded_selector_accepts_side_id", true))
		and not bool(source_contract.get("bounded_selector_accepts_memory", true)),
	)
	_check.call(
		"search_simulated_perspective_multi_search_does_not_thread_perspective_primitives",
		not bool(source_contract.get("multi_search_uses_observation_builder", true))
		and not bool(source_contract.get("multi_search_uses_battle_memory", true))
		and not bool(source_contract.get("multi_search_uses_belief_inference", true)),
	)
	_check.call(
		"search_simulated_perspective_candidate_score_provenance_is_exact_c3ft_depth1_search",
		String(score_source.get("candidate_policy_id", "")) == CANDIDATE_POLICY_ID_C3FY
		and String(score_source.get("search_class", "")) == "TrainerMultiTurnSearch"
		and String(score_source.get("search_model_id", "")) == TrainerMultiTurnSearch.SEARCH_MODEL_ID
		and int(score_source.get("depth_turns", -1)) == 1
		and int(score_source.get("max_worlds", -1)) == 4
		and int(score_source.get("max_simulations", -1)) == 220
		and int(score_source.get("max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_simulated_perspective_candidate_score_is_not_strategic_switch_evaluator_score",
		not bool(score_source.get("uses_strategic_switch_evaluator", true))
		and String(score_source.get("strategic_switch_model_id", "")) == TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
	)
	_check.call(
		"search_simulated_perspective_audited_depth1_score_is_not_proven_item_aware_equivalent",
		String(score_source.get("score_source_status", "")) == SCORE_SOURCE_STATUS_C3FAA
		and not bool(score_source.get("item_aware_equivalence_proven", true))
		and bool(score_source.get("base_search_has_no_item_specific_semantics", false))
		and bool(score_source.get("item_search_has_item_specific_overrides", false)),
	)
	_check.call(
		"search_simulated_perspective_root_opponent_role_side_and_state_mapped",
		String(root.get("side_id", "")) == String(OPPONENT_SIDE)
		and String(root.get("simulated_state_source", "")) == "world.state_before_root_turn"
		and String(root.get("action_space_source", "")) == "root_fork.server",
	)
	_check.call(
		"search_simulated_perspective_root_opponent_requires_distinct_opponent_history",
		String(root.get("required_memory_scope", "")) == "opponent_historical_public_memory"
		and not bool(root.get("observer_private_memory_reuse_authorized", true))
		and not bool(root.get("required_prior_history_available", true)),
	)
	_check.call(
		"search_simulated_perspective_root_opponent_is_blocked_by_information_boundary",
		String(root.get("status", "")) == STATUS_BLOCKED_INFORMATION
		and bool(root.get("fails_closed", false)),
	)
	_check.call(
		"search_simulated_perspective_own_depth2_role_side_and_state_mapped",
		String(own.get("side_id", "")) == String(OBSERVER_SIDE)
		and String(own.get("simulated_state_source", "")) == "branch.fork.state_after_root_turn"
		and String(own.get("action_space_source", "")) == "branch.fork.server",
	)
	_check.call(
		"search_simulated_perspective_own_depth2_has_branch_local_reconstruction_primitives",
		bool(own.get("memory_clone_api_present", false))
		and bool(own.get("observe_events_api_present", false))
		and bool(own.get("observation_builder_api_present", false))
		and bool(own.get("belief_clone_api_present", false))
		and bool(own.get("belief_update_api_present", false))
		and bool(own.get("decision_context_create_api_present", false)),
	)
	_check.call(
		"search_simulated_perspective_own_depth2_root_events_exist_but_are_not_threaded",
		bool(own.get("root_turn_events_exist_transiently", false))
		and not bool(own.get("root_turn_events_retained_in_branch", true)),
	)
	_check.call(
		"search_simulated_perspective_own_depth2_needs_adapter_not_hidden_information",
		String(own.get("status", "")) == STATUS_NEEDS_ADAPTER
		and bool(own.get("required_prior_history_available", false))
		and not bool(own.get("information_boundary_missing", true))
		and bool(own.get("fails_closed", false)),
	)
	_check.call(
		"search_simulated_perspective_opponent_depth2_role_side_and_state_mapped",
		String(opponent.get("side_id", "")) == String(OPPONENT_SIDE)
		and String(opponent.get("simulated_state_source", "")) == "branch.fork.state_after_root_turn"
		and String(opponent.get("action_space_source", "")) == "branch.fork.server",
	)
	_check.call(
		"search_simulated_perspective_opponent_depth2_cannot_reuse_observer_history",
		String(opponent.get("required_memory_scope", "")) == "opponent_historical_public_memory"
		and not bool(opponent.get("observer_private_memory_reuse_authorized", true))
		and not bool(opponent.get("required_prior_history_available", true)),
	)
	_check.call(
		"search_simulated_perspective_opponent_depth2_is_blocked_by_information_boundary",
		String(opponent.get("status", "")) == STATUS_BLOCKED_INFORMATION
		and bool(opponent.get("fails_closed", false)),
	)
	_check.call(
		"search_simulated_perspective_observation_builder_requires_side_matching_memory",
		bool(source_contract.get("observation_builder_requires_matching_side_memory", false)),
	)
	_check.call(
		"search_simulated_perspective_context_has_only_observer_memory_snapshot",
		bool(source_contract.get("decision_context_has_memory_snapshot", false))
		and not bool(source_contract.get("decision_context_has_opponent_memory_snapshot", true)),
	)
	_check.call(
		"search_simulated_perspective_memory_public_event_envelope_strips_metadata",
		bool(memory_probe.get("roundtrip_ok", false))
		and not bool(memory_probe.get("event_has_metadata", true))
		and not bool(memory_probe.get("event_has_source_id", true))
		and bool(source_contract.get("memory_deliberately_strips_event_metadata", false)),
	)
	_check.call(
		"search_simulated_perspective_observer_snapshot_cannot_reconstruct_symmetric_ability_item_history",
		not bool(source_contract.get("symmetric_opponent_history_reconstructible_from_context", true))
		and bool(source_contract.get("observer_memory_reveal_maps_are_opponent_scoped", false)),
	)
	_check.call(
		"search_simulated_perspective_fresh_opponent_memory_would_be_sanitized_but_historically_incomplete",
		bool(source_contract.get("fresh_memory_begin_only_marks_current_opponent", false))
		and not bool(source_contract.get("fresh_opponent_memory_is_historically_equivalent", true)),
	)
	_check.call(
		"search_simulated_perspective_root_scores_must_not_be_reused_after_simulated_turn",
		bool(report_a.get("simulated_state_changes_before_depth2", false))
		and not bool(report_a.get("root_switch_score_reuse_authorized", true))
		and bool(report_a.get("role_local_score_recalculation_required", false)),
	)
	_check.call(
		"search_simulated_perspective_role_local_score_requires_role_local_context",
		bool(score_source.get("requires_role_local_decision_context", false))
		and bool(score_source.get("requires_role_local_observation", false))
		and bool(score_source.get("requires_role_local_memory_and_belief", false)),
	)
	_check.call(
		"search_simulated_perspective_item_aware_score_portability_requires_separate_validation",
		bool(score_source.get("item_aware_portability_audit_required", false))
		and String(score_source.get("item_search_model_id", "")) == TrainerItemAwareSearch.ITEM_SEARCH_MODEL
		and String(score_source.get("item_sampling_model_id", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
	)
	_check.call(
		"search_simulated_perspective_keeps_c3fz_narrow_contract_test_only",
		String(report_a.get("composition_policy_id", "")) == COMPOSITION_POLICY_ID_C3FZ
		and bool(report_a.get("c3fz_contract_test_only", false))
		and not bool(report_a.get("c3fz_production_port_authorized", true)),
	)
	_check.call(
		"search_simulated_perspective_keeps_move_switch_item_explicit",
		(report_a.get("action_kinds", []) as Array) == ["MOVE", "SWITCH", "ITEM"],
	)
	_check.call(
		"search_simulated_perspective_keeps_root_fanout_separate_from_inner_cap",
		bool(report_a.get("root_fanout_all_legal_preserved", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP
		and bool(source_contract.get("depth_brain_enumerates_all_legal_roots", false)),
	)
	_check.call(
		"search_simulated_perspective_selects_no_strategy_scheduler_or_budget",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("shared_660_reopened_as_production_budget", true)),
	)
	_check.call(
		"search_simulated_perspective_keeps_production_and_fase34_closed",
		not bool(report_a.get("production_adapter_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("production_files_modified", true))
		and not bool(report_a.get("fase34_open", true)),
	)
	_check.call(
		"search_simulated_perspective_recommends_test_only_contract_work_next",
		String(report_a.get("recommended_next_boundary", "")) == NEXT_BOUNDARY_C3FAA,
	)
	_check.call("search_simulated_perspective_report_deterministic", report_a == report_b)
	_check.call(
		"search_simulated_perspective_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH SIMULATED PERSPECTIVE + SWITCH SCORE SOURCE AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3faa_report() -> Dictionary:
	var sources := _c3faa_sources()
	var source_contract := _c3faa_source_contract(sources)
	var score_source := _c3faa_score_source(sources)
	var role_common := {
		"memory_clone_api_present": bool(source_contract.get("memory_clone_api_present", false)),
		"observe_events_api_present": bool(source_contract.get("observe_events_api_present", false)),
		"observation_builder_api_present": bool(source_contract.get("observation_builder_api_present", false)),
		"belief_clone_api_present": bool(source_contract.get("belief_clone_api_present", false)),
		"belief_update_api_present": bool(source_contract.get("belief_update_api_present", false)),
		"decision_context_create_api_present": bool(source_contract.get("decision_context_create_api_present", false)),
	}
	var roles := {
		ROLE_ROOT_OPPONENT: _c3faa_root_opponent_report(role_common),
		ROLE_OWN_DEPTH2: _c3faa_own_depth2_report(role_common, source_contract),
		ROLE_OPPONENT_DEPTH2: _c3faa_opponent_depth2_report(role_common),
	}
	return {
		"audit_id": AUDIT_ID_C3FAA,
		"tranche_status": TRANCHE_STATUS_C3FAA,
		"boundary_id": "map_sanitized_simulated_perspective_and_switch_score_sources_per_item_aware_role_before_any_adapter",
		"roles": roles,
		"source_contract": source_contract,
		"switch_score_source": score_source,
		"memory_sanitization_probe": _c3faa_memory_sanitization_probe(),
		"simulated_state_changes_before_depth2": bool(source_contract.get("root_turn_submit_present", false)),
		"root_switch_score_reuse_authorized": false,
		"role_local_score_recalculation_required": true,
		"composition_policy_id": COMPOSITION_POLICY_ID_C3FZ,
		"c3fz_contract_test_only": true,
		"c3fz_production_port_authorized": false,
		"action_kinds": ["MOVE", "SWITCH", "ITEM"],
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened_as_production_budget": false,
		"production_adapter_authorized": false,
		"behavior_integration_authorized": false,
		"production_files_modified": false,
		"fase34_open": false,
		"recommended_next_boundary": NEXT_BOUNDARY_C3FAA,
	}


func _c3faa_sources() -> Dictionary:
	return {
		"multi": FileAccess.get_file_as_string(PATH_C3FAA_MULTI_SEARCH),
		"item": FileAccess.get_file_as_string(PATH_C3FAA_ITEM_SEARCH),
		"observation": FileAccess.get_file_as_string(PATH_C3FAA_OBSERVATION_BUILDER),
		"memory": FileAccess.get_file_as_string(PATH_MEMORY),
		"belief": FileAccess.get_file_as_string(PATH_BELIEF),
		"belief_inference": FileAccess.get_file_as_string(PATH_BELIEF_INFERENCE),
		"context": FileAccess.get_file_as_string(PATH_CONTEXT),
		"depth_brain": FileAccess.get_file_as_string(PATH_C3FAA_DEPTH_BRAIN),
		"strategic_switch": FileAccess.get_file_as_string(PATH_STRATEGIC_SWITCH),
		"c3ft": FileAccess.get_file_as_string(PATH_C3FT),
	}


func _c3faa_source_contract(sources: Dictionary) -> Dictionary:
	var multi := String(sources.get("multi", ""))
	var item := String(sources.get("item", ""))
	var observation := String(sources.get("observation", ""))
	var memory := String(sources.get("memory", ""))
	var belief := String(sources.get("belief", ""))
	var belief_inference := String(sources.get("belief_inference", ""))
	var context := String(sources.get("context", ""))
	var depth_brain := String(sources.get("depth_brain", ""))
	var loaded := true
	for key in sources.keys():
		if String(sources.get(key, "")).is_empty():
			loaded = false
	return {
		"all_sources_loaded": loaded,
		"bounded_action_call_site_count": maxi(0, multi.count("_bounded_actions(") - 1),
		"bounded_selector_accepts_context": multi.contains("func _bounded_actions(context"),
		"bounded_selector_accepts_side_id": multi.contains("func _bounded_actions(side_id"),
		"bounded_selector_accepts_memory": multi.contains("func _bounded_actions(memory"),
		"multi_search_uses_observation_builder": multi.contains("TrainerObservationBuilder"),
		"multi_search_uses_battle_memory": multi.contains("TrainerBattleMemory"),
		"multi_search_uses_belief_inference": multi.contains("TrainerBeliefInference"),
		"memory_clone_api_present": memory.contains("static func from_dict(data: Dictionary) -> TrainerBattleMemory"),
		"observe_events_api_present": memory.contains("func observe_events(events: Array[BattleEvent], state: BattleState) -> bool"),
		"observation_builder_api_present": observation.contains("static func build("),
		"belief_clone_api_present": belief.contains("static func from_dict(data: Dictionary) -> TrainerBeliefState"),
		"belief_update_api_present": belief_inference.contains("func update_after_observation("),
		"decision_context_create_api_present": context.contains("static func create("),
		"observation_builder_requires_matching_side_memory": observation.contains("memory.observer_side_id != observer_side_id"),
		"decision_context_has_memory_snapshot": context.contains("var memory_snapshot: Dictionary"),
		"decision_context_has_opponent_memory_snapshot": context.contains("opponent_memory_snapshot"),
		"memory_deliberately_strips_event_metadata": (
			memory.contains("BattleEvent.metadata")
			and memory.contains("is deliberately not copied")
		),
		"observer_memory_reveal_maps_are_opponent_scoped": (
			memory.contains("if not _is_opponent_creature(state, event.actor_id):")
			and memory.contains("_revealed_abilities")
			and memory.contains("_revealed_items")
		),
		"fresh_memory_begin_only_marks_current_opponent": (
			memory.contains("func begin(state: BattleState")
			and memory.contains("_mark_current_opponent_seen(state)")
		),
		"fresh_opponent_memory_is_historically_equivalent": false,
		"symmetric_opponent_history_reconstructible_from_context": false,
		"root_turn_submit_present": multi.contains("var events := fork.submit_turn(actions)"),
		"root_turn_events_retained_in_branch": multi.contains("\"events\": events"),
		"item_search_has_item_specific_overrides": (
			item.contains("func _bounded_actions(actions: Array[BattleAction], limit: int)")
			and item.contains("BattleAction.ITEM")
			and item.contains("func _normalize_action(")
		),
		"base_search_has_item_specific_semantics": multi.contains("BattleAction.ITEM"),
		"depth_brain_enumerates_all_legal_roots": depth_brain.contains("for action in context.legal_actions"),
	}


func _c3faa_score_source(sources: Dictionary) -> Dictionary:
	var c3ft := String(sources.get("c3ft", ""))
	var multi := String(sources.get("multi", ""))
	var item := String(sources.get("item", ""))
	var strategic := String(sources.get("strategic_switch", ""))
	var exact_budget := c3ft.contains("TrainerSearchBudget.constrained(1, 4, 220, EXPECTED_DEFAULT_CAP)")
	var base_search := c3ft.contains("TrainerMultiTurnSearch.new(catalog, neutral_profile, screen_budget)")
	var evaluate_call := c3ft.contains("var result := screen_search.evaluate(context, action)")
	var score_capture := c3ft.contains("depth1_scores[candidate_id] = int(result.get(\"score\", 0))")
	return {
		"candidate_policy_id": CANDIDATE_POLICY_ID_C3FY,
		"search_class": "TrainerMultiTurnSearch" if base_search else "UNRESOLVED",
		"search_model_id": TrainerMultiTurnSearch.SEARCH_MODEL_ID if base_search else "",
		"depth_turns": 1 if exact_budget else -1,
		"max_worlds": 4 if exact_budget else -1,
		"max_simulations": 220 if exact_budget else -1,
		"max_actions_per_side": INNER_ACTION_CAP if exact_budget else -1,
		"evaluate_call_present": evaluate_call,
		"score_capture_present": score_capture,
		"uses_strategic_switch_evaluator": c3ft.contains("TrainerStrategicSwitchEvaluatorV2"),
		"strategic_switch_model_id": TrainerStrategicSwitchEvaluatorV2.MODEL_ID if not strategic.is_empty() else "",
		"base_search_has_no_item_specific_semantics": not multi.contains("BattleAction.ITEM"),
		"item_search_has_item_specific_overrides": (
			item.contains("BattleAction.ITEM")
			and item.contains("ITEM_ACTION_SAMPLING_MODEL")
		),
		"item_aware_equivalence_proven": false,
		"score_source_status": SCORE_SOURCE_STATUS_C3FAA,
		"item_search_model_id": TrainerItemAwareSearch.ITEM_SEARCH_MODEL,
		"item_sampling_model_id": TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
		"item_aware_portability_audit_required": true,
		"requires_role_local_decision_context": true,
		"requires_role_local_observation": true,
		"requires_role_local_memory_and_belief": true,
	}


func _c3faa_root_opponent_report(common: Dictionary) -> Dictionary:
	var out := common.duplicate(true)
	out.merge({
		"role": ROLE_ROOT_OPPONENT,
		"side_id": String(OPPONENT_SIDE),
		"simulated_state_source": "world.state_before_root_turn",
		"action_space_source": "root_fork.server",
		"required_perspective": "opponent_sanitized_perspective_at_world_root",
		"required_memory_scope": "opponent_historical_public_memory",
		"required_prior_history_available": false,
		"observer_private_memory_reuse_authorized": false,
		"information_boundary_missing": true,
		"score_recalculation_required": true,
		"status": STATUS_BLOCKED_INFORMATION,
		"fails_closed": true,
	})
	return out


func _c3faa_own_depth2_report(common: Dictionary, source_contract: Dictionary) -> Dictionary:
	var out := common.duplicate(true)
	out.merge({
		"role": ROLE_OWN_DEPTH2,
		"side_id": String(OBSERVER_SIDE),
		"simulated_state_source": "branch.fork.state_after_root_turn",
		"action_space_source": "branch.fork.server",
		"required_perspective": "observer_branch_local_sanitized_perspective",
		"required_memory_scope": "observer_memory_cloned_then_updated_with_branch_events",
		"required_prior_history_available": true,
		"observer_private_memory_reuse_authorized": true,
		"information_boundary_missing": false,
		"root_turn_events_exist_transiently": bool(source_contract.get("root_turn_submit_present", false)),
		"root_turn_events_retained_in_branch": bool(source_contract.get("root_turn_events_retained_in_branch", false)),
		"score_recalculation_required": true,
		"score_source_needs_item_aware_portability_validation": true,
		"status": STATUS_NEEDS_ADAPTER,
		"fails_closed": true,
	})
	return out


func _c3faa_opponent_depth2_report(common: Dictionary) -> Dictionary:
	var out := common.duplicate(true)
	out.merge({
		"role": ROLE_OPPONENT_DEPTH2,
		"side_id": String(OPPONENT_SIDE),
		"simulated_state_source": "branch.fork.state_after_root_turn",
		"action_space_source": "branch.fork.server",
		"required_perspective": "opponent_branch_local_sanitized_perspective",
		"required_memory_scope": "opponent_historical_public_memory",
		"required_prior_history_available": false,
		"observer_private_memory_reuse_authorized": false,
		"information_boundary_missing": true,
		"score_recalculation_required": true,
		"status": STATUS_BLOCKED_INFORMATION,
		"fails_closed": true,
	})
	return out


func _c3faa_memory_sanitization_probe() -> Dictionary:
	var memory := TrainerBattleMemory.from_dict({
		"schema_version": TrainerBattleMemory.SCHEMA_VERSION,
		"battle_id": "c3faa_probe",
		"observer_side_id": "observer",
		"last_observed_turn": 3,
		"seen_opponent_ids": ["opponent_active"],
		"revealed_moves": {"opponent_active": ["tackle"]},
		"revealed_abilities": {"opponent_active": "pressure"},
		"revealed_items": {"opponent_active": "leftovers"},
		"event_log": [{
			"kind": String(BattleEvent.ABILITY_TRIGGERED),
			"turn": 3,
			"actor_id": "opponent_active",
			"target_id": "observer_active",
			"move_id": "",
			"amount": 0,
		}],
	})
	var snapshot := memory.to_dict()
	var events := snapshot.get("event_log", []) as Array
	var event: Dictionary = {}
	if not events.is_empty():
		event = events[0] as Dictionary
	return {
		"roundtrip_ok": String(snapshot.get("battle_id", "")) == "c3faa_probe",
		"event_has_metadata": event.has("metadata"),
		"event_has_source_id": event.has("source_id"),
		"event_keys": _c3faa_sorted_string_keys(event),
	}


func _c3faa_sorted_string_keys(data: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in data.keys():
		out.append(String(key))
	out.sort()
	return out
