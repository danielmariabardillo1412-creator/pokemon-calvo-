extends Control

signal close_requested
const Backend = preload("res://modules/battle/backends/showdown/doubles_backend.gd")
const Plan = preload("res://scenes/visual/native_doubles_timeline.gd")
const Art = preload("res://scenes/visual/doubles_battle_art.gd")
const Clips = preload("res://scenes/visual/live_battle_catalog.gd")
const Serializer = preload("res://modules/save/save_game_serializer.gd")
const IDS := ["after_you", "ally_switch", "aromatic_mist", "coaching", "dragon_cheer", "follow_me", "helping_hand", "hold_hands", "quash", "rage_powder", "spotlight"]
const SAVE := "user://pokemon_calvo_doubles.json"
var save_path := SAVE
var format_id := "gen9doublescustomgame"
var server: RefCounted
var arena: Control
var clips: Node
var available := false
var loading := false
var _catalog: DefinitionCatalog
var _preset: OptionButton
var _origin: OptionButton
var _title: Label
var _log: RichTextLabel
var _commands: VBoxContainer
var _choices := {}
var _buttons: Array[Button] = []
var _sequence: Array[Dictionary] = []
var _index := -1
var _elapsed := 0.0
var _epoch := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("172d29"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(margin)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 10)
	var columns := HBoxContainer.new(); margin.add_child(columns)
	var left := VBoxContainer.new(); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; columns.add_child(left)
	_title = Label.new(); left.add_child(_title)
	arena = Art.new(); arena.generic_effects_enabled = false; arena.size_flags_vertical = Control.SIZE_EXPAND_FILL; arena.custom_minimum_size = Vector2(460, 300); left.add_child(arena)
	clips = Clips.new(); add_child(clips); clips.configure(arena)
	_log = RichTextLabel.new(); _log.custom_minimum_size.y = 95; _log.scroll_following = true; left.add_child(_log)
	var right := VBoxContainer.new(); right.custom_minimum_size.x = 300; columns.add_child(right)
	var hint := Label.new(); hint.text = "Dobles · ensayo sin alterar tu partida"; right.add_child(hint)
	_preset = OptionButton.new(); right.add_child(_preset)
	_origin = OptionButton.new(); _origin.add_item("Movimiento desde tu lado", 0); _origin.add_item("Movimiento desde el rival", 1); right.add_child(_origin)
	_button(right, "Preparar caso seleccionado", reset_scenario)
	_commands = VBoxContainer.new(); right.add_child(_commands)
	_button(right, "Resolver las cuatro acciones", submit_selected_turn)
	var row := HBoxContainer.new(); right.add_child(row)
	_button(row, "Guardar ensayo", save_trial); _button(row, "Cargar ensayo", load_trial)
	_button(right, "Volver al mapa · Esc", func(): close_requested.emit())
	var help := Label.new(); help.text = "Elige movimiento y objetivo por puesto.\nPuedes cambiar a una reserva.\nManos Juntas no concede mejoras."
	help.add_theme_font_size_override("font_size", 12); right.add_child(help)
	hide()


func _button(parent: Node, text: String, action: Callable) -> void:
	var b := Button.new(); b.text = text; b.pressed.connect(action); parent.add_child(b); _buttons.append(b)


func configure(catalog: DefinitionCatalog) -> bool:
	_catalog = catalog
	if not clips.available: return false
	var pack := "res://.godot/battle_ally_switch/manifest.json"
	if FileAccess.get_sha256(pack) != "bc085c4228966202b8037773f773b2b1a7b75864699c021b7e4832e77f85db9d": return false
	arena.fade_curves = JSON.parse_string(FileAccess.get_file_as_string(pack)).fade_curves
	if _preset.item_count == 0:
		for id: String in IDS: _preset.add_item(_catalog.move(StringName(id)).display_name); _preset.set_item_metadata(_preset.item_count - 1, id)
	available = true; reset_scenario(); return true


