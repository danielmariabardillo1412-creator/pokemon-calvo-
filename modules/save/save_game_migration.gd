class_name SaveGameMigration
extends RefCounted

# Explicit save-format normalization. We only migrate the exact legacy pair that actually existed:
# schema 1 + calvo_save_v1. Migration is in-memory and non-destructive; loading never rewrites disk.
# The next explicit save writes V2.

const LEGACY_V1_VERSION := 1
const LEGACY_V1_FORMAT_ID := &"calvo_save_v1"


static func normalize(raw: Dictionary) -> Dictionary:
	var version := int(raw.get("schema_version", 0))
	var format_id := StringName(raw.get("format_id", ""))

	if format_id == &"":
		return _fail("missing_format_id")
	if version <= 0:
		return _fail("missing_schema")

	# Current format: accept only the exact current schema. No guessing/backfilling.
	if format_id == SaveGameData.FORMAT_ID:
		if version > SaveGameData.CURRENT_VERSION:
			return _fail("unsupported_schema")
		if version != SaveGameData.CURRENT_VERSION:
			return _fail("unsupported_schema")
		return {
			"ok": true,
			"reason": "",
			"data": raw.duplicate(true),
			"migrated_from_version": 0,
		}

	# Legacy V1: inventory did not exist. The only truthful migration is an empty bag; we must not
	# infer balls/items from party, storage, capture history, or any unknown extra field.
	if format_id == LEGACY_V1_FORMAT_ID:
		if version != LEGACY_V1_VERSION:
			return _fail("unsupported_schema")
		var migrated := raw.duplicate(true)
		migrated["schema_version"] = SaveGameData.CURRENT_VERSION
		migrated["format_id"] = String(SaveGameData.FORMAT_ID)
		migrated["inventory"] = PlayerInventory.new().to_dict()
		return {
			"ok": true,
			"reason": "",
			"data": migrated,
			"migrated_from_version": LEGACY_V1_VERSION,
		}

	return _fail("unsupported_format")


static func _fail(reason: String) -> Dictionary:
	return {
		"ok": false,
		"reason": reason,
		"data": {},
		"migrated_from_version": 0,
	}
