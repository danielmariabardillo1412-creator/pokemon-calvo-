class_name DataFoundationV3AllPokemonTestSuite
extends RefCounted


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var moves := _moves_by_id(raw.get("moves", []))
	var flower: Dictionary = moves.get("flower_shield", {})
	var rototiller: Dictionary = moves.get("rototiller", {})

	check.call("data_v3_all_pokemon_flower_present", not flower.is_empty())
	check.call(
		"data_v3_all_pokemon_flower_contract",
		flower.get("target") == "all-pokemon"
		and int(flower.get("accuracy", -999)) == -1
		and flower.get("classification") == "DATA_ONLY"
		and (flower.get("effect_specs", []) as Array).is_empty(),
	)
	var flower_summary := str(flower.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_all_pokemon_flower_summary",
		"grass-type" in flower_summary
		and "defense" in flower_summary
		and "generation ix" in flower_summary,
	)

	check.call("data_v3_all_pokemon_rototiller_present", not rototiller.is_empty())
	check.call(
		"data_v3_all_pokemon_rototiller_contract",
		rototiller.get("target") == "all-pokemon"
		and int(rototiller.get("accuracy", -999)) == -1
		and rototiller.get("classification") == "DATA_ONLY"
		and (rototiller.get("effect_specs", []) as Array).is_empty(),
	)
	var rototiller_summary := str(rototiller.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_all_pokemon_rototiller_summary",
		"grounded grass-type" in rototiller_summary
		and "attack and special attack" in rototiller_summary
		and "generation viii" in rototiller_summary,
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
