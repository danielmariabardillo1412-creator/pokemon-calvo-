class_name TrainerItemAwareActionProposal
extends RefCounted

# C3f-aj production proposal seam. It may compute a detached, auditable action
# proposal from all legal MOVE/SWITCH/ITEM roots, but it never submits or replaces
# an authoritative BattleAction. Exact ties and incomplete depth remain fail-closed.

const PROPOSAL_READY := "PROPOSAL_READY"
const TIE_UNRESOLVED := "TIE_UNRESOLVED"
const BLOCKED := "BLOCKED"
const SINGLE_ROOT_CONTRACT := "SINGLE_ROOT_CONTRACT"
const INCOMPLETE_COMMON_DEPTH := "INCOMPLETE_COMMON_DEPTH"
const PROPOSAL_MODEL := "itemaware_all_legal_deep2_unique_max_v1"
const REQUIRED_DEPTH := 2
const MAX_WORLDS := 4
const MAX_SIMULATIONS := 220
const INNER_ACTION_CAP := TrainerItemAwareShadowProbe.INNER_ACTION_CAP
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
	if not TrainerBeliefInference.new(catalog).seed_from_observation(belief, observation):
		return blocked_report("belief_seed_failed", side_id)

	var server := AuthoritativeBattleServer.new(state_clone, catalog)
	if server == null or server.state == null:
		return blocked_report("proposal_server_failed", side_id)
	var legal_actions := TrainerActionSpace.from_server(server, side_id)
	if legal_actions.is_empty():
		return blocked_report("no_legal_roots", side_id)
	var context := TrainerDecisionContext.create(observation, belief, memory_clone, legal_actions)
	if context == null:
		return blocked_report("context_build_failed", side_id)
	if (
		String((context.memory_snapshot as Dictionary).get("observer_side_id", "")) != String(side_id)
		or String((context.belief_snapshot as Dictionary).get("observer_side_id", "")) != String(side_id)
	):
		return blocked_report("context_side_mismatch", side_id)

	var root_ids: Array[String] = []
	var root_kinds: Dictionary = {}
	var root_scores: Dictionary = {}
	var root_depths: Dictionary = {}
	var root_simulations: Dictionary = {}
	var root_actions: Dictionary = {}
	var evaluations_complete := true
	var metadata_models_match := true
	var same_budget := true
	var expected_budget := _budget_signature()
	for action in legal_actions:
		var root := BattleAction.from_dict(action.to_dict()) if action != null else null
		var root_id := _root_id(root)
		if root == null or root_id.is_empty() or root_ids.has(root_id):
			return blocked_report("invalid_or_duplicate_root_id", side_id)
		root_ids.append(root_id)
		root_kinds[root_id] = _kind(root)
		root_actions[root_id] = root
		var budget := _budget()
		var result := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget).evaluate(context, root)
		var metadata := result.get("metadata", {}) as Dictionary
		root_scores[root_id] = int(result.get("score", -2147483648))
		root_depths[root_id] = int(metadata.get("fully_completed_depth", 0))
		root_simulations[root_id] = int(metadata.get("simulations_used", 0))
		evaluations_complete = evaluations_complete and _result_complete(result)
		metadata_models_match = metadata_models_match and _metadata_models_valid(metadata)
		same_budget = same_budget and JSON.stringify(metadata.get("budget", {})) == expected_budget

	var resolution := resolve_scores_for_contract(root_ids, root_scores, root_depths, root_kinds)
	var outcome := String(resolution.get("outcome", ""))
	var ready := (
		evaluations_complete
		and metadata_models_match
		and same_budget
		and root_scores.size() == legal_actions.size()
		and outcome == SINGLE_ROOT_CONTRACT
		and bool(resolution.get("order_invariant", false))
	)
	var tied := (
		evaluations_complete
		and metadata_models_match
		and same_budget
		and root_scores.size() == legal_actions.size()
		and outcome == TIE_UNRESOLVED
		and bool(resolution.get("order_invariant", false))
	)
	var proposal_status := PROPOSAL_READY if ready else (TIE_UNRESOLVED if tied else BLOCKED)
	var selected_root_id := String(resolution.get("selected_root_id", "")) if ready else ""
	var proposal_action: Variant = null
	if ready and root_actions.has(selected_root_id):
		proposal_action = (root_actions[selected_root_id] as BattleAction).to_dict().duplicate(true)
	var blocked_reason := ""
	if proposal_status == BLOCKED:
		blocked_reason = "itemaware_action_proposal_incomplete"

	return {
		"proposal_status": proposal_status,
		"blocked_reason": blocked_reason,
		"proposal_model": PROPOSAL_MODEL,
		"battle_id": String(state_clone.battle_id),
		"observer_side_id": String(side_id),
		"opponent_side_id": String(observation.opponent_side_id),
		"turn": observation.turn,
		"context_side_matching": true,
		"memory_snapshot_detached": memory_clone != memory,
		"root_all_legal": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"required_depth": REQUIRED_DEPTH,
		"legal_action_count": legal_actions.size(),
		"legal_action_kind_histogram": _action_kind_histogram(legal_actions),
		"evaluated_root_count": root_scores.size(),
		"root_ids": root_ids,
		"root_kinds": root_kinds,
		"root_scores": root_scores,
		"root_depths": root_depths,
		"root_simulations": root_simulations,
		"evaluations_complete": evaluations_complete,
		"metadata_models_match": metadata_models_match,
		"same_budget": same_budget,
		"common_depth": int(resolution.get("common_depth", 0)),
		"resolution_outcome": outcome,
		"selected_root_id": selected_root_id,
		"selected_kind": String(resolution.get("selected_kind", "")) if ready else "",
		"best_root_ids": resolution.get("best_root_ids", []),
		"best_kinds": resolution.get("best_kinds", []),
		"order_invariant": bool(resolution.get("order_invariant", false)),
		"proposal_action": proposal_action,
		"proposal_action_detached": ready and proposal_action is Dictionary,
		"proposal_is_telemetry_only": true,
		"action_substitution_authorized": false,
		"behavior_integration_authorized": false,
		"kind_priority_used": false,
		"lexical_tiebreak_used": false,
		"input_order_tiebreak_used": false,
		"sampler_tiebreak_used": false,
		"live_rng_used": false,
		"frontier_fallback_used": false,
		"pareto_tiebreak_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"hidden_belief_fallback_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"fase34_open": false,
	}


