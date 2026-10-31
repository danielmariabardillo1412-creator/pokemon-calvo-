extends "res://scenes/visual/showdown_battle_lab.gd"

const Adventure = preload("res://modules/gameplay/showdown_adventure_session.gd")
const NativeEvents = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const ItemArt = preload("res://scenes/visual/item_art_catalog.gd")
const BallPicker = preload("res://scenes/visual/capture_ball_picker.gd")
var player: PlayerCollection
var _ball: Button
var _capture_balls: OptionButton
var _master: Button
var _flee: Button
var _collection_label: Label
var _encounters := 0
var _settlement_error := false
var _bag_button: Button
var _medicine_popup: PopupPanel
var _medicine_items: OptionButton
var _medicine_icon: TextureRect
var _medicine_targets: OptionButton
var _medicine_moves: OptionButton
var _medicine_use: Button
var _medicine_hint: Label
var _medicine_target_label: Label
var _dynamax_toggle: CheckButton
var _battle_format := "gen9customgame"


func _build_ui() -> void:
	super._build_ui()
	var parent := _continue_button.get_parent()
	for child: Node in parent.get_children():
		if child is Label and child.text == "GUARDADO DE ESTA PRUEBA": child.text = "ENCUENTRO"
		if child is Label and child.text == "PRUEBA DE COMBATE · SHOWDOWN": child.text = "PRUEBA DE AVENTURA · SHOWDOWN"
	_bag_button = _button(parent, "Mochila"); _bag_button.pressed.connect(open_medicine_bag)
	_dynamax_toggle = CheckButton.new(); _dynamax_toggle.text = "Dinamax"; parent.add_child(_dynamax_toggle); _dynamax_toggle.hide()
	_dynamax_toggle.toggled.connect(func(pressed: bool):
		if pressed: _z_toggle.set_pressed_no_signal(false)
		_refresh_view())
	_z_toggle.toggled.connect(func(pressed: bool):
		if pressed: _dynamax_toggle.set_pressed_no_signal(false)
		_refresh_view())
	_build_medicine_bag()
	_capture_balls = BallPicker.new(); parent.add_child(_capture_balls)
	_capture_balls.item_selected.connect(func(_index): _refresh_view())
	_ball = _button(parent, "Lanzar Poké Ball"); _ball.pressed.connect(func(): await adventure_command("ball"))
	_master = _button(parent, "Lanzar Master Ball"); _master.pressed.connect(func(): await adventure_command("master"))
	_ball.icon = ItemArt.texture(&"poke_ball"); _ball.add_theme_constant_override("icon_max_width", 24)
	_master.icon = ItemArt.texture(&"master_ball"); _master.add_theme_constant_override("icon_max_width", 24)
	_flee = _button(parent, "Huir"); _flee.pressed.connect(func(): await adventure_command("flee"))
	_collection_label = _label(parent, "")
	_continue_button.text = "Otro encuentro"
	# This vertical slice keeps a real PlayerCollection in memory. Campaign disk
	# saves/active-battle recovery remain application-owned; never load a bare lab
	# snapshot and lose the staged bag/collection transaction.
	_save.hide(); _load.hide(); _resume.hide()


func new_battle() -> bool:
	if _working: return false
	if session != null and session.has_active_battle(): return false
	_working = true
	if _playback != null: _playback.cancel()
	if session != null: await session.close()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--battle-format=") and arg.get_slice("=", 1) in ["gen8customgame", "gen9customgame", "gen9calvounifiedv1"]: _battle_format = arg.get_slice("=", 1)
	if player == null:
		player = PlayerCollection.new()
		var rng := RandomNumberGenerator.new(); rng.seed = 703
		for row: Array in [["charizard", ["flamethrower", "protect", "reflect", "u_turn"]], ["blastoise", ["surf", "ice_beam", "life_dew", "heal_bell"]]]:
			var id := StringName("adventure_" + row[0])
			player.party.add_creature(CreatureFactory.create(catalogs.species(StringName(row[0])), 50, catalogs, ProgressionRuleset.new(), rng, {"instance_id": id, "moves": row[1]}))
		player.inventory.add(&"poke_ball", 10); player.inventory.add(&"master_ball", 2)
		player.inventory.add(&"potion", 3); player.inventory.add(&"super_potion", 2)
		player.inventory.add(&"full_heal", 2); player.inventory.add(&"ether", 2)
	var rng := RandomNumberGenerator.new(); rng.seed = 100 + _encounters
	var wild := CreatureFactory.create(catalogs.species(&"snorlax"), 42, catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName("adventure_wild_%d" % _encounters), "moves": [&"tackle"]})
	_encounters += 1
	session = Adventure.new(catalogs, player, _battle_format)
	_dynamax_toggle.set_pressed_no_signal(false)
	_settlement_error = false
	var ok: bool = await session.begin_wild(get_tree(), wild, [37, 11, 4, 2])
	_working = false
	_event_log.clear()
	_event_log.text = "Encuentro salvaje. Puedes combatir, capturar o huir." if ok else "No se pudo iniciar el encuentro: " + session.last_error
	_refresh_view()
	if ok: diagnostic_event.emit({"event": "battle_opened"})
	return ok


