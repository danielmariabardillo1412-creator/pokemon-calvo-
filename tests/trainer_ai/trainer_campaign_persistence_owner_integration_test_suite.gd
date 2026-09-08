class_name TrainerCampaignPersistenceOwnerIntegrationTestSuite
extends RefCounted

const P1C_AUDIT_ID := "p1_c_campaign_persistence_owner_integration_v1"
const P1C_STATUS := "CAMPAIGN_PERSISTENCE_OWNER_INTEGRATED"

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var report := _exercise_owner_contract()
	var source := _source_trace()

	_check.call("p1c_audit_id", String(report.get("audit_id", "")) == P1C_AUDIT_ID)
	_check.call("p1c_owner_configures_valid_roster", bool(report.get("configured", false)))
	_check.call("p1c_owner_retains_trainer_identity", bool(report.get("trainer_identity_retained", false)))
	_check.call("p1c_owner_retains_roster_size", bool(report.get("roster_size_retained", false)))
	_check.call("p1c_battle_roster_preserves_exact_creature_refs", bool(report.get("battle_roster_exact_refs", false)))
	_check.call("p1c_battle_roster_container_is_detached", bool(report.get("battle_roster_container_detached", false)))
	_check.call("p1c_mutation_through_battle_ref_reaches_owner", bool(report.get("shared_creature_mutation_visible", false)))
	_check.call("p1c_roster_handoff_does_not_auto_heal", bool(report.get("handoff_no_auto_heal", false)))
	_check.call("p1c_empty_trainer_id_rejected", bool(report.get("empty_trainer_rejected", false)))
	_check.call("p1c_invalid_reconfigure_preserves_prior_owner", bool(report.get("invalid_reconfigure_atomic", false)))
	_check.call("p1c_duplicate_config_rejected", bool(report.get("duplicate_config_rejected", false)))
	_check.call("p1c_duplicate_config_is_atomic", bool(report.get("duplicate_config_atomic", false)))
	_check.call("p1c_null_creature_config_rejected", bool(report.get("null_config_rejected", false)))
	_check.call("p1c_empty_identity_config_rejected", bool(report.get("empty_identity_rejected", false)))
	_check.call("p1c_explicit_recovery_succeeds", bool(report.get("recovery_succeeded", false)))
	_check.call("p1c_recovery_preserves_creature_identity", bool(report.get("recovery_same_reference", false)))
	_check.call("p1c_recovery_restores_hp", bool(report.get("recovery_hp_full", false)))
	_check.call("p1c_recovery_restores_pp", bool(report.get("recovery_pp_full", false)))
	_check.call("p1c_recovery_clears_persistent_status", bool(report.get("recovery_persistent_status_cleared", false)))
	_check.call("p1c_recovery_clears_battle_only_state", bool(report.get("recovery_battle_only_state_cleared", false)))
	_check.call("p1c_unique_campaign_replacement_succeeds", bool(report.get("replacement_succeeded", false)))
	_check.call("p1c_replacement_owns_exact_new_reference", bool(report.get("replacement_exact_reference", false)))
	_check.call("p1c_replacement_releases_old_identity", bool(report.get("replacement_old_identity_released", false)))
	_check.call("p1c_duplicate_replacement_rejected", bool(report.get("duplicate_replacement_rejected", false)))
	_check.call("p1c_duplicate_replacement_is_atomic", bool(report.get("duplicate_replacement_atomic", false)))
	_check.call("p1c_identity_rebind_rejected", bool(report.get("identity_rebind_rejected", false)))
	_check.call("p1c_identity_rebind_is_atomic", bool(report.get("identity_rebind_atomic", false)))
	_check.call("p1c_missing_current_replacement_rejected", bool(report.get("missing_current_rejected", false)))
	_check.call("p1c_overworld_uses_campaign_owner", bool(source.get("overworld_uses_campaign_owner", false)))
	_check.call("p1c_overworld_removed_raw_trainer_roster", bool(source.get("overworld_removed_raw_roster", false)))
	_check.call("p1c_p1d_boundary_transition_authorized", bool(source.get("p1d_boundary_authorized", false)))
	_check.call("p1c_owner_does_not_reach_save_or_combat_ai", bool(source.get("owner_scope_isolated", false)))
	_check.call("p1c_status_integrated", bool(report.get("all_core_contracts_satisfied", false)) and bool(source.get("integration_source_satisfied", false)))
	_check.call("p1c_report_json_serializable", JSON.parse_string(JSON.stringify({"runtime": report, "source": source})) is Dictionary)

	print("\n=== TRAINER CAMPAIGN P1-C OWNER INTEGRATION ===")
	print(JSON.stringify({"runtime": report, "source": source}))


