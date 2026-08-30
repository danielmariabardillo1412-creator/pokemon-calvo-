class_name BattleRunPresentationTestSuite
extends RefCounted

const HIT := &"run_ui_hit"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _escape_rules := WildEscapeRuleset.new()


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	var normalized := _load_json("res://data/normalized/pokemon_api.json")
	var game_data := GameData.from_dict(normalized) if not normalized.is_empty() else null
	_catalog = game_data.to_definition_catalog() if game_data != null else null
	_check.call("brp_catalog_loaded", _catalog != null)
	if _catalog == null:
		return
	_add_test_move()
	print("BRP_TEST _test_run_control_available_in_active_wild_battle")
	await _test_run_control_available_in_active_wild_battle(tree)
	print("BRP_TEST _test_probabilistic_run_without_rng_is_safe")
	await _test_probabilistic_run_without_rng_is_safe(tree)
	print("BRP_TEST _test_guaranteed_run_needs_no_rng_or_reaction")
	await _test_guaranteed_run_needs_no_rng_or_reaction(tree)
	print("BRP_TEST _test_failed_run_refreshes_battle_presentation")
	await _test_failed_run_refreshes_battle_presentation(tree)
	print("BRP_TEST _test_failed_run_can_present_defeat")
	await _test_failed_run_can_present_defeat(tree)
	print("BRP_TEST _test_run_keeps_capture_rng_and_inventory_separate")
	await _test_run_keeps_capture_rng_and_inventory_separate(tree)
	print("BRP_TEST _test_run_button_signal_uses_canonical_command")
	await _test_run_button_signal_uses_canonical_command(tree)
	print("BRP_TEST _test_technical_scene_run_flow")
	await _test_technical_scene_run_flow(tree)


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


func _add_test_move() -> void:
	if _catalog.move_catalog.has(HIT):
		return
	var move := MoveDefinition.new()
	move.id = HIT
	move.display_name = "Run UI Hit"
	move.power = 40
	move.type_id = &"normal"
	move.priority = 0
	move.damage_class = "physical"
	move.accuracy = -1
	move.pp = 40
	_catalog.add_move(move)


func _creature(instance_id: StringName, species_id: StringName, seed_value: int) -> CreatureInstance:
	var species := _catalog.species_catalog.get_by_id(species_id)
	var creature := CreatureFactory.create(
		species,
		8,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	) if species != null else null
	if creature != null:
		creature.moveset = [BattleMoveSlot.new(HIT, 40, 40)] as Array[BattleMoveSlot]
		creature.move_ids = [HIT] as Array[StringName]
	return creature


