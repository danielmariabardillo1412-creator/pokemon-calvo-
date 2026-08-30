class_name WildBattleCommand
extends RefCounted

# Player-intent envelope at the wild-adventure application boundary. MOVE/SWITCH still use the
# canonical BattleAction type; CAPTURE carries only the stable ball id; RUN carries no trusted
# battle facts. The session derives live actor/target/ownership state from its own authority.

const ACTION := &"action"
const CAPTURE := &"capture"
const RUN := &"run"

var turn: int = 0
var command_type: StringName = ACTION
var side_id: StringName = &""
var action: BattleAction = null
var ball_id: StringName = &""


static func from_action(p_action: BattleAction) -> WildBattleCommand:
	var command := WildBattleCommand.new()
	command.command_type = ACTION
	command.action = p_action
	if p_action != null:
		command.turn = p_action.turn
		command.side_id = p_action.side_id
	return command


static func capture(
	p_turn: int,
	p_side_id: StringName,
	p_ball_id: StringName,
) -> WildBattleCommand:
	var command := WildBattleCommand.new()
	command.turn = p_turn
	command.command_type = CAPTURE
	command.side_id = p_side_id
	command.ball_id = p_ball_id
	return command


static func run(
	p_turn: int,
	p_side_id: StringName,
) -> WildBattleCommand:
	var command := WildBattleCommand.new()
	command.turn = p_turn
	command.command_type = RUN
	command.side_id = p_side_id
	return command


func to_dict() -> Dictionary:
	var out := {
		"turn": turn,
		"command_type": String(command_type),
		"side_id": String(side_id),
	}
	if command_type == ACTION:
		out["action"] = action.to_dict() if action != null else null
	elif command_type == CAPTURE:
		out["ball_id"] = String(ball_id)
	return out


static func from_dict(data: Dictionary) -> WildBattleCommand:
	var command := WildBattleCommand.new()
	command.turn = int(data.get("turn", 0))
	command.command_type = StringName(data.get("command_type", ACTION))
	command.side_id = StringName(data.get("side_id", ""))
	if command.command_type == ACTION:
		var action_data = data.get("action")
		if action_data is Dictionary:
			command.action = BattleAction.from_dict(action_data)
	elif command.command_type == CAPTURE:
		command.ball_id = StringName(data.get("ball_id", ""))
	return command
