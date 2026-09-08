class_name TrainerCampaignPersistenceRematchE2EClosureTestSuite
extends RefCounted

const MAIN_SCENE := "res://scenes/overworld/technical_overworld.tscn"
const P1D_AUDIT_ID := "p1_d_campaign_persistence_rematch_e2e_closure_v1"
const P1D_STATUS := "CAMPAIGN_PERSISTENCE_REMATCH_E2E_CLOSED"

var _check: Callable


func run(check_callback: Callable, tree: SceneTree) -> void:
	_check = check_callback
	var report := await _exercise_rematch_lifecycle(tree)
	var source := _source_trace()

	_check.call("p1d_audit_id", String(report.get("audit_id", "")) == P1D_AUDIT_ID)
	_check.call("p1d_main_scene_loads", bool(report.get("scene_loads", false)))
	_check.call("p1d_main_scene_instantiates", bool(report.get("scene_instantiates", false)))
	_check.call("p1d_bootstrap_ready", bool(report.get("bootstrap_ready", false)))
	_check.call("p1d_owner_ready", bool(report.get("owner_ready", false)))
	_check.call("p1d_owner_single_member", bool(report.get("owner_single_member", false)))
	_check.call("p1d_owner_initial_reference_available", bool(report.get("owner_initial_reference", false)))
	_check.call("p1d_first_battle_starts", bool(report.get("first_battle_starts", false)))
	_check.call("p1d_first_session_active", bool(report.get("first_session_active", false)))
	_check.call("p1d_first_opponent_is_owner_reference", bool(report.get("first_opponent_same_reference", false)))
	_check.call("p1d_first_turn_zero", bool(report.get("first_turn_zero", false)))
	_check.call("p1d_first_memory_ready", bool(report.get("first_memory_ready", false)))
	_check.call("p1d_first_damaging_move_available", bool(report.get("first_damaging_move_available", false)))
	_check.call("p1d_first_terminal_actors_present", bool(report.get("first_actors_present", false)))
	_check.call("p1d_first_terminal_move_emits_events", bool(report.get("first_terminal_events", false)))
	_check.call("p1d_first_battle_settles_completed", bool(report.get("first_completed", false)))
	_check.call("p1d_first_battle_is_victory", bool(report.get("first_victory", false)))
	_check.call("p1d_post_settlement_owner_same_reference", bool(report.get("post_settlement_same_reference", false)))
	_check.call("p1d_post_settlement_ko_persists", bool(report.get("post_settlement_ko_persists", false)))
	_check.call("p1d_continue_after_first_completion", bool(report.get("continue_succeeds", false)))
	_check.call("p1d_session_ready_after_continue", bool(report.get("session_ready_after_continue", false)))
	_check.call("p1d_reset_preserves_owner_reference", bool(report.get("reset_preserves_owner_reference", false)))
	_check.call("p1d_reset_preserves_ko", bool(report.get("reset_preserves_ko", false)))
	_check.call("p1d_rematch_without_recovery_blocked", bool(report.get("rematch_without_recovery_blocked", false)))
	_check.call("p1d_rematch_block_reason_exact", bool(report.get("rematch_block_reason_exact", false)))
	_check.call("p1d_blocked_rematch_has_no_active_battle", bool(report.get("blocked_rematch_no_active_battle", false)))
	_check.call("p1d_blocked_rematch_does_not_auto_heal", bool(report.get("blocked_rematch_no_autoheal", false)))
	_check.call("p1d_explicit_recovery_succeeds", bool(report.get("explicit_recovery_succeeds", false)))
	_check.call("p1d_recovery_preserves_reference", bool(report.get("recovery_preserves_reference", false)))
	_check.call("p1d_recovery_restores_hp", bool(report.get("recovery_hp_full", false)))
	_check.call("p1d_recovery_restores_pp", bool(report.get("recovery_pp_full", false)))
	_check.call("p1d_recovery_clears_persistent_status", bool(report.get("recovery_status_cleared", false)))
	_check.call("p1d_second_battle_starts", bool(report.get("second_battle_starts", false)))
	_check.call("p1d_second_opponent_is_same_owner_reference", bool(report.get("second_opponent_same_reference", false)))
	_check.call("p1d_second_turn_zero", bool(report.get("second_turn_zero", false)))
	_check.call("p1d_second_memory_is_fresh", bool(report.get("second_memory_fresh", false)))
	_check.call("p1d_second_switch_available", bool(report.get("second_switch_available", false)))
	_check.call("p1d_second_turn_emits_events", bool(report.get("second_turn_events", false)))
	_check.call("p1d_second_turn_advances", bool(report.get("second_turn_advanced", false)))
	_check.call("p1d_second_substitution_ready", bool(report.get("second_substitution_ready", false)))
	_check.call("p1d_second_turn_has_no_caller_fallback", bool(report.get("second_no_caller_fallback", false)))
	_check.call("p1d_combat_campaign_flags_stay_off", bool(report.get("combat_campaign_flags_off", false)))
	_check.call("p1d_source_rematch_replaces_one_shot", bool(source.get("rematch_replaces_one_shot", false)))
	_check.call("p1d_source_scope_isolated", bool(source.get("scope_isolated", false)))
	_check.call("p1d_status_closed", String(report.get("tranche_status", "")) == P1D_STATUS and bool(source.get("source_contract_satisfied", false)))
	_check.call("p1d_report_json_serializable", JSON.parse_string(JSON.stringify({"runtime": report, "source": source})) is Dictionary)

	print("\n=== TRAINER CAMPAIGN P1-D REMATCH E2E CLOSURE ===")
	print(JSON.stringify({"runtime": report, "source": source}))


