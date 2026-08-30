class_name BattleCapturePresentationTestSuite
extends RefCounted

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	var normalized := _load_json("res://data/normalized/pokemon_api.json")
	var game_data := GameData.from_dict(normalized) if not normalized.is_empty() else null
	_catalog = game_data.to_definition_catalog() if game_data != null else null
	_check.call("bcp_catalog_loaded", _catalog != null)
	if _catalog == null:
		return
	await _test_owned_ball_controls(tree)
	await _test_capture_without_rng_is_safe(tree)
	await _test_invalid_missing_ball_is_not_a_turn(tree)
	await _test_failed_capture_runs_retaliation(tree)
	await _test_master_capture_completes_and_returns(tree)
	await _test_full_party_capture_routes_storage(tree)
	await _test_technical_scene_capture_flow(tree)


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


func _creature(index: int) -> CreatureInstance:
	var creature := CreatureFactory.create(
		_catalog.species_catalog.get_by_id(&"bulbasaur"),
		5,
		_catalog,
		_rules,
		_rng(15000 + index),
		{"instance_id": StringName("bcp_player_%d" % index)},
	)
	if creature != null and _catalog.move(&"tackle") != null:
		var slots: Array[BattleMoveSlot] = [BattleMoveSlot.new(&"tackle", 35, 35)]
		var ids: Array[StringName] = [&"tackle"]
		creature.moveset = slots
		creature.move_ids = ids
	return creature


