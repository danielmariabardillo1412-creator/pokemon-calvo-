class_name DatasetManifest
extends RefCounted

# Versioned dataset manifest. Decouples savegames from file names and lets us
# detect incompatible data before loading. Schema evolves via schema_version.
const CURRENT_SCHEMA_VERSION := 1

var schema_version: int = CURRENT_SCHEMA_VERSION
var dataset_version: String = "0.0.0"
var source: String = ""
var generated_at: String = ""
var ruleset: String = ""
var provenance: Dictionary = {}   # source_name, source_version, source_url, license

func is_valid() -> bool:
	return schema_version == CURRENT_SCHEMA_VERSION and dataset_version != "" and source != ""

func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"dataset_version": dataset_version,
		"source": source,
		"generated_at": generated_at,
		"ruleset": ruleset,
		"provenance": provenance,
	}

static func from_dict(d: Dictionary) -> DatasetManifest:
	var m := DatasetManifest.new()
	m.schema_version = int(d.get("schema_version", 0))
	m.dataset_version = d.get("dataset_version", "")
	m.source = d.get("source", "")
	m.generated_at = d.get("generated_at", "")
	m.ruleset = d.get("ruleset", "")
	m.provenance = d.get("provenance", {})
	return m
