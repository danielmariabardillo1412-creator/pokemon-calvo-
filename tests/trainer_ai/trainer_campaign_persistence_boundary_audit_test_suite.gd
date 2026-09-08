class_name TrainerCampaignPersistenceBoundaryAuditTestSuite
extends TrainerBattleSessionCrossBattleResetLifecycleAuditTestSuite

# P1-A is strictly TEST/AUDIT-ONLY. It localizes the ownership seam that exists
# between TrainerBattleSession and its caller before any campaign/recovery/replacement
# policy is designed or implemented.
const P1A_AUDIT_ID := "p1_a_campaign_persistence_ownership_boundary_audit_v1"
const GAP_LOCALIZED := "CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED"
const P1A_BLOCKED := "BLOCKED"

var _p1a_check: Callable


func run(check_callback: Callable) -> void:
	_p1a_check = check_callback
	var report := _build_p1a_report()
	var runtime := report.get("runtime_ownership_probe", {}) as Dictionary
	var source := report.get("source_trace", {}) as Dictionary
	var files := report.get("policy_file_scan", {}) as Dictionary

	_p1a_check.call("p1a_audit_id", String(report.get("audit_id", "")) == P1A_AUDIT_ID)
	_p1a_check.call("p1a_gap_localized", String(report.get("tranche_status", "")) == GAP_LOCALIZED)
	_p1a_check.call("p1a_runtime_probe_started", bool(runtime.get("session_started", false)) and bool(runtime.get("live_opponent_found", false)))
	_p1a_check.call("p1a_live_state_shares_session_roster_identity", bool(runtime.get("live_matches_session_roster_reference", false)))
	_p1a_check.call("p1a_live_mutation_visible_through_session_roster", bool(runtime.get("mutation_visible_through_session_roster", false)))
	_p1a_check.call("p1a_session_accepts_external_roster", bool(source.get("session_accepts_external_roster", false)))
	_p1a_check.call("p1a_living_roster_reuses_creature_objects", bool(source.get("living_roster_reuses_creature_objects", false)))
	_p1a_check.call("p1a_session_keeps_shallow_roster_array", bool(source.get("session_keeps_shallow_roster_array", false)))
	_p1a_check.call("p1a_settlement_reconciles_opponent_objects", bool(source.get("settlement_reconciles_opponent_roster", false)))
	_p1a_check.call("p1a_settlement_releases_session_roster", bool(source.get("settlement_clears_session_roster", false)))
	_p1a_check.call("p1a_reset_clears_opponent_identity", bool(source.get("reset_clears_opponent_identity", false)))
	_p1a_check.call("p1a_overworld_owns_roster_outside_session", bool(source.get("overworld_owns_trainer_roster", false)))
	_p1a_check.call("p1a_overworld_builds_roster_before_battle", bool(source.get("overworld_builds_roster_in_bootstrap", false)))
	_p1a_check.call("p1a_demo_is_one_shot_after_completion", bool(source.get("overworld_blocks_rematch_after_completion", false)))
	_p1a_check.call("p1a_historical_campaign_snapshot_transport_exists", bool(source.get("historical_campaign_snapshot_transport_exists", false)))
	_p1a_check.call("p1a_historical_campaign_snapshot_is_deep_detached", bool(source.get("historical_campaign_snapshot_deep_detached", false)))
	_p1a_check.call("p1a_game_ready_proposal_keeps_campaign_snapshot_disconnected", bool(source.get("game_ready_proposal_omits_campaign_snapshot", false)))
	_p1a_check.call("p1a_no_dedicated_campaign_policy_owner", bool(files.get("no_dedicated_campaign_policy_owner", false)))
	_p1a_check.call("p1a_no_dedicated_recovery_policy_owner", bool(files.get("no_dedicated_recovery_policy_owner", false)))
	_p1a_check.call("p1a_no_dedicated_replacement_policy_owner", bool(files.get("no_dedicated_replacement_policy_owner", false)))
	_p1a_check.call("p1a_battle_ai_reports_keep_campaign_policies_off", bool(source.get("proposal_campaign_recovery_replacement_flags_false", false)))
	_p1a_check.call("p1a_scope_audit_only", bool(report.get("audit_only_scope", false)) and not bool(report.get("production_modified", true)) and not bool(report.get("battle_core_modified", true)))
	_p1a_check.call("p1a_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER CAMPAIGN P1-A PERSISTENCE OWNERSHIP BOUNDARY AUDIT ===")
	print(JSON.stringify(report))


