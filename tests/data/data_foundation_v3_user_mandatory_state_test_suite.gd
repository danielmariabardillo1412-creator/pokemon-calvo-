class_name DataFoundationV3UserMandatoryStateTestSuite
extends RefCounted


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var moves := _moves_by_id(raw.get("moves", []))
	_test_geomancy(moves.get("geomancy", {}), check)
	_test_no_retreat(moves.get("no_retreat", {}), check)


func _test_geomancy(move: Dictionary, check: Callable) -> void:
	check.call("data_v3_mandatory_state_geomancy_present", not move.is_empty())
	if move.is_empty():
		return
	check.call(
		"data_v3_mandatory_state_geomancy_contract",
		move.get("target") == "user"
		and int(move.get("accuracy", -999)) == -1
		and move.get("classification") == "DATA_ONLY"
		and (move.get("effect_specs", []) as Array).is_empty(),
	)
	var summary := str(move.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_mandatory_state_geomancy_summary_retained",
		"one turn to charge" in summary
		and "special attack" in summary
		and "special defense" in summary
		and "speed" in summary,
	)


func _test_no_retreat(move: Dictionary, check: Callable) -> void:
	check.call("data_v3_mandatory_state_no_retreat_present", not move.is_empty())
	if move.is_empty():
		return
	check.call(
		"data_v3_mandatory_state_no_retreat_contract",
		move.get("target") == "user"
		and int(move.get("accuracy", -999)) == -1
		and move.get("classification") == "DATA_ONLY"
		and (move.get("effect_specs", []) as Array).is_empty(),
	)
	var summary := str(move.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_mandatory_state_no_retreat_summary_retained",
		"prevents user from switching out" in summary
		and "raises all" in summary,
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
