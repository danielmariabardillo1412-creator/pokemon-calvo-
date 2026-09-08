class_name TrainerRosterParetoFrontierConsumptionAuditTestSuite
extends TrainerRosterParetoFrontierProductionTestSuite

const AUDIT_ID_C3FK := "c3f_k_pareto_frontier_consumption_semantics_audit_v1"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_consumption_semantics_synthetic()
	_test_consumption_semantics_real_data()


func _test_consumption_semantics_synthetic() -> void:
	var evaluator := TrainerRosterParetoFrontier.new()
	var structural_heavy := _vector("a", 9000, 6000, 9000, 6000)
	var operational_heavy := _vector("z", 6000, 9000, 6000, 9000)
	var dominated := _vector("m", 5000, 5000, 5000, 5000)
	var contract := _production_synthetic_contract([
		_synthetic_state("z", operational_heavy, 9000, false),
		_synthetic_state("m", dominated, 3000, false),
		_synthetic_state("a", structural_heavy, 1000, true),
	])
	var contract_snapshot := contract.duplicate(true)
	var frontier := evaluator.evaluate(contract)
	var frontier_ids := frontier.get("frontier_instance_ids", []) as Array
	var dominated_ids := frontier.get("dominated_instance_ids", []) as Array
	var joined_frontier := _join_ids_lossless(contract, frontier_ids)
	var joined_dominated := _join_ids_lossless(contract, dominated_ids)

	_check.call(
		"frontier_consumption_synthetic_has_unresolved_tradeoff",
		frontier_ids == ["a", "z"] and int(frontier.get("frontier_count", -1)) == 2,
	)
	_check.call(
		"frontier_consumption_frontier_join_is_lossless",
		int(joined_frontier.get("missing", -1)) == 0
		and int(joined_frontier.get("duplicates", -1)) == 0
		and int((joined_frontier.get("states", []) as Array).size()) == 2,
	)
	_check.call(
		"frontier_consumption_dominated_join_is_lossless",
		dominated_ids == ["m"]
		and int(joined_dominated.get("missing", -1)) == 0
		and int(joined_dominated.get("duplicates", -1)) == 0
		and int((joined_dominated.get("states", []) as Array).size()) == 1,
	)
	_check.call(
		"frontier_consumption_keeps_structural_and_operational_separate",
		_joined_components_match_contract(contract, joined_frontier.get("states", []) as Array),
	)
	_check.call(
		"frontier_consumption_dominated_state_remains_auditable",
		_joined_components_match_contract(contract, joined_dominated.get("states", []) as Array),
	)

	var renamed := contract.duplicate(true)
	var renamed_states := renamed.get("member_states", []) as Array
	for raw_state in renamed_states:
		if not (raw_state is Dictionary):
			continue
		var state := raw_state as Dictionary
		var instance_id := String(state.get("instance_id", ""))
		if instance_id == "a":
			state["instance_id"] = "z"
		elif instance_id == "z":
			state["instance_id"] = "a"
	renamed["member_states"] = renamed_states
	var renamed_frontier := evaluator.evaluate(renamed)
	var original_first := _single_joined_state(contract, String(frontier_ids[0]))
	var renamed_ids := renamed_frontier.get("frontier_instance_ids", []) as Array
	var renamed_first := _single_joined_state(renamed, String(renamed_ids[0]))
	var original_first_structural := int((original_first.get("structural", {}) as Dictionary).get("structural_value_bp", -1))
	var renamed_first_structural := int((renamed_first.get("structural", {}) as Dictionary).get("structural_value_bp", -1))
	_check.call(
		"frontier_consumption_lexical_first_is_not_semantic_tiebreak",
		frontier_ids == ["a", "z"]
		and renamed_ids == ["a", "z"]
		and original_first_structural != renamed_first_structural,
	)

	var side_a := contract.duplicate(true)
	var side_b := contract.duplicate(true)
	var states_a := side_a.get("member_states", []) as Array
	var states_b := side_b.get("member_states", []) as Array
	for raw_state in states_a:
		if raw_state is Dictionary and String((raw_state as Dictionary).get("instance_id", "")) == "a":
			var state := raw_state as Dictionary
			var operational := state.get("operational", {}) as Dictionary
			operational["attrition"] = {"next_active_tick_loss_max_hp_bp": 1}
			operational["held_item"] = {"available": true, "item_id": "synthetic_a"}
			state["operational"] = operational
	for raw_state in states_b:
		if raw_state is Dictionary and String((raw_state as Dictionary).get("instance_id", "")) == "a":
			var state := raw_state as Dictionary
			var operational := state.get("operational", {}) as Dictionary
			operational["attrition"] = {"next_active_tick_loss_max_hp_bp": 9999}
			operational["held_item"] = {"available": false, "item_id": "synthetic_b"}
			state["operational"] = operational
	side_a["member_states"] = states_a
	side_b["member_states"] = states_b
	_check.call(
		"frontier_consumption_side_evidence_cannot_hidden_tiebreak",
		evaluator.evaluate(side_a) == evaluator.evaluate(side_b),
	)

	var single_contract := _production_synthetic_contract([
		_synthetic_state("strong", _vector("strong", 9000, 9000, 9000, 9000), 1000, true),
		_synthetic_state("weak", _vector("weak", 5000, 5000, 5000, 5000), 9999, false),
	])
	var single_frontier := evaluator.evaluate(single_contract)
	_check.call(
		"frontier_consumption_single_frontier_is_not_action_decision",
		int(single_frontier.get("frontier_count", -1)) == 1
		and not single_frontier.has("action_type")
		and not single_frontier.has("selected_member_id")
		and not single_frontier.has("best_member_id"),
	)

	var stale_frontier := single_frontier.duplicate(true)
	var ko_contract := single_contract.duplicate(true)
	var ko_states := ko_contract.get("member_states", []) as Array
	for raw_state in ko_states:
		if raw_state is Dictionary and String((raw_state as Dictionary).get("instance_id", "")) == "strong":
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
	var fresh_frontier := evaluator.evaluate(ko_contract)
	_check.call(
		"frontier_consumption_roster_change_requires_recompute",
		(stale_frontier.get("frontier_instance_ids", []) as Array).has("strong")
		and not (fresh_frontier.get("frontier_instance_ids", []) as Array).has("strong")
		and fresh_frontier.get("frontier_instance_ids", []) == ["weak"],
	)
	_check.call("frontier_consumption_audit_does_not_mutate_contract", contract == contract_snapshot)


