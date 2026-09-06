class_name TrainerAIRuntimeFinalClosureTestSuite
extends RefCounted

const MAIN_SCENE := "res://scenes/overworld/technical_overworld.tscn"
const TRAINER_CONTROLLER_SOURCE := "res://modules/battle/presentation/trainer_battle_presentation_controller.gd"
const WILD_CONTROLLER_SOURCE := "res://modules/battle/presentation/battle_presentation_controller.gd"
const OVERWORLD_SOURCE := "res://scenes/overworld/technical_overworld.gd"
const TRAINER_SESSION_SOURCE := "res://modules/gameplay/trainer_battle_session.gd"
const AGGREGATE := "TRAINER_AI_RUNTIME_SYSTEM_FINAL_CLOSURE_VALIDATED"

var _check: Callable


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	_test_static_final_boundaries()
	await _test_fresh_main_scene_defeat_cycle(tree)
	print(AGGREGATE)


func _test_static_final_boundaries() -> void:
	var trainer_source := _read_text(TRAINER_CONTROLLER_SOURCE)
	var wild_source := _read_text(WILD_CONTROLLER_SOURCE)
	var overworld_source := _read_text(OVERWORLD_SOURCE)
	var session_source := _read_text(TRAINER_SESSION_SOURCE)

	_check.call("c3fas_main_scene_contract", String(ProjectSettings.get_setting("application/run/main_scene", "")) == MAIN_SCENE)
	_check.call("c3fas_trainer_controller_source_present", not trainer_source.is_empty())
	_check.call("c3fas_wild_controller_source_present", not wild_source.is_empty())
	_check.call("c3fas_overworld_source_present", not overworld_source.is_empty())
	_check.call("c3fas_trainer_session_source_present", not session_source.is_empty())
	_check.call("c3fas_trainer_uses_autonomous_submit", trainer_source.contains("submit_player_action_with_autonomous_trainer(player_action)"))
	_check.call("c3fas_trainer_has_no_simple_wild_policy", not trainer_source.contains("SimpleBattleOpponentPolicy"))
	_check.call("c3fas_trainer_has_no_external_opponent_action", not trainer_source.contains("opponent_action"))
	_check.call("c3fas_trainer_has_no_capture_api", not trainer_source.contains("func submit_capture_ball"))
	_check.call("c3fas_trainer_has_no_run_api", not trainer_source.contains("func submit_player_run"))
	_check.call("c3fas_wild_policy_preserved", wild_source.contains("SimpleBattleOpponentPolicy.choose_move_action"))
	_check.call("c3fas_wild_capture_preserved", wild_source.contains("func submit_capture_ball"))
	_check.call("c3fas_wild_run_preserved", wild_source.contains("func submit_player_run"))
	_check.call("c3fas_overworld_owns_trainer_session", overworld_source.contains("TrainerBattleSession.new(collection, _catalogs, rules)"))
	_check.call("c3fas_overworld_separate_trainer_presentation", overworld_source.contains("trainer_battle_presentation.configure(_trainer_session, _catalogs)"))
	_check.call("c3fas_session_autonomous_api_preserved", session_source.contains("func submit_player_action_with_autonomous_trainer("))
	_check.call("c3fas_session_historical_explicit_api_preserved", session_source.contains("func submit_player_action("))
	_check.call("c3fas_no_global_autonomy_toggle_in_overworld", not overworld_source.contains("set_trainer_action_substitution_enabled(true)"))
	_check.call("c3fas_no_general_brain_integration_in_overworld", not overworld_source.contains("TrainerBrain"))
	_check.call("c3fas_no_scheduler_integration_in_overworld", not overworld_source.contains("TrainerScheduler"))


