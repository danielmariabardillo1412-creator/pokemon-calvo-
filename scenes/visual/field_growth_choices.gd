extends VBoxContainer

signal chosen(value: Variant)
signal cancelled

var _label: Label
var _options: OptionButton
var _confirm: Button

func _ready() -> void:
	_label = Label.new(); _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(_label)
	_options = OptionButton.new(); add_child(_options)
	var buttons := HBoxContainer.new(); add_child(buttons)
	_confirm = Button.new(); _confirm.text = "Continuar"; buttons.add_child(_confirm)
	_confirm.pressed.connect(func():
		if _options.selected > 0: chosen.emit(_options.get_item_metadata(_options.selected)))
	var cancel := Button.new(); cancel.text = "Cancelar uso · conservar objeto"; buttons.add_child(cancel)
	cancel.pressed.connect(func(): cancelled.emit())
	_options.item_selected.connect(func(index): _confirm.disabled = index <= 0)
	hide()

func present(prompt: Dictionary, catalogs: DefinitionCatalog) -> void:
	_options.clear(); _options.add_item("Elige una opción"); _confirm.disabled = true
	if prompt.kind == "move":
		_label.text = "Nv. %d · Quiere aprender %s. ¿Qué decides?" % [prompt.level, SpanishGameText.move_name(StringName(prompt.move_id), catalogs)]
		_options.add_item("No aprender este movimiento"); _options.set_item_metadata(1, -1)
		for index in prompt.slots.size():
			_options.add_item("Sustituir: " + SpanishGameText.move_name(StringName(prompt.slots[index].move_id), catalogs))
			_options.set_item_metadata(_options.item_count - 1, index)
	else:
		_label.text = "Nv. %d · Puede evolucionar. ¿Qué decides?" % prompt.level
		_options.add_item("No evolucionar"); _options.set_item_metadata(1, "")
		for target: String in prompt.targets:
			_options.add_item("Evolucionar a " + SpanishGameText.species_name(StringName(target), catalogs))
			_options.set_item_metadata(_options.item_count - 1, target)
	show()
