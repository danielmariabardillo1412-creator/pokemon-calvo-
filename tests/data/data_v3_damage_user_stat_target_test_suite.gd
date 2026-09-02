class_name DataV3DamageUserStatTargetTestSuite
extends RefCounted

var _check: Callable
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	var file := FileAccess.open("res://data/normalized/pokemon_api.json", FileAccess.READ)
	_expect("data_v3_self_debuff_dataset_open", file != null)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	_expect("data_v3_self_debuff_dataset_parse", parsed is Dictionary)
	if not (parsed is Dictionary):
		return
	var game_data := GameData.from_dict(parsed)
	var catalog := game_data.to_definition_catalog()
	var move := catalog.move(&"close_combat")
	_expect("data_v3_close_combat_present", move != null)
	if move == null:
		return

	var stages: Array[BattleEffectSpec] = []
	_collect_stat_stages(move.effect_specs, stages)
	_expect("data_v3_close_combat_has_two_stat_changes", stages.size() == 2)
	var all_self := stages.size() == 2
	var has_defense := false
	var has_special_defense := false
	for stage in stages:
		all_self = all_self and stage.target == BattleEffectSpec.SELF
		if stage.stat_id == &"defense" and stage.value == -1:
			has_defense = true
		if stage.stat_id == &"special_defense" and stage.value == -1:
			has_special_defense = true
	_expect("data_v3_close_combat_specs_target_self", all_self)
	_expect("data_v3_close_combat_specs_match_cost", has_defense and has_special_defense)

	# End-to-end Battle Core regression: executing the real DATA V3 move must lower
	# the user's stages and must not debuff the target.
	var state := BattleState.new(&"data_v3_self_debuff", [
		CreatureInstance.new(
			&"a", &"charmander", 30,
			StatBlock.new(220, 80, 70, 40, 60, 70),
			[&"close_combat"],
		),
		CreatureInstance.new(
			&"b", &"squirtle", 30,
			StatBlock.new(1000, 60, 120, 20, 60, 120),
			[&"tackle"],
		),
	], 91021)
	var server := AuthoritativeBattleServer.new(state, catalog)
	var events := server.submit_turn([
		_client.request_move(1, &"a", &"close_combat", &"b", &"side_a"),
		_client.request_move(1, &"b", &"tackle", &"a", &"side_b"),
	])
	var actor := server.state.creature(&"a")
	var target := server.state.creature(&"b")
	_expect(
		"data_v3_close_combat_runtime_lowers_user",
		actor.stat_stages.get_stage(&"defense") == -1
		and actor.stat_stages.get_stage(&"special_defense") == -1,
	)
	_expect(
		"data_v3_close_combat_runtime_does_not_debuff_target",
		target.stat_stages.get_stage(&"defense") == 0
		and target.stat_stages.get_stage(&"special_defense") == 0,
	)
	var self_stage_events := 0
	var target_stage_events := 0
	for event in events:
		if event.kind == BattleEvent.STAT_STAGE_CHANGED and event.target_id == &"a":
			self_stage_events += 1
		if event.kind == BattleEvent.STAT_STAGE_CHANGED and event.target_id == &"b":
			target_stage_events += 1
	_expect("data_v3_close_combat_runtime_emits_two_self_stage_events", self_stage_events == 2)
	_expect("data_v3_close_combat_runtime_emits_no_target_stage_event", target_stage_events == 0)


func _collect_stat_stages(
	specs: Array[BattleEffectSpec], out: Array[BattleEffectSpec]
) -> void:
	for spec in specs:
		if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
			out.append(spec)
		_collect_stat_stages(spec.children, out)


func _expect(name: String, condition: bool) -> void:
	_check.call(name, condition)
