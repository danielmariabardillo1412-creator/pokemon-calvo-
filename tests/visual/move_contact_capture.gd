extends SceneTree

# Screenshot evidence only. No battle routes, mechanics or asset pixels changed.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const AUDIT := "res://.godot/move_batch_checks/gpu_result.json"
const OUTPUT := "res://.godot/move_contact_review/"
var _rows: Array[Dictionary] = []
var _errors: Array[String] = []
var _generation := ""
var _index_hash := ""
var _renderer_hash := ""
var _script_hash := ""
var _audit_hash := ""


func _initialize() -> void:
	call_deferred("_test_sampling" if "--self-test" in OS.get_cmdline_user_args() else "_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("GPU required; refusing dummy screenshots")
		return
	_index_hash = FileAccess.get_sha256(INDEX)
	_renderer_hash = FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	_script_hash = FileAccess.get_sha256("res://tests/visual/move_contact_capture.gd")
	_audit_hash = FileAccess.get_sha256(AUDIT)
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var audit: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUDIT))
	if not index is Dictionary or not audit is Dictionary or audit.get("index_sha256") != _index_hash or not audit.get("gpu", false) or not audit.get("failures", ["missing"]).is_empty() or audit.get("clips", []).size() != int(index.get("converted_clips", -1)):
		_fail("Missing, stale or failed technical sweep; capture is not an audit substitute")
		return
	_generation = (_index_hash + _renderer_hash + _script_hash + _audit_hash).sha256_text().substr(0, 16)
	var directory := OUTPUT + _generation + "/strips/"
	DirAccess.make_dir_recursive_absolute(directory)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview := Preview.new()
	preview.size = Vector2(640, 360)
	viewport.add_child(preview)
	for shard: Dictionary in index.shards:
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		if FileAccess.get_sha256(path) != shard.sha256 or not preview.load_pack(path):
			_fail("Invalid shard: " + path + " " + preview.last_error)
			return
		for clip_index in preview.pack.clips.size():
			preview.select_clip(clip_index)
			var clip: Dictionary = preview.clip
			var selection := _sample_frames(clip)
			var strip := Image.create(1920, 360, false, Image.FORMAT_RGBA8)
			var hashes: Dictionary = {}
			var samples: Array[Dictionary] = []
			for slot in 3:
				var frame: int = selection.frames[slot]
				if not preview.show_frame(frame):
					_fail("Cannot show " + String(clip.id))
					return
				await process_frame
				RenderingServer.force_draw(false)
				var image := viewport.get_texture().get_image()
				if image.get_size() != Vector2i(640, 360):
					_fail("Screenshot dimensions")
					return
				image.convert(Image.FORMAT_RGBA8)
				var context := HashingContext.new()
				context.start(HashingContext.HASH_SHA256)
				context.update(image.get_data())
				var digest := context.finish().hex_encode()
				hashes[digest] = true
				samples.append({"frame": frame, "seconds": frame / 20.0, "pixels_sha256": digest})
				strip.blit_rect(image, Rect2i(0, 0, 640, 360), Vector2i(slot * 640, 0))
			var filename := String(clip.id).replace("/", "_") + ".png"
			if strip.save_png(directory + filename) != OK:
				_fail("Cannot save screenshot strip")
				return
			_rows.append({"id": clip.id, "family": String(clip.id).get_base_dir(), "move_id": clip.move_id,
				"title": clip.title, "side": clip.actor_side, "total_frames": clip.frames.size(),
				"source_unique_states": selection.unique_states, "samples": samples, "distinct_gpu_samples": hashes.size(),
				"path": "strips/" + filename, "sha256": FileAccess.get_sha256(directory + filename),
				"source_manifest_sha256": shard.sha256})
		print("MOVE_CONTACT_SHARD ", shard.path, " strips=", _rows.size())
		await process_frame
	if _rows.size() != int(index.converted_clips) or FileAccess.get_sha256(INDEX) != _index_hash or FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd") != _renderer_hash:
		_fail("Evidence changed during capture or clips missing")
		return
	for path: String in index.canonical_hashes_unchanged:
		if FileAccess.get_sha256(path) != index.canonical_hashes_unchanged[path]:
			_fail("Canonical data changed")
			return
	var manifest := {"version": 1, "generation": _generation, "index_sha256": _index_hash,
		"audit_sha256": _audit_hash, "renderer_sha256": _renderer_hash, "capture_script_sha256": _script_hash,
		"scope": "Sampled static screenshots; not full motion or aesthetic approval", "clips": _rows}
	var path := OUTPUT + _generation + "/captures.json"
	_write(path, manifest)
	_write(OUTPUT + "latest.json", {"path": _generation + "/captures.json", "sha256": FileAccess.get_sha256(path)})
	preview.queue_free()
	viewport.queue_free()
	await process_frame
	print("MOVE_CONTACT_CAPTURE PASS clips=", _rows.size(), " screenshots=", _rows.size() * 3, " generation=", _generation)
	quit(0)


