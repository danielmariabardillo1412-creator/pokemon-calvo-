extends "res://scenes/overworld/technical_overworld.gd"

const FieldTheme = preload("res://scenes/visual/field_theme.gd")
const FieldArt = preload("res://scenes/visual/field_art.gd")
const CharacterArt = preload("res://scenes/visual/character_art.gd")
const CollisionOverlay = preload("res://scenes/visual/collision_overlay.gd")
const PokemonGallery = preload("res://scenes/visual/pokemon_gallery.gd")
const INITIAL_CHANCE := 15
const CHANCES := [0, 5, 15, 30, 100]
const ELEMENTAL_TEST_MOVES: Array[StringName] = [&"flamethrower", &"thunderbolt", &"ice_beam"]
var _elemental_test_index := 0
const EXTERNAL_DAMAGE_TEST_MOVES: Array[StringName] = [&"circle_throw", &"dragon_tail", &"flip_turn", &"u_turn", &"volt_switch"]
var _external_test_index := 0
var _switch_test_index := 0
const STATUS_SWITCH_TEST_MOVES: Array[StringName] = [&"roar", &"whirlwind", &"teleport", &"baton_pass", &"parting_shot"]
var _status_switch_index := 0
const WEATHER_TEST_MOVES: Array[StringName] = [&"rain_dance", &"hail", &"sandstorm", &"snowscape", &"chilly_reception"]
var _weather_index := 0
const SUBSTITUTE_TEST_MOVES: Array[StringName] = [&"substitute", &"shed_tail"]
var _substitute_index := 0
const TRANSFORM_TEST_SPECIES: Array[StringName] = [&"wailord", &"pikachu", &"charizard"]
var _transform_index := 0

var _hud: Control
var _frequency_label: Label
var _observed_label: Label
var _place_label: Label
var _collection_label: Label
var _chance_button: Button
var _notice_label: Label
var _geometry_overlay: Node2D
var _doubles_demo: Control
var _pokemon_gallery: Control
var _grass_walking_seconds := 0.0
var _chance_index := 2
var native_battles_enabled := true
var _native_battles: Node
var _item_bag: Control


func _ready() -> void:
	native_battles_enabled = native_battles_enabled and "--legacy-field" not in OS.get_cmdline_user_args()
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
	_geometry_overlay = CollisionOverlay.new()
	_geometry_overlay.z_index = 5
	_geometry_overlay.visible = false
	add_child(_geometry_overlay)
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
	_pokemon_gallery = PokemonGallery.new()
	_pokemon_gallery.theme = theme
	_pokemon_gallery.close_requested.connect(toggle_pokemon_gallery)
	canvas.add_child(_pokemon_gallery)
	player.motion_resolved.connect(_observe_walk)
	_refresh_hud()
	if native_battles_enabled:
		_native_battles = preload("res://scenes/visual/field_native_bridge.gd").new()
		add_child(_native_battles); _native_battles.configure(self)
		var saves := HBoxContainer.new(); saves.position = Vector2(20, 99); _hud.add_child(saves)
		_hud_button(saves, "Guardar · Ctrl+S", func(): _native_battles.save_game())
		_hud_button(saves, "Cargar · Ctrl+L", func(): await _native_battles.load_game())
		_hud_button(saves, "B · Mochila", toggle_item_bag)
	_item_bag = preload("res://scenes/visual/field_item_bag.gd").new()
	_item_bag.field = self; _item_bag.theme = theme; canvas.add_child(_item_bag)
	_item_bag.popup_hide.connect(func(): player.movement_enabled = _can_configure() and not test_panel.is_panel_open())
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
	_hud.visible = not battle_presentation.visible and not trainer_battle_presentation.visible and not test_panel.is_panel_open() and not _pokemon_gallery.visible and (_item_bag == null or not _item_bag.visible) and (_doubles_demo == null or not _doubles_demo.visible) and (_native_battles == null or not _native_battles.occupied())
	if _native_battles != null and _native_battles.occupied(): player.movement_enabled = false
	_refresh_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _item_bag != null and _item_bag.visible:
		if event.keycode in [KEY_ESCAPE, KEY_B]: _item_bag.hide()
		get_viewport().set_input_as_handled(); return
	if event.keycode == KEY_B:
		toggle_item_bag(); get_viewport().set_input_as_handled(); return
	if _native_battles != null and event.ctrl_pressed and event.keycode in [KEY_S, KEY_L]:
		if event.keycode == KEY_S: _native_battles.save_game()
		else: await _native_battles.load_game()
		get_viewport().set_input_as_handled(); return
	if _doubles_demo != null and _doubles_demo.visible:
		if event.keycode in [KEY_ESCAPE, KEY_F12]:
			_close_doubles_demo()
			get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F12:
		open_doubles_demo()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F3 or (event.keycode == KEY_ESCAPE and _pokemon_gallery.visible):
		toggle_pokemon_gallery()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F1 and _can_configure():
		if test_panel.is_panel_open():
			test_panel._close_config()
		else:
			test_panel._open_config()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and test_panel.is_panel_open():
		test_panel._close_config()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F2:
		toggle_geometry_overlay()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F4:
		prepare_tera_visual_test()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F5:
		cycle_elemental_visual_test()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F6:
		cycle_external_damage_test()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F7:
		cycle_switch_move_test()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F8:
		cycle_status_switch_test()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F11:
		cycle_transform_test()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F10:
		cycle_substitute_test()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F9:
		cycle_weather_test()
		get_viewport().set_input_as_handled()


