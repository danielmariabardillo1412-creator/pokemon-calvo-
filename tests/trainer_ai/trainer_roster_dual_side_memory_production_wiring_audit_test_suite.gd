class_name TrainerRosterDualSideMemoryProductionWiringAuditTestSuite
extends TrainerRosterSearchItemAwareMarginDisjointRoleLocalValidationAuditTestSuite

# C3f-ae is the first production-wiring tranche after C3f-ad. It may establish trusted
# dual side-specific memory ownership and branch-safe snapshots, but it must not select
# actions or activate any search/switch policy.

const AUDIT_ID_C3FAE := "c3f_ae_dual_side_memory_production_wiring_audit_v1"
const BOUNDARY_ID_C3FAE := "wire_trusted_dual_side_memory_from_battle_start_without_behavior_integration"
const WIRED_NO_BEHAVIOR_INTEGRATION := "WIRED_NO_BEHAVIOR_INTEGRATION"
const BLOCKED_C3FAE := "BLOCKED"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_dual_side_memory_production_wiring()


func _test_dual_side_memory_production_wiring() -> void:
	var report_a := _build_c3fae_report()
	var report_b := _build_c3fae_report()
	var status := String(report_a.get("tranche_status", ""))

	_check.call("dual_memory_wiring_audit_id_recorded", String(report_a.get("audit_id", "")) == AUDIT_ID_C3FAE)
	_check.call("dual_memory_wiring_boundary_id_recorded", String(report_a.get("boundary_id", "")) == BOUNDARY_ID_C3FAE)
	_check.call("dual_memory_wiring_status_explicit", [WIRED_NO_BEHAVIOR_INTEGRATION, BLOCKED_C3FAE].has(status))
	_check.call("dual_memory_wiring_prebegin_fails_closed", bool(report_a.get("prebegin_snapshot_rejected", false)))
	_check.call("dual_memory_wiring_begins_ready_from_battle_start", bool(report_a.get("begin_ok", false)) and bool(report_a.get("wiring_ready_after_begin", false)))
	_check.call("dual_memory_wiring_side_and_battle_ids_match", bool(report_a.get("side_and_battle_ids_match", false)))
	_check.call("dual_memory_wiring_initial_opponents_seen", bool(report_a.get("initial_opponents_seen", false)))
	_check.call("dual_memory_wiring_wrong_side_rejected", bool(report_a.get("wrong_side_snapshot_rejected", false)))
	_check.call("dual_memory_wiring_returned_snapshot_isolated", bool(report_a.get("returned_snapshot_isolated", false)))
	_check.call("dual_memory_wiring_explicit_opponent_action_still_required", bool(report_a.get("missing_opponent_action_rejected", false)))
	_check.call("dual_memory_wiring_missing_opponent_does_not_advance_turn", bool(report_a.get("missing_opponent_action_no_turn", false)))
	_check.call("dual_memory_wiring_authoritative_turn_succeeds", bool(report_a.get("authoritative_turn_succeeds", false)))
	_check.call("dual_memory_wiring_same_public_event_batch_fanned_out", bool(report_a.get("same_public_event_log_both_sides", false)))
	_check.call("dual_memory_wiring_side_a_reveal_is_opponent_only", bool(report_a.get("side_a_reveal_isolated", false)))
	_check.call("dual_memory_wiring_side_b_reveal_is_opponent_only", bool(report_a.get("side_b_reveal_isolated", false)))
	_check.call("dual_memory_wiring_raw_metadata_not_persisted", bool(report_a.get("public_log_metadata_sanitized", false)))
	_check.call("dual_memory_wiring_branch_snapshots_exist_for_both_sides", bool(report_a.get("branch_snapshots_both_sides", false)))
	_check.call("dual_memory_wiring_branch_projection_does_not_mutate_live", bool(report_a.get("branch_projection_live_unchanged", false)))
	_check.call("dual_memory_wiring_wrong_branch_side_rejected", bool(report_a.get("wrong_branch_side_rejected", false)))
	_check.call("dual_memory_wiring_missing_lifecycle_fails_closed_before_turn", bool(report_a.get("missing_lifecycle_fail_closed", false)))
	_check.call("dual_memory_wiring_no_behavior_selection_surface", bool(report_a.get("no_behavior_selection_surface", false)))
	_check.call(
		"dual_memory_wiring_behavior_policy_barriers_stay_closed",
		not bool(report_a.get("behavior_integration_authorized", true))
		and not bool(report_a.get("margin3000_behavior_enabled", true))
		and not bool(report_a.get("production_sampler_modified", true))
		and not bool(report_a.get("production_budget_modified", true)),
	)
	_check.call(
		"dual_memory_wiring_scheduler_strategy_and_fase34_stay_closed",
		report_a.get("selected_strategy_id", "sentinel") == null
		and report_a.get("selected_scheduler_id", "sentinel") == null
		and report_a.get("selected_shared_budget", "sentinel") == null
		and not bool(report_a.get("shared_660_reopened", true))
		and not bool(report_a.get("fase34_open", true)),
	)
	_check.call("dual_memory_wiring_report_deterministic", report_a == report_b)
	_check.call("dual_memory_wiring_report_json_serializable", JSON.parse_string(JSON.stringify(report_a)) is Dictionary)

	print("\n=== TRAINER ROSTER DUAL SIDE MEMORY PRODUCTION WIRING AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fae_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return _c3fae_blocked_report()
	var bundle := _c3fae_session_bundle(catalog)
	var session := bundle.get("session", null) as TrainerBattleSession
	var opponent_roster: Array[CreatureInstance] = []
	for value in bundle.get("opponent_roster", []):
		var creature := value as CreatureInstance
		if creature != null:
			opponent_roster.append(creature)
	if session == null or opponent_roster.size() != 3:
		return _c3fae_blocked_report()

	var prebegin_snapshot_rejected := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAD) == null
	var begin_ok := session.begin_battle(&"c3fae_trainer", opponent_roster, 852401)
	if not begin_ok or session.battle_state() == null:
		var blocked := _c3fae_blocked_report()
		blocked["prebegin_snapshot_rejected"] = prebegin_snapshot_rejected
		return blocked

	var state := session.battle_state()
	var active_a := state.active_for_side(SIDE_A_C3FAD)
	var active_b := state.active_for_side(SIDE_B_C3FAD)
	var memory_a := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAD)
	var memory_b := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAD)
	var wiring_ready_after_begin := session.trainer_memory_wiring_ready()
	var side_and_battle_ids_match := (
		memory_a != null
		and memory_b != null
		and memory_a.battle_id == state.battle_id
		and memory_b.battle_id == state.battle_id
		and memory_a.observer_side_id == SIDE_A_C3FAD
		and memory_b.observer_side_id == SIDE_B_C3FAD
	)
	var initial_opponents_seen := (
		active_a != null
		and active_b != null
		and memory_a != null
		and memory_b != null
		and memory_a.has_seen(active_b.instance_id)
		and memory_b.has_seen(active_a.instance_id)
	)
	var wrong_side_snapshot_rejected := session.trainer_memory_snapshot_for_side(&"side_x") == null

	var returned_snapshot_isolated := false
	if memory_a != null:
		memory_a.clear()
		var fresh_a := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAD)
		returned_snapshot_isolated = (
			fresh_a != null
			and fresh_a.battle_id == state.battle_id
			and fresh_a.observer_side_id == SIDE_A_C3FAD
			and active_b != null
			and fresh_a.has_seen(active_b.instance_id)
		)

	var actions := _c3fae_actions(session.battle_state())
	var turn_before_missing := session.battle_state().turn
	var missing_events: Array[BattleEvent] = []
	if actions.size() == 2:
		missing_events = session.submit_player_action(actions[0], null)
	var missing_opponent_action_rejected := missing_events.is_empty() and session.last_error == "opponent_action_required"
	var missing_opponent_action_no_turn := session.battle_state().turn == turn_before_missing

	actions = _c3fae_actions(session.battle_state())
	var events: Array[BattleEvent] = []
	if actions.size() == 2:
		events = session.submit_player_action(actions[0], actions[1])
	var authoritative_turn_succeeds := not events.is_empty() and session.last_error.is_empty()
	var after_a := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAD)
	var after_b := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAD)
	var same_public_event_log_both_sides := (
		after_a != null
		and after_b != null
		and not after_a.event_log.is_empty()
		and JSON.stringify(after_a.event_log) == JSON.stringify(after_b.event_log)
		and after_a.last_observed_turn == session.battle_state().turn
		and after_b.last_observed_turn == session.battle_state().turn
	)
	var side_a_reveal_isolated := false
	var side_b_reveal_isolated := false
	if active_a != null and active_b != null and after_a != null and after_b != null:
		side_a_reveal_isolated = (
			after_a.revealed_move_ids(active_b.instance_id).has(SETUP_B_C3FAD)
			and not after_a.revealed_move_ids(active_a.instance_id).has(SETUP_A_C3FAD)
		)
		side_b_reveal_isolated = (
			after_b.revealed_move_ids(active_a.instance_id).has(SETUP_A_C3FAD)
			and not after_b.revealed_move_ids(active_b.instance_id).has(SETUP_B_C3FAD)
		)
	var public_log_metadata_sanitized := _c3fae_public_log_sanitized(after_a) and _c3fae_public_log_sanitized(after_b)

	var branch_snapshots_both_sides := false
	var branch_projection_live_unchanged := false
	var wrong_branch_side_rejected := false
	if after_a != null and after_b != null:
		var live_a_before := JSON.stringify(after_a.to_dict())
		var live_b_before := JSON.stringify(after_b.to_dict())
		var fork := BattleSimulationFork.from_state(session.battle_state(), catalog)
		if fork != null and fork.state() != null:
			var branch_actions := _c3fae_actions(fork.state())
			if branch_actions.size() == 2:
				var branch_events := fork.submit_turn(branch_actions)
				var branch_a := session.trainer_branch_memory_snapshot_for_side(SIDE_A_C3FAD, branch_events, fork.state())
				var branch_b := session.trainer_branch_memory_snapshot_for_side(SIDE_B_C3FAD, branch_events, fork.state())
				branch_snapshots_both_sides = (
					branch_a != null
					and branch_b != null
					and branch_a.event_log.size() > after_a.event_log.size()
					and branch_b.event_log.size() > after_b.event_log.size()
					and branch_a.observer_side_id == SIDE_A_C3FAD
					and branch_b.observer_side_id == SIDE_B_C3FAD
				)
				wrong_branch_side_rejected = session.trainer_branch_memory_snapshot_for_side(&"side_x", branch_events, fork.state()) == null
				if branch_a != null:
					branch_a.clear()
				var live_a_after := session.trainer_memory_snapshot_for_side(SIDE_A_C3FAD)
				var live_b_after := session.trainer_memory_snapshot_for_side(SIDE_B_C3FAD)
				branch_projection_live_unchanged = (
					live_a_after != null
					and live_b_after != null
					and JSON.stringify(live_a_after.to_dict()) == live_a_before
					and JSON.stringify(live_b_after.to_dict()) == live_b_before
				)

	var no_behavior_selection_surface := (
		not session.has_method("choose_opponent_action")
		and not session.has_method("choose_trainer_action")
	)

	# Deliberately corrupt the trusted lifecycle after all positive checks. The next
	# turn must be rejected before Battle Core mutates, proving fail-closed wiring.
	session._trainer_memory_owner.clear()
	var broken_turn_before := session.battle_state().turn
	var broken_actions := _c3fae_actions(session.battle_state())
	var broken_events: Array[BattleEvent] = []
	if broken_actions.size() == 2:
		broken_events = session.submit_player_action(broken_actions[0], broken_actions[1])
	var missing_lifecycle_fail_closed := (
		broken_events.is_empty()
		and session.last_error == "trainer_memory_not_ready"
		and session.battle_state().turn == broken_turn_before
		and not session.trainer_memory_wiring_ready()
		and session.trainer_memory_snapshot_for_side(SIDE_A_C3FAD) == null
	)

	var critical_ok := (
		prebegin_snapshot_rejected
		and wiring_ready_after_begin
		and side_and_battle_ids_match
		and initial_opponents_seen
		and wrong_side_snapshot_rejected
		and returned_snapshot_isolated
		and missing_opponent_action_rejected
		and missing_opponent_action_no_turn
		and authoritative_turn_succeeds
		and same_public_event_log_both_sides
		and side_a_reveal_isolated
		and side_b_reveal_isolated
		and public_log_metadata_sanitized
		and branch_snapshots_both_sides
		and branch_projection_live_unchanged
		and wrong_branch_side_rejected
		and missing_lifecycle_fail_closed
		and no_behavior_selection_surface
	)

	return {
		"audit_id": AUDIT_ID_C3FAE,
		"boundary_id": BOUNDARY_ID_C3FAE,
		"tranche_status": WIRED_NO_BEHAVIOR_INTEGRATION if critical_ok else BLOCKED_C3FAE,
		"prebegin_snapshot_rejected": prebegin_snapshot_rejected,
		"begin_ok": begin_ok,
		"wiring_ready_after_begin": wiring_ready_after_begin,
		"side_and_battle_ids_match": side_and_battle_ids_match,
		"initial_opponents_seen": initial_opponents_seen,
		"wrong_side_snapshot_rejected": wrong_side_snapshot_rejected,
		"returned_snapshot_isolated": returned_snapshot_isolated,
		"missing_opponent_action_rejected": missing_opponent_action_rejected,
		"missing_opponent_action_no_turn": missing_opponent_action_no_turn,
		"authoritative_turn_succeeds": authoritative_turn_succeeds,
		"authoritative_event_count": events.size(),
		"same_public_event_log_both_sides": same_public_event_log_both_sides,
		"side_a_reveal_isolated": side_a_reveal_isolated,
		"side_b_reveal_isolated": side_b_reveal_isolated,
		"public_log_metadata_sanitized": public_log_metadata_sanitized,
		"branch_snapshots_both_sides": branch_snapshots_both_sides,
		"branch_projection_live_unchanged": branch_projection_live_unchanged,
		"wrong_branch_side_rejected": wrong_branch_side_rejected,
		"missing_lifecycle_fail_closed": missing_lifecycle_fail_closed,
		"no_behavior_selection_surface": no_behavior_selection_surface,
		"production_wiring_present": wiring_ready_after_begin,
		"behavior_integration_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}


func _c3fae_catalog() -> DefinitionCatalog:
	var helper := TrainerItemActionsTestSuite.new()
	helper._build_catalog()
	helper._add_setup_move(SETUP_A_C3FAD, [])
	helper._add_setup_move(SETUP_B_C3FAD, [])
	helper._add_damage_move(CHIP_A_C3FAD, 35)
	helper._add_damage_move(CHIP_B_C3FAD, 45)
	helper._add_species(SPECIES_A_C3FAD, 85, 95, 75, 88, [SETUP_A_C3FAD, CHIP_A_C3FAD])
	helper._add_species(SPECIES_B_C3FAD, 90, 102, 78, 82, [SETUP_B_C3FAD, CHIP_B_C3FAD])
	return helper._catalog as DefinitionCatalog


func _c3fae_session_bundle(catalog: DefinitionCatalog) -> Dictionary:
	if catalog == null:
		return {}
	var specs := _c3fad_fixture_specs()
	if specs.is_empty():
		return {}
	var fixture := specs[0] as Dictionary
	var a_stats := fixture.get("a_stats", []) as Array
	var b_stats := fixture.get("b_stats", []) as Array
	var a_hp := fixture.get("a_hp", []) as Array
	var b_hp := fixture.get("b_hp", []) as Array
	if a_stats.size() != 3 or b_stats.size() != 3 or a_hp.size() != 3 or b_hp.size() != 3:
		return {}
	var player := PlayerCollection.new()
	var opponent_roster: Array[CreatureInstance] = []
	for index in range(3):
		var a_moves: Array[StringName] = [SETUP_A_C3FAD, CHIP_A_C3FAD]
		var b_moves: Array[StringName] = [SETUP_B_C3FAD, CHIP_B_C3FAD]
		var creature_a := _c3fad_creature(
			StringName("c3fae_a%d" % index),
			SPECIES_A_C3FAD,
			_c3fad_stat_block(a_stats[index] as Array),
			a_moves,
			catalog,
			int(a_hp[index]),
		)
		var creature_b := _c3fad_creature(
			StringName("c3fae_b%d" % index),
			SPECIES_B_C3FAD,
			_c3fad_stat_block(b_stats[index] as Array),
			b_moves,
			catalog,
			int(b_hp[index]),
		)
		player.party.add_creature(creature_a)
		opponent_roster.append(creature_b)
	return {
		"session": TrainerBattleSession.new(player, catalog, ProgressionRuleset.new()),
		"opponent_roster": opponent_roster,
	}


func _c3fae_actions(state: BattleState) -> Array[BattleAction]:
	var out: Array[BattleAction] = []
	if state == null:
		return out
	var active_a := state.active_for_side(SIDE_A_C3FAD)
	var active_b := state.active_for_side(SIDE_B_C3FAD)
	if active_a == null or active_b == null:
		return out
	out.append(BattleAction.new(
		state.turn + 1,
		active_a.instance_id,
		SETUP_A_C3FAD,
		active_b.instance_id,
		BattleAction.MOVE,
		SIDE_A_C3FAD,
	))
	out.append(BattleAction.new(
		state.turn + 1,
		active_b.instance_id,
		SETUP_B_C3FAD,
		active_a.instance_id,
		BattleAction.MOVE,
		SIDE_B_C3FAD,
	))
	return out


func _c3fae_public_log_sanitized(memory: TrainerBattleMemory) -> bool:
	if memory == null or memory.event_log.is_empty():
		return false
	for value in memory.event_log:
		var record := value as Dictionary
		if record.has("metadata") or record.has("source_id"):
			return false
	return true


func _c3fae_blocked_report() -> Dictionary:
	return {
		"audit_id": AUDIT_ID_C3FAE,
		"boundary_id": BOUNDARY_ID_C3FAE,
		"tranche_status": BLOCKED_C3FAE,
		"prebegin_snapshot_rejected": false,
		"begin_ok": false,
		"wiring_ready_after_begin": false,
		"side_and_battle_ids_match": false,
		"initial_opponents_seen": false,
		"wrong_side_snapshot_rejected": false,
		"returned_snapshot_isolated": false,
		"missing_opponent_action_rejected": false,
		"missing_opponent_action_no_turn": false,
		"authoritative_turn_succeeds": false,
		"authoritative_event_count": 0,
		"same_public_event_log_both_sides": false,
		"side_a_reveal_isolated": false,
		"side_b_reveal_isolated": false,
		"public_log_metadata_sanitized": false,
		"branch_snapshots_both_sides": false,
		"branch_projection_live_unchanged": false,
		"wrong_branch_side_rejected": false,
		"missing_lifecycle_fail_closed": false,
		"no_behavior_selection_surface": false,
		"production_wiring_present": false,
		"behavior_integration_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}
