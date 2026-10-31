extends Node

# Detached replay of already-resolved diagnostic events. Never submits commands,
# mutates creatures, rolls RNG or holds a live BattleState between frames.
signal pose_started(entry: Dictionary)
signal playback_finished

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Plan = preload("res://scenes/visual/battle_timeline_plan.gd")
const MoveVisuals = preload("res://scenes/visual/battle_move_visuals.gd")
const CommunityPilot = preload("res://scenes/visual/battle_community_move_pilot.gd")
const ExternalDamagePilot = preload("res://scenes/visual/battle_external_damage_pilot.gd")
const StatusSwitchPilot = preload("res://scenes/visual/battle_status_switch_pilot.gd")
const WeatherCastPilot = preload("res://scenes/visual/battle_weather_cast_pilot.gd")
const WeatherLayer = preload("res://scenes/visual/battle_weather_layer.gd")
const LiveCatalog = preload("res://scenes/visual/live_battle_catalog.gd")
const TransformPilot = preload("res://scenes/visual/battle_transform_pilot.gd")
const SubstitutePilot = preload("res://scenes/visual/battle_substitute_pilot.gd")
const SubstituteRules = preload("res://modules/battle/application/substitute_rules.gd")
const WeatherRules = preload("res://modules/battle/application/weather_rules.gd")
var _community: Node
var _external_damage: Node
var _status_switch: Node
var _live_catalog: Node
var _transform: Node
var _substitute: Node
var _weather_cast: Node
var _weather_layer: Node
var _final_weather: Dictionary = {}
var _community_text_shown := false
var _presentation: Control
var _arena: Control
var _before: Dictionary = {}
var _sequence: Array[Dictionary] = []
var _final_views: Dictionary = {}
var _index := -1
var _remaining := 0.0
var _locked: Array[Dictionary] = []
var _collecting := false
var _logs: Array[String] = []
var _prefix_count := 0
var _messages: Array[String] = []
var _final_hud: Dictionary = {}
var _display_hud: Dictionary = {}
var _caught_ball := ""


func configure(presentation: Control, arena: Control) -> void:
	_presentation = presentation
	_arena = arena
	_community = CommunityPilot.new()
	add_child(_community)
	_community.configure(arena)
	_external_damage = ExternalDamagePilot.new()
	add_child(_external_damage)
	_external_damage.configure(arena)
	_status_switch = StatusSwitchPilot.new()
	add_child(_status_switch)
	_status_switch.configure(arena)
	_weather_layer = WeatherLayer.new()
	add_child(_weather_layer)
	_weather_layer.configure(arena)
	_weather_cast = WeatherCastPilot.new()
	add_child(_weather_cast)
	_weather_cast.configure(arena)
	_live_catalog = LiveCatalog.new()
	add_child(_live_catalog)
	_live_catalog.configure(arena)
	_transform = TransformPilot.new()
	add_child(_transform)
	_transform.configure(arena)
	_substitute = SubstitutePilot.new()
	add_child(_substitute)
	_substitute.configure(arena)
	_presentation.diagnostic_event.connect(_on_diagnostic_event)
	_presentation.visibility_changed.connect(_on_visibility_changed)


func is_playing() -> bool:
	return _index >= 0


func enforce_input_lock() -> void:
	for entry: Dictionary in _locked:
		if is_instance_valid(entry.control):
			entry.control.disabled = true


func _process(delta: float) -> void:
	advance(delta)


func note_event_messages(events: Array[BattleEvent]) -> void:
	_prefix_count = _logs.size()
	_messages.clear()
	for event: BattleEvent in events:
		_messages.append(_presentation._event_text(event))
		if _collecting and event != null:
			_remember_move(event.move_id, _before)


func restore_display() -> void:
	if is_playing():
		_write_hud(_display_hud)


func advance(delta: float) -> void:
	if not is_playing() or not is_finite(delta) or delta < 0.0:
		return
	while is_playing():
		if delta < _remaining:
			_remaining -= delta
			_update_display()
			return
		delta -= _remaining
		_remaining = 0.0
		_update_display()
		_index += 1
		if _index >= _sequence.size():
			_finish()
		else:
			_apply_entry()


