class_name SaveGameSerializer
extends RefCounted

# Filesystem IO for the savegame. DOMAIN logic (snapshot building, validation, reconstruction)
# lives in SaveGameRepository; this class is pure serialization + an ATOMIC, LAST-KNOWN-GOOD
# PROTECTED replacement.
#
# write_atomic(path, data):
#   1. serialize to path+".tmp"
#   2. verify tmp is readable + parseable
#   3. replacement:
#      a. if no target exists: rename tmp -> target
#      b. if target exists:    rename target -> target+".bak" (backup of the LAST KNOWN GOOD save)
#                              rename tmp -> target (publish)
#                              on success: remove backup
#                              on failure: restore backup -> target (previous save fully recovered)
#
# INVARIANT: the previous good save is NEVER destroyed before the replacement is verified and
# published. A failed publish restores the previous good save (or reports a catastrophic
# restore failure) and never leaves a half-written target.

const TMP_SUFFIX := ".tmp"
const BAK_SUFFIX := ".bak"

# Test seam: if set, _safe_rename delegates to it (must return an int error code). Lets the
# test suite deterministically simulate a failed filesystem rename without touching the disk
# in a way real OS calls would not.
var rename_failure_inject: Callable = Callable()


func write_atomic(path: String, data: SaveGameData) -> SaveResult:
	var res := SaveResult.new()
	var tmp := path + TMP_SUFFIX
	var bak := path + BAK_SUFFIX

	# 1. serialize to tmp
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		res.reason = "cannot_open_temp"
		return res
	f.store_string(JSON.stringify(data.to_dict()))
	f.close()

	# 2. verify tmp is readable + parseable before we trust it
	var raw := read_raw(tmp)
	if parse(raw) == null:
		_safe_remove(tmp)
		res.reason = "temp_verify_failed"
		return res

	# 3. replacement
	if not FileAccess.file_exists(path):
		if _safe_rename(tmp, path) != OK:
			_safe_remove(tmp)
			res.reason = "rename_failed"
			return res
		res.ok = true
		res.path = path
		return res

	# target exists -> protected replacement with backup of the last known good save
	if FileAccess.file_exists(bak):
		_safe_remove(bak)
	if _safe_rename(path, bak) != OK:
		# cannot back up the current good save: do NOT touch the live target, discard tmp.
		_safe_remove(tmp)
		res.reason = "cannot_back_up_target"
		return res

	# previous good save now at bak; publish the new content from tmp
	if _safe_rename(tmp, path) == OK:
		_safe_remove(bak)
		res.ok = true
		res.path = path
		return res

	# publish failed: restore the previous good save from the backup
	if _safe_rename(bak, path) == OK:
		_safe_remove(tmp)
		res.reason = "replace_failed_restored"
		return res

	# catastrophic: publish failed AND restore failed; the live target is in an unknown state.
	res.reason = "replace_failed_restore_failed"
	return res


func read_raw(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


func parse(text: String) -> Variant:
	if text == "":
		return null
	return JSON.parse_string(text)


func _safe_remove(path: String) -> int:
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return ERR_CANT_OPEN
	return dir.remove(path.get_file())


func _safe_rename(from: String, to: String) -> int:
	if rename_failure_inject.is_valid():
		return int(rename_failure_inject.call(from, to))
	var dir := DirAccess.open(from.get_base_dir())
	if dir == null:
		return ERR_CANT_OPEN
	return dir.rename(from.get_file(), to.get_file())
