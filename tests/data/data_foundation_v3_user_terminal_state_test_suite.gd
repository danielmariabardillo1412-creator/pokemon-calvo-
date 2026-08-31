class_name DataFoundationV3UserTerminalStateTestSuite
extends RefCounted


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var moves := _moves_by_id(raw.get("moves", []))
	_assert_effect_free(check, moves, "extreme_evoboost")
	_assert_effect_free(check, moves, "stockpile")
	_assert_effect_free(check, moves, "tidy_up")

	var extreme: Dictionary = moves.get("extreme_evoboost", {})
	var extreme_summary := str(extreme.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_terminal_extreme_evoboost_summary",
		"exclusive z-move" in extreme_summary
		and "five battle stats" in extreme_summary
		and "generation viii" in extreme_summary,
	)

	var stockpile: Dictionary = moves.get("stockpile", {})
	var stockpile_summary := str(stockpile.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_terminal_stockpile_summary",
		"maximum three" in stockpile_summary
		and "spit up" in stockpile_summary
		and "swallow" in stockpile_summary
		and "associated stockpile stat boosts" in stockpile_summary,
	)

	var tidy: Dictionary = moves.get("tidy_up", {})
	var tidy_summary := str(tidy.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_terminal_tidy_up_summary",
		"attack and speed" in tidy_summary
		and "hazards" in tidy_summary
		and "substitute" in tidy_summary
		and "both sides" in tidy_summary,
	)


func _assert_effect_free(
	check: Callable,
	moves: Dictionary,
	move_id: String,
) -> void:
	var move: Dictionary = moves.get(move_id, {})
	check.call("data_v3_terminal_%s_present" % move_id, not move.is_empty())
	check.call(
		"data_v3_terminal_%s_contract" % move_id,
		move.get("target") == "user"
		and int(move.get("accuracy", -999)) == -1
		and move.get("classification") == "DATA_ONLY"
		and (move.get("effect_specs", []) as Array).is_empty(),
	)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary


func _moves_by_id(records: Array) -> Dictionary:
	var result := {}
	for record in records:
		if record is Dictionary:
			result[str(record.get("id", ""))] = record
	return result
