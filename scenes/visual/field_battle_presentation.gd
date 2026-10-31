extends "res://scenes/debug/diagnostic_wild_battle_presentation.gd"

# Only layout and sprites change. Every button still invokes the certified controller.
const ArenaArt = preload("res://scenes/visual/battle_art.gd")
const AnimationPlayback = preload("res://scenes/visual/battle_animation_playback.gd")
const Weather = preload("res://modules/battle/application/weather_rules.gd")
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
	_playback = AnimationPlayback.new()
	_playback.configure(self, _arena)
	add_child(_playback)


func submit_player_move(move_id: StringName) -> Array[BattleEvent]:
	if _playback.is_playing():
		return []
	return super.submit_player_move(move_id)


func submit_player_switch(instance_id: StringName) -> WildBattleCommandResult:
	if _playback.is_playing():
		return _busy_result(WildBattleCommand.ACTION)
	if session != null and session.battle_state() != null and session.battle_state().phase == BattleState.WAITING_FOR_SWITCH:
		diagnostic_event.emit({"event": "command", "scope": "wild", "kind": "switch_choice", "switch_instance_id": String(instance_id)})
		var result := session.submit_switch_choice(instance_id, session.battle_state().turn)
		_render_events(result.battle_events)
		_refresh_view()
		if session.battle_state().phase == BattleState.FINISHED:
			_settle_finished_battle()
		_emit_command_result("switch_choice", result)
		return result
	return super.submit_player_switch(instance_id)


func submit_capture_ball(ball_id: StringName) -> WildBattleCommandResult:
	if _playback.is_playing():
		return _busy_result(WildBattleCommand.CAPTURE)
	return super.submit_capture_ball(ball_id)


func submit_player_run() -> WildBattleCommandResult:
	if _playback.is_playing():
		return _busy_result(WildBattleCommand.RUN)
	return super.submit_player_run()


func continue_after_completion() -> bool:
	return false if _playback.is_playing() else super.continue_after_completion()


func _busy_result(kind: StringName) -> WildBattleCommandResult:
	var result := WildBattleCommandResult.new()
	result.command_type = kind
	result.reason = "visual_playback_busy"
	return result


func _refresh_view() -> void:
	super._refresh_view()
	if _playback != null and _playback.is_playing():
		_playback.enforce_input_lock()
		_playback.restore_display()
		return
	if _arena == null or session == null:
		return
	var state := session.battle_state()
	if state != null and state.phase == BattleState.WAITING_FOR_SWITCH:
		_turn_label.text = "Elige el Pokémon que entra · continúa el mismo turno"
		_refresh_switch_controls_es(state, state.pending_switch.get("side_id", "") == "side_a")
		_switch_button.text = "Enviar"
	elif _switch_button != null:
		_switch_button.text = "Cambiar"
	if state != null and state.weather_rules_enabled and not state.weather.is_empty():
		_turn_label.text += " · Clima: " + Weather.label(Weather.presentation(state))
	var actor := session.player_active()
	var wild := session.current_wild()
	if actor != null:
		_arena.player_species = actor.appearance_id()
	if wild != null:
		_arena.enemy_species = wild.appearance_id()


func _settle_finished_battle() -> void:
	if session.battle_state().end_reason == &"forced_escape":
		var settlement := session.settle_finished_battle()
		if settlement.ok:
			_completion_reason = session.completion_reason
			_append_log("El encuentro terminó por expulsión. Sin experiencia ni captura.")
			_present_completed_command("Fled")
		return
	super._settle_finished_battle()


func _render_events(events: Array[BattleEvent]) -> void:
	_playback.note_event_messages(events)
	super._render_events(events)


