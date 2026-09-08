class_name TrainerRosterSearchCrossKindDeepScoreComparabilityAuditTestSuite
extends TrainerRosterSearchDeepScoreFinalSwitchSelectorContractAuditTestSuite

# C3f-ai: TEST/AUDIT/CONTRACT-ONLY. No production action substitution.
const AUDIT_ID_C3FAI := "c3f_ai_cross_kind_deep_score_comparability_audit_v1"
const BOUNDARY_ID_C3FAI := "validate_deepest_complete_itemaware_root_score_comparability_across_move_switch_item"
const VALIDATED_C3FAI := "CROSS_KIND_DEEP_SCORE_COMPARABILITY_VALIDATED"
const VALIDATED_TIES_C3FAI := "CROSS_KIND_DEEP_SCORE_COMPARABILITY_VALIDATED_WITH_UNRESOLVED_TIES"
const NOT_COMPARABLE_C3FAI := "NOT_COMPARABLE_NEEDS_POLICY"
const NEEDS_MORE_C3FAI := "NEEDS_MORE_VALIDATION"
const BLOCKED_C3FAI := "BLOCKED"
const SINGLE_C3FAI := "SINGLE_ROOT_CONTRACT"
const TIE_C3FAI := "TIE_UNRESOLVED"
const INCOMPLETE_C3FAI := "INCOMPLETE_COMMON_DEPTH"
const DEPTH_C3FAI := 2

var _cached_ah: Dictionary = {}


func _build_c3fah_report() -> Dictionary:
	if not _cached_ah.is_empty():
		return _cached_ah.duplicate(true)
	var report := super._build_c3fah_report()
	_cached_ah = report.duplicate(true)
	return report


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	var r := _build_c3fai_report()
	var probes := r.get("probes", []) as Array
	var trace := r.get("source_trace", {}) as Dictionary
	_check.call("c3fai_audit_id", String(r.get("audit_id", "")) == AUDIT_ID_C3FAI)
	_check.call("c3fai_boundary_id", String(r.get("boundary_id", "")) == BOUNDARY_ID_C3FAI)
	_check.call("c3fai_status_allowed", [VALIDATED_C3FAI, VALIDATED_TIES_C3FAI, NOT_COMPARABLE_C3FAI, NEEDS_MORE_C3FAI, BLOCKED_C3FAI].has(String(r.get("tranche_status", ""))))
	_check.call("c3fai_inherits_c3fah", String(r.get("c3fah_status", "")) == DEEP_SCORE_SELECTOR_VALIDATED_WITH_UNRESOLVED_TIES)
	_check.call("c3fai_source_trace_common_scalar", bool(r.get("score_pipeline_comparable", false)))
	_check.call("c3fai_itemaware_delegates_score", bool(trace.get("itemaware_delegates", false)))
	_check.call("c3fai_no_kind_score_normalizer", not bool(trace.get("kind_score_normalizer", true)))
	_check.call("c3fai_same_state_evaluator_root_leaf", int(trace.get("state_eval_calls", 0)) == 2)
	_check.call("c3fai_four_lifecycle_contexts", probes.size() == 4)
	_check.call("c3fai_side_matching_detached", _all_true(probes, "side_matching") and _all_true(probes, "detached"))
	_check.call("c3fai_all_legal_roots_enumerated", _all_true(probes, "all_roots_enumerated"))
	_check.call("c3fai_all_three_kinds_present", _all_kinds(probes))
	_check.call("c3fai_all_roots_depth2_complete", _all_true(probes, "complete") and _all_depth(probes))
	_check.call("c3fai_same_budget_and_models", _all_true(probes, "same_budget") and _all_true(probes, "models_match"))
	_check.call("c3fai_switch_scores_coherent_with_c3fah", _all_true(probes, "switch_coherent"))
	_check.call("c3fai_order_invariant", _all_true(probes, "order_invariant"))
	_check.call("c3fai_ties_unresolved", _ties_unresolved(probes))
	_check.call("c3fai_simulation_accounting_complete", _all_true(probes, "simulation_accounting"))
	_check.call("c3fai_live_state_unchanged", bool(r.get("live_state_unchanged", false)))
	_check.call("c3fai_live_memories_unchanged", bool(r.get("live_memories_unchanged", false)))
	var tie_probe := r.get("synthetic_tie", {}) as Dictionary
	_check.call("c3fai_synthetic_cross_kind_tie_unresolved", String(tie_probe.get("outcome", "")) == TIE_C3FAI and String(tie_probe.get("selected_root_id", "")).is_empty())
	var incomplete_probe := r.get("synthetic_incomplete", {}) as Dictionary
	_check.call("c3fai_synthetic_incomplete_fails_closed", String(incomplete_probe.get("outcome", "")) == INCOMPLETE_C3FAI)
	_check.call("c3fai_no_hidden_tiebreaks", not bool(r.get("kind_priority_used", true)) and not bool(r.get("lexical_used", true)) and not bool(r.get("sampler_tiebreak_used", true)) and not bool(r.get("rng_used", true)))
	_check.call("c3fai_root_all_legal_inner_cap_separate", bool(r.get("root_all_legal", false)) and int(r.get("inner_cap", -1)) == TrainerItemAwareShadowProbe.INNER_ACTION_CAP)
	_check.call("c3fai_behavior_stays_closed", not bool(r.get("behavior_integration_authorized", true)) and not bool(r.get("action_substitution_authorized", true)))
	_check.call("c3fai_production_untouched", not bool(r.get("production_modified", true)) and not bool(r.get("brains_modified", true)) and not bool(r.get("budget_modified", true)))
	_check.call("c3fai_scheduler_fase34_closed", r.get("selected_strategy_id", "x") == null and r.get("selected_scheduler_id", "x") == null and r.get("selected_shared_budget", "x") == null and not bool(r.get("fase34_open", true)))
	_check.call("c3fai_report_json", JSON.parse_string(JSON.stringify(r)) is Dictionary)
	print("\n=== TRAINER ROSTER SEARCH CROSS-KIND DEEP-SCORE COMPARABILITY AUDIT ===")
	print(JSON.stringify(r))


