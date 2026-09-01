class_name TrainerRosterRoleInferenceTestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var catalog: DefinitionCatalog = TrainerRosterRoleInferenceFixtures.build_catalog()
	var inference := TrainerRosterRoleInference.new()
	_test_fail_closed_move_classification(inference, catalog)
	_test_damage_and_bulk_evidence(inference, catalog)
	_test_structured_utility_evidence(inference, catalog)
	_test_structural_state_independence(inference, catalog)
	_test_determinism_and_boundary(inference, catalog)


func _test_fail_closed_move_classification(
	inference: TrainerRosterRoleInference,
	catalog: DefinitionCatalog,
) -> void:
	var stats := StatBlock.new(200, 200, 100, 100, 80, 100)
	var view: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_fail_closed",
		[
			TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL,
			TrainerRosterRoleInferenceFixtures.MOVE_PARTIAL,
			TrainerRosterRoleInferenceFixtures.MOVE_DATA_ONLY,
			TrainerRosterRoleInferenceFixtures.MOVE_UNSUPPORTED,
		],
		stats,
	)
	var evidence: Dictionary = inference.extract_intrinsic_evidence(view, catalog)
	var move_features: Dictionary = evidence.get("move_features", {}) as Dictionary
	var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
	_check.call("role_inference_runtime_gate_counts_only_supported", int(move_features.get("runtime_supported_count", 0)) == 1)
	_check.call("role_inference_runtime_gate_tracks_three_excluded", int(move_features.get("excluded_count", 0)) == 3)
	_check.call("role_inference_runtime_gate_ignores_excluded_power", int(move_features.get("physical_power_sum", 0)) == 100)
	_check.call("role_inference_runtime_gate_ignores_excluded_damage_signal", int(capabilities.get("physical_damage_signal", 0)) == 20000)

	var unknown_view: Dictionary = view.duplicate(true)
	var unknown_move_ids: Array = unknown_view.get("move_ids", []) as Array
	unknown_move_ids.append("role_fixture_missing_move")
	var unknown_evidence: Dictionary = inference.extract_intrinsic_evidence(unknown_view, catalog)
	var unknown_features: Dictionary = unknown_evidence.get("move_features", {}) as Dictionary
	_check.call("role_inference_unknown_move_fails_closed", int(unknown_features.get("unknown_count", 0)) == 1)
	_check.call("role_inference_unknown_move_does_not_change_power", int(unknown_features.get("physical_power_sum", 0)) == 100)

	var excluded_control: MoveDefinition = catalog.move(TrainerRosterRoleInferenceFixtures.MOVE_DATA_ONLY)
	if excluded_control != null:
		excluded_control.effect_specs.append(BattleEffectSpec.new(
			BattleEffectSpec.MODIFY_STAT_STAGE,
			BattleEffectSpec.OPPONENT,
			-6,
		))
	var excluded_only: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_excluded_effect",
		[TrainerRosterRoleInferenceFixtures.MOVE_DATA_ONLY],
		stats,
	)
	var excluded_evidence: Dictionary = inference.extract_intrinsic_evidence(excluded_only, catalog)
	var excluded_capabilities: Dictionary = excluded_evidence.get("capability_evidence", {}) as Dictionary
	_check.call("role_inference_excluded_effect_does_not_add_control", int(excluded_capabilities.get("control_signal_bp", -1)) == 0)


func _test_damage_and_bulk_evidence(
	inference: TrainerRosterRoleInference,
	catalog: DefinitionCatalog,
) -> void:
	var physical_low: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_physical_low",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		StatBlock.new(200, 100, 90, 80, 70, 60),
	)
	var physical_high: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_physical_high",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		StatBlock.new(200, 180, 90, 80, 70, 60),
	)
	var low_cap: Dictionary = (inference.extract_intrinsic_evidence(physical_low, catalog).get("capability_evidence", {}) as Dictionary)
	var high_cap: Dictionary = (inference.extract_intrinsic_evidence(physical_high, catalog).get("capability_evidence", {}) as Dictionary)
	_check.call("role_inference_physical_damage_monotonic_with_attack", int(high_cap.get("physical_damage_signal", 0)) > int(low_cap.get("physical_damage_signal", 0)))
	_check.call("role_inference_physical_route_has_no_special_signal", int(high_cap.get("special_damage_signal", -1)) == 0)

	var special: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_special",
		[TrainerRosterRoleInferenceFixtures.MOVE_SPECIAL],
		StatBlock.new(200, 70, 90, 80, 180, 60),
	)
	var special_cap: Dictionary = (inference.extract_intrinsic_evidence(special, catalog).get("capability_evidence", {}) as Dictionary)
	_check.call("role_inference_special_route_has_special_signal", int(special_cap.get("special_damage_signal", 0)) == 18000)
	_check.call("role_inference_special_route_has_no_physical_signal", int(special_cap.get("physical_damage_signal", -1)) == 0)

	var no_physical_route: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_no_physical_route",
		[TrainerRosterRoleInferenceFixtures.MOVE_SPECIAL],
		StatBlock.new(200, 250, 100, 100, 50, 100),
	)
	var no_route_cap: Dictionary = (inference.extract_intrinsic_evidence(no_physical_route, catalog).get("capability_evidence", {}) as Dictionary)
	_check.call("role_inference_high_attack_without_physical_route_is_zero", int(no_route_cap.get("physical_damage_signal", -1)) == 0)

	var bulky: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_bulk",
		[TrainerRosterRoleInferenceFixtures.MOVE_CONTROL],
		StatBlock.new(240, 80, 150, 70, 80, 130),
	)
	var bulky_cap: Dictionary = (inference.extract_intrinsic_evidence(bulky, catalog).get("capability_evidence", {}) as Dictionary)
	_check.call("role_inference_physical_bulk_uses_max_hp_and_defense", int(bulky_cap.get("physical_bulk_signal", 0)) == 36000)
	_check.call("role_inference_special_bulk_uses_max_hp_and_special_defense", int(bulky_cap.get("special_bulk_signal", 0)) == 31200)
	_check.call("role_inference_speed_is_structural_stat", int(bulky_cap.get("speed_stat", 0)) == 70)

	var priority: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_priority",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL, TrainerRosterRoleInferenceFixtures.MOVE_PRIORITY],
		StatBlock.new(200, 120, 100, 90, 80, 100),
	)
	var priority_cap: Dictionary = (inference.extract_intrinsic_evidence(priority, catalog).get("capability_evidence", {}) as Dictionary)
	_check.call("role_inference_priority_tracks_max_runtime_priority", int(priority_cap.get("priority", 0)) == 1)