func _refresh_view() -> void:
	super._refresh_view()
	if _ball == null or session == null or session.battle_state() == null: return
	var locked: bool = _working or session.busy or _playback.is_playing()
	var usable: bool = not locked and session.phase() == "move"
	var capturable: bool = usable and session.battle_kind == "wild"
	_capture_balls.render_balls(session.inventory, catalogs, not capturable)
	var selected: StringName = _capture_balls.selected_ball()
	_ball.text = "%s · %d" % [SpanishGameText.item_name(selected, catalogs), session.inventory.quantity(selected)]
	_ball.icon = ItemArt.texture(selected)
	_master.text = "Master Ball · %d" % session.inventory.quantity(&"master_ball")
	_ball.disabled = not capturable or not session.inventory.has(selected)
	_master.disabled = not capturable or not session.inventory.has(&"master_ball")
	_flee.disabled = not usable
	_bag_button.disabled = not usable
	var native: Dictionary = session.request().get("active", [{}])[0] if not session.request().get("active", []).is_empty() else {}
	_dynamax_toggle.visible = session.dynamax_profile()
	_dynamax_toggle.disabled = not usable or not native.get("canDynamax", false)
	for child: Node in _continue_button.get_parent().get_children():
		if child is Label and child.text.begins_with("Reglas de "):
			child.text = "Reglas de generación 8 · Dinamax\nPartida de prueba independiente." if session.format_id == "gen8customgame" else "Reglas de novena generación\nPartida de prueba independiente."
	if session.dynamax_profile():
		var max_moves: Array = native.get("maxMoves", {}).get("maxMoves", [])
		if _dynamax_toggle.button_pressed or "dynamax" in session._checkpoint.roster[0].pokemon[0].get("volatiles", []):
			for i in mini(max_moves.size(), _move_buttons.size()):
				var id: StringName = StringName(session._moves.get(NativeEvents.normalized(String(max_moves[i].move)), ""))
				_move_buttons[i].text = SpanishGameText.move_name(id, catalogs)
	_continue_button.disabled = locked or session.has_active_battle()
	_collection_label.text = "Equipo: %d · PC: %d" % [player.party.size(), player.storage.get_all_creatures().size()]
	_save.hide(); _load.hide(); _resume.visible = session.phase() == "interrupted"
	if not session.completion_reason.is_empty():
		_turn_label.text = {"CAPTURED": "¡Pokémon capturado!", "FLED": "Has huido del encuentro.", "VICTORY": "¡Victoria! Experiencia recibida.", "DEFEAT": "Tu equipo se ha debilitado.", "DRAW": "Empate."}.get(session.completion_reason, "Encuentro terminado")
	if session.phase() == "finished" and session.completion_reason.is_empty() and not locked and not _settlement_error: _settle.call_deferred()


func _settle() -> void:
	if _working or session.completion_reason != "": return
	var result: Dictionary = session.settle_finished_battle()
	if result.accepted: _event_log.append_text("\nResultado aplicado al equipo y al inventario de esta prueba.")
	else:
		_settlement_error = true
		_event_log.append_text("\nNo se pudo aplicar el resultado: " + session.last_error)
	_refresh_view()


func adventure_command(kind: String) -> Dictionary:
	if _working or _playback.is_playing() or session == null: return {"accepted": false}
	if kind not in ["ball", "master", "flee"]: return {"accepted": false, "error": "unknown_adventure_command"}
	var ball_id: StringName = &"master_ball" if kind == "master" else _capture_balls.selected_ball()
	_working = true
	diagnostic_event.emit({"event": "command", "kind": "adventure"})
	_refresh_view()
	var result: Dictionary
	if kind == "flee": result = await session.flee(session.revision)
	else: result = await session.capture(ball_id, session.revision)
	if result.accepted:
		var events: Array[BattleEvent] = []; events.assign(result.events)
		_playback.note_event_messages(events)
		for event: BattleEvent in events:
			var message := _event_text(event)
			if not message.is_empty(): _adventure_log(message)
		if session.completion_reason == "CAPTURED": _adventure_log("¡Capturado! " + ("Enviado al PC." if result.stored else "Añadido al equipo."))
		elif session.completion_reason == "FLED": _adventure_log("Has escapado.")
		elif kind == "flee": _adventure_log("No has podido huir.")
		else: _adventure_log("El Pokémon se ha escapado de la Poké Ball.")
		diagnostic_event.emit({"event": "command_result", "kind": "run" if kind == "flee" else "capture", "accepted": true,
			"session_completed": not session.completion_reason.is_empty(), "capture_outcome": result.get("capture_outcome", {}),
			"escape_resolution": result.get("escape_resolution", {}), "battle_events": _event_dicts(events)})
	else: _event_log.append_text("\nLa acción no se ha aplicado: " + session.last_error)
	_working = false
	_refresh_view()
	return result


