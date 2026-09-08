class_name TrainerExpertiseRuntimeIntegrationTestSuite
extends TrainerSearchDepthBudgetTestSuite

const AGGREGATE := "TRAINER_AI_EXPERTISE_RUNTIME_INTEGRATION_COMPLETE"


func run(check_callback: Callable) -> void:
	_check = Callable(self, "_ignore_fixture_check")
	_build_catalog()
	_check = check_callback

	_check.call("expertise_runtime_limited_supported", TrainerExpertise.is_supported(TrainerExpertise.LIMITED))
	_check.call("expertise_runtime_full_supported", TrainerExpertise.is_supported(TrainerExpertise.FULL))
	_check.call(
		"expertise_runtime_only_e1b_certified_caps_exposed",
		TrainerExpertise.inner_action_cap(TrainerExpertise.LIMITED) == 1
		and TrainerExpertise.inner_action_cap(TrainerExpertise.FULL) == TrainerItemAwareActionProposal.INNER_ACTION_CAP
		and TrainerExpertise.inner_action_cap(&"unsupported") == 0
	)

	var invalid_profile_fx := _session_fixture("invalid_profile")
	var invalid_profile_session := invalid_profile_fx.session as TrainerBattleSession
	var invalid_profile_ok := invalid_profile_session.begin_battle(
		&"e1c_invalid_profile",
		invalid_profile_fx.roster,
		7101,
		&"not_a_profile",
		TrainerExpertise.FULL
	)
	_check.call("expertise_runtime_invalid_profile_rejected", not invalid_profile_ok and invalid_profile_session.last_error == "invalid_trainer_profile")
	_check.call("expertise_runtime_invalid_profile_no_battle", not invalid_profile_session.has_active_battle())

	var invalid_expertise_fx := _session_fixture("invalid_expertise")
	var invalid_expertise_session := invalid_expertise_fx.session as TrainerBattleSession
	var invalid_expertise_ok := invalid_expertise_session.begin_battle(
		&"e1c_invalid_expertise",
		invalid_expertise_fx.roster,
		7102,
		TrainerProfile.BALANCED,
		&"not_an_expertise"
	)
	_check.call("expertise_runtime_invalid_expertise_rejected", not invalid_expertise_ok and invalid_expertise_session.last_error == "invalid_trainer_expertise")
	_check.call("expertise_runtime_invalid_expertise_no_battle", not invalid_expertise_session.has_active_battle())

	var limited_fx := _session_fixture("limited")
	var limited_session := limited_fx.session as TrainerBattleSession
	var limited_ok := limited_session.begin_battle(
		&"e1c_limited",
		limited_fx.roster,
		7201,
		TrainerProfile.AGGRESSIVE,
		TrainerExpertise.LIMITED
	)
	_check.call("expertise_runtime_limited_begin_ok", limited_ok and limited_session.has_active_battle())
	_check.call(
		"expertise_runtime_limited_ids_owned_by_session",
		limited_session.trainer_profile_id() == TrainerProfile.AGGRESSIVE
		and limited_session.trainer_expertise_id() == TrainerExpertise.LIMITED
	)
	var limited_report := limited_session.trainer_action_proposal_report_for_side(&"side_b")
	_check.call("expertise_runtime_limited_report_complete", _proposal_complete(limited_report))
	_check.call("expertise_runtime_limited_profile_threaded", String(limited_report.get("trainer_profile_id", "")) == String(TrainerProfile.AGGRESSIVE))
	_check.call("expertise_runtime_limited_expertise_threaded", String(limited_report.get("trainer_expertise_id", "")) == String(TrainerExpertise.LIMITED))
	_check.call("expertise_runtime_limited_cap_one", int(limited_report.get("inner_max_actions_per_side", 0)) == 1)
	_check.call(
		"expertise_runtime_limited_outer_roots_all_legal",
		bool(limited_report.get("root_all_legal", false))
		and int(limited_report.get("evaluated_root_count", 0)) == int(limited_report.get("legal_action_count", -1))
	)
	_check.call(
		"expertise_runtime_aggressive_style_reaches_search",
		_all_values_equal(limited_report.get("root_risk_weight_basis_points", {}) as Dictionary, 2500)
	)
	var limited_json := JSON.stringify(limited_report)
	_check.call("expertise_runtime_hidden_move_not_leaked", not limited_json.contains(String(OPP_SECRET)))
	_check.call("expertise_runtime_live_rng_not_leaked", not limited_json.contains("rng_state"))
	_check.call(
		"expertise_runtime_tiebreak_and_fase34_barriers_preserved",
		not bool(limited_report.get("profile_tiebreak_used", true))
		and not bool(limited_report.get("fase34_open", true))
	)

	var full_fx := _session_fixture("full")
	var full_session := full_fx.session as TrainerBattleSession
	var full_ok := full_session.begin_battle(
		&"e1c_full",
		full_fx.roster,
		7201,
		TrainerProfile.AGGRESSIVE,
		TrainerExpertise.FULL
	)
	_check.call("expertise_runtime_full_begin_ok", full_ok and full_session.has_active_battle())
	var full_report := full_session.trainer_action_proposal_report_for_side(&"side_b")
	_check.call("expertise_runtime_full_report_complete", _proposal_complete(full_report))
	_check.call("expertise_runtime_full_cap_three", int(full_report.get("inner_max_actions_per_side", 0)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP)
	_check.call(
		"expertise_runtime_expertise_keeps_outer_root_set",
		int(full_report.get("legal_action_count", -1)) == int(limited_report.get("legal_action_count", -2))
		and (full_report.get("root_ids", []) as Array).size() == (limited_report.get("root_ids", []) as Array).size()
	)
	_check.call(
		"expertise_runtime_full_materially_widens_internal_search",
		_sum_values(full_report.get("root_simulations", {}) as Dictionary) > _sum_values(limited_report.get("root_simulations", {}) as Dictionary)
	)

	var default_fx := _session_fixture("default")
	var default_session := default_fx.session as TrainerBattleSession
	var default_ok := default_session.begin_battle(&"e1c_default", default_fx.roster, 7301)
	_check.call("expertise_runtime_default_begin_backward_compatible", default_ok and default_session.has_active_battle())
	var default_report := default_session.trainer_action_proposal_report_for_side(&"side_b")
	_check.call(
		"expertise_runtime_default_is_balanced_full_legacy_cap",
		String(default_report.get("trainer_profile_id", "")) == String(TrainerProfile.BALANCED)
		and String(default_report.get("trainer_expertise_id", "")) == String(TrainerExpertise.FULL)
		and int(default_report.get("inner_max_actions_per_side", 0)) == TrainerItemAwareActionProposal.INNER_ACTION_CAP
	)
	_check.call(
		"expertise_runtime_default_complete_and_fail_closed_contract",
		_proposal_complete(default_report)
		and bool(default_report.get("root_all_legal", false))
		and int(default_report.get("required_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH
	)

	_check.call("expertise_runtime_aggregate", true)
	print(AGGREGATE)


func _session_fixture(suffix: String) -> Dictionary:
	var player := _creature(
		StringName("e1c_player_%s" % suffix),
		HEAVY_SPECIES,
		StatBlock.new(200, 150, 110, 90, 120, 120),
		[OPP_HEAVY, OPP_SECRET]
	)
	var trainer := _creature(
		StringName("e1c_trainer_%s" % suffix),
		GLASS_SPECIES,
		StatBlock.new(120, 250, 80, 40, 70, 80),
		[GREEDY_MOVE, DEFEND_MOVE]
	)
	var player_collection := PlayerCollection.new()
	player_collection.party.add_creature(player)
	var roster: Array[CreatureInstance] = [trainer]
	return {
		"session": TrainerBattleSession.new(player_collection, _catalog, ProgressionRuleset.new()),
		"roster": roster,
	}


func _proposal_complete(report: Dictionary) -> bool:
	var status := String(report.get("proposal_status", ""))
	return (
		(status == TrainerItemAwareActionProposal.PROPOSAL_READY or status == TrainerItemAwareActionProposal.TIE_UNRESOLVED)
		and bool(report.get("evaluations_complete", false))
		and bool(report.get("metadata_models_match", false))
		and bool(report.get("same_budget", false))
		and int(report.get("common_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH
	)


func _all_values_equal(values: Dictionary, expected: int) -> bool:
	if values.is_empty():
		return false
	for value in values.values():
		if int(value) != expected:
			return false
	return true


func _sum_values(values: Dictionary) -> int:
	var total := 0
	for value in values.values():
		total += int(value)
	return total


func _ignore_fixture_check(_name: String, _condition: bool) -> void:
	pass
