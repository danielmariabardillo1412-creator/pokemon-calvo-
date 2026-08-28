class_name TypeDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var effectiveness: Dictionary = {}


func multiplier_against(defender_type_id: StringName) -> float:
	return float(effectiveness.get(String(defender_type_id), 1.0))