func _build_p1a_report() -> Dictionary:
	var runtime := _p1a_runtime_ownership_probe()
	var source := _p1a_source_trace()
	var files := _p1a_policy_file_scan()
	var localized := (
		bool(runtime.get("session_started", false))
		and bool(runtime.get("live_matches_session_roster_reference", false))
		and bool(runtime.get("mutation_visible_through_session_roster", false))
		and bool(source.get("session_accepts_external_roster", false))
		and bool(source.get("living_roster_reuses_creature_objects", false))
		and bool(source.get("session_keeps_shallow_roster_array", false))
		and bool(source.get("settlement_reconciles_opponent_roster", false))
		and bool(source.get("settlement_clears_session_roster", false))
		and bool(source.get("overworld_owns_trainer_roster", false))
		and bool(source.get("overworld_blocks_rematch_after_completion", false))
		and bool(source.get("historical_campaign_snapshot_transport_exists", false))
		and bool(source.get("historical_campaign_snapshot_deep_detached", false))
		and bool(source.get("game_ready_proposal_omits_campaign_snapshot", false))
		and bool(files.get("no_dedicated_campaign_policy_owner", false))
		and bool(files.get("no_dedicated_recovery_policy_owner", false))
		and bool(files.get("no_dedicated_replacement_policy_owner", false))
	)
	return {
		"audit_id": P1A_AUDIT_ID,
		"tranche_status": GAP_LOCALIZED if localized else P1A_BLOCKED,
		"runtime_ownership_probe": runtime,
		"source_trace": source,
		"policy_file_scan": files,
		"ownership_conclusion": "caller_can_own_same_creature_objects_but_session_releases_post_battle_roster",
		"historical_campaign_snapshot_transport_implemented": bool(source.get("historical_campaign_snapshot_transport_exists", false)),
		"game_ready_campaign_snapshot_connected": not bool(source.get("game_ready_proposal_omits_campaign_snapshot", false)),
		"campaign_persistence_owner_implemented": false,
		"recovery_policy_implemented": false,
		"replacement_policy_implemented": false,
		"durable_trainer_registry_implemented": false,
		"rematch_lifecycle_implemented_in_executable_slice": false,
		"battle_core_modified": false,
		"production_modified": false,
		"audit_only_scope": true,
	}


func _p1a_runtime_ownership_probe() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null or not _c3fan_tune_catalog(catalog):
		return {}
	var session := _c3faf_started_session(catalog, &"p1a_ownership_probe", 931001)
	if session == null or session.battle_state() == null:
		return {}
	var live_opponent := session.opponent_active()
	if live_opponent == null:
		return {"session_started": true, "live_opponent_found": false}

	var matching_session_creature: CreatureInstance = null
	for creature in session._opponent_roster:
		if creature != null and creature.instance_id == live_opponent.instance_id:
			matching_session_creature = creature
			break
	var same_reference := matching_session_creature != null and matching_session_creature == live_opponent
	var hp_before := live_opponent.current_hp
	var hp_after := maxi(0, hp_before - 1)
	live_opponent.current_hp = hp_after
	var mutation_visible := matching_session_creature != null and matching_session_creature.current_hp == hp_after
	live_opponent.current_hp = hp_before

	return {
		"session_started": true,
		"live_opponent_found": true,
		"opponent_instance_id": String(live_opponent.instance_id),
		"live_matches_session_roster_reference": same_reference,
		"hp_before": hp_before,
		"probe_hp": hp_after,
		"mutation_visible_through_session_roster": mutation_visible,
	}


