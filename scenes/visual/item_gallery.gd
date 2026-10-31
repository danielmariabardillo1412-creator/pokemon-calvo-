extends VBoxContainer

signal close_requested
const Art = preload("res://scenes/visual/item_art_catalog.gd")
var _list: ItemList
var _detail: Label
var _large: TextureRect
var _small: TextureRect
var _keys: Array[String] = []
var selected_id := ""


func _ready() -> void:
	var title := Label.new(); title.text = "CATÁLOGO DE OBJETOS · %d imágenes · beta" % Art.rows().size(); add_child(title)
	var columns := HBoxContainer.new(); columns.size_flags_vertical = Control.SIZE_EXPAND_FILL; add_child(columns)
	var left := VBoxContainer.new(); left.custom_minimum_size.x = 290; columns.add_child(left)
	var search := LineEdit.new(); search.placeholder_text = "Buscar nombre o ID…"; search.text_changed.connect(_filter); left.add_child(search)
	_list = ItemList.new(); _list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.fixed_icon_size = Vector2i(40, 40); _list.icon_mode = ItemList.ICON_MODE_LEFT
	_list.item_selected.connect(_select); left.add_child(_list)
	var right := VBoxContainer.new(); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; columns.add_child(right)
	var previews := HBoxContainer.new(); previews.size_flags_vertical = Control.SIZE_EXPAND_FILL; previews.alignment = BoxContainer.ALIGNMENT_CENTER; right.add_child(previews)
	_large = _preview(previews, 128); _small = _preview(previews, 48)
	_detail = Label.new(); _detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right.add_child(_detail)
	var close := Button.new(); close.text = "Cerrar · F3 / Esc"; close.pressed.connect(func(): close_requested.emit()); right.add_child(close)
	var footer := Label.new(); footer.text = "Arte provisional. Consultar un objeto no lo añade a la mochila ni habilita su uso."
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(footer)
	_filter("")


func _preview(parent: Control, pixels: int) -> TextureRect:
	var column := VBoxContainer.new(); column.size_flags_vertical = Control.SIZE_SHRINK_CENTER; parent.add_child(column)
	var image := TextureRect.new(); image.custom_minimum_size = Vector2(pixels, pixels)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; column.add_child(image)
	var caption := Label.new(); caption.text = "%d px" % pixels; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(caption)
	return image


func _fold(text: String) -> String:
	return text.to_lower().replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")


func _filter(query: String) -> void:
	_list.clear(); _keys.clear()
	var ids := Art.rows().keys(); ids.sort()
	for id: String in ids:
		var row: Dictionary = Art.rows()[id]
		if not _fold(String(row.display_name) + " " + id).contains(_fold(query.strip_edges())): continue
		_keys.append(id); _list.add_item(String(row.display_name), Art.texture(StringName(id)))
	if not _keys.is_empty():
		_list.select(0); _select(0)
	else:
		selected_id = ""; _large.texture = null; _small.texture = null; _detail.text = "No se han encontrado objetos."


func select_id(id: String) -> bool:
	_filter(id)
	var index := _keys.find(id)
	if index < 0: return false
	_list.select(index); _select(index); return true


func _select(index: int) -> void:
	if index < 0 or index >= _keys.size(): return
	selected_id = _keys[index]
	var row: Dictionary = Art.rows()[selected_id]
	_large.texture = Art.texture(StringName(selected_id)); _small.texture = _large.texture
	var filter_mode := CanvasItem.TEXTURE_FILTER_NEAREST if row.small_fallback else CanvasItem.TEXTURE_FILTER_LINEAR
	_large.texture_filter = filter_mode; _small.texture_filter = filter_mode
	var origin: String = {"SV": "Escarlata/Púrpura", "ZA": "Leyendas: Z-A", "GLOBAL_LINK": "Global Link", "GLOBAL_LINK_PACK": "Global Link", "LEGENDS_ARCEUS": "Leyendas: Arceus", "POKEAPI_ROOT": "PokéAPI", "SMALL_SPRITE": "Icono provisional", "GENERATED": "Arte generado · beta"}.get(row.source, "Catálogo moderno")
	_detail.text = "%s\n%s\nArte: %s · original %d × %d px" % [row.display_name, selected_id, origin, row.width, row.height]
	if row.small_fallback: _detail.text += "\nIcono pequeño provisional; pendiente de mejorar el acabado."
	if row.historical_review: _detail.text += "\nDiseño pendiente de revisar para la ambientación romana/vikinga."
	if row.has("mechanic_note"): _detail.text += "\n" + String(row.mechanic_note)
