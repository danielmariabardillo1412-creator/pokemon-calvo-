extends "res://scenes/overworld/technical_overworld.gd"

const FieldTheme = preload("res://scenes/visual/field_theme.gd")
const FieldArt = preload("res://scenes/visual/field_art.gd")
const CharacterArt = preload("res://scenes/visual/character_art.gd")
const CollisionOverlay = preload("res://scenes/visual/collision_overlay.gd")
const PokemonGallery = preload("res://scenes/visual/pokemon_gallery.gd")
const FieldDiagnostics = preload("res://scenes/visual/field_diagnostics.gd")
const INITIAL_CHANCE := 15
const CHANCES := [0, 5, 15, 30, 100]
const ELEMENTAL_TEST_MOVES: Array[StringName] = FieldDiagnostics.ELEMENTAL_TEST_MOVES
const EXTERNAL_DAMAGE_TEST_MOVES: Array[StringName] = FieldDiagnostics.EXTERNAL_DAMAGE_TEST_MOVES
const STATUS_SWITCH_TEST_MOVES: Array[StringName] = FieldDiagnostics.STATUS_SWITCH_TEST_MOVES
const WEATHER_TEST_MOVES: Array[StringName] = FieldDiagnostics.WEATHER_TEST_MOVES
const SUBSTITUTE_TEST_MOVES: Array[StringName] = FieldDiagnostics.SUBSTITUTE_TEST_MOVES
const TRANSFORM_TEST_SPECIES: Array[StringName] = FieldDiagnostics.TRANSFORM_TEST_SPECIES
var _diagnostics := FieldDiagnostics.new()
var _elemental_test_index: int:
	get:
		return _diagnostics.index_for(&"elemental")
var _external_test_index: int:
	get:
		return _diagnostics.index_for(&"external")
var _switch_test_index: int:
	get:
		return _diagnostics.index_for(&"switch")
var _status_switch_index: int:
	get:
		return _diagnostics.index_for(&"status_switch")
var _weather_index: int:
	get:
		return _diagnostics.index_for(&"weather")
var _substitute_index: int:
	get:
		return _diagnostics.index_for(&"substitute")
var _transform_index: int:
	get:
		return _diagnostics.index_for(&"transform")

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
	elif _diagnostics.action_for_key(event.keycode) != &"":
		var action: StringName = _diagnostics.action_for_key(event.keycode)
		match action:
			&"tera":
				prepare_tera_visual_test()
			&"elemental":
				cycle_elemental_visual_test()
			&"external":
				cycle_external_damage_test()
			&"switch":
				cycle_switch_move_test()
			&"status_switch":
				cycle_status_switch_test()
			&"weather":
				cycle_weather_test()
			&"substitute":
				cycle_substitute_test()
			&"transform":
				cycle_transform_test()
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
	var request := _diagnostics.request_for(&"elemental")
	var move_id: StringName = request.get("move_id", &"")
	if not prepare_visual_move_test(move_id):
		return false
	_diagnostics.commit_success(&"elemental")
	return true


func cycle_external_damage_test() -> bool:
	var request := _diagnostics.request_for(&"external")
	var move_id: StringName = request.get("move_id", &"")
	if not prepare_visual_move_test(move_id):
		return false
	_diagnostics.commit_success(&"external")
	return true


func cycle_switch_move_test() -> bool:
	var request := _diagnostics.request_for(&"switch")
	var move_id: StringName = request.get("move_id", &"")
	if not prepare_visual_move_test(move_id, true):
		return false
	_diagnostics.commit_success(&"switch")
	return true


func prepare_visual_move_test(move_id: StringName, switch_rules: bool = false, weather_rules: bool = false, substitute_rules: bool = false, transform_rules: bool = false) -> bool:
	# Explicit disposable demo preset, NOT a learnset/TM or save-game mechanic.
	var classification := _diagnostics.describe_move(move_id)
	var external_damage := bool(classification.get("external_damage", false))
	var status_switch := bool(classification.get("status_switch", false))
	var transform := bool(classification.get("transform", false))
	var substitute := bool(classification.get("substitute", false))
	var weather := bool(classification.get("weather", false))
	if not _can_configure() or test_panel.is_panel_open() or not bool(classification.get("supported", false)):
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
	var request := _diagnostics.request_for(&"transform")
	var move_id: StringName = request.get("move_id", &"")
	if not prepare_visual_move_test(move_id, bool(request.get("switch_rules", false)), bool(request.get("weather_rules", false)), bool(request.get("substitute_rules", false)), bool(request.get("transform_rules", false))): return false
	var target: StringName = request.get("target_species", &"")
	_diagnostics.commit_success(&"transform")
	_notice_label.text = "F11 · Transformación · Ditto frente a %s · Reiniciar restaura el equipo." % SpanishGameText.species_name(target, _catalogs)
	_recorder.record(&"visual_test", &"transform_preset", {"move_id": "transform", "target_species": String(target), "mechanics_scope": "transform_singles_v1"})
	return true