func cancel() -> void:
	_before.clear()
	_collecting = false
	if is_playing():
		_finish(true)


func build_sequence(events: Array, before: Dictionary, messages: Array = []) -> Array[Dictionary]:
	var sequence := Plan.build(events, before, messages)
	if _community != null:
		sequence = _community.decorate(sequence, before)
	if _external_damage != null:
		sequence = _external_damage.decorate(sequence, before)
	if _status_switch != null:
		sequence = _status_switch.decorate(sequence, before)
	if _weather_cast != null:
		sequence = _weather_cast.decorate(sequence, before)
	if _substitute != null: sequence = _substitute.decorate(sequence, before)
	if _transform != null: sequence = _transform.decorate(sequence, before)
	return _live_catalog.decorate(sequence, before) if _live_catalog != null else sequence


func _on_diagnostic_event(entry: Dictionary) -> void:
	match String(entry.get("event", "")):
		"battle_opened":
			cancel()
			_set_views(_snapshot().get("views", {}))
			_weather_layer.set_weather(_snapshot().get("weather", {}))
			_arena.set_capture_visual("", "", 0.0)
			_arena.set_move_visual({}, 0.0)
		"command", "player_action":
			if not is_playing():
				_before = _snapshot()
				_before["hud"] = _read_hud()
				_collecting = true
				_logs.clear()
				_messages.clear()
				_prefix_count = 0
				_caught_ball = ""
				_arena.set_capture_visual("", "", 0.0)
		"ui_log":
			if _collecting:
				_logs.append(String(entry.get("text", "")))
		"command_result", "turn_resolved":
			if is_playing():
				return
			_collecting = false
			var command_steps: Array[Dictionary] = Plan.command(entry, _before)
			_sequence = command_steps + build_sequence(entry.get("battle_events", []), _before, _messages)
			for step: Dictionary in command_steps:
				if step.get("capture_phase", "") == "caught":
					_caught_ball = String(step.ball_id)
			_final_views = _snapshot().get("views", {}).duplicate(true)
			_final_weather = _snapshot().get("weather", {}).duplicate(true)
			_final_hud = _read_hud()
			# Settlement deliberately releases BattleState before the diagnostic
			# result. Retain detached final identities instead of blanking a KO view.
			if _final_views.is_empty() and not _sequence.is_empty():
				_final_views = _sequence.back().after_views.duplicate(true)
			_reconcile_completed_player()
			if _sequence.is_empty():
				_before.clear()
				return
			_display_hud = _before.get("hud", {}).duplicate(true)
			_add_log_steps(command_steps.size())
			_before.clear()
			_write_hud(_display_hud)
			_lock_controls(_presentation)
			_index = 0
			_apply_entry()


func _snapshot() -> Dictionary:
	var session = _presentation.session
	if session == null:
		return {}
	var state: BattleState = session.battle_state()
	if state == null:
		return {}
	var result := {"views": {}, "creatures": {}, "moves": {}}
	if state.live_moves_enabled: result["live_moves_enabled"] = true
	if state.transform_rules_enabled: result["transform_rules_enabled"] = true
	if state.substitute_rules_enabled:
		result["substitute_rules_enabled"] = true
	if state.switch_move_rules_enabled:
		result["switch_move_rules_enabled"] = true
	if state.weather_rules_enabled:
		result["weather_rules_enabled"] = true
		result["weather"] = state.weather.duplicate(true)
		if not state.weather.is_empty(): result.weather["suppressed"] = WeatherRules.effective(state) == &""
	for side: BattleSide in state.sides:
		if side.side_id not in [&"side_a", &"side_b"]:
			continue
		var image_side := "back" if side.side_id == &"side_a" else "front"
		for instance_id: StringName in side.party_ids:
			var creature := state.creature(instance_id)
			if creature == null:
				continue
			var row := {"instance_id": String(instance_id), "species": String(creature.appearance_id()), "side": image_side,
				"name": SpanishGameText.creature_name(creature, _presentation.catalogs),
				"level": creature.level, "hp": creature.current_hp, "max_hp": creature.stats.max_hp,
				"visible": creature.current_hp > 0}
			if state.substitute_rules_enabled and SubstituteRules.hp(creature) > 0:
				row["substitute"] = SubstituteRules.record(creature)
			result.creatures[String(instance_id)] = row
			for slot: BattleMoveSlot in creature.moveset:
				_remember_move(slot.move_id, result)
			if instance_id == side.active_id:
				result.views[image_side] = row.duplicate(true)
	return result


