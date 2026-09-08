class_name TrainerBattleSessionCrossBattleResetLifecycleAuditTestSuite
extends TrainerBattleSessionTerminalHorizonCompletenessAuditTestSuite

# C3f-ap is strictly TEST/AUDIT-ONLY. It validates that the same TrainerBattleSession
# can settle an autonomous battle, reset, begin a distinct second battle and build/use
# fresh Trainer memory/proposal state without cross-battle leakage. Production remains
# untouched; any real blocker found here must be repaired only in a later authorized tranche.
const AUDIT_ID_C3FAP := "c3f_ap_cross_battle_reset_lifecycle_audit_v1"
const VALIDATED_C3FAP := "AUTONOMOUS_CROSS_BATTLE_RESET_LIFECYCLE_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY"
const BLOCKED_C3FAP := "BLOCKED"
const SECOND_TRAINER_C3FAP := &"c3fap_second_trainer"

var _c3fap_check: Callable


func run(check_callback: Callable) -> void:
	# C3f-ao is already executed independently by the Evaluation Corpus runner.
	_c3fap_check = check_callback
	var report := _build_c3fap_report()
	var first := report.get("first_battle", {}) as Dictionary
	var settled := report.get("post_settlement", {}) as Dictionary
	var premature := report.get("premature_reset_control", {}) as Dictionary
	var reset := report.get("post_reset", {}) as Dictionary
	var second := report.get("second_battle", {}) as Dictionary
	var stale := second.get("stale_first_proposal_control", {}) as Dictionary
	var fresh := second.get("fresh_proposal", {}) as Dictionary
	var autonomous := second.get("autonomous_turn", {}) as Dictionary
	var historical := second.get("historical_explicit_control", {}) as Dictionary
	var source := report.get("source_trace", {}) as Dictionary

	_c3fap_check.call("c3fap_audit_id", String(report.get("audit_id", "")) == AUDIT_ID_C3FAP)
	_c3fap_check.call("c3fap_status_validated", String(report.get("tranche_status", "")) == VALIDATED_C3FAP)
	_c3fap_check.call("c3fap_first_autonomous_victory_finishes", bool(first.get("first_two_turns_succeeded", false)) and bool(first.get("terminal_turn_succeeded", false)) and bool(first.get("finished", false)) and String(first.get("winner_side_id", "")) == "side_a")
	_c3fap_check.call("c3fap_first_settlement_victory", bool(first.get("settlement_ok", false)) and bool(first.get("player_won", false)) and String(first.get("completion_reason", "")) == String(TrainerBattleSession.COMPLETED_VICTORY))
	_c3fap_check.call("c3fap_first_stale_proposal_was_ready", String(first.get("preserved_proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY and not String(first.get("preserved_battle_id", "")).is_empty())

	_c3fap_check.call("c3fap_post_settlement_completed_no_server", String(settled.get("status", "")) == String(TrainerBattleSession.COMPLETED) and not bool(settled.get("has_active_battle", true)) and bool(settled.get("battle_state_null", false)))
	_c3fap_check.call("c3fap_post_settlement_memory_not_ready", not bool(settled.get("memory_wiring_ready", true)))
	_c3fap_check.call("c3fap_post_settlement_reports_clean", bool(settled.get("reports_empty", false)))
	_c3fap_check.call("c3fap_post_settlement_toggles_off", bool(settled.get("toggles_off", false)))

	_c3fap_check.call("c3fap_premature_reset_fails_closed", not bool(premature.get("reset_ok", true)) and String(premature.get("last_error", "")) == "session_not_completed")
	_c3fap_check.call("c3fap_premature_reset_preserves_active_battle", bool(premature.get("same_battle", false)) and bool(premature.get("same_turn", false)) and bool(premature.get("still_active", false)) and bool(premature.get("memory_still_ready", false)))

	_c3fap_check.call("c3fap_completed_reset_succeeds", bool(reset.get("reset_ok", false)))
	_c3fap_check.call("c3fap_reset_returns_ready_identity_clear", String(reset.get("status", "")) == String(TrainerBattleSession.READY) and String(reset.get("completion_reason", "x")).is_empty() and String(reset.get("opponent_trainer_id", "x")).is_empty())
	_c3fap_check.call("c3fap_reset_keeps_reports_clean", bool(reset.get("reports_empty", false)) and bool(reset.get("toggles_off", false)) and not bool(reset.get("memory_wiring_ready", true)))

	_c3fap_check.call("c3fap_second_battle_same_session_starts", bool(second.get("begin_ok", false)) and bool(second.get("same_session_reused", false)) and String(second.get("trainer_id", "")) == String(SECOND_TRAINER_C3FAP))
	_c3fap_check.call("c3fap_second_battle_new_identity_turn_zero", int(second.get("turn_at_start", -1)) == 0 and String(second.get("battle_id", "")).begins_with("trainer_battle_") and String(second.get("battle_id", "")) != String(first.get("battle_id", "")))
	_c3fap_check.call("c3fap_second_battle_reports_start_empty", bool(second.get("reports_empty_at_start", false)) and bool(second.get("toggles_off_at_start", false)))
	_c3fap_check.call("c3fap_second_memory_fresh_battle_binding", bool(second.get("memory_ready", false)) and bool(second.get("memory_battle_ids_current", false)) and bool(second.get("memory_sides_correct", false)))
	_c3fap_check.call("c3fap_second_memory_has_no_first_opponent_ids", bool(second.get("no_first_opponent_ids_seen", false)) and int(second.get("first_opponent_id_count", 0)) > 0)

	_c3fap_check.call("c3fap_fresh_proposal_current_context", String(fresh.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY and String(fresh.get("battle_id", "")) == String(second.get("battle_id", "")) and int(fresh.get("turn", -1)) == 0 and bool(fresh.get("context_side_matching", false)))
	_c3fap_check.call("c3fap_fresh_proposal_all_legal", int(fresh.get("legal_action_count", 0)) > 0 and int(fresh.get("evaluated_root_count", -1)) == int(fresh.get("legal_action_count", 0)) and bool(fresh.get("root_all_legal", false)))
	_c3fap_check.call("c3fap_fresh_proposal_actor_is_second_active", bool(fresh.get("proposal_actor_matches_second_active", false)) and bool(fresh.get("proposal_action_detached", false)))
	_c3fap_check.call("c3fap_first_and_second_reports_distinct_binding", String(first.get("preserved_battle_id", "")) != String(fresh.get("battle_id", "")) and int(first.get("preserved_turn", -1)) != int(fresh.get("turn", -1)))

	_c3fap_check.call("c3fap_stale_first_proposal_fails_closed", String(stale.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED and String(stale.get("blocked_reason", "")) == "proposal_battle_mismatch")
	_c3fap_check.call("c3fap_stale_first_proposal_no_turn", bool(stale.get("turn_unchanged", false)) and stale.get("submitted_action", "sentinel") == null and not bool(stale.get("caller_fallback_used", true)))

	_c3fap_check.call("c3fap_second_autonomous_turn_succeeds", bool(autonomous.get("succeeded", false)) and String(autonomous.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY and bool(autonomous.get("turn_advanced", false)))
	_c3fap_check.call("c3fap_second_autonomous_has_no_caller_side_b", autonomous.get("caller_action", "sentinel") == null and not bool(autonomous.get("caller_fallback_used", true)))
	_c3fap_check.call("c3fap_second_forced_switches_stay_authoritative", bool(autonomous.get("forced_switches_authoritative", false)))

	_c3fap_check.call("c3fap_historical_explicit_after_reset_succeeds", bool(historical.get("succeeded", false)) and bool(historical.get("turn_advanced", false)) and bool(historical.get("reports_empty_after_explicit", false)))
	_c3fap_check.call("c3fap_source_fresh_memory_and_proposal_instances", bool(source.get("fresh_memory_owner_per_begin", false)) and bool(source.get("fresh_proposal_per_report", false)))
	_c3fap_check.call("c3fap_scope_audit_only", bool(report.get("audit_only_scope", false)) and not bool(report.get("production_modified", true)) and not bool(report.get("battle_core_modified", true)) and not bool(report.get("brains_modified", true)) and not bool(report.get("search_budget_modified", true)) and not bool(report.get("phase_logic_modified", true)))
	_c3fap_check.call("c3fap_policy_barriers_closed", not bool(report.get("replacement_policy_used", true)) and not bool(report.get("campaign_policy_used", true)) and not bool(report.get("recovery_policy_used", true)))
	_c3fap_check.call("c3fap_scheduler_shared_budget_fase34_closed", report.get("selected_strategy_id", "sentinel") == null and report.get("selected_scheduler_id", "sentinel") == null and report.get("selected_shared_budget", "sentinel") == null and not bool(report.get("shared_660_reopened", true)) and not bool(report.get("fase34_open", true)))
	_c3fap_check.call("c3fap_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER BATTLE SESSION C3F-AP CROSS-BATTLE RESET LIFECYCLE AUDIT ===")
	print(JSON.stringify(report))


func _build_c3fap_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null or not _c3fan_tune_catalog(catalog):
		return {"audit_id": AUDIT_ID_C3FAP, "tranche_status": BLOCKED_C3FAP}

	var premature := _c3fap_premature_reset_control()
	var session := _c3faf_started_session(catalog, &"c3fap_first_trainer", 915301)
	if session == null or session.battle_state() == null:
		return {"audit_id": AUDIT_ID_C3FAP, "tranche_status": BLOCKED_C3FAP}

	var session_identity := session
	var first_state := session.battle_state()
	var first_battle_id := String(first_state.battle_id)
	var first_opponent_ids := _c3fap_party_ids(first_state, SIDE_B_C3FAF)
	_c3fan_set_side_hp(first_state, SIDE_B_C3FAF, 1)

	var turn_one := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var turn_two := _c3fan_submit_autonomous(session, CHIP_A_C3FAD)
	var first_two_ok := bool(turn_one.get("succeeded", false)) and bool(turn_two.get("succeeded", false))
	if not first_two_ok or session.battle_state() == null:
		return {
			"audit_id": AUDIT_ID_C3FAP,
			"tranche_status": BLOCKED_C3FAP,
			"first_battle": {"first_two_turns_succeeded": false},
		}

	var stale_proposal := session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF).duplicate(true)
	var terminal_action := _c3fan_player_action(session, CHIP_A_C3FAD)
	var terminal_events: Array[BattleEvent] = []
	if terminal_action != null:
		terminal_events = session.submit_player_action_with_autonomous_trainer(terminal_action)
	var terminal_finished := session.battle_state() != null and session.battle_state().phase == BattleState.FINISHED
	var winner_side := _c3fan_winner_side(session.battle_state())
	var settlement := session.settle_finished_battle() if terminal_finished else TrainerBattleSettlement.new()

	var first := {
		"battle_id": first_battle_id,
		"first_two_turns_succeeded": first_two_ok,
		"terminal_turn_succeeded": not terminal_events.is_empty(),
		"finished": terminal_finished,
		"winner_side_id": winner_side,
		"settlement_ok": settlement.ok,
		"player_won": settlement.player_won,
		"completion_reason": String(session.completion_reason),
		"preserved_proposal_status": String(stale_proposal.get("proposal_status", "")),
		"preserved_battle_id": String(stale_proposal.get("battle_id", "")),
		"preserved_turn": int(stale_proposal.get("turn", -1)),
		"first_opponent_ids": first_opponent_ids,
	}

	var post_settlement := _c3fap_public_cleanup_snapshot(session)
	var reset_ok := session.reset_after_completion()
	var post_reset := _c3fap_public_cleanup_snapshot(session)
	post_reset["reset_ok"] = reset_ok
	post_reset["opponent_trainer_id"] = String(session.opponent_trainer_id)
	post_reset["completion_reason"] = String(session.completion_reason)

	var second_roster := _c3fap_distinct_second_roster(catalog)
	var begin_ok := false
	if reset_ok and not second_roster.is_empty():
		begin_ok = session.begin_battle(SECOND_TRAINER_C3FAP, second_roster, 915303)

	var second := _c3fap_second_battle_report(
		session,
		session_identity,
		begin_ok,
		first_battle_id,
		first_opponent_ids,
		stale_proposal
	)

	var source := _c3fap_source_trace()
	var validated := (
		bool(first.get("finished", false))
		and bool(first.get("settlement_ok", false))
		and bool(first.get("player_won", false))
		and String(first.get("preserved_proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY
		and String(post_settlement.get("status", "")) == String(TrainerBattleSession.COMPLETED)
		and not bool(post_settlement.get("has_active_battle", true))
		and bool(post_settlement.get("reports_empty", false))
		and bool(post_settlement.get("toggles_off", false))
		and not bool(premature.get("reset_ok", true))
		and bool(premature.get("same_battle", false))
		and reset_ok
		and String(post_reset.get("status", "")) == String(TrainerBattleSession.READY)
		and begin_ok
		and bool(second.get("memory_ready", false))
		and bool(second.get("no_first_opponent_ids_seen", false))
		and String((second.get("fresh_proposal", {}) as Dictionary).get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY
		and String((second.get("stale_first_proposal_control", {}) as Dictionary).get("blocked_reason", "")) == "proposal_battle_mismatch"
		and bool((second.get("autonomous_turn", {}) as Dictionary).get("succeeded", false))
		and bool((second.get("historical_explicit_control", {}) as Dictionary).get("succeeded", false))
		and bool(source.get("fresh_memory_owner_per_begin", false))
		and bool(source.get("fresh_proposal_per_report", false))
	)

	return {
		"audit_id": AUDIT_ID_C3FAP,
		"tranche_status": VALIDATED_C3FAP if validated else BLOCKED_C3FAP,
		"first_battle": first,
		"post_settlement": post_settlement,
		"premature_reset_control": premature,
		"post_reset": post_reset,
		"second_battle": second,
		"source_trace": source,
		"forced_replacement_owned_by_battle_core": true,
		"replacement_policy_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
		"production_modified": false,
		"battle_core_modified": false,
		"brains_modified": false,
		"sampler_modified": false,
		"search_budget_modified": false,
		"phase_logic_modified": false,
		"audit_only_scope": true,
	}


func _c3fap_premature_reset_control() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null or not _c3fan_tune_catalog(catalog):
		return {}
	var session := _c3faf_started_session(catalog, &"c3fap_premature_reset", 915302)
	if session == null or session.battle_state() == null:
		return {}
	var battle_id := String(session.battle_state().battle_id)
	var turn := session.battle_state().turn
	var reset_ok := session.reset_after_completion()
	return {
		"reset_ok": reset_ok,
		"last_error": session.last_error,
		"same_battle": session.battle_state() != null and String(session.battle_state().battle_id) == battle_id,
		"same_turn": session.battle_state() != null and session.battle_state().turn == turn,
		"still_active": session.has_active_battle() and session.status == TrainerBattleSession.BATTLE_ACTIVE,
		"memory_still_ready": session.trainer_memory_wiring_ready(),
	}


func _c3fap_public_cleanup_snapshot(session: TrainerBattleSession) -> Dictionary:
	if session == null:
		return {}
	return {
		"status": String(session.status),
		"has_active_battle": session.has_active_battle(),
		"battle_state_null": session.battle_state() == null,
		"memory_wiring_ready": session.trainer_memory_wiring_ready(),
		"reports_empty": (
			session.last_trainer_shadow_report.is_empty()
			and session.last_trainer_action_proposal_report.is_empty()
			and session.last_trainer_action_substitution_report.is_empty()
		),
		"toggles_off": (
			not session.trainer_shadow_item_aware_is_enabled()
			and not session.trainer_action_proposal_is_enabled()
			and not session.trainer_action_substitution_is_enabled()
		),
	}


func _c3fap_distinct_second_roster(catalog: DefinitionCatalog) -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	var donor := _c3faf_started_session(catalog, &"c3fap_second_roster_donor", 915304)
	if donor == null or donor.battle_state() == null:
		return out
	var index := 0
	for side in donor.battle_state().sides:
		if side == null or side.side_id != SIDE_B_C3FAF:
			continue
		for creature_id in side.party_ids:
			var creature := donor.battle_state().creature(creature_id)
			if creature == null:
				continue
			var data := creature.to_dict().duplicate(true)
			data["instance_id"] = StringName("c3fap_second_b%d" % index)
			var clone := CreatureInstance.from_dict(data)
			if clone != null:
				out.append(clone)
			index += 1
	return out


func _c3fap_second_battle_report(
	session: TrainerBattleSession,
	session_identity: TrainerBattleSession,
	begin_ok: bool,
	first_battle_id: String,
	first_opponent_ids: Array[String],
	stale_proposal: Dictionary,
) -> Dictionary:
	if not begin_ok or session == null or session.battle_state() == null:
		return {"begin_ok": begin_ok}

	var state := session.battle_state()
	var second_battle_id := String(state.battle_id)
	var reports_empty_at_start := (
		session.last_trainer_shadow_report.is_empty()
		and session.last_trainer_action_proposal_report.is_empty()
		and session.last_trainer_action_substitution_report.is_empty()
	)
	var toggles_off_at_start := (
		not session.trainer_shadow_item_aware_is_enabled()
		and not session.trainer_action_proposal_is_enabled()
		and not session.trainer_action_substitution_is_enabled()
	)

	var memory_a := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAF)
	var memory_b := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)
	var memory_ids_current := (
		memory_a != null
		and memory_b != null
		and String(memory_a.battle_id) == second_battle_id
		and String(memory_b.battle_id) == second_battle_id
	)
	var memory_sides_correct := (
		memory_a != null
		and memory_b != null
		and memory_a.observer_side_id == SIDE_A_C3FAF
		and memory_b.observer_side_id == SIDE_B_C3FAF
	)
	var no_first_ids := _c3fap_memory_excludes(memory_a, first_opponent_ids) and _c3fap_memory_excludes(memory_b, first_opponent_ids)

	var active_b := session.opponent_active()
	var fresh_proposal := session.trainer_action_proposal_report_for_side(SIDE_B_C3FAF).duplicate(true)
	var proposal_action := fresh_proposal.get("proposal_action", {}) as Dictionary
	var fresh := {
		"proposal_status": String(fresh_proposal.get("proposal_status", "")),
		"battle_id": String(fresh_proposal.get("battle_id", "")),
		"turn": int(fresh_proposal.get("turn", -1)),
		"context_side_matching": bool(fresh_proposal.get("context_side_matching", false)),
		"legal_action_count": int(fresh_proposal.get("legal_action_count", 0)),
		"evaluated_root_count": int(fresh_proposal.get("evaluated_root_count", -1)),
		"root_all_legal": bool(fresh_proposal.get("root_all_legal", false)),
		"selected_root_id": String(fresh_proposal.get("selected_root_id", "")),
		"proposal_action_detached": bool(fresh_proposal.get("proposal_action_detached", false)),
		"proposal_actor_matches_second_active": (
			active_b != null
			and String(proposal_action.get("actor_id", "")) == String(active_b.instance_id)
		),
	}

	var stale_turn_before := state.turn
	var stale_validation := session._trainer_action_substitution_candidate_from_report(stale_proposal)
	var stale_turn_after := session.battle_state().turn if session.battle_state() != null else -1
	var stale := {
		"substitution_status": String(stale_validation.get("substitution_status", "")),
		"blocked_reason": String(stale_validation.get("blocked_reason", "")),
		"submitted_action": stale_validation.get("submitted_action", null),
		"caller_fallback_used": bool(stale_validation.get("caller_fallback_used", false)),
		"turn_unchanged": stale_turn_after == stale_turn_before,
	}

	var autonomous_result := _c3fan_submit_autonomous(session, SETUP_A_C3FAD)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var autonomous := {
		"succeeded": bool(autonomous_result.get("succeeded", false)),
		"turn_advanced": session.battle_state() != null and session.battle_state().turn == stale_turn_before + 1,
		"substitution_status": String(substitution.get("substitution_status", "")),
		"caller_action": substitution.get("caller_action", "sentinel"),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", true)),
		"forced_switches_authoritative": bool(autonomous_result.get("forced_switches_authoritative", false)),
	}

	var historical := _c3fap_historical_after_reset(session)

	return {
		"begin_ok": begin_ok,
		"same_session_reused": session == session_identity,
		"trainer_id": String(session.opponent_trainer_id),
		"battle_id": second_battle_id,
		"first_battle_id": first_battle_id,
		"turn_at_start": 0,
		"reports_empty_at_start": reports_empty_at_start,
		"toggles_off_at_start": toggles_off_at_start,
		"memory_ready": memory_a != null and memory_b != null and session.trainer_memory_wiring_ready(),
		"memory_battle_ids_current": memory_ids_current,
		"memory_sides_correct": memory_sides_correct,
		"no_first_opponent_ids_seen": no_first_ids,
		"first_opponent_id_count": first_opponent_ids.size(),
		"fresh_proposal": fresh,
		"stale_first_proposal_control": stale,
		"autonomous_turn": autonomous,
		"historical_explicit_control": historical,
	}


func _c3fap_historical_after_reset(session: TrainerBattleSession) -> Dictionary:
	if session == null or session.battle_state() == null or session.battle_state().phase != BattleState.WAITING_FOR_ACTIONS:
		return {}
	var turn_before := session.battle_state().turn
	var player_action := _c3fan_player_action(session, SETUP_A_C3FAD)
	var opponent_action := _c3fan_opponent_action(session, SETUP_B_C3FAD)
	var events: Array[BattleEvent] = []
	if player_action != null and opponent_action != null:
		events = session.submit_player_action(player_action, opponent_action)
	return {
		"succeeded": not events.is_empty() and session.last_error.is_empty(),
		"turn_advanced": session.battle_state() != null and session.battle_state().turn == turn_before + 1,
		"reports_empty_after_explicit": (
			session.last_trainer_action_proposal_report.is_empty()
			and session.last_trainer_action_substitution_report.is_empty()
		),
	}


func _c3fap_party_ids(state: BattleState, side_id: StringName) -> Array[String]:
	var out: Array[String] = []
	if state == null:
		return out
	for side in state.sides:
		if side == null or side.side_id != side_id:
			continue
		for creature_id in side.party_ids:
			out.append(String(creature_id))
	return out


func _c3fap_memory_excludes(memory: TrainerBattleMemory, ids: Array[String]) -> bool:
	if memory == null:
		return false
	for raw_id in ids:
		if memory.has_seen(StringName(raw_id)):
			return false
	return true


func _c3fap_source_trace() -> Dictionary:
	var source := FileAccess.get_file_as_string("res://modules/gameplay/trainer_battle_session.gd")
	return {
		"fresh_memory_owner_per_begin": source.contains("var memory_owner := TrainerDualSideBattleMemoryOwner.new()") and source.contains("_trainer_memory_owner = memory_owner"),
		"fresh_proposal_per_report": source.contains("func trainer_action_proposal_report_for_side") and source.contains("var proposal := TrainerItemAwareActionProposal.new()"),
		"reset_clears_reports": source.contains("func reset_after_completion()") and source.contains("last_trainer_action_proposal_report = {}") and source.contains("last_trainer_action_substitution_report = {}"),
	}
