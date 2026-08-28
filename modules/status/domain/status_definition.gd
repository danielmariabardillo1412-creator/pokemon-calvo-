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

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"end_turn_max_hp_divisor": end_turn_max_hp_divisor,
		"minimum_damage": minimum_damage,
	}

static func from_dict(d: Dictionary) -> StatusDefinition:
	var s := StatusDefinition.new()
	s.id = StringName(d.get("id", ""))
	s.display_name = d.get("display_name", "")
	s.end_turn_max_hp_divisor = int(d.get("end_turn_max_hp_divisor", 0))
	s.minimum_damage = int(d.get("minimum_damage", 1))
	return s

