class_name SpanishBattlePresentationController
extends BattlePresentationController

# Spanish presentation adapter for the current executable slice.
# Battle/domain contracts and stable IDs remain language-neutral.


func _ready() -> void:
	super._ready()
	_translate_control_tree(self)


func _refresh_view() -> void:
	super._refresh_view()
	if session == null or catalogs == null or not session.has_active_battle():
		return
	var state := session.battle_state()
	var player_creature := session.player_active()
	var enemy_creature := session.current_wild()
	if state == null or player_creature == null or enemy_creature == null:
		return

	_turn_label.text = "Combate terminado" if state.phase == BattleState.FINISHED else "Turno %d" % (state.turn + 1)
	_player_label.text = "%s  Nv.%d   PS %d/%d" % [
		SpanishGameText.species_name(player_creature.species_id, catalogs),
		player_creature.level,
		player_creature.current_hp,
		player_creature.stats.max_hp,
	]
	_enemy_label.text = "Salvaje: %s  Nv.%d   PS %d/%d" % [
		SpanishGameText.species_name(enemy_creature.species_id, catalogs),
		enemy_creature.level,
		enemy_creature.current_hp,
		enemy_creature.stats.max_hp,
	]

	var moves := available_move_ids()
	for i in _move_buttons.size():
		if i >= moves.size():
			continue
		var move_id := moves[i]
		var slot := player_creature.move_slot(move_id)
		if slot != null:
			_move_buttons[i].text = "%s  PP %d/%d" % [
				SpanishGameText.move_name(move_id, catalogs),
				slot.current_pp,
				slot.max_pp,
			]

	var balls := available_capture_ball_ids()
	for i in _capture_buttons.size():
		if i >= balls.size():
			continue
		var ball_id := balls[i]
		_capture_buttons[i].text = "%s  x%d" % [
			SpanishGameText.item_name(ball_id, catalogs),
			session.player.inventory.quantity(ball_id),
		]

	_refresh_switch_controls_es(state, state.phase == BattleState.WAITING_FOR_ACTIONS)
	_translate_control_tree(self)


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


func _append_log(text: String) -> void:
	super._append_log(SpanishGameText.translate_runtime_message(text))


func _present_completed_command(label: String) -> void:
	super._present_completed_command(label)
	if _turn_label != null:
		_turn_label.text = "Capturado" if label == "Captured" else "Huida completada"
	if _continue_button != null:
		_continue_button.text = "Volver al mundo"


func _refresh_switch_controls_es(state: BattleState, waiting: bool) -> void:
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


func _creature_label(instance_id: StringName) -> String:
	if session != null and session.has_active_battle():
		var state := session.battle_state()
		if state != null:
			var creature := state.creature(instance_id)
			if creature != null:
				return SpanishGameText.species_name(creature.species_id, catalogs)
	return String(instance_id).replace("_", " ").capitalize()


func _translate_control_tree(node: Node) -> void:
	if node is Label:
		var label := node as Label
		match label.text:
			"Moves": label.text = "Movimientos"
			"Switch": label.text = "Cambiar"
			"Capture": label.text = "Captura"
			"Turn 1": label.text = "Turno 1"
			"Wild opponent": label.text = "Pokémon salvaje"
			"Player creature": label.text = "Tu Pokémon"
			"[ PLAYER ]": label.text = "[ JUGADOR ]"
			"[ WILD ]": label.text = "[ SALVAJE ]"
	elif node is Button:
		var button := node as Button
		match button.text:
			"Switch": button.text = "Cambiar"
			"Run": button.text = "Huir"
			"Return to overworld": button.text = "Volver al mundo"
	for child in node.get_children():
		_translate_control_tree(child)
