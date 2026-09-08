class_name TrainerRosterSupportProductionTestSuite
extends RefCounted

const MOVE_DAMAGING_PERFECT := &"support_prod_damaging_perfect"
const MOVE_DEDICATED_SECOND := &"support_prod_dedicated_second"
const MOVE_DEDICATED_INACCURATE := &"support_prod_dedicated_inaccurate"
const MOVE_EXCLUDED_CONTROL := &"support_prod_excluded_control"

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var inference := TrainerRosterRoleInference.new()
	var stats := StatBlock.new(220, 100, 120, 90, 100, 120)

	_test_single_damaging_cap(inference, stats)
	_test_single_dedicated_cap(inference, stats)
	_test_two_reliable_routes(inference, stats)
	_test_dedicated_plus_sustain(inference, stats)
	_test_accuracy_and_sustain(inference, stats)
	_test_fail_closed_and_boundary(inference, stats)


func _test_single_damaging_cap(
	inference: TrainerRosterRoleInference,
	stats: StatBlock,
) -> void:
	var catalog: DefinitionCatalog = _catalog()
	var view: Dictionary = _view(catalog, &"support_prod_single_damaging", [MOVE_DAMAGING_PERFECT], stats)
	var result: Dictionary = inference.infer_role_scores(view, catalog)
	var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
	var evidence: Dictionary = result.get("intrinsic_evidence", {}) as Dictionary
	var cap: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
	_check.call("support_prod_single_damaging_reliability_is_perfect", int(cap.get("control_reliability_bp", 0)) == 10000)
	_check.call("support_prod_single_damaging_legacy_signal_preserved", int(cap.get("control_signal_bp", 0)) == 10000)
	_check.call("support_prod_single_damaging_does_not_reach_ceiling", int(scores.get("support", 0)) == 9500)


func _test_single_dedicated_cap(
	inference: TrainerRosterRoleInference,
	stats: StatBlock,
) -> void:
	var catalog: DefinitionCatalog = _catalog()
	var view: Dictionary = _view(
		catalog,
		&"support_prod_single_dedicated",
		[TrainerRosterRoleInferenceFixtures.MOVE_CONTROL],
		stats,
	)
	var result: Dictionary = inference.infer_role_scores(view, catalog)
	var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
	var cap: Dictionary = ((result.get("intrinsic_evidence", {}) as Dictionary).get("capability_evidence", {}) as Dictionary)
	_check.call("support_prod_single_dedicated_remains_high", int(scores.get("support", 0)) == 9500)
	_check.call("support_prod_single_dedicated_is_auditable", int(cap.get("control_dedicated_move_count", 0)) == 1 and int(cap.get("control_reliability_bp", 0)) == 10000)


func _test_two_reliable_routes(
	inference: TrainerRosterRoleInference,
	stats: StatBlock,
) -> void:
	var catalog: DefinitionCatalog = _catalog()
	var view: Dictionary = _view(
		catalog,
		&"support_prod_two_routes",
		[
			TrainerRosterRoleInferenceFixtures.MOVE_CONTROL,
			MOVE_DEDICATED_SECOND,
		],
		stats,
	)
	var result: Dictionary = inference.infer_role_scores(view, catalog)
	var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
	var cap: Dictionary = ((result.get("intrinsic_evidence", {}) as Dictionary).get("capability_evidence", {}) as Dictionary)
	_check.call("support_prod_two_routes_track_secondary_reliability", int(cap.get("control_reliability_bp", 0)) == 10000 and int(cap.get("control_secondary_reliability_bp", 0)) == 8000)
	_check.call("support_prod_two_reliable_routes_reach_ceiling", int(scores.get("support", 0)) == 10000)


func _test_dedicated_plus_sustain(
	inference: TrainerRosterRoleInference,
	stats: StatBlock,
) -> void:
	var catalog: DefinitionCatalog = _catalog()
	var view: Dictionary = _view(
		catalog,
		&"support_prod_control_sustain",
		[
			TrainerRosterRoleInferenceFixtures.MOVE_CONTROL,
			TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN,
		],
		stats,
	)
	var result: Dictionary = inference.infer_role_scores(view, catalog)
	var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
	var cap: Dictionary = ((result.get("intrinsic_evidence", {}) as Dictionary).get("capability_evidence", {}) as Dictionary)
	_check.call("support_prod_control_sustain_evidence_present", int(cap.get("control_reliability_bp", 0)) == 10000 and int(cap.get("sustain_signal_bp", 0)) == 5000 and int(cap.get("control_dedicated_move_count", 0)) == 1)
	_check.call("support_prod_control_sustain_reaches_ceiling", int(scores.get("support", 0)) == 10000)


