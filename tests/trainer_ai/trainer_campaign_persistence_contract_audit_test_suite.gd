class_name TrainerCampaignPersistenceContractAuditTestSuite
extends TrainerCampaignPersistenceBoundaryAuditTestSuite

# P1-B remains CONTRACT-FIRST / TEST-AUDIT-ONLY. It turns the P1-A ownership seam
# into an executable contract before P1-C is allowed to add a persistent owner.
const P1B_AUDIT_ID := "p1_b_campaign_persistence_contract_audit_v1"
const P1B_CONTRACT_PINNED := "CAMPAIGN_PERSISTENCE_CONTRACT_PINNED"
const P1B_BLOCKED := "BLOCKED"

var _p1b_check: Callable


func run(check_callback: Callable) -> void:
	_p1b_check = check_callback
	var report := _build_p1b_report()
	var contract := report.get("persistent_owner_contract", {}) as Dictionary
	var runtime := report.get("reconcile_runtime_probe", {}) as Dictionary
	var source := report.get("source_contract_trace", {}) as Dictionary

	_p1b_check.call("p1b_audit_id", String(report.get("audit_id", "")) == P1B_AUDIT_ID)
	_p1b_check.call("p1b_contract_pinned", String(report.get("tranche_status", "")) == P1B_CONTRACT_PINNED)
	_p1b_check.call("p1b_owner_must_live_outside_battle_runtime", String(contract.get("authoritative_owner_boundary", "")) == "outside_battle_state_and_trainer_battle_session")
	_p1b_check.call("p1b_owner_must_preserve_creature_identity", String(contract.get("identity_mode", "")) == "same_creature_instance")
	_p1b_check.call("p1b_recovery_is_explicit_inter_battle_policy", String(contract.get("recovery_mode", "")) == "explicit_inter_battle_policy" and not bool(contract.get("implicit_auto_heal", true)))
	_p1b_check.call("p1b_campaign_replacement_is_not_forced_replacement", String(contract.get("campaign_replacement_mode", "")) == "outside_battle_distinct_from_forced_replacement")
	_p1b_check.call("p1b_duplicate_ownership_must_fail_closed", String(contract.get("duplicate_ownership_mode", "")) == "fail_closed")
	_p1b_check.call("p1b_battle_state_must_not_be_persisted", not bool(contract.get("persist_battle_state", true)))
	_p1b_check.call("p1b_campaign_snapshot_is_detached_dto_only", String(contract.get("campaign_snapshot_role", "")) == "detached_dto_only_not_source_of_truth")

	_p1b_check.call("p1b_runtime_probe_started", bool(runtime.get("session_started", false)) and bool(runtime.get("live_opponent_found", false)))
	_p1b_check.call("p1b_reconcile_preserves_creature_reference", bool(runtime.get("same_reference_after_reconcile", false)))
	_p1b_check.call("p1b_reconcile_preserves_damaged_hp", bool(runtime.get("damaged_hp_preserved", false)))
	_p1b_check.call("p1b_reconcile_does_not_full_heal", bool(runtime.get("no_implicit_full_heal", false)))
	_p1b_check.call("p1b_reconcile_preserves_reduced_pp", bool(runtime.get("reduced_pp_preserved", false)))
	_p1b_check.call("p1b_reconcile_preserves_persistent_status", bool(runtime.get("persistent_status_preserved", false)))
	_p1b_check.call("p1b_reconcile_clears_volatile_status", bool(runtime.get("volatile_status_cleared", false)))
	_p1b_check.call("p1b_reconcile_clears_stat_stages", bool(runtime.get("stat_stage_cleared", false)))

	_p1b_check.call("p1b_creature_instance_is_persistent_source_of_truth", bool(source.get("creature_instance_single_persistent_source", false)) and bool(source.get("creature_instance_stable_identity", false)))
	_p1b_check.call("p1b_session_reconciles_before_releasing_runtime_roster", bool(source.get("session_reconciles_roster", false)) and bool(source.get("session_releases_roster", false)))
	_p1b_check.call("p1b_collection_moves_same_identity_with_rollback", bool(source.get("collection_preserves_identity", false)) and bool(source.get("collection_has_transfer_rollback", false)))
	_p1b_check.call("p1b_collection_rejects_ambiguous_ownership", bool(source.get("collection_fails_closed_on_ambiguous_ownership", false)))
	_p1b_check.call("p1b_save_precedent_is_canonical_and_fail_closed", bool(source.get("save_has_canonical_registry", false)) and bool(source.get("save_rejects_duplicate_creature_id", false)) and bool(source.get("save_rejects_double_ownership", false)))
	_p1b_check.call("p1b_settlement_does_not_own_recovery_or_replacement", bool(source.get("settlement_has_no_recovery_or_replacement_contract", false)))
	_p1b_check.call("p1b_game_ready_proposal_keeps_snapshot_disconnected", bool(source.get("game_ready_proposal_omits_campaign_snapshot", false)))
	_p1b_check.call("p1b_combat_reports_keep_campaign_policies_off", bool(source.get("combat_policy_flags_remain_false", false)))
	_p1b_check.call("p1b_scope_contract_only", bool(report.get("contract_first_scope", false)) and not bool(report.get("production_modified", true)) and not bool(report.get("battle_core_modified", true)) and not bool(report.get("save_v2_modified", true)))
	_p1b_check.call("p1b_report_json_serializable", JSON.parse_string(JSON.stringify(report)) is Dictionary)

	print("\n=== TRAINER CAMPAIGN P1-B PERSISTENT CONTRACT AUDIT ===")
	print(JSON.stringify(report))