func cycle_substitute_test() -> bool:
	var request := _diagnostics.request_for(&"substitute")
	var move_id: StringName = request.get("move_id", &"")
	if not prepare_visual_move_test(move_id, bool(request.get("switch_rules", false)), bool(request.get("weather_rules", false)), bool(request.get("substitute_rules", false))): return false
	var actor := _session.player.party.get_active()
	for id: StringName in [&"tackle", &"flamethrower", &"baton_pass"]:
		actor.add_move(id, _catalogs)
	_diagnostics.commit_success(&"substitute")
	_notice_label.text = "F10 · %s · Sustituto y relevo con elección de reserva · Reiniciar restaura el equipo." % _catalogs.move(move_id).display_name
	_recorder.record(&"visual_test", &"substitute_preset", {"move_id": String(move_id), "mechanics_scope": "substitute_singles_v1"})
	return true


func cycle_weather_test() -> bool:
	var request := _diagnostics.request_for(&"weather")
	var move_id: StringName = request.get("move_id", &"")
	if not prepare_visual_move_test(move_id, bool(request.get("switch_rules", false)), bool(request.get("weather_rules", false))): return false
	var actor := _session.player.party.get_active()
	for id: StringName in [&"water_gun", &"flamethrower", &"tackle"]:
		actor.add_move(id, _catalogs)
	_diagnostics.commit_success(&"weather")
	_notice_label.text = "F9 · %s · Clima persistente y ataques de prueba · Reiniciar restaura el equipo." % _catalogs.move(move_id).display_name
	_recorder.record(&"visual_test", &"weather_preset", {"move_id": String(move_id), "mechanics_scope": "weather_singles_v1"})
	return true


func cycle_status_switch_test() -> bool:
	var request := _diagnostics.request_for(&"status_switch")
	var move_id: StringName = request.get("move_id", &"")
	if not prepare_visual_move_test(move_id, true):
		return false
	if move_id == &"baton_pass":
		var actor := _session.player.party.get_active()
		actor.stat_stages.change(StatStages.ATTACK, 2)
		actor.stat_stages.change(StatStages.SPEED, 1)
	_notice_label.text = "F8 · %s · Ensayo de cambios de estado · Reiniciar restaura el learnset." % _catalogs.move(move_id).display_name
	_diagnostics.commit_success(&"status_switch")
	_recorder.record(&"visual_test", &"status_switch_preset", {"move_id": String(move_id), "mechanics_scope": "singles_status_switch_v1", "reset_restores_learnset": true})
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


func field_collection() -> PlayerCollection:
	return _session.player if _session != null else null


func field_definitions() -> DefinitionCatalog:
	return _catalogs


func field_can_configure() -> bool:
	if not is_demo_ready():
		return false
	return _can_configure()


func field_can_use_items() -> bool:
	if not is_demo_ready():
		return false
	return _can_use_field_items()


func field_can_open_item_bag() -> bool:
	if not is_demo_ready() or _native_battles == null:
		return false
	return _can_configure() and not test_panel.is_panel_open()


func field_activity_snapshot() -> Dictionary:
	return {
		"native_available": _native_battles != null,
		"native_occupied": _native_battles != null and _native_battles.occupied(),
		"traversal_busy": traversal_is_busy(),
		"panel_open": is_demo_ready() and test_panel.is_panel_open(),
		"gallery_open": _pokemon_gallery != null and _pokemon_gallery.visible,
		"doubles_open": _doubles_demo != null and _doubles_demo.visible,
		"bag_open": _item_bag != null and _item_bag.visible,
		"can_configure": field_can_configure(),
		"can_use_items": field_can_use_items(),
		"can_open_bag": field_can_open_item_bag(),
	}


