extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var suite := TrainerSearchLimitBenchmarkV3TestSuite.new()
	suite._check = Callable(self, "_ignore")
	suite._build_catalog()
	var result := TrainerSearchLimitBenchmark.run(
		suite._catalog,
		suite._scenarios(),
		Callable(suite, "_planner_factory"),
	)
	for target_id in ["three_turn_replanning_control", "isolated_three_turn_horizon"]:
		var horizon: Dictionary = {}
		for value in result.get("scenarios", []):
			var record := value as Dictionary
			if String(record.get("id", "")) == target_id:
				horizon = record
				break
		print("REPLANNING_DIAGNOSTIC_SUMMARY id=%s planner=%s" % [target_id, JSON.stringify(horizon.get("planner", {}))])
		var matches := horizon.get("planner_matches", []) as Array
		for i in range(matches.size()):
			var match_record := matches[i] as Dictionary
			var battle := match_record.get("result", {}) as Dictionary
			var actions: Array[String] = []
			for turn_value in battle.get("turns", []):
				var turn := turn_value as Dictionary
				var key := "side_b_action" if bool(match_record.get("mirrored", false)) else "side_a_action"
				var action := turn.get(key, {}) as Dictionary
				actions.append(String(action.get("move_id", action.get("switch_instance_id", ""))))
			print("REPLANNING_DIAGNOSTIC_MATCH id=%s index=%d seed=%d mirrored=%s outcome=%s winner=%s turns=%d actions=%s" % [
				target_id,
				i,
				int(match_record.get("seed", 0)),
				str(bool(match_record.get("mirrored", false))),
				String(match_record.get("outcome", "")),
				String(battle.get("winner_side_id", "")),
				int(battle.get("turn_count", 0)),
				JSON.stringify(actions),
			])
	quit(0)


func _ignore(_name: String, _condition: bool) -> void:
	pass
