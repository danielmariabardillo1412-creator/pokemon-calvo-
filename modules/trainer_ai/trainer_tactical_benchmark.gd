class_name TrainerTacticalBenchmark
extends RefCounted

# Small deterministic benchmark contract for FASE 21. It intentionally benchmarks
# decision cases rather than wall-clock time. Future self-play can build on the same
# action signatures and traces without making CI timing-sensitive.


static func run(
	brain: TrainerBrain,
	cases: Array[Dictionary],
) -> Dictionary:
	var decisions: Array[Dictionary] = []
	var matched := 0
	var expected_count := 0
	var null_actions := 0
	var signature_parts: Array[String] = []
	for index in cases.size():
		var case_data := cases[index]
		var context := case_data.get("context") as TrainerDecisionContext
		var chosen: BattleAction = brain.choose_action(context) if brain != null else null
		var key := action_key(chosen)
		if chosen == null:
			null_actions += 1
		var expected := String(case_data.get("expected_action_key", ""))
		var matches := true
		if not expected.is_empty():
			expected_count += 1
			matches = key == expected
			if matches:
				matched += 1
		var case_id := String(case_data.get("id", "case_%d" % index))
		decisions.append({
			"id": case_id,
			"action_key": key,
			"expected_action_key": expected,
			"matches_expected": matches,
		})
		signature_parts.append("%s=%s" % [case_id, key])
	return {
		"case_count": cases.size(),
		"expected_count": expected_count,
		"matched_expected": matched,
		"null_actions": null_actions,
		"signature": "|".join(signature_parts),
		"decisions": decisions,
	}


static func action_key(action: BattleAction) -> String:
	if action == null:
		return "null"
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	return "move:%s" % String(action.move_id)
