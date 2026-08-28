class_name BattleAction
extends RefCounted

var turn: int
var actor_id: StringName
var move_id: StringName
var target_id: StringName


func _init(
	p_turn: int = 0,
	p_actor_id: StringName = &"",
	p_move_id: StringName = &"",
	p_target_id: StringName = &"",
) -> void:
	turn = p_turn
	actor_id = p_actor_id
	move_id = p_move_id
	target_id = p_target_id


func to_dict() -> Dictionary:
	return {
		"turn": turn,
		"actor_id": String(actor_id),
		"move_id": String(move_id),
		"target_id": String(target_id),
	}


static func from_dict(data: Dictionary) -> BattleAction:
	return BattleAction.new(
		int(data.get("turn", 0)),
		StringName(data.get("actor_id", "")),
		StringName(data.get("move_id", "")),
		StringName(data.get("target_id", "")),
	)

