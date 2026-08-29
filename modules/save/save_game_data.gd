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
# Stored as Variant (not Array/Dictionary) on purpose: a malformed save must be REJECTED by
# validate(), never crash the loader. With strict types, assigning a wrong-shaped value inside
# from_dict would raise a SCRIPT ERROR before validation ever runs.
var creatures: Variant = []                # canonical registry (instance_id -> creature data)
var party_layout: Variant = {}             # { schema_version, ruleset_id, ordered_instance_ids }
var storage_layout: Variant = {}           # { schema_version, ruleset_id, boxes: [{box_id,name,capacity,slots}] }


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
# Reasons: missing_format_id, unsupported_format, missing_schema, unsupported_schema,
# invalid_creatures_type, invalid_party_type, invalid_storage_type, invalid_boxes_type,
# empty_creature_instance_id, duplicate_creature_id, invalid_party_layout, empty_party_instance_id,
# duplicate_party_instance_id, party_over_capacity, missing_creature_reference, invalid_storage_slot,
# double_ownership.
func validate() -> Dictionary:
	# --- format id: a save from a different format must never be silently loaded ---
	if format_id == &"":
		return {"ok": false, "reason": "missing_format_id"}
	if format_id != FORMAT_ID:
		return {"ok": false, "reason": "unsupported_format"}

	# --- schema version: older saves cannot be upgraded here; only FASE 8 schema is accepted ---
	if schema_version != CURRENT_VERSION:
		if schema_version > CURRENT_VERSION:
			return {"ok": false, "reason": "unsupported_schema"}
		return {"ok": false, "reason": "missing_schema"}

	# --- structural types ---
	if not (creatures is Array):
		return {"ok": false, "reason": "invalid_creatures_type"}
	if not (party_layout is Dictionary):
		return {"ok": false, "reason": "invalid_party_type"}
	if not (storage_layout is Dictionary):
		return {"ok": false, "reason": "invalid_storage_type"}

	# --- canonical creature registry (each instance stored exactly once) ---
	var ids := {}
	for cd in creatures:
		if not (cd is Dictionary):
			return {"ok": false, "reason": "invalid_creature_entry"}
		var id := StringName(cd.get("instance_id", ""))
		if id == &"":
			return {"ok": false, "reason": "empty_creature_instance_id"}
		if ids.has(id):
			return {"ok": false, "reason": "duplicate_creature_id"}
		ids[id] = true

	# --- party layout: a corrupt/duplicate/over-capacity party is rejected (never accepted silently) ---
	var ordered: Variant = party_layout.get("ordered_instance_ids", [])
	if not (ordered is Array):
		return {"ok": false, "reason": "invalid_party_layout"}
	if ordered.size() > PartyRuleset.MAX_PARTY:
		return {"ok": false, "reason": "party_over_capacity"}
	var party_ids := {}
	for sid in ordered:
		var id := StringName(sid)
		if id == &"":
			return {"ok": false, "reason": "empty_party_instance_id"}
		if party_ids.has(id):
			return {"ok": false, "reason": "duplicate_party_instance_id"}
		if not ids.has(id):
			return {"ok": false, "reason": "missing_creature_reference"}
		party_ids[id] = true

	# --- storage layout ---
	var boxes: Variant = storage_layout.get("boxes", [])
	if not (boxes is Array):
		return {"ok": false, "reason": "invalid_boxes_type"}
	var storage_ids := {}
	for boxd in boxes:
		if not (boxd is Dictionary):
			return {"ok": false, "reason": "invalid_box_entry"}
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

	# --- a creature cannot be owned by both party and storage ---
	for pid in party_ids.keys():
		if storage_ids.has(pid):
			return {"ok": false, "reason": "double_ownership"}

	return {"ok": true, "reason": ""}