func _can_configure() -> bool:
	return _field_idle_for_items() and (_item_bag == null or not _item_bag.visible)


func _can_use_field_items() -> bool:
	return _field_idle_for_items() and not test_panel.is_panel_open()


func _field_idle_for_items() -> bool:
	return (_native_battles == null or not _native_battles.occupied()) and not has_active_demo_battle() and not has_active_demo_trainer_battle() and not battle_presentation.visible and not trainer_battle_presentation.visible and not traversal_is_busy() and (_pokemon_gallery == null or not _pokemon_gallery.visible) and (_doubles_demo == null or not _doubles_demo.visible)


func toggle_item_bag() -> bool:
	if _item_bag == null: return false
	if _item_bag.visible: _item_bag.hide(); return true
	return _item_bag.open_bag()


func open_doubles_demo() -> bool:
	if not _can_configure() or test_panel.is_panel_open(): return false
	if _doubles_demo == null:
		_doubles_demo = preload("res://scenes/visual/native_doubles_demo.gd").new() if native_battles_enabled else preload("res://scenes/visual/doubles_position_demo.gd").new()
		_doubles_demo.theme = FieldTheme.create()
		_doubles_demo.close_requested.connect(_close_doubles_demo)
		$CanvasLayer.add_child(_doubles_demo)
	if native_battles_enabled:
		_doubles_demo.format_id = "gen9calvounifieddoublesv1" if _native_battles.format_id == "gen9calvounifiedv1" else "gen9doublescustomgame"
	if not _doubles_demo.configure(_catalogs): return false
	_doubles_demo.show()
	player.movement_enabled = false
	return true


func _close_doubles_demo() -> void:
	if _doubles_demo != null and _doubles_demo.has_method("shutdown"): await _doubles_demo.shutdown()
	if _doubles_demo != null: _doubles_demo.hide()
	player.movement_enabled = not test_panel.is_panel_open()


func toggle_pokemon_gallery() -> void:
	if _pokemon_gallery.visible:
		_pokemon_gallery.hide()
		player.movement_enabled = not test_panel.is_panel_open()
	elif _can_configure() and not test_panel.is_panel_open():
		_pokemon_gallery.show()
		player.movement_enabled = false


func _open_settings() -> void:
	if _can_configure():
		test_panel._open_config()


func prepare_tera_visual_test() -> bool:
	return prepare_visual_move_test(&"tera_blast")


func cycle_elemental_visual_test() -> bool:
	if not prepare_visual_move_test(ELEMENTAL_TEST_MOVES[_elemental_test_index]):
		return false
	_elemental_test_index = (_elemental_test_index + 1) % ELEMENTAL_TEST_MOVES.size()
	return true


func cycle_external_damage_test() -> bool:
	if not prepare_visual_move_test(EXTERNAL_DAMAGE_TEST_MOVES[_external_test_index]):
		return false
	_external_test_index = (_external_test_index + 1) % EXTERNAL_DAMAGE_TEST_MOVES.size()
	return true


func cycle_switch_move_test() -> bool:
	if not prepare_visual_move_test(EXTERNAL_DAMAGE_TEST_MOVES[_switch_test_index], true):
		return false
	_switch_test_index = (_switch_test_index + 1) % EXTERNAL_DAMAGE_TEST_MOVES.size()
	return true


