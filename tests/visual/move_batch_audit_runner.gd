extends SceneTree

# Exhaustive frame/side/arena sweep; aesthetic warnings are not mechanical approval.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const OUTPUT := "res://.godot/move_batch_checks/"
var _checks := 0
var _frames := 0
var _failures: Array[String] = []
var _rows: Array[Dictionary] = []
var _captures := 0
var _gpu := false
var _index_hash := ""
var _alpha_bounds: Dictionary = {}
var _sheet_images: Dictionary = {}
var _viewport: SubViewport


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _failures.size() < 100:
		_failures.append(label)


func _run() -> void:
	_gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	_index_hash = FileAccess.get_sha256(INDEX)
	DirAccess.make_dir_recursive_absolute(OUTPUT + "captures")
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	_check("batch index", index is Dictionary and index.get("version") == 1)
	if not index is Dictionary:
		_finish()
		return
	var seen: Dictionary = {}
	_viewport = SubViewport.new()
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	var preview := Preview.new()
	_viewport.add_child(preview)
	_test_rejections(preview, index)
	for shard: Dictionary in index.shards:
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("manifest hash/" + path, FileAccess.get_sha256(path) == shard.sha256)
		if not preview.load_pack(path):
			_check("load/" + path + "/" + preview.last_error, false)
			continue
		_check("bounded count/" + path, preview.pack.clips.size() == int(shard.clips) and int(shard.clips) <= 64)
		_alpha_bounds.clear()
		_sheet_images.clear()
		for clip_index in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[clip_index]
			var id := String(clip.id)
			_check("unique/" + id, not seen.has(id))
			seen[id] = true
			var result: Dictionary = {"id": id, "source_flags": clip.get("audit_flags", []), "warnings": [], "arenas": [], "battle_approved": false}
			for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
				_viewport.size = arena
				preview.size = Vector2(arena)
				_check("select/" + id, preview.select_clip(clip_index))
				var effect_frames := 0
				var onscreen_frames := 0
				var clipped_frames := 0
				var peak := -1
				var peak_frame := 0
				for frame_index in clip.frames.size():
					_frames += 1
					_check("show/" + id, preview.show_frame(frame_index))
					var expected := 0
					var effects := 0
					var onscreen := false
					var clipped := false
					for slot in clip.frames[frame_index].size():
						var cel: Variant = clip.frames[frame_index][slot]
						var visible: bool = cel != null and int(cel[6]) == 1 and float(cel[8]) > 0
						if visible and clip.get("_motif_policy", "") == "electric_without_badge" and int(cel[7]) in [10, 11, 12]:
							visible = false
						if visible and String(clip.get("_z_particle_choice", "")) in ["savage_spin_out_physical", "savage_spin_out_special"] and int(cel[7]) in [6, 7, 8, 9, 23, 24, 25, 26]:
							visible = false
						if visible and cel[7] < 0 and clip.target_scope == "user" and slot < 2 and slot != preview._self_body_slot(clip.frames[frame_index]):
							visible = false
						var sprite: Sprite2D = preview._sprites[slot]
						_check("visibility/" + id, sprite.visible == visible)
						if not visible:
							continue
						expected += 1
						_check("finite/" + id, sprite.position.is_finite() and sprite.scale.is_finite() and is_finite(sprite.rotation))
						_check("texture/" + id, sprite.texture != null)
						var focus := 2 if cel[7] >= 0 and cel[26] == 1 and clip.get("_native_target_anchor", false) else int(cel[26])
						if clip.get("_general_pose", "") == "clanging_scales" and slot == 1 and cel[7] == -2:
							focus = 1
						if focus == 1:
							if clip.get("_native_projection", "") == "field_body" and slot == 0 and cel[7] == -1:
								focus = 2
							elif clip.get("_native_projection", "") == "shadow_path" and cel[7] >= 0:
								focus = 3 if cel[7] == 0 else 2
						var expected_position := preview.map_position(Vector2(cel[0], cel[1]), focus)
						if clip.get("_dash_user_path", false):
							if cel[7] == (-2 if clip.opponent_export else -1):
								focus = 3
							elif clip.id == "take_down/front" and cel[7] >= 0 and focus == 1:
								focus = 2
							expected_position = preview.map_position(Vector2(cel[0], cel[1]), focus)
						if clip.get("_local_effect", "") == "entrainment" and cel[7] == -2:
							var actor: Dictionary = preview._actors[clip.slot_sides[1]]
							var delta := expected_position.y - float(actor.center.y)
							if delta > 0:
								var room := maxf(0, arena.y - 8.0 - float(actor.center.y) - float(actor.half_height))
								expected_position.y = float(actor.center.y) + delta * clampf(room / (80.0 * minf(arena.x / 512.0, arena.y / 384.0)), 0, 1)
						if cel[7] >= 0 and focus == 3 and clip.get("_beam_target_source_x", 0.0) > 0.0:
							var rear_x := float(preview._actors[clip.slot_sides[0]].center.x)
							var front_x := float(preview._actors[clip.slot_sides[1]].center.x)
							expected_position.x = rear_x + (float(cel[0]) - 176.0) / 208.0 * (front_x - rear_x)
						if clip.get("_general_pose", "") == "court_change" and slot < 2 and cel[7] < 0:
							var home := Vector2(preview._actors[clip.slot_sides[0 if cel[7] == -1 else 1]].center)
							var fraction := clampf(float(frame_index - 13) / float(clip.frames.size() - 14), 0.0, 1.0)
							var weight := fraction * fraction * (3.0 - 2.0 * fraction)
							expected_position = expected_position * (1.0 - weight) + home * weight
						if clip.get("_z_fit_leap", false) and slot == 0 and cel[0] > 384:
							var actor: Dictionary = preview._actors[clip.slot_sides[0]]
							var target := Vector2(preview._actors[clip.slot_sides[1]].center)
							var half := Vector2(actor.half_width, actor.half_height) * Vector2(cel[2], cel[11]).abs() / 100.0
							var lower := half + Vector2.ONE * 8.0
							var upper := Vector2(arena) - lower
							# Independent interval projection: preserve the source offset
							# from a feasible target anchor, then constrain that excursion.
							expected_position = (target.clamp(lower, upper) + expected_position - target).clamp(lower, upper)
						_check("camera/" + id, sprite.position.is_equal_approx(expected_position))
						if int(cel[7]) >= 0 and sprite.scale.x != 0 and sprite.scale.y != 0:
							var local_bounds := _particle_bounds(sprite, String(clip.sheet), int(cel[7]))
							if not local_bounds.has_area():
								continue
							effects += 1
							var bounds: Rect2 = sprite.transform * local_bounds
							var screen := Rect2(Vector2.ZERO, Vector2(arena))
							onscreen = onscreen or screen.intersects(bounds)
							clipped = clipped or not screen.encloses(bounds)
					_check("no stale cells/" + id, preview.visible_cells() == expected)
					if effects > peak:
						peak = effects
						peak_frame = frame_index
					effect_frames += int(effects > 0)
					onscreen_frames += int(onscreen)
					clipped_frames += int(clipped)
				var metrics := {"size": [arena.x, arena.y], "effect_frames": effect_frames, "onscreen_frames": onscreen_frames, "edge_crossing_frames": clipped_frames, "peak_frame": peak_frame}
				result.arenas.append(metrics)
				if effect_frames > 0 and onscreen_frames == 0:
					result.warnings.append("all_particle_bounds_offscreen/%s" % arena)
				if effect_frames > 0 and clipped_frames > effect_frames * 0.8:
					result.warnings.append("frequent_edge_crossing_review/%s" % arena)
				if _gpu:
					var hashes: Dictionary = {}
					var samples: Dictionary = {0: true, peak_frame: true, int(clip.frames.size() / 2): true, clip.frames.size() - 1: true}
					for sample: int in samples:
						preview.show_frame(sample)
						await process_frame
						# Explicit offscreen draw: no dependence on an exposed/non-minimized
						# desktop window emitting frame_post_draw while the user works.
						RenderingServer.force_draw(false)
						var image := _viewport.get_texture().get_image()
						_check("GPU dimensions/" + id, image.get_size() == arena)
						var context := HashingContext.new()
						context.start(HashingContext.HASH_SHA256)
						context.update(image.get_data())
						hashes[context.finish().hex_encode()] = true
						if arena.x == 640 and sample == peak_frame:
							var capture_path := OUTPUT + "captures/" + id.replace("/", "_") + ".png"
							_check("capture/" + id, image.save_png(capture_path) == OK)
							_captures += 1
					metrics["gpu_distinct_samples"] = hashes.size()
					if hashes.size() <= 1:
						result.warnings.append("unchanged_GPU_samples_review/%s" % arena)
				_check("end clears/" + id, not preview.show_frame(clip.frames.size()) and preview.visible_cells() == 0)
			_rows.append(result)
		print("MOVE_BATCH_SHARD ", shard.path, " clips=", _rows.size(), " frames=", _frames, " failures=", _failures.size())
		await process_frame
	_check("all indexed clips", seen.size() == int(index.converted_clips))
	for move: Dictionary in index.moves:
		for id: String in move.get("clip_ids", []):
			_check("indexed clip/" + id, seen.has(id))
	for path: String in index.canonical_hashes_unchanged:
		_check("canonical unchanged/" + path, FileAccess.get_sha256(path) == index.canonical_hashes_unchanged[path])
	_check("index stable throughout audit", FileAccess.get_sha256(INDEX) == _index_hash)
	var lab := load("res://scenes/visual/move_resource_lab.tscn").instantiate() as Control
	root.add_child(lab)
	lab._playing = false
	_check("legacy lab preserved", lab._choices.item_count == 70)
	lab._filter("max_flutterby")
	_check("legacy Max reference is visibly historical", lab._status.text.contains("REFERENCIA HISTÓRICA"))
	lab._load_catalog(true)
	_check("batch lab all entries", lab._choices.item_count == int(index.converted_clips))
	lab._filter("flamethrower")
	_check("search both sides", lab._choices.item_count == 2 and lab.stage.clip.move_id == "flamethrower")
	lab._select(1)
	_check("search opponent", lab.stage.clip.actor_side == "front")
	lab._filter("yawn")
	_check("lazy shard switch", lab._choices.item_count == 2 and lab.stage.clip.move_id == "yawn")
	var equivalent_count := 0
	for move: Dictionary in index.moves:
		if move.get("mapping", "") != "explicit_visual_equivalent" or move.status != "converted_lab_only":
			continue
		_check("native gap retained/" + move.move_id, not move.get("native_gap_fixed", true) and not String(move.get("primary_source_issue", "")).is_empty())
		lab._filter(move.move_id)
		var selected := 0
		for n in lab._filtered.size():
			var entry: Dictionary = lab._entries[lab._filtered[n]]
			if entry.move_id != move.move_id:
				continue
			lab._select(n)
			lab._update_status()
			_check("equivalent visible label/" + entry.id, lab._status.text.contains("EQUIVALENTE VISUAL") and lab._status.text.contains("NO resuelto"))
			var meta: Dictionary = lab.stage.clip.get("visual_equivalent", {})
			_check("equivalent not mechanics/" + entry.id, meta.get("mechanics_enabled", true) == false and meta.get("native_gap_fixed", true) == false)
			lab.stage.clip.visual_equivalent = "malformed"
			lab._update_status()
			_check("malformed equivalent label safe/" + entry.id, lab._status.text.contains("INVÁLIDOS"))
			lab.stage.clip.visual_equivalent = meta
			lab._update_status()
			selected += 1
		_check("equivalent both sides/" + move.move_id, selected == 2)
		equivalent_count += 1
	_check("equivalent index count", equivalent_count == int(index.get("visual_equivalent_moves", 0)))
	var art_count := 0
	for move: Dictionary in index.moves:
		if move.get("mapping", "") != "reviewed_art_equivalent":
			continue
		lab._filter(move.move_id)
		_check("art pair offered", lab._choices.item_count == 2)
		for side in 2:
			lab._select(side)
			var art: Dictionary = lab.stage.clip.get("visual_art_choice", {})
			_check("explicit art label", lab._status.text.contains("EQUIVALENTE ARTÍSTICO EXPLÍCITO"))
			_check("art not native repair or mechanics", art.get("native_source_repaired", true) == false and art.get("mechanics_enabled", true) == false and art.get("replaced_source_status") == "renderable_but_art_rejected")
			lab.stage.clip.visual_art_choice = "malformed"
			lab._update_status()
			_check("invalid art metadata handled", lab._status.text.contains("ARTÍSTICOS INVÁLIDOS"))
			lab.stage.clip.visual_art_choice = art
		art_count += 1
	_check("art choices count", art_count == int(index.get("art_equivalent_moves", 0)))
	lab._filter("no_such_move_123456")
	_check("empty filter clears", lab.stage.clip.is_empty() and lab._choices.item_count == 0)
	lab.queue_free()
	preview.queue_free()
	_viewport.queue_free()
	await process_frame
	_finish()


