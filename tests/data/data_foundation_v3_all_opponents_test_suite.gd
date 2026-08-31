class_name DataFoundationV3AllOpponentsTestSuite
extends RefCounted


func run(check_callback: Callable) -> void:
	_test_runtime_supported(
		"growl", 100, {"attack": -1}, check_callback
	)
	_test_runtime_supported(
		"leer", 100, {"defense": -1}, check_callback
	)
	_test_runtime_supported(
		"string_shot", 95, {"speed": -2}, check_callback
	)
	_test_runtime_supported(
		"sweet_scent", 100, {"evasion": -2}, check_callback
	)
	_test_runtime_supported(
		"tail_whip", 100, {"defense": -1}, check_callback
	)
	_test_neutralized("captivate", 100, check_callback)
	_test_neutralized("cotton_spore", 100, check_callback)
	_test_neutralized("venom_drench", 100, check_callback)
	_test_sweet_scent_summary(check_callback)


func _load_raw_move(move_id: String) -> Dictionary:
	var raw_text := FileAccess.get_file_as_string("res://data/raw/pokemon_api.json")
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {}
	for move in parsed.get("moves", []):
		if move is Dictionary and String(move.get("id", "")) == move_id:
			return move
	return {}


func _test_runtime_supported(
	move_id: String,
	expected_accuracy: int,
	expected_stats: Dictionary,
	check_callback: Callable,
) -> void:
	var move := _load_raw_move(move_id)
	check_callback.call("data_v3_%s_present" % move_id, not move.is_empty())
	if move.is_empty():
		return
	check_callback.call(
		"data_v3_%s_target_is_all_opponents" % move_id,
		move.get("target", "") == "all-opponents",
	)
	check_callback.call(
		"data_v3_%s_accuracy" % move_id,
		int(move.get("accuracy", -999)) == expected_accuracy,
	)
	check_callback.call(
		"data_v3_%s_runtime_supported" % move_id,
		move.get("classification", "") == "RUNTIME_SUPPORTED",
	)
	var specs: Array = move.get("effect_specs", [])
	check_callback.call(
		"data_v3_%s_effect_count" % move_id,
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
	check_callback.call("data_v3_%s_effect_shape" % move_id, shape_ok)
	check_callback.call(
		"data_v3_%s_effect_package" % move_id,
		generated == expected_stats,
	)


func _test_neutralized(
	move_id: String,
	expected_accuracy: int,
	check_callback: Callable,
) -> void:
	var move := _load_raw_move(move_id)
	check_callback.call("data_v3_%s_present" % move_id, not move.is_empty())
	if move.is_empty():
		return
	check_callback.call(
		"data_v3_%s_target_preserved" % move_id,
		move.get("target", "") == "all-opponents",
	)
	check_callback.call(
		"data_v3_%s_accuracy_preserved" % move_id,
		int(move.get("accuracy", -999)) == expected_accuracy,
	)
	check_callback.call(
		"data_v3_%s_data_only" % move_id,
		move.get("classification", "") == "DATA_ONLY",
	)
	check_callback.call(
		"data_v3_%s_has_no_unsafe_effect" % move_id,
		(move.get("effect_specs", []) as Array).is_empty(),
	)


func _test_sweet_scent_summary(check_callback: Callable) -> void:
	var move := _load_raw_move("sweet_scent")
	check_callback.call("data_v3_sweet_scent_summary_move_present", not move.is_empty())
	if move.is_empty():
		return
	var summary := String(move.get("effect_summary", "")).to_lower()
	check_callback.call(
		"data_v3_sweet_scent_summary_matches_current_minus_two",
		"two stages" in summary and "evasion" in summary,
	)
	check_callback.call(
		"data_v3_sweet_scent_summary_no_stale_one_stage",
		not ("one stage" in summary),
	)
