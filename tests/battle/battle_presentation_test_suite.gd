class_name BattlePresentationTestSuite
extends RefCounted

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	var normalized := _load_json("res://data/normalized/pokemon_api.json")
	var game_data := GameData.from_dict(normalized) if not normalized.is_empty() else null
	_catalog = game_data.to_definition_catalog() if game_data != null else null
	_check.call("bp_catalog_loaded", _catalog != null)
	if _catalog == null:
		return
	_test_opponent_policy()
	await _test_controller_active_battle(tree)
	await _test_controller_completion_and_return(tree)
	await _test_technical_scene_transition(tree)


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


func _starter() -> CreatureInstance:
	var creature := CreatureFactory.create(
		_catalog.species_catalog.get_by_id(&"bulbasaur"),
		5,
		_catalog,
		_rules,
		_rng(13001),
		{"instance_id": &"bp_starter"},
	)
	if creature != null and _catalog.move(&"tackle") != null:
		var slots: Array[BattleMoveSlot] = [BattleMoveSlot.new(&"tackle", 35, 35)]
		var ids: Array[StringName] = [&"tackle"]
		creature.moveset = slots
		creature.move_ids = ids
	return creature


func _session(battle_seed: int = 13003) -> WildAdventureSession:
	var collection := PlayerCollection.new()
	var starter := _starter()
	if starter != null:
		collection.party.add_creature(starter)
	var session := WildAdventureSession.new(collection, _catalog, _rules)
	var table := WildEncounterTable.new(&"bp_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"bp_pikachu", &"pikachu", 1, 4, 4))
	var encounter := session.begin_encounter(table, _rng(13002), battle_seed)
	if encounter.status == WildEncounterResult.ENCOUNTER and session.current_wild() != null and _catalog.move(&"tackle") != null:
		var enemy_slots: Array[BattleMoveSlot] = [BattleMoveSlot.new(&"tackle", 35, 35)]
		var enemy_ids: Array[StringName] = [&"tackle"]
		session.current_wild().moveset = enemy_slots
		session.current_wild().move_ids = enemy_ids
	return session


func _test_opponent_policy() -> void:
	var session := _session()
	_check.call("bp_policy_session_active", session.has_active_battle())
	var state := session.battle_state()
	var enemy := session.current_wild()
	var player := session.player_active()
	var before_pp := enemy.move_slot(&"tackle").current_pp
	var action := SimpleBattleOpponentPolicy.choose_move_action(state, &"side_b", _catalog)
	_check.call("bp_policy_action_created", action != null)
	_check.call("bp_policy_actor", action != null and action.actor_id == enemy.instance_id)
	_check.call("bp_policy_target", action != null and action.target_id == player.instance_id)
	_check.call("bp_policy_side", action != null and action.side_id == &"side_b")
	_check.call("bp_policy_turn", action != null and action.turn == state.turn + 1)
	_check.call("bp_policy_move_usable", action != null and action.move_id == &"tackle")
	_check.call("bp_policy_pure_no_pp_mutation", enemy.move_slot(&"tackle").current_pp == before_pp)
	var old_phase := state.phase
	state.phase = BattleState.FINISHED
	_check.call("bp_policy_refuses_finished", SimpleBattleOpponentPolicy.choose_move_action(state, &"side_b", _catalog) == null)
	state.phase = old_phase
	_check.call("bp_policy_refuses_unknown_side", SimpleBattleOpponentPolicy.choose_move_action(state, &"missing", _catalog) == null)


func _test_controller_active_battle(tree: SceneTree) -> void:
	var session := _session(13004)
	var controller := BattlePresentationController.new()
	tree.root.add_child(controller)
	await tree.process_frame
	_check.call("bp_controller_hidden_initially", not controller.visible)
	controller.configure(session, _catalog)
	_check.call("bp_controller_opens", controller.open_for_active_battle())
	_check.call("bp_controller_presenting", controller.is_presenting_battle())
	var moves := controller.available_move_ids()
	_check.call("bp_controller_has_move", moves == [&"tackle"])
	_check.call("bp_controller_button_count", controller.move_button_count() == 1)
	_check.call("bp_controller_player_hp_sync", controller.displayed_player_hp() == session.player_active().current_hp)
	_check.call("bp_controller_enemy_hp_sync", controller.displayed_enemy_hp() == session.current_wild().current_hp)

	var turn_before := session.battle_state().turn
	var pp_before := session.player_active().move_slot(&"tackle").current_pp
	var invalid := controller.submit_player_move(&"not_a_real_move")
	_check.call("bp_invalid_move_no_events", invalid.is_empty())
	_check.call("bp_invalid_move_no_turn", session.battle_state().turn == turn_before)
	_check.call("bp_invalid_move_no_pp", session.player_active().move_slot(&"tackle").current_pp == pp_before)
	_check.call("bp_continue_blocked_mid_battle", not controller.continue_after_completion())

	var events := controller.submit_player_move(&"tackle")
	_check.call("bp_turn_emits_events", not events.is_empty())
	var rejected := false
	for event in events:
		if event.kind == BattleEvent.ACTION_REJECTED:
			rejected = true
			break
	_check.call("bp_turn_authoritative_accept", not rejected)
	_check.call("bp_turn_progressed", session.battle_state() == null or session.battle_state().turn >= 1)
	if session.has_active_battle():
		_check.call("bp_post_turn_player_hp_sync", controller.displayed_player_hp() == session.player_active().current_hp)
		_check.call("bp_post_turn_enemy_hp_sync", controller.displayed_enemy_hp() == session.current_wild().current_hp)
	else:
		_check.call("bp_post_turn_player_hp_sync", true)
		_check.call("bp_post_turn_enemy_hp_sync", true)
	controller.queue_free()
	await tree.process_frame


func _test_controller_completion_and_return(tree: SceneTree) -> void:
	var session := _session(13005)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 999
	wild.current_hp = 1
	var controller := BattlePresentationController.new()
	tree.root.add_child(controller)
	await tree.process_frame
	controller.configure(session, _catalog)
	_check.call("bp_finish_open", controller.open_for_active_battle())
	var closed_reason: Array[StringName] = []
	controller.battle_closed.connect(func(reason: StringName): closed_reason.append(reason))
	var events := controller.submit_player_move(&"tackle")
	_check.call("bp_finish_events", not events.is_empty())
	_check.call("bp_finish_session_completed", session.status == WildAdventureSession.COMPLETED)
	_check.call("bp_finish_reason_victory", session.completion_reason == WildAdventureSession.COMPLETED_VICTORY)
	_check.call("bp_finish_overlay_stays_for_continue", controller.visible and controller.is_presenting_battle())
	_check.call("bp_finish_continue_success", controller.continue_after_completion())
	_check.call("bp_finish_session_ready", session.status == WildAdventureSession.READY)
	_check.call("bp_finish_overlay_hidden", not controller.visible)
	_check.call("bp_finish_signal_reason", closed_reason == [WildAdventureSession.COMPLETED_VICTORY])
	controller.queue_free()
	await tree.process_frame


func _test_technical_scene_transition(tree: SceneTree) -> void:
	var packed := load("res://scenes/overworld/technical_overworld.tscn") as PackedScene
	_check.call("bp_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	tree.root.add_child(scene)
	await tree.process_frame
	_check.call("bp_scene_bootstrap", scene.call("is_demo_ready"))
	var player := scene.get_node("Player") as OverworldPlayer
	var zone := scene.get_node("EncounterZone") as OverworldEncounterZone
	var controller := scene.get_node("CanvasLayer/BattlePresentation") as BattlePresentationController
	_check.call("bp_scene_controller_present", controller != null)
	if player != null and zone != null and controller != null:
		player.global_position = zone.global_position
		player.reset_step_meter()
		player.step_distance = 1.0
		player.move_speed = 32.0
		player.apply_motion(Vector2.RIGHT, 0.1)
		_check.call("bp_scene_real_battle_active", scene.call("has_active_demo_battle"))
		_check.call("bp_scene_overlay_visible", scene.call("is_battle_presentation_visible"))
		_check.call("bp_scene_overworld_frozen", not player.movement_enabled)
		_check.call("bp_scene_move_controls_visible", controller.move_button_count() > 0)
	scene.queue_free()
	await tree.process_frame
