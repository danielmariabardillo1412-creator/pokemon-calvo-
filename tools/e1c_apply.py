from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected exactly one match, got {count}: {old[:100]!r}")
    write(path, text.replace(old, new, 1))


# ---------------------------------------------------------------------------
# Production: explicit expertise contract. Only E1-B-certified caps exist in V1.
# ---------------------------------------------------------------------------
write(
    "modules/trainer_ai/trainer_expertise.gd",
    '''class_name TrainerExpertise
extends RefCounted

# Expertise changes only bounded internal search breadth. It never changes legal
# roots, required depth, world breadth, hidden-information access, or Battle RNG.
# E1-B explicitly certified only caps 1 and 3; V1 therefore exposes only these.
const LIMITED := &"limited"
const FULL := &"full"
const DEFAULT := FULL

const LIMITED_INNER_ACTION_CAP := 1
const FULL_INNER_ACTION_CAP := TrainerItemAwareShadowProbe.INNER_ACTION_CAP


static func is_supported(expertise_id: StringName) -> bool:
    return expertise_id == LIMITED or expertise_id == FULL


static func inner_action_cap(expertise_id: StringName) -> int:
    if expertise_id == LIMITED:
        return LIMITED_INNER_ACTION_CAP
    if expertise_id == FULL:
        return FULL_INNER_ACTION_CAP
    return 0
'''.replace("    ", "\t")
)

