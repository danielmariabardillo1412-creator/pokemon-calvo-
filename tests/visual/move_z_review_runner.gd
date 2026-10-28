extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const Before = preload("res://.godot/move_z_checks/reference/preview_before.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["extreme_evoboost", "genesis_supernova", "guardian_of_alola", "lets_snuggle_forever", "savage_spin_out_physical", "savage_spin_out_special", "soul_stealing_7_star_strike"]

class Candidate extends Before:
	func _actor(species: StringName, side: String) -> Dictionary:
		var actor := super._actor(species, side)
		var animation: Dictionary = Catalog.animation(species, side)
		var bounds := Catalog.presentation_bounds(species, side, animation)
		var placement := Layout.placement(size, side, bounds)
		actor["half_width"] = bounds.size.x * float(placement.gain) * 0.5
		return actor

	func show_frame(index: int) -> bool:
		if not super.show_frame(index):
			return false
		if clip.move_id == "soul_stealing_7_star_strike":
			var user: Variant = clip.frames[index][0]
			if user != null and _sprites[0].visible and user[0] > SOURCE_FRONT.x:
				var sprite: Sprite2D = _sprites[0]
				var actor: Dictionary = _actors[clip.slot_sides[0]]
				var target := Vector2(_actors[clip.slot_sides[1]].center)
				var delta := sprite.position - target
				var half := Vector2(actor.half_width, actor.half_height) * Vector2(user[2], user[11]).abs() / 100.0
				target = target.clamp(half + Vector2.ONE * 8.0, size - half - Vector2.ONE * 8.0)
				for axis in 2:
					var room: float = size[axis] - 8.0 - half[axis] - target[axis] if delta[axis] >= 0.0 else target[axis] - 8.0 - half[axis]
					if absf(delta[axis]) > 0.0:
						delta[axis] *= clampf(room / absf(delta[axis]), 0.0, 1.0)
				sprite.position = target + delta
		for slot in clip.frames[index].size():
			var cel: Variant = clip.frames[index][slot]
			if cel == null or not _sprites[slot].visible or cel[7] < 0:
				continue
			var pattern := int(cel[7])
			var replacement := -1
			if clip.move_id == "extreme_evoboost" and pattern in range(8):
				replacement = 9 + pattern % 4
			elif clip.move_id == "genesis_supernova" and pattern >= 35 and pattern <= 46:
				replacement = 31 + (pattern - 35) % 3
			elif clip.move_id == "lets_snuggle_forever" and pattern in [3, 4, 5, 21, 22, 23, 24, 25, 26]:
				replacement = 12
			elif String(clip.move_id).begins_with("savage_spin_out_") and pattern in [6, 7, 8, 9, 23, 24, 25, 26]:
				_sprites[slot].hide()
				continue
			if clip.move_id in ["extreme_evoboost", "genesis_supernova", "lets_snuggle_forever", "savage_spin_out_physical", "savage_spin_out_special"]:
				_sprites[slot].region_filter_clip_enabled = true
			if replacement >= 0:
				_sprites[slot].region_rect = Rect2((replacement % 5) * 192, (replacement / 5) * 192, 192, 192)
				_sprites[slot].region_filter_clip_enabled = true
		return true

var checks := 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok and errors.size() < 30:
		errors.append(label)

func _run() -> void:
	var gpu := DisplayServer.get_name() != "headless"
	var probe := "--probe" in OS.get_cmdline_user_args()
	check("immutable starting renderer", FileAccess.get_sha256("res://.godot/move_z_checks/reference/preview_before.gd") == "a9e655948ae20b50b2f2d8ee34b906f3729db6e29d0bb7b9a45b1a704aca9ce2")
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_z_review_runner.gd")
	var out := "res://.godot/move_z_checks/" + (index_sha + renderer_sha + runner_sha + str(probe)).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
	DirAccess.make_dir_recursive_absolute(out)
	var views: Array[SubViewport] = []
	var stages: Array = []
	for script in [Before, Candidate if probe else Preview]:
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
	var samples: Array = []
	var clips: Array = []
	var states := 0
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in MOVES):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for stage in stages:
			check("load source", stage.load_pack(path))
		for n in stages[0].pack.clips.size():
			var clip: Dictionary = stages[0].pack.clips[n]
			if not String(clip.move_id) in MOVES:
				continue
			var source := {"id": clip.id, "name": clip.name, "frames": clip.frames.size(), "frames_sha256": JSON.stringify(clip.frames).sha256_text(), "layers_sha256": JSON.stringify(clip.layers).sha256_text(), "sheet": clip.sheet, "opponent_export": clip.opponent_export, "mapped_opponent": clip.mapped_opponent}
			var diagnostic: Array = []
			for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
				for k in 2:
					views[k].size = arena
					stages[k].size = Vector2(arena)
					stages[k].back_species = &"ogerpon"
					stages[k].front_species = &"charizard"
					check("select", stages[k].select_clip(n))
				for f in clip.frames.size():
					states += 1
					for stage in stages:
						check("frame", stage.show_frame(f))
					var bodies: Array = []
					if arena.x == 640:
						for slot in clip.frames[f].size():
							var cel: Variant = clip.frames[f][slot]
							if cel != null and cel[7] < 0:
								var sprite: Sprite2D = stages[1]._sprites[slot]
								bodies.append({"slot": slot, "pattern": cel[7], "visible": sprite.visible, "position": [sprite.position.x, sprite.position.y], "scale": [sprite.scale.x, sprite.scale.y], "opacity": sprite.material.get_shader_parameter("opacity"), "source_xy": cel.slice(0, 2), "source_alpha": cel[8], "focus": cel[26]})
						diagnostic.append({"frame": f, "bodies": bodies})
					var sample := false
					for step in range(10):
						sample = sample or f == roundi(float(clip.frames.size() - 1) * step / 9.0)
					if gpu and sample:
						await process_frame
						RenderingServer.force_draw(false)
						var captures: Array = []
						for k in 2:
							var name := String(clip.id).replace("/", "_") + "_%d_%03d_%d.png" % [arena.x, f, k]
							var image := views[k].get_texture().get_image()
							image.convert(Image.FORMAT_RGBA8)
							check("save", image.save_png(out + name) == OK)
							captures.append({"path": name, "sha256": FileAccess.get_sha256(out + name)})
						samples.append({"id": clip.id, "arena": [arena.x, arena.y], "frame": f, "captures": captures})
				for stage in stages:
					check("end clear", not stage.show_frame(clip.frames.size()) and stage.visible_cells() == 0)
			clips.append({"source": source, "diagnostic": diagnostic})
	check("14 Z clips covered", clips.size() == 14 and states == 2724)
	var contract := _contract_matrix() if not probe else {}
	var report := {"version": 1, "probe": probe, "gpu": gpu, "checks": checks, "errors": errors, "states": states, "contract": contract, "clips": clips, "samples": samples, "index_sha256": index_sha, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "scope": "Visual evidence only. Z pool undecided; no mechanics or source edits."}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("Z_REVIEW ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " states=", states, " output=", out, " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _same_sprite(a: Sprite2D, b: Sprite2D) -> bool:
	if a.visible != b.visible:
		return false
	if not a.visible:
		return true
	return a.transform.is_equal_approx(b.transform) and a.region_rect == b.region_rect and a.region_filter_clip_enabled == b.region_filter_clip_enabled and a.offset == b.offset and a.flip_h == b.flip_h and a.z_index == b.z_index and a.texture.get_size() == b.texture.get_size() and a.material.shader.code == b.material.shader.code and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity") and a.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and a.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay")


