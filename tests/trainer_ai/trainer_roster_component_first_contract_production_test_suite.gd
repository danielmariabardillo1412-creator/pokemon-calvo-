class_name TrainerRosterComponentFirstContractProductionTestSuite
extends TrainerRosterComponentFirstConsumerContractAuditTestSuite


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_component_first_contract_production()


func _test_component_first_contract_production() -> void:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	_check.call("component_contract_production_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data := GameData.from_dict(normalized)
	var catalog := game_data.to_definition_catalog()
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe := helper._build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)
	_check.call("component_contract_production_probe_has_eligible_species", members.size() == 1021)
	if members.size() < TrainerRosterStructuralRealDataAuditTestSuite.ROSTER_SIZE:
		return

	var fixture_catalog := _catalog
	_catalog = catalog
	var roster := helper._scheduled_roster(
		members,
		0,
		int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0]),
	)
	var degraded := _degraded_roster(roster, 0)
	var input_snapshot := degraded.duplicate(true)
	var evaluator := TrainerRosterComponentFirstContract.new(catalog, _operational_ruleset)
	var production := evaluator.build_contract(degraded)
	var candidate := _component_first_contract(degraded, catalog)
	candidate["model_id"] = TrainerRosterComponentFirstContract.MODEL_ID

	_check.call(
		"component_contract_production_model_recorded",
		String(production.get("model_id", "")) == TrainerRosterComponentFirstContract.MODEL_ID,
	)
	_check.call(
		"component_contract_production_source_models_recorded",
		String(production.get("structural_model_id", ""))
		== TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID
		and String(production.get("structural_formula_id", ""))
		== TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_FORMULA_ID
		and String(production.get("operational_model_id", ""))
		== TrainerRosterOperationalReadinessEvaluator.MODEL_ID,
	)
	_check.call(
		"component_contract_production_matches_certified_candidate_shape",
		production == candidate,
	)
	_check.call(
		"component_contract_production_counts_all_operational_members",
		int(production.get("member_count", -1)) == degraded.size()
		and (production.get("member_states", []) as Array).size() == degraded.size(),
	)
	_check.call(
		"component_contract_production_does_not_mutate_input",
		degraded == input_snapshot,
	)

	var reversed := degraded.duplicate(true)
	reversed.reverse()
	_check.call(
		"component_contract_production_input_reorder_invariant",
		evaluator.build_contract(reversed) == production,
	)
	var state_ids: Array[String] = []
	for raw_state in production.get("member_states", []):
		if raw_state is Dictionary:
			state_ids.append(String((raw_state as Dictionary).get("instance_id", "")))
	var sorted_state_ids := state_ids.duplicate()
	sorted_state_ids.sort()
	_check.call(
		"component_contract_production_member_order_is_lexical",
		state_ids == sorted_state_ids,
	)

	var all_operational_available := true
	var all_survivors_structural_available := true
	for raw_state in production.get("member_states", []):
		if not (raw_state is Dictionary):
			all_operational_available = false
			all_survivors_structural_available = false
			continue
		var state := raw_state as Dictionary
		var operational := state.get("operational", {}) as Dictionary
		var structural := state.get("structural", {}) as Dictionary
		if not bool(operational.get("available", false)):
			all_operational_available = false
		if String(state.get("availability_state", "")) == "surviving" and not bool(structural.get("available", false)):
			all_survivors_structural_available = false
	_check.call("component_contract_production_operational_join_complete", all_operational_available)
	_check.call("component_contract_production_survivor_structural_join_complete", all_survivors_structural_available)

	var knocked := degraded.duplicate(true)
	var ko_id := String(knocked[1].get("instance_id", ""))
	knocked[1]["current_hp"] = 0
	knocked[1]["is_knocked_out"] = true
	var ko_contract := evaluator.build_contract(knocked)
	var ko_state := _contract_state_by_id(ko_contract, ko_id)
	var ko_structural := ko_state.get("structural", {}) as Dictionary
	var ko_operational := ko_state.get("operational", {}) as Dictionary
	_check.call(
		"component_contract_production_ko_retained_operationally",
		not ko_state.is_empty()
		and String(ko_state.get("availability_state", "")) == "knocked_out"
		and bool(ko_operational.get("available", false))
		and bool(ko_operational.get("is_knocked_out", false))
		and int(ko_operational.get("hp_state_bp", -1)) == 0,
	)
	_check.call(
		"component_contract_production_ko_has_no_fake_structural_value",
		not bool(ko_structural.get("available", true))
		and not ko_structural.has("structural_value_bp")
		and String(ko_structural.get("unavailable_reason", ""))
		== "knocked_out_not_in_surviving_structural_roster",
	)

	var target_id := String(degraded[0].get("instance_id", ""))
	var before_target := _contract_state_by_id(production, target_id)
	var after_ko_target := _contract_state_by_id(ko_contract, target_id)
	_check.call(
		"component_contract_production_teammate_ko_does_not_rewrite_operational_state",
		before_target.get("operational", {}) == after_ko_target.get("operational", {}),
	)

	_check.call(
		"component_contract_production_attrition_and_item_remain_separate",
		(ko_operational.get("attrition", {}) is Dictionary)
		and (ko_operational.get("held_item", {}) is Dictionary)
		and not ko_operational.has("operational_readiness_bp"),
	)
	_check.call(
		"component_contract_production_contains_no_hidden_scalar_or_policy",
		not _contains_any_key_recursive(production, FORBIDDEN_CONTRACT_KEYS)
		and not _contains_any_key_recursive(production, FORBIDDEN_CONTEXT_KEYS),
	)
	_check.call(
		"component_contract_production_has_no_behavior_selection",
		not production.has("selected_combined_scalar")
		and not production.has("consumer_behavior_integration_authorized")
		and not production.has("best_member_id")
		and not production.has("selected_member_id"),
	)

	var deterministic_again := evaluator.build_contract(degraded)
	_check.call("component_contract_production_is_deterministic", production == deterministic_again)
	_check.call(
		"component_contract_production_is_json_serializable",
		JSON.parse_string(JSON.stringify(production)) is Dictionary,
	)

	var invalid_result := evaluator.build_contract([
		42,
		{},
		{"instance_id": "missing_species", "species_id": ""},
	])
	_check.call(
		"component_contract_production_invalid_members_fail_closed",
		int(invalid_result.get("member_count", -1)) == 0
		and (invalid_result.get("member_states", []) as Array).is_empty(),
	)
	var null_result := TrainerRosterComponentFirstContract.new(null, _operational_ruleset).build_contract(degraded)
	_check.call(
		"component_contract_production_null_catalog_fails_closed",
		String(null_result.get("model_id", "")) == TrainerRosterComponentFirstContract.MODEL_ID
		and int(null_result.get("member_count", -1)) == 0
		and (null_result.get("member_states", []) as Array).is_empty(),
	)

	_catalog = fixture_catalog
