extends RefCounted

# Presentation-only palette shared by the route and the battle adapter.
static func box(color: Color, radius: int = 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 12
	theme.set_color("font_color", "Label", Color("eaf2db"))
	theme.set_color("default_color", "RichTextLabel", Color("eaf2db"))
	theme.set_stylebox("panel", "PanelContainer", box(Color("1e3a35")))
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, box(Color("33594d")))
		theme.set_stylebox("hover", type, box(Color("48745b")))
		theme.set_stylebox("pressed", type, box(Color("587d60")))
		theme.set_stylebox("disabled", type, box(Color("243d37")))
		theme.set_stylebox("focus", type, box(Color(0.85, 0.8, 0.46, 0.25)))
		theme.set_color("font_color", type, Color("f3f0d8"))
		theme.set_color("font_disabled_color", type, Color("7d9686"))
	theme.set_stylebox("background", "ProgressBar", box(Color("142c29"), 3))
	theme.set_stylebox("fill", "ProgressBar", box(Color("a5d47b"), 3))
	return theme
