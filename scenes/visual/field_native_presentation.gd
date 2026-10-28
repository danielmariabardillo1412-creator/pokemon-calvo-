extends "res://scenes/visual/showdown_adventure_lab.gd"

signal return_requested
var owner_bridge: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui(); hide()


func _build_ui() -> void:
	super._build_ui()
	# Keep every command reachable at the map's window size.
	var right := _continue_button.get_parent()
	var columns := right.get_parent()
	var index := right.get_index()
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.x = 300
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll); columns.move_child(scroll, index); right.reparent(scroll)
	var save_row := HBoxContainer.new(); right.add_child(save_row)
	_save.reparent(save_row); _load.reparent(save_row)
	var capture_row := HBoxContainer.new(); right.add_child(capture_row)
	_ball.reparent(capture_row); _master.reparent(capture_row); _flee.reparent(capture_row)
	right.move_child(capture_row, 6)
	_continue_button.text = "Volver al mapa"
	_save.text = "Guardar partida"; _load.text = "Cargar partida"
	for c: Node in _continue_button.get_parent().get_children():
		if c is Label and c.text.contains("SHOWDOWN"): c.text = "COMBATE"
		if c is Label and c.text.begins_with("Reglas de "): c.hide()


func new_battle() -> bool:
	if session != null and not session.has_active_battle() and not _playback.is_playing(): return_requested.emit(); return true
	return false


func _refresh_view() -> void:
	super._refresh_view()
	if session == null or _ball == null: return
	var locked: bool = _working or session.busy or _playback.is_playing()
	var wild: bool = session.battle_kind == "wild"
	_ball.visible = wild; _master.visible = wild; _flee.visible = wild
	_continue_button.text = "Volver al mapa"
	_save.show(); _load.show()
	_save.disabled = locked or owner_bridge == null
	_load.disabled = locked or owner_bridge == null or not FileAccess.file_exists(owner_bridge.save_path)


func save_battle(_path: String = "") -> bool:
	if owner_bridge == null: return false
	return owner_bridge.save_game()


func load_battle(_path: String = "") -> bool:
	if owner_bridge == null: return false
	return await owner_bridge.load_game()


func resume_battle() -> bool:
	if owner_bridge == null: return false
	return await owner_bridge.recover_battle()


func _settle() -> void:
	super._settle()
	if session != null and not session.completion_reason.is_empty():
		_event_log.append_text("\nResultado aplicado. Puedes volver al mapa o guardar.")
