class_name TrainerRosterRoleInferenceFixtureTestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var catalog: DefinitionCatalog = TrainerRosterRoleInferenceFixtures.build_catalog()
	_test_classification_contract(catalog)
	_test_structured_effect_contract(catalog)
	_test_sanitized_member_views(catalog)
	_test_hp_and_pp_variants_preserve_structural_identity(catalog)
	_test_fixture_independence(catalog)


func _test_classification_contract(catalog: DefinitionCatalog) -> void:
	var runtime_ids: Array[StringName] = [
		TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL,
		TrainerRosterRoleInferenceFixtures.MOVE_SPECIAL,
		TrainerRosterRoleInferenceFixtures.MOVE_PRIORITY,
		TrainerRosterRoleInferenceFixtures.MOVE_CONTROL,
		TrainerRosterRoleInferenceFixtures.MOVE_SETUP,
		TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN,
	]
	var all_runtime_supported := true
	for move_id in runtime_ids:
		var move: MoveDefinition = catalog.move(move_id)
		all_runtime_supported = (
			all_runtime_supported
			and move != null
			and move.classification == TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED
		)
	_check.call("role_fixture_runtime_moves_explicitly_supported", all_runtime_supported)

	var partial: MoveDefinition = catalog.move(TrainerRosterRoleInferenceFixtures.MOVE_PARTIAL)
	var data_only: MoveDefinition = catalog.move(TrainerRosterRoleInferenceFixtures.MOVE_DATA_ONLY)
	var unsupported: MoveDefinition = catalog.move(TrainerRosterRoleInferenceFixtures.MOVE_UNSUPPORTED)
	_check.call(
		"role_fixture_partial_explicit",
		partial != null and partial.classification == TrainerRosterRoleInferenceFixtures.CLASS_PARTIAL_RUNTIME,
	)
	_check.call(
		"role_fixture_data_only_explicit",
		data_only != null and data_only.classification == TrainerRosterRoleInferenceFixtures.CLASS_DATA_ONLY,
	)
	_check.call(
		"role_fixture_unsupported_explicit",
		unsupported != null and unsupported.classification == TrainerRosterRoleInferenceFixtures.CLASS_UNSUPPORTED,
	)


func _test_structured_effect_contract(catalog: DefinitionCatalog) -> void:
	var control: MoveDefinition = catalog.move(TrainerRosterRoleInferenceFixtures.MOVE_CONTROL)
	var setup: MoveDefinition = catalog.move(TrainerRosterRoleInferenceFixtures.MOVE_SETUP)
	var sustain: MoveDefinition = catalog.move(TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN)

	var control_ok := false
	if control != null and control.effect_specs.size() == 1:
		var control_spec := control.effect_specs[0] as BattleEffectSpec
		control_ok = (
			control_spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE
			and control_spec.target == BattleEffectSpec.OPPONENT
			and control_spec.value < 0
		)
	_check.call("role_fixture_control_is_structured_opponent_debuff", control_ok)

	var setup_ok := false
	if setup != null and setup.effect_specs.size() == 1:
		var setup_spec := setup.effect_specs[0] as BattleEffectSpec
		setup_ok = (
			setup_spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE
			and setup_spec.target == BattleEffectSpec.SELF
			and setup_spec.value > 0
		)
	_check.call("role_fixture_setup_is_structured_self_buff", setup_ok)

	var sustain_ok := false
	if sustain != null and sustain.effect_specs.size() == 1:
		var sustain_spec := sustain.effect_specs[0] as BattleEffectSpec
		sustain_ok = (
			sustain_spec.kind == BattleEffectSpec.HEAL
			and sustain_spec.target == BattleEffectSpec.SELF
			and sustain_spec.ratio_basis_points == 5000
		)
	_check.call("role_fixture_sustain_is_structured_self_heal", sustain_ok)


