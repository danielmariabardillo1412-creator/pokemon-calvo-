extends SceneTree

# Headless build tool: runs the canonical DataImporter on the PokéAPI raw dataset,
# validates references, and writes import_summary.json + the normalized dataset.
# Run: godot --headless --script tools/run_import.gd --path <project>

const RAW_PATH := "res://data/raw/pokemon_api.json"
const MANIFEST_PATH := "res://data/manifests/pokemon_api_manifest.json"
const SUMMARY_PATH := "res://data/reports/import_summary.json"
const NORMALIZED_PATH := "res://data/normalized/pokemon_api.json"

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()

	var raw_text := _read(RAW_PATH)
	var manifest_text := _read(MANIFEST_PATH)
	var raw: Dictionary = JSON.parse_string(raw_text)
	var manifest: DatasetManifest = DatasetManifest.from_dict(JSON.parse_string(manifest_text))

	var importer := DataImporter.new()
	var res: Dictionary = importer.import_dataset(raw, manifest)
	var gd: GameData = res["game_data"]
	var report: DataImportReport = res["report"]

	var t_import := Time.get_ticks_msec()

	# Totals from the validated canonical dataset.
	var learnset_total := 0
	var evo_total := 0
	for sid in gd.species_catalog.all_ids():
		var sp: CreatureSpecies = gd.species_catalog.get_by_id(sid)
		learnset_total += sp.learnset.size()
		evo_total += sp.evolutions.size()

	# Forms total from the forms policy report.
	var forms_total := 0
	var fp := FileAccess.open("res://data/reports/forms_policy_report.json", FileAccess.READ)
	if fp != null:
		var fr: Dictionary = JSON.parse_string(fp.get_as_text())
		fp.close()
		forms_total = int(fr.get("forms_total", 0))

	var summary := {
		"schema_version": manifest.schema_version,
		"dataset_version": manifest.dataset_version,
		"source": manifest.source,
		"source_commit": manifest.provenance.get("source_commit", ""),
		"ruleset": manifest.ruleset,
		"species_total": gd.species_catalog.size(),
		"forms_total": forms_total,
		"types_total": gd.type_catalog.size(),
		"moves_total": gd.move_catalog.size(),
		"abilities_total": gd.ability_catalog.size(),
		"items_total": gd.item_catalog.size(),
		"statuses_total": gd.status_catalog.size(),
		"learnset_entries_total": learnset_total,
		"evolutions_total": evo_total,
		"imported": {
			"species": report.species_imported,
			"moves": report.moves_imported,
			"abilities": report.abilities_imported,
			"items": report.items_imported,
			"statuses": report.statuses_imported,
		},
		"rejected": report.rejected,
		"warnings": report.unsupported_mechanics,
		"broken_references": report.broken_references,
		"import_time_ms": t_import - t0,
	}

	_write(JSON.stringify(summary, "  "))
	# Normalized canonical dump (round-trip through GameData).
	var norm_text := JSON.stringify(gd.to_dict(), "  ")
	var nf := FileAccess.open(NORMALIZED_PATH, FileAccess.WRITE)
	if nf != null:
		nf.store_string(norm_text)
		nf.close()

	print("IMPORT SUMMARY: species=%d forms=%d types=%d moves=%d abilities=%d items=%d statuses=%d" % [
		summary.species_total, summary.forms_total, summary.types_total, summary.moves_total,
		summary.abilities_total, summary.items_total, summary.statuses_total])
	print("learnset_entries=%d evolutions=%d broken_references=%d rejected=%d" % [
		learnset_total, evo_total, report.broken_references.size(), report.rejected.size()])
	print("import_time_ms=%d" % (t_import - t0))
	if report.broken_references.size() > 0:
		push_error("BROKEN REFERENCES DETECTED: %d" % report.broken_references.size())
	quit(1 if report.broken_references.size() > 0 else 0)

func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open " + path)
		quit(1)
		return ""
	var t := f.get_as_text()
	f.close()
	return t

func _write(text: String) -> void:
	var f := FileAccess.open(SUMMARY_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write " + SUMMARY_PATH)
		quit(1)
		return
	f.store_string(text)
	f.close()
