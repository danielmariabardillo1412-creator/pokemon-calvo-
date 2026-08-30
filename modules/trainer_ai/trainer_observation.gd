class_name TrainerObservation
extends RefCounted

const SCHEMA_VERSION := 1

var battle_id: StringName = &""
var turn: int = 0
var phase: StringName = &""
var observer_side_id: StringName = &""
var opponent_side_id: StringName = &""
var own_active_id: StringName = &""
var opponent_active_id: StringName = &""
var own_party: Array[Dictionary] = []
var observed_opponents: Array[Dictionary] = []


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"battle_id": String(battle_id),
		"turn": turn,
		"phase": String(phase),
		"observer_side_id": String(observer_side_id),
		"opponent_side_id": String(opponent_side_id),
		"own_active_id": String(own_active_id),
		"opponent_active_id": String(opponent_active_id),
		"own_party": own_party.duplicate(true),
		"observed_opponents": observed_opponents.duplicate(true),
	}
