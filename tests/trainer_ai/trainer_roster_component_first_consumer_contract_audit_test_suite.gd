class_name TrainerRosterComponentFirstConsumerContractAuditTestSuite
extends TrainerRosterOperationalReadinessProductionRealDataAuditTestSuite

const AUDIT_ID_C3FF := "c3f_f_component_first_consumer_contract_audit_v1"
const CONTRACT_MODEL_ID := "trainer_roster_component_first_consumer_contract_candidate_v1"
const REAL_DATA_ROSTER_STRIDE := 8
const KO_PROBE_ROSTERS := 24
const INDEPENDENCE_PROBE_ROSTERS := 24
const FORBIDDEN_CONTRACT_KEYS: Array[String] = [
	"operational_readiness_bp",
	"permadeath_loss_cost_bp",
	"combined_score",
	"combined_score_bp",
	"ranking_score",
	"ranking_score_bp",
	"preservation_score",
	"preservation_score_bp",
	"replacement_policy",
	"between_battle_recovery_policy",
	"recovery_policy",
	"switch_score",
	"search_score",
	"best_member_id",
	"selected_member_id",
]
const FORBIDDEN_CONTEXT_KEYS: Array[String] = [
	"observed_opponents",
	"beliefs",
	"rival_memory",
	"trainer_profile",
	"campaign_snapshot",
	"hidden_bracket",
	"future_opponents",
	"rng",
	"seed",
]


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_component_first_consumer_contract()


