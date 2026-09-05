class_name TrainerBattleSessionAutonomousTrainerBattleLifecycleAuditTestSuite
extends TrainerBattleSessionAutonomousSideBSubmissionApiAuditTestSuite

# C3f-an is strictly TEST/AUDIT-ONLY. It does not repair the discovered lifecycle
# boundary. Instead it proves the exact asymmetry: after two authoritative side_b
# forced replacements, the same terminal-winning side_a turn is blocked only by the
# autonomous proposal path while the historical explicit pair reaches Battle Core,
# FINISHED and settlement. Default autonomy, Trainer Brain, scheduler/shared budget
# and FASE34 remain closed.
const AUDIT_ID_C3FAN := "c3f_an_autonomous_terminal_lifecycle_blocker_audit_v2"
const TERMINAL_BLOCKER_CONFIRMED_C3FAN := "AUTONOMOUS_TERMINAL_VICTORY_PROPOSAL_BLOCKER_CONFIRMED"
const BLOCKED_C3FAN := "BLOCKED"

var _c3fan_check: Callable


func run(check_callback: Callable) -> void:
	_c3fan_check = check_callback
	var report := _build_c3fan_report()
	var autonomous := report.get("autonomous_victory_boundary", {}) as Dictionary
	var explicit := report.get("explicit_terminal_control", {}) as Dictionary
	var defeat := report.get("autonomous_defeat_control", {}) as Dictionary
	var source := report.get("source_trace", {}) as Dictionary
	var preflight := autonomous.get("preflight_proposal", {}) as Dictionary

	_c3fan_check.call("c3fan_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAN)
	_c3fan_check.call("c3fan_status_confirms_terminal_blocker", String(report.get("tranche_status", "")) == TERMINAL_BLOCKER_CONFIRMED_C3FAN)
	_c3fan_check.call("c3fan_audit_only_scope", bool(report.get("audit_only_scope", false)) and not bool(report.get("production_modified", true)))
	_c3fan_check.call("c3fan_no_default_autonomy", bool(report.get("no_global_autonomous_toggle", false)))
	_c3fan_check.call("c3fan_two_authoritative_replacements_before_boundary", bool(autonomous.get("first_two_turns_succeeded", false)) and int(autonomous.get("forced_side_b_switch_count", -1)) == 2)
	_c3fan_check.call("c3fan_forced_replacements_owned_by_battle_core", bool(autonomous.get("forced_switches_authoritative", false)) and bool(report.get("forced_replacement_owned_by_battle_core", false)))
	_c3fan_check.call("c3fan_memory_coherent_after_replacements", bool(autonomous.get("memory_ready_after_two", false)) and bool(autonomous.get("memory_tracks_live_side_b", false)))
	_c3fan_check.call("c3fan_terminal_preflight_has_legal_roots", int(preflight.get("legal_action_count", 0)) > 0 and int(preflight.get("evaluated_root_count", -1)) == int(preflight.get("legal_action_count", 0)))
	_c3fan_check.call("c3fan_terminal_preflight_blocked_incomplete", String(preflight.get("proposal_status", "")) == TrainerItemAwareActionProposal.BLOCKED and String(preflight.get("blocked_reason", "")) == "itemaware_action_proposal_incomplete")
	_c3fan_check.call("c3fan_terminal_preflight_has_depth_below_required", bool(autonomous.get("any_root_depth_below_required", false)))
	_c3fan_check.call("c3fan_terminal_preflight_not_stale_or_side_mismatch", bool(preflight.get("context_side_matching", false)) and String(preflight.get("observer_side_id", "")) == "side_b" and int(preflight.get("turn", -1)) == int(autonomous.get("turn_before_blocked_submit", -2)))
	_c3fan_check.call("c3fan_autonomous_terminal_submit_fails_closed", bool(autonomous.get("blocked_submit_events_empty", false)) and String(autonomous.get("blocked_submit_error", "")) == "trainer_action_substitution_not_ready")
	_c3fan_check.call("c3fan_autonomous_terminal_submit_no_turn", int(autonomous.get("turn_after_blocked_submit", -1)) == int(autonomous.get("turn_before_blocked_submit", -2)))
	_c3fan_check.call("c3fan_autonomous_terminal_submit_no_caller_fallback", autonomous.get("caller_action", "sentinel") == null and not bool(autonomous.get("caller_fallback_used", true)))
	_c3fan_check.call("c3fan_explicit_control_reaches_finished", bool(explicit.get("same_boundary_prepared", false)) and bool(explicit.get("terminal_turn_succeeded", false)) and bool(explicit.get("finished", false)) and String(explicit.get("winner_side_id", "")) == "side_a")
	_c3fan_check.call("c3fan_explicit_control_settles_victory", bool(explicit.get("settlement_ok", false)) and bool(explicit.get("player_won", false)) and String(explicit.get("completion_reason", "")) == String(TrainerBattleSession.COMPLETED_VICTORY))
	_c3fan_check.call("c3fan_explicit_control_uses_historical_pair", bool(explicit.get("historical_reports_empty", false)))
	_c3fan_check.call("c3fan_autonomous_defeat_still_completes", bool(defeat.get("three_turns_succeeded", false)) and bool(defeat.get("finished", false)) and String(defeat.get("winner_side_id", "")) == "side_b")
	_c3fan_check.call("c3fan_autonomous_defeat_settles", bool(defeat.get("settlement_ok", false)) and not bool(defeat.get("player_won", true)) and String(defeat.get("completion_reason", "")) == String(TrainerBattleSession.COMPLETED_DEFEAT))
	_c3fan_check.call("c3fan_source_trace_terminal_depth_gate", bool(source.get("terminal_branches_not_expandable", false)) and bool(source.get("depth2_requires_expandable_branch", false)))
	_c3fan_check.call("c3fan_source_trace_proposal_requires_depth2", bool(source.get("proposal_requires_exact_required_depth", false)))
	_c3fan_check.call("c3fan_blocker_is_proposal_not_battle_core", bool(report.get("blocker_is_proposal_not_battle_core", false)))
	_c3fan_check.call("c3fan_no_replacement_policy_added", not bool(report.get("replacement_policy_used", true)))
	_c3fan_check.call("c3fan_scheduler_shared_budget_closed", report.get("selected_strategy_id", "sentinel") == null and report.get("selected_scheduler_id", "sentinel") == null and report.get("selected_shared_budget", "sentinel") == null and not bool(report.get("shared_660_reopened", true)))
	_c3fan_check.call("c3fan_fase34_closed", not bool(report.get("fase34_open", true)))
	_c3fan_check.call("c3fan_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AN TERMINAL LIFECYCLE BLOCKER AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fan_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null or not _c3fan_tune_catalog(catalog):
		return {"audit_id": AUDIT_ID_C3FAN, "tranche_status": BLOCKED_C3FAN}

	var autonomous := _c3fan_autonomous_victory_boundary(catalog)
	var explicit_catalog := _c3fae_catalog()
	var defeat_catalog := _c3fae_catalog()
	if explicit_catalog == null or defeat_catalog == null:
		return {"audit_id": AUDIT_ID_C3FAN, "tranche_status": BLOCKED_C3FAN}
	if not _c3fan_tune_catalog(explicit_catalog) or not _c3fan_tune_catalog(defeat_catalog):
		return {"audit_id": AUDIT_ID_C3FAN, "tranche_status": BLOCKED_C3FAN}
	var explicit := _c3fan_explicit_terminal_control(explicit_catalog)
	var defeat := _c3fan_autonomous_defeat_control(defeat_catalog)
	var source := _c3fan_source_trace()

	var blocker_confirmed := (
		bool(autonomous.get("first_two_turns_succeeded", false))
		and int(autonomous.get("forced_side_b_switch_count", -1)) == 2
		and bool(autonomous.get("memory_ready_after_two", false))
		and bool(autonomous.get("any_root_depth_below_required", false))
		and bool(autonomous.get("blocked_submit_events_empty", false))
		and String(autonomous.get("blocked_submit_error", "")) == "trainer_action_substitution_not_ready"
		and int(autonomous.get("turn_after_blocked_submit", -1)) == int(autonomous.get("turn_before_blocked_submit", -2))
		and bool(explicit.get("same_boundary_prepared", false))
		and bool(explicit.get("terminal_turn_succeeded", false))
		and bool(explicit.get("finished", false))
		and String(explicit.get("winner_side_id", "")) == "side_a"
		and bool(explicit.get("settlement_ok", false))
		and bool(defeat.get("three_turns_succeeded", false))
		and bool(defeat.get("finished", false))
		and String(defeat.get("winner_side_id", "")) == "side_b"
		and bool(source.get("terminal_branches_not_expandable", false))
		and bool(source.get("depth2_requires_expandable_branch", false))
		and bool(source.get("proposal_requires_exact_required_depth", false))
	)
	return {
		"audit_id": AUDIT_ID_C3FAN,
		"tranche_status": TERMINAL_BLOCKER_CONFIRMED_C3FAN if blocker_confirmed else BLOCKED_C3FAN,
		"autonomous_victory_boundary": autonomous,
		"explicit_terminal_control": explicit,
		"autonomous_defeat_control": defeat,
		"source_trace": source,
		"blocker_is_proposal_not_battle_core": blocker_confirmed,
		"forced_replacement_owned_by_battle_core": true,
		"replacement_policy_used": false,
		"no_global_autonomous_toggle": true,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
		"production_modified": false,
		"brains_modified": false,
		"sampler_modified": false,
		"search_budget_modified": false,
		"phase_logic_modified": false,
		"audit_only_scope": true,
	}


func _c3fan_tune_catalog(catalog: DefinitionCatalog) -> bool:
	var chip_a := catalog.move(CHIP_A_C3FAD)
	var chip_b := catalog.move(CHIP_B_C3FAD)
	if chip_a == null or chip_b == null:
		return false
	chip_a.power = 10000
	chip_a.priority = 100
	chip_a.accuracy = -1
	chip_b.power = 10000
	chip_b.priority = 90
	chip_b.accuracy = -1
	return true


func _c3fan_autonomous_victory_boundary(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3fan_autonomous_victory", 915101)
	if session == null or session.battle_state() == null:
		return {}
	_c3fan_set_side_hp(session.battle_state(), SIDE_B_C3FAF, 1)

	var first := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var second := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var first_two_ok := bool(first.get("succeeded", false)) and bool(second.get("succeeded", false))
	var forced_count := int(first.get("forced_side_b_switches", 0)) + int(second.get("forced_side_b_switches", 0))
	var memory := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF)
	var active_b := session.opponent_active()
	var memory_tracks := memory != null and active_b != null and memory.has_seen(active_b.instance_id)
	var preflight := session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF)
	var turn_before := session.battle_state().turn
	var player_action := _c3fan_player_action(session, CHIP_A_C3FAD)
	var events: Array[BattleEvent] = []
	if player_action != null:
		events = session.submit_player_action_with_autonomous_trainer(player_action)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)

	return {
		"first_two_turns_succeeded": first_two_ok,
		"forced_side_b_switch_count": forced_count,
		"forced_switches_authoritative": bool(first.get("forced_switches_authoritative", false)) and bool(second.get("forced_switches_authoritative", false)),
		"memory_ready_after_two": session.trainer_memory_wiring_ready(),
		"memory_tracks_live_side_b": memory_tracks,
		"preflight_proposal": preflight,
		"any_root_depth_below_required": _c3fan_any_root_depth_below_required(preflight),
		"min_root_depth": _c3fan_min_root_depth(preflight),
		"turn_before_blocked_submit": turn_before,
		"turn_after_blocked_submit": session.battle_state().turn,
		"blocked_submit_events_empty": events.is_empty(),
		"blocked_submit_error": session.last_error,
		"caller_action": substitution.get("caller_action", null),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", false)),
		"substitution_status": String(substitution.get("substitution_status", "")),
	}