func _test_consumption_semantics_real_data() -> void:
	var report_a := _build_c3fk_report()
	var report_b := _build_c3fk_report()

	_check.call(
		"frontier_consumption_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FK,
	)
	_check.call(
		"frontier_consumption_uses_certified_real_data_sample",
		int(report_a.get("eligible_species", 0)) == 1021
		and int(report_a.get("sampled_rosters", 0)) == 128
		and int(report_a.get("eligible_member_states", 0)) == 768,
	)
	_check.call(
		"frontier_consumption_reproduces_certified_partition",
		int(report_a.get("frontier_member_occurrences", -1)) == 424
		and int(report_a.get("dominated_member_occurrences", -1)) == 344
		and int(report_a.get("single_frontier_rosters", -1)) == 12
		and int(report_a.get("multiple_frontier_rosters", -1)) == 116,
	)
	_check.call(
		"frontier_consumption_frontier_join_complete",
		int(report_a.get("frontier_join_missing_cases", -1)) == 0
		and int(report_a.get("frontier_join_duplicate_cases", -1)) == 0,
	)
	_check.call(
		"frontier_consumption_dominated_join_complete",
		int(report_a.get("dominated_join_missing_cases", -1)) == 0
		and int(report_a.get("dominated_join_duplicate_cases", -1)) == 0,
	)
	_check.call(
		"frontier_consumption_components_preserved_losslessly",
		int(report_a.get("component_preservation_mismatches", -1)) == 0,
	)
	_check.call(
		"frontier_consumption_ko_recompute_invalidates_stale_frontier",
		int(report_a.get("ko_probe_cases", -1)) == KO_PROBE_ROSTERS
		and int(report_a.get("stale_frontier_invalidated_cases", -1)) == KO_PROBE_ROSTERS
		and int(report_a.get("ko_frontier_inclusions", -1)) == 0,
	)
	_check.call(
		"frontier_consumption_ko_rejoin_complete",
		int(report_a.get("ko_rejoin_missing_cases", -1)) == 0
		and int(report_a.get("ko_rejoin_duplicate_cases", -1)) == 0,
	)
	_check.call(
		"frontier_consumption_no_tiebreak_semantics_recorded",
		not bool(report_a.get("lexical_order_used_as_tiebreak", true))
		and not bool(report_a.get("side_evidence_used_as_tiebreak", true))
		and not bool(report_a.get("single_frontier_is_action_decision", true)),
	)
	_check.call(
		"frontier_consumption_keeps_behavior_integration_unauthorized",
		not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call(
		"frontier_consumption_contains_no_hidden_scalar_ranking_or_context",
		int(report_a.get("forbidden_output_key_cases", -1)) == 0
		and int(report_a.get("forbidden_context_key_cases", -1)) == 0,
	)
	_check.call("frontier_consumption_report_deterministic", report_a == report_b)
	_check.call(
		"frontier_consumption_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER PARETO FRONTIER CONSUMPTION SEMANTICS AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fk_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FK, "eligible_species": 0}

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
	var single_frontier_rosters := 0
	var multiple_frontier_rosters := 0
	var frontier_join_missing_cases := 0
	var frontier_join_duplicate_cases := 0
	var dominated_join_missing_cases := 0
	var dominated_join_duplicate_cases := 0
	var component_preservation_mismatches := 0
	var forbidden_output_key_cases := 0
	var forbidden_context_key_cases := 0

	for anchor in range(0, members.size(), SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var contract := contract_evaluator.build_contract(degraded)
		var frontier := frontier_evaluator.evaluate(contract)
		var frontier_ids := frontier.get("frontier_instance_ids", []) as Array
		var dominated_ids := frontier.get("dominated_instance_ids", []) as Array
		var frontier_join := _join_ids_lossless(contract, frontier_ids)
		var dominated_join := _join_ids_lossless(contract, dominated_ids)

		sampled_rosters += 1
		eligible_member_states += int(frontier.get("eligible_member_count", 0))
		frontier_member_occurrences += frontier_ids.size()
		dominated_member_occurrences += dominated_ids.size()
		if frontier_ids.size() == 1:
			single_frontier_rosters += 1
		elif frontier_ids.size() > 1:
			multiple_frontier_rosters += 1
		frontier_join_missing_cases += int(frontier_join.get("missing", 0))
		frontier_join_duplicate_cases += int(frontier_join.get("duplicates", 0))
		dominated_join_missing_cases += int(dominated_join.get("missing", 0))
		dominated_join_duplicate_cases += int(dominated_join.get("duplicates", 0))
		if not _joined_components_match_contract(contract, frontier_join.get("states", []) as Array):
			component_preservation_mismatches += 1
		if not _joined_components_match_contract(contract, dominated_join.get("states", []) as Array):
			component_preservation_mismatches += 1
		if _contains_any_key_recursive(frontier, FORBIDDEN_CONTRACT_KEYS):
			forbidden_output_key_cases += 1
		if _contains_any_key_recursive(frontier, FORBIDDEN_CONTEXT_KEYS):
			forbidden_context_key_cases += 1

	var stale_frontier_invalidated_cases := 0
	var ko_frontier_inclusions := 0
	var ko_rejoin_missing_cases := 0
	var ko_rejoin_duplicate_cases := 0
	for anchor in range(KO_PROBE_ROSTERS):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, anchor)
		var baseline_contract := contract_evaluator.build_contract(degraded)
		var baseline_frontier := frontier_evaluator.evaluate(baseline_contract)
		var baseline_ids := baseline_frontier.get("frontier_instance_ids", []) as Array
		if baseline_ids.is_empty():
			continue
		var removed_id := String(baseline_ids[0])
		for member in degraded:
			if String(member.get("instance_id", "")) == removed_id:
				member["current_hp"] = 0
				member["is_knocked_out"] = true
				break
		var fresh_contract := contract_evaluator.build_contract(degraded)
		var fresh_frontier := frontier_evaluator.evaluate(fresh_contract)
		var fresh_ids := fresh_frontier.get("frontier_instance_ids", []) as Array
		if baseline_ids.has(removed_id) and not fresh_ids.has(removed_id):
			stale_frontier_invalidated_cases += 1
		if fresh_ids.has(removed_id):
			ko_frontier_inclusions += 1
		var fresh_join := _join_ids_lossless(fresh_contract, fresh_ids)
		ko_rejoin_missing_cases += int(fresh_join.get("missing", 0))
		ko_rejoin_duplicate_cases += int(fresh_join.get("duplicates", 0))

	var report := {
		"audit_id": AUDIT_ID_C3FK,
		"production_frontier_model_id": TrainerRosterParetoFrontier.MODEL_ID,
		"source_contract_model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"eligible_species": members.size(),
		"sample_stride": SAMPLE_STRIDE,
		"sampled_rosters": sampled_rosters,
		"eligible_member_states": eligible_member_states,
		"frontier_member_occurrences": frontier_member_occurrences,
		"dominated_member_occurrences": dominated_member_occurrences,
		"single_frontier_rosters": single_frontier_rosters,
		"multiple_frontier_rosters": multiple_frontier_rosters,
		"frontier_join_missing_cases": frontier_join_missing_cases,
		"frontier_join_duplicate_cases": frontier_join_duplicate_cases,
		"dominated_join_missing_cases": dominated_join_missing_cases,
		"dominated_join_duplicate_cases": dominated_join_duplicate_cases,
		"component_preservation_mismatches": component_preservation_mismatches,
		"ko_probe_cases": KO_PROBE_ROSTERS,
		"stale_frontier_invalidated_cases": stale_frontier_invalidated_cases,
		"ko_frontier_inclusions": ko_frontier_inclusions,
		"ko_rejoin_missing_cases": ko_rejoin_missing_cases,
		"ko_rejoin_duplicate_cases": ko_rejoin_duplicate_cases,
		"lexical_order_used_as_tiebreak": false,
		"side_evidence_used_as_tiebreak": false,
		"single_frontier_is_action_decision": false,
		"behavior_integration_authorized": false,
		"forbidden_output_key_cases": forbidden_output_key_cases,
		"forbidden_context_key_cases": forbidden_context_key_cases,
	}
	if _contains_any_key_recursive(report, FORBIDDEN_CONTRACT_KEYS):
		report["forbidden_output_key_cases"] = int(report.get("forbidden_output_key_cases", 0)) + 1
	if _contains_any_key_recursive(report, FORBIDDEN_CONTEXT_KEYS):
		report["forbidden_context_key_cases"] = int(report.get("forbidden_context_key_cases", 0)) + 1
	_catalog = fixture_catalog
	return report


func _join_ids_lossless(contract: Dictionary, ids: Array) -> Dictionary:
	var joined: Array = []
	var missing := 0
	var duplicates := 0
	for raw_id in ids:
		var instance_id := String(raw_id)
		var matches: Array = []
		for raw_state in contract.get("member_states", []):
			if raw_state is Dictionary and String((raw_state as Dictionary).get("instance_id", "")) == instance_id:
				matches.append((raw_state as Dictionary).duplicate(true))
		if matches.is_empty():
			missing += 1
		elif matches.size() > 1:
			duplicates += matches.size() - 1
		else:
			joined.append(matches[0])
	return {"states": joined, "missing": missing, "duplicates": duplicates}


func _single_joined_state(contract: Dictionary, instance_id: String) -> Dictionary:
	var result := _join_ids_lossless(contract, [instance_id])
	var states := result.get("states", []) as Array
	if states.size() != 1 or not (states[0] is Dictionary):
		return {}
	return states[0] as Dictionary


func _joined_components_match_contract(contract: Dictionary, joined_states: Array) -> bool:
	for raw_joined in joined_states:
		if not (raw_joined is Dictionary):
			return false
		var joined := raw_joined as Dictionary
		var original := _single_contract_state(contract, String(joined.get("instance_id", "")))
		if original.is_empty():
			return false
		if joined.get("species_id", null) != original.get("species_id", null):
			return false
		if joined.get("structural", null) != original.get("structural", null):
			return false
		if joined.get("operational", null) != original.get("operational", null):
			return false
	return true


func _single_contract_state(contract: Dictionary, instance_id: String) -> Dictionary:
	var found: Dictionary = {}
	var count := 0
	for raw_state in contract.get("member_states", []):
		if raw_state is Dictionary and String((raw_state as Dictionary).get("instance_id", "")) == instance_id:
			found = raw_state as Dictionary
			count += 1
	if count != 1:
		return {}
	return found
