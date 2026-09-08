class_name TrainerBattlePresentationController
extends Control

signal battle_closed(reason: StringName)

# Trainer-only presentation seam for the executable technical slice.
# It never owns Battle rules, never exposes Capture/Run and never constructs a side_b action.
# Every player MOVE/SWITCH is submitted through TrainerBattleSession's autonomous side_b API.

var session: TrainerBattleSession = null
var catalogs: DefinitionCatalog = null

var _enemy_label: Label = null
var _enemy_hp: ProgressBar = null
var _player_label: Label = null
var _player_hp: ProgressBar = null
var _turn_label: Label = null
var _event_log: RichTextLabel = null
var _move_buttons: Array[Button] = []
var _switch_selector: OptionButton = null
var _switch_button: Button = null
var _continue_button: Button = null
var _completion_reason: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


func configure(p_session: TrainerBattleSession, p_catalogs: DefinitionCatalog) -> void:
	session = p_session
	catalogs = p_catalogs


func open_for_active_battle() -> bool:
	if session == null or catalogs == null or not session.has_active_battle():
		return false
	_completion_reason = &""
	visible = true
	if _continue_button != null:
		_continue_button.visible = false
	_clear_log()
	_append_log("¡El entrenador %s te desafía!" % String(session.opponent_trainer_id))
	_refresh_view()
	return true


func is_presenting_battle() -> bool:
	return visible and session != null and (
		session.has_active_battle() or session.status == TrainerBattleSession.COMPLETED
	)


func completion_reason() -> StringName:
	return _completion_reason


func available_move_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if session == null or catalogs == null or not session.has_active_battle():
		return result
	var actor := session.player_active()
	if actor == null:
		return result
	for slot_variant in actor.moveset:
		var slot := slot_variant as BattleMoveSlot
		if slot != null and slot.current_pp > 0 and catalogs.move(slot.move_id) != null:
			result.append(slot.move_id)
	return result


func available_switch_instance_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if session == null or not session.has_active_battle():
		return result
	var state := session.battle_state()
	var actor := session.player_active()
	if state == null or actor == null:
		return result
	var side := state.side_for_creature(actor.instance_id)
	if side == null:
		return result
	for instance_id in side.party_ids:
		if instance_id == side.active_id:
			continue
		var candidate := state.creature(instance_id)
		if candidate != null and not candidate.is_knocked_out():
			result.append(instance_id)
	return result


func move_button_count() -> int:
	var count := 0
	for button in _move_buttons:
		if button.visible:
			count += 1
	return count


func switch_option_count() -> int:
	return _switch_selector.item_count if _switch_selector != null else 0


func switch_control_enabled() -> bool:
	return (
		_switch_selector != null
		and _switch_button != null
		and not _switch_selector.disabled
		and not _switch_button.disabled
	)


func selected_switch_instance_id() -> StringName:
	if _switch_selector == null:
		return &""
	var index := _switch_selector.selected
	if index < 0 or index >= _switch_selector.item_count:
		return &""
	var metadata = _switch_selector.get_item_metadata(index)
	if metadata == null:
		return &""
	return StringName(String(metadata))


func displayed_player_hp() -> int:
	return int(_player_hp.value) if _player_hp != null else -1


func displayed_enemy_hp() -> int:
	return int(_enemy_hp.value) if _enemy_hp != null else -1


func submit_player_move(move_id: StringName) -> Array[BattleEvent]:
	var empty: Array[BattleEvent] = []
	if session == null or catalogs == null or not session.has_active_battle():
		_append_log("No hay un combate contra entrenador activo.")
		return empty
	var state := session.battle_state()
	var actor := session.player_active()
	var target := session.opponent_active()
	if state == null or actor == null or target == null:
		_append_log("El estado del combate está incompleto.")
		return empty
	var slot := actor.move_slot(move_id)
	if slot == null or slot.current_pp <= 0 or catalogs.move(move_id) == null:
		_append_log("Ese movimiento no se puede usar ahora.")
		return empty
	var player_side := state.side_for_creature(actor.instance_id)
	if player_side == null or player_side.side_id != &"side_a":
		_append_log("La propiedad del lado del jugador está incompleta.")
		return empty

	var player_action := BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		move_id,
		target.instance_id,
		BattleAction.MOVE,
		player_side.side_id,
	)
	return _submit_autonomous_player_action(player_action)