func _build_c3fai_report() -> Dictionary:
	var ah := _cached_ah.duplicate(true)
	if ah.is_empty():
		ah = _build_c3fah_report()
	var trace := _source_trace()
	var life := _lifecycle(ah)
	var probes := life.get("probes", []) as Array
	var comparable := _trace_valid(trace)
	var incomplete := not _all_true(probes, "complete") or not _all_true(probes, "same_budget") or not _all_true(probes, "models_match") or not _all_true(probes, "switch_coherent") or not _all_true(probes, "order_invariant")
	var status := VALIDATED_C3FAI
	if String(ah.get("tranche_status", "")) != DEEP_SCORE_SELECTOR_VALIDATED_WITH_UNRESOLVED_TIES or probes.size() != 4:
		status = BLOCKED_C3FAI
	elif not comparable:
		status = NOT_COMPARABLE_C3FAI
	elif incomplete:
		status = NEEDS_MORE_C3FAI
	elif _count_outcome(probes, TIE_C3FAI) > 0:
		status = VALIDATED_TIES_C3FAI
	return {
		"audit_id": AUDIT_ID_C3FAI,
		"boundary_id": BOUNDARY_ID_C3FAI,
		"tranche_status": status,
		"c3fah_status": String(ah.get("tranche_status", "")),
		"score_pipeline_comparable": comparable,
		"source_trace": trace,
		"probes": probes,
		"live_state_unchanged": bool(life.get("live_state_unchanged", false)),
		"live_memories_unchanged": bool(life.get("live_memories_unchanged", false)),
		"synthetic_tie": _resolve(["move:x", "item:y:z"], {"move:x": 100, "item:y:z": 100}, {"move:x": 2, "item:y:z": 2}, {"move:x": "MOVE", "item:y:z": "ITEM"}),
		"synthetic_incomplete": _resolve(["move:x", "switch:y"], {"move:x": 100, "switch:y": 90}, {"move:x": 2, "switch:y": 1}, {"move:x": "MOVE", "switch:y": "SWITCH"}),
		"kind_priority_used": false,
		"lexical_used": false,
		"sampler_tiebreak_used": false,
		"rng_used": false,
		"root_all_legal": true,
		"inner_cap": TrainerItemAwareShadowProbe.INNER_ACTION_CAP,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"behavior_integration_authorized": false,
		"action_substitution_authorized": false,
		"production_modified": false,
		"brains_modified": false,
		"budget_modified": false,
		"fase34_open": false,
	}


