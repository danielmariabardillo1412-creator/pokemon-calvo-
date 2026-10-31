extends SceneTree

# Evidence collector, NOT artistic approval or battle/mechanics admission.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const REVIEW_ROOT := "res://.godot/move_contact_review/"
const OUTPUT := "res://.godot/move_temporal_checks/"
var _errors: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _read(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok:
		_errors.append(label)


func _image_hash(image: Image) -> String:
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
		print("TEMPORAL_REVIEW BLOCKED: GPU required")
		quit(1)
		return
	var index_hash := FileAccess.get_sha256(INDEX)
	var renderer_hash := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var pointer := _read(REVIEW_ROOT + "latest.json")
	var relative := String(pointer.get("path", ""))
	if relative.is_empty() or relative.is_absolute_path() or relative.contains(".."):
		quit(1)
		return
	var capture_path := REVIEW_ROOT + relative
	var capture := _read(capture_path)
	var folder := capture_path.get_base_dir()
	var boards := _read(folder + "/sheets_20/boards.json")
	var ledger_path := folder + "/sheets_20/review_log.json"
	var ledger := _read(ledger_path)
	var ledger_hash := FileAccess.get_sha256(ledger_path)
	_check("capture manifest hash", FileAccess.get_sha256(capture_path) == pointer.sha256)
	_check("capture context", capture.get("index_sha256") == index_hash and capture.get("renderer_sha256") == renderer_hash)
	_check("board context", boards.get("index_sha256") == index_hash and boards.get("capture_manifest_sha256") == pointer.sha256)
	var valid: Dictionary = {}
	for page: Dictionary in boards.get("pages", []):
		_check("board bytes/" + String(page.id), FileAccess.get_sha256(folder + "/sheets_20/" + String(page.path)) == page.sha256)
		valid[page.id] = page
	var latest: Dictionary = {}
	for entry: Dictionary in ledger.get("reviews", []):
		if entry.index_sha256 != index_hash or not valid.has(entry.board) or entry.board_sha256 != valid[entry.board].sha256:
			continue
		for id: String in entry.clip_ids:
			_check("review membership", id in valid[entry.board].clip_ids)
			latest[id] = entry
	var selected: Dictionary = {}
	# Explicit bounded comparisons may include an already sampled reference.
	# Default remains the complete exception queue; never silently skip a side.
	var requested: Array[String] = []
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--moves=") or not requested.is_empty():
			_check("valid focal argument", false)
			continue
		for move: String in argument.trim_prefix("--moves=").split(",", false):
			_check("unique focal move", not requested.has(move) and move.is_valid_identifier())
			requested.append(move)
		_check("bounded nonempty focal comparison", not requested.is_empty() and requested.size() <= 10)
	requested.sort()
	for id: String in latest:
		if (not requested.is_empty() and String(id).get_slice("/", 0) in requested) or (requested.is_empty() and latest[id].status in ["needs_motion_review", "suspected_issue", "confirmed_issue"]):
			selected[id] = latest[id].status
	for move: String in requested:
		_check("complete focal pair/" + move, selected.has(move + "/back") and selected.has(move + "/front"))
	_check("nonempty focal queue", not selected.is_empty())
	if not _errors.is_empty():
		print("TEMPORAL_REVIEW FAIL preflight ", _errors)
		quit(1)
		return
	var script_hash := FileAccess.get_sha256("res://tests/visual/move_temporal_review.gd")
	var generation := (index_hash + renderer_hash + ledger_hash + script_hash + JSON.stringify(requested)).sha256_text().substr(0, 16)
	var out := OUTPUT + generation + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview := Preview.new()
	preview.size = Vector2(640, 360)
	viewport.add_child(preview)
	var index := _read(INDEX)
	var clips: Array[Dictionary] = []
	var frames := 0
	for shard: Dictionary in index.shards:
		var relevant := false
		for entry: Dictionary in shard.entries:
			relevant = relevant or selected.has(entry.id)
		if not relevant:
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard hash/load", FileAccess.get_sha256(path) == shard.sha256 and preview.load_pack(path))
		if not _errors.is_empty():
			break
		for clip_index in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[clip_index]
			if not selected.has(clip.id):
				continue
			preview.select_clip(clip_index)
			preview.clear_preview()
			var clean_before := _image_hash(await _capture(viewport))
			preview.select_clip(clip_index)
			var rows: Array[Dictionary] = []
			var directory := String(clip.id).replace("/", "_")
			DirAccess.make_dir_recursive_absolute(out + directory)
			for frame in clip.frames.size():
				_check("show_frame", preview.show_frame(frame))
				var image := await _capture(viewport)
				var filename := directory + "/%03d.png" % frame
				_check("save native frame", image.save_png(out + filename) == OK)
				var bodies: Array = []
				var particles := 0
				for slot in clip.frames[frame].size():
					var cel: Variant = clip.frames[frame][slot]
					if cel == null:
						continue
					if cel[7] < 0:
						var sprite: Sprite2D = preview._sprites[slot]
						var material := sprite.material as ShaderMaterial
						bodies.append({"pattern": cel[7], "side": clip.slot_sides[0 if cel[7] == -1 else 1],
							"source_opacity": cel[8], "source_tone": cel.slice(16, 20),
							"visible": sprite.visible, "render_opacity": material.get_shader_parameter("opacity"),
							"render_tone": str(material.get_shader_parameter("tone"))})
					elif cel[6] == 1 and cel[8] > 0:
						particles += 1
				rows.append({"frame": frame, "seconds": frame / 20.0, "path": filename,
					"sha256": FileAccess.get_sha256(out + filename), "pixels_sha256": _image_hash(image),
					"visible_source_particles": particles, "bodies": bodies})
				frames += 1
			# Check real playback indexing at every source interval, not only scrubbing.
			for frame in clip.frames.size():
				preview.show_seconds((frame + 0.5) / 20.0)
				_check("clock frame indexing", preview.current_frame == frame)
			preview.clear_preview()
			_check("clear preview state", preview.current_frame == -1 and preview.clip.is_empty() and preview.visible_cells() == 0)
			for layer: Sprite2D in preview._layers.values():
				_check("clear layers", not layer.visible)
			var clean_after := _image_hash(await _capture(viewport))
			_check("clear GPU pixels", clean_after == clean_before)
			clips.append({"id": clip.id, "move_id": clip.move_id, "title": clip.title,
				"side": clip.actor_side, "source_name": clip.name, "source_shard_sha256": shard.sha256,
				"previous_status": selected[clip.id], "fps": 20, "frames": rows,
				"cleanup_pixels_sha256": clean_after, "cleanup_matches_baseline": clean_after == clean_before})
			print("TEMPORAL_CLIP ", clip.id, " frames=", rows.size(), " cleanup=", clean_after == clean_before)
	_check("complete selection", clips.size() == selected.size())
	_check("unchanged inputs", FileAccess.get_sha256(INDEX) == index_hash and FileAccess.get_sha256(ledger_path) == ledger_hash and FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd") == renderer_hash)
	var report := {"version": 1, "checks": _checks, "failures": _errors, "frames": frames,
		"index_sha256": index_hash, "renderer_sha256": renderer_hash, "runner_sha256": script_hash,
		"source_capture_manifest_sha256": pointer.sha256, "source_ledger_path": ledger_path,
		"source_ledger_sha256": ledger_hash, "requested_moves": requested, "clips": clips,
		"scope": "All-frame GPU capture, clock-index and cleanup checks. Human temporal sheets are samples, not watched realtime playback or mechanics/art approval."}
	var report_path := out + "result.json"
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("TEMPORAL_REVIEW ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " frames=", frames, " clips=", clips.size(), " output=", report_path, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