func field_encounter_snapshot() -> Dictionary:
	var snapshot := encounter_expectation()
	snapshot["region_id"] = String(technical_region_id())
	return snapshot


func field_show_notice(message: String) -> void:
	if _notice_label != null:
		_notice_label.text = message


func field_refresh_hud() -> void:
	_refresh_hud()


func field_item_bag_opened() -> void:
	player.movement_enabled = false


func field_bind_item_service(service: RefCounted) -> bool:
	if service == null or not service.has_method("configure"):
		return false
	if _native_battles == null or not field_can_use_items():
		return false
	var collection := field_collection()
	var definitions := field_definitions()
	if collection == null or definitions == null:
		return false
	var clocks: Dictionary = _native_battles.clocks
	var binding := _field_item_binding_guard(collection, definitions, clocks)
	return bool(service.configure(collection, definitions, binding, clocks))


func field_item_service_is_current(service: RefCounted) -> bool:
	if service == null or not service.has_method("configure"):
		return false
	if _session == null or _session.player == null or _catalogs == null or _native_battles == null:
		return false
	return (
		is_same(service.get("owner"), _session.player)
		and is_same(service.get("catalogs"), _catalogs)
		and is_same(service.get("sleep_clocks"), _native_battles.clocks)
	)


func _field_item_binding_guard(collection: PlayerCollection, definitions: DefinitionCatalog, clocks: Dictionary) -> Callable:
	return func() -> bool:
		return field_can_use_items() and _field_item_binding_matches(collection, definitions, clocks)


func _field_item_binding_matches(collection: PlayerCollection, definitions: DefinitionCatalog, clocks: Dictionary) -> bool:
	if _session == null or _session.player == null or _catalogs == null or _native_battles == null:
		return false
	return is_same(_session.player, collection) and is_same(_catalogs, definitions) and is_same(_native_battles.clocks, clocks)


func _build_hud(canvas: CanvasLayer, theme: Theme) -> void:
	_hud = preload("res://scenes/visual/field_hud.gd").new()
	canvas.add_child(_hud)
	canvas.move_child(_hud, 0)
	_hud.build(theme, {
		"tera": prepare_tera_visual_test,
		"elemental": cycle_elemental_visual_test,
		"external": cycle_external_damage_test,
		"frequency": cycle_frequency,
		"restart": restart_field_run,
		"settings": _open_settings,
		"geometry": toggle_geometry_overlay,
		"gallery": toggle_pokemon_gallery,
		"report": func():
			_on_export_report_requested()
			_notice_label.text = "Informe exportado · F1 > ABRIR CARPETA DE INFORMES",
	})
	_place_label = _hud.place_label
	_frequency_label = _hud.frequency_label
	_observed_label = _hud.observed_label
	_collection_label = _hud.collection_label
	_chance_button = _hud.chance_button
	_notice_label = _hud.notice_label


