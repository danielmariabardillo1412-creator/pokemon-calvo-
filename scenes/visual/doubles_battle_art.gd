extends Control

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Layout = preload("res://scenes/visual/battle_sprite_layout.gd")
const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
var step := {}
var progress := 1.0
var fade_curves := {}
var move_metadata := {}
var generic_effects_enabled := true
var animated_units := {} # Bodies rendered by the imported clip; labels remain here.
var _clock := 0.0
var centers := {}


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func show_step(value: Dictionary, amount: float) -> void:
	step = value.duplicate(true)
	progress = clampf(amount, 0, 1)
	queue_redraw()


func anchor(side: String, slot: int) -> Vector2:
	var positions := [Vector2(0.19, 0.84), Vector2(0.43, 0.67)] if side == "side_a" else [Vector2(0.65, 0.44), Vector2(0.85, 0.28)]
	return positions[slot] * size


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("aec38e"))
	draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.45), Color("c7d4a3"))
	if step.is_empty(): return
	var before: Dictionary = step.before
	var after: Dictionary = step.after
	var event: Dictionary = step.get("event", {})
	var swapping: bool = event.get("kind") == String(BattleEvent.ALLY_POSITIONS_SWAPPED)
	centers.clear()
	for side: String in ["side_b", "side_a"]:
		for position in [1, 0]:
			var foot := anchor(side, position)
			draw_set_transform(foot, 0, Vector2(1, 0.2))
			draw_circle(Vector2.ZERO, 35, Color("8eac73"))
			draw_set_transform(Vector2.ZERO)
			draw_string(ThemeDB.fallback_font, foot + Vector2(-5, 29), str(position + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("324d3e"))
	var ids: Array = before.units.keys()
	ids.sort_custom(func(a, b): return anchor(before.units[a].side, before.units[a].position).y < anchor(before.units[b].side, before.units[b].position).y)
	for id: String in ids:
		var row: Dictionary = before.units[id]
		var final: Dictionary = after.units.get(id, row)
		var foot := anchor(String(row.side), int(row.position))
		var opacity := 1.0
		if swapping and row.side == event.get("metadata", {}).get("side_id"):
			foot = foot.lerp(anchor(String(final.side), int(final.position)), smoothstep(0, 1, progress))
			var curve: Array = fade_curves.get("back" if row.side == "side_a" else "front", [])
			var phase := progress * 2.0 if progress < 0.5 else (1.0 - progress) * 2.0
			if not curve.is_empty(): opacity = float(curve[mini(curve.size() - 1, int(phase * curve.size()))])
		var hp := roundi(lerpf(int(row.hp), int(final.hp), smoothstep(0.15, 0.85, progress)))
		_draw_unit(row, foot, opacity if hp > 0 else 0, hp)
	if generic_effects_enabled and event.get("kind") == String(BattleEvent.DAMAGE_APPLIED) and int(event.get("amount", 0)) > 0:
		var source := String(event.actor_id)
		var target := String(event.target_id)
		var move: Dictionary = move_metadata.get(String(event.move_id), {})
		if centers.has(source) and centers.has(target) and Visuals.TYPES.has(String(move.get("type_id", ""))):
			var recipe: Array = Visuals.TYPES[String(move.type_id)]
			Visuals.draw(self, {"phase": "hit", "family": recipe[0], "color": recipe[1], "category": move.category}, centers[source], centers[target], progress, 0.8, 24)


func _draw_unit(row: Dictionary, foot: Vector2, opacity: float, hp: int) -> void:
	var side := "back" if row.side == "side_a" else "front"
	var species := StringName(row.species)
	var clip: Dictionary = Catalog.animation(species, side, "reposo")
	if clip.is_empty(): return
	var region: Array = clip.regions[Catalog.frame_index(clip, _clock)]
	var source := Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	var bounds := Catalog.presentation_bounds(species, side, clip)
	var placement := Layout.placement(size, side, bounds)
	var gain := float(placement.gain) * 0.62
	var body_anchor := foot - Vector2(0, bounds.end.y * gain)
	var scale := gain * float(clip.unit_scale)
	var destination := Rect2(body_anchor - Vector2(clip.pivot) * scale, source.size * scale)
	centers[String(row.id)] = body_anchor + bounds.get_center() * gain
	if not animated_units.has(String(row.id)): draw_texture_rect_region(clip.texture, destination, source, Color(1, 1, 1, opacity))
	var text := "%s  %d/%d" % [String(row.get("name", row.species)), hp, int(row.max_hp)]
	draw_string(ThemeDB.fallback_font, foot + Vector2(-62, 13), text, HORIZONTAL_ALIGNMENT_LEFT, 130, 11, Color("183c30"))
	draw_rect(Rect2(foot + Vector2(-42, 17), Vector2(84, 5)), Color("60774d"))
	draw_rect(Rect2(foot + Vector2(-42, 17), Vector2(84.0 * hp / maxi(1, int(row.max_hp)), 5)), Color("b4e079"))


func actor_layout(row: Dictionary) -> Dictionary:
	var side := "back" if row.side == "side_a" else "front"
	var clip: Dictionary = Catalog.animation(StringName(row.species), side)
	if clip.is_empty(): return {}
	var r: Array = clip.regions[0]
	var region := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	var bounds := Catalog.presentation_bounds(StringName(row.species), side, clip)
	var gain := float(Layout.placement(size, side, bounds).gain) * 0.62
	var body := anchor(row.side, int(row.position)) - Vector2(0, bounds.end.y * gain)
	var scale := gain * float(clip.unit_scale)
	var center := body + bounds.get_center() * gain
	var full_center := body + (region.size * 0.5 - Vector2(clip.pivot)) * scale
	return {"texture": clip.texture, "region": region, "gain": scale, "center": center,
		"offset": (full_center - center) / scale, "half_width": bounds.size.x * gain * 0.5, "half_height": bounds.size.y * gain * 0.5}