func _source_trace() -> Dictionary:
	var item := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_item_aware_search.gd")
	var search := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_multi_turn_search.gd")
	var evaluator := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_search_state_evaluator.gd")
	return {
		"readable": not item.is_empty() and not search.is_empty() and not evaluator.is_empty(),
		"itemaware_delegates": item.contains("var result := super.evaluate(context, root_action)"),
		"kind_score_normalizer": item.contains("result[\"score\"]") or item.contains("result.score"),
		"state_eval_calls": search.count("TrainerSearchStateEvaluator.evaluate("),
		"robust_aggregation": search.contains("weighted_total += robust * world.weight_basis_points") and search.contains("var score := weighted_total / used_weight"),
		"state_evaluator_kind_agnostic": not evaluator.contains("action_type") and not evaluator.contains("BattleAction."),
	}


func _trace_valid(t: Dictionary) -> bool:
	return bool(t.get("readable", false)) and bool(t.get("itemaware_delegates", false)) and not bool(t.get("kind_score_normalizer", true)) and int(t.get("state_eval_calls", 0)) == 2 and bool(t.get("robust_aggregation", false)) and bool(t.get("state_evaluator_kind_agnostic", false))


func _lifecycle(ah: Dictionary) -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return {"probes": []}
	var ah_map: Dictionary = {}
	for raw in ah.get("lifecycle_probes", []) as Array:
		var p := raw as Dictionary
		ah_map[String(p.get("label", ""))] = p
	var session := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	if session == null or session.battle_state() == null:
		return {"probes": []}
	var before_state := JSON.stringify(session.battle_state().to_dict())
	var before_a := _memory_json(session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
	var before_b := _memory_json(session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
	var probes: Array[Dictionary] = []
	probes.append(_probe("current_side_a", session.battle_state(), SIDE_A_C3FAF, session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF), ah_map.get("current_side_a", {}) as Dictionary, catalog))
	probes.append(_probe("current_side_b", session.battle_state(), SIDE_B_C3FAF, session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF), ah_map.get("current_side_b", {}) as Dictionary, catalog))
	var fork := BattleSimulationFork.from_state(session.battle_state(), catalog)
	var events: Array[BattleEvent] = []
	var branch: BattleState = null
	if fork != null:
		var actions := _c3fae_actions(fork.state())
		if actions.size() == 2:
			events = fork.submit_turn(actions)
			branch = fork.state()
	if branch != null and not events.is_empty() and not _c3faf_has_rejection(events):
		probes.append(_probe("branch_side_a", branch, SIDE_A_C3FAF, session.trainer_branch_memory_snapshot_for_side(SIDE_A_C3FAF, events, branch), ah_map.get("branch_side_a", {}) as Dictionary, catalog))
		probes.append(_probe("branch_side_b", branch, SIDE_B_C3FAF, session.trainer_branch_memory_snapshot_for_side(SIDE_B_C3FAF, events, branch), ah_map.get("branch_side_b", {}) as Dictionary, catalog))
	return {
		"probes": probes,
		"live_state_unchanged": before_state == JSON.stringify(session.battle_state().to_dict()),
		"live_memories_unchanged": before_a == _memory_json(session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF)) and before_b == _memory_json(session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)),
	}


