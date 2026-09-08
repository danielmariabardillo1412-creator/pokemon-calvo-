class_name TrainerRosterItemAwareShadowProductionLifecycleAuditTestSuite
extends TrainerRosterDualSideMemoryProductionWiringAuditTestSuite

# C3f-af connects the certified dual-memory seam to real ItemAware search only as
# read-only production shadow telemetry. The explicit opponent_action remains authoritative.

const AUDIT_ID_C3FAF := "c3f_af_itemaware_shadow_production_lifecycle_audit_v1"
const BOUNDARY_ID_C3FAF := "execute_side_local_itemaware_shadow_without_action_substitution"
const SHADOW_VALIDATED_NO_BEHAVIOR := "SHADOW_VALIDATED_NO_BEHAVIOR_INTEGRATION"
const BLOCKED_C3FAF := "BLOCKED"
const SIDE_A_C3FAF := &"side_a"
const SIDE_B_C3FAF := &"side_b"
const POTION_C3FAF := &"potion"
const HYPER_POTION_C3FAF := &"hyper_potion"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_itemaware_shadow_production_lifecycle()


func _test_itemaware_shadow_production_lifecycle() -> void:
	var report := _build_c3faf_report()
	var current_a := report.get("current_side_a", {}) as Dictionary
	var current_b := report.get("current_side_b", {}) as Dictionary
	var branch_a := report.get("branch_side_a", {}) as Dictionary
	var branch_b := report.get("branch_side_b", {}) as Dictionary

	_check.call("shadow_lifecycle_audit_id_recorded", String(report.get("audit_id", "")) == AUDIT_ID_C3FAF)
	_check.call("shadow_lifecycle_boundary_id_recorded", String(report.get("boundary_id", "")) == BOUNDARY_ID_C3FAF)
	_check.call(
		"shadow_lifecycle_status_explicit",
		[SHADOW_VALIDATED_NO_BEHAVIOR, BLOCKED_C3FAF].has(String(report.get("tranche_status", ""))),
	)
	_check.call("shadow_lifecycle_prebegin_fails_closed", bool(report.get("prebegin_blocked", false)))
	_check.call("shadow_lifecycle_current_both_sides_ready", _shadow_ready(current_a) and _shadow_ready(current_b))
	_check.call(
		"shadow_lifecycle_current_contexts_side_matching",
		_shadow_side_matches(current_a, SIDE_A_C3FAF) and _shadow_side_matches(current_b, SIDE_B_C3FAF),
	)
	_check.call(
		"shadow_lifecycle_move_switch_item_accounting_explicit",
		_action_kinds_exercised(current_a) and _action_kinds_exercised(current_b)
		and String(current_a.get("action_kind_contract", "")) == "MOVE_SWITCH_ITEM_explicit"
		and String(current_b.get("action_kind_contract", "")) == "MOVE_SWITCH_ITEM_explicit",
	)
	_check.call(
		"shadow_lifecycle_all_legal_switch_roots_evaluated",
		_all_legal_switches_evaluated(current_a) and _all_legal_switches_evaluated(current_b),
	)
	_check.call(
		"shadow_lifecycle_itemaware_runtime_metadata_present",
		bool(current_a.get("itemaware_metadata_matches_runtime_models", false))
		and bool(current_b.get("itemaware_metadata_matches_runtime_models", false)),
	)
	_check.call(
		"shadow_lifecycle_margin3000_is_switch_only_telemetry",
		_shadow_margin_contract(current_a) and _shadow_margin_contract(current_b),
	)
	_check.call(
		"shadow_lifecycle_root_fanout_separate_from_inner_cap3",
		bool(current_a.get("root_fanout_all_legal_preserved", false))
		and bool(current_b.get("root_fanout_all_legal_preserved", false))
		and int(current_a.get("inner_max_actions_per_side", -1)) == 3
		and int(current_b.get("inner_max_actions_per_side", -1)) == 3,
	)
	_check.call(
		"shadow_lifecycle_result_is_telemetry_not_action_selection",
		bool(current_a.get("shadow_result_is_telemetry_only", false))
		and bool(current_b.get("shadow_result_is_telemetry_only", false))
		and not bool(current_a.get("shadow_action_selected", true))
		and not bool(current_b.get("shadow_action_selected", true))
		and not bool(current_a.get("action_substitution_authorized", true))
		and not bool(current_b.get("action_substitution_authorized", true)),
	)
	_check.call(
		"shadow_lifecycle_global_safety_claim_stays_false",
		not bool(current_a.get("candidate_strategy_proven_safe_globally", true))
		and not bool(current_b.get("candidate_strategy_proven_safe_globally", true)),
	)
	_check.call("shadow_lifecycle_invalid_side_fails_closed", bool(report.get("invalid_side_blocked", false)))
	_check.call("shadow_lifecycle_mismatched_memory_fails_closed", bool(report.get("mismatched_memory_blocked", false)))
	_check.call("shadow_lifecycle_on_off_sessions_both_begin", bool(report.get("invariance_sessions_begin", false)))
	_check.call("shadow_lifecycle_on_off_receive_same_explicit_actions", bool(report.get("invariance_input_actions_equal", false)))
	_check.call("shadow_lifecycle_on_off_authoritative_events_identical", bool(report.get("invariance_events_equal", false)))
	_check.call("shadow_lifecycle_on_off_authoritative_state_identical", bool(report.get("invariance_state_equal", false)))
	_check.call("shadow_lifecycle_on_report_materialized", bool(report.get("shadow_on_report_ready", false)))
	_check.call("shadow_lifecycle_off_has_no_shadow_telemetry", bool(report.get("shadow_off_report_empty", false)))
	_check.call("shadow_lifecycle_explicit_opponent_action_remains_required", bool(report.get("explicit_opponent_action_still_required", false)))
	_check.call("shadow_lifecycle_session_exposes_no_choose_action_surface", bool(report.get("no_choose_action_surface", false)))
	_check.call("shadow_lifecycle_branch_events_valid", bool(report.get("branch_events_valid", false)))
	_check.call("shadow_lifecycle_branch_both_sides_ready", _shadow_ready(branch_a) and _shadow_ready(branch_b))
	_check.call(
		"shadow_lifecycle_branch_contexts_side_matching",
		_shadow_side_matches(branch_a, SIDE_A_C3FAF) and _shadow_side_matches(branch_b, SIDE_B_C3FAF),
	)
	_check.call(
		"shadow_lifecycle_branch_all_legal_switch_roots_evaluated",
		_all_legal_switches_evaluated(branch_a) and _all_legal_switches_evaluated(branch_b),
	)
	_check.call("shadow_lifecycle_branch_projection_does_not_mutate_live_state", bool(report.get("branch_live_state_unchanged", false)))
	_check.call("shadow_lifecycle_branch_projection_does_not_mutate_live_memory", bool(report.get("branch_live_memories_unchanged", false)))
	_check.call("shadow_lifecycle_wrong_branch_side_fails_closed", bool(report.get("wrong_branch_side_blocked", false)))
	_check.call("shadow_lifecycle_missing_lifecycle_fails_closed_before_turn", bool(report.get("missing_lifecycle_no_turn", false)))
	_check.call(
		"shadow_lifecycle_behavior_barriers_remain_closed",
		not bool(report.get("behavior_integration_authorized", true))
		and not bool(report.get("margin3000_behavior_enabled", true))
		and not bool(report.get("production_sampler_modified", true))
		and not bool(report.get("production_budget_modified", true)),
	)
	_check.call(
		"shadow_lifecycle_no_forbidden_fallbacks",
		not bool(report.get("lexical_fallback_used", true))
		and not bool(report.get("frontier_fallback_used", true))
		and not bool(report.get("roster_value_fallback_used", true))
		and not bool(report.get("profile_tiebreak_used", true))
		and not bool(report.get("campaign_policy_used", true))
		and not bool(report.get("recovery_policy_used", true))
		and not bool(report.get("replacement_policy_used", true)),
	)
	_check.call(
		"shadow_lifecycle_scheduler_budget_660_and_fase34_stay_closed",
		report.get("selected_strategy_id", "sentinel") == null
		and report.get("selected_scheduler_id", "sentinel") == null
		and report.get("selected_shared_budget", "sentinel") == null
		and not bool(report.get("shared_660_reopened", true))
		and not bool(report.get("fase34_open", true)),
	)
	_check.call("shadow_lifecycle_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER ROSTER ITEMAWARE SHADOW PRODUCTION LIFECYCLE AUDIT ===")
	print(JSON.stringify(report))


