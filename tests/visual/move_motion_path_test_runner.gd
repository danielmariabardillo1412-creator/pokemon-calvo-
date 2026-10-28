extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const BEFORE := "res://.godot/move_motion_path_checks/reference/preview_before.gd"
const BEFORE_SHA := "b7da766584d96b4a5d809738b7c68cdb9031f35a05faa828a37869a80e064505"
const INDEX := "res://.godot/move_batch_catalog/index.json"
const SAMPLES := {"rock_climb": [0, 13, 20, 22, 23, 24, 28, 33], "take_down": [0, 4, 8, 9, 10, 13, 14, 19], "storm_throw": [0, 15, 19, 20, 23, 25]}
class CanonicalPreview extends Preview:
	func _dash_visibility_weight(_index: int) -> float:
		return 1.0

	func _actor(species: StringName, side: String) -> Dictionary:
		var actor := super._actor(species, side)
		actor.center = Vector2(128, 224) if side == "back" else Vector2(384, 96)
		return actor
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

func _appearance(a: Sprite2D, b: Sprite2D) -> bool:
	return a.transform.x.is_equal_approx(b.transform.x) and a.transform.y.is_equal_approx(b.transform.y) and a.region_rect == b.region_rect and a.offset == b.offset and a.flip_h == b.flip_h and a.z_index == b.z_index and a.region_filter_clip_enabled == b.region_filter_clip_enabled and a.texture.get_size() == b.texture.get_size() and a.material.shader.code == b.material.shader.code and a.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and a.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay")