func _exercise_rematch_lifecycle(tree: SceneTree) -> Dictionary:
	var report := {
		"audit_id": P1D_AUDIT_ID,
		"tranche_status": "BLOCKED",
		"scene_loads": false,
		"scene_instantiates": false,
	}
	var packed := load(MAIN_SCENE) as PackedScene
	report["scene_loads"] = packed != null
	if packed == null:
		return report
	var scene := packed.instantiate()
	report["scene_instantiates"] = scene != null
	if scene == null:
		return report
	tree.root.add_child(scene)
	await tree.process_frame

	report["bootstrap_ready"] = bool(scene.call("is_demo_ready"))
	var controller := scene.get_node_or_null("CanvasLayer/TrainerBattlePresentation") as TrainerBattlePresentationController
	var owner := scene.get("_trainer_campaign_owner") as TrainerCampaignRosterOwner
	var session := controller.session if controller != null else null
	report["owner_ready"] = owner != null and owner.is_ready()
	report["owner_single_member"] = owner != null and owner.roster_size() == 1
	var initial_roster := owner.roster_for_battle() if owner != null else []
	var owner_creature: CreatureInstance = initial_roster[0] if initial_roster.size() == 1 else null
	report["owner_initial_reference"] = owner_creature != null

	var first_started := bool(scene.call("start_demo_trainer_battle")) if controller != null and owner_creature != null else false
	report["first_battle_starts"] = first_started
	report["first_session_active"] = session != null and session.has_active_battle()
	var first_opponent := session.opponent_active() if session != null and session.has_active_battle() else null
	report["first_opponent_same_reference"] = first_opponent != null and first_opponent == owner_creature
	report["first_turn_zero"] = session != null and session.battle_state() != null and session.battle_state().turn == 0
	report["first_memory_ready"] = session != null and session.trainer_memory_wiring_ready()

	var damaging_move := _first_damaging_move(controller)
	report["first_damaging_move_available"] = damaging_move != &""
	var player_active := session.player_active() if session != null and session.has_active_battle() else null
	report["first_actors_present"] = player_active != null and first_opponent != null
	var first_events: Array[BattleEvent] = []
	if damaging_move != &"" and player_active != null and first_opponent != null:
		first_opponent.current_hp = 1
		player_active.stats.speed = 999
		first_events = controller.submit_player_move(damaging_move)
	report["first_terminal_events"] = not first_events.is_empty()
	report["first_completed"] = session != null and session.status == TrainerBattleSession.COMPLETED
	report["first_victory"] = session != null and session.completion_reason == TrainerBattleSession.COMPLETED_VICTORY
	report["post_settlement_same_reference"] = owner != null and owner_creature != null and owner.owned_creature(owner_creature.instance_id) == owner_creature
	report["post_settlement_ko_persists"] = owner_creature != null and owner_creature.current_hp == 0

	var continued := controller != null and controller.continue_after_completion()
	report["continue_succeeds"] = continued
	report["session_ready_after_continue"] = session != null and session.status == TrainerBattleSession.READY
	report["reset_preserves_owner_reference"] = owner != null and owner_creature != null and owner.owned_creature(owner_creature.instance_id) == owner_creature
	report["reset_preserves_ko"] = owner_creature != null and owner_creature.current_hp == 0

	var rematch_without_recovery := bool(scene.call("start_demo_trainer_battle"))
	report["rematch_without_recovery_blocked"] = not rematch_without_recovery
	report["rematch_block_reason_exact"] = session != null and session.last_error == "no_available_opponent_creature"
	report["blocked_rematch_no_active_battle"] = session != null and not session.has_active_battle()
	report["blocked_rematch_no_autoheal"] = owner_creature != null and owner_creature.current_hp == 0

	var owner_slot := owner_creature.moveset[0] as BattleMoveSlot if owner_creature != null and not owner_creature.moveset.is_empty() else null
	if owner_slot != null:
		owner_slot.current_pp = 1
	if owner_creature != null and owner_creature.status_state != null:
		owner_creature.status_state.persistent_id = &"burn"
	var recovery_ref := owner_creature
	var recovered := bool(scene.call("recover_demo_trainer_full"))
	report["explicit_recovery_succeeds"] = recovered
	report["recovery_preserves_reference"] = owner != null and recovery_ref != null and owner.owned_creature(recovery_ref.instance_id) == recovery_ref
	report["recovery_hp_full"] = recovery_ref != null and recovery_ref.current_hp == recovery_ref.stats.max_hp
	report["recovery_pp_full"] = owner_slot != null and owner_slot.current_pp == owner_slot.max_pp
	report["recovery_status_cleared"] = recovery_ref != null and recovery_ref.status_state != null and recovery_ref.status_state.persistent_id == &""

	var second_started := bool(scene.call("start_demo_trainer_battle"))
	report["second_battle_starts"] = second_started
	var second_opponent := session.opponent_active() if session != null and session.has_active_battle() else null
	report["second_opponent_same_reference"] = second_opponent != null and second_opponent == owner_creature
	report["second_turn_zero"] = session != null and session.battle_state() != null and session.battle_state().turn == 0
	report["second_memory_fresh"] = (
		session != null
		and session.trainer_memory_wiring_ready()
		and session.last_trainer_action_proposal_report.is_empty()
		and session.last_trainer_action_substitution_report.is_empty()
	)
	var switch_ids := controller.available_switch_instance_ids() if controller != null else []
	report["second_switch_available"] = not switch_ids.is_empty()
	var second_events: Array[BattleEvent] = []
	var second_turn_before := session.battle_state().turn if session != null and session.battle_state() != null else -1
	if controller != null and not switch_ids.is_empty():
		second_events = controller.submit_player_switch(switch_ids[0])
	report["second_turn_events"] = not second_events.is_empty()
	report["second_turn_advanced"] = session != null and session.battle_state() != null and session.battle_state().turn == second_turn_before + 1
	var substitution := session.last_trainer_action_substitution_report if session != null else {}
	report["second_substitution_ready"] = String(substitution.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
	report["second_no_caller_fallback"] = not bool(substitution.get("caller_fallback_used", true))
	report["combat_campaign_flags_off"] = (
		not bool(substitution.get("campaign_policy_used", true))
		and not bool(substitution.get("recovery_policy_used", true))
		and not bool(substitution.get("replacement_policy_used", true))
	)

	var closed := (
		bool(report.get("first_victory", false))
		and bool(report.get("post_settlement_ko_persists", false))
		and bool(report.get("rematch_without_recovery_blocked", false))
		and bool(report.get("rematch_block_reason_exact", false))
		and bool(report.get("explicit_recovery_succeeds", false))
		and bool(report.get("recovery_preserves_reference", false))
		and bool(report.get("second_battle_starts", false))
		and bool(report.get("second_opponent_same_reference", false))
		and bool(report.get("second_turn_advanced", false))
		and bool(report.get("combat_campaign_flags_off", false))
	)
	report["tranche_status"] = P1D_STATUS if closed else "BLOCKED"

	scene.queue_free()
	await tree.process_frame
	return report


func _first_damaging_move(controller: TrainerBattlePresentationController) -> StringName:
	if controller == null or controller.catalogs == null:
		return &""
	for move_id in controller.available_move_ids():
		var move := controller.catalogs.move(move_id)
		if move != null and move.power > 0:
			return move_id
	return &""


func _source_trace() -> Dictionary:
	var overworld_source := FileAccess.get_file_as_string("res://scenes/overworld/technical_overworld.gd")
	var owner_source := FileAccess.get_file_as_string("res://modules/gameplay/trainer_campaign_roster_owner.gd")
	var session_source := FileAccess.get_file_as_string("res://modules/gameplay/trainer_battle_session.gd")
	var rematch := (
		overworld_source.contains("func recover_demo_trainer_full() -> bool:")
		and not overworld_source.contains("_trainer_demo_completed")
		and overworld_source.contains("_trainer_campaign_owner.roster_for_battle()")
	)
	var isolated := (
		not owner_source.contains("SaveGameData")
		and not owner_source.contains("BattleState")
		and not owner_source.contains("TrainerItemAwareActionProposal")
		and session_source.contains("\"campaign_policy_used\": false")
		and session_source.contains("\"recovery_policy_used\": false")
		and session_source.contains("\"replacement_policy_used\": false")
	)
	return {
		"rematch_replaces_one_shot": rematch,
		"scope_isolated": isolated,
		"source_contract_satisfied": rematch and isolated,
		"save_v2_modified": false,
		"battle_core_modified": false,
		"campaign_snapshot_connected_to_proposal": false,
	}
