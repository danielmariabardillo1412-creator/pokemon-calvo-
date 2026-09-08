class_name OverworldLedge
extends Area2D

signal jump_requested(ledge: OverworldLedge, player: OverworldPlayer)
signal jump_rejected(ledge: OverworldLedge, player: OverworldPlayer, reason: String)

# One-way ledge trigger. A separate collision barrier can block travel in the reverse direction;
# this area only authorizes the jump when the player's facing matches allowed_direction.

@export var ledge_id: StringName = &""
@export var allowed_direction: Vector2 = Vector2.DOWN
@export var landing_path: NodePath
@export_range(1, 2000, 1) var jump_duration_msec: int = 180
@export_range(0.0, 64.0, 0.5) var visual_arc_height: float = 10.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


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
	if not direction_matches(player.facing):
		jump_rejected.emit(self, player, "wrong_direction")
		return
	jump_requested.emit(self, player)
