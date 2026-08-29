class_name OverworldEncounterZone
extends Area2D

# Scene-side encounter surface. V1 deliberately supports RectangleShape2D only; final map tooling
# can later generate these zones from TileMap/custom data without changing the encounter director.

@export var zone_id: StringName = &""


func is_valid_zone() -> bool:
	if zone_id == &"":
		return false
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	return collision != null and not collision.disabled and collision.shape is RectangleShape2D


func contains_world_point(world_point: Vector2) -> bool:
	if not is_valid_zone():
		return false
	var collision := get_node("CollisionShape2D") as CollisionShape2D
	var rect := collision.shape as RectangleShape2D
	var local_point := collision.to_local(world_point)
	var half := rect.size * 0.5
	return Rect2(-half, rect.size).has_point(local_point)
