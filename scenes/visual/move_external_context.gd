extends RefCounted

# Optional LAB simulation only. Never mutates a battler, team, HP or weather state.
const Preview = preload("res://scenes/visual/community_move_preview.gd")
const ROOT := "res://.godot/move_external_context/"
const INDEX := "res://.godot/move_batch_catalog/index.json"
const MOVES := ["rain_dance", "hail", "snowscape", "chilly_reception", "substitute", "transform"]
const REQUIREMENTS := {
	"ally_switch": "Intercambio con un aliado: necesita una escena con dos aliados.",
	"baton_pass": "Entrada del relevo y transferencia de efectos permitidos.",
	"chilly_reception": "Nieve persistente y entrada del relevo tras la retirada.",
	"circle_throw": "Resolver la expulsión del objetivo y su relevo o salida del encuentro.",
	"dragon_tail": "Resolver la expulsión del objetivo y su relevo o salida del encuentro.",
	"flip_turn": "Entrada del relevo después del impacto y retirada del usuario.",
	"hail": "Mantener granizo según el estado real del combate.",
	"parting_shot": "Entrada del relevo después de aplicar los efectos del movimiento.",
	"rain_dance": "Mantener lluvia según el estado real del combate.",
	"roar": "Resolver la expulsión del objetivo y su relevo o salida del encuentro.",
	"sandstorm": "Mantener tormenta de arena según el estado real del combate.",
	"shed_tail": "Entrada del relevo conservando el sustituto que corresponda.",
	"snowscape": "Mantener nieve según el estado real del combate.",
	"substitute": "Muñeco persistente, ligado al sustituto real del combatiente.",
	"teleport": "Retirada del usuario: relevo o salida del encuentro según el combate.",
	"transform": "Apariencia y datos copiados según la transformación real.",
	"u_turn": "Entrada del relevo después del impacto y retirada del usuario.",
	"volt_switch": "Entrada del relevo después del impacto y retirada del usuario.",
	"whirlwind": "Resolver la expulsión del objetivo y su relevo o salida del encuentro.",
}

class WeatherOverlay extends Preview:
	func show_frame(frame: int) -> bool:
		var ok := super.show_frame(frame)
		_arena.hide()
		if ok:
			for slot in clip.frames[frame].size():
				var cel: Variant = clip.frames[frame][slot]
				if cel != null and cel[7] < 0:
					_sprites[slot].hide()
		return ok

var stage: Control
var weather: Control
var replacement: Sprite2D
var active := false
var error := ""
var metadata: Dictionary = {}
var definition: Dictionary = {}
var manifest_sha256 := ""
var _last_frame := -1


func attach(preview: Control) -> void:
	stage = preview
	weather = WeatherOverlay.new()
	weather.hide()
	stage.add_child(weather)
	replacement = Sprite2D.new()
	replacement.region_enabled = true
	replacement.hide()
	stage.add_child(replacement)
	stage.resized.connect(_schedule_refresh)


func _schedule_refresh() -> void:
	# The native preview schedules its own source-only refresh on resize. Reapply
	# the optional composition AFTER that callback, including while paused.
	_refresh_after_source.call_deferred()


func _refresh_after_source() -> void:
	_reapply_frame.call_deferred()


func _reapply_frame() -> void:
	if active and _last_frame >= 0 and is_instance_valid(stage) and not stage.is_queued_for_deletion():
		show_frame(_last_frame)


