extends Control

signal diagnostic_event(entry: Dictionary)
const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Art = preload("res://scenes/visual/battle_art.gd")
const Playback = preload("res://scenes/visual/showdown_battle_playback.gd")
const LiveText = preload("res://modules/battle/presentation/live_move_event_text.gd")
const SAVE_PATH := "user://showdown_lab_battle_v1.json"
var catalogs: DefinitionCatalog
var session: RefCounted
var _arena: Control
var _playback: Node
var _turn_label: Label
var _player_label: Label
var _enemy_label: Label
var _player_hp: ProgressBar
var _enemy_hp: ProgressBar
var _event_log: RichTextLabel
var _continue_button: Button
var _move_buttons: Array[Button] = []
var _z_toggle: CheckButton
var _selector: OptionButton
var _switch_button: Button
var _save: Button
var _load: Button
var _resume: Button
var _working := false
var _auto_pending := false
var _last_result := {}


func _ready() -> void:
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	if not preload("res://modules/creatures/progression/pokemon_variant_catalog.gd").apply(catalogs):
		push_error("Invalid existing regional catalogue"); return
	_build_ui()
	await new_battle()


func _build_ui() -> void:
	var bg := ColorRect.new(); bg.color = Color("172d2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var columns := HBoxContainer.new(); columns.add_theme_constant_override("separation", 18); margin.add_child(columns)
	var left := VBoxContainer.new(); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; columns.add_child(left)
	_turn_label = _label(left, "Preparando combate…")
	_enemy_label = _label(left, "Rival"); _enemy_hp = _hp(left)
	_arena = Art.new(); _arena.size_flags_vertical = Control.SIZE_EXPAND_FILL; _arena.custom_minimum_size = Vector2(500, 300); left.add_child(_arena)
	_player_label = _label(left, "Tu Pokémon"); _player_hp = _hp(left)
	_event_log = RichTextLabel.new(); _event_log.custom_minimum_size.y = 110; _event_log.scroll_following = true; left.add_child(_event_log)
	var right := VBoxContainer.new(); right.custom_minimum_size.x = 280; columns.add_child(right)
	_label(right, "PRUEBA DE COMBATE · SHOWDOWN")
	_label(right, "¿QUÉ VAS A HACER?")
	for i in 4:
		var b := _button(right, "—"); b.pressed.connect(func(): await choose("move %d" % (i + 1))); _move_buttons.append(b)
	_z_toggle = CheckButton.new(); _z_toggle.text = "Movimiento Z"; right.add_child(_z_toggle)
	_z_toggle.toggled.connect(func(_pressed: bool): _refresh_view())
	_label(right, "EQUIPO")
	_selector = OptionButton.new(); _selector.custom_minimum_size.x = 260; right.add_child(_selector)
	_switch_button = _button(right, "Cambiar Pokémon"); _switch_button.pressed.connect(_switch_pressed)
	_label(right, "GUARDADO DE ESTA PRUEBA")
	_save = _button(right, "Guardar combate"); _save.pressed.connect(func(): save_battle())
	_load = _button(right, "Cargar combate"); _load.pressed.connect(func(): await load_battle())
	_resume = _button(right, "Reanudar combate"); _resume.pressed.connect(func(): await resume_battle()); _resume.hide()
	_continue_button = _button(right, "Nueva prueba"); _continue_button.pressed.connect(func(): await new_battle())
	_label(right, "Reglas de novena generación\nPartida de prueba independiente.")
	_playback = Playback.new(); _playback.configure(self, _arena); add_child(_playback)


func new_battle() -> bool:
	if _working: return false
	_working = true
	if _playback != null: _playback.cancel()
	if session != null: await session.close()
	var rng := RandomNumberGenerator.new(); rng.seed = 703
	var rules := ProgressionRuleset.new()
	var a: Array[CreatureInstance] = [
		CreatureFactory.create(catalogs.species(&"charizard"), 50, catalogs, rules, rng, {"instance_id": &"player_1", "moves": [&"flamethrower", &"protect", &"reflect", &"u_turn"]}),
		CreatureFactory.create(catalogs.species(&"blastoise"), 50, catalogs, rules, rng, {"instance_id": &"player_2", "moves": [&"surf", &"ice_beam", &"life_dew", &"heal_bell"]})]
	var b: Array[CreatureInstance] = [
		CreatureFactory.create(catalogs.species(&"snorlax"), 42, catalogs, rules, rng, {"instance_id": &"enemy_1", "moves": [&"tackle", &"light_screen"]}),
		CreatureFactory.create(catalogs.species(&"gengar"), 42, catalogs, rules, rng, {"instance_id": &"enemy_2", "moves": [&"shadow_ball", &"toxic"]})]
	if "--z-demo" in OS.get_cmdline_user_args():
		a[0].held_item_id = &"firium_z_held"; a[1].held_item_id = &"waterium_z_held"
	_z_toggle.set_pressed_no_signal(false)
	session = Backend.new(catalogs)
	var ok: bool = await session.open(get_tree(), a, b, [37, 11, 4, 2])
	_working = false
	_event_log.text = "Comienza la prueba. Elige un movimiento." if ok else "No se pudo iniciar el combate. Consulta el informe de la prueba."
	_refresh_view()
	if ok: diagnostic_event.emit({"event": "battle_opened"})
	return ok


func choose(choice: String) -> Dictionary:
	if session == null or _working or _playback.is_playing(): return {"accepted": false, "error": "busy"}
	if _z_toggle.button_pressed and choice.begins_with("move ") and not choice.ends_with(" zmove") and not choice.ends_with(" dynamax"):
		choice += " zmove"
	_working = true
	diagnostic_event.emit({"event": "command", "kind": "move"})
	_refresh_view()
	var result: Dictionary = await session.submit(choice, session.revision)
	_last_result = result
	if not result.accepted:
		_playback.cancel(); _event_log.append_text("\nNo se pudo completar esa acción. El estado anterior se conserva.")
		_working = false; _refresh_view(); return result
	var events: Array[BattleEvent] = []; events.assign(result.events)
	_playback.note_event_messages(events)
	for e: BattleEvent in events:
		var message := _event_text(e)
		if not message.is_empty():
			_event_log.append_text("\n" + message)
			diagnostic_event.emit({"event": "ui_log", "text": message})
	_refresh_view()
	var rows: Array = []
	for e: BattleEvent in events: rows.append(e.to_dict())
	diagnostic_event.emit({"event": "turn_resolved", "battle_events": rows})
	_working = false
	_refresh_view()
	return result


func _refresh_view() -> void:
	if session == null or session.battle_state() == null: return
	var state: BattleState = session.battle_state()
	var player := state.active_for_side(&"side_a"); var enemy := state.active_for_side(&"side_b")
	_player_label.text = _creature_label(player)
	_enemy_label.text = "Rival: " + _creature_label(enemy)
	_player_hp.max_value = player.stats.max_hp; _player_hp.value = player.current_hp
	_enemy_hp.max_value = enemy.stats.max_hp; _enemy_hp.value = enemy.current_hp
	_arena.player_species = player.appearance_id(); _arena.enemy_species = enemy.appearance_id()
	var phase: String = session.phase()
	_turn_label.text = "Turno %d" % int(session._checkpoint.snapshot.native.turn)
	if phase == "player_switch": _turn_label.text = "Elige el siguiente Pokémon"
	if phase == "finished": _turn_label.text = "¡Victoria!" if state.winner_id == &"side_a" else "Combate terminado"
	if phase == "interrupted": _turn_label.text = "Combate interrumpido. Puedes reanudarlo."
	var locked: bool = _working or session.busy or _playback.is_playing()
	var req: Dictionary = session.request()
	var moves: Array = req.get("active", [{}])[0].get("moves", []) if not req.get("active", []).is_empty() else []
	var has_z := false
	for i in moves.size():
		if not session.z_move_id(i).is_empty(): has_z = true
	_z_toggle.disabled = locked or phase != "move" or not has_z
	if not has_z: _z_toggle.set_pressed_no_signal(false)
	for i in 4:
		var button := _move_buttons[i]
		button.disabled = locked or phase != "move" or i >= moves.size()
		if i < moves.size():
			var row: Dictionary = moves[i]
			var id := StringName(session._moves.get(String(row.id), String(row.id)))
			button.text = "%s · PP %d/%d" % [SpanishGameText.move_name(id, catalogs), int(row.get("pp", 1)), int(row.get("maxpp", 1))]
			button.disabled = button.disabled or bool(row.get("disabled", false))
			if _z_toggle.button_pressed:
				var z_id: String = session.z_move_id(i)
				button.disabled = button.disabled or z_id.is_empty()
				if not z_id.is_empty(): button.text = SpanishGameText.move_name(StringName(z_id), catalogs) + " · Z"
		else: button.text = "—"
	_selector.clear()
	for i in req.get("side", {}).get("pokemon", []).size():
		var p: Dictionary = req.side.pokemon[i]
		if session.is_reviving():
			if not String(p.condition).contains("fnt"): continue
		elif p.active or String(p.condition).contains("fnt"): continue
		var id := preload("res://modules/battle/backends/showdown/event_adapter.gd").identity(String(p.ident), session._checkpoint.snapshot.identities)
		var creature := state.creature(StringName(id))
		_selector.add_item(_creature_label(creature)); _selector.set_item_metadata(_selector.item_count - 1, "switch %d" % (i + 1))
	_selector.disabled = locked or _selector.item_count == 0 or phase not in ["move", "player_switch"]
	_switch_button.disabled = _selector.disabled
	_save.disabled = locked; _load.disabled = locked; _continue_button.disabled = locked
	_resume.visible = phase == "interrupted"; _resume.disabled = locked
	_load.disabled = _load.disabled or not FileAccess.file_exists(SAVE_PATH)
	if _playback.is_playing(): _playback.restore_display(); _playback.enforce_input_lock()
	if phase == "opponent_switch" and not locked and not _auto_pending:
		_auto_pending = true; _opponent_switch.call_deferred()


func _opponent_switch() -> void:
	await choose("")
	_auto_pending = false
	_refresh_view()


func _switch_pressed() -> void:
	if _selector.selected >= 0: await choose(String(_selector.get_item_metadata(_selector.selected)))


func save_battle(path: String = SAVE_PATH) -> bool:
	if session == null or _working or _playback.is_playing(): return false
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(session.snapshot())); f.close()
	_event_log.append_text("\nCombate guardado."); _refresh_view(); return true


