class_name TrainerPlausibleWorld
extends RefCounted

var world_id: StringName = &""
var state: BattleState = null
var weight_basis_points: int = 0
var assumptions: Array[String] = []
var metadata: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"world_id": String(world_id),
		"weight_basis_points": weight_basis_points,
		"assumptions": assumptions.duplicate(),
		"metadata": metadata.duplicate(true),
	}
