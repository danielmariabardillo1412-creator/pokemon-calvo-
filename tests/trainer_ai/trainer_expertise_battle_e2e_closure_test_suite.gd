class_name TrainerExpertiseBattleE2EClosureTestSuite
extends TrainerExpertiseRuntimeIntegrationTestSuite

# E1-D is strictly TEST/AUDIT-ONLY. Production was completed in E1-C.
# This final gate proves the trusted style/expertise configuration survives the real
# autonomous battle path, remains fail-closed under metadata tampering, and resets
# cleanly between battles on the same TrainerBattleSession.
const E1D_AGGREGATE := "TRAINER_AI_EXPERTISE_V1_E2E_CLOSURE_COMPLETE"


func run(check_callback: Callable) -> void:
	# Build the inherited E1-C fixture without counting its fixture-construction check.
	_check = Callable(self, "_ignore_fixture_check")
	_build_catalog()
	_check = check_callback

	var limited := _e1d_autonomous_case(
		"limited",
		TrainerProfile.AGGRESSIVE,
		TrainerExpertise.LIMITED,
		8101
	)
	var full := _e1d_autonomous_case(
		"full",
		TrainerProfile.AGGRESSIVE,
		TrainerExpertise.FULL,
		8101
	)

	_check.call("expertise_e1d_limited_autonomous_turn_succeeds", bool(limited.get("succeeded", false)))
	_check.call("expertise_e1d_full_autonomous_turn_succeeds", bool(full.get("succeeded", false)))
	_check.call(
		"expertise_e1d_runtime_caps_enforced",
		int(limited.get("inner_cap", 0)) == 1
		and int(full.get("inner_cap", 0)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP
	)
	_check.call(
		"expertise_e1d_same_outer_legal_roots",
		(limited.get("root_ids", []) as Array) == (full.get("root_ids", []) as Array)
		and int(limited.get("legal_action_count", -1)) == int(full.get("legal_action_count", -2))
	)
	_check.call(
		"expertise_e1d_full_materially_wider_internal_search",
		int(full.get("simulation_total", 0)) > int(limited.get("simulation_total", 0))
	)
	_check.call(
		"expertise_e1d_autonomous_never_uses_caller_fallback",
		not bool(limited.get("caller_fallback_used", true))
		and not bool(full.get("caller_fallback_used", true))
	)
	_check.call(
		"expertise_e1d_autonomous_depth2_preserved",
		int(limited.get("common_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH
		and int(full.get("common_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH
	)
	_check.call(
		"expertise_e1d_autonomous_ids_threaded",
		String(limited.get("profile_id", "")) == String(TrainerProfile.AGGRESSIVE)
		and String(full.get("profile_id", "")) == String(TrainerProfile.AGGRESSIVE)
		and String(limited.get("expertise_id", "")) == String(TrainerExpertise.LIMITED)
		and String(full.get("expertise_id", "")) == String(TrainerExpertise.FULL)
	)

	var styles := _e1d_style_matrix()
	_check.call("expertise_e1d_all_four_styles_runtime_complete", bool(styles.get("all_complete", false)))
	_check.call("expertise_e1d_all_four_style_ids_threaded", bool(styles.get("all_ids_threaded", false)))
	_check.call("expertise_e1d_all_four_styles_reach_expected_risk_scoring", bool(styles.get("all_risk_weights_match", false)))
	_check.call("expertise_e1d_styles_keep_identical_legal_action_space", bool(styles.get("same_legal_roots", false)))
	_check.call("expertise_e1d_styles_materialize_scores_for_every_root", bool(styles.get("all_scores_materialized", false)))
	_check.call("expertise_e1d_styles_keep_full_cap_and_depth2", bool(styles.get("all_full_cap_depth2", false)))
	_check.call("expertise_e1d_styles_keep_anticheat_fase34_barriers", bool(styles.get("all_barriers_closed", false)))

	var tamper := _e1d_tamper_report()
	var profile_tamper := tamper.get("profile", {}) as Dictionary
	var expertise_tamper := tamper.get("expertise", {}) as Dictionary
	var cap_tamper := tamper.get("cap", {}) as Dictionary
	_check.call("expertise_e1d_tamper_baseline_is_authoritatively_ready", bool(tamper.get("baseline_ready", false)))
	_check.call(
		"expertise_e1d_profile_tamper_fails_closed",
		String(profile_tamper.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(profile_tamper.get("blocked_reason", "")) == "proposal_profile_mismatch"
	)
	_check.call(
		"expertise_e1d_expertise_tamper_fails_closed",
		String(expertise_tamper.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(expertise_tamper.get("blocked_reason", "")) == "proposal_expertise_mismatch"
	)
	_check.call(
		"expertise_e1d_inner_cap_tamper_fails_closed",
		String(cap_tamper.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_BLOCKED
		and String(cap_tamper.get("blocked_reason", "")) == "proposal_inner_cap_mismatch"
	)
	_check.call("expertise_e1d_tamper_validation_never_advances_turn", bool(tamper.get("turn_unchanged", false)))
	_check.call("expertise_e1d_tamper_validation_never_submits_action", bool(tamper.get("all_blocked_without_submission", false)))

	var reset := _e1d_cross_battle_reset_report()
	_check.call(
		"expertise_e1d_first_battle_settles_and_resets",
		bool(reset.get("first_finished", false))
		and bool(reset.get("settlement_ok", false))
		and bool(reset.get("reset_ok", false))
	)
	_check.call(
		"expertise_e1d_reset_restores_balanced_full_defaults",
		String(reset.get("profile_after_reset", "")) == String(TrainerProfile.BALANCED)
		and String(reset.get("expertise_after_reset", "")) == String(TrainerExpertise.FULL)
	)
	_check.call(
		"expertise_e1d_second_battle_accepts_fresh_config",
		bool(reset.get("second_begin_ok", false))
		and String(reset.get("second_session_profile", "")) == String(TrainerProfile.CAUTIOUS)
		and String(reset.get("second_session_expertise", "")) == String(TrainerExpertise.FULL)
	)
	_check.call(
		"expertise_e1d_second_proposal_uses_only_fresh_config",
		String(reset.get("second_report_profile", "")) == String(TrainerProfile.CAUTIOUS)
		and String(reset.get("second_report_expertise", "")) == String(TrainerExpertise.FULL)
		and int(reset.get("second_inner_cap", 0)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP
	)
	_check.call(
		"expertise_e1d_second_scoring_has_no_first_battle_config_leak",
		bool(reset.get("second_complete", false))
		and bool(reset.get("second_cautious_risk", false))
		and not bool(reset.get("first_config_leaked", true))
	)

	_check.call("expertise_e1d_aggregate", true)
	print(E1D_AGGREGATE)


func _e1d_autonomous_case(
	suffix: String,
	profile_id: StringName,
	expertise_id: StringName,
	seed: int,
) -> Dictionary:
	var fx := _session_fixture("e1d_auto_%s" % suffix)
	var session := fx.session as TrainerBattleSession
	var begin_ok := session.begin_battle(
		StringName("e1d_auto_%s" % suffix),
		fx.roster,
		seed,
		profile_id,
		expertise_id
	)
	if not begin_ok or session.battle_state() == null:
		return {"succeeded": false, "last_error": session.last_error}

	var proposal_before := session.trainer_action_proposal_report_for_side(&"side_b").duplicate(true)
	var player_action := _e1d_player_action(session)
	var turn_before := session.battle_state().turn
	var events: Array[BattleEvent] = []
	if player_action != null:
		events = session.submit_player_action_with_autonomous_trainer(player_action)
	var proposal := session.last_trainer_action_proposal_report.duplicate(true)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var turn_after := session.battle_state().turn if session.battle_state() != null else -1
	return {
		"succeeded": (
			not events.is_empty()
			and session.last_error.is_empty()
			and turn_after == turn_before + 1
			and String(substitution.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		),
		"profile_id": String(proposal.get("trainer_profile_id", "")),
		"expertise_id": String(proposal.get("trainer_expertise_id", "")),
		"inner_cap": int(proposal.get("inner_max_actions_per_side", 0)),
		"common_depth": int(proposal.get("common_depth", 0)),
		"legal_action_count": int(proposal_before.get("legal_action_count", -1)),
		"root_ids": _e1d_sorted_strings(proposal_before.get("root_ids", []) as Array),
		"simulation_total": _sum_values(proposal_before.get("root_simulations", {}) as Dictionary),
		"caller_fallback_used": bool(substitution.get("caller_fallback_used", true)),
	}


func _e1d_style_matrix() -> Dictionary:
	var profiles: Array[StringName] = [
		TrainerProfile.BALANCED,
		TrainerProfile.AGGRESSIVE,
		TrainerProfile.CAUTIOUS,
		TrainerProfile.TECHNICAL,
	]
	var expected_risk := {
		String(TrainerProfile.BALANCED): 4000,
		String(TrainerProfile.AGGRESSIVE): 2500,
		String(TrainerProfile.CAUTIOUS): 6500,
		String(TrainerProfile.TECHNICAL): 5000,
	}
	var baseline_roots: Array[String] = []
	var all_complete := true
	var all_ids_threaded := true
	var all_risk_weights_match := true
	var same_legal_roots := true
	var all_scores_materialized := true
	var all_full_cap_depth2 := true
	var all_barriers_closed := true

	for profile_id in profiles:
		var profile_name := String(profile_id)
		var fx := _session_fixture("e1d_style_%s" % profile_name)
		var session := fx.session as TrainerBattleSession
		var begin_ok := session.begin_battle(
			StringName("e1d_style_%s" % profile_name),
			fx.roster,
			8201,
			profile_id,
			TrainerExpertise.FULL
		)
		if not begin_ok:
			all_complete = false
			all_ids_threaded = false
			all_risk_weights_match = false
			same_legal_roots = false
			all_scores_materialized = false
			all_full_cap_depth2 = false
			all_barriers_closed = false
			continue
		var report := session.trainer_action_proposal_report_for_side(&"side_b")
		var roots := _e1d_sorted_strings(report.get("root_ids", []) as Array)
		if baseline_roots.is_empty():
			baseline_roots = roots.duplicate()
		else:
			same_legal_roots = same_legal_roots and roots == baseline_roots
		all_complete = all_complete and _proposal_complete(report)
		all_ids_threaded = all_ids_threaded and String(report.get("trainer_profile_id", "")) == profile_name
		all_risk_weights_match = all_risk_weights_match and _all_values_equal(
			report.get("root_risk_weight_basis_points", {}) as Dictionary,
			int(expected_risk.get(profile_name, -1))
		)
		all_scores_materialized = (
			all_scores_materialized
			and not (report.get("root_scores", {}) as Dictionary).is_empty()
			and (report.get("root_scores", {}) as Dictionary).size() == int(report.get("legal_action_count", -1))
		)
		all_full_cap_depth2 = (
			all_full_cap_depth2
			and int(report.get("inner_max_actions_per_side", 0)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP
			and int(report.get("common_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH
		)
		all_barriers_closed = (
			all_barriers_closed
			and not bool(report.get("live_rng_used", true))
			and not bool(report.get("profile_tiebreak_used", true))
			and not bool(report.get("fase34_open", true))
		)

	return {
		"all_complete": all_complete,
		"all_ids_threaded": all_ids_threaded,
		"all_risk_weights_match": all_risk_weights_match,
		"same_legal_roots": same_legal_roots and not baseline_roots.is_empty(),
		"all_scores_materialized": all_scores_materialized,
		"all_full_cap_depth2": all_full_cap_depth2,
		"all_barriers_closed": all_barriers_closed,
	}


func _e1d_tamper_report() -> Dictionary:
	var fx := _session_fixture("e1d_tamper")
	var session := fx.session as TrainerBattleSession
	var begin_ok := session.begin_battle(
		&"e1d_tamper",
		fx.roster,
		8301,
		TrainerProfile.BALANCED,
		TrainerExpertise.FULL
	)
	if not begin_ok or session.battle_state() == null:
		return {"baseline_ready": false}
	var raw := session.trainer_action_proposal_report_for_side(&"side_b")
	var ready := _e1d_ready_report_for_validation(session, raw)
	if ready.is_empty():
		return {"baseline_ready": false}
	var turn_before := session.battle_state().turn
	var baseline := session._trainer_action_substitution_candidate_from_report(ready)

	var profile_report := ready.duplicate(true)
	profile_report["trainer_profile_id"] = String(TrainerProfile.AGGRESSIVE)
	var profile_blocked := session._trainer_action_substitution_candidate_from_report(profile_report)

	var expertise_report := ready.duplicate(true)
	expertise_report["trainer_expertise_id"] = String(TrainerExpertise.LIMITED)
	var expertise_blocked := session._trainer_action_substitution_candidate_from_report(expertise_report)

	var cap_report := ready.duplicate(true)
	cap_report["inner_max_actions_per_side"] = 1
	var cap_blocked := session._trainer_action_substitution_candidate_from_report(cap_report)
	var turn_after := session.battle_state().turn

	return {
		"baseline_ready": String(baseline.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY,
		"profile": profile_blocked,
		"expertise": expertise_blocked,
		"cap": cap_blocked,
		"turn_unchanged": turn_after == turn_before,
		"all_blocked_without_submission": (
			profile_blocked.get("submitted_action", "sentinel") == null
			and expertise_blocked.get("submitted_action", "sentinel") == null
			and cap_blocked.get("submitted_action", "sentinel") == null
		),
	}


func _e1d_ready_report_for_validation(
	session: TrainerBattleSession,
	report: Dictionary,
) -> Dictionary:
	if String(report.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY:
		return report.duplicate(true)
	if String(report.get("proposal_status", "")) != TrainerItemAwareActionProposal.TIE_UNRESOLVED:
		return {}
	if session == null or session._battle_server == null or session.battle_state() == null:
		return {}
	var tie := TrainerGameReadyTieResolver.new().resolve(
		report,
		TrainerActionSpace.from_server(session._battle_server, &"side_b"),
		session.battle_state().battle_id,
		session.battle_state().turn,
		&"side_b"
	)
	if String(tie.get("tie_resolution_status", "")) != TrainerGameReadyTieResolver.TIE_RESOLVED:
		return {}
	var selected_action: Dictionary = tie.get("selected_action", {}) as Dictionary
	if selected_action.is_empty():
		return {}
	var ready := report.duplicate(true)
	var root_id := String(tie.get("selected_root_id", ""))
	ready["proposal_status"] = TrainerItemAwareActionProposal.PROPOSAL_READY
	ready["resolution_outcome"] = TrainerItemAwareActionProposal.SINGLE_ROOT_CONTRACT
	ready["selected_root_id"] = root_id
	ready["selected_kind"] = String(tie.get("selected_kind", ""))
	ready["best_root_ids"] = [root_id]
	ready["best_kinds"] = [String(tie.get("selected_kind", ""))]
	ready["proposal_action"] = selected_action.duplicate(true)
	ready["proposal_action_detached"] = true
	return ready


func _e1d_cross_battle_reset_report() -> Dictionary:
	var first_fx := _session_fixture("e1d_reset_first")
	var session := first_fx.session as TrainerBattleSession
	var first_begin := session.begin_battle(
		&"e1d_reset_first",
		first_fx.roster,
		8401,
		TrainerProfile.AGGRESSIVE,
		TrainerExpertise.LIMITED
	)
	if not first_begin or session.battle_state() == null or session.opponent_active() == null:
		return {"first_finished": false}

	var first_opponent_id := String(session.opponent_active().instance_id)
	# Deterministic terminal fixture: player's priority-1, accuracy-100 move acts first.
	session.opponent_active().current_hp = 1
	var first_action := _e1d_player_action(session)
	var first_events: Array[BattleEvent] = []
	if first_action != null:
		first_events = session.submit_player_action_with_autonomous_trainer(first_action)
	var first_finished := (
		not first_events.is_empty()
		and session.battle_state() != null
		and session.battle_state().phase == BattleState.FINISHED
	)
	var settlement: TrainerBattleSettlement = null
	if first_finished:
		settlement = session.settle_finished_battle()
	var settlement_ok := settlement != null and settlement.ok and settlement.session_completed
	var reset_ok := session.reset_after_completion() if settlement_ok else false
	var profile_after_reset := String(session.trainer_profile_id())
	var expertise_after_reset := String(session.trainer_expertise_id())

	var second_fx := _session_fixture("e1d_reset_second")
	var second_begin := false
	if reset_ok:
		second_begin = session.begin_battle(
			&"e1d_reset_second",
			second_fx.roster,
			8402,
			TrainerProfile.CAUTIOUS,
			TrainerExpertise.FULL
		)
	var second_report: Dictionary = {}
	if second_begin:
		second_report = session.trainer_action_proposal_report_for_side(&"side_b")
	var second_json := JSON.stringify(second_report)
	return {
		"first_finished": first_finished,
		"settlement_ok": settlement_ok,
		"reset_ok": reset_ok,
		"profile_after_reset": profile_after_reset,
		"expertise_after_reset": expertise_after_reset,
		"second_begin_ok": second_begin,
		"second_session_profile": String(session.trainer_profile_id()),
		"second_session_expertise": String(session.trainer_expertise_id()),
		"second_report_profile": String(second_report.get("trainer_profile_id", "")),
		"second_report_expertise": String(second_report.get("trainer_expertise_id", "")),
		"second_inner_cap": int(second_report.get("inner_max_actions_per_side", 0)),
		"second_complete": _proposal_complete(second_report),
		"second_cautious_risk": _all_values_equal(
			second_report.get("root_risk_weight_basis_points", {}) as Dictionary,
			6500
		),
		"first_config_leaked": (
			String(second_report.get("trainer_profile_id", "")) == String(TrainerProfile.AGGRESSIVE)
			or String(second_report.get("trainer_expertise_id", "")) == String(TrainerExpertise.LIMITED)
			or second_json.contains(first_opponent_id)
		),
	}


func _e1d_player_action(session: TrainerBattleSession) -> BattleAction:
	if session == null or session.battle_state() == null:
		return null
	var actor := session.player_active()
	var target := session.opponent_active()
	if actor == null or target == null:
		return null
	return BattleAction.new(
		session.battle_state().turn + 1,
		actor.instance_id,
		OPP_HEAVY,
		target.instance_id,
		BattleAction.MOVE,
		&"side_a"
	)


func _e1d_sorted_strings(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	out.sort()
	return out