func _test_component_first_consumer_contract() -> void:
	var report_a := _build_c3ff_report()
	var report_b := _build_c3ff_report()

	_check.call(
		"consumer_contract_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FF,
	)
	_check.call(
		"consumer_contract_uses_broad_real_data_sample",
		int(report_a.get("sampled_rosters", 0)) == 128
		and int(report_a.get("member_states", 0)) == 768,
	)
	_check.call(
		"consumer_contract_join_is_complete_by_instance_id",
		int(report_a.get("missing_operational_join_cases", -1)) == 0
		and int(report_a.get("missing_structural_survivor_join_cases", -1)) == 0
		and int(report_a.get("species_identity_mismatches", -1)) == 0
		and int(report_a.get("duplicate_contract_instance_ids", -1)) == 0,
	)
	_check.call(
		"consumer_contract_is_input_reorder_invariant",
		int(report_a.get("reorder_contract_mismatches", -1)) == 0,
	)
	_check.call(
		"consumer_contract_keeps_structural_and_operational_models_explicit",
		int(report_a.get("model_identity_mismatches", -1)) == 0,
	)
	_check.call(
		"consumer_contract_hp_changes_only_operational_state",
		int(report_a.get("hp_structural_mutation_mismatches", -1)) == 0
		and int(report_a.get("hp_operational_change_cases", 0)) > 0,
	)
	_check.call(
		"consumer_contract_pp_changes_only_operational_route",
		int(report_a.get("pp_structural_mutation_mismatches", -1)) == 0
		and int(report_a.get("pp_unexpected_operational_dimension_mismatches", -1)) == 0
		and int(report_a.get("pp_route_change_cases", 0)) > 0,
	)
	_check.call(
		"consumer_contract_status_changes_only_operational_status_layer",
		int(report_a.get("status_structural_mutation_mismatches", -1)) == 0
		and int(report_a.get("status_unexpected_operational_dimension_mismatches", -1)) == 0
		and int(report_a.get("status_action_change_cases", 0)) > 0,
	)
	_check.call(
		"consumer_contract_held_item_stays_separate_evidence",
		int(report_a.get("item_structural_mutation_mismatches", -1)) == 0
		and int(report_a.get("item_numeric_component_mismatches", -1)) == 0
		and int(report_a.get("item_availability_change_cases", 0)) > 0,
	)
	_check.call(
		"consumer_contract_ko_keeps_operational_but_not_fake_structural_value",
		int(report_a.get("ko_probe_cases", -1)) == KO_PROBE_ROSTERS
		and int(report_a.get("ko_contract_missing_cases", -1)) == 0
		and int(report_a.get("ko_fake_structural_value_cases", -1)) == 0
		and int(report_a.get("ko_operational_state_mismatches", -1)) == 0,
	)
	_check.call(
		"consumer_contract_teammate_ko_does_not_rewrite_survivor_operational_state",
		int(report_a.get("survivor_operational_changes_after_teammate_ko", -1)) == 0,
	)
	_check.call(
		"consumer_contract_teammate_ko_can_recompute_structural_context",
		int(report_a.get("survivor_structural_decrease_after_teammate_ko", -1)) == 0
		and int(report_a.get("survivor_structural_change_after_teammate_ko", 0)) > 0,
	)
	_check.call(
		"consumer_contract_has_pareto_dominance_without_total_ranking",
		int(report_a.get("pair_comparisons", 0)) > 0
		and int(report_a.get("pareto_dominance_pairs", 0)) > 0
		and int(report_a.get("incomparable_pairs", 0)) > 0,
	)
	_check.call(
		"consumer_contract_real_data_contains_structural_operational_tradeoffs",
		int(report_a.get("structural_higher_operational_lower_pairs", 0)) > 0,
	)
	_check.call(
		"consumer_contract_attrition_stays_outside_immediate_pareto_vector",
		bool(report_a.get("attrition_excluded_from_immediate_pareto", false)),
	)
	_check.call(
		"consumer_contract_contains_no_hidden_scalar_or_campaign_policy",
		int(report_a.get("forbidden_contract_key_cases", -1)) == 0
		and int(report_a.get("forbidden_context_key_cases", -1)) == 0
		and report_a.get("selected_combined_scalar") == null
		and not bool(report_a.get("consumer_behavior_integration_authorized", true)),
	)
	_check.call("consumer_contract_report_deterministic", report_a == report_b)
	_check.call(
		"consumer_contract_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER COMPONENT-FIRST CONSUMER CONTRACT AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3ff_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FF, "sampled_rosters": 0}

	var game_data := GameData.from_dict(normalized)
	var catalog := game_data.to_definition_catalog()
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe := helper._build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)

	var fixture_catalog := _catalog
	_catalog = catalog

	var sampled_rosters := 0
	var member_states := 0
	var missing_operational_join_cases := 0
	var missing_structural_survivor_join_cases := 0
	var species_identity_mismatches := 0
	var duplicate_contract_instance_ids := 0
	var reorder_contract_mismatches := 0
	var model_identity_mismatches := 0
	var forbidden_contract_key_cases := 0
	var forbidden_context_key_cases := 0
	var pair_comparisons := 0
	var pareto_dominance_pairs := 0
	var incomparable_pairs := 0
	var structural_higher_operational_lower_pairs := 0
	var sampled_species_examples: Array[String] = []

	for anchor in range(0, members.size(), REAL_DATA_ROSTER_STRIDE):
		var roster := helper._scheduled_roster(
			members,
			anchor,
			int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0]),
		)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var contract := _component_first_contract(degraded, catalog)
		var reversed := degraded.duplicate(true)
		reversed.reverse()
		var reversed_contract := _component_first_contract(reversed, catalog)

		sampled_rosters += 1
		member_states += int(contract.get("member_count", 0))
		if contract != reversed_contract:
			reorder_contract_mismatches += 1
		if (
			String(contract.get("structural_model_id", ""))
			!= TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID
			or String(contract.get("operational_model_id", ""))
			!= TrainerRosterOperationalReadinessEvaluator.MODEL_ID
		):
			model_identity_mismatches += 1
		if _contains_any_key_recursive(contract, FORBIDDEN_CONTRACT_KEYS):
			forbidden_contract_key_cases += 1
		if _contains_any_key_recursive(contract, FORBIDDEN_CONTEXT_KEYS):
			forbidden_context_key_cases += 1

		var seen_ids: Dictionary = {}
		var surviving_vectors: Array[Dictionary] = []
		for raw_state in contract.get("member_states", []):
			if not (raw_state is Dictionary):
				continue
			var state := raw_state as Dictionary
			var instance_id := String(state.get("instance_id", ""))
			if seen_ids.has(instance_id):
				duplicate_contract_instance_ids += 1
		seen_ids[instance_id] = true
		var operational := state.get("operational", {}) as Dictionary
		if not bool(operational.get("available", false)):
			missing_operational_join_cases += 1
		var structural := state.get("structural", {}) as Dictionary
		if String(state.get("availability_state", "")) == "surviving" and not bool(structural.get("available", false)):
			missing_structural_survivor_join_cases += 1
		if (
			bool(structural.get("available", false))
			and String(structural.get("species_id", "")) != String(state.get("species_id", ""))
		):
			species_identity_mismatches += 1
		if String(operational.get("species_id", "")) != String(state.get("species_id", "")):
			species_identity_mismatches += 1
		if sampled_species_examples.size() < 12:
			sampled_species_examples.append(String(state.get("species_id", "")))
		if String(state.get("availability_state", "")) == "surviving":
			surviving_vectors.append(_immediate_value_vector(state))

		for i in range(surviving_vectors.size()):
			for j in range(i + 1, surviving_vectors.size()):
				var a := surviving_vectors[i]
				var b := surviving_vectors[j]
				pair_comparisons += 1
				var a_dominates := _dominates(a, b)
				var b_dominates := _dominates(b, a)
				if a_dominates or b_dominates:
					pareto_dominance_pairs += 1
				else:
					incomparable_pairs += 1
				if _structural_operational_tradeoff(a, b) or _structural_operational_tradeoff(b, a):
					structural_higher_operational_lower_pairs += 1

	var independence := _independence_report(helper, catalog, members)
	var ko_report := _ko_join_report(helper, catalog, members)
	_catalog = fixture_catalog

	return {
		"audit_id": AUDIT_ID_C3FF,
		"contract_model_id": CONTRACT_MODEL_ID,
		"structural_model_id": TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID,
		"operational_model_id": TrainerRosterOperationalReadinessEvaluator.MODEL_ID,
		"eligible_species": members.size(),
		"real_data_roster_stride": REAL_DATA_ROSTER_STRIDE,
		"sampled_rosters": sampled_rosters,
		"member_states": member_states,
		"sampled_species_examples": sampled_species_examples,
		"missing_operational_join_cases": missing_operational_join_cases,
		"missing_structural_survivor_join_cases": missing_structural_survivor_join_cases,
		"species_identity_mismatches": species_identity_mismatches,
		"duplicate_contract_instance_ids": duplicate_contract_instance_ids,
		"reorder_contract_mismatches": reorder_contract_mismatches,
		"model_identity_mismatches": model_identity_mismatches,
		"forbidden_contract_key_cases": forbidden_contract_key_cases,
		"forbidden_context_key_cases": forbidden_context_key_cases,
		"pair_comparisons": pair_comparisons,
		"pareto_dominance_pairs": pareto_dominance_pairs,
		"incomparable_pairs": incomparable_pairs,
		"structural_higher_operational_lower_pairs": structural_higher_operational_lower_pairs,
		"attrition_excluded_from_immediate_pareto": true,
		"hp_structural_mutation_mismatches": int(independence.get("hp_structural_mutation_mismatches", -1)),
		"hp_operational_change_cases": int(independence.get("hp_operational_change_cases", 0)),
		"pp_structural_mutation_mismatches": int(independence.get("pp_structural_mutation_mismatches", -1)),
		"pp_unexpected_operational_dimension_mismatches": int(independence.get("pp_unexpected_operational_dimension_mismatches", -1)),
		"pp_route_change_cases": int(independence.get("pp_route_change_cases", 0)),
		"status_structural_mutation_mismatches": int(independence.get("status_structural_mutation_mismatches", -1)),
		"status_unexpected_operational_dimension_mismatches": int(independence.get("status_unexpected_operational_dimension_mismatches", -1)),
		"status_action_change_cases": int(independence.get("status_action_change_cases", 0)),
		"item_structural_mutation_mismatches": int(independence.get("item_structural_mutation_mismatches", -1)),
		"item_numeric_component_mismatches": int(independence.get("item_numeric_component_mismatches", -1)),
		"item_availability_change_cases": int(independence.get("item_availability_change_cases", 0)),
		"ko_probe_cases": int(ko_report.get("ko_probe_cases", -1)),
		"ko_contract_missing_cases": int(ko_report.get("ko_contract_missing_cases", -1)),
		"ko_fake_structural_value_cases": int(ko_report.get("ko_fake_structural_value_cases", -1)),
		"ko_operational_state_mismatches": int(ko_report.get("ko_operational_state_mismatches", -1)),
		"survivor_operational_changes_after_teammate_ko": int(ko_report.get("survivor_operational_changes_after_teammate_ko", -1)),
		"survivor_structural_change_after_teammate_ko": int(ko_report.get("survivor_structural_change_after_teammate_ko", 0)),
		"survivor_structural_decrease_after_teammate_ko": int(ko_report.get("survivor_structural_decrease_after_teammate_ko", -1)),
		"selected_combined_scalar": null,
		"consumer_behavior_integration_authorized": false,
	}


