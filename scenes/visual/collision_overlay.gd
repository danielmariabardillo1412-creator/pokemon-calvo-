extends Node2D

# Draw the actual collision resources; never create duplicate physics geometry.
func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	_draw_colliders(get_parent())


func _draw_colliders(node: Node) -> void:
	if node is CollisionShape2D:
		var collider := node as CollisionShape2D
		if collider.shape != null and not collider.disabled:
			var tint := Color(1.0, 0.3, 0.25, 0.28)
			if collider.get_parent() is OverworldEncounterZone:
				tint = Color(0.3, 1.0, 0.5, 0.3)
			elif collider.get_parent() is OverworldLedge:
				tint = Color(1.0, 0.75, 0.1, 0.4)
			elif collider.get_parent() is OverworldPortal:
				tint = Color(0.3, 0.7, 1.0, 0.4)
			elif collider.get_parent() is Area2D:
				tint = Color(1.0, 0.4, 0.8, 0.35)
			elif collider.get_parent() is OverworldPlayer:
				tint = Color(1, 1, 1, 0.6)
			draw_set_transform_matrix(global_transform.affine_inverse() * collider.global_transform)
			collider.shape.draw(get_canvas_item(), tint)
			draw_rect(collider.shape.get_rect(), Color(tint, 0.9), false, 1.0)
	for child in node.get_children():
		_draw_colliders(child)
