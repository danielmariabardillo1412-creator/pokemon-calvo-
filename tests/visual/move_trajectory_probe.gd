extends SceneTree

# Diagnostic comparison, not battle contact/damage or aesthetic approval.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["astral_barrage", "dynamax_cannon", "eternabeam", "moongeist_beam", "solar_blade", "oblivion_wing"]

class CanonicalPreview extends Preview:
	func _actor(species: StringName, side: String) -> Dictionary:
		var actor := super._actor(species, side)
		if not actor.is_empty():
			actor.center = Vector2(128, 224) if side == "back" else Vector2(384, 96)
		return actor

var _checks := 0
var _errors: Array[String] = []
var _texture_images: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 25:
		_errors.append(label)


func _coverage(image: Image, center: Vector2, radius: float) -> float:
	var covered := 0
	var count := 0
	for y in range(maxi(0, int(center.y - radius)), mini(image.get_height(), int(center.y + radius) + 1)):
		for x in range(maxi(0, int(center.x - radius)), mini(image.get_width(), int(center.x + radius) + 1)):
			if Vector2(x + 0.5, y + 0.5).distance_squared_to(center) <= radius * radius:
				count += 1
				covered += int(image.get_pixel(x, y).a > 0.05)
	return covered / float(maxi(count, 1))


func _capture(viewport: SubViewport) -> Image:
	await process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