func submit_player_switch(switch_instance_id: StringName) -> Array[BattleEvent]:
	var empty: Array[BattleEvent] = []
	if session == null or catalogs == null or not session.has_active_battle():
		_append_log("No hay un combate contra entrenador activo.")
		return empty
	var state := session.battle_state()
	var actor := session.player_active()
	if state == null or actor == null:
		_append_log("El estado del combate está incompleto.")
		return empty
	if not available_switch_instance_ids().has(switch_instance_id):
		_append_log("Ese cambio no está disponible.")
		return empty
	var player_side := state.side_for_creature(actor.instance_id)
	if player_side == null or player_side.side_id != &"side_a":
		_append_log("La propiedad del lado del jugador está incompleta.")
		return empty

	var player_action := BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		&"",
		&"",
		BattleAction.SWITCH,
		player_side.side_id,
		switch_instance_id,
	)
	return _submit_autonomous_player_action(player_action)


func continue_after_completion() -> bool:
	if session == null or session.status != TrainerBattleSession.COMPLETED:
		return false
	var reason := session.completion_reason
	if not session.reset_after_completion():
		return false
	_completion_reason = reason
	visible = false
	battle_closed.emit(reason)
	return true


func _submit_autonomous_player_action(player_action: BattleAction) -> Array[BattleEvent]:
	var events := session.submit_player_action_with_autonomous_trainer(player_action)
	_render_events(events)
	if not session.last_error.is_empty():
		_append_log("Acción rechazada: %s" % session.last_error)
		_refresh_view()
		return events
	_refresh_view()
	var post_state := session.battle_state()
	if post_state != null and post_state.phase == BattleState.FINISHED:
		_settle_finished_battle()
	return events


func _on_move_pressed(index: int) -> void:
	var ids := available_move_ids()
	if index < 0 or index >= ids.size():
		return
	submit_player_move(ids[index])


func _on_switch_pressed() -> void:
	var instance_id := selected_switch_instance_id()
	if instance_id == &"":
		return
	submit_player_switch(instance_id)


func _on_continue_pressed() -> void:
	continue_after_completion()


func _settle_finished_battle() -> void:
	var settlement := session.settle_finished_battle()
	if settlement == null or not settlement.ok:
		_append_log("El combate terminó, pero falló el cierre: %s" % (
			settlement.reason if settlement != null else "missing_settlement"
		))
		_set_command_controls_enabled(false)
		return
	_completion_reason = session.completion_reason
	if settlement.player_won:
		_append_log("Victoria. La progresión se ha reconciliado.")
	else:
		_append_log("Derrota. El estado persistente se ha reconciliado.")
	_set_command_controls_enabled(false)
	if _continue_button != null:
		_continue_button.text = "Volver al mundo"
		_continue_button.visible = true


