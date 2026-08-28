class_name BattleState
extends RefCounted

const SCHEMA_VERSION := 1
const RNG_ALGORITHM := "lcg32_v1"
const WAITING_FOR_ACTIONS := &"waiting_for_actions"
const FINISHED := &"finished"

var battle_id: StringName
var ruleset_id: StringName
var turn: int = 0
var phase: StringName = WAITING_FOR_ACTIONS
var winner_id: StringName = &""
var rng_state: int
var active_ids: Array[StringName] = []
var participants: Dictionary = {}


func _init(
	p_battle_id: StringName = &"",
	p_creatures: Array[CreatureInstance] = [],
	p_rng_state: int = 1,
	p_ruleset_id: StringName = &"foundation_v1",
) -> void:
	battle_id = p_battle_id
	ruleset_id = p_ruleset_id
	rng_state = p_rng_state
	for creature in p_creatures:
		participants[creature.instance_id] = creature
		active_ids.append(creature.instance_id)


func creature(id: StringName) -> CreatureInstance:
	return participants.get(id) as CreatureInstance


func opponent_of(actor_id: StringName) -> CreatureInstance:
	for id in active_ids:
		if id != actor_id:
			return creature(id)
	return null


func to_dict() -> Dictionary:
	var serialized_ids: Array[String] = []
	var serialized_participants: Array[Dictionary] = []
	for id in active_ids:
		serialized_ids.append(String(id))
		serialized_participants.append(creature(id).to_dict())
	return {
		"schema_version": SCHEMA_VERSION,
		"ruleset_id": String(ruleset_id),
		"rng_algorithm": RNG_ALGORITHM,
		"battle_id": String(battle_id),
		"turn": turn,
		"phase": String(phase),
		"winner_id": String(winner_id),
		"rng_state": rng_state,
		"active_ids": serialized_ids,
		"participants": serialized_participants,
	}


static func from_dict(data: Dictionary) -> BattleState:
	assert(int(data.get("schema_version", -1)) == SCHEMA_VERSION, "Unsupported battle snapshot schema")
	assert(data.get("rng_algorithm", "") == RNG_ALGORITHM, "Unsupported battle RNG algorithm")
	var restored_creatures: Array[CreatureInstance] = []
	var creatures_by_id: Dictionary = {}
	for creature_data in data.get("participants", []):
		var restored := CreatureInstance.from_dict(creature_data)
		creatures_by_id[restored.instance_id] = restored
	for id in data.get("active_ids", []):
		var stable_id := StringName(id)
		if creatures_by_id.has(stable_id):
			restored_creatures.append(creatures_by_id[stable_id])
	var state := BattleState.new(
		StringName(data.get("battle_id", "")),
		restored_creatures,
		int(data.get("rng_state", 1)),
		StringName(data.get("ruleset_id", "")),
	)
	state.turn = int(data.get("turn", 0))
	state.phase = StringName(data.get("phase", WAITING_FOR_ACTIONS))
	state.winner_id = StringName(data.get("winner_id", ""))
	return state