func _exercise_owner_contract() -> Dictionary:
	var first := _creature(&"p1c_first", 100)
	var second := _creature(&"p1c_second", 90)
	var roster: Array[CreatureInstance] = [first, second]
	var owner := TrainerCampaignRosterOwner.new()
	var configured := owner.configure(&"p1c_trainer", roster)
	var initial_first := owner.owned_creature(&"p1c_first")
	var initial_second := owner.owned_creature(&"p1c_second")
	var battle_roster := owner.roster_for_battle()
	var exact_refs := battle_roster.size() == 2 and battle_roster[0] == first and battle_roster[1] == second

	# The Array container is detached, but the creatures themselves are shared by identity.
	if not battle_roster.is_empty():
		battle_roster.remove_at(0)
	var container_detached := owner.roster_size() == 2 and battle_roster.size() == 1
	var shared_roster := owner.roster_for_battle()
	first.current_hp = 63
	var shared_mutation := not shared_roster.is_empty() and shared_roster[0] == first and owner.owned_creature(&"p1c_first").current_hp == 63
	var handoff_again := owner.roster_for_battle()
	var no_auto_heal := not handoff_again.is_empty() and handoff_again[0].current_hp == 63

	# Invalid configure attempts must fail before replacing the previous valid ownership state.
	var empty_trainer_rejected := not owner.configure(&"", roster) and owner.last_error == "trainer_id_required"
	var invalid_reconfigure_atomic := owner.trainer_id == &"p1c_trainer" and owner.owned_creature(&"p1c_first") == initial_first and owner.owned_creature(&"p1c_second") == initial_second
	var duplicates: Array[CreatureInstance] = [first, first]
	var duplicate_config_rejected := not owner.configure(&"p1c_other", duplicates) and owner.last_error == "duplicate_creature_identity"
	var duplicate_config_atomic := owner.trainer_id == &"p1c_trainer" and owner.roster_size() == 2 and owner.owned_creature(&"p1c_first") == first
	var null_roster: Array[CreatureInstance] = [null]
	var null_config_rejected := not owner.configure(&"p1c_other", null_roster) and owner.last_error == "null_creature"
	var empty_identity := _creature(&"", 50)
	var empty_identity_roster: Array[CreatureInstance] = [empty_identity]
	var empty_identity_rejected := not owner.configure(&"p1c_other", empty_identity_roster) and owner.last_error == "creature_identity_required"

	# Merely handing the roster to battle never heals. Recovery is a separate explicit operation.
	first.current_hp = 41
	var first_slot := first.moveset[0] as BattleMoveSlot
	first_slot.current_pp = 1
	first.status_state.persistent_id = &"burn"
	first.status_state.add_volatile(&"flinch")
	first.stat_stages.change(StatStages.ATTACK, 2)
	var recovery_ref_before := first
	var recovery_succeeded := owner.recover_creature_full(&"p1c_first")
	var recovery_same_ref := owner.owned_creature(&"p1c_first") == recovery_ref_before
	var recovery_hp_full := first.current_hp == first.stats.max_hp
	var recovery_pp_full := first_slot.current_pp == first_slot.max_pp
	var recovery_status_cleared := first.status_state.persistent_id == &""
	var recovery_battle_only_cleared := not first.status_state.has_volatile(&"flinch") and first.stat_stages.get_stage(StatStages.ATTACK) == 0

	# Campaign replacement is atomic and independent from Battle Core forced replacement.
	var replacement := _creature(&"p1c_replacement", 110)
	var replacement_succeeded := owner.replace_member(&"p1c_first", replacement)
	var replacement_exact_ref := owner.owned_creature(&"p1c_replacement") == replacement
	var old_identity_released := owner.owned_creature(&"p1c_first") == null
	var replacement_before_duplicate := owner.owned_creature(&"p1c_replacement")
	var second_before_duplicate := owner.owned_creature(&"p1c_second")
	var duplicate_replacement_rejected := not owner.replace_member(&"p1c_replacement", second) and owner.last_error == "duplicate_creature_identity"
	var duplicate_replacement_atomic := owner.owned_creature(&"p1c_replacement") == replacement_before_duplicate and owner.owned_creature(&"p1c_second") == second_before_duplicate
	var rebound := _creature(&"p1c_replacement", 120)
	var identity_rebind_rejected := not owner.replace_member(&"p1c_replacement", rebound) and owner.last_error == "identity_rebind_forbidden"
	var identity_rebind_atomic := owner.owned_creature(&"p1c_replacement") == replacement and owner.owned_creature(&"p1c_replacement") != rebound
	var missing_current_rejected := not owner.replace_member(&"p1c_missing", _creature(&"p1c_new", 80)) and owner.last_error == "current_creature_not_owned"

	var core_ok := (
		configured
		and exact_refs
		and container_detached
		and shared_mutation
		and no_auto_heal
		and invalid_reconfigure_atomic
		and duplicate_config_atomic
		and recovery_succeeded
		and recovery_same_ref
		and recovery_hp_full
		and recovery_pp_full
		and recovery_status_cleared
		and recovery_battle_only_cleared
		and replacement_succeeded
		and replacement_exact_ref
		and old_identity_released
		and duplicate_replacement_rejected
		and duplicate_replacement_atomic
		and identity_rebind_rejected
		and identity_rebind_atomic
		and missing_current_rejected
	)
	return {
		"audit_id": P1C_AUDIT_ID,
		"tranche_status": P1C_STATUS if core_ok else "BLOCKED",
		"configured": configured,
		"trainer_identity_retained": owner.trainer_id == &"p1c_trainer",
		"roster_size_retained": owner.roster_size() == 2,
		"battle_roster_exact_refs": exact_refs,
		"battle_roster_container_detached": container_detached,
		"shared_creature_mutation_visible": shared_mutation,
		"handoff_no_auto_heal": no_auto_heal,
		"empty_trainer_rejected": empty_trainer_rejected,
		"invalid_reconfigure_atomic": invalid_reconfigure_atomic,
		"duplicate_config_rejected": duplicate_config_rejected,
		"duplicate_config_atomic": duplicate_config_atomic,
		"null_config_rejected": null_config_rejected,
		"empty_identity_rejected": empty_identity_rejected,
		"recovery_succeeded": recovery_succeeded,
		"recovery_same_reference": recovery_same_ref,
		"recovery_hp_full": recovery_hp_full,
		"recovery_pp_full": recovery_pp_full,
		"recovery_persistent_status_cleared": recovery_status_cleared,
		"recovery_battle_only_state_cleared": recovery_battle_only_cleared,
		"replacement_succeeded": replacement_succeeded,
		"replacement_exact_reference": replacement_exact_ref,
		"replacement_old_identity_released": old_identity_released,
		"duplicate_replacement_rejected": duplicate_replacement_rejected,
		"duplicate_replacement_atomic": duplicate_replacement_atomic,
		"identity_rebind_rejected": identity_rebind_rejected,
		"identity_rebind_atomic": identity_rebind_atomic,
		"missing_current_rejected": missing_current_rejected,
		"all_core_contracts_satisfied": core_ok,
		"battle_state_persisted": false,
		"implicit_auto_heal": false,
		"save_v2_modified": false,
	}


