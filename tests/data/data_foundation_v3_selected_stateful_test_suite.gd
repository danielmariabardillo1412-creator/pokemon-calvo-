class_name DataFoundationV3SelectedStatefulTestSuite
extends RefCounted


func run(check_callback: Callable) -> void:
	_test_data_only_neutralized("defog", -1, check_callback)
	_test_data_only_neutralized("memento", 100, check_callback)
	_test_data_only_neutralized("parting_shot", 100, check_callback)
	_test_tar_shot_partial(check_callback)


func _load_raw_move(move_id: String) -> Dictionary:
	var raw_text := FileAccess.get_file_as_string("res://data/raw/pokemon_api.json")
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {}
	for move in parsed.get("moves", []):
		if move is Dictionary and String(move.get("id", "")) == move_id:
			return move
	return {}


func _test_data_only_neutralized(
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
		move.get("target", "") == "selected-pokemon",
	)
	check_callback.call(
		"data_v3_%s_accuracy_preserved" % move_id,
		int(move.get("accuracy", 999)) == expected_accuracy,
	)
	check_callback.call(
		"data_v3_%s_is_data_only" % move_id,
		move.get("classification", "") == "DATA_ONLY",
	)
	check_callback.call(
		"data_v3_%s_has_no_unsafe_partial_effect" % move_id,
		(move.get("effect_specs", []) as Array).is_empty(),
	)


func _test_tar_shot_partial(check_callback: Callable) -> void:
	var move := _load_raw_move("tar_shot")
	check_callback.call("data_v3_tar_shot_present", not move.is_empty())
	if move.is_empty():
		return
	check_callback.call("data_v3_tar_shot_target_preserved", move.get("target", "") == "selected-pokemon")
	check_callback.call("data_v3_tar_shot_accuracy_preserved", int(move.get("accuracy", 0)) == 100)
	check_callback.call("data_v3_tar_shot_is_partial", move.get("classification", "") == "PARTIAL_RUNTIME")
	var specs: Array = move.get("effect_specs", [])
	check_callback.call("data_v3_tar_shot_has_one_safe_subset_effect", specs.size() == 1)
	if specs.size() != 1 or not (specs[0] is Dictionary):
		return
	var stage: Dictionary = specs[0]
	check_callback.call("data_v3_tar_shot_subset_is_speed_drop", stage.get("kind", "") == "modify_stat_stage" and stage.get("target", "") == "opponent" and stage.get("stat_id", "") == "speed" and int(stage.get("value", 0)) == -1 and int(stage.get("chance_basis_points", 0)) == 10000)
