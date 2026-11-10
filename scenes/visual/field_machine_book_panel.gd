extends PanelContainer

# Panel opcional de libros. No modifica FieldItemBag.
# Usa el FieldItemService de la mochila, no otro motor de MT.
signal teaching_finished(result: Dictionary)
const Books = preload("res://modules/inventory/field_machine_book_profile.gd")

var service: Variant = null
var books: OptionButton
var targets: OptionButton
var sort_mode: OptionButton
var type_filter: OptionButton
var translation_label: Label
var slots: OptionButton
var book_label: Label
var type_label: Label
var compatibility_label: Label
var result_label: Label
var teach_button: Button
var last_result: Dictionary = {}
var _blocked_reason := "service_not_bound"
# A disappeared selection must NOT become the first other item after the next refresh.
var _book_selection_stale := false
var _target_selection_stale := false


func _ready() -> void:
	# A re-entered panel must never duplicate controls or event connections.
	if books != null:
		refresh()
		return
	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(440, 270)
	layout.add_theme_constant_override("separation", 8)
	add_child(layout)
	var title := Label.new()
	title.text = "LIBROS DE MOVIMIENTOS · MT"
	layout.add_child(title)
	sort_mode = OptionButton.new()
	for mode in ["ID original", "Nombre", "Tipo", "Cantidad"]:
		sort_mode.add_item("Orden: " + mode)
	sort_mode.select(0)
	layout.add_child(sort_mode)
	type_filter = OptionButton.new()
	type_filter.add_item("Todos los tipos")
	type_filter.set_item_metadata(0, "")
	type_filter.select(0)
	layout.add_child(type_filter)
	books = OptionButton.new()
	layout.add_child(books)
	book_label = Label.new()
	layout.add_child(book_label)
	type_label = Label.new()
	layout.add_child(type_label)
	translation_label = Label.new()
	translation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(translation_label)
	targets = OptionButton.new()
	layout.add_child(targets)
	compatibility_label = Label.new()
	compatibility_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(compatibility_label)
	slots = OptionButton.new()
	layout.add_child(slots)
	teach_button = Button.new()
	teach_button.text = "Enseñar movimiento"
	layout.add_child(teach_button)
	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(result_label)
	sort_mode.item_selected.connect(func(_i: int): refresh())
	type_filter.item_selected.connect(func(_i: int): refresh())
	books.item_selected.connect(func(_i: int):
		_book_selection_stale = false
		_refresh_preview())
	targets.item_selected.connect(func(_i: int):
		_target_selection_stale = false
		_refresh_preview())
	slots.item_selected.connect(func(_i: int): _refresh_compatibility())
	teach_button.pressed.connect(func(): teach_selected())
	refresh()


# Contrato para IA6, sin editar la mochila:
# panel.bind_existing_service(field_item_bag.service)
# panel.select_book(item_id)
func bind_existing_service(bound_service: Variant) -> bool:
	if bound_service == null or bound_service.owner == null or bound_service.catalogs == null:
		return false
	if bound_service.owner.inventory == null:
		return false
	service = bound_service
	refresh()
	return true


func _selected(button: OptionButton) -> StringName:
	if button == null or button.selected < 0 or button.selected >= button.item_count:
		return &""
	return StringName(button.get_item_metadata(button.selected))


func _choose(button: OptionButton, id: StringName) -> bool:
	if button == null:
		return false
	for i in range(button.item_count):
		if StringName(button.get_item_metadata(i)) == id:
			button.select(i)
			return true
	return false


func select_book(id: StringName) -> bool:
	if not _choose(books, id):
		return false
	_book_selection_stale = false
	_refresh_preview()
	return true


func select_creature(id: StringName) -> bool:
	if not _choose(targets, id):
		return false
	_target_selection_stale = false
	_refresh_preview()
	return true


func select_replacement_slot(slot: int) -> bool:
	for i in range(slots.item_count):
		if int(slots.get_item_metadata(i)) == slot:
			slots.select(i)
			_refresh_compatibility()
			return true
	return false


