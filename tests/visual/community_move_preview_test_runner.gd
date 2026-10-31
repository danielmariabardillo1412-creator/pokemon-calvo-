extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
var _passed := 0
var _failures: Array[String] = []
var _captures := 0
var _render_differences := 0
const OUTPUT := "res://.godot/community_move_checks/"
var _output := OUTPUT
const LENGTHS := {"ivy_cudgel": 38, "max_airstream": 70, "max_darkness": 53,
	"max_flare": 52, "max_flutterby": 98, "max_geyser": 51, "max_guard": 32,
	"max_hailstorm": 55, "max_knuckle": 43, "max_lightning": 50, "max_mindstorm": 60,
	"max_ooze": 60, "max_overgrowth": 46, "max_phantasm": 40, "max_quake": 97,
	"max_rockfall": 60, "max_starfall": 69, "max_steelspike": 120, "max_strike": 42, "max_wyrmwind": 62,
	"tera_blast": 70, "nature_power/neutral": 70, "nature_power/electric": 27,
	"nature_power/grassy": 45, "nature_power/misty": 60, "nature_power/psychic": 25,
	"secret_power/neutral": 15, "secret_power/electric": 20, "secret_power/grassy": 14,
	"secret_power/misty": 35, "secret_power/psychic": 29,
	"ivy_cudgel/fire": 38, "ivy_cudgel/rock": 38, "ivy_cudgel/water": 38, "hard_press": 27}
