extends SceneTree

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const Before = preload("res://.godot/move_general_checks/reference/preview_before.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const ExternalContext = preload("res://scenes/visual/move_external_context.gd")
const Lab = preload("res://scenes/visual/move_resource_lab.tscn")
const CONTRAST := ["aeroblast", "clanging_scales", "court_change", "destiny_bond", "doom_desire"]
const CONTEXT := ["ally_switch", "baton_pass", "chilly_reception", "circle_throw", "dragon_tail", "flip_turn", "hail", "parting_shot", "rain_dance", "roar", "sandstorm", "shed_tail", "snowscape", "substitute", "teleport", "transform", "u_turn", "volt_switch", "whirlwind"]

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
	var moves: Array = CONTRAST.duplicate()
	if "--all" in OS.get_cmdline_user_args():
		moves.append_array(CONTEXT)
	var probe := false
	check("immutable starting renderer", FileAccess.get_sha256("res://.godot/move_general_checks/reference/preview_before.gd") == "16892e3fcdd25ab448a42e45d1a96f48dba4863ed28adddf1863bf23de770c26")
	var index_sha := FileAccess.get_sha256(INDEX)
	var renderer_sha := FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd")
	var runner_sha := FileAccess.get_sha256("res://tests/visual/move_general_review_runner.gd")
	var out := "res://.godot/move_general_checks/" + (index_sha + renderer_sha + runner_sha + JSON.stringify(moves)).sha256_text().substr(0, 16) + ("/gpu/" if gpu else "/headless/")
	DirAccess.make_dir_recursive_absolute(out)
	var views: Array[SubViewport] = []
	var stages: Array = []
	for script in [Before, Preview]:
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
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in moves):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		check("shard SHA", FileAccess.get_sha256(path) == shard.sha256)
		for stage in stages:
			check("load source", stage.load_pack(path))
		for n in stages[0].pack.clips.size():
			var clip: Dictionary = stages[0].pack.clips[n]
			if not String(clip.move_id) in moves:
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
	check("complete paired selection", clips.size() == moves.size() * 2)
	var contract := _contract_matrix(moves)
	var report := {"version": 1, "probe": probe, "gpu": gpu, "checks": checks, "errors": errors, "states": states, "contract": contract, "clips": clips, "samples": samples, "index_sha256": index_sha, "renderer_sha256": renderer_sha, "runner_sha256": runner_sha, "scope": "Visual evidence only. Z pool undecided; no mechanics or source edits."}
	var file := FileAccess.open(out + "result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print( "GENERAL_REVIEW ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " states=", states, " output=", out, " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _same_sprite(a: Sprite2D, b: Sprite2D) -> bool:
	if a.visible != b.visible:
		return false
	if not a.visible:
		return true
	return a.transform.is_equal_approx(b.transform) and a.region_rect == b.region_rect and a.region_filter_clip_enabled == b.region_filter_clip_enabled and a.offset == b.offset and a.flip_h == b.flip_h and a.z_index == b.z_index and a.texture.get_size() == b.texture.get_size() and a.material.shader.code == b.material.shader.code and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity") and a.material.get_shader_parameter("tone") == b.material.get_shader_parameter("tone") and a.material.get_shader_parameter("overlay") == b.material.get_shader_parameter("overlay")


func _contract_matrix(moves: Array) -> Dictionary:
	var stages: Array = []
	var views: Array[SubViewport] = []
	for script in [Before, Preview]:
		var view := SubViewport.new()
		view.disable_3d = true
		root.add_child(view)
		var stage = script.new()
		view.add_child(stage)
		views.append(view)
		stages.append(stage)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var states := 0
	var rejected := 0
	var fixed_targets := 0
	var settled_bodies := 0
	var handoffs: Array = []
	for shard: Dictionary in index.shards:
		if not shard.entries.any(func(e: Dictionary) -> bool: return String(e.move_id) in moves):
			continue
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		for stage in stages:
			check("matrix load", stage.load_pack(path))
		for n in stages[1].pack.clips.size():
			var clip: Dictionary = stages[1].pack.clips[n]
			if not String(clip.move_id) in moves:
				continue
			var corrected: bool = clip.move_id in ["clanging_scales", "court_change"]
			check("original arrays retained", JSON.stringify(clip.frames) == JSON.stringify(stages[0].pack.clips[n].frames) and JSON.stringify(clip.layers) == JSON.stringify(stages[0].pack.clips[n].layers) and clip.sheet == stages[0].pack.clips[n].sheet and clip.classification_unchanged == stages[0].pack.clips[n].classification_unchanged)
			for pair: Array in [["ogerpon", "charizard"], ["pikachu", "wailord"], ["wailord", "pikachu"], ["charizard", "ogerpon"], ["ogerpon", "wailord"]]:
				for arena: Vector2i in [Vector2i(640, 360), Vector2i(400, 300)]:
					for k in 2:
						views[k].size = arena
						stages[k].size = Vector2(arena)
						stages[k].back_species = StringName(pair[0])
						stages[k].front_species = StringName(pair[1])
						check("matrix select", stages[k].select_clip(n))
					for f in clip.frames.size():
						states += 1
						for stage in stages:
							check("matrix frame", stage.show_frame(f))
						for slot in clip.frames[f].size():
							var a: Sprite2D = stages[0]._sprites[slot]
							var b: Sprite2D = stages[1]._sprites[slot]
							check("visibility unchanged", a.visible == b.visible)
							if not b.visible:
								continue
							var cel: Variant = clip.frames[f][slot]
							check("finite matrix body", b.position.is_finite() and b.scale.is_finite())
							if not corrected or slot >= 2 or cel[7] >= 0:
								check("unrelated render inputs identical", _same_sprite(a, b))
							elif clip.move_id == "clanging_scales":
								if slot == 1:
									check("stationary recipient on own anchor", b.position.is_equal_approx(stages[1]._actors[clip.slot_sides[1]].center))
									fixed_targets += 1
								else:
									check("clanging user unchanged", _same_sprite(a, b))
							elif f <= 13:
								check("court source crossing preserved", _same_sprite(a, b))
							elif f == clip.frames.size() - 1:
								var home: Vector2 = stages[1]._actors[clip.slot_sides[slot]].center
								check("court final body on own side", b.position.is_equal_approx(home))
								settled_bodies += 1
							check("pose size/fade/material unchanged", a.scale.is_equal_approx(b.scale) and is_equal_approx(a.rotation, b.rotation) and a.material.get_shader_parameter("opacity") == b.material.get_shader_parameter("opacity") and a.region_rect == b.region_rect)
						for layer: String in ["back", "front"]:
							check("source layers identical", _same_sprite(stages[0]._layers[layer], stages[1]._layers[layer]))
					for stage in stages:
						check("matrix cleanup", not stage.show_frame(clip.frames.size()) and stage.visible_cells() == 0)
			if String(clip.move_id) in CONTEXT:
				check("external requirement identified", ExternalContext.REQUIREMENTS.has(String(clip.move_id)))
				handoffs.append({"id": clip.id, "source_frames": clip.frames.size(), "requirement": ExternalContext.REQUIREMENTS[String(clip.move_id)], "optional_lab_context_available": String(clip.move_id) in ExternalContext.MOVES, "native_source_verified": true, "external_presentation_resolved": false, "mechanics_approved": false})
			if corrected:
				var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				bad.clips[n].frames[0][0][0] += 1
				var fixture := path.get_base_dir() + "/general_pose_rejection.json"
				var file := FileAccess.open(fixture, FileAccess.WRITE)
				file.store_string(JSON.stringify(bad))
				file.close()
				check("different pose source rejected", not stages[1].load_pack(fixture) and stages[1].last_error.contains("Export distinto"))
				check("restore pose source", stages[1].load_pack(path))
				rejected += 1
	check("all corrected pose exports rejected if changed", rejected == 4)
	check("all clanging target poses anchored", fixed_targets == 540)
	check("all court final bodies restored", settled_bodies == 40)
	var lab = Lab.instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab._load_catalog(true)
	for move: String in moves:
		lab._filter(move)
		var matched := 0
		for choice in lab._filtered.size():
			if String(lab._entries[lab._filtered[choice]].move_id) != move:
				continue
			matched += 1
			lab._select(choice)
			if move in CONTEXT:
				check("external debt visible in UI", lab._status.text.contains("CONTEXTO DE COMBATE PENDIENTE") and lab._status.text.contains(ExternalContext.REQUIREMENTS[move]))
			if move == "doom_desire":
				check("preparation not presented as impact", lab._status.text.contains("REFERENCIA DE CARGA"))
			if move == "court_change":
				check("metaphor not presented as mechanics", lab._status.text.contains("METÁFORA VISUAL"))
		check("both exact-ID laboratory views", matched == 2)
	lab.queue_free()
	for view in views:
		view.queue_free()
	return {"states": states, "target_anchor_checks": fixed_targets, "court_final_anchor_checks": settled_bodies, "rejected_changed_exports": rejected, "pairs": 5, "arenas": 2, "external_handoffs": handoffs}
