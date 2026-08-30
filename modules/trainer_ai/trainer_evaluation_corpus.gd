class_name TrainerEvaluationCorpus
extends RefCounted

const SCHEMA_VERSION := 1
const MODEL_ID := "segmented_paired_mirrored_corpus_v1"


static func run(
	catalog: DefinitionCatalog,
	scenarios: Array[Dictionary],
	baseline_factory: Callable,
	planner_factory: Callable,
) -> Dictionary:
	var records: Array[Dictionary] = []
	var totals := {
		"baseline_wins": 0,
		"baseline_losses": 0,
		"baseline_draws": 0,
		"baseline_invalid": 0,
		"planner_wins": 0,
		"planner_losses": 0,
		"planner_draws": 0,
		"planner_invalid": 0,
		"paired_improvements": 0,
		"paired_regressions": 0,
		"paired_equal": 0,
		"matches_per_candidate": 0,
	}
	for scenario in scenarios:
		var scenario_id := String(scenario.get("id", "scenario"))
		var family := String(scenario.get("family", "unspecified"))
		var reference_factory := scenario.get("reference_factory", Callable()) as Callable
		var candidate_roster := scenario.get("candidate_roster", []) as Array[CreatureInstance]
		var reference_roster := scenario.get("reference_roster", []) as Array[CreatureInstance]
		var seeds := _int_array(scenario.get("seeds", []))
		var max_turns := maxi(1, int(scenario.get("max_turns", 40)))
		var evaluation := TrainerSelfPlayEvaluation.compare_against_reference(
			catalog,
			candidate_roster,
			reference_roster,
			baseline_factory,
			planner_factory,
			reference_factory,
			seeds,
			max_turns,
		)
		var baseline := evaluation.get("baseline", {}) as Dictionary
		var planner := evaluation.get("planner", {}) as Dictionary
		var record := {
			"id": scenario_id,
			"family": family,
			"seed_count": seeds.size(),
			"matches_per_candidate": int(evaluation.get("matches_per_candidate", 0)),
			"baseline": _summary(baseline),
			"planner": _summary(planner),
			"paired_improvements": int(evaluation.get("paired_improvements", 0)),
			"paired_regressions": int(evaluation.get("paired_regressions", 0)),
			"paired_equal": int(evaluation.get("paired_equal", 0)),
			"signature": String(evaluation.get("signature", "")),
		}
		records.append(record)
		_accumulate(totals, baseline, planner, evaluation)

	var baseline_decisive := int(totals.baseline_wins) + int(totals.baseline_losses)
	var planner_decisive := int(totals.planner_wins) + int(totals.planner_losses)
	var paired_directional := int(totals.paired_improvements) + int(totals.paired_regressions)
	var statistics := {
		"baseline_win_interval": TrainerWilsonInterval.calculate(int(totals.baseline_wins), baseline_decisive),
		"planner_win_interval": TrainerWilsonInterval.calculate(int(totals.planner_wins), planner_decisive),
		"improvement_interval": TrainerWilsonInterval.calculate(int(totals.paired_improvements), paired_directional),
		"regression_interval": TrainerWilsonInterval.calculate(int(totals.paired_regressions), paired_directional),
	}
	var out := {
		"schema_version": SCHEMA_VERSION,
		"evaluation_model": MODEL_ID,
		"scenario_count": records.size(),
		"scenarios": records,
		"totals": totals,
		"statistics": statistics,
	}
	out["signature"] = _signature(out)
	return out


static func _summary(data: Dictionary) -> Dictionary:
	return {
		"wins": int(data.get("wins", 0)),
		"losses": int(data.get("losses", 0)),
		"draws": int(data.get("draws", 0)),
		"invalid": int(data.get("invalid", 0)),
		"total_turns": int(data.get("total_turns", 0)),
		"total_blunders": int(data.get("total_blunders", 0)),
	}


static func _accumulate(
	totals: Dictionary,
	baseline: Dictionary,
	planner: Dictionary,
	evaluation: Dictionary,
) -> void:
	for key in ["wins", "losses", "draws", "invalid"]:
		totals["baseline_%s" % key] = int(totals.get("baseline_%s" % key, 0)) + int(baseline.get(key, 0))
		totals["planner_%s" % key] = int(totals.get("planner_%s" % key, 0)) + int(planner.get(key, 0))
	totals.paired_improvements = int(totals.paired_improvements) + int(evaluation.get("paired_improvements", 0))
	totals.paired_regressions = int(totals.paired_regressions) + int(evaluation.get("paired_regressions", 0))
	totals.paired_equal = int(totals.paired_equal) + int(evaluation.get("paired_equal", 0))
	totals.matches_per_candidate = int(totals.matches_per_candidate) + int(evaluation.get("matches_per_candidate", 0))


static func _int_array(values: Array) -> Array[int]:
	var out: Array[int] = []
	for value in values:
		out.append(int(value))
	return out


static func _signature(result: Dictionary) -> String:
	var totals := result.get("totals", {}) as Dictionary
	var scenario_parts: Array[String] = []
	for value in result.get("scenarios", []):
		var record := value as Dictionary
		scenario_parts.append("%s=%s" % [String(record.get("id", "")), String(record.get("signature", ""))])
	return "m:%d|bw:%d|bl:%d|pw:%d|pl:%d|i:%d|r:%d|%s" % [
		int(totals.get("matches_per_candidate", 0)),
		int(totals.get("baseline_wins", 0)),
		int(totals.get("baseline_losses", 0)),
		int(totals.get("planner_wins", 0)),
		int(totals.get("planner_losses", 0)),
		int(totals.get("paired_improvements", 0)),
		int(totals.get("paired_regressions", 0)),
		"|".join(scenario_parts),
	]
