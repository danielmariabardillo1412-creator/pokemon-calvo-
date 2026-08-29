class_name StatStages
extends RefCounted

const ATTACK := &"attack"
const DEFENSE := &"defense"
const SPECIAL_ATTACK := &"special_attack"
const SPECIAL_DEFENSE := &"special_defense"
const SPEED := &"speed"
const ACCURACY := &"accuracy"
const EVASION := &"evasion"
const ALL: Array[StringName] = [
	ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE, SPEED, ACCURACY, EVASION,
]

var _values: Dictionary = {}


func _init() -> void:
	for stat_id in ALL:
		_values[stat_id] = 0


func get_stage(stat_id: StringName) -> int:
	return int(_values.get(stat_id, 0))


func change(stat_id: StringName, delta: int) -> int:
	assert(ALL.has(stat_id), "Unsupported battle stat stage")
	var before := get_stage(stat_id)
	_values[stat_id] = clampi(before + delta, BattleRuleset.STAGE_MIN, BattleRuleset.STAGE_MAX)
	return int(_values[stat_id]) - before


func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for stat_id in ALL:
		result[String(stat_id)] = get_stage(stat_id)
	return result


static func from_dict(data: Dictionary) -> StatStages:
	var stages := StatStages.new()
	for stat_id in ALL:
		stages._values[stat_id] = clampi(
			int(data.get(String(stat_id), 0)), BattleRuleset.STAGE_MIN, BattleRuleset.STAGE_MAX
		)
	return stages
