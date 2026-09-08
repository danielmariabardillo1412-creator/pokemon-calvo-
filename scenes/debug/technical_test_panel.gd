class_name TechnicalTestPanel
extends Control

signal configuration_applied(config: Dictionary)
signal automatic_audit_requested
signal export_report_requested
signal open_report_folder_requested
signal panel_visibility_changed(open: bool)

const MAX_TEAM_SIZE := 6
const DEFAULT_LEVEL := 20

var _config_panel: PanelContainer = null
var _runtime_status: Label = null
var _report_status: Label = null
var _player_species_inputs: Array[LineEdit] = []
var _player_level_inputs: Array[SpinBox] = []
var _trainer_species_inputs: Array[LineEdit] = []
var _trainer_level_inputs: Array[SpinBox] = []
var _wild_species_input: LineEdit = null
var _wild_min_level: SpinBox = null
var _wild_max_level: SpinBox = null
var _encounter_chance: SpinBox = null
var _profile_selector: OptionButton = null
var _expertise_selector: OptionButton = null
var _audit_running := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_toolbar()
	_build_config_panel()
	_load_defaults()
	automatic_audit_requested.connect(_on_automatic_audit_requested)


func current_configuration() -> Dictionary:
	return {
		"player_team": _team_configuration(_player_species_inputs, _player_level_inputs),
		"trainer_team": _team_configuration(_trainer_species_inputs, _trainer_level_inputs),
		"wild_species_id": _wild_species_input.text.strip_edges().to_lower(),
		"wild_min_level": int(_wild_min_level.value),
		"wild_max_level": int(_wild_max_level.value),
		"encounter_chance_percent": int(_encounter_chance.value),
		"trainer_profile_id": String(_profile_selector.get_item_metadata(_profile_selector.selected)),
		"trainer_expertise_id": String(_expertise_selector.get_item_metadata(_expertise_selector.selected)),
	}


func set_runtime_status(text_value: String) -> void:
	if _runtime_status != null:
		_runtime_status.text = text_value


func set_report_status(text_value: String) -> void:
	if _report_status != null:
		_report_status.text = text_value


func is_panel_open() -> bool:
	return _config_panel != null and _config_panel.visible


func _on_automatic_audit_requested() -> void:
	if _audit_running:
		return
	_audit_running = true
	set_runtime_status("AUTOPRUEBA — revisando motor real...")
	set_report_status("Autoprueba en curso: datos + mundo + encuentros + captura + IA")
	# Give physics one frame so CharacterBody2D.test_move sees the live physics world.
	await get_tree().physics_frame
	var world := get_tree().current_scene as Node2D
	var result := TechnicalRuntimeAuditService.run_and_export(world, current_configuration())
	if not bool(result.get("ok", false)):
		var error := String(result.get("error", "unknown_audit_error"))
		set_runtime_status("AUTOPRUEBA ERROR")
		set_report_status("ERROR de autoprueba: %s" % error)
		print("TECHNICAL_AUDIT_COMPLETE status=FAIL ok=0 warn=0 fail=1 error=%s" % error)
		_audit_running = false
		return
	var audit := result.get("audit", {}) as Dictionary
	var counts := audit.get("counts", {}) as Dictionary
	var status := String(audit.get("overall_status", "FAIL"))
	var ok_count := int(counts.get("OK", 0))
	var warn_count := int(counts.get("WARN", 0))
	var fail_count := int(counts.get("FAIL", 0))
	var path := String(result.get("path", ""))
	set_runtime_status("AUTOPRUEBA %s | OK %d | WARN %d | FAIL %d" % [status, ok_count, warn_count, fail_count])
	set_report_status("Informe automático: %s" % path)
	print("TECHNICAL_AUDIT_COMPLETE status=%s ok=%d warn=%d fail=%d report=%s" % [
		status, ok_count, warn_count, fail_count, path,
	])
	_audit_running = false


