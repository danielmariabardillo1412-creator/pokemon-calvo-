extends Node2D

# Authored vector scenery. Decorative blades stay inside the real encounter bounds.
# Visual animation uses no gameplay RNG and creates no collision/encounter zones.
var _time := 0.0
var actor: OverworldPlayer


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if actor != null and actor.global_position.y >= 420:
		_cave()
	elif actor != null and actor.global_position.x >= 680:
		_building()
	else:
		_surface()


func _surface() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("82aa70"))
	for y in range(24, 336, 8):
		for x in range(24, 616, 8):
			var n := posmod(x * 17 + y * 31, 37)
			if n < 5:
				draw_line(Vector2(x, y), Vector2(x + 2, y - 2), Color("749c63"))
	draw_rect(Rect2(24, 156, 592, 48), Color("c2b485"))
	draw_rect(Rect2(48, 156, 48, 180), Color("c2b485"))
	draw_rect(Rect2(320, 156, 48, 156), Color("c2b485"))
	draw_rect(Rect2(344, 264, 240, 48), Color("c2b485"))
	for x in range(30, 610, 15):
		draw_rect(Rect2(x, 159, 6, 2), Color("d6c89a"))
		draw_rect(Rect2(x + 4, 199, 5, 2), Color("a99c70"))
	# Exact collider footprint of the original central obstacle.
	draw_rect(Rect2(256, 116, 32, 128), Color("6d6851"))
	for y in range(116, 240, 14):
		draw_rect(Rect2(258, y + 2, 28, 11), Color("9d9875"))
		draw_line(Vector2(260, y + 3), Vector2(282, y + 3), Color("c3be96"))
	# Grass is exactly x=384..576, y=100..260, matching EncounterZone.
	draw_rect(Rect2(384, 100, 192, 160), Color("507e4a"))
	for y in range(108, 260, 9):
		for x in range(390, 576, 9):
			var bend := sin(_time * 1.8 + x * 0.1 + y * 0.07) * 1.2
			var moving_nearby := actor != null and actor.global_position.distance_to(Vector2(x, y)) < 19.0
			if moving_nearby:
				bend += sin(_time * 12.0) * 2.0
			draw_line(Vector2(x, y + 3), Vector2(x - 3 + bend, y - 3), Color("83ae64"), 2)
			draw_line(Vector2(x, y + 3), Vector2(x + 3 + bend, y - 5), Color("a4c879"), 2)
	for x in range(16, 640, 31):
		_tree(Vector2(x, 30))
		_tree(Vector2(x, 364))
	for y in range(70, 335, 42):
		_tree(Vector2(7, y))
		_tree(Vector2(636, y))
	# The bottom row is a cliff: buildings are represented by reachable doorways.
	_house(Vector2(72, 314))
	_entrance(Vector2(560, 314))
	draw_rect(Rect2(152, 272, 96, 12), Color("705f48"))
	draw_rect(Rect2(152, 270, 96, 4), Color("b5bc7a"))
	for x in range(156, 248, 12):
		draw_line(Vector2(x, 279), Vector2(x + 5, 279), Color("a68a62"), 2)
	var config: Dictionary = get_parent()._active_config
	_sign(Vector2(350, 112), "HIERBA", "Nv. %d–%d" % [int(config.get("wild_min_level", 4)), int(config.get("wild_max_level", 6))])
	_sign(Vector2(203, 81), "RIVAL", "Combate")
	for p in [Vector2(312, 90), Vector2(303, 285), Vector2(124, 224)]:
		_flower(p)


func _tree(p: Vector2) -> void:
	draw_circle(p + Vector2(1, 3), 17, Color(0.12, 0.23, 0.15, 0.18))
	draw_rect(Rect2(p + Vector2(-4, -10), Vector2(8, 14)), Color("765b3c"))
	draw_circle(p + Vector2(-7, -18), 13, Color("325d43"))
	draw_circle(p + Vector2(7, -19), 13, Color("386a47"))
	draw_circle(p + Vector2(0, -29), 14, Color("4b7d4d"))
	draw_arc(p + Vector2(-1, -29), 10, PI, TAU - 0.3, 12, Color("6e985a"), 2)


