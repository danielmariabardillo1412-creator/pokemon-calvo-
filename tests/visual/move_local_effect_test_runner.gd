extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const BEFORE := "res://.godot/move_local_effect_checks/reference/preview_before.gd"
const BEFORE_SHA := "c712c423db4a45d7287a2c658505e311b03267391b85c8f3b1674b436f0fe4ad"
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["acupressure", "aromatic_mist", "entrainment", "flatter"]
var _checks := 0
var _errors: Array[String] = []
var _bounds_cache: Dictionary = {}
var _tile_cache: Dictionary = {}

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

func _capture(view: SubViewport, path: String) -> Dictionary:
	var image := view.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	_check("save PNG", image.save_png(path) == OK)
	return {"path": path.get_file(), "sha256": FileAccess.get_sha256(path)}

func _run() -> void:
	_check("immutable reference", FileAccess.get_sha256(BEFORE) == BEFORE_SHA)
	var gpu := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_local_effect_test_runner.gd")
	var index_sha := FileAccess.get_sha256(INDEX)
	var out := "res://.godot/move_local_effect_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
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
	var samples: Array[Dictionary] = []
	var oracles: Array[Dictionary] = []
	var states := 0
	var clips := 0
	var old_clipped := 0
	var new_clipped := 0
	var rejected := 0
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in MOVES):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for stage in stages:
			_check("load", stage.load_pack(path))
		for n in stages[1].pack.clips.size():
			var clip: Dictionary = stages[1].pack.clips[n]
			if not String(clip.move_id) in MOVES:
				continue
			clips += 1
			var corrected: bool = not String(clip.get("_local_effect", "")).is_empty()
			_check("source preserved", JSON.stringify(clip.frames) == JSON.stringify(stages[0].pack.clips[n].frames) and JSON.stringify(clip.layers) == JSON.stringify(stages[0].pack.clips[n].layers) and clip.sheet == stages[0].pack.clips[n].sheet and clip.slot_sides == stages[0].pack.clips[n].slot_sides)
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["charizard", "ogerpon"]]:
				for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
					for k in 2:
						views[k].size = arena
						stages[k].size = Vector2(arena)
						stages[k].back_species = StringName(pair[0])
						stages[k].front_species = StringName(pair[1])
						_check("select", stages[k].select_clip(n))
					for f in clip.frames.size():
						states += 1
						for stage in stages:
							_check("frame", stage.show_frame(f))
						for slot in clip.frames[f].size():
							var a: Sprite2D = stages[0]._sprites[slot]
							var b: Sprite2D = stages[1]._sprites[slot]
							_check("visibility", a.visible == b.visible)
							if not b.visible:
								continue
							var cel: Array = clip.frames[f][slot]
							var descent: bool = corrected and clip.move_id == "entrainment" and cel[7] == -2 and cel[1] > 96
							_check("geometry retained", a.transform.x == b.transform.x and a.transform.y == b.transform.y and a.region_rect == b.region_rect and a.offset == b.offset and a.flip_h == b.flip_h and a.z_index == b.z_index and a.material.shader.code == b.material.shader.code)
							_check("position retained except bounded descent", a.position == b.position if not descent else a.position.x == b.position.x and b.position.y <= a.position.y)
							var tint_source: Sprite2D = stages[0]._sprites[1 - slot] if clip.move_id == "acupressure" and slot < 2 else a
							_check("correct recipient tint", tint_source.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and tint_source.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay") and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity"))
							_check("filter isolated", b.region_filter_clip_enabled == (clip.move_id == "flatter" and cel[7] >= 0))
							if corrected and clip.move_id == "entrainment" and cel[7] == -2:
								var before := _bounds(a)
								var after := _bounds(b)
								old_clipped += int(before.end.y > arena.y)
								new_clipped += int(after.end.y > arena.y)
								_check("recipient fits independent alpha bounds", after.end.y <= arena.y - 7.9)
						if gpu and pair[0] == "ogerpon":
							if f in [0, 8, 12, 20, 29, clip.frames.size() - 1]:
								await process_frame
								RenderingServer.force_draw(false)
								var captures: Array[Dictionary] = []
								for k in 2:
									var name := String(clip.id).replace("/", "_") + "_%d_%03d_" % [arena.x, f] + ("before.png" if k == 0 else "after.png")
									captures.append(_capture(views[k], out + name))
								if not corrected:
									_check("control screenshot identical", captures[0].sha256 == captures[1].sha256)
								samples.append({"id": clip.id, "arena": [arena.x, arena.y], "frame": f, "corrected": corrected, "captures": captures})
							if clip.move_id == "flatter":
								# Independent oracle: isolated source tiles have no neighboring
								# atlas texels. Do not use the new region-clip flag as oracle.
								for stage in stages:
									stage._arena.hide()
									for layer in stage._layers.values():
										layer.hide()
									for slot in clip.frames[f].size():
										var cel: Variant = clip.frames[f][slot]
										var sprite: Sprite2D = stage._sprites[slot]
										if cel != null and cel[7] < 0:
											sprite.hide()
								for sprite: Sprite2D in stages[0]._sprites:
									if not sprite.visible:
										continue
									var key := str(sprite.texture.get_instance_id()) + str(sprite.region_rect)
									if not _tile_cache.has(key):
										_tile_cache[key] = ImageTexture.create_from_image(sprite.texture.get_image().get_region(Rect2i(sprite.region_rect)))
									sprite.texture = _tile_cache[key]
									sprite.region_rect = Rect2(Vector2.ZERO, sprite.texture.get_size())
									sprite.region_filter_clip_enabled = false
								await process_frame
								RenderingServer.force_draw(false)
								var name := String(clip.id).replace("/", "_") + "_%d_%03d" % [arena.x, f]
								oracles.append({"id": clip.id, "arena": [arena.x, arena.y], "frame": f, "oracle": _capture(views[0], out + name + "_oracle.png"), "actual": _capture(views[1], out + name + "_actual.png")})
			if corrected:
				var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				bad.clips[n].frames[0][0][0] += 1
				var fixture := path.get_base_dir() + "/local_effect_rejection.json"
				var file := FileAccess.open(fixture, FileAccess.WRITE)
				file.store_string(JSON.stringify(bad))
				file.close()
				_check("modified export rejected", not stages[1].load_pack(fixture) and stages[1].last_error.contains("Export distinto"))
				rejected += 1
				_check("restore", stages[1].load_pack(path))
	_check("complete matrix", clips == 8 and states == 1800 and rejected == 5)
	_check("clipping reproduced and removed", old_clipped > 0 and new_clipped == 0)
	_check("complete GPU oracle", not gpu or oracles.size() == 96)
	var report := {"version": 1, "gpu": gpu, "checks": _checks, "failures": _errors, "states": states, "clips": clips, "samples": samples, "oracles": oracles, "old_clipped_states": old_clipped, "new_clipped_states": new_clipped, "renderer_before_sha256": BEFORE_SHA, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "index_sha256": index_sha, "scope": "Local presentation fixes; cropped-tile oracle must also pass Python pixel gate; no mechanics or full-motion approval"}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("LOCAL_EFFECT_TEST ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", states, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
