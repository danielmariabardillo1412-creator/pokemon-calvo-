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

var player: PlayerCollection
var catalogs: DefinitionCatalog
var progression_ruleset: ProgressionRuleset
var status: StringName = READY
var completion_reason: StringName = &""
var opponent_trainer_id: StringName = &""
var last_error: String = ""
var last_trainer_shadow_report: Dictionary = {}
var last_trainer_action_proposal_report: Dictionary = {}

var _battle_server: AuthoritativeBattleServer = null
var _opponent_roster: Array[CreatureInstance] = []
var _trainer_memory_owner := TrainerDualSideBattleMemoryOwner.new()
var _trainer_shadow_item_aware_enabled: bool = false
var _trainer_action_proposal_enabled: bool = false


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


# Starts a trainer battle from trusted trainer identity + roster data.
# The session never creates/copies combatants: Battle receives the same CreatureInstance objects.
func begin_battle(
	p_opponent_trainer_id: StringName,
	p_opponent_roster: Array[CreatureInstance],
	battle_seed: int = 1,
) -> bool:
	last_error = ""
	last_trainer_shadow_report = {}
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

	if _trainer_action_proposal_enabled:
		last_trainer_action_proposal_report = trainer_action_proposal_report_for_side(&"side_b").duplicate(true)
	else:
		last_trainer_action_proposal_report = {}

	var events := _battle_server.submit_turn([player_action, opponent_action])
	if not _trainer_memory_owner.observe_authoritative(events, _battle_server.state):
		_trainer_memory_owner.clear()
		last_error = "trainer_memory_fanout_failed"
		return events
	var rejection := _battle_rejection_reason(events)
	if not rejection.is_empty():
		last_error = rejection
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
