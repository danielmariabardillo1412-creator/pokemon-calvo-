class_name OverworldTraversalController
extends Node

signal transition_started(payload: Dictionary)
signal transition_finished(payload: Dictionary)
signal ledge_jump_started(payload: Dictionary)
signal ledge_jump_finished(payload: Dictionary)
signal traversal_blocked(payload: Dictionary)
signal ledge_rejected(payload: Dictionary)

# Presentation/application controller for non-combat overworld traversal.
# Portals and ledges request traversal; this controller temporarily owns player movement,
# performs the relocation, and publishes detached timing/position facts for observers.

var _player: OverworldPlayer = null
var _fade_rect: ColorRect = null
var _busy: bool = false


func configure(player: OverworldPlayer, fade_rect: ColorRect = null) -> void:
	_player = player
	_fade_rect = fade_rect
	if _fade_rect != null:
		_fade_rect.visible = false
		_fade_rect.modulate.a = 0.0


func register_portal(portal: OverworldPortal) -> void:
	if portal == null:
		return
	if not portal.traversal_requested.is_connected(_on_portal_requested):
		portal.traversal_requested.connect(_on_portal_requested)


func register_ledge(ledge: OverworldLedge) -> void:
	if ledge == null:
		return
	if not ledge.jump_requested.is_connected(_on_ledge_requested):
		ledge.jump_requested.connect(_on_ledge_requested)
	if not ledge.jump_rejected.is_connected(_on_ledge_rejected):
		ledge.jump_rejected.connect(_on_ledge_rejected)


func is_busy() -> bool:
	return _busy


# Public deterministic seam used by runtime signals and headless tests alike.
func traverse_portal(portal: OverworldPortal) -> bool:
	if portal == null or _player == null:
		_emit_blocked("portal", "missing_dependency", portal)
		return false
	if _busy:
		_emit_blocked("portal", "traversal_busy", portal)
		return false
	if not _player.movement_enabled:
		_emit_blocked("portal", "movement_locked", portal)
		return false
	var destination := portal.destination_node()
	if destination == null:
		_emit_blocked("portal", "missing_destination", portal)
		return false

	_busy = true
	var start_ticks := Time.get_ticks_msec()
	var start_position := _player.global_position
	var target_position := destination.global_position
	var expected_msec := portal.expected_duration_msec()
	var restore_movement := _player.movement_enabled
	_player.movement_enabled = false
	_player.velocity = Vector2.ZERO
	_player.reset_step_meter()
	transition_started.emit({
		"portal_id": String(portal.portal_id),
		"kind": String(portal.transition_kind),
		"source_region_id": String(portal.source_region_id),
		"destination_region_id": String(portal.destination_region_id),
		"expected_msec": expected_msec,
		"from_position": _vec(start_position),
		"target_position": _vec(target_position),
	})

	await _fade_to(1.0, portal.fade_out_msec)
	_player.global_position = target_position
	_player.velocity = Vector2.ZERO
	_player.reset_step_meter()
	if portal.hold_msec > 0:
		await get_tree().create_timer(float(portal.hold_msec) / 1000.0).timeout
	await _fade_to(0.0, portal.fade_in_msec)
	if _fade_rect != null:
		_fade_rect.visible = false

	var final_position := _player.global_position
	var elapsed := maxi(0, Time.get_ticks_msec() - start_ticks)
	_player.reset_step_meter()
	_player.movement_enabled = restore_movement
	_busy = false
	transition_finished.emit({
		"portal_id": String(portal.portal_id),
		"kind": String(portal.transition_kind),
		"source_region_id": String(portal.source_region_id),
		"destination_region_id": String(portal.destination_region_id),
		"expected_msec": expected_msec,
		"elapsed_msec": elapsed,
		"from_position": _vec(start_position),
		"target_position": _vec(target_position),
		"final_position": _vec(final_position),
		"position_error_px": final_position.distance_to(target_position),
	})
	return true


