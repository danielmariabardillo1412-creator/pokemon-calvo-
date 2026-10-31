extends SceneTree

# Diagnostic snapshots; not domain support or full-motion approval.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["acupressure", "aromatic_mist", "entrainment", "flatter"]
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
		var image := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
		_bounds_cache[key] = Rect2(image.get_used_rect())
	var rect: Rect2 = _bounds_cache[key]
	if sprite.flip_h:
		rect.position.x = sprite.region_rect.size.x - rect.end.x
	rect.position += sprite.get_rect().position
	return sprite.transform * rect

func _capture(view: SubViewport, path: String) -> String:
	await process_frame
	RenderingServer.force_draw(false)
	var image := view.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	_check("save PNG", image.save_png(path) == OK)
	return FileAccess.get_sha256(path)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_local_effect_probe.gd")
	var out := "res://.godot/move_local_effect_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var rows: Array[Dictionary] = []
	var states := 0
	var mist_hashes: Dictionary = {}
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in MOVES):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
			var view := SubViewport.new()
			view.disable_3d = true
			view.transparent_bg = true
			view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			view.size = arena
			root.add_child(view)
			var stage := Preview.new()
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
						bodies.append({"slot": slot, "pattern": cel[7], "side": clip.slot_sides[0 if cel[7] == -1 else 1], "bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "bottom_overflow": maxf(0, bounds.end.y - arena.y), "tone": sprite.material.get_shader_parameter("tone")})
					var row := {"frame": f, "bodies": bodies, "layers_visible": [stage._layers.back.visible, stage._layers.front.visible]}
					if f in [0, 7, 8, 10, 12, 20, 25, 29, 30, 35, 40, clip.frames.size() - 1]:
						var name := String(clip.id).replace("/", "_") + "_%d_%03d.png" % [arena.x, f]
						row["path"] = name
						row["sha256"] = await _capture(view, out + name)
						if clip.move_id == "flatter" and f == 12:
							for sprite: Sprite2D in stage._sprites:
								sprite.region_filter_clip_enabled = true
							row["clip_region_path"] = name.trim_suffix(".png") + "_region_clip.png"
							row["clip_region_sha256"] = await _capture(view, out + row.clip_region_path)
							for sprite: Sprite2D in stage._sprites:
								sprite.region_filter_clip_enabled = false
						if clip.move_id == "aromatic_mist" and f in [20, 40]:
							stage._arena.hide()
							for sprite: Sprite2D in stage._sprites:
								sprite.hide()
							row["layers_path"] = name.trim_suffix(".png") + "_layers.png"
							row["layers_sha256"] = await _capture(view, out + row.layers_path)
							var key := str(arena) + str(f)
							if mist_hashes.has(key):
								_check("mist layers identical both sides", mist_hashes[key] == row.layers_sha256)
							else:
								mist_hashes[key] = row.layers_sha256
					frames.append(row)
					states += 1
				rows.append({"id": clip.id, "arena": [arena.x, arena.y], "frames": frames})
			stage.queue_free()
			view.queue_free()
			await process_frame
	_check("complete selection", rows.size() == 16 and states == 600)
	var report := {"version": 1, "gpu": true, "checks": _checks, "failures": _errors, "states": states, "clips": rows, "index_sha256": index_sha, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "scope": "All frames structural body bounds, sampled full GPU previews, mist layer equality and region-clip candidate; no mechanics approval"}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("LOCAL_EFFECT_PROBE ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", states, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
