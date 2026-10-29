extends RefCounted

# Only the seven fixed source samples needed by tests. No fallback to an absent
# multi-gigabyte API checkout and no dataset generation or writes.
const ROOT := "res://tests/fixtures/pokeapi_sources/"

static func verified_path(relative: String) -> String:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	if not manifest is Dictionary or manifest.get("version") != 1:
		return ""
	var entry: Dictionary = manifest.get("files", {}).get(relative, {})
	if entry.is_empty() or relative.contains(".."):
		return ""
	var path := ROOT + relative
	return path if FileAccess.file_exists(path) and FileAccess.get_sha256(path) == entry.get("sha256") else ""

static func read(relative: String) -> Dictionary:
	var path := verified_path(relative)
	if path.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
