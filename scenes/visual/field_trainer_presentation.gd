extends "res://scenes/debug/diagnostic_trainer_battle_presentation.gd"

# Visual-only subclass: all commands still use the existing autonomous session.
const ArenaArt = preload("res://scenes/visual/battle_art.gd")
const AnimationPlayback = preload("res://scenes/visual/battle_animation_playback.gd")
var _arena: Control
var _playback: Node


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
	_turn_label = _label(left, "COMBATE DE ENTRENADOR")
	_enemy_label = _label(left, "Pokémon rival")
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
	for i in 4:
		var button := _button(right, "—")
		button.pressed.connect(_on_move_pressed.bind(i))
		_move_buttons.append(button)
	_switch_selector = OptionButton.new()
	_switch_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_switch_selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right.add_child(_switch_selector)
	_switch_button = _button(right, "Cambiar Pokémon")
	_switch_button.pressed.connect(_on_switch_pressed)
	_continue_button = _button(right, "Volver a la ruta")
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	_playback = AnimationPlayback.new()
	_playback.configure(self, _arena)
	add_child(_playback)


func submit_player_move(move_id: StringName) -> Array[BattleEvent]:
	if _playback.is_playing():
		return []
	return super.submit_player_move(move_id)


func submit_player_switch(instance_id: StringName) -> Array[BattleEvent]:
	if _playback.is_playing():
		return []
	return super.submit_player_switch(instance_id)


func continue_after_completion() -> bool:
	return false if _playback.is_playing() else super.continue_after_completion()


func _refresh_view() -> void:
	super._refresh_view()
	if _playback != null and _playback.is_playing():
		_playback.enforce_input_lock()
		_playback.restore_display()
		return
	if _arena == null or session == null:
		return
	var actor := session.player_active()
	var rival := session.opponent_active()
	if actor != null:
		_arena.player_species = actor.appearance_id()
	if rival != null:
		_arena.enemy_species = rival.appearance_id()


func _render_events(events: Array[BattleEvent]) -> void:
	_playback.note_event_messages(events)
	super._render_events(events)


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