func resolve_scores_for_contract(
	values: Array,
	scores: Dictionary,
	depths: Dictionary,
	kinds: Dictionary,
) -> Dictionary:
	var root_ids: Array[String] = []
	for value in values:
		var root_id := String(value)
		if root_id.is_empty() or root_ids.has(root_id):
			return _incomplete_resolution()
		root_ids.append(root_id)
	if root_ids.is_empty():
		return _incomplete_resolution()
	for root_id in root_ids:
		if not scores.has(root_id) or int(depths.get(root_id, 0)) != REQUIRED_DEPTH:
			return _incomplete_resolution()
	var best_ids := _max_score_ids(scores, root_ids)
	var reverse_ids := root_ids.duplicate()
	reverse_ids.reverse()
	var reverse_best := _max_score_ids(scores, reverse_ids)
	var order_invariant := best_ids == reverse_best
	var best_kinds: Array[String] = []
	for root_id in best_ids:
		var kind := String(kinds.get(root_id, ""))
		if not kind.is_empty() and not best_kinds.has(kind):
			best_kinds.append(kind)
	best_kinds.sort()
	var selected_root_id := best_ids[0] if best_ids.size() == 1 else ""
	return {
		"outcome": SINGLE_ROOT_CONTRACT if best_ids.size() == 1 else TIE_UNRESOLVED,
		"selected_root_id": selected_root_id,
		"selected_kind": String(kinds.get(selected_root_id, "")) if not selected_root_id.is_empty() else "",
		"best_root_ids": best_ids,
		"best_kinds": best_kinds,
		"common_depth": REQUIRED_DEPTH,
		"order_invariant": order_invariant,
	}


