extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const Lab = preload("res://scenes/visual/move_resource_lab.tscn")
const BEFORE := "res://.godot/move_art_motif_checks/reference/preview_before.gd"
const BEFORE_SHA := "d934d0ccf43b955c1a055e2415bbd54e01ec4b8d56ed4eb9b8c08e792d6ef3a9"
const INDEX := "res://.godot/move_batch_catalog/index.json"
const FOCAL := ["behemoth_bash", "catastropika"]
const CONTROLS := ["behemoth_blade", "thunderbolt"]
var _checks := 0
var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 20:
		_errors.append(label)

func _appearance(a: Sprite2D, b: Sprite2D) -> bool:
	return a.transform.is_equal_approx(b.transform) and a.offset == b.offset and a.flip_h == b.flip_h and a.z_index == b.z_index and a.texture.get_size() == b.texture.get_size() and a.material.shader.code == b.material.shader.code and a.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and a.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay") and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity")

func _run() -> void:
	_check("immutable before", FileAccess.get_sha256(BEFORE) == BEFORE_SHA)
	var gpu := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_art_motif_test_runner.gd")
	var out := "res://.godot/move_art_motif_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
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
	var samples: Array[Dictionary] = []
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var states := 0
	var clips := 0
	var replaced := 0
	var omitted := 0
	var rejected := 0
	var effect_frames: Dictionary = {}
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in FOCAL or String(e.move_id) in CONTROLS):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for stage in stages:
			_check("load", stage.load_pack(path))
		for n in stages[1].pack.clips.size():
			var clip: Dictionary = stages[1].pack.clips[n]
			if not String(clip.move_id) in FOCAL and not String(clip.move_id) in CONTROLS:
				continue
			clips += 1
			var art: bool = String(clip.move_id) in FOCAL
			_check("source arrays preserved", JSON.stringify(clip.frames) == JSON.stringify(stages[0].pack.clips[n].frames) and JSON.stringify(clip.layers) == JSON.stringify(stages[0].pack.clips[n].layers) and clip.sheet == stages[0].pack.clips[n].sheet and clip.slot_sides == stages[0].pack.clips[n].slot_sides and clip.classification_unchanged == stages[0].pack.clips[n].classification_unchanged)
			if art:
				_check("explicit partial choice", clip.visual_art_choice.kind == "partial_motif_only" and not clip.visual_art_choice.mechanics_enabled and not clip.visual_art_choice.native_source_repaired)
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["charizard", "ogerpon"]]:
				for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
					for k in 2:
						views[k].size = arena
						stages[k].size = Vector2(arena)
						stages[k].back_species = StringName(pair[0])
						stages[k].front_species = StringName(pair[1])
						_check("select", stages[k].select_clip(n))
					var visible_effect_frames := 0
					for f in clip.frames.size():
						states += 1
						for stage in stages:
							_check("frame", stage.show_frame(f))
						var effects := false
						for slot in clip.frames[f].size():
							var cel: Variant = clip.frames[f][slot]
							var a: Sprite2D = stages[0]._sprites[slot]
							var b: Sprite2D = stages[1]._sprites[slot]
							var badge: bool = cel != null and clip.move_id == "catastropika" and int(cel[7]) in [10, 11, 12]
							_check("only badge visibility removed", b.visible == (a.visible and not badge))
							if badge and a.visible:
								omitted += 1
							if not b.visible:
								continue
							_check("appearance and choreography preserved", _appearance(a, b))
							if clip.move_id == "behemoth_bash" and cel[7] == 8:
								_check("neutral tile9 only", b.region_rect == Rect2(768, 192, 192, 192) and b.region_filter_clip_enabled)
								replaced += 1
							else:
								_check("other tiles identical", a.region_rect == b.region_rect and a.region_filter_clip_enabled == b.region_filter_clip_enabled)
							effects = effects or cel[7] >= 0
						for layer in ["back", "front"]:
							var a: Sprite2D = stages[0]._layers[layer]
							var b: Sprite2D = stages[1]._layers[layer]
							_check("layers unchanged", a.visible == b.visible and (not b.visible or _appearance(a, b) and a.region_rect == b.region_rect))
							effects = effects or b.visible
						visible_effect_frames += int(effects)
						var sampled: bool = f in [0, 4, 7, 14, 20, 28, 40, clip.frames.size() - 1] if art else f in [0, 10, clip.frames.size() - 1]
						if gpu and pair[0] == "ogerpon" and sampled:
							await process_frame
							RenderingServer.force_draw(false)
							var captures: Array[Dictionary] = []
							for k in 2:
								var image := views[k].get_texture().get_image()
								image.convert(Image.FORMAT_RGBA8)
								var name := String(clip.id).replace("/", "_") + "_%d_%03d_" % [arena.x, f] + ("before.png" if k == 0 else "after.png")
								_check("save", image.save_png(out + name) == OK)
								captures.append({"path": name, "sha256": FileAccess.get_sha256(out + name)})
							if not art:
								_check("control PNG identical", captures[0].sha256 == captures[1].sha256)
							samples.append({"id": clip.id, "arena": [arena.x, arena.y], "frame": f, "art_choice": art, "captures": captures})
					if art:
						_check("not an empty or one-frame replacement", visible_effect_frames >= 30)
						effect_frames[String(clip.id) + str(arena) + str(pair)] = visible_effect_frames
					for stage in stages:
						_check("end clear", not stage.show_frame(clip.frames.size()) and stage.visible_cells() == 0)
			if art:
				var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				bad.clips[n].frames[0][0][0] += 1
				var fixture := path.get_base_dir() + "/art_motif_rejection.json"
				var file := FileAccess.open(fixture, FileAccess.WRITE)
				file.store_string(JSON.stringify(bad))
				file.close()
				_check("changed export rejected", not stages[1].load_pack(fixture) and stages[1].last_error.contains("Export distinto"))
				rejected += 1
				_check("restore", stages[1].load_pack(path))
	_check("complete matrix", clips == 8 and states == 2136 and rejected == 4)
	_check("source changes bounded and exercised", replaced > 0 and omitted > 0)
	_check("GPU samples complete", not gpu or samples.size() == 88)
	var lab := Lab.instantiate() as Control
	root.add_child(lab)
	lab._playing = false
	lab._load_catalog(true)
	for move: String in FOCAL:
		lab._filter(move)
		_check("both choices visible", lab._choices.item_count == 2)
		for side in 2:
			lab._select(side)
			lab._update_status()
			_check("partial artistic UI label", lab._status.text.contains("EQUIVALENTE ARTÍSTICO EXPLÍCITO") and lab._status.text.contains("PARCIAL"))
	var report := {"version": 1, "gpu": gpu, "checks": _checks, "failures": _errors, "states": states, "clips": clips, "samples": samples, "replaced_cells": replaced, "omitted_cells": omitted, "effect_frames": effect_frames, "renderer_before_sha256": BEFORE_SHA, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "index_sha256": index_sha, "scope": "Explicit partial motif choices, not source repair or mechanics; source arrays/atlas/control moves preserved."}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("ART_MOTIF_TEST ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", states, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
