extends RefCounted

# Shared visual recipes, not mechanics or individual move animations.
# Only immutable definition metadata and already-resolved events are read.
const TYPES := {
	"normal": ["burst", "e3e0c9"], "fire": ["flame", "ff8a3d"],
	"water": ["bubble", "55c9ff"], "electric": ["bolt", "ffe55a"],
	"grass": ["leaf", "83d96c"], "ice": ["shard", "a2eeff"],
	"fighting": ["slash", "f4a074"], "poison": ["bubble", "c987e7"],
	"ground": ["shard", "d9b370"], "flying": ["wind", "c1e4f5"],
	"psychic": ["ring", "f393c9"], "bug": ["leaf", "b8cf51"],
	"rock": ["shard", "c9b187"], "ghost": ["wisp", "b39ae9"],
	"dragon": ["wisp", "9998ff"], "dark": ["slash", "a6a0b8"],
	"steel": ["slash", "d3e3e9"], "fairy": ["sparkle", "ffc0e7"]}


static func metadata(move: MoveDefinition) -> Dictionary:
	if move == null:
		return {}
	return {"id": String(move.id), "type_id": String(move.type_id),
		"category": move.damage_class, "target": move.target, "classification": move.classification,
		"power": move.power, "effects_empty": move.effect_specs.is_empty()}


static func describe(event: Dictionary, moves: Dictionary, creatures: Dictionary, views: Dictionary, action: Dictionary) -> Dictionary:
	var kind := String(event.get("kind", ""))
	var id := String(event.get("move_id", ""))
	var move: Dictionary = moves.get(id, {})
	if move.is_empty() or not TYPES.has(String(move.get("type_id", ""))):
		return {}
	var category := String(move.get("category", ""))
	if category not in ["physical", "special", "status"]:
		return {}
	var actor := String(event.get("actor_id", ""))
	var target := String(event.get("target_id", ""))
	var source_side := _visible_side(actor, creatures, views)
	var target_side := _visible_side(target, creatures, views)
	var phase := ""
	if kind == String(BattleEvent.ACTION_USED):
		if source_side.is_empty():
			return {}
		phase = "cast"
		if category == "status" or String(move.get("target", "")) == "user":
			target_side = source_side
	elif kind in [String(BattleEvent.DAMAGE_APPLIED), String(BattleEvent.SUBSTITUTE_DAMAGED)]:
		# Reactive ability/item damage can carry the original move ID. Do not
		# replay its element as another attack unless actor/recipient match it.
		if int(event.get("amount", 0)) <= 0 or category == "status" or not _same_action(event, action) or target != String(action.get("target_id", "")):
			return {}
		phase = "hit"
	elif kind in [String(BattleEvent.STATUS_APPLIED), String(BattleEvent.STAT_STAGE_CHANGED), String(BattleEvent.HP_RECOVERED)]:
		if category != "status" or not _same_action(event, action):
			return {}
		if kind != String(BattleEvent.STATUS_APPLIED) and int(event.get("amount", 0)) == 0:
			return {}
		phase = "support"
	else:
		return {}
	if source_side.is_empty() or target_side.is_empty():
		return {}
	var recipe: Array = TYPES[String(move.type_id)]
	return {"move_id": id, "type_id": String(move.type_id), "category": category,
		"family": String(recipe[0]), "color": String(recipe[1]), "phase": phase,
		"source_side": source_side, "target_side": target_side}


static func _same_action(event: Dictionary, action: Dictionary) -> bool:
	return not action.is_empty() and String(event.get("move_id", "")) == String(action.get("move_id", "")) and String(event.get("actor_id", "")) == String(action.get("actor_id", ""))


static func _visible_side(id: String, creatures: Dictionary, views: Dictionary) -> String:
	var creature: Dictionary = creatures.get(id, {})
	var side := String(creature.get("side", ""))
	if side.is_empty() or String(views.get(side, {}).get("instance_id", "")) != id or not bool(views.get(side, {}).get("visible", true)):
		return ""
	return side


static func cast_endpoint(source: Vector2, target: Vector2, target_radius: float, scale: float) -> Vector2:
	var distance := source.distance_to(target)
	if distance <= 0.0001:
		return source
	return source.lerp(target, clampf(1.0 - (target_radius + 12.0 * scale) / distance, 0.0, 0.82))