func _hud_button(parent: Node, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _hud_snapshot() -> Dictionary:
	var region := technical_region_id()
	var expected := encounter_expectation()
	var current: Dictionary = technical_audit_summary().get("current_run", {})
	var encounters: Dictionary = current.get("encounters", {})
	var captures: Dictionary = current.get("capture", {})
	var species_id := StringName(String(_active_config.get("wild_species_id", "")))
	var species_label := "Pool aleatorio" if species_id == &"" else SpanishGameText.species_name(species_id, _catalogs)
	var cave := region == &"cave"
	var min_level := int(_active_config.get("cave_min_level" if cave else "wild_min_level", 4))
	var max_level := int(_active_config.get("cave_max_level" if cave else "wild_max_level", 6))
	return {
		"region_id": String(region),
		"cave_title_min_level": int(_active_config.get("cave_min_level", 8)),
		"cave_title_max_level": int(_active_config.get("cave_max_level", 12)),
		"encounters_enabled": bool(expected.get("enabled", false)),
		"encounter_percent": int(expected.get("percent", 0)),
		"mean_steps": (0.0 if not bool(expected.get("enabled", false)) else float(expected.get("mean_steps", 0.0))),
		"mean_walking_seconds": (0.0 if not bool(expected.get("enabled", false)) else float(expected.get("mean_walking_seconds", 0.0))),
		"rolls": int(encounters.get("rolls", 0)),
		"encounters": int(encounters.get("encounters", 0)),
		"captures": int(captures.get("successes", 0)),
		"grass_walking_seconds": float(_grass_walking_seconds),
		"party_size": int(demo_party_size()),
		"poke_balls": int(demo_inventory_quantity(&"poke_ball")),
		"species_label": species_label,
		"min_level": min_level,
		"max_level": max_level,
	}

func _refresh_hud() -> void:
	_hud.render_snapshot(_hud_snapshot())


func field_trainer_owner() -> TrainerCampaignRosterOwner:
	return _trainer_campaign_owner


func field_has_living_party() -> bool:
	var collection := field_collection()
	if collection == null or collection.party == null:
		return false
	return collection.party.get_creatures().any(func(creature: CreatureInstance): return creature != null and not creature.is_knocked_out())


func field_has_world_overlay() -> bool:
	if not is_inside_tree():
		return false
	return (
		(test_panel != null and test_panel.is_panel_open())
		or (_pokemon_gallery != null and _pokemon_gallery.visible)
		or (_item_bag != null and _item_bag.visible)
		or (_doubles_demo != null and _doubles_demo.visible)
	)


func field_attach_battle_view(view: Control) -> void:
	get_node("CanvasLayer").add_child(view)


func field_forward_battle_diagnostic(kind: String, entry: Dictionary) -> void:
	if kind == "trainer":
		_on_trainer_diagnostic_event(entry)
	else:
		_on_wild_diagnostic_event(entry)


func field_note_native_step(position: Vector2) -> StringName:
	if not is_inside_tree():
		return &""
	var zone := zone_at_position(position)
	_metrics.note_step(zone)
	_recorder.record(&"overworld", &"step_completed", {"x": position.x, "y": position.y, "zone_id": String(zone), "backend": "native"})
	return zone


func field_prepare_native_encounter(zone_id: StringName) -> Dictionary:
	if _director == null or _session == null or _catalogs == null:
		return {}
	if zone_id == &"" or not _director.has_zone(zone_id):
		return {}
	if not field_has_living_party():
		return {}
	var table := _director._tables.get(zone_id) as WildEncounterTable
	# O120: the only owner-side change. The pure helper returns the original table
	# unless the first party member really holds an active Cleanse Tag or Pure
	# Incense, in which case it returns a validated COPY with the 2/3 rate. The
	# authored table, resolver, metrics, seeds and RNG stream stay untouched.
	table = preload("res://modules/gameplay/encounter_item_modifiers.gd").prepare_table(table, _session.player.party.get_creatures())
	var staged := RandomNumberGenerator.new()
	staged.state = _director._encounter_rng.state
	var encounter := WildEncounterSystem.resolve(table, staged, _catalogs, _session.progression_ruleset)
	_metrics.note_encounter_roll(encounter.status == WildEncounterResult.ENCOUNTER, encounter.status, encounter.reason)
	if encounter.status == WildEncounterResult.NONE:
		_director._encounter_rng.state = staged.state
	elif encounter.status == WildEncounterResult.ENCOUNTER and encounter.creature != null:
		if _session.force_shiny_encounters and _catalogs.shiny_species_ids.has(String(encounter.creature.species_id)):
			encounter.creature.is_shiny = true
	return {"result": encounter, "next_rng": staged.state}


func field_native_seed() -> int:
	return _director._next_battle_seed if _director != null else -1


func field_commit_native_battle_start(next_rng: int, kind: StringName, format_id: String) -> void:
	if _director == null:
		return
	if next_rng != -1:
		_director._encounter_rng.state = next_rng
	var seed_value := _director._next_battle_seed
	_director._next_battle_seed += 1
	_metrics.note_battle_started(kind)
	_recorder.record(kind, &"battle_started", {"backend": "native", "format": format_id, "seed": seed_value})


func field_lock_battle_world() -> void:
	if player == null:
		return
	player.movement_enabled = false
	player.velocity = Vector2.ZERO


func field_show_battle_view(view: Control) -> void:
	if view == null:
		return
	get_window().content_scale_size = Vector2i(1280, 720)
	view.show()
	if _hud != null:
		_hud.hide()


func field_unlock_battle_world() -> void:
	get_window().content_scale_size = Vector2i(960, 540)
	if player != null:
		player.reset_step_meter()
	player.movement_enabled = not (test_panel != null and test_panel.is_panel_open())


func field_record_native_battle_closed(reason: String) -> void:
	_recorder.record(&"native", &"battle_closed", {"reason": reason})


func field_player_position() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return player.global_position


func field_player_movement_enabled() -> bool:
	return player != null and player.movement_enabled


func field_native_world_snapshot(format_id: String) -> Dictionary:
	var position := field_player_position()
	return {"position": [position.x, position.y], "region": String(technical_region_id()),
		"config": _active_config.duplicate(true), "rng": str(_director._encounter_rng.state), "next_seed": _director._next_battle_seed, "format": format_id}


func field_build_native_encounter_tables(config: Dictionary) -> Dictionary:
	var tables := {}
	for key: String in ["player_team", "trainer_team"]:
		if not config.get(key) is Array or config[key].is_empty() or config[key].size() > 6: return {}
		for row: Variant in config[key]:
			if not row is Dictionary or not row.get("species_id") is String or not (row.get("level") is int or row.get("level") is float) or row.level != int(row.level) or row.level < 1 or row.level > 100: return {}
	if not config.get("wild_species_id") is String: return {}
	for key: String in ["wild_min_level", "wild_max_level", "cave_min_level", "cave_max_level", "encounter_chance_percent"]:
		if not (config.get(key) is float or config.get(key) is int) or int(config[key]) != config[key] or config[key] < 0 or config[key] > 100: return {}
	var species := String(config.get("wild_species_id", "")).trim_suffix("__shiny")
	if String(config.get("wild_species_id", "")).ends_with("__shiny") and not _catalogs.shiny_species_ids.has(species): return {}
	for row: Array in [[TECHNICAL_ZONE_ID, "wild_min_level", "wild_max_level"], [TECHNICAL_CAVE_ZONE_ID, "cave_min_level", "cave_max_level"]]:
		if config[row[1]] < 1 or config[row[2]] < config[row[1]]: return {}
		var built := TechnicalEncounterPoolBuilder.build(_catalogs, row[0], int(config.encounter_chance_percent), int(config[row[1]]), int(config[row[2]]), StringName(species))
		if not built.ok: return {}
		tables[row[0]] = built.table
	return tables


func field_validate_native_loaded_world(world: Dictionary) -> Dictionary:
	if not world.get("region") is String or not world.get("position") is Array or world.position.size() != 2 or not world.get("config") is Dictionary or world.get("format") not in ["gen8customgame", "gen9customgame", "gen9calvounifiedv1"] or not world.get("rng") is String or not world.rng.is_valid_int() or not (world.get("next_seed") is int or world.get("next_seed") is float): return {"ok": false, "error": "world_shape"}
	for v: Variant in world.position:
		if not (v is int or v is float) or not is_finite(v): return {"ok": false, "error": "world_position"}
	var position := Vector2(world.position[0], world.position[1])
	if position.x < 16 or position.x > 1280 or position.y < 16 or position.y > 850 or String(_region_at_position(position)) != world.get("region") or not traversal_controller._destination_is_clear(position): return {"ok": false, "error": "world_position"}
	if world.next_seed != int(world.next_seed) or world.next_seed < 1 or world.next_seed > 2147483646: return {"ok": false, "error": "world_seed"}
	var tables := field_build_native_encounter_tables(world.config)
	if tables.is_empty(): return {"ok": false, "error": "world_encounters"}
	return {"ok": true, "position": position, "tables": tables}


func field_publish_native_loaded_world(collection: PlayerCollection, trainer: TrainerCampaignRosterOwner, world: Dictionary, position: Vector2, tables: Dictionary) -> void:
	_session = WildAdventureSession.new(collection, _catalogs, ProgressionRuleset.new())
	_trainer_session = TrainerBattleSession.new(collection, _catalogs, ProgressionRuleset.new())
	_trainer_campaign_owner = trainer
	_active_config = world.config.duplicate(true)
	test_panel.restore_configuration(world.config)
	_trainer_profile_id = StringName(world.config.get("trainer_profile_id", "balanced"))
	_trainer_expertise_id = StringName(world.config.get("trainer_expertise_id", "full"))
	_session.force_shiny_encounters = String(world.config.get("wild_species_id", "")).ends_with("__shiny")
	_director.session = _session; _director._tables = tables
	_director._encounter_rng.state = int(world.rng); _director._next_battle_seed = int(world.next_seed)
	player.global_position = position; player.reset_step_meter()


func field_refresh_legacy_presentations() -> void:
	_configure_presentations()
