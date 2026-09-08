class_name TrainerGameReadyTieResolver
extends RefCounted

# Post-26.67 game-ready boundary. The deep proposal keeps reporting TIE_UNRESOLVED;
# this resolver may choose only among an exact, complete, current deep-best tie.
const TIE_RESOLVED := "TIE_RESOLVED"
const BLOCKED := "BLOCKED"
const POLICY_ID := "uniform_seeded_equal_deep_best_v1"
const SEED_SCOPE := "battle_id|turn|side|canonical_best_roots|policy"


func resolve(
	proposal_report: Dictionary,
	legal_actions: Array[BattleAction],
	battle_id: StringName,
	turn: int,
	side_id: StringName,
) -> Dictionary:
	if String(proposal_report.get("proposal_status", "")) != TrainerItemAwareActionProposal.TIE_UNRESOLVED:
		return _blocked("proposal_not_tied", side_id)
	if String(proposal_report.get("resolution_outcome", "")) != TrainerItemAwareActionProposal.TIE_UNRESOLVED:
		return _blocked("resolution_not_tied", side_id)
	if String(proposal_report.get("battle_id", "")) != String(battle_id):
		return _blocked("proposal_battle_mismatch", side_id)
	if int(proposal_report.get("turn", -1)) != turn:
		return _blocked("proposal_turn_mismatch", side_id)
	if String(proposal_report.get("observer_side_id", "")) != String(side_id):
		return _blocked("proposal_side_mismatch", side_id)
	if not bool(proposal_report.get("context_side_matching", false)):
		return _blocked("proposal_context_side_mismatch", side_id)
	if not bool(proposal_report.get("memory_snapshot_detached", false)):
		return _blocked("proposal_memory_not_detached", side_id)
	if not bool(proposal_report.get("root_all_legal", false)):
		return _blocked("proposal_root_coverage_not_all_legal", side_id)
	if (
		int(proposal_report.get("required_depth", -1)) != TrainerItemAwareActionProposal.REQUIRED_DEPTH
		or int(proposal_report.get("common_depth", -1)) != TrainerItemAwareActionProposal.REQUIRED_DEPTH
	):
		return _blocked("proposal_depth_incomplete", side_id)
	if (
		not bool(proposal_report.get("evaluations_complete", false))
		or not bool(proposal_report.get("metadata_models_match", false))
		or not bool(proposal_report.get("same_budget", false))
	):
		return _blocked("proposal_evaluation_incomplete", side_id)
	if not bool(proposal_report.get("order_invariant", false)):
		return _blocked("proposal_not_order_invariant", side_id)

	var expected_count := int(proposal_report.get("legal_action_count", 0))
	if expected_count <= 0 or int(proposal_report.get("evaluated_root_count", -1)) != expected_count:
		return _blocked("proposal_root_coverage_incomplete", side_id)

	var legal_by_root: Dictionary = {}
	for action in legal_actions:
		if action == null or action.side_id != side_id:
			continue
		var root_id := _root_id(action)
		if root_id.is_empty() or legal_by_root.has(root_id):
			return _blocked("duplicate_or_invalid_live_root", side_id)
		legal_by_root[root_id] = action.to_dict().duplicate(true)
	if legal_by_root.size() != expected_count:
		return _blocked("live_root_coverage_mismatch", side_id)

	var scores := proposal_report.get("root_scores", {}) as Dictionary
	if scores.size() != expected_count:
		return _blocked("proposal_score_coverage_mismatch", side_id)
	var max_score := -2147483648
	var max_ids: Array[String] = []
	for raw_id in scores.keys():
		var root_id := String(raw_id)
		if not legal_by_root.has(root_id):
			return _blocked("scored_root_not_currently_legal", side_id)
		var score := int(scores[raw_id])
		if score > max_score:
			max_score = score
			max_ids.clear()
			max_ids.append(root_id)
		elif score == max_score:
			max_ids.append(root_id)
	max_ids.sort()

	var best_ids: Array[String] = []
	var raw_best := proposal_report.get("best_root_ids", []) as Array
	for value in raw_best:
		var root_id := String(value)
		if root_id.is_empty() or best_ids.has(root_id):
			return _blocked("invalid_best_root_set", side_id)
		best_ids.append(root_id)
	best_ids.sort()
	if best_ids.size() < 2:
		return _blocked("tie_requires_multiple_best_roots", side_id)
	if best_ids != max_ids:
		return _blocked("best_root_set_not_exact_maximum", side_id)
	for root_id in best_ids:
		if not legal_by_root.has(root_id):
			return _blocked("best_root_not_currently_legal", side_id)

	var seed_material := "%s|%d|%s|%s|%s" % [
		String(battle_id),
		turn,
		String(side_id),
		";".join(best_ids),
		POLICY_ID,
	]
	var seed := _stable_seed(seed_material)
	var selected_index := seed % best_ids.size()
	var selected_root_id := best_ids[selected_index]
	var selected_dict := (legal_by_root[selected_root_id] as Dictionary).duplicate(true)
	var selected_action := BattleAction.from_dict(selected_dict)
	if selected_action == null or selected_action.side_id != side_id or selected_action.turn != turn + 1:
		return _blocked("selected_action_binding_invalid", side_id)

	return {
		"tie_resolution_status": TIE_RESOLVED,
		"blocked_reason": "",
		"policy_id": POLICY_ID,
		"seed_scope": SEED_SCOPE,
		"battle_id": String(battle_id),
		"turn": turn,
		"side_id": String(side_id),
		"candidate_root_ids": best_ids,
		"candidate_count": best_ids.size(),
		"max_score": max_score,
		"selection_seed": seed,
		"selected_index": selected_index,
		"selected_root_id": selected_root_id,
		"selected_kind": _kind(selected_action),
		"selected_action": selected_dict,
		"selected_action_detached": true,
		"uniform_seeded_equal_best": true,
		"canonicalization_only_lexical_sort": true,
		"lexical_priority_used": false,
		"input_order_priority_used": false,
		"kind_priority_used": false,
		"live_rng_used": false,
		"player_current_action_used": false,
		"order_invariant": true,
	}


func _blocked(reason: String, side_id: StringName) -> Dictionary:
	return {
		"tie_resolution_status": BLOCKED,
		"blocked_reason": reason,
		"policy_id": POLICY_ID,
		"seed_scope": SEED_SCOPE,
		"side_id": String(side_id),
		"candidate_root_ids": [],
		"candidate_count": 0,
		"selected_root_id": "",
		"selected_kind": "",
		"selected_action": null,
		"selected_action_detached": false,
		"uniform_seeded_equal_best": false,
		"canonicalization_only_lexical_sort": true,
		"lexical_priority_used": false,
		"input_order_priority_used": false,
		"kind_priority_used": false,
		"live_rng_used": false,
		"player_current_action_used": false,
		"order_invariant": false,
	}


func _stable_seed(text: String) -> int:
	# Stable FNV-1a-like 31-bit hash. It does not consume Battle RNG and is reproducible.
	var value: int = 2166136261
	for byte in text.to_utf8_buffer():
		value = int(((value ^ int(byte)) * 16777619) & 0x7fffffff)
	return value


func _root_id(action: BattleAction) -> String:
	if action == null:
		return ""
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	if action.action_type == BattleAction.MOVE:
		return "move:%s" % String(action.move_id)
	return ""


func _kind(action: BattleAction) -> String:
	if action == null:
		return ""
	match action.action_type:
		BattleAction.MOVE:
			return "MOVE"
		BattleAction.SWITCH:
			return "SWITCH"
		BattleAction.ITEM:
			return "ITEM"
	return ""
