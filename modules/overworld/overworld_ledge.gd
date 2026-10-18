class_name OverworldLedge
extends Area2D

signal jump_requested(ledge: OverworldLedge, player: OverworldPlayer)
signal jump_rejected(ledge: OverworldLedge, player: OverworldPlayer, reason: String)

# One-way ledge trigger. A separate collision barrier can block travel in the reverse direction;
# this area only authorizes a jump on movement intent in allowed_direction.

@export var ledge_id: StringName = &""
@export var allowed_direction: Vector2 = Vector2.DOWN
@export var landing_path: NodePath
@export_range(1, 2000, 1) var jump_duration_msec: int = 180
@export_range(0.0, 64.0, 0.5) var visual_arc_height: float = 10.0

var _last_rejected_direction: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func landing_node() -> Node2D:
	if landing_path.is_empty():
		return null
	return get_node_or_null(landing_path) as Node2D


func direction_matches(facing: Vector2) -> bool:
	if allowed_direction == Vector2.ZERO or facing == Vector2.ZERO:
		return false
	return facing.normalized().dot(allowed_direction.normalized()) >= 0.9


func _on_body_entered(body: Node2D) -> void:
	var player := body as OverworldPlayer
	if player == null:
		return
	var callback := _on_motion_requested.bind(player)
	if not player.motion_requested.is_connected(callback):
		player.motion_requested.connect(callback)
	# An approach that crosses the boundary has a velocity; a stationary spawn
	# inside the area must wait for actual input instead of hopping on its own.
	if player.movement_enabled and player.velocity.length_squared() > 0.0:
		_request_jump(player.velocity.normalized(), player)


func _on_body_exited(body: Node2D) -> void:
	var player := body as OverworldPlayer
	if player == null:
		return
	_last_rejected_direction.erase(player.get_instance_id())
	var callback := _on_motion_requested.bind(player)
	if player.motion_requested.is_connected(callback):
		player.motion_requested.disconnect(callback)


func _on_motion_requested(direction: Vector2, player: OverworldPlayer) -> void:
	if overlaps_body(player):
		_request_jump(direction, player)


func _request_jump(direction: Vector2, player: OverworldPlayer) -> void:
	if not player.movement_enabled:
		return
	if not direction_matches(direction):
		var id := player.get_instance_id()
		if _last_rejected_direction.get(id, Vector2.ZERO) != direction:
			_last_rejected_direction[id] = direction
			jump_rejected.emit(self, player, "wrong_direction")
		return
	_last_rejected_direction.erase(player.get_instance_id())
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or not (collision.shape is RectangleShape2D):
		return
	var rectangle := collision.shape as RectangleShape2D
	var body_collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_collision == null or body_collision.shape == null:
		return
	# Area2D overlap notifications can lag behind a teleport for a physics tick.
	# Check current geometry as well so held input cannot jump again after landing.
	var relative := collision.global_transform.affine_inverse() * body_collision.global_transform
	var body_rect: Rect2 = relative * body_collision.shape.get_rect()
	if not Rect2(-rectangle.size * 0.5, rectangle.size).intersects(body_rect):
		return
	var local := collision.to_local(player.global_position)
	var horizontal_jump := absf(allowed_direction.x) > absf(allowed_direction.y)
	# A body overlapping from the side is not standing in front of the ledge.
	if absf(local.y if horizontal_jump else local.x) > (rectangle.size.y if horizontal_jump else rectangle.size.x) * 0.5:
		return
	jump_requested.emit(self, player)


func landing_position(player_position: Vector2) -> Vector2:
	var landing := landing_node()
	if landing == null:
		return player_position
	var direction := allowed_direction.normalized()
	var tangent := Vector2(-direction.y, direction.x)
	return landing.global_position + tangent * (player_position - global_position).dot(tangent)
