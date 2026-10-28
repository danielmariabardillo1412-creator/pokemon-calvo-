extends Control

const Preview = preload("res://scenes/visual/community_move_preview.gd")
const ExternalContext = preload("res://scenes/visual/move_external_context.gd")
const ContentPolicy = preload("res://modules/gameplay/randomlock_content_policy.gd")
var _content_policy := ContentPolicy.new()
var _game_pool_switch: CheckButton
var stage: Control
var _choices: OptionButton
var _slider: HSlider
var _status: Label
var _play: Button
var _elapsed := 0.0
var _playing := true
var _updating := false
const BATCH_INDEX := "res://.godot/move_batch_catalog/index.json"
var _entries: Array[Dictionary] = []
var _filtered: Array[int] = []
var _search: LineEdit
var _batch := false
var _loaded_path := ""
var _external: RefCounted
var _context_switch: CheckButton
var _presentation_frame := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var heading := Label.new()
	heading.text = "PRUEBA VISUAL LOCAL · sin combate, daño ni audio"
	column.add_child(heading)
	var catalog_bar := HBoxContainer.new()
	column.add_child(catalog_bar)
	var batch_switch := CheckButton.new()
	batch_switch.text = "Catálogo por lotes · solo laboratorio"
	batch_switch.toggled.connect(_load_catalog)
	catalog_bar.add_child(batch_switch)
	_search = LineEdit.new()
	_search.placeholder_text = "Buscar nombre o ID del movimiento…"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_filter)
	catalog_bar.add_child(_search)
	_game_pool_switch = CheckButton.new()
	_game_pool_switch.text = "Solo pool de juego"
	_game_pool_switch.toggled.connect(func(_enabled: bool) -> void: _filter(_search.text))
	column.add_child(_game_pool_switch)
	_content_policy.load_local()
	if _content_policy.move_state("catastropika") == "pending":
		_game_pool_switch.text += " · Z pendientes fuera"
	_context_switch = CheckButton.new()
	_context_switch.text = "Contexto visual opcional · NO mecánicas"
	_context_switch.toggled.connect(_toggle_context)
	column.add_child(_context_switch)
	var toolbar := HBoxContainer.new()
	column.add_child(toolbar)
	_choices = OptionButton.new()
	_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choices.get_popup().max_size = Vector2i(0, 480)
	toolbar.add_child(_choices)
	_play = Button.new()
	_play.text = "Pausar"
	_play.pressed.connect(func() -> void:
		_playing = not _playing
		_play.text = "Pausar" if _playing else "Reproducir")
	toolbar.add_child(_play)
	var restart := Button.new()
	restart.text = "Reiniciar"
	restart.pressed.connect(func() -> void: _select(_choices.selected))
	toolbar.add_child(restart)
	stage = Preview.new()
	stage.custom_minimum_size = Vector2(640, 360)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(stage)
	_external = ExternalContext.new()
	_external.attach(stage)
	_slider = HSlider.new()
	_slider.step = 1
	_slider.value_changed.connect(_scrub)
	column.add_child(_slider)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.text = "Cargando recursos locales…"
	column.add_child(_status)
	var credits := Label.new()
	credits.text = "Garrote: Toxillian · Max: equivalente Gen 9, no animación Max propia\nCréditos completos y procedencias: docs/project_book/VISUAL_CATALOG.md"
	column.add_child(credits)
	_choices.item_selected.connect(_select)
	_load_catalog(false)
	if "--batch" in OS.get_cmdline_user_args():
		batch_switch.button_pressed = true
	if "--game-pool" in OS.get_cmdline_user_args():
		_game_pool_switch.button_pressed = true