func _contract_matrix() -> Dictionary:
	var controls := ["tackle", "thunderbolt", "behemoth_bash", "catastropika"]
	var stages: Array = []
	var views: Array[SubViewport] = []
	for script in [Before, Preview, Candidate]:
		var view := SubViewport.new()
		view.disable_3d = true
		root.add_child(view)
		var stage = script.new()
		view.add_child(stage)
		views.append(view)
		stages.append(stage)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var states := 0
	var bounded_leaps := 0
	var expected_leaps := 0
	var rejected := 0
	var effect_frames: Dictionary = {}
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in MOVES or String(e.move_id) in controls):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		for stage in stages:
			check("contract load", stage.load_pack(path))
		for n in stages[1].pack.clips.size():
			var clip: Dictionary = stages[1].pack.clips[n]
			if not String(clip.move_id) in MOVES and not String(clip.move_id) in controls:
				continue
			check("immutable arrays and art", JSON.stringify(clip.frames) == JSON.stringify(stages[0].pack.clips[n].frames) and JSON.stringify(clip.layers) == JSON.stringify(stages[0].pack.clips[n].layers) and clip.sheet == stages[0].pack.clips[n].sheet and clip.classification_unchanged == stages[0].pack.clips[n].classification_unchanged)
			if clip.move_id == "soul_stealing_7_star_strike":
				for frame: Array in clip.frames:
					var cel: Variant = frame[0]
					if cel != null and cel[0] > 384 and cel[6] == 1 and cel[8] > 0:
						expected_leaps += 5 * 2
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["wailord", "pikachu"], ["charizard", "ogerpon"], ["ogerpon", "wailord"]]:
				for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
					for k in 3:
						views[k].size = arena
						stages[k].size = Vector2(arena)
						stages[k].back_species = StringName(pair[0])
						stages[k].front_species = StringName(pair[1])
						check("contract select", stages[k].select_clip(n))
					var effects := 0
					for f in clip.frames.size():
						states += 1
						for stage in stages:
							check("contract frame", stage.show_frame(f))
						var has_effect := false
						for slot in clip.frames[f].size():
							var sprite: Sprite2D = stages[1]._sprites[slot]
							check("matches candidate %s f%d slot%d" % [clip.id, f, slot], _same_sprite(sprite, stages[2]._sprites[slot]))
							var cel: Variant = clip.frames[f][slot]
							if cel == null:
								continue
							if sprite.visible and cel[7] >= 0:
								has_effect = true
							if clip.move_id == "guardian_of_alola" or String(clip.move_id) in controls:
								check("reference/control unchanged", _same_sprite(sprite, stages[0]._sprites[slot]))
							if clip.move_id == "soul_stealing_7_star_strike" and slot == 0 and sprite.visible and cel[0] > 384:
								var actor: Dictionary = stages[1]._actors[clip.slot_sides[0]]
								var half := Vector2(actor.half_width, actor.half_height) * Vector2(cel[2], cel[11]).abs() / 100.0
								check("jump body stays inside arena", sprite.position.x - half.x >= 7.99 and sprite.position.y - half.y >= 7.99 and sprite.position.x + half.x <= arena.x - 7.99 and sprite.position.y + half.y <= arena.y - 7.99)
								bounded_leaps += 1
						for layer: String in ["back", "front"]:
							check("layers untouched", _same_sprite(stages[0]._layers[layer], stages[1]._layers[layer]))
							has_effect = has_effect or stages[1]._layers[layer].visible
						effects += int(has_effect)
					if String(clip.move_id) in MOVES:
						check("Z effect not empty/one frame", effects >= 20)
					effect_frames[String(clip.id)] = effects
					for stage in stages:
						check("contract end cleanup", not stage.show_frame(clip.frames.size()) and stage.visible_cells() == 0)
			if String(clip.move_id) in MOVES:
				var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				bad.clips[n].frames[0][0][0] += 1
				var fixture := path.get_base_dir() + "/z_rejection_fixture.json"
				var file := FileAccess.open(fixture, FileAccess.WRITE)
				file.store_string(JSON.stringify(bad))
				file.close()
				check("changed source rejected", not stages[1].load_pack(fixture) and stages[1].last_error.contains("Export distinto"))
				check("restore real source", stages[1].load_pack(path))
				rejected += 1
	check("all pinned sources rejected if changed", rejected == 14)
	check("all source leap poses in both directions and every body size", expected_leaps > 0 and bounded_leaps == expected_leaps)
	for view in views:
		view.queue_free()
	return {"states": states, "bounded_leap_frames": bounded_leaps, "expected_leap_frames": expected_leaps, "rejected_changed_exports": rejected, "effect_frames": effect_frames, "pairs": 5, "arenas": 2, "control_ids": controls}
