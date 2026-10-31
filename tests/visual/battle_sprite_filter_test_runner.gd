extends SceneTree

const BattleArt = preload("res://scenes/visual/battle_art.gd")
const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Layout = preload("res://scenes/visual/battle_sprite_layout.gd")
const SPECIES := ["charizard", "rayquaza", "gengar", "pikachu", "wailord", "miraidon"]
const ARENAS := [Vector2i(640, 360), Vector2i(400, 225)]
var _passed := 0
var _failures: Array[String] = []
var _captures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var capture := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute("res://.godot/filter_checks")
	for arena: Vector2i in ARENAS:
		root.size = Vector2i(arena.x * 2, arena.y + 42)
		root.content_scale_size = root.size
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		for key: String in SPECIES:
			var panel := Control.new()
			root.add_child(panel)
			var before := BattleArt.new()
			var after := BattleArt.new()
			for index in 2:
				var art: Control = before if index == 0 else after
				art.position = Vector2(index * arena.x, 42)
				art.size = Vector2(arena)
				art.player_species = StringName(key)
				art.enemy_species = StringName(key)
				panel.add_child(art)
				art.set_process(false)
				_check("linear_by_default/%s/%s" % [key, arena], art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR)
				var label := Label.new()
				label.position = Vector2(index * arena.x + 10, 10)
				label.text = key + (" · ANTES: píxel marcado" if index == 0 else " · AHORA: suavizado")
				panel.add_child(label)
			before.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			for side: String in ["front", "back"]:
				var clip: Dictionary = Catalog.animation(StringName(key), side)
				_check("clip_available/%s/%s" % [key, side], not clip.is_empty())
				if clip.is_empty():
					continue
				var bounds := Catalog.presentation_bounds(StringName(key), side, clip)
				var expected := Layout.placement(Vector2(arena), side, bounds)
				# Filtering must not change size, position, source frames or cadence.
				_check("same_layout/%s/%s" % [key, side], expected == Layout.placement(after.size, side, bounds))
				var seconds := float(clip.seconds)
				for elapsed: float in [0.0, seconds * 0.5, maxf(0.0, seconds - 0.000001)]:
					before._player_time = elapsed
					before._enemy_time = elapsed
					after._player_time = elapsed
					after._enemy_time = elapsed
					_check("same_frame/%s/%s" % [key, side], Catalog.frame_index(clip, before._enemy_time) == Catalog.frame_index(clip, after._enemy_time))
			before._player_time = 0.0
			before._enemy_time = 0.0
			after._player_time = 0.0
			after._enemy_time = 0.0
			before.queue_redraw()
			after.queue_redraw()
			await process_frame
			if capture:
				await RenderingServer.frame_post_draw
				var path := "res://.godot/filter_checks/%s_%sx%s.png" % [key, arena.x, arena.y]
				var saved := root.get_texture().get_image().save_png(path) == OK
				_check("capture/" + path, saved)
				if saved:
					_captures += 1
			panel.queue_free()
			await process_frame
	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed,
		"failures": _failures, "captures": _captures, "species_sampled": SPECIES.size(), "arena_sizes": ARENAS.size(),
		"scope": "Shared battle renderer filtering only; source art and presentation scales unchanged. Not exhaustive art approval."}
	var output := FileAccess.open("res://.godot/filter_checks/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t") + "\n")
	output.close()
	print("SPRITE_FILTER_RESULT " + JSON.stringify(result))
	Catalog.clear_cache()
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
