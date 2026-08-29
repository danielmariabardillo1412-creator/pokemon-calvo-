class_name CaptureAttempt
extends RefCounted

# Input to a capture resolution. `target` is the live wild CreatureInstance and `context` carries
# the battle facts. CaptureSystem is pure logic and does not authenticate these: when networking
# exists, a higher layer must ensure `target` + `context` are resolved from trusted state.

var target: CreatureInstance
var ball_id: StringName = &""
var context: CaptureBattleContext


func _init(p_target: CreatureInstance = null, p_ball_id: StringName = &"", p_context: CaptureBattleContext = null) -> void:
	target = p_target
	ball_id = p_ball_id
	context = p_context
