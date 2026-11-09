extends PanelContainer

# Panel opcional de libros. No modifica FieldItemBag.
# Usa el FieldItemService de la mochila, no otro motor de MT.
signal teaching_finished(result: Dictionary)
const Books = preload("res://modules/inventory/field_machine_book_profile.gd")
const PILOT_NAMES := {"pain_split": "Divide Dolor", "metal_claw": "Garra Metal"}

var service: Variant = null
var books: OptionButton
var targets: OptionButton
var slots: OptionButton
var book_label: Label
var type_label: Label
var compatibility_label: Label
var result_label: Label
var teach_button: Button
var last_result: Dictionary = {}


func _ready() -> void:
	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(440, 270)
	layout.add_theme_constant_override("separation", 8)
	add_child(layout)
	var title := Label.new()
	title.text = "LIBROS DE MOVIMIENTOS · MT"
	layout.add_child(title)
	books = OptionButton.new()
	layout.add_child(books)
	book_label = Label.new()
	layout.add_child(book_label)
	type_label = Label.new()
	layout.add_child(type_label)
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
	books.item_selected.connect(func(_i: int): _refresh_preview())
	targets.item_selected.connect(func(_i: int): _refresh_preview())
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
	_refresh_preview()
	return true


func select_creature(id: StringName) -> bool:
	if not _choose(targets, id):
		return false
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
	books.clear()
	targets.clear()
	if service != null and service.owner != null and service.catalogs != null:
		var mapping: Dictionary = service.profile.get("machine_rows", {})
		for id: StringName in service.owner.inventory.all_item_ids():
			if not mapping.has(String(id)):
				continue
			var presentation: Dictionary = Books.presentacion(id, service.profile, service.catalogs)
			if not presentation.get("disponible", false):
				continue
			var spanish := String(PILOT_NAMES.get(String(presentation.get("move_id", "")),
				presentation.get("nombre_movimiento", "")))
			books.add_item("Libro MT · " + spanish + " · x%d" % service.owner.inventory.quantity(id))
			books.set_item_metadata(books.item_count - 1, String(id))
		for creature: CreatureInstance in service.owner.party.get_creatures():
			targets.add_item("%s · Nv. %d" % [
				SpanishGameText.species_name(creature.species_id, service.catalogs), creature.level])
			targets.set_item_metadata(targets.item_count - 1, String(creature.instance_id))
	if not _choose(books, chosen_book) and books.item_count > 0:
		books.select(0)
	if not _choose(targets, chosen_target) and targets.item_count > 0:
		targets.select(0)
	_refresh_preview()


func _refresh_preview() -> void:
	if slots == null:
		return
	slots.clear()
	slots.add_item("Aprender sin sustituir")
	slots.set_item_metadata(0, -1)
	if service != null and service.owner != null:
		var creature: CreatureInstance = service.owner.owned_creature(_selected(targets))
		if creature != null:
			for i in range(creature.moveset.size()):
				var slot: BattleMoveSlot = creature.moveset[i]
				slots.add_item("Sustituir: " + SpanishGameText.move_name(slot.move_id, service.catalogs))
				slots.set_item_metadata(slots.item_count - 1, i)
	_refresh_compatibility()


func _slot() -> int:
	if slots == null or slots.selected < 0:
		return -1
	return int(slots.get_item_metadata(slots.selected))


func _refresh_compatibility() -> void:
	if book_label == null:
		return
	book_label.text = "Selecciona un libro."
	type_label.text = ""
	compatibility_label.text = "Selecciona un Pokémon."
	var item_id := _selected(books)
	var creature_id := _selected(targets)
	teach_button.disabled = item_id == &"" or creature_id == &""
	if teach_button.disabled or service == null:
		return
	var presented: Dictionary = Books.presentacion(item_id, service.profile, service.catalogs)
	if not presented.get("disponible", false):
		compatibility_label.text = "Libro no disponible."
		teach_button.disabled = true
		return
	var move_id := StringName(presented.get("move_id", ""))
	var name_es := String(PILOT_NAMES.get(String(move_id), presented.get("nombre_movimiento", "")))
	book_label.text = "Libro de movimiento · " + name_es
	type_label.text = "Tipo: " + String(presented.get("nombre_tipo", ""))
	var creature: CreatureInstance = service.owner.owned_creature(creature_id)
	var species: CreatureSpecies = service.catalogs.species(creature.species_id) if creature != null else null
	if species == null:
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
		compatibility_label.text = "Faltan datos de compatibilidad para esta versión."
	elif not compatible:
		compatibility_label.text = "Incompatible · no puede aprender el movimiento."
	elif creature.has_move(move_id):
		compatibility_label.text = "Ya conoce ese movimiento."
	elif creature.moveset.size() >= ProgressionRuleset.MOVE_SLOTS_MAX and _slot() < 0:
		compatibility_label.text = "Compatible · elige qué movimiento sustituir."
	else:
		compatibility_label.text = "Compatible · el servicio comprobará el uso antes del consumo."


func teach_selected() -> Dictionary:
	if service == null:
		last_result = {"accepted": false, "reason": "service_not_bound"}
	else:
		var id := _selected(books)
		var target := _selected(targets)
		if id == &"" or target == &"":
			last_result = {"accepted": false, "reason": "selection_missing"}
		else:
			last_result = service.teach(id, target, _slot())
	var answer := last_result.duplicate(true)
	refresh()
	if last_result.get("accepted", false):
		var move_id := StringName(last_result.get("move_id", ""))
		var spanish := String(PILOT_NAMES.get(String(move_id), SpanishGameText.move_name(move_id, service.catalogs)))
		result_label.text = "¡Ha aprendido %s! Se consumió un libro." % spanish
	else:
		var reason := String(last_result.get("reason", ""))
		result_label.text = {
			"machine_incompatible": "Incompatible. Libro conservado.",
			"item_not_owned": "Sin existencias. No se consume nada.",
			"move_replacement_required": "Elige el movimiento que quieres sustituir. Libro conservado.",
			"move_already_known": "Ya conoce el movimiento. Libro conservado.",
			"creature_not_owned": "Pokémon ajeno. Libro conservado.",
			"field_locked": "No puedes enseñar ahora. Libro conservado.",
			"selection_missing": "Selecciona libro y Pokémon.",
			"service_not_bound": "Falta vincular la mochila."
		}.get(reason, "No se ha enseñado. Libro conservado.")
	teaching_finished.emit(answer)
	return answer
