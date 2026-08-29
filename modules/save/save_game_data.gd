class_name SaveGameData
extends RefCounted

# Pure, serializable snapshot of the player's savegame (V1). The creature registry is CANONICAL:
# each creature is stored exactly once under `creatures`; party and storage layouts reference them
# by instance_id. This guarantees a creature exists conceptually once in the player's state.
#
# This class never creates CreatureInstance objects; it only carries dictionaries. Reconstruction
# (and the creature registry build) lives in SaveGameRepository.

const CURRENT_VERSION := 1
const FORMAT_ID := &"calvo_save_v1"

var schema_version: int = CURRENT_VERSION
var format_id: StringName = FORMAT_ID
var creatures: Array = []                # canonical registry (instance_id -> creature data)
var party_layout: Dictionary = {}         # { schema_version, ruleset_id, ordered_instance_ids }
var storage_layout: Dictionary = {}       # { schema_version, ruleset_id, boxes: [{box_id,name,capacity,slots}] }


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"format_id": String(format_id),
		"creatures": creatures,
		"party": party_layout,
		"storage": storage_layout,
	}


static func from_dict(d: Dictionary) -> SaveGameData:
	var snap := SaveGameData.new()
	snap.schema_version = int(d.get("schema_version", 0))
	snap.format_id = StringName(d.get("format_id", ""))
	snap.creatures = d.get("creatures", [])
	snap.party_layout = d.get("party", {})
	snap.storage_layout = d.get("storage", {})
	return snap


# Assemble a snapshot from live state. Caller must check `validate()` before persisting.
static func build(party: CreatureParty, storage: CreatureStorage) -> SaveGameData:
	var snap := SaveGameData.new()
	for c in party.get_creatures():
		snap.creatures.append((c as CreatureInstance).to_dict())
	for c in storage.get_all_creatures():
		snap.creatures.append((c as CreatureInstance).to_dict())
	# Party layout is a REFERENCE layout only (ordered instance_ids); the canonical creature
	# data lives in `creatures`. This guarantees a creature exists once in the savegame.
	snap.party_layout = {
		"schema_version": party.party_ruleset.SCHEMA_VERSION,
		"ruleset_id": String(party.party_ruleset.ID),
		"ordered_instance_ids": party.get_ordered_ids().duplicate(),
	}
	snap.storage_layout = storage.to_dict()
	return snap


# Structural validation. Returns {ok: bool, reason: String}.
# Reasons: missing_schema, unsupported_schema, duplicate_creature_id, missing_creature_reference,
# double_ownership, invalid_storage_slot.
func validate() -> Dictionary:
	if schema_version != CURRENT_VERSION:
		if schema_version > CURRENT_VERSION:
			return {"ok": false, "reason": "unsupported_schema"}
		return {"ok": false, "reason": "missing_schema"}

	var ids := {}
	for cd in creatures:
		var id := StringName(cd.get("instance_id", ""))
		if ids.has(id):
			return {"ok": false, "reason": "duplicate_creature_id"}
		ids[id] = true

	var party_ids := {}
	for sid in party_layout.get("ordered_instance_ids", []):
		var id := StringName(sid)
		if not ids.has(id):
			return {"ok": false, "reason": "missing_creature_reference"}
		party_ids[id] = true

	var storage_ids := {}
	for boxd in storage_layout.get("boxes", []):
		var slots: Array = boxd.get("slots", [])
		if int(boxd.get("capacity", 0)) != slots.size():
			return {"ok": false, "reason": "invalid_storage_slot"}
		for sid in slots:
			if sid == null:
				continue
			var id := StringName(sid)
			if not ids.has(id):
				return {"ok": false, "reason": "missing_creature_reference"}
			if storage_ids.has(id):
				return {"ok": false, "reason": "double_ownership"}
			storage_ids[id] = true

	for pid in party_ids.keys():
		if storage_ids.has(pid):
			return {"ok": false, "reason": "double_ownership"}

	return {"ok": true, "reason": ""}