const IVY_PATTERNS := {"": [0, 4], "fire": [2, 6], "rock": [3, 7], "water": [1, 5]}
const CONTEXT_REFERENCES := {"nature_power/neutral": "TRIATTACK", "nature_power/electric": "THUNDERBOLT",
	"nature_power/grassy": "ENERGYBALL", "nature_power/misty": "MOONBLAST", "nature_power/psychic": "PSYCHIC",
	"secret_power/neutral": "BODYSLAM", "secret_power/electric": "THUNDERSHOCK", "secret_power/grassy": "VINEWHIP",
	"secret_power/misty": "FAIRYWIND", "secret_power/psychic": "CONFUSION"}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_output = OUTPUT + FileAccess.get_sha256(Preview.DEFAULT_PACK).substr(0, 12) + "/"
	DirAccess.make_dir_recursive_absolute(_output)
	var capture := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var preview := Preview.new()
	root.add_child(preview)
	_check("load_pack", preview.load_pack())
	if preview.pack.is_empty():
		_check(preview.last_error, false)
		_finish()
		return
	_check("seventy_clips", preview.pack.clips.size() == 70)
	var by_id: Dictionary = {}
	var native_opponents := 0
	var mapped_opponents := 0
	for index in preview.pack.clips.size():
		var row: Dictionary = preview.pack.clips[index]
		by_id[row.id] = index
		native_opponents += int(bool(row.opponent_export))
		mapped_opponents += int(bool(row.mapped_opponent))
	for move: String in LENGTHS:
		_check("paired/" + move, by_id.has(move + "/back") and by_id.has(move + "/front"))
	_check("native_opponent_count", native_opponents == 18)
	_check("mapped_opponent_count", mapped_opponents == 17)
	for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 225)]:
		root.size = arena
		root.content_scale_size = arena
		preview.size = Vector2(arena)
		for clip_index in preview.pack.clips.size():
			preview.back_species = &"ogerpon" if preview.pack.clips[clip_index].move_id == "ivy_cudgel" else &"charizard"
			preview.front_species = preview.back_species
			_check("select/%d" % clip_index, preview.select_clip(clip_index))
			var move := String(preview.clip.move_id)
			var family := String(preview.clip.id).get_base_dir()
			var expected_length: int = 78 if move == "max_starfall" and preview.clip.actor_side == "front" else int(LENGTHS.get(family, -1))
			_check("length/%d" % clip_index, preview.clip.frames.size() == expected_length)
			if move in ["nature_power", "secret_power"]:
				_check("context_is_reference/%d" % clip_index, preview.clip.visual_only_context and not String(preview.clip.context_key).is_empty())
				_check("context_mechanics_unchanged/%d" % clip_index, preview.clip.classification_unchanged == ("UNSUPPORTED" if move == "nature_power" else "PARTIAL_RUNTIME"))
				_check("context_reference/%d" % clip_index, preview.clip.reference_animation_id == CONTEXT_REFERENCES.get(family, ""))
			var expected_opponent: bool = preview.clip.actor_side == "front" and (String(preview.clip.name).begins_with("OppMove:") or move == "ivy_cudgel")
			if move == "tera_blast":
				_check("tera_normal_subset_not_full_tera/%d" % clip_index, preview.clip.classification_unchanged == "PARTIAL_RUNTIME" and preview.clip.reference_animation_id == "TECHNOBLAST")
			_check("opponent_export/%d" % clip_index, bool(preview.clip.opponent_export) == expected_opponent)
			if move == "ivy_cudgel":
				var variant := String(preview.clip.variant_key)
				_check("ivy_variant_known/%d" % clip_index, IVY_PATTERNS.has(variant))
				_check("ivy_native_views/%d" % clip_index, not preview.clip.mapped_opponent and String(preview.clip.source_export_file).ends_with("_Opp.anm") == (preview.clip.actor_side == "front"))
				_check("ivy_export_hash/%d" % clip_index, String(preview.clip.source_export_sha256).length() == 64)
				if not variant.is_empty():
					_check("ivy_variant_is_visual/%d" % clip_index, preview.clip.visual_only_variant and not preview.clip.visual_only_context)
			if move == "hard_press":
				_check("hard_press_unchanged/%d" % clip_index, preview.clip.classification_unchanged == "DATA_ONLY" and preview.clip.reference_animation_id == "HEAVYSLAM")
			var baseline := PackedByteArray()
			var rendered_changes := 0
			var samples := [0, expected_length / 4, expected_length / 2, expected_length * 3 / 4, expected_length - 1]
			for frame_index in preview.clip.frames.size():
				var label := "%d/%s/%d" % [clip_index, arena, frame_index]
				_check("show/" + label, preview.show_frame(frame_index))
				_check("frame/" + label, preview.current_frame == frame_index)
				var expected_visible := 0
				for slot in preview.clip.frames[frame_index].size():
					var cel: Variant = preview.clip.frames[frame_index][slot]
					var visible: bool = cel != null and int(cel[6]) == 1 and float(cel[8]) > 0.0
					if visible and cel[7] < 0 and preview.clip.target_scope == "user" and slot < 2 and slot != preview._self_body_slot(preview.clip.frames[frame_index]):
						visible = false
					var sprite: Sprite2D = preview._sprites[slot]
					_check("visibility/" + label + "/%d" % slot, sprite.visible == visible)
					if not visible:
						continue
					expected_visible += 1
					_check("position/" + label + "/%d" % slot, sprite.position.is_equal_approx(preview.map_position(Vector2(cel[0], cel[1]), int(cel[26]))))
					_check("rotation/" + label + "/%d" % slot, is_equal_approx(sprite.rotation, -deg_to_rad(float(cel[3])) * (-1.0 if preview.clip.mapped_opponent else 1.0)))
					var pattern := int(cel[7])
					_check("mirror/" + label + "/%d" % slot, sprite.flip_h == ((int(cel[4]) != 0) != (pattern >= 0 and bool(preview.clip.mapped_opponent))))
					_check("blend/" + label + "/%d" % slot, sprite.material.shader == preview._blend_shaders[int(cel[5])])
					if pattern >= 0:
						if move == "ivy_cudgel":
							_check("ivy_palette/" + label + "/%d" % slot, pattern in IVY_PATTERNS[preview.clip.variant_key])
							_check("ivy_preserves_source_ratio/" + label + "/%d" % slot, is_equal_approx(sprite.scale.x * float(cel[11]), sprite.scale.y * float(cel[2])))
						var full := Rect2((pattern % 5) * 192, floori(float(pattern) / 5.0) * 192, 192, 192)
						var available := full.intersection(Rect2(Vector2.ZERO, sprite.texture.get_size()))
						_check("region/" + label + "/%d" % slot, sprite.region_rect == available)
						_check("crop_keeps_pivot/" + label + "/%d" % slot, sprite.offset.is_equal_approx(available.get_center() - full.get_center()))
						if int(cel[26]) == 4:
							if pattern in preview.clip.get("uniform_screen_patterns", []):
								var gain := minf(preview.size.x / 512.0, preview.size.y / 384.0)
								_check("solid_shape_uniform/" + label + "/%d" % slot, sprite.scale.is_equal_approx(Vector2(float(cel[2]), float(cel[11])) * gain / 100.0))
								_check("cube_source_ratio/" + label + "/%d" % slot, is_equal_approx(sprite.scale.x / sprite.scale.y, float(cel[2]) / float(cel[11])) if sprite.scale.y != 0.0 else sprite.scale.x == 0.0)
							else:
								var camera := ((Vector2(preview._actors[preview.clip.slot_sides[1]].center) - Vector2(preview._actors[preview.clip.slot_sides[0]].center)) / Vector2(256, -128)).abs()
								_check("screen_cell_camera_scale/" + label + "/%d" % slot, sprite.scale.is_equal_approx(Vector2(float(cel[2]), float(cel[11])) * camera / 100.0))
					else:
						var side: String = preview.clip.slot_sides[0 if pattern == -1 else 1]
						_check("actor_texture/" + label + "/%d" % slot, sprite.texture == preview._actors[side].texture)
					_check("opacity/" + label + "/%d" % slot, is_equal_approx(float(sprite.material.get_shader_parameter("opacity")), float(cel[8]) / 255.0))
				_check("no_stale_cells/" + label, preview.visible_cells() == expected_visible)
				_check("source_anchor/" + label, preview.map_position(Vector2(128, 224), 2).is_equal_approx(preview._actors[preview.clip.slot_sides[0]].center))
				_check("target_anchor/" + label, preview.map_position(Vector2(384, 96), 1).is_equal_approx(preview._actors[preview.clip.slot_sides[1]].center))
				if move == "max_guard":
					_check("guard_targets_self/" + label, preview.clip.slot_sides[0] == preview.clip.actor_side and preview.clip.slot_sides[1] == preview.clip.actor_side)
					_check("guard_keeps_opponent/" + label, preview._arena._player_visible == (preview.clip.actor_side == "front") and preview._arena._enemy_visible == (preview.clip.actor_side == "back"))
				for layer: String in ["back", "front"]:
					var data: Dictionary = preview.clip.layers[frame_index][layer]
					var solid: bool = String(data.name).is_empty()
					var visible: bool = float(data.opacity) > 0.0 and (not solid or float(data.colorAlpha) > 0.0)
					_check("layer_visibility/" + label + layer, preview._layers[layer].visible == visible)
					if visible:
						var expected_opacity := float(data.opacity) / 255.0 * (float(data.colorAlpha) / 255.0 if solid else 1.0)
						_check("layer_opacity/" + label + layer, is_equal_approx(float(preview._layers[layer].material.get_shader_parameter("opacity")), expected_opacity))
				if capture and frame_index in samples:
					await process_frame
					await RenderingServer.frame_post_draw
					var image := root.get_texture().get_image()
					var bytes := image.get_data()
					if frame_index == 0:
						baseline = bytes
					else:
						if bytes != baseline:
							_render_differences += 1
							rendered_changes += 1
					_check("capture/" + label, image.save_png(_output + "%s_%s_%dx%d_%03d.png" % [family.replace("/", "_"), preview.clip.actor_side, arena.x, arena.y, frame_index]) == OK)
					_captures += 1
			if capture:
				_check("render_changes/%d/%s" % [clip_index, arena], rendered_changes > 0)
			_check("end_hides_effect", not preview.show_frame(expected_length) and preview.visible_cells() == 0)
			_check("no_layer_after_end", not preview._layers.back.visible and not preview._layers.front.visible)
			_check("seconds_start", preview.show_seconds(0.0) and preview.current_frame == 0)
			_check("seconds_next", preview.show_seconds(0.051) and preview.current_frame == 1)
	for arena: Vector2i in [Vector2i(640, 480), Vector2i(960, 320)]:
		root.size = arena
		root.content_scale_size = arena
		preview.size = Vector2(arena)
		for side: String in ["back", "front"]:
			_check("select_cube/" + side, preview.select_clip(by_id["max_mindstorm/" + side]))
			_check("show_cube/" + side, preview.show_frame(30))
			var cube: Sprite2D = preview._sprites[13]
			_check("cube_metadata_int/" + side, 0 in preview.clip.uniform_screen_patterns)
			_check("cube_not_squashed/%s/%s" % [side, arena], cube.visible and is_equal_approx(cube.scale.x, cube.scale.y) and cube.scale.x > 0.0)
			if capture:
				await process_frame
				await RenderingServer.frame_post_draw
				_check("cube_ratio_capture/" + side, root.get_texture().get_image().save_png(_output + "cube_ratio_%s_%dx%d.png" % [side, arena.x, arena.y]) == OK)
				_captures += 1
	_check("invalid_selection", not preview.select_clip(-1) and preview.visible_cells() == 0)
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Preview.DEFAULT_PACK))
	parsed.clips[0].frames[0][0] = [1]
	# Resource paths remain valid for this fixture; copy manifest next to the pack.
	var adjacent := "res://.godot/move_resource_pilot/invalid_test_manifest.json"
	var file := FileAccess.open(adjacent, FileAccess.WRITE)
	file.store_string(JSON.stringify(parsed))
	file.close()
	_check("reject_bad_cell", not preview.load_pack(adjacent) and preview.last_error == "Celda inválida")
	_check("failure_clears_pack", preview.pack.is_empty() and preview.textures.is_empty() and preview.visible_cells() == 0)
	DirAccess.remove_absolute(adjacent)
	_check("reload", preview.load_pack())
	_check("missing_pack", not preview.load_pack(_output + "does_not_exist.json") and preview.visible_cells() == 0)
	if capture:
		preview.hide()
		await _check_blending(preview)
	preview.queue_free()
	await process_frame
	root.size = Vector2i(960, 680)
	root.content_scale_size = root.size
	var lab := load("res://scenes/visual/move_resource_lab.tscn").instantiate() as Control
	root.add_child(lab)
	lab._playing = false
	await process_frame
	await process_frame
	_check("ui_pack_loaded", not lab.stage.pack.is_empty())
	_check("ui_seventy_options", lab._choices.item_count == 70)
	_check("ui_popup_bounded", lab._choices.get_popup().max_size.y == 480)
	_check("ui_frame_slider", lab._slider.max_value == 37)
	lab._select(1)
	lab._scrub(20)
	_check("ui_opponent_export", lab.stage.clip.opponent_export and lab.stage.current_frame == 20)
	_check("ui_scrub_pauses", not lab._playing)
	var flare_index: int = by_id["max_flare/back"]
	lab._select(flare_index)
	lab._scrub(30)
	_check("ui_max_length", lab._slider.max_value == 51 and lab.stage.current_frame == 30)
	_check("ui_selected_label", lab._choices.selected == flare_index)
	lab._select(by_id["secret_power/psychic/front"])
	lab._scrub(14)
	_check("ui_context_warning", lab._status.text.contains("REFERENCIA VISUAL MANUAL") and lab.stage.current_frame == 14)
	_check("ui_tera_pair", by_id.has("tera_blast/back") and by_id.has("tera_blast/front"))
	lab._select(by_id["hard_press/front"])
	lab._scrub(13)
	_check("ui_hard_press_warning", lab._status.text.contains("DATA_ONLY") and lab.stage.clip.mapped_opponent)
	lab._select(by_id["ivy_cudgel/fire/front"])
	lab._scrub(19)
	_check("ui_variant_warning", lab._status.text.contains("no cambia la forma") and not lab.stage.clip.mapped_opponent)
	_check("ui_variant_species_unchanged", lab.stage.back_species == &"ogerpon" and lab.stage.front_species == &"ogerpon")
	if capture:
		await process_frame
		await RenderingServer.frame_post_draw
		_check("ui_capture", root.get_texture().get_image().save_png(_output + "lab_ui.png") == OK)
		_captures += 1
	lab.queue_free()
	Catalog.clear_cache()
	await process_frame
	_finish()