func _p1a_source_trace() -> Dictionary:
	var session_source := FileAccess.get_file_as_string("res://modules/gameplay/trainer_battle_session.gd")
	var overworld_source := FileAccess.get_file_as_string("res://scenes/overworld/technical_overworld.gd")
	var controller_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_intelligence_controller.gd")
	var context_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_decision_context.gd")
	var proposal_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_item_aware_action_proposal.gd")
	return {
		"session_accepts_external_roster": session_source.contains("p_opponent_roster: Array[CreatureInstance]") and session_source.contains("_roster_with_living_active(p_opponent_roster)"),
		"living_roster_reuses_creature_objects": session_source.contains("var roster: Array[CreatureInstance] = [first_living]") and session_source.contains("roster.append(creature)"),
		"session_keeps_shallow_roster_array": session_source.contains("_opponent_roster = trainer_roster.duplicate()"),
		"settlement_reconciles_opponent_roster": session_source.contains("_reconcile_roster(_opponent_roster)"),
		"settlement_clears_session_roster": session_source.contains("_opponent_roster.clear()"),
		"reset_clears_opponent_identity": session_source.contains("opponent_trainer_id = &\"\""),
		"overworld_owns_trainer_roster": overworld_source.contains("var _trainer_roster: Array[CreatureInstance] = []"),
		"overworld_builds_roster_in_bootstrap": overworld_source.contains("_trainer_roster.append(trainer_creature)"),
		"overworld_blocks_rematch_after_completion": overworld_source.contains("if _trainer_demo_completed:") and overworld_source.contains("_trainer_demo_completed = true"),
		"historical_campaign_snapshot_transport_exists": controller_source.contains("var _campaign_snapshot: Dictionary = {}") and controller_source.contains("func set_campaign_snapshot(p_campaign_snapshot: Dictionary) -> void:") and controller_source.contains("_campaign_snapshot,") and context_source.contains("var campaign_snapshot: Dictionary = {}"),
		"historical_campaign_snapshot_deep_detached": controller_source.contains("_campaign_snapshot = p_campaign_snapshot.duplicate(true)") and context_source.contains("context.campaign_snapshot = p_campaign_snapshot.duplicate(true)"),
		"game_ready_proposal_omits_campaign_snapshot": proposal_source.contains("TrainerDecisionContext.create(observation, belief, memory_clone, legal_actions)") and not proposal_source.contains("campaign_snapshot"),
		"proposal_campaign_recovery_replacement_flags_false": session_source.contains("\"campaign_policy_used\": false") and session_source.contains("\"recovery_policy_used\": false") and session_source.contains("\"replacement_policy_used\": false"),
	}


func _p1a_policy_file_scan() -> Dictionary:
	var candidate_files: Array[String] = []
	var roots: Array[String] = ["res://modules/trainer_ai", "res://modules/gameplay"]
	for root in roots:
		var dir := DirAccess.open(root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry := dir.get_next()
		while not entry.is_empty():
			if not dir.current_is_dir() and entry.ends_with(".gd"):
				candidate_files.append("%s/%s" % [root, entry])
			entry = dir.get_next()
		dir.list_dir_end()

	var campaign_files: Array[String] = []
	var recovery_files: Array[String] = []
	var replacement_files: Array[String] = []
	for path in candidate_files:
		var name := path.get_file().to_lower()
		if name.contains("campaign"):
			campaign_files.append(path)
		if name.contains("recovery"):
			recovery_files.append(path)
		if name.contains("replacement"):
			replacement_files.append(path)
	return {
		"scanned_top_level_gd_files": candidate_files.size(),
		"campaign_named_files": campaign_files,
		"recovery_named_files": recovery_files,
		"replacement_named_files": replacement_files,
		"no_dedicated_campaign_policy_owner": campaign_files.is_empty(),
		"no_dedicated_recovery_policy_owner": recovery_files.is_empty(),
		"no_dedicated_replacement_policy_owner": replacement_files.is_empty(),
	}
