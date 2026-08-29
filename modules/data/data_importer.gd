class_name DataImporter
extends RefCounted

# Minimal, safe data pipeline:
#   raw records -> validation -> canonical definitions -> injectable catalogs.
# Rejects duplicate IDs, malformed IDs, invalid stats, and broken references.
# Does NOT import massive PokéAPI yet; the same code path scales to large raw sets.

const TYPE_KEYS := ["id", "display_name", "effectiveness"]
const MOVE_KEYS := ["id", "display_name", "power", "type_id", "priority"]
const ABILITY_KEYS := ["id", "display_name", "description", "effect_id"]
const ITEM_KEYS := ["id", "display_name", "description", "category"]
const STATUS_KEYS := ["id", "display_name", "end_turn_max_hp_divisor", "minimum_damage"]
const SPECIES_KEYS := [
	"id", "display_name", "primary_type_id", "secondary_type_id", "type_ids", "types",
	"base_hp", "base_attack", "base_defense", "base_speed", "ability_ids",
	"base_experience", "learnset", "evolutions",
]

var _type_catalog := TypeCatalog.new()
var _move_catalog := MoveCatalog.new()
var _ability_catalog := AbilityCatalog.new()
var _item_catalog := ItemCatalog.new()
var _status_catalog := StatusCatalog.new()

func import_dataset(raw: Dictionary, manifest: DatasetManifest) -> Dictionary:
	_type_catalog = TypeCatalog.new()
	_move_catalog = MoveCatalog.new()
	_ability_catalog = AbilityCatalog.new()
	_item_catalog = ItemCatalog.new()
	_status_catalog = StatusCatalog.new()

	var report := DataImportReport.new()
	var gd := GameData.new()
	gd.manifest = manifest if manifest != null else DatasetManifest.new()

	if manifest == null or not manifest.is_valid():
		report.add_issue("invalid_manifest", "Manifest missing schema_version/dataset_version/source")

	_ingest_list("type", raw.get("types", []), TYPE_KEYS, report)
	_ingest_list("move", raw.get("moves", []), MOVE_KEYS, report)
	_ingest_list("ability", raw.get("abilities", []), ABILITY_KEYS, report)
	_ingest_list("item", raw.get("items", []), ITEM_KEYS, report)
	_ingest_list("status", raw.get("statuses", []), STATUS_KEYS, report)
	_ingest_species(raw.get("species", []), report)

	report.moves_imported = _move_catalog.size()
	report.abilities_imported = _ability_catalog.size()
	report.items_imported = _item_catalog.size()
	report.statuses_imported = _status_catalog.size()
	report.unsupported_mechanics = _dedup(report.unsupported_mechanics)

	gd.type_catalog = _type_catalog
	gd.move_catalog = _move_catalog
	gd.ability_catalog = _ability_catalog
	gd.item_catalog = _item_catalog
	gd.status_catalog = _status_catalog
	gd.species_catalog = _species_result_catalog
	return {"game_data": gd, "report": report}

var _species_result_catalog := SpeciesCatalog.new()

func _ingest_list(kind: String, records: Array, allowed: Array, report: DataImportReport) -> void:
	var seen: Dictionary = {}
	for rec in records:
		var rid := StringName(String(rec.get("id", "")))
		if not DataValidator.is_valid_id(rid):
			report.rejected.append("%s (invalid_id)" % rid)
			report.add_issue("invalid_id", "Bad %s id" % kind, {"id": String(rid)})
			continue
		if seen.has(rid):
			report.rejected.append("%s (duplicate_id)" % rid)
			report.add_issue("duplicate_id", "Duplicate %s id" % kind, {"id": String(rid)})
			continue
		seen[rid] = true
		for k in rec.keys():
			if not allowed.has(k):
				_report_once(report, "unsupported:%s:%s" % [kind, k])
		var built = _build(kind, rec)
		if built == null:
			report.rejected.append("%s (build_error)" % rid)
			report.add_issue("build_error", "Could not build %s" % kind, {"id": String(rid)})
			continue
		_add(kind, built)

