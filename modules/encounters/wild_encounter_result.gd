class_name WildEncounterResult
extends RefCounted

const INVALID := &"INVALID"
const NONE := &"NONE"
const ENCOUNTER := &"ENCOUNTER"

var status: StringName = INVALID
var reason: String = ""
var zone_id: StringName = &""
var slot_id: StringName = &""
var species_id: StringName = &""
var level: int = 0
var creature: CreatureInstance = null


func to_dict() -> Dictionary:
	return {
		"status": String(status),
		"reason": reason,
		"zone_id": String(zone_id),
		"slot_id": String(slot_id),
		"species_id": String(species_id),
		"level": level,
		"creature_instance_id": String(creature.instance_id) if creature != null else "",
	}
