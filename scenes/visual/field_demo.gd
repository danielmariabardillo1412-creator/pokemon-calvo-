extends "res://scenes/overworld/technical_overworld.gd"

const FieldTheme = preload("res://scenes/visual/field_theme.gd")
const FieldArt = preload("res://scenes/visual/field_art.gd")
const CharacterArt = preload("res://scenes/visual/character_art.gd")
const INITIAL_CHANCE := 15
const CHANCES := [0, 5, 15, 30, 100]

var _hud: Control
var _frequency_label: Label
var _observed_label: Label
var _place_label: Label
var _collection_label: Label
var _chance_button: Button
var _notice_label: Label
var _grass_walking_seconds := 0.0
var _chance_index := 2


func _ready() -> void:
	get_window().content_scale_size = Vector2i(960, 540)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	# Child controls are ready before the inherited root boots its real sessions.
	test_panel._encounter_chance.value = INITIAL_CHANCE
	test_panel._wild_species_input.text = "pidgey"
	super._ready()
	var canvas := $CanvasLayer as CanvasLayer
	for child in get_children():
		if child is Polygon2D or child is Label:
			(child as CanvasItem).hide()
	for path in ["EncounterZone/Visual", "TrainerTrigger/Visual", "CenterObstacle/Visual", "TopWall/Visual", "BottomWall/Visual", "BuildingEntrance/Visual", "CaveEntrance/Visual", "LedgeBarrier/Visual", "LedgeTrigger/Visual", "BuildingExit/Visual", "CaveEncounterZone/Visual", "CaveExit/Visual", "Player/Visual"]:
		(get_node(path) as CanvasItem).hide()
	var scenery := FieldArt.new()
	scenery.actor = player
	add_child(scenery)
	move_child(scenery, 0)
	var hero := CharacterArt.new()
	player.add_child(hero)
	player.z_index = 2
	var trainer := CharacterArt.new()
	trainer.trainer = true
	trainer.position = Vector2(144, 80)
	trainer.z_index = 2
	add_child(trainer)
	var camera := $Player/Camera2D as Camera2D
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2(1.15, 1.15)
	status_label.visible = false
	test_panel.get_child(0).hide()
	var theme := FieldTheme.create()
	for child in canvas.get_children():
		if child is Control:
			(child as Control).theme = theme
	_build_hud(canvas, theme)
	player.motion_resolved.connect(_observe_walk)
	_refresh_hud()
	status_label.text = "Camina hacia la hierba de la derecha para encontrar un Pidgey."
	print("VISUAL_FIELD_READY chance=15 species=pidgey")


func _process(_delta: float) -> void:
	if not is_demo_ready():
		return
	var center := Vector2(320, 214)
	match technical_region_id():
		&"building": center = Vector2(940, 214)
		&"cave": center = Vector2(320, 654)
	($Player/Camera2D as Camera2D).global_position = center
	_hud.visible = not battle_presentation.visible and not trainer_battle_presentation.visible and not test_panel.is_panel_open()
	_refresh_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F1 and _can_configure():
		if test_panel.is_panel_open():
			test_panel._close_config()
		else:
			test_panel._open_config()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and test_panel.is_panel_open():
		test_panel._close_config()
		get_viewport().set_input_as_handled()


func _can_configure() -> bool:
	return not battle_presentation.visible and not trainer_battle_presentation.visible and not traversal_is_busy()


func _observe_walk(_requested: Vector2, actual: Vector2, _from: Vector2, to: Vector2) -> void:
	if zone_at_position(to) != &"" and player.move_speed > 0:
		_grass_walking_seconds += actual.length() / player.move_speed


func cycle_frequency() -> void:
	if not _can_configure():
		return
	_chance_index = (CHANCES.find(int(_active_config.get("encounter_chance_percent", INITIAL_CHANCE))) + 1) % CHANCES.size()
	test_panel._encounter_chance.value = CHANCES[_chance_index]
	restart_field_run()


func restart_field_run() -> void:
	if not _can_configure():
		return
	_on_configuration_applied(test_panel.current_configuration())
	status_label.text = "Prueba reiniciada: equipo y mochila restaurados."


func _on_configuration_applied(config: Dictionary) -> void:
	if not _can_configure():
		return
	_grass_walking_seconds = 0.0
	if _notice_label != null:
		_notice_label.text = ""
	super._on_configuration_applied(config)


func encounter_expectation() -> Dictionary:
	var percent := int(_active_config.get("encounter_chance_percent", 0))
	if percent <= 0:
		return {"enabled": false, "percent": 0}
	var mean_steps := 100.0 / float(percent)
	return {
		"enabled": true, "percent": percent, "mean_steps": mean_steps,
		"mean_walking_seconds": mean_steps * player.step_distance / player.move_speed,
	}