func _event_text(event: BattleEvent) -> String:
	if event != null:
		match event.kind:
			BattleEvent.TRANSFORMED: return "%s se transformó en %s." % [_creature_label(event.actor_id), SpanishGameText.species_name(StringName(event.metadata.get("species_id", "")), catalogs)]
			BattleEvent.TRANSFORM_REVERTED: return "%s recuperó su forma original." % _creature_label(event.actor_id)
			BattleEvent.TRANSFORM_FAILED: return "No se pudo completar la transformación."
			BattleEvent.HP_COST: return "%s cedió %d PS para crear el sustituto." % [_creature_label(event.actor_id), event.amount]
			BattleEvent.SUBSTITUTE_CREATED: return "%s creó un sustituto." % _creature_label(event.target_id)
			BattleEvent.SUBSTITUTE_DAMAGED: return "El sustituto recibió el golpe (%d PS)." % event.amount
			BattleEvent.SUBSTITUTE_BROKEN: return "El sustituto se ha roto."
			BattleEvent.SUBSTITUTE_BLOCKED: return "El sustituto bloqueó el efecto sobre el Pokémon."
			BattleEvent.SUBSTITUTE_TRANSFERRED: return "%s recibió el sustituto." % _creature_label(event.target_id)
			BattleEvent.SUBSTITUTE_FAILED:
				return {"already_substitute": "Ya tiene un sustituto.", "no_reserve": "No quedan reservas para el relevo.", "insufficient_hp": "No tiene suficientes PS para crear un sustituto."}.get(event.metadata.get("reason", ""), "No se pudo crear el sustituto.")
	if event != null and event.kind == BattleEvent.STATUS_DAMAGE and event.metadata.get("cause", "") == "weather":
		var climate := "el granizo" if event.metadata.get("weather_id") == "hail" else "la tormenta de arena"
		return "%s perdió %d PS por %s." % [_creature_label(event.target_id), event.amount, climate]
	if event != null and event.kind == BattleEvent.HP_RECOVERED and event.metadata.get("cause", "") == "weather_ability":
		return "%s recuperó %d PS por su habilidad." % [_creature_label(event.target_id), event.amount]
	if event != null and event.kind in [BattleEvent.WEATHER_CHANGED, BattleEvent.WEATHER_UPKEEP]:
		return "Clima: " + Weather.label(event.metadata.get("weather", {}))
	if event != null and event.kind == BattleEvent.WEATHER_ENDED:
		return "El clima ha terminado."
	if event != null and event.kind == BattleEvent.WEATHER_FAILED:
		return "Ese clima ya está activo; no se prolonga su duración."
	if event != null and event.kind == BattleEvent.SWITCH_REQUESTED:
		return "Elige una reserva para completar el relevo. El turno está en pausa."
	if event != null and event.kind == BattleEvent.SWITCH_EFFECT_FAILED:
		var reason := String(event.metadata.get("reason", ""))
		return {"no_reserve": "No quedan Pokémon de reserva que puedan entrar.",
			"wild_level": "No pudo expulsar al Pokémon salvaje por su nivel.",
			"no_stat_change": "No fue posible cambiar esas estadísticas.",
			"blocked": "El objetivo ha bloqueado el movimiento."}.get(reason,
			"El estado o la habilidad del objetivo impidió completar el cambio o la expulsión.")
	if event != null and event.kind == BattleEvent.STAT_STAGE_CHANGED:
		var stat := String(event.metadata.get("stat_id", ""))
		var label := String({"attack": "Ataque", "defense": "Defensa", "special_attack": "Ataque Especial",
			"special_defense": "Defensa Especial", "speed": "Velocidad", "accuracy": "Precisión", "evasion": "Evasión"}.get(stat, "Estadística"))
		if event.amount == 0:
			return "%s: %s no pudo cambiar." % [_creature_label(event.target_id), label]
		return "%s: %s %s %d %s." % [_creature_label(event.target_id), label,
			"subió" if event.amount > 0 else "bajó", absi(event.amount), "nivel" if absi(event.amount) == 1 else "niveles"]
	if event != null and event.kind == BattleEvent.MOVE_EFFECT_RESOLVED:
		return "Se ha resuelto el efecto de %s." % SpanishGameText.move_name(event.move_id, catalogs)
	if event != null and event.kind == BattleEvent.MOVE_REFLECTED:
		return "%s ha reflejado el movimiento." % _creature_label(event.actor_id)
	if event != null and event.kind == BattleEvent.BATTLE_ENDED and event.metadata.get("reason") == "forced_escape":
		return "El movimiento ha terminado el encuentro salvaje."
	return super._event_text(event)


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
