class_name TrainerBattleSession
extends RefCounted

# Headless application boundary for battles against owned trainer parties.
# Battle rules remain authoritative in Battle Core. This layer composes player ownership,
# opponent roster, settlement and progression; it deliberately exposes no Capture or Run command.
# C3f-ae owns trusted dual side-specific battle memory from battle start. C3f-af may execute
# ItemAware search as read-only shadow telemetry, but still never selects/substitutes an action.

const READY := &"READY"
const BATTLE_ACTIVE := &"BATTLE_ACTIVE"
const COMPLETED := &"COMPLETED"

const COMPLETED_VICTORY := &"VICTORY"
const COMPLETED_DEFEAT := &"DEFEAT"

const SUBSTITUTION_READY := "SUBSTITUTION_READY"
const SUBSTITUTION_BLOCKED := "BLOCKED"

var player: PlayerCollection
var catalogs: DefinitionCatalog
var progression_ruleset: ProgressionRuleset
var status: StringName = READY
var completion_reason: StringName = &""
var opponent_trainer_id: StringName = &""
var last_error: String = ""
var last_trainer_shadow_report: Dictionary = {}
var last_trainer_action_proposal_report: Dictionary = {}
var last_trainer_action_substitution_report: Dictionary = {}

var _battle_server: AuthoritativeBattleServer = null
var _opponent_roster: Array[CreatureInstance] = []
var _trainer_memory_owner := TrainerDualSideBattleMemoryOwner.new()
var _trainer_shadow_item_aware_enabled: bool = false
var _trainer_action_proposal_enabled: bool = false
var _trainer_action_substitution_enabled: bool = false


func _init(
	p_player: PlayerCollection = null,
	p_catalogs: DefinitionCatalog = null,
	p_progression_ruleset: ProgressionRuleset = null,
) -> void:
	player = p_player if p_player != null else PlayerCollection.new()
	catalogs = p_catalogs
	progression_ruleset = p_progression_ruleset if p_progression_ruleset != null else ProgressionRuleset.new()


func has_active_battle() -> bool:
	return status == BATTLE_ACTIVE and _battle_server != null


func battle_state() -> BattleState:
	return _battle_server.state if _battle_server != null else null


func player_active() -> CreatureInstance:
	if _battle_server == null:
		return null
	return _battle_server.state.active_for_side(&"side_a")


func opponent_active() -> CreatureInstance:
	if _battle_server == null:
		return null
	return _battle_server.state.active_for_side(&"side_b")


# Wiring-only read seam. Callers receive detached snapshots; no mutable live
# TrainerBattleMemory escapes the trusted session.
func trainer_memory_wiring_ready() -> bool:
	return (
		has_active_battle()
		and _trainer_memory_owner != null
		and _trainer_memory_owner.is_ready(_battle_server.state)
	)


func trainer_memory_snapshot_for_side(side_id: StringName) -> TrainerBattleMemory:
	if not trainer_memory_wiring_ready():
		return null
	return _trainer_memory_owner.snapshot_for_side(_battle_server.state, side_id)


func trainer_branch_memory_snapshot_for_side(
	side_id: StringName,
	events: Array[BattleEvent],
	branch_state: BattleState,
) -> TrainerBattleMemory:
	if not trainer_memory_wiring_ready():
		return null
	return _trainer_memory_owner.branch_snapshot_for_side(side_id, events, branch_state)


# C3f-af shadow toggle. Disabled by default. Enabling it can produce telemetry or fail
# closed, but can never replace the explicit opponent_action submitted by the caller.
func set_trainer_shadow_item_aware_enabled(enabled: bool) -> void:
	_trainer_shadow_item_aware_enabled = enabled
	last_trainer_shadow_report = {}


func trainer_shadow_item_aware_is_enabled() -> bool:
	return _trainer_shadow_item_aware_enabled