func _read(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return value if value is Dictionary else {}


func clear() -> void:
	active = false
	_last_frame = -1
	definition = {}
	weather.clear_preview()
	weather.hide()
	replacement.hide()
	replacement.texture = null
	# Restore the native source, including its arena species and body visibility.
	if not stage.clip.is_empty() and stage.current_frame >= 0:
		stage.show_frame(stage.current_frame)


func _fail(message: String) -> bool:
	clear()
	error = message
	return false


func bind(source_path: String) -> bool:
	clear()
	error = ""
	if not stage.clip.get("move_id", "") in MOVES:
		return false
	var pointer := _read(ROOT + "latest.json")
	var relative := String(pointer.get("path", ""))
	if relative.is_empty() or relative.is_absolute_path() or relative.contains("..") or relative.contains("\\"):
		return _fail("Falta el pack de contexto; ejecutar build_move_external_context.py")
	var path := ROOT + relative
	if FileAccess.get_sha256(path) != pointer.get("sha256", ""):
		return _fail("El manifiesto de contexto cambió")
	metadata = _read(path)
	manifest_sha256 = pointer.sha256
	if metadata.get("version") != 1 or metadata.get("scope") != "LAB_ONLY_NOT_BATTLE_APPROVAL" or metadata.get("mechanics_enabled") != false or metadata.get("extension_frames") != 30:
		return _fail("Contexto no válido para este laboratorio")
	if metadata.get("catalog_index_sha256") != FileAccess.get_sha256(INDEX) or metadata.get("renderer_sha256") != FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd"):
		return _fail("Contexto obsoleto: reconstruir para el catálogo actual")
	if not metadata.get("bindings") is Dictionary or not metadata.get("definitions") is Dictionary:
		return _fail("Faltan contratos de contexto")
	var binding: Variant = metadata.bindings.get(stage.clip.id)
	if not binding is Dictionary or binding.get("source_shard_sha256") != FileAccess.get_sha256(source_path) or binding.get("source_name") != stage.clip.name or binding.get("source_frames") != stage.clip.frames.size() or binding.get("classification_unchanged") != stage.clip.classification_unchanged:
		return _fail("El clip no coincide con su fuente de contexto")
	var config: Variant = metadata.definitions.get(stage.clip.move_id)
	if not config is Dictionary or not config.get("kind") in ["weather", "withdrawal_snow", "doll", "appearance"]:
		return _fail("Definición de contexto inválida")
	var pack_relative := String(metadata.get("weather_path", ""))
	if pack_relative != "weather.json":
		return _fail("Ruta de contexto inválida")
	var pack_path := path.get_base_dir().path_join(pack_relative)
	if FileAccess.get_sha256(pack_path) != metadata.get("weather_sha256") or not weather.load_pack(pack_path) or weather.pack.clips.size() != 3:
		return _fail("Falta o cambió el pack común de clima")
	for n in 3:
		if weather.pack.clips[n].name != ["Common:Rain", "Common:Hail", "Common:Snow"][n] or weather.pack.clips[n].frames.size() != 30:
			return _fail("Export de clima inesperado")
	if not weather.textures.has(metadata.get("doll_sheet", "")):
		return _fail("Falta la hoja original del muñeco")
	if not metadata.get("doll_bounds") is Dictionary:
		return _fail("Faltan límites alfa del muñeco")
	for side: String in ["back", "front"]:
		var bounds: Variant = metadata.doll_bounds.get(side)
		if not bounds is Array or bounds.size() != 4:
			return _fail("Límites del muñeco inválidos")
		for number: Variant in bounds:
			if not (number is float or number is int) or not is_finite(float(number)) or float(number) < 0 or float(number) > 192:
				return _fail("Límites alfa fuera de la celda")
		if bounds[2] <= 0 or bounds[3] <= 0 or bounds[0] + bounds[2] > 192 or bounds[1] + bounds[3] > 192:
			return _fail("Celda alfa fuera de rango")
	if config.get("kind") in ["weather", "withdrawal_snow"]:
		var choice: Variant = config.get("weather")
		if not (choice is float or choice is int) or choice != int(choice) or int(choice) < 0 or int(choice) > 2:
			return _fail("Selección de clima inválida")
	if config.get("kind") == "appearance" and config.get("handoff_frame") != 8:
		return _fail("El cambio de apariencia debe quedar bajo el destello de muestra")
	definition = config.duplicate(true)
	active = true
	return true


func frame_count() -> int:
	return stage.clip.get("frames", []).size() + (30 if active else 0)


func show_frame(frame: int) -> bool:
	weather.hide()
	replacement.hide()
	if frame < 0 or frame >= frame_count() or stage.clip.is_empty():
		clear()
		stage.clear_preview()
		return false
	var length: int = stage.clip.frames.size()
	_last_frame = frame
	if not stage.show_frame(mini(frame, length - 1)):
		return false
	# Appearance swaps while the native flash is opaque, avoiding an original-
	# body pop after the flash. This is a declared demo hook, NOT a source edit.
	var appearance_handoff: bool = active and definition.kind == "appearance" and frame >= int(definition.handoff_frame)
	if not active or (frame < length and not appearance_handoff):
		return true
	var side := String(stage.clip.actor_side)
	if definition.kind in ["weather", "withdrawal_snow"]:
		weather.size = stage.size
		weather.back_species = stage.back_species
		weather.front_species = stage.front_species
		weather.clip = weather.pack.clips[int(definition.weather)]
		weather.show()
		return weather.show_frame(frame - length)
	var native_frame := mini(frame, length - 1)
	for slot in stage.clip.frames[native_frame].size():
		var cel: Variant = stage.clip.frames[native_frame][slot]
		if cel != null and cel[7] < 0 and stage.clip.slot_sides[0 if cel[7] == -1 else 1] == side:
			stage._sprites[slot].hide()
	if definition.kind == "doll":
		replacement.texture = weather.textures[metadata.doll_sheet]
		replacement.region_rect = Rect2(192 if side == "back" else 0, 0, 192, 192)
		# Keep the native doll artwork/scale. Position its opaque feet at the
		# actor's ground anchor rather than centering the transparent 192px tile.
		var gain := minf(stage.size.x / 512.0, stage.size.y / 384.0)
		var box: Array = metadata.doll_bounds[side]
		var bounds := Rect2(box[0], box[1], box[2], box[3])
		replacement.offset = Vector2(96, 96) - Vector2(bounds.get_center().x, bounds.end.y)
		var species: StringName = stage.back_species if side == "back" else stage.front_species
		var animation: Dictionary = Preview.Catalog.animation(species, side)
		var presentation := Preview.Catalog.presentation_bounds(species, side, animation)
		var placement := Preview.Layout.placement(stage.size, side, presentation)
		replacement.position = placement.anchor + Vector2(0, presentation.end.y * float(placement.gain))
		replacement.scale = Vector2.ONE * gain
	else:
		var species: StringName = stage.front_species if side == "back" else stage.back_species
		var actor: Dictionary = stage._actor(species, side)
		if actor.is_empty():
			return _fail("Falta la vista del Pokémon copiado")
		replacement.texture = actor.texture
		replacement.region_rect = actor.region
		replacement.offset = actor.offset
		replacement.position = actor.center
		replacement.scale = Vector2.ONE * float(actor.gain)
		if side == "back":
			stage._arena.player_species = species
		else:
			stage._arena.enemy_species = species
		stage._arena.queue_redraw()
	replacement.z_index = 30 if side == "back" else 20
	replacement.show()
	return true


func label() -> String:
	if active:
		return "SIMULACIÓN VISUAL LOCAL · " + String(definition.label) + " · 1,5 s de muestra"
	return error