func _build_toolbar() -> void:
	var toolbar := PanelContainer.new()
	toolbar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toolbar.offset_left = 8
	toolbar.offset_right = -8
	toolbar.offset_top = -66
	toolbar.offset_bottom = -8
	toolbar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(toolbar)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 2)
	toolbar.add_child(rows)

	var buttons := HBoxContainer.new()
	rows.add_child(buttons)

	var config_button := Button.new()
	config_button.text = "CONFIGURAR PRUEBAS"
	config_button.pressed.connect(_open_config)
	buttons.add_child(config_button)

	var audit_button := Button.new()
	audit_button.text = "AUTOPRUEBA COMPLETA"
	audit_button.tooltip_text = "Revisa datos, hierba/encuentros, captura, colisiones y niveles de IA; luego exporta un informe."
	audit_button.pressed.connect(func(): automatic_audit_requested.emit())
	buttons.add_child(audit_button)

	var export_button := Button.new()
	export_button.text = "EXPORTAR INFORME"
	export_button.pressed.connect(func(): export_report_requested.emit())
	buttons.add_child(export_button)

	var folder_button := Button.new()
	folder_button.text = "ABRIR CARPETA DE INFORMES"
	folder_button.pressed.connect(func(): open_report_folder_requested.emit())
	buttons.add_child(folder_button)

	_runtime_status = Label.new()
	_runtime_status.text = "Preparando build técnica..."
	_runtime_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_runtime_status)

	_report_status = Label.new()
	_report_status.text = "Caja negra: iniciando..."
	_report_status.clip_text = true
	rows.add_child(_report_status)


func _build_config_panel() -> void:
	_config_panel = PanelContainer.new()
	_config_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_config_panel.visible = false
	_config_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_config_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	_config_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)
	margin.add_child(root)

	var title := Label.new()
	title.text = "LABORATORIO TÉCNICO — sin arte, usando el motor real"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	root.add_child(title)

	var hint := Label.new()
	hint.text = "Configura equipos y el encuentro salvaje. Después puedes jugar manualmente o lanzar AUTOPRUEBA COMPLETA."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)

	var teams := HBoxContainer.new()
	teams.size_flags_vertical = Control.SIZE_EXPAND_FILL
	teams.add_theme_constant_override("separation", 12)
	root.add_child(teams)
	teams.add_child(_build_team_editor("TU EQUIPO", _player_species_inputs, _player_level_inputs))
	teams.add_child(_build_team_editor("ENTRENADOR IA", _trainer_species_inputs, _trainer_level_inputs))

	var wild_row := HBoxContainer.new()
	root.add_child(wild_row)
	wild_row.add_child(_label("Salvaje:"))
	_wild_species_input = LineEdit.new()
	_wild_species_input.custom_minimum_size = Vector2(120, 0)
	wild_row.add_child(_wild_species_input)
	wild_row.add_child(_label("Nv. mín:"))
	_wild_min_level = _level_spinbox(4)
	wild_row.add_child(_wild_min_level)
	wild_row.add_child(_label("máx:"))
	_wild_max_level = _level_spinbox(4)
	wild_row.add_child(_wild_max_level)
	wild_row.add_child(_label("Probabilidad %:"))
	_encounter_chance = SpinBox.new()
	_encounter_chance.min_value = 0
	_encounter_chance.max_value = 100
	_encounter_chance.step = 1
	_encounter_chance.value = 100
	_encounter_chance.custom_minimum_size = Vector2(72, 0)
	wild_row.add_child(_encounter_chance)

	var ai_row := HBoxContainer.new()
	root.add_child(ai_row)
	ai_row.add_child(_label("Estilo IA:"))
	_profile_selector = OptionButton.new()
	_add_selector_item(_profile_selector, "Equilibrado", "balanced")
	_add_selector_item(_profile_selector, "Agresivo", "aggressive")
	_add_selector_item(_profile_selector, "Cauto", "cautious")
	_add_selector_item(_profile_selector, "Técnico", "technical")
	ai_row.add_child(_profile_selector)
	ai_row.add_child(_label("Nivel IA:"))
	_expertise_selector = OptionButton.new()
	_add_selector_item(_expertise_selector, "Novato", "limited")
	_add_selector_item(_expertise_selector, "Normal", "standard")
	_add_selector_item(_expertise_selector, "Experto", "full")
	ai_row.add_child(_expertise_selector)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_row.add_child(spacer)

	var defaults_button := Button.new()
	defaults_button.text = "RESTAURAR EJEMPLO"
	defaults_button.pressed.connect(_load_defaults)
	ai_row.add_child(defaults_button)

	var close_button := Button.new()
	close_button.text = "CERRAR"
	close_button.pressed.connect(_close_config)
	ai_row.add_child(close_button)

	var apply_button := Button.new()
	apply_button.text = "APLICAR Y REINICIAR PRUEBA"
	apply_button.pressed.connect(_apply_config)
	ai_row.add_child(apply_button)


