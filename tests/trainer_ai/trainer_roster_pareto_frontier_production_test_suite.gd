class_name TrainerRosterParetoFrontierProductionTestSuite
extends TrainerRosterComponentFirstParetoFrontierAuditTestSuite

const AUDIT_ID_C3FJ := "c3f_j_pareto_frontier_production_real_data_v1"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_pareto_frontier_production_contract()
	_test_pareto_frontier_production_real_data()


func _test_pareto_frontier_production_contract() -> void:
	var evaluator := TrainerRosterParetoFrontier.new()
	var a := _vector("a", 8000, 8000, 8000, 8000)
	var b := _vector("b", 7000, 7000, 7000, 7000)
	var d := _vector("d", 9000, 7000, 9000, 7000)
	var e := _vector("e", 8000, 8000, 8000, 8000)
	var base_contract := _production_synthetic_contract([
		_synthetic_state("b", b, 700, false),
		_synthetic_state("a", a, 100, true),
	])
	var input_snapshot := base_contract.duplicate(true)
	var result := evaluator.evaluate(base_contract)
	var expected := _frontier_ids(_eligible_frontier_vectors(base_contract))

	_check.call(
		"pareto_frontier_production_model_recorded",
		String(result.get("model_id", "")) == TrainerRosterParetoFrontier.MODEL_ID,
	)
	_check.call(
		"pareto_frontier_production_source_contract_recorded",
		String(result.get("source_contract_model_id", "")) == TrainerRosterComponentFirstContract.MODEL_ID,
	)
	_check.call(
		"pareto_frontier_production_dimensions_match_c3fi",
		result.get("frontier_dimensions", []) == FRONTIER_DIMENSIONS
		and TrainerRosterParetoFrontier.FRONTIER_DIMENSIONS == FRONTIER_DIMENSIONS,
	)
	_check.call("pareto_frontier_production_accepts_valid_contract", bool(result.get("input_contract_valid", false)))
	_check.call(
		"pareto_frontier_production_matches_c3fi_synthetic_frontier",
		result.get("frontier_instance_ids", []) == expected
		and result.get("frontier_instance_ids", []) == ["a"],
	)
	_check.call(
		"pareto_frontier_production_exposes_partition_without_ranking",
		result.get("dominated_instance_ids", []) == ["b"]
		and int(result.get("eligible_member_count", -1)) == 2
		and int(result.get("frontier_count", -1)) == 1
		and int(result.get("dominated_count", -1)) == 1,
	)
	_check.call("pareto_frontier_production_does_not_mutate_input", base_contract == input_snapshot)

	var reversed_contract := base_contract.duplicate(true)
	var reversed_states := reversed_contract.get("member_states", []) as Array
	reversed_states.reverse()
	reversed_contract["member_states"] = reversed_states
	_check.call(
		"pareto_frontier_production_input_order_invariant",
		evaluator.evaluate(reversed_contract) == result,
	)
	var frontier_ids := result.get("frontier_instance_ids", []) as Array
	var dominated_ids := result.get("dominated_instance_ids", []) as Array
	var frontier_sorted := frontier_ids.duplicate()
	var dominated_sorted := dominated_ids.duplicate()
	frontier_sorted.sort()
	dominated_sorted.sort()
	_check.call(
		"pareto_frontier_production_outputs_are_lexical",
		frontier_ids == frontier_sorted and dominated_ids == dominated_sorted,
	)

	var tie_contract := _production_synthetic_contract([
		_synthetic_state("e", e, 9000, false),
		_synthetic_state("a", a, 100, true),
	])
	_check.call(
		"pareto_frontier_production_equal_vectors_preserve_both",
		evaluator.evaluate(tie_contract).get("frontier_instance_ids", []) == ["a", "e"],
	)
	var tradeoff_contract := _production_synthetic_contract([
		_synthetic_state("d", d, 200, false),
		_synthetic_state("a", a, 9000, true),
	])
	_check.call(
		"pareto_frontier_production_tradeoff_remains_incomparable",
		evaluator.evaluate(tradeoff_contract).get("frontier_instance_ids", []) == ["a", "d"],
	)

	var non_vector_a := tie_contract.duplicate(true)
	var non_vector_b := tie_contract.duplicate(true)
	var states_a := non_vector_a.get("member_states", []) as Array
	var states_b := non_vector_b.get("member_states", []) as Array
	(states_a[0] as Dictionary)["operational"]["attrition"] = {"next_active_tick_loss_max_hp_bp": 1}
	(states_a[0] as Dictionary)["operational"]["held_item"] = {"available": true}
	(states_b[0] as Dictionary)["operational"]["attrition"] = {"next_active_tick_loss_max_hp_bp": 9999}
	(states_b[0] as Dictionary)["operational"]["held_item"] = {"available": false}
	non_vector_a["member_states"] = states_a
	non_vector_b["member_states"] = states_b
	_check.call(
		"pareto_frontier_production_item_and_attrition_are_non_vector",
		evaluator.evaluate(non_vector_a) == evaluator.evaluate(non_vector_b)
		and bool(result.get("attrition_excluded_from_immediate_frontier", false))
		and bool(result.get("held_item_excluded_from_immediate_frontier", false)),
	)

	var ko_contract := tradeoff_contract.duplicate(true)
	var ko_states := ko_contract.get("member_states", []) as Array
	for raw_state in ko_states:
		if raw_state is Dictionary and String((raw_state as Dictionary).get("instance_id", "")) == "a":
			var state := raw_state as Dictionary
			state["availability_state"] = "knocked_out"
			var structural := state.get("structural", {}) as Dictionary
			structural["available"] = false
			structural.erase("structural_value_bp")
			state["structural"] = structural
			var operational := state.get("operational", {}) as Dictionary
			operational["is_knocked_out"] = true
			operational["hp_state_bp"] = 0
			state["operational"] = operational
	ko_contract["member_states"] = ko_states
	var ko_snapshot := ko_contract.duplicate(true)
	var ko_result := evaluator.evaluate(ko_contract)
	_check.call(
		"pareto_frontier_production_excludes_ko_without_erasing_contract",
		bool(ko_result.get("input_contract_valid", false))
		and not (ko_result.get("frontier_instance_ids", []) as Array).has("a")
		and not (ko_result.get("dominated_instance_ids", []) as Array).has("a")
		and ko_contract == ko_snapshot,
	)

	var unavailable_contract := tradeoff_contract.duplicate(true)
	var unavailable_states := unavailable_contract.get("member_states", []) as Array
	var unavailable_state := unavailable_states[0] as Dictionary
	var unavailable_structural := unavailable_state.get("structural", {}) as Dictionary
	unavailable_structural["available"] = false
	unavailable_structural.erase("structural_value_bp")
	unavailable_state["structural"] = unavailable_structural
	unavailable_states[0] = unavailable_state
	unavailable_contract["member_states"] = unavailable_states
	var unavailable_result := evaluator.evaluate(unavailable_contract)
	_check.call(
		"pareto_frontier_production_unavailable_survivor_is_ineligible_not_fabricated",
		bool(unavailable_result.get("input_contract_valid", false))
		and int(unavailable_result.get("eligible_member_count", -1)) == 1,
	)

	var wrong_model := base_contract.duplicate(true)
	wrong_model["model_id"] = "wrong_contract"
	_check.call("pareto_frontier_production_wrong_model_fails_closed", _is_closed_empty(evaluator.evaluate(wrong_model)))
	var wrong_count := base_contract.duplicate(true)
	wrong_count["member_count"] = 999
	_check.call("pareto_frontier_production_wrong_member_count_fails_closed", _is_closed_empty(evaluator.evaluate(wrong_count)))
	var duplicate_ids := base_contract.duplicate(true)
	var duplicate_states := duplicate_ids.get("member_states", []) as Array
	(duplicate_states[1] as Dictionary)["instance_id"] = String((duplicate_states[0] as Dictionary).get("instance_id", ""))
	duplicate_ids["member_states"] = duplicate_states
	_check.call("pareto_frontier_production_duplicate_id_fails_closed", _is_closed_empty(evaluator.evaluate(duplicate_ids)))
	var missing_vector := base_contract.duplicate(true)
	var missing_states := missing_vector.get("member_states", []) as Array
	var missing_state := missing_states[0] as Dictionary
	var missing_operational := missing_state.get("operational", {}) as Dictionary
	missing_operational.erase("route_retention_bp")
	missing_state["operational"] = missing_operational
	missing_states[0] = missing_state
	missing_vector["member_states"] = missing_states
	_check.call("pareto_frontier_production_missing_component_fails_closed", _is_closed_empty(evaluator.evaluate(missing_vector)))

	_check.call("pareto_frontier_production_is_deterministic", evaluator.evaluate(base_contract) == result)
	_check.call(
		"pareto_frontier_production_is_json_serializable",
		JSON.parse_string(JSON.stringify(result)) is Dictionary,
	)
	_check.call(
		"pareto_frontier_production_contains_no_hidden_scalar_ranking_or_context",
		not _contains_any_key_recursive(result, FORBIDDEN_CONTRACT_KEYS)
		and not _contains_any_key_recursive(result, FORBIDDEN_CONTEXT_KEYS),
	)
	_check.call(
		"pareto_frontier_production_has_no_behavior_selection",
		not result.has("best_member_id")
		and not result.has("selected_member_id")
		and not result.has("ranking")
		and not result.has("behavior_integration_authorized"),
	)


