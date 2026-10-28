extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
var _passed := 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_passed += int(ok)
	if not ok and _failures.size() < 20:
		_failures.append(label)


func _run() -> void:
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var gpu := DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args()
	var out := "res://.godot/move_layer_checks/" + FileAccess.get_sha256(INDEX).substr(0, 12) + "_" + FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd").substr(0, 12) + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview := Preview.new()
	viewport.add_child(preview)
	var tested := 0
	var hashes_by_clip: Dictionary = {}
	for shard: Dictionary in index.shards:
		var relevant := false
		for entry: Dictionary in shard.entries:
			relevant = relevant or String(entry.move_id) in ["wish", "sunny_day", "substitute", "extreme_evoboost", "destiny_bond"]
		if not relevant:
			continue
		_check("load", preview.load_pack(INDEX.get_base_dir().path_join(String(shard.path))))
		for clip_index in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[clip_index]
			if not String(clip.move_id) in ["wish", "sunny_day", "substitute", "extreme_evoboost", "destiny_bond"]:
				continue
			tested += 1
			for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
				viewport.size = arena
				preview.size = Vector2(arena)
				_check("select", preview.select_clip(clip_index))
				for frame_index in clip.frames.size():
					preview.show_frame(frame_index)
					for slot in clip.frames[frame_index].size():
						var cel: Variant = clip.frames[frame_index][slot]
						if cel == null or cel[7] < 0 or cel[26] != 4 or cel[6] != 1 or cel[8] <= 0:
							continue
						var sprite: Sprite2D = preview._sprites[slot]
						_check("nonzero_screen/" + String(clip.id), sprite.scale.x > 0 and sprite.scale.y > 0)
						var gain := minf(arena.x / 512.0, arena.y / 384.0)
						var expected_scale := Vector2(cel[2], cel[11]) * gain / 100.0
						_check("uniform_screen_scale/" + String(clip.id), sprite.scale.distance_to(expected_scale) < 0.001)
						var expected := (Vector2(arena) - Vector2(512, 384) * gain) / 2 + Vector2(cel[0], cel[1]) * gain
						_check("screen_camera/" + String(clip.id), sprite.position.distance_to(expected) < 0.001)
				if clip.move_id == "sunny_day":
					preview.show_frame(10)
					_check("sun_peak", is_equal_approx(float(clip.layers[10].back.opacity), 200.0) and preview._layers.back.visible)
					preview.show_frame(19)
					_check("sun_fades_out", float(clip.layers[19].back.opacity) == 0 and not preview._layers.back.visible)
			if gpu:
				viewport.size = Vector2i(640, 360)
				preview.size = Vector2(640, 360)
				preview.select_clip(clip_index)
				var samples: Array = [1, 10, 19] if clip.move_id == "sunny_day" else [3, 4, 15] if clip.move_id == "wish" else [1, int(clip.frames.size() / 2), clip.frames.size() - 1]
				var strip := Image.create(1920, 360, false, Image.FORMAT_RGBA8)
				var hashes: Dictionary = {}
				for sample in 3:
					preview.show_frame(samples[sample])
					await process_frame
					RenderingServer.force_draw(false)
					var image := viewport.get_texture().get_image()
					var context := HashingContext.new()
					context.start(HashingContext.HASH_SHA256)
					context.update(image.get_data())
					hashes[context.finish().hex_encode()] = true
					strip.blit_rect(image, Rect2i(0, 0, 640, 360), Vector2i(sample * 640, 0))
				_check("save", strip.save_png(out + String(clip.id).replace("/", "_") + ".png") == OK)
				hashes_by_clip[clip.id] = hashes.size()
				if clip.move_id == "wish":
					_check("wish_gpu_changes", hashes.size() > 1)
	_check("ten clips", tested == 10)
	var result := {"passed": _passed, "failures": _failures, "gpu": gpu, "distinct_samples": hashes_by_clip}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("SELF_SCREEN_LAYER ", "PASS" if _failures.is_empty() else "FAIL", " passed=", _passed, " failures=", _failures.size(), " output=", out)
	quit(0 if _failures.is_empty() else 1)