func _c3fan_explicit_terminal_control(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3fan_explicit_terminal", 915102)
	if session == null or session.battle_state() == null:
		return {}
	_c3fan_set_side_hp(session.battle_state(), SIDE_B_C3FAF, 1)

	var first := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var second := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var prepared := bool(first.get("succeeded", false)) and bool(second.get("succeeded", false)) and session.battle_state().turn == 2
	if not prepared:
		return {"same_boundary_prepared": false}

	var preflight := session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF)
	var player_action := _c3fan_player_action(session, CHIP_A_C3FAD)
	var opponent_action := _c3fan_opponent_action(session, SETUP_B_C3FAD)
	var events: Array[BattleEvent] = []
	if player_action != null and opponent_action != null:
		events = session.submit_player_action(player_action, opponent_action)
	var finished := session.battle_state() != null and session.battle_state().phase == BattleState.FINISHED
	var winner_side := _c3fan_winner_side(session.battle_state())
	var reports_empty := session.last_trainer_action_proposal_report.is_empty() and session.last_trainer_action_substitution_report.is_empty()
	var settlement := session.settle_finished_battle() if finished else TrainerBattleSettlement.new()

	return {
		"same_boundary_prepared": prepared,
		"preflight_also_blocked": String(preflight.get("proposal_status", "")) == TrainerItemAwareActionProposal.BLOCKED,
		"preflight_min_root_depth": _c3fan_min_root_depth(preflight),
		"terminal_turn_succeeded": not events.is_empty() and finished,
		"finished": finished,
		"winner_side_id": winner_side,
		"historical_reports_empty": reports_empty,
		"settlement_ok": settlement.ok,
		"player_won": settlement.player_won,
		"completion_reason": String(session.completion_reason),
	}


