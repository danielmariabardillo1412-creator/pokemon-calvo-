extends Node2D

@export var trainer: bool = false
var _phase := 0.0


func _process(delta: float) -> void:
	if not trainer and get_parent() is OverworldPlayer:
		var actor := get_parent() as OverworldPlayer
		if actor.movement_enabled and actor.velocity.length_squared() > 0.0:
			_phase += delta * 13.0
		else:
			_phase = 0.0
	queue_redraw()


func _draw() -> void:
	var skin := Color("e9b779")
	var coat := Color("dc8461") if trainer else Color("3e7775")
	var dark := Color("293f3b")
	var facing := Vector2.DOWN
	if get_parent() is OverworldPlayer:
		facing = (get_parent() as OverworldPlayer).facing
	var bob := -absf(sin(_phase)) * 1.2
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2(0, 16), 12, Color(0.08, 0.18, 0.14, 0.24))
	draw_set_transform(Vector2(0, bob))
	var stride := sin(_phase) * 2.0
	draw_rect(Rect2(-7, 4 + stride, 6, 8), dark)
	draw_rect(Rect2(1, 4 - stride, 6, 8), dark)
	draw_rect(Rect2(-9, -10, 18, 16), dark)
	draw_rect(Rect2(-8, -9, 16, 14), coat)
	draw_rect(Rect2(-10, -6, 3, 9), skin)
	draw_rect(Rect2(7, -6, 3, 9), skin)
	draw_rect(Rect2(-6, -22, 12, 14), dark)
	draw_rect(Rect2(-8, -20, 16, 10), dark)
	draw_rect(Rect2(-6, -21, 12, 13), skin)
	draw_rect(Rect2(-7, -19, 14, 9), skin)
	draw_rect(Rect2(-4, -21, 7, 2), Color("f6d3a0"))
	if trainer:
		draw_rect(Rect2(-8, -22, 16, 5), Color("414f69"))
		draw_rect(Rect2(-7, -17, 18, 2), Color("354257"))
	if facing != Vector2.UP:
		var eye_offset := facing.x * 2.0
		draw_rect(Rect2(-4 + eye_offset, -15, 2, 2), dark)
		draw_rect(Rect2(2 + eye_offset, -15, 2, 2), dark)
		draw_rect(Rect2(-1 + eye_offset, -10, 3, 1), Color("ad7656"))
	else:
		draw_rect(Rect2(-5, -5, 10, 9), Color("bc9660"))
		draw_rect(Rect2(-3, -4, 6, 2), Color("d4b57a"))
	draw_set_transform(Vector2.ZERO)
