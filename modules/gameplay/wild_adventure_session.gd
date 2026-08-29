class_name WildAdventureSession
extends RefCounted

# Headless application-layer vertical slice for one player's wild-adventure loop.
# It composes existing domain services; it does NOT own their rules and contains no UI, Node,
# autoload, map, animation or networking transport.

const READY := &"READY"
const BATTLE_ACTIVE := &"BATTLE_ACTIVE"
const COMPLETED := &"COMPLETED"

const COMPLETED_CAPTURED := &"CAPTURED"
const COMPLETED_VICTORY := &"VICTORY"
const COMPLETED_DEFEAT := &"DEFEAT"

var player: PlayerCollection
var catalogs: DefinitionCatalog
var progression_ruleset: ProgressionRuleset
var status: StringName = READY
var completion_reason: StringName = &""

var _encounter: WildEncounterResult = null
var _battle_server: AuthoritativeBattleServer = null
var _save_repository: SaveGameRepository = SaveGameRepository.new()


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


func current_wild() -> CreatureInstance:
	if _battle_server == null:
		return null
	return _battle_server.state.active_for_side(&"side_b")


func player_active() -> CreatureInstance:
	if _battle_server == null:
		return null
	return _battle_server.state.active_for_side(&"side_a")


# Start a wild encounter request. Invalid player state is rejected BEFORE Encounter consumes RNG.
# If chance misses, the session remains READY and the semantic NONE result is returned.
func begin_encounter(
	table: WildEncounterTable,
	encounter_rng: RandomNumberGenerator,
	battle_seed: int = 1,
) -> WildEncounterResult:
	if has_active_battle():
		return _encounter_error("battle_already_active")
	if catalogs == null:
		return _encounter_error("missing_catalog")
	var roster := _battle_roster_with_living_active()
	if roster.is_empty():
		return _encounter_error("no_available_player_creature")

	var result := WildEncounterSystem.resolve(table, encounter_rng, catalogs, progression_ruleset)
	if result.status != WildEncounterResult.ENCOUNTER:
		status = READY
		completion_reason = &""
		_encounter = null
		_battle_server = null
		return result

	_encounter = result
	var battle_id := StringName("wild_battle_%s" % String(result.creature.instance_id))
	var state := BattleState.create_with_parties(
		battle_id,
		roster,
		[result.creature],
		battle_seed,
		BattleRuleset.ID,
	)
	_battle_server = AuthoritativeBattleServer.new(state, catalogs)
	status = BATTLE_ACTIVE
	completion_reason = &""
	return result


func submit_turn(actions: Array[BattleAction]) -> Array[BattleEvent]:
	if not has_active_battle():
		return []
	return _battle_server.submit_turn(actions)