func _adventure_log(text: String) -> void:
	_event_log.append_text("\n" + text)
	diagnostic_event.emit({"event": "ui_log", "text": text})


func _build_medicine_bag() -> void:
	_medicine_popup = PopupPanel.new(); add_child(_medicine_popup)
	var box := VBoxContainer.new(); box.custom_minimum_size = Vector2(460, 280); box.add_theme_constant_override("separation", 12); _medicine_popup.add_child(box)
	_label(box, "MOCHILA · OBJETOS DE COMBATE")
	var item_row := HBoxContainer.new(); box.add_child(item_row)
	_medicine_icon = TextureRect.new(); _medicine_icon.custom_minimum_size = Vector2(40, 40)
	_medicine_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _medicine_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_medicine_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; item_row.add_child(_medicine_icon)
	_medicine_items = OptionButton.new(); _medicine_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL; item_row.add_child(_medicine_items)
	_medicine_hint = _label(box, "")
	_medicine_target_label = _label(box, "¿En qué Pokémon?")
	_medicine_targets = OptionButton.new(); box.add_child(_medicine_targets)
	_medicine_moves = OptionButton.new(); box.add_child(_medicine_moves)
	_medicine_items.item_selected.connect(func(_i): _refresh_medicine_moves())
	_medicine_targets.item_selected.connect(func(_i): _refresh_medicine_moves())
	_medicine_use = _button(box, "Usar objeto"); _medicine_use.pressed.connect(use_selected_medicine)
	_button(box, "Cancelar").pressed.connect(func(): _medicine_popup.hide())


func open_medicine_bag() -> void:
	if _working or _playback.is_playing() or session == null or session.phase() != "move": return
	_medicine_items.clear(); _medicine_targets.clear()
	for id: StringName in session.inventory.all_item_ids():
		if not session.battle_item_usable(id): continue
		_medicine_items.add_item("%s · %d" % [SpanishGameText.item_name(id, catalogs), session.inventory.quantity(id)])
		_medicine_items.set_item_metadata(_medicine_items.item_count - 1, String(id))
	for cid: StringName in session.battle_state().sides[0].party_ids:
		var creature: CreatureInstance = session.battle_state().creature(cid)
		if creature.is_knocked_out(): continue
		_medicine_targets.add_item(_creature_label(creature))
		_medicine_targets.set_item_metadata(_medicine_targets.item_count - 1, String(cid))
		if cid == session.battle_state().sides[0].active_id: _medicine_targets.select(_medicine_targets.item_count - 1)
	_refresh_medicine_moves()
	_medicine_popup.popup_centered()


func _refresh_medicine_moves() -> void:
	_medicine_moves.clear()
	_medicine_use.disabled = _medicine_items.item_count == 0 or _medicine_targets.item_count == 0
	_medicine_hint.visible = not _medicine_use.disabled
	if _medicine_use.disabled: _medicine_moves.hide(); _medicine_icon.texture = null; return
	var id := String(_medicine_items.get_item_metadata(_medicine_items.selected))
	_medicine_icon.texture = ItemArt.texture(StringName(id))
	var escape := Adventure.Escape.supports(StringName(id))
	var support: Dictionary = Adventure.BattleSupport.row(StringName(id))
	_medicine_targets.visible = not escape
	_medicine_target_label.visible = _medicine_targets.visible
	if escape:
		_medicine_hint.text = "Huye del combate salvaje. Se consume una unidad."
	elif not support.is_empty():
		# O110: scope, reuse and consumption come from the service profile; the
		# view never derives stages, conditions or friendship on its own.
		var active_only: bool = support.get("target", "") == "active_own"
		_medicine_target_label.text = "Solo el Pokémon activo." if active_only else "¿En qué Pokémon?"
		_medicine_hint.text = "Se consume una unidad al tener efecto." if support.get("consumable", false) else "Es reutilizable; no gasta unidades."
		if active_only: _select_active_target()
	else:
		_medicine_target_label.text = "¿En qué Pokémon?"
		_medicine_hint.text = "Elige el Pokémon al que quieres aplicar el objeto."
	var spec: Dictionary = Adventure.Medicine.items().get(id, {})
	_medicine_moves.visible = spec.get("scope") == "one"
	if not _medicine_moves.visible: return
	var target := StringName(_medicine_targets.get_item_metadata(_medicine_targets.selected))
	var creature: CreatureInstance = session.battle_state().creature(target)
	for slot: BattleMoveSlot in creature.moveset:
		_medicine_moves.add_item("%s · PP %d/%d" % [SpanishGameText.move_name(slot.move_id, catalogs), slot.current_pp, slot.max_pp])


