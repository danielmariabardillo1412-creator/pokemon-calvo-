class_name CombatReviewPlaceholder
extends Control

# Human-facing review harness. This scene intentionally contains no story, map progression,
# art pipeline, savegame ownership, or alternate battle rules. It reads the canonical
# normalized PokeAPI dataset and drives the real TrainerBattleSession + trainer AI runtime.

const RUNTIME_DATA_PATH := "res://data/normalized/pokemon_api.json"
const MAX_TEAM_SIZE := 6
const DEFAULT_LEVEL := 20
const BATTLE_SEED := 44001

const DEFAULT_PLAYER_TEAM := [
	["bulbasaur", 20],
	["pikachu", 20],
	["geodude", 20],
]
const DEFAULT_TRAINER_TEAM := [
	["charmander", 20],
	["squirtle", 20],
	["pidgeotto", 20],
]

@onready var battle_presentation: TrainerBattlePresentationController = $TrainerBattlePresentation

var _catalogs: DefinitionCatalog = null
var _rules := ProgressionRuleset.new()
var _session: TrainerBattleSession = null

var _setup_panel: PanelContainer = null
var _data_status: Label = null
var _battle_status: Label = null
var _player_species_inputs: Array[LineEdit] = []
var _player_level_inputs: Array[SpinBox] = []
var _trainer_species_inputs: Array[LineEdit] = []
var _trainer_level_inputs: Array[SpinBox] = []
var _profile_selector: OptionButton = null
var _expertise_selector: OptionButton = null
var _start_button: Button = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_setup_ui()
	battle_presentation.battle_closed.connect(_on_battle_closed)
	_load_runtime_data()
	_load_default_teams()


func is_data_ready() -> bool:
	return _catalogs != null


func configured_player_ids() -> Array[StringName]:
	return _configured_ids(_player_species_inputs)


func configured_trainer_ids() -> Array[StringName]:
	return _configured_ids(_trainer_species_inputs)


func start_configured_battle() -> bool:
	_battle_status.text = ""
	if _catalogs == null:
		_set_error("No se puede combatir: el archivo de datos no está cargado.")
		return false

	var player_collection := PlayerCollection.new()
	var player_summary: Array[String] = []
	for index in range(MAX_TEAM_SIZE):
		var species_text := _player_species_inputs[index].text.strip_edges().to_lower()
		if species_text.is_empty():
			continue
		var creature := _build_creature(
			StringName(species_text),
			int(_player_level_inputs[index].value),
			"player",
			index,
		)
		if creature == null:
			return false
		if not player_collection.party.add_creature(creature):
			_set_error("No se ha podido añadir %s al equipo del jugador." % species_text)
			return false
		player_summary.append(_creature_summary(creature))

	var trainer_roster: Array[CreatureInstance] = []
	var trainer_summary: Array[String] = []
	for index in range(MAX_TEAM_SIZE):
		var species_text := _trainer_species_inputs[index].text.strip_edges().to_lower()
		if species_text.is_empty():
			continue
		var creature := _build_creature(
			StringName(species_text),
			int(_trainer_level_inputs[index].value),
			"trainer",
			index,
		)
		if creature == null:
			return false
		trainer_roster.append(creature)
		trainer_summary.append(_creature_summary(creature))

	if player_collection.party.is_empty():
		_set_error("El equipo del jugador está vacío.")
		return false
	if trainer_roster.is_empty():
		_set_error("El equipo del entrenador está vacío.")
		return false

	_session = TrainerBattleSession.new(player_collection, _catalogs, _rules)
	var profile_id := StringName(String(_profile_selector.get_item_metadata(_profile_selector.selected)))
	var expertise_id := StringName(String(_expertise_selector.get_item_metadata(_expertise_selector.selected)))
	if not _session.begin_battle(
		&"combat_review_placeholder_trainer",
		trainer_roster,
		BATTLE_SEED,
		profile_id,
		expertise_id,
	):
		_set_error("TrainerBattleSession rechazó el combate: %s" % _session.last_error)
		return false

	battle_presentation.configure(_session, _catalogs)
	_setup_panel.visible = false
	if not battle_presentation.open_for_active_battle():
		_setup_panel.visible = true
		_set_error("La sesión arrancó, pero la pantalla de combate no pudo abrirse.")
		return false

	print("COMBAT_PLACEHOLDER_BATTLE_START player=%s trainer=%s profile=%s expertise=%s" % [
		str(player_summary),
		str(trainer_summary),
		String(profile_id),
		String(expertise_id),
	])
	return true


func reload_runtime_data() -> bool:
	return _load_runtime_data()


