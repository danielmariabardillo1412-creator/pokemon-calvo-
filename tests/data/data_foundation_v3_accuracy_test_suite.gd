class_name DataFoundationV3AccuracyTestSuite
extends RefCounted


func run(check_callback: Callable) -> void:
	var always_hit_ids := [
		"confide",
		"play_nice",
		"tearful_look",
		"decorate",
		"spicy_extract",
	]
	for move_id in always_hit_ids:
		var move := _load_raw_move(move_id)
		check_callback.call("data_v3_%s_accuracy_record_present" % move_id, not move.is_empty())
		if move.is_empty():
			continue
		check_callback.call(
			"data_v3_%s_null_accuracy_maps_to_always_hit" % move_id,
			int(move.get("accuracy", 100)) == -1,
		)
		var definition := MoveDefinition.from_dict(move)
		check_callback.call(
			"data_v3_%s_move_definition_preserves_always_hit" % move_id,
			definition.accuracy == -1,
		)

	var charm := _load_raw_move("charm")
	check_callback.call("data_v3_charm_accuracy_control_present", not charm.is_empty())
	if not charm.is_empty():
		check_callback.call(
			"data_v3_charm_real_100_accuracy_is_preserved",
			int(charm.get("accuracy", -1)) == 100,
		)

	var ruleset := BattleRuleset.new()
	check_callback.call(
		"battle_ruleset_always_hit_ignores_extreme_accuracy_evasion",
		ruleset.accuracy_threshold_basis_points(-1, -6, 6) == 10000,
	)
	check_callback.call(
		"battle_ruleset_real_100_accuracy_remains_stage_sensitive",
		ruleset.accuracy_threshold_basis_points(100, -6, 6) < 10000,
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