func trainer_shadow_item_aware_report_for_side(side_id: StringName) -> Dictionary:
	var probe := TrainerItemAwareShadowProbe.new()
	if not trainer_memory_wiring_ready():
		return probe.blocked_report("trainer_memory_not_ready", side_id)
	var memory := trainer_memory_snapshot_for_side(side_id)
	if memory == null:
		return probe.blocked_report("side_memory_unavailable", side_id)
	return probe.evaluate(_battle_server.state, side_id, memory, catalogs)


func trainer_branch_shadow_item_aware_report_for_side(
	side_id: StringName,
	events: Array[BattleEvent],
	branch_state: BattleState,
) -> Dictionary:
	var probe := TrainerItemAwareShadowProbe.new()
	if not trainer_memory_wiring_ready():
		return probe.blocked_report("trainer_memory_not_ready", side_id)
	var memory := trainer_branch_memory_snapshot_for_side(side_id, events, branch_state)
	if memory == null:
		return probe.blocked_report("branch_memory_unavailable", side_id)
	return probe.evaluate(branch_state, side_id, memory, catalogs)


# C3f-aj proposal toggle. Disabled by default. A proposal is detached telemetry only:
# the explicit opponent_action supplied by the caller remains authoritative.
func set_trainer_action_proposal_enabled(enabled: bool) -> void:
	_trainer_action_proposal_enabled = enabled
	last_trainer_action_proposal_report = {}


func trainer_action_proposal_is_enabled() -> bool:
	return _trainer_action_proposal_enabled


func trainer_action_proposal_report_for_side(side_id: StringName) -> Dictionary:
	var proposal := TrainerItemAwareActionProposal.new()
	if not trainer_memory_wiring_ready():
		return proposal.blocked_report("trainer_memory_not_ready", side_id)
	var memory := trainer_memory_snapshot_for_side(side_id)
	if memory == null:
		return proposal.blocked_report("side_memory_unavailable", side_id)
	return proposal.evaluate(_battle_server.state, side_id, memory, catalogs)


func trainer_branch_action_proposal_report_for_side(
	side_id: StringName,
	events: Array[BattleEvent],
	branch_state: BattleState,
) -> Dictionary:
	var proposal := TrainerItemAwareActionProposal.new()
	if not trainer_memory_wiring_ready():
		return proposal.blocked_report("trainer_memory_not_ready", side_id)
	var memory := trainer_branch_memory_snapshot_for_side(side_id, events, branch_state)
	if memory == null:
		return proposal.blocked_report("branch_memory_unavailable", side_id)
	return proposal.evaluate(branch_state, side_id, memory, catalogs)


# C3f-ak authoritative substitution toggle. It is independent from proposal telemetry and
# disabled by default. When enabled, any non-ready proposal fails closed before Battle Core.
func set_trainer_action_substitution_enabled(enabled: bool) -> void:
	_trainer_action_substitution_enabled = enabled
	last_trainer_action_substitution_report = {}


func trainer_action_substitution_is_enabled() -> bool:
	return _trainer_action_substitution_enabled


