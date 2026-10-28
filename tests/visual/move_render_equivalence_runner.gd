extends SceneTree

# Compares complete visible render inputs for every source frame in two arenas.
# Used only with identical source-clip/sheet contracts and identical GPU samples
# when carrying a STATIC review through a narrowly changed renderer.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const OLD_FOLDER := "res://.godot/move_contact_review/84cfcc27cf596d4c/"
const INDEX := "res://.godot/move_batch_catalog/index.json"
var _texture_hashes: Dictionary = {}
var _shader_hashes: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _texture_key(texture: Texture2D) -> String:
	if texture == null:
		return "null"
	var key := texture.get_instance_id()
	if not _texture_hashes.has(key):
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(texture.get_image().get_data())
		_texture_hashes[key] = str(texture.get_size()) + ":" + context.finish().hex_encode()
	return _texture_hashes[key]


func _signature(preview: Control) -> String:
	var values: Array = [preview.size, preview.clip_contents, preview.texture_filter,
		preview._arena.visible, preview._arena.size, preview._arena.player_species,
		preview._arena.enemy_species, preview._arena._player_visible, preview._arena._enemy_visible]
	var sprites: Array = []
	sprites.append_array(preview._sprites)
	sprites.append_array(preview._layers.values())
	for sprite: Sprite2D in sprites:
		if not sprite.visible:
			values.append(false)
			continue
		var material := sprite.material as ShaderMaterial
		var shader_key := material.shader.get_instance_id()
		if not _shader_hashes.has(shader_key):
			_shader_hashes[shader_key] = material.shader.code.sha256_text()
		values.append([true, sprite.transform, sprite.position, sprite.rotation, sprite.scale, sprite.offset,
			sprite.region_rect, sprite.region_enabled, sprite.centered, sprite.flip_h, sprite.flip_v,
			sprite.z_index, sprite.z_as_relative, sprite.modulate, sprite.self_modulate,
			sprite.texture_filter, sprite.texture_repeat, _texture_key(sprite.texture),
			_shader_hashes[shader_key], material.get_shader_parameter("overlay"),
			material.get_shader_parameter("tone"), material.get_shader_parameter("opacity")])
	return JSON.stringify(values)


func _run() -> void:
	var old_folder := OLD_FOLDER
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):
			old_folder = arg.trim_prefix("--baseline=").trim_suffix("/") + "/"
	var old_index_path := old_folder + "catalog_index.json"
	var old_renderer_path := old_folder + "renderer_snapshot.gd"
	if not FileAccess.file_exists(old_renderer_path):
		old_renderer_path = old_folder + "renderer_before.gd"
	var old_index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(old_index_path))
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var OldPreview: Script = load(old_renderer_path)
	var before: Control = OldPreview.new()
	var after := Preview.new()
	root.add_child(before)
	root.add_child(after)
	var failures: Array[String] = []
	var equivalent: Array[String] = []
	var changed: Array[String] = []
	var frames := 0
	for n in index.shards.size():
		var old_shard: Dictionary = old_index.shards[n]
		var shard: Dictionary = index.shards[n]
		var old_path := INDEX.get_base_dir().path_join(String(old_shard.path))
		var path := INDEX.get_base_dir().path_join(String(shard.path))
		if FileAccess.get_sha256(old_path) != old_shard.sha256 or FileAccess.get_sha256(path) != shard.sha256 or not before.load_pack(old_path) or not after.load_pack(path):
			failures.append("shard/hash/load")
			break
		for clip_index in after.pack.clips.size():
			var clip: Dictionary = after.pack.clips[clip_index]
			if before.pack.clips[clip_index].id != clip.id or before.pack.clips[clip_index].frames.size() != clip.frames.size():
				failures.append("clip membership/length")
				break
			var same := true
			for arena: Vector2 in [Vector2(640, 360), Vector2(400, 300)]:
				before.size = arena
				after.size = arena
				before.select_clip(clip_index)
				after.select_clip(clip_index)
				for f in clip.frames.size():
					if not before.show_frame(f) or not after.show_frame(f):
						failures.append("show frame")
					frames += 1
					same = (_signature(before) == _signature(after)) and same
			if same:
				equivalent.append(clip.id)
			else:
				changed.append(clip.id)
		print("RENDER_EQUIVALENCE_SHARD ", n, " frames=", frames, " equivalent=", equivalent.size(), " changed=", changed.size())
		await process_frame
	if equivalent.size() + changed.size() != int(index.converted_clips):
		failures.append("incomplete catalog")
	var result := {"version": 1, "failures": failures, "frames": frames,
		"old_index_sha256": FileAccess.get_sha256(old_index_path), "new_index_sha256": FileAccess.get_sha256(INDEX),
		"old_renderer_sha256": FileAccess.get_sha256(old_renderer_path),
		"new_renderer_sha256": FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd"),
		"runner_sha256": FileAccess.get_sha256("res://tests/visual/move_render_equivalence_runner.gd"),
		"equivalent_clip_ids": equivalent, "changed_clip_ids": changed,
		"scope": "Complete visible draw inputs, two arenas; requires identical source/sheets and native GPU samples for static-review migration, not motion/mechanics approval"}
	var path := "res://.godot/move_batch_checks/render_equivalence.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	print("RENDER_EQUIVALENCE ", "PASS" if failures.is_empty() else "FAIL", " frames=", frames, " equivalent=", equivalent.size(), " changed=", changed.size())
	quit(0 if failures.is_empty() else 1)
