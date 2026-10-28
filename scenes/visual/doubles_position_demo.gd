extends Control

signal close_requested
const Doubles = preload("res://modules/battle/server/doubles_position_battle.gd")
const Plan = preload("res://scenes/visual/doubles_timeline_plan.gd")
const Art = preload("res://scenes/visual/doubles_battle_art.gd")
const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
const PACK := "res://.godot/battle_ally_switch/manifest.json"
const PACK_SHA := "bc085c4228966202b8037773f773b2b1a7b75864699c021b7e4832e77f85db9d"
const MOVES: Array[StringName] = [&"ally_switch", &"tackle", &"water_gun", &"quick_attack", &"extreme_speed"]
var available := false
var server: RefCounted
var arena: Control
var _catalog: DefinitionCatalog
var _choices := {}
var _turn: Label
var _log: RichTextLabel
var _submit: Button
var _reset: Button
var _close: Button
var _sequence: Array[Dictionary] = []
var _index := -1
var _elapsed := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("172d29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var columns := HBoxContainer.new()
	margin.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	_turn = _label(left, "Ensayo de dobles · Cambio de Banda")
	arena = Art.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.custom_minimum_size = Vector2(420, 300)
	left.add_child(arena)
	_log = RichTextLabel.new()
	_log.custom_minimum_size.y = 100
	_log.scroll_following = true
	left.add_child(_log)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 285
	columns.add_child(right)
	_label(right, "Elegir movimientos de ambos equipos")
	for id: String in ["a0", "a1", "b0", "b1"]:
		var label := _label(right, id)
		var row := HBoxContainer.new()
		right.add_child(row)
		var move := OptionButton.new()
		move.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(move)
		var target := OptionButton.new()
		target.add_item("Rival 1", 0)
		target.add_item("Rival 2", 1)
		row.add_child(target)
		_choices[id] = {"label": label, "move": move, "target": target}
	_submit = _button(right, "Resolver turno", submit_selected_turn)
	_reset = _button(right, "Reiniciar ensayo", reset_scenario)
	_close = _button(right, "Volver al mapa · Esc", func(): close_requested.emit())
	_label(right, "Los ataques se dirigen al puesto elegido.\nCambio de Banda intercambia a los aliados.")
	hide()


func configure(catalog: DefinitionCatalog) -> bool:
	_catalog = catalog
	if not FileAccess.file_exists(PACK) or FileAccess.get_sha256(PACK) != PACK_SHA: return false
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PACK))
	if data.get("selection") != "ally_switch_positions_v1": return false
	arena.fade_curves = data.fade_curves.duplicate(true)
	for id: StringName in MOVES: arena.move_metadata[String(id)] = Visuals.metadata(_catalog.move(id))
	available = true
	reset_scenario()
	return true


func reset_scenario() -> void:
	if not available: return
	_index = -1
	_sequence.clear()
	var creatures: Array[CreatureInstance] = []
	for index in 4:
		creatures.append(CreatureInstance.new(StringName(["a0", "a1", "b0", "b1"][index]),
			StringName(["gardevoir", "pikachu", "charizard", "blastoise"][index]), 50,
			StatBlock.new(500, 100, 100, [50, 100, 150, 125][index], 100, 100), MOVES))
	server = Doubles.new(BattleState.create_with_parties(&"f12_ally_switch", [creatures[0], creatures[1]], [creatures[2], creatures[3]], 107), _catalog)
	_log.text = "Dos Pokémon activos por equipo. Prepara las cuatro acciones y resuelve el turno.\n"
	for id: String in _choices:
		var input: OptionButton = _choices[id].move
		input.clear()
		for move: StringName in MOVES:
			input.add_item(_catalog.move(move).display_name)
			input.set_item_metadata(input.item_count - 1, move)
		input.select(0 if id == "a0" else (2 if id == "b0" else 1))
		_choices[id].target.select(0)
	show_projection(Plan.projection(server.snapshot()))
	_refresh_controls()


func show_projection(frame: Dictionary) -> void:
	var localized := frame.duplicate(true)
	for id: String in localized.units: localized.units[id]["name"] = String(localized.units[id].species).capitalize()
	arena.show_step({"before": localized, "after": localized, "event": {}}, 1.0)


func selected_commands() -> Array[BattleAction]:
	var result: Array[BattleAction] = []
	for id: StringName in server.living_ids():
		var selected: Dictionary = _choices[String(id)]
		var move := StringName(selected.move.get_item_metadata(selected.move.selected))
		var own_side: String = server.position_of(id).side_id
		var opposite := "side_b" if own_side == "side_a" else "side_a"
		var target := id if move == &"ally_switch" else StringName(server.slots[opposite][selected.target.selected])
		result.append(BattleAction.new(server.state.turn + 1, id, move, target, BattleAction.MOVE, StringName(own_side)))
	return result