func _build_team_editor(
	title_text: String,
	species_inputs: Array[LineEdit],
	level_inputs: Array[SpinBox],
) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for index in range(MAX_TEAM_SIZE):
		var row := HBoxContainer.new()
		var slot_label := Label.new()
		slot_label.text = "%d." % (index + 1)
		slot_label.custom_minimum_size = Vector2(24, 0)
		row.add_child(slot_label)
		var species := LineEdit.new()
		species.placeholder_text = "vacío"
		species.custom_minimum_size = Vector2(120, 0)
		species.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(species)
		species_inputs.append(species)
		var level := _level_spinbox(DEFAULT_LEVEL)
		row.add_child(level)
		level_inputs.append(level)
		column.add_child(row)
	return column


func _team_configuration(species_inputs: Array[LineEdit], level_inputs: Array[SpinBox]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(species_inputs.size()):
		var species_id := species_inputs[index].text.strip_edges().to_lower()
		if species_id.is_empty():
			continue
		result.append({"species_id": species_id, "level": int(level_inputs[index].value)})
	return result


func _load_defaults() -> void:
	_clear_team(_player_species_inputs, _player_level_inputs)
	_clear_team(_trainer_species_inputs, _trainer_level_inputs)
	# Keep the historical technical-scene defaults so existing integration tests remain meaningful.
	# The panel still allows any 1–6 vs 1–6 roster after opening CONFIGURAR PRUEBAS.
	_apply_team_defaults(_player_species_inputs, _player_level_inputs, [
		["bulbasaur", 5], ["charmander", 5],
	])
	_apply_team_defaults(_trainer_species_inputs, _trainer_level_inputs, [
		["squirtle", 4],
	])
	if _wild_species_input != null:
		_wild_species_input.text = "pikachu"
		_wild_min_level.value = 4
		_wild_max_level.value = 4
		_encounter_chance.value = 100
	if _profile_selector != null:
		_profile_selector.select(0)
	if _expertise_selector != null:
		# Expert preserves the historical full-search behavior of this technical scene.
		_expertise_selector.select(2)


func _clear_team(species_inputs: Array[LineEdit], level_inputs: Array[SpinBox]) -> void:
	for index in range(species_inputs.size()):
		species_inputs[index].text = ""
		level_inputs[index].value = DEFAULT_LEVEL


func _apply_team_defaults(species_inputs: Array[LineEdit], level_inputs: Array[SpinBox], defaults: Array) -> void:
	for index in range(mini(defaults.size(), species_inputs.size())):
		var row := defaults[index] as Array
		species_inputs[index].text = String(row[0])
		level_inputs[index].value = int(row[1])


func _open_config() -> void:
	_config_panel.visible = true
	panel_visibility_changed.emit(true)


func _close_config() -> void:
	_config_panel.visible = false
	panel_visibility_changed.emit(false)


func _apply_config() -> void:
	configuration_applied.emit(current_configuration())
	_close_config()


func _level_spinbox(initial_value: int) -> SpinBox:
	var box := SpinBox.new()
	box.min_value = 1
	box.max_value = 100
	box.step = 1
	box.value = initial_value
	box.custom_minimum_size = Vector2(62, 0)
	return box


func _add_selector_item(selector: OptionButton, label_text: String, value: String) -> void:
	selector.add_item(label_text)
	selector.set_item_metadata(selector.item_count - 1, value)


func _label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	return label