func _remember_move(id: StringName, snapshot: Dictionary) -> void:
	if id == &"":
		return
	if not snapshot.has("moves"):
		snapshot["moves"] = {}
	if not snapshot.moves.has(String(id)):
		var metadata := MoveVisuals.metadata(_presentation.catalogs.move(id))
		if not metadata.is_empty():
			snapshot.moves[String(id)] = metadata


func _apply_entry() -> void:
	var entry: Dictionary = _sequence[_index]
	_set_views(entry.views)
	for side: String in ["back", "front"]:
		_arena.set_runtime_pose(side, String(entry.state) if side == String(entry.side) else "reposo", side == String(entry.side))
	_remaining = float(entry.duration)
	_community_text_shown = false
	if not entry.has("community_clip") and not entry.has("catalog_clip") and not String(entry.get("text", "")).is_empty():
		_display_hud.log = String(_display_hud.get("log", "")) + ("\n" if not String(_display_hud.get("log", "")).is_empty() else "") + String(entry.text)
	_update_display()
	pose_started.emit(entry.duplicate(true))


func _update_display() -> void:
	var entry: Dictionary = _sequence[_index]
	var progress := clampf(1.0 - _remaining / float(entry.duration), 0.0, 1.0)
	var weight := smoothstep(0.15, 0.85, progress)
	var elapsed := float(entry.duration) - _remaining
	var effect_progress := progress
	if entry.has("transform_binding"):
		var handed_off := elapsed >= float(entry.appearance_handoff_seconds)
		var appearance: Dictionary = entry.after_views if handed_off else entry.views
		_arena.player_species = StringName(appearance.get("back", {}).get("species", ""))
		_arena.enemy_species = StringName(appearance.get("front", {}).get("species", ""))
		effect_progress = 0.5 * elapsed / float(entry.appearance_handoff_seconds) if not handed_off else 0.5 + 0.5 * (elapsed - float(entry.appearance_handoff_seconds)) / (float(entry.duration) - float(entry.appearance_handoff_seconds))
	if entry.has("catalog_clip"):
		weight = smoothstep(maxf(0.0, float(entry.duration) - 0.05), float(entry.duration), elapsed)
		if weight > 0: _show_community_text(entry)
	if entry.has("community_clip"):
		var impact := float(entry.community_impact)
		weight = smoothstep(impact, float(entry.community_hp_end), elapsed)
		effect_progress = clampf((elapsed - impact) / (float(entry.duration) - impact), 0.0, 1.0)
		if elapsed >= impact:
			_show_community_text(entry)
	for side: String in ["back", "front"]:
		var from: Dictionary = entry.views.get(side, {})
		var to: Dictionary = entry.after_views.get(side, from)
		if from.is_empty():
			continue
		var hp := roundi(lerpf(float(from.get("hp", 1)), float(to.get("hp", 1)), weight))
		var maximum := maxi(1, int(to.get("max_hp", 1)))
		var key := "player" if side == "back" else "enemy"
		var prefix := "" if side == "back" else ("Entrenador: " if _presentation is TrainerBattlePresentationController else "Salvaje: ")
		_display_hud[key + "_hp"] = hp
		_display_hud[key + "_max"] = maximum
		_display_hud[key + "_text"] = "%s%s  Nv.%d   PS %d/%d" % [prefix, String(to.get("name", to.get("species", ""))), int(to.get("level", 1)), hp, maximum]
	_arena.set_runtime_effect(String(entry.side), String(entry.get("effect", "")), effect_progress)
	_community.show_entry(entry, _arena, elapsed)
	_external_damage.show_entry(entry, _arena, elapsed)
	_status_switch.show_entry(entry, _arena, elapsed)
	_weather_cast.show_entry(entry, _arena, elapsed)
	_substitute.show_entry(entry, _arena, elapsed)
	var display_views: Dictionary = entry.views.duplicate(true)
	for doll_side: String in ["back", "front"]:
		if weight >= 0.5 and display_views.has(doll_side):
			display_views[doll_side]["substitute"] = entry.after_views.get(doll_side, {}).get("substitute", {}).duplicate(true)
	_arena.set_runtime_substitutes(display_views)
	if String(entry.get("community_clip", "")).get_base_dir() in ["substitute", "shed_tail"]:
		# The native creation already draws the doll; restore the persistent one at
		# the following event, rather than drawing two during the transition.
		_arena.set_runtime_visibility(bool(display_views.get("back", {}).get("visible", true)) and entry.side != "back",
			bool(display_views.get("front", {}).get("visible", true)) and entry.side != "front")
	_weather_layer.set_weather(entry.get("weather", {}))
	if entry.has("weather"):
		var turn_text := String(_display_hud.get("turn", "")).split(" · Clima:")[0]
		var weather_label := WeatherRules.label(entry.weather)
		_display_hud.turn = turn_text + (" · Clima: " + weather_label if not weather_label.is_empty() else "")
	var visual: Dictionary = entry.get("move_visual", {})
	var visual_progress := progress
	if visual.get("phase", "") == "cast":
		var window := minf(0.6, float(entry.duration))
		visual_progress = clampf((float(entry.duration) - _remaining - (float(entry.duration) - window)) / window, 0.0, 1.0)
	_live_catalog.show_entry(entry, _arena, elapsed)
	_arena.set_move_visual(visual, visual_progress)
	if entry.has("capture_phase"):
		_arena.set_capture_visual(String(entry.capture_phase), String(entry.ball_id), progress)
	_write_hud(_display_hud)


