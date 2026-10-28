extends PanelContainer

signal popup_hide

const Service = preload("res://modules/inventory/field_item_service.gd")
const Art = preload("res://scenes/visual/item_art_catalog.gd")
var field: Node2D
var service := Service.new()
var _items: ItemList
var _targets: OptionButton
var _moves: OptionButton
var _result: Label
var _description: Label
var _use: Button
var _equip: Button


func _ready() -> void:
	hide()
	visibility_changed.connect(func():
		if not visible: popup_hide.emit())
	var box := VBoxContainer.new(); box.custom_minimum_size = Vector2(600, 360); box.add_theme_constant_override("separation", 10); add_child(box)
	var title := Label.new(); title.text = "MOCHILA · FUERA DEL COMBATE"; box.add_child(title)
	_items = ItemList.new(); _items.custom_minimum_size.y = 135; _items.fixed_icon_size = Vector2i(32, 32); box.add_child(_items)
	_description = Label.new(); _description.custom_minimum_size.x = 540; _description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(_description)
	_targets = OptionButton.new(); box.add_child(_targets)
	_moves = OptionButton.new(); box.add_child(_moves)
	_items.item_selected.connect(func(_i): _refresh_choices())
	_targets.item_selected.connect(func(_i): _refresh_choices())
	var buttons := HBoxContainer.new(); box.add_child(buttons)
	_use = _button(buttons, "Usar", func(): _apply("use"))
	_equip = _button(buttons, "Equipar", func(): _apply("equip"))
	_button(buttons, "Quitar equipado", func(): _apply("unequip"))
	_button(buttons, "Cerrar · B / Esc", hide)
	_result = Label.new(); _result.custom_minimum_size.x = 540; _result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(_result)


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new(); button.text = text; button.pressed.connect(callback); parent.add_child(button); return button


func open_bag() -> bool:
	if field == null or not field.field_can_open_item_bag(): return false
	if not field.field_bind_item_service(service): return false
	_result.text = "Selecciona un objeto y un Pokémon. Las funciones pendientes no consumirán el objeto."
	refresh()
	reset_size()
	position = (get_viewport_rect().size - size) / 2.0
	show()
	_fit_bag.call_deferred()
	field.field_item_bag_opened()
	return true


func _fit_bag() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not visible: return
	reset_size()
	position = (get_viewport_rect().size - size) / 2.0


func _selected_item() -> StringName:
	var selected := _items.get_selected_items()
	return StringName(_items.get_item_metadata(selected[0])) if not selected.is_empty() else &""


func _selected_creature() -> StringName:
	return StringName(_targets.get_item_metadata(_targets.selected)) if _targets.item_count > 0 else &""


func refresh() -> void:
	var item_id := _selected_item()
	var creature_id := _selected_creature()
	_items.clear(); _targets.clear()
	if not _ensure_binding():
		_moves.clear(); _moves.hide()
		_description.text = ""
		_use.disabled = true
		_equip.disabled = true
		return
	var definitions: DefinitionCatalog = field.field_definitions()
	var collection: PlayerCollection = service.owner
	for id: StringName in collection.inventory.all_item_ids():
		_items.add_item("%s · %d" % [SpanishGameText.item_name(id, definitions), collection.inventory.quantity(id)], Art.texture(id))
		var index := _items.item_count - 1; _items.set_item_metadata(index, String(id))
		if id == item_id: _items.select(index)
	if _items.item_count > 0 and _items.get_selected_items().is_empty(): _items.select(0)
	_items.ensure_current_is_visible.call_deferred()
	for creature: CreatureInstance in collection.party.get_creatures():
		var held := SpanishGameText.item_name(creature.held_item_id, definitions) if creature.held_item_id != &"" and not creature.held_item_consumed else "sin objeto"
		_targets.add_item("%s · Nv. %d · PS %d/%d · %s" % [SpanishGameText.species_name(creature.species_id, definitions), creature.level, creature.current_hp, creature.stats.max_hp, held])
		var index := _targets.item_count - 1; _targets.set_item_metadata(index, String(creature.instance_id))
		if creature.instance_id == creature_id: _targets.select(index)
	_refresh_choices()


func _ensure_binding() -> bool:
	if field == null: return false
	if field.field_item_service_is_current(service): return true
	if not field.field_bind_item_service(service): return false
	return field.field_item_service_is_current(service)