func _c3fan_autonomous_defeat_control(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"c3fan_autonomous_defeat", 915103)
	if session == null or session.battle_state() == null:
		return {}
	_c3fan_set_side_hp(session.battle_state(), SIDE_A_C3FAF, 1)

	var succeeded := true
	var turns := 0
	for _index in range(3):
		if session.battle_state() == null or session.battle_state().phase == BattleState.FINISHED:
			break
		var result := _c3fan_submit_autonomous(session, SETUP_A_C3FAD)
		succeeded = succeeded and bool(result.get("succeeded", false))
		turns += 1
	var finished := session.battle_state() != null and session.battle_state().phase == BattleState.FINISHED
	var winner_side := _c3fan_winner_side(session.battle_state())
	var settlement := session.settle_finished_battle() if finished else TrainerBattleSettlement.new()
	return {
		"three_turns_succeeded": succeeded and turns == 3,
		"finished": finished,
		"winner_side_id": winner_side,
		"settlement_ok": settlement.ok,
		"player_won": settlement.player_won,
		"completion_reason": String(session.completion_reason),
	}


func _c3fan_submit_autonomous(session: TrainerBattleSession, move_id: StringName) -> Dictionary:
	if session == null or session.battle_state() == null:
		return {}
	var before := session.battle_state().turn
	var action := _c3fan_player_action(session, move_id)
	if action == null:
		return {}
	var events := session.submit_player_action_with_autonomous_trainer(action)
	var forced_b := _c3fan_forced_switch_count(events, SIDE_B_C3FAF)
	return {
		"succeeded": not events.is_empty() and session.last_error.is_empty() and session.battle_state().turn == before + 1,
		"forced_side_b_switches": forced_b,
		"forced_switches_authoritative": forced_b == 0 or _c3fan_all_forced_switches_marked(events, SIDE_B_C3FAF),
	}


