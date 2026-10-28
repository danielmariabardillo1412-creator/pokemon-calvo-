extends SceneTree

func _initialize() -> void:
	call_deferred("_preview")

func _label(parent: Control, text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	parent.add_child(label)

func _preview() -> void:
	root.size = Vector2i(1100, 980)
	var canvas := Control.new()
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color("252d38")
	bg.size = Vector2(1100, 980)
	canvas.add_child(bg)
	_label(canvas, "SIETE CANDIDATOS - revisión GPU - todavía sin instalar", Vector2(20, 12))
	var review: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art_review/item_icons_generated_completion_v1/review.json"))
	var ids := ["armorite_ore", "gold_leaf", "silver_leaf", "lure", "super_lure", "max_lure", "wishing_piece"]
	for row in range(ids.size()):
		var item: Dictionary = review.items[ids[row]]
		var top := 54 + row * 128
		_label(canvas, item.display_name, Vector2(20, top + 26))
		var paths := [item.original_file, item.selected_file, item.selected_file, item.selected_file, item.selected_file, "assets/local_item_catalog/icons/repel.png"]
		var sizes := [80, 96, 48, 40, 32, 48]
		for column in range(paths.size()):
			var image := Image.new()
			if image.load(ProjectSettings.globalize_path("res://" + paths[column])) != OK or image.is_empty():
				push_error("Failed to load " + paths[column])
				quit(1)
				return
			var view := TextureRect.new()
			view.texture = ImageTexture.create_from_image(image)
			view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			view.position = Vector2(205 + column * 142, top)
			view.set_meta("requested_size", sizes[column])
			view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if column == 0 else CanvasItem.TEXTURE_FILTER_LINEAR
			canvas.add_child(view)
			_label(canvas, "original" if column == 0 else "ref." if column == 5 else str(sizes[column]) + " px", Vector2(205 + column * 142, top + 97))
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
				push_error("Incorrect preview dimensions")
				quit(2)
				return
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://art_review/item_icons_generated_completion_v1/godot_preview.png")
	print("ITEM_ART_SEVEN_GPU_PASS" if error == OK else "ITEM_ART_SEVEN_GPU_FAIL")
	quit(0 if error == OK else 1)
