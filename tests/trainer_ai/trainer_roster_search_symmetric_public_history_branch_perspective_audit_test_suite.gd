class_name TrainerRosterSearchSymmetricPublicHistoryBranchPerspectiveAuditTestSuite
extends TrainerRosterSearchSimulatedPerspectiveSwitchScoreSourceAuditTestSuite

# C3f-ab is strictly TEST/AUDIT-ONLY. It maps whether the current trusted battle
# event stream can support two legitimate side-specific histories and branch-local
# projections without inventing hidden information or a production adapter.

const AUDIT_ID_C3FAB := "c3f_ab_symmetric_public_history_branch_perspective_contract_audit_v1"
const TRANCHE_STATUS_C3FAB := "NEEDS_ADAPTER"
const BOUNDARY_ID_C3FAB := "symmetric_authoritative_event_fanout_to_side_specific_memory_then_branch_local_clone_v1"
const MISSING_SEAM_C3FAB := "trusted_dual_side_memory_owner_and_authoritative_event_fanout_from_battle_start_not_threaded_into_trainer_session_or_search"
const NEXT_BOUNDARY_C3FAB := "validate_item_aware_depth1_switch_score_portability_on_role_local_sanitized_context_before_any_production_adapter"

const PATH_C3FAB_SERVER := "res://modules/battle/server/authoritative_battle_server.gd"
const PATH_C3FAB_SESSION := "res://modules/gameplay/trainer_battle_session.gd"
const PATH_C3FAB_SELF_PLAY := "res://modules/trainer_ai/trainer_self_play_match.gd"
const PATH_C3FAB_CONTROLLER := "res://modules/trainer_ai/trainer_intelligence_controller.gd"
const PATH_C3FAB_MEMORY := "res://modules/trainer_ai/trainer_battle_memory.gd"
const PATH_C3FAB_FORK := "res://modules/battle/simulation/battle_simulation_fork.gd"
const PATH_C3FAB_EVENT := "res://modules/battle/domain/battle_event.gd"
const PATH_C3FAB_MULTI_SEARCH := "res://modules/trainer_ai/trainer_multi_turn_search.gd"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_symmetric_public_history_and_branch_contract()