func _test_structured_utility_evidence(
	inference: TrainerRosterRoleInference,
	catalog: DefinitionCatalog,
) -> void:
	var stats := StatBlock.new(200, 100, 100, 100, 100, 100)
	var control: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_control",
		[TrainerRosterRoleInferenceFixtures.MOVE_CONTROL],
		stats,
	)
	var setup: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_setup",
		[TrainerRosterRoleInferenceFixtures.MOVE_SETUP],
		stats,
	)
	var sustain: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_sustain",
		[TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN],
		stats,
	)
	var control_cap: Dictionary = (inference.extract_intrinsic_evidence(control, catalog).get("capability_evidence", {}) as Dictionary)
	var setup_cap: Dictionary = (inference.extract_intrinsic_evidence(setup, catalog).get("capability_evidence", {}) as Dictionary)
	var sustain_cap: Dictionary = (inference.extract_intrinsic_evidence(sustain, catalog).get("capability_evidence", {}) as Dictionary)
	_check.call("role_inference_control_reads_structured_debuff", int(control_cap.get("control_signal_bp", 0)) == 10000)
	_check.call("role_inference_control_does_not_become_setup", int(control_cap.get("setup_signal_bp", -1)) == 0)
	_check.call("role_inference_setup_reads_structured_self_buff", int(setup_cap.get("setup_signal_bp", 0)) == 10000)
	_check.call("role_inference_setup_does_not_become_control", int(setup_cap.get("control_signal_bp", -1)) == 0)
	_check.call("role_inference_sustain_reads_structured_heal_ratio", int(sustain_cap.get("sustain_signal_bp", 0)) == 5000)


func _test_structural_state_independence(
	inference: TrainerRosterRoleInference,
	catalog: DefinitionCatalog,
) -> void:
	var stats := StatBlock.new(220, 150, 140, 90, 70, 130)
	var full: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_structural",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
	)
	var low_hp: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_structural",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
		22,
	)
	var zero_pp: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_structural",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
		-1,
		TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL,
	)
	var full_evidence: Dictionary = inference.extract_intrinsic_evidence(full, catalog)
	_check.call("role_inference_low_hp_does_not_change_intrinsic_evidence", full_evidence == inference.extract_intrinsic_evidence(low_hp, catalog))
	_check.call("role_inference_zero_pp_does_not_change_intrinsic_evidence", full_evidence == inference.extract_intrinsic_evidence(zero_pp, catalog))

	var decorated: Dictionary = full.duplicate(true)
	decorated["role_id"] = "support"
	decorated["trainer_profile"] = "aggressive"
	decorated["hidden_rival_species"] = ["secret_fixture"]
	_check.call("role_inference_ignores_authored_role_profile_and_rival_noise", full_evidence == inference.extract_intrinsic_evidence(decorated, catalog))


func _test_determinism_and_boundary(
	inference: TrainerRosterRoleInference,
	catalog: DefinitionCatalog,
) -> void:
	var view: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_inference_deterministic",
		[
			TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL,
			TrainerRosterRoleInferenceFixtures.MOVE_CONTROL,
			TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN,
		],
		StatBlock.new(210, 130, 115, 105, 90, 120),
	)
	var first: Dictionary = inference.extract_intrinsic_evidence(view, catalog)
	var second: Dictionary = inference.extract_intrinsic_evidence(view, catalog)
	_check.call("role_inference_same_input_same_evidence", first == second)
	var parsed: Variant = JSON.parse_string(JSON.stringify(first))
	_check.call("role_inference_evidence_json_serializable", parsed is Dictionary)
	_check.call("role_inference_model_id_recorded", String(first.get("model_id", "")) == TrainerRosterRoleInference.MODEL_ID)
