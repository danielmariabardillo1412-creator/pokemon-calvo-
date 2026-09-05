class_name TrainerRosterControlEvidenceTestSuite
extends RefCounted

const DOUBLE := &"control_evidence_double"
const INACCURATE := &"control_evidence_inaccurate"
const DAMAGING := &"control_evidence_damaging"
const MULTI := &"control_evidence_multi"
const EXCLUDED := &"control_evidence_excluded"

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var catalog: DefinitionCatalog = TrainerRosterRoleInferenceFixtures.build_catalog()
	_add_test_moves(catalog)
	var inference := TrainerRosterRoleInference.new()
	var stats := StatBlock.new(200, 100, 100, 100, 100, 100)

	var double_evidence: Dictionary = inference.extract_intrinsic_evidence(_view(catalog, DOUBLE, stats), catalog)
	var double_cap: Dictionary = double_evidence.get("capability_evidence", {}) as Dictionary
	_check.call("control_evidence_preserves_legacy_signal", int(double_cap.get("control_signal_bp", 0)) == 900)
	_check.call("control_evidence_runtime_chance_not_double_counted", int(double_cap.get("control_best_runtime_effect_bp", 0)) == 3000)
	_check.call("control_evidence_runtime_reliability_not_double_counted", int(double_cap.get("control_reliability_bp", 0)) == 3000)
	var double_scores: Dictionary = (inference.infer_role_scores(_view(catalog, DOUBLE, stats), catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("control_evidence_support_uses_runtime_reliability", int(double_scores.get("support", 0)) == 3000)

	var inaccurate_cap: Dictionary = (inference.extract_intrinsic_evidence(_view(catalog, INACCURATE, stats), catalog).get("capability_evidence", {}) as Dictionary)
	_check.call("control_evidence_accuracy_reduces_reliability", int(inaccurate_cap.get("control_reliability_bp", 0)) == 5000)
	_check.call("control_evidence_keeps_on_hit_signal_separate", int(inaccurate_cap.get("control_best_runtime_effect_bp", 0)) == 10000)
	_check.call("control_evidence_tracks_stat_drop_magnitude", int(inaccurate_cap.get("control_strongest_stat_drop_stages", 0)) == 2)

	var combo := TrainerRosterRoleInferenceFixtures.member_view(catalog, &"control_evidence_combo", [INACCURATE, DAMAGING, MULTI], stats)
	var combo_evidence: Dictionary = inference.extract_intrinsic_evidence(combo, catalog)
	var combo_cap: Dictionary = combo_evidence.get("capability_evidence", {}) as Dictionary
	var combo_breakdown: Array = combo_evidence.get("control_breakdown", []) as Array
	_check.call("control_evidence_tracks_best_and_second_reliability", int(combo_cap.get("control_reliability_bp", 0)) == 10000 and int(combo_cap.get("control_secondary_reliability_bp", 0)) == 9500)
	_check.call("control_evidence_tracks_move_breadth", int(combo_cap.get("control_move_count", 0)) == 3)
	_check.call("control_evidence_tracks_effect_breadth", int(combo_cap.get("control_effect_key_count", 0)) == 4)
	_check.call("control_evidence_tracks_dedicated_and_damaging_sources", int(combo_cap.get("control_dedicated_move_count", 0)) == 2 and int(combo_cap.get("control_damaging_move_count", 0)) == 1)
	_check.call("control_evidence_breakdown_has_control_moves", combo_breakdown.size() == 3)

	var multi_evidence: Dictionary = inference.extract_intrinsic_evidence(_view(catalog, MULTI, stats), catalog)
	var multi_cap: Dictionary = multi_evidence.get("capability_evidence", {}) as Dictionary
	var multi_breakdown: Array = multi_evidence.get("control_breakdown", []) as Array
	var multi_report: Dictionary = multi_breakdown[0] as Dictionary if not multi_breakdown.is_empty() else {}
	_check.call("control_evidence_one_move_can_cover_two_effect_keys", int(multi_cap.get("control_move_count", 0)) == 1 and int(multi_cap.get("control_effect_key_count", 0)) == 2)
	_check.call("control_evidence_breakdown_preserves_route_count", int(multi_report.get("route_count", 0)) == 2)

	var excluded_evidence: Dictionary = inference.extract_intrinsic_evidence(_view(catalog, EXCLUDED, stats), catalog)
	var excluded_cap: Dictionary = excluded_evidence.get("capability_evidence", {}) as Dictionary
	_check.call("control_evidence_excluded_move_fails_closed", int(excluded_cap.get("control_move_count", -1)) == 0 and (excluded_evidence.get("control_breakdown", []) as Array).is_empty())
	_check.call("control_evidence_model_id_recorded", String(combo_evidence.get("control_evidence_model_id", "")) == TrainerRosterRoleInference.CONTROL_EVIDENCE_MODEL_ID)
	_check.call("control_evidence_breakdown_json_serializable", not JSON.stringify(combo_breakdown).is_empty())


func _view(catalog: DefinitionCatalog, move_id: StringName, stats: StatBlock) -> Dictionary:
	return TrainerRosterRoleInferenceFixtures.member_view(catalog, &"control_evidence_fixture", [move_id], stats)


func _add_test_moves(catalog: DefinitionCatalog) -> void:
	var wrapper := BattleEffectSpec.new(BattleEffectSpec.CHANCE, BattleEffectSpec.OPPONENT, 0, 0, 3000)
	wrapper.children.append(_debuff(StatStages.DEFENSE, -1, 3000))
	catalog.add_move(_move(DOUBLE, 0, 100, [wrapper], TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED))
	catalog.add_move(_move(INACCURATE, 0, 50, [_debuff(StatStages.DEFENSE, -2)], TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED))
	catalog.add_move(_move(DAMAGING, 80, 95, [_debuff(StatStages.SPEED, -1)], TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED))
	catalog.add_move(_move(MULTI, 0, 100, [_debuff(StatStages.ATTACK, -1), _debuff(StatStages.SPECIAL_ATTACK, -1)], TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED))
	catalog.add_move(_move(EXCLUDED, 0, 100, [_debuff(StatStages.ATTACK, -6)], TrainerRosterRoleInferenceFixtures.CLASS_DATA_ONLY))


func _debuff(stat_key: StringName, value: int, chance_bp: int = 10000) -> BattleEffectSpec:
	return BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.OPPONENT, value, 0, chance_bp, &"", stat_key)


func _move(id: StringName, power: int, accuracy: int, effects: Array, classification: String) -> MoveDefinition:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.type_id = &"normal"
	move.damage_class = "physical" if power > 0 else "status"
	move.power = power
	move.accuracy = accuracy
	move.pp = 20
	move.classification = classification
	for effect in effects:
		if effect is BattleEffectSpec:
			move.effect_specs.append(effect as BattleEffectSpec)
	return move