func _refresh_view() -> void:
	if _enemy_label == null:
		return
	if session == null or not session.has_active_battle():
		_set_command_controls_enabled(false)
		return
	var state := session.battle_state()
	var player_creature := session.player_active()
	var enemy_creature := session.opponent_active()
	if state == null or player_creature == null or enemy_creature == null:
		_set_command_controls_enabled(false)
		return

	_turn_label.text = "Combate terminado" if state.phase == BattleState.FINISHED else "Turno %d" % (state.turn + 1)
	_player_label.text = "%s  Nv.%d   PS %d/%d" % [
		SpanishGameText.species_name(player_creature.species_id, catalogs),
		player_creature.level,
		player_creature.current_hp,
		player_creature.stats.max_hp,
	]
	_player_hp.max_value = maxi(1, player_creature.stats.max_hp)
	_player_hp.value = player_creature.current_hp
	_enemy_label.text = "Entrenador: %s  Nv.%d   PS %d/%d" % [
		SpanishGameText.species_name(enemy_creature.species_id, catalogs),
		enemy_creature.level,
		enemy_creature.current_hp,
		enemy_creature.stats.max_hp,
	]
	_enemy_hp.max_value = maxi(1, enemy_creature.stats.max_hp)
	_enemy_hp.value = enemy_creature.current_hp

	var waiting := state.phase == BattleState.WAITING_FOR_ACTIONS
	var moves := available_move_ids()
	for i in _move_buttons.size():
		var move_button := _move_buttons[i]
		if i < moves.size():
			var move_id := moves[i]
			var slot := player_creature.move_slot(move_id)
			move_button.text = "%s  PP %d/%d" % [
				SpanishGameText.move_name(move_id, catalogs),
				slot.current_pp,
				slot.max_pp,
			]
			move_button.visible = true
			move_button.disabled = not waiting
		else:
			move_button.text = "-"
			move_button.visible = false

	_refresh_switch_controls(state, waiting)


func _refresh_switch_controls(state: BattleState, waiting: bool) -> void:
	if _switch_selector == null or _switch_button == null:
		return
	_switch_selector.clear()
	for instance_id in available_switch_instance_ids():
		var candidate := state.creature(instance_id)
		if candidate == null:
			continue
		_switch_selector.add_item("%s Nv.%d  PS %d/%d" % [
			SpanishGameText.species_name(candidate.species_id, catalogs),
			candidate.level,
			candidate.current_hp,
			candidate.stats.max_hp,
		])
		var item_index := _switch_selector.item_count - 1
		_switch_selector.set_item_metadata(item_index, String(instance_id))
	var can_switch := waiting and _switch_selector.item_count > 0
	_switch_selector.disabled = not can_switch
	_switch_button.disabled = not can_switch


func _set_command_controls_enabled(enabled: bool) -> void:
	for button in _move_buttons:
		button.disabled = not enabled
	if not enabled:
		if _switch_selector != null:
			_switch_selector.disabled = true
		if _switch_button != null:
			_switch_button.disabled = true
	else:
		var can_switch := not available_switch_instance_ids().is_empty()
		if _switch_selector != null:
			_switch_selector.disabled = not can_switch
		if _switch_button != null:
			_switch_button.disabled = not can_switch


func _render_events(events: Array[BattleEvent]) -> void:
	for event in events:
		_append_log(_event_text(event))


func _event_text(event: BattleEvent) -> String:
	if event == null:
		return "Evento de combate desconocido."
	match event.kind:
		BattleEvent.ACTION_USED:
			return "%s ha usado %s." % [
				_creature_label(event.actor_id),
				SpanishGameText.move_name(event.move_id, catalogs),
			]
		BattleEvent.MOVE_MISSED:
			return "¡%s ha fallado %s!" % [
				_creature_label(event.actor_id),
				SpanishGameText.move_name(event.move_id, catalogs),
			]
		BattleEvent.DAMAGE_APPLIED:
			return "%s ha perdido %d PS." % [_creature_label(event.target_id), event.amount]
		BattleEvent.CRITICAL_HIT:
			return "¡Golpe crítico!"
		BattleEvent.TYPE_EFFECTIVENESS:
			return SpanishGameText.effectiveness_text(float(event.metadata.get("multiplier", 1.0)))
		BattleEvent.KNOCKED_OUT:
			return "¡%s se ha debilitado!" % _creature_label(event.target_id)
		BattleEvent.STATUS_APPLIED:
			return "%s ha sufrido un problema de estado." % _creature_label(event.target_id)
		BattleEvent.ACTION_PREVENTED:
			return "%s no ha podido actuar." % _creature_label(event.actor_id)
		BattleEvent.SWITCHED:
			return "%s ha cambiado a %s." % [
				_creature_label(event.actor_id),
				_creature_label(event.target_id),
			]
		BattleEvent.BATTLE_ENDED:
			return "El combate ha terminado."
		BattleEvent.ACTION_REJECTED:
			return "Acción rechazada."
		_:
			return "Evento de combate: %s" % String(event.kind).replace("_", " ")


