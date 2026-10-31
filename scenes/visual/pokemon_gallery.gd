extends Control

signal close_requested
const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Arena = preload("res://scenes/visual/battle_art.gd")
const ItemGallery = preload("res://scenes/visual/item_gallery.gd")
var _tabs: TabContainer
var _items: Control
var _list: ItemList
var _arena: Control
var _detail: Label
var _states: OptionButton
var _keys: Array[String] = []
var _selected_species: StringName = &""
var _comparison_species: StringName = &""
var _comparison_swapped := false
var _comparison_input: LineEdit
var _comparison_status: Label
var _shiny: CheckButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("172d2b")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	_tabs = TabContainer.new()
	margin.add_child(_tabs)
	var root := VBoxContainer.new()
	root.name = "Pokémon"
	_tabs.add_child(root)
	var heading := Label.new()
	heading.text = "CATÁLOGO VISUAL · %d entradas · especies base y regionales" % Catalog.species_rows().size()
	root.add_child(heading)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 230
	columns.add_child(left)
	var search := LineEdit.new()
	search.placeholder_text = "Buscar nombre o ID…"
	search.text_changed.connect(_filter)
	left.add_child(search)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_select)
	left.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	_arena = Arena.new()
	_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_arena)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_detail)
	var comparison := HBoxContainer.new()
	right.add_child(comparison)
	_comparison_input = LineEdit.new()
	_comparison_input.placeholder_text = "Comparar con ID o nombre"
	_comparison_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comparison_input.text_submitted.connect(_compare_with)
	comparison.add_child(_comparison_input)
	var compare_button := Button.new()
	compare_button.text = "Comparar"
	compare_button.pressed.connect(func(): _compare_with(_comparison_input.text))
	comparison.add_child(compare_button)
	var swap_button := Button.new()
	swap_button.text = "Invertir lados"
	swap_button.pressed.connect(_swap_comparison)
	comparison.add_child(swap_button)
	var same_button := Button.new()
	same_button.text = "Misma especie"
	same_button.pressed.connect(_clear_comparison)
	comparison.add_child(same_button)
	_comparison_status = Label.new()
	_comparison_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_comparison_status)
	var controls := HBoxContainer.new()
	right.add_child(controls)
	_states = OptionButton.new()
	_states.item_selected.connect(func(_index: int): _repeat())
	controls.add_child(_states)
	_shiny = CheckButton.new()
	_shiny.text = "Shiny"
	_shiny.toggled.connect(func(_enabled: bool): _apply_comparison())
	controls.add_child(_shiny)
	var repeat := Button.new()
	repeat.text = "Repetir"
	repeat.pressed.connect(_repeat)
	controls.add_child(repeat)
	var close := Button.new()
	close.text = "Cerrar · F3 / Esc"
	close.pressed.connect(func(): close_requested.emit())
	controls.add_child(close)
	var footer := Label.new()
	footer.text = "Vista artística: no modifica el equipo. Shiny solo con recursos existentes; sin VFX de ataques."
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(footer)
	_items = ItemGallery.new()
	_items.name = "Objetos"
	_items.close_requested.connect(func(): close_requested.emit())
	_tabs.add_child(_items)
	_filter("")
	hide()


func _repeat() -> void:
	if _states.selected >= 0:
		_arena.restart_animation(String(_states.get_item_metadata(_states.selected)))
		_apply_comparison()


func _compare_with(query: String) -> void:
	var key := query.strip_edges().to_lower().replace("-", "_")
	var rows: Dictionary = Catalog.species_rows()
	if not rows.has(key):
		key = ""
		for candidate: String in rows:
			if String(rows[candidate].display_name).to_lower() == query.strip_edges().to_lower():
				key = candidate
				break
	if key.is_empty():
		_comparison_status.text = "No encontrado: utiliza el ID mostrado junto al nombre."
		return
	_comparison_species = StringName(key)
	_comparison_input.text = key
	_apply_comparison()


