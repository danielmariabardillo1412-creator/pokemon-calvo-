class_name TrainerRosterComponentFirstContract
extends RefCounted

# C3f-g productionizes only the passive component-first contract certified by
# C3f-f. It deliberately does not rank members, choose a combined scalar, or
# introduce campaign/recovery/replacement policy.

const MODEL_ID := "trainer_roster_component_first_contract_v1"

var _catalog: DefinitionCatalog
var _ruleset: BattleRuleset


func _init(catalog: DefinitionCatalog, ruleset: BattleRuleset = null) -> void:
	_catalog = catalog
	_ruleset = ruleset if ruleset != null else BattleRuleset.new()


func build_contract(own_party: Array) -> Dictionary:
	if _catalog == null:
		return _empty_result()

	var structural_result := TrainerRosterStrategicValueEvaluator.new(_catalog).evaluate_structural_value(own_party)
	var operational_result := TrainerRosterOperationalReadinessEvaluator.new(_catalog, _ruleset).evaluate_current_components(own_party)
	var structural_by_id: Dictionary = {}
	for raw_member in structural_result.get("member_values", []):
		if raw_member is Dictionary:
			var member := raw_member as Dictionary
			structural_by_id[String(member.get("instance_id", ""))] = member

	var operational_by_id: Dictionary = {}
	for raw_member in operational_result.get("member_components", []):
		if raw_member is Dictionary:
			var member := raw_member as Dictionary
			operational_by_id[String(member.get("instance_id", ""))] = member

	var member_states: Array[Dictionary] = []
	var instance_ids: Array[String] = []
	for raw_id in operational_by_id.keys():
		instance_ids.append(String(raw_id))
	instance_ids.sort()

	for instance_id in instance_ids:
		var operational := operational_by_id.get(instance_id, {}) as Dictionary
		var structural := structural_by_id.get(instance_id, {}) as Dictionary
		var knocked_out := bool(operational.get("is_knocked_out", false))
		var structural_available := not structural.is_empty()
		var structural_block: Dictionary = {
			"available": structural_available,
			"model_id": String(structural_result.get("model_id", "")),
			"formula_id": String(structural_result.get("formula_id", "")),
		}
		if structural_available:
			structural_block["species_id"] = String(structural.get("species_id", ""))
			structural_block["structural_value_bp"] = int(structural.get("structural_value_bp", 0))
			structural_block["breakdown"] = (structural.get("breakdown", {}) as Dictionary).duplicate(true)
		else:
			structural_block["unavailable_reason"] = (
				"knocked_out_not_in_surviving_structural_roster"
				if knocked_out
				else "no_structural_join"
			)

		member_states.append({
			"instance_id": instance_id,
			"species_id": String(operational.get("species_id", "")),
			"availability_state": "knocked_out" if knocked_out else "surviving",
			"structural": structural_block,
			"operational": {
				"available": true,
				"model_id": String(operational_result.get("model_id", "")),
				"species_id": String(operational.get("species_id", "")),
				"is_active": bool(operational.get("is_active", false)),
				"is_knocked_out": knocked_out,
				"hp_state_bp": int(operational.get("hp_state_bp", 0)),
				"route_retention_bp": int(operational.get("route_retention_bp", 0)),
				"immediate_status_action_bp": int(operational.get("immediate_status_action_bp", 0)),
				"attrition": (operational.get("attrition", {}) as Dictionary).duplicate(true),
				"held_item": (operational.get("held_item", {}) as Dictionary).duplicate(true),
				"breakdown": (operational.get("breakdown", {}) as Dictionary).duplicate(true),
			},
		})

	return {
		"model_id": MODEL_ID,
		"structural_model_id": String(structural_result.get("model_id", "")),
		"structural_formula_id": String(structural_result.get("formula_id", "")),
		"operational_model_id": String(operational_result.get("model_id", "")),
		"member_count": member_states.size(),
		"member_states": member_states,
	}


func _empty_result() -> Dictionary:
	return {
		"model_id": MODEL_ID,
		"structural_model_id": "",
		"structural_formula_id": "",
		"operational_model_id": "",
		"member_count": 0,
		"member_states": [],
	}