func _load_catalog(batch: bool) -> void:
	_batch = batch
	_entries.clear()
	_loaded_path = ""
	_external.clear()
	stage.clear_preview()
	if batch:
		var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(BATCH_INDEX)) if FileAccess.file_exists(BATCH_INDEX) else null
		if not index is Dictionary or index.get("version") != 1 or not index.get("shards") is Array:
			_status.text = "Falta el índice por lotes; ejecutar tools/visual/run_move_batch.ps1"
			_choices.clear()
			return
		for shard: Dictionary in index.shards:
			var relative := String(shard.get("path", ""))
			if relative.is_empty() or relative.contains("..") or relative.is_absolute_path() or relative.contains("\\"):
				continue
			for entry_index in shard.get("entries", []).size():
				var entry: Dictionary = shard.entries[entry_index].duplicate()
				entry["path"] = BATCH_INDEX.get_base_dir().path_join(relative)
				entry["sha256"] = shard.sha256
				entry["index"] = entry_index
				_entries.append(entry)
	else:
		if not stage.load_pack():
			_status.text = stage.last_error
			return
		_loaded_path = Preview.DEFAULT_PACK
		for clip_index in stage.pack.clips.size():
			var entry: Dictionary = stage.pack.clips[clip_index].duplicate(false)
			entry["path"] = _loaded_path
			entry["index"] = clip_index
			_entries.append(entry)
	_filter(_search.text)


func _filter(query: String) -> void:
	_choices.clear()
	_filtered.clear()
	_external.clear()
	stage.clear_preview()
	if _game_pool_switch.button_pressed and not _content_policy.valid:
		_status.text = "POOL BLOQUEADO: " + "; ".join(_content_policy.errors)
		return
	for index in _entries.size():
		var entry: Dictionary = _entries[index]
		if _game_pool_switch.button_pressed and not _content_policy.move_allowed(String(entry.move_id)):
			continue
		if not query.is_empty() and not (String(entry.title) + " " + String(entry.id)).to_lower().contains(query.to_lower()):
			continue
		_filtered.append(index)
		_choices.add_item(String(entry.title) + " · " + String(entry.id))
	if not _filtered.is_empty():
		_select(0)
	else:
		_status.text = "Sin coincidencias. Los recursos en cuarentena no se ofrecen como reproducibles."


func _select(index: int) -> void:
	_elapsed = 0.0
	if index < 0 or index >= _filtered.size():
		return
	var entry: Dictionary = _entries[_filtered[index]]
	if _loaded_path != entry.path:
		if _batch and FileAccess.get_sha256(entry.path) != entry.sha256:
			_status.text = "El bloque cambió: reconstruir/reabrir el catálogo"
			return
		if not stage.load_pack(entry.path):
			_status.text = stage.last_error
			return
		_loaded_path = entry.path
	if stage.select_clip(int(entry.index)):
		_choices.select(index)
		if String(stage.clip.move_id) == "transform":
			stage.back_species = &"ditto"
			stage.front_species = &"charizard"
		elif String(stage.clip.move_id) != "ivy_cudgel":
			stage.back_species = &"charizard"
			stage.front_species = &"charizard"
		else:
			stage.back_species = &"ogerpon"
			stage.front_species = &"ogerpon"
		_bind_context()
		_updating = true
		_slider.max_value = _frame_count() - 1
		_slider.value = 0
		_updating = false
		_show_frame(0)
		_update_status()


func _scrub(value: float) -> void:
	if _updating or stage.clip.is_empty():
		return
	_playing = false
	_play.text = "Reproducir"
	_elapsed = value / 20.0
	_show_frame(int(value))
	_update_status()


func _process(delta: float) -> void:
	if stage == null or stage.clip.is_empty():
		return
	if _playing:
		_elapsed += delta
		var duration := float(_frame_count()) / 20.0
		# Brief rest between repetitions, not an invented loop in the source data.
		if _elapsed >= duration + 0.7:
			_elapsed = 0.0
		_show_frame(int(floor(minf(_elapsed, duration - 0.00001) * 20.0)))
	_update_status()