func use_selected_medicine() -> Dictionary:
	if session == null or not session.has_active_battle() or session.phase() != "move" or _working or _playback.is_playing() or _medicine_use.disabled: return {"accepted": false}
	var id := StringName(_medicine_items.get_item_metadata(_medicine_items.selected))
	var target := StringName(_medicine_targets.get_item_metadata(_medicine_targets.selected))
	if Adventure.Escape.supports(id) or Adventure.BattleSupport.target_scope(id) == &"active_own":
		target = session.battle_state().sides[0].active_id
	var slot := _medicine_moves.selected if _medicine_moves.visible else -1
	_medicine_popup.hide()
	_working = true; diagnostic_event.emit({"event": "command", "kind": "item"}); _refresh_view()
	var result: Dictionary = await session.use_item(id, target, session.revision, slot)
	if result.accepted:
		if session.completion_reason == "FLED": _adventure_log("Has escapado usando %s." % SpanishGameText.item_name(id, catalogs))
		var events: Array[BattleEvent] = []; events.assign(result.events)
		_playback.note_event_messages(events)
		for event: BattleEvent in events:
			var text := _event_text(event)
			if not text.is_empty(): _adventure_log(text)
		if Adventure.BattleSupport.supports(id) and not Adventure.BattleSupport.consumable(id):
			_adventure_log("Puedes volver a usar %s." % SpanishGameText.item_name(id, catalogs))
		if session.completion_reason == "FLED":
			diagnostic_event.emit({"event": "command_result", "kind": "run", "item_id": String(id), "accepted": true, "session_completed": true, "escape_resolution": result.escape_resolution, "battle_events": _event_dicts(events)})
		else: diagnostic_event.emit({"event": "turn_resolved", "item_id": String(id), "battle_events": _event_dicts(events)})
	else:
		_playback.cancel()
		if Adventure.Escape.supports(id): _event_log.append_text("\nNo se ha podido huir con ese objeto. Se conserva en la mochila.")
		elif Adventure.BattleSupport.supports(id): _event_log.append_text("\nNo se ha usado el objeto: %s. No se ha gastado ninguna unidad." % session.last_error)
		else: _event_log.append_text("\nNo se ha usado el objeto. Comprueba el Pokémon y sus PS, estado o PP.")
	_working = false; _refresh_view()
	return result


func _select_active_target() -> void:
	if session == null or session.battle_state() == null: return
	var active: StringName = session.battle_state().sides[0].active_id
	for i: int in _medicine_targets.item_count:
		if StringName(_medicine_targets.get_item_metadata(i)) == active:
			_medicine_targets.select(i)
			return


func _event_text(event: BattleEvent) -> String:
	if event.metadata.has("native_dynamax"):
		return "¡%s usa Dinamax!" % _name(session.battle_state().creature(event.target_id)) if event.metadata.native_dynamax else "El Dinamax terminó."
	if event.metadata.get("silent", false): return ""
	if event.kind == BattleEvent.TRAINER_ITEM_USED:
		return "Usaste %s en %s." % [SpanishGameText.item_name(StringName(event.metadata.get("item_id", "")), catalogs), _name(session.battle_state().creature(event.target_id))]
	return super._event_text(event)


func choose(choice: String) -> Dictionary:
	if _dynamax_toggle.button_pressed and choice.begins_with("move ") and session != null and session.request().get("active", [{}])[0].get("canDynamax", false): choice += " dynamax"
	return await super.choose(choice)


func _event_dicts(events: Array[BattleEvent]) -> Array:
	var rows: Array = []
	for event: BattleEvent in events: rows.append(event.to_dict())
	return rows


func save_battle(_path: String = "") -> bool:
	return false # No campaign persistence UI until the owner saves both contracts.


func load_battle(_path: String = "") -> bool:
	return false


func resume_battle() -> bool:
	if _working or session == null or not session.needs_recovery: return false
	_working = true
	var restored := Adventure.new(catalogs, player, session.format_id)
	var ok: bool = await restored.restore_saved(get_tree(), session.snapshot())
	if ok:
		await session.close(); session = restored
		_event_log.append_text("\nEncuentro recuperado con su inventario y RNG confirmados.")
		diagnostic_event.emit({"event": "battle_opened"})
	else: await restored.close()
	_working = false; _refresh_view(); return ok
