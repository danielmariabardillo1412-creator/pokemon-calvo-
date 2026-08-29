class_name OverworldPlayer
extends CharacterBody2D

# Minimal four-direction overworld mover. Movement is continuous in world pixels, while
# `step_completed` is emitted from ACTUAL distance travelled after collision resolution. This keeps
# encounter cadence independent from frame rate and prevents walking into a wall from generating
# fake encounter steps. If one physics tick crosses several steps, each signal carries the actual
# intermediate world position where that step boundary was crossed.

signal step_completed(world_position: Vector2)
signal facing_changed(direction: Vector2)

@export var move_speed: float = 96.0
@export var step_distance: float = 32.0

var movement_enabled: bool = true
var facing: Vector2 = Vector2.DOWN
var _distance_since_step: float = 0.0


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	apply_motion(input_direction, delta)


# Public deterministic seam used both by runtime input and headless scene tests.
func apply_motion(direction: Vector2, delta: float) -> Vector2:
	if not movement_enabled or delta <= 0.0:
		velocity = Vector2.ZERO
		return Vector2.ZERO
	var cardinal := cardinalize(direction)
	if cardinal == Vector2.ZERO:
		velocity = Vector2.ZERO
		return Vector2.ZERO
	if cardinal != facing:
		facing = cardinal
		facing_changed.emit(facing)

	velocity = cardinal * move_speed
	var before := global_position
	move_and_collide(velocity * delta)
	var moved := global_position - before
	_track_real_movement(before, moved)
	return moved


func reset_step_meter() -> void:
	_distance_since_step = 0.0


static func cardinalize(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	if absf(direction.x) >= absf(direction.y) and not is_zero_approx(direction.x):
		return Vector2(signf(direction.x), 0.0)
	if not is_zero_approx(direction.y):
		return Vector2(0.0, signf(direction.y))
	return Vector2.ZERO


func _track_real_movement(start_position: Vector2, moved: Vector2) -> void:
	var distance := moved.length()
	if distance <= 0.0 or step_distance <= 0.0:
		return
	var direction := moved / distance
	var remaining := distance
	var cursor := start_position

	while _distance_since_step + remaining + 0.0001 >= step_distance:
		var distance_to_boundary := step_distance - _distance_since_step
		# Numeric drift can make this almost zero after a prior exact boundary.
		distance_to_boundary = maxf(0.0, distance_to_boundary)
		cursor += direction * distance_to_boundary
		remaining = maxf(0.0, remaining - distance_to_boundary)
		_distance_since_step = 0.0
		step_completed.emit(cursor)
		if remaining <= 0.0001:
			remaining = 0.0
			break

	_distance_since_step += remaining