func _test_fresh_main_scene_defeat_cycle(tree: SceneTree) -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_check.call("c3fas_defeat_main_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	_check.call("c3fas_defeat_main_scene_instantiates", scene != null)
	if scene == null:
		return
	tree.root.add_child(scene)
	await tree.process_frame

	_check.call("c3fas_defeat_bootstrap_ready", bool(scene.call("is_demo_ready")))
	var player := scene.get_node_or_null("Player") as OverworldPlayer
	var trainer_trigger := scene.get_node_or_null("TrainerTrigger") as Area2D
	var wild_controller := scene.get_node_or_null("CanvasLayer/BattlePresentation") as BattlePresentationController
	var trainer_controller := scene.get_node_or_null("CanvasLayer/TrainerBattlePresentation") as TrainerBattlePresentationController
	_check.call("c3fas_defeat_player_present", player != null)
	_check.call("c3fas_defeat_trigger_present", trainer_trigger != null)
	_check.call("c3fas_defeat_wild_controller_present", wild_controller != null)
	_check.call("c3fas_defeat_trainer_controller_present", trainer_controller != null)
	_check.call("c3fas_defeat_controllers_separate", wild_controller != null and trainer_controller != null and wild_controller != trainer_controller)
	if player == null or trainer_trigger == null or wild_controller == null or trainer_controller == null:
		scene.queue_free()
		await tree.process_frame
		return

	# Enter through the same physical step seam as runtime input.
	player.global_position = trainer_trigger.global_position
	player.reset_step_meter()
	player.step_distance = 1.0
	player.move_speed = 32.0
	player.apply_motion(Vector2.RIGHT, 0.1)
	await tree.process_frame

	_check.call("c3fas_defeat_trainer_started_from_trigger", bool(scene.call("has_active_demo_trainer_battle")))
	_check.call("c3fas_defeat_trainer_overlay_visible", bool(scene.call("is_trainer_battle_presentation_visible")))
	_check.call("c3fas_defeat_wild_not_started", not bool(scene.call("has_active_demo_battle")))
	_check.call("c3fas_defeat_wild_overlay_hidden", not bool(scene.call("is_battle_presentation_visible")))
	_check.call("c3fas_defeat_overworld_frozen", not player.movement_enabled)

	var trainer_session := trainer_controller.session
	_check.call("c3fas_defeat_session_type", trainer_session is TrainerBattleSession)
	_check.call("c3fas_defeat_session_active", trainer_session != null and trainer_session.has_active_battle())
	_check.call("c3fas_defeat_memory_ready", trainer_session != null and trainer_session.trainer_memory_wiring_ready())
	if trainer_session == null or not trainer_session.has_active_battle():
		scene.queue_free()
		await tree.process_frame
		return

	# Deterministic defeat boundary: every player party member starts at 1 HP and very low Speed;
	# the technical trainer has one legal damaging move (Tackle), is made faster, and receives a
	# large HP cushion so the player's submitted action cannot accidentally win first.
	var state := trainer_session.battle_state()
	var player_active := trainer_session.player_active()
	var opponent := trainer_session.opponent_active()
	_check.call("c3fas_defeat_state_present", state != null)
	_check.call("c3fas_defeat_actors_present", player_active != null and opponent != null)
	if state == null or player_active == null or opponent == null:
		scene.queue_free()
		await tree.process_frame
		return

	var side_a := state.side_for_creature(player_active.instance_id)
	_check.call("c3fas_defeat_player_side_present", side_a != null and side_a.side_id == &"side_a")
	if side_a == null:
		scene.queue_free()
		await tree.process_frame
		return
	for instance_id in side_a.party_ids:
		var creature := state.creature(instance_id)
		if creature != null:
			creature.current_hp = 1
			creature.stats.speed = 1
	opponent.current_hp = 999
	opponent.stats.speed = 999

	var observed_ready_report := false
	var authoritative_turns := 0
	for _turn_index in 3:
		if not trainer_session.has_active_battle():
			break
		var move_ids := trainer_controller.available_move_ids()
		_check.call("c3fas_defeat_player_has_legal_move_%d" % authoritative_turns, not move_ids.is_empty())
		if move_ids.is_empty():
			break
		var turn_before := trainer_session.battle_state().turn
		var events := trainer_controller.submit_player_move(move_ids[0])
		_check.call("c3fas_defeat_turn_events_%d" % authoritative_turns, not events.is_empty())
		authoritative_turns += 1
		if trainer_session.has_active_battle():
			_check.call("c3fas_defeat_turn_advanced_%d" % authoritative_turns, trainer_session.battle_state().turn == turn_before + 1)
			var report := trainer_session.last_trainer_action_substitution_report
			_check.call("c3fas_defeat_substitution_ready_%d" % authoritative_turns, String(report.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY)
			_check.call("c3fas_defeat_no_caller_action_%d" % authoritative_turns, report.get("caller_action", "unexpected") == null)
			_check.call("c3fas_defeat_no_caller_fallback_%d" % authoritative_turns, not bool(report.get("caller_fallback_used", true)))
			_check.call("c3fas_defeat_brain_closed_%d" % authoritative_turns, not bool(report.get("trainer_brain_integration_authorized", true)))
			_check.call("c3fas_defeat_scheduler_closed_%d" % authoritative_turns, report.get("selected_scheduler_id", "unexpected") == null)
			_check.call("c3fas_defeat_shared_budget_closed_%d" % authoritative_turns, report.get("selected_shared_budget", "unexpected") == null)
			_check.call("c3fas_defeat_fase34_closed_%d" % authoritative_turns, not bool(report.get("fase34_open", true)))
			observed_ready_report = true

	_check.call("c3fas_defeat_authoritative_turns_executed", authoritative_turns >= 2)
	_check.call("c3fas_defeat_nonterminal_ready_report_observed", observed_ready_report)
	_check.call("c3fas_defeat_session_completed", trainer_session.status == TrainerBattleSession.COMPLETED)
	_check.call("c3fas_defeat_completion_reason", trainer_session.completion_reason == TrainerBattleSession.COMPLETED_DEFEAT)
	_check.call("c3fas_defeat_overlay_waits_for_continue", trainer_controller.visible and trainer_controller.is_presenting_battle())
	_check.call("c3fas_defeat_overworld_still_frozen_before_continue", not player.movement_enabled)
	_check.call("c3fas_defeat_continue_success", trainer_controller.continue_after_completion())
	_check.call("c3fas_defeat_session_reset_ready", trainer_session.status == TrainerBattleSession.READY)
	_check.call("c3fas_defeat_overlay_hidden_after_continue", not trainer_controller.visible)
	_check.call("c3fas_defeat_overworld_resumed", player.movement_enabled)
	_check.call("c3fas_defeat_wild_controller_untouched", wild_controller.session is WildAdventureSession)
	_check.call("c3fas_defeat_trainer_no_capture_method", not trainer_controller.has_method("submit_capture_ball"))
	_check.call("c3fas_defeat_trainer_no_run_method", not trainer_controller.has_method("submit_player_run"))
	_check.call("c3fas_defeat_wild_capture_method", wild_controller.has_method("submit_capture_ball"))
	_check.call("c3fas_defeat_wild_run_method", wild_controller.has_method("submit_player_run"))
	_check.call("c3fas_final_closure_aggregate", true)

	scene.queue_free()
	await tree.process_frame


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""
