extends RefCounted
## IA3/W03 AUTORUN V2: player's *successful* caught base-species ledger.
## No party/storage inference; catalog is authoritative for forms and base species.
const VERSION := 1

static func canonical_id(raw_id: StringName, catalogs: DefinitionCatalog) -> StringName:
	if catalogs == null or raw_id == &"": return &""
	var species: CreatureSpecies = catalogs.species(raw_id)
	if species == null: return &""
	var raw_base: Variant = species.source_metadata.get("base_species_id", String(raw_id))
	if not (raw_base is String or raw_base is StringName): return &""
	var base := StringName(raw_base)
	if base == &"" or catalogs.species(base) == null: return &""
	return base

static func has_caught(ledger: Array[StringName], raw_id: StringName, catalogs: DefinitionCatalog) -> bool:
	var base := canonical_id(raw_id, catalogs)
	return base != &"" and ledger.has(base)

static func record(ledger: Array[StringName], raw_id: StringName, catalogs: DefinitionCatalog) -> bool:
	var base := canonical_id(raw_id, catalogs)
	if base == &"": return false
	if not ledger.has(base):
		ledger.append(base)
		ledger.sort()
	return true

static func encode(ledger: Array[StringName]) -> Dictionary:
	var ids: Array[String] = []
	for id: StringName in ledger: ids.append(String(id))
	ids.sort()
	return {"schema_version": VERSION, "ids": ids}

static func parse(payload: Variant) -> Dictionary:
	if not payload is Dictionary: return {"ok": false, "reason": "caught_history_type"}
	var version: Variant = payload.get("schema_version", null)
	if not (version is int or version is float) or version != VERSION:
		return {"ok": false, "reason": "caught_history_version"}
	var ids: Variant = payload.get("ids", null)
	if not ids is Array: return {"ok": false, "reason": "caught_history_ids"}
	var result: Array[StringName] = []
	var seen := {}
	for value: Variant in ids:
		if not value is String or value.is_empty() or value.strip_edges() != value:
			return {"ok": false, "reason": "caught_history_entry"}
		var id := StringName(value)
		if seen.has(id): return {"ok": false, "reason": "caught_history_duplicate"}
		seen[id] = true
		result.append(id)
		if result.size() > 100000: return {"ok": false, "reason": "caught_history_capacity"}
	result.sort()
	return {"ok": true, "ids": result}

static func validate_catalog(ledger: Array[StringName], catalogs: DefinitionCatalog) -> bool:
	for id: StringName in ledger:
		if canonical_id(id, catalogs) != id: return false
	return true