func _component_first_contract(own_party: Array, catalog: DefinitionCatalog) -> Dictionary:
	var structural_result := TrainerRosterStrategicValueEvaluator.new(catalog).evaluate_structural_value(own_party)
	var operational_result := TrainerRosterOperationalReadinessEvaluator.new(catalog, _operational_ruleset).evaluate_current_components(own_party)
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
			structural_block["unavailable_reason"] = "knocked_out_not_in_surviving_structural_roster" if knocked_out else "no_structural_join"

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
		"model_id": CONTRACT_MODEL_ID,
		"structural_model_id": String(structural_result.get("model_id", "")),
		"structural_formula_id": String(structural_result.get("formula_id", "")),
		"operational_model_id": String(operational_result.get("model_id", "")),
		"member_count": member_states.size(),
		"member_states": member_states,
	}


func _degraded_roster(roster: Array[Dictionary], roster_index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in range(roster.size()):
		var member := _real_member_with_full_pp(roster[slot])
		var occurrence := roster_index * TrainerRosterStructuralRealDataAuditTestSuite.ROSTER_SIZE + slot
		var stats := member.get("stats", {}) as Dictionary
		var max_hp := maxi(1, int(stats.get("max_hp", 1)))
		var hp_cycle := [2500, 5000, 7500, 10000]
		member["current_hp"] = maxi(1, max_hp * int(hp_cycle[occurrence % hp_cycle.size()]) / 10000)
		member["is_active"] = slot == 0
		var move_ids := member.get("move_ids", []) as Array
		if occurrence % 2 == 0 and not move_ids.is_empty():
			var move_id := StringName(String(move_ids[0]))
			var move := _catalog.move(move_id)
			if move != null:
				_set_move_pp(member, move_id, 0, maxi(1, int(move.pp)))
		_apply_real_status_cycle(member, occurrence)
		if occurrence % 3 == 0:
			member["held_item_id"] = "c3ff_audit_item"
			member["held_item_consumed"] = occurrence % 6 == 0
		out.append(member)
	return out


func _independence_report(
	helper: TrainerRosterStructuralRealDataAuditTestSuite,
	catalog: DefinitionCatalog,
	members: Array[Dictionary],
) -> Dictionary:
	var hp_structural_mutation_mismatches := 0
	var hp_operational_change_cases := 0
	var pp_structural_mutation_mismatches := 0
	var pp_unexpected_operational_dimension_mismatches := 0
	var pp_route_change_cases := 0
	var status_structural_mutation_mismatches := 0
	var status_unexpected_operational_dimension_mismatches := 0
	var status_action_change_cases := 0
	var item_structural_mutation_mismatches := 0
	var item_numeric_component_mismatches := 0
	var item_availability_change_cases := 0

	for anchor in range(mini(INDEPENDENCE_PROBE_ROSTERS, members.size())):
		var roster := helper._scheduled_roster(
			members,
			anchor,
			int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0]),
		)
		var baseline: Array[Dictionary] = []
		for raw_member in roster:
			baseline.append(_real_member_with_full_pp(raw_member))
		baseline[0]["is_active"] = true
		var base_contract := _component_first_contract(baseline, catalog)
		var target_id := String(baseline[0].get("instance_id", ""))
		var base_state := _contract_state_by_id(base_contract, target_id)
		var base_structural := base_state.get("structural", {}) as Dictionary
		var base_operational := base_state.get("operational", {}) as Dictionary

		var low_hp := baseline.duplicate(true)
		var stats := low_hp[0].get("stats", {}) as Dictionary
		low_hp[0]["current_hp"] = maxi(1, int(stats.get("max_hp", 1)) / 2)
		var hp_state := _contract_state_by_id(_component_first_contract(low_hp, catalog), target_id)
		if hp_state.get("structural", {}) != base_structural:
			hp_structural_mutation_mismatches += 1
		var hp_op := hp_state.get("operational", {}) as Dictionary
		if int(hp_op.get("hp_state_bp", -1)) < int(base_operational.get("hp_state_bp", -1)):
			hp_operational_change_cases += 1

		var move_ids := baseline[0].get("move_ids", []) as Array
		if not move_ids.is_empty():
			var pp_depleted := baseline.duplicate(true)
			var move_id := StringName(String(move_ids[0]))
			var move := catalog.move(move_id)
			if move != null:
				_set_move_pp(pp_depleted[0], move_id, 0, maxi(1, int(move.pp)))
				var pp_state := _contract_state_by_id(_component_first_contract(pp_depleted, catalog), target_id)
				if pp_state.get("structural", {}) != base_structural:
					pp_structural_mutation_mismatches += 1
				var pp_op := pp_state.get("operational", {}) as Dictionary
				if int(pp_op.get("route_retention_bp", -1)) < int(base_operational.get("route_retention_bp", -1)):
					pp_route_change_cases += 1
				if (
					int(pp_op.get("hp_state_bp", -1)) != int(base_operational.get("hp_state_bp", -1))
					or int(pp_op.get("immediate_status_action_bp", -1)) != int(base_operational.get("immediate_status_action_bp", -1))
				):
					pp_unexpected_operational_dimension_mismatches += 1

		var sleeping := baseline.duplicate(true)
		_set_status(sleeping[0], StatusSystem.SLEEP, 2, 0)
		var status_state := _contract_state_by_id(_component_first_contract(sleeping, catalog), target_id)
		if status_state.get("structural", {}) != base_structural:
			status_structural_mutation_mismatches += 1
		var status_op := status_state.get("operational", {}) as Dictionary
		if int(status_op.get("immediate_status_action_bp", -1)) < int(base_operational.get("immediate_status_action_bp", -1)):
			status_action_change_cases += 1
		if (
			int(status_op.get("hp_state_bp", -1)) != int(base_operational.get("hp_state_bp", -1))
			or int(status_op.get("route_retention_bp", -1)) != int(base_operational.get("route_retention_bp", -1))
		):
			status_unexpected_operational_dimension_mismatches += 1

		var item_available := baseline.duplicate(true)
		item_available[0]["held_item_id"] = "c3ff_audit_item"
		item_available[0]["held_item_consumed"] = false
		var item_consumed := item_available.duplicate(true)
		item_consumed[0]["held_item_consumed"] = true
		var item_available_state := _contract_state_by_id(_component_first_contract(item_available, catalog), target_id)
		var item_consumed_state := _contract_state_by_id(_component_first_contract(item_consumed, catalog), target_id)
		if item_available_state.get("structural", {}) != item_consumed_state.get("structural", {}):
			item_structural_mutation_mismatches += 1
		var item_available_op := item_available_state.get("operational", {}) as Dictionary
		var item_consumed_op := item_consumed_state.get("operational", {}) as Dictionary
		if _immediate_numeric_signature(item_available_op) != _immediate_numeric_signature(item_consumed_op):
			item_numeric_component_mismatches += 1
		var available_item := item_available_op.get("held_item", {}) as Dictionary
		var consumed_item := item_consumed_op.get("held_item", {}) as Dictionary
		if bool(available_item.get("available", false)) != bool(consumed_item.get("available", false)):
			item_availability_change_cases += 1

	return {
		"hp_structural_mutation_mismatches": hp_structural_mutation_mismatches,
		"hp_operational_change_cases": hp_operational_change_cases,
		"pp_structural_mutation_mismatches": pp_structural_mutation_mismatches,
		"pp_unexpected_operational_dimension_mismatches": pp_unexpected_operational_dimension_mismatches,
		"pp_route_change_cases": pp_route_change_cases,
		"status_structural_mutation_mismatches": status_structural_mutation_mismatches,
		"status_unexpected_operational_dimension_mismatches": status_unexpected_operational_dimension_mismatches,
		"status_action_change_cases": status_action_change_cases,
		"item_structural_mutation_mismatches": item_structural_mutation_mismatches,
		"item_numeric_component_mismatches": item_numeric_component_mismatches,
		"item_availability_change_cases": item_availability_change_cases,
	}


