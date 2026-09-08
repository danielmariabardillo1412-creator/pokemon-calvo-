class_name TrainerBattleRuntimeIntegrationTestSuite
extends RefCounted

const MAIN_SCENE := "res://scenes/overworld/technical_overworld.tscn"
const TRAINER_CONTROLLER_SOURCE := "res://modules/battle/presentation/trainer_battle_presentation_controller.gd"
const WILD_CONTROLLER_SOURCE := "res://modules/battle/presentation/battle_presentation_controller.gd"

var _check: Callable


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	_test_static_isolation_contract()
	await _test_executable_trainer_vertical_slice(tree)


func _test_static_isolation_contract() -> void:
	_check.call("c3far_main_scene_contract", String(ProjectSettings.get_setting("application/run/main_scene", "")) == MAIN_SCENE)
	var trainer_source := _read_text(TRAINER_CONTROLLER_SOURCE)
	var wild_source := _read_text(WILD_CONTROLLER_SOURCE)
	_check.call("c3far_trainer_controller_source_present", not trainer_source.is_empty())
	_check.call("c3far_trainer_controller_uses_autonomous_api", trainer_source.contains("submit_player_action_with_autonomous_trainer(player_action)"))
	_check.call("c3far_trainer_controller_has_no_simple_wild_policy", not trainer_source.contains("SimpleBattleOpponentPolicy"))
	_check.call("c3far_trainer_controller_has_no_external_opponent_action", not trainer_source.contains("opponent_action"))
	_check.call("c3far_trainer_controller_has_no_capture_surface", not trainer_source.contains("func submit_capture_ball"))
	_check.call("c3far_trainer_controller_has_no_run_surface", not trainer_source.contains("func submit_player_run"))
	_check.call("c3far_wild_controller_policy_preserved", wild_source.contains("SimpleBattleOpponentPolicy.choose_move_action"))
	_check.call("c3far_wild_capture_surface_preserved", wild_source.contains("func submit_capture_ball"))
	_check.call("c3far_wild_run_surface_preserved", wild_source.contains("func submit_player_run"))