func refresh() -> void:
	if books == null:
		return
	var chosen_book := _selected(books)
	var chosen_target := _selected(targets)
	var chosen_type := _selected(type_filter)
	books.clear()
	targets.clear()
	var entries: Array[Dictionary] = []
	var types: Dictionary = {}
	if service != null and service.owner != null and service.catalogs != null:
		var mapping: Dictionary = service.profile.get("machine_rows", {})
		for id: StringName in service.owner.inventory.all_item_ids():
			if not mapping.has(String(id)):
				continue
			var presentation: Dictionary = Books.presentacion(id, service.profile, service.catalogs)
			if not presentation.get("disponible", false):
				continue
			var move_id := String(presentation.get("move_id", ""))
			var name := String(presentation.get("nombre_movimiento", ""))
			var type_id := String(presentation.get("type_id", ""))
			var type_es := String(presentation.get("nombre_tipo", ""))
			entries.append({"id": String(id), "name": name, "type_id": type_id,
				"type_es": type_es, "quantity": service.owner.inventory.quantity(id)})
			types[type_id] = type_es
		for creature: CreatureInstance in service.owner.party.get_creatures():
			targets.add_item("%s · Nv. %d" % [
				SpanishGameText.species_name(creature.species_id, service.catalogs), creature.level])
			targets.set_item_metadata(targets.item_count - 1, String(creature.instance_id))
	# The filter contains only type IDs obtained from canonical presentations.
	type_filter.clear()
	type_filter.add_item("Todos los tipos")
	type_filter.set_item_metadata(0, "")
	var type_ids: Array = types.keys()
	type_ids.sort_custom(func(a, b): return String(a) < String(b))
	for type_id in type_ids:
		type_filter.add_item(String(types[type_id]))
		type_filter.set_item_metadata(type_filter.item_count - 1, String(type_id))
	if not _choose(type_filter, chosen_type):
		type_filter.select(0)
	var active_type := _selected(type_filter)
	var mode := sort_mode.selected if sort_mode != null else 0
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := ""
		var b_key := ""
		match mode:
			1:
				a_key = String(a.name).to_lower()
				b_key = String(b.name).to_lower()
			2:
				a_key = String(a.type_es).to_lower()
				b_key = String(b.type_es).to_lower()
			3:
				# Stable descending stock, with ID for deterministic ties.
				if int(a.quantity) != int(b.quantity):
					return int(a.quantity) > int(b.quantity)
			_:
				pass
		if a_key != b_key:
			return a_key < b_key
		return String(a.id) < String(b.id))
	for entry: Dictionary in entries:
		if active_type != &"" and String(entry.type_id) != String(active_type):
			continue
		books.add_item("Libro MT · " + String(entry.name) + " · x%d" % int(entry.quantity))
		books.set_item_metadata(books.item_count - 1, String(entry.id))
	# Preserve stable IDs. If a previously selected book or Pokémon disappears,
	# leave the selection EMPTY: never silently teach a different one.
	if not _choose(books, chosen_book):
		if chosen_book != &"":
			_book_selection_stale = true
		if chosen_book == &"" and not _book_selection_stale and books.item_count > 0:
			books.select(0)
		else:
			books.select(-1)
	else:
		_book_selection_stale = false
	if not _choose(targets, chosen_target):
		if chosen_target != &"":
			_target_selection_stale = true
		if chosen_target == &"" and not _target_selection_stale and targets.item_count > 0:
			targets.select(0)
		else:
			targets.select(-1)
	else:
		_target_selection_stale = false
	_refresh_preview()

func _refresh_preview() -> void:
	if slots == null:
		return
	slots.clear()
	slots.add_item("Aprender sin sustituir")
	slots.set_item_metadata(0, -1)
	if service != null and service.owner != null:
		var creature: CreatureInstance = service.owner.party.get_creature(_selected(targets))
		if creature != null:
			for i in range(creature.moveset.size()):
				var slot: BattleMoveSlot = creature.moveset[i]
				var old_text: Dictionary = MachineMovesEsSvW05.resolve(slot.move_id,
					SpanishGameText.move_name(slot.move_id, service.catalogs))
				slots.add_item("Sustituir: " + String(old_text.get("name", "")))
				slots.set_item_metadata(slots.item_count - 1, i)
	_refresh_compatibility()


func _slot() -> int:
	if slots == null or slots.selected < 0:
		return -1
	return int(slots.get_item_metadata(slots.selected))


