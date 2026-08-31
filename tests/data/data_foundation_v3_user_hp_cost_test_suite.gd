class_name DataFoundationV3UserHpCostTestSuite
extends RefCounted


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var moves := _moves_by_id(raw.get("moves", []))
	var clangorous: Dictionary = moves.get("clangorous_soul", {})
	var fillet: Dictionary = moves.get("fillet_away", {})

	check.call("data_v3_hp_cost_clangorous_present", not clangorous.is_empty())
	check.call(
		"data_v3_hp_cost_clangorous_contract",
		clangorous.get("target") == "user"
		and int(clangorous.get("accuracy", -999)) == 100
		and clangorous.get("classification") == "DATA_ONLY"
		and (clangorous.get("effect_specs", []) as Array).is_empty(),
	)
	var clangorous_summary := str(clangorous.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_hp_cost_clangorous_summary_retained",
		"33%" in clangorous_summary
		and "max hp" in clangorous_summary
		and "raises all" in clangorous_summary,
	)

	check.call("data_v3_hp_cost_fillet_present", not fillet.is_empty())
	check.call(
		"data_v3_hp_cost_fillet_contract",
		fillet.get("target") == "user"
		and int(fillet.get("accuracy", -999)) == -1
		and fillet.get("classification") == "DATA_ONLY"
		and (fillet.get("effect_specs", []) as Array).is_empty(),
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