# Canonical player-command boundary for the wild battle loop. A MOVE/SWITCH command is paired with
# the already-selected opponent action and submitted as a normal authoritative turn. A CAPTURE
# command is resolved against trusted live battle/player state. Invalid capture commands consume
# neither turn nor opponent response; a failed valid capture consumes one turn and executes exactly
# one legal opponent response through the same TurnExecutor end-turn pipeline.
func submit_player_command(
	command: WildBattleCommand,
	capture_rng: RandomNumberGenerator = null,
	opponent_action: BattleAction = null,
) -> WildBattleCommandResult:
	var out := WildBattleCommandResult.new()
	if command != null:
		out.command_type = command.command_type
	if not has_active_battle():
		out.reason = "no_active_wild_battle"
		return out
	var state := _battle_server.state
	if state.phase != BattleState.WAITING_FOR_ACTIONS:
		out.reason = "battle_finished"
		return out
	if command == null:
		out.reason = "command_required"
		return out
	if command.turn != state.turn + 1:
		out.reason = "wrong_turn"
		return out
	var active_player := player_active()
	if active_player == null:
		out.reason = "player_actor_missing"
		return out
	var player_side := state.side_for_creature(active_player.instance_id)
	if player_side == null:
		out.reason = "player_side_missing"
		return out
	if command.side_id == &"":
		out.reason = "missing_participant"
		return out
	if command.side_id != player_side.side_id:
		out.reason = "wrong_participant"
		return out

	# Validate the response before any command can mutate inventory or consume capture RNG. This is
	# what prevents a malformed/forged opponent action from turning a failed capture into a free turn.
	var reaction_error := _battle_server.validate_reaction_action(opponent_action, player_side.side_id)
	if not reaction_error.is_empty():
		out.reason = "invalid_opponent_response:%s" % reaction_error
		return out

	if command.command_type == WildBattleCommand.ACTION:
		if command.action == null:
			out.reason = "action_required"
			return out
		if command.action.turn != command.turn or command.action.side_id != command.side_id:
			out.reason = "command_action_mismatch"
			return out
		out.battle_events = _battle_server.submit_turn([command.action, opponent_action])
		var rejection := _battle_rejection_reason(out.battle_events)
		if not rejection.is_empty():
			out.reason = rejection
			return out
		out.accepted = true
		out.turn_consumed = true
		out.battle_finished = state.phase == BattleState.FINISHED
		return out

	if command.command_type != WildBattleCommand.CAPTURE:
		out.reason = "invalid_command_type"
		return out
	if command.ball_id == &"":
		out.reason = "ball_id_required"
		return out
	if capture_rng == null:
		out.reason = "capture_rng_required"
		return out

	var capture_outcome := capture_current(command.ball_id, capture_rng)
	out.capture_outcome = capture_outcome
	if capture_outcome == null or capture_outcome.resolution == null or capture_outcome.resolution.result == null:
		out.reason = "capture_resolution_missing"
		return out
	var capture_result := capture_outcome.resolution.result
	if capture_result.status == CaptureResult.INVALID:
		out.reason = capture_result.reason
		return out
	if capture_result.status == CaptureResult.SUCCESS:
		out.accepted = capture_outcome.session_completed
		out.turn_consumed = capture_outcome.session_completed
		out.session_completed = capture_outcome.session_completed
		if not capture_outcome.session_completed:
			out.reason = capture_outcome.reason if not capture_outcome.reason.is_empty() else "capture_completion_failed"
		return out
	if capture_result.status != CaptureResult.FAILED:
		out.reason = "unknown_capture_result"
		return out

	out.battle_events = _battle_server.submit_reaction_turn(opponent_action, player_side.side_id)
	var reaction_rejection := _battle_rejection_reason(out.battle_events)
	if not reaction_rejection.is_empty():
		out.reason = "opponent_response_rejected:%s" % reaction_rejection
		return out
	out.accepted = true
	out.turn_consumed = true
	out.battle_finished = _battle_server.state.phase == BattleState.FINISHED
	return out


# Attempt to capture the active wild creature. The session constructs the trusted capture context
# from its own live battle instead of accepting ownership/battle facts from the caller.
func capture_current(ball_id: StringName, capture_rng: RandomNumberGenerator) -> WildAdventureCaptureOutcome:
	var out := WildAdventureCaptureOutcome.new()
	if not has_active_battle():
		out.reason = "no_active_wild_battle"
		return out
	if _battle_server.state.phase == BattleState.FINISHED:
		out.reason = "battle_finished"
		return out
	var target := current_wild()
	if target == null:
		out.reason = "wild_target_missing"
		return out

	var context := CaptureBattleContext.new()
	context.is_wild = true
	context.battle_finished = false
	context.target_owner_trainer_id = &""
	context.target_side_id = &"side_b"
	var attempt := CaptureAttempt.new(target, ball_id, context)
	var resolution := CaptureInventoryService.resolve(
		attempt, capture_rng, catalogs, player.party, player.inventory
	)
	out.resolution = resolution
	if resolution == null or resolution.result == null:
		out.reason = "capture_resolution_missing"
		return out
	if resolution.result.status != CaptureResult.SUCCESS:
		out.reason = resolution.result.reason
		return out

	var routing := CaptureOwnershipRouter.new().route(resolution, player.party, player.storage)
	out.routing = routing
	if routing == null or not routing.routed:
		out.reason = "capture_routing_failed"
		return out

	# Battle-only modifiers must never leak into the newly-owned creature or the player's roster.
	_reconcile_player_party()
	if resolution.captured != null:
		resolution.captured.reconcile_post_battle()
	status = COMPLETED
	completion_reason = COMPLETED_CAPTURED
	out.session_completed = true
	out.reason = ""
	_encounter = null
	_battle_server = null
	return out


