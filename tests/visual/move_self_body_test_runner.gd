extends SceneTree

# Compare the pinned pre-fix renderer against the current one, using unchanged
# source clips. Body aliases are not additional battlers. Extra cels remain cels.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const BEFORE := "res://.godot/move_self_body_checks/reference/preview_before.gd"
const BEFORE_SHA := "9636af2c5cba04511e4dbb48c92411564bf64bf2e738695a39aabd5542f55334"
const INDEX := "res://.godot/move_batch_catalog/index.json"
const FOCAL := {"bulk_up": 7, "celebrate": 7, "copycat": 10, "dragon_dance": 20,
	"endure": 6, "fillet_away": 10, "laser_focus": 23, "lunar_dance": 9,
	"magnet_rise": 14, "meditate": 7, "minimize": 6, "moonlight": 10,
	"no_retreat": 10, "power_trick": 7, "quiver_dance": 3, "rage_powder": 13,
	"rock_polish": 12, "sharpen": 2, "slack_off": 8, "snatch": 4, "splash": 3,
	"tidy_up": 2, "victory_dance": 2, "work_up": 4, "barrier": 6, "detect": 7,
	"magic_coat": 7}
const CONTROLS := {"bide": 9, "double_team": 12, "nightmare": 12, "iron_defense": 5,
	"iron_tail": 4, "swallow": 15, "substitute": 5, "sunny_day": 8,
	"wish": 10, "teleport": 20, "baton_pass": 30}
var _checks := 0
var _errors: Array[String] = []
var _texture_proofs: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 30:
		_errors.append(label)

func _hash(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()

func _same(a: Sprite2D, b: Sprite2D) -> bool:
	# Each renderer loads its own ImageTextures; compare pixels once per pair,
	# rather than treating different resource instances as different artwork.
	var key := str(a.texture.get_rid()) + "/" + str(b.texture.get_rid())
	if not _texture_proofs.has(key):
		_texture_proofs[key] = _hash(a.texture.get_image()) == _hash(b.texture.get_image())
	return _texture_proofs[key] and a.region_rect == b.region_rect and a.transform.is_equal_approx(b.transform) and a.offset.is_equal_approx(b.offset) and a.flip_h == b.flip_h and a.z_index == b.z_index and a.material.shader.code == b.material.shader.code and a.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay") and a.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity")

