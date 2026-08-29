class_name SaveGameSerializer
extends RefCounted

# IO for savegames. Atomic write: serialize -> temp file -> verify parse -> replace target.
# No UI, no autoload; uses FileAccess / DirAccess directly.

const TMP_SUFFIX := ".tmp"


func write_atomic(path: String, data: SaveGameData) -> SaveResult:
	var res := SaveResult.new()
	var tmp := path + TMP_SUFFIX
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		res.reason = "cannot_open_temp"
		return res
	f.store_string(JSON.stringify(data.to_dict()))
	f.close()
	# Verify the temp file is readable and parseable before replacing the target.
	var raw := read_raw(tmp)
	if parse(raw) == null:
		var d0 := DirAccess.open(path.get_base_dir())
		if d0 != null:
			d0.remove(tmp.get_file())
		res.reason = "temp_verify_failed"
		return res
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		res.reason = "cannot_open_dir"
		return res
	if FileAccess.file_exists(path):
		if dir.remove(path.get_file()) != OK:
			dir.remove(tmp.get_file())
			res.reason = "cannot_remove_target"
			return res
	if dir.rename(tmp.get_file(), path.get_file()) != OK:
		res.reason = "rename_failed"
		return res
	res.ok = true
	res.path = path
	return res


func read_raw(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var s := f.get_as_text()
	f.close()
	return s


# Returns the parsed Dictionary, or null on parse failure / empty input.
func parse(s: String):
	if s == null or s == "":
		return null
	return JSON.parse_string(s)