func _build_hud(canvas: CanvasLayer, theme: Theme) -> void:
	_hud = Control.new()
	_hud.name = "FieldHUD"
	_hud.theme = theme
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_hud)
	canvas.move_child(_hud, 0)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 10
	top.offset_top = 8
	top.offset_right = -10
	top.offset_bottom = 48
	_hud.add_child(top)
	var title_row := HBoxContainer.new()
	top.add_child(title_row)
	var title := Label.new()
	title.text = "POKÉMON CALVO"
	title.add_theme_font_size_override("font_size", 17)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_place_label = Label.new()
	_place_label.add_theme_color_override("font_color", Color("b7cf9d"))
	title_row.add_child(_place_label)
	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 10
	bottom.offset_right = -10
	bottom.offset_top = -79
	bottom.offset_bottom = -8
	_hud.add_child(bottom)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 3)
	bottom.add_child(rows)
	var buttons := HBoxContainer.new()
	rows.add_child(buttons)
	var hint := Label.new()
	hint.text = "Flechas · mover"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(hint)
	_chance_button = _hud_button(buttons, "Frecuencia: 15 %", cycle_frequency)
	_hud_button(buttons, "Reiniciar", restart_field_run)
	_hud_button(buttons, "F1 · Ajustes", func(): test_panel._open_config())
	_hud_button(buttons, "Informe", func():
		_on_export_report_requested()
		_notice_label.text = "Informe exportado · F1 > ABRIR CARPETA DE INFORMES"
	)
	_frequency_label = Label.new()
	_frequency_label.add_theme_color_override("font_color", Color("e1d39a"))
	rows.add_child(_frequency_label)
	_observed_label = Label.new()
	rows.add_child(_observed_label)
	_collection_label = Label.new()
	_collection_label.position = Vector2(20, 53)
	_collection_label.add_theme_color_override("font_color", Color("f3f0d8"))
	_collection_label.add_theme_color_override("font_shadow_color", Color("172d2b"))
	_collection_label.add_theme_constant_override("shadow_offset_x", 1)
	_collection_label.add_theme_constant_override("shadow_offset_y", 1)
	_hud.add_child(_collection_label)
	_notice_label = Label.new()
	_notice_label.position = Vector2(20, 77)
	_notice_label.add_theme_color_override("font_color", Color("f3e7b6"))
	_notice_label.add_theme_color_override("font_shadow_color", Color("172d2b"))
	_notice_label.add_theme_constant_override("shadow_offset_x", 1)
	_notice_label.add_theme_constant_override("shadow_offset_y", 1)
	_hud.add_child(_notice_label)


func _hud_button(parent: Node, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _refresh_hud() -> void:
	_place_label.text = "RUTA 01 · CLARO DE PRUEBAS"
	if technical_region_id() == &"building":
		_place_label.text = "REFUGIO · ZONA SEGURA"
	elif technical_region_id() == &"cave":
		_place_label.text = "CUEVA · ENCUENTROS Nv. %d–%d" % [int(_active_config.get("cave_min_level", 8)), int(_active_config.get("cave_max_level", 12))]
	var expected := encounter_expectation()
	_chance_button.text = "Frecuencia: %d %%" % int(expected.get("percent", 0))
	_frequency_label.text = "Sin encuentros: frecuencia 0 %." if not expected.enabled else (
		"Media teórica: %.1f pasos / %.1f s en zona · no es un plazo garantizado" % [
			float(expected.mean_steps), float(expected.mean_walking_seconds),
		]
	)
	var current: Dictionary = technical_audit_summary().get("current_run", {})
	var encounters: Dictionary = current.get("encounters", {})
	var captures: Dictionary = current.get("capture", {})
	_observed_label.text = "%d tiradas · %d encuentros · %d capturas · %.1f s andando en zona" % [
		int(encounters.get("rolls", 0)), int(encounters.get("encounters", 0)),
		int(captures.get("successes", 0)), _grass_walking_seconds,
	]
	var species_id := StringName(String(_active_config.get("wild_species_id", "")))
	var species_label := "Pool aleatorio" if species_id == &"" else SpanishGameText.species_name(species_id, _catalogs)
	var cave := technical_region_id() == &"cave"
	_collection_label.text = "Equipo %d/6   ·   Poké Balls %d   ·   %s Nv. %d–%d" % [
		demo_party_size(), demo_inventory_quantity(&"poke_ball"), species_label,
		int(_active_config.get("cave_min_level" if cave else "wild_min_level", 4)),
		int(_active_config.get("cave_max_level" if cave else "wild_max_level", 6)),
	]
	if technical_region_id() == &"building":
		_collection_label.text = "Equipo %d/6   ·   Refugio sin encuentros" % demo_party_size()