func _refresh_choices() -> void:
	_moves.clear(); _moves.add_item("Aprender sin sustituir un movimiento")
	if field == null or not field.field_item_service_is_current(service) or service.owner == null:
		_moves.visible = false
		_description.text = ""
		_use.disabled = true
		_equip.disabled = true
		return
	var definitions: DefinitionCatalog = field.field_definitions()
	var creature := service.owner.owned_creature(_selected_creature())
	if creature != null:
		for slot: BattleMoveSlot in creature.moveset: _moves.add_item("Sustituir: " + SpanishGameText.move_name(slot.move_id, definitions))
	_moves.visible = service.profile.get("machine_rows", {}).has(String(_selected_item()))
	var pp_target: bool = service.FieldEffects.pp_target_required(_selected_item())
	if pp_target:
		_moves.clear(); _moves.add_item("Elige el movimiento que recuperará PP")
		if creature != null:
			for slot: BattleMoveSlot in creature.moveset: _moves.add_item("%s · PP %d/%d" % [SpanishGameText.move_name(slot.move_id, definitions), slot.current_pp, slot.max_pp])
		_moves.visible = true
	_description.text = ""
	if pp_target:
		_description.text = "Recupera PP del movimiento seleccionado."
	elif _moves.visible:
		var taught := service.machine_move(_selected_item())
		_description.text = "Enseña: " + SpanishGameText.move_name(taught, definitions) if taught != &"" else "Esta máquina necesita una versión de reglas aún pendiente."
	elif service.Medicine.supports(_selected_item()):
		_description.text = "Medicina para el Pokémon seleccionado. Se consume solo si tiene efecto."
	elif service.FieldEffects.EV_BERRIES.has(String(_selected_item())):
		_description.text = "Reduce hasta 10 EV de una estadística y aumenta la amistad."
	_use.disabled = _selected_item() == &"" or creature == null
	_equip.disabled = _use.disabled or not service.holdable(_selected_item())


func _apply(action: String) -> Dictionary:
	if field == null or not field.field_item_service_is_current(service):
		_result.text = "Espera a terminar el combate o el desplazamiento."
		refresh()
		if field != null: field.field_refresh_hud()
		return {"accepted": false, "reason": "field_locked", "status": "REJECTED"}
	var definitions: DefinitionCatalog = field.field_definitions()
	var result: Dictionary
	match action:
		"equip": result = service.equip(_selected_item(), _selected_creature())
		"unequip": result = service.unequip(_selected_creature())
		_: result = service.use_item(_selected_item(), _selected_creature(), _moves.selected - 1 if _moves.visible else -1)
	if result.accepted:
		_result.text = "Objeto equipado." if action == "equip" else "Objeto retirado." if action == "unequip" else "Objeto utilizado."
		if result.has("species_id"): _result.text = "¡Ha evolucionado a %s!" % SpanishGameText.species_name(StringName(result.species_id), definitions)
		if result.has("move_id"): _result.text = "¡Ha aprendido %s!" % SpanishGameText.move_name(StringName(result.move_id), definitions)
	else:
		if result.reason in ["item_has_no_effect", "move_slot_required", "unexpected_move_slot"]:
			_result.text = {"item_has_no_effect": "No tendría efecto. El objeto se conserva.", "move_slot_required": "Elige qué movimiento recuperará PP.", "unexpected_move_slot": "Este objeto no necesita seleccionar un movimiento."}[result.reason]
			refresh(); field.field_refresh_hud(); return result
		_result.text = {"field_locked": "Espera a terminar el combate o el desplazamiento.", "item_not_owned": "No queda ese objeto en la mochila.", "move_replacement_required": "Elige qué movimiento quieres sustituir.", "move_already_known": "Este Pokémon ya conoce ese movimiento.", "machine_incompatible": "Este Pokémon no puede aprender ese movimiento con esta MT.", "machine_not_in_active_version": "Esta máquina necesita una versión de reglas que todavía no está activa.", "species_machine_version_context_missing": "Faltan datos de compatibilidad para esta versión; no se ha usado el objeto.", "no_eligible_evolution": "Este objeto no provoca una evolución disponible para este Pokémon.", "nothing_equipped": "Este Pokémon no lleva objeto.", "already_equipped": "Este Pokémon ya lleva ese objeto.", "creature_knocked_out": "El Pokémon está debilitado.", "field_effect_not_connected": "La función de este objeto fuera del combate aún está pendiente."}.get(result.reason, "No se ha aplicado la acción. El inventario se conserva.")
	refresh()
	field.field_refresh_hud()
	return result
