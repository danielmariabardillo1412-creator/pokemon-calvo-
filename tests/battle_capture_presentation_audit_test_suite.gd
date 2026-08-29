class_name BattleCapturePresentationAuditTestSuite
extends RefCounted

var _check: Callable
var _catalog: DefinitionCatalog
var _rules := ProgressionRuleset.new()


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	var normalized := _load_json("res://data/normalized/pokemon_api.json")
	var game_data := GameData.from_dict(normalized) if not normalized.is_empty() else null
	_catalog = game_data.to_definition_catalog() if game_data != null else null
	if _catalog == null:
		_check.call("bcp_audit_catalog", false)
		return
	await _test_no_rng_disables_visible_capture_control(tree)
	await _test_failed_last_ball_disappears_from_controls(tree)
	await _test_failed_capture_ko_settles_visible_defeat(tree)
	await _test_success_removes_stale_capture_controls(tree)


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


func _starter(instance_id: StringName, seed_value: int) -> CreatureInstance:
	var creature := CreatureFactory.create(
		_catalog.species_catalog.get_by_id(&"bulbasaur"),
		5,
		_catalog,
		_rules,
		_rng(seed_value),
		{"instance_id": instance_id},
	)
	if creature != null and _catalog.move(&"tackle") != null:
		var slots: Array[BattleMoveSlot] = [BattleMoveSlot.new(&"tackle", 35, 35)]
		var ids: Array[StringName] = [&"tackle"]
		creature.moveset = slots
		creature.move_ids = ids
	return creature


func _session(ball_id: StringName, amount: int, battle_seed: int) -> WildAdventureSession:
	var collection := PlayerCollection.new()
	collection.party.add_creature(_starter(&"bcp_audit_player", 15900 + battle_seed))
	if amount > 0:
		collection.inventory.add(ball_id, amount)
	var session := WildAdventureSession.new(collection, _catalog, _rules)
	var table := WildEncounterTable.new(&"bcp_audit_grass", 10000)
	table.add_slot(WildEncounterSlot.new(&"bcp_audit_pikachu", &"pikachu", 1, 4, 4))
	var encounter := session.begin_encounter(table, _rng(15910 + battle_seed), battle_seed)
	if encounter.status == WildEncounterResult.ENCOUNTER and session.current_wild() != null:
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


func _test_no_rng_disables_visible_capture_control(tree: SceneTree) -> void:
	var session := _session(&"poke_ball", 1, 16101)
	var controller := await _controller(tree, session, null)
	_check.call("bcp_audit_no_rng_button_visible", controller.capture_button_count() == 1)
	var visible_disabled := true
	for button in controller._capture_buttons:
		if button.visible and not button.disabled:
			visible_disabled = false
	_check.call("bcp_audit_no_rng_button_disabled", visible_disabled)
	controller.queue_free()
	await tree.process_frame


func _test_failed_last_ball_disappears_from_controls(tree: SceneTree) -> void:
	var session := _session(&"poke_ball", 1, 16102)
	var failure_seed := _find_failure_seed(session.current_wild(), &"poke_ball")
	var controller := await _controller(tree, session, _rng(failure_seed))
	var result := controller.submit_capture_ball(&"poke_ball")
	_check.call("bcp_audit_last_fail_accepted", result.succeeded() and result.capture_outcome.resolution.result.status == CaptureResult.FAILED)
	_check.call("bcp_audit_last_fail_inventory_zero", session.player.inventory.quantity(&"poke_ball") == 0)
	_check.call("bcp_audit_last_fail_ids_empty", controller.available_capture_ball_ids().is_empty())
	_check.call("bcp_audit_last_fail_buttons_removed", controller.capture_button_count() == 0)
	controller.queue_free()
	await tree.process_frame


func _test_failed_capture_ko_settles_visible_defeat(tree: SceneTree) -> void:
	var session := _session(&"poke_ball", 1, 16103)
	var player := session.player_active()
	player.current_hp = 1
	var failure_seed := _find_failure_seed(session.current_wild(), &"poke_ball")
	var controller := await _controller(tree, session, _rng(failure_seed))
	var result := controller.submit_capture_ball(&"poke_ball")
	_check.call("bcp_audit_defeat_command_accepted", result.succeeded() and result.battle_finished)
	_check.call("bcp_audit_defeat_session_completed", session.status == WildAdventureSession.COMPLETED)
	_check.call("bcp_audit_defeat_reason", session.completion_reason == WildAdventureSession.COMPLETED_DEFEAT)
	_check.call("bcp_audit_defeat_overlay_visible", controller.visible and controller.is_presenting_battle())
	_check.call("bcp_audit_defeat_continue", controller.continue_after_completion())
	_check.call("bcp_audit_defeat_ready", session.status == WildAdventureSession.READY and not controller.visible)
	controller.queue_free()
	await tree.process_frame


func _test_success_removes_stale_capture_controls(tree: SceneTree) -> void:
	var session := _session(&"master_ball", 1, 16104)
	var controller := await _controller(tree, session, _rng(16140))
	var result := controller.submit_capture_ball(&"master_ball")
	_check.call("bcp_audit_success_accepted", result.succeeded() and result.session_completed)
	_check.call("bcp_audit_success_inventory_zero", session.player.inventory.quantity(&"master_ball") == 0)
	_check.call("bcp_audit_success_ids_empty", controller.available_capture_ball_ids().is_empty())
	_check.call("bcp_audit_success_buttons_removed", controller.capture_button_count() == 0)
	var all_disabled := true
	for button in controller._move_buttons:
		if not button.disabled:
			all_disabled = false
	for button in controller._capture_buttons:
		if not button.disabled:
			all_disabled = false
	_check.call("bcp_audit_success_controls_disabled", all_disabled)
	controller.queue_free()
	await tree.process_frame
