class_name TechnicalTestRecorder
extends RefCounted

# Black-box recorder for the asset-free technical build.
# It deliberately lives outside Battle Core and gameplay rules: callers only feed it
# already-observed facts. Every entry is flushed to JSONL immediately so a crash still
# leaves a useful trace. A human-friendly JSON snapshot can be exported at any time.

const REPORT_DIR := "user://pokemon_calvo_test_reports"
const BUILD_METADATA_PATH := "res://data/build_metadata.json"

var _session_id: String = ""
var _stream_path: String = ""
var _entries: Array[Dictionary] = []
var _stream: FileAccess = null
var _sequence: int = 0
var _started_ticks_msec: int = 0
var _session_metadata: Dictionary = {}


func start_session(metadata: Dictionary = {}) -> bool:
	close()
	_entries.clear()
	_sequence = 0
	_started_ticks_msec = Time.get_ticks_msec()
	_session_metadata = metadata.duplicate(true)
	_session_metadata["build"] = _load_build_metadata()
	var absolute_dir := ProjectSettings.globalize_path(REPORT_DIR)
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		return false
	_session_id = _timestamp_id()
	_stream_path = "%s/session_%s.jsonl" % [REPORT_DIR, _session_id]
	_stream = FileAccess.open(_stream_path, FileAccess.WRITE)
	if _stream == null:
		return false
	record(&"session", &"started", _session_metadata)
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
	var diagnostics := _diagnostic_summary()
	var document := {
		"schema_version": 2,
		"session_id": _session_id,
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"session_metadata": _session_metadata.duplicate(true),
		"summary": summary.duplicate(true),
		"coverage": diagnostics.get("coverage", {}),
		"diagnostics": diagnostics.get("diagnostics", {}),
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


func build_metadata() -> Dictionary:
	return (_session_metadata.get("build", {}) as Dictionary).duplicate(true)


func close() -> void:
	if _stream != null:
		_stream.flush()
		_stream = null


func _load_build_metadata() -> Dictionary:
	var fallback := {
		"schema_version": 1,
		"source_sha": "unknown",
		"repository": "",
		"build_kind": "unknown",
		"workflow_run_id": "",
		"built_at_utc": "",
		"data_sha256": "",
	}
	var file := FileAccess.open(BUILD_METADATA_PATH, FileAccess.READ)
	if file == null:
		fallback["metadata_status"] = "missing"
		return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		fallback["metadata_status"] = "invalid_json"
		return fallback
	var result := (parsed as Dictionary).duplicate(true)
	result["metadata_status"] = "loaded"
	return result


func _diagnostic_summary() -> Dictionary:
	var coverage := {
		"movement_steps": false,
		"encounter_rolls": false,
		"wild_battle": false,
		"capture_attempt": false,
		"run_attempt": false,
		"trainer_battle": false,
		"trainer_autonomous_turn": false,
		"state_validation": false,
		"transition": false,
		"building_transition": false,
		"cave_transition": false,
		"ledge_jump": false,
		"ledge_rejection": false,
	}
	var category_counts: Dictionary = {}
	var anomaly_examples: Array[Dictionary] = []
	var anomaly_count := 0
	for entry in _entries:
		var category := String(entry.get("category", ""))
		var event_name := String(entry.get("event", ""))
		var payload := entry.get("payload", {}) as Dictionary
		category_counts[category] = int(category_counts.get(category, 0)) + 1

		if category == "overworld" and event_name == "step_completed":
			coverage["movement_steps"] = true
		elif category == "encounter" and event_name == "roll_resolved":
			coverage["encounter_rolls"] = true
		elif category == "wild" and event_name == "battle_started":
			coverage["wild_battle"] = true
		elif category == "trainer" and event_name == "battle_started":
			coverage["trainer_battle"] = true
		elif category == "trainer_ui" and event_name == "turn_resolved":
			coverage["trainer_autonomous_turn"] = true
		elif event_name == "state_snapshot":
			coverage["state_validation"] = true
		elif category == "traversal" and event_name == "transition_finished":
			coverage["transition"] = true
			var traversal_text := JSON.stringify(payload).to_lower()
			if traversal_text.contains("building"):
				coverage["building_transition"] = true
			if traversal_text.contains("cave"):
				coverage["cave_transition"] = true
		elif category == "traversal" and event_name == "ledge_jump_finished":
			coverage["ledge_jump"] = true
		elif category == "traversal" and event_name == "ledge_rejected":
			coverage["ledge_rejection"] = true

		if category == "wild_ui" and (event_name == "command" or event_name == "command_result"):
			var kind := String(payload.get("kind", ""))
			if kind == "capture":
				coverage["capture_attempt"] = true
			elif kind == "run":
				coverage["run_attempt"] = true

		var anomaly_reason := _entry_anomaly_reason(event_name, payload)
		if not anomaly_reason.is_empty():
			anomaly_count += 1
			if anomaly_examples.size() < 50:
				anomaly_examples.append({
					"sequence": int(entry.get("sequence", -1)),
					"category": category,
					"event": event_name,
					"reason": anomaly_reason,
				})

	var covered_count := 0
	for value in coverage.values():
		if bool(value):
			covered_count += 1
	return {
		"coverage": {
			"checks": coverage,
			"covered_count": covered_count,
			"total_count": coverage.size(),
			"category_event_counts": category_counts,
		},
		"diagnostics": {
			"status": "OK" if anomaly_count == 0 else "CHECK",
			"anomaly_count": anomaly_count,
			"examples": anomaly_examples,
		},
	}


func _entry_anomaly_reason(event_name: String, payload: Dictionary) -> String:
	if payload.has("validation_ok") and not bool(payload.get("validation_ok", true)):
		return "state_validation_failed"
	if bool(payload.get("anomaly", false)):
		return "runtime_anomaly"
	var last_error := String(payload.get("last_error", ""))
	if not last_error.is_empty() and last_error != "missing_session":
		return "last_error:%s" % last_error
	if event_name.ends_with("_failed") or event_name.contains("error"):
		return "event:%s" % event_name
	return ""


func _timestamp_id() -> String:
	return Time.get_datetime_string_from_system(false, false) \
		.replace("-", "") \
		.replace(":", "") \
		.replace("T", "_") \
		.replace(" ", "_")
