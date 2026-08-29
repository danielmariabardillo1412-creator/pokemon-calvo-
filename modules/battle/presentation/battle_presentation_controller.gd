class_name BattlePresentationController
extends Control

signal battle_closed(reason: StringName)

# Technical, asset-free presentation adapter. The authoritative state remains inside
# WildAdventureSession/Battle Core. This Control only reads state, builds legal player/opponent
# actions, submits them through the application boundary, and renders semantic BattleEvents.

var session: WildAdventureSession = null
var catalogs: DefinitionCatalog = null

var _enemy_label: Label = null
var _enemy_hp: ProgressBar = null
var _player_label: Label = null
var _player_hp: ProgressBar = null
var _turn_label: Label = null
var _event_log: RichTextLabel = null
var _move_buttons: Array[Button] = []
var _continue_button: Button = null
var _completion_reason: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


func configure(p_session: WildAdventureSession, p_catalogs: DefinitionCatalog) -> void:
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
	var wild := session.current_wild()
	if wild != null:
		_append_log("A wild %s Lv.%d appeared." % [String(wild.species_id), wild.level])
	_refresh_view()
	return true


func is_presenting_battle() -> bool:
	return visible and session != null and (
		session.has_active_battle() or session.status == WildAdventureSession.COMPLETED
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


func move_button_count() -> int:
	var count := 0
	for button in _move_buttons:
		if button.visible:
			count += 1
	return count


func displayed_player_hp() -> int:
	return int(_player_hp.value) if _player_hp != null else -1


func displayed_enemy_hp() -> int:
	return int(_enemy_hp.value) if _enemy_hp != null else -1


func submit_player_move(move_id: StringName) -> Array[BattleEvent]:
	var empty: Array[BattleEvent] = []
	if session == null or catalogs == null or not session.has_active_battle():
		_append_log("No active battle.")
		return empty
	var state := session.battle_state()
	var actor := session.player_active()
	var target := session.current_wild()
	if state == null or actor == null or target == null:
		_append_log("Battle state is incomplete.")
		return empty
	var slot := actor.move_slot(move_id)
	if slot == null or slot.current_pp <= 0 or catalogs.move(move_id) == null:
		_append_log("That move is not currently usable.")
		return empty

	# Derive participant IDs from the live authoritative state instead of baking side_a/side_b
	# into the presentation layer. WildAdventureSession happens to use those IDs today, but the UI
	# should depend on ownership, not on a naming convention.
	var player_side := state.side_for_creature(actor.instance_id)
	var opponent_side := state.side_for_creature(target.instance_id)
	if player_side == null or opponent_side == null:
		_append_log("Battle ownership is incomplete.")
		return empty

	var player_action := BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		move_id,
		target.instance_id,
		BattleAction.MOVE,
		player_side.side_id,
	)
	var opponent_action := SimpleBattleOpponentPolicy.choose_move_action(
		state, opponent_side.side_id, catalogs
	)
	if opponent_action == null:
		_append_log("Opponent has no supported usable action.")
		return empty

	var actions: Array[BattleAction] = [player_action, opponent_action]
	var events := session.submit_turn(actions)
	_render_events(events)
	_refresh_view()
	var post_state := session.battle_state()
	if post_state != null and post_state.phase == BattleState.FINISHED:
		_settle_finished_battle()
	return events


func continue_after_completion() -> bool:
	if session == null or session.status != WildAdventureSession.COMPLETED:
		return false
	var reason := session.completion_reason
	if not session.reset_after_completion():
		return false
	_completion_reason = reason
	visible = false
	battle_closed.emit(reason)
	return true


func _on_move_pressed(index: int) -> void:
	var ids := available_move_ids()
	if index < 0 or index >= ids.size():
		return
	submit_player_move(ids[index])


func _on_continue_pressed() -> void:
	continue_after_completion()


func _settle_finished_battle() -> void:
	var settlement := session.settle_finished_battle()
	if settlement == null or not settlement.ok:
		_append_log("Battle finished but settlement failed: %s" % (settlement.reason if settlement != null else "missing_settlement"))
		_set_moves_enabled(false)
		return
	_completion_reason = session.completion_reason
	if settlement.player_won:
		_append_log("Victory. Progression has been reconciled.")
	else:
		_append_log("Defeat. Persistent battle state has been reconciled.")
	_set_moves_enabled(false)
	if _continue_button != null:
		_continue_button.text = "Return to overworld"
		_continue_button.visible = true