static func draw(canvas: CanvasItem, visual: Dictionary, source: Vector2, target: Vector2, progress: float, scale: float, target_radius: float = 0.0) -> void:
	if visual.is_empty() or progress <= 0.0 or progress >= 1.0:
		return
	var p := clampf(progress, 0.0, 1.0)
	var pulse := sin(p * PI)
	var color := Color(String(visual.color))
	color.a = pulse * 0.9
	var phase := String(visual.phase)
	if phase == "support" or (phase == "cast" and String(visual.category) == "status"):
		var center := target if phase == "support" else source
		canvas.draw_arc(center, (10.0 + p * 22.0) * scale, 0, TAU, 32, color, 2.0 * scale, true)
		for index in 4:
			_glyph(canvas, "sparkle", center + Vector2.from_angle(index * TAU / 4.0 + p) * 20.0 * scale, 4.0 * scale, color, p)
	elif phase == "cast":
		if String(visual.category) == "physical":
			var center := source.lerp(target, pulse * 0.18)
			_glyph(canvas, String(visual.family), center, 11.0 * scale, color, p)
		else:
			# Travel stops short of the recipient. Only DAMAGE_APPLIED creates a
			# hit there, so misses/immunity never acquire a fabricated impact.
			var end := cast_endpoint(source, target, target_radius, scale)
			for index in 3:
				var travel := clampf(p - index * 0.06, 0.0, 1.0)
				var center := source.lerp(end, travel)
				center.y += sin(p * TAU + index) * 3.0 * scale
				var trail := color
				trail.a *= 1.0 - index * 0.25
				_glyph(canvas, String(visual.family), center, (10.0 - index * 2.0) * scale, trail, p)
	elif phase == "hit":
		for index in 6:
			var direction := Vector2.from_angle(index * TAU / 6.0 + p * 0.3)
			var center := target + direction * (5.0 + p * 22.0) * scale
			_glyph(canvas, String(visual.family), center, (5.5 - p * 2.0) * scale, color, p)


static func _glyph(canvas: CanvasItem, family: String, center: Vector2, radius: float, color: Color, progress: float) -> void:
	match family:
		"bubble":
			canvas.draw_circle(center, radius, Color(color, color.a * 0.2))
			canvas.draw_arc(center, radius, 0, TAU, 20, color, 1.5, true)
			canvas.draw_circle(center + Vector2(-0.3, -0.3) * radius, radius * 0.18, Color(1, 1, 1, color.a))
		"bolt":
			canvas.draw_polyline(PackedVector2Array([center + Vector2(-0.3, -1) * radius, center + Vector2(0.25, -0.2) * radius,
				center + Vector2(-0.25, 0.15) * radius, center + Vector2(0.35, 1) * radius]), color, 2.5, true)
		"flame":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -1.3) * radius, center + Vector2(0.75, 0.25) * radius,
				center + Vector2(0.25, 0.9) * radius, center + Vector2(-0.5, 0.65) * radius, center + Vector2(-0.75, 0.1) * radius]), color)
			canvas.draw_circle(center + Vector2(0, 0.25) * radius, radius * 0.32, Color(1, 0.95, 0.65, color.a))
		"leaf", "shard":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -1) * radius, center + Vector2(0.5, -0.1) * radius,
				center + Vector2(0, 1) * radius, center + Vector2(-0.5, 0.1) * radius]), color)
			canvas.draw_line(center - Vector2(0, radius * 0.7), center + Vector2(0, radius * 0.7), Color(1, 1, 1, color.a * 0.6), 1, true)
		"ring", "wind":
			canvas.draw_arc(center, radius, progress * TAU, progress * TAU + PI * 1.6, 24, color, 2.0, true)
			canvas.draw_arc(center, radius * 0.6, -progress * TAU, -progress * TAU + PI * 1.4, 20, color, 1.0, true)
		"wisp":
			canvas.draw_circle(center, radius, Color(color, color.a * 0.25))
			canvas.draw_circle(center, radius * 0.55, color)
			canvas.draw_arc(center, radius * 1.3, 0.1, PI * 1.3, 20, color, 1.5, true)
		"slash":
			for index in 3:
				var shift := Vector2(index - 1, 0) * radius * 0.45
				canvas.draw_line(center + shift + Vector2(-0.6, 0.8) * radius, center + shift + Vector2(0.6, -0.8) * radius, color, 2.0, true)
		_:
			var rays := 4 if family == "sparkle" else 6
			for index in rays:
				var direction := Vector2.from_angle(index * TAU / rays)
				canvas.draw_line(center + direction * radius * 0.2, center + direction * radius, color, 2.0, true)
