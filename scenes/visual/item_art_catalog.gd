extends RefCounted

const MANIFEST := "res://assets/local_item_catalog/manifest.json"
static var _loaded := false
static var _rows: Dictionary = {}
static var _textures: Dictionary = {}


static func rows() -> Dictionary:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(MANIFEST):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
			if data is Dictionary and data.get("schema_version") == 1 and data.get("items") is Dictionary:
				_rows = data.items
	return _rows


static func texture(id: StringName) -> Texture2D:
	var key := String(id)
	if not rows().has(key): return null
	if not _textures.has(key):
		var path := String(_rows[key].get("texture", ""))
		if not path.begins_with("res://assets/local_item_catalog/icons/") or not ResourceLoader.exists(path): return null
		_textures[key] = load(path) as Texture2D
	return _textures[key] as Texture2D