func _refresh_view() -> void:
	if _enemy_label == null:
		return
	if session == null or not session.has_active_battle():
		_set_moves_enabled(false)
		return
	var state := session.battle_state()
	var player_creature := session.player_active()
	var enemy_creature := session.current_wild()
	if state == null or player_creature == null or enemy_creature == null:
		_set_moves_enabled(false)
		return

	_turn_label.text = "Battle finished" if state.phase == BattleState.FINISHED else "Turn %d" % (state.turn + 1)
	_player_label.text = "%s  Lv.%d   HP %d/%d" % [
		String(player_creature.species_id),
		player_creature.level,
		player_creature.current_hp,
		player_creature.stats.max_hp,
	]
	_player_hp.max_value = maxi(1, player_creature.stats.max_hp)
	_player_hp.value = player_creature.current_hp
	_enemy_label.text = "Wild %s  Lv.%d   HP %d/%d" % [
		String(enemy_creature.species_id),
		enemy_creature.level,
		enemy_creature.current_hp,
		enemy_creature.stats.max_hp,
	]
	_enemy_hp.max_value = maxi(1, enemy_creature.stats.max_hp)
	_enemy_hp.value = enemy_creature.current_hp

	var ids := available_move_ids()
	for i in _move_buttons.size():
		var button := _move_buttons[i]
		if i < ids.size():
			var current_move_id := ids[i]
			var current_slot := player_creature.move_slot(current_move_id)
			button.text = "%s  PP %d/%d" % [String(current_move_id), current_slot.current_pp, current_slot.max_pp]
			button.visible = true
			button.disabled = state.phase != BattleState.WAITING_FOR_ACTIONS
		else:
			button.text = "-"
			button.visible = false


func _set_moves_enabled(enabled: bool) -> void:
	for button in _move_buttons:
		button.disabled = not enabled


func _render_events(events: Array[BattleEvent]) -> void:
	for event in events:
		_append_log(_event_text(event))


func _event_text(event: BattleEvent) -> String:
	if event == null:
		return "Unknown battle event."
	match event.kind:
		BattleEvent.ACTION_USED:
			return "%s used %s." % [String(event.actor_id), String(event.move_id)]
		BattleEvent.MOVE_MISSED:
			return "%s's %s missed." % [String(event.actor_id), String(event.move_id)]
		BattleEvent.DAMAGE_APPLIED:
			return "%s lost %d HP." % [String(event.target_id), event.amount]
		BattleEvent.CRITICAL_HIT:
			return "Critical hit."
		BattleEvent.TYPE_EFFECTIVENESS:
			return "Type effectiveness: %s" % str(event.metadata.get("multiplier", "?"))
		BattleEvent.KNOCKED_OUT:
			return "%s was knocked out." % String(event.target_id)
		BattleEvent.STATUS_APPLIED:
			return "%s gained a status." % String(event.target_id)
		BattleEvent.ACTION_PREVENTED:
			return "%s could not act." % String(event.actor_id)
		BattleEvent.SWITCHED:
			return "%s switched." % String(event.actor_id)
		BattleEvent.BATTLE_ENDED:
			return "Battle ended."
		BattleEvent.ACTION_REJECTED:
			return "Action rejected: %s" % String(event.metadata.get("reason", "unknown"))
		_:
			return String(event.kind).replace("_", " ")


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
	root.add_theme_constant_override("separation", 8)
	frame.add_child(root)

	_turn_label = Label.new()
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_label.text = "Turn 1"
	root.add_child(_turn_label)

	_enemy_label = Label.new()
	_enemy_label.text = "Wild opponent"
	root.add_child(_enemy_label)
	_enemy_hp = ProgressBar.new()
	_enemy_hp.show_percentage = false
	_enemy_hp.custom_minimum_size = Vector2(0, 18)
	root.add_child(_enemy_hp)

	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(arena)
	var player_marker := Label.new()
	player_marker.text = "[ PLAYER ]"
	player_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(player_marker)
	var versus := Label.new()
	versus.text = "VS"
	versus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	versus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	versus.custom_minimum_size = Vector2(60, 80)
	arena.add_child(versus)
	var enemy_marker := Label.new()
	enemy_marker.text = "[ WILD ]"
	enemy_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(enemy_marker)

	_player_label = Label.new()
	_player_label.text = "Player creature"
	root.add_child(_player_label)
	_player_hp = ProgressBar.new()
	_player_hp.show_percentage = false
	_player_hp.custom_minimum_size = Vector2(0, 18)
	root.add_child(_player_hp)

	_event_log = RichTextLabel.new()
	_event_log.custom_minimum_size = Vector2(0, 72)
	_event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_log.scroll_active = true
	root.add_child(_event_log)

	var moves := GridContainer.new()
	moves.columns = 2
	moves.add_theme_constant_override("h_separation", 8)
	moves.add_theme_constant_override("v_separation", 6)
	root.add_child(moves)
	for i in 4:
		var button := Button.new()
		button.text = "-"
		button.custom_minimum_size = Vector2(0, 38)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_move_pressed.bind(i))
		moves.add_child(button)
		_move_buttons.append(button)

	_continue_button = Button.new()
	_continue_button.text = "Return to overworld"
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	root.add_child(_continue_button)
