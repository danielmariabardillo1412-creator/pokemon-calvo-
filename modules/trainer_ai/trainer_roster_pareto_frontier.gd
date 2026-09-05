class_name TrainerRosterParetoFrontier
extends RefCounted

# C3f-j productionizes only the passive Pareto pruning operation certified by
# C3f-i. It deliberately does not rank frontier members, choose a winner, or
# introduce profile/campaign/recovery/replacement policy.

const MODEL_ID := "trainer_roster_pareto_frontier_v1"
const SOURCE_CONTRACT_MODEL_ID := TrainerRosterComponentFirstContract.MODEL_ID
const FRONTIER_DIMENSIONS: Array[String] = [
	"structural_value_bp",
	"hp_state_bp",
	"route_retention_bp",
	"immediate_status_action_bp",
]


func evaluate(contract: Dictionary) -> Dictionary:
	var result := _empty_result()
	var validation := _validated_eligible_vectors(contract)
	if not bool(validation.get("valid", false)):
		return result

	var vectors: Array[Dictionary] = []
	for raw_vector in validation.get("vectors", []):
		if raw_vector is Dictionary:
			vectors.append(raw_vector as Dictionary)

	var frontier_ids := _frontier_ids(vectors)
	var dominated_ids: Array[String] = []
	for vector in vectors:
		var instance_id := String(vector.get("instance_id", ""))
		if not frontier_ids.has(instance_id):
			dominated_ids.append(instance_id)
	dominated_ids.sort()

	result["source_contract_model_id"] = String(contract.get("model_id", ""))
	result["input_contract_valid"] = true
	result["eligible_member_count"] = vectors.size()
	result["frontier_count"] = frontier_ids.size()
	result["dominated_count"] = dominated_ids.size()
	result["frontier_instance_ids"] = frontier_ids
	result["dominated_instance_ids"] = dominated_ids
	return result


func _validated_eligible_vectors(contract: Dictionary) -> Dictionary:
	if String(contract.get("model_id", "")) != SOURCE_CONTRACT_MODEL_ID:
		return {"valid": false, "vectors": []}

	var raw_states: Variant = contract.get("member_states", null)
	if not (raw_states is Array):
		return {"valid": false, "vectors": []}
	var states := raw_states as Array
	var raw_member_count: Variant = contract.get("member_count", null)
	if typeof(raw_member_count) != TYPE_INT or int(raw_member_count) != states.size():
		return {"valid": false, "vectors": []}

	var vectors: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	for raw_state in states:
		if not (raw_state is Dictionary):
			return {"valid": false, "vectors": []}
		var state := raw_state as Dictionary
		var instance_id := String(state.get("instance_id", ""))
		if instance_id.is_empty() or seen_ids.has(instance_id):
			return {"valid": false, "vectors": []}
		seen_ids[instance_id] = true

		var availability_state := String(state.get("availability_state", ""))
		if availability_state != "surviving" and availability_state != "knocked_out":
			return {"valid": false, "vectors": []}
		var raw_structural: Variant = state.get("structural", null)
		var raw_operational: Variant = state.get("operational", null)
		if not (raw_structural is Dictionary) or not (raw_operational is Dictionary):
			return {"valid": false, "vectors": []}
		var structural := raw_structural as Dictionary
		var operational := raw_operational as Dictionary

		if availability_state != "surviving":
			continue
		if not bool(structural.get("available", false)) or not bool(operational.get("available", false)):
			continue
		if not _has_integer_component(structural, "structural_value_bp"):
			return {"valid": false, "vectors": []}
		for dimension in ["hp_state_bp", "route_retention_bp", "immediate_status_action_bp"]:
			if not _has_integer_component(operational, dimension):
				return {"valid": false, "vectors": []}

		vectors.append({
			"instance_id": instance_id,
			"structural_value_bp": int(structural.get("structural_value_bp", 0)),
			"hp_state_bp": int(operational.get("hp_state_bp", 0)),
			"route_retention_bp": int(operational.get("route_retention_bp", 0)),
			"immediate_status_action_bp": int(operational.get("immediate_status_action_bp", 0)),
		})

	return {"valid": true, "vectors": vectors}


func _has_integer_component(block: Dictionary, key: String) -> bool:
	return block.has(key) and typeof(block[key]) == TYPE_INT


func _frontier_ids(vectors: Array[Dictionary]) -> Array[String]:
	var frontier: Array[String] = []
	for i in range(vectors.size()):
		var dominated := false
		for j in range(vectors.size()):
			if i == j:
				continue
			if _dominates(vectors[j], vectors[i]):
				dominated = true
				break
		if not dominated:
			frontier.append(String(vectors[i].get("instance_id", "")))
	frontier.sort()
	return frontier


func _dominates(a: Dictionary, b: Dictionary) -> bool:
	var strictly_better := false
	for dimension in FRONTIER_DIMENSIONS:
		var av := int(a.get(dimension, 0))
		var bv := int(b.get(dimension, 0))
		if av < bv:
			return false
		if av > bv:
			strictly_better = true
	return strictly_better


func _empty_result() -> Dictionary:
	return {
		"model_id": MODEL_ID,
		"source_contract_model_id": "",
		"frontier_dimensions": FRONTIER_DIMENSIONS.duplicate(),
		"input_contract_valid": false,
		"eligible_member_count": 0,
		"frontier_count": 0,
		"dominated_count": 0,
		"frontier_instance_ids": [],
		"dominated_instance_ids": [],
		"attrition_excluded_from_immediate_frontier": true,
		"held_item_excluded_from_immediate_frontier": true,
	}