func _body_overlap(sprite: Sprite2D, effects: Image, was_visible: bool) -> Dictionary:
	# Diagnostic overlap of rendered VFX with opaque pixels of the animated body.
	# This does NOT infer a hit, damage event, timing contract or mechanics support.
	var covered := 0
	var pixels := 0
	if sprite == null or not was_visible or absf(sprite.transform.determinant()) < 0.00001:
		return {"pixels": 0, "covered": 0, "fraction": 0.0}
	var key := sprite.texture.get_instance_id()
	if not _texture_images.has(key):
		_texture_images[key] = sprite.texture.get_image()
	var texture: Image = _texture_images[key]
	var rect := sprite.get_rect()
	var bounds: Rect2 = sprite.transform * rect
	var inverse := sprite.transform.affine_inverse()
	var region := sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, sprite.texture.get_size())
	for y in range(maxi(0, floori(bounds.position.y)), mini(effects.get_height(), ceili(bounds.end.y))):
		for x in range(maxi(0, floori(bounds.position.x)), mini(effects.get_width(), ceili(bounds.end.x))):
			var local := inverse * Vector2(x + 0.5, y + 0.5)
			if not rect.has_point(local):
				continue
			var uv := local - rect.position
			if sprite.flip_h:
				uv.x = region.size.x - uv.x
			if sprite.flip_v:
				uv.y = region.size.y - uv.y
			var tx := clampi(floori(region.position.x + uv.x), 0, texture.get_width() - 1)
			var ty := clampi(floori(region.position.y + uv.y), 0, texture.get_height() - 1)
			if texture.get_pixel(tx, ty).a > 0.05:
				pixels += 1
				covered += int(effects.get_pixel(x, y).a > 0.05)
	return {"pixels": pixels, "covered": covered, "fraction": covered / float(maxi(pixels, 1))}


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("TRAJECTORY_PROBE BLOCKED: GPU required")
		quit(1)
		return
	var index_hash := FileAccess.get_sha256(INDEX)
	var renderer_hash := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_hash := FileAccess.get_sha256("res://tests/visual/move_trajectory_probe.gd")
	var generation := (index_hash + renderer_hash + runner_hash).sha256_text().substr(0, 16)
	var out := "res://.godot/move_trajectory_checks/" + generation + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var solid := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	solid.fill(Color.WHITE)
	_check("opaque disk calibration", _coverage(solid, Vector2(16, 16), 8) == 1.0)
	solid.fill(Color.TRANSPARENT)
	_check("transparent disk calibration", _coverage(solid, Vector2(16, 16), 8) == 0.0)
	var mask_texture := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	mask_texture.fill(Color.WHITE)
	var mask_sprite := Sprite2D.new()
	mask_sprite.texture = ImageTexture.create_from_image(mask_texture)
	mask_sprite.position = Vector2(16, 16)
	solid.fill(Color.WHITE)
	_check("body overlap calibration", _body_overlap(mask_sprite, solid, true) == {"pixels": 64, "covered": 64, "fraction": 1.0})
	solid.fill(Color.TRANSPARENT)
	_check("body non-overlap calibration", _body_overlap(mask_sprite, solid, true).covered == 0)
	_check("invisible body calibration", _body_overlap(mask_sprite, solid, false).pixels == 0)
	mask_sprite.free()
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var clips: Array[Dictionary] = []
	var total_frames := 0
	for shard: Dictionary in index.shards:
		var relevant := false
		for entry: Dictionary in shard.entries:
			relevant = relevant or String(entry.move_id) in MOVES
		if not relevant:
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard hash", FileAccess.get_sha256(path) == shard.sha256)
		for mode: String in ["canonical_512", "adapted_640", "adapted_400"]:
			var viewport := SubViewport.new()
			viewport.disable_3d = true
			viewport.transparent_bg = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			viewport.size = Vector2i(512, 384) if mode == "canonical_512" else Vector2i(640, 360) if mode == "adapted_640" else Vector2i(400, 300)
			root.add_child(viewport)
			var preview: Control = CanonicalPreview.new() if mode == "canonical_512" else Preview.new()
			preview.size = Vector2(viewport.size)
			viewport.add_child(preview)
			_check("load pack", preview.load_pack(path))
			for clip_index in preview.pack.clips.size():
				var clip: Dictionary = preview.pack.clips[clip_index]
				if not String(clip.move_id) in MOVES:
					continue
				preview.select_clip(clip_index)
				var samples: Array[int] = []
				for percent in [0.3, 0.5, 0.75, 1.0]:
					samples.append(roundi((clip.frames.size() - 1) * percent))
				var target_side := "front" if clip.actor_side == "back" else "back"
				var rows: Array[Dictionary] = []
				var gain := minf(viewport.size.x / 512.0, viewport.size.y / 384.0)
				for f in clip.frames.size():
					preview.effects_only = false
					preview.show_frame(f)
					var body: Sprite2D = null
					for slot in clip.frames[f].size():
						var cel: Variant = clip.frames[f][slot]
						if cel != null and int(cel[7]) in [-1, -2] and clip.slot_sides[0 if cel[7] == -1 else 1] == target_side:
							body = preview._sprites[slot]
					var body_visible: bool = body != null and body.visible
					preview.effects_only = true
					_check("frame", preview.show_frame(f))
					var rear := Vector2(preview._actors[clip.slot_sides[0]].center)
					var forward := Vector2(preview._actors[clip.slot_sides[1]].center)
					var target := Vector2(preview._actors[target_side].center)
					for slot in clip.frames[f].size():
						var cel: Variant = clip.frames[f][slot]
						if cel == null or cel[7] < 0 or cel[6] != 1 or cel[8] <= 0:
							continue
						_check("source focus 3", int(cel[26]) == 3)
						var point := Vector2(cel[0], cel[1])
						var expected := rear + (point - Vector2(128, 224)) / Vector2(256, -128) * (forward - rear)
						_check("independent camera", preview._sprites[slot].position.distance_to(expected) < 0.001)
					var particles := await _capture(viewport)
					var coverage := _coverage(particles, target, 10 * gain)
					rows.append({"frame": f, "target_anchor_disk_coverage": coverage,
						"target_body_overlap": _body_overlap(body, particles, body_visible)})
					if f in samples:
						preview.effects_only = false
						preview.show_frame(f)
						var image := await _capture(viewport)
						var filename := String(clip.id).replace("/", "_") + "_%s_%03d.png" % [mode, f]
						_check("save", image.save_png(out + filename) == OK)
						rows[-1]["path"] = filename
						rows[-1]["sha256"] = FileAccess.get_sha256(out + filename)
					total_frames += 1
				# A one-frame blade crossing can fall between every percentile.
				# Capture its measured silhouette-overlap peak, not a guessed impact.
				var body_peak_frame := 0
				var body_peak := 0.0
				for row: Dictionary in rows:
					if float(row.target_body_overlap.fraction) > body_peak:
						body_peak = float(row.target_body_overlap.fraction)
						body_peak_frame = int(row.frame)
				if not rows[body_peak_frame].has("path"):
					preview.effects_only = false
					preview.show_frame(body_peak_frame)
					var image := await _capture(viewport)
					var filename := String(clip.id).replace("/", "_") + "_%s_%03d.png" % [mode, body_peak_frame]
					_check("save silhouette peak", image.save_png(out + filename) == OK)
					rows[body_peak_frame]["path"] = filename
					rows[body_peak_frame]["sha256"] = FileAccess.get_sha256(out + filename)
				clips.append({"id": clip.id, "title": clip.title, "source_name": clip.name, "mode": mode,
					"frames": rows, "sample_frames": samples, "body_peak_frame": body_peak_frame,
					"anchor_covered_frames": rows.filter(func(r: Dictionary) -> bool: return float(r.target_anchor_disk_coverage) > 0.1).size()})
				if clip.move_id == "moongeist_beam":
					var peak := 0.0
					for row: Dictionary in rows:
						peak = maxf(peak, float(row.target_anchor_disk_coverage))
					_check("ray retains target-anchor coverage", peak > 0.95 and int(clips[-1].anchor_covered_frames) >= 12)
			preview.queue_free()
			viewport.queue_free()
			await process_frame
		print("TRAJECTORY_SHARD ", shard.path, " variants=", clips.size())
	_check("all paired modes", clips.size() == MOVES.size() * 2 * 3)
	_check("inputs unchanged", FileAccess.get_sha256(INDEX) == index_hash and FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd") == renderer_hash)
	var report := {"version": 1, "checks": _checks, "failures": _errors, "frames": total_frames,
		"index_sha256": index_hash, "renderer_sha256": renderer_hash, "runner_sha256": runner_hash, "clips": clips,
		"scope": "Fixed canonical-slot reference versus adapted camera; anchor disk alpha is diagnostic, not real body contact, damage or motion/art approval. Mapped opponent reference is synthetic, not a native export."}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("TRAJECTORY_PROBE ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " frames=", total_frames, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
