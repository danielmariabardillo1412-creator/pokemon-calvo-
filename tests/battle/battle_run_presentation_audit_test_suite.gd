class_name BattleRunPresentationAuditTestSuite
extends RefCounted

const HIT := &"run_ui_audit_hit"

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()
var _escape_rules := WildEscapeRuleset.new()


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	var normalized := _load_json("res://data/normalized/pokemon_api.json")
	var game_data := GameData.from_dict(normalized) if not normalized.is_empty() else null
	_catalog = game_data.to_definition_catalog() if game_data != null else null
	_check.call("brp_audit_catalog_loaded", _catalog != null)
	if _catalog == null:
		return
	_add_test_move()
	print("BRP_AUDIT _test_guaranteed_run_without_opponent_action")
	await _test_guaranteed_run_without_opponent_action(tree)
	print("BRP_AUDIT _test_probabilistic_run_without_opponent_action_is_safe")
	await _test_probabilistic_run_without_opponent_action_is_safe(tree)
	print("BRP_AUDIT _test_invalid_speed_is_side_effect_free")
	await _test_invalid_speed_is_side_effect_free(tree)
	print("BRP_AUDIT _test_repeated_failed_runs_keep_presentation_coherent")
	await _test_repeated_failed_runs_keep_presentation_coherent(tree)
	print("BRP_AUDIT _test_failed_run_then_capture")
	await _test_failed_run_then_capture(tree)
	print("BRP_AUDIT _test_failed_capture_then_run")
	await _test_failed_capture_then_run(tree)
	print("BRP_AUDIT _test_switch_then_run_uses_current_active")
	await _test_switch_then_run_uses_current_active(tree)
	print("BRP_AUDIT _test_fled_signal_and_reopen_lifecycle")
	await _test_fled_signal_and_reopen_lifecycle(tree)
	print("BRP_AUDIT _test_public_run_after_completion_is_safe")
	await _test_public_run_after_completion_is_safe(tree)


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
	move.display_name = "Run UI Audit Hit"
	move.power = 35
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
		10,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	) if species != null else null
	if creature != null:
		creature.moveset = [BattleMoveSlot.new(HIT, 40, 40)] as Array[BattleMoveSlot]
		creature.move_ids = [HIT] as Array[StringName]
	return creature


func _session(
	battle_seed: int,
	party: Array[CreatureInstance] = [],
) -> WildAdventureSession:
	var collection := PlayerCollection.new()
	if party.is_empty():
		party = [_creature(&"brpa_player", &"bulbasaur", 24000 + battle_seed % 37)] as Array[CreatureInstance]
	for creature in party:
		if creature != null:
			collection.party.add_creature(creature)
	collection.inventory.add(&"poke_ball", 2)
	collection.inventory.add(&"master_ball", 1)
	var session := WildAdventureSession.new(collection, _catalog, _rules)
	var table := _table()
	var encounter := session.begin_encounter(table, _rng(24100 + battle_seed % 41), battle_seed)
	if encounter.status == WildEncounterResult.ENCOUNTER and session.current_wild() != null:
		session.current_wild().moveset = [BattleMoveSlot.new(HIT, 40, 40)] as Array[BattleMoveSlot]
		session.current_wild().move_ids = [HIT] as Array[StringName]
	return session