func _ko_join_report(
	helper: TrainerRosterStructuralRealDataAuditTestSuite,
	catalog: DefinitionCatalog,
	members: Array[Dictionary],
) -> Dictionary:
	var ko_contract_missing_cases := 0
	var ko_fake_structural_value_cases := 0
	var ko_operational_state_mismatches := 0
	var survivor_operational_changes_after_teammate_ko := 0
	var survivor_structural_change_after_teammate_ko := 0
	var survivor_structural_decrease_after_teammate_ko := 0

	for anchor in range(mini(KO_PROBE_ROSTERS, members.size())):
		var roster := helper._scheduled_roster(
			members,
			anchor,
			int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0]),
		)
		var baseline: Array[Dictionary] = []
		for raw_member in roster:
			baseline.append(_real_member_with_full_pp(raw_member))
		baseline[0]["is_active"] = true
		var before := _component_first_contract(baseline, catalog)
		var knocked := baseline.duplicate(true)
		var ko_slot := 1
		var ko_id := String(knocked[ko_slot].get("instance_id", ""))
		knocked[ko_slot]["current_hp"] = 0
		knocked[ko_slot]["is_knocked_out"] = true
		var after := _component_first_contract(knocked, catalog)
		var ko_state := _contract_state_by_id(after, ko_id)
		if ko_state.is_empty():
			ko_contract_missing_cases += 1
		else:
			var ko_structural := ko_state.get("structural", {}) as Dictionary
			var ko_operational := ko_state.get("operational", {}) as Dictionary
			if bool(ko_structural.get("available", false)) or ko_structural.has("structural_value_bp"):
				ko_fake_structural_value_cases += 1
			if (
				String(ko_state.get("availability_state", "")) != "knocked_out"
				or not bool(ko_operational.get("is_knocked_out", false))
				or int(ko_operational.get("hp_state_bp", -1)) != 0
			):
				ko_operational_state_mismatches += 1

		for slot in range(baseline.size()):
			if slot == ko_slot:
				continue
			var survivor_id := String(baseline[slot].get("instance_id", ""))
			var before_state := _contract_state_by_id(before, survivor_id)
			var after_state := _contract_state_by_id(after, survivor_id)
			if before_state.get("operational", {}) != after_state.get("operational", {}):
				survivor_operational_changes_after_teammate_ko += 1
			var before_structural := before_state.get("structural", {}) as Dictionary
			var after_structural := after_state.get("structural", {}) as Dictionary
			var before_score := int(before_structural.get("structural_value_bp", -1))
			var after_score := int(after_structural.get("structural_value_bp", -1))
			if after_score != before_score:
				survivor_structural_change_after_teammate_ko += 1
			if after_score < before_score:
				survivor_structural_decrease_after_teammate_ko += 1

	return {
		"ko_probe_cases": mini(KO_PROBE_ROSTERS, members.size()),
		"ko_contract_missing_cases": ko_contract_missing_cases,
		"ko_fake_structural_value_cases": ko_fake_structural_value_cases,
		"ko_operational_state_mismatches": ko_operational_state_mismatches,
		"survivor_operational_changes_after_teammate_ko": survivor_operational_changes_after_teammate_ko,
		"survivor_structural_change_after_teammate_ko": survivor_structural_change_after_teammate_ko,
		"survivor_structural_decrease_after_teammate_ko": survivor_structural_decrease_after_teammate_ko,
	}


