extends "res://scenes/debug/diagnostic_wild_battle_presentation.gd"

# Only layout and sprites change. Every button still invokes the certified controller.
const ArenaArt = preload("res://scenes/visual/battle_art.gd")
var _arena: Control


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("172d2b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 12)
	add_child(frame)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	frame.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 338
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	_turn_label = _label(left, "ENCUENTRO SALVAJE")
	_enemy_label = _label(left, "Pokémon salvaje")
	_enemy_hp = _hp(left)
	_arena = ArenaArt.new()
	_arena.custom_minimum_size.y = 120
	_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_arena)
	_player_label = _label(left, "Tu Pokémon")
	_player_hp = _hp(left)
	_event_log = RichTextLabel.new()
	_event_log.custom_minimum_size = Vector2(0, 58)
	_event_log.scroll_following = true
	left.add_child(_event_log)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 250
	columns.add_child(right)
	_label(right, "¿QUÉ VAS A HACER?")
	var moves := GridContainer.new()
	moves.columns = 1
	right.add_child(moves)
	for i in 4:
		var button := _button(moves, "—")
		button.pressed.connect(_on_move_pressed.bind(i))
		_move_buttons.append(button)
	var switch_row := HBoxContainer.new()
	right.add_child(switch_row)
	_switch_selector = OptionButton.new()
	_switch_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_switch_selector.custom_minimum_size.x = 150
	_switch_selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	switch_row.add_child(_switch_selector)
	_switch_button = _button(switch_row, "Cambiar")
	_switch_button.pressed.connect(_on_switch_pressed)
	_label(right, "MOCHILA · CAPTURA")
	var balls := GridContainer.new()
	balls.columns = 2
	right.add_child(balls)
	for i in 4:
		var button := _button(balls, "—")
		button.pressed.connect(_on_capture_pressed.bind(i))
		_capture_buttons.append(button)
	_run_button = _button(right, "Huir")
	_run_button.pressed.connect(_on_run_pressed)
	_continue_button = _button(right, "Volver a la ruta")
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)


func _refresh_view() -> void:
	super._refresh_view()
	if _arena == null or session == null:
		return
	var actor := session.player_active()
	var wild := session.current_wild()
	if actor != null:
		_arena.player_species = actor.species_id
	if wild != null:
		_arena.enemy_species = wild.species_id


func _label(parent: Node, text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)
	return label


func _hp(parent: Node) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 7
	parent.add_child(bar)
	return bar


func _button(parent: Node, text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 27
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button
