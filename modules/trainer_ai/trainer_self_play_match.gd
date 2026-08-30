class_name TrainerSelfPlayMatch
extends RefCounted

const SCHEMA_VERSION := 1
const COMPLETED := "completed"
const TURN_LIMIT := "turn_limit"
const DECISION_FAILURE := "decision_failure"
const ACTION_REJECTED := "action_rejected"
const OBSERVATION_FAILURE := "observation_failure"

var max_turns: int = 40


func _init(p_max_turns: int = 40) -> void:
	max_turns = maxi(1, p_max_turns)


func run(
	catalog: DefinitionCatalog,
	roster_a: Array[CreatureInstance],
	brain_a: TrainerBrain,
	roster_b: Array[CreatureInstance],
	brain_b: TrainerBrain,
	seed: int,
	battle_id: StringName = &"trainer_self_play",
) -> Dictionary:
	if catalog == null or brain_a == null or brain_b == null:
		return _invalid_result(seed, "missing_match_dependency")
	var party_a := _clone_roster(roster_a)
	var party_b := _clone_roster(roster_b)
	if party_a.is_empty() or party_b.is_empty():
		return _invalid_result(seed, "empty_roster")

	var state := BattleState.create_with_parties(
		battle_id,
		party_a,
		party_b,
		seed,
		BattleRuleset.ID,
	)
	var server := AuthoritativeBattleServer.new(state, catalog)
	var controller_a := TrainerIntelligenceController.new(&"side_a", brain_a, catalog)
	var controller_b := TrainerIntelligenceController.new(&"side_b", brain_b, catalog)
	if not controller_a.begin(server) or not controller_b.begin(server):
		return _invalid_result(seed, "controller_begin_failed")

	var analyzer := TrainerBlunderAnalyzer.new()
	var turn_records: Array[Dictionary] = []
	var termination := ""

	while state.phase == BattleState.WAITING_FOR_ACTIONS and state.turn < max_turns:
		var next_turn := state.turn + 1
		# Both decisions are made before either action reaches Battle Core.
		var action_a := controller_a.choose_action(server)
		var trace_a := _trace_for_brain(brain_a)
		var action_b := controller_b.choose_action(server)
		var trace_b := _trace_for_brain(brain_b)
		analyzer.inspect_decision(&"side_a", action_a, trace_a, next_turn)
		analyzer.inspect_decision(&"side_b", action_b, trace_b, next_turn)
		if action_a == null or action_b == null:
			termination = DECISION_FAILURE
			break

		var events := server.submit_turn([action_a, action_b])
		analyzer.inspect_events(events, next_turn)
		turn_records.append({
			"turn": next_turn,
			"side_a_action": action_a.to_dict().duplicate(true),
			"side_b_action": action_b.to_dict().duplicate(true),
			"side_a_trace": trace_a.to_dict() if trace_a != null else {},
			"side_b_trace": trace_b.to_dict() if trace_b != null else {},
			"events": _events_to_dict(events),
		})
		if _has_rejection(events):
			termination = ACTION_REJECTED
			break
		if not controller_a.observe(events, server) or not controller_b.observe(events, server):
			termination = OBSERVATION_FAILURE
			break

	if termination.is_empty():
		if state.phase == BattleState.FINISHED:
			termination = COMPLETED
		else:
			termination = TURN_LIMIT
			analyzer.mark_turn_limit(state.turn)

	var winner_side_id := _winner_side_id(state)
	return {
		"schema_version": SCHEMA_VERSION,
		"ok": termination == COMPLETED or termination == TURN_LIMIT,
		"battle_id": String(battle_id),
		"seed": seed,
		"max_turns": max_turns,
		"turn_count": state.turn,
		"termination": termination,
		"winner_side_id": String(winner_side_id),
		"draw": winner_side_id == &"",
		"brain_a_id": String(brain_a.brain_id),
		"brain_b_id": String(brain_b.brain_id),
		"turns": turn_records,
		"blunders": analyzer.report(),
	}


func _clone_roster(source: Array[CreatureInstance]) -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	for creature in source:
		if creature != null:
			out.append(CreatureInstance.from_dict(creature.to_dict().duplicate(true)))
	return out


func _trace_for_brain(brain: TrainerBrain) -> TrainerDecisionTrace:
	if brain is DepthSearchTrainerBrain:
		return (brain as DepthSearchTrainerBrain).last_trace
	if brain is SearchTrainerBrain:
		return (brain as SearchTrainerBrain).last_trace
	if brain is TacticalTrainerBrain:
		return (brain as TacticalTrainerBrain).last_trace
	return null


func _events_to_dict(events: Array[BattleEvent]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event in events:
		if event != null:
			out.append(event.to_dict())
	return out


func _has_rejection(events: Array[BattleEvent]) -> bool:
	for event in events:
		if event != null and event.kind == BattleEvent.ACTION_REJECTED:
			return true
	return false


func _winner_side_id(state: BattleState) -> StringName:
	if state == null or state.phase != BattleState.FINISHED or state.winner_id == &"":
		return &""
	var side := state.side_for_creature(state.winner_id)
	return side.side_id if side != null else &""


func _invalid_result(seed: int, reason: String) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"ok": false,
		"seed": seed,
		"max_turns": max_turns,
		"turn_count": 0,
		"termination": reason,
		"winner_side_id": "",
		"draw": true,
		"brain_a_id": "",
		"brain_b_id": "",
		"turns": [],
		"blunders": {"schema_version": 1, "counts": {}, "records": [], "record_count": 0},
	}