func _table() -> WildEncounterTable:
	var table := WildEncounterTable.new(&"brpa_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"brpa_pikachu", &"pikachu", 1, 10, 10))
	return table


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


func _find_capture_failure_seed(target: CreatureInstance, ball_id: StringName) -> int:
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
	for seed_value in range(1, 10000):
		if _rng(seed_value).randf() >= probability:
			return seed_value
	return -1


func _test_guaranteed_run_without_opponent_action(tree: SceneTree) -> void:
	var session := _session(24101)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 999
	wild.stats.speed = 1
	wild.moveset = [] as Array[BattleMoveSlot]
	wild.move_ids = [] as Array[StringName]
	var controller := await _controller(tree, session, _rng(24111), null)
	var result := controller.submit_player_run()
	_check.call("brp_audit_guaranteed_no_response_success", result.succeeded() and result.session_completed)
	_check.call("brp_audit_guaranteed_no_response_fled", session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("brp_audit_guaranteed_no_response_rng_free", result.escape_resolution != null and not result.escape_resolution.rng_consumed)
	_check.call("brp_audit_guaranteed_no_response_events_empty", result.battle_events.is_empty())
	controller.queue_free()
	await tree.process_frame


func _test_probabilistic_run_without_opponent_action_is_safe(tree: SceneTree) -> void:
	var session := _session(24201)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	wild.moveset = [] as Array[BattleMoveSlot]
	wild.move_ids = [] as Array[StringName]
	var escape_rng := _rng(24211)
	var control_rng := _rng(24211)
	var controller := await _controller(tree, session, _rng(24212), escape_rng)
	var result := controller.submit_player_run()
	_check.call("brp_audit_prob_no_response_rejected", not result.accepted and result.reason.begins_with("invalid_opponent_response:"))
	_check.call("brp_audit_prob_no_response_no_turn", session.battle_state().turn == 0)
	_check.call("brp_audit_prob_no_response_no_attempt", session.escape_attempts() == 0)
	_check.call("brp_audit_prob_no_response_rng_safe", escape_rng.randi() == control_rng.randi())
	_check.call("brp_audit_prob_no_response_control_alive", controller.run_control_enabled() and session.has_active_battle())
	controller.queue_free()
	await tree.process_frame


func _test_invalid_speed_is_side_effect_free(tree: SceneTree) -> void:
	var session := _session(24301)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 0
	wild.stats.speed = 50
	var escape_rng := _rng(24311)
	var control_rng := _rng(24311)
	var wild_pp := wild.move_slot(HIT).current_pp
	var controller := await _controller(tree, session, _rng(24312), escape_rng)
	var result := controller.submit_player_run()
	_check.call("brp_audit_bad_speed_reason", not result.accepted and result.reason == "invalid_escape_speed")
	_check.call("brp_audit_bad_speed_no_turn_attempt", session.battle_state().turn == 0 and session.escape_attempts() == 0)
	_check.call("brp_audit_bad_speed_rng_safe", escape_rng.randi() == control_rng.randi())
	_check.call("brp_audit_bad_speed_no_response", wild.move_slot(HIT).current_pp == wild_pp)
	_check.call("brp_audit_bad_speed_control_alive", controller.run_control_enabled() and session.has_active_battle())
	controller.queue_free()
	await tree.process_frame


func _test_repeated_failed_runs_keep_presentation_coherent(tree: SceneTree) -> void:
	var session := _session(24401)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	player.current_hp = player.stats.max_hp
	var fail_seed_1 := _find_escape_seed(1, 200, 1, false)
	var controller := await _controller(tree, session, _rng(24411), _rng(fail_seed_1))
	var first := controller.submit_player_run()
	var first_odds := first.escape_resolution.odds if first.escape_resolution != null else -1
	_check.call("brp_audit_repeat_first_failed", first.succeeded() and first.escape_resolution != null and not first.escape_resolution.escaped)
	_check.call("brp_audit_repeat_first_state", session.escape_attempts() == 1 and session.battle_state().turn == 1 and controller.run_control_enabled())
	if session.has_active_battle():
		controller._escape_rng = _rng(_find_escape_seed(1, 200, 2, false))
		var second := controller.submit_player_run()
		_check.call("brp_audit_repeat_second_failed", second.succeeded() and second.escape_resolution != null and not second.escape_resolution.escaped)
		_check.call("brp_audit_repeat_second_state", session.escape_attempts() == 2 and session.battle_state().turn == 2)
		_check.call("brp_audit_repeat_odds_grow", second.escape_resolution.odds == first_odds + WildEscapeRuleset.ATTEMPT_BONUS)
		_check.call("brp_audit_repeat_display_sync", controller.displayed_player_hp() == session.player_active().current_hp)
		_check.call("brp_audit_repeat_control_coherent", session.has_active_battle() == controller.run_control_enabled())
	else:
		_check.call("brp_audit_repeat_second_failed", false)
		_check.call("brp_audit_repeat_second_state", false)
		_check.call("brp_audit_repeat_odds_grow", false)
		_check.call("brp_audit_repeat_display_sync", false)
		_check.call("brp_audit_repeat_control_coherent", false)
	controller.queue_free()
	await tree.process_frame


func _test_failed_run_then_capture(tree: SceneTree) -> void:
	var session := _session(24501)
	var player := session.player_active()
	var wild := session.current_wild()
	player.stats.speed = 1
	wild.stats.speed = 200
	var fail_seed := _find_escape_seed(1, 200, 1, false)
	var controller := await _controller(tree, session, _rng(24511), _rng(fail_seed))
	var run_result := controller.submit_player_run()
	_check.call("brp_audit_run_then_capture_run_failed", run_result.succeeded() and not run_result.escape_resolution.escaped)
	_check.call("brp_audit_run_then_capture_inventory_intact", session.player.inventory.quantity(&"master_ball") == 1)
	if session.has_active_battle():
		var wild_id := session.current_wild().instance_id
		var capture_result := controller.submit_capture_ball(&"master_ball")
		_check.call("brp_audit_run_then_capture_success", capture_result.succeeded() and capture_result.session_completed)
		_check.call("brp_audit_run_then_capture_reason", session.completion_reason == WildAdventureSession.COMPLETED_CAPTURED)
		_check.call("brp_audit_run_then_capture_identity", session.player.party.contains_instance_id(wild_id))
		_check.call("brp_audit_run_then_capture_controls_locked", not controller.run_control_enabled())
	else:
		_check.call("brp_audit_run_then_capture_success", false)
		_check.call("brp_audit_run_then_capture_reason", false)
		_check.call("brp_audit_run_then_capture_identity", false)
		_check.call("brp_audit_run_then_capture_controls_locked", false)
	controller.queue_free()
	await tree.process_frame


func _test_failed_capture_then_run(tree: SceneTree) -> void:
	var session := _session(24601)
	var wild := session.current_wild()
	var failure_seed := _find_capture_failure_seed(wild, &"poke_ball")
	var controller := await _controller(tree, session, _rng(failure_seed), null)
	var capture_result := controller.submit_capture_ball(&"poke_ball")
	_check.call("brp_audit_capture_then_run_seed", failure_seed > 0)
	_check.call("brp_audit_capture_then_run_capture_failed", capture_result.succeeded() and capture_result.capture_outcome != null and capture_result.capture_outcome.resolution.result.status == CaptureResult.FAILED)
	_check.call("brp_audit_capture_then_run_run_still_available", session.has_active_battle() and controller.run_control_enabled())
	if session.has_active_battle():
		session.player_active().stats.speed = 999
		session.current_wild().stats.speed = 1
		var run_result := controller.submit_player_run()
		_check.call("brp_audit_capture_then_run_fled", run_result.succeeded() and run_result.session_completed and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
		_check.call("brp_audit_capture_then_run_ball_count", session.player.inventory.quantity(&"poke_ball") == 1)
	else:
		_check.call("brp_audit_capture_then_run_fled", false)
		_check.call("brp_audit_capture_then_run_ball_count", false)
	controller.queue_free()
	await tree.process_frame


func _test_switch_then_run_uses_current_active(tree: SceneTree) -> void:
	var outgoing := _creature(&"brpa_outgoing", &"bulbasaur", 24711)
	var incoming := _creature(&"brpa_incoming", &"charmander", 24712)
	var session := _session(24701, [outgoing, incoming] as Array[CreatureInstance])
	var controller := await _controller(tree, session, _rng(24713), null)
	var switch_result := controller.submit_player_switch(incoming.instance_id)
	_check.call("brp_audit_switch_then_run_switch_ok", switch_result.succeeded() and session.player_active() == incoming)
	_check.call("brp_audit_switch_then_run_control", session.has_active_battle() and controller.run_control_enabled())
	if session.has_active_battle():
		incoming.stats.speed = 999
		session.current_wild().stats.speed = 1
		var run_result := controller.submit_player_run()
		_check.call("brp_audit_switch_then_run_fled", run_result.succeeded() and run_result.session_completed)
		_check.call("brp_audit_switch_then_run_reason", session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	else:
		_check.call("brp_audit_switch_then_run_fled", false)
		_check.call("brp_audit_switch_then_run_reason", false)
	controller.queue_free()
	await tree.process_frame


func _test_fled_signal_and_reopen_lifecycle(tree: SceneTree) -> void:
	var session := _session(24801)
	session.player_active().stats.speed = 999
	session.current_wild().stats.speed = 1
	var controller := await _controller(tree, session, _rng(24811), null)
	var closed: Array[StringName] = []
	controller.battle_closed.connect(func(reason: StringName): closed.append(reason))
	var result := controller.submit_player_run()
	_check.call("brp_audit_lifecycle_fled", result.succeeded() and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("brp_audit_lifecycle_no_early_signal", closed.is_empty())
	_check.call("brp_audit_lifecycle_controls_locked", not controller.run_control_enabled())
	var continued := controller.continue_after_completion()
	_check.call("brp_audit_lifecycle_signal_once", continued and closed == [WildAdventureSession.COMPLETED_FLED])
	_check.call("brp_audit_lifecycle_ready_hidden", session.status == WildAdventureSession.READY and not controller.visible)
	var encounter := session.begin_encounter(_table(), _rng(24812), 24802)
	if encounter.status == WildEncounterResult.ENCOUNTER and session.current_wild() != null:
		session.current_wild().moveset = [BattleMoveSlot.new(HIT, 40, 40)] as Array[BattleMoveSlot]
		session.current_wild().move_ids = [HIT] as Array[StringName]
	var reopened := controller.open_for_active_battle()
	_check.call("brp_audit_lifecycle_reopen", reopened and session.has_active_battle() and controller.visible)
	_check.call("brp_audit_lifecycle_reenable", controller.run_control_enabled())
	_check.call("brp_audit_lifecycle_counter_reset", session.escape_attempts() == 0)
	_check.call("brp_audit_lifecycle_signal_not_repeated", closed == [WildAdventureSession.COMPLETED_FLED])
	controller.queue_free()
	await tree.process_frame


func _test_public_run_after_completion_is_safe(tree: SceneTree) -> void:
	var session := _session(24901)
	session.player_active().stats.speed = 999
	session.current_wild().stats.speed = 1
	var controller := await _controller(tree, session, _rng(24911), null)
	var first := controller.submit_player_run()
	var attempts := session.escape_attempts()
	var second := controller.submit_player_run()
	_check.call("brp_audit_after_complete_first_fled", first.succeeded() and first.session_completed)
	_check.call("brp_audit_after_complete_rejected", not second.accepted and second.reason == "no_active_wild_battle")
	_check.call("brp_audit_after_complete_reason_stable", session.status == WildAdventureSession.COMPLETED and session.completion_reason == WildAdventureSession.COMPLETED_FLED)
	_check.call("brp_audit_after_complete_attempt_stable", session.escape_attempts() == attempts)
	_check.call("brp_audit_after_complete_controls_locked", not controller.run_control_enabled())
	controller.queue_free()
	await tree.process_frame
