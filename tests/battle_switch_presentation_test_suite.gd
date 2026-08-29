class_name BattleSwitchPresentationTestSuite
extends RefCounted

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	var normalized := _load_json("res://data/normalized/pokemon_api.json")
	var game_data := GameData.from_dict(normalized) if not normalized.is_empty() else null
	_catalog = game_data.to_definition_catalog() if game_data != null else null
	_check.call("bsp_catalog_loaded", _catalog != null)
	if _catalog == null:
		return
	await _test_switch_choices_are_authoritative(tree)
	await _test_single_member_has_no_switch(tree)
	await _test_elective_switch_consumes_normal_turn(tree)
	await _test_invalid_switch_is_rejected_without_mutation(tree)
	await _test_ko_switch_target_is_rejected_and_hidden(tree)
	await _test_forced_switch_after_retaliation_refreshes_presentation(tree)
	await _test_technical_scene_switch_flow(tree)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _creature(
	instance_id: StringName,
	species_id: StringName,
	seed_value: int,
) -> CreatureInstance:
	var species := _catalog.species_catalog.get_by_id(species_id)
	var creature := CreatureFactory.create(
		species,
		5,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	) if species != null else null
	if creature != null and _catalog.move(&"tackle") != null:
		creature.moveset = [BattleMoveSlot.new(&"tackle", 35, 35)] as Array[BattleMoveSlot]
		creature.move_ids = [&"tackle"] as Array[StringName]
	return creature


