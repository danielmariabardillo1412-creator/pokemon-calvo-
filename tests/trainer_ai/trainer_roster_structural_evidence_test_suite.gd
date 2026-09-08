class_name TrainerRosterStructuralEvidenceTestSuite
extends TrainerTeamRandomCupAnalysisTestSuite


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_structural_roster_evidence()


func _test_structural_roster_evidence() -> void:
	_enable_runtime_team_moves()
	var evaluator := TrainerRosterStrategicValueEvaluator.new(_catalog)

	var fire := _view(
		&"c3_fire",
		TC_FIRE_A,
		StatBlock.new(100, 160, 80, 90, 60, 80),
		[TC_FIRE_PHYS],
	)
	var water := _view(
		&"c3_water",
		TC_WATER,
		StatBlock.new(100, 60, 90, 80, 160, 100),
		[TC_WATER_SPEC],
	)
	var grass := _view(
		&"c3_grass",
		TC_GRASS,
		StatBlock.new(110, 150, 100, 70, 60, 90),
		[TC_GRASS_PHYS],
	)
	var ground := _view(
		&"c3_ground",
		TC_GROUND,
		StatBlock.new(120, 150, 120, 60, 50, 100),
		[TC_GROUND_PHYS],
	)

	var roster: Array[Dictionary] = [fire, water, grass]
	var evidence: Dictionary = evaluator.extract_structural_evidence(roster)
	_check.call(
		"roster_structural_evidence_model_recorded",
		String(evidence.get("model_id", "")) == TrainerRosterStrategicValueEvaluator.STRUCTURAL_EVIDENCE_MODEL_ID,
	)
	_check.call(
		"roster_structural_evidence_counts_surviving_members",
		int(evidence.get("member_count", -1)) == 3,
	)
	_check.call(
		"roster_structural_evidence_reuses_role_threshold",
		int(evidence.get("role_presence_threshold_bp", -1)) == TrainerRosterStrategicValueEvaluator.STRONG_ROLE_BP,
	)
	_check.call(
		"roster_structural_evidence_physical_role_is_redundant",
		int((evidence.get("strong_role_counts", {}) as Dictionary).get("physical_attacker", 0)) == 2
		and (_member(evidence, "c3_fire").get("redundant_strong_role_ids", []) as Array).has("physical_attacker"),
	)
	_check.call(
		"roster_structural_evidence_special_role_is_unique",
		int((evidence.get("strong_role_counts", {}) as Dictionary).get("special_attacker", 0)) == 1
		and (_member(evidence, "c3_water").get("unique_strong_role_ids", []) as Array).has("special_attacker"),
	)

	var reduced: Array[Dictionary] = [fire, water]
	var reduced_evidence: Dictionary = evaluator.extract_structural_evidence(reduced)
	_check.call(
		"roster_structural_evidence_role_uniqueness_recomputes_after_loss",
		(_member(reduced_evidence, "c3_fire").get("unique_strong_role_ids", []) as Array).has("physical_attacker")
		and not (_member(reduced_evidence, "c3_fire").get("redundant_strong_role_ids", []) as Array).has("physical_attacker"),
	)

	var low_hp_fire: Dictionary = fire.duplicate(true)
	low_hp_fire["current_hp"] = 1
	var low_hp_roster: Array[Dictionary] = [low_hp_fire, water, grass]
	var low_hp_evidence: Dictionary = evaluator.extract_structural_evidence(low_hp_roster)
	_check.call(
		"roster_structural_evidence_low_hp_does_not_rewrite_structure",
		_member(low_hp_evidence, "c3_fire") == _member(evidence, "c3_fire"),
	)

	var knocked_out_fire: Dictionary = fire.duplicate(true)
	knocked_out_fire["current_hp"] = 0
	var ko_roster: Array[Dictionary] = [knocked_out_fire, water, grass]
	var ko_evidence: Dictionary = evaluator.extract_structural_evidence(ko_roster)
	_check.call(
		"roster_structural_evidence_knocked_out_member_is_not_a_survivor",
		int(ko_evidence.get("member_count", -1)) == 2
		and (ko_evidence.get("skipped_knocked_out_instance_ids", []) as Array).has("c3_fire")
		and _member(ko_evidence, "c3_fire").is_empty(),
	)

	_check.call(
		"roster_structural_evidence_tracks_unique_offensive_coverage",
		(_member(evidence, "c3_fire").get("unique_offensive_coverage_type_ids", []) as Array).has(String(T_GRASS)),
	)

	var ground_roster: Array[Dictionary] = [fire, water, ground]
	var ground_evidence: Dictionary = evaluator.extract_structural_evidence(ground_roster)
	_check.call(
		"roster_structural_evidence_tracks_unique_immunity",
		(_member(ground_evidence, "c3_ground").get("unique_immunity_type_ids", []) as Array).has(String(T_ELECTRIC)),
	)
	var ground_clone: Dictionary = ground.duplicate(true)
	ground_clone["instance_id"] = "c3_ground_clone"
	var duplicated_ground_roster: Array[Dictionary] = [ground, ground_clone]
	var duplicated_ground: Dictionary = evaluator.extract_structural_evidence(duplicated_ground_roster)
	_check.call(
		"roster_structural_evidence_immunity_becomes_redundant_when_duplicated",
		not (_member(duplicated_ground, "c3_ground").get("unique_immunity_type_ids", []) as Array).has(String(T_ELECTRIC))
		and (_member(duplicated_ground, "c3_ground").get("redundant_immunity_type_ids", []) as Array).has(String(T_ELECTRIC)),
	)

	var fire_special := _view(
		&"c3_fire_special",
		TC_FIRE_A,
		StatBlock.new(100, 160, 80, 90, 60, 80),
		[TC_FIRE_SPEC],
	)
	var physical_scores: Dictionary = (_member(
		evaluator.extract_structural_evidence([fire]),
		"c3_fire"
	).get("role_scores_bp", {}) as Dictionary)
	var special_scores: Dictionary = (_member(
		evaluator.extract_structural_evidence([fire_special]),
		"c3_fire_special"
	).get("role_scores_bp", {}) as Dictionary)
	_check.call(
		"roster_structural_evidence_same_species_moveset_changes_roles",
		int(physical_scores.get("physical_attacker", 0)) > int(special_scores.get("physical_attacker", 0))
		and int(special_scores.get("special_attacker", 0)) > int(physical_scores.get("special_attacker", 0)),
	)

	var electric_move: MoveDefinition = _catalog.move(TC_ELECTRIC_PHYS)
	var previous_classification: String = electric_move.classification
	electric_move.classification = "DATA_ONLY"
	var unsupported := _view(
		&"c3_unsupported",
		TC_ELECTRIC,
		StatBlock.new(90, 170, 70, 150, 60, 70),
		[TC_ELECTRIC_PHYS],
	)
	var unsupported_evidence: Dictionary = evaluator.extract_structural_evidence([unsupported])
	var unsupported_member: Dictionary = _member(unsupported_evidence, "c3_unsupported")
	_check.call(
		"roster_structural_evidence_unsupported_move_fails_closed",
		int(unsupported_member.get("runtime_supported_damaging_move_count", -1)) == 0
		and (unsupported_member.get("offensive_coverage_type_ids", []) as Array).is_empty()
		and int((unsupported_member.get("role_scores_bp", {}) as Dictionary).get("physical_attacker", -1)) == 0,
	)
	electric_move.classification = previous_classification

	var repeat: Dictionary = evaluator.extract_structural_evidence(roster)
	_check.call("roster_structural_evidence_is_deterministic", repeat == evidence)
	var parsed: Variant = JSON.parse_string(JSON.stringify(evidence))
	_check.call("roster_structural_evidence_is_json_serializable", parsed is Dictionary)
	_check.call(
		"roster_structural_evidence_does_not_fake_final_scalar",
		not evidence.has("structural_value_bp")
		and not evidence.has("operational_readiness_bp")
		and not evidence.has("permadeath_loss_cost_bp"),
	)

	var empty: Dictionary = TrainerRosterStrategicValueEvaluator.new(null).extract_structural_evidence([])
	_check.call(
		"roster_structural_evidence_null_catalog_fails_closed",
		int(empty.get("member_count", -1)) == 0
		and (empty.get("member_evidence", []) as Array).is_empty(),
	)


func _view(
	instance_id: StringName,
	species_id: StringName,
	stats: StatBlock,
	move_ids: Array,
) -> Dictionary:
	var resolved_move_ids: Array[StringName] = []
	for raw_move_id in move_ids:
		resolved_move_ids.append(StringName(raw_move_id))
	return CreatureInstance.new(
		instance_id,
		species_id,
		50,
		stats,
		resolved_move_ids,
	).to_dict()


func _member(evidence: Dictionary, instance_id: String) -> Dictionary:
	for raw_member in evidence.get("member_evidence", []):
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		if String(member.get("instance_id", "")) == instance_id:
			return member
	return {}
