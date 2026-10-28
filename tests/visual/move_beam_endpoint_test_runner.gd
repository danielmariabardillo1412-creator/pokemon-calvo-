extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const BEFORE := "res://.godot/move_beam_endpoint_checks/reference/preview_before.gd"
const BEFORE_SHA := "81cb49e7e0b2594181ebec834f5fa3c58bbffa036e7fb02a0e13a3d31d10a074"
const INDEX := "res://.godot/move_batch_catalog/index.json"
const FOCAL := {"twin_beam": 19}
# These controls include the two reviewed native impacts and prior repairs.
const CONTROLS := {"dragon_pulse": 35, "glacial_lance": 18, "light_screen": 12,
	"shadow_sneak": 20, "wing_attack": 5, "pollen_puff": 19,
	"bulk_up": 7, "lunar_dance": 9, "double_team": 12}
var _checks := 0
var _errors: Array[String] = []
var _textures: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 25:
		_errors.append(label)

func _hash(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()

func _appearance(a: Sprite2D, b: Sprite2D) -> bool:
	var key := str(a.texture.get_rid()) + "/" + str(b.texture.get_rid())
	if not _textures.has(key):
		_textures[key] = _hash(a.texture.get_image()) == _hash(b.texture.get_image())
	return _textures[key] and a.region_rect == b.region_rect and a.transform.x.is_equal_approx(b.transform.x) and a.transform.y.is_equal_approx(b.transform.y) and a.offset.is_equal_approx(b.offset) and a.flip_h == b.flip_h and a.z_index == b.z_index and a.material.shader.code == b.material.shader.code and a.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay") and a.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity")

func _run() -> void:
	_check("immutable before", FileAccess.get_sha256(BEFORE) == BEFORE_SHA)
	if not _errors.is_empty():
		quit(1)
		return
	var before_script: Script = load(BEFORE)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_beam_endpoint_test_runner.gd")
	var gpu := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var out := "res://.godot/move_beam_endpoint_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
	DirAccess.make_dir_recursive_absolute(out)
	var views: Array[SubViewport] = []
	var stages: Array = []
	for script in [before_script, Preview]:
		var view := SubViewport.new()
		view.disable_3d = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var stage = script.new()
		view.add_child(stage)
		views.append(view)
		stages.append(stage)
	var samples: Array[Dictionary] = []
	var frames := 0
	var clips := 0
	var shifted := 0
	var rejection_tested := false
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return FOCAL.has(e.move_id) or CONTROLS.has(e.move_id)):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard proof", FileAccess.get_sha256(path) == shard.sha256)
		for stage in stages:
			_check("load", stage.load_pack(path))
		for n in stages[1].pack.clips.size():
			var clip: Dictionary = stages[1].pack.clips[n]
			if not FOCAL.has(clip.move_id) and not CONTROLS.has(clip.move_id):
				continue
			clips += 1
			var corrected: bool = FOCAL.has(clip.move_id) and clip.actor_side == "front"
			var focal := int(FOCAL.get(clip.move_id, CONTROLS.get(clip.move_id, -1)))
			_check("all source frames preserved", JSON.stringify(clip.frames) == JSON.stringify(stages[0].pack.clips[n].frames))
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["charizard", "ogerpon"]]:
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
							_check("show", stage.show_frame(f))
						for slot in clip.frames[f].size():
							var cel: Variant = clip.frames[f][slot]
							var a: Sprite2D = stages[0]._sprites[slot]
							var b: Sprite2D = stages[1]._sprites[slot]
							_check("visibility unchanged", a.visible == b.visible)
							if not b.visible:
								continue
							_check("appearance unchanged", _appearance(a, b))
							if corrected and cel[7] >= 0 and cel[26] == 3:
								var rear: Vector2 = stages[1]._actors.back.center
								var forward: Vector2 = stages[1]._actors.front.center
								var expected_x := rear.x + (float(cel[0]) - 176.0) / 208.0 * (forward.x - rear.x)
								_check("source endpoint x176 reaches target", absf(b.position.x - expected_x) < 0.001 and is_equal_approx(b.position.y, a.position.y))
								_check("legacy offset reproduced", absf(a.position.x - expected_x) > 0.1)
								shifted += 1
							else:
								_check("other trajectories and bodies unchanged", a.position.is_equal_approx(b.position))
						for layer: String in ["back", "front"]:
							var a: Sprite2D = stages[0]._layers[layer]
							var b: Sprite2D = stages[1]._layers[layer]
							_check("layers unchanged", a.visible == b.visible and (not b.visible or (_appearance(a, b) and a.position.is_equal_approx(b.position))))
						if gpu and pair == ["ogerpon", "charizard"] and arena == Vector2i(640, 360) and f in [0, focal, clip.frames.size() - 1]:
							await process_frame
							RenderingServer.force_draw(false)
							var paths: Array[String] = []
							var pixels: Array[String] = []
							for k in 2:
								var image := views[k].get_texture().get_image()
								image.convert(Image.FORMAT_RGBA8)
								var name := String(clip.id).replace("/", "_") + "_%03d_" % f + ("before.png" if k == 0 else "after.png")
								_check("save", image.save_png(out + name) == OK)
								paths.append(name)
								pixels.append(_hash(image))
							if not corrected:
								_check("control GPU identical", pixels[0] == pixels[1])
							samples.append({"id": clip.id, "move_id": clip.move_id, "title": clip.title, "side": clip.actor_side, "frame": f, "focal": f == focal, "corrected": corrected, "paths": paths, "pixels_sha256": pixels, "classification": clip.classification_unchanged})
					for stage in stages:
						_check("end clears", not stage.show_frame(clip.frames.size()) and stage.visible_cells() == 0)
						stage.clear_preview()
			if corrected and not rejection_tested:
				var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				bad.clips[n].frames[0][0][0] += 1
				var rejected := path.get_base_dir() + "/anchor_rejection_fixture.json"
				var file := FileAccess.open(rejected, FileAccess.WRITE)
				file.store_string(JSON.stringify(bad))
				file.close()
				_check("changed export rejected", not stages[1].load_pack(rejected) and stages[1].last_error.contains("Export distinto"))
				rejection_tested = true
				_check("restore after rejection", stages[1].load_pack(path))
	_check("complete paired selection", clips == (FOCAL.size() + CONTROLS.size()) * 2)
	_check("actual source rejection", rejection_tested and shifted > 0)
	_check("all GPU samples", not gpu or samples.size() == clips * 3)
	_check("stable inputs", FileAccess.get_sha256(INDEX) == index_sha and FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd") == renderer_sha and FileAccess.get_sha256(BEFORE) == BEFORE_SHA)
	var result := {"version": 1, "gpu": gpu, "checks": _checks, "failures": _errors, "frames_checked": frames, "clips": clips, "shifted_cels_checked": shifted, "samples": samples, "index_sha256": index_sha, "renderer_before_sha256": BEFORE_SHA, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "scope": "Pinned Twin Beam endpoint x calibration; not battle mechanics or entire animation watched"}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("BEAM_ENDPOINT ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " frames=", frames, " samples=", samples.size(), " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