func _creature_label(instance_id: StringName) -> String:
	if session != null and session.has_active_battle():
		var state := session.battle_state()
		if state != null:
			var creature := state.creature(instance_id)
			if creature != null:
				return SpanishGameText.species_name(creature.species_id, catalogs)
	return String(instance_id).replace("_", " ").capitalize()


func _append_log(text: String) -> void:
	if _event_log == null or text.is_empty():
		return
	if not _event_log.text.is_empty():
		_event_log.text += "\n"
	_event_log.text += text
	_event_log.scroll_to_line(maxi(0, _event_log.get_line_count() - 1))


func _clear_log() -> void:
	if _event_log != null:
		_event_log.text = ""


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.045, 0.07, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 28)
	frame.add_theme_constant_override("margin_top", 20)
	frame.add_theme_constant_override("margin_right", 28)
	frame.add_theme_constant_override("margin_bottom", 20)
	add_child(frame)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	frame.add_child(root)

	_turn_label = Label.new()
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_label.text = "Turno 1"
	root.add_child(_turn_label)

	_enemy_label = Label.new()
	_enemy_label.text = "Entrenador rival"
	root.add_child(_enemy_label)
	_enemy_hp = ProgressBar.new()
	_enemy_hp.show_percentage = false
	_enemy_hp.custom_minimum_size = Vector2(0, 18)
	root.add_child(_enemy_hp)

	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(arena)
	var player_marker := Label.new()
	player_marker.text = "[ JUGADOR ]"
	player_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(player_marker)
	var versus := Label.new()
	versus.text = "VS"
	versus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	versus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	versus.custom_minimum_size = Vector2(60, 48)
	arena.add_child(versus)
	var enemy_marker := Label.new()
	enemy_marker.text = "[ ENTRENADOR ]"
	enemy_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(enemy_marker)

	_player_label = Label.new()
	_player_label.text = "Tu Pokémon"
	root.add_child(_player_label)
	_player_hp = ProgressBar.new()
	_player_hp.show_percentage = false
	_player_hp.custom_minimum_size = Vector2(0, 18)
	root.add_child(_player_hp)

	_event_log = RichTextLabel.new()
	_event_log.custom_minimum_size = Vector2(0, 54)
	_event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_log.scroll_active = true
	root.add_child(_event_log)

	var moves_title := Label.new()
	moves_title.text = "Movimientos"
	root.add_child(moves_title)
	var moves := GridContainer.new()
	moves.columns = 2
	moves.add_theme_constant_override("h_separation", 8)
	moves.add_theme_constant_override("v_separation", 4)
	root.add_child(moves)
	for i in 4:
		var move_button := Button.new()
		move_button.text = "-"
		move_button.custom_minimum_size = Vector2(0, 32)
		move_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		move_button.pressed.connect(_on_move_pressed.bind(i))
		moves.add_child(move_button)
		_move_buttons.append(move_button)

	var switch_row := HBoxContainer.new()
	switch_row.add_theme_constant_override("separation", 8)
	root.add_child(switch_row)
	var switch_title := Label.new()
	switch_title.text = "Cambiar"
	switch_row.add_child(switch_title)
	_switch_selector = OptionButton.new()
	_switch_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_switch_selector.disabled = true
	switch_row.add_child(_switch_selector)
	_switch_button = Button.new()
	_switch_button.text = "Cambiar"
	_switch_button.disabled = true
	_switch_button.pressed.connect(_on_switch_pressed)
	switch_row.add_child(_switch_button)

	_continue_button = Button.new()
	_continue_button.text = "Volver al mundo"
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	root.add_child(_continue_button)