func submit_selected_turn() -> Array[BattleEvent]:
	if not available or _index >= 0: return []
	var before := Plan.projection(server.snapshot())
	var events: Array[BattleEvent] = server.submit_turn(selected_commands())
	_sequence = Plan.build(events, before)
	_index = 0 if not _sequence.is_empty() else -1
	_elapsed = 0
	_refresh_controls()
	if _index >= 0: _start_step()
	return events


func _process(delta: float) -> void:
	if not visible or _index < 0: return
	advance(delta)


func advance(seconds: float) -> void:
	if _index < 0: return
	_elapsed += maxf(0, seconds)
	while _index >= 0 and _elapsed >= float(_sequence[_index].duration):
		_elapsed -= float(_sequence[_index].duration)
		_index += 1
		if _index >= _sequence.size():
			_index = -1
			show_projection(Plan.projection(server.snapshot()))
			_refresh_controls()
			return
		_start_step()
	if _index >= 0: arena.show_step(_sequence[_index], _elapsed / float(_sequence[_index].duration))


func _start_step() -> void:
	var event: Dictionary = _sequence[_index].event
	var message := _event_text(event)
	if not message.is_empty(): _log.append_text(message + "\n")
	arena.show_step(_sequence[_index], _elapsed / float(_sequence[_index].duration))


func _name(id: String) -> String:
	var creature: CreatureInstance = server.state.creature(StringName(id))
	return String(creature.species_id).capitalize() if creature != null else "Pokémon"


func _event_text(event: Dictionary) -> String:
	var actor := _name(String(event.get("actor_id", "")))
	var target := _name(String(event.get("target_id", "")))
	match String(event.kind):
		String(BattleEvent.ACTION_USED): return "%s usó %s." % [actor, _catalog.move(StringName(event.move_id)).display_name]
		String(BattleEvent.ALLY_POSITIONS_SWAPPED): return "%s y %s intercambiaron sus puestos." % [actor, target]
		String(BattleEvent.ALLY_SWITCH_FAILED): return "Cambio de Banda falló: " + ("no queda un aliado activo." if event.metadata.reason == "no_living_ally" else "no pudo repetir el intercambio.")
		String(BattleEvent.POSITION_TARGET_RESOLVED): return "El ataque alcanza ahora a %s, que ocupa el puesto elegido." % target
		String(BattleEvent.DAMAGE_APPLIED): return "%s recibió %d PS de daño." % [target, int(event.amount)]
		String(BattleEvent.STATUS_DAMAGE): return "%s perdió %d PS por su estado." % [target, int(event.amount)]
		String(BattleEvent.KNOCKED_OUT): return "%s cayó debilitado." % target
		String(BattleEvent.MOVE_MISSED): return "%s falló el ataque." % actor
		String(BattleEvent.BATTLE_ENDED): return "El combate ha terminado."
		String(BattleEvent.ACTION_REJECTED): return "No se pudo resolver el turno con esa selección."
	return ""


func _refresh_controls() -> void:
	var playing := _index >= 0
	_turn.text = "Ensayo de dobles · Turno %d" % (server.state.turn + 1)
	if server.state.phase == BattleState.FINISHED: _turn.text = "Ensayo de dobles · Combate terminado"
	_submit.disabled = playing or server.state.phase == BattleState.FINISHED
	_reset.disabled = playing
	for id: String in _choices:
		var creature: CreatureInstance = server.state.creature(StringName(id))
		var input: Dictionary = _choices[id]
		input.label.text = "%s · %s · Puesto %d" % [_name(id), "Tu equipo" if id.begins_with("a") else "Rival", int(server.position_of(StringName(id)).slot) + 1]
		input.move.disabled = playing or creature.is_knocked_out()
		input.target.disabled = playing or creature.is_knocked_out()
		var opposite := "side_b" if id.begins_with("a") else "side_a"
		for position in 2:
			var candidate: CreatureInstance = server.at_position(opposite, position)
			input.target.set_item_disabled(position, candidate == null or candidate.is_knocked_out())
		if input.target.is_item_disabled(input.target.selected):
			for position in 2:
				if not input.target.is_item_disabled(position):
					input.target.select(position)
					break
		for index in MOVES.size():
			var slot := creature.move_slot(MOVES[index])
			input.move.set_item_text(index, "%s · %d PP" % [_catalog.move(MOVES[index]).display_name, slot.current_pp])
			input.move.set_item_disabled(index, slot.current_pp <= 0)


func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
