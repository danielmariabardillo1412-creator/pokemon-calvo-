extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["rock_climb", "storm_throw", "take_down"]

class CanonicalPreview extends Preview:
	func _actor(species: StringName, side: String) -> Dictionary:
		var actor := super._actor(species, side)
		actor.center = Vector2(128, 224) if side == "back" else Vector2(384, 96)
		return actor

class CandidatePreview extends Preview:
	func show_frame(index: int) -> bool:
		var ok := super.show_frame(index)
		if not ok or not String(clip.move_id) in ["rock_climb", "take_down"]:
			return ok
		var user_pattern := -2 if clip.opponent_export else -1
		for slot in clip.frames[index].size():
			var cel: Variant = clip.frames[index][slot]
			if cel == null or not _sprites[slot].visible:
				continue
			if cel[7] == user_pattern:
				_sprites[slot].position = map_position(Vector2(cel[0], cel[1]), 3)
			elif clip.id == "take_down/front" and cel[7] >= 0 and cel[26] == 1:
				_sprites[slot].position = map_position(Vector2(cel[0], cel[1]), 2)
		return ok

var _checks := 0
var _errors: Array[String] = []
var _bounds_cache: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 20:
		_errors.append(label)

func _bounds(sprite: Sprite2D) -> Rect2:
	var key := str(sprite.texture.get_instance_id()) + str(sprite.region_rect)
	if not _bounds_cache.has(key):
		_bounds_cache[key] = Rect2(sprite.texture.get_image().get_region(Rect2i(sprite.region_rect)).get_used_rect())
	var rect: Rect2 = _bounds_cache[key]
	if sprite.flip_h:
		rect.position.x = sprite.region_rect.size.x - rect.end.x
	rect.position += sprite.get_rect().position
	return sprite.transform * rect

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_motion_path_probe.gd")
	var out := "res://.godot/move_motion_path_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var rows: Array[Dictionary] = []
	var states := 0
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in MOVES):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for mode: String in ["canonical", "before640", "candidate640", "before400", "candidate400"]:
			var arena := Vector2i(512, 384) if mode == "canonical" else Vector2i(400, 300) if mode.ends_with("400") else Vector2i(640, 360)
			var view := SubViewport.new()
			view.disable_3d = true
			view.transparent_bg = true
			view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			view.size = arena
			root.add_child(view)
			var stage: Control = CanonicalPreview.new() if mode == "canonical" else CandidatePreview.new() if mode.begins_with("candidate") else Preview.new()
			stage.size = Vector2(arena)
			view.add_child(stage)
			_check("load", stage.load_pack(path))
			for n in stage.pack.clips.size():
				var clip: Dictionary = stage.pack.clips[n]
				if not String(clip.move_id) in MOVES:
					continue
				_check("select", stage.select_clip(n))
				var frames: Array[Dictionary] = []
				for f in clip.frames.size():
					_check("frame", stage.show_frame(f))
					var bodies: Array[Dictionary] = []
					for slot in clip.frames[f].size():
						var cel: Variant = clip.frames[f][slot]
						var sprite: Sprite2D = stage._sprites[slot]
						if cel == null or not sprite.visible or cel[7] >= 0:
							continue
						var bounds := _bounds(sprite)
						var intersection := Rect2(Vector2.ZERO, Vector2(arena)).intersection(bounds)
						bodies.append({"slot": slot, "pattern": cel[7], "source": [cel[0], cel[1]], "source_focus": cel[26], "position": [sprite.position.x, sprite.position.y], "bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "bbox_visible_fraction": intersection.get_area() / maxf(1, bounds.get_area())})
					var row := {"frame": f, "bodies": bodies}
					if f in [0, 4, 8, 9, 10, 13, 15, 19, 20, 22, 23, 24, 25, 28, clip.frames.size() - 1]:
						await process_frame
						RenderingServer.force_draw(false)
						var image := view.get_texture().get_image()
						image.convert(Image.FORMAT_RGBA8)
						var name := String(clip.id).replace("/", "_") + "_%s_%03d.png" % [mode, f]
						_check("save", image.save_png(out + name) == OK)
						row["path"] = name
						row["sha256"] = FileAccess.get_sha256(out + name)
					frames.append(row)
					states += 1
				rows.append({"id": clip.id, "mode": mode, "arena": [arena.x, arena.y], "frames": frames})
			stage.queue_free()
			view.queue_free()
			await process_frame
	_check("complete matrix", rows.size() == 30 and states == 800)
	var report := {"version": 1, "gpu": true, "checks": _checks, "failures": _errors, "states": states, "clips": rows, "index_sha256": index_sha, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "scope": "Candidate source-line body path, not final approval; canonical slots are geometric reference, not original-game footage; bbox fraction is not pixel coverage."}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("MOTION_PATH_PROBE ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", states, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
