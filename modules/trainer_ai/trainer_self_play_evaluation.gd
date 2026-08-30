class_name TrainerSelfPlayEvaluation
extends RefCounted

const SCHEMA_VERSION := 1


static func compare_against_reference(
	catalog: DefinitionCatalog,
	candidate_roster: Array[CreatureInstance],
	reference_roster: Array[CreatureInstance],
	baseline_factory: Callable,
	planner_factory: Callable,
	reference_factory: Callable,
	seeds: Array[int],
	max_turns: int = 40,
) -> Dictionary:
	var baseline := _run_candidate(
		"baseline",
		catalog,
		candidate_roster,
		reference_roster,
		baseline_factory,
		reference_factory,
		seeds,
		max_turns,
	)
	var planner := _run_candidate(
		"planner",
		catalog,
		candidate_roster,
		reference_roster,
		planner_factory,
		reference_factory,
		seeds,
		max_turns,
	)
	var paired_improvements := 0
	var paired_regressions := 0
	var paired_equal := 0
	var baseline_matches := baseline.get("matches", []) as Array
	var planner_matches := planner.get("matches", []) as Array
	for index in mini(baseline_matches.size(), planner_matches.size()):
		var b := baseline_matches[index] as Dictionary
		var p := planner_matches[index] as Dictionary
		var b_score := _candidate_outcome_score(b)
		var p_score := _candidate_outcome_score(p)
		if p_score > b_score:
			paired_improvements += 1
		elif p_score < b_score:
			paired_regressions += 1
		else:
			paired_equal += 1
	var result := {
		"schema_version": SCHEMA_VERSION,
		"evaluation_model": "paired_mirrored_reference_v1",
		"seed_count": seeds.size(),
		"matches_per_candidate": seeds.size() * 2,
		"baseline": baseline,
		"planner": planner,
		"paired_improvements": paired_improvements,
		"paired_regressions": paired_regressions,
		"paired_equal": paired_equal,
	}
	result["signature"] = _signature(result)
	return result


static func _run_candidate(
	label: String,
	catalog: DefinitionCatalog,
	candidate_roster: Array[CreatureInstance],
	reference_roster: Array[CreatureInstance],
	candidate_factory: Callable,
	reference_factory: Callable,
	seeds: Array[int],
	max_turns: int,
) -> Dictionary:
	var wins := 0
	var losses := 0
	var draws := 0
	var invalid := 0
	var total_turns := 0
	var total_blunders := 0
	var matches: Array[Dictionary] = []
	for seed in seeds:
		for mirror in 2:
			var candidate_side := &"side_a" if mirror == 0 else &"side_b"
			var candidate_brain := candidate_factory.call(catalog) as TrainerBrain
			var reference_brain := reference_factory.call(catalog) as TrainerBrain
			var runner := TrainerSelfPlayMatch.new(max_turns)
			var match_result: Dictionary
			if mirror == 0:
				match_result = runner.run(
					catalog,
					candidate_roster,
					candidate_brain,
					reference_roster,
					reference_brain,
					seed,
					StringName("selfplay_%s_%d_a" % [label, seed]),
				)
			else:
				match_result = runner.run(
					catalog,
					reference_roster,
					reference_brain,
					candidate_roster,
					candidate_brain,
					seed,
					StringName("selfplay_%s_%d_b" % [label, seed]),
				)
			var winner_side := StringName(match_result.get("winner_side_id", ""))
			var candidate_won := winner_side == candidate_side
			var reference_won := winner_side != &"" and winner_side != candidate_side
			if not bool(match_result.get("ok", false)):
				invalid += 1
			elif candidate_won:
				wins += 1
			elif reference_won:
				losses += 1
			else:
				draws += 1
			total_turns += int(match_result.get("turn_count", 0))
			var blunder_report := match_result.get("blunders", {}) as Dictionary
			total_blunders += int(blunder_report.get("record_count", 0))
			matches.append({
				"key": "%d:%s" % [seed, String(candidate_side)],
				"seed": seed,
				"candidate_side_id": String(candidate_side),
				"candidate_won": candidate_won,
				"reference_won": reference_won,
				"draw": winner_side == &"",
				"termination": String(match_result.get("termination", "")),
				"turn_count": int(match_result.get("turn_count", 0)),
				"blunder_count": int(blunder_report.get("record_count", 0)),
				"match": match_result,
			})
	return {
		"label": label,
		"match_count": matches.size(),
		"wins": wins,
		"losses": losses,
		"draws": draws,
		"invalid": invalid,
		"total_turns": total_turns,
		"total_blunders": total_blunders,
		"matches": matches,
	}


static func _candidate_outcome_score(match_record: Dictionary) -> int:
	if bool(match_record.get("candidate_won", false)):
		return 2
	if bool(match_record.get("draw", false)):
		return 1
	return 0


static func _signature(result: Dictionary) -> String:
	var baseline := result.get("baseline", {}) as Dictionary
	var planner := result.get("planner", {}) as Dictionary
	return "b:%d-%d-%d-%d|p:%d-%d-%d-%d|i:%d|r:%d|e:%d" % [
		int(baseline.get("wins", 0)),
		int(baseline.get("losses", 0)),
		int(baseline.get("draws", 0)),
		int(baseline.get("invalid", 0)),
		int(planner.get("wins", 0)),
		int(planner.get("losses", 0)),
		int(planner.get("draws", 0)),
		int(planner.get("invalid", 0)),
		int(result.get("paired_improvements", 0)),
		int(result.get("paired_regressions", 0)),
		int(result.get("paired_equal", 0)),
	]
