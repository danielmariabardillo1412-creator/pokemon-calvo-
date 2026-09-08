class_name TrainerTeamRandomCupAnalysisTestSuite
extends TrainerTeamCompositionTestSuite

const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_random_cup_inferred_role_analysis()


func _test_random_cup_inferred_role_analysis() -> void:
	_enable_runtime_team_moves()
	var analyzer := TrainerTeamAnalyzer.new(_catalog)
	var team: TrainerTeamDefinition = _balanced_authored_team()
	var original_signature: String = team.signature()
	var authored: Dictionary = analyzer.analyze(team)
	var inferred: Dictionary = analyzer.analyze_random_cup(team)

	_check.call(
		"team_random_cup_model_recorded",
		String(inferred.get("model", "")) == TrainerTeamAnalyzer.RANDOM_CUP_MODEL_ID,
	)
	_check.call(
		"team_random_cup_preserves_authored_analyzer_model",
		String(authored.get("model", "")) == TrainerTeamAnalyzer.MODEL_ID,
	)
	_check.call(
		"team_random_cup_infers_all_valid_members",
		int(inferred.get("inferred_member_count", -1)) == team.size()
		and (inferred.get("uninferred_member_indices", []) as Array).is_empty(),
	)
	_check.call(
		"team_random_cup_does_not_mutate_team",
		team.signature() == original_signature,
	)
	_check.call(
		"team_random_cup_uses_strong_role_threshold",
		int(inferred.get("role_presence_threshold_bp", -1)) == TrainerTeamAnalyzer.STRONG_ROLE_BP,
	)
	_check.call(
		"team_random_cup_aggregation_matches_member_scores",
		_aggregation_matches_member_scores(inferred),
	)
	_check.call(
		"team_random_cup_role_partition_is_complete",
		_role_partition_is_complete(inferred),
	)
	_check.call(
		"team_random_cup_never_promotes_balanced_to_capability",
		not (inferred.get("role_counts", {}) as Dictionary).has(String(TrainerPokemonLoadout.ROLE_BALANCED)),
	)

	var relabeled: TrainerTeamDefinition = TrainerTeamDefinition.from_dict(team.to_dict())
	for loadout in relabeled.loadouts:
		if loadout != null:
			loadout.role_id = TrainerPokemonLoadout.ROLE_BALANCED
	var authored_relabeled: Dictionary = analyzer.analyze(relabeled)
	var inferred_relabeled: Dictionary = analyzer.analyze_random_cup(relabeled)
	_check.call(
		"team_random_cup_authored_path_still_reads_role_id",
		(authored.get("role_counts", {}) as Dictionary) != (authored_relabeled.get("role_counts", {}) as Dictionary)
		and int((authored_relabeled.get("role_counts", {}) as Dictionary).get(String(TrainerPokemonLoadout.ROLE_BALANCED), 0)) == team.size(),
	)
	_check.call(
		"team_random_cup_inferred_path_ignores_authored_role_id",
		inferred == inferred_relabeled,
	)

	var changed_moves: TrainerTeamDefinition = TrainerTeamDefinition.from_dict(team.to_dict())
	var special_only: Array[StringName] = [TC_FIRE_SPEC]
	changed_moves.loadouts[0].move_ids = special_only
	var inferred_changed: Dictionary = analyzer.analyze_random_cup(changed_moves)
	var original_member_scores: Dictionary = _member_role_scores(inferred, 0)
	var changed_member_scores: Dictionary = _member_role_scores(inferred_changed, 0)
	_check.call(
		"team_random_cup_actual_moveset_changes_inference",
		inferred_changed != inferred
		and int(original_member_scores.get("physical_attacker", 0)) > int(changed_member_scores.get("physical_attacker", 0))
		and int(changed_member_scores.get("physical_attacker", -1)) == 0
		and int(changed_member_scores.get("special_attacker", 0)) > 0,
	)

	var repeat: Dictionary = analyzer.analyze_random_cup(team)
	_check.call("team_random_cup_is_deterministic", repeat == inferred)
	var parsed: Variant = JSON.parse_string(JSON.stringify(inferred))
	_check.call("team_random_cup_output_is_json_serializable", parsed is Dictionary)

	var empty: Dictionary = analyzer.analyze_random_cup(null)
	_check.call(
		"team_random_cup_null_fails_closed",
		String(empty.get("model", "")) == TrainerTeamAnalyzer.RANDOM_CUP_MODEL_ID
		and int(empty.get("member_count", -1)) == 0
		and int(empty.get("inferred_member_count", -1)) == 0
		and (empty.get("absent_strong_roles", []) as Array).size() == TrainerTeamAnalyzer.INFERRED_ROLE_IDS.size(),
	)