func prepare_visual_move_test(move_id: StringName, switch_rules: bool = false, weather_rules: bool = false, substitute_rules: bool = false, transform_rules: bool = false) -> bool:
	# Explicit disposable demo preset, NOT a learnset/TM or save-game mechanic.
	var external_damage := move_id in EXTERNAL_DAMAGE_TEST_MOVES
	var status_switch := move_id in STATUS_SWITCH_TEST_MOVES
	var transform := move_id == &"transform"
	var substitute := move_id in SUBSTITUTE_TEST_MOVES
	var weather := move_id in WEATHER_TEST_MOVES
	if not _can_configure() or test_panel.is_panel_open() or (move_id != &"tera_blast" and not move_id in ELEMENTAL_TEST_MOVES and not external_damage and not status_switch and not weather and not substitute and not transform):
		return false
	if status_switch and not switch_rules:
		return false
	if weather and not weather_rules: return false
	if substitute and not substitute_rules: return false
	if transform and not transform_rules: return false
	var pilot: Node = battle_presentation._playback._transform if transform else (battle_presentation._playback._substitute if substitute else (battle_presentation._playback._weather_cast if weather else (battle_presentation._playback._status_switch if status_switch else (battle_presentation._playback._external_damage if external_damage else battle_presentation._playback._community))))
	var move := _catalogs.move(move_id)
	var metadata := preload("res://scenes/visual/battle_move_visuals.gd").metadata(move)
	if not pilot.available or not pilot._indices.has(String(move_id) + "/back") or not pilot._accepts(String(move_id), metadata):
		_notice_label.text = "Falta el pack local del ensayo o su contrato no es válido."
		return false
	for field: LineEdit in test_panel._player_species_inputs:
		field.text = ""
	test_panel._player_species_inputs[0].text = "ditto" if transform_rules else "charizard"
	test_panel._player_level_inputs[0].value = 50
	if switch_rules:
		test_panel._player_species_inputs[1].text = "lapras" if weather_rules else "pikachu"
		test_panel._player_level_inputs[1].value = 50
		test_panel._player_species_inputs[2].text = "golem" if weather_rules else "blastoise"
		test_panel._player_level_inputs[2].value = 50
	test_panel._wild_species_input.text = String(TRANSFORM_TEST_SPECIES[_transform_index]) if transform_rules else "wailord"
	test_panel._wild_min_level.value = 50
	test_panel._wild_max_level.value = 50
	test_panel._encounter_chance.value = 100
	restart_field_run()
	_session.live_moves_enabled = false # Explicit comparison presets retain their own scope.
	_session.switch_move_rules_enabled = switch_rules
	_session.weather_rules_enabled = weather_rules
	_session.substitute_rules_enabled = substitute_rules
	_session.transform_rules_enabled = transform_rules
	var actor := _session.player.party.get_active()
	actor.moveset.clear()
	actor.move_ids.clear()
	actor.add_move(move_id, _catalogs)
	_recorder.record(&"visual_test", &"visual_move_preset", {"temporary_move": String(move_id), "mechanics_scope": "damage_only_special_effect_pending" if external_damage else "existing_rules_only", "reset_restores_learnset": true})
	var label := "TERA NORMAL" if move_id == &"tera_blast" else move.display_name.to_upper()
	_notice_label.text = "ENSAYO %s · movimiento temporal, sin Tera · Reiniciar restaura el learnset." % label
	if external_damage:
		_notice_label.text = "SOLO DAÑO · %s · El relevo/expulsión sigue pendiente. Reiniciar restaura el learnset." % move.display_name
	if switch_rules:
		_notice_label.text = "F7 · %s · SALVAJE: relevo/expulsión reales · Ensayo individual; Reiniciar restaura el equipo." % move.display_name
		_recorder.record(&"visual_test", &"switch_move_preset", {"move_id": String(move_id), "mechanics_scope": "singles_switch_moves_v1", "reset_restores_learnset": true})
	return true


func cycle_transform_test() -> bool:
	if not prepare_visual_move_test(&"transform", true, true, true, true): return false
	var target := TRANSFORM_TEST_SPECIES[_transform_index]
	_transform_index = (_transform_index + 1) % TRANSFORM_TEST_SPECIES.size()
	_notice_label.text = "F11 · Transformación · Ditto frente a %s · Reiniciar restaura el equipo." % SpanishGameText.species_name(target, _catalogs)
	_recorder.record(&"visual_test", &"transform_preset", {"move_id": "transform", "target_species": String(target), "mechanics_scope": "transform_singles_v1"})
	return true


func cycle_substitute_test() -> bool:
	var move := SUBSTITUTE_TEST_MOVES[_substitute_index]
	if not prepare_visual_move_test(move, true, false, true): return false
	var actor := _session.player.party.get_active()
	for id: StringName in [&"tackle", &"flamethrower", &"baton_pass"]:
		actor.add_move(id, _catalogs)
	_substitute_index = (_substitute_index + 1) % SUBSTITUTE_TEST_MOVES.size()
	_notice_label.text = "F10 · %s · Sustituto y relevo con elección de reserva · Reiniciar restaura el equipo." % _catalogs.move(move).display_name
	_recorder.record(&"visual_test", &"substitute_preset", {"move_id": String(move), "mechanics_scope": "substitute_singles_v1"})
	return true


