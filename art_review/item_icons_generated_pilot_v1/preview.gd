extends SceneTree

func _initialize() -> void:
	call_deferred("_preview")

func _label(parent: Control, text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	parent.add_child(label)

func _preview() -> void:
	root.size = Vector2i(1180, 620)
	var canvas := Control.new()
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color("252d38")
	bg.size = Vector2(1180, 620)
	canvas.add_child(bg)
	_label(canvas, "PILOTO DE ARTE - candidatos v2 - sin instalar en el juego", Vector2(24, 16))
	var ids := ["armorite_ore", "lure"]
	for row in range(ids.size()):
		_label(canvas, ids[row], Vector2(24, 100 + row * 240))
		var paths := ["res://art_review/item_icons_generated_pilot_v1/" + ids[row] + "_original.png", "res://art_review/item_icons_generated_pilot_v1/" + ids[row] + "_160_v2.png", "res://art_review/item_icons_generated_pilot_v1/" + ids[row] + "_160_v2.png", "res://art_review/item_icons_generated_pilot_v1/" + ids[row] + "_160_v2.png", "res://art_review/item_icons_generated_pilot_v1/" + ids[row] + "_160_v2.png", "res://assets/local_item_catalog/icons/repel.png"]
		var sizes := [128, 128, 48, 40, 32, 48]
		for column in range(paths.size()):
			var image := Image.new()
			var load_error := image.load(ProjectSettings.globalize_path(paths[column]))
			if load_error != OK or image.is_empty():
				push_error("Failed to load pilot image " + paths[column])
				quit(1)
				return
			var view := TextureRect.new()
			view.texture = ImageTexture.create_from_image(image)
			view.position = Vector2(210 + column * 155, 100 + row * 240)
			view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			view.size = Vector2(sizes[column], sizes[column])
			view.set_meta("requested_size", sizes[column])
			view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if column == 0 else CanvasItem.TEXTURE_FILTER_LINEAR
			canvas.add_child(view)
			_label(canvas, ("original" if column == 0 else "ref. repelente" if column == 5 else str(sizes[column]) + " px"), Vector2(210 + column * 155, 245 + row * 240))
	await process_frame
	for child in canvas.get_children():
		if child is TextureRect:
			var pixels: int = child.get_meta("requested_size")
			child.size = Vector2(pixels, pixels)
	for frame in range(6):
		await process_frame
	for child in canvas.get_children():
		if child is TextureRect:
			var pixels: int = child.get_meta("requested_size")
			if child.size != Vector2(pixels, pixels):
				push_error("Incorrect preview dimensions: %s expected %s" % [child.size, pixels])
				quit(2)
				return
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://art_review/item_icons_generated_pilot_v1/godot_preview.png")
	print("ITEM_ART_PILOT_GPU_PASS" if error == OK else "ITEM_ART_PILOT_GPU_FAIL")
	quit(0 if error == OK else 1)