func _particle_bounds(sprite: Sprite2D, sheet: String, pattern: int) -> Rect2:
	# A declared partial art choice can render a different tile without
	# changing the immutable source pattern number.
	var key := sheet + "/" + str(sprite.region_rect)
	if not _alpha_bounds.has(key):
		if not _sheet_images.has(sheet):
			_sheet_images[sheet] = sprite.texture.get_image()
		var image: Image = _sheet_images[sheet]
		_alpha_bounds[key] = image.get_region(Rect2i(sprite.region_rect)).get_used_rect()
	var used: Rect2i = _alpha_bounds[key]
	# Include the preserved crop pivot and ignore transparent sprite-sheet padding.
	return Rect2(sprite.get_rect().position + Vector2(used.position), Vector2(used.size))


func _test_rejections(preview: Control, index: Dictionary) -> void:
	var path := INDEX.get_base_dir().path_join(String(index.shards[0].path))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var fixture := source.duplicate(true)
	fixture.clips = fixture.clips.slice(0, 2)
	# Copy exact local dependencies into disposable fault-injection output only.
	for key: String in fixture.sheets:
		_check("fault fixture copy", DirAccess.copy_absolute(path.get_base_dir().path_join(key), OUTPUT + key) == OK)
	var fixture_path := OUTPUT + "fault_fixture.json"
	_write(fixture_path, fixture)
	_check("valid small batch accepted", preview.load_pack(fixture_path))
	for invalid: Variant in ["not_an_array", [-1], [0.5], ["0"], [true]]:
		var malformed := fixture.duplicate(true)
		malformed.clips[0].affine_particle_patterns = invalid
		_write(fixture_path, malformed)
		_check("invalid affine declaration rejected", not preview.load_pack(fixture_path))
	var mapped := fixture.duplicate(true)
	mapped.clips[1].mapped_opponent = true
	mapped.clips[1].opponent_export = false
	mapped.clips[1].slot_sides = ["front", "back"]
	mapped.clips[1].affine_particle_patterns = [0]
	_write(fixture_path, mapped)
	_check("mapped affine export rejected", not preview.load_pack(fixture_path))
	var wrong_focus := fixture.duplicate(true)
	var selected_patterns: Array[int] = []
	for frame: Array in wrong_focus.clips[0].frames:
		for cel: Variant in frame:
			if cel != null and cel[7] >= 0:
				selected_patterns.append(int(cel[7]))
				cel[26] = 2
	wrong_focus.clips[0].affine_particle_patterns = selected_patterns
	_write(fixture_path, wrong_focus)
	_check("wrong affine focus rejected", not selected_patterns.is_empty() and not preview.load_pack(fixture_path))
	var bad := fixture.duplicate(true)
	bad.clips[0].frames.resize(1)
	_write(fixture_path, bad)
	_check("one frame rejected", not preview.load_pack(fixture_path) and preview.pack.is_empty() and preview.textures.is_empty())
	bad = fixture.duplicate(true)
	bad.clips[1].id = bad.clips[0].id
	_write(fixture_path, bad)
	_check("duplicate id rejected", not preview.load_pack(fixture_path))
	bad = fixture.duplicate(true)
	bad.clips.resize(65)
	_write(fixture_path, bad)
	_check("overlarge batch rejected", not preview.load_pack(fixture_path))
	bad = fixture.duplicate(true)
	var key: String = bad.sheets.keys()[0]
	var missing := "0".repeat(64) + ".png"
	bad.sheets[missing] = bad.sheets[key].duplicate()
	bad.sheets[missing].sha256 = "0".repeat(64)
	bad.sheets.erase(key)
	_write(fixture_path, bad)
	_check("missing resource rejected", not preview.load_pack(fixture_path))
	# Keep the expected filename but corrupt bytes; loader must verify content.
	var file := FileAccess.open(OUTPUT + key, FileAccess.WRITE)
	file.store_string("deliberately not the pinned PNG")
	file.close()
	_write(fixture_path, fixture)
	_check("wrong hash rejected", not preview.load_pack(fixture_path))
	_check("restore disposable copy", DirAccess.copy_absolute(path.get_base_dir().path_join(key), OUTPUT + key) == OK)
	_check("recovery after rejection", preview.load_pack(fixture_path))
	preview.clear_preview()


func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _finish() -> void:
	var result := {"checks": _checks, "frames": _frames, "failures": _failures, "gpu": _gpu, "captures": _captures,
		"index_sha256": _index_hash, "runner_sha256": FileAccess.get_sha256("res://tests/visual/move_batch_audit_runner.gd"),
		"clips": _rows, "scope": "Technical sweep only; warnings require triage; not aesthetic/mechanical approval"}
	var file := FileAccess.open(OUTPUT + ("gpu_result.json" if _gpu else "headless_result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("MOVE_BATCH_AUDIT ", "PASS" if _failures.is_empty() else "FAIL", " checks=", _checks, " frames=", _frames, " clips=", _rows.size(), " captures=", _captures)
	for failure: String in _failures:
		printerr(failure)
	quit(0 if _failures.is_empty() else 1)
