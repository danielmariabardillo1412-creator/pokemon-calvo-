extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const PROOF := "res://.godot/move_gap_checks/sources.json"
var _checks := 0
var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 20:
		_errors.append(label)


func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROOF))
	if not data is Dictionary or not data.get("rows") is Array:
		printerr("MOVE_GAP_FOCAL FAIL missing proof")
		quit(1)
		return
	var proof: Dictionary = data
	_check("current proof/index", proof.index_sha256 == FileAccess.get_sha256(INDEX))
	_check("current source audit", proof.runner_sha256 == FileAccess.get_sha256("res://tools/visual/audit_move_gap_sources.py"))
	var rows: Dictionary = {}
	for row: Dictionary in proof.rows:
		rows[row.id] = row
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var preview := Preview.new()
	root.add_child(preview)
	var seen: Dictionary = {}
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return rows.has(e.id)):
			continue
		_check("load", preview.load_pack(INDEX.get_base_dir().path_join(shard.path)))
		for n in preview.pack.clips.size():
			var clip: Dictionary = preview.pack.clips[n]
			if not rows.has(clip.id):
				continue
			seen[clip.id] = true
			var row: Dictionary = rows[clip.id]
			for arena: Vector2 in [Vector2(640, 360), Vector2(400, 300)]:
				preview.size = arena
				_check("select", preview.select_clip(n))
				for f in clip.frames.size():
					_check("frame", preview.show_frame(f))
					for pair: Array in row.priority_cells:
						if int(pair[0]) != f:
							continue
						# Essentials priority ELSE is z80, independent of focus/side.
						_check("priority fallback/z80", preview._sprites[int(pair[1])].z_index == 80)
					for layer: String in ["back", "front"]:
						if not row.omitted_layers.is_empty():
							_check("invisible missing layer", not preview._layers[layer].visible)
		await process_frame
	_check("complete focal set", seen.size() == rows.size() and seen.size() == 8)
	var result := {"checks": _checks, "failures": _errors, "index_sha256": proof.index_sha256,
		"source_proof_sha256": FileAccess.get_sha256(PROOF), "runner_sha256": FileAccess.get_sha256("res://tests/visual/move_gap_test_runner.gd"),
		"scope": "Every new clip/frame in two arenas; priority z80 and invisible layers, not art approval"}
	var file := FileAccess.open("res://.godot/move_gap_checks/result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("MOVE_GAP_FOCAL ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " failures=", _errors)
	quit(0 if _errors.is_empty() else 1)
