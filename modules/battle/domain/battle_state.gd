class_name BattleState
extends RefCounted

const SCHEMA_VERSION := 2
const RNG_ALGORITHM := "lcg32_v1"
const WAITING_FOR_ACTIONS := &"waiting_for_actions"
const WAITING_FOR_SWITCH := &"waiting_for_switch"
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
# Optional additive field within snapshot schema V2. Empty inventories are omitted
# from serialization so all historical V2 snapshots remain byte-for-byte stable.
var side_item_inventories: Dictionary = {} # side_id -> BattleSideItemInventory
# Explicit singles pilot. Disabled snapshots retain the historical V2 wire format.
# Continuation is state, not a UI callback, so a restored server can resume it.
var switch_move_rules_enabled: bool = false
var battle_kind: StringName = &"trainer"
var pending_switch: Dictionary = {}
var remaining_turn_actions: Array[BattleAction] = []
var end_reason: StringName = &""
var live_moves_enabled: bool = false
var transform_rules_enabled: bool = false
var substitute_rules_enabled: bool = false
var weather_rules_enabled: bool = false
var weather: Dictionary = {}


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


func item_inventory_for_side(side_id: StringName) -> BattleSideItemInventory:
	var value: Variant = side_item_inventories.get(side_id, null)
	return value as BattleSideItemInventory if value is BattleSideItemInventory else null


func ensure_item_inventory_for_side(side_id: StringName) -> BattleSideItemInventory:
	if side_id == &"":
		return null
	var existing := item_inventory_for_side(side_id)
	if existing != null:
		return existing
	var created := BattleSideItemInventory.new()
	side_item_inventories[side_id] = created
	return created


func set_item_inventory_for_side(
	side_id: StringName,
	inventory: BattleSideItemInventory,
) -> bool:
	if side_id == &"":
		return false
	if inventory == null or inventory.is_empty():
		side_item_inventories.erase(side_id)
		return true
	side_item_inventories[side_id] = inventory.duplicate_inventory()
	return true


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
	var result := {
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
	var serialized_inventories: Dictionary = {}
	var inventory_side_ids := side_item_inventories.keys()
	inventory_side_ids.sort_custom(func(a, b): return String(a) < String(b))
	for raw_side_id in inventory_side_ids:
		var side_id := StringName(raw_side_id)
		var inventory := item_inventory_for_side(side_id)
		if inventory != null and not inventory.is_empty():
			serialized_inventories[String(side_id)] = inventory.to_dict()
	if not serialized_inventories.is_empty():
		result["side_item_inventories"] = serialized_inventories
	if switch_move_rules_enabled:
		var remaining: Array[Dictionary] = []
		for action in remaining_turn_actions:
			remaining.append(action.to_dict())
		result["switch_move_context"] = {"version": 1, "battle_kind": String(battle_kind),
			"pending": pending_switch.duplicate(true), "remaining_actions": remaining,
			"end_reason": String(end_reason)}
	if weather_rules_enabled:
		result["weather_context"] = {"version": 1, "weather": weather.duplicate(true)}
	if live_moves_enabled: result["live_moves_context"] = {"version": 1}
	if transform_rules_enabled:
		result["transform_context"] = {"version": 1}
	if substitute_rules_enabled:
		result["substitute_context"] = {"version": 1}
	if switch_move_rules_enabled or weather_rules_enabled or substitute_rules_enabled or transform_rules_enabled or live_moves_enabled:
		return _canonical_switch_snapshot(result)
	return result


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
	var live_context: Variant = data.get("live_moves_context", {})
	if live_context is Dictionary: state.live_moves_enabled = live_context.get("version", 0) == 1
	var transform_context: Variant = data.get("transform_context", {})
	if transform_context is Dictionary: state.transform_rules_enabled = transform_context.get("version", 0) == 1
	var substitute_context: Variant = data.get("substitute_context", {})
	if substitute_context is Dictionary:
		state.substitute_rules_enabled = substitute_context.get("version", 0) == 1
	var weather_context: Variant = data.get("weather_context", {})
	if weather_context is Dictionary and weather_context.get("version", 0) == 1:
		state.weather_rules_enabled = true
		state.weather = weather_context.get("weather", {}).duplicate(true)
		for field: String in ["turns_remaining", "set_turn"]:
			if state.weather.has(field): state.weather[field] = int(state.weather[field])
	var switch_context: Variant = data.get("switch_move_context", {})
	if switch_context is Dictionary and switch_context.get("version", 0) == 1:
		state.switch_move_rules_enabled = true
		state.battle_kind = StringName(switch_context.get("battle_kind", "trainer"))
		state.pending_switch = switch_context.get("pending", {}).duplicate(true)
		state.end_reason = StringName(switch_context.get("end_reason", ""))
		for action_data: Dictionary in switch_context.get("remaining_actions", []):
			state.remaining_turn_actions.append(BattleAction.from_dict(action_data))
	var raw_inventories: Variant = data.get("side_item_inventories", {})
	if raw_inventories is Dictionary:
		for raw_side_id in (raw_inventories as Dictionary).keys():
			var side_id := StringName(raw_side_id)
			var raw_inventory: Variant = (raw_inventories as Dictionary)[raw_side_id]
			if side_id != &"" and raw_inventory is Dictionary:
				var inventory := BattleSideItemInventory.from_dict(raw_inventory as Dictionary)
				if not inventory.is_empty():
					state.side_item_inventories[side_id] = inventory
	return state


static func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


static func _canonical_switch_snapshot(value: Variant) -> Variant:
	# JSON parses numbers as floats. Canonicalize exact integral payload values so
	# transferred volatile counters compare identically after save/restore. Preserve
	# genuine fractions and leave the historical disabled snapshot path unchanged.
	if value is Dictionary:
		var result := {}
		for key: Variant in value:
			result[key] = _canonical_switch_snapshot(value[key])
		return result
	if value is Array:
		var result := []
		for item: Variant in value:
			result.append(_canonical_switch_snapshot(item))
		return result
	if value is float and is_finite(value) and absf(value) <= 9007199254740991.0 and value == floor(value):
		return int(value)
	return value