func _finish() -> void:
	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed,
		"failures": _failures, "captures": _captures, "render_differences": _render_differences,
		"artifact_directory": _output, "pack_sha256": FileAccess.get_sha256(Preview.DEFAULT_PACK),
		"preview_sha256": FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd"),
		"test_sha256": FileAccess.get_sha256("res://tests/visual/community_move_preview_test_runner.gd"),
		"scope": "Priority visual set: Max, four Ivy effects, Hard Press/Tera equivalents, manual Nature/Secret references; not mechanics or artistic approval"}
	var file := FileAccess.open(_output + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	file = FileAccess.open(OUTPUT + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print("COMMUNITY_MOVE_PILOT_RESULT " + JSON.stringify(result))
	quit(0 if _failures.is_empty() else 1)


func _check_blending(preview: Control) -> void:
	var background := ColorRect.new()
	background.color = Color(0.5, 0.5, 0.5, 1.0)
	background.size = Vector2(32, 32)
	root.add_child(background)
	var sprite := Sprite2D.new()
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.2, 0.2, 1.0))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	sprite.material = ShaderMaterial.new()
	root.add_child(sprite)
	for blend in [0, 1, 2]:
		sprite.material.shader = preview._blend_shaders[blend]
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		var value := rendered.get_pixel(4, 4).r
		var expected: float = [0.2, 0.7, 0.3][blend]
		_check("gpu_blend_calibration/%d" % blend, absf(value - expected) < 0.015)
		_check("blend_capture/%d" % blend, rendered.save_png(_output + "blend_%d.png" % blend) == OK)
		_captures += 1
	sprite.queue_free()
	background.queue_free()
	await process_frame


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
