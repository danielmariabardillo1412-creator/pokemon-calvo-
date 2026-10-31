extends Control

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Layout = preload("res://scenes/visual/battle_sprite_layout.gd")
const MoveVisuals = preload("res://scenes/visual/battle_move_visuals.gd")
var player_species: StringName = &"":
	set(value):
		if value != player_species:
			player_species = value
			_player_time = 0.0
			queue_redraw()
var enemy_species: StringName = &"":
	set(value):
		if value != enemy_species:
			enemy_species = value
			_enemy_time = 0.0
			queue_redraw()
var preview_state := "reposo"
var player_preview_state := ""
var enemy_preview_state := ""
var _player_time := 0.0
var _enemy_time := 0.0
var _effect_side := ""
var _effect_kind := ""
var _effect_progress := 0.0
var _player_visible := true
var _enemy_visible := true
var _capture_phase := ""
var _capture_ball := ""
var _capture_progress := 0.0
var _move_visual: Dictionary = {}
var _move_progress := 0.0
var _substitute_views: Dictionary = {}
var _doll_texture: Texture2D
var _doll_checked := false
var _visual_centers: Dictionary = {}
var _visual_radii: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Battle renders use fractional reference scales. Smooth their existing pixels
	# without changing the source art, layout, or the pixel-art overworld/UI.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	clip_contents = true


func restart_animation(state: String = "reposo") -> void:
	preview_state = state
	_player_time = 0.0
	_enemy_time = 0.0
	queue_redraw()


func set_runtime_pose(side: String, state: String, restart: bool = false) -> void:
	if side == "back":
		if restart or player_preview_state != state:
			_player_time = 0.0
		player_preview_state = state
	elif side == "front":
		if restart or enemy_preview_state != state:
			_enemy_time = 0.0
		enemy_preview_state = state
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_player_time += delta
	_enemy_time += delta
	queue_redraw()


func set_runtime_effect(side: String, kind: String, progress: float) -> void:
	_effect_side = side
	_effect_kind = kind
	_effect_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func set_runtime_substitutes(views: Dictionary) -> void:
	_substitute_views = views.duplicate(true)
	if not _doll_checked:
		_doll_checked = true
		var path := "res://.godot/battle_substitute/doll.png"
		if FileAccess.file_exists(path) and FileAccess.get_sha256(path) == "e4cb8b5708589c81ce97fb5c9be30dbf60477f5437c0c17554abbded3a8ed093":
			var image := Image.load_from_file(path)
			if image != null: _doll_texture = ImageTexture.create_from_image(image)
	queue_redraw()


func set_runtime_visibility(player_visible: bool, enemy_visible: bool) -> void:
	_player_visible = player_visible
	_enemy_visible = enemy_visible
	queue_redraw()


func set_capture_visual(phase: String, ball_id: String, progress: float) -> void:
	_capture_phase = phase
	_capture_ball = ball_id
	_capture_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func set_move_visual(visual: Dictionary, progress: float) -> void:
	_move_visual = visual.duplicate(true)
	_move_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("aec38e"))
	draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.45), Color("c7d4a3"))
	var left := Vector2(size.x * 0.25, size.y * 0.88)
	var right := Vector2(size.x * 0.75, size.y * 0.56)
	_platform(left, Vector2(64, 12))
	_platform(right, Vector2(55, 10))
	_visual_centers.clear()
	_visual_radii.clear()
	_creature(player_species, left, "back", _player_time)
	_creature(enemy_species, right, "front", _enemy_time)
	if not _move_visual.is_empty() and _visual_centers.has(String(_move_visual.source_side)) and _visual_centers.has(String(_move_visual.target_side)):
		MoveVisuals.draw(self, _move_visual, _visual_centers[String(_move_visual.source_side)], _visual_centers[String(_move_visual.target_side)],
			_move_progress, clampf(minf(size.x / 640.0, size.y / 360.0), 0.5, 1.8), float(_visual_radii.get(String(_move_visual.target_side), 0.0)))
	_draw_capture_ball()


