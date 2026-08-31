class_name DataFoundationV3FinalDataOnlyEffectsTestSuite
extends RefCounted


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var moves_array: Array = raw.get("moves", [])
	var moves := _moves_by_id(moves_array)
	var purify: Dictionary = moves.get("purify", {})
	var swallow: Dictionary = moves.get("swallow", {})
	var beat_up: Dictionary = moves.get("beat_up", {})

	check.call("data_v3_final_effects_purify_present", not purify.is_empty())
	check.call(
		"data_v3_final_effects_purify_contract",
		purify.get("target") == "selected-pokemon"
		and int(purify.get("accuracy", -999)) == -1
		and purify.get("classification") == "DATA_ONLY"
		and (purify.get("effect_specs", []) as Array).is_empty(),
	)
	var purify_summary := str(purify.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_final_effects_purify_summary",
		"major status" in purify_summary
		and "50%" in purify_summary
		and "only if" in purify_summary,
	)

	check.call("data_v3_final_effects_swallow_present", not swallow.is_empty())
	check.call(
		"data_v3_final_effects_swallow_contract",
		swallow.get("target") == "user"
		and int(swallow.get("accuracy", -999)) == -1
		and swallow.get("classification") == "DATA_ONLY"
		and (swallow.get("effect_specs", []) as Array).is_empty(),
	)
	var swallow_summary := str(swallow.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_final_effects_swallow_summary",
		"stockpile" in swallow_summary
		and "25%/50%/100%" in swallow_summary
		and "level 0" in swallow_summary,
	)

	check.call("data_v3_final_effects_beat_up_present", not beat_up.is_empty())
	check.call(
		"data_v3_final_effects_beat_up_contract",
		beat_up.get("target") == "selected-pokemon"
		and int(beat_up.get("accuracy", -999)) == 100
		and int(beat_up.get("power", -999)) == 0
		and beat_up.get("damage_class") == "physical"
		and beat_up.get("classification") == "DATA_ONLY"
		and (beat_up.get("effect_specs", []) as Array).is_empty(),
	)
	var beat_up_summary := str(beat_up.get("effect_summary", "")).to_lower()
	check.call(
		"data_v3_final_effects_beat_up_summary",
		"party-dependent" in beat_up_summary
		and "fainted" in beat_up_summary
		and "statused" in beat_up_summary,
	)

	var unsafe_data_only: Array[String] = []
	for record in moves_array:
		if record is Dictionary:
			var move: Dictionary = record
			if (
				move.get("classification") == "DATA_ONLY"
				and not (move.get("effect_specs", []) as Array).is_empty()
			):
				unsafe_data_only.append(str(move.get("id", "")))
	check.call(
		"data_v3_final_effects_zero_data_only_with_specs",
		unsafe_data_only.is_empty(),
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
