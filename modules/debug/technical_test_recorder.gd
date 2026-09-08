class_name TechnicalTestRecorder
extends RefCounted

# Black-box recorder for the asset-free technical build.
# It deliberately lives outside Battle Core and gameplay rules: callers only feed it
# already-observed facts. Every entry is flushed to JSONL immediately so a crash still
# leaves a useful trace. A human-friendly JSON snapshot can be exported at any time.

const REPORT_DIR := "user://pokemon_calvo_test_reports"

var _session_id: String = ""
var _stream_path: String = ""
var _entries: Array[Dictionary] = []
var _stream: FileAccess = null
var _sequence: int = 0
var _started_ticks_msec: int = 0


func start_session(metadata: Dictionary = {}) -> bool:
	close()
	_entries.clear()
	_sequence = 0
	_started_ticks_msec = Time.get_ticks_msec()
	var absolute_dir := ProjectSettings.globalize_path(REPORT_DIR)
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		return false
	_session_id = _timestamp_id()
	_stream_path = "%s/session_%s.jsonl" % [REPORT_DIR, _session_id]
	_stream = FileAccess.open(_stream_path, FileAccess.WRITE)
	if _stream == null:
		return false
	record(&"session", &"started", metadata)
	return true


func record(category: StringName, event_name: StringName, payload: Dictionary = {}) -> void:
	var entry := {
		"sequence": _sequence,
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"elapsed_msec": maxi(0, Time.get_ticks_msec() - _started_ticks_msec),
		"category": String(category),
		"event": String(event_name),
		"payload": payload.duplicate(true),
	}
	_sequence += 1
	_entries.append(entry)
	if _stream != null:
		_stream.store_line(JSON.stringify(entry))
		_stream.flush()


func export_report(summary: Dictionary = {}) -> String:
	if _session_id.is_empty():
		return ""
	var report_path := "%s/report_%s.json" % [REPORT_DIR, _session_id]
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		return ""
	var document := {
		"schema_version": 1,
		"session_id": _session_id,
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"summary": summary.duplicate(true),
		"entry_count": _entries.size(),
		"entries": _entries.duplicate(true),
	}
	file.store_string(JSON.stringify(document, "\t", true))
	file.flush()
	return ProjectSettings.globalize_path(report_path)


func report_directory_global_path() -> String:
	return ProjectSettings.globalize_path(REPORT_DIR)


func current_stream_global_path() -> String:
	return ProjectSettings.globalize_path(_stream_path) if not _stream_path.is_empty() else ""


func entry_count() -> int:
	return _entries.size()


func close() -> void:
	if _stream != null:
		_stream.flush()
		_stream = null


func _timestamp_id() -> String:
	return Time.get_datetime_string_from_system(false, false) \
		.replace("-", "") \
		.replace(":", "") \
		.replace("T", "_") \
		.replace(" ", "_")
