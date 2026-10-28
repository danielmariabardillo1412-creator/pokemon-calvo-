extends Node

const Overlay = preload("res://scenes/visual/move_external_context.gd").WeatherOverlay
const PACK := "res://.godot/battle_weather/common.json"
const SHA := "044675099b36945a28c7838a8d1a5a59257167aa0ce26d5d94fec3970e2ad42d"
const INDICES := {"rain": 0, "hail": 1, "snow": 2, "sandstorm": 3}
var preview: Control
var available := false
var current: Dictionary = {}
var clock := 0.0
var arena: Control


func configure(p_arena: Control) -> void:
	arena = p_arena
	preview = Overlay.new()
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.add_child(preview)
	preview.hide()
	available = FileAccess.file_exists(PACK) and FileAccess.get_sha256(PACK) == SHA and preview.load_pack(PACK)


func set_weather(data: Dictionary) -> void:
	if data.get("id", "") != current.get("id", ""): clock = 0.0
	current = data.duplicate(true)
	_draw_weather()


func _process(delta: float) -> void:
	clock += maxf(0.0, delta)
	_draw_weather()


func _draw_weather() -> void:
	var id := String(current.get("id", ""))
	if not available or not INDICES.has(id) or current.get("suppressed", false):
		preview.hide()
		return
	preview.back_species = arena.player_species
	preview.front_species = arena.enemy_species
	if preview.clip.get("name", "") != preview.pack.clips[INDICES[id]].name:
		preview.select_clip(INDICES[id])
	preview.show_frame(int(clock * 20.0) % preview.clip.frames.size())
	preview.show()