# Public deterministic seam used by runtime signals and headless tests alike.
func jump_ledge(ledge: OverworldLedge) -> bool:
	if ledge == null or _player == null:
		_emit_blocked("ledge", "missing_dependency", ledge)
		return false
	if _busy:
		_emit_blocked("ledge", "traversal_busy", ledge)
		return false
	if not _player.movement_enabled:
		_emit_blocked("ledge", "movement_locked", ledge)
		return false
	var landing := ledge.landing_node()
	if landing == null:
		_emit_blocked("ledge", "missing_destination", ledge)
		return false

	_busy = true
	var start_ticks := Time.get_ticks_msec()
	var start_position := _player.global_position
	var target_position := landing.global_position
	var restore_movement := _player.movement_enabled
	_player.movement_enabled = false
	_player.velocity = Vector2.ZERO
	_player.reset_step_meter()
	ledge_jump_started.emit({
		"ledge_id": String(ledge.ledge_id),
		"expected_msec": ledge.jump_duration_msec,
		"from_position": _vec(start_position),
		"target_position": _vec(target_position),
		"allowed_direction": _vec(ledge.allowed_direction),
	})

	var duration := float(ledge.jump_duration_msec) / 1000.0
	var half_duration := duration * 0.5
	var midpoint := start_position.lerp(target_position, 0.5)
	midpoint.y -= ledge.visual_arc_height
	if duration > 0.0:
		var tween := create_tween()
		tween.tween_property(_player, "global_position", midpoint, half_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_player, "global_position", target_position, half_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
	else:
		_player.global_position = target_position
	_player.global_position = target_position
	_player.velocity = Vector2.ZERO
	_player.reset_step_meter()

	var final_position := _player.global_position
	var elapsed := maxi(0, Time.get_ticks_msec() - start_ticks)
	_player.movement_enabled = restore_movement
	_busy = false
	ledge_jump_finished.emit({
		"ledge_id": String(ledge.ledge_id),
		"expected_msec": ledge.jump_duration_msec,
		"elapsed_msec": elapsed,
		"from_position": _vec(start_position),
		"target_position": _vec(target_position),
		"final_position": _vec(final_position),
		"distance_px": start_position.distance_to(target_position),
		"position_error_px": final_position.distance_to(target_position),
	})
	return true


func _on_portal_requested(portal: OverworldPortal, player: OverworldPlayer) -> void:
	if player != _player:
		return
	traverse_portal(portal)


func _on_ledge_requested(ledge: OverworldLedge, player: OverworldPlayer) -> void:
	if player != _player:
		return
	jump_ledge(ledge)


func _on_ledge_rejected(ledge: OverworldLedge, player: OverworldPlayer, reason: String) -> void:
	if player != _player:
		return
	ledge_rejected.emit({
		"ledge_id": String(ledge.ledge_id),
		"reason": reason,
		"player_position": _vec(_player.global_position) if _player != null else {},
		"facing": _vec(_player.facing) if _player != null else {},
	})


func _fade_to(alpha: float, duration_msec: int) -> void:
	if _fade_rect == null:
		if duration_msec > 0:
			await get_tree().create_timer(float(duration_msec) / 1000.0).timeout
		return
	_fade_rect.visible = true
	if duration_msec <= 0:
		_fade_rect.modulate.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, float(duration_msec) / 1000.0)
	await tween.finished


func _emit_blocked(kind: String, reason: String, source: Variant) -> void:
	var source_id := ""
	if source is OverworldPortal:
		source_id = String((source as OverworldPortal).portal_id)
	elif source is OverworldLedge:
		source_id = String((source as OverworldLedge).ledge_id)
	traversal_blocked.emit({
		"kind": kind,
		"source_id": source_id,
		"reason": reason,
		"player_position": _vec(_player.global_position) if _player != null else {},
	})


func _vec(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
