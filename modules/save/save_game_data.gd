class_name SaveGameData
extends RefCounted

# Pure, serializable snapshot of the player's savegame (V2). The creature registry is CANONICAL:
# each creature is stored exactly once under `creatures`; party and storage layouts reference them
# by instance_id. Inventory is separate mutable player state and is serialized once under `inventory`.
#
# This class never creates CreatureInstance objects; it only carries dictionaries. Reconstruction
# (and explicit V1 -> V2 migration) lives outside this value object.

const CURRENT_VERSION := 2
const FORMAT_ID := &"calvo_save_v2"

var schema_version: int = CURRENT_VERSION
var format_id: StringName = FORMAT_ID
# Stored as Variant on purpose: malformed saves must be REJECTED by validate(), never crash the
# loader before validation because a JSON field has an unexpected shape.
var creatures: Variant = []
var party_layout: Variant = {}
var storage_layout: Variant = {}
var inventory_layout: Variant = {}


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"format_id": String(format_id),
		"creatures": creatures,
		"party": party_layout,
		"storage": storage_layout,
		"inventory": inventory_layout,
	}


static func from_dict(d: Dictionary) -> SaveGameData:
	var snap := SaveGameData.new()
	snap.schema_version = int(d.get("schema_version", 0))
	snap.format_id = StringName(d.get("format_id", ""))
	snap.creatures = d.get("creatures", [])
	snap.party_layout = d.get("party", {})
	snap.storage_layout = d.get("storage", {})
	# Missing inventory is deliberately distinct from an empty inventory. V2 requires the field;
	# only the explicit V1 migrator is allowed to synthesize an empty bag.
	snap.inventory_layout = d.get("inventory", null)
	return snap


# Assemble a V2 snapshot from live state. Caller must check `validate()` before persisting.
# The optional inventory keeps the lower-level save_state API source-compatible; callers that own a
# PlayerCollection should use save_collection(), which always passes its real inventory.
static func build(party: CreatureParty, storage: CreatureStorage, inventory: PlayerInventory = null) -> SaveGameData:
	var snap := SaveGameData.new()
	for c in party.get_creatures():
		snap.creatures.append((c as CreatureInstance).to_dict())
	for c in storage.get_all_creatures():
		snap.creatures.append((c as CreatureInstance).to_dict())
	# Party layout is a REFERENCE layout only; canonical creature data lives in `creatures`.
	snap.party_layout = {
		"schema_version": party.party_ruleset.SCHEMA_VERSION,
		"ruleset_id": String(party.party_ruleset.ID),
		"ordered_instance_ids": party.get_ordered_ids().duplicate(),
	}
	snap.storage_layout = storage.to_dict()
	var actual_inventory := inventory if inventory != null else PlayerInventory.new()
	snap.inventory_layout = actual_inventory.to_dict()
	return snap


# Structural validation. Returns {ok: bool, reason: String}.
func validate() -> Dictionary:
	# --- format/schema: migration is NOT performed here ---
	if format_id == &"":
		return {"ok": false, "reason": "missing_format_id"}
	if format_id != FORMAT_ID:
		return {"ok": false, "reason": "unsupported_format"}
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
	if not (inventory_layout is Dictionary):
		return {"ok": false, "reason": "invalid_inventory_type"}

	# --- inventory domain contract ---
	var inv := PlayerInventory.from_dict(inventory_layout as Dictionary)
	var inv_validation := inv.validate()
	if not inv_validation.ok:
		return {"ok": false, "reason": "inventory_" + String(inv_validation.reason)}

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

	# --- party layout: corrupt/duplicate/over-capacity party is rejected, never repaired ---
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
		var raw_slots: Variant = boxd.get("slots", [])
		if not (raw_slots is Array):
			return {"ok": false, "reason": "invalid_storage_slot"}
		var slots: Array = raw_slots
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
