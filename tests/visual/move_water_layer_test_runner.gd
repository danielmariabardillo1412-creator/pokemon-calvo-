extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const BEFORE := "res://.godot/move_water_checks/reference/preview_before.gd"
const BEFORE_SHA := "d1861790b5291352cf21c4517158682a7254ea23e10736920917af021ea99e18"
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["hydro_vortex_physical", "hydro_vortex_special", "max_geyser", "surf", "sludge_wave"]
var _checks := 0
var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 20:
		_errors.append(label)

func _hash(image: Image) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(image.get_data())
	return h.finish().hex_encode()

func _same_sprite(a: Sprite2D, b: Sprite2D, primary: bool = false) -> bool:
	return a.visible == b.visible and (not a.visible or (a.transform == b.transform and a.offset == b.offset and a.region_rect == b.region_rect and a.flip_h == b.flip_h and a.z_index == b.z_index and a.texture_repeat == b.texture_repeat and a.texture.get_size() == b.texture.get_size() and (primary or a.material.shader.code == b.material.shader.code) and a.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay") and a.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity")))

func _run() -> void:
	_check("immutable before", FileAccess.get_sha256(BEFORE) == BEFORE_SHA)
	var gpu := DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args()
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_water_layer_test_runner.gd")
	var index_sha := FileAccess.get_sha256(INDEX)
	var out := "res://.godot/move_water_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
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
	var states := 0
	var clips := 0
	var removed_pixels := 0
	var retained_pixels := 0
	var changed_exports_rejected := 0
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
			var corrected: bool = String(clip.id) in Preview.HYDRO_PRIMARY_IDS
			_check("frames preserved", JSON.stringify(clip.frames) == JSON.stringify(stages[0].pack.clips[n].frames))
			_check("layers preserved", JSON.stringify(clip.layers) == JSON.stringify(stages[0].pack.clips[n].layers))
			_check("art preserved", clip.layer_sheets == stages[0].pack.clips[n].layer_sheets and clip.sheet == stages[0].pack.clips[n].sheet)
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
						for slot in 60:
							_check("body and particle unchanged", _same_sprite(stages[0]._sprites[slot], stages[1]._sprites[slot]))
						for layer in ["back", "front"]:
							_check("layer properties preserved", _same_sprite(stages[0]._layers[layer], stages[1]._layers[layer], corrected and layer == "front" and f < 12))
						if gpu and pair[0] == "ogerpon" and arena == Vector2i(640, 360):
							if f in [0, 3, 7, 12, 14, 20, 30, 40, clip.frames.size() - 1]:
								await process_frame
								RenderingServer.force_draw(false)
								var paths: Array[String] = []
								var hashes: Array[String] = []
								for k in 2:
									var image := views[k].get_texture().get_image()
									image.convert(Image.FORMAT_RGBA8)
									var name := String(clip.id).replace("/", "_") + "_%03d_" % f + ("before.png" if k == 0 else "after.png")
									_check("save", image.save_png(out + name) == OK)
									paths.append(name)
									hashes.append(_hash(image))
								if not corrected:
									_check("control GPU identical", hashes[0] == hashes[1])
								samples.append({"id": clip.id, "frame": f, "corrected": corrected, "paths": paths, "pixels_sha256": hashes})
							if corrected:
								for stage in stages:
									stage._arena.hide()
									stage._layers.back.hide()
									for sprite in stage._sprites:
										sprite.hide()
								await process_frame
								RenderingServer.force_draw(false)
								var a := views[0].get_texture().get_image()
								var b := views[1].get_texture().get_image()
								var gain := minf(arena.x / 512.0, arena.y / 384.0)
								for y in arena.y:
									var sy := fposmod((y + 0.5) / gain - float(clip.layers[f].front.bgY), 1151.0)
									if absf(sy - 524.0) < 2 or sy > 1149 or sy < 2:
										continue
									for x in range(0, arena.x, 4):
										if sy >= 524 and f < 12:
											_check("secondary strip transparent", b.get_pixel(x, y).a < 0.005)
											removed_pixels += int(a.get_pixel(x, y).a > 0.05)
										else:
											_check("primary crest unchanged", a.get_pixel(x, y).is_equal_approx(b.get_pixel(x, y)))
											retained_pixels += int(a.get_pixel(x, y).a > 0.05)
			if corrected:
				for field in ["frames", "layers"]:
					var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
					if field == "frames":
						bad.clips[n].frames[0][0][0] += 1
					else:
						bad.clips[n].layers[0].front.bgY += 1
					# Keep the fixture beside its sheets so rejection tests the
					# modified export, rather than failing early on missing PNGs.
					var rejected := path.get_base_dir() + "/water_rejection_fixture.json"
					var file := FileAccess.open(rejected, FileAccess.WRITE)
					file.store_string(JSON.stringify(bad))
					file.close()
					_check("changed export rejected", not stages[1].load_pack(rejected) and stages[1].last_error.contains("Export distinto"))
					changed_exports_rejected += 1
					_check("restore", stages[1].load_pack(path))
	_check("complete selection", clips == MOVES.size() * 2)
	_check("rejections", changed_exports_rejected == 6)
	_check("GPU removed secondary and retained crest", not gpu or (removed_pixels > 0 and retained_pixels > 0))
	_check("stable inputs", FileAccess.get_sha256(INDEX) == index_sha and FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd") == renderer_sha)
	var report := {"version": 1, "gpu": gpu, "checks": _checks, "failures": _errors, "clips": clips, "states": states, "samples": samples, "removed_sampled_pixels": removed_pixels, "retained_sampled_pixels": retained_pixels, "renderer_before_sha256": BEFORE_SHA, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "index_sha256": index_sha, "scope": "Pinned secondary strip suppression; original art/timelines retained; no mechanics or full motion approval"}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("WATER_LAYER_TEST ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", states, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
