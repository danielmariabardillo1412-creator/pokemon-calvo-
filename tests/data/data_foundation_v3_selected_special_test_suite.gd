class_name DataFoundationV3SelectedSpecialTestSuite
extends RefCounted


func run(check_callback: Callable) -> void:
	var expected := {
		"decorate": {"attack": 2, "special_attack": 2},
		"spicy_extract": {"attack": 2, "defense": -2},
	}
	for move_id in expected:
		var move := _load_raw_move(move_id)
		check_callback.call("data_v3_%s_selected_special_present" % move_id, not move.is_empty())
		if move.is_empty():
			continue
		check_callback.call(
			"data_v3_%s_selected_special_target" % move_id,
			move.get("target", "") == "selected-pokemon",
		)
		check_callback.call(
			"data_v3_%s_selected_special_always_hit" % move_id,
			int(move.get("accuracy", 100)) == -1,
		)
		check_callback.call(
			"data_v3_%s_selected_special_runtime_supported" % move_id,
			move.get("classification", "") == "RUNTIME_SUPPORTED",
		)
		var specs: Array = move.get("effect_specs", [])
		var expected_stats: Dictionary = expected[move_id]
		check_callback.call(
			"data_v3_%s_selected_special_effect_count" % move_id,
			specs.size() == expected_stats.size(),
		)
		var generated := {}
		var shape_ok := true
		for spec in specs:
			if not (spec is Dictionary):
				shape_ok = false
				continue
			if (
				spec.get("kind", "") != "modify_stat_stage"
				or spec.get("target", "") != "opponent"
				or int(spec.get("chance_basis_points", 0)) != 10000
			):
				shape_ok = false
			generated[String(spec.get("stat_id", ""))] = int(spec.get("value", 0))
		check_callback.call("data_v3_%s_selected_special_effect_shape" % move_id, shape_ok)
		check_callback.call(
			"data_v3_%s_selected_special_effect_package" % move_id,
			generated == expected_stats,
		)


func _load_raw_move(move_id: String) -> Dictionary:
	var raw_text := FileAccess.get_file_as_string("res://data/raw/pokemon_api.json")
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {}
	var root: Dictionary = parsed
	for move in root.get("moves", []):
		if move is Dictionary and String(move.get("id", "")) == move_id:
			return move
	return {}
