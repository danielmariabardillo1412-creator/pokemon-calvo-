class_name TrainerBattleSession
extends RefCounted

# Headless application boundary for battles against owned trainer parties.
# Battle rules remain authoritative in Battle Core. This layer composes player ownership,
# opponent roster, settlement and progression; it deliberately exposes no Capture or Run command.

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

var _battle_server: AuthoritativeBattleServer = null
var _opponent_roster: Array[CreatureInstance] = []


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


# Starts a trainer battle from trusted trainer identity + roster data.
# The session never creates/copies combatants: Battle receives the same CreatureInstance objects.
func begin_battle(
	p_opponent_trainer_id: StringName,
	p_opponent_roster: Array[CreatureInstance],
	battle_seed: int = 1,
) -> bool:
	last_error = ""
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

	_battle_server = AuthoritativeBattleServer.new(state, catalogs)
	_opponent_roster = trainer_roster.duplicate()
	opponent_trainer_id = p_opponent_trainer_id
	status = BATTLE_ACTIVE
	completion_reason = &""
	return true


# The application/presentation layer may choose the trainer action, but Battle Core validates both
# actions authoritatively. Future network/AI work must move opponent strategy behind server authority;
# this phase only proves the local trainer-battle seam and does not claim network security.
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

	var events := _battle_server.submit_turn([player_action, opponent_action])
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
	_battle_server = null
	_opponent_roster.clear()
	return out


func reset_after_completion() -> bool:
	last_error = ""
	if status != COMPLETED or _battle_server != null:
		last_error = "session_not_completed"
		return false
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
			return String(event.data.get("reason", "action_rejected"))
	return ""