func load_battle(path: String = SAVE_PATH) -> bool:
	if _working or _playback.is_playing() or not FileAccess.file_exists(path): return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary: return false
	_working = true
	var restored := Backend.new(catalogs)
	var ok: bool = await restored.restore_saved(get_tree(), data)
	if ok:
		if session != null: await session.close()
		session = restored; _event_log.text = "Combate recuperado."; diagnostic_event.emit({"event": "battle_opened"})
	else:
		printerr("SHOWDOWN_LOAD_FAILED ", restored.last_error)
		await restored.close()
	_working = false; _refresh_view(); return ok


func resume_battle() -> bool:
	if _working or session == null or not session.needs_recovery: return false
	_working = true
	var saved: Dictionary = session.snapshot()
	var restored := Backend.new(catalogs)
	var ok: bool = await restored.restore_saved(get_tree(), saved)
	if ok:
		await session.close(); session = restored
		_event_log.text = "Combate recuperado desde la última acción confirmada."
		diagnostic_event.emit({"event": "battle_opened"})
	else: await restored.close()
	_working = false; _refresh_view(); return ok


func _event_text(e: BattleEvent) -> String:
	if e.metadata.get("native_zpower", false):
		return "¡%s libera su poder Z!" % _name(session.battle_state().creature(e.target_id))
	var state: BattleState = session.battle_state()
	var actor := _name(state.creature(e.actor_id)); var target := _name(state.creature(e.target_id))
	match e.kind:
		BattleEvent.ACTION_USED: return "%s usó %s." % [actor, SpanishGameText.move_name(e.move_id, catalogs)]
		BattleEvent.DAMAGE_APPLIED, BattleEvent.STATUS_DAMAGE: return "%s perdió %d PS." % [target, e.amount]
		BattleEvent.SWITCHED: return "¡Adelante, %s!" % target
		BattleEvent.KNOCKED_OUT: return "%s se debilitó." % target
		BattleEvent.BATTLE_ENDED: return "El combate terminó."
		BattleEvent.STATUS_APPLIED: return "%s sufre %s." % [target, SpanishGameText.status_name(StringName(e.metadata.get("status_id", "")))]
		BattleEvent.STAT_STAGE_CHANGED: return "Las estadísticas de %s cambiaron." % target
		BattleEvent.TYPE_EFFECTIVENESS:
			if e.metadata.get("category") == "immune": return "El ataque no tuvo efecto."
			return "El ataque no fue muy eficaz." if e.metadata.get("category") == "not_very_effective" else "¡El ataque fue supereficaz!"
		BattleEvent.CRITICAL_HIT: return "¡Golpe crítico!"
		BattleEvent.PP_CHANGED, BattleEvent.TURN_ENDED: return ""
		BattleEvent.MOVE_EFFECT_RESOLVED:
			if e.metadata.get("native_tag") in ["-sideend", "-fieldend", "-end"]: return "Un efecto de combate terminó."
			return LiveText.describe(e, actor, target, catalogs)
	return LiveText.describe(e, actor, target, catalogs)


func _creature_label(c: CreatureInstance) -> String:
	return "%s  Nv.%d   PS %d/%d" % [_name(c), c.level, c.current_hp, c.stats.max_hp] if c != null else "—"


func _name(c: CreatureInstance) -> String:
	return SpanishGameText.creature_name(c, catalogs) if c != null else "Pokémon"


func _label(parent: Node, text: String) -> Label:
	var value := Label.new(); value.text = text; parent.add_child(value); return value


func _button(parent: Node, text: String) -> Button:
	var value := Button.new(); value.text = text; value.custom_minimum_size.y = 38; parent.add_child(value); return value


func _hp(parent: Node) -> ProgressBar:
	var value := ProgressBar.new(); value.show_percentage = false; value.custom_minimum_size.y = 12; parent.add_child(value); return value


func _exit_tree() -> void:
	if session != null: session.stop_now()
