class_name CaptureAttempt
extends RefCounted

# Server-side input to a capture resolution. `target` is the live wild CreatureInstance
# (server-resolved by id, never trusted from the client). `context` carries the battle facts.

var target: CreatureInstance
var ball_id: StringName = &""
var context: CaptureBattleContext


func _init(p_target: CreatureInstance = null, p_ball_id: StringName = &"", p_context: CaptureBattleContext = null) -> void:
	target = p_target
	ball_id = p_ball_id
	context = p_context
