class_name BattleAction
extends RefCounted

const MOVE := &"move"
const SWITCH := &"switch"
const ITEM := &"item"

var turn: int
var action_type: StringName
var side_id: StringName
var actor_id: StringName
var move_id: StringName
var target_id: StringName
var switch_instance_id: StringName
var item_id: StringName


func _init(
	p_turn: int = 0,
	p_actor_id: StringName = &"",
	p_move_id: StringName = &"",
	p_target_id: StringName = &"",
	p_action_type: StringName = MOVE,
	p_side_id: StringName = &"",
	p_switch_instance_id: StringName = &"",
	p_item_id: StringName = &"",
) -> void:
	turn = p_turn
	action_type = p_action_type
	side_id = p_side_id
	actor_id = p_actor_id
	move_id = p_move_id
	target_id = p_target_id
	switch_instance_id = p_switch_instance_id
	item_id = p_item_id


func to_dict() -> Dictionary:
	var result := {
		"turn": turn,
		"actor_id": String(actor_id),
		"move_id": String(move_id),
		"target_id": String(target_id),
	}
	if action_type != MOVE:
		result["action_type"] = String(action_type)
	if action_type == SWITCH:
		result["switch_instance_id"] = String(switch_instance_id)
	if action_type == ITEM:
		result["item_id"] = String(item_id)
	if side_id != &"":
		result["side_id"] = String(side_id)
	return result


static func from_dict(data: Dictionary) -> BattleAction:
	return BattleAction.new(
		int(data.get("turn", 0)),
		StringName(data.get("actor_id", "")),
		StringName(data.get("move_id", "")),
		StringName(data.get("target_id", "")),
		StringName(data.get("action_type", MOVE)),
		StringName(data.get("side_id", "")),
		StringName(data.get("switch_instance_id", "")),
		StringName(data.get("item_id", "")),
	)
