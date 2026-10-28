extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["behemoth_bash", "catastropika"]

class CandidatePreview extends Preview:
	func show_frame(index: int) -> bool:
		var ok := super.show_frame(index)
		if not ok:
			return false
		for slot in clip.frames[index].size():
			var cel: Variant = clip.frames[index][slot]
			if cel == null or not _sprites[slot].visible:
				continue
			if clip.move_id == "behemoth_bash" and cel[7] == 8:
				_sprites[slot].region_rect = Rect2(768, 192, 192, 192)
				_sprites[slot].region_filter_clip_enabled = true
			elif clip.move_id == "catastropika" and int(cel[7]) in [10, 11, 12]:
				_sprites[slot].hide()
		return true

var _checks := 0
var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _errors.size() < 20:
		_errors.append(label)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_art_motif_probe.gd")
	var out := "res://.godot/move_art_motif_checks/" + (index_sha + renderer_sha + runner_sha).sha256_text().substr(0, 16) + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var clips: Array[Dictionary] = []
	var states := 0
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in MOVES):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		_check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for candidate: bool in [false, true]:
			for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
				var view := SubViewport.new()
				view.disable_3d = true
				view.transparent_bg = true
				view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
				view.size = arena
				root.add_child(view)
				var stage: Control = CandidatePreview.new() if candidate else Preview.new()
				stage.size = Vector2(arena)
				view.add_child(stage)
				_check("load", stage.load_pack(path))
				for n in stage.pack.clips.size():
					var clip: Dictionary = stage.pack.clips[n]
					if not String(clip.move_id) in MOVES:
						continue
					_check("select", stage.select_clip(n))
					var rows: Array[Dictionary] = []
					for f in clip.frames.size():
						_check("frame", stage.show_frame(f))
						var particles := 0
						var layers := 0
						for slot in clip.frames[f].size():
							var cel: Variant = clip.frames[f][slot]
							if cel != null and cel[7] >= 0 and stage._sprites[slot].visible:
								particles += 1
						for layer in stage._layers.values():
							layers += int(layer.visible)
						var row := {"frame": f, "particles": particles, "layers": layers}
						if f in [0, 4, 7, 14, 20, 28, 40, clip.frames.size() - 1]:
							await process_frame
							RenderingServer.force_draw(false)
							var image := view.get_texture().get_image()
							image.convert(Image.FORMAT_RGBA8)
							var name := String(clip.id).replace("/", "_") + "_%d_%03d_" % [arena.x, f] + ("candidate.png" if candidate else "before.png")
							_check("save", image.save_png(out + name) == OK)
							row["path"] = name
							row["sha256"] = FileAccess.get_sha256(out + name)
						rows.append(row)
						states += 1
					clips.append({"id": clip.id, "arena": [arena.x, arena.y], "candidate": candidate, "frames": rows})
				stage.queue_free()
				view.queue_free()
				await process_frame
	_check("complete matrix", clips.size() == 16 and states == 808)
	var report := {"version": 1, "gpu": true, "checks": _checks, "failures": _errors, "states": states, "clips": clips, "index_sha256": index_sha, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "scope": "Art selection candidates only, source data and mechanics unchanged; not full-motion approval."}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("ART_MOTIF_PROBE ", "PASS" if _errors.is_empty() else "FAIL", " checks=", _checks, " states=", states, " output=", out, " errors=", _errors)
	quit(0 if _errors.is_empty() else 1)