func _update_status() -> void:
	_updating = true
	_slider.value = _presentation_frame
	_updating = false
	_status.text = "%s · fotograma %d/%d · 20 fps · cámara adaptada, revisión pendiente" % [stage.clip.name, stage.current_frame + 1, stage.clip.frames.size()]
	if _game_pool_switch.button_pressed:
		_status.text += "\nPOOL DE JUEGO · selección permitida; no certifica mecánicas"
	else:
		_status.text += "\nARCHIVO DE INVESTIGACIÓN · puede incluir descartados y decisiones pendientes"
	if stage.clip.get("visual_only_context", false):
		_status.text += "\nREFERENCIA VISUAL MANUAL · no ejecuta ni habilita este movimiento"
	elif stage.clip.get("visual_only_variant", false):
		_status.text += "\nVARIANTE DEL EFECTO · no cambia la forma ni activa máscaras de Ogerpon"
	elif stage.clip.get("classification_unchanged", "") == "DATA_ONLY":
		_status.text += "\nSOLO REFERENCIA VISUAL · mecánica DATA_ONLY, no habilitada en combate"
	if _batch:
		_status.text += "\nLOTE AUTOMÁTICO · no implica aprobación artística ni conexión al combate"
	if stage.clip.has("visual_equivalent"):
		var equivalent: Variant = stage.clip.visual_equivalent
		if equivalent is Dictionary:
			_status.text += "\nEQUIVALENTE VISUAL EXPLÍCITO · fuente: %s · hueco original NO resuelto" % str(equivalent.get("source_name", "sin procedencia"))
			if equivalent.get("kind", "") == "native_impact_phase_only_not_preparation":
				_status.text += " · solo impacto, no preparación/espera"
		else:
			_status.text += "\nMETADATOS DE EQUIVALENCIA INVÁLIDOS · no aprobar este recurso"
	if stage.clip.has("visual_art_choice"):
		var art: Variant = stage.clip.visual_art_choice
		if art is Dictionary:
			_status.text += "\nEQUIVALENTE ARTÍSTICO EXPLÍCITO · fuente: %s · no repara la fuente ni habilita mecánicas" % str(art.get("source_name", "sin procedencia"))
		else:
			_status.text += "\nMETADATOS ARTÍSTICOS INVÁLIDOS · no aprobar este recurso"
	if not _batch and stage.clip.move_id == "max_flutterby":
		_status.text += "\nREFERENCIA HISTÓRICA CON POKÉMON INCRUSTADOS · usar la alternativa del catálogo por lotes"
	if ExternalContext.REQUIREMENTS.has(String(stage.clip.move_id)):
		_status.text += "\nCONTEXTO DE COMBATE PENDIENTE · " + String(ExternalContext.REQUIREMENTS[String(stage.clip.move_id)])
		if String(stage.clip.move_id) in ExternalContext.MOVES:
			_status.text += " Hay muestra visual opcional; no resuelve la integración real."
	if String(stage.clip.move_id) == "doom_desire":
		_status.text += "\nREFERENCIA DE CARGA / IMPACTO POR VINCULAR · existe una variante DOOMDUMMY separada; su asignación final a cada fase sigue pendiente."
	if String(stage.clip.move_id) == "court_change":
		_status.text += "\nMETÁFORA VISUAL · los cuerpos vuelven a sus plazas; no intercambia condiciones reales."
	if _context_switch.button_pressed:
		if _external.active:
			_status.text += "\n" + _external.label()
			if _presentation_frame >= stage.clip.frames.size():
				_status.text += " · contexto %d/30" % (_presentation_frame - stage.clip.frames.size() + 1)
		elif not _external.error.is_empty():
			_status.text += "\nCONTEXTO NO DISPONIBLE · " + _external.error


func _bind_context() -> void:
	_external.clear()
	_external.error = ""
	if _context_switch.button_pressed and not stage.clip.is_empty():
		_external.bind(_loaded_path)


func _frame_count() -> int:
	return _external.frame_count() if _external.active else stage.clip.frames.size()


func _show_frame(frame: int) -> bool:
	_presentation_frame = frame
	return _external.show_frame(frame) if _external.active else stage.show_frame(frame)


func _toggle_context(_enabled: bool) -> void:
	if stage == null or stage.clip.is_empty():
		return
	_elapsed = 0.0
	_bind_context()
	_updating = true
	_slider.max_value = _frame_count() - 1
	_updating = false
	_show_frame(0)
	_update_status()