# Contract validator for the narrowly authorized side_b substitution boundary. It accepts
# only the current, complete, uniquely resolved C3f-aj proposal and revalidates exact legality
# against the live authoritative server before returning a detached action dictionary.
func _trainer_action_substitution_candidate_from_report(report: Dictionary) -> Dictionary:
	if not has_active_battle() or _battle_server == null or _battle_server.state == null:
		return _trainer_action_substitution_blocked_report("no_active_trainer_battle", report)
	if String(report.get("proposal_status", "")) != TrainerItemAwareActionProposal.PROPOSAL_READY:
		return _trainer_action_substitution_blocked_report("proposal_not_ready", report)
	if String(report.get("battle_id", "")) != String(_battle_server.state.battle_id):
		return _trainer_action_substitution_blocked_report("proposal_battle_mismatch", report)
	if int(report.get("turn", -1)) != _battle_server.state.turn:
		return _trainer_action_substitution_blocked_report("proposal_turn_mismatch", report)
	if String(report.get("observer_side_id", "")) != "side_b" or not bool(report.get("context_side_matching", false)):
		return _trainer_action_substitution_blocked_report("proposal_side_mismatch", report)
	if not bool(report.get("memory_snapshot_detached", false)):
		return _trainer_action_substitution_blocked_report("proposal_memory_not_detached", report)
	if not bool(report.get("root_all_legal", false)):
		return _trainer_action_substitution_blocked_report("proposal_root_coverage_not_all_legal", report)
	if int(report.get("inner_max_actions_per_side", -1)) != TrainerItemAwareActionProposal.INNER_ACTION_CAP:
		return _trainer_action_substitution_blocked_report("proposal_inner_cap_mismatch", report)
	if int(report.get("required_depth", -1)) != TrainerItemAwareActionProposal.REQUIRED_DEPTH or int(report.get("common_depth", -1)) != TrainerItemAwareActionProposal.REQUIRED_DEPTH:
		return _trainer_action_substitution_blocked_report("proposal_depth_incomplete", report)
	if not bool(report.get("evaluations_complete", false)) or not bool(report.get("metadata_models_match", false)) or not bool(report.get("same_budget", false)):
		return _trainer_action_substitution_blocked_report("proposal_evaluation_incomplete", report)
	if int(report.get("legal_action_count", 0)) <= 0 or int(report.get("evaluated_root_count", -1)) != int(report.get("legal_action_count", 0)):
		return _trainer_action_substitution_blocked_report("proposal_root_coverage_incomplete", report)
	if String(report.get("resolution_outcome", "")) != TrainerItemAwareActionProposal.SINGLE_ROOT_CONTRACT:
		return _trainer_action_substitution_blocked_report("proposal_resolution_not_unique", report)
	if not bool(report.get("order_invariant", false)):
		return _trainer_action_substitution_blocked_report("proposal_not_order_invariant", report)
	if not bool(report.get("proposal_action_detached", false)) or not (report.get("proposal_action", null) is Dictionary):
		return _trainer_action_substitution_blocked_report("proposal_action_not_detached", report)

	var proposal_dict := (report.get("proposal_action", {}) as Dictionary).duplicate(true)
	var candidate := BattleAction.from_dict(proposal_dict)
	if candidate == null or candidate.side_id != &"side_b":
		return _trainer_action_substitution_blocked_report("proposal_action_wrong_side", report)
	var selected_root_id := String(report.get("selected_root_id", ""))
	if selected_root_id.is_empty() or _trainer_action_root_id(candidate) != selected_root_id:
		return _trainer_action_substitution_blocked_report("proposal_action_root_mismatch", report)

	var legal_actions := TrainerActionSpace.from_server(_battle_server, &"side_b")
	var exact_match := false
	for legal_action in legal_actions:
		if _trainer_battle_actions_equal(candidate, legal_action):
			exact_match = true
			break
	if not exact_match:
		return _trainer_action_substitution_blocked_report("proposal_action_not_currently_legal", report)

	return {
		"substitution_status": SUBSTITUTION_READY,
		"blocked_reason": "",
		"authoritative_substitution_scope": "side_b_opt_in_only",
		"proposal_status": String(report.get("proposal_status", "")),
		"proposal_model": String(report.get("proposal_model", "")),
		"selected_root_id": selected_root_id,
		"selected_kind": String(report.get("selected_kind", "")),
		"submitted_root_id": selected_root_id,
		"submitted_action": candidate.to_dict().duplicate(true),
		"proposal_action_currently_legal": true,
		"proposal_action_exact_match": true,
		"root_all_legal": bool(report.get("root_all_legal", false)),
		"inner_max_actions_per_side": int(report.get("inner_max_actions_per_side", -1)),
		"common_depth": int(report.get("common_depth", 0)),
		"caller_action": null,
		"caller_fallback_used": false,
		"action_substitution_authorized": true,
		"behavior_integration_authorized": true,
		"trainer_brain_integration_authorized": false,
		"lexical_tiebreak_used": false,
		"input_order_tiebreak_used": false,
		"kind_priority_used": false,
		"sampler_tiebreak_used": false,
		"live_rng_used": false,
		"frontier_fallback_used": false,
		"pareto_tiebreak_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"hidden_belief_fallback_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}


