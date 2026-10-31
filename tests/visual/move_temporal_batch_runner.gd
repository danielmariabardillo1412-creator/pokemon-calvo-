extends SceneTree

# Every-frame GPU collection for a pinned, resumable block. NOT a battle test.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const PLANNER := "res://tools/visual/review_move_temporal_batches.py"
const RUNNER := "res://tests/visual/move_temporal_batch_runner.gd"
var _errors: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _read(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return value if value is Dictionary else {}


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 30:
		_errors.append(label)


func _pixels(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()


func _capture(viewport: SubViewport) -> Image:
	await process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("TEMPORAL_BATCH BLOCKED: actual GPU required")
		quit(1)
		return
	var plan_path := ""
	var number := 0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--plan=") and plan_path.is_empty():
			plan_path = arg.trim_prefix("--plan=")
		elif arg.begins_with("--batch=") and number == 0 and arg.trim_prefix("--batch=").is_valid_int():
			number = int(arg.trim_prefix("--batch="))
		else:
			_check("unknown or duplicate batch argument", false)
	_check("bounded local plan path", plan_path.begins_with("res://.godot/move_temporal_batches/") and plan_path.ends_with("/plan.json") and not plan_path.contains("..") and not plan_path.contains("\\"))
	var plan := _read(plan_path)
	var index := _read(INDEX)
	var index_hash := FileAccess.get_sha256(INDEX)
	var renderer_hash := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	_check("plan version/scope", plan.get("version") == 1 and plan.get("scope") == "TEMPORAL_LAB_REVIEW_NOT_BATTLE_TEST")
	_check("current plan inputs", plan.get("index_sha256") == index_hash and plan.get("renderer_sha256") == renderer_hash and plan.get("builder_sha256") == FileAccess.get_sha256(PLANNER))
	_check("no mechanics", plan.get("mechanics_approved") == false and plan.get("battle_routes_added") == 0)
	_check("batch number", plan.get("batches") is Array and number >= 1 and number <= plan.get("batches", []).size() and plan.get("batch_size") == 50)
	if not _errors.is_empty():
		print("TEMPORAL_BATCH FAIL preflight ", _errors)
		quit(1)
		return
	var all_moves: Dictionary = {}
	var all_clips: Dictionary = {}
	for batch: Dictionary in plan.batches:
		_check("bounded batch", batch.move_ids.size() > 0 and batch.move_ids.size() <= 50)
		for move: String in batch.move_ids:
			_check("unique planned move", not all_moves.has(move))
			all_moves[move] = true
		for id: String in batch.clip_ids:
			_check("unique paired clip", not all_clips.has(id) and (id.get_slice("/", 0) in batch.move_ids))
			all_clips[id] = true
			var family := id.get_base_dir()
			_check("complete context/variant family", family + "/back" in batch.clip_ids and family + "/front" in batch.clip_ids)
	for move: Dictionary in index.moves:
		_check("complete converted move coverage", all_moves.has(move.move_id) == (move.status == "converted_lab_only"))
	for shard: Dictionary in index.shards:
		for entry: Dictionary in shard.entries:
			_check("complete indexed clip coverage", all_clips.has(entry.id))
	_check("exact total clip coverage", all_clips.size() == int(index.converted_clips) and all_moves.size() == int(plan.move_count))
	if not _errors.is_empty():
		print("TEMPORAL_BATCH FAIL membership ", _errors)
		quit(1)
		return
	var batch: Dictionary = plan.batches[number - 1]
	_check("batch position", batch.number == number)
	var plan_hash := FileAccess.get_sha256(plan_path)
	var runner_hash := FileAccess.get_sha256(RUNNER)
	var generation := (plan_hash + runner_hash + str(number)).sha256_text().substr(0, 16)
	var out := plan_path.get_base_dir() + "/batch_%02d_" % number + generation + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview := Preview.new()
	preview.size = Vector2(640, 360)
	viewport.add_child(preview)
	var rows: Array[Dictionary] = []
	var frames := 0
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return e.id in batch.clip_ids):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard hash/load", FileAccess.get_sha256(path) == shard.sha256 and preview.load_pack(path))
		if not _errors.is_empty():
			break
		for n in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[n]
			if not clip.id in batch.clip_ids:
				continue
			preview.select_clip(n)
			preview.clear_preview()
			var clean := _pixels(await _capture(viewport))
			preview.select_clip(n)
			var directory := String(clip.id).replace("/", "_")
			DirAccess.make_dir_recursive_absolute(out + directory)
			var sequence: Array[Dictionary] = []
			for f in clip.frames.size():
				_check("native frame", preview.show_frame(f))
				var image := await _capture(viewport)
				var filename := directory + "/%03d.png" % f
				_check("real frame save", image.save_png(out + filename) == OK)
				var bodies: Array = []
				var particles := 0
				for slot in clip.frames[f].size():
					var cel: Variant = clip.frames[f][slot]
					if cel == null:
						continue
					if cel[7] < 0:
						var sprite: Sprite2D = preview._sprites[slot]
						bodies.append({"slot": slot, "pattern": cel[7], "side": clip.slot_sides[0 if cel[7] == -1 else 1], "visible": sprite.visible,
							"opacity": (sprite.material as ShaderMaterial).get_shader_parameter("opacity"),
							"position": [sprite.position.x, sprite.position.y], "scale": [sprite.scale.x, sprite.scale.y]})
					elif cel[6] == 1 and cel[8] > 0:
						particles += 1
				sequence.append({"frame": f, "seconds": f / 20.0, "path": filename, "sha256": FileAccess.get_sha256(out + filename),
					"pixels_sha256": _pixels(image), "source_visible_particle_cels": particles, "bodies": bodies})
				preview.show_seconds((f + 0.5) / 20.0)
				_check("clock index", preview.current_frame == f)
				frames += 1
			preview.clear_preview()
			_check("state cleanup", preview.current_frame == -1 and preview.clip.is_empty() and preview.visible_cells() == 0)
			for layer: Sprite2D in preview._layers.values():
				_check("layer cleanup", not layer.visible)
			var after := _pixels(await _capture(viewport))
			_check("GPU cleanup", after == clean)
			rows.append({"id": clip.id, "move_id": clip.move_id, "title": clip.title, "side": clip.actor_side, "source_name": clip.name,
				"classification": clip.classification_unchanged, "fps": 20, "frames": sequence, "cleanup_matches_baseline": after == clean})
			print("TEMPORAL_BATCH_CLIP ", clip.id, " frames=", sequence.size())
	_check("complete requested batch", rows.size() == batch.clip_ids.size())
	_check("inputs stable", FileAccess.get_sha256(INDEX) == index_hash and FileAccess.get_sha256(plan_path) == plan_hash and FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd") == renderer_hash)
	var report := {"version": 1, "gpu": true, "checks": _checks, "failures": _errors, "frames": frames, "batch": number,
		"plan_path": plan_path, "plan_sha256": plan_hash, "index_sha256": index_hash, "renderer_sha256": renderer_hash,
		"runner_sha256": runner_hash, "clips": rows, "scope": "Every-frame lab capture and clock/cleanup tests, not realtime human viewing or battle/mechanics approval"}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("TEMPORAL_BATCH ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " frames=", frames, " clips=", rows.size(), " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