func _build(kind: String, rec: Dictionary):
	match kind:
		"type":
			return TypeDefinition.from_dict(rec)
		"move":
			if not DataValidator.is_valid_pow(int(rec.get("power", 0))):
				return null
			if not _type_catalog.has(StringName(String(rec.get("type_id", "normal")))):
				return null
			return MoveDefinition.from_dict(rec)
		"ability":
			return AbilityDefinition.from_dict(rec)
		"item":
			return ItemDefinition.from_dict(rec)
		"status":
			return StatusDefinition.from_dict(rec)
	return null

func _add(kind: String, def) -> void:
	match kind:
		"type":
			_type_catalog.add(def as TypeDefinition)
		"move":
			_move_catalog.add(def as MoveDefinition)
		"ability":
			_ability_catalog.add(def as AbilityDefinition)
		"item":
			_item_catalog.add(def as ItemDefinition)
		"status":
			_status_catalog.add(def as StatusDefinition)

func _ingest_species(records: Array, report: DataImportReport) -> void:
	_species_result_catalog = SpeciesCatalog.new()
	var seen: Dictionary = {}
	var pending: Array = []
	for rec in records:
		var sid := StringName(String(rec.get("id", "")))
		if not DataValidator.is_valid_id(sid):
			report.rejected.append("%s (invalid_id)" % sid)
			report.add_issue("invalid_id", "Bad species id", {"id": String(sid)})
			continue
		if seen.has(sid):
			report.rejected.append("%s (duplicate_id)" % sid)
			report.add_issue("duplicate_id", "Duplicate species id", {"id": String(sid)})
			continue
		for k in rec.keys():
			if not SPECIES_KEYS.has(k):
				_report_once(report, "unsupported:species:%s" % k)
		var built := CreatureSpecies.from_dict(rec)
		var reason := _validate_species(built)
		if reason != "":
			report.rejected.append("%s (%s)" % [sid, reason])
			report.broken_references.append("%s:%s" % [sid, reason])
			report.add_issue(reason, "Rejected species", {"id": String(sid)})
			continue
		seen[sid] = built
		pending.append(built)
	for built in pending:
		var ok := true
		for ev in built.evolutions:
			if ev is EvolutionRecord and not seen.has((ev as EvolutionRecord).species_id):
				ok = false
				report.rejected.append("%s (broken_evolution_reference)" % built.id)
				report.broken_references.append("%s:evolution:%s" % [built.id, (ev as EvolutionRecord).species_id])
				report.add_issue("broken_evolution_reference", "Evolution to unknown species", {"id": String(built.id)})
				break
		if ok:
			_species_result_catalog.add(built)
			report.species_imported += 1
			report.evolutions_count += built.evolutions.size()

func _validate_species(s: CreatureSpecies) -> String:
	if not DataValidator.is_valid_stat(s.base_hp) or not DataValidator.is_valid_stat(s.base_attack) \
		or not DataValidator.is_valid_stat(s.base_defense) or not DataValidator.is_valid_stat(s.base_speed):
		return "invalid_stats"
	for t in s.type_ids_resolved():
		if not _type_catalog.has(t):
			return "broken_type_reference"
	for a in s.ability_ids:
		if not _ability_catalog.has(a):
			return "broken_ability_reference"
	for le in s.learnset:
		if le is LearnSetEntry and not _move_catalog.has((le as LearnSetEntry).move_id):
			return "broken_move_reference"
	return ""

func _report_once(report: DataImportReport, key: String) -> void:
	if not report.unsupported_mechanics.has(key):
		report.unsupported_mechanics.append(key)

func _dedup(arr: Array) -> Array:
	var out: Array = []
	for x in arr:
		if not out.has(x):
			out.append(x)
	return out
