class_name TrainerBattleMemory
extends RefCounted

const SCHEMA_VERSION := 1

var battle_id: StringName = &""
var observer_side_id: StringName = &""
var last_observed_turn: int = 0
var seen_opponent_ids: Array[StringName] = []
var event_log: Array[Dictionary] = []

var _revealed_moves: Dictionary = {}
var _revealed_abilities: Dictionary = {}
var _revealed_items: Dictionary = {}


func begin(state: BattleState, p_observer_side_id: StringName) -> bool:
	clear()
	if state == null or state.active_for_side(p_observer_side_id) == null:
		return false
	battle_id = state.battle_id
	observer_side_id = p_observer_side_id
	last_observed_turn = state.turn
	_mark_current_opponent_seen(state)
	return true


func clear() -> void:
	battle_id = &""
	observer_side_id = &""
	last_observed_turn = 0
	seen_opponent_ids.clear()
	event_log.clear()
	_revealed_moves.clear()
	_revealed_abilities.clear()
	_revealed_items.clear()


func observe_events(events: Array[BattleEvent], state: BattleState) -> bool:
	if state == null or observer_side_id == &"" or state.battle_id != battle_id:
		return false
	for event in events:
		if event == null:
			continue
		event_log.append(event.to_dict().duplicate(true))
		last_observed_turn = maxi(last_observed_turn, event.turn)
		if event.kind == BattleEvent.SWITCHED and _is_opponent_creature(state, event.target_id):
			mark_seen(event.target_id)
		if not _is_opponent_creature(state, event.actor_id):
			continue
		match event.kind:
			BattleEvent.ACTION_USED:
				if event.move_id != &"":
					reveal_move(event.actor_id, event.move_id)
			BattleEvent.ABILITY_TRIGGERED:
				var ability_id := StringName(event.metadata.get("source_id", ""))
				if ability_id != &"":
					reveal_ability(event.actor_id, ability_id)
			BattleEvent.ITEM_TRIGGERED:
				var item_id := StringName(event.metadata.get("source_id", ""))
				if item_id != &"":
					reveal_item(event.actor_id, item_id)
	_mark_current_opponent_seen(state)
	last_observed_turn = maxi(last_observed_turn, state.turn)
	return true


func mark_seen(creature_id: StringName) -> void:
	if creature_id != &"" and not seen_opponent_ids.has(creature_id):
		seen_opponent_ids.append(creature_id)


func has_seen(creature_id: StringName) -> bool:
	return seen_opponent_ids.has(creature_id)


func reveal_move(creature_id: StringName, move_id: StringName) -> void:
	if creature_id == &"" or move_id == &"":
		return
	_append_unique(_revealed_moves, creature_id, move_id)


func reveal_ability(creature_id: StringName, ability_id: StringName) -> void:
	if creature_id != &"" and ability_id != &"":
		_revealed_abilities[creature_id] = ability_id


func reveal_item(creature_id: StringName, item_id: StringName) -> void:
	if creature_id != &"" and item_id != &"":
		_revealed_items[creature_id] = item_id


func revealed_move_ids(creature_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for value in _revealed_moves.get(creature_id, []):
		out.append(StringName(value))
	return out


func revealed_ability_id(creature_id: StringName) -> StringName:
	return StringName(_revealed_abilities.get(creature_id, ""))


func revealed_item_id(creature_id: StringName) -> StringName:
	return StringName(_revealed_items.get(creature_id, ""))


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"battle_id": String(battle_id),
		"observer_side_id": String(observer_side_id),
		"last_observed_turn": last_observed_turn,
		"seen_opponent_ids": _string_names_to_strings(seen_opponent_ids),
		"revealed_moves": _serialize_multi_map(_revealed_moves),
		"revealed_abilities": _serialize_single_map(_revealed_abilities),
		"revealed_items": _serialize_single_map(_revealed_items),
		"event_log": event_log.duplicate(true),
	}


static func from_dict(data: Dictionary) -> TrainerBattleMemory:
	assert(int(data.get("schema_version", -1)) == SCHEMA_VERSION, "Unsupported trainer memory schema")
	var memory := TrainerBattleMemory.new()
	memory.battle_id = StringName(data.get("battle_id", ""))
	memory.observer_side_id = StringName(data.get("observer_side_id", ""))
	memory.last_observed_turn = maxi(0, int(data.get("last_observed_turn", 0)))
	for creature_id in data.get("seen_opponent_ids", []):
		memory.mark_seen(StringName(creature_id))
	for creature_id in data.get("revealed_moves", {}).keys():
		for move_id in data["revealed_moves"][creature_id]:
			memory.reveal_move(StringName(creature_id), StringName(move_id))
	for creature_id in data.get("revealed_abilities", {}).keys():
		memory.reveal_ability(
			StringName(creature_id),
			StringName(data["revealed_abilities"][creature_id]),
		)
	for creature_id in data.get("revealed_items", {}).keys():
		memory.reveal_item(
			StringName(creature_id),
			StringName(data["revealed_items"][creature_id]),
		)
	for event_data in data.get("event_log", []):
		memory.event_log.append((event_data as Dictionary).duplicate(true))
	return memory


func _mark_current_opponent_seen(state: BattleState) -> void:
	var opponent_side := _opponent_side(state)
	if opponent_side != null:
		mark_seen(opponent_side.active_id)


func _opponent_side(state: BattleState) -> BattleSide:
	for side in state.sides:
		if side.side_id != observer_side_id:
			return side
	return null


func _is_opponent_creature(state: BattleState, creature_id: StringName) -> bool:
	if creature_id == &"":
		return false
	var side := state.side_for_creature(creature_id)
	return side != null and side.side_id != observer_side_id


func _append_unique(source: Dictionary, creature_id: StringName, value: StringName) -> void:
	var values: Array = source.get(creature_id, [])
	if not values.has(value):
		values.append(value)
	source[creature_id] = values


func _serialize_multi_map(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for creature_id in source.keys():
		var values: Array[String] = []
		for value in source[creature_id]:
			values.append(String(value))
		out[String(creature_id)] = values
	return out


func _serialize_single_map(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for creature_id in source.keys():
		out[String(creature_id)] = String(source[creature_id])
	return out


static func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out
