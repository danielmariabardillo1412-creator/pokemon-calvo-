extends "res://scenes/visual/showdown_adventure_lab.gd"

signal return_requested
const GrowthChoices = preload("res://scenes/visual/field_growth_choices.gd")
var owner_bridge: Node
var _evolution_choices: VBoxContainer


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
	right.move_child(_capture_balls, 6)
	right.move_child(capture_row, 7)
	_continue_button.text = "Volver al mapa"
	_save.text = "Guardar partida"; _load.text = "Cargar partida"
	_evolution_choices = GrowthChoices.new()
	right.add_child(_evolution_choices); right.move_child(_evolution_choices, _continue_button.get_index())
	_evolution_choices.chosen.connect(func(value): _resolve_evolution(StringName(value)))
	_evolution_choices.cancelled.connect(func(): _resolve_evolution(&""))
	for c: Node in _continue_button.get_parent().get_children():
		if c is Label and c.text.contains("SHOWDOWN"): c.text = "COMBATE"
		if c is Label and c.text.begins_with("Reglas de "): c.hide()


func new_battle() -> bool:
	if session == null or session.has_active_battle() or session.has_level_evolution_choice() or _playback.is_playing(): return false
	return_requested.emit()
	return true


func _refresh_view() -> void:
	super._refresh_view()
	if session == null or session.battle_state() == null or _ball == null: return
	var locked: bool = _working or session.busy or _playback.is_playing()
	var wild: bool = session.battle_kind == "wild"
	_ball.visible = wild; _master.visible = wild; _flee.visible = wild
	_capture_balls.visible = wild
	_continue_button.text = "Volver al mapa"
	_save.show(); _load.show()
	var pending: bool = session.has_level_evolution_choice()
	_continue_button.disabled = _continue_button.disabled or pending
	_save.disabled = locked or pending or owner_bridge == null
	_load.disabled = locked or pending or owner_bridge == null or not FileAccess.file_exists(owner_bridge.save_path)
	if session.completion_reason == "VICTORY":
		var active: CreatureInstance = session.battle_state().active_for_side(&"side_a")
		var owned := player.owned_creature(active.instance_id)
		if owned != null:
			_player_label.text = _creature_label(owned)
			_player_hp.max_value = owned.stats.max_hp
			_player_hp.value = owned.current_hp
			_arena.player_species = owned.appearance_id()
	if pending and not _evolution_choices.visible:
		_evolution_choices.present(session.level_evolution_prompt(), catalogs, "Omitir evolución")
		var scroll := _evolution_choices.get_parent().get_parent() as ScrollContainer
		scroll.ensure_control_visible.call_deferred(_evolution_choices)


func save_battle(_path: String = "") -> bool:
	if owner_bridge == null: return false
	return owner_bridge.save_game()


func load_battle(_path: String = "") -> bool:
	if owner_bridge == null: return false
	return await owner_bridge.load_game()


func resume_battle() -> bool:
	if owner_bridge == null: return false
	return await owner_bridge.recover_battle()


func _resolve_evolution(target: StringName) -> void:
	if session == null or not _evolution_choices.visible: return
	if not session.resolve_level_evolution(target):
		_event_log.append_text("\nNo se pudo aplicar la evolución.")
		return
	_evolution_choices.hide()
	if target != &"":
		_event_log.append_text("\n¡Ha evolucionado a %s!" % SpanishGameText.species_name(target, catalogs))
	_refresh_view()
