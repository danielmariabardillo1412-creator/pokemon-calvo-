class_name TrainerItemAwareShadowProbe
extends RefCounted

# C3f-af read-only production shadow seam. It builds a side-matching sanitized
# TrainerDecisionContext from detached state/memory snapshots and evaluates every
# legal SWITCH root with TrainerItemAwareSearch. It never selects or submits an action.

const SHADOW_READY := "SHADOW_READY"
const BLOCKED := "BLOCKED"
const CANDIDATE_POLICY_ID := "depth1_margin_3000_all_legal"
const CANDIDATE_MARGIN := 3000
const INNER_ACTION_CAP := 3
const SIDE_A := &"side_a"
const SIDE_B := &"side_b"


func evaluate(
	state: BattleState,
	side_id: StringName,
	memory: TrainerBattleMemory,
	catalog: DefinitionCatalog,
) -> Dictionary:
	if state == null or memory == null or catalog == null:
		return blocked_report("missing_input", side_id)
	if not _valid_side(side_id):
		return blocked_report("invalid_side", side_id)
	if state.battle_id == &"" or memory.battle_id != state.battle_id:
		return blocked_report("battle_id_mismatch", side_id)
	if memory.observer_side_id != side_id:
		return blocked_report("memory_side_mismatch", side_id)

	var state_clone := BattleState.from_dict(state.to_dict().duplicate(true))
	var memory_clone := TrainerBattleMemory.from_dict(memory.to_dict().duplicate(true))
	if state_clone == null or memory_clone == null:
		return blocked_report("snapshot_clone_failed", side_id)
	if memory_clone.observer_side_id != side_id or memory_clone.battle_id != state_clone.battle_id:
		return blocked_report("snapshot_identity_mismatch", side_id)

	var observation := TrainerObservationBuilder.build(state_clone, side_id, memory_clone)
	if observation == null or observation.observer_side_id != side_id:
		return blocked_report("observation_not_sanitizable", side_id)
	var belief := TrainerBeliefState.new()
	if not belief.begin(memory_clone):
		return blocked_report("belief_begin_failed", side_id)
	var inference := TrainerBeliefInference.new(catalog)
	if not inference.seed_from_observation(belief, observation):
		return blocked_report("belief_seed_failed", side_id)

	var server := AuthoritativeBattleServer.new(state_clone, catalog)
	if server == null or server.state == null:
		return blocked_report("shadow_server_failed", side_id)
	var legal_actions := TrainerActionSpace.from_server(server, side_id)
	var context := TrainerDecisionContext.create(observation, belief, memory_clone, legal_actions)
	if context == null:
		return blocked_report("context_build_failed", side_id)
	if (
		String((context.memory_snapshot as Dictionary).get("observer_side_id", "")) != String(side_id)
		or String((context.belief_snapshot as Dictionary).get("observer_side_id", "")) != String(side_id)
	):
		return blocked_report("context_side_mismatch", side_id)

	var switches := _switch_actions(legal_actions)
	if switches.is_empty():
		return blocked_report("no_legal_switch_roots", side_id)
	var budget := TrainerSearchBudget.constrained(1, 4, 220, INNER_ACTION_CAP)
	var search := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget)
	var scores: Dictionary = {}
	var simulations_used := 0
	var evaluations_complete := true
	var metadata_models_match := true
	for root_action in switches:
		var result := search.evaluate(context, root_action)
		var metadata := result.get("metadata", {}) as Dictionary
		var world_count := int(metadata.get("world_count", 0))
		var complete := (
			world_count > 0
			and int(metadata.get("complete_world_count", -1)) == world_count
			and int(metadata.get("world_coverage_basis_points", 0)) == 10000
			and int(metadata.get("fully_completed_depth", 0)) == 1
			and not bool(metadata.get("budget_exhausted", true))
		)
		evaluations_complete = evaluations_complete and complete
		metadata_models_match = metadata_models_match \
			and String(metadata.get("item_search_model", "")) == TrainerItemAwareSearch.ITEM_SEARCH_MODEL \
			and String(metadata.get("item_action_sampling_model", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL \
			and String(metadata.get("battle_item_resource_model", "")) == TrainerItemAwareWorldFactory.RESOURCE_MODEL
		simulations_used += int(metadata.get("simulations_used", 0))
		scores[String(root_action.switch_instance_id)] = int(result.get("score", -2147483648))

	var switch_ids := _switch_ids(switches)
	var margin_ids := _margin_membership(scores)
	var membership_switch_only := true
	for switch_id in margin_ids:
		if not switch_ids.has(switch_id):
			membership_switch_only = false
	var ready := (
		evaluations_complete
		and metadata_models_match
		and scores.size() == switches.size()
		and not margin_ids.is_empty()
		and membership_switch_only
	)
	return {
		"tranche_status": SHADOW_READY if ready else BLOCKED,
		"blocked_reason": "" if ready else "itemaware_shadow_evaluation_incomplete",
		"battle_id": String(state_clone.battle_id),
		"observer_side_id": String(side_id),
		"opponent_side_id": String(observation.opponent_side_id),
		"turn": observation.turn,
		"context_side_matching": true,
		"memory_snapshot_side_id": String((context.memory_snapshot as Dictionary).get("observer_side_id", "")),
		"belief_snapshot_side_id": String((context.belief_snapshot as Dictionary).get("observer_side_id", "")),
		"legal_action_count": legal_actions.size(),
		"legal_action_kind_histogram": _action_kind_histogram(legal_actions),
		"legal_switch_count": switches.size(),
		"evaluated_switch_count": scores.size(),
		"switch_ids": switch_ids,
		"switch_scores": scores,
		"itemaware_evaluations_complete": evaluations_complete,
		"itemaware_metadata_matches_runtime_models": metadata_models_match,
		"simulations_used": simulations_used,
		"candidate_policy_id": CANDIDATE_POLICY_ID,
		"candidate_policy_scope": "switch_only",
		"candidate_margin": CANDIDATE_MARGIN,
		"margin3000_switch_ids": margin_ids,
		"candidate_membership_switch_only": membership_switch_only,
		"all_legal_switch_reference_evaluated": scores.size() == switches.size(),
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit",
		"shadow_result_is_telemetry_only": true,
		"shadow_action_selected": false,
		"action_substitution_authorized": false,
		"candidate_strategy_proven_safe_globally": false,
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
		"behavior_integration_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"fase34_open": false,
	}


func blocked_report(reason: String, side_id: StringName) -> Dictionary:
	return {
		"tranche_status": BLOCKED,
		"blocked_reason": reason,
		"observer_side_id": String(side_id),
		"context_side_matching": false,
		"legal_action_count": 0,
		"legal_action_kind_histogram": {"MOVE": 0, "SWITCH": 0, "ITEM": 0},
		"legal_switch_count": 0,
		"evaluated_switch_count": 0,
		"switch_ids": [],
		"switch_scores": {},
		"itemaware_evaluations_complete": false,
		"itemaware_metadata_matches_runtime_models": false,
		"simulations_used": 0,
		"candidate_policy_id": CANDIDATE_POLICY_ID,
		"candidate_policy_scope": "switch_only",
		"candidate_margin": CANDIDATE_MARGIN,
		"margin3000_switch_ids": [],
		"candidate_membership_switch_only": true,
		"all_legal_switch_reference_evaluated": false,
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit",
		"shadow_result_is_telemetry_only": true,
		"shadow_action_selected": false,
		"action_substitution_authorized": false,
		"candidate_strategy_proven_safe_globally": false,
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
		"behavior_integration_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"fase34_open": false,
	}


func _valid_side(side_id: StringName) -> bool:
	return side_id == SIDE_A or side_id == SIDE_B


func _switch_actions(actions: Array[BattleAction]) -> Array[BattleAction]:
	var out: Array[BattleAction] = []
	for action in actions:
		if action != null and action.action_type == BattleAction.SWITCH:
			out.append(BattleAction.from_dict(action.to_dict()))
	return out


func _switch_ids(actions: Array[BattleAction]) -> Array[String]:
	var out: Array[String] = []
	for action in actions:
		out.append(String(action.switch_instance_id))
	# Canonical telemetry ordering only. This order never selects a candidate.
	out.sort()
	return out


func _margin_membership(scores: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if scores.is_empty():
		return out
	var best := -2147483648
	for value in scores.values():
		best = maxi(best, int(value))
	for raw_key in scores.keys():
		var key := String(raw_key)
		if int(scores[raw_key]) >= best - CANDIDATE_MARGIN:
			out.append(key)
	# Canonical telemetry ordering only; membership above is score/set based.
	out.sort()
	return out


func _action_kind_histogram(actions: Array[BattleAction]) -> Dictionary:
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