func _swap_comparison() -> void:
	if _comparison_species != &"":
		_comparison_swapped = not _comparison_swapped
		_apply_comparison()


func _clear_comparison() -> void:
	_comparison_species = &""
	_comparison_swapped = false
	_comparison_input.clear()
	_apply_comparison()


func _apply_comparison() -> void:
	_arena.player_preview_state = ""
	_arena.enemy_preview_state = ""
	_arena.player_species = _selected_species
	_arena.enemy_species = _selected_species
	_arena.queue_redraw()
	_comparison_status.text = ""
	if _selected_species == &"":
		return
	if _comparison_species != &"" and _comparison_swapped:
		_arena.enemy_species = _comparison_species
		_arena.enemy_preview_state = "reposo"
	elif _comparison_species != &"":
		_arena.player_species = _comparison_species
		_arena.player_preview_state = "reposo"
	var rows: Dictionary = Catalog.species_rows()
	_comparison_status.text = "Espalda: %s · Frontal: %s · referencia en reposo" % [
		rows[String(_arena.player_species)].display_name, rows[String(_arena.enemy_species)].display_name]
	if _shiny != null and _shiny.button_pressed:
		for side: String in ["player_species", "enemy_species"]:
			var id: StringName = _arena.get(side)
			if Catalog.has_shiny(id):
				_arena.set(side, StringName(String(id) + "__shiny"))
			else:
				_comparison_status.text += " · Sin shiny preparado: " + String(id)
		_arena.player_preview_state = "reposo"
		_arena.enemy_preview_state = "reposo"


func _filter(query: String) -> void:
	_list.clear()
	_keys.clear()
	var rows: Dictionary = Catalog.species_rows()
	var keys: Array = rows.keys()
	keys.sort()
	for key: String in keys:
		var label := "%s · %s" % [rows[key].display_name, key]
		if query.is_empty() or query.to_lower() in label.to_lower():
			_keys.append(key)
			_list.add_item(label)
	if not _keys.is_empty():
		_list.select(0)
		_select(0)
	else:
		_selected_species = &""
		_arena.player_species = &""
		_arena.enemy_species = &""
		_detail.text = "Sin coincidencias o pack local ausente."
		_states.clear()


func _select(index: int) -> void:
	if index < 0 or index >= _keys.size():
		return
	var key := _keys[index]
	var row: Dictionary = Catalog.species_rows()[key]
	_shiny.disabled = not Catalog.has_shiny(StringName(key))
	if _shiny.disabled: _shiny.set_pressed_no_signal(false)
	_selected_species = StringName(key)
	_apply_comparison()
	_states.clear()
	for state: String in ["reposo", "ataque", "dano"]:
		if row.states.has(state):
			_states.add_item("Daño" if state == "dano" else state.capitalize())
			_states.set_item_metadata(_states.item_count - 1, state)
	_states.select(0)
	_arena.restart_animation("reposo")
	var reference: Dictionary = Catalog.scale_references().get(key, {})
	var reference_text := "Sin tabla de escala compatible."
	if bool(row.provisional):
		reference_text = "Render propio: escala relativa propuesta, sin referencia externa."
	elif reference.get("front", {}).get("status", "") == "reference_silhouette_adapted" or reference.get("back", {}).get("status", "") == "reference_silhouette_adapted":
		reference_text = "Escala adaptada a Showdown; versión del recurso distinta."
	elif not reference.is_empty():
		reference_text = "Proporciones del pack Showdown; encuadre adaptado a esta arena."
	elif row.has("metrics"):
		reference_text = "Escala de catálogo y límites medidos; encuadre adaptado a esta arena."
	_detail.text = "%s · ID del juego: %s\n%s\n%s" % [row.display_name, key,
		"Candidato 3D provisional: reposo, ataque corporal y daño." if row.provisional else "Render existente: reposo; no se inventan ataques corporales.",
		reference_text]