func _test_executable_trainer_vertical_slice(tree: SceneTree) -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_check.call("c3far_main_scene_loads", packed != null)
	if packed == null:
		return
	var scene := packed.instantiate()
	_check.call("c3far_main_scene_instantiates", scene != null)
	if scene == null:
		return
	tree.root.add_child(scene)
	await tree.process_frame

	_check.call("c3far_runtime_bootstrap_ready", bool(scene.call("is_demo_ready")))
	var player := scene.get_node_or_null("Player") as OverworldPlayer
	var trainer_trigger := scene.get_node_or_null("TrainerTrigger") as Area2D
	var wild_zone := scene.get_node_or_null("EncounterZone") as OverworldEncounterZone
	var wild_controller := scene.get_node_or_null("CanvasLayer/BattlePresentation") as BattlePresentationController
	var trainer_controller := scene.get_node_or_null("CanvasLayer/TrainerBattlePresentation") as TrainerBattlePresentationController
	_check.call("c3far_player_present", player != null)
	_check.call("c3far_trainer_trigger_present", trainer_trigger != null)
	_check.call("c3far_wild_zone_present", wild_zone != null)
	_check.call("c3far_wild_controller_present", wild_controller != null)
	_check.call("c3far_trainer_controller_present", trainer_controller != null)
	_check.call("c3far_controllers_are_separate_nodes", wild_controller != null and trainer_controller != null and wild_controller != trainer_controller)
	_check.call("c3far_trainer_has_no_capture_method", trainer_controller != null and not trainer_controller.has_method("submit_capture_ball"))
	_check.call("c3far_trainer_has_no_run_method", trainer_controller != null and not trainer_controller.has_method("submit_player_run"))
	_check.call("c3far_wild_still_has_capture_method", wild_controller != null and wild_controller.has_method("submit_capture_ball"))
	_check.call("c3far_wild_still_has_run_method", wild_controller != null and wild_controller.has_method("submit_player_run"))
	if player == null or trainer_trigger == null or wild_zone == null or wild_controller == null or trainer_controller == null:
		scene.queue_free()
		await tree.process_frame
		return

	_check.call("c3far_wild_session_type_preserved", wild_controller.session is WildAdventureSession)
	_check.call("c3far_trainer_session_type", trainer_controller.session is TrainerBattleSession)
	_check.call("c3far_trigger_geometry_live", bool(scene.call("trainer_trigger_contains", trainer_trigger.global_position)))
	_check.call("c3far_initial_no_wild_battle", not bool(scene.call("has_active_demo_battle")))
	_check.call("c3far_initial_no_trainer_battle", not bool(scene.call("has_active_demo_trainer_battle")))
	_check.call("c3far_initial_wild_overlay_hidden", not bool(scene.call("is_battle_presentation_visible")))
	_check.call("c3far_initial_trainer_overlay_hidden", not bool(scene.call("is_trainer_battle_presentation_visible")))

	# Reach the Trainer seam through the same physical movement/step signal used by runtime input.
	player.global_position = trainer_trigger.global_position
	player.reset_step_meter()
	player.step_distance = 1.0
	player.move_speed = 32.0
	player.apply_motion(Vector2.RIGHT, 0.1)
	await tree.process_frame

	_check.call("c3far_trainer_battle_started_from_overworld", bool(scene.call("has_active_demo_trainer_battle")))
	_check.call("c3far_trainer_overlay_visible", bool(scene.call("is_trainer_battle_presentation_visible")))
	_check.call("c3far_wild_battle_not_started_by_trainer_trigger", not bool(scene.call("has_active_demo_battle")))
	_check.call("c3far_wild_overlay_stays_hidden", not bool(scene.call("is_battle_presentation_visible")))
	_check.call("c3far_overworld_frozen_for_trainer", not player.movement_enabled)

	var trainer_session := trainer_controller.session
	_check.call("c3far_runtime_session_active", trainer_session != null and trainer_session.has_active_battle())
	_check.call("c3far_runtime_trainer_identity", trainer_session != null and trainer_session.opponent_trainer_id == &"technical_trainer")
	_check.call("c3far_runtime_starts_turn_zero", trainer_session != null and trainer_session.battle_state() != null and trainer_session.battle_state().turn == 0)
	_check.call("c3far_runtime_memory_ready", trainer_session != null and trainer_session.trainer_memory_wiring_ready())
	_check.call("c3far_runtime_move_controls", trainer_controller.move_button_count() > 0)
	_check.call("c3far_runtime_switch_available", trainer_controller.switch_option_count() > 0 and trainer_controller.switch_control_enabled())

	# First real turn: elective player switch. The controller supplies only side_a.
	var switch_ids := trainer_controller.available_switch_instance_ids()
	_check.call("c3far_switch_target_available", not switch_ids.is_empty())
	if not switch_ids.is_empty() and trainer_session != null and trainer_session.battle_state() != null:
		var turn_before_switch := trainer_session.battle_state().turn
		var switch_events := trainer_controller.submit_player_switch(switch_ids[0])
		_check.call("c3far_switch_emits_authoritative_events", not switch_events.is_empty())
		_check.call("c3far_switch_no_session_error", trainer_session.last_error.is_empty())
		_check.call("c3far_switch_turn_advanced", trainer_session.battle_state() != null and trainer_session.battle_state().turn == turn_before_switch + 1)
		var substitution := trainer_session.last_trainer_action_substitution_report
		_check.call("c3far_switch_substitution_ready", String(substitution.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY)
		_check.call("c3far_switch_no_caller_action", substitution.get("caller_action", "unexpected") == null)
		_check.call("c3far_switch_no_caller_fallback", not bool(substitution.get("caller_fallback_used", true)))
		_check.call("c3far_switch_brain_not_integrated", not bool(substitution.get("trainer_brain_integration_authorized", true)))
		_check.call("c3far_switch_scheduler_closed", substitution.get("selected_scheduler_id", "unexpected") == null)
		_check.call("c3far_switch_shared_budget_closed", substitution.get("selected_shared_budget", "unexpected") == null)
		_check.call("c3far_switch_fase34_closed", not bool(substitution.get("fase34_open", true)))

	# Second real turn: choose a damaging player move and force only the target HP boundary so the
	# runtime path proves FINISHED -> settlement -> presentation continue without bypassing Battle Core.
	if trainer_session != null and trainer_session.has_active_battle():
		var damaging_move: StringName = &""
		for move_id in trainer_controller.available_move_ids():
			var move := trainer_controller.catalogs.move(move_id)
			if move != null and move.power > 0:
				damaging_move = move_id
				break
		_check.call("c3far_damaging_player_move_available", damaging_move != &"")
		var opponent := trainer_session.opponent_active()
		var active_player := trainer_session.player_active()
		_check.call("c3far_terminal_actors_present", opponent != null and active_player != null)
		if damaging_move != &"" and opponent != null and active_player != null:
			opponent.current_hp = 1
			active_player.stats.speed = 999
			var terminal_events := trainer_controller.submit_player_move(damaging_move)
			_check.call("c3far_terminal_move_emits_events", not terminal_events.is_empty())
			_check.call("c3far_runtime_auto_settles", trainer_session.status == TrainerBattleSession.COMPLETED)
			_check.call("c3far_runtime_victory_reason", trainer_session.completion_reason == TrainerBattleSession.COMPLETED_VICTORY)
			_check.call("c3far_trainer_overlay_waits_for_continue", trainer_controller.visible and trainer_controller.is_presenting_battle())
			_check.call("c3far_overworld_still_frozen_before_continue", not player.movement_enabled)
			_check.call("c3far_runtime_continue_success", trainer_controller.continue_after_completion())
			_check.call("c3far_runtime_session_reset_ready", trainer_session.status == TrainerBattleSession.READY)
			_check.call("c3far_trainer_overlay_hidden_after_continue", not trainer_controller.visible)
			_check.call("c3far_overworld_resumed_after_trainer", player.movement_enabled)

	# Isolation control: after completing the Trainer seam, the original Wild seam is still reachable
	# from the actual EncounterZone and owns its own presentation/session.
	player.global_position = wild_zone.global_position
	player.reset_step_meter()
	player.step_distance = 1.0
	player.move_speed = 32.0
	player.apply_motion(Vector2.RIGHT, 0.1)
	await tree.process_frame
	_check.call("c3far_wild_battle_still_reachable", bool(scene.call("has_active_demo_battle")))
	_check.call("c3far_wild_overlay_still_visible", bool(scene.call("is_battle_presentation_visible")))
	_check.call("c3far_trainer_battle_not_reopened", not bool(scene.call("has_active_demo_trainer_battle")))
	_check.call("c3far_trainer_overlay_stays_isolated", not bool(scene.call("is_trainer_battle_presentation_visible")))
	_check.call("c3far_wild_capture_after_trainer_still_exposed", wild_controller.capture_button_count() > 0)
	_check.call("c3far_wild_run_after_trainer_still_exposed", wild_controller.run_button_visible())
	_check.call("c3far_runtime_integration_aggregate", true)

	scene.queue_free()
	await tree.process_frame


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""
