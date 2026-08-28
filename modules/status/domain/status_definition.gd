class_name StatusDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var end_turn_max_hp_divisor: int = 0
@export var minimum_damage: int = 1


func end_turn_damage(max_hp: int) -> int:
	if end_turn_max_hp_divisor <= 0:
		return 0
	return maxi(minimum_damage, max_hp / end_turn_max_hp_divisor)