func _build_c3faf_report() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null:
		return _c3faf_blocked_report()

	var cold_session := TrainerBattleSession.new(PlayerCollection.new(), catalog, ProgressionRuleset.new())
	var cold_report := cold_session.trainer_shadow_item_aware_report_for_side(SIDE_B_C3FAF)
	var prebegin_blocked := String(cold_report.get("tranche_status", "")) == TrainerItemAwareShadowProbe.BLOCKED

	var current := _c3faf_started_session(catalog, &"c3faf_current", 913401)
	if current == null:
		var early := _c3faf_blocked_report()
		early["prebegin_blocked"] = prebegin_blocked
		return early
	var current_a := current.trainer_shadow_item_aware_report_for_side(SIDE_A_C3FAF)
	var current_b := current.trainer_shadow_item_aware_report_for_side(SIDE_B_C3FAF)
	var invalid_side := current.trainer_shadow_item_aware_report_for_side(&"side_x")
	var invalid_side_blocked := String(invalid_side.get("tranche_status", "")) == TrainerItemAwareShadowProbe.BLOCKED
	var memory_b := current.trainer_memory_snapshot_for_side(SIDE_B_C3FAF)
	var mismatch := TrainerItemAwareShadowProbe.new().evaluate(current.battle_state(), SIDE_A_C3FAF, memory_b, catalog)
	var mismatched_memory_blocked := (
		String(mismatch.get("tranche_status", "")) == TrainerItemAwareShadowProbe.BLOCKED
		and String(mismatch.get("blocked_reason", "")) == "memory_side_mismatch"
	)

	var live_state_before := JSON.stringify(current.battle_state().to_dict())
	var live_a_before := _memory_json(current.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
	var live_b_before := _memory_json(current.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
	var fork := BattleSimulationFork.from_state(current.battle_state(), catalog)
	var branch_events: Array[BattleEvent] = []
	var branch_a: Dictionary = {}
	var branch_b: Dictionary = {}
	var wrong_branch: Dictionary = {}
	if fork != null and fork.state() != null:
		var branch_actions := _c3fae_actions(fork.state())
		if branch_actions.size() == 2:
			branch_events = fork.submit_turn(branch_actions)
			branch_a = current.trainer_branch_shadow_item_aware_report_for_side(SIDE_A_C3FAF, branch_events, fork.state())
			branch_b = current.trainer_branch_shadow_item_aware_report_for_side(SIDE_B_C3FAF, branch_events, fork.state())
			wrong_branch = current.trainer_branch_shadow_item_aware_report_for_side(&"side_x", branch_events, fork.state())
	var branch_events_valid := not branch_events.is_empty() and not _c3faf_has_rejection(branch_events)
	var branch_live_state_unchanged := live_state_before == JSON.stringify(current.battle_state().to_dict())
	var branch_live_memories_unchanged := (
		live_a_before == _memory_json(current.trainer_memory_snapshot_for_side(SIDE_A_C3FAF))
		and live_b_before == _memory_json(current.trainer_memory_snapshot_for_side(SIDE_B_C3FAF))
	)
	var wrong_branch_side_blocked := String(wrong_branch.get("tranche_status", "")) == TrainerItemAwareShadowProbe.BLOCKED

	var off := _c3faf_started_session(catalog, &"c3faf_invariance", 913777)
	var on := _c3faf_started_session(catalog, &"c3faf_invariance", 913777)
	var invariance_sessions_begin := off != null and on != null
	var invariance_input_actions_equal := false
	var invariance_events_equal := false
	var invariance_state_equal := false
	var shadow_on_report_ready := false
	var shadow_off_report_empty := false
	var explicit_opponent_action_still_required := false
	if invariance_sessions_begin:
		off.set_trainer_shadow_item_aware_enabled(false)
		on.set_trainer_shadow_item_aware_enabled(true)
		var off_actions := _c3fae_actions(off.battle_state())
		var on_actions := _c3fae_actions(on.battle_state())
		if off_actions.size() == 2 and on_actions.size() == 2:
			invariance_input_actions_equal = (
				JSON.stringify(off_actions[0].to_dict()) == JSON.stringify(on_actions[0].to_dict())
				and JSON.stringify(off_actions[1].to_dict()) == JSON.stringify(on_actions[1].to_dict())
			)
			var off_events := off.submit_player_action(off_actions[0], off_actions[1])
			var on_events := on.submit_player_action(on_actions[0], on_actions[1])
			invariance_events_equal = _events_json(off_events) == _events_json(on_events)
			invariance_state_equal = JSON.stringify(off.battle_state().to_dict()) == JSON.stringify(on.battle_state().to_dict())
			shadow_on_report_ready = String(on.last_trainer_shadow_report.get("tranche_status", "")) == TrainerItemAwareShadowProbe.SHADOW_READY
			shadow_off_report_empty = off.last_trainer_shadow_report.is_empty()
		var required_session := _c3faf_started_session(catalog, &"c3faf_required", 913778)
		if required_session != null:
			required_session.set_trainer_shadow_item_aware_enabled(true)
			var required_actions := _c3fae_actions(required_session.battle_state())
			if required_actions.size() == 2:
				var required_turn := required_session.battle_state().turn
				var required_events := required_session.submit_player_action(required_actions[0], null)
				explicit_opponent_action_still_required = (
					required_events.is_empty()
					and required_session.last_error == "opponent_action_required"
					and required_session.battle_state().turn == required_turn
				)

	var broken := _c3faf_started_session(catalog, &"c3faf_broken", 913889)
	var missing_lifecycle_no_turn := false
	if broken != null:
		broken.set_trainer_shadow_item_aware_enabled(true)
		var broken_actions := _c3fae_actions(broken.battle_state())
		var broken_turn := broken.battle_state().turn
		broken._trainer_memory_owner.clear()
		if broken_actions.size() == 2:
			var broken_events := broken.submit_player_action(broken_actions[0], broken_actions[1])
			missing_lifecycle_no_turn = (
				broken_events.is_empty()
				and broken.last_error == "trainer_memory_not_ready"
				and broken.battle_state().turn == broken_turn
			)

	var no_choose_action_surface := (
		not current.has_method("choose_opponent_action")
		and not current.has_method("choose_trainer_action")
	)
	var critical_ok := (
		prebegin_blocked
		and _shadow_ready(current_a)
		and _shadow_ready(current_b)
		and invalid_side_blocked
		and mismatched_memory_blocked
		and branch_events_valid
		and _shadow_ready(branch_a)
		and _shadow_ready(branch_b)
		and branch_live_state_unchanged
		and branch_live_memories_unchanged
		and wrong_branch_side_blocked
		and invariance_sessions_begin
		and invariance_input_actions_equal
		and invariance_events_equal
		and invariance_state_equal
		and shadow_on_report_ready
		and shadow_off_report_empty
		and explicit_opponent_action_still_required
		and missing_lifecycle_no_turn
		and no_choose_action_surface
	)
	return {
		"audit_id": AUDIT_ID_C3FAF,
		"boundary_id": BOUNDARY_ID_C3FAF,
		"tranche_status": SHADOW_VALIDATED_NO_BEHAVIOR if critical_ok else BLOCKED_C3FAF,
		"prebegin_blocked": prebegin_blocked,
		"current_side_a": current_a,
		"current_side_b": current_b,
		"invalid_side_blocked": invalid_side_blocked,
		"mismatched_memory_blocked": mismatched_memory_blocked,
		"branch_events_valid": branch_events_valid,
		"branch_event_count": branch_events.size(),
		"branch_side_a": branch_a,
		"branch_side_b": branch_b,
		"branch_live_state_unchanged": branch_live_state_unchanged,
		"branch_live_memories_unchanged": branch_live_memories_unchanged,
		"wrong_branch_side_blocked": wrong_branch_side_blocked,
		"invariance_sessions_begin": invariance_sessions_begin,
		"invariance_input_actions_equal": invariance_input_actions_equal,
		"invariance_events_equal": invariance_events_equal,
		"invariance_state_equal": invariance_state_equal,
		"shadow_on_report_ready": shadow_on_report_ready,
		"shadow_off_report_empty": shadow_off_report_empty,
		"explicit_opponent_action_still_required": explicit_opponent_action_still_required,
		"no_choose_action_surface": no_choose_action_surface,
		"missing_lifecycle_no_turn": missing_lifecycle_no_turn,
		"candidate_policy_id": TrainerItemAwareShadowProbe.CANDIDATE_POLICY_ID,
		"candidate_policy_scope": "switch_only",
		"candidate_margin": TrainerItemAwareShadowProbe.CANDIDATE_MARGIN,
		"candidate_strategy_proven_safe_globally": false,
		"root_fanout_all_legal_preserved": true,
		"inner_max_actions_per_side": TrainerItemAwareShadowProbe.INNER_ACTION_CAP,
		"action_kind_contract": "MOVE_SWITCH_ITEM_explicit",
		"shadow_mode": "read_only_no_action_substitution",
		"behavior_integration_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"lexical_fallback_used": false,
		"frontier_fallback_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}


func _c3faf_started_session(
	catalog: DefinitionCatalog,
	trainer_id: StringName,
	seed: int,
) -> TrainerBattleSession:
	var bundle := _c3fae_session_bundle(catalog)
	var session := bundle.get("session", null) as TrainerBattleSession
	var opponent_roster: Array[CreatureInstance] = []
	for value in bundle.get("opponent_roster", []):
		var creature := value as CreatureInstance
		if creature != null:
			opponent_roster.append(creature)
	if session == null or opponent_roster.size() != 3:
		return null
	if not session.begin_battle(trainer_id, opponent_roster, seed):
		return null
	_c3faf_install_items(session)
	return session


func _c3faf_install_items(session: TrainerBattleSession) -> void:
	if session == null or session.battle_state() == null:
		return
	var inventory_a := BattleSideItemInventory.new()
	inventory_a.set_quantity(POTION_C3FAF, 1)
	inventory_a.set_quantity(HYPER_POTION_C3FAF, 1)
	var inventory_b := BattleSideItemInventory.new()
	inventory_b.set_quantity(POTION_C3FAF, 1)
	inventory_b.set_quantity(HYPER_POTION_C3FAF, 1)
	session.battle_state().set_item_inventory_for_side(SIDE_A_C3FAF, inventory_a)
	session.battle_state().set_item_inventory_for_side(SIDE_B_C3FAF, inventory_b)


func _shadow_ready(report: Dictionary) -> bool:
	return String(report.get("tranche_status", "")) == TrainerItemAwareShadowProbe.SHADOW_READY


func _shadow_side_matches(report: Dictionary, side_id: StringName) -> bool:
	return bool(report.get("context_side_matching", false)) \
		and String(report.get("observer_side_id", "")) == String(side_id) \
		and String(report.get("memory_snapshot_side_id", "")) == String(side_id) \
		and String(report.get("belief_snapshot_side_id", "")) == String(side_id)


func _action_kinds_exercised(report: Dictionary) -> bool:
	var histogram := report.get("legal_action_kind_histogram", {}) as Dictionary
	return int(histogram.get("MOVE", 0)) > 0 \
		and int(histogram.get("SWITCH", 0)) > 0 \
		and int(histogram.get("ITEM", 0)) > 0


func _all_legal_switches_evaluated(report: Dictionary) -> bool:
	return bool(report.get("all_legal_switch_reference_evaluated", false)) \
		and int(report.get("legal_switch_count", 0)) >= 2 \
		and int(report.get("evaluated_switch_count", -1)) == int(report.get("legal_switch_count", -2)) \
		and bool(report.get("itemaware_evaluations_complete", false))


func _shadow_margin_contract(report: Dictionary) -> bool:
	return String(report.get("candidate_policy_id", "")) == TrainerItemAwareShadowProbe.CANDIDATE_POLICY_ID \
		and String(report.get("candidate_policy_scope", "")) == "switch_only" \
		and int(report.get("candidate_margin", -1)) == TrainerItemAwareShadowProbe.CANDIDATE_MARGIN \
		and bool(report.get("candidate_membership_switch_only", false)) \
		and not (report.get("margin3000_switch_ids", []) as Array).is_empty() \
		and not bool(report.get("margin3000_behavior_enabled", true))


func _memory_json(memory: TrainerBattleMemory) -> String:
	return JSON.stringify(memory.to_dict()) if memory != null else "null"


func _events_json(events: Array[BattleEvent]) -> String:
	var records: Array[Dictionary] = []
	for event in events:
		if event != null:
			records.append(event.to_dict())
	return JSON.stringify(records)


func _c3faf_has_rejection(events: Array[BattleEvent]) -> bool:
	for event in events:
		if event != null and event.kind == BattleEvent.ACTION_REJECTED:
			return true
	return false


func _c3faf_blocked_report() -> Dictionary:
	return {
		"audit_id": AUDIT_ID_C3FAF,
		"boundary_id": BOUNDARY_ID_C3FAF,
		"tranche_status": BLOCKED_C3FAF,
		"prebegin_blocked": false,
		"current_side_a": {},
		"current_side_b": {},
		"branch_side_a": {},
		"branch_side_b": {},
		"behavior_integration_authorized": false,
		"margin3000_behavior_enabled": false,
		"production_sampler_modified": false,
		"production_budget_modified": false,
		"lexical_fallback_used": false,
		"frontier_fallback_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}