func cycle_weather_test() -> bool:
	var move := WEATHER_TEST_MOVES[_weather_index]
	if not prepare_visual_move_test(move, true, true): return false
	var actor := _session.player.party.get_active()
	for id: StringName in [&"water_gun", &"flamethrower", &"tackle"]:
		actor.add_move(id, _catalogs)
	_weather_index = (_weather_index + 1) % WEATHER_TEST_MOVES.size()
	_notice_label.text = "F9 · %s · Clima persistente y ataques de prueba · Reiniciar restaura el equipo." % _catalogs.move(move).display_name
	_recorder.record(&"visual_test", &"weather_preset", {"move_id": String(move), "mechanics_scope": "weather_singles_v1"})
	return true


func cycle_status_switch_test() -> bool:
	var move := STATUS_SWITCH_TEST_MOVES[_status_switch_index]
	if not prepare_visual_move_test(move, true):
		return false
	if move == &"baton_pass":
		var actor := _session.player.party.get_active()
		actor.stat_stages.change(StatStages.ATTACK, 2)
		actor.stat_stages.change(StatStages.SPEED, 1)
	_notice_label.text = "F8 · %s · Ensayo de cambios de estado · Reiniciar restaura el learnset." % _catalogs.move(move).display_name
	_status_switch_index = (_status_switch_index + 1) % STATUS_SWITCH_TEST_MOVES.size()
	_recorder.record(&"visual_test", &"status_switch_preset", {"move_id": String(move), "mechanics_scope": "singles_status_switch_v1", "reset_restores_learnset": true})
	return true


func toggle_geometry_overlay() -> void:
	_geometry_overlay.visible = not _geometry_overlay.visible
	_notice_label.text = "Colisiones: rojo muro · verde hierba · amarillo salto · azul puerta · rosa rival" if _geometry_overlay.visible else ""


func _observe_walk(_requested: Vector2, actual: Vector2, from: Vector2, to: Vector2) -> void:
	if player.move_speed <= 0 or actual.length_squared() <= 0.0:
		return
	for node in get_tree().get_nodes_in_group("encounter_zones"):
		var zone := node as OverworldEncounterZone
		if zone != null:
			_grass_walking_seconds += zone.distance_within_segment(from, to) / player.move_speed


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
	if _native_battles != null:
		if _native_battles.view.session != null: _native_battles.view.session.stop_now()
		_native_battles.view.session = null
		_native_battles.view.catalogs = _catalogs; _native_battles.view.player = _session.player
		_native_battles.clocks.clear()


func _on_player_step_completed(world_position: Vector2) -> void:
	if _native_battles != null: await _native_battles.on_step(world_position)
	else: super._on_player_step_completed(world_position)


func start_demo_trainer_battle() -> bool:
	return _native_battles.start_trainer() if _native_battles != null else super.start_demo_trainer_battle()


func recover_demo_trainer_full() -> bool:
	if _native_battles != null and _native_battles.occupied(): return false
	return super.recover_demo_trainer_full()


func has_active_demo_battle() -> bool:
	return _native_battles.occupied() and _native_battles.kind == "wild" if _native_battles != null else super.has_active_demo_battle()


func has_active_demo_trainer_battle() -> bool:
	return _native_battles.occupied() and _native_battles.kind == "trainer" if _native_battles != null else super.has_active_demo_trainer_battle()


func is_battle_presentation_visible() -> bool:
	return _native_battles.view.visible and _native_battles.kind == "wild" if _native_battles != null else super.is_battle_presentation_visible()


func is_trainer_battle_presentation_visible() -> bool:
	return _native_battles.view.visible and _native_battles.kind == "trainer" if _native_battles != null else super.is_trainer_battle_presentation_visible()


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
	_hud_button(title_row, "F4 · Ensayo Tera (reinicia)", prepare_tera_visual_test)
	_hud_button(title_row, "F5 · Elementales (reinicia)", cycle_elemental_visual_test)
	_hud_button(title_row, "F6 · Ensayo parcial", cycle_external_damage_test)
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
	hint.text = "Flechas · mover | F7/F8 · Cambios | F9 · Clima | F10 · Sustituto | F11 · Transformar | F12 · Dobles"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(hint)
	_chance_button = _hud_button(buttons, "Frecuencia: 15 %", cycle_frequency)
	_hud_button(buttons, "Reiniciar", restart_field_run)
	_hud_button(buttons, "F1 · Ajustes", _open_settings)
	_hud_button(buttons, "F2 · Colisiones", toggle_geometry_overlay)
	_hud_button(buttons, "F3 · Pokémon", toggle_pokemon_gallery)
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