func _trainer_action_substitution_blocked_report(reason: String, proposal_report: Dictionary) -> Dictionary:
	return {
		"substitution_status": SUBSTITUTION_BLOCKED,
		"blocked_reason": reason,
		"authoritative_substitution_scope": "side_b_opt_in_only",
		"proposal_status": String(proposal_report.get("proposal_status", "")),
		"proposal_model": String(proposal_report.get("proposal_model", "")),
		"selected_root_id": String(proposal_report.get("selected_root_id", "")),
		"selected_kind": String(proposal_report.get("selected_kind", "")),
		"submitted_root_id": "",
		"submitted_action": null,
		"proposal_action_currently_legal": false,
		"proposal_action_exact_match": false,
		"root_all_legal": bool(proposal_report.get("root_all_legal", false)),
		"inner_max_actions_per_side": int(proposal_report.get("inner_max_actions_per_side", TrainerItemAwareActionProposal.INNER_ACTION_CAP)),
		"common_depth": int(proposal_report.get("common_depth", 0)),
		"caller_action": null,
		"caller_fallback_used": false,
		"action_substitution_authorized": false,
		"behavior_integration_authorized": false,
		"trainer_brain_integration_authorized": false,
		"lexical_tiebreak_used": false,
		"input_order_tiebreak_used": false,
		"kind_priority_used": false,
		"sampler_tiebreak_used": false,
		"live_rng_used": false,
		"frontier_fallback_used": false,
		"pareto_tiebreak_used": false,
		"roster_value_fallback_used": false,
		"profile_tiebreak_used": false,
		"campaign_policy_used": false,
		"recovery_policy_used": false,
		"replacement_policy_used": false,
		"hidden_belief_fallback_used": false,
		"selected_strategy_id": null,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}


func _trainer_battle_actions_equal(a: BattleAction, b: BattleAction) -> bool:
	return (
		a != null
		and b != null
		and a.turn == b.turn
		and a.action_type == b.action_type
		and a.side_id == b.side_id
		and a.actor_id == b.actor_id
		and a.move_id == b.move_id
		and a.target_id == b.target_id
		and a.switch_instance_id == b.switch_instance_id
		and a.item_id == b.item_id
	)


func _trainer_action_root_id(action: BattleAction) -> String:
	if action == null:
		return ""
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	return "move:%s" % String(action.move_id)


# Starts a trainer battle from trusted trainer identity + roster data.
# The session never creates/copies combatants: Battle receives the same CreatureInstance objects.
func begin_battle(
	p_opponent_trainer_id: StringName,
	p_opponent_roster: Array[CreatureInstance],
	battle_seed: int = 1,
) -> bool:
	last_error = ""
	last_trainer_shadow_report = {}
	last_trainer_action_proposal_report = {}
	last_trainer_action_substitution_report = {}
	if has_active_battle():
		last_error = "battle_already_active"
		return false
	if catalogs == null:
		last_error = "missing_catalog"
		return false
	if p_opponent_trainer_id == &"":
		last_error = "trainer_id_required"
		return false

	var player_roster := _roster_with_living_active(player.party.get_creatures())
	if player_roster.is_empty():
		last_error = "no_available_player_creature"
		return false
	var trainer_roster := _roster_with_living_active(p_opponent_roster)
	if trainer_roster.is_empty():
		last_error = "no_available_opponent_creature"
		return false

	var player_identity_error := _roster_identity_error(player_roster)
	if not player_identity_error.is_empty():
		last_error = "invalid_player_roster:%s" % player_identity_error
		return false
	var trainer_identity_error := _roster_identity_error(trainer_roster)
	if not trainer_identity_error.is_empty():
		last_error = "invalid_opponent_roster:%s" % trainer_identity_error
		return false
	if _has_identity_overlap(player_roster, trainer_roster):
		last_error = "creature_identity_overlap"
		return false

	var battle_id := StringName("trainer_battle_%s" % String(p_opponent_trainer_id))
	var state := BattleState.create_with_parties(
		battle_id,
		player_roster,
		trainer_roster,
		battle_seed,
		BattleRuleset.ID,
	)
	if state == null:
		last_error = "battle_state_creation_failed"
		return false

	var memory_owner := TrainerDualSideBattleMemoryOwner.new()
	if not memory_owner.begin(state):
		last_error = "trainer_memory_initialization_failed"
		return false

	_battle_server = AuthoritativeBattleServer.new(state, catalogs)
	_trainer_memory_owner = memory_owner
	_opponent_roster = trainer_roster.duplicate()
	opponent_trainer_id = p_opponent_trainer_id
	status = BATTLE_ACTIVE
	completion_reason = &""
	return true