func _session(
	party_size: int = 1,
	poke_balls: int = 0,
	great_balls: int = 0,
	ultra_balls: int = 0,
	master_balls: int = 0,
	battle_seed: int = 15090,
) -> WildAdventureSession:
	var collection := PlayerCollection.new()
	for i in party_size:
		collection.party.add_creature(_creature(i))
	if poke_balls > 0:
		collection.inventory.add(&"poke_ball", poke_balls)
	if great_balls > 0:
		collection.inventory.add(&"great_ball", great_balls)
	if ultra_balls > 0:
		collection.inventory.add(&"ultra_ball", ultra_balls)
	if master_balls > 0:
		collection.inventory.add(&"master_ball", master_balls)
	# Non-capture inventory must never leak into the capture controls.
	collection.inventory.add(&"potion", 4)
	var session := WildAdventureSession.new(collection, _catalog, _rules)
	var table := WildEncounterTable.new(&"bcp_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"bcp_pikachu", &"pikachu", 1, 4, 4))
	var encounter := session.begin_encounter(table, _rng(15080), battle_seed)
	if encounter.status == WildEncounterResult.ENCOUNTER and session.current_wild() != null and _catalog.move(&"tackle") != null:
		var enemy_slots: Array[BattleMoveSlot] = [BattleMoveSlot.new(&"tackle", 35, 35)]
		var enemy_ids: Array[StringName] = [&"tackle"]
		session.current_wild().moveset = enemy_slots
		session.current_wild().move_ids = enemy_ids
	return session


func _controller(
	tree: SceneTree,
	session: WildAdventureSession,
	capture_rng: RandomNumberGenerator,
) -> BattlePresentationController:
	var controller := BattlePresentationController.new()
	tree.root.add_child(controller)
	await tree.process_frame
	controller.configure(session, _catalog, capture_rng)
	controller.open_for_active_battle()
	return controller


func _find_failure_seed(target: CreatureInstance, ball_id: StringName) -> int:
	var capture_rules := CaptureRuleset.new()
	var species := _catalog.species_catalog.get_by_id(target.species_id)
	var ball := capture_rules.ball(ball_id)
	var probability := capture_rules.catch_probability(
		species.capture_rate,
		ball.base_multiplier,
		capture_rules.status_bonus(target.status_state.persistent_id),
		target.stats.max_hp,
		target.current_hp,
	)
	for seed_value in range(1, 5000):
		if _rng(seed_value).randf() >= probability:
			return seed_value
	return -1


func _count_action_used(events: Array[BattleEvent], actor_id: StringName) -> int:
	var count := 0
	for event in events:
		if event != null and event.kind == BattleEvent.ACTION_USED and event.actor_id == actor_id:
			count += 1
	return count


func _test_owned_ball_controls(tree: SceneTree) -> void:
	var session := _session(1, 2, 1, 0, 1, 15091)
	var controller := await _controller(tree, session, _rng(15100))
	_check.call("bcp_controls_presenting", controller.is_presenting_battle())
	_check.call("bcp_controls_owned_only", controller.available_capture_ball_ids() == [&"poke_ball", &"great_ball", &"master_ball"])
	_check.call("bcp_controls_button_count", controller.capture_button_count() == 3)
	_check.call("bcp_controls_poke_quantity", controller.displayed_capture_quantity(&"poke_ball") == 2)
	_check.call("bcp_controls_great_quantity", controller.displayed_capture_quantity(&"great_ball") == 1)
	_check.call("bcp_controls_master_quantity", controller.displayed_capture_quantity(&"master_ball") == 1)
	_check.call("bcp_controls_non_capture_hidden", not controller.available_capture_ball_ids().has(&"potion"))
	controller.queue_free()
	await tree.process_frame


func _test_capture_without_rng_is_safe(tree: SceneTree) -> void:
	var session := _session(1, 1, 0, 0, 0, 15092)
	var controller := await _controller(tree, session, null)
	var turn_before := session.battle_state().turn
	var result := controller.submit_capture_ball(&"poke_ball")
	_check.call("bcp_no_rng_rejected", not result.accepted and result.reason == "capture_rng_unavailable")
	_check.call("bcp_no_rng_no_turn", session.battle_state().turn == turn_before)
	_check.call("bcp_no_rng_ball_safe", session.player.inventory.quantity(&"poke_ball") == 1)
	_check.call("bcp_no_rng_battle_active", session.has_active_battle())
	controller.queue_free()
	await tree.process_frame


func _test_invalid_missing_ball_is_not_a_turn(tree: SceneTree) -> void:
	var session := _session(1, 1, 0, 0, 0, 15093)
	var capture_rng := _rng(15101)
	var control_rng := _rng(15101)
	var controller := await _controller(tree, session, capture_rng)
	var wild := session.current_wild()
	var wild_pp := wild.move_slot(&"tackle").current_pp
	var result := controller.submit_capture_ball(&"ultra_ball")
	_check.call("bcp_missing_ball_rejected", not result.accepted and result.reason == "item_not_owned")
	_check.call("bcp_missing_ball_no_turn", session.battle_state().turn == 0)
	_check.call("bcp_missing_ball_no_response", wild.move_slot(&"tackle").current_pp == wild_pp and result.battle_events.is_empty())
	_check.call("bcp_missing_ball_rng_safe", is_equal_approx(capture_rng.randf(), control_rng.randf()))
	_check.call("bcp_missing_ball_inventory_unchanged", session.player.inventory.quantity(&"poke_ball") == 1)
	controller.queue_free()
	await tree.process_frame


func _test_failed_capture_runs_retaliation(tree: SceneTree) -> void:
	var session := _session(1, 2, 0, 0, 0, 15094)
	var wild := session.current_wild()
	var player := session.player_active()
	var failure_seed := _find_failure_seed(wild, &"poke_ball")
	var player_hp := player.current_hp
	var player_pp := player.move_slot(&"tackle").current_pp
	var wild_pp := wild.move_slot(&"tackle").current_pp
	var controller := await _controller(tree, session, _rng(failure_seed))
	var result := controller.submit_capture_ball(&"poke_ball")
	_check.call("bcp_fail_seed_found", failure_seed > 0)
	_check.call("bcp_fail_accepted", result.succeeded() and result.capture_outcome != null and result.capture_outcome.resolution.result.status == CaptureResult.FAILED)
	_check.call("bcp_fail_ball_consumed", session.player.inventory.quantity(&"poke_ball") == 1 and controller.displayed_capture_quantity(&"poke_ball") == 1)
	_check.call("bcp_fail_turn_once", result.turn_consumed and session.battle_state().turn == 1)
	_check.call("bcp_fail_exactly_one_response", _count_action_used(result.battle_events, wild.instance_id) == 1)
	_check.call("bcp_fail_enemy_pp", wild.move_slot(&"tackle").current_pp == wild_pp - 1)
	_check.call("bcp_fail_player_pp_safe", player.move_slot(&"tackle").current_pp == player_pp)
	_check.call("bcp_fail_damage_visible", player.current_hp < player_hp and controller.displayed_player_hp() == player.current_hp)
	_check.call("bcp_fail_battle_continues", session.has_active_battle() and controller.is_presenting_battle())
	controller.queue_free()
	await tree.process_frame


func _test_master_capture_completes_and_returns(tree: SceneTree) -> void:
	var session := _session(1, 0, 0, 0, 1, 15095)
	var wild := session.current_wild()
	var wild_id := wild.instance_id
	var wild_pp := wild.move_slot(&"tackle").current_pp
	var controller := await _controller(tree, session, _rng(15102))
	var closed: Array[StringName] = []
	controller.battle_closed.connect(func(reason: StringName): closed.append(reason))
	var result := controller.submit_capture_ball(&"master_ball")
	_check.call("bcp_master_success", result.succeeded() and result.session_completed)
	_check.call("bcp_master_completed_reason", session.status == WildAdventureSession.COMPLETED and session.completion_reason == WildAdventureSession.COMPLETED_CAPTURED)
	_check.call("bcp_master_same_owned_identity", session.player.party.contains_instance_id(wild_id) and session.player.party.get_creature(wild_id) == wild)
	_check.call("bcp_master_ball_consumed", session.player.inventory.quantity(&"master_ball") == 0)
	_check.call("bcp_master_no_retaliation", result.battle_events.is_empty() and wild.move_slot(&"tackle").current_pp == wild_pp)
	_check.call("bcp_master_overlay_waits", controller.visible and controller.is_presenting_battle())
	_check.call("bcp_master_continue", controller.continue_after_completion())
	_check.call("bcp_master_ready", session.status == WildAdventureSession.READY and not controller.visible)
	_check.call("bcp_master_closed_signal", closed == [WildAdventureSession.COMPLETED_CAPTURED])
	controller.queue_free()
	await tree.process_frame


func _test_full_party_capture_routes_storage(tree: SceneTree) -> void:
	var session := _session(6, 0, 0, 0, 1, 15096)
	var wild := session.current_wild()
	var wild_id := wild.instance_id
	var controller := await _controller(tree, session, _rng(15103))
	var result := controller.submit_capture_ball(&"master_ball")
	_check.call("bcp_storage_success", result.succeeded() and result.session_completed)
	_check.call("bcp_storage_party_six", session.player.party.size() == 6)
	_check.call("bcp_storage_same_identity", session.player.storage.contains_instance_id(wild_id) and session.player.storage.get_creature(wild_id) == wild)
	_check.call("bcp_storage_routing_flag", result.capture_outcome != null and result.capture_outcome.routing != null and result.capture_outcome.routing.stored)
	_check.call("bcp_storage_no_response", result.battle_events.is_empty())
	controller.queue_free()
	await tree.process_frame


func _test_technical_scene_capture_flow(tree: SceneTree) -> void:
	var packed := load("res://scenes/overworld/technical_overworld.tscn") as PackedScene
	_check.call("bcp_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	tree.root.add_child(scene)
	await tree.process_frame
	_check.call("bcp_scene_ready", scene.call("is_demo_ready"))
	var player := scene.get_node("Player") as OverworldPlayer
	var zone := scene.get_node("EncounterZone") as OverworldEncounterZone
	var controller := scene.get_node("CanvasLayer/BattlePresentation") as BattlePresentationController
	var party_before := int(scene.call("demo_party_size"))
	_check.call("bcp_scene_controller", controller != null)
	if player != null and zone != null and controller != null:
		_check.call("bcp_scene_demo_inventory", scene.call("demo_inventory_quantity", &"poke_ball") == 3 and scene.call("demo_inventory_quantity", &"master_ball") == 1)
		player.global_position = zone.global_position
		player.reset_step_meter()
		player.step_distance = 1.0
		player.move_speed = 32.0
		player.apply_motion(Vector2.RIGHT, 0.1)
		_check.call("bcp_scene_battle_started", scene.call("has_active_demo_battle") and not player.movement_enabled)
		_check.call("bcp_scene_capture_controls", controller.available_capture_ball_ids() == [&"poke_ball", &"great_ball", &"master_ball"] and controller.capture_button_count() == 3)
		var wild := controller.session.current_wild()
		var wild_id := wild.instance_id if wild != null else &""
		var result := controller.submit_capture_ball(&"master_ball")
		_check.call("bcp_scene_capture_success", result.succeeded() and result.session_completed)
		_check.call("bcp_scene_party_received", wild_id != &"" and controller.session.player.party.contains_instance_id(wild_id) and scene.call("demo_party_size") == party_before + 1)
		_check.call("bcp_scene_still_frozen_until_confirm", not player.movement_enabled and controller.visible)
		_check.call("bcp_scene_continue", controller.continue_after_completion())
		_check.call("bcp_scene_overworld_resumed", player.movement_enabled and not controller.visible and not scene.call("has_active_demo_battle"))
	scene.queue_free()
	await tree.process_frame