func _test_accuracy_and_sustain(
	inference: TrainerRosterRoleInference,
	stats: StatBlock,
) -> void:
	var catalog: DefinitionCatalog = _catalog()
	var inaccurate: Dictionary = _view(catalog, &"support_prod_inaccurate", [MOVE_DEDICATED_INACCURATE], stats)
	var inaccurate_result: Dictionary = inference.infer_role_scores(inaccurate, catalog)
	var inaccurate_scores: Dictionary = inaccurate_result.get("role_scores_bp", {}) as Dictionary
	var inaccurate_cap: Dictionary = ((inaccurate_result.get("intrinsic_evidence", {}) as Dictionary).get("capability_evidence", {}) as Dictionary)
	_check.call("support_prod_accuracy_reduces_role_score", int(inaccurate_cap.get("control_reliability_bp", 0)) == 8500 and int(inaccurate_scores.get("support", 0)) == 8500)

	var sustain: Dictionary = _view(
		catalog,
		&"support_prod_sustain_only",
		[TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN],
		stats,
	)
	var sustain_scores: Dictionary = (inference.infer_role_scores(sustain, catalog).get("role_scores_bp", {}) as Dictionary)
	_check.call("support_prod_sustain_only_preserved", int(sustain_scores.get("support", 0)) == 5000)


func _test_fail_closed_and_boundary(
	inference: TrainerRosterRoleInference,
	stats: StatBlock,
) -> void:
	var catalog: DefinitionCatalog = _catalog()
	var excluded: Dictionary = _view(catalog, &"support_prod_excluded", [MOVE_EXCLUDED_CONTROL], stats)
	var excluded_result: Dictionary = inference.infer_role_scores(excluded, catalog)
	var excluded_scores: Dictionary = excluded_result.get("role_scores_bp", {}) as Dictionary
	var excluded_cap: Dictionary = ((excluded_result.get("intrinsic_evidence", {}) as Dictionary).get("capability_evidence", {}) as Dictionary)
	_check.call("support_prod_excluded_control_fails_closed", int(excluded_cap.get("control_reliability_bp", -1)) == 0 and int(excluded_scores.get("support", -1)) == 0)

	var catalog_repeat: DefinitionCatalog = _catalog()
	var view: Dictionary = _view(
		catalog_repeat,
		&"support_prod_boundary",
		[
			TrainerRosterRoleInferenceFixtures.MOVE_CONTROL,
			MOVE_DEDICATED_SECOND,
			TrainerRosterRoleInferenceFixtures.MOVE_SUSTAIN,
		],
		stats,
	)
	var first: Dictionary = inference.infer_role_scores(view, catalog_repeat)
	var second: Dictionary = inference.infer_role_scores(view, catalog_repeat)
	_check.call("support_prod_model_id_recorded", String(first.get("support_model_id", "")) == TrainerRosterRoleInference.SUPPORT_MODEL_ID)
	_check.call("support_prod_deterministic", first == second)
	_check.call("support_prod_json_serializable", JSON.parse_string(JSON.stringify(first)) is Dictionary)


func _catalog() -> DefinitionCatalog:
	var catalog: DefinitionCatalog = TrainerRosterRoleInferenceFixtures.build_catalog()
	catalog.add_move(_control_move(
		MOVE_DAMAGING_PERFECT,
		80,
		100,
		TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED,
	))
	catalog.add_move(_control_move(
		MOVE_DEDICATED_SECOND,
		0,
		80,
		TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED,
	))
	catalog.add_move(_control_move(
		MOVE_DEDICATED_INACCURATE,
		0,
		85,
		TrainerRosterRoleInferenceFixtures.CLASS_RUNTIME_SUPPORTED,
	))
	catalog.add_move(_control_move(
		MOVE_EXCLUDED_CONTROL,
		0,
		100,
		TrainerRosterRoleInferenceFixtures.CLASS_DATA_ONLY,
	))
	return catalog


func _view(
	catalog: DefinitionCatalog,
	instance_id: StringName,
	move_ids: Array,
	stats: StatBlock,
) -> Dictionary:
	return TrainerRosterRoleInferenceFixtures.member_view(catalog, instance_id, move_ids, stats)


func _control_move(
	id: StringName,
	power: int,
	accuracy: int,
	classification: String,
) -> MoveDefinition:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.type_id = &"normal"
	move.damage_class = "physical" if power > 0 else "status"
	move.power = power
	move.accuracy = accuracy
	move.pp = 20
	move.classification = classification
	move.effect_specs.append(BattleEffectSpec.new(
		BattleEffectSpec.MODIFY_STAT_STAGE,
		BattleEffectSpec.OPPONENT,
		-1,
		0,
		10000,
		&"",
		StatStages.ATTACK,
	))
	return move
