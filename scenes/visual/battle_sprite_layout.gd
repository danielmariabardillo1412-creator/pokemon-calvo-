extends RefCounted

# Adapt Showdown's native-footprint sizes and modern singles perspective to our
# arena. Anchors and safety caps remain local, not a replica of its entire camera.
const REFERENCE_ARENA := Vector2(640, 360)
const FRONT_PERSPECTIVE := 1.0
const BACK_PERSPECTIVE := 1.5
const FRONT_MAX_FRACTION := Vector2(0.30, 0.40)
const BACK_MAX_FRACTION := Vector2(0.40, 0.56)


static func placement(arena: Vector2, side: String, envelope: Rect2) -> Dictionary:
	var front := side == "front"
	var anchor := arena * (Vector2(0.75, 0.56) if front else Vector2(0.25, 0.88))
	var base := minf(arena.x / REFERENCE_ARENA.x, arena.y / REFERENCE_ARENA.y)
	var gain := base * (FRONT_PERSPECTIVE if front else BACK_PERSPECTIVE)
	if envelope.size.x <= 0.0 or envelope.size.y <= 0.0 or arena.x <= 0.0 or arena.y <= 0.0:
		return {"anchor": anchor, "gain": 0.0, "guard": 0.0}
	var fraction := FRONT_MAX_FRACTION if front else BACK_MAX_FRACTION
	var guard := minf(1.0, minf(arena.x * fraction.x / (envelope.size.x * gain), arena.y * fraction.y / (envelope.size.y * gain)))
	# Guard asymmetric poses and movement past the fixed pivot, not only total size.
	var left := arena.x * (0.52 if front else 0.025)
	var right := arena.x * (0.975 if front else 0.48)
	var top := arena.y * 0.025
	var bottom := arena.y * (0.69 if front else 0.975)
	if envelope.position.x < 0.0:
		guard = minf(guard, (anchor.x - left) / (-envelope.position.x * gain))
	if envelope.end.x > 0.0:
		guard = minf(guard, (right - anchor.x) / (envelope.end.x * gain))
	if envelope.position.y < 0.0:
		guard = minf(guard, (anchor.y - top) / (-envelope.position.y * gain))
	if envelope.end.y > 0.0:
		guard = minf(guard, (bottom - anchor.y) / (envelope.end.y * gain))
	return {"anchor": anchor, "gain": gain * guard, "guard": guard}