func _contract_state_by_id(contract: Dictionary, instance_id: String) -> Dictionary:
	for raw_state in contract.get("member_states", []):
		if raw_state is Dictionary:
			var state := raw_state as Dictionary
			if String(state.get("instance_id", "")) == instance_id:
				return state
	return {}


func _immediate_value_vector(state: Dictionary) -> Dictionary:
	var structural := state.get("structural", {}) as Dictionary
	var operational := state.get("operational", {}) as Dictionary
	return {
		"instance_id": String(state.get("instance_id", "")),
		"structural_value_bp": int(structural.get("structural_value_bp", 0)),
		"hp_state_bp": int(operational.get("hp_state_bp", 0)),
		"route_retention_bp": int(operational.get("route_retention_bp", 0)),
		"immediate_status_action_bp": int(operational.get("immediate_status_action_bp", 0)),
	}


func _dominates(a: Dictionary, b: Dictionary) -> bool:
	var dimensions := [
		"structural_value_bp",
		"hp_state_bp",
		"route_retention_bp",
		"immediate_status_action_bp",
	]
	var strictly_better := false
	for dimension in dimensions:
		var av := int(a.get(dimension, 0))
		var bv := int(b.get(dimension, 0))
		if av < bv:
			return false
		if av > bv:
			strictly_better = true
	return strictly_better


func _structural_operational_tradeoff(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("structural_value_bp", 0)) <= int(b.get("structural_value_bp", 0)):
		return false
	return (
		int(a.get("hp_state_bp", 0)) < int(b.get("hp_state_bp", 0))
		or int(a.get("route_retention_bp", 0)) < int(b.get("route_retention_bp", 0))
		or int(a.get("immediate_status_action_bp", 0)) < int(b.get("immediate_status_action_bp", 0))
	)


func _immediate_numeric_signature(operational: Dictionary) -> Array[int]:
	return [
		int(operational.get("hp_state_bp", 0)),
		int(operational.get("route_retention_bp", 0)),
		int(operational.get("immediate_status_action_bp", 0)),
	]


func _contains_any_key_recursive(value: Variant, keys: Array[String]) -> bool:
	if value is Dictionary:
		var dictionary := value as Dictionary
		for raw_key in dictionary.keys():
			var key := String(raw_key)
			if keys.has(key):
				return true
			if _contains_any_key_recursive(dictionary[raw_key], keys):
				return true
	elif value is Array:
		for item in value as Array:
			if _contains_any_key_recursive(item, keys):
				return true
	return false