func _session(battle_seed: int = 23001) -> WildAdventureSession:
	var collection := PlayerCollection.new()
	collection.party.add_creature(_creature(&"brp_player", &"bulbasaur", 23010 + battle_seed % 31))
	collection.inventory.add(&"poke_ball", 2)
	collection.inventory.add(&"master_ball", 1)
	var session := WildAdventureSession.new(collection, _catalog, _rules)
	var table := WildEncounterTable.new(&"brp_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"brp_pikachu", &"pikachu", 1, 8, 8))
	var encounter := session.begin_encounter(table, _rng(23020 + battle_seed % 29), battle_seed)
	if encounter.status == WildEncounterResult.ENCOUNTER and session.current_wild() != null:
		session.current_wild().moveset = [BattleMoveSlot.new(HIT, 40, 40)] as Array[BattleMoveSlot]
		session.current_wild().move_ids = [HIT] as Array[StringName]
	return session


func _controller(
	tree: SceneTree,
	session: WildAdventureSession,
	capture_rng: RandomNumberGenerator = null,
	escape_rng: RandomNumberGenerator = null,
) -> BattlePresentationController:
	var controller := BattlePresentationController.new()
	tree.root.add_child(controller)
	await tree.process_frame
	controller.configure(session, _catalog, capture_rng, escape_rng)
	controller.open_for_active_battle()
	return controller


func _find_escape_seed(player_speed: int, wild_speed: int, attempt: int, want_success: bool) -> int:
	var odds := _escape_rules.odds(player_speed, wild_speed, attempt)
	for seed_value in range(1, 10000):
		var roll := _rng(seed_value).randi_range(0, WildEscapeRuleset.ROLL_MAX)
		if (roll < odds) == want_success:
			return seed_value
	return -1


func _test_run_control_available_in_active_wild_battle(tree: SceneTree) -> void:
	var session := _session(23101)
	var controller := await _controller(tree, session, _rng(23111), _rng(23112))
	_check.call("brp_control_presenting", controller.is_presenting_battle())
	_check.call("brp_control_visible", controller.run_button_visible())
	_check.call("brp_control_enabled", controller.run_control_enabled())
	_check.call("brp_control_no_attempt_before_press", session.escape_attempts() == 0)
	controller.queue_free()
	await tree.process_frame


func _test_probabilistic_run_without_rng_is_safe(tree: SceneTree) -> void:
	var session := _session(23201)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	var wild_pp := wild.move_slot(HIT).current_pp
	var controller := await _controller(tree, session, _rng(23211), null)
	var result := controller.submit_player_run()
	_check.call("brp_no_rng_rejected", not result.accepted and result.reason == "escape_rng_required")
	_check.call("brp_no_rng_no_turn", session.battle_state().turn == 0)
	_check.call("brp_no_rng_no_attempt", session.escape_attempts() == 0)
	_check.call("brp_no_rng_no_response", wild.move_slot(HIT).current_pp == wild_pp)
	_check.call("brp_no_rng_battle_active", session.has_active_battle() and controller.run_control_enabled())
	controller.queue_free()
	await tree.process_frame


func _test_guaranteed_run_needs_no_rng_or_reaction(tree: SceneTree) -> void:
	var session := _session(23301)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 200
	wild.stats.speed = 20
	# No Escape RNG is injected. Guaranteed escape must remain available because the domain ruleset
	# can resolve it without randomness; presentation must not duplicate those rules.
	var controller := await _controller(tree, session, _rng(23311), null)
	var closed: Array[StringName] = []
	controller.battle_closed.connect(func(reason: StringName): closed.append(reason))
	var wild_pp := wild.move_slot(HIT).current_pp
	var result := controller.submit_player_run()
	_check.call("brp_fast_success", result.succeeded() and result.escape_resolution != null and result.escape_resolution.escaped)
	_check.call("brp_fast_no_rng", not result.escape_resolution.rng_consumed)
	_check.call("brp_fast_completed", result.session_completed and session.status == WildAdventureSession.COMPLETED and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("brp_fast_no_response", result.battle_events.is_empty() and wild.move_slot(HIT).current_pp == wild_pp)
	_check.call("brp_fast_waits_for_continue", controller.visible and not controller.run_control_enabled())
	_check.call("brp_fast_continue", controller.continue_after_completion())
	_check.call("brp_fast_returns_ready", session.status == WildAdventureSession.READY and not controller.visible and closed == [WildAdventureSession.COMPLETED_FLED])
	controller.queue_free()
	await tree.process_frame


func _test_failed_run_refreshes_battle_presentation(tree: SceneTree) -> void:
	var session := _session(23401)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	var failure_seed := _find_escape_seed(1, 200, 1, false)
	var hp_before := player.current_hp
	var wild_pp := wild.move_slot(HIT).current_pp
	var controller := await _controller(tree, session, _rng(23411), _rng(failure_seed))
	var result := controller.submit_player_run()
	_check.call("brp_fail_seed", failure_seed > 0)
	_check.call("brp_fail_accepted", result.succeeded() and result.escape_resolution != null and not result.escape_resolution.escaped)
	_check.call("brp_fail_turn_once", result.turn_consumed and session.battle_state().turn == 1 and session.escape_attempts() == 1)
	_check.call("brp_fail_response_once", wild.move_slot(HIT).current_pp == wild_pp - 1)
	_check.call("brp_fail_damage_refreshed", player.current_hp < hp_before and controller.displayed_player_hp() == player.current_hp)
	_check.call("brp_fail_stays_presenting", session.has_active_battle() and controller.is_presenting_battle())
	_check.call("brp_fail_control_reenabled", controller.run_control_enabled())
	controller.queue_free()
	await tree.process_frame


func _test_failed_run_can_present_defeat(tree: SceneTree) -> void:
	var session := _session(23501)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	player.current_hp = 1
	var failure_seed := _find_escape_seed(1, 200, 1, false)
	var controller := await _controller(tree, session, _rng(23511), _rng(failure_seed))
	var result := controller.submit_player_run()
	_check.call("brp_defeat_failed_escape", result.succeeded() and result.battle_finished and not result.escape_resolution.escaped)
	_check.call("brp_defeat_settled", session.status == WildAdventureSession.COMPLETED and session.completion_reason == WildAdventureSession.COMPLETED_DEFEAT)
	_check.call("brp_defeat_overlay_waits", controller.visible and controller.is_presenting_battle())
	_check.call("brp_defeat_run_disabled", not controller.run_control_enabled())
	_check.call("brp_defeat_continue", controller.continue_after_completion() and session.status == WildAdventureSession.READY and not controller.visible)
	controller.queue_free()
	await tree.process_frame


func _test_run_keeps_capture_rng_and_inventory_separate(tree: SceneTree) -> void:
	var session := _session(23601)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	var failure_seed := _find_escape_seed(1, 200, 1, false)
	var capture_rng := _rng(23611)
	var capture_control := _rng(23611)
	var controller := await _controller(tree, session, capture_rng, _rng(failure_seed))
	var result := controller.submit_player_run()
	_check.call("brp_separate_run_failed", result.succeeded() and not result.escape_resolution.escaped)
	_check.call("brp_separate_capture_rng", is_equal_approx(capture_rng.randf(), capture_control.randf()))
	_check.call("brp_separate_inventory", session.player.inventory.quantity(&"poke_ball") == 2 and session.player.inventory.quantity(&"master_ball") == 1)
	controller.queue_free()
	await tree.process_frame


func _test_run_button_signal_uses_canonical_command(tree: SceneTree) -> void:
	var session := _session(23701)
	session.player_active().stats.speed = 200
	session.current_wild().stats.speed = 20
	var controller := await _controller(tree, session, _rng(23711), null)
	_check.call("brp_button_exists", controller._run_button != null and controller._run_button.visible)
	controller._run_button.pressed.emit()
	_check.call("brp_button_completed_fled", session.status == WildAdventureSession.COMPLETED and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("brp_button_waits_for_confirm", controller.visible and not controller.run_control_enabled())
	controller.queue_free()
	await tree.process_frame


func _test_technical_scene_run_flow(tree: SceneTree) -> void:
	var packed := load("res://scenes/overworld/technical_overworld.tscn") as PackedScene
	_check.call("brp_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	tree.root.add_child(scene)
	await tree.process_frame
	var player := scene.get_node("Player") as OverworldPlayer
	var zone := scene.get_node("EncounterZone") as OverworldEncounterZone
	var controller := scene.get_node("CanvasLayer/BattlePresentation") as BattlePresentationController
	_check.call("brp_scene_ready", scene.call("is_demo_ready"))
	if player != null and zone != null and controller != null:
		player.global_position = zone.global_position
		player.reset_step_meter()
		player.step_distance = 1.0
		player.move_speed = 32.0
		player.apply_motion(Vector2.RIGHT, 0.1)
		_check.call("brp_scene_battle_started", scene.call("has_active_demo_battle") and not player.movement_enabled)
		_check.call("brp_scene_run_control", controller.run_button_visible() and controller.run_control_enabled())
		controller.session.player_active().stats.speed = 999
		controller.session.current_wild().stats.speed = 1
		var result := controller.submit_player_run()
		_check.call("brp_scene_fled", result.succeeded() and result.session_completed and controller.session.completion_reason == WildAdventureSession.COMPLETED_FLED)
		_check.call("brp_scene_still_frozen_until_confirm", not player.movement_enabled and controller.visible)
		_check.call("brp_scene_continue", controller.continue_after_completion())
		_check.call("brp_scene_overworld_resumed", player.movement_enabled and not controller.visible and not scene.call("has_active_demo_battle"))
	scene.queue_free()
	await tree.process_frame