func _run() -> void:
	_check("pinned before renderer", FileAccess.get_sha256(BEFORE) == BEFORE_SHA)
	if not _errors.is_empty():
		print("SELF_BODY FAIL preflight ", _errors)
		quit(1)
		return
	var old_script: GDScript = load(BEFORE)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_self_body_test_runner.gd")
	var gpu := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var out := "res://.godot/move_self_body_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
	DirAccess.make_dir_recursive_absolute(out)
	var viewports: Array[SubViewport] = []
	var previews: Array = []
	for script in [old_script, Preview]:
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var preview = script.new()
		viewport.add_child(preview)
		viewports.append(viewport)
		previews.append(preview)
	var self_clips := 0
	var frames := 0
	var samples: Array[Dictionary] = []
	var extras := 0
	var native_opponents := 0
	for shard: Dictionary in index.shards:
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard identity", FileAccess.get_sha256(path) == shard.sha256)
		for preview in previews:
			_check("load shard", preview.load_pack(path))
		for n in previews[1].pack.clips.size():
			var clip: Dictionary = previews[1].pack.clips[n]
			var own: bool = clip.target_scope == "user"
			if not own and not CONTROLS.has(clip.move_id):
				continue
			self_clips += int(own)
			native_opponents += int(own and clip.opponent_export)
			for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
				for k in 2:
					viewports[k].size = arena
					previews[k].size = Vector2(arena)
					_check("select", previews[k].select_clip(n))
				for f in clip.frames.size():
					frames += 1
					for preview in previews:
						_check("show", preview.show_frame(f))
					var base_count := 0
					for slot in clip.frames[f].size():
						var cel: Variant = clip.frames[f][slot]
						var a: Sprite2D = previews[0]._sprites[slot]
						var b: Sprite2D = previews[1]._sprites[slot]
						if own and slot < 2 and cel != null and cel[7] < 0:
							_check("no invented body/" + clip.id, not b.visible or a.visible)
						else:
							_check("visibility unchanged/" + clip.id, b.visible == a.visible)
						if b.visible:
							_check("source settings preserved/" + clip.id, _same(a, b))
							if slot < 2 and cel[7] < 0:
								base_count += 1
							if slot >= 2 and cel[7] < 0:
								extras += 1
					if own:
						_check("at most one primary self body/" + clip.id, base_count <= 1)
						if previews[0]._sprites[0].visible and previews[0]._sprites[1].visible:
							_check("one source body retained/" + clip.id, base_count == 1)
						var expected_slot := -1
						if FOCAL.has(clip.move_id) and f == int(FOCAL[clip.move_id]):
							expected_slot = 1 if clip.opponent_export or clip.move_id == "lunar_dance" else 0
						if clip.move_id == "bide" and f in [2, 9]:
							expected_slot = 0 if f == 2 else 1
						if expected_slot >= 0:
							_check("authored gesture retained/" + clip.id, previews[1]._sprites[expected_slot].visible and _same(previews[0]._sprites[expected_slot], previews[1]._sprites[expected_slot]) and not previews[1]._sprites[1 - expected_slot].visible)
					for layer: String in ["back", "front"]:
						var a: Sprite2D = previews[0]._layers[layer]
						var b: Sprite2D = previews[1]._layers[layer]
						_check("layers unchanged", a.visible == b.visible and (not b.visible or _same(a, b)))
					var selected := int(FOCAL.get(clip.move_id, CONTROLS.get(clip.move_id, -1)))
					if gpu and arena == Vector2i(640, 360) and f == selected:
						await process_frame
						RenderingServer.force_draw(false)
						var hashes: Array[String] = []
						var paths: Array[String] = []
						for k in 2:
							var image := viewports[k].get_texture().get_image()
							var name := String(clip.id).replace("/", "_") + ("_before.png" if k == 0 else "_after.png")
							_check("save comparison", image.save_png(out + name) == OK)
							hashes.append(_hash(image))
							paths.append(name)
						if not own:
							_check("nonself control GPU identical/" + clip.id, hashes[0] == hashes[1])
						samples.append({"id": clip.id, "move_id": clip.move_id, "title": clip.title, "side": clip.actor_side,
							"frame": f, "classification": clip.classification_unchanged, "self": own, "native_opponent": clip.opponent_export,
							"paths": paths, "pixels_sha256": hashes, "changed": hashes[0] != hashes[1]})
				for preview in previews:
					preview.effects_only = true
					preview.show_frame(0)
					for slot in clip.frames[0].size():
						var cel: Variant = clip.frames[0][slot]
						if cel != null and cel[7] < 0:
							_check("effects only still excludes bodies", not preview._sprites[slot].visible)
					preview.effects_only = false
					_check("end clears", not preview.show_frame(clip.frames.size()) and preview.visible_cells() == 0)
					preview.clear_preview()
					_check("explicit clear", preview.clip.is_empty() and preview.current_frame == -1)
	_check("all self sides", self_clips == 194 and native_opponents == 17)
	_check("extra cels actually exercised", extras > 0)
	_check("capture paired focal and controls", not gpu or samples.size() == (FOCAL.size() + CONTROLS.size()) * 2)
	_check("inputs stable", FileAccess.get_sha256(INDEX) == index_sha and FileAccess.get_sha256(BEFORE) == BEFORE_SHA and FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd") == renderer_sha)
	var result := {"version": 1, "gpu": gpu, "checks": _checks, "failures": _errors, "frames_checked": frames,
		"self_clips": self_clips, "native_opponents": native_opponents, "extra_body_instances_checked": extras,
		"index_sha256": index_sha, "renderer_before_sha256": BEFORE_SHA, "renderer_sha256": renderer_sha,
		"runner_sha256": runner_sha, "samples": samples, "scope": "Self body visibility repair, unchanged source clips; not battle/mechanics approval"}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("SELF_BODY ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " frames=", frames, " samples=", samples.size(), " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
