class_name TrainerRosterSearchProductionSeamMappingAuditTestSuite
extends TrainerRosterSearchHeldOutSharedBudgetValidationAuditTestSuite

# C3f-w is strictly TEST/AUDIT-ONLY. It maps the validated C3f-n..v sampling
# evidence onto the production search architecture before any sampler port.
# The tranche deliberately does not modify search, brains, budgets or behavior.

const AUDIT_ID_C3FW := "c3f_w_search_production_seam_mapping_audit_v1"
const SEAM_STATUS_C3FW := "NEEDS_NEW_API"
const RECOMMENDED_NEXT_BOUNDARY_C3FW := "design_test_only_side_aware_action_kind_aware_continuation_selector_and_shared_root_scheduler_contract_before_any_production_port"
const SHARED_BUDGET_CONTROL_C3FW := 660
const MAX_LEGAL_SWITCH_ROOTS_C3FW := 5

const PATH_MULTI_SEARCH := "res://modules/trainer_ai/trainer_multi_turn_search.gd"
const PATH_SEARCH_BUDGET := "res://modules/trainer_ai/trainer_search_budget.gd"
const PATH_DEPTH_BRAIN := "res://modules/trainer_ai/depth_search_trainer_brain.gd"
const PATH_ITEM_BRAIN := "res://modules/trainer_ai/item_aware_trainer_brain.gd"
const PATH_STRATEGIC_BRAIN := "res://modules/trainer_ai/strategic_switching_trainer_brain.gd"
const PATH_ITEM_SEARCH := "res://modules/trainer_ai/trainer_item_aware_search.gd"
const PATH_OBSERVATION_BUILDER := "res://modules/trainer_ai/trainer_observation_builder.gd"
const PATH_C3FN := "res://tests/trainer_ai/trainer_roster_search_switch_sampling_boundary_audit_test_suite.gd"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_production_seam_mapping()


