class_name OverworldPortal
extends Area2D

signal traversal_requested(portal: OverworldPortal, player: OverworldPlayer)

# Reusable walk-in transition seam for doors, caves, stairs and map warps.
# It owns no scene changing, fading or player movement. The traversal controller decides
# how the requested relocation is presented and instrumented.

@export var portal_id: StringName = &""
@export var transition_kind: StringName = &"door"
@export var source_region_id: StringName = &""
@export var destination_region_id: StringName = &""
@export var destination_path: NodePath
@export_range(0, 2000, 1) var fade_out_msec: int = 120
@export_range(0, 2000, 1) var hold_msec: int = 40
@export_range(0, 2000, 1) var fade_in_msec: int = 120


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func destination_node() -> Node2D:
	if destination_path.is_empty():
		return null
	return get_node_or_null(destination_path) as Node2D


func expected_duration_msec() -> int:
	return fade_out_msec + hold_msec + fade_in_msec


func _on_body_entered(body: Node2D) -> void:
	var player := body as OverworldPlayer
	if player == null:
		return
	traversal_requested.emit(self, player)