func _test_sanitized_member_views(catalog: DefinitionCatalog) -> void:
	var physical_stats := StatBlock.new(200, 180, 100, 100, 80, 100)
	var special_stats := StatBlock.new(200, 80, 100, 100, 180, 100)
	var physical: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_physical_member",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		physical_stats,
	)
	var special: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_special_member",
		[TrainerRosterRoleInferenceFixtures.MOVE_SPECIAL],
		special_stats,
	)
	_check.call("role_fixture_physical_view_uses_real_stats", int((physical.get("stats", {}) as Dictionary).get("attack", 0)) == 180)
	_check.call("role_fixture_special_view_uses_real_stats", int((special.get("stats", {}) as Dictionary).get("special_attack", 0)) == 180)
	_check.call("role_fixture_views_have_distinct_damage_routes", physical.get("move_ids", []) != special.get("move_ids", []))

	var parsed: Variant = JSON.parse_string(JSON.stringify(physical))
	_check.call("role_fixture_member_view_json_serializable", parsed is Dictionary)
	_check.call("role_fixture_member_view_is_dictionary_boundary", typeof(physical) == TYPE_DICTIONARY)


func _test_hp_and_pp_variants_preserve_structural_identity(catalog: DefinitionCatalog) -> void:
	var stats := StatBlock.new(220, 150, 140, 90, 70, 130)
	var full: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_structural_member",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
	)
	var low_hp: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_structural_member",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
		22,
	)
	var zero_pp: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_structural_member",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
		-1,
		TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL,
	)

	_check.call("role_fixture_low_hp_keeps_stats", full.get("stats", {}) == low_hp.get("stats", {}))
	_check.call("role_fixture_low_hp_keeps_moves", full.get("move_ids", []) == low_hp.get("move_ids", []))
	_check.call("role_fixture_low_hp_changes_only_readiness_signal", int(full.get("current_hp", 0)) > int(low_hp.get("current_hp", 0)))

	var full_moveset: Array = full.get("moveset", []) as Array
	var zero_moveset: Array = zero_pp.get("moveset", []) as Array
	var pp_variant_ok: bool = (
		full.get("move_ids", []) == zero_pp.get("move_ids", [])
		and full_moveset.size() == 1
		and zero_moveset.size() == 1
		and int((full_moveset[0] as Dictionary).get("current_pp", 0)) > 0
		and int((zero_moveset[0] as Dictionary).get("current_pp", -1)) == 0
	)
	_check.call("role_fixture_zero_pp_keeps_structural_move_identity", pp_variant_ok)

	var excluded: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_excluded_moves",
		[
			TrainerRosterRoleInferenceFixtures.MOVE_PARTIAL,
			TrainerRosterRoleInferenceFixtures.MOVE_DATA_ONLY,
			TrainerRosterRoleInferenceFixtures.MOVE_UNSUPPORTED,
		],
		stats,
	)
	_check.call("role_fixture_excluded_classifications_can_reach_fail_closed_test", (excluded.get("move_ids", []) as Array).size() == 3)


func _test_fixture_independence(catalog: DefinitionCatalog) -> void:
	var stats := StatBlock.new(200, 120, 110, 100, 90, 80)
	var a: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_independent",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
	)
	var b: Dictionary = TrainerRosterRoleInferenceFixtures.member_view(
		catalog,
		&"role_fixture_independent",
		[TrainerRosterRoleInferenceFixtures.MOVE_PHYSICAL],
		stats,
	)
	var a_stats: Dictionary = a.get("stats", {}) as Dictionary
	a_stats["attack"] = 1
	var a_moveset: Array = a.get("moveset", []) as Array
	if not a_moveset.is_empty():
		(a_moveset[0] as Dictionary)["current_pp"] = 0
	var b_moveset: Array = b.get("moveset", []) as Array
	var independent: bool = (
		int((b.get("stats", {}) as Dictionary).get("attack", 0)) == 120
		and b_moveset.size() == 1
		and int((b_moveset[0] as Dictionary).get("current_pp", 0)) > 0
	)
	_check.call("role_fixture_views_are_deeply_independent", independent)
