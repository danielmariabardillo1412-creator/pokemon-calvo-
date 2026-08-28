class_name CreatureSpecies
extends Resource

@export var id: StringName
@export var display_name: String
@export var primary_type_id: StringName = &"normal"
@export var base_hp: int = 1
@export var base_attack: int = 1
@export var base_defense: int = 1
@export var base_speed: int = 1


func stats_for_level(level: int) -> StatBlock:
	var safe_level := maxi(1, level)
	return StatBlock.new(
		base_hp + safe_level * 2,
		base_attack + safe_level,
		base_defense + safe_level,
		base_speed + safe_level,
	)