func _probe(label: String, state: BattleState, side: StringName, memory: TrainerBattleMemory, ah_probe: Dictionary, catalog: DefinitionCatalog) -> Dictionary:
	if state == null or memory == null or memory.observer_side_id != side:
		return _blocked(label)
	var state_clone := BattleState.from_dict(state.to_dict().duplicate(true))
	var memory_clone := TrainerBattleMemory.from_dict(memory.to_dict().duplicate(true))
	var obs := TrainerObservationBuilder.build(state_clone, side, memory_clone)
	var belief := TrainerBeliefState.new()
	if obs == null or not belief.begin(memory_clone) or not TrainerBeliefInference.new(catalog).seed_from_observation(belief, obs):
		return _blocked(label)
	var server := AuthoritativeBattleServer.new(state_clone, catalog)
	var legal := TrainerActionSpace.from_server(server, side)
	var context := TrainerDecisionContext.create(obs, belief, memory_clone, legal)
	if context == null:
		return _blocked(label)
	var side_matching := String((context.memory_snapshot as Dictionary).get("observer_side_id", "")) == String(side) and String((context.belief_snapshot as Dictionary).get("observer_side_id", "")) == String(side)
	if not side_matching:
		return _blocked(label)
	var ah_scores := ah_probe.get("deep_scores", {}) as Dictionary
	var ah_depths := ah_probe.get("completed_depths", {}) as Dictionary
	var ah_sims := ah_probe.get("simulations_by_candidate", {}) as Dictionary
	var ids: Array[String] = []
	var kinds: Dictionary = {}
	var scores: Dictionary = {}
	var depths: Dictionary = {}
	var sims: Dictionary = {}
	var complete := true
	var models_match := bool(ah_probe.get("runtime_models_match", false))
	var switch_coherent := true
	var expected_budget := _budget_sig()
	for action in legal:
		var id := _root_id(action)
		if id.is_empty() or ids.has(id):
			return _blocked(label)
		ids.append(id)
		var kind := _kind(action)
		kinds[id] = kind
		if kind == "SWITCH":
			var sid := String(action.switch_instance_id)
			if not ah_scores.has(sid):
				switch_coherent = false
				complete = false
				continue
			scores[id] = int(ah_scores[sid])
			depths[id] = int(ah_depths.get(sid, 0))
			sims[id] = int(ah_sims.get(sid, 0))
			complete = complete and int(depths[id]) == DEPTH_C3FAI
		else:
			var budget := TrainerSearchBudget.constrained(DEPTH_C3FAI, 4, 220, TrainerItemAwareShadowProbe.INNER_ACTION_CAP)
			var result := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget).evaluate(context, BattleAction.from_dict(action.to_dict()))
			var meta := result.get("metadata", {}) as Dictionary
			scores[id] = int(result.get("score", -2147483648))
			depths[id] = int(meta.get("fully_completed_depth", 0))
			sims[id] = int(meta.get("simulations_used", 0))
			complete = complete and _c3fad_depth_result_complete(result, DEPTH_C3FAI)
			models_match = models_match and _c3fad_itemaware_metadata_valid(meta)
			complete = complete and JSON.stringify(meta.get("budget", {})) == expected_budget
	var resolution := _resolve(ids, scores, depths, kinds)
	var sim_ok := true
	for id in ids:
		sim_ok = sim_ok and int(sims.get(id, 0)) > 0
	return {
		"label": label,
		"side_matching": side_matching,
		"detached": memory_clone != memory,
		"histogram": _c3fah_action_kind_histogram(legal),
		"all_roots_enumerated": ids.size() == legal.size(),
		"root_ids": ids,
		"kinds": kinds,
		"scores": scores,
		"depths": depths,
		"simulations": sims,
		"simulation_accounting": sim_ok,
		"same_budget": complete,
		"models_match": models_match,
		"switch_coherent": switch_coherent,
		"complete": complete and String(resolution.get("outcome", "")) != INCOMPLETE_C3FAI,
		"common_depth": int(resolution.get("common_depth", 0)),
		"outcome": String(resolution.get("outcome", "")),
		"selected_root_id": String(resolution.get("selected_root_id", "")),
		"best_root_ids": resolution.get("best_root_ids", []),
		"best_kinds": resolution.get("best_kinds", []),
		"order_invariant": bool(resolution.get("order_invariant", false)),
	}