func _test_pareto_frontier_production_real_data() -> void:
	var report_a := _build_c3fj_report()
	var report_b := _build_c3fj_report()

	_check.call(
		"pareto_frontier_production_real_data_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FJ,
	)
	_check.call(
		"pareto_frontier_production_real_data_uses_c3fi_sample",
		int(report_a.get("eligible_species", 0)) == 1021
		and int(report_a.get("sampled_rosters", 0)) == 128
		and int(report_a.get("eligible_member_states", 0)) == 768,
	)
	_check.call(
		"pareto_frontier_production_real_data_exact_c3fi_frontier_parity",
		int(report_a.get("frontier_parity_mismatches", -1)) == 0
		and int(report_a.get("dominated_partition_mismatches", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_production_real_data_reproduces_c3fi_distribution",
		int(report_a.get("frontier_member_occurrences", -1)) == 424
		and int(report_a.get("dominated_member_occurrences", -1)) == 344
		and int(report_a.get("rosters_with_reduction", -1)) == 124
		and report_a.get("frontier_size_histogram", {}) == {
			"1": 12,
			"2": 22,
			"3": 34,
			"4": 38,
			"5": 18,
			"6": 4,
		},
	)
	_check.call(
		"pareto_frontier_production_real_data_models_and_dimensions_match",
		int(report_a.get("model_id_mismatches", -1)) == 0
		and int(report_a.get("source_contract_model_id_mismatches", -1)) == 0
		and int(report_a.get("dimension_mismatches", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_production_real_data_reorder_invariant",
		int(report_a.get("reorder_mismatches", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_production_real_data_does_not_mutate_contract",
		int(report_a.get("contract_mutation_cases", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_production_real_data_ko_parity",
		int(report_a.get("ko_probe_cases", -1)) == KO_PROBE_ROSTERS
		and int(report_a.get("ko_frontier_parity_mismatches", -1)) == 0
		and int(report_a.get("ko_frontier_inclusions", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_production_real_data_keeps_scalar_policy_context_absent",
		int(report_a.get("forbidden_output_key_cases", -1)) == 0
		and int(report_a.get("forbidden_context_key_cases", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_production_real_data_behavior_stays_unauthorized",
		not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call("pareto_frontier_production_real_data_report_deterministic", report_a == report_b)
	_check.call(
		"pareto_frontier_production_real_data_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER PARETO FRONTIER PRODUCTION REAL-DATA AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fj_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FJ, "eligible_species": 0}

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
	var contract_evaluator := TrainerRosterComponentFirstContract.new(catalog, _operational_ruleset)
	var frontier_evaluator := TrainerRosterParetoFrontier.new()
	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])

	var sampled_rosters := 0
	var eligible_member_states := 0
	var frontier_member_occurrences := 0
	var dominated_member_occurrences := 0
	var rosters_with_reduction := 0
	var frontier_size_histogram: Dictionary = {}
	var frontier_parity_mismatches := 0
	var dominated_partition_mismatches := 0
	var model_id_mismatches := 0
	var source_contract_model_id_mismatches := 0
	var dimension_mismatches := 0
	var reorder_mismatches := 0
	var contract_mutation_cases := 0
	var forbidden_output_key_cases := 0
	var forbidden_context_key_cases := 0

	for anchor in range(0, members.size(), SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var contract := contract_evaluator.build_contract(degraded)
		var contract_snapshot := contract.duplicate(true)
		var vectors := _eligible_frontier_vectors(contract)
		var expected_frontier := _frontier_ids(vectors)
		var expected_dominated: Array[String] = []
		for vector in vectors:
			var instance_id := String(vector.get("instance_id", ""))
			if not expected_frontier.has(instance_id):
				expected_dominated.append(instance_id)
		expected_dominated.sort()
		var actual := frontier_evaluator.evaluate(contract)

		sampled_rosters += 1
		eligible_member_states += vectors.size()
		var actual_frontier := actual.get("frontier_instance_ids", []) as Array
		var actual_dominated := actual.get("dominated_instance_ids", []) as Array
		frontier_member_occurrences += actual_frontier.size()
		dominated_member_occurrences += actual_dominated.size()
		if actual_frontier.size() < vectors.size():
			rosters_with_reduction += 1
		var histogram_key := String.num_int64(actual_frontier.size())
		frontier_size_histogram[histogram_key] = int(frontier_size_histogram.get(histogram_key, 0)) + 1
		if actual_frontier != expected_frontier:
			frontier_parity_mismatches += 1
		if actual_dominated != expected_dominated:
			dominated_partition_mismatches += 1
		if String(actual.get("model_id", "")) != TrainerRosterParetoFrontier.MODEL_ID:
			model_id_mismatches += 1
		if String(actual.get("source_contract_model_id", "")) != TrainerRosterComponentFirstContract.MODEL_ID:
			source_contract_model_id_mismatches += 1
		if actual.get("frontier_dimensions", []) != FRONTIER_DIMENSIONS:
			dimension_mismatches += 1
		if contract != contract_snapshot:
			contract_mutation_cases += 1
		if _contains_any_key_recursive(actual, FORBIDDEN_CONTRACT_KEYS):
			forbidden_output_key_cases += 1
		if _contains_any_key_recursive(actual, FORBIDDEN_CONTEXT_KEYS):
			forbidden_context_key_cases += 1

		var reversed_contract := contract.duplicate(true)
		var reversed_states := reversed_contract.get("member_states", []) as Array
		reversed_states.reverse()
		reversed_contract["member_states"] = reversed_states
		if frontier_evaluator.evaluate(reversed_contract) != actual:
			reorder_mismatches += 1

	var ko_frontier_parity_mismatches := 0
	var ko_frontier_inclusions := 0
	for anchor in range(KO_PROBE_ROSTERS):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, anchor)
		var ko_index := anchor % TrainerRosterStructuralRealDataAuditTestSuite.ROSTER_SIZE
		var ko_id := String(degraded[ko_index].get("instance_id", ""))
		degraded[ko_index]["current_hp"] = 0
		degraded[ko_index]["is_knocked_out"] = true
		var contract := contract_evaluator.build_contract(degraded)
		var expected_frontier := _frontier_ids(_eligible_frontier_vectors(contract))
		var actual_frontier := frontier_evaluator.evaluate(contract).get("frontier_instance_ids", []) as Array
		if actual_frontier != expected_frontier:
			ko_frontier_parity_mismatches += 1
		if actual_frontier.has(ko_id):
			ko_frontier_inclusions += 1

	var report := {
		"audit_id": AUDIT_ID_C3FJ,
		"production_model_id": TrainerRosterParetoFrontier.MODEL_ID,
		"source_contract_model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"frontier_dimensions": FRONTIER_DIMENSIONS.duplicate(),
		"eligible_species": members.size(),
		"sample_stride": SAMPLE_STRIDE,
		"sampled_rosters": sampled_rosters,
		"eligible_member_states": eligible_member_states,
		"frontier_member_occurrences": frontier_member_occurrences,
		"dominated_member_occurrences": dominated_member_occurrences,
		"rosters_with_reduction": rosters_with_reduction,
		"frontier_size_histogram": frontier_size_histogram,
		"frontier_parity_mismatches": frontier_parity_mismatches,
		"dominated_partition_mismatches": dominated_partition_mismatches,
		"model_id_mismatches": model_id_mismatches,
		"source_contract_model_id_mismatches": source_contract_model_id_mismatches,
		"dimension_mismatches": dimension_mismatches,
		"reorder_mismatches": reorder_mismatches,
		"contract_mutation_cases": contract_mutation_cases,
		"ko_probe_cases": KO_PROBE_ROSTERS,
		"ko_frontier_parity_mismatches": ko_frontier_parity_mismatches,
		"ko_frontier_inclusions": ko_frontier_inclusions,
		"forbidden_output_key_cases": forbidden_output_key_cases,
		"forbidden_context_key_cases": forbidden_context_key_cases,
		"attrition_excluded_from_immediate_frontier": true,
		"held_item_excluded_from_immediate_frontier": true,
		"behavior_integration_authorized": false,
	}
	if _contains_any_key_recursive(report, FORBIDDEN_CONTRACT_KEYS):
		report["forbidden_output_key_cases"] = int(report.get("forbidden_output_key_cases", 0)) + 1
	if _contains_any_key_recursive(report, FORBIDDEN_CONTEXT_KEYS):
		report["forbidden_context_key_cases"] = int(report.get("forbidden_context_key_cases", 0)) + 1
	_catalog = fixture_catalog
	return report


func _production_synthetic_contract(states: Array) -> Dictionary:
	return {
		"model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"structural_model_id": TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID,
		"structural_formula_id": TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_FORMULA_ID,
		"operational_model_id": TrainerRosterOperationalReadinessEvaluator.MODEL_ID,
		"member_count": states.size(),
		"member_states": states,
	}


func _is_closed_empty(result: Dictionary) -> bool:
	return (
		String(result.get("model_id", "")) == TrainerRosterParetoFrontier.MODEL_ID
		and not bool(result.get("input_contract_valid", true))
		and int(result.get("eligible_member_count", -1)) == 0
		and int(result.get("frontier_count", -1)) == 0
		and int(result.get("dominated_count", -1)) == 0
		and (result.get("frontier_instance_ids", []) as Array).is_empty()
		and (result.get("dominated_instance_ids", []) as Array).is_empty()
	)
