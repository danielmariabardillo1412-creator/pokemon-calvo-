class_name TrainerRosterOperationalReadinessProductionRealDataAuditTestSuite
extends TrainerRosterOperationalReadinessProductionTestSuite

const AUDIT_ID := "c3f_e_operational_readiness_production_real_data_v1"
const SAMPLE_STRIDE := 8
const EXPECTED_ELIGIBLE_SPECIES := 1021


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_production_real_data_audit()


func _test_production_real_data_audit() -> void:
	_enable_runtime_team_moves()
	var report_a := _build_c3fe_report()
	var report_b := _build_c3fe_report()

	_check.call(
		"readiness_production_real_data_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID,
	)
	_check.call(
		"readiness_production_real_data_has_canonical_eligible_species",
		int(report_a.get("eligible_species", -1)) == EXPECTED_ELIGIBLE_SPECIES,
	)
	_check.call(
		"readiness_production_real_data_full_healthy_probe_exercised",
		int(report_a.get("healthy_member_count", -1)) == EXPECTED_ELIGIBLE_SPECIES,
	)
	_check.call(
		"readiness_production_real_data_healthy_components_match_certified_helpers",
		int(report_a.get("healthy_component_parity_mismatches", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_healthy_route_breakdown_matches_certified_helpers",
		int(report_a.get("healthy_route_evidence_mismatches", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_healthy_state_is_full_readiness_components",
		int(report_a.get("healthy_non_ceiling_component_cases", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_uses_128_member_degraded_sample",
		int(report_a.get("sample_stride", -1)) == SAMPLE_STRIDE
		and int(report_a.get("degraded_sample_members", -1)) == 128,
	)
	_check.call(
		"readiness_production_real_data_degraded_components_match_certified_helpers",
		int(report_a.get("degraded_component_parity_mismatches", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_degraded_route_evidence_matches_certified_helpers",
		int(report_a.get("degraded_route_evidence_mismatches", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_attrition_bp_matches_certified_helpers",
		int(report_a.get("attrition_bp_mismatches", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_attrition_integer_damage_matches_runtime_contract",
		int(report_a.get("attrition_raw_damage_mismatches", -1)) == 0
		and int(report_a.get("attrition_applied_damage_mismatches", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_active_bench_semantics_match_runtime_contract",
		int(report_a.get("active_bench_application_mismatches", -1)) == 0
		and int(report_a.get("active_attrition_cases", 0)) > 0
		and int(report_a.get("bench_attrition_formula_cases", 0)) > 0,
	)
	_check.call(
		"readiness_production_real_data_held_item_remains_evidence_only",
		int(report_a.get("held_item_component_mismatches", -1)) == 0,
	)
	_check.call(
		"readiness_production_real_data_exercises_all_status_families",
		_all_status_families_present(report_a.get("status_case_counts", {}) as Dictionary),
	)
	_check.call(
		"readiness_production_real_data_components_are_bounded_and_diverse",
		_component_ranges_are_bounded(report_a)
		and int(report_a.get("distinct_immediate_component_vectors", 0)) > 16,
	)
	_check.call(
		"readiness_production_real_data_has_runtime_move_evidence",
		int(report_a.get("healthy_runtime_move_entries", 0)) > EXPECTED_ELIGIBLE_SPECIES,
	)
	_check.call(
		"readiness_production_real_data_keeps_blocked_scalar_and_policy_absent",
		int(report_a.get("blocked_output_cases", -1)) == 0
		and report_a.get("selected_operational_readiness_formula") == null,
	)
	_check.call("readiness_production_real_data_report_deterministic", report_a == report_b)
	_check.call(
		"readiness_production_real_data_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER OPERATIONAL READINESS PRODUCTION REAL-DATA AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fe_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID, "eligible_species": 0}

	var game_data := GameData.from_dict(normalized)
	var real_catalog := game_data.to_definition_catalog()
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe: Dictionary = helper._build_probe_members(game_data, real_catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)

	var fixture_catalog := _catalog
	_catalog = real_catalog
	var evaluator := TrainerRosterOperationalReadinessEvaluator.new(real_catalog, _operational_ruleset)

	var healthy_member_count := 0
	var healthy_component_parity_mismatches := 0
	var healthy_route_evidence_mismatches := 0
	var healthy_non_ceiling_component_cases := 0
	var healthy_runtime_move_entries := 0
	var blocked_output_cases := 0
	var sampled_species_examples: Array[String] = []

	for raw_member in members:
		var healthy := _real_member_with_full_pp(raw_member)
		healthy["is_active"] = true
		var evidence := _operational_evidence(healthy)
		var expected := _component_vector(evidence)
		var result := evaluator.evaluate_current_components([healthy])
		var production := _first_production_member(result)
		healthy_member_count += 1
		if not _components_match(production, expected):
			healthy_component_parity_mismatches += 1
		if not _route_evidence_matches(production, evidence):
			healthy_route_evidence_mismatches += 1
		if (
			int(production.get("hp_state_bp", -1)) != 10000
			or int(production.get("route_retention_bp", -1)) != 10000
			or int(production.get("immediate_status_action_bp", -1)) != 10000
		):
			healthy_non_ceiling_component_cases += 1
		var route := (production.get("breakdown", {}) as Dictionary).get("route_retention", {}) as Dictionary
		healthy_runtime_move_entries += (route.get("runtime_move_pp", []) as Array).size()
		if _contains_forbidden_key(result):
			blocked_output_cases += 1

	var degraded_sample_members := 0
	var degraded_component_parity_mismatches := 0
	var degraded_route_evidence_mismatches := 0
	var attrition_bp_mismatches := 0
	var attrition_raw_damage_mismatches := 0
	var attrition_applied_damage_mismatches := 0
	var active_bench_application_mismatches := 0
	var held_item_component_mismatches := 0
	var active_attrition_cases := 0
	var bench_attrition_formula_cases := 0
	var status_case_counts: Dictionary = {}
	var component_signature_set: Dictionary = {}
	var component_sums := {
		"hp_state_bp": 0,
		"route_retention_bp": 0,
		"immediate_status_action_bp": 0,
	}
	var component_mins := {
		"hp_state_bp": 10001,
		"route_retention_bp": 10001,
		"immediate_status_action_bp": 10001,
	}
	var component_maxs := {
		"hp_state_bp": -1,
		"route_retention_bp": -1,
		"immediate_status_action_bp": -1,
	}
	var hp_cycle := [2500, 5000, 7500, 10000]

	for index in range(0, members.size(), SAMPLE_STRIDE):
		var member := _real_member_with_full_pp(members[index])
		var sample_index := degraded_sample_members
		var stats := member.get("stats", {}) as Dictionary
		var max_hp := maxi(1, int(stats.get("max_hp", 1)))
		var target_hp_bp := int(hp_cycle[sample_index % hp_cycle.size()])
		member["current_hp"] = maxi(1, max_hp * target_hp_bp / 10000)
		member["is_active"] = sample_index % 2 == 0

		var move_ids := member.get("move_ids", []) as Array
		if sample_index % 2 == 0 and not move_ids.is_empty():
			var first_move_id := StringName(String(move_ids[0]))
			var first_move := real_catalog.move(first_move_id)
			if first_move != null:
				_set_move_pp(member, first_move_id, 0, maxi(1, int(first_move.pp)))
		if sample_index % 5 == 0 and move_ids.size() >= 2:
			var second_move_id := StringName(String(move_ids[1]))
			var second_move := real_catalog.move(second_move_id)
			if second_move != null:
				_set_move_pp(member, second_move_id, 0, maxi(1, int(second_move.pp)))

		var status_id := _apply_real_status_cycle(member, sample_index)
		status_case_counts[String(status_id)] = int(status_case_counts.get(String(status_id), 0)) + 1
		if sample_index % 3 == 0:
			member["held_item_id"] = "c3fe_audit_item"
			member["held_item_consumed"] = sample_index % 6 == 0

		var evidence := _operational_evidence(member)
		var expected := _component_vector(evidence)
		var result := evaluator.evaluate_current_components([member])
		var production := _first_production_member(result)
		if sampled_species_examples.size() < 12:
			sampled_species_examples.append(String(member.get("species_id", "")))
		if not _components_match(production, expected):
			degraded_component_parity_mismatches += 1
		if not _route_evidence_matches(production, evidence):
			degraded_route_evidence_mismatches += 1

		var attrition := production.get("attrition", {}) as Dictionary
		var expected_attrition_bp := clampi(_next_active_tick_loss_bp(evidence), 0, 10000)
		if int(attrition.get("next_active_tick_loss_max_hp_bp", -1)) != expected_attrition_bp:
			attrition_bp_mismatches += 1
		var expected_raw_damage := _expected_raw_tick_damage(member, status_id)
		if int(attrition.get("next_active_tick_raw_damage_hp", -1)) != expected_raw_damage:
			attrition_raw_damage_mismatches += 1
		var expected_applies_now := expected_raw_damage > 0 and bool(member.get("is_active", false)) and int(member.get("current_hp", 0)) > 0
		if bool(attrition.get("next_active_tick_applies_now", false)) != expected_applies_now:
			active_bench_application_mismatches += 1
		var expected_applied_damage := mini(int(member.get("current_hp", 0)), expected_raw_damage) if expected_applies_now else 0
		if int(attrition.get("next_active_tick_applied_damage_hp", -1)) != expected_applied_damage:
			attrition_applied_damage_mismatches += 1
		if expected_raw_damage > 0:
			if bool(member.get("is_active", false)):
				active_attrition_cases += 1
			else:
				bench_attrition_formula_cases += 1

		var item_available := member.duplicate(true)
		item_available["held_item_id"] = "c3fe_audit_item"
		item_available["held_item_consumed"] = false
		var item_consumed := item_available.duplicate(true)
		item_consumed["held_item_consumed"] = true
		var item_available_component := _first_production_member(evaluator.evaluate_current_components([item_available]))
		var item_consumed_component := _first_production_member(evaluator.evaluate_current_components([item_consumed]))
		if (
			_numeric_signature(item_available_component) != _numeric_signature(item_consumed_component)
			or item_available_component.get("attrition", {}) != item_consumed_component.get("attrition", {})
		):
			held_item_component_mismatches += 1

		if _contains_forbidden_key(result):
			blocked_output_cases += 1

		var signature := JSON.stringify([
			int(production.get("hp_state_bp", -1)),
			int(production.get("route_retention_bp", -1)),
			int(production.get("immediate_status_action_bp", -1)),
		])
		component_signature_set[signature] = true
		for component_id in component_sums.keys():
			var value := int(production.get(component_id, -1))
			component_sums[component_id] = int(component_sums[component_id]) + value
			component_mins[component_id] = mini(int(component_mins[component_id]), value)
			component_maxs[component_id] = maxi(int(component_maxs[component_id]), value)
		degraded_sample_members += 1

	_catalog = fixture_catalog
	var component_means: Dictionary = {}
	for component_id in component_sums.keys():
		component_means[component_id] = int(component_sums[component_id]) / maxi(1, degraded_sample_members)

	return {
		"audit_id": AUDIT_ID,
		"production_model_id": TrainerRosterOperationalReadinessEvaluator.MODEL_ID,
		"eligible_species": members.size(),
		"healthy_member_count": healthy_member_count,
		"healthy_component_parity_mismatches": healthy_component_parity_mismatches,
		"healthy_route_evidence_mismatches": healthy_route_evidence_mismatches,
		"healthy_non_ceiling_component_cases": healthy_non_ceiling_component_cases,
		"healthy_runtime_move_entries": healthy_runtime_move_entries,
		"sample_stride": SAMPLE_STRIDE,
		"degraded_sample_members": degraded_sample_members,
		"sampled_species_examples": sampled_species_examples,
		"degraded_component_parity_mismatches": degraded_component_parity_mismatches,
		"degraded_route_evidence_mismatches": degraded_route_evidence_mismatches,
		"attrition_bp_mismatches": attrition_bp_mismatches,
		"attrition_raw_damage_mismatches": attrition_raw_damage_mismatches,
		"attrition_applied_damage_mismatches": attrition_applied_damage_mismatches,
		"active_bench_application_mismatches": active_bench_application_mismatches,
		"held_item_component_mismatches": held_item_component_mismatches,
		"active_attrition_cases": active_attrition_cases,
		"bench_attrition_formula_cases": bench_attrition_formula_cases,
		"status_case_counts": status_case_counts,
		"distinct_immediate_component_vectors": component_signature_set.size(),
		"component_means_bp": component_means,
		"component_mins_bp": component_mins,
		"component_maxs_bp": component_maxs,
		"blocked_output_cases": blocked_output_cases,
		"selected_operational_readiness_formula": null,
		"consumer_integration_authorized": false,
	}


func _first_production_member(result: Dictionary) -> Dictionary:
	var components := result.get("member_components", []) as Array
	if components.is_empty() or not (components[0] is Dictionary):
		return {}
	return components[0] as Dictionary


func _components_match(production: Dictionary, expected: Dictionary) -> bool:
	return (
		int(production.get("hp_state_bp", -1)) == int(expected.get("hp_state_bp", -2))
		and int(production.get("route_retention_bp", -1)) == int(expected.get("route_retention_bp", -2))
		and int(production.get("immediate_status_action_bp", -1)) == int(expected.get("immediate_status_action_bp", -2))
	)


func _route_evidence_matches(production: Dictionary, evidence: Dictionary) -> bool:
	var route := (production.get("breakdown", {}) as Dictionary).get("route_retention", {}) as Dictionary
	return (
		route.get("runtime_move_pp", []) == evidence.get("runtime_move_pp", [])
		and route.get("available_runtime_move_ids", []) == evidence.get("available_runtime_move_ids", [])
		and route.get("depleted_runtime_move_ids", []) == evidence.get("depleted_runtime_move_ids", [])
		and route.get("excluded_move_ids", []) == evidence.get("excluded_move_ids", [])
		and route.get("unknown_move_ids", []) == evidence.get("unknown_move_ids", [])
		and route.get("all_pp_sensitive_role_max_bp", {}) == evidence.get("all_pp_sensitive_role_max_bp", {})
		and route.get("available_pp_sensitive_role_max_bp", {}) == evidence.get("available_pp_sensitive_role_max_bp", {})
	)


func _apply_real_status_cycle(member: Dictionary, sample_index: int) -> StringName:
	match sample_index % 7:
		0:
			_set_status(member, &"", 0, 0)
			return &"none"
		1:
			_set_status(member, StatusSystem.BURN, 0, 0)
			return StatusSystem.BURN
		2:
			_set_status(member, StatusSystem.PARALYSIS, 0, 0)
			return StatusSystem.PARALYSIS
		3:
			_set_status(member, StatusSystem.POISON, 0, 0)
			return StatusSystem.POISON
		4:
			_set_status(member, StatusSystem.BADLY_POISONED, 0, 2 + sample_index % 3)
			return StatusSystem.BADLY_POISONED
		5:
			_set_status(member, StatusSystem.SLEEP, 2, 0)
			return StatusSystem.SLEEP
		_:
			_set_status(member, StatusSystem.FREEZE, 0, 0)
			return StatusSystem.FREEZE


func _expected_raw_tick_damage(member: Dictionary, status_id: StringName) -> int:
	var stats := member.get("stats", {}) as Dictionary
	var max_hp := maxi(0, int(stats.get("max_hp", 0)))
	if max_hp <= 0:
		return 0
	match status_id:
		StatusSystem.BURN:
			return maxi(1, max_hp / maxi(1, _operational_ruleset.burn_max_hp_divisor))
		StatusSystem.POISON:
			return maxi(1, max_hp / maxi(1, _operational_ruleset.poison_max_hp_divisor))
		StatusSystem.BADLY_POISONED:
			var state := member.get("status_state", {}) as Dictionary
			var next_counter := maxi(1, int(state.get("toxic_counter", 0)) + 1)
			return maxi(1, max_hp * next_counter / maxi(1, _operational_ruleset.badly_poisoned_max_hp_divisor))
	return 0


func _all_status_families_present(counts: Dictionary) -> bool:
	for status_id in [
		"none",
		String(StatusSystem.BURN),
		String(StatusSystem.PARALYSIS),
		String(StatusSystem.POISON),
		String(StatusSystem.BADLY_POISONED),
		String(StatusSystem.SLEEP),
		String(StatusSystem.FREEZE),
	]:
		if int(counts.get(status_id, 0)) <= 0:
			return false
	return true


func _component_ranges_are_bounded(report: Dictionary) -> bool:
	var mins := report.get("component_mins_bp", {}) as Dictionary
	var maxs := report.get("component_maxs_bp", {}) as Dictionary
	for component_id in ["hp_state_bp", "route_retention_bp", "immediate_status_action_bp"]:
		var min_value := int(mins.get(component_id, -1))
		var max_value := int(maxs.get(component_id, 10001))
		if min_value < 0 or max_value > 10000 or min_value > max_value:
			return false
	return true
