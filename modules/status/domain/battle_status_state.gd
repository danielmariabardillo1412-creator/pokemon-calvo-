class_name BattleStatusState
extends RefCounted

var persistent_id: StringName = &""
var turns_remaining: int = 0
var toxic_counter: int = 0
var volatile: Dictionary = {}


func clear_persistent() -> StringName:
	var removed := persistent_id
	persistent_id = &""
	turns_remaining = 0
	toxic_counter = 0
	return removed


func has_volatile(status_id: StringName) -> bool:
	return volatile.has(status_id)


func add_volatile(status_id: StringName, data: Dictionary = {}) -> void:
	volatile[status_id] = data.duplicate(true)


func remove_volatile(status_id: StringName) -> void:
	volatile.erase(status_id)


func to_dict() -> Dictionary:
	var serialized_volatile: Dictionary = {}
	var keys := volatile.keys()
	keys.sort()
	for status_id in keys:
		serialized_volatile[String(status_id)] = (volatile[status_id] as Dictionary).duplicate(true)
	return {
		"persistent_id": String(persistent_id),
		"turns_remaining": turns_remaining,
		"toxic_counter": toxic_counter,
		"volatile": serialized_volatile,
	}


static func from_dict(data: Dictionary) -> BattleStatusState:
	var state := BattleStatusState.new()
	state.persistent_id = StringName(data.get("persistent_id", ""))
	state.turns_remaining = maxi(0, int(data.get("turns_remaining", 0)))
	state.toxic_counter = maxi(0, int(data.get("toxic_counter", 0)))
	for status_id in data.get("volatile", {}).keys():
		state.volatile[StringName(status_id)] = data["volatile"][status_id].duplicate(true)
	return state