func _source_trace() -> Dictionary:
	var owner_source := FileAccess.get_file_as_string("res://modules/gameplay/trainer_campaign_roster_owner.gd")
	var overworld_source := FileAccess.get_file_as_string("res://scenes/overworld/technical_overworld.gd")
	var uses_owner := (
		overworld_source.contains("var _trainer_campaign_owner: TrainerCampaignRosterOwner")
		and overworld_source.contains("_trainer_campaign_owner.roster_for_battle()")
		and overworld_source.contains("_trainer_campaign_owner.configure(TECHNICAL_TRAINER_ID, trainer_roster)")
	)
	var removed_raw := not overworld_source.contains("var _trainer_roster: Array[CreatureInstance]")
	var legacy_one_shot := (
		overworld_source.contains("var _trainer_demo_completed: bool = false")
		and overworld_source.contains("if _trainer_demo_completed:")
		and overworld_source.contains("_trainer_demo_completed = true")
	)
	var p1d_rematch := (
		overworld_source.contains("func recover_demo_trainer_full() -> bool:")
		and not overworld_source.contains("_trainer_demo_completed")
	)
	var boundary_authorized := legacy_one_shot or p1d_rematch
	var isolated := (
		not owner_source.contains("SaveGameData")
		and not owner_source.contains("TrainerItemAwareActionProposal")
		and not owner_source.contains("TrainerItemAwareSearch")
		and not owner_source.contains("TrainerGameReadyTieResolver")
	)
	return {
		"overworld_uses_campaign_owner": uses_owner,
		"overworld_removed_raw_roster": removed_raw,
		"legacy_one_shot_boundary": legacy_one_shot,
		"p1d_rematch_live": p1d_rematch,
		"p1d_boundary_authorized": boundary_authorized,
		"owner_scope_isolated": isolated,
		"integration_source_satisfied": uses_owner and removed_raw and boundary_authorized and isolated,
	}


func _creature(instance_id: StringName, max_hp: int) -> CreatureInstance:
	var move_ids: Array[StringName] = [&"p1c_move"]
	var creature := CreatureInstance.new(instance_id, &"p1c_species", 5, StatBlock.new(max_hp, 50, 50, 50, 50, 50), move_ids)
	var slots: Array[BattleMoveSlot] = [BattleMoveSlot.new(&"p1c_move", 5, 5)]
	creature.moveset = slots
	creature.move_ids = move_ids
	return creature