class_name StatBlock
extends RefCounted

var max_hp: int
var attack: int
var defense: int
var speed: int
var special_attack: int
var special_defense: int


func _init(
	p_max_hp: int = 1,
	p_attack: int = 1,
	p_defense: int = 1,
	p_speed: int = 1,
	p_special_attack: int = 1,
	p_special_defense: int = 1,
) -> void:
	max_hp = maxi(1, p_max_hp)
	attack = maxi(1, p_attack)
	defense = maxi(1, p_defense)
	speed = maxi(1, p_speed)
	special_attack = maxi(1, p_special_attack)
	special_defense = maxi(1, p_special_defense)


func to_dict() -> Dictionary:
	return {
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"special_attack": special_attack,
		"special_defense": special_defense,
	}


func duplicate() -> StatBlock:
	return StatBlock.new(max_hp, attack, defense, speed, special_attack, special_defense)


static func from_dict(data: Dictionary) -> StatBlock:
	return StatBlock.new(
		int(data.get("max_hp", 1)),
		int(data.get("attack", 1)),
		int(data.get("defense", 1)),
		int(data.get("speed", 1)),
		int(data.get("special_attack", data.get("attack", 1))),
		int(data.get("special_defense", data.get("defense", 1))),
	)
