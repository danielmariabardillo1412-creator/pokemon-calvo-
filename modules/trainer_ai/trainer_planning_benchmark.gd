class_name TrainerPlanningBenchmark
extends RefCounted

# Deterministic decision benchmark for planning depth. It deliberately compares
# decisions and search metadata, not wall-clock duration, so CI remains reproducible.


static func compare(
	baseline: TrainerBrain,
	planner: TrainerBrain,
	cases: Array[Dictionary],
) -> Dictionary:
	var decisions: Array[Dictionary] = []
	var baseline_matches := 0
	var planner_matches := 0
	var expected_count := 0
	var changed := 0
	var horizon_improvements := 0
	var regressions := 0
	var baseline_signature: Array[String] = []
	var planner_signature: Array[String] = []
	for index in cases.size():
		var case_data := cases[index]
		var context := case_data.get("context") as TrainerDecisionContext
		var baseline_action := baseline.choose_action(context) if baseline != null else null
		var planner_action := planner.choose_action(context) if planner != null else null
		var baseline_key := TrainerTacticalBenchmark.action_key(baseline_action)
		var planner_key := TrainerTacticalBenchmark.action_key(planner_action)
		var expected := String(case_data.get("expected_action_key", ""))
		var baseline_ok := expected.is_empty() or baseline_key == expected
		var planner_ok := expected.is_empty() or planner_key == expected
		if not expected.is_empty():
			expected_count += 1
			if baseline_ok:
				baseline_matches += 1
			if planner_ok:
				planner_matches += 1
			if planner_ok and not baseline_ok:
				horizon_improvements += 1
			elif baseline_ok and not planner_ok:
				regressions += 1
		if baseline_key != planner_key:
			changed += 1
		var case_id := String(case_data.get("id", "case_%d" % index))
		decisions.append({
			"id": case_id,
			"expected_action_key": expected,
			"baseline_action_key": baseline_key,
			"planner_action_key": planner_key,
			"baseline_matches_expected": baseline_ok,
			"planner_matches_expected": planner_ok,
		})
		baseline_signature.append("%s=%s" % [case_id, baseline_key])
		planner_signature.append("%s=%s" % [case_id, planner_key])
	return {
		"case_count": cases.size(),
		"expected_count": expected_count,
		"baseline_matched_expected": baseline_matches,
		"planner_matched_expected": planner_matches,
		"changed_decisions": changed,
		"horizon_improvements": horizon_improvements,
		"regressions": regressions,
		"baseline_signature": "|".join(baseline_signature),
		"planner_signature": "|".join(planner_signature),
		"decisions": decisions,
	}