func _refresh_compatibility() -> void:
	if book_label == null:
		return
	# La vista nunca autoriza el consumo. FieldItemService.teach sigue siendo
	# el unico punto de mutacion: la vista solo previene intentos imposibles.
	teach_button.disabled = true
	_blocked_reason = "selection_missing"
	book_label.text = "Selecciona un libro."
	type_label.text = ""
	translation_label.text = ""
	compatibility_label.text = "Selecciona un Pokémon."
	if service == null or service.owner == null or service.catalogs == null:
		_blocked_reason = "service_not_bound"
		compatibility_label.text = "La mochila no está vinculada."
		return
	var item_id := _selected(books)
	var creature_id := _selected(targets)
	if item_id == &"":
		compatibility_label.text = "No quedan libros seleccionados en la mochila."
		return
	if creature_id == &"":
		compatibility_label.text = "Selecciona un Pokémon del equipo."
		return
	var presented: Dictionary = Books.presentacion(item_id, service.profile, service.catalogs)
	if not presented.get("disponible", false):
		_blocked_reason = String(presented.get("motivo", "machine_not_in_active_version"))
		compatibility_label.text = "Este libro no está disponible con las reglas actuales."
		return
	var move_id := StringName(presented.get("move_id", ""))
	var name_es := String(presented.get("nombre_movimiento", ""))
	book_label.text = "Libro de movimiento · " + name_es
	type_label.text = "Tipo: " + String(presented.get("nombre_tipo", ""))
	# Only explicitly localized names can be presented as verified Spanish.
	# The catalog display_name can be English; we must not fabricate translations.
	if not bool(presented.get("traduccion_es_verificada", false)):
		translation_label.text = "Nombre disponible; traducción española no verificada."
	# Reutilizar la puerta EXISTENTE del servicio, incluida la sesion
	# bloqueada; el panel no decide si un objeto se gasta.
	var boundary := String(service._boundary(item_id))
	if boundary != "":
		_blocked_reason = boundary
		compatibility_label.text = "No puedes enseñar ahora. El libro se conserva." if boundary == "field_locked" else "El uso de este libro está bloqueado."
		return
	if not service.owner.inventory.has(item_id):
		_blocked_reason = "item_not_owned"
		compatibility_label.text = "Sin existencias. El libro no se consumirá."
		return
	var location: StringName = service.owner.location_of(creature_id)
	if location != &"PARTY":
		_blocked_reason = "creature_not_owned" if location == &"" else "creature_not_in_party"
		compatibility_label.text = "Pokémon no disponible en el equipo. Libro conservado."
		return
	var creature: CreatureInstance = service.owner.owned_creature(creature_id)
	var species: CreatureSpecies = service.catalogs.species(creature.species_id) if creature != null else null
	if species == null:
		_blocked_reason = "unknown_species"
		compatibility_label.text = "Especie no disponible."
		return
	var any_version := false
	var compatible := false
	for entry: LearnSetEntry in species.learnset:
		if entry.method != "machine" or String(entry.version_group) != "scarlet-violet":
			continue
		any_version = true
		if entry.move_id == move_id:
			compatible = true
	if not any_version:
		_blocked_reason = "species_machine_version_context_missing"
		compatibility_label.text = "Faltan datos de compatibilidad para esta versión."
	elif not compatible:
		_blocked_reason = "machine_incompatible"
		compatibility_label.text = "Incompatible · no puede aprender el movimiento."
	elif creature.has_move(move_id):
		_blocked_reason = "move_already_known"
		compatibility_label.text = "Ya conoce ese movimiento."
	elif not service.content.move_learnable(String(move_id)):
		_blocked_reason = "move_not_permitted"
		compatibility_label.text = "Este movimiento no está permitido en la partida."
	elif creature.moveset.size() >= ProgressionRuleset.MOVE_SLOTS_MAX and _slot() < 0:
		_blocked_reason = "move_replacement_required"
		compatibility_label.text = "Compatible · elige qué movimiento sustituir."
	else:
		_blocked_reason = ""
		teach_button.disabled = false
		compatibility_label.text = "Compatible · el servicio comprobará el uso antes del consumo."


func teach_selected() -> Dictionary:
	# Un evento atrasado o una invocacion directa NO elude un boton bloqueado.
	# Revalidar el estado vivo justo antes del unico teach().
	_refresh_compatibility()
	if teach_button == null or teach_button.disabled:
		last_result = {"accepted": false, "reason": _blocked_reason, "status": "REJECTED"}
	else:
		var id := _selected(books)
		var target := _selected(targets)
		last_result = service.teach(id, target, _slot())
	var answer := last_result.duplicate(true)
	refresh()
	if last_result.get("accepted", false):
		var move_id := StringName(last_result.get("move_id", ""))
		var localized := MachineMovesEsSvW05.resolve(move_id,
			SpanishGameText.move_name(move_id, service.catalogs))
		var spanish := String(localized.get("name", ""))
		result_label.text = "¡Ha aprendido %s! Se consumió un libro." % spanish
	else:
		var reason := String(last_result.get("reason", ""))
		result_label.text = {
			"machine_incompatible": "Incompatible. Libro conservado.",
			"item_not_owned": "Sin existencias. No se consume nada.",
			"move_replacement_required": "Elige el movimiento que quieres sustituir. Libro conservado.",
			"move_already_known": "Ya conoce el movimiento. Libro conservado.",
			"creature_not_owned": "Pokémon ajeno. Libro conservado.",
			"creature_not_in_party": "El Pokémon ya no está en el equipo. Libro conservado.",
			"field_locked": "No puedes enseñar ahora. Libro conservado.",
			"service_not_bound": "Falta vincular la mochila.",
			"species_machine_version_context_missing": "Faltan datos de compatibilidad. Libro conservado.",
			"move_not_permitted": "Movimiento no permitido. Libro conservado.",
			"selection_missing": "Selecciona libro y Pokémon."
		}.get(reason, "No se ha enseñado. Libro conservado.")
	teaching_finished.emit(answer)
	return answer