func _c3fan_player_action(session: TrainerBattleSession, move_id: StringName) -> BattleAction:
	if session == null or session.battle_state() == null:
		return null
	var state := session.battle_state()
	var actor := state.active_for_side(SIDE_A_C3FAF)
	var target := state.active_for_side(SIDE_B_C3FAF)
	if actor == null or target == null:
		return null
	return BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		move_id,
		target.instance_id,
		BattleAction.MOVE,
		SIDE_A_C3FAF,
	)


func _c3fan_opponent_action(session: TrainerBattleSession, move_id: StringName) -> BattleAction:
	if session == null or session.battle_state() == null:
		return null
	var state := session.battle_state()
	var actor := state.active_for_side(SIDE_B_C3FAF)
	var target := state.active_for_side(SIDE_A_C3FAF)
	if actor == null or target == null:
		return null
	return BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		move_id,
		target.instance_id,
		BattleAction.MOVE,
		SIDE_B_C3FAF,
	)


func _c3fan_set_side_hp(state: BattleState, side_id: StringName, hp: int) -> void:
	if state == null:
		return
	for side in state.sides:
		if side.side_id != side_id:
			continue
		for creature_id in side.party_ids:
			var creature := state.creature(creature_id)
			if creature != null:
				creature.current_hp = clampi(hp, 1, creature.stats.max_hp)


func _c3fan_forced_switch_count(events: Array[BattleEvent], side_id: StringName) -> int:
	var count := 0
	for event in events:
		if event == null or event.kind != BattleEvent.SWITCHED:
			continue
		if String(event.metadata.get("side_id", "")) == String(side_id) and bool(event.metadata.get("forced", false)):
			count += 1
	return count


func _c3fan_all_forced_switches_marked(events: Array[BattleEvent], side_id: StringName) -> bool:
	var seen := false
	for event in events:
		if event == null or event.kind != BattleEvent.SWITCHED:
			continue
		if String(event.metadata.get("side_id", "")) != String(side_id):
			continue
		seen = true
		if not bool(event.metadata.get("forced", false)):
			return false
	return seen


func _c3fan_any_root_depth_below_required(report: Dictionary) -> bool:
	var depths := report.get("root_depths", {}) as Dictionary
	if depths.is_empty():
		return false
	for value in depths.values():
		if int(value) < TrainerItemAwareActionProposal.REQUIRED_DEPTH:
			return true
	return false


func _c3fan_min_root_depth(report: Dictionary) -> int:
	var depths := report.get("root_depths", {}) as Dictionary
	if depths.is_empty():
		return -1
	var out := 2147483647
	for value in depths.values():
		out = mini(out, int(value))
	return out


func _c3fan_winner_side(state: BattleState) -> String:
	if state == null or state.winner_id == &"":
		return ""
	var side := state.side_for_creature(state.winner_id)
	return String(side.side_id) if side != null else ""


func _c3fan_source_trace() -> Dictionary:
	var multi := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_multi_turn_search.gd")
	var proposal := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_item_aware_action_proposal.gd")
	return {
		"terminal_branches_not_expandable": (
			multi.contains("if fork.state().phase != BattleState.WAITING_FOR_ACTIONS:")
			and multi.contains("continue")
		),
		"depth2_requires_expandable_branch": (
			multi.contains("var fully_completed_depth := 1")
			and multi.contains("and not expandable_branches.is_empty()")
			and multi.contains("fully_completed_depth = 2")
		),
		"proposal_requires_exact_required_depth": (
			proposal.contains("fully_completed_depth")
			and proposal.contains("!= REQUIRED_DEPTH")
		),
	}
