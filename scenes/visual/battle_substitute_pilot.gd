extends "res://scenes/visual/battle_status_switch_pilot.gd"

const SUB_PACK := "res://.godot/battle_substitute/manifest.json"
const SUB_SHA := "82c25e89c56f754d4715ac6fc7f5eb024473798dae9a1070e0d9c5f0616d5355"
var _profiles := {}


func configure(arena: Control, path: String = SUB_PACK) -> void:
	preview = Preview.new()
	preview.effects_only = true
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.add_child(preview)
	preview.hide()
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != SUB_SHA or not preview.load_pack(path):
		last_error = "Pack local de Sustituto ausente o distinto"
		return
	if preview.pack.get("selection") != "substitute_v1" or preview.pack.clips.size() != 4:
		return
	_profiles = preview.pack.profiles.duplicate(true)
	for n in preview.pack.clips.size():
		var row: Dictionary = preview.pack.clips[n]
		var profile := _profile(String(row.move_id), String(row.actor_side))
		if profile.is_empty() or row.frames.size() != profile.frames or row.fps != 20 or row.reference_animation_id != profile.reference or row.classification_unchanged != "DATA_ONLY":
			_indices.clear()
			return
		_indices[String(row.id)] = n
	available = _indices.size() == 4


func _profile(move: String, side: String) -> Dictionary:
	return _profiles.get(move + "/" + side, {}).duplicate(true)


func _accepts(move: String, data: Dictionary) -> bool:
	return move in ["substitute", "shed_tail"] and data.get("power") == 0 and data.get("category") == "status" \
		and data.get("target") == "user" and data.get("effects_empty") == true \
		and data.get("classification") == "DATA_ONLY" and data.get("type_id") == "normal"


func _enabled(before: Dictionary) -> bool:
	return bool(before.get("substitute_rules_enabled", false))


func _is_confirmed(step: Dictionary) -> bool:
	return step.get("event_kind") == String(BattleEvent.SUBSTITUTE_CREATED)


func show_entry(entry: Dictionary, arena: Control, elapsed: float) -> void:
	super.show_entry(entry, arena, elapsed)
	if not preview.visible: return
	var side := String(preview.clip.actor_side)
	var species: StringName = arena.player_species if side == "back" else arena.enemy_species
	var animation: Dictionary = Preview.Catalog.animation(species, side, "reposo")
	var bounds: Rect2 = Preview.Catalog.presentation_bounds(species, side, animation)
	var placement: Dictionary = Preview.Layout.placement(arena.size, side, bounds)
	var feet := Vector2(placement.anchor) + Vector2(0, bounds.end.y * float(placement.gain))
	var gain := minf(arena.size.x / 512.0, arena.size.y / 384.0)
	var doll_bounds := Rect2(66, 61, 62, 62) if side == "back" else Rect2(64, 58, 60, 64)
	var desired: Vector2 = feet - (Vector2(doll_bounds.get_center().x, doll_bounds.end.y) - Vector2(96, 96)) * gain
	var pattern := (7 if side == "back" else 6) if preview.clip.move_id == "shed_tail" else (1 if side == "back" else 0)
	var origin: Vector2 = Preview.SOURCE_BACK if side == "back" else Preview.SOURCE_FRONT
	var focus := 4
	for frame: Array in preview.clip.frames:
		for cell: Variant in frame:
			if cell != null and int(cell[7]) == pattern: focus = int(cell[26])
	var delta: Vector2 = desired - preview.map_position(origin, focus)
	# Move the already-authored particles as one group onto the actual doll feet.
	# Neither PNGs nor the frozen preview renderer are edited.
	for sprite: Sprite2D in preview._sprites:
		if sprite.visible: sprite.position += delta