proposal = "modules/trainer_ai/trainer_item_aware_action_proposal.gd"
replace_once(
    proposal,
    'const SIDE_A := &"side_a"\nconst SIDE_B := &"side_b"\n',
    'const SIDE_A := &"side_a"\nconst SIDE_B := &"side_b"\n\nvar _active_profile_id: StringName = TrainerProfile.BALANCED\nvar _active_expertise_id: StringName = TrainerExpertise.DEFAULT\nvar _active_inner_action_cap: int = INNER_ACTION_CAP\n',
)
replace_once(
    proposal,
    '''func evaluate(\n\tstate: BattleState,\n\tside_id: StringName,\n\tmemory: TrainerBattleMemory,\n\tcatalog: DefinitionCatalog,\n) -> Dictionary:\n\tif state == null or memory == null or catalog == null:\n''',
    '''func evaluate(\n\tstate: BattleState,\n\tside_id: StringName,\n\tmemory: TrainerBattleMemory,\n\tcatalog: DefinitionCatalog,\n\tprofile: TrainerProfile = null,\n\texpertise_id: StringName = TrainerExpertise.DEFAULT,\n) -> Dictionary:\n\t_active_profile_id = profile.profile_id if profile != null else TrainerProfile.BALANCED\n\t_active_expertise_id = expertise_id\n\t_active_inner_action_cap = TrainerExpertise.inner_action_cap(expertise_id)\n\tvar active_profile := _canonical_profile(_active_profile_id)\n\tif active_profile == null:\n\t\treturn blocked_report("invalid_trainer_profile", side_id)\n\tif not TrainerExpertise.is_supported(_active_expertise_id) or _active_inner_action_cap <= 0:\n\t\treturn blocked_report("invalid_trainer_expertise", side_id)\n\tif state == null or memory == null or catalog == null:\n''',
)
replace_once(
    proposal,
    '\tvar root_simulations: Dictionary = {}\n\tvar root_horizon_complete: Dictionary = {}\n',
    '\tvar root_simulations: Dictionary = {}\n\tvar root_risk_weight_basis_points: Dictionary = {}\n\tvar root_horizon_complete: Dictionary = {}\n',
)
replace_once(
    proposal,
    '\tvar expected_budget := _budget_signature()\n',
    '\tvar expected_budget := _budget_signature(_active_inner_action_cap)\n',
)
replace_once(
    proposal,
    '''\t\tvar budget := _budget()\n\t\tvar result := TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget).evaluate(context, root)\n''',
    '''\t\tvar budget := _budget(_active_inner_action_cap)\n\t\tvar result := TrainerItemAwareSearch.new(catalog, active_profile, budget).evaluate(context, root)\n''',
)
replace_once(
    proposal,
    '\t\troot_simulations[root_id] = int(metadata.get("simulations_used", 0))\n\t\troot_horizon_complete[root_id] = bool(metadata.get("required_horizon_complete", false))\n',
    '\t\troot_simulations[root_id] = int(metadata.get("simulations_used", 0))\n\t\troot_risk_weight_basis_points[root_id] = int(metadata.get("risk_weight_basis_points", -1))\n\t\troot_horizon_complete[root_id] = bool(metadata.get("required_horizon_complete", false))\n',
)
replace_once(
    proposal,
    '''\t\t"root_all_legal": true,\n\t\t"inner_max_actions_per_side": INNER_ACTION_CAP,\n\t\t"required_depth": REQUIRED_DEPTH,\n''',
    '''\t\t"root_all_legal": true,\n\t\t"trainer_profile_id": String(_active_profile_id),\n\t\t"trainer_expertise_id": String(_active_expertise_id),\n\t\t"inner_max_actions_per_side": _active_inner_action_cap,\n\t\t"required_depth": REQUIRED_DEPTH,\n''',
)
replace_once(
    proposal,
    '\t\t"root_simulations": root_simulations,\n\t\t"root_horizon_complete": root_horizon_complete,\n',
    '\t\t"root_simulations": root_simulations,\n\t\t"root_risk_weight_basis_points": root_risk_weight_basis_points,\n\t\t"root_horizon_complete": root_horizon_complete,\n',
)
# This match is now only in blocked_report because the normal report was replaced above.
replace_once(
    proposal,
    '''\t\t"root_all_legal": true,\n\t\t"inner_max_actions_per_side": INNER_ACTION_CAP,\n\t\t"required_depth": REQUIRED_DEPTH,\n''',
    '''\t\t"root_all_legal": true,\n\t\t"trainer_profile_id": String(_active_profile_id),\n\t\t"trainer_expertise_id": String(_active_expertise_id),\n\t\t"inner_max_actions_per_side": _active_inner_action_cap,\n\t\t"required_depth": REQUIRED_DEPTH,\n''',
)
replace_once(
    proposal,
    '\t\t"root_simulations": {},\n\t\t"root_horizon_complete": {},\n',
    '\t\t"root_simulations": {},\n\t\t"root_risk_weight_basis_points": {},\n\t\t"root_horizon_complete": {},\n',
)
replace_once(
    proposal,
    '''func _budget() -> TrainerSearchBudget:\n\treturn TrainerSearchBudget.constrained(REQUIRED_DEPTH, MAX_WORLDS, MAX_SIMULATIONS, INNER_ACTION_CAP)\n\n\nfunc _budget_signature() -> String:\n\treturn JSON.stringify(_budget().normalized().to_dict())\n''',
    '''func _canonical_profile(profile_id: StringName) -> TrainerProfile:\n\tif profile_id == TrainerProfile.BALANCED:\n\t\treturn TrainerProfile.balanced()\n\tif profile_id == TrainerProfile.AGGRESSIVE:\n\t\treturn TrainerProfile.aggressive()\n\tif profile_id == TrainerProfile.CAUTIOUS:\n\t\treturn TrainerProfile.cautious()\n\tif profile_id == TrainerProfile.TECHNICAL:\n\t\treturn TrainerProfile.technical()\n\treturn null\n\n\nfunc _budget(inner_action_cap: int = INNER_ACTION_CAP) -> TrainerSearchBudget:\n\treturn TrainerSearchBudget.constrained(REQUIRED_DEPTH, MAX_WORLDS, MAX_SIMULATIONS, inner_action_cap)\n\n\nfunc _budget_signature(inner_action_cap: int = INNER_ACTION_CAP) -> String:\n\treturn JSON.stringify(_budget(inner_action_cap).normalized().to_dict())\n''',
)