func _mon(id: String, species: String, moves: Array, level: int = 50) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(_catalog.species(StringName(species)), level, _catalog, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""; return c


func reset_scenario() -> void:
	if not available or loading: return
	loading = true; _sequence.clear(); _index = -1; clips.clear(); arena.animated_units.clear(); _refresh_lock()
	var token := _epoch
	if server != null: await server.close()
	if token != _epoch: return
	var id := String(_preset.get_item_metadata(_preset.selected))
	var own := [_mon("actor", "mew", [id, "protect", "tackle"], 60), _mon("ally", "druddigon", ["tackle", "protect"]), _mon("reserve_a", "pikachu", ["tackle", "protect"])] as Array[CreatureInstance]
	var foe := [_mon("foe0", "mew", ["reflect", "tackle"]), _mon("foe1", "mew", ["reflect", "tackle"]), _mon("reserve_b", "charizard", ["tackle", "protect"])] as Array[CreatureInstance]
	server = Backend.new(_catalog, format_id)
	var ok: bool = await server.open(get_tree(), own if _origin.selected == 0 else foe, foe if _origin.selected == 0 else own)
	if token != _epoch: return
	loading = false
	_log.clear()
	_log.append_text("Selecciona las acciones de ambos equipos. Las reservas y los PS pertenecen solo a este ensayo.\n" if ok else "No se pudo abrir: " + server.last_error)
	if ok:
		show_projection(Plan.projection(server._checkpoint, _catalog)); refresh_choices(); _preset_commands(id)
	_refresh_lock()


func show_projection(frame: Dictionary) -> void:
	arena.show_step({"before": frame, "after": frame, "event": {}}, 1.0)


func refresh_choices() -> void:
	for child in _commands.get_children(): _commands.remove_child(child); child.queue_free()
	_choices.clear()
	for side: String in ["p1", "p2"]:
		var req: Dictionary = server.request(side)
		for slot in 2:
			var label := Label.new(); label.add_theme_font_size_override("font_size", 12)
			var ids: Array = server.active_ids(side)
			var c: CreatureInstance = server.presentation_state.creature(StringName(ids[slot])) if not String(ids[slot]).is_empty() else null
			label.text = ("Tú " if side == "p1" else "Rival ") + str(slot + 1) + " · " + (SpanishGameText.creature_name(c, _catalog) if c != null else "Vacío")
			_commands.add_child(label)
			var row := HBoxContainer.new(); _commands.add_child(row)
			var move := OptionButton.new(); move.custom_minimum_size.x = 150; move.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(move)
			var target := OptionButton.new(); target.custom_minimum_size.x = 130; row.add_child(target)
			var key := side + str(slot); _choices[key] = {"move": move, "target": target, "side": side, "slot": slot}
			var forced: Array = req.get("forceSwitch", [])
			var waiting: bool = req.is_empty() or req.get("wait", false) or not forced.is_empty() and not forced[slot]
			if waiting or c == null or c.is_knocked_out() and forced.is_empty():
				move.add_item("Esperar"); move.set_item_metadata(0, {"command": "pass", "target": "self"})
			else:
				if forced.is_empty():
					var moves: Array = req.active[slot].moves
					for i in moves.size():
						var m: Dictionary = moves[i]; move.add_item(String(m.move) + " · " + str(m.pp) + " PP")
						move.set_item_metadata(move.item_count - 1, {"command": "move " + str(i + 1), "target": m.target})
						move.set_item_disabled(move.item_count - 1, m.get("disabled", false) or int(m.pp) <= 0)
				for i in req.side.pokemon.size():
					var p: Dictionary = req.side.pokemon[i]
					if p.active or String(p.condition).ends_with("fnt"): continue
					move.add_item("Cambiar: " + String(p.details).split(",")[0]); move.set_item_metadata(move.item_count - 1, {"command": "switch " + str(i + 1), "target": "self"})
			for i in move.item_count:
				if not move.is_item_disabled(i): move.select(i); break
			move.item_selected.connect(func(_i): refresh_targets(key)); refresh_targets(key)
	_refresh_lock()


func refresh_targets(key: String) -> void:
	var row: Dictionary = _choices[key]; var menu: OptionButton = row.target; menu.clear()
	if row.move.selected < 0: return
	var action: Dictionary = row.move.get_item_metadata(row.move.selected)
	for option: Dictionary in server.targets(row.side, row.slot, action.target):
		menu.add_item(option.label); menu.set_item_metadata(menu.item_count - 1, option.location)


func _preset_commands(id: String) -> void:
	var side := "p1" if _origin.selected == 0 else "p2"
	for key: String in _choices:
		var row: Dictionary = _choices[key]
		var attack: bool = id in ["follow_me", "rage_powder"] and row.side != side
		row.move.select(1 if attack else 0); refresh_targets(key)
		var location := 2 if attack or id == "spotlight" and row.side == side and row.slot == 0 else 1
		if row.side == side and row.slot == 0 and id in ["after_you", "aromatic_mist", "coaching", "dragon_cheer", "helping_hand", "hold_hands"]: location = -2
		for i in row.target.item_count:
			if int(row.target.get_item_metadata(i)) == location: row.target.select(i); break


func selected_commands() -> Dictionary:
	var choices := {}
	for side: String in ["p1", "p2"]:
		var req: Dictionary = server.request(side)
		if req.is_empty() or req.get("wait", false): continue
		var parts: Array[String] = []
		for slot in 2:
			var row: Dictionary = _choices[side + str(slot)]
			if row.move.selected < 0 or row.move.is_item_disabled(row.move.selected) or row.target.selected < 0: return {}
			var action: Dictionary = row.move.get_item_metadata(row.move.selected)
			var location := int(row.target.get_item_metadata(row.target.selected))
			parts.append(String(action.command) + (" " + str(location) if location != 0 else ""))
		choices[side] = ", ".join(parts)
	return choices


func submit_selected_turn() -> Dictionary:
	if loading or _index >= 0 or server == null: return {"accepted": false}
	var before := Plan.projection(server._checkpoint, _catalog)
	loading = true; _refresh_lock(); var token := _epoch
	var result: Dictionary = await server.submit_pair(selected_commands(), server.revision)
	if token != _epoch: return result
	loading = false
	if result.accepted:
		_sequence = Plan.build(result.events, before, Plan.projection(server._checkpoint, _catalog)); _index = 0; _elapsed = 0; _start_step()
	else: _log.append_text("Acción rechazada: " + String(result.get("error", "")) + "\n")
	_refresh_lock(); return result


func _start_step() -> void:
	clips.clear()
	arena.animated_units.clear()
	var step: Dictionary = _sequence[_index]; var e: Dictionary = step.event
	if e.get("kind") == String(BattleEvent.ACTION_USED):
		var actor := String(e.actor_id); var target := String(e.target_id)
		var units: Dictionary = step.before.units
		if not units.has(target): target = actor
		var definition := _catalog.move(StringName(e.move_id))
		_log.append_text(String(units.get(actor, {}).get("name", actor)) + ": " + (definition.display_name if definition != null else String(e.move_id)) + " → " + String(units.get(target, {}).get("name", target)) + "\n")
		if units.has(actor) and units.has(target) and e.move_id != "ally_switch":
			var key := String(e.move_id) + ("/back" if units[actor].side == "side_a" else "/front")
			if clips._load(key):
				var preview: Control = clips.preview
				preview.effects_only = false; preview.affine_particle_path = false; preview.size = arena.size
				preview.external_layer_names.assign(["PRAS- Mist FG.png", "PRAS- Aromatherapy FG.png"] if e.move_id == "aromatic_mist" else [])
				var origin := String(preview.clip.actor_side)
				# Native OppMove exports retain canonical back/front source slots;
				# mirrored exports reverse them. Bind the actor by semantic side.
				preview.external_actor_layout = {origin: arena.actor_layout(units[actor]), "front" if origin == "back" else "back": arena.actor_layout(units[target])}
				preview.external_bystanders.clear()
				for other: String in units:
					if other in [actor, target] or int(units[other].hp) <= 0: continue
					var layout: Dictionary = arena.actor_layout(units[other])
					layout["depth"] = 30 if units[other].side == "side_a" else 20
					preview.external_bystanders.append(layout); arena.animated_units[other] = true
				# Keep imported battler motion/tint as well as particles. Only the
				# two clip-owned bodies are replaced; the other actives stay visible.
				for frame: Array in preview.clip.frames:
					for slot in mini(2, frame.size()):
						if frame[slot] != null and int(frame[slot][7]) < 0:
							var source_side := String(preview.clip.slot_sides[0 if int(frame[slot][7]) == -1 else 1])
							var owner := actor if source_side == origin else target
							arena.animated_units[owner] = true
				step.duration = float(clips.bindings[key].frames) / float(clips.bindings[key].fps)
				preview.show_seconds(0); preview.show()
		elif e.move_id == "ally_switch": step.duration = 0.1
	elif e.get("metadata", {}).get("native_tag") in ["-fail", "-miss"]: _log.append_text("El movimiento ha fallado.\n")
	arena.show_step(step, 0)


func _process(delta: float) -> void:
	if visible and _index >= 0: advance(delta)


func advance(seconds: float) -> void:
	if _index < 0: return
	_elapsed += maxf(0, seconds)
	var step: Dictionary = _sequence[_index]
	arena.show_step(step, _elapsed / maxf(0.01, float(step.duration)))
	if is_instance_valid(clips.preview) and clips.preview.visible: clips.preview.show_seconds(minf(_elapsed, float(step.duration) - 0.000001))
	if _elapsed < float(step.duration): return
	_index += 1; _elapsed = 0
	if _index >= _sequence.size():
		_index = -1; clips.clear(); arena.animated_units.clear(); show_projection(Plan.projection(server._checkpoint, _catalog)); refresh_choices()
	else: _start_step()
	_refresh_lock()


func _refresh_lock() -> void:
	var locked: bool = loading or _index >= 0
	for b: Button in _buttons: b.disabled = locked
	_preset.disabled = locked; _origin.disabled = locked
	for row: Dictionary in _choices.values(): row.move.disabled = locked; row.target.disabled = locked
	_title.text = "Preparando dobles…" if loading else "Dobles · Turno " + str(server.presentation_state.turn + 1 if server != null and server.presentation_state != null else 0)
	if server != null and server.phase() == "finished": _title.text += " · Finalizado"


func save_trial() -> void:
	if loading or _index >= 0 or server == null or server.needs_recovery: return
	_log.append_text("Ensayo guardado.\n" if Serializer.new().write_atomic_dictionary(save_path, server.snapshot()).ok else "No se pudo guardar.\n")


func load_trial() -> void:
	if loading or _index >= 0: return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path)) if FileAccess.file_exists(save_path) else null
	if not data is Dictionary: _log.append_text("No hay un ensayo válido guardado.\n"); return
	loading = true; _refresh_lock(); var token := _epoch; var candidate := Backend.new(_catalog, format_id)
	var ok: bool = await candidate.restore_saved(get_tree(), data)
	if token != _epoch: await candidate.close(); return
	if ok:
		if server != null: await server.close()
		if token != _epoch: await candidate.close(); return
		server = candidate; clips.clear(); arena.animated_units.clear(); show_projection(Plan.projection(server._checkpoint, _catalog)); refresh_choices()
	else: await candidate.close()
	loading = false; _log.append_text("Ensayo cargado.\n" if ok else "Ensayo rechazado; se conserva el actual.\n"); _refresh_lock()


func shutdown() -> void:
	_epoch += 1; _sequence.clear(); _index = -1; clips.clear(); arena.animated_units.clear()
	if server != null: await server.close()
	server = null; loading = false; hide()


func _exit_tree() -> void:
	_epoch += 1
	if server != null: server.stop_now()