func _read_hud() -> Dictionary:
	return {"turn": _presentation._turn_label.text, "player_text": _presentation._player_label.text,
		"enemy_text": _presentation._enemy_label.text, "player_hp": _presentation._player_hp.value,
		"enemy_hp": _presentation._enemy_hp.value, "player_max": _presentation._player_hp.max_value,
		"enemy_max": _presentation._enemy_hp.max_value, "log": _presentation._event_log.text,
		"continue_visible": _presentation._continue_button.visible}


func _reconcile_completed_player() -> void:
	var session = _presentation.session
	if session == null or session.battle_state() != null or session.player == null:
		return
	var view: Dictionary = _final_views.get("back", {})
	var creature: CreatureInstance = session.player.owned_creature(StringName(view.get("instance_id", "")))
	if creature == null:
		return
	if _before.get("transform_rules_enabled", false):
		# Capture/run release BattleState after restoring the live party. Retain
		# that confirmed original appearance instead of the pre-command copy.
		_final_views.back.species = String(creature.appearance_id())
		_final_views.back.hp = creature.current_hp
		_final_views.back.max_hp = creature.stats.max_hp
		_final_views.back.level = creature.level
	# Settlement can level up/recompute HP after the base UI's last refresh.
	# Read its completed result, never reproduce progression in presentation.
	_final_hud.player_hp = creature.current_hp
	_final_hud.player_max = creature.stats.max_hp
	_final_hud.player_text = "%s  Nv.%d   PS %d/%d" % [SpanishGameText.creature_name(creature, _presentation.catalogs), creature.level, creature.current_hp, creature.stats.max_hp]


