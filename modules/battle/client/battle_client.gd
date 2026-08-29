class_name BattleClient
extends RefCounted


func request_move(
	turn: int,
	actor_id: StringName,
	move_id: StringName,
	target_id: StringName,
	side_id: StringName = &"",
) -> BattleAction:
	# This is intent only. HP, damage, RNG and outcomes are absent by design.
	return BattleAction.new(turn, actor_id, move_id, target_id, BattleAction.MOVE, side_id)


func request_switch(
	turn: int,
	side_id: StringName,
	actor_id: StringName,
	switch_instance_id: StringName,
) -> BattleAction:
	return BattleAction.new(
		turn, actor_id, &"", &"", BattleAction.SWITCH, side_id, switch_instance_id
	)