func _enable_runtime_team_moves() -> void:
	var move_ids: Array[StringName] = [
		TC_FIRE_PHYS,
		TC_FIRE_SPEC,
		TC_WATER_SPEC,
		TC_GRASS_PHYS,
		TC_ELECTRIC_PHYS,
		TC_GROUND_PHYS,
		TC_SUPPORT,
	]
	for move_id in move_ids:
		var move: MoveDefinition = _catalog.move(move_id)
		if move != null:
			move.classification = RUNTIME_SUPPORTED


func _aggregation_matches_member_scores(analysis: Dictionary) -> bool:
	var expected_counts: Dictionary = {}
	var expected_sums: Dictionary = {}
	var expected_max: Dictionary = {}
	for raw_role_id in TrainerTeamAnalyzer.INFERRED_ROLE_IDS:
		var role_id := String(raw_role_id)
		expected_sums[role_id] = 0
		expected_max[role_id] = 0

	var members: Array = analysis.get("member_role_inference", []) as Array
	for raw_member in members:
		if not (raw_member is Dictionary):
			return false
		var member: Dictionary = raw_member as Dictionary
		var role_scores: Dictionary = member.get("role_scores_bp", {}) as Dictionary
		for raw_role_id in TrainerTeamAnalyzer.INFERRED_ROLE_IDS:
			var role_id := String(raw_role_id)
			var score: int = int(role_scores.get(role_id, 0))
			expected_sums[role_id] = int(expected_sums.get(role_id, 0)) + score
			expected_max[role_id] = maxi(int(expected_max.get(role_id, 0)), score)
			if score >= TrainerTeamAnalyzer.STRONG_ROLE_BP:
				expected_counts[role_id] = int(expected_counts.get(role_id, 0)) + 1

	return (
		expected_counts == (analysis.get("role_counts", {}) as Dictionary)
		and expected_sums == (analysis.get("role_score_sums_bp", {}) as Dictionary)
		and expected_max == (analysis.get("role_max_scores_bp", {}) as Dictionary)
	)


func _role_partition_is_complete(analysis: Dictionary) -> bool:
	var absent: Array = analysis.get("absent_strong_roles", []) as Array
	var unique: Array = analysis.get("unique_strong_roles", []) as Array
	var redundant: Array = analysis.get("redundant_strong_roles", []) as Array
	if absent.size() + unique.size() + redundant.size() != TrainerTeamAnalyzer.INFERRED_ROLE_IDS.size():
		return false
	var seen: Dictionary = {}
	for group in [absent, unique, redundant]:
		for raw_role_id in group:
			var role_id := String(raw_role_id)
			if seen.has(role_id):
				return false
			seen[role_id] = true
	for raw_role_id in TrainerTeamAnalyzer.INFERRED_ROLE_IDS:
		if not seen.has(String(raw_role_id)):
			return false
	return true


func _member_role_scores(analysis: Dictionary, member_index: int) -> Dictionary:
	var members: Array = analysis.get("member_role_inference", []) as Array
	for raw_member in members:
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		if int(member.get("member_index", -1)) == member_index:
			return (member.get("role_scores_bp", {}) as Dictionary).duplicate(true)
	return {}
