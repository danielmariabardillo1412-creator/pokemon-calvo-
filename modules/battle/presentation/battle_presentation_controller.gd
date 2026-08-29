class_name BattlePresentationController
extends Control

signal battle_closed(reason: StringName)

# Technical, asset-free presentation adapter. The authoritative state remains inside
# WildAdventureSession/Battle Core. This Control only reads state, builds player intents, asks the
# technical opponent policy for a legal response, submits through the application boundary, and
# renders semantic results. Capture rules/inventory mutation never live in this UI.

const CAPTURE_BALL_ORDER := [
	&"poke_ball",
	&"great_ball",
	&"ultra_ball",
	&"master_ball",
]

var session: WildAdventureSession = null
var catalogs: DefinitionCatalog = null

var _capture_rng: RandomNumberGenerator = null
var _enemy_label: Label = null
var _enemy_hp: ProgressBar = null
var _player_label: Label = null
var _player_hp: ProgressBar = null
var _turn_label: Label = null
var _event_log: RichTextLabel = null
var _move_buttons: Array[Button] = []
var _capture_buttons: Array[Button] = []
var _switch_selector: OptionButton = null
var _switch_button: Button = null
var _continue_button: Button = null
var _completion_reason: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


# Capture RNG is deliberately injected. A presentation with no RNG can still play moves/switches,
# but its capture controls remain disabled. This avoids inventing a hidden gameplay seed in UI.
func configure(
	p_session: WildAdventureSession,
	p_catalogs: DefinitionCatalog,
	p_capture_rng: RandomNumberGenerator = null,
) -> void:
	session = p_session
	catalogs = p_catalogs
	_capture_rng = p_capture_rng


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


# Only authoritative Battle-side ownership is used here. Active, knocked-out, unknown and foreign
# creatures are never offered as elective switch targets. Party order remains stable.
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


# Presentation ordering is stable and explicit; ownership/quantity comes only from PlayerInventory.
# Unknown/non-capture items in the bag are never exposed as capture controls.
func available_capture_ball_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if session == null or session.player == null or session.player.inventory == null:
		return result
	for ball_variant in CAPTURE_BALL_ORDER:
		var ball_id := StringName(ball_variant)
		if session.player.inventory.quantity(ball_id) > 0:
			result.append(ball_id)
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


func capture_button_count() -> int:
	var count := 0
	for button in _capture_buttons:
		if button.visible:
			count += 1
	return count


func displayed_capture_quantity(ball_id: StringName) -> int:
	if session == null or session.player == null or session.player.inventory == null:
		return 0
	return session.player.inventory.quantity(ball_id)


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

	var command := WildBattleCommand.from_action(player_action)
	var result := session.submit_player_command(command, null, opponent_action)
	if result == null:
		_append_log("Battle command returned no result.")
		return empty
	if not result.accepted:
		_append_log("Action rejected: %s" % result.reason)
		_render_events(result.battle_events)
		_refresh_view()
		return result.battle_events
	_render_events(result.battle_events)
	_refresh_view()
	var post_state := session.battle_state()
	if post_state != null and post_state.phase == BattleState.FINISHED:
		_settle_finished_battle()
	return result.battle_events


# Elective Switch is only a presentation of the existing canonical BattleAction.SWITCH contract.
# The UI does not mutate active_id, clear stages/status or decide priority; Battle Core owns all of it.
func submit_player_switch(switch_instance_id: StringName) -> WildBattleCommandResult:
	var fallback := WildBattleCommandResult.new()
	fallback.command_type = WildBattleCommand.ACTION
	if session == null or catalogs == null or not session.has_active_battle():
		fallback.reason = "no_active_wild_battle"
		_append_log("No active battle.")
		return fallback
	var state := session.battle_state()
	var actor := session.player_active()
	var target := session.current_wild()
	if state == null or actor == null or target == null:
		fallback.reason = "battle_state_incomplete"
		_append_log("Battle state is incomplete.")
		return fallback
	var player_side := state.side_for_creature(actor.instance_id)
	var opponent_side := state.side_for_creature(target.instance_id)
	if player_side == null or opponent_side == null:
		fallback.reason = "battle_ownership_incomplete"
		_append_log("Battle ownership is incomplete.")
		return fallback

	var opponent_action := SimpleBattleOpponentPolicy.choose_move_action(
		state, opponent_side.side_id, catalogs
	)
	if opponent_action == null:
		fallback.reason = "opponent_action_unavailable"
		_append_log("Opponent has no supported usable response.")
		return fallback

	var player_action := BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		&"",
		&"",
		BattleAction.SWITCH,
		player_side.side_id,
		switch_instance_id,
	)
	var command := WildBattleCommand.from_action(player_action)
	var result := session.submit_player_command(command, null, opponent_action)
	if result == null:
		fallback.reason = "battle_command_result_missing"
		_append_log("Switch command returned no result.")
		return fallback
	if not result.accepted:
		_append_log("Switch rejected: %s" % result.reason)
		_render_events(result.battle_events)
		_refresh_view()
		return result

	_render_events(result.battle_events)
	_refresh_view()
	var post_state := session.battle_state()
	if post_state != null and post_state.phase == BattleState.FINISHED:
		_settle_finished_battle()
	return result


