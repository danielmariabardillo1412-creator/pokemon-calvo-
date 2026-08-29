class_name WildEncounterSlot
extends RefCounted

var slot_id: StringName = &""
var species_id: StringName = &""
var weight: int = 1
var min_level: int = 1
var max_level: int = 1
var corrupted: bool = false
var corruption_reason: String = ""


func _init(
	p_slot_id: StringName = &"",
	p_species_id: StringName = &"",
	p_weight: int = 1,
	p_min_level: int = 1,
	p_max_level: int = 1,
) -> void:
	slot_id = p_slot_id
	species_id = p_species_id
	weight = p_weight
	min_level = p_min_level
	max_level = p_max_level


func to_dict() -> Dictionary:
	return {
		"slot_id": String(slot_id),
		"species_id": String(species_id),
		"weight": weight,
		"min_level": min_level,
		"max_level": max_level,
	}


static func from_dict(d: Dictionary) -> WildEncounterSlot:
	var slot := WildEncounterSlot.new()
	var parsed_slot_id := _read_id(d, "slot_id")
	if not parsed_slot_id.ok:
		return _corrupt(slot, parsed_slot_id.reason)
	var parsed_species_id := _read_id(d, "species_id")
	if not parsed_species_id.ok:
		return _corrupt(slot, parsed_species_id.reason)
	var parsed_weight := _read_int(d, "weight")
	if not parsed_weight.ok:
		return _corrupt(slot, parsed_weight.reason)
	var parsed_min := _read_int(d, "min_level")
	if not parsed_min.ok:
		return _corrupt(slot, parsed_min.reason)
	var parsed_max := _read_int(d, "max_level")
	if not parsed_max.ok:
		return _corrupt(slot, parsed_max.reason)

	slot.slot_id = parsed_slot_id.value
	slot.species_id = parsed_species_id.value
	slot.weight = parsed_weight.value
	slot.min_level = parsed_min.value
	slot.max_level = parsed_max.value
	var v := slot.validate()
	if not v.ok:
		return _corrupt(slot, v.reason)
	return slot


func validate(catalogs = null) -> Dictionary:
	if corrupted:
		return {"ok": false, "reason": corruption_reason}
	if slot_id == &"":
		return {"ok": false, "reason": "empty_slot_id"}
	if species_id == &"":
		return {"ok": false, "reason": "empty_species_id"}
	if not WildEncounterRuleset.is_valid_weight(weight):
		return {"ok": false, "reason": "invalid_weight"}
	if not WildEncounterRuleset.is_valid_level(min_level) or not WildEncounterRuleset.is_valid_level(max_level):
		return {"ok": false, "reason": "invalid_level_range"}
	if min_level > max_level:
		return {"ok": false, "reason": "invalid_level_range"}
	if catalogs != null:
		if catalogs.species_catalog == null or not catalogs.species_catalog.has(species_id):
			return {"ok": false, "reason": "unknown_species"}
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


static func _corrupt(slot: WildEncounterSlot, reason: String) -> WildEncounterSlot:
	slot.corrupted = true
	slot.corruption_reason = reason
	return slot
