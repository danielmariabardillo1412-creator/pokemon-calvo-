class_name TechnicalRuntimeAuditService
extends RefCounted

const RUNTIME_DATA_PATH := "res://data/normalized/pokemon_api.json"
const REPORT_DIR := "user://pokemon_calvo_test_reports"


static func run_and_export(world: Node2D, config: Dictionary) -> Dictionary:
	var load_result := _load_catalogs()
	if not bool(load_result.get("ok", false)):
		return {"ok": false, "error": String(load_result.get("error", "data_load_failed")), "audit": {}, "path": ""}
	var catalogs := load_result.get("catalogs", null) as DefinitionCatalog
	var audit := TechnicalRuntimeAudit.new().run(catalogs, world, config)
	var path := _write_audit(audit)
	return {
		"ok": not path.is_empty(),
		"error": "" if not path.is_empty() else "audit_write_failed",
		"audit": audit,
		"path": path,
	}


static func _load_catalogs() -> Dictionary:
	var file := FileAccess.open(RUNTIME_DATA_PATH, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "canonical_data_missing"}
	var parsed := JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {"ok": false, "error": "canonical_data_invalid_json"}
	var game_data := GameData.from_dict(parsed as Dictionary)
	if game_data == null or game_data.manifest == null or not game_data.manifest.is_valid():
		return {"ok": false, "error": "canonical_manifest_invalid"}
	var type_validation := PokemonTypeChart.validate_catalog(game_data.type_catalog)
	if not bool(type_validation.get("valid", false)):
		return {"ok": false, "error": "canonical_type_chart_invalid"}
	return {"ok": true, "catalogs": game_data.to_definition_catalog()}


static func _write_audit(audit: Dictionary) -> String:
	var absolute_dir := ProjectSettings.globalize_path(REPORT_DIR)
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		return ""
	var stamp := Time.get_datetime_string_from_system(false, false) \
		.replace("-", "") \
		.replace(":", "") \
		.replace("T", "_") \
		.replace(" ", "_")
	var relative_path := "%s/automatic_audit_%s.json" % [REPORT_DIR, stamp]
	var file := FileAccess.open(relative_path, FileAccess.WRITE)
	if file == null:
		return ""
	var document := {
		"schema_version": 1,
		"kind": "pokemon_calvo_automatic_runtime_audit",
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"data_path": RUNTIME_DATA_PATH,
		"godot": Engine.get_version_info(),
		"audit": audit.duplicate(true),
	}
	file.store_string(JSON.stringify(document, "\t", true))
	file.flush()
	return ProjectSettings.globalize_path(relative_path)
