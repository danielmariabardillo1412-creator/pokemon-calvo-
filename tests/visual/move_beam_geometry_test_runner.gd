extends SceneTree

# Independent point-by-point affine oracle, not preview.map_position reused.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["moongeist_beam", "oblivion_wing"]
var _checks := 0
var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 20:
		_errors.append(label)


func _run() -> void:
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var preview := Preview.new()
	root.add_child(preview)
	var seen := 0
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return e.move_id in MOVES):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard hash/load", FileAccess.get_sha256(path) == shard.sha256 and preview.load_pack(path))
		for n in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[n]
			if not clip.move_id in MOVES:
				continue
			seen += 1
			_check("native source", not clip.mapped_opponent)
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["charizard", "ogerpon"]]:
				preview.back_species = StringName(pair[0])
				preview.front_species = StringName(pair[1])
				for arena: Vector2 in [Vector2(640, 360), Vector2(400, 300), Vector2(960, 320)]:
					preview.size = arena
					_check("select", preview.select_clip(n))
					for f in clip.frames.size():
						preview.show_frame(f)
						for slot in clip.frames[f].size():
							var cel: Variant = clip.frames[f][slot]
							if cel == null or cel[7] < 0 or cel[6] != 1 or cel[8] <= 0:
								continue
							var sprite: Sprite2D = preview._sprites[slot]
							var rect := sprite.get_rect()
							for local: Vector2 in [rect.position, rect.end, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.get_center()]:
								var source := Vector2(cel[0], cel[1]) + (local * Vector2(cel[2], cel[11]) / 100.0).rotated(-deg_to_rad(cel[3]))
								var rear := Vector2(preview._actors.back.center)
								var forward := Vector2(preview._actors.front.center)
								var expected := rear + (source - Vector2(128, 224)) / Vector2(256, -128) * (forward - rear)
								_check("whole source geometry/" + String(clip.id), (sprite.transform * local).distance_to(expected) < 0.002)
	_check("both sides of both beams", seen == MOVES.size() * 2)
	var folder := "res://.godot/move_beam_checks/" + FileAccess.get_sha256(INDEX).substr(0, 16) + "_" + FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd").substr(0, 12) + "_" + FileAccess.get_sha256("res://tests/visual/move_beam_geometry_test_runner.gd").substr(0, 12) + "/"
	DirAccess.make_dir_recursive_absolute(folder)
	var result := {"checks": _checks, "failures": _errors, "index_sha256": FileAccess.get_sha256(INDEX),
		"renderer_sha256": FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd"),
		"runner_sha256": FileAccess.get_sha256("res://tests/visual/move_beam_geometry_test_runner.gd")}
	var file := FileAccess.open(folder + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("BEAM_GEOMETRY ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " errors=", _errors.size(), " output=", folder)
	quit(0 if _errors.is_empty() else 1)