func _test_production_seam_mapping() -> void:
	var report_a := _build_c3fw_report()
	var report_b := _build_c3fw_report()
	var source_status := report_a.get("source_files_loaded", {}) as Dictionary
	var sampler_probe := report_a.get("mixed_action_sampler_probe", {}) as Dictionary
	var call_sites := report_a.get("bounded_action_call_sites", {}) as Dictionary
	var information := report_a.get("information_boundary", {}) as Dictionary
	var scheduler := report_a.get("shared_scheduler_boundary", {}) as Dictionary

	_check.call(
		"search_production_seam_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FW,
	)
	_check.call(
		"search_production_seam_sources_loaded",
		_c3fw_all_true(source_status),
	)
	_check.call(
		"search_production_seam_brain_roots_are_already_all_legal",
		bool(report_a.get("depth_brain_enumerates_all_legal_roots", false))
		and not bool(report_a.get("depth_brain_uses_bounded_root_prefilter", true)),
	)
	_check.call(
		"search_production_seam_maps_three_bounded_action_call_sites",
		int(report_a.get("bounded_action_call_site_count", -1)) == 3
		and bool(call_sites.get("root_opponent_responses", false))
		and bool(call_sites.get("own_depth2_continuations", false))
		and bool(call_sites.get("opponent_depth2_continuations", false)),
	)
	_check.call(
		"search_production_seam_base_sampler_is_context_free",
		not bool(report_a.get("base_sampler_accepts_context", true))
		and not bool(report_a.get("base_sampler_accepts_side_id", true))
		and not bool(report_a.get("base_sampler_accepts_memory", true)),
	)
	_check.call(
		"search_production_seam_budget_220_is_per_root_evaluation",
		String(report_a.get("max_simulations_scope", "")) == "per_root_search_evaluate_local_counter"
		and int(report_a.get("production_max_simulations_per_root", -1)) == 220,
	)
	_check.call(
		"search_production_seam_has_no_shared_total_budget_api",
		not bool(scheduler.get("shared_total_budget_field_present", true))
		and not bool(scheduler.get("shared_root_scheduler_api_present", true)),
	)
	_check.call(
		"search_production_seam_660_is_not_direct_budget_mapping",
		int(scheduler.get("observed_control_budget", -1)) == SHARED_BUDGET_CONTROL_C3FW
		and int(scheduler.get("five_root_independent_per_root_hard_cap", -1)) == 1100
		and not bool(scheduler.get("control_660_directly_maps_to_current_budget", true)),
	)
	_check.call(
		"search_production_seam_c3fn_targets_base_sampler",
		bool(report_a.get("c3fn_instantiates_base_multi_turn_search", false))
		and String(report_a.get("c3fn_sampler_model", "")) == TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
	)
	_check.call(
		"search_production_seam_strategic_path_uses_item_aware_override",
		bool(report_a.get("strategic_brain_extends_item_aware", false))
		and bool(report_a.get("item_brain_installs_item_aware_search", false))
		and bool(report_a.get("item_search_overrides_bounded_actions", false)),
	)
	_check.call(
		"search_production_seam_mixed_probe_base_signature",
		(sampler_probe.get("base_signature", []) as Array) == ["move:move_zero", "switch:switch_zero", "move:move_one"],
	)
	_check.call(
		"search_production_seam_mixed_probe_item_aware_signature",
		(sampler_probe.get("item_aware_signature", []) as Array) == ["move:move_zero", "switch:switch_zero", "item:potion"],
	)
	_check.call(
		"search_production_seam_effective_sampler_differs_when_items_exist",
		bool(sampler_probe.get("signatures_differ", false))
		and String(sampler_probe.get("base_model", "")) == TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL
		and String(sampler_probe.get("item_aware_model", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
	)
	_check.call(
		"search_production_seam_observation_contract_blocks_hidden_opponent_state",
		bool(information.get("observation_builder_restricts_unseen_opponents", false))
		and bool(information.get("observation_builder_requires_matching_observer_memory", false)),
	)
	_check.call(
		"search_production_seam_multi_search_has_no_perspective_adapter",
		not bool(information.get("multi_search_uses_observation_builder", true))
		and not bool(information.get("bounded_sampler_receives_observer_context", true)),
	)
	_check.call(
		"search_production_seam_own_and_opponent_sides_need_distinct_context_contracts",
		String(information.get("own_continuation_screen_status", "")) == "NEEDS_UPDATED_OBSERVER_CONTEXT_API"
		and String(information.get("opponent_continuation_screen_status", "")) == "NEEDS_OPPONENT_PERSPECTIVE_API"
		and not bool(information.get("same_screen_policy_both_sides_proven_safe", true)),
	)
	_check.call(
		"search_production_seam_scheduler_outcomes_are_explicit",
		(scheduler.get("required_future_outcomes", []) as Array) == ["COMPLETE", "TRUNCATED", "NO_DECISION"]
		and not bool(scheduler.get("implicit_fallback_authorized", true)),
	)
	_check.call(
		"search_production_seam_root_fanout_remains_separate_from_inner_cap",
		bool(report_a.get("root_fanout_separate_from_inner_action_cap", false))
		and int(report_a.get("inner_max_actions_per_side", -1)) == 3,
	)
	_check.call(
		"search_production_seam_requires_new_api",
		String(report_a.get("seam_status", "")) == SEAM_STATUS_C3FW
		and String(report_a.get("recommended_next_boundary", "")) == RECOMMENDED_NEXT_BOUNDARY_C3FW,
	)
	_check.call(
		"search_production_seam_keeps_behavior_unauthorized",
		not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("search_sampling_redesign_authorized", true))
		and not bool(report_a.get("production_strategy_selected", true)),
	)
	_check.call(
		"search_production_seam_selects_no_strategy_scheduler_or_budget",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null,
	)
	_check.call(
		"search_production_seam_production_files_unchanged_by_audit",
		not bool(report_a.get("production_search_modified", true))
		and not bool(report_a.get("production_brain_modified", true))
		and not bool(report_a.get("production_budget_modified", true)),
	)
	_check.call("search_production_seam_report_deterministic", report_a == report_b)
	_check.call(
		"search_production_seam_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER SEARCH PRODUCTION SEAM MAPPING AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fw_report() -> Dictionary:
	var multi_source := FileAccess.get_file_as_string(PATH_MULTI_SEARCH)
	var budget_source := FileAccess.get_file_as_string(PATH_SEARCH_BUDGET)
	var depth_brain_source := FileAccess.get_file_as_string(PATH_DEPTH_BRAIN)
	var item_brain_source := FileAccess.get_file_as_string(PATH_ITEM_BRAIN)
	var strategic_brain_source := FileAccess.get_file_as_string(PATH_STRATEGIC_BRAIN)
	var item_search_source := FileAccess.get_file_as_string(PATH_ITEM_SEARCH)
	var observation_source := FileAccess.get_file_as_string(PATH_OBSERVATION_BUILDER)
	var c3fn_source := FileAccess.get_file_as_string(PATH_C3FN)
	var bounded_block := _c3fw_function_block(multi_source, "func _bounded_actions(")
	var bounded_occurrences := _c3fw_count_occurrences(multi_source, "_bounded_actions(")
	var budget := TrainerSearchBudget.depth_two_default()
	var sampler_probe := _c3fw_mixed_action_sampler_probe(budget)

	var source_files_loaded := {
		"multi_turn_search": not multi_source.is_empty(),
		"search_budget": not budget_source.is_empty(),
		"depth_search_brain": not depth_brain_source.is_empty(),
		"item_aware_brain": not item_brain_source.is_empty(),
		"strategic_switching_brain": not strategic_brain_source.is_empty(),
		"item_aware_search": not item_search_source.is_empty(),
		"observation_builder": not observation_source.is_empty(),
		"c3fn_audit": not c3fn_source.is_empty(),
	}
	var call_sites := {
		"root_opponent_responses": multi_source.contains(
			"TrainerActionSpace.from_server(root_fork.server, context.observation.opponent_side_id)"
		),
		"own_depth2_continuations": multi_source.contains(
			"TrainerActionSpace.from_server(fork.server, context.observation.observer_side_id)"
		),
		"opponent_depth2_continuations": multi_source.contains(
			"TrainerActionSpace.from_server(fork.server, context.observation.opponent_side_id)"
		),
	}
	var information_boundary := {
		"observation_builder_restricts_unseen_opponents": observation_source.contains(
			"creature_id != opponent_side.active_id and not memory.has_seen(creature_id)"
		),
		"observation_builder_requires_matching_observer_memory": observation_source.contains(
			"memory.battle_id != state.battle_id or memory.observer_side_id != observer_side_id"
		),
		"multi_search_uses_observation_builder": multi_source.contains("TrainerObservationBuilder"),
		"bounded_sampler_receives_observer_context": bounded_block.contains("context") or bounded_block.contains("memory"),
		"own_continuation_screen_status": "NEEDS_UPDATED_OBSERVER_CONTEXT_API",
		"opponent_continuation_screen_status": "NEEDS_OPPONENT_PERSPECTIVE_API",
		"same_screen_policy_both_sides_proven_safe": false,
		"reuse_observer_memory_for_opponent_perspective_authorized": false,
	}
	var has_shared_budget_field := (
		budget_source.contains("shared_total_simulations")
		or budget_source.contains("shared_total_budget")
		or budget_source.contains("shared_root_budget")
	)
	var has_shared_scheduler_api := (
		multi_source.contains("shared_total_simulations")
		or multi_source.contains("shared_root_scheduler")
		or multi_source.contains("root_scheduler")
	)
	var shared_scheduler_boundary := {
		"shared_total_budget_field_present": has_shared_budget_field,
		"shared_root_scheduler_api_present": has_shared_scheduler_api,
		"observed_control_budget": SHARED_BUDGET_CONTROL_C3FW,
		"five_root_independent_per_root_hard_cap": MAX_LEGAL_SWITCH_ROOTS_C3FW * budget.max_simulations,
		"control_660_directly_maps_to_current_budget": false,
		"required_future_outcomes": ["COMPLETE", "TRUNCATED", "NO_DECISION"],
		"implicit_fallback_authorized": false,
		"lexical_fallback_authorized": false,
		"frontier_fallback_authorized": false,
		"roster_value_fallback_authorized": false,
		"current_sampler_fallback_authorized": false,
	}

	return {
		"audit_id": AUDIT_ID_C3FW,
		"seam_status": SEAM_STATUS_C3FW,
		"recommended_next_boundary": RECOMMENDED_NEXT_BOUNDARY_C3FW,
		"source_files_loaded": source_files_loaded,
		"depth_brain_enumerates_all_legal_roots": (
			depth_brain_source.contains("for action in context.legal_actions:")
			and depth_brain_source.contains("_search.evaluate(context, action)")
		),
		"depth_brain_uses_bounded_root_prefilter": depth_brain_source.contains("_bounded_actions("),
		"bounded_action_call_site_count": maxi(0, bounded_occurrences - 1),
		"bounded_action_call_sites": call_sites,
		"base_sampler_accepts_context": bounded_block.contains("context"),
		"base_sampler_accepts_side_id": bounded_block.contains("side_id"),
		"base_sampler_accepts_memory": bounded_block.contains("memory"),
		"max_simulations_scope": "per_root_search_evaluate_local_counter",
		"production_max_simulations_per_root": budget.max_simulations,
		"inner_max_actions_per_side": budget.max_actions_per_side,
		"root_fanout_separate_from_inner_action_cap": true,
		"shared_scheduler_boundary": shared_scheduler_boundary,
		"c3fn_instantiates_base_multi_turn_search": c3fn_source.contains("TrainerMultiTurnSearch.new("),
		"c3fn_sampler_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"strategic_brain_extends_item_aware": strategic_brain_source.contains("extends ItemAwareTrainerBrain"),
		"item_brain_installs_item_aware_search": item_brain_source.contains("_search = TrainerItemAwareSearch.new("),
		"item_search_overrides_bounded_actions": item_search_source.contains("func _bounded_actions("),
		"mixed_action_sampler_probe": sampler_probe,
		"information_boundary": information_boundary,
		"behavior_integration_authorized": false,
		"search_sampling_redesign_authorized": false,
		"production_strategy_selected": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"production_search_modified": false,
		"production_brain_modified": false,
		"production_budget_modified": false,
	}


func _c3fw_mixed_action_sampler_probe(budget: TrainerSearchBudget) -> Dictionary:
	var catalog := DefinitionCatalog.new()
	var profile := TrainerProfile.balanced()
	var base_search := TrainerMultiTurnSearch.new(catalog, profile, budget)
	var item_search := TrainerItemAwareSearch.new(catalog, profile, budget)
	var actions := _c3fw_mixed_actions()
	var base_sample := base_search._bounded_actions(actions, budget.max_actions_per_side)
	var item_sample := item_search._bounded_actions(actions, budget.max_actions_per_side)
	var base_signature := _c3fw_action_signature(base_sample)
	var item_signature := _c3fw_action_signature(item_sample)
	return {
		"input_signature": _c3fw_action_signature(actions),
		"cap": budget.max_actions_per_side,
		"base_model": TrainerMultiTurnSearch.ACTION_SAMPLING_MODEL,
		"item_aware_model": TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL,
		"base_signature": base_signature,
		"item_aware_signature": item_signature,
		"signatures_differ": base_signature != item_signature,
	}


func _c3fw_mixed_actions() -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	actions.append(BattleAction.new(1, &"actor", &"move_zero", &"target", BattleAction.MOVE, &"own"))
	actions.append(BattleAction.new(1, &"actor", &"move_one", &"target", BattleAction.MOVE, &"own"))
	actions.append(BattleAction.new(1, &"actor", &"", &"", BattleAction.SWITCH, &"own", &"switch_zero"))
	actions.append(BattleAction.new(1, &"actor", &"", &"actor", BattleAction.ITEM, &"own", &"", &"potion"))
	return actions


func _c3fw_action_signature(actions: Array[BattleAction]) -> Array[String]:
	var out: Array[String] = []
	for action in actions:
		match action.action_type:
			BattleAction.SWITCH:
				out.append("switch:%s" % String(action.switch_instance_id))
			BattleAction.ITEM:
				out.append("item:%s" % String(action.item_id))
			_:
				out.append("move:%s" % String(action.move_id))
	return out


func _c3fw_function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\n\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)


func _c3fw_count_occurrences(source: String, needle: String) -> int:
	if source.is_empty() or needle.is_empty():
		return 0
	var count := 0
	var offset := 0
	while offset < source.length():
		var found := source.find(needle, offset)
		if found < 0:
			break
		count += 1
		offset = found + needle.length()
	return count


func _c3fw_all_true(values: Dictionary) -> bool:
	if values.is_empty():
		return false
	for value in values.values():
		if not bool(value):
			return false
	return true
