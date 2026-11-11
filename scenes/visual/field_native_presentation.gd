extends "res://scenes/visual/showdown_adventure_lab.gd"

signal return_requested
var owner_bridge: Node
const EvolutionConsumerW04 = preload("res://modules/gameplay/w04_postbattle_evolution_consumer_v6.gd")
const GrowthChoicesW04 = preload("res://scenes/visual/field_growth_choices.gd")
var _evolution_choices_w04: VBoxContainer
var _pending_evolution_events_w04: Array = []
var _active_evolution_event_w04: ProgressionEvent
var _active_evolution_contract_w04: Dictionary = {}


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
	# Real post-battle evolution choice, reused from the field growth UI.
	_evolution_choices_w04 = GrowthChoicesW04.new()
	right.add_child(_evolution_choices_w04)
	_evolution_choices_w04.chosen.connect(func(value: Variant):
		_resolve_postbattle_evolution_w04(StringName(str(value)) == StringName(_active_evolution_contract_w04.get("target_id", ""))))
	_evolution_choices_w04.cancelled.connect(func():
		_resolve_postbattle_evolution_w04(false))
	_save.text = "Guardar partida"; _load.text = "Cargar partida"
	for c: Node in _continue_button.get_parent().get_children():
		if c is Label and c.text.contains("SHOWDOWN"): c.text = "COMBATE"
		if c is Label and c.text.begins_with("Reglas de "): c.hide()


func new_battle() -> bool:
	if has_pending_evolution_w04(): return false
	if session != null and not session.has_active_battle() and not _playback.is_playing(): return_requested.emit(); return true
	return false


func _refresh_view() -> void:
	super._refresh_view()
	if session == null or _ball == null: return
	var locked: bool = _working or session.busy or _playback.is_playing()
	var wild: bool = session.battle_kind == "wild"
	_ball.visible = wild; _master.visible = wild; _flee.visible = wild
	_capture_balls.visible = wild
	_continue_button.text = "Volver al mapa"
	_save.show(); _load.show()
	_save.disabled = locked or owner_bridge == null or has_pending_evolution_w04()
	_continue_button.disabled = _continue_button.disabled or has_pending_evolution_w04()
	_load.disabled = locked or owner_bridge == null or not FileAccess.file_exists(owner_bridge.save_path)


func save_battle(_path: String = "") -> bool:
	if owner_bridge == null: return false
	return owner_bridge.save_game()


func load_battle(_path: String = "") -> bool:
	if owner_bridge == null: return false
	return await owner_bridge.load_game()


func resume_battle() -> bool:
	if owner_bridge == null: return false
	return await owner_bridge.recover_battle()


# Actual settlement result is the ONLY source of evolution events. The
# inherited adventure presentation discarded it after publishing battle XP.
func _settle() -> void:
	if _working or session == null or session.completion_reason != "": return
	var result: Dictionary = session.settle_finished_battle()
	if not result.get("accepted", false):
		_settlement_error = true
		_event_log.append_text("\nNo se pudo aplicar el resultado: " + session.last_error)
		_refresh_view()
		return
	_event_log.append_text("\nResultado aplicado al equipo y al inventario.")
	_pending_evolution_events_w04.clear()
	_active_evolution_event_w04 = null
	_active_evolution_contract_w04.clear()
	for event in result.get("progression_events", []):
		if not (event is ProgressionEvent) or event.kind != ProgressionEvent.EVOLUTION_AVAILABLE: continue
		var proof: Dictionary = EvolutionConsumerW04.eligible(player, catalogs, event)
		if proof.get("ok", false): _pending_evolution_events_w04.append(event)
	_show_next_postbattle_evolution_w04()
	_refresh_view()


func has_pending_evolution_w04() -> bool:
	return _active_evolution_event_w04 != null or not _pending_evolution_events_w04.is_empty()


func _show_next_postbattle_evolution_w04() -> void:
	_active_evolution_event_w04 = null
	_active_evolution_contract_w04.clear()
	if _evolution_choices_w04 != null: _evolution_choices_w04.hide()
	while not _pending_evolution_events_w04.is_empty():
		var event: ProgressionEvent = _pending_evolution_events_w04.pop_front()
		var proof: Dictionary = EvolutionConsumerW04.eligible(player, catalogs, event)
		if not proof.get("ok", false):
			_event_log.append_text("\nEvolución no disponible: " + String(proof.get("reason", "invalid_event")))
			continue
		_active_evolution_event_w04 = event
		_active_evolution_contract_w04 = proof
		_evolution_choices_w04.present({"kind": "evolution", "level": proof.level,
			"targets": [String(proof.target_id)]}, catalogs)
		_event_log.append_text("\nSe requiere decidir una evolución antes de volver al mapa.")
		break
	_refresh_view()


func _resolve_postbattle_evolution_w04(accept: bool) -> void:
	if _active_evolution_event_w04 == null or session == null or session.completion_reason == "" \
			or session.busy or _working or _playback.is_playing(): return
	var event: ProgressionEvent = _active_evolution_event_w04
	var proof := _active_evolution_contract_w04.duplicate()
	var response: Dictionary = EvolutionConsumerW04.decide(player, catalogs,
		session.progression_ruleset, event, proof, accept)
	if not response.get("accepted", false):
		_event_log.append_text("\nEvolución rechazada por validación: " + String(response.get("reason", "")))
		# A failed publication must remain visible and never be reported successful.
		return
	if response.get("evolved", false):
		_event_log.append_text("\n¡Ha evolucionado a " + SpanishGameText.species_name(
			StringName(response.species_id), catalogs) + "!")
	else:
		_event_log.append_text("\nHas decidido no evolucionar.")
	_show_next_postbattle_evolution_w04()