func _write_hud(hud: Dictionary) -> void:
	if hud.is_empty():
		return
	_presentation._turn_label.text = hud.turn
	_presentation._player_label.text = hud.player_text
	_presentation._enemy_label.text = hud.enemy_text
	_presentation._player_hp.max_value = hud.player_max
	_presentation._enemy_hp.max_value = hud.enemy_max
	_presentation._player_hp.value = hud.player_hp
	_presentation._enemy_hp.value = hud.enemy_hp
	_presentation._continue_button.visible = hud.continue_visible
	if _presentation._event_log.text != String(hud.log):
		_presentation._event_log.text = hud.log
		_presentation._event_log.scroll_to_line(maxi(0, _presentation._event_log.get_line_count() - 1))


func _add_log_steps(command_steps: int) -> void:
	var views: Dictionary = _sequence[command_steps].views if command_steps < _sequence.size() else _sequence.back().after_views
	var prefixes: Array[Dictionary] = []
	for index in mini(_prefix_count, _logs.size()):
		prefixes.append(_log_step(views, _logs[index]))
	var combined: Array[Dictionary] = []
	combined.assign(_sequence.slice(0, command_steps))
	combined.append_array(prefixes)
	combined.append_array(_sequence.slice(command_steps))
	_sequence = combined
	var final_views: Dictionary = _sequence.back().after_views
	for index in range(_prefix_count + _messages.size(), _logs.size()):
		_sequence.append(_log_step(final_views, _logs[index]))


func _log_step(views: Dictionary, text: String) -> Dictionary:
	return {"views": views.duplicate(true), "after_views": views.duplicate(true), "side": "", "state": "reposo",
		"effect": "", "duration": 0.3, "event_kind": "message", "event_index": -1, "text": text}


func _set_views(views: Dictionary) -> void:
	_arena.set_runtime_substitutes(views)
	_arena.player_species = StringName(views.get("back", {}).get("species", ""))
	_arena.enemy_species = StringName(views.get("front", {}).get("species", ""))
	_arena.set_runtime_visibility(bool(views.get("back", {}).get("visible", true)), bool(views.get("front", {}).get("visible", true)))


func _finish(cancelled: bool = false) -> void:
	if cancelled:
		if _index >= 0 and _index < _sequence.size() and _sequence[_index].has("community_clip"):
			_show_community_text(_sequence[_index])
		for index in range(_index + 1, _sequence.size()):
			var text := String(_sequence[index].get("text", ""))
			if not text.is_empty():
				_display_hud.log = String(_display_hud.get("log", "")) + "\n" + text
	_index = -1
	_remaining = 0.0
	_sequence.clear()
	_community.clear()
	_external_damage.clear()
	_status_switch.clear()
	_weather_cast.clear()
	_substitute.clear()
	_live_catalog.clear()
	_weather_layer.set_weather(_final_weather)
	_set_views(_final_views)
	_arena.set_runtime_pose("back", "")
	_arena.set_runtime_pose("front", "")
	_arena.set_runtime_effect("", "", 0.0)
	_arena.set_move_visual({}, 0.0)
	_arena.set_capture_visual("caught" if not _caught_ball.is_empty() else "", _caught_ball, 1.0)
	# Preserve the paced, semantic log; final authoritative HUD values win over
	# any projection discrepancy (e.g. settlement or progression after a KO).
	_final_hud.log = _display_hud.get("log", _final_hud.get("log", ""))
	_write_hud(_final_hud)
	for entry: Dictionary in _locked:
		if is_instance_valid(entry.control):
			entry.control.disabled = entry.disabled
	_locked.clear()
	_presentation._refresh_view()
	playback_finished.emit()


func _show_community_text(entry: Dictionary) -> void:
	if not _community_text_shown and not String(entry.get("text", "")).is_empty():
		_display_hud.log = String(_display_hud.get("log", "")) + ("\n" if not String(_display_hud.get("log", "")).is_empty() else "") + String(entry.text)
	_community_text_shown = true


func _lock_controls(node: Node) -> void:
	if node is BaseButton:
		_locked.append({"control": node, "disabled": node.disabled})
		node.disabled = true
	for child in node.get_children():
		_lock_controls(child)


func _on_visibility_changed() -> void:
	if not _presentation.is_visible_in_tree():
		cancel()
