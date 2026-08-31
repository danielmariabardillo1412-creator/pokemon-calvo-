class_name DataFoundationV3UserStatefulSafeTestSuite
extends RefCounted


const EXPECTED := {
	"charge": {
		"classification": "PARTIAL_RUNTIME",
		"stats": {"special_defense": 1},
	},
	"defense_curl": {
		"classification": "PARTIAL_RUNTIME",
		"stats": {"defense": 1},
	},
	"growth": {
		"classification": "PARTIAL_RUNTIME",
		"stats": {"attack": 1, "special_attack": 1},
	},
	"shell_smash": {
		"classification": "RUNTIME_SUPPORTED",
		"stats": {
			"defense": -1,
			"special_defense": -1,
			"attack": 2,
			"special_attack": 2,
			"speed": 2,
		},
	},
}


func run(check_callback: Callable) -> void:
	for move_id in EXPECTED.keys():
		_test_move(String(move_id), EXPECTED[move_id], check_callback)


func _load_raw_move(move_id: String) -> Dictionary:
	var raw_text := FileAccess.get_file_as_string("res://data/raw/pokemon_api.json")
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {}
	for move in parsed.get("moves", []):
		if move is Dictionary and String(move.get("id", "")) == move_id:
			return move
	return {}


func _test_move(move_id: String, expected: Dictionary, check_callback: Callable) -> void:
	var move := _load_raw_move(move_id)
	check_callback.call("data_v3_%s_present" % move_id, not move.is_empty())
	if move.is_empty():
		return
	check_callback.call(
		"data_v3_%s_target_is_user" % move_id,
		move.get("target", "") == "user",
	)
	check_callback.call(
		"data_v3_%s_is_always_hit" % move_id,
		int(move.get("accuracy", 999)) == -1,
	)
	check_callback.call(
		"data_v3_%s_coverage" % move_id,
		move.get("classification", "") == expected.get("classification", ""),
	)

	var specs: Array = move.get("effect_specs", [])
	var expected_stats: Dictionary = expected.get("stats", {})
	check_callback.call(
		"data_v3_%s_effect_count" % move_id,
		specs.size() == expected_stats.size(),
	)
	if specs.size() != expected_stats.size():
		return

	var actual_stats := {}
	var shape_ok := true
	for spec in specs:
		if not (spec is Dictionary):
			shape_ok = false
			continue
		var stage: Dictionary = spec
		if (
			stage.get("kind", "") != "modify_stat_stage"
			or stage.get("target", "") != "self"
			or int(stage.get("chance_basis_points", 0)) != 10000
		):
			shape_ok = false
		actual_stats[String(stage.get("stat_id", ""))] = int(stage.get("value", 0))
	check_callback.call("data_v3_%s_effect_shape" % move_id, shape_ok)
	check_callback.call("data_v3_%s_exact_stats" % move_id, actual_stats == expected_stats)