func _platform(p: Vector2, radius: Vector2) -> void:
	draw_set_transform(p, 0.0, Vector2(1, radius.y / radius.x))
	draw_circle(Vector2.ZERO, radius.x, Color("8eac73"))
	draw_arc(Vector2.ZERO, radius.x - 3, 0, TAU, 32, Color("d9dfb0"), 2)
	draw_set_transform(Vector2.ZERO)


func _creature(species: StringName, ground: Vector2, side: String, elapsed: float) -> void:
	if species == &"" or not (_player_visible if side == "back" else _enemy_visible):
		return
	var override_state := player_preview_state if side == "back" else enemy_preview_state
	var clip: Dictionary = Catalog.animation(species, side, preview_state if override_state.is_empty() else override_state)
	if clip.is_empty():
		# Never substitute a missing back with a front or another species.
		draw_circle(ground + Vector2(0, -27), 22, Color("5e8170"))
		draw_string(ThemeDB.fallback_font, ground + Vector2(-4, -22), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f4e9bd"))
		draw_string(ThemeDB.fallback_font, ground + Vector2(-68, 15), "Recurso pendiente · " + side, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("324d3e"))
		return
	var index := Catalog.frame_index(clip, elapsed)
	var region: Array = clip.regions[index]
	var source := Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	# Envelope covers every state/frame; scaling never pumps as the animation moves.
	var envelope := Catalog.presentation_bounds(species, side, clip)
	var placement := Layout.placement(size, side, envelope)
	_visual_centers[side] = Vector2(placement.anchor) + envelope.get_center() * float(placement.gain)
	_visual_radii[side] = envelope.size.length() * float(placement.gain) * 0.5
	var gain := float(placement.gain) * float(clip.unit_scale)
	if _substitute_views.get(side, {}).get("dynamax", false): gain *= 1.35
	var destination := Rect2(Vector2(placement.anchor) - Vector2(clip.pivot) * gain, source.size * gain)
	var texture: Texture2D = clip.texture
	var effect_anchor := Vector2(placement.anchor)
	if not _substitute_views.get(side, {}).get("substitute", {}).is_empty() and _doll_texture != null:
		# Original front/back tiles; opaque doll feet share the creature's ground.
		var bounds := Rect2(66, 61, 62, 62) if side == "back" else Rect2(64, 58, 60, 64)
		var doll_gain := minf(size.x / 512.0, size.y / 384.0)
		effect_anchor += Vector2(0, envelope.end.y * float(placement.gain))
		source = Rect2(bounds.position + Vector2(192 if side == "back" else 0, 0), bounds.size)
		destination = Rect2(effect_anchor - Vector2(bounds.size.x * 0.5, bounds.size.y) * doll_gain, bounds.size * doll_gain)
		texture = _doll_texture
		_visual_centers[side] = destination.get_center()
		_visual_radii[side] = destination.size.length() * 0.5
	var tint := Color.WHITE
	if side == _effect_side and not _effect_kind.is_empty():
		var pulse := sin(_effect_progress * PI)
		if _effect_kind == "action":
			var direction := Vector2(1, -0.35) if side == "back" else Vector2(-1, 0.35)
			destination.position += direction * minf(6.0, size.x * 0.009) * pulse
		elif _effect_kind == "transform":
			var fraction := maxf(0.04, absf(_effect_progress * 2.0 - 1.0))
			destination.position.x = effect_anchor.x + (destination.position.x - effect_anchor.x) * fraction
			destination.size.x *= fraction
			tint.a = maxf(0.15, fraction)
		elif _effect_kind == "impact":
			if override_state != "dano":
				destination.position.x += sin(_effect_progress * TAU * 3.0) * minf(4.0, size.x * 0.006) * pulse
			tint = Color(1.0 + 0.2 * pulse, 1.0 - 0.25 * pulse, 1.0 - 0.25 * pulse, 1.0)
		elif _effect_kind in ["withdraw", "send_out", "capture_absorb", "capture_breakout"]:
			var fraction := smoothstep(0.0, 1.0, _effect_progress)
			if _effect_kind in ["withdraw", "capture_absorb"]:
				fraction = 1.0 - fraction
			destination.position = effect_anchor + (destination.position - effect_anchor) * maxf(0.001, fraction)
			destination.size *= maxf(0.001, fraction)
			tint.a = fraction
		elif _effect_kind in ["faint", "flee"]:
			var fraction := smoothstep(0.0, 1.0, _effect_progress)
			destination.position += Vector2(0, minf(14.0, size.y * 0.04) * fraction) if _effect_kind == "faint" else Vector2(-size.x * 0.08 * fraction, 0)
			tint.a = 1.0 - fraction
	draw_texture_rect_region(texture, destination, source, tint)
	if side == _effect_side and not _effect_kind.is_empty():
		var center: Vector2 = _visual_centers[side]
		_effect_marks(center, sin(_effect_progress * PI))


func _effect_marks(center: Vector2, pulse: float) -> void:
	if _effect_kind not in ["impact", "heal"] or pulse <= 0.0:
		return
	var color := Color(0.5, 1.0, 0.6, pulse * 0.8) if _effect_kind == "heal" else Color(1.0, 0.95, 0.65, pulse * 0.8)
	var radius := minf(size.x * 0.025, 15.0) * (0.5 + _effect_progress)
	for index in 8:
		var direction := Vector2.from_angle(index * TAU / 8.0)
		draw_line(center + direction * radius * 0.45, center + direction * radius, color, 2.0, true)


func _draw_capture_ball() -> void:
	if _capture_phase.is_empty() or (_capture_phase == "breakout" and _capture_progress >= 1.0):
		return
	var target := Vector2(size.x * 0.75, size.y * 0.56)
	var center := target
	var angle := 0.0
	if _capture_phase == "throw":
		center = Vector2(size.x * 0.25, size.y * 0.78).lerp(target, _capture_progress)
		center.y -= sin(_capture_progress * PI) * size.y * 0.28
		angle = _capture_progress * TAU
	elif _capture_phase == "settle":
		center.y -= sin(_capture_progress * PI) * 5.0
	elif _capture_phase == "shake":
		angle = sin(_capture_progress * TAU) * 0.25
		center.x += sin(_capture_progress * TAU) * 3.0
	var radius := clampf(size.y * 0.025, 4.0, 10.0)
	var color: Color = {"great_ball": Color("3489df"), "ultra_ball": Color("e6c64d"), "master_ball": Color("a367ce")}.get(_capture_ball, Color("e85b58"))
	draw_set_transform(center, angle, Vector2.ONE)
	draw_circle(Vector2.ZERO, radius, Color("f5f3e5"))
	var cap := PackedVector2Array([Vector2.ZERO])
	for index in 17:
		cap.append(Vector2.from_angle(PI + index * PI / 16.0) * radius)
	draw_colored_polygon(cap, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color("263b38"), 1.4, true)
	draw_line(Vector2(-radius, 0), Vector2(radius, 0), Color("263b38"), 1.4, true)
	draw_circle(Vector2.ZERO, radius * 0.24, Color("263b38"))
	draw_circle(Vector2.ZERO, radius * 0.12, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	if _capture_phase == "caught":
		var pulse := sin(_capture_progress * PI)
		for index in 3:
			var point := center + Vector2((index - 1) * radius * 1.8, -radius * (1.7 + pulse))
			draw_line(point - Vector2(3, 0), point + Vector2(3, 0), Color(1, 0.88, 0.3, pulse), 2, true)
			draw_line(point - Vector2(0, 3), point + Vector2(0, 3), Color(1, 0.88, 0.3, pulse), 2, true)