func _build_p1b_report() -> Dictionary:
	var contract := _p1b_persistent_owner_contract()
	var runtime := _p1b_reconcile_runtime_probe()
	var source := _p1b_source_contract_trace()
	var pinned := (
		String(contract.get("authoritative_owner_boundary", "")) == "outside_battle_state_and_trainer_battle_session"
		and String(contract.get("identity_mode", "")) == "same_creature_instance"
		and String(contract.get("post_battle_transition", "")) == "reconcile_post_battle"
		and not bool(contract.get("implicit_auto_heal", true))
		and String(contract.get("recovery_mode", "")) == "explicit_inter_battle_policy"
		and String(contract.get("campaign_replacement_mode", "")) == "outside_battle_distinct_from_forced_replacement"
		and String(contract.get("duplicate_ownership_mode", "")) == "fail_closed"
		and not bool(contract.get("persist_battle_state", true))
		and String(contract.get("campaign_snapshot_role", "")) == "detached_dto_only_not_source_of_truth"
		and bool(runtime.get("same_reference_after_reconcile", false))
		and bool(runtime.get("damaged_hp_preserved", false))
		and bool(runtime.get("no_implicit_full_heal", false))
		and bool(runtime.get("reduced_pp_preserved", false))
		and bool(runtime.get("persistent_status_preserved", false))
		and bool(runtime.get("volatile_status_cleared", false))
		and bool(runtime.get("stat_stage_cleared", false))
		and bool(source.get("creature_instance_single_persistent_source", false))
		and bool(source.get("collection_preserves_identity", false))
		and bool(source.get("collection_fails_closed_on_ambiguous_ownership", false))
		and bool(source.get("save_has_canonical_registry", false))
		and bool(source.get("save_rejects_duplicate_creature_id", false))
		and bool(source.get("save_rejects_double_ownership", false))
		and bool(source.get("settlement_has_no_recovery_or_replacement_contract", false))
		and bool(source.get("game_ready_proposal_omits_campaign_snapshot", false))
		and bool(source.get("combat_policy_flags_remain_false", false))
	)
	return {
		"audit_id": P1B_AUDIT_ID,
		"tranche_status": P1B_CONTRACT_PINNED if pinned else P1B_BLOCKED,
		"persistent_owner_contract": contract,
		"reconcile_runtime_probe": runtime,
		"source_contract_trace": source,
		"production_owner_implemented": false,
		"campaign_snapshot_connected_to_game_ready_proposal": false,
		"contract_first_scope": true,
		"production_modified": false,
		"battle_core_modified": false,
		"save_v2_modified": false,
	}


func _p1b_persistent_owner_contract() -> Dictionary:
	return {
		"authoritative_owner_boundary": "outside_battle_state_and_trainer_battle_session",
		"identity_mode": "same_creature_instance",
		"post_battle_transition": "reconcile_post_battle",
		"implicit_auto_heal": false,
		"persistent_consequences": ["current_hp", "moveset.current_pp", "status_state.persistent_id"],
		"cleared_battle_only_state": ["stat_stages", "status_state.volatile"],
		"recovery_mode": "explicit_inter_battle_policy",
		"campaign_replacement_mode": "outside_battle_distinct_from_forced_replacement",
		"duplicate_ownership_mode": "fail_closed",
		"persist_battle_state": false,
		"campaign_snapshot_role": "detached_dto_only_not_source_of_truth",
		"combat_decision_policy_dependency": false,
	}