# The application/presentation layer still chooses both actions. When C3f-af shadow is enabled,
# side_b ItemAware search is executed only to produce telemetry before the authoritative submit.
# The exact opponent_action argument below remains the action sent to Battle Core.
func submit_player_action(
	player_action: BattleAction,
	opponent_action: BattleAction,
) -> Array[BattleEvent]:
	last_error = ""
	if not has_active_battle():
		last_error = "no_active_trainer_battle"
		return []
	if player_action == null:
		last_error = "player_action_required"
		return []
	if opponent_action == null:
		last_error = "opponent_action_required"
		return []
	if player_action.side_id != &"side_a":
		last_error = "wrong_player_side"
		return []
	if opponent_action.side_id != &"side_b":
		last_error = "wrong_opponent_side"
		return []
	if not _trainer_memory_owner.is_ready(_battle_server.state):
		last_error = "trainer_memory_not_ready"
		return []

	if _trainer_shadow_item_aware_enabled:
		var shadow_report := trainer_shadow_item_aware_report_for_side(&"side_b")
		last_trainer_shadow_report = shadow_report.duplicate(true)
		if String(shadow_report.get("tranche_status", "")) != TrainerItemAwareShadowProbe.SHADOW_READY:
			last_error = "trainer_shadow_context_not_ready"
			return []
	else:
		last_trainer_shadow_report = {}

	var authoritative_opponent_action := opponent_action
	if _trainer_action_substitution_enabled:
		var proposal_report := trainer_action_proposal_report_for_side(&"side_b")
		last_trainer_action_proposal_report = proposal_report.duplicate(true)
		var substitution_report := _trainer_action_substitution_candidate_from_report(proposal_report)
		substitution_report["caller_action"] = opponent_action.to_dict().duplicate(true)
		last_trainer_action_substitution_report = substitution_report.duplicate(true)
		if String(substitution_report.get("substitution_status", "")) != SUBSTITUTION_READY:
			last_error = "trainer_action_substitution_not_ready"
			return []
		var submitted_dict := substitution_report.get("submitted_action", null)
		if not (submitted_dict is Dictionary):
			last_error = "trainer_action_substitution_not_ready"
			return []
		authoritative_opponent_action = BattleAction.from_dict((submitted_dict as Dictionary).duplicate(true))
		if authoritative_opponent_action == null:
			last_error = "trainer_action_substitution_not_ready"
			return []
	elif _trainer_action_proposal_enabled:
		last_trainer_action_proposal_report = trainer_action_proposal_report_for_side(&"side_b").duplicate(true)
		last_trainer_action_substitution_report = {}
	else:
		last_trainer_action_proposal_report = {}
		last_trainer_action_substitution_report = {}

	var events: Array[BattleEvent] = []
	if _trainer_action_substitution_enabled:
		events = _battle_server.submit_turn([player_action, authoritative_opponent_action])
	else:
		events = _submit_explicit_opponent_action(player_action, opponent_action)
	if not _trainer_memory_owner.observe_authoritative(events, _battle_server.state):
		_trainer_memory_owner.clear()
		last_error = "trainer_memory_fanout_failed"
		return events
	var rejection := _battle_rejection_reason(events)
	if not rejection.is_empty():
		last_error = rejection
	return events


