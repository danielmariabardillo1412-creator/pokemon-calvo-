class_name StatBlock
extends RefCounted

var max_hp: int
var attack: int
var defense: int
var speed: int


func _init(p_max_hp: int = 1, p_attack: int = 1, p_defense: int = 1, p_speed: int = 1) -> void:
	max_hp = maxi(1, p_max_hp)
	attack = maxi(1, p_attack)
	defense = maxi(1, p_defense)
	speed = maxi(1, p_speed)


func to_dict() -> Dictionary:
	return {
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
	}


static func from_dict(data: Dictionary) -> StatBlock:
	return StatBlock.new(
		int(data.get("max_hp", 1)),
		int(data.get("attack", 1)),
		int(data.get("defense", 1)),
		int(data.get("speed", 1)),
	)

