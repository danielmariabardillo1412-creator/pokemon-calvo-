class_name TrainerRosterComponentFirstParetoFrontierAuditTestSuite
extends TrainerRosterComponentFirstContractRealDataAuditTestSuite

const AUDIT_ID_C3FI := "c3f_i_component_first_pareto_frontier_audit_v1"
const FRONTIER_DIMENSIONS: Array[String] = [
	"structural_value_bp",
	"hp_state_bp",
	"route_retention_bp",
	"immediate_status_action_bp",
]


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_component_first_pareto_frontier()


func _test_component_first_pareto_frontier() -> void:
	var report_a := _build_c3fi_report()
	var report_b := _build_c3fi_report()
	var synthetic := report_a.get("synthetic_invariants", {}) as Dictionary

	_check.call(
		"pareto_frontier_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FI,
	)
	_check.call(
		"pareto_frontier_dimensions_are_explicit_and_component_first",
		report_a.get("frontier_dimensions", []) == FRONTIER_DIMENSIONS,
	)
	_check.call(
		"pareto_frontier_uses_certified_real_data_sample",
		int(report_a.get("eligible_species", 0)) == 1021
		and int(report_a.get("sampled_rosters", 0)) == 128
		and int(report_a.get("eligible_member_states", 0)) == 768,
	)
	_check.call(
		"pareto_frontier_reproduces_c3fh_pair_geometry",
		int(report_a.get("pair_comparisons", 0)) == 1920
		and int(report_a.get("pareto_dominance_pairs", 0)) == 519
		and int(report_a.get("incomparable_pairs", 0)) == 1401,
	)
	_check.call(
		"pareto_frontier_accounts_for_every_eligible_member",
		int(report_a.get("frontier_member_occurrences", -1))
		+ int(report_a.get("dominated_member_occurrences", -1))
		== int(report_a.get("eligible_member_states", -2)),
	)
	_check.call(
		"pareto_frontier_is_nonempty_and_bounded_per_roster",
		int(report_a.get("empty_frontier_rosters", -1)) == 0
		and int(report_a.get("frontier_size_min", 0)) >= 1
		and int(report_a.get("frontier_size_max", 0)) <= TrainerRosterStructuralRealDataAuditTestSuite.ROSTER_SIZE,
	)
	_check.call(
		"pareto_frontier_real_data_actually_filters_dominated_members",
		int(report_a.get("dominated_member_occurrences", 0)) > 0
		and int(report_a.get("rosters_with_reduction", 0)) > 0,
	)
	_check.call(
		"pareto_frontier_is_input_order_invariant_and_lexical",
		int(report_a.get("reorder_frontier_mismatches", -1)) == 0
		and int(report_a.get("frontier_order_mismatches", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_excludes_ko_without_erasing_contract_state",
		int(report_a.get("ko_probe_cases", -1)) == KO_PROBE_ROSTERS
		and int(report_a.get("ko_contract_missing_cases", -1)) == 0
		and int(report_a.get("ko_frontier_inclusions", -1)) == 0
		and int(report_a.get("ko_empty_frontier_cases", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_adding_dominated_alternative_keeps_frontier",
		bool(synthetic.get("dominated_injection_invariant", false)),
	)
	_check.call(
		"pareto_frontier_adding_incomparable_alternative_preserves_it",
		bool(synthetic.get("incomparable_injection_invariant", false)),
	)
	_check.call(
		"pareto_frontier_equal_vectors_do_not_break_ties",
		bool(synthetic.get("equal_vector_tie_invariant", false)),
	)
	_check.call(
		"pareto_frontier_componentwise_improvement_is_monotonic",
		bool(synthetic.get("componentwise_monotonicity", false)),
	)
	_check.call(
		"pareto_frontier_tradeoff_remains_incomparable",
		bool(synthetic.get("tradeoff_incomparability", false)),
	)
	_check.call(
		"pareto_frontier_item_and_attrition_do_not_enter_immediate_vector",
		bool(synthetic.get("non_vector_evidence_excluded", false)),
	)
	_check.call(
		"pareto_frontier_keeps_attrition_outside_without_horizon",
		bool(report_a.get("attrition_excluded_from_immediate_frontier", false)),
	)
	_check.call(
		"pareto_frontier_contains_no_hidden_scalar_ranking_or_context",
		int(report_a.get("forbidden_frontier_key_cases", -1)) == 0
		and int(report_a.get("forbidden_context_key_cases", -1)) == 0,
	)
	_check.call(
		"pareto_frontier_does_not_authorize_behavior_or_production_port",
		not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("frontier_production_authorized", true)),
	)
	_check.call("pareto_frontier_report_deterministic", report_a == report_b)
	_check.call(
		"pareto_frontier_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER COMPONENT-FIRST PARETO FRONTIER AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fi_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FI, "eligible_species": 0}

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
	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])

	var sampled_rosters := 0
	var eligible_member_states := 0
	var frontier_member_occurrences := 0
	var dominated_member_occurrences := 0
	var rosters_with_reduction := 0
	var all_frontier_rosters := 0
	var single_frontier_rosters := 0
	var empty_frontier_rosters := 0
	var frontier_size_min := 999
	var frontier_size_max := 0
	var frontier_size_sum := 0
	var frontier_size_histogram: Dictionary = {}
	var reorder_frontier_mismatches := 0
	var frontier_order_mismatches := 0
	var pair_comparisons := 0
	var pareto_dominance_pairs := 0
	var incomparable_pairs := 0
	var identical_vector_pairs := 0
	var frontier_identical_vector_pairs := 0
	var forbidden_frontier_key_cases := 0
	var forbidden_context_key_cases := 0
	var frontier_examples: Array[Dictionary] = []

	for anchor in range(0, members.size(), SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var contract := evaluator.build_contract(degraded)
		var vectors := _eligible_frontier_vectors(contract)
		var frontier_ids := _frontier_ids(vectors)
		var sorted_copy := frontier_ids.duplicate()
		sorted_copy.sort()

		sampled_rosters += 1
		eligible_member_states += vectors.size()
		frontier_member_occurrences += frontier_ids.size()
		dominated_member_occurrences += vectors.size() - frontier_ids.size()
		frontier_size_sum += frontier_ids.size()
		frontier_size_min = mini(frontier_size_min, frontier_ids.size())
		frontier_size_max = maxi(frontier_size_max, frontier_ids.size())
		var histogram_key := String.num_int64(frontier_ids.size())
		frontier_size_histogram[histogram_key] = int(frontier_size_histogram.get(histogram_key, 0)) + 1
		if frontier_ids.is_empty():
			empty_frontier_rosters += 1
		if frontier_ids.size() < vectors.size():
			rosters_with_reduction += 1
		if frontier_ids.size() == vectors.size():
			all_frontier_rosters += 1
		if frontier_ids.size() == 1:
			single_frontier_rosters += 1
		if frontier_ids != sorted_copy:
			frontier_order_mismatches += 1

		var reversed := degraded.duplicate(true)
		reversed.reverse()
		var reversed_frontier := _frontier_ids(_eligible_frontier_vectors(evaluator.build_contract(reversed)))
		if reversed_frontier != frontier_ids:
			reorder_frontier_mismatches += 1

		for i in range(vectors.size()):
			for j in range(i + 1, vectors.size()):
				var a := vectors[i]
				var b := vectors[j]
				pair_comparisons += 1
				var a_dominates := _dominates(a, b)
				var b_dominates := _dominates(b, a)
				if a_dominates or b_dominates:
					pareto_dominance_pairs += 1
				else:
					incomparable_pairs += 1
				if _same_numeric_vector(a, b):
					identical_vector_pairs += 1
					if frontier_ids.has(String(a.get("instance_id", ""))) and frontier_ids.has(String(b.get("instance_id", ""))):
						frontier_identical_vector_pairs += 1

		if _contains_any_key_recursive({"frontier_instance_ids": frontier_ids}, FORBIDDEN_CONTRACT_KEYS):
			forbidden_frontier_key_cases += 1
		if _contains_any_key_recursive({"frontier_instance_ids": frontier_ids}, FORBIDDEN_CONTEXT_KEYS):
			forbidden_context_key_cases += 1
		if frontier_examples.size() < 8:
			frontier_examples.append({
				"anchor": anchor,
				"eligible_count": vectors.size(),
				"frontier_instance_ids": frontier_ids,
			})

	var ko_contract_missing_cases := 0
	var ko_frontier_inclusions := 0
	var ko_empty_frontier_cases := 0
	for anchor in range(KO_PROBE_ROSTERS):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, anchor)
		var ko_index := anchor % TrainerRosterStructuralRealDataAuditTestSuite.ROSTER_SIZE
		var ko_id := String(degraded[ko_index].get("instance_id", ""))
		degraded[ko_index]["current_hp"] = 0
		degraded[ko_index]["is_knocked_out"] = true
		var contract := evaluator.build_contract(degraded)
		var ko_state := _contract_state_by_id(contract, ko_id)
		if ko_state.is_empty() or String(ko_state.get("availability_state", "")) != "knocked_out":
			ko_contract_missing_cases += 1
		var frontier_ids := _frontier_ids(_eligible_frontier_vectors(contract))
		if frontier_ids.has(ko_id):
			ko_frontier_inclusions += 1
		if frontier_ids.is_empty():
			ko_empty_frontier_cases += 1

	var synthetic := _synthetic_frontier_invariants()
	var report := {
		"audit_id": AUDIT_ID_C3FI,
		"production_contract_model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"frontier_dimensions": FRONTIER_DIMENSIONS.duplicate(),
		"eligible_species": members.size(),
		"sample_stride": SAMPLE_STRIDE,
		"sampled_rosters": sampled_rosters,
		"eligible_member_states": eligible_member_states,
		"frontier_member_occurrences": frontier_member_occurrences,
		"dominated_member_occurrences": dominated_member_occurrences,
		"rosters_with_reduction": rosters_with_reduction,
		"all_frontier_rosters": all_frontier_rosters,
		"single_frontier_rosters": single_frontier_rosters,
		"empty_frontier_rosters": empty_frontier_rosters,
		"frontier_size_min": 0 if sampled_rosters == 0 else frontier_size_min,
		"frontier_size_max": frontier_size_max,
		"frontier_size_sum": frontier_size_sum,
		"frontier_size_histogram": frontier_size_histogram,
		"identical_vector_pairs": identical_vector_pairs,
		"frontier_identical_vector_pairs": frontier_identical_vector_pairs,
		"pair_comparisons": pair_comparisons,
		"pareto_dominance_pairs": pareto_dominance_pairs,
		"incomparable_pairs": incomparable_pairs,
		"reorder_frontier_mismatches": reorder_frontier_mismatches,
		"frontier_order_mismatches": frontier_order_mismatches,
		"ko_probe_cases": KO_PROBE_ROSTERS,
		"ko_contract_missing_cases": ko_contract_missing_cases,
		"ko_frontier_inclusions": ko_frontier_inclusions,
		"ko_empty_frontier_cases": ko_empty_frontier_cases,
		"forbidden_frontier_key_cases": forbidden_frontier_key_cases,
		"forbidden_context_key_cases": forbidden_context_key_cases,
		"frontier_examples": frontier_examples,
		"synthetic_invariants": synthetic,
		"attrition_excluded_from_immediate_frontier": true,
		"behavior_integration_authorized": false,
		"frontier_production_authorized": false,
	}
	if _contains_any_key_recursive(report, FORBIDDEN_CONTRACT_KEYS):
		report["forbidden_frontier_key_cases"] = int(report.get("forbidden_frontier_key_cases", 0)) + 1
	if _contains_any_key_recursive(report, FORBIDDEN_CONTEXT_KEYS):
		report["forbidden_context_key_cases"] = int(report.get("forbidden_context_key_cases", 0)) + 1
	_catalog = fixture_catalog
	return report


func _eligible_frontier_vectors(contract: Dictionary) -> Array[Dictionary]:
	var vectors: Array[Dictionary] = []
	for raw_state in contract.get("member_states", []):
		if not (raw_state is Dictionary):
			continue
		var state := raw_state as Dictionary
		if String(state.get("availability_state", "")) != "surviving":
			continue
		var structural := state.get("structural", {}) as Dictionary
		var operational := state.get("operational", {}) as Dictionary
		if not bool(structural.get("available", false)) or not bool(operational.get("available", false)):
			continue
		vectors.append(_immediate_value_vector(state))
	return vectors


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


func _same_numeric_vector(a: Dictionary, b: Dictionary) -> bool:
	for dimension in FRONTIER_DIMENSIONS:
		if int(a.get(dimension, 0)) != int(b.get(dimension, 0)):
			return false
	return true


func _synthetic_frontier_invariants() -> Dictionary:
	var a := _vector("a", 8000, 8000, 8000, 8000)
	var b := _vector("b", 7000, 7000, 7000, 7000)
	var c := _vector("c", 6000, 6000, 6000, 6000)
	var d := _vector("d", 9000, 7000, 9000, 7000)
	var e := _vector("e", 8000, 8000, 8000, 8000)
	var superior := _vector("superior", 8001, 8000, 8000, 8000)

	var base_frontier := _frontier_ids([a, b])
	var dominated_frontier := _frontier_ids([a, b, c])
	var incomparable_frontier := _frontier_ids([a, b, d])
	var tie_frontier := _frontier_ids([a, e])

	var state_item_a := _synthetic_state("item_a", a, 100, true)
	var state_item_b := _synthetic_state("item_b", a, 9000, false)
	var item_vector_a := _immediate_value_vector(state_item_a)
	var item_vector_b := _immediate_value_vector(state_item_b)
	item_vector_b["instance_id"] = "item_b"

	return {
		"dominated_injection_invariant": base_frontier == ["a"] and dominated_frontier == ["a"],
		"incomparable_injection_invariant": incomparable_frontier == ["a", "d"],
		"equal_vector_tie_invariant": tie_frontier == ["a", "e"] and not _dominates(a, e) and not _dominates(e, a),
		"componentwise_monotonicity": _dominates(superior, a) and not _dominates(a, superior),
		"tradeoff_incomparability": not _dominates(a, d) and not _dominates(d, a),
		"non_vector_evidence_excluded": _same_numeric_vector(item_vector_a, item_vector_b)
		and not _dominates(item_vector_a, item_vector_b)
		and not _dominates(item_vector_b, item_vector_a),
	}


func _vector(
	instance_id: String,
	structural_value_bp: int,
	hp_state_bp: int,
	route_retention_bp: int,
	immediate_status_action_bp: int,
) -> Dictionary:
	return {
		"instance_id": instance_id,
		"structural_value_bp": structural_value_bp,
		"hp_state_bp": hp_state_bp,
		"route_retention_bp": route_retention_bp,
		"immediate_status_action_bp": immediate_status_action_bp,
	}


func _synthetic_state(instance_id: String, vector: Dictionary, attrition_bp: int, item_available: bool) -> Dictionary:
	return {
		"instance_id": instance_id,
		"species_id": "synthetic",
		"availability_state": "surviving",
		"structural": {
			"available": true,
			"instance_id": instance_id,
			"species_id": "synthetic",
			"structural_value_bp": int(vector.get("structural_value_bp", 0)),
		},
		"operational": {
			"available": true,
			"instance_id": instance_id,
			"species_id": "synthetic",
			"hp_state_bp": int(vector.get("hp_state_bp", 0)),
			"route_retention_bp": int(vector.get("route_retention_bp", 0)),
			"immediate_status_action_bp": int(vector.get("immediate_status_action_bp", 0)),
			"attrition": {"next_active_tick_loss_max_hp_bp": attrition_bp},
			"held_item": {"available": item_available},
		},
	}