func blocked_report(reason: String, side_id: StringName) -> Dictionary:
	return {
		"proposal_status": BLOCKED,
		"blocked_reason": reason,
		"proposal_model": PROPOSAL_MODEL,
		"observer_side_id": String(side_id),
		"context_side_matching": false,
		"memory_snapshot_detached": false,
		"root_all_legal": true,
		"inner_max_actions_per_side": INNER_ACTION_CAP,
		"required_depth": REQUIRED_DEPTH,
		"legal_action_count": 0,
		"legal_action_kind_histogram": {"MOVE": 0, "SWITCH": 0, "ITEM": 0},
		"evaluated_root_count": 0,
		"root_ids": [],
		"root_kinds": {},
		"root_scores": {},
		"root_depths": {},
		"root_simulations": {},
		"evaluations_complete": false,
		"metadata_models_match": false,
		"same_budget": false,
		"common_depth": 0,
		"resolution_outcome": INCOMPLETE_COMMON_DEPTH,
		"selected_root_id": "",
		"selected_kind": "",
		"best_root_ids": [],
		"best_kinds": [],
		"order_invariant": false,
		"proposal_action": null,
		"proposal_action_detached": false,
		"proposal_is_telemetry_only": true,
		"action_substitution_authorized": false,
		"behavior_integration_authorized": false,
		"kind_priority_used": false,
		"lexical_tiebreak_used": false,
		"input_order_tiebreak_used": false,
		"sampler_tiebreak_used": false,
		"live_rng_used": false,
		"frontier_fallback_used": false,
		"pareto_tiebreak_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"hidden_belief_fallback_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"fase34_open": false,
	}


func _budget() -> TrainerSearchBudget:
	return TrainerSearchBudget.constrained(REQUIRED_DEPTH, MAX_WORLDS, MAX_SIMULATIONS, INNER_ACTION_CAP)


func _budget_signature() -> String:
	return JSON.stringify(_budget().normalized().to_dict())


func _result_complete(result: Dictionary) -> bool:
	var metadata := result.get("metadata", {}) as Dictionary
	var world_count := int(metadata.get("world_count", 0))
	if world_count <= 0:
		return false
	if int(metadata.get("complete_world_count", -1)) != world_count:
		return false
	if int(metadata.get("world_coverage_basis_points", 0)) != 10000:
		return false
	if int(metadata.get("fully_completed_depth", 0)) != REQUIRED_DEPTH:
		return false
	if int(metadata.get("max_depth_reached", 0)) < REQUIRED_DEPTH:
		return false
	if bool(metadata.get("budget_exhausted", true)):
		return false
	var expandable := int(metadata.get("expandable_branch_count", 0))
	if expandable > 0:
		if int(metadata.get("completed_depth_two_branch_count", -1)) != expandable:
			return false
		if int(metadata.get("depth_two_coverage_basis_points", 0)) != 10000:
			return false
	return true


func _metadata_models_valid(metadata: Dictionary) -> bool:
	return (
		String(metadata.get("item_search_model", "")) == TrainerItemAwareSearch.ITEM_SEARCH_MODEL
		and String(metadata.get("item_action_sampling_model", "")) == TrainerItemAwareSearch.ITEM_ACTION_SAMPLING_MODEL
		and String(metadata.get("battle_item_resource_model", "")) == TrainerItemAwareWorldFactory.RESOURCE_MODEL
	)


func _max_score_ids(scores: Dictionary, root_ids: Array[String]) -> Array[String]:
	var best_score := -2147483648
	var best_ids: Array[String] = []
	for root_id in root_ids:
		if not scores.has(root_id):
			continue
		var score := int(scores[root_id])
		if score > best_score:
			best_score = score
			best_ids = [root_id]
		elif score == best_score:
			best_ids.append(root_id)
	# Canonical set ordering only; sorting never selects a winner.
	best_ids.sort()
	return best_ids


func _incomplete_resolution() -> Dictionary:
	return {
		"outcome": INCOMPLETE_COMMON_DEPTH,
		"selected_root_id": "",
		"selected_kind": "",
		"best_root_ids": [],
		"best_kinds": [],
		"common_depth": 0,
		"order_invariant": false,
	}


func _root_id(action: BattleAction) -> String:
	if action == null:
		return ""
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	return "move:%s" % String(action.move_id)


func _kind(action: BattleAction) -> String:
	if action == null:
		return ""
	if action.action_type == BattleAction.SWITCH:
		return "SWITCH"
	if action.action_type == BattleAction.ITEM:
		return "ITEM"
	return "MOVE"


func _valid_side(side_id: StringName) -> bool:
	return side_id == SIDE_A or side_id == SIDE_B


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