# Preserve the historical explicit-caller path exactly when C3f-ak substitution is OFF.
# This helper is live production code, not a compatibility stub: submit_player_action uses it
# on the disabled/default path and returns the same authoritative event batch.
func _submit_explicit_opponent_action(
	player_action: BattleAction,
	opponent_action: BattleAction,
) -> Array[BattleEvent]:
	var events := _battle_server.submit_turn([player_action, opponent_action])
	return events


# Trainer battles settle only after Battle Core reaches FINISHED. Capture/Flee are not settlement
# reasons here. Victory reuses the same BattleOutcome -> Progression pipeline as the wild loop.
func settle_finished_battle() -> TrainerBattleSettlement:
	var out := TrainerBattleSettlement.new()
	last_error = ""
	if not has_active_battle():
		out.reason = "no_active_trainer_battle"
		last_error = out.reason
		return out
	var state := _battle_server.state
	if state.phase != BattleState.FINISHED:
		out.reason = "battle_not_finished"
		last_error = out.reason
		return out

	var outcome := BattleOutcome.from_battle_state(state, catalogs)
	out.outcome = outcome
	out.player_won = outcome.winner_side_id == &"side_a"
	if out.player_won:
		out.progression_events = ProgressionSystem.reconcile_battle_result(
			player.party.get_creatures(), outcome, catalogs, progression_ruleset
		)
	_reconcile_roster(player.party.get_creatures())
	_reconcile_roster(_opponent_roster)

	status = COMPLETED
	completion_reason = COMPLETED_VICTORY if out.player_won else COMPLETED_DEFEAT
	out.ok = true
	out.reason = ""
	out.session_completed = true
	_trainer_memory_owner.clear()
	_battle_server = null
	_opponent_roster.clear()
	_trainer_shadow_item_aware_enabled = false
	last_trainer_shadow_report = {}
	_trainer_action_proposal_enabled = false
	last_trainer_action_proposal_report = {}
	_trainer_action_substitution_enabled = false
	last_trainer_action_substitution_report = {}
	return out


func reset_after_completion() -> bool:
	last_error = ""
	if status != COMPLETED or _battle_server != null:
		last_error = "session_not_completed"
		return false
	_trainer_memory_owner.clear()
	_trainer_shadow_item_aware_enabled = false
	last_trainer_shadow_report = {}
	_trainer_action_proposal_enabled = false
	last_trainer_action_proposal_report = {}
	_trainer_action_substitution_enabled = false
	last_trainer_action_substitution_report = {}
	status = READY
	completion_reason = &""
	opponent_trainer_id = &""
	return true


func _roster_with_living_active(source: Array[CreatureInstance]) -> Array[CreatureInstance]:
	var first_living: CreatureInstance = null
	for creature in source:
		if creature != null and not creature.is_knocked_out():
			first_living = creature
			break
	if first_living == null:
		return []
	var roster: Array[CreatureInstance] = [first_living]
	for creature in source:
		if creature != null and creature != first_living:
			roster.append(creature)
	return roster


func _roster_identity_error(roster: Array[CreatureInstance]) -> String:
	var seen := {}
	for creature in roster:
		if creature == null:
			continue
		if creature.instance_id == &"":
			return "creature_identity_required"
		if seen.has(creature.instance_id):
			return "duplicate_creature_identity"
		seen[creature.instance_id] = true
	return ""


func _has_identity_overlap(
	player_roster: Array[CreatureInstance],
	trainer_roster: Array[CreatureInstance],
) -> bool:
	var ids := {}
	for creature in player_roster:
		if creature == null or creature.instance_id == &"":
			continue
		ids[creature.instance_id] = true
	for creature in trainer_roster:
		if creature != null and creature.instance_id != &"" and ids.has(creature.instance_id):
			return true
	return false


func _reconcile_roster(roster: Array[CreatureInstance]) -> void:
	for creature in roster:
		if creature != null:
			creature.reconcile_post_battle()


func _battle_rejection_reason(events: Array[BattleEvent]) -> String:
	for event in events:
		if event != null and event.kind == BattleEvent.ACTION_REJECTED:
			return String(event.metadata.get("reason", "action_rejected"))
	return ""