func _build_setup_ui() -> void:
	_setup_panel = PanelContainer.new()
	_setup_panel.name = "SetupPanel"
	_setup_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_setup_panel)
	move_child(_setup_panel, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	_setup_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	var title := _label("POKÉMON CALVO — PLACEHOLDER DE COMBATE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	var explanation := _label(
		"Prueba aislada: usa el pokemon_api.json normalizado real, CreatureFactory, Battle Core y la IA real de entrenadores. "
		+ "Deja una casilla vacía para no usar ese hueco. IDs de ejemplo: bulbasaur, pikachu, charizard."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(explanation)

	var data_row := HBoxContainer.new()
	root.add_child(data_row)
	_data_status = _label("Datos: sin cargar")
	_data_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_row.add_child(_data_status)
	var reload_button := Button.new()
	reload_button.text = "Recargar/validar datos"
	reload_button.pressed.connect(reload_runtime_data)
	data_row.add_child(reload_button)

	var teams := HBoxContainer.new()
	teams.size_flags_vertical = Control.SIZE_EXPAND_FILL
	teams.add_theme_constant_override("separation", 14)
	root.add_child(teams)
	teams.add_child(_build_team_editor("TU EQUIPO", _player_species_inputs, _player_level_inputs))
	teams.add_child(_build_team_editor("EQUIPO DEL ENTRENADOR IA", _trainer_species_inputs, _trainer_level_inputs))

	var settings_row := HBoxContainer.new()
	root.add_child(settings_row)
	settings_row.add_child(_label("Estilo IA:"))
	_profile_selector = OptionButton.new()
	_add_selector_item(_profile_selector, "Equilibrado", TrainerProfile.BALANCED)
	_add_selector_item(_profile_selector, "Agresivo", TrainerProfile.AGGRESSIVE)
	_add_selector_item(_profile_selector, "Cauto", TrainerProfile.CAUTIOUS)
	_add_selector_item(_profile_selector, "Técnico", TrainerProfile.TECHNICAL)
	settings_row.add_child(_profile_selector)

	settings_row.add_child(_label("  Profundidad interna:"))
	_expertise_selector = OptionButton.new()
	_add_selector_item(_expertise_selector, "Completa", TrainerExpertise.FULL)
	_add_selector_item(_expertise_selector, "Limitada", TrainerExpertise.LIMITED)
	settings_row.add_child(_expertise_selector)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_row.add_child(spacer)

	var reset_button := Button.new()
	reset_button.text = "Restaurar ejemplo 3 vs 3"
	reset_button.pressed.connect(_load_default_teams)
	settings_row.add_child(reset_button)

	_start_button = Button.new()
	_start_button.text = "COMBATIR"
	_start_button.custom_minimum_size = Vector2(150, 36)
	_start_button.pressed.connect(start_configured_battle)
	settings_row.add_child(_start_button)

	_battle_status = _label("")
	_battle_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_battle_status)


func _build_team_editor(
	title_text: String,
	species_inputs: Array[LineEdit],
	level_inputs: Array[SpinBox],
) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := _label(title_text)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var header := HBoxContainer.new()
	header.add_child(_sized_label("Pokémon (ID)", 180))
	header.add_child(_sized_label("Nivel", 70))
	panel.add_child(header)

	for index in range(MAX_TEAM_SIZE):
		var row := HBoxContainer.new()
		var slot := _sized_label("%d." % (index + 1), 24)
		row.add_child(slot)
		var species := LineEdit.new()
		species.placeholder_text = "vacío"
		species.custom_minimum_size = Vector2(150, 0)
		species.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(species)
		species_inputs.append(species)
		var level := SpinBox.new()
		level.min_value = 1
		level.max_value = 100
		level.step = 1
		level.value = DEFAULT_LEVEL
		level.custom_minimum_size = Vector2(68, 0)
		row.add_child(level)
		level_inputs.append(level)
		panel.add_child(row)
	return panel


func _load_default_teams() -> void:
	_clear_team_inputs(_player_species_inputs, _player_level_inputs)
	_clear_team_inputs(_trainer_species_inputs, _trainer_level_inputs)
	_apply_defaults(_player_species_inputs, _player_level_inputs, DEFAULT_PLAYER_TEAM)
	_apply_defaults(_trainer_species_inputs, _trainer_level_inputs, DEFAULT_TRAINER_TEAM)
	if _battle_status != null:
		_battle_status.text = "Ejemplo preparado. Puedes cambiar cualquier ID o nivel antes de combatir."


func _clear_team_inputs(species_inputs: Array[LineEdit], level_inputs: Array[SpinBox]) -> void:
	for index in range(species_inputs.size()):
		species_inputs[index].text = ""
		level_inputs[index].value = DEFAULT_LEVEL


func _apply_defaults(species_inputs: Array[LineEdit], level_inputs: Array[SpinBox], defaults: Array) -> void:
	for index in range(mini(defaults.size(), species_inputs.size())):
		var row := defaults[index] as Array
		if row.size() < 2:
			continue
		species_inputs[index].text = String(row[0])
		level_inputs[index].value = int(row[1])


func _load_runtime_data() -> bool:
	_catalogs = null
	if _start_button != null:
		_start_button.disabled = true
	var file := FileAccess.open(RUNTIME_DATA_PATH, FileAccess.READ)
	if file == null:
		_set_data_error("No se puede abrir %s" % RUNTIME_DATA_PATH)
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_set_data_error("El JSON existe, pero no se puede interpretar como diccionario.")
		return false
	var game_data := GameData.from_dict(parsed as Dictionary)
	if game_data == null or game_data.manifest == null or not game_data.manifest.is_valid():
		_set_data_error("El JSON se leyó, pero GameData/manifest no es válido.")
		return false
	var type_validation := PokemonTypeChart.validate_catalog(game_data.type_catalog)
	if not bool(type_validation.get("valid", false)):
		_set_data_error("La tabla de tipos canónica está incompleta: %s" % str(type_validation))
		return false
	_catalogs = game_data.to_definition_catalog()
	if _catalogs == null or _catalogs.species_catalog.size() <= 0 or _catalogs.move_catalog.size() <= 0:
		_catalogs = null
		_set_data_error("Los catálogos de especies o movimientos quedaron vacíos.")
		return false
	_data_status.text = "DATOS OK — %d especies / %d movimientos — %s" % [
		_catalogs.species_catalog.size(),
		_catalogs.move_catalog.size(),
		RUNTIME_DATA_PATH,
	]
	if _start_button != null:
		_start_button.disabled = false
	print("COMBAT_PLACEHOLDER_READY species=%d moves=%d source=%s" % [
		_catalogs.species_catalog.size(),
		_catalogs.move_catalog.size(),
		RUNTIME_DATA_PATH,
	])
	return true


func _build_creature(species_id: StringName, level: int, side: String, slot_index: int) -> CreatureInstance:
	var species := _catalogs.species_catalog.get_by_id(species_id)
	if species == null:
		_set_error("No existe la especie '%s' en pokemon_api.json." % String(species_id))
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 880000 + slot_index + (100 if side == "trainer" else 0)
	var creature := CreatureFactory.create(
		species,
		level,
		_catalogs,
		_rules,
		rng,
		{"instance_id": StringName("placeholder_%s_%d_%s" % [side, slot_index + 1, String(species_id)])},
	)
	if creature == null:
		_set_error("CreatureFactory no pudo construir %s." % String(species_id))
		return null
	if creature.moveset.is_empty():
		_set_error(
			"%s Nv.%d se creó sin movimientos utilizables. Esto apunta a datos/learnset y no se oculta en el placeholder."
			% [String(species_id), level]
		)
		return null
	return creature


func _creature_summary(creature: CreatureInstance) -> String:
	var move_names: Array[String] = []
	for move_id in creature.move_ids:
		move_names.append(String(move_id))
	return "%s Nv.%d HP=%d/%d habilidad=%s movimientos=%s" % [
		String(creature.species_id),
		creature.level,
		creature.current_hp,
		creature.stats.max_hp,
		String(creature.ability_id),
		",".join(move_names),
	]


func _configured_ids(inputs: Array[LineEdit]) -> Array[StringName]:
	var result: Array[StringName] = []
	for input in inputs:
		var text := input.text.strip_edges().to_lower()
		if not text.is_empty():
			result.append(StringName(text))
	return result


func _on_battle_closed(reason: StringName) -> void:
	_setup_panel.visible = true
	_battle_status.text = "Combate terminado (%s). Cambia equipos/niveles y pulsa COMBATIR para repetir." % String(reason)


func _set_data_error(message: String) -> void:
	if _data_status != null:
		_data_status.text = "ERROR DE DATOS — %s" % message
	if _battle_status != null:
		_battle_status.text = message
	push_error("COMBAT_PLACEHOLDER_DATA_ERROR: %s" % message)


func _set_error(message: String) -> void:
	if _battle_status != null:
		_battle_status.text = "ERROR — %s" % message
	push_error("COMBAT_PLACEHOLDER_ERROR: %s" % message)


func _add_selector_item(selector: OptionButton, label_text: String, value: StringName) -> void:
	selector.add_item(label_text)
	selector.set_item_metadata(selector.item_count - 1, String(value))


func _label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	return label


func _sized_label(text_value: String, width: float) -> Label:
	var label := _label(text_value)
	label.custom_minimum_size = Vector2(width, 0)
	return label