# ---------------------------------------------------------------------------
# Production: trusted session owns profile/expertise IDs and revalidates them.
# ---------------------------------------------------------------------------
session = "modules/gameplay/trainer_battle_session.gd"
replace_once(
    session,
    'var _trainer_action_substitution_enabled: bool = false\n',
    'var _trainer_action_substitution_enabled: bool = false\nvar _trainer_profile_id: StringName = TrainerProfile.BALANCED\nvar _trainer_expertise_id: StringName = TrainerExpertise.DEFAULT\n',
)
replace_once(
    session,
    '''func opponent_active() -> CreatureInstance:\n\tif _battle_server == null:\n\t\treturn null\n\treturn _battle_server.state.active_for_side(&"side_b")\n''',
    '''func opponent_active() -> CreatureInstance:\n\tif _battle_server == null:\n\t\treturn null\n\treturn _battle_server.state.active_for_side(&"side_b")\n\n\nfunc trainer_profile_id() -> StringName:\n\treturn _trainer_profile_id\n\n\nfunc trainer_expertise_id() -> StringName:\n\treturn _trainer_expertise_id\n''',
)
replace_once(
    session,
    '\treturn proposal.evaluate(_battle_server.state, side_id, memory, catalogs)\n',
    '\tvar profile := _trainer_profile_for_id(_trainer_profile_id)\n\tif profile == null or not TrainerExpertise.is_supported(_trainer_expertise_id):\n\t\treturn proposal.blocked_report("trainer_expertise_config_not_ready", side_id)\n\treturn proposal.evaluate(_battle_server.state, side_id, memory, catalogs, profile, _trainer_expertise_id)\n',
)
replace_once(
    session,
    '\treturn proposal.evaluate(branch_state, side_id, memory, catalogs)\n',
    '\tvar profile := _trainer_profile_for_id(_trainer_profile_id)\n\tif profile == null or not TrainerExpertise.is_supported(_trainer_expertise_id):\n\t\treturn proposal.blocked_report("trainer_expertise_config_not_ready", side_id)\n\treturn proposal.evaluate(branch_state, side_id, memory, catalogs, profile, _trainer_expertise_id)\n',
)
replace_once(
    session,
    '''\tif int(report.get("inner_max_actions_per_side", -1)) != TrainerItemAwareActionProposal.INNER_ACTION_CAP:\n\t\treturn _trainer_action_substitution_blocked_report("proposal_inner_cap_mismatch", report)\n''',
    '''\tvar expected_inner_cap := TrainerExpertise.inner_action_cap(_trainer_expertise_id)\n\tif expected_inner_cap <= 0 or int(report.get("inner_max_actions_per_side", -1)) != expected_inner_cap:\n\t\treturn _trainer_action_substitution_blocked_report("proposal_inner_cap_mismatch", report)\n''',
)
replace_once(
    session,
    '''\tif not bool(report.get("proposal_action_detached", false)) or not (report.get("proposal_action", null) is Dictionary):\n\t\treturn _trainer_action_substitution_blocked_report("proposal_action_not_detached", report)\n\n\tvar proposal_dict := (report.get("proposal_action", {}) as Dictionary).duplicate(true)\n''',
    '''\tif not bool(report.get("proposal_action_detached", false)) or not (report.get("proposal_action", null) is Dictionary):\n\t\treturn _trainer_action_substitution_blocked_report("proposal_action_not_detached", report)\n\tif String(report.get("trainer_profile_id", "")) != String(_trainer_profile_id):\n\t\treturn _trainer_action_substitution_blocked_report("proposal_profile_mismatch", report)\n\tif String(report.get("trainer_expertise_id", "")) != String(_trainer_expertise_id):\n\t\treturn _trainer_action_substitution_blocked_report("proposal_expertise_mismatch", report)\n\n\tvar proposal_dict := (report.get("proposal_action", {}) as Dictionary).duplicate(true)\n''',
)
# Ready substitution telemetry.
replace_once(
    session,
    '''\t\t"proposal_model": String(report.get("proposal_model", "")),\n\t\t"selected_root_id": selected_root_id,\n''',
    '''\t\t"proposal_model": String(report.get("proposal_model", "")),\n\t\t"trainer_profile_id": String(report.get("trainer_profile_id", "")),\n\t\t"trainer_expertise_id": String(report.get("trainer_expertise_id", "")),\n\t\t"selected_root_id": selected_root_id,\n''',
)
# Blocked substitution telemetry; after the first replacement exactly one occurrence remains.
replace_once(
    session,
    '''\t\t"proposal_model": String(proposal_report.get("proposal_model", "")),\n\t\t"selected_root_id": String(proposal_report.get("selected_root_id", "")),\n''',
    '''\t\t"proposal_model": String(proposal_report.get("proposal_model", "")),\n\t\t"trainer_profile_id": String(proposal_report.get("trainer_profile_id", _trainer_profile_id)),\n\t\t"trainer_expertise_id": String(proposal_report.get("trainer_expertise_id", _trainer_expertise_id)),\n\t\t"selected_root_id": String(proposal_report.get("selected_root_id", "")),\n''',
)
replace_once(
    session,
    '"inner_max_actions_per_side": int(proposal_report.get("inner_max_actions_per_side", TrainerItemAwareActionProposal.INNER_ACTION_CAP)),',
    '"inner_max_actions_per_side": int(proposal_report.get("inner_max_actions_per_side", TrainerExpertise.inner_action_cap(_trainer_expertise_id))),',
)
replace_once(
    session,
    '''func begin_battle(\n\tp_opponent_trainer_id: StringName,\n\tp_opponent_roster: Array[CreatureInstance],\n\tbattle_seed: int = 1,\n) -> bool:\n''',
    '''func begin_battle(\n\tp_opponent_trainer_id: StringName,\n\tp_opponent_roster: Array[CreatureInstance],\n\tbattle_seed: int = 1,\n\tp_trainer_profile_id: StringName = TrainerProfile.BALANCED,\n\tp_trainer_expertise_id: StringName = TrainerExpertise.DEFAULT,\n) -> bool:\n''',
)
replace_once(
    session,
    '''\tif p_opponent_trainer_id == &"":\n\t\tlast_error = "trainer_id_required"\n\t\treturn false\n\n\tvar player_roster := _roster_with_living_active(player.party.get_creatures())\n''',
    '''\tif p_opponent_trainer_id == &"":\n\t\tlast_error = "trainer_id_required"\n\t\treturn false\n\tif _trainer_profile_for_id(p_trainer_profile_id) == null:\n\t\tlast_error = "invalid_trainer_profile"\n\t\treturn false\n\tif not TrainerExpertise.is_supported(p_trainer_expertise_id):\n\t\tlast_error = "invalid_trainer_expertise"\n\t\treturn false\n\n\tvar player_roster := _roster_with_living_active(player.party.get_creatures())\n''',
)
replace_once(
    session,
    '''\topponent_trainer_id = p_opponent_trainer_id\n\tstatus = BATTLE_ACTIVE\n\tcompletion_reason = &""\n''',
    '''\topponent_trainer_id = p_opponent_trainer_id\n\t_trainer_profile_id = p_trainer_profile_id\n\t_trainer_expertise_id = p_trainer_expertise_id\n\tstatus = BATTLE_ACTIVE\n\tcompletion_reason = &""\n''',
)
replace_once(
    session,
    '''\tlast_trainer_game_ready_tie_report = {}\n\tstatus = READY\n\tcompletion_reason = &""\n\topponent_trainer_id = &""\n''',
    '''\tlast_trainer_game_ready_tie_report = {}\n\t_trainer_profile_id = TrainerProfile.BALANCED\n\t_trainer_expertise_id = TrainerExpertise.DEFAULT\n\tstatus = READY\n\tcompletion_reason = &""\n\topponent_trainer_id = &""\n''',
)
replace_once(
    session,
    '''func _roster_with_living_active(source: Array[CreatureInstance]) -> Array[CreatureInstance]:\n''',
    '''func _trainer_profile_for_id(profile_id: StringName) -> TrainerProfile:\n\tif profile_id == TrainerProfile.BALANCED:\n\t\treturn TrainerProfile.balanced()\n\tif profile_id == TrainerProfile.AGGRESSIVE:\n\t\treturn TrainerProfile.aggressive()\n\tif profile_id == TrainerProfile.CAUTIOUS:\n\t\treturn TrainerProfile.cautious()\n\tif profile_id == TrainerProfile.TECHNICAL:\n\t\treturn TrainerProfile.technical()\n\treturn null\n\n\nfunc _roster_with_living_active(source: Array[CreatureInstance]) -> Array[CreatureInstance]:\n''',
)

