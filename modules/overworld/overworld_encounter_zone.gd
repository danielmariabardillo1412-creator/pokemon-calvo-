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


func distance_within_segment(from: Vector2, to: Vector2) -> float:
	if not is_valid_zone():
		return 0.0
	var collision := get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := collision.shape as RectangleShape2D
	var start := collision.to_local(from)
	var direction := collision.to_local(to) - start
	var half := rectangle.size * 0.5
	var enter := 0.0
	var leave := 1.0
	for axis in 2:
		if is_zero_approx(direction[axis]):
			# Match contains_world_point's half-open right/bottom boundaries.
			if start[axis] < -half[axis] or start[axis] >= half[axis]:
				return 0.0
			continue
		var first := (-half[axis] - start[axis]) / direction[axis]
		var last := (half[axis] - start[axis]) / direction[axis]
		enter = maxf(enter, minf(first, last))
		leave = minf(leave, maxf(first, last))
		if leave <= enter:
			return 0.0
	return from.distance_to(to) * maxf(0.0, leave - enter)
