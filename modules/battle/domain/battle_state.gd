class_name BattleState
extends RefCounted

const SCHEMA_VERSION := 2
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
var participant_ids: Array[StringName] = []
var sides: Array[BattleSide] = []
var battle_started: bool = false


func _init(
	p_battle_id: StringName = &"",
	p_creatures: Array[CreatureInstance] = [],
	p_rng_state: int = 1,
	p_ruleset_id: StringName = BattleRuleset.ID,
) -> void:
	battle_id = p_battle_id
	ruleset_id = p_ruleset_id
	rng_state = p_rng_state
	for creature in p_creatures:
		add_participant(creature)
	if p_creatures.size() == 2:
		sides.append(BattleSide.new(&"side_a", [p_creatures[0].instance_id], p_creatures[0].instance_id))
		sides.append(BattleSide.new(&"side_b", [p_creatures[1].instance_id], p_creatures[1].instance_id))
	_refresh_active_ids()


static func create_with_parties(
	p_battle_id: StringName,
	party_a: Array[CreatureInstance],
	party_b: Array[CreatureInstance],
	p_rng_state: int = 1,
	p_ruleset_id: StringName = BattleRuleset.ID,
) -> BattleState:
	var state := BattleState.new(p_battle_id, [], p_rng_state, p_ruleset_id)
	var ids_a: Array[StringName] = []
	var ids_b: Array[StringName] = []
	for creature in party_a:
		state.add_participant(creature)
		ids_a.append(creature.instance_id)
	for creature in party_b:
		state.add_participant(creature)
		ids_b.append(creature.instance_id)
	state.sides.append(BattleSide.new(&"side_a", ids_a))
	state.sides.append(BattleSide.new(&"side_b", ids_b))
	state._refresh_active_ids()
	return state


func add_participant(creature_instance: CreatureInstance) -> void:
	participants[creature_instance.instance_id] = creature_instance
	if not participant_ids.has(creature_instance.instance_id):
		participant_ids.append(creature_instance.instance_id)


func side_for_creature(creature_id: StringName) -> BattleSide:
	for side in sides:
		if side.owns(creature_id):
			return side
	return null


func active_for_side(side_id: StringName) -> CreatureInstance:
	for side in sides:
		if side.side_id == side_id:
			return creature(side.active_id)
	return null


func switch_active(side_id: StringName, creature_id: StringName) -> bool:
	for side in sides:
		if side.side_id == side_id and side.owns(creature_id):
			side.active_id = creature_id
			_refresh_active_ids()
			return true
	return false


func _refresh_active_ids() -> void:
	active_ids.clear()
	for side in sides:
		if side.active_id != &"":
			active_ids.append(side.active_id)


func creature(id: StringName) -> CreatureInstance:
	return participants.get(id) as CreatureInstance


func opponent_of(actor_id: StringName) -> CreatureInstance:
	var actor_side := side_for_creature(actor_id)
	for side in sides:
		if side != actor_side:
			return creature(side.active_id)
	return null


func to_dict() -> Dictionary:
	var serialized_ids: Array[String] = []
	var serialized_participants: Array[Dictionary] = []
	for id in participant_ids:
		serialized_ids.append(String(id))
		serialized_participants.append(creature(id).to_dict())
	var serialized_sides: Array[Dictionary] = []
	for side in sides:
		serialized_sides.append(side.to_dict())
	return {
		"schema_version": SCHEMA_VERSION,
		"ruleset_id": String(ruleset_id),
		"rng_algorithm": RNG_ALGORITHM,
		"battle_id": String(battle_id),
		"turn": turn,
		"phase": String(phase),
		"winner_id": String(winner_id),
		"rng_state": rng_state,
		"participant_ids": serialized_ids,
		"active_ids": _string_names_to_strings(active_ids),
		"participants": serialized_participants,
		"sides": serialized_sides,
		"battle_started": battle_started,
	}


static func from_dict(data: Dictionary) -> BattleState:
	assert(int(data.get("schema_version", -1)) == SCHEMA_VERSION, "Unsupported battle snapshot schema")
	assert(data.get("rng_algorithm", "") == RNG_ALGORITHM, "Unsupported battle RNG algorithm")
	var restored_creatures: Array[CreatureInstance] = []
	var creatures_by_id: Dictionary = {}
	for creature_data in data.get("participants", []):
		var restored := CreatureInstance.from_dict(creature_data)
		creatures_by_id[restored.instance_id] = restored
	for id in data.get("participant_ids", data.get("active_ids", [])):
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
	state.sides.clear()
	for side_data in data.get("sides", []):
		state.sides.append(BattleSide.from_dict(side_data))
	if state.sides.is_empty() and restored_creatures.size() == 2:
		state.sides.append(BattleSide.new(&"side_a", [restored_creatures[0].instance_id]))
		state.sides.append(BattleSide.new(&"side_b", [restored_creatures[1].instance_id]))
	state._refresh_active_ids()
	state.battle_started = bool(data.get("battle_started", false))
	return state


static func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
