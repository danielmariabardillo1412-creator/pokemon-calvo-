class_name WildEncounterTable
extends RefCounted

var schema_version: int = WildEncounterRuleset.SCHEMA_VERSION
var ruleset_id: StringName = WildEncounterRuleset.ID
var zone_id: StringName = &""
var encounter_chance_bp: int = 10000
var slots: Array[WildEncounterSlot] = []
var corrupted: bool = false
var corruption_reason: String = ""


func _init(p_zone_id: StringName = &"", p_encounter_chance_bp: int = 10000) -> void:
	zone_id = p_zone_id
	encounter_chance_bp = p_encounter_chance_bp


func add_slot(slot: WildEncounterSlot) -> bool:
	if slot == null:
		return false
	if not slot.validate().ok:
		return false
	for existing in slots:
		if existing.slot_id == slot.slot_id:
			return false
	slots.append(slot)
	return true


func total_weight() -> int:
	var total := 0
	for slot in slots:
		total += slot.weight
	return total


func to_dict() -> Dictionary:
	var serialized_slots: Array = []
	for slot in slots:
		serialized_slots.append(slot.to_dict())
	return {
		"schema_version": schema_version,
		"ruleset_id": String(ruleset_id),
		"zone_id": String(zone_id),
		"encounter_chance_bp": encounter_chance_bp,
		"slots": serialized_slots,
	}


static func from_dict(d: Dictionary) -> WildEncounterTable:
	var table := WildEncounterTable.new()

	var parsed_version := _read_int(d, "schema_version")
	if not parsed_version.ok:
		return _corrupt(table, parsed_version.reason)
	table.schema_version = parsed_version.value

	var parsed_ruleset := _read_id(d, "ruleset_id")
	if not parsed_ruleset.ok:
		return _corrupt(table, parsed_ruleset.reason)
	table.ruleset_id = parsed_ruleset.value

	var parsed_zone := _read_id(d, "zone_id")
	if not parsed_zone.ok:
		return _corrupt(table, parsed_zone.reason)
	table.zone_id = parsed_zone.value

	var parsed_chance := _read_int(d, "encounter_chance_bp")
	if not parsed_chance.ok:
		return _corrupt(table, parsed_chance.reason)
	table.encounter_chance_bp = parsed_chance.value

	var raw_slots: Variant = d.get("slots", null)
	if not (raw_slots is Array):
		return _corrupt(table, "invalid_slots_type")
	for raw_slot in raw_slots:
		if not (raw_slot is Dictionary):
			return _corrupt(table, "invalid_slot_entry")
		var slot := WildEncounterSlot.from_dict(raw_slot as Dictionary)
		if slot.corrupted:
			return _corrupt(table, "slot_" + slot.corruption_reason)
		table.slots.append(slot)

	var v := table.validate()
	if not v.ok:
		return _corrupt(table, v.reason)
	return table


func validate(catalogs = null) -> Dictionary:
	if corrupted:
		return {"ok": false, "reason": corruption_reason}
	if schema_version != WildEncounterRuleset.SCHEMA_VERSION:
		return {"ok": false, "reason": "unsupported_schema"}
	if ruleset_id != WildEncounterRuleset.ID:
		return {"ok": false, "reason": "unsupported_ruleset"}
	if zone_id == &"":
		return {"ok": false, "reason": "empty_zone_id"}
	if not WildEncounterRuleset.is_valid_chance_bp(encounter_chance_bp):
		return {"ok": false, "reason": "invalid_encounter_chance"}
	if slots.is_empty():
		return {"ok": false, "reason": "empty_encounter_table"}

	var seen := {}
	var total := 0
	for slot in slots:
		if slot == null:
			return {"ok": false, "reason": "null_slot"}
		var sv := slot.validate(catalogs)
		if not sv.ok:
			return {"ok": false, "reason": "slot_" + String(sv.reason)}
		if seen.has(slot.slot_id):
			return {"ok": false, "reason": "duplicate_slot_id"}
		seen[slot.slot_id] = true
		total += slot.weight
		if total > WildEncounterRuleset.MAX_TOTAL_WEIGHT:
			return {"ok": false, "reason": "total_weight_overflow"}
	if total <= 0:
		return {"ok": false, "reason": "invalid_total_weight"}
	return {"ok": true, "reason": ""}


static func _read_id(d: Dictionary, key: String) -> Dictionary:
	if not d.has(key):
		return {"ok": false, "reason": "missing_" + key, "value": &""}
	var raw: Variant = d[key]
	if not (raw is String or raw is StringName):
		return {"ok": false, "reason": "invalid_" + key + "_type", "value": &""}
	var value := StringName(raw)
	if value == &"":
		return {"ok": false, "reason": "empty_" + key, "value": &""}
	return {"ok": true, "reason": "", "value": value}


static func _read_int(d: Dictionary, key: String) -> Dictionary:
	if not d.has(key):
		return {"ok": false, "reason": "missing_" + key, "value": 0}
	var raw: Variant = d[key]
	if not (raw is int or raw is float):
		return {"ok": false, "reason": "invalid_" + key + "_type", "value": 0}
	var value := int(raw)
	if float(value) != float(raw):
		return {"ok": false, "reason": "invalid_" + key + "_fraction", "value": 0}
	return {"ok": true, "reason": "", "value": value}


static func _corrupt(table: WildEncounterTable, reason: String) -> WildEncounterTable:
	table.corrupted = true
	table.corruption_reason = reason
	table.slots.clear()
	return table
