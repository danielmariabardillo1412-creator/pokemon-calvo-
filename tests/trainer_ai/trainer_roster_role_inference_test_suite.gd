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
	_test_role_affinity_scores(inference, catalog)
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


func _test_role_affinity_scores(
	inference: TrainerRosterRoleInference,
	catalog: DefinitionCatalog,
) -> void:
	var physical: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_physical",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		StatBlock.new(200, 180, 90, 90, 70, 80),
	)
	var physical_result: Dictionary = inference.infer_role_scores(physical, catalog)
	var physical_scores: Dictionary = physical_result.get("role_scores_bp", {}) as Dictionary
	_check.call("role_score_physical_clear_route_is_max", int(physical_scores.get("physical_attacker", 0)) == 10000)
	_check.call("role_score_physical_clear_route_has_no_special", int(physical_scores.get("special_attacker", -1)) == 0)
	_check.call("role_score_fast_requires_speed_focus", int(physical_scores.get("fast_attacker", 0)) == 5000)

	var special: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_special",
		[TrainerRosterRoleInferenceFixtures.MOVE_SPECIAL],
		StatBlock.new(200, 70, 80, 90, 180, 90),
	)
	var special_scores: Dictionary = (inference.infer_role_scores(special, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("role_score_special_clear_route_is_max", int(special_scores.get("special_attacker", 0)) == 10000)
	_check.call("role_score_special_clear_route_has_no_physical", int(special_scores.get("physical_attacker", -1)) == 0)

	var fast: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_fast",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		StatBlock.new(200, 150, 90, 180, 80, 90),
	)
	var fast_scores: Dictionary = (inference.infer_role_scores(fast, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("role_score_fast_attacker_matches_available_offense", int(fast_scores.get("fast_attacker", 0)) == int(fast_scores.get("physical_attacker", -1)))
	_check.call("role_score_fast_attacker_exceeds_bulk_axes", int(fast_scores.get("fast_attacker", 0)) > int(fast_scores.get("bulky_physical", 0)))

	var bulky: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_bulky",
		[TrainerRosterRoleInferenceFixtures.MOVE_CONTROL],
		StatBlock.new(240, 80, 180, 70, 80, 120),
	)
	var bulky_scores: Dictionary = (inference.infer_role_scores(bulky, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("role_score_bulky_physical_tracks_defense_focus", int(bulky_scores.get("bulky_physical", 0)) == 10000)
	_check.call("role_score_non_attacker_has_no_fast_role", int(bulky_scores.get("fast_attacker", -1)) == 0)

	var bulky_special: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_bulky_special",
		[TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN],
		StatBlock.new(240, 80, 120, 70, 80, 180),
	)
	var bulky_special_scores: Dictionary = (inference.infer_role_scores(bulky_special, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("role_score_bulky_special_tracks_special_defense_focus", int(bulky_special_scores.get("bulky_special", 0)) == 10000)

	var support: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_support",
		[TrainerRosterRoleInferenceFixtures.MOVE_CONTROL, TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN],
		StatBlock.new(220, 90, 130, 80, 90, 130),
	)
	var support_scores: Dictionary = (inference.infer_role_scores(support, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("role_score_support_uses_structured_control_or_sustain", int(support_scores.get("support", 0)) == 10000)

	var setup_only: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_setup_only",
		[TrainerRosterRoleInferenceFixtures.MOVE_SETUP],
		StatBlock.new(220, 130, 100, 100, 90, 100),
	)
	var setup_result: Dictionary = inference.infer_role_scores(setup_only, catalog)
	var setup_scores: Dictionary = setup_result.get("role_scores_bp", {}) as Dictionary
	var setup_normalization: Dictionary = setup_result.get("normalization", {}) as Dictionary
	_check.call("role_score_setup_is_preserved_without_becoming_support", int(setup_normalization.get("setup_signal_bp", 0)) == 10000 and int(setup_scores.get("support", -1)) == 0)

	var hybrid: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_hybrid",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL, TrainerRosterRoleInferenceFixtures.MOVE_SPECIAL],
		StatBlock.new(210, 160, 90, 100, 160, 90),
	)
	var hybrid_scores: Dictionary = (inference.infer_role_scores(hybrid, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("role_score_hybrid_can_hold_physical_and_special_roles", int(hybrid_scores.get("physical_attacker", 0)) == 10000 and int(hybrid_scores.get("special_attacker", 0)) == 10000)

	var excluded: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_excluded",
		[TrainerRosterRoleInferenceFixtures.MOVE_DATA_ONLY],
		StatBlock.new(200, 220, 80, 100, 70, 80),
	)
	var excluded_scores: Dictionary = (inference.infer_role_scores(excluded, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("role_score_data_only_move_cannot_create_attack_role", int(excluded_scores.get("physical_attacker", -1)) == 0 and int(excluded_scores.get("fast_attacker", -1)) == 0)

	var priority: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_score_priority",
		[TrainerRosterRoleInferenceFixtures.MOVE_PRIORITY],
		StatBlock.new(200, 180, 90, 45, 70, 90),
	)
	var priority_result: Dictionary = inference.infer_role_scores(priority, catalog)
	var priority_scores: Dictionary = priority_result.get("role_scores_bp", {}) as Dictionary
	var priority_normalization: Dictionary = priority_result.get("normalization", {}) as Dictionary
	_check.call("role_score_priority_remains_auditable_without_shortcutting_fast_role", int(priority_normalization.get("priority", 0)) == 1 and int(priority_scores.get("fast_attacker", 0)) == 2500)

	var decorated: Dictionary = hybrid.duplicate(true)
	decorated["role_id"] = "support"
	decorated["trainer_profile"] = "cautious"
	decorated["hidden_rival_species"] = ["secret_a", "secret_b"]
	_check.call("role_score_ignores_authored_role_profile_and_rival_noise", inference.infer_role_scores(hybrid, catalog) == inference.infer_role_scores(decorated, catalog))

	var all_in_range: bool = true
	for raw_score in hybrid_scores.values():
		var score: int = int(raw_score)
		all_in_range = all_in_range and score >= 0 and score <= 10000
	_check.call("role_score_all_axes_are_basis_points", all_in_range)
	var parsed: Variant = JSON.parse_string(JSON.stringify(physical_result))
	_check.call("role_score_output_is_json_serializable", parsed is Dictionary)
	_check.call("role_score_model_id_recorded", String(physical_result.get("model_id", "")) == TrainerRosterRoleInference.ROLE_MODEL_ID)


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
