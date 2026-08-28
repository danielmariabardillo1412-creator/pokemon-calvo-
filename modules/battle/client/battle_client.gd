class_name BattleClient
extends RefCounted


func request_move(
	turn: int,
	actor_id: StringName,
	move_id: StringName,
	target_id: StringName,
) -> BattleAction:
	# This is intent only. HP, damage, RNG and outcomes are absent by design.
	return BattleAction.new(turn, actor_id, move_id, target_id)