# Settle a Battle Core victory/defeat only after the authoritative battle has actually finished.
# Progression consumes BattleOutcome; this layer never reaches into Progression internals.
func settle_finished_battle() -> WildBattleSettlement:
	var out := WildBattleSettlement.new()
	if not has_active_battle():
		out.reason = "no_active_wild_battle"
		return out
	var state := _battle_server.state
	if state.phase != BattleState.FINISHED:
		out.reason = "battle_not_finished"
		return out

	var outcome := BattleOutcome.from_battle_state(state, catalogs)
	out.outcome = outcome
	out.player_won = outcome.winner_side_id == &"side_a"
	if out.player_won:
		out.progression_events = ProgressionSystem.reconcile_battle_result(
			player.party.get_creatures(), outcome, catalogs, progression_ruleset
		)
	_reconcile_player_party()

	status = COMPLETED
	completion_reason = COMPLETED_VICTORY if out.player_won else COMPLETED_DEFEAT
	out.ok = true
	out.reason = ""
	out.session_completed = true
	_encounter = null
	_battle_server = null
	return out


# Apply only a currently-eligible evolution target for the owned creature. This rejects a forged
# EVOLUTION_AVAILABLE event that names an arbitrary species, which is important for future network
# authority and is also a useful local invariant today.
func apply_evolution_event(event: ProgressionEvent) -> CreatureInstance:
	if event == null or event.kind != ProgressionEvent.EVOLUTION_AVAILABLE:
		return null
	var current := player.owned_creature(event.creature_id)
	if current == null:
		return null
	var species: CreatureSpecies = catalogs.species_catalog.get_by_id(current.species_id) if catalogs != null else null
	if species == null:
		return null
	var requested_target := StringName(event.data.get("species_id", ""))
	if requested_target == &"":
		return null
	var allowed := false
	for candidate in EvolutionSystem.evolution_candidates(
		species, {"level": current.level}, catalogs
	):
		if candidate is EvolutionRecord and candidate.species_id == requested_target:
			allowed = true
			break
	if not allowed:
		return null
	var evolved := ProgressionSystem.apply_evolution(
		current, event, catalogs, progression_ruleset
	)
	if evolved == null or evolved.instance_id != current.instance_id:
		return null
	if not player.replace_owned_same_identity(evolved):
		return null
	return evolved


# The V2 save does not claim to serialize a live wild battle. Refuse mid-battle saves rather than
# silently dropping transient state. World/battle continuation can get an explicit schema later.
func save_game(path: String) -> SaveResult:
	if has_active_battle():
		var blocked := SaveResult.new()
		blocked.reason = "active_wild_battle"
		blocked.path = path
		return blocked
	return _save_repository.save_collection(path, player)


# Loading is likewise all-or-nothing. On success replace the player aggregate, clear any completed
# transient encounter state, and make the restored collection immediately usable for another loop.
func load_game(path: String) -> LoadResult:
	if has_active_battle():
		var blocked := LoadResult.new()
		blocked.reason = "active_wild_battle"
		return blocked
	var loaded := _save_repository.load(path)
	if not loaded.ok:
		return loaded
	var restored := PlayerCollection.new()
	restored.party = loaded.party
	restored.storage = loaded.storage
	restored.inventory = loaded.inventory
	player = restored
	status = READY
	completion_reason = &""
	_encounter = null
	_battle_server = null
	return loaded


func reset_after_completion() -> bool:
	if status != COMPLETED:
		return false
	status = READY
	completion_reason = &""
	return true


func _battle_roster_with_living_active() -> Array[CreatureInstance]:
	var all := player.party.get_creatures()
	var first_living: CreatureInstance = null
	for creature in all:
		if creature != null and not creature.is_knocked_out():
			first_living = creature
			break
	if first_living == null:
		return []
	var roster: Array[CreatureInstance] = [first_living]
	for creature in all:
		if creature != first_living:
			roster.append(creature)
	return roster


func _reconcile_player_party() -> void:
	for creature in player.party.get_creatures():
		if creature != null:
			creature.reconcile_post_battle()


func _battle_rejection_reason(events: Array[BattleEvent]) -> String:
	for event in events:
		if event != null and event.kind == BattleEvent.ACTION_REJECTED:
			return String(event.metadata.get("reason", "action_rejected"))
	return ""


func _encounter_error(reason: String) -> WildEncounterResult:
	var out := WildEncounterResult.new()
	out.status = WildEncounterResult.INVALID
	out.reason = reason
	return out
