class_name DataFoundationV3UserPersistentStateTestSuite
extends RefCounted


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var moves := _moves_by_id(raw.get("moves", []))
	_test_autotomize(moves.get("autotomize", {}), check)
	_test_minimize(moves.get("minimize", {}), check)


func _test_autotomize(move: Dictionary, check: Callable) -> void:
	check.call("data_v3_persistent_autotomize_present", not move.is_empty())
	if move.is_empty():
		return
	check.call(
		"data_v3_persistent_autotomize_contract",
		move.get("target") == "user"
		and int(move.get("accuracy", -999)) == -1
		and move.get("classification") == "DATA_ONLY"
		and (move.get("effect_specs", []) as Array).is_empty(),
	)
	var summary := str(move.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_persistent_autotomize_summary_current",
		"speed" in summary
		and "100 kg" in summary
		and not "halves" in summary
		and not "does not stack" in summary,
	)


func _test_minimize(move: Dictionary, check: Callable) -> void:
	check.call("data_v3_persistent_minimize_present", not move.is_empty())
	if move.is_empty():
		return
	check.call(
		"data_v3_persistent_minimize_contract",
		move.get("target") == "user"
		and int(move.get("accuracy", -999)) == -1
		and move.get("classification") == "DATA_ONLY"
		and (move.get("effect_specs", []) as Array).is_empty(),
	)
	var summary := str(move.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_persistent_minimize_summary_current",
		"evasion" in summary
		and "minimized state" in summary,
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