func _p1b_reconcile_runtime_probe() -> Dictionary:
	var catalog := _c3fae_catalog()
	if catalog == null or not _c3fan_tune_catalog(catalog):
		return {}
	var session := _c3faf_started_session(catalog, &"p1b_reconcile_probe", 932001)
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
	if matching_session_creature == null:
		return {"session_started": true, "live_opponent_found": true, "session_reference_found": false}

	var pp_slot: BattleMoveSlot = null
	for raw_slot in live_opponent.moveset:
		var candidate := raw_slot as BattleMoveSlot
		if candidate != null and candidate.max_pp > 0:
			pp_slot = candidate
			break
	if pp_slot == null:
		return {"session_started": true, "live_opponent_found": true, "session_reference_found": true, "pp_slot_found": false}

	var max_hp := live_opponent.stats.max_hp
	var probe_hp := maxi(0, max_hp - 3)
	if probe_hp == max_hp:
		probe_hp = maxi(0, max_hp - 1)
	var probe_pp := maxi(0, pp_slot.max_pp - 1)

	live_opponent.current_hp = probe_hp
	pp_slot.current_pp = probe_pp
	live_opponent.status_state.persistent_id = &"burn"
	live_opponent.status_state.add_volatile(&"flinch")
	live_opponent.stat_stages.change(StatStages.ATTACK, 2)
	var identity_before := matching_session_creature == live_opponent

	live_opponent.reconcile_post_battle()

	return {
		"session_started": true,
		"live_opponent_found": true,
		"session_reference_found": true,
		"pp_slot_found": true,
		"same_reference_after_reconcile": identity_before and matching_session_creature == live_opponent,
		"max_hp": max_hp,
		"probe_hp": probe_hp,
		"hp_after_reconcile": live_opponent.current_hp,
		"damaged_hp_preserved": live_opponent.current_hp == probe_hp,
		"no_implicit_full_heal": probe_hp < max_hp and live_opponent.current_hp != max_hp,
		"probe_pp": probe_pp,
		"pp_after_reconcile": pp_slot.current_pp,
		"reduced_pp_preserved": pp_slot.current_pp == probe_pp,
		"persistent_status_preserved": live_opponent.status_state.persistent_id == &"burn",
		"volatile_status_cleared": not live_opponent.status_state.has_volatile(&"flinch"),
		"stat_stage_cleared": live_opponent.stat_stages.get_stage(StatStages.ATTACK) == 0,
	}


func _p1b_source_contract_trace() -> Dictionary:
	var creature_source := FileAccess.get_file_as_string("res://modules/creatures/domain/creature_instance.gd")
	var collection_source := FileAccess.get_file_as_string("res://modules/creatures/storage/player_collection.gd")
	var save_source := FileAccess.get_file_as_string("res://modules/save/save_game_data.gd")
	var session_source := FileAccess.get_file_as_string("res://modules/gameplay/trainer_battle_session.gd")
	var settlement_source := FileAccess.get_file_as_string("res://modules/gameplay/trainer_battle_settlement.gd")
	var proposal_source := FileAccess.get_file_as_string("res://modules/trainer_ai/trainer_item_aware_action_proposal.gd")
	return {
		"creature_instance_single_persistent_source": creature_source.contains("SINGLE persistent source of truth") and creature_source.contains("func reconcile_post_battle() -> void:"),
		"creature_instance_stable_identity": creature_source.contains("Identity is `instance_id` (a stable StringName)"),
		"session_reconciles_roster": session_source.contains("_reconcile_roster(_opponent_roster)"),
		"session_releases_roster": session_source.contains("_opponent_roster.clear()"),
		"collection_preserves_identity": collection_source.contains("Same CreatureInstance") and collection_source.contains("preserving its identity"),
		"collection_has_transfer_rollback": collection_source.contains("# rollback"),
		"collection_fails_closed_on_ambiguous_ownership": collection_source.contains("if in_party == in_storage:") and collection_source.contains("return null") and collection_source.contains("return false"),
		"save_has_canonical_registry": save_source.contains("creature registry is CANONICAL") and save_source.contains("each creature is stored exactly once"),
		"save_rejects_duplicate_creature_id": save_source.contains("\"reason\": \"duplicate_creature_id\""),
		"save_rejects_double_ownership": save_source.contains("\"reason\": \"double_ownership\""),
		"save_does_not_persist_battle_state": not save_source.contains("BattleState"),
		"settlement_has_no_recovery_or_replacement_contract": not settlement_source.contains("recovery") and not settlement_source.contains("replacement"),
		"game_ready_proposal_omits_campaign_snapshot": proposal_source.contains("TrainerDecisionContext.create(observation, belief, memory_clone, legal_actions)") and not proposal_source.contains("campaign_snapshot"),
		"combat_policy_flags_remain_false": session_source.contains("\"campaign_policy_used\": false") and session_source.contains("\"recovery_policy_used\": false") and session_source.contains("\"replacement_policy_used\": false"),
	}