# ---------------------------------------------------------------------------
# E1-A live regression: retain permanent contract checks, replace obsolete gap checks.
# ---------------------------------------------------------------------------
contract = "tests/trainer_ai/trainer_expertise_contract_audit_test_suite.gd"
replace_once(
    contract,
    '''\t_check.call(\n\t\t"expertise_audit_runtime_proposal_is_currently_balanced_fixed",\n\t\tproposal_source.contains("TrainerItemAwareSearch.new(catalog, TrainerProfile.balanced(), budget)")\n\t)\n\t_check.call(\n\t\t"expertise_audit_runtime_proposal_has_no_profile_or_expertise_input",\n\t\tnot proposal_source.contains("p_profile")\n\t\tand not proposal_source.contains("expertise_id")\n\t\tand not proposal_source.contains("difficulty_id")\n\t)\n''',
    '''\t_check.call(\n\t\t"expertise_audit_runtime_proposal_accepts_explicit_style_and_expertise",\n\t\tproposal_source.contains("profile: TrainerProfile = null")\n\t\tand proposal_source.contains("expertise_id: StringName = TrainerExpertise.DEFAULT")\n\t\tand proposal_source.contains("TrainerItemAwareSearch.new(catalog, active_profile, budget)")\n\t)\n\t_check.call(\n\t\t"expertise_audit_runtime_proposal_preserves_balanced_full_defaults",\n\t\tproposal_source.contains("profile.profile_id if profile != null else TrainerProfile.BALANCED")\n\t\tand proposal_source.contains("TrainerExpertise.DEFAULT")\n\t\tand proposal_source.contains("const INNER_ACTION_CAP := TrainerItemAwareShadowProbe.INNER_ACTION_CAP")\n\t)\n''',
)
replace_once(
    contract,
    '''\t_check.call(\n\t\t"expertise_audit_session_has_no_runtime_expertise_state",\n\t\tnot session_source.contains("expertise_id")\n\t\tand not session_source.contains("difficulty_id")\n\t\tand not session_source.contains("competence_id")\n\t)\n''',
    '''\t_check.call(\n\t\t"expertise_audit_session_keeps_style_and_expertise_separate",\n\t\tsession_source.contains("_trainer_profile_id")\n\t\tand session_source.contains("_trainer_expertise_id")\n\t\tand session_source.contains("TrainerExpertise.is_supported")\n\t\tand not TrainerProfile.balanced().to_dict().has("expertise_id")\n\t)\n''',
)

