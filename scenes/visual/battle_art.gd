extends Control

const SPRITES := {
	&"bulbasaur": "1", &"charmander": "4", &"squirtle": "7", &"pidgey": "16",
}
var player_species: StringName = &""
var enemy_species: StringName = &""
var _textures: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for species in SPRITES:
		var id := String(SPRITES[species])
		_textures[species] = load("res://assets/prototype/pokemon/%s.png" % id)
		var back := "res://assets/prototype/pokemon/%s-back.png" % id
		if ResourceLoader.exists(back):
			_textures[String(species) + "_back"] = load(back)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("aec38e"))
	draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.45), Color("c7d4a3"))
	var left := Vector2(size.x * 0.25, size.y * 0.85)
	var right := Vector2(size.x * 0.76, size.y * 0.53)
	_platform(left, Vector2(64, 12))
	_platform(right, Vector2(55, 10))
	_creature(player_species, left, true)
	_creature(enemy_species, right, false)


func _platform(p: Vector2, radius: Vector2) -> void:
	draw_set_transform(p, 0.0, Vector2(1, radius.y / radius.x))
	draw_circle(Vector2.ZERO, radius.x, Color("8eac73"))
	draw_arc(Vector2.ZERO, radius.x - 3, 0, TAU, 32, Color("d9dfb0"), 2)
	draw_set_transform(Vector2.ZERO)


func _creature(species: StringName, ground: Vector2, back: bool) -> void:
	var key := String(species) + "_back" if back and _textures.has(String(species) + "_back") else String(species)
	var texture := _textures.get(key) as Texture2D
	if texture != null:
		draw_texture_rect(texture, Rect2(ground + Vector2(-72, -119), Vector2(144, 144)), false)
	elif species != &"":
		# Explicit fallback for species selected in the advanced lab without a local sprite.
		draw_circle(ground + Vector2(0, -27), 22, Color("5e8170"))
		draw_string(ThemeDB.fallback_font, ground + Vector2(-4, -22), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f4e9bd"))
		draw_string(ThemeDB.fallback_font, ground + Vector2(-42, 22), "Sprite pendiente", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("324d3e"))