func _run() -> void:
	_check("immutable before", FileAccess.get_sha256(BEFORE) == BEFORE_SHA)
	var gpu := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_motion_path_test_runner.gd")
	var out := "res://.godot/move_motion_path_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
	DirAccess.make_dir_recursive_absolute(out)
	var views: Array[SubViewport] = []
	var stages: Array = []
	for script in [load(BEFORE), Preview]:
		var view := SubViewport.new()
		view.disable_3d = true
		view.transparent_bg = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var stage = script.new()
		view.add_child(stage)
		views.append(view)
		stages.append(stage)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var canonical := CanonicalPreview.new()
	canonical.size = Vector2(512, 384)
	root.add_child(canonical)
	var samples: Array[Dictionary] = []
	var endpoint_captures: Array[Dictionary] = []
	var wrap_comparisons: Array[Dictionary] = []
	var frames := 0
	var clips := 0
	var rejections := 0
	var old_wrap_visible := 0
	var new_wrap_visible := 0
	var large_wrap_visible := 0
	var hidden_wrap_endpoints := 0
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return SAMPLES.has(e.move_id)):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for stage in stages:
			_check("load", stage.load_pack(path))
		_check("canonical load", canonical.load_pack(path))
		for n in stages[1].pack.clips.size():
			var clip: Dictionary = stages[1].pack.clips[n]
			if not SAMPLES.has(clip.move_id):
				continue
			clips += 1
			var corrected: bool = clip.get("_dash_user_path", false)
			_check("source retained", JSON.stringify(clip.frames) == JSON.stringify(stages[0].pack.clips[n].frames) and JSON.stringify(clip.layers) == JSON.stringify(stages[0].pack.clips[n].layers) and clip.slot_sides == stages[0].pack.clips[n].slot_sides and clip.sheet == stages[0].pack.clips[n].sheet)
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["charizard", "ogerpon"], ["wailord", "pikachu"], ["charizard", "wailord"]]:
				canonical.back_species = StringName(pair[0])
				canonical.front_species = StringName(pair[1])
				_check("canonical select", canonical.select_clip(n))
				for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
					for k in 2:
						views[k].size = arena
						stages[k].size = Vector2(arena)
						stages[k].back_species = StringName(pair[0])
						stages[k].front_species = StringName(pair[1])
						_check("select", stages[k].select_clip(n))
					for f in clip.frames.size():
						frames += 1
						for stage in stages:
							_check("frame", stage.show_frame(f))
						for slot in clip.frames[f].size():
							var a: Sprite2D = stages[0]._sprites[slot]
							var b: Sprite2D = stages[1]._sprites[slot]
							_check("visibility flags unchanged", a.visible == b.visible)
							if not b.visible:
								continue
							var cel: Array = clip.frames[f][slot]
							_check("appearance unchanged", _appearance(a, b))
							var owner: bool = corrected and cel[7] == (-2 if clip.opponent_export else -1)
							var impact: bool = corrected and clip.id == "take_down/front" and cel[7] >= 0 and cel[26] == 1
							var alpha_weight := 1.0
							if owner:
								if clip.move_id == "rock_climb":
									alpha_weight = 0.0 if f >= 20 and f <= 24 else 0.5 if f in [19, 25] else 1.0
								else:
									alpha_weight = 0.0 if f >= 9 and f <= 13 else 0.5 if f in [8, 14] else 1.0
							_check("only wrap opacity changes", is_equal_approx(float(b.material.get_shader_parameter("opacity")), float(a.material.get_shader_parameter("opacity")) * alpha_weight))
							if owner:
								if f in ([23, 24] if clip.move_id == "rock_climb" else [9, 10]):
									_check("both discontinuity endpoints invisible for every pair", float(b.material.get_shader_parameter("opacity")) == 0.0)
									hidden_wrap_endpoints += 1
									if gpu:
										stages[1]._arena.hide()
										for layer in stages[1]._layers.values():
											layer.hide()
										for other: Sprite2D in stages[1]._sprites:
											if other != b:
												other.hide()
										await process_frame
										RenderingServer.force_draw(false)
										var image := views[1].get_texture().get_image()
										image.convert(Image.FORMAT_RGBA8)
										_check("GPU wrap body fully transparent", not image.get_used_rect().has_area())
										var name := String(clip.id).replace("/", "_") + "_%s_%s_%d_%03d_endpoint.png" % [pair[0], pair[1], arena.x, f]
										_check("save endpoint", image.save_png(out + name) == OK)
										endpoint_captures.append({"id": clip.id, "pair": pair, "arena": [arena.x, arena.y], "frame": f, "path": name, "sha256": FileAccess.get_sha256(out + name)})
										_check("restore after endpoint capture", stages[1].show_frame(f))
								var rear := Vector2(stages[1]._actors[clip.slot_sides[0]].center)
								var front := Vector2(stages[1]._actors[clip.slot_sides[1]].center)
								var expected := rear + (Vector2(cel[0], cel[1]) - Vector2(128, 224)) / Vector2(256, -128) * (front - rear)
								_check("independent source-line path", b.position.distance_to(expected) < 0.001)
								var wrap: bool = (clip.move_id == "rock_climb" and f in [20, 21, 22, 23]) or (clip.move_id == "take_down" and f in [8, 9, 10])
								if wrap:
									var screen := Rect2(Vector2.ZERO, Vector2(arena))
									var old_visible := screen.intersects(_bounds(a))
									var new_visible := screen.intersects(_bounds(b))
									if pair[0] == "ogerpon":
										old_wrap_visible += int(old_visible)
										new_wrap_visible += int(new_visible)
										_check("default source wrap completely offscreen", not new_visible)
									else:
										large_wrap_visible += int(new_visible)
									_check("canonical frame", canonical.show_frame(f))
									var source_body: Sprite2D = canonical._sprites[slot]
									_check("canonical preserves source point", source_body.position.distance_to(Vector2(cel[0], cel[1])) < 0.001)
									var source_bounds := _bounds(source_body)
									var actual_bounds := _bounds(b)
									var source_fraction := Rect2(0, 0, 512, 384).intersection(source_bounds).get_area() / maxf(1, source_bounds.get_area())
									var actual_fraction := screen.intersection(actual_bounds).get_area() / maxf(1, actual_bounds.get_area())
									wrap_comparisons.append({"id": clip.id, "pair": pair, "arena": [arena.x, arena.y], "frame": f, "source_bbox_fraction": source_fraction, "actual_bbox_fraction": actual_fraction})
							elif impact:
								var target := Vector2(stages[1]._actors.back.center)
								var expected := target + (Vector2(cel[0], cel[1]) - Vector2(128, 224)) * minf(arena.x / 512.0, arena.y / 384.0)
								_check("impact local to recipient", b.position.distance_to(expected) < 0.001)
							else:
								_check("other paths identical", a.position.is_equal_approx(b.position))
						if gpu and pair[0] == "ogerpon" and f in SAMPLES[clip.move_id]:
							await process_frame
							RenderingServer.force_draw(false)
							var captures: Array[Dictionary] = []
							for k in 2:
								var image := views[k].get_texture().get_image()
								image.convert(Image.FORMAT_RGBA8)
								var name := String(clip.id).replace("/", "_") + "_%d_%03d_" % [arena.x, f] + ("before.png" if k == 0 else "after.png")
								_check("save", image.save_png(out + name) == OK)
								captures.append({"path": name, "sha256": FileAccess.get_sha256(out + name)})
							if not corrected:
								_check("control GPU identical", captures[0].sha256 == captures[1].sha256)
							samples.append({"id": clip.id, "arena": [arena.x, arena.y], "frame": f, "corrected": corrected, "captures": captures})
					for stage in stages:
						_check("end cleared", not stage.show_frame(clip.frames.size()) and stage.visible_cells() == 0)
			if corrected:
				var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				bad.clips[n].frames[0][0][0] += 1
				var fixture := path.get_base_dir() + "/motion_path_rejection.json"
				var file := FileAccess.open(fixture, FileAccess.WRITE)
				file.store_string(JSON.stringify(bad))
				file.close()
				_check("changed export rejected", not stages[1].load_pack(fixture) and stages[1].last_error.contains("Export distinto"))
				rejections += 1
				_check("restore", stages[1].load_pack(path))
	_check("complete matrix", clips == 6 and frames == 1600 and rejections == 4)
	_check("wrap artifact reproduced and removed", old_wrap_visible > 0 and new_wrap_visible == 0)
	_check("all discontinuity endpoints checked", hidden_wrap_endpoints == 80)
	_check("complete GPU samples", not gpu or samples.size() == 88)
	var report := {"version": 1, "gpu": gpu, "checks": _checks, "failures": _errors, "states": frames, "clips": clips, "samples": samples, "endpoint_captures": endpoint_captures, "wrap_comparisons": wrap_comparisons, "old_default_wrap_visible": old_wrap_visible, "new_default_wrap_visible": new_wrap_visible, "other_pair_wrap_bbox_intersections": large_wrap_visible, "hidden_wrap_endpoints": hidden_wrap_endpoints, "renderer_before_sha256": BEFORE_SHA, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "index_sha256": index_sha, "scope": "Preserve authored exits and returns, with a bounded offscreen wrap fade for large sprites. Five pairs/two arenas, independent path oracle; no mechanics/full-motion approval."}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("MOTION_PATH_TEST ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", frames, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