func submit_capture_ball(ball_id: StringName) -> WildBattleCommandResult:
	var fallback := WildBattleCommandResult.new()
	fallback.command_type = WildBattleCommand.CAPTURE
	if session == null or catalogs == null or not session.has_active_battle():
		fallback.reason = "no_active_wild_battle"
		_append_log("No active battle.")
		return fallback
	if _capture_rng == null:
		fallback.reason = "capture_rng_unavailable"
		_append_log("Capture is unavailable in this presentation.")
		return fallback

	var state := session.battle_state()
	var actor := session.player_active()
	var target := session.current_wild()
	if state == null or actor == null or target == null:
		fallback.reason = "battle_state_incomplete"
		_append_log("Battle state is incomplete.")
		return fallback
	var player_side := state.side_for_creature(actor.instance_id)
	var opponent_side := state.side_for_creature(target.instance_id)
	if player_side == null or opponent_side == null:
		fallback.reason = "battle_ownership_incomplete"
		_append_log("Battle ownership is incomplete.")
		return fallback

	# The technical policy only chooses a legal response. It does not resolve Capture or Battle.
	var opponent_action := SimpleBattleOpponentPolicy.choose_move_action(
		state, opponent_side.side_id, catalogs
	)
	if opponent_action == null:
		fallback.reason = "opponent_action_unavailable"
		_append_log("Opponent has no supported usable response.")
		return fallback

	var command := WildBattleCommand.capture(state.turn + 1, player_side.side_id, ball_id)
	var result := session.submit_player_command(command, _capture_rng, opponent_action)
	if result == null:
		fallback.reason = "battle_command_result_missing"
		_append_log("Capture command returned no result.")
		return fallback

	if not result.accepted:
		_append_log("Capture rejected: %s" % result.reason)
		_render_events(result.battle_events)
		_refresh_view()
		return result

	var capture_status := CaptureResult.INVALID
	if result.capture_outcome != null and result.capture_outcome.resolution != null and result.capture_outcome.resolution.result != null:
		capture_status = result.capture_outcome.resolution.result.status

	if capture_status == CaptureResult.SUCCESS and result.session_completed:
		_completion_reason = session.completion_reason
		_append_log("Captured the wild Pokémon with %s." % String(ball_id))
		if result.capture_outcome != null and result.capture_outcome.routing != null and result.capture_outcome.routing.stored:
			_append_log("Party full: captured Pokémon was routed to storage.")
		_set_command_controls_enabled(false)
		# The successful command clears the live Battle, so _refresh_view() can no longer rebuild the
		# command rows from active state. Remove stale capture/switch choices explicitly.
		for button in _capture_buttons:
			button.visible = false
		_clear_switch_controls()
		if _turn_label != null:
			_turn_label.text = "Captured"
		if _continue_button != null:
			_continue_button.text = "Return to overworld"
			_continue_button.visible = true
		return result

	if capture_status == CaptureResult.FAILED:
		_append_log("The wild Pokémon broke free.")
		_render_events(result.battle_events)
		_refresh_view()
		var post_state := session.battle_state()
		if post_state != null and post_state.phase == BattleState.FINISHED:
			_settle_finished_battle()
		return result

	# Defensive fallback: accepted commands should currently be either SUCCESS or FAILED.
	_append_log("Capture command completed with an unknown result.")
	_render_events(result.battle_events)
	_refresh_view()
	return result


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


func _on_switch_pressed() -> void:
	var ids := available_switch_instance_ids()
	if _switch_selector == null or ids.is_empty():
		return
	var index := _switch_selector.selected
	if index < 0 or index >= ids.size():
		return
	submit_player_switch(ids[index])


func _on_capture_pressed(index: int) -> void:
	var ids := available_capture_ball_ids()
	if index < 0 or index >= ids.size():
		return
	submit_capture_ball(ids[index])


func _on_continue_pressed() -> void:
	continue_after_completion()


