extends SceneTree

# Independent canonical-line/rigid-slot oracles for audited native OppMove exports.
# No battle routes or mechanics. Captures are optional, via an offscreen viewport.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const FRAMES := {"hyper_drill": [0, 7, 28], "rolling_kick": [0, 5, 7], "upper_hand": [0, 2, 12],
	"chilly_reception": [0, 12, 17], "malignant_chain": [4, 11, 21]}
var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _failures.size() < 20:
		_failures.append(label)


func _run() -> void:
	var index_path := INDEX
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--index="):
			index_path = arg.trim_prefix("--index=")
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(index_path))
	var capture := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var test_hash := FileAccess.get_sha256("res://tests/visual/move_camera_repair_test_runner.gd")
	var folder := "res://.godot/move_camera_checks/" + FileAccess.get_sha256(index_path).substr(0, 16) + "_" + test_hash.substr(0, 12) + "/"
	DirAccess.make_dir_recursive_absolute(folder)
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview := Preview.new()
	viewport.add_child(preview)
	var seen := 0
	for shard: Dictionary in index.shards:
		var relevant := false
		for entry: Dictionary in shard.entries:
			relevant = relevant or FRAMES.has(String(entry.move_id))
		if not relevant:
			continue
		_check("load", preview.load_pack(INDEX.get_base_dir().path_join(String(shard.path))))
		for clip_index in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[clip_index]
			if not FRAMES.has(String(clip.move_id)):
				continue
			seen += 1
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["charizard", "ogerpon"]]:
				preview.back_species = StringName(pair[0])
				preview.front_species = StringName(pair[1])
				for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
					viewport.size = arena
					preview.size = Vector2(arena)
					_check("select", preview.select_clip(clip_index))
					for frame_index in clip.frames.size():
						_check("show", preview.show_frame(frame_index))
						for slot in clip.frames[frame_index].size():
							var cel: Variant = clip.frames[frame_index][slot]
							if cel == null or int(cel[7]) < 0 or int(cel[6]) != 1 or float(cel[8]) <= 0:
								continue
							if clip.actor_side == "front":
								# Do not use preview.map_position as its own oracle.
								var rear := Vector2(preview._actors.back.center)
								var forward := Vector2(preview._actors.front.center)
								var point := Vector2(float(cel[0]), float(cel[1]))
								var expected := rear + (point - Vector2(128, 224)) / Vector2(256, -128) * (forward - rear)
								if clip.move_id in ["malignant_chain", "chilly_reception"]:
									var gain := minf(arena.x / 512.0, arena.y / 384.0)
									if clip.move_id == "chilly_reception" and int(cel[7]) == 2:
										expected = forward + (point - Vector2(384, 96)) * gain
									else:
										expected = rear + (point - Vector2(128, 224)) * gain
									_check("rigid_tile_scale/" + String(clip.id), preview._sprites[slot].scale.distance_to(Vector2(cel[2], cel[11]) * gain / 100.0) < 0.001)
								_check("canonical/" + String(clip.id) + "/%d/%d" % [frame_index, slot], preview._sprites[slot].position.distance_to(expected) < 0.001)
			if capture:
				preview.back_species = &"ogerpon"
				preview.front_species = &"charizard"
				viewport.size = Vector2i(640, 360)
				preview.size = Vector2(640, 360)
				preview.select_clip(clip_index)
				var strip := Image.create(1920, 360, false, Image.FORMAT_RGBA8)
				for sample in 3:
					preview.show_frame(FRAMES[String(clip.move_id)][sample])
					await process_frame
					RenderingServer.force_draw(false)
					strip.blit_rect(viewport.get_texture().get_image(), Rect2i(0, 0, 640, 360), Vector2i(sample * 640, 0))
				_check("save", strip.save_png(folder + String(clip.id).replace("/", "_") + ".png") == OK)
	_check("paired clips", seen == FRAMES.size() * 2)
	var result := {"checks": _checks, "failures": _failures, "index_sha256": FileAccess.get_sha256(index_path), "runner_sha256": test_hash, "gpu": capture}
	var file := FileAccess.open(folder + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("MOVE_CAMERA_REPAIR ", "PASS" if _failures.is_empty() else "FAIL", " checks=", _checks, " failures=", _failures.size(), " output=", folder)
	quit(0 if _failures.is_empty() else 1)