func _session(
	party: Array[CreatureInstance],
	battle_seed: int,
) -> WildAdventureSession:
	var collection := PlayerCollection.new()
	for creature in party:
		if creature != null:
			collection.party.add_creature(creature)
	collection.inventory.add(&"poke_ball", 1)
	collection.inventory.add(&"master_ball", 1)
	var session := WildAdventureSession.new(collection, _catalog, _rules)
	var table := WildEncounterTable.new(&"bsp_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"bsp_pikachu", &"pikachu", 1, 4, 4))
	var encounter := session.begin_encounter(table, _rng(17000 + battle_seed), battle_seed)
	if encounter.status == WildEncounterResult.ENCOUNTER and session.current_wild() != null:
		session.current_wild().moveset = [BattleMoveSlot.new(&"tackle", 35, 35)] as Array[BattleMoveSlot]
		session.current_wild().move_ids = [&"tackle"] as Array[StringName]
	return session


func _controller(
	tree: SceneTree,
	session: WildAdventureSession,
	capture_rng: RandomNumberGenerator = null,
) -> BattlePresentationController:
	var controller := BattlePresentationController.new()
	tree.root.add_child(controller)
	await tree.process_frame
	controller.configure(session, _catalog, capture_rng if capture_rng != null else _rng(17999))
	controller.open_for_active_battle()
	return controller


func _find_failure_seed(target: CreatureInstance, ball_id: StringName) -> int:
	var rules := CaptureRuleset.new()
	var species := _catalog.species_catalog.get_by_id(target.species_id)
	var ball := rules.ball(ball_id)
	var p := rules.catch_probability(
		species.capture_rate,
		ball.base_multiplier,
		rules.status_bonus(target.status_state.persistent_id),
		target.stats.max_hp,
		target.current_hp,
	)
	for seed_value in range(1, 5000):
		if _rng(seed_value).randf() >= p:
			return seed_value
	return -1


func _first(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event != null and event.kind == kind:
			return event
	return null


func _event_index(events: Array[BattleEvent], needle: BattleEvent) -> int:
	for i in events.size():
		if events[i] == needle:
			return i
	return -1


func _test_switch_choices_are_authoritative(tree: SceneTree) -> void:
	var active := _creature(&"bsp_active", &"bulbasaur", 17101)
	var bench_a := _creature(&"bsp_bench_a", &"charmander", 17102)
	var bench_b := _creature(&"bsp_bench_b", &"squirtle", 17103)
	var knocked_out := _creature(&"bsp_ko", &"pikachu", 17104)
	knocked_out.current_hp = 0
	var session := _session([active, bench_a, bench_b, knocked_out] as Array[CreatureInstance], 17110)
	var controller := await _controller(tree, session)
	_check.call("bsp_choices_active_is_first_living", session.player_active() == active)
	_check.call("bsp_choices_preserve_living_party_order", controller.available_switch_instance_ids() == [&"bsp_bench_a", &"bsp_bench_b"])
	_check.call("bsp_choices_selector_count", controller.switch_option_count() == 2)
	_check.call("bsp_choices_control_enabled", controller.switch_control_enabled())
	_check.call("bsp_choices_metadata_first", controller.selected_switch_instance_id() == &"bsp_bench_a")
	controller._switch_selector.select(1)
	_check.call("bsp_choices_metadata_second", controller.selected_switch_instance_id() == &"bsp_bench_b")
	_check.call("bsp_choices_ko_not_selected", controller.selected_switch_instance_id() != knocked_out.instance_id)
	controller.queue_free()
	await tree.process_frame


func _test_single_member_has_no_switch(tree: SceneTree) -> void:
	var only := _creature(&"bsp_only", &"bulbasaur", 17201)
	var session := _session([only] as Array[CreatureInstance], 17210)
	var controller := await _controller(tree, session)
	_check.call("bsp_single_choices_empty", controller.available_switch_instance_ids().is_empty())
	_check.call("bsp_single_selector_empty", controller.switch_option_count() == 0)
	_check.call("bsp_single_control_disabled", not controller.switch_control_enabled())
	controller.queue_free()
	await tree.process_frame


func _test_elective_switch_consumes_normal_turn(tree: SceneTree) -> void:
	var outgoing := _creature(&"bsp_outgoing", &"bulbasaur", 17301)
	var incoming := _creature(&"bsp_incoming", &"charmander", 17302)
	var session := _session([outgoing, incoming] as Array[CreatureInstance], 17310)
	var wild := session.current_wild()
	var wild_pp_before := wild.move_slot(&"tackle").current_pp
	var outgoing_hp_before := outgoing.current_hp
	var incoming_hp_before := incoming.current_hp
	var capture_rng := _rng(17399)
	var capture_control_rng := _rng(17399)
	outgoing.stat_stages.change(StatStages.ATTACK, 2)
	outgoing.status_state.add_volatile(&"bsp_marker")
	var controller := await _controller(tree, session, capture_rng)
	var result := controller.submit_player_switch(incoming.instance_id)
	var switched := _first(result.battle_events, BattleEvent.SWITCHED)
	var enemy_used := _first(result.battle_events, BattleEvent.ACTION_USED)
	_check.call("bsp_switch_accepted", result.succeeded() and result.turn_consumed)
	_check.call("bsp_switch_turn_once", session.battle_state().turn == 1)
	_check.call("bsp_switch_active_changed", session.player_active() == incoming)
	_check.call("bsp_switch_event_elective", switched != null and not bool(switched.metadata.get("forced", true)))
	_check.call("bsp_switch_priority_before_move", switched != null and enemy_used != null and _event_index(result.battle_events, switched) < _event_index(result.battle_events, enemy_used))
	_check.call("bsp_switch_enemy_response_once", wild.move_slot(&"tackle").current_pp == wild_pp_before - 1)
	_check.call("bsp_switch_outgoing_not_hit", outgoing.current_hp == outgoing_hp_before)
	_check.call("bsp_switch_incoming_takes_response", incoming.current_hp < incoming_hp_before and controller.displayed_player_hp() == incoming.current_hp)
	_check.call("bsp_switch_clears_stages", outgoing.stat_stages.get_stage(StatStages.ATTACK) == 0)
	_check.call("bsp_switch_clears_volatile", outgoing.status_state.volatile.is_empty())
	_check.call("bsp_switch_old_active_becomes_choice", controller.available_switch_instance_ids() == [&"bsp_outgoing"])
	_check.call("bsp_switch_inventory_untouched", session.player.inventory.quantity(&"master_ball") == 1 and session.player.inventory.quantity(&"poke_ball") == 1)
	_check.call("bsp_switch_capture_rng_untouched", is_equal_approx(capture_rng.randf(), capture_control_rng.randf()))
	controller.queue_free()
	await tree.process_frame


func _test_invalid_switch_is_rejected_without_mutation(tree: SceneTree) -> void:
	var active := _creature(&"bsp_invalid_active", &"bulbasaur", 17401)
	var bench := _creature(&"bsp_invalid_bench", &"charmander", 17402)
	var session := _session([active, bench] as Array[CreatureInstance], 17410)
	var wild := session.current_wild()
	var wild_pp_before := wild.move_slot(&"tackle").current_pp
	var controller := await _controller(tree, session)
	var result := controller.submit_player_switch(&"not_owned")
	_check.call("bsp_invalid_rejected", not result.accepted and result.reason == "invalid_switch")
	_check.call("bsp_invalid_no_turn", session.battle_state().turn == 0)
	_check.call("bsp_invalid_active_unchanged", session.player_active() == active)
	_check.call("bsp_invalid_no_response", wild.move_slot(&"tackle").current_pp == wild_pp_before)
	controller.queue_free()
	await tree.process_frame


func _test_ko_switch_target_is_rejected_and_hidden(tree: SceneTree) -> void:
	var active := _creature(&"bsp_ko_active", &"bulbasaur", 17501)
	var knocked_out := _creature(&"bsp_ko_bench", &"charmander", 17502)
	knocked_out.current_hp = 0
	var session := _session([active, knocked_out] as Array[CreatureInstance], 17510)
	var controller := await _controller(tree, session)
	var result := controller.submit_player_switch(knocked_out.instance_id)
	_check.call("bsp_ko_hidden", controller.available_switch_instance_ids().is_empty() and controller.switch_option_count() == 0)
	_check.call("bsp_ko_rejected", not result.accepted and result.reason == "switch_target_unavailable")
	_check.call("bsp_ko_no_turn", session.battle_state().turn == 0 and session.player_active() == active)
	controller.queue_free()
	await tree.process_frame


func _test_forced_switch_after_retaliation_refreshes_presentation(tree: SceneTree) -> void:
	var outgoing := _creature(&"bsp_forced_out", &"bulbasaur", 17601)
	var replacement := _creature(&"bsp_forced_in", &"charmander", 17602)
	var session := _session([outgoing, replacement] as Array[CreatureInstance], 17610)
	outgoing.current_hp = 1
	var wild := session.current_wild()
	var failure_seed := _find_failure_seed(wild, &"poke_ball")
	var controller := await _controller(tree, session, _rng(failure_seed))
	var result := controller.submit_capture_ball(&"poke_ball")
	var switched := _first(result.battle_events, BattleEvent.SWITCHED)
	_check.call("bsp_forced_seed_found", failure_seed > 0)
	_check.call("bsp_forced_capture_failed", result.succeeded() and result.capture_outcome != null and result.capture_outcome.resolution.result.status == CaptureResult.FAILED)
	_check.call("bsp_forced_ball_consumed", session.player.inventory.quantity(&"poke_ball") == 0)
	_check.call("bsp_forced_outgoing_ko", outgoing.is_knocked_out())
	_check.call("bsp_forced_active_replacement", session.player_active() == replacement)
	_check.call("bsp_forced_event", switched != null and bool(switched.metadata.get("forced", false)) and switched.actor_id == outgoing.instance_id and switched.target_id == replacement.instance_id)
	_check.call("bsp_forced_battle_continues", session.has_active_battle() and session.status == WildAdventureSession.ACTIVE)
	_check.call("bsp_forced_display_refresh", controller.displayed_player_hp() == replacement.current_hp)
	_check.call("bsp_forced_no_ko_choice", controller.available_switch_instance_ids().is_empty() and controller.switch_option_count() == 0)
	controller.queue_free()
	await tree.process_frame


func _test_technical_scene_switch_flow(tree: SceneTree) -> void:
	var packed := load("res://scenes/overworld/technical_overworld.tscn") as PackedScene
	_check.call("bsp_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	tree.root.add_child(scene)
	await tree.process_frame
	var player := scene.get_node("Player") as OverworldPlayer
	var zone := scene.get_node("EncounterZone") as OverworldEncounterZone
	var controller := scene.get_node("CanvasLayer/BattlePresentation") as BattlePresentationController
	_check.call("bsp_scene_ready", scene.call("is_demo_ready") and scene.call("demo_party_size") == 2)
	if player != null and zone != null and controller != null:
		player.global_position = zone.global_position
		player.reset_step_meter()
		player.step_distance = 1.0
		player.move_speed = 32.0
		player.apply_motion(Vector2.RIGHT, 0.1)
		_check.call("bsp_scene_battle_started", scene.call("has_active_demo_battle") and not player.movement_enabled)
		_check.call("bsp_scene_bench_offered", controller.available_switch_instance_ids() == [&"technical_bench"] and controller.switch_option_count() == 1 and controller.selected_switch_instance_id() == &"technical_bench")
		var switch_result := controller.submit_player_switch(&"technical_bench")
		_check.call("bsp_scene_switch_success", switch_result.succeeded() and controller.session.player_active().instance_id == &"technical_bench")
		_check.call("bsp_scene_stays_frozen", not player.movement_enabled and controller.visible)
		var capture_result := controller.submit_capture_ball(&"master_ball")
		_check.call("bsp_scene_capture_after_switch", capture_result.succeeded() and capture_result.session_completed)
		_check.call("bsp_scene_continue", controller.continue_after_completion())
		_check.call("bsp_scene_overworld_resumed", player.movement_enabled and not controller.visible)
	scene.queue_free()
	await tree.process_frame
