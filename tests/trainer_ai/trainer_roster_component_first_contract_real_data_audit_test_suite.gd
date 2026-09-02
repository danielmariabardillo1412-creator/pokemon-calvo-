class_name TrainerRosterComponentFirstContractRealDataAuditTestSuite
extends TrainerRosterComponentFirstContractProductionTestSuite

const AUDIT_ID_C3FH := "c3f_h_component_first_contract_production_real_data_v1"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_component_first_contract_real_data()


func _test_component_first_contract_real_data() -> void:
	var report_a := _build_c3fh_report()
	var report_b := _build_c3fh_report()

	_check.call(
		"component_contract_real_data_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FH,
	)
	_check.call(
		"component_contract_real_data_has_canonical_eligible_species",
		int(report_a.get("eligible_species", 0)) == 1021,
	)
	_check.call(
		"component_contract_real_data_uses_128_rosters",
		int(report_a.get("sampled_rosters", 0)) == 128
		and int(report_a.get("member_states", 0)) == 768,
	)
	_check.call(
		"component_contract_real_data_matches_certified_candidate_roster_by_roster",
		int(report_a.get("candidate_parity_mismatches", -1)) == 0,
	)
	_check.call(
		"component_contract_real_data_reorder_invariant",
		int(report_a.get("reorder_mismatches", -1)) == 0,
	)
	_check.call(
		"component_contract_real_data_identity_and_model_ids_match",
		int(report_a.get("identity_mismatches", -1)) == 0
		and int(report_a.get("model_id_mismatches", -1)) == 0,
	)
	_check.call(
		"component_contract_real_data_joins_are_complete",
		int(report_a.get("missing_operational_join_cases", -1)) == 0
		and int(report_a.get("missing_structural_survivor_join_cases", -1)) == 0
		and int(report_a.get("duplicate_instance_id_cases", -1)) == 0,
	)
	_check.call(
		"component_contract_real_data_keeps_forbidden_scalar_policy_context_absent",
		int(report_a.get("forbidden_contract_key_cases", -1)) == 0
		and int(report_a.get("forbidden_context_key_cases", -1)) == 0,
	)
	_check.call(
		"component_contract_real_data_exercises_ko_semantics",
		int(report_a.get("ko_probe_cases", -1)) == KO_PROBE_ROSTERS
		and int(report_a.get("ko_candidate_parity_mismatches", -1)) == 0
		and int(report_a.get("ko_state_mismatches", -1)) == 0
		and int(report_a.get("ko_fake_structural_value_cases", -1)) == 0,
	)
	_check.call(
		"component_contract_real_data_preserves_operational_state_of_survivors_after_teammate_ko",
		int(report_a.get("survivor_operational_changes_after_teammate_ko", -1)) == 0,
	)
	_check.call(
		"component_contract_real_data_recomputes_structural_context_after_teammate_ko",
		int(report_a.get("survivor_structural_decrease_after_teammate_ko", -1)) == 0
		and int(report_a.get("survivor_structural_change_after_teammate_ko", 0)) > 0,
	)
	_check.call(
		"component_contract_real_data_contains_pareto_dominance_and_incomparability",
		int(report_a.get("pair_comparisons", 0)) == 1920
		and int(report_a.get("pareto_dominance_pairs", 0)) > 0
		and int(report_a.get("incomparable_pairs", 0)) > 0,
	)
	_check.call(
		"component_contract_real_data_preserves_structural_operational_tradeoffs",
		int(report_a.get("structural_higher_operational_lower_pairs", 0)) > 0,
	)
	_check.call(
		"component_contract_real_data_keeps_attrition_outside_immediate_pareto",
		bool(report_a.get("attrition_excluded_from_immediate_pareto", false)),
	)
	_check.call(
		"component_contract_real_data_does_not_authorize_behavior",
		report_a.get("selected_combined_scalar") == null
		and not bool(report_a.get("consumer_behavior_integration_authorized", true)),
	)
	_check.call("component_contract_real_data_report_deterministic", report_a == report_b)
	_check.call(
		"component_contract_real_data_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER COMPONENT-FIRST PRODUCTION REAL-DATA AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fh_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FH, "eligible_species": 0}

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
	var evaluator := TrainerRosterComponentFirstContract.new(catalog, _operational_ruleset)

	var sampled_rosters := 0
	var member_states := 0
	var candidate_parity_mismatches := 0
	var reorder_mismatches := 0
	var identity_mismatches := 0
	var model_id_mismatches := 0
	var missing_operational_join_cases := 0
	var missing_structural_survivor_join_cases := 0
	var duplicate_instance_id_cases := 0
	var forbidden_contract_key_cases := 0
	var forbidden_context_key_cases := 0
	var pair_comparisons := 0
	var pareto_dominance_pairs := 0
	var incomparable_pairs := 0
	var structural_higher_operational_lower_pairs := 0
	var structural_available_states := 0
	var operational_available_states := 0
	var sampled_species_examples: Array[String] = []

	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])
	for anchor in range(0, members.size(), SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var production := evaluator.build_contract(degraded)
		var candidate := _component_first_contract(degraded, catalog)
		candidate["model_id"] = TrainerRosterComponentFirstContract.MODEL_ID

		sampled_rosters += 1
		member_states += int(production.get("member_count", 0))
		if production != candidate:
			candidate_parity_mismatches += 1

		var reversed := degraded.duplicate(true)
		reversed.reverse()
		if evaluator.build_contract(reversed) != production:
			reorder_mismatches += 1

		if (
			String(production.get("model_id", "")) != TrainerRosterComponentFirstContract.MODEL_ID
			or String(production.get("structural_model_id", ""))
			!= TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID
			or String(production.get("structural_formula_id", ""))
			!= TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_FORMULA_ID
			or String(production.get("operational_model_id", ""))
			!= TrainerRosterOperationalReadinessEvaluator.MODEL_ID
		):
			model_id_mismatches += 1
		if _contains_any_key_recursive(production, FORBIDDEN_CONTRACT_KEYS):
			forbidden_contract_key_cases += 1
		if _contains_any_key_recursive(production, FORBIDDEN_CONTEXT_KEYS):
			forbidden_context_key_cases += 1

		var seen_ids: Dictionary = {}
		var surviving_vectors: Array[Dictionary] = []
		for raw_state in production.get("member_states", []):
			if not (raw_state is Dictionary):
				identity_mismatches += 1
				continue
			var state := raw_state as Dictionary
			var instance_id := String(state.get("instance_id", ""))
			var species_id := String(state.get("species_id", ""))
			if instance_id.is_empty() or species_id.is_empty():
				identity_mismatches += 1
			if seen_ids.has(instance_id):
				duplicate_instance_id_cases += 1
			seen_ids[instance_id] = true

			var operational := state.get("operational", {}) as Dictionary
			var structural := state.get("structural", {}) as Dictionary
			if not bool(operational.get("available", false)):
				missing_operational_join_cases += 1
			else:
				operational_available_states += 1
			if String(operational.get("species_id", "")) != species_id:
				identity_mismatches += 1
			if String(state.get("availability_state", "")) == "surviving":
				if not bool(structural.get("available", false)):
					missing_structural_survivor_join_cases += 1
				else:
					structural_available_states += 1
					if String(structural.get("species_id", "")) != species_id:
						identity_mismatches += 1
				surviving_vectors.append(_immediate_value_vector(state))
			if sampled_species_examples.size() < 12:
				sampled_species_examples.append(species_id)

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

	var ko_probe_cases := 0
	var ko_candidate_parity_mismatches := 0
	var ko_state_mismatches := 0
	var ko_fake_structural_value_cases := 0
	var survivor_operational_changes_after_teammate_ko := 0
	var survivor_structural_change_after_teammate_ko := 0
	var survivor_structural_decrease_after_teammate_ko := 0

	for anchor in range(KO_PROBE_ROSTERS):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, anchor)
		var baseline := evaluator.build_contract(degraded)
		var knocked := degraded.duplicate(true)
		var ko_index := anchor % TrainerRosterStructuralRealDataAuditTestSuite.ROSTER_SIZE
		var ko_id := String(knocked[ko_index].get("instance_id", ""))
		knocked[ko_index]["current_hp"] = 0
		knocked[ko_index]["is_knocked_out"] = true
		var production_ko := evaluator.build_contract(knocked)
		var candidate_ko := _component_first_contract(knocked, catalog)
		candidate_ko["model_id"] = TrainerRosterComponentFirstContract.MODEL_ID
		ko_probe_cases += 1
		if production_ko != candidate_ko:
			ko_candidate_parity_mismatches += 1

		var ko_state := _contract_state_by_id(production_ko, ko_id)
		var ko_operational := ko_state.get("operational", {}) as Dictionary
		var ko_structural := ko_state.get("structural", {}) as Dictionary
		if (
			ko_state.is_empty()
			or String(ko_state.get("availability_state", "")) != "knocked_out"
			or not bool(ko_operational.get("available", false))
			or not bool(ko_operational.get("is_knocked_out", false))
			or int(ko_operational.get("hp_state_bp", -1)) != 0
		):
			ko_state_mismatches += 1
		if bool(ko_structural.get("available", true)) or ko_structural.has("structural_value_bp"):
			ko_fake_structural_value_cases += 1

		for raw_state in baseline.get("member_states", []):
			if not (raw_state is Dictionary):
				continue
			var before := raw_state as Dictionary
			var survivor_id := String(before.get("instance_id", ""))
			if survivor_id == ko_id:
				continue
			var after := _contract_state_by_id(production_ko, survivor_id)
			if after.is_empty():
				continue
			if before.get("operational", {}) != after.get("operational", {}):
				survivor_operational_changes_after_teammate_ko += 1
			var before_structural := before.get("structural", {}) as Dictionary
			var after_structural := after.get("structural", {}) as Dictionary
			if bool(before_structural.get("available", false)) and bool(after_structural.get("available", false)):
				var before_bp := int(before_structural.get("structural_value_bp", 0))
				var after_bp := int(after_structural.get("structural_value_bp", 0))
				if after_bp != before_bp:
					survivor_structural_change_after_teammate_ko += 1
				if after_bp < before_bp:
					survivor_structural_decrease_after_teammate_ko += 1

	_catalog = fixture_catalog
	return {
		"audit_id": AUDIT_ID_C3FH,
		"production_model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"structural_model_id": TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID,
		"structural_formula_id": TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_FORMULA_ID,
		"operational_model_id": TrainerRosterOperationalReadinessEvaluator.MODEL_ID,
		"eligible_species": members.size(),
		"sample_stride": SAMPLE_STRIDE,
		"sampled_rosters": sampled_rosters,
		"member_states": member_states,
		"sampled_species_examples": sampled_species_examples,
		"candidate_parity_mismatches": candidate_parity_mismatches,
		"reorder_mismatches": reorder_mismatches,
		"identity_mismatches": identity_mismatches,
		"model_id_mismatches": model_id_mismatches,
		"missing_operational_join_cases": missing_operational_join_cases,
		"missing_structural_survivor_join_cases": missing_structural_survivor_join_cases,
		"duplicate_instance_id_cases": duplicate_instance_id_cases,
		"forbidden_contract_key_cases": forbidden_contract_key_cases,
		"forbidden_context_key_cases": forbidden_context_key_cases,
		"structural_available_states": structural_available_states,
		"operational_available_states": operational_available_states,
		"pair_comparisons": pair_comparisons,
		"pareto_dominance_pairs": pareto_dominance_pairs,
		"incomparable_pairs": incomparable_pairs,
		"structural_higher_operational_lower_pairs": structural_higher_operational_lower_pairs,
		"attrition_excluded_from_immediate_pareto": true,
		"ko_probe_cases": ko_probe_cases,
		"ko_candidate_parity_mismatches": ko_candidate_parity_mismatches,
		"ko_state_mismatches": ko_state_mismatches,
		"ko_fake_structural_value_cases": ko_fake_structural_value_cases,
		"survivor_operational_changes_after_teammate_ko": survivor_operational_changes_after_teammate_ko,
		"survivor_structural_change_after_teammate_ko": survivor_structural_change_after_teammate_ko,
		"survivor_structural_decrease_after_teammate_ko": survivor_structural_decrease_after_teammate_ko,
		"selected_combined_scalar": null,
		"consumer_behavior_integration_authorized": false,
	}