func _sample_frames(clip: Dictionary) -> Dictionary:
	# Sample distinct VISIBLE source states, not clock percentages that might all
	# land on idle padding around a short effect. Still a sample, not a movie.
	var seen: Dictionary = {}
	var unique: Array[int] = []
	var peak := -1
	var peak_frame := 0
	for frame_index in clip.frames.size():
		var visible: Array = []
		var particles := 0
		for slot in clip.frames[frame_index].size():
			var cel: Variant = clip.frames[frame_index][slot]
			if cel != null and int(cel[6]) == 1 and float(cel[8]) > 0:
				visible.append([slot, cel])
				particles += int(int(cel[7]) >= 0)
		var signature := JSON.stringify([visible, clip.layers[frame_index]])
		if not seen.has(signature):
			seen[signature] = true
			unique.append(frame_index)
		if particles > peak:
			peak = particles
			peak_frame = frame_index
	var frames: Array[int]
	if unique.size() <= 3:
		# Floor(percentile) picked state zero three times for two-state effects.
		# Cover every available state; duplicate only when fewer than three exist.
		frames.assign(unique)
		while frames.size() < 3:
			frames.append(unique.back())
	else:
		frames.assign([unique[int((unique.size() - 1) * 0.2)], unique[int((unique.size() - 1) * 0.5)], unique[int((unique.size() - 1) * 0.8)]])
	if peak > 0 and not peak_frame in frames:
		frames[1] = peak_frame
	frames.sort()
	return {"frames": frames, "unique_states": unique.size()}


func _test_sampling() -> void:
	var passed := 0
	for states in [1, 2, 3, 100]:
		var test_clip := {"frames": [], "layers": []}
		for frame in states:
			test_clip.frames.append([[frame, 0, 100, 0, 0, 0, 1, 0, 255]])
			test_clip.layers.append({})
		var result := _sample_frames(test_clip)
		var distinct: Dictionary = {}
		for frame: int in result.frames:
			distinct[frame] = true
		if result.unique_states != states or result.frames.size() != 3 or distinct.size() != mini(states, 3):
			_fail("sampling state coverage: " + str(states))
			return
		passed += 1
	var brief := {"frames": [], "layers": []}
	for frame in 10:
		brief.frames.append([[frame, 0, 100, 0, 0, 0, int(frame == 8), 0, 255]])
		brief.layers.append({})
	var result := _sample_frames(brief)
	if result.unique_states != 2 or not 8 in result.frames:
		_fail("brief visible effect missing from samples")
		return
	passed += 1
	print("MOVE_CONTACT_SAMPLING PASS checks=", passed)
	quit(0)


func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _fail(message: String) -> void:
	printerr("MOVE_CONTACT_CAPTURE FAIL: ", message)
	quit(1)
