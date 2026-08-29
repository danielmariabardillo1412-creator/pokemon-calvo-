class_name BattleMoveSlot
extends RefCounted

var move_id: StringName
var current_pp: int
var max_pp: int


func _init(p_move_id: StringName = &"", p_max_pp: int = -1, p_current_pp: int = -1) -> void:
	move_id = p_move_id
	max_pp = p_max_pp
	current_pp = p_current_pp


func initialize(definition: MoveDefinition) -> void:
	if max_pp < 0:
		max_pp = maxi(1, definition.pp)
	if current_pp < 0:
		current_pp = max_pp
	current_pp = clampi(current_pp, 0, max_pp)


func consume() -> bool:
	if current_pp <= 0:
		return false
	current_pp -= 1
	return true


func to_dict() -> Dictionary:
	return {"move_id": String(move_id), "current_pp": current_pp, "max_pp": max_pp}


static func from_dict(data: Dictionary) -> BattleMoveSlot:
	return BattleMoveSlot.new(
		StringName(data.get("move_id", "")),
		int(data.get("max_pp", -1)),
		int(data.get("current_pp", -1)),
	)
