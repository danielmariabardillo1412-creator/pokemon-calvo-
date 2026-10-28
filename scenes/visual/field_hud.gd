extends Control
class_name FieldHud

var place_label: Label
var frequency_label: Label
var observed_label: Label
var collection_label: Label
var chance_button: Button
var notice_label: Label

func build(theme: Theme, actions: Dictionary) -> Control:
	name = "FieldHUD"
	self.theme = theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 10
	top.offset_top = 8
	top.offset_right = -10
	top.offset_bottom = 48
	add_child(top)
	var title_row := HBoxContainer.new()
	top.add_child(title_row)
	var title := Label.new()
	title.text = "POKÉMON CALVO"
	title.add_theme_font_size_override("font_size", 17)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	_add_button(title_row, "F4 · Ensayo Tera (reinicia)", actions.get("tera", Callable()))
	_add_button(title_row, "F5 · Elementales (reinicia)", actions.get("elemental", Callable()))
	_add_button(title_row, "F6 · Ensayo parcial", actions.get("external", Callable()))

	place_label = Label.new()
	place_label.add_theme_color_override("font_color", Color("b7cf9d"))
	title_row.add_child(place_label)

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 10
	bottom.offset_right = -10
	bottom.offset_top = -79
	bottom.offset_bottom = -8
	add_child(bottom)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 3)
	bottom.add_child(rows)
	var buttons := HBoxContainer.new()
	rows.add_child(buttons)
	var hint := Label.new()
	hint.text = "Flechas · mover | F7/F8 · Cambios | F9 · Clima | F10 · Sustituto | F11 · Transformar | F12 · Dobles"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(hint)

	chance_button = _create_action_button(buttons, "Frecuencia: 15 %", actions.get("frequency", Callable()))
	_create_action_button(buttons, "Reiniciar", actions.get("restart", Callable()))
	_create_action_button(buttons, "F1 · Ajustes", actions.get("settings", Callable()))
	_create_action_button(buttons, "F2 · Colisiones", actions.get("geometry", Callable()))
	_create_action_button(buttons, "F3 · Pokémon", actions.get("gallery", Callable()))
	_create_action_button(buttons, "Informe", actions.get("report", Callable()))

	frequency_label = Label.new()
	frequency_label.add_theme_color_override("font_color", Color("e1d39a"))
	rows.add_child(frequency_label)
	observed_label = Label.new()
	rows.add_child(observed_label)
	collection_label = Label.new()
	collection_label.position = Vector2(20, 53)
	collection_label.add_theme_color_override("font_color", Color("f3f0d8"))
	collection_label.add_theme_color_override("font_shadow_color", Color("172d2b"))
	collection_label.add_theme_constant_override("shadow_offset_x", 1)
	collection_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(collection_label)
	notice_label = Label.new()
	notice_label.position = Vector2(20, 77)
	notice_label.add_theme_color_override("font_color", Color("f3e7b6"))
	notice_label.add_theme_color_override("font_shadow_color", Color("172d2b"))
	notice_label.add_theme_constant_override("shadow_offset_x", 1)
	notice_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(notice_label)

	return self

func _add_button(parent: Node, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 11)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button

func create_action_button(parent: Node, text_value: String, callback: Callable) -> Button:
	return _create_action_button(parent, text_value, callback)

func _create_action_button(parent: Node, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 11)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button