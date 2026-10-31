extends SceneTree

# LAB-only visual composition checks. Never a battle/mechanics acceptance test.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const Context = preload("res://scenes/visual/move_external_context.gd")
const Lab = preload("res://scenes/visual/move_resource_lab.tscn")
const INDEX := "res://.godot/move_batch_catalog/index.json"
var _checks := 0
var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 30:
		_errors.append(label)


func _read(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func _hash(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()


func _capture(viewport: SubViewport) -> Image:
	await process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


func _run() -> void:
	var gpu := DisplayServer.get_name() != "headless"
	var index_hash := FileAccess.get_sha256(INDEX)
	var pointer := _read(Context.ROOT + "latest.json")
	var descriptor := Context.ROOT + String(pointer.path)
	var generation := (index_hash + String(pointer.sha256) + FileAccess.get_sha256("res://scenes/visual/move_external_context.gd") + FileAccess.get_sha256("res://tests/visual/move_external_context_test_runner.gd")).sha256_text().substr(0, 16)
	var out := "res://.godot/move_external_checks/" + generation + ("/gpu/" if gpu else "/headless/")
	DirAccess.make_dir_recursive_absolute(out)
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview := Preview.new()
	viewport.add_child(preview)
	var adapter := Context.new()
	adapter.attach(preview)
	var index := _read(INDEX)
	var rows: Array[Dictionary] = []
	var states := 0
	var seen: Dictionary = {}
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return e.move_id in Context.MOVES):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard hash/load", FileAccess.get_sha256(path) == shard.sha256 and preview.load_pack(path))
		for n in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[n]
			if not clip.move_id in Context.MOVES:
				continue
			seen[clip.id] = true
			var source_before := JSON.stringify(clip)
			for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
				viewport.size = arena
				preview.size = Vector2(arena)
				preview.back_species = &"ditto" if clip.move_id == "transform" else &"ogerpon"
				preview.front_species = &"charizard"
				preview.select_clip(n)
				_check("bind/" + String(clip.id) + "/" + adapter.error, adapter.bind(path))
				if not adapter.active:
					continue
				_check("explicit no mechanics", adapter.metadata.mechanics_enabled == false and adapter.metadata.battle_routes_added == 0)
				_check("bounded extra phase", adapter.frame_count() == clip.frames.size() + 30)
				var frames: Array[Dictionary] = []
				for frame in adapter.frame_count():
					_check("show composed frame", adapter.show_frame(frame))
					_check("source clock unchanged", preview.current_frame == mini(frame, clip.frames.size() - 1))
					var post: bool = frame >= clip.frames.size()
					var weather_expected: bool = post and clip.move_id in ["rain_dance", "hail", "snowscape", "chilly_reception"]
					var body_expected: bool = (post and clip.move_id == "substitute") or (clip.move_id == "transform" and frame >= 8)
					_check("only declared overlay visible", adapter.weather.visible == weather_expected and adapter.replacement.visible == body_expected)
					if weather_expected:
						_check("weather clock", adapter.weather.current_frame == frame - clip.frames.size())
						_check("no duplicate weather arena", not adapter.weather._arena.visible)
						for slot in adapter.weather.clip.frames[adapter.weather.current_frame].size():
							var cel: Variant = adapter.weather.clip.frames[adapter.weather.current_frame][slot]
							if cel != null and cel[7] < 0:
								_check("no duplicate weather bodies", not adapter.weather._sprites[slot].visible)
					if body_expected:
						_check("replacement texture and geometry", adapter.replacement.texture != null and adapter.replacement.position.is_finite() and adapter.replacement.scale.is_finite())
						for slot in clip.frames[-1].size():
							var cel: Variant = clip.frames[-1][slot]
							if cel != null and cel[7] < 0 and clip.slot_sides[0 if cel[7] == -1 else 1] == clip.actor_side:
								_check("original user not duplicated", not preview._sprites[slot].visible)
						if clip.move_id == "transform":
							var target_species: StringName = preview.front_species if clip.actor_side == "back" else preview.back_species
							var expected: Dictionary = preview._actor(target_species, clip.actor_side)
							_check("correct copied view", adapter.replacement.texture == expected.texture and adapter.replacement.region_rect == expected.region)
					if gpu:
						var image := await _capture(viewport)
						var filename := String(clip.id).replace("/", "_") + "_%dx%d_%03d.png" % [arena.x, arena.y, frame]
						_check("capture", image.save_png(out + filename) == OK)
						frames.append({"frame": frame, "path": filename, "sha256": FileAccess.get_sha256(out + filename), "pixels_sha256": _hash(image), "post_source": post})
						if not post and not (clip.move_id == "transform" and frame >= 8):
							preview.show_frame(frame)
							_check("native prefix GPU unchanged", _hash(await _capture(viewport)) == _hash(image))
					states += 1
				# Scrubbing backwards must remove all added context and restore native bodies.
				_check("scrub back", adapter.show_frame(0))
				_check("scrub restores native", not adapter.weather.visible and not adapter.replacement.visible)
				adapter.clear()
				_check("toggle clears", not adapter.active and not adapter.weather.visible and not adapter.replacement.visible)
				_check("input clip untouched", JSON.stringify(clip) == source_before)
				if gpu:
					preview.show_frame(0)
					var native := _hash(await _capture(viewport))
					adapter.bind(path)
					adapter.show_frame(adapter.frame_count() - 1)
					adapter.clear()
					preview.show_frame(0)
					_check("toggle GPU cleanup", _hash(await _capture(viewport)) == native)
				_check("wrong binding rejected", not adapter.bind("res://project.godot") and not adapter.active and not adapter.weather.visible)
				rows.append({"id": clip.id, "title": clip.title, "side": clip.actor_side, "arena": [arena.x, arena.y], "source_frames": clip.frames.size(), "context_frames": 30, "frames": frames})
	_check("complete paired set", seen.size() == 12 and rows.size() == 24 and states == 1164)
	# Normal UI stays native by default; opt-in cursor includes the separate phase.
	var ui_viewport := SubViewport.new()
	ui_viewport.size = Vector2i(1000, 760)
	ui_viewport.disable_3d = true
	ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(ui_viewport)
	var lab := Lab.instantiate() as Control
	ui_viewport.add_child(lab)
	lab._playing = false
	var catalog_switch := lab.get_child(0).get_child(1).get_child(0) as CheckButton
	catalog_switch.button_pressed = true
	_check("context defaults off", not lab._context_switch.button_pressed and not lab._external.active)
	for move: String in Context.MOVES:
		lab._search.text = move
		var matching: Array[int] = []
		for choice in lab._filtered.size():
			if lab._entries[lab._filtered[choice]].move_id == move:
				matching.append(choice)
		_check("UI exact paired selection/" + move, matching.size() == 2)
		lab._select(matching[0])
		lab._context_switch.button_pressed = true
		_check("UI context opt in/" + move, lab._external.active and lab._slider.max_value == lab.stage.clip.frames.size() + 29)
		lab._scrub(lab._slider.max_value)
		_check("UI explicit simulation", lab._status.text.contains("SIMULACIÓN VISUAL LOCAL") and lab._status.text.contains("contexto 30/30"))
		if gpu and move == "transform":
			# A source-only deferred resize refresh once resurrected the original
			# Ditto beneath the copied appearance. Exercise the REAL UI layout.
			ui_viewport.size = Vector2i(1012, 768)
			await process_frame
			await process_frame
			var ui_image := await _capture(ui_viewport)
			_check("UI screenshot", ui_image.save_png(out + "lab_transform_context.png") == OK)
			for slot in lab.stage.clip.frames[-1].size():
				var cel: Variant = lab.stage.clip.frames[-1][slot]
				if cel != null and cel[7] < 0 and lab.stage.clip.slot_sides[0 if cel[7] == -1 else 1] == lab.stage.clip.actor_side:
					_check("UI resize does not resurrect original", not lab.stage._sprites[slot].visible)
		lab._context_switch.button_pressed = false
		_check("UI toggle resets", not lab._external.active and lab._presentation_frame == 0 and not lab._external.replacement.visible)
	lab._filter("flamethrower")
	lab._context_switch.button_pressed = true
	_check("unrelated clip has no context", not lab._external.active and lab._slider.max_value == lab.stage.clip.frames.size() - 1)
	lab.queue_free()
	_check("stable catalog and resources", FileAccess.get_sha256(INDEX) == index_hash and FileAccess.get_sha256(descriptor) == pointer.sha256)
	var report := {"version": 1, "failures": _errors, "checks": _checks, "gpu": gpu, "states": states,
		"index_sha256": index_hash, "context_manifest_path": descriptor, "context_manifest_sha256": pointer.sha256,
		"renderer_sha256": FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd"),
		"adapter_sha256": FileAccess.get_sha256("res://scenes/visual/move_external_context.gd"),
		"ui_sha256": FileAccess.get_sha256("res://scenes/visual/move_resource_lab.gd"),
		"runner_sha256": FileAccess.get_sha256("res://tests/visual/move_external_context_test_runner.gd"),
		"scope": "Optional LAB-only simulation. Original clips, mechanics and battle routes unchanged; not full artistic approval.", "clips": rows}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("EXTERNAL_CONTEXT ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", states, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