func _house(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-30, -13), Vector2(60, 23)), Color("e4d7a5"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-34, -14), p + Vector2(0, -40), p + Vector2(34, -14)]), Color("ab6650"))
	draw_line(p + Vector2(-34, -14), p + Vector2(34, -14), Color("784f40"), 3)
	draw_rect(Rect2(p + Vector2(-10, -9), Vector2(20, 22)), Color("4e5140"))
	draw_rect(Rect2(p + Vector2(-25, -7), Vector2(10, 8)), Color("79a7a2"))
	draw_rect(Rect2(p + Vector2(15, -7), Vector2(10, 8)), Color("79a7a2"))
	draw_rect(Rect2(p + Vector2(-20, 13), Vector2(40, 6)), Color("d8c58f"))


func _entrance(p: Vector2) -> void:
	draw_circle(p + Vector2(0, -7), 30, Color("737763"))
	draw_circle(p + Vector2(-12, -12), 17, Color("969781"))
	draw_circle(p + Vector2(15, -9), 18, Color("858b73"))
	draw_rect(Rect2(p + Vector2(-19, -9), Vector2(38, 28)), Color("313d38"))
	draw_arc(p + Vector2(0, -8), 19, PI, TAU, 15, Color("b0ad8b"), 4)
	draw_rect(Rect2(p + Vector2(-16, 12), Vector2(32, 5)), Color("aa9e7a"))


func _sign(p: Vector2, title: String, subtitle: String) -> void:
	draw_rect(Rect2(p + Vector2(-2, 2), Vector2(4, 18)), Color("7b6545"))
	draw_rect(Rect2(p + Vector2(-28, -14), Vector2(56, 25)), Color("e1d1a0"))
	draw_rect(Rect2(p + Vector2(-27, -13), Vector2(54, 23)), Color("e1d1a0"), false)
	draw_string(ThemeDB.fallback_font, p + Vector2(-23, -3), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("3f5140"))
	draw_string(ThemeDB.fallback_font, p + Vector2(-23, 7), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("657053"))


func _flower(p: Vector2) -> void:
	draw_line(p, p + Vector2(0, -4), Color("456e46"), 2)
	draw_circle(p + Vector2(0, -6), 3, Color("f2d59a"))
	draw_circle(p + Vector2(0, -6), 1, Color("b88752"))


func _building() -> void:
	draw_rect(Rect2(700, 0, 480, 360), Color("746b5c"))
	for y in range(24, 336, 24):
		for x in range(724, 1156, 24):
			draw_rect(Rect2(x, y, 23, 23), Color("c8bd98") if (x + y) % 48 == 0 else Color("d6cca9"))
	draw_rect(Rect2(812, 230, 256, 90), Color("a87360"))
	draw_rect(Rect2(818, 236, 244, 78), Color("bc8e72"), false, 2)
	draw_rect(Rect2(796, 86, 288, 34), Color("5d7c70"))
	draw_rect(Rect2(800, 84, 280, 10), Color("a4bc91"))
	for x in [766, 1105]:
		draw_rect(Rect2(x, 150, 28, 28), Color("997a54"))
		draw_circle(Vector2(x + 14, 149), 20, Color("64915d"))
	draw_string(ThemeDB.fallback_font, Vector2(842, 67), "REFUGIO DEL CLARO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("efe5c6"))
	draw_string(ThemeDB.fallback_font, Vector2(818, 202), "Zona segura · sin encuentros", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("4a5b4c"))
	draw_rect(Rect2(914, 297, 52, 34), Color("394d46"))
	draw_string(ThemeDB.fallback_font, Vector2(921, 319), "SALIR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e0d6a8"))


func _cave() -> void:
	draw_rect(Rect2(0, 440, 640, 360), Color("34433f"))
	draw_rect(Rect2(24, 464, 592, 312), Color("647467"))
	draw_rect(Rect2(80, 545, 480, 220), Color("526658"))
	for y in range(550, 764, 17):
		for x in range(85, 558, 23):
			draw_line(Vector2(x, y), Vector2(x + 5, y - 2), Color("6d7f68"), 2)
	for x in range(20, 640, 30):
		draw_circle(Vector2(x, 452), 20, Color("43584b"))
		draw_circle(Vector2(x, 787), 20, Color("43584b"))
	draw_rect(Rect2(294, 461, 52, 34), Color("c8c591"))
	draw_string(ThemeDB.fallback_font, Vector2(302, 481), "SALIR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("3b4c42"))
	var config: Dictionary = get_parent()._active_config
	_sign(Vector2(100, 512), "CUEVA", "Nv. %d–%d" % [int(config.get("cave_min_level", 8)), int(config.get("cave_max_level", 12))])