func _settle_finished_battle() -> void:
	var settlement := session.settle_finished_battle()
	if settlement == null or not settlement.ok:
		_append_log("Battle finished but settlement failed: %s" % (settlement.reason if settlement != null else "missing_settlement"))
		_set_command_controls_enabled(false)
		return
	_completion_reason = session.completion_reason
	if settlement.player_won:
		_append_log("Victory. Progression has been reconciled.")
	else:
		_append_log("Defeat. Persistent battle state has been reconciled.")
	_set_command_controls_enabled(false)
	if _continue_button != null:
		_continue_button.text = "Return to overworld"
		_continue_button.visible = true


func _refresh_view() -> void:
	if _enemy_label == null:
		return
	if session == null or not session.has_active_battle():
		_set_command_controls_enabled(false)
		return
	var state := session.battle_state()
	var player_creature := session.player_active()
	var enemy_creature := session.current_wild()
	if state == null or player_creature == null or enemy_creature == null:
		_set_command_controls_enabled(false)
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

	var waiting := state.phase == BattleState.WAITING_FOR_ACTIONS
	var moves := available_move_ids()
	for i in _move_buttons.size():
		var move_button := _move_buttons[i]
		if i < moves.size():
			var current_move_id := moves[i]
			var current_slot := player_creature.move_slot(current_move_id)
			move_button.text = "%s  PP %d/%d" % [String(current_move_id), current_slot.current_pp, current_slot.max_pp]
			move_button.visible = true
			move_button.disabled = not waiting
		else:
			move_button.text = "-"
			move_button.visible = false

	_refresh_switch_controls(state, waiting)

	var balls := available_capture_ball_ids()
	for i in _capture_buttons.size():
		var capture_button := _capture_buttons[i]
		if i < balls.size():
			var ball_id := balls[i]
			capture_button.text = "%s  x%d" % [String(ball_id), session.player.inventory.quantity(ball_id)]
			capture_button.visible = true
			capture_button.disabled = not waiting or _capture_rng == null
		else:
			capture_button.text = "-"
			capture_button.visible = false


func _refresh_switch_controls(state: BattleState, waiting: bool) -> void:
	if _switch_selector == null or _switch_button == null:
		return
	_switch_selector.clear()
	var ids := available_switch_instance_ids()
	for instance_id in ids:
		var candidate := state.creature(instance_id)
		if candidate == null:
			continue
		_switch_selector.add_item("%s Lv.%d  HP %d/%d" % [
			String(candidate.species_id),
			candidate.level,
			candidate.current_hp,
			candidate.stats.max_hp,
		])
	var can_switch := waiting and not ids.is_empty()
	_switch_selector.disabled = not can_switch
	_switch_button.disabled = not can_switch


func _clear_switch_controls() -> void:
	if _switch_selector != null:
		_switch_selector.clear()
		_switch_selector.disabled = true
	if _switch_button != null:
		_switch_button.disabled = true


func _set_command_controls_enabled(enabled: bool) -> void:
	for button in _move_buttons:
		button.disabled = not enabled
	for button in _capture_buttons:
		button.disabled = not enabled or _capture_rng == null
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
			return "%s switched to %s." % [String(event.actor_id), String(event.target_id)]
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
	root.add_theme_constant_override("separation", 6)
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
	versus.custom_minimum_size = Vector2(60, 48)
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
	_event_log.custom_minimum_size = Vector2(0, 54)
	_event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_log.scroll_active = true
	root.add_child(_event_log)

	var moves_title := Label.new()
	moves_title.text = "Moves"
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
	switch_title.text = "Switch"
	switch_row.add_child(switch_title)
	_switch_selector = OptionButton.new()
	_switch_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_switch_selector.disabled = true
	switch_row.add_child(_switch_selector)
	_switch_button = Button.new()
	_switch_button.text = "Switch"
	_switch_button.disabled = true
	_switch_button.pressed.connect(_on_switch_pressed)
	switch_row.add_child(_switch_button)

	var capture_title := Label.new()
	capture_title.text = "Capture"
	root.add_child(capture_title)
	var captures := GridContainer.new()
	captures.columns = 2
	captures.add_theme_constant_override("h_separation", 8)
	captures.add_theme_constant_override("v_separation", 4)
	root.add_child(captures)
	for i in 4:
		var capture_button := Button.new()
		capture_button.text = "-"
		capture_button.custom_minimum_size = Vector2(0, 30)
		capture_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		capture_button.pressed.connect(_on_capture_pressed.bind(i))
		captures.add_child(capture_button)
		_capture_buttons.append(capture_button)

	_continue_button = Button.new()
	_continue_button.text = "Return to overworld"
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	root.add_child(_continue_button)