# ---------------------------------------------------------------------------
# E1-C focal runtime integration suite: 26 checks.
# ---------------------------------------------------------------------------
write(
    "tests/trainer_ai/trainer_expertise_runtime_integration_test_suite.gd",
    '''class_name TrainerExpertiseRuntimeIntegrationTestSuite
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
'''.replace("    ", "\t")
)

runner = "tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd"
replace_once(
    runner,
    '\tTrainerExpertiseBudgetSafetyAuditTestSuite.new().run(Callable(self, "_check"))\n\tprint("\\n=== TRAINER EVALUATION CORPUS RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])\n',
    '\tTrainerExpertiseBudgetSafetyAuditTestSuite.new().run(Callable(self, "_check"))\n\tTrainerExpertiseRuntimeIntegrationTestSuite.new().run(Callable(self, "_check"))\n\tprint("\\n=== TRAINER EVALUATION CORPUS RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])\n',
)

# ---------------------------------------------------------------------------
# Project book: E1-B becomes certified; E1-C is implemented but not pre-certified.
# ---------------------------------------------------------------------------
doc = "docs/project_book/TRAINER_AI_EXPERTISE.md"
replace_once(
    doc,
    '2. **E1-B — seguridad de knobs de competencia** — ACTUAL / TEST-AUDIT-ONLY.\n3. **E1-C — integración productiva mínima de estilo + expertise**.\n',
    '2. **E1-B — seguridad de knobs de competencia** — COMPLETADO / CERTIFICADO.\n3. **E1-C — integración productiva mínima de estilo + expertise** — ACTUAL / CI PENDING.\n',
)
replace_once(
    doc,
    '## E1-B — seguridad de knobs de competencia\n',
    '## E1-B — seguridad de knobs de competencia — CLOSED / CERTIFIED\n',
)
insert = '''## E1-C — integración productiva mínima — IMPLEMENTED / CI PENDING

E1-B quedó certificado en el checkpoint exacto:

`f8053f2a655fd38b1082e6e48688b8318e17d850`

Resultado literal recuperado del workflow Evaluation:

- **18/18 workflows SUCCESS**;
- **444 PASS / 0 FAIL**;
- aggregate `TRAINER_AI_EXPERTISE_BUDGET_SAFETY_AUDIT_COMPLETE`;
- `depth_turns=1` sigue prohibido para Game-Ready;
- un budget depth-2 agotado sigue incompleto/fail-closed;
- caps internos 1 y 3 conservan depth 2, determinismo y frontera anti-cheat;
- cap 3 expande materialmente más búsqueda que cap 1;
- `MAX_WORLDS=4` no se modifica.

Implementación E1-C deliberadamente mínima:

- estilos canónicos: `balanced`, `aggressive`, `cautious`, `technical`;
- expertise V1: `limited` = cap interno 1, `full` = cap interno 3;
- no existe un nivel intermedio inventado porque E1-B no certificó cap 2;
- default compatible: `balanced + full`, equivalente al comportamiento Game-Ready previo;
- depth 2, 4 mundos, 220 simulaciones por root y **todas las raíces legales externas** permanecen comunes;
- `TrainerBattleSession` posee los IDs trusted de estilo/expertise por batalla;
- el proposal recibe un `TrainerProfile` canónico y el cap de expertise;
- el validador autoritativo revalida profile ID, expertise ID, cap, profundidad, completeness y legalidad exacta;
- `TrainerGameReadyTieResolver` permanece sin cambios y no usa estilo/expertise como desempate;
- Battle Core, scheduler/shared budget/660 y FASE34 permanecen fuera de alcance.

Nueva suite focal: `TrainerExpertiseRuntimeIntegrationTestSuite`, **26 checks**. Objetivo Evaluation si no aparece ninguna regresión: **470 PASS / 0 FAIL**.

E1-C no se declarará CLOSED hasta obtener la matriz normal **18/18 SUCCESS** y el total literal **470/0** sobre el SHA técnico exacto.

'''
replace_once(doc, '## Qué sigue fuera de Expertise V1\n', insert + '## Qué sigue fuera de Expertise V1\n')

print("E1-C guarded patch applied successfully")