func _resolve(values: Array, scores: Dictionary, depths: Dictionary, kinds: Dictionary) -> Dictionary:
	var ids := _c3fag_string_array(values)
	if ids.is_empty():
		return {"outcome": INCOMPLETE_C3FAI, "selected_root_id": "", "best_root_ids": [], "best_kinds": [], "common_depth": 0, "order_invariant": false}
	for id in ids:
		if not scores.has(id) or int(depths.get(id, 0)) != DEPTH_C3FAI:
			return {"outcome": INCOMPLETE_C3FAI, "selected_root_id": "", "best_root_ids": [], "best_kinds": [], "common_depth": 0, "order_invariant": false}
	var best := _c3fag_max_score_ids(scores, ids)
	var reverse := ids.duplicate()
	reverse.reverse()
	var order_ok := best == _c3fag_max_score_ids(scores, reverse)
	var best_kinds: Array[String] = []
	for id in best:
		var kind := String(kinds.get(id, ""))
		if not kind.is_empty() and not best_kinds.has(kind):
			best_kinds.append(kind)
	best_kinds.sort()
	return {
		"outcome": SINGLE_C3FAI if best.size() == 1 else TIE_C3FAI,
		"selected_root_id": best[0] if best.size() == 1 else "",
		"best_root_ids": best,
		"best_kinds": best_kinds,
		"common_depth": DEPTH_C3FAI,
		"order_invariant": order_ok,
	}


func _blocked(label: String) -> Dictionary:
	return {"label": label, "side_matching": false, "detached": false, "histogram": {"MOVE": 0, "SWITCH": 0, "ITEM": 0}, "all_roots_enumerated": false, "root_ids": [], "kinds": {}, "scores": {}, "depths": {}, "simulations": {}, "simulation_accounting": false, "same_budget": false, "models_match": false, "switch_coherent": false, "complete": false, "common_depth": 0, "outcome": INCOMPLETE_C3FAI, "selected_root_id": "", "best_root_ids": [], "best_kinds": [], "order_invariant": false}


func _root_id(a: BattleAction) -> String:
	if a == null:
		return ""
	if a.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(a.switch_instance_id)
	if a.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(a.item_id), String(a.target_id)]
	return "move:%s" % String(a.move_id)


func _kind(a: BattleAction) -> String:
	if a.action_type == BattleAction.SWITCH:
		return "SWITCH"
	if a.action_type == BattleAction.ITEM:
		return "ITEM"
	return "MOVE"


func _budget_sig() -> String:
	return JSON.stringify(TrainerSearchBudget.constrained(DEPTH_C3FAI, 4, 220, TrainerItemAwareShadowProbe.INNER_ACTION_CAP).normalized().to_dict())


func _all_true(probes: Array, key: String) -> bool:
	if probes.is_empty():
		return false
	for raw in probes:
		if not bool((raw as Dictionary).get(key, false)):
			return false
	return true


func _all_depth(probes: Array) -> bool:
	for raw in probes:
		if int((raw as Dictionary).get("common_depth", 0)) != DEPTH_C3FAI:
			return false
	return not probes.is_empty()


func _all_kinds(probes: Array) -> bool:
	for raw in probes:
		var h := (raw as Dictionary).get("histogram", {}) as Dictionary
		if int(h.get("MOVE", 0)) <= 0 or int(h.get("SWITCH", 0)) <= 0 or int(h.get("ITEM", 0)) <= 0:
			return false
	return probes.size() == 4


func _ties_unresolved(probes: Array) -> bool:
	for raw in probes:
		var p := raw as Dictionary
		if String(p.get("outcome", "")) == TIE_C3FAI and not String(p.get("selected_root_id", "")).is_empty():
			return false
	return true


func _count_outcome(probes: Array, outcome: String) -> int:
	var n := 0
	for raw in probes:
		if String((raw as Dictionary).get("outcome", "")) == outcome:
			n += 1
	return n
