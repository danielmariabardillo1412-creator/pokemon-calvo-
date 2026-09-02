class_name TrainerRosterStructuralValueProductionTestSuite
extends TrainerRosterStructuralEvidenceTestSuite

var _formula_helper := TrainerRosterStructuralFormulaComparisonTestSuite.new()
var _disjoint_helper := TrainerRosterStructuralOverlapRealDataAuditTestSuite.new()


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_structural_value_production()


func _test_structural_value_production() -> void:
	_enable_runtime_team_moves()
	var evaluator := TrainerRosterStrategicValueEvaluator.new(_catalog)

	var fire := _view(
		&"c3d_fire",
		TC_FIRE_A,
		StatBlock.new(100, 160, 80, 90, 60, 80),
		[TC_FIRE_PHYS],
	)
	var water := _view(
		&"c3d_water",
		TC_WATER,
		StatBlock.new(100, 60, 90, 80, 160, 100),
		[TC_WATER_SPEC],
	)
	var grass := _view(
		&"c3d_grass",
		TC_GRASS,
		StatBlock.new(110, 150, 100, 70, 60, 90),
		[TC_GRASS_PHYS],
	)
	var roster: Array[Dictionary] = [fire, water, grass]
	var roster_snapshot: Array = roster.duplicate(true)
	var result: Dictionary = evaluator.evaluate_structural_value(roster)

	_check.call(
		"roster_structural_value_model_recorded",
		String(result.get("model_id", "")) == TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID,
	)
	_check.call(
		"roster_structural_value_formula_recorded",
		String(result.get("formula_id", "")) == TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_FORMULA_ID,
	)
	_check.call(
		"roster_structural_value_evidence_model_recorded",
		String(result.get("evidence_model_id", "")) == TrainerRosterStrategicValueEvaluator.STRUCTURAL_EVIDENCE_MODEL_ID,
	)
	_check.call("roster_structural_value_counts_survivors", int(result.get("member_count", -1)) == 3)
	_check.call("roster_structural_value_does_not_mutate_input", roster == roster_snapshot)

	var evidence: Dictionary = evaluator.extract_structural_evidence(roster)
	var disjoint_by_id: Dictionary = _disjoint_helper._disjoint_member_metrics(evidence)
	var parity_ok := true
	for raw_member in evidence.get("member_evidence", []):
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		var disjoint: Dictionary = disjoint_by_id.get(instance_id, {}) as Dictionary
		var metrics: Dictionary = _formula_helper._formula_metrics(member, disjoint)
		var expected: int = _formula_helper._candidate_score("capped_units_blend", metrics)
		var production_member: Dictionary = _value_member(result, instance_id)
		parity_ok = parity_ok and int(production_member.get("structural_value_bp", -1)) == expected
		var breakdown: Dictionary = production_member.get("breakdown", {}) as Dictionary
		parity_ok = parity_ok and int(breakdown.get("absolute_capacity_bp", -1)) == int(metrics.get("absolute_capacity_bp", -2))
		parity_ok = parity_ok and int(breakdown.get("context_bp", -1)) == int(metrics.get("capped_units_context_bp", -2))
	_check.call("roster_structural_value_matches_selected_c3c_formula", parity_ok)

	var fire_value: Dictionary = _value_member(result, "c3d_fire")
	var fire_breakdown: Dictionary = fire_value.get("breakdown", {}) as Dictionary
	_check.call(
		"roster_structural_value_breakdown_is_auditable",
		fire_value.has("structural_value_bp")
		and fire_breakdown.has("role_max_bp")
		and fire_breakdown.has("role_second_bp")
		and fire_breakdown.has("absolute_capacity_bp")
		and fire_breakdown.has("context_bp")
		and fire_breakdown.has("absolute_floor_bp")
		and fire_breakdown.has("blended_score_bp")
		and fire_breakdown.has("capped_unique_counts"),
	)

	var low_hp_fire: Dictionary = fire.duplicate(true)
	low_hp_fire["current_hp"] = 1
	var low_hp_result: Dictionary = evaluator.evaluate_structural_value([low_hp_fire, water, grass])
	_check.call(
		"roster_structural_value_one_hp_invariant",
		int(_value_member(low_hp_result, "c3d_fire").get("structural_value_bp", -1))
		== int(fire_value.get("structural_value_bp", -2)),
	)

	var reduced_result: Dictionary = evaluator.evaluate_structural_value([fire, water])
	var reduced_fire: Dictionary = _value_member(reduced_result, "c3d_fire")
	var reduced_breakdown: Dictionary = reduced_fire.get("breakdown", {}) as Dictionary
	_check.call(
		"roster_structural_value_recomputes_context_after_loss",
		int(reduced_breakdown.get("unique_role_count", -1)) >= int(fire_breakdown.get("unique_role_count", -2))
		and int(reduced_fire.get("structural_value_bp", -1)) >= int(fire_value.get("structural_value_bp", -2)),
	)

	var knocked_out_fire: Dictionary = fire.duplicate(true)
	knocked_out_fire["current_hp"] = 0
	var ko_result: Dictionary = evaluator.evaluate_structural_value([knocked_out_fire, water, grass])
	_check.call(
		"roster_structural_value_knocked_out_member_excluded",
		int(ko_result.get("member_count", -1)) == 2
		and _value_member(ko_result, "c3d_fire").is_empty()
		and (ko_result.get("skipped_knocked_out_instance_ids", []) as Array).has("c3d_fire"),
	)

	var ground := _view(
		&"c3d_ground",
		TC_GROUND,
		StatBlock.new(120, 150, 120, 60, 50, 100),
		[TC_GROUND_PHYS],
	)
	var ground_result: Dictionary = evaluator.evaluate_structural_value([fire, water, ground])
	var ground_breakdown: Dictionary = _value_member(ground_result, "c3d_ground").get("breakdown", {}) as Dictionary
	_check.call(
		"roster_structural_value_defense_is_disjoint",
		(ground_breakdown.get("unique_immunity_type_ids", []) as Array).has(String(T_ELECTRIC))
		and not (ground_breakdown.get("unique_exclusive_resistance_type_ids", []) as Array).has(String(T_ELECTRIC)),
	)

	var repeat: Dictionary = evaluator.evaluate_structural_value(roster)
	_check.call("roster_structural_value_is_deterministic", repeat == result)
	var parsed: Variant = JSON.parse_string(JSON.stringify(result))
	_check.call("roster_structural_value_is_json_serializable", parsed is Dictionary)
	_check.call(
		"roster_structural_value_does_not_fake_blocked_layers",
		not result.has("operational_readiness_bp")
		and not result.has("permadeath_loss_cost_bp")
		and not fire_value.has("operational_readiness_bp")
		and not fire_value.has("permadeath_loss_cost_bp"),
	)

	var empty: Dictionary = TrainerRosterStrategicValueEvaluator.new(null).evaluate_structural_value([])
	_check.call(
		"roster_structural_value_null_catalog_fails_closed",
		int(empty.get("member_count", -1)) == 0
		and (empty.get("member_values", []) as Array).is_empty()
		and String(empty.get("model_id", "")) == TrainerRosterStrategicValueEvaluator.STRUCTURAL_VALUE_MODEL_ID,
	)


func _value_member(result: Dictionary, instance_id: String) -> Dictionary:
	for raw_member in result.get("member_values", []):
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		if String(member.get("instance_id", "")) == instance_id:
			return member
	return {}