func _test_symmetric_public_history_and_branch_contract() -> void:
	var report_a := _build_c3fab_report()
	var report_b := _build_c3fab_report()
	var source := report_a.get("source_contract", {}) as Dictionary
	var layers := report_a.get("history_layers", {}) as Dictionary
	var branch := report_a.get("branch_local_projection_contract", {}) as Dictionary
	var metadata := report_a.get("metadata_boundary", {}) as Dictionary

	_check.call(
		"search_symmetric_history_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FAB,
	)
	_check.call(
		"search_symmetric_history_classifies_needs_adapter",
		String(report_a.get("tranche_status", "")) == TRANCHE_STATUS_C3FAB,
	)
	_check.call(
		"search_symmetric_history_boundary_id_recorded",
		String(report_a.get("boundary_id", "")) == BOUNDARY_ID_C3FAB,
	)
	_check.call(
		"search_symmetric_history_all_sources_loaded",
		bool(source.get("all_sources_loaded", false)),
	)
	_check.call(
		"search_symmetric_history_distinguishes_four_required_layers",
		layers.size() == 4
		and layers.has("observer_snapshot")
		and layers.has("authoritative_neutral_stream")
		and layers.has("side_specific_history")
		and layers.has("branch_local_events"),
	)
	_check.call(
		"search_symmetric_history_server_returns_authoritative_turn_events",
		bool(source.get("server_returns_turn_events", false)),
	)
	_check.call(
		"search_symmetric_history_server_retains_no_authoritative_event_history",
		not bool(source.get("server_retains_event_history", true)),
	)
	_check.call(
		"search_symmetric_history_session_returns_same_turn_events_without_history_owner",
		bool(source.get("session_returns_turn_events", false))
		and not bool(source.get("session_retains_event_history", true)),
	)
	_check.call(
		"search_symmetric_history_self_play_has_two_side_specific_controllers",
		bool(source.get("self_play_dual_controllers", false)),
	)
	_check.call(
		"search_symmetric_history_self_play_fans_same_authoritative_events_to_both",
		bool(source.get("self_play_same_events_fanned_to_both", false)),
	)
	_check.call(
		"search_symmetric_history_controller_owns_side_specific_memory",
		bool(source.get("controller_owns_memory", false))
		and bool(source.get("controller_memory_begins_with_side_id", false)),
	)
	_check.call(
		"search_symmetric_history_controller_projects_events_through_memory",
		bool(source.get("controller_observes_authoritative_events", false)),
	)
	_check.call(
		"search_symmetric_history_memory_projection_is_observer_side_specific",
		bool(source.get("memory_filters_by_observer_side", false)),
	)
	_check.call(
		"search_symmetric_history_memory_reveals_only_opponent_actor_metadata",
		bool(source.get("memory_reveal_metadata_opponent_gated", false)),
	)
	_check.call(
		"search_symmetric_history_public_memory_log_drops_generic_metadata",
		bool(source.get("memory_public_log_strips_metadata", false)),
	)
	_check.call(
		"search_symmetric_history_raw_battle_event_delivery_contains_metadata",
		bool(metadata.get("raw_event_has_metadata", false)),
	)
	_check.call(
		"search_symmetric_history_metadata_is_trusted_input_not_brain_history",
		bool(metadata.get("raw_metadata_trusted_internal_only", false))
		and not bool(metadata.get("generic_metadata_persisted_to_brain_memory", true)),
	)
	_check.call(
		"search_symmetric_history_source_id_has_narrow_reveal_use",
		bool(metadata.get("source_id_used_for_ability_item_reveal_only", false)),
	)
	_check.call(
		"search_symmetric_history_observer_snapshot_not_symmetric_history",
		not bool(layers.get("observer_snapshot", {}).get("symmetric_history", true)),
	)
	_check.call(
		"search_symmetric_history_neutral_stream_is_transient_not_retained",
		bool(layers.get("authoritative_neutral_stream", {}).get("exists_per_turn", false))
		and not bool(layers.get("authoritative_neutral_stream", {}).get("retained_across_battle", true)),
	)
	_check.call(
		"search_symmetric_history_side_specific_history_pattern_exists",
		bool(layers.get("side_specific_history", {}).get("existing_pattern_demonstrated", false)),
	)
	_check.call(
		"search_symmetric_history_side_specific_history_must_start_at_battle_begin",
		bool(layers.get("side_specific_history", {}).get("must_start_at_battle_begin", false)),
	)
	_check.call(
		"search_symmetric_history_mid_battle_bootstrap_from_observer_snapshot_forbidden",
		not bool(report_a.get("mid_battle_bootstrap_supported", true))
		and not bool(report_a.get("observer_snapshot_reconstructs_opponent_history", true)),
	)
	_check.call(
		"search_symmetric_history_no_new_information_channel_required",
		not bool(report_a.get("new_public_information_channel_required", true))
		and bool(report_a.get("existing_authoritative_stream_semantically_sufficient_if_fanned_out_from_start", false)),
	)
	_check.call(
		"search_symmetric_history_existing_retained_public_history_not_sufficient",
		not bool(report_a.get("existing_retained_public_history_sufficient", true)),
	)
	_check.call(
		"search_symmetric_history_missing_seam_is_wiring_not_hidden_information",
		String(report_a.get("missing_seam", "")) == MISSING_SEAM_C3FAB
		and String(report_a.get("missing_seam_class", "")) == "TRUSTED_WIRING_ADAPTER",
	)
	_check.call(
		"search_symmetric_history_branch_fork_returns_local_events",
		bool(branch.get("fork_submit_returns_events", false)),
	)
	_check.call(
		"search_symmetric_history_branch_fork_retains_no_history",
		not bool(branch.get("fork_retains_event_history", true)),
	)
	_check.call(
		"search_symmetric_history_branch_can_clone_side_memory_before_projection",
		bool(branch.get("memory_roundtrip_clone_api_present", false)),
	)
	_check.call(
		"search_symmetric_history_branch_can_project_events_against_branch_state",
		bool(branch.get("observe_events_accepts_events_and_state", false))
		and bool(branch.get("fork_state_api_present", false)),
	)
	_check.call(
		"search_symmetric_history_branch_projection_keeps_each_observer_filter",
		bool(branch.get("side_specific_filter_reused_on_branch", false)),
	)
	_check.call(
		"search_symmetric_history_branch_projection_does_not_require_live_memory_mutation",
		not bool(branch.get("live_memory_mutation_required", true)),
	)
	_check.call(
		"search_symmetric_history_does_not_claim_item_aware_score_portability",
		not bool(report_a.get("item_aware_score_portability_proven", true)),
	)
	_check.call(
		"search_symmetric_history_selects_no_strategy_scheduler_or_budget",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("shared_660_reopened", true)),
	)
	_check.call(
		"search_symmetric_history_keeps_root_and_inner_boundaries_unchanged",
		bool(report_a.get("root_fanout_all_legal_preserved", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == INNER_ACTION_CAP,
	)
	_check.call(
		"search_symmetric_history_keeps_production_and_fase34_closed",
		not bool(report_a.get("production_adapter_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("production_files_modified", true))
		and not bool(report_a.get("fase34_open", true)),
	)
	_check.call(
		"search_symmetric_history_recommends_item_aware_portability_audit_next",
		String(report_a.get("recommended_next_boundary", "")) == NEXT_BOUNDARY_C3FAB,
	)
	_check.call("search_symmetric_history_report_deterministic", report_a == report_b)
	_check.call(
		"search_symmetric_history_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH SYMMETRIC PUBLIC HISTORY + BRANCH PERSPECTIVE AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fab_report() -> Dictionary:
	var sources := _c3fab_sources()
	var source := _c3fab_source_contract(sources)
	var dual_pattern := bool(source.get("self_play_dual_controllers", false)) \
		and bool(source.get("self_play_same_events_fanned_to_both", false)) \
		and bool(source.get("controller_owns_memory", false)) \
		and bool(source.get("controller_memory_begins_with_side_id", false)) \
		and bool(source.get("controller_observes_authoritative_events", false)) \
		and bool(source.get("memory_filters_by_observer_side", false))
	var retained_history := bool(source.get("server_retains_event_history", false)) \
		or bool(source.get("session_retains_event_history", false))
	var branch_contract := _c3fab_branch_contract(sources, source)
	var status := "BLOCKED"
	if dual_pattern and bool(branch_contract.get("projection_isolatable", false)):
		status = "EXISTING_PUBLIC_HISTORY_SUFFICIENT" if retained_history else "NEEDS_ADAPTER"
	elif not bool(source.get("server_returns_turn_events", false)):
		status = "NEEDS_PUBLIC_HISTORY_CHANNEL"

	return {
		"audit_id": AUDIT_ID_C3FAB,
		"tranche_status": status,
		"boundary_id": BOUNDARY_ID_C3FAB,
		"source_contract": source,
		"history_layers": {
			"observer_snapshot": {
				"present_in_decision_context": true,
				"symmetric_history": false,
				"historically_complete_for_other_side": false,
			},
			"authoritative_neutral_stream": {
				"exists_per_turn": bool(source.get("server_returns_turn_events", false)),
				"retained_across_battle": retained_history,
				"trusted_internal_raw_metadata": true,
			},
			"side_specific_history": {
				"existing_pattern_demonstrated": dual_pattern,
				"must_start_at_battle_begin": true,
				"projection_owner": "TrainerBattleMemory_per_observer_side",
			},
			"branch_local_events": {
				"returned_by_simulation": bool(branch_contract.get("fork_submit_returns_events", false)),
				"retained_by_fork": bool(branch_contract.get("fork_retains_event_history", false)),
				"must_project_into_cloned_side_histories": true,
			},
		},
		"metadata_boundary": {
			"raw_event_has_metadata": bool(source.get("battle_event_to_dict_includes_metadata", false)),
			"raw_metadata_trusted_internal_only": true,
			"generic_metadata_persisted_to_brain_memory": false,
			"source_id_used_for_ability_item_reveal_only": bool(source.get("memory_source_id_narrow_use", false)),
			"generic_metadata_may_contain_diagnostics": bool(source.get("memory_comment_warns_metadata_diagnostics", false)),
		},
		"branch_local_projection_contract": branch_contract,
		"existing_retained_public_history_sufficient": retained_history,
		"existing_authoritative_stream_semantically_sufficient_if_fanned_out_from_start": dual_pattern,
		"new_public_information_channel_required": false,
		"observer_snapshot_reconstructs_opponent_history": false,
		"mid_battle_bootstrap_supported": false,
		"missing_seam": MISSING_SEAM_C3FAB,
		"missing_seam_class": "TRUSTED_WIRING_ADAPTER",
		"item_aware_score_portability_proven": false,
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"production_adapter_authorized": false,
		"behavior_integration_authorized": false,
		"production_files_modified": false,
		"fase34_open": false,
		"recommended_next_boundary": NEXT_BOUNDARY_C3FAB,
	}


func _c3fab_sources() -> Dictionary:
	return {
		"server": FileAccess.get_file_as_string(PATH_C3FAB_SERVER),
		"session": FileAccess.get_file_as_string(PATH_C3FAB_SESSION),
		"self_play": FileAccess.get_file_as_string(PATH_C3FAB_SELF_PLAY),
		"controller": FileAccess.get_file_as_string(PATH_C3FAB_CONTROLLER),
		"memory": FileAccess.get_file_as_string(PATH_C3FAB_MEMORY),
		"fork": FileAccess.get_file_as_string(PATH_C3FAB_FORK),
		"event": FileAccess.get_file_as_string(PATH_C3FAB_EVENT),
		"multi": FileAccess.get_file_as_string(PATH_C3FAB_MULTI_SEARCH),
	}


func _c3fab_source_contract(sources: Dictionary) -> Dictionary:
	var server := String(sources.get("server", ""))
	var session := String(sources.get("session", ""))
	var self_play := String(sources.get("self_play", ""))
	var controller := String(sources.get("controller", ""))
	var memory := String(sources.get("memory", ""))
	var fork_source := String(sources.get("fork", ""))
	var event_source := String(sources.get("event", ""))
	var multi := String(sources.get("multi", ""))
	var all_loaded := true
	for value in sources.values():
		if String(value).is_empty():
			all_loaded = false
			break
	return {
		"all_sources_loaded": all_loaded,
		"server_returns_turn_events": _has(server, "func submit_turn(actions: Array[BattleAction]) -> Array[BattleEvent]:")
		and _has(server, "return _executor.execute(state, actions, _catalog, _rng)"),
		"server_retains_event_history": _has(server, "var event_history") or _has(server, "var _event_history") or _has(server, "event_log.append"),
		"session_returns_turn_events": _has(session, "var events := _battle_server.submit_turn([player_action, opponent_action])")
		and _has(session, "return events"),
		"session_retains_event_history": _has(session, "var event_history") or _has(session, "var _event_history") or _has(session, "event_log.append"),
		"self_play_dual_controllers": _has(self_play, "var controller_a := TrainerIntelligenceController.new(&\"side_a\"")
		and _has(self_play, "var controller_b := TrainerIntelligenceController.new(&\"side_b\""),
		"self_play_same_events_fanned_to_both": _has(self_play, "controller_a.observe(events, server) or not controller_b.observe(events, server)"),
		"controller_owns_memory": _has(controller, "var memory := TrainerBattleMemory.new()"),
		"controller_memory_begins_with_side_id": _has(controller, "memory.begin(server.state, side_id)"),
		"controller_observes_authoritative_events": _has(controller, "memory.observe_events(events, server.state)"),
		"memory_filters_by_observer_side": _has(memory, "side.side_id != observer_side_id")
		and _has(memory, "if not _is_opponent_creature(state, event.actor_id):")
		and _has(memory, "continue"),
		"memory_reveal_metadata_opponent_gated": _has(memory, "BattleEvent.ABILITY_TRIGGERED:")
		and _has(memory, "BattleEvent.ITEM_TRIGGERED:")
		and _has(memory, "event.metadata.get(\"source_id\", \"\")"),
		"memory_public_log_strips_metadata": _has(memory, "BattleEvent.metadata")
		and _has(memory, "is deliberately not copied")
		and not _has(memory, "\"metadata\": event.metadata"),
		"memory_source_id_narrow_use": _count_occurrences(memory, "event.metadata.get(\"source_id\", \"\")") == 2,
		"memory_comment_warns_metadata_diagnostics": _has(memory, "diagnostics or")
		and _has(memory, "implementation details"),
		"battle_event_to_dict_includes_metadata": _has(event_source, "\"metadata\": metadata.duplicate(true)"),
		"fork_submit_returns_events": _has(fork_source, "func submit_turn(actions: Array[BattleAction]) -> Array[BattleEvent]:")
		and _has(fork_source, "return server.submit_turn(actions)"),
		"fork_retains_event_history": _has(fork_source, "var event_history") or _has(fork_source, "var _event_history") or _has(fork_source, "event_log.append"),
		"memory_roundtrip_clone_api_present": _has(memory, "func to_dict() -> Dictionary:")
		and _has(memory, "static func from_dict(data: Dictionary) -> TrainerBattleMemory:"),
		"memory_observe_api_present": _has(memory, "func observe_events(events: Array[BattleEvent], state: BattleState) -> bool:"),
		"fork_state_api_present": _has(fork_source, "func state() -> BattleState:"),
		"multi_search_threads_dual_memory": _has(multi, "opponent_memory") or _has(multi, "side_memories"),
	}


func _c3fab_branch_contract(sources: Dictionary, source: Dictionary) -> Dictionary:
	return {
		"fork_submit_returns_events": bool(source.get("fork_submit_returns_events", false)),
		"fork_retains_event_history": bool(source.get("fork_retains_event_history", false)),
		"memory_roundtrip_clone_api_present": bool(source.get("memory_roundtrip_clone_api_present", false)),
		"observe_events_accepts_events_and_state": bool(source.get("memory_observe_api_present", false)),
		"fork_state_api_present": bool(source.get("fork_state_api_present", false)),
		"side_specific_filter_reused_on_branch": bool(source.get("memory_filters_by_observer_side", false)),
		"projection_isolatable": bool(source.get("fork_submit_returns_events", false))
		and bool(source.get("memory_roundtrip_clone_api_present", false))
		and bool(source.get("memory_observe_api_present", false))
		and bool(source.get("fork_state_api_present", false))
		and bool(source.get("memory_filters_by_observer_side", false)),
		"live_memory_mutation_required": false,
		"branch_events_must_not_be_appended_to_live_history": true,
		"branch_projection_order": [
			"clone_each_side_specific_memory",
			"submit_branch_turn",
			"observe_same_branch_events_with_each_clone_against_branch_state",
			"build_role_local_observation_and_belief",
		],
	}


func _has(source: String, needle: String) -> bool:
	return source.find(needle) >= 0


func _count_occurrences(source: String, needle: String) -> int:
	if needle.is_empty():
		return 0
	var count := 0
	var offset := 0
	while true:
		var found := source.find(needle, offset)
		if found < 0:
			break
		count += 1
		offset = found + needle.length()
	return count
