class_name SaveGameRepository
extends RefCounted

# Build/validate/persist and transactionally load the savegame. DOMAIN (snapshot building,
# migration, validation and reconstruction) is kept separate from IO (SaveGameSerializer).
# Load is all-or-nothing: party, storage and inventory are published only after every component is
# valid. Legacy V1 is migrated in memory; load never rewrites the source file.

var _serializer: SaveGameSerializer = SaveGameSerializer.new()


func save_state(path: String, party: CreatureParty, storage: CreatureStorage, inventory: PlayerInventory = null) -> SaveResult:
	var actual_inventory := inventory if inventory != null else PlayerInventory.new()
	var inv_validation := actual_inventory.validate()
	if not inv_validation.ok:
		var invalid_inventory := SaveResult.new()
		invalid_inventory.reason = "inventory_" + String(inv_validation.reason)
		return invalid_inventory

	var snap := SaveGameData.build(party, storage, actual_inventory)
	var v := snap.validate()
	if not v.ok:
		var r := SaveResult.new()
		r.reason = v.reason
		return r
	return _serializer.write_atomic(path, snap)


func save_collection(path: String, pc: PlayerCollection) -> SaveResult:
	return save_state(path, pc.party, pc.storage, pc.inventory)


# Transactional load. Returns ok=false (with reason) on any migration/validation/rebuild failure.
func load(path: String) -> LoadResult:
	var out := LoadResult.new()
	var raw := _serializer.read_raw(path)
	if raw == "":
		out.reason = "missing_file"
		return out
	var d = _serializer.parse(raw)
	if d == null or not (d is Dictionary):
		out.reason = "json_parse_error"
		return out

	# Normalize the exact legacy format before constructing a V2 snapshot. No other historic/future
	# shape is guessed or silently repaired.
	var migration := SaveGameMigration.normalize(d as Dictionary)
	if not migration.ok:
		out.reason = migration.reason
		return out

	var snap := SaveGameData.from_dict(migration.data as Dictionary)
	var v := snap.validate()
	if not v.ok:
		out.reason = v.reason
		return out

	# 1) inventory. Reconstruct before creatures so a bad bag aborts as early as possible.
	var inventory := PlayerInventory.from_dict(snap.inventory_layout as Dictionary)
	var inv_validation := inventory.validate()
	if not inv_validation.ok:
		out.reason = "inventory_" + String(inv_validation.reason)
		return out

	# 2) canonical creature registry (each instance built exactly once).
	var reg: Dictionary = {}
	for cd in snap.creatures:
		var c := CreatureInstance.from_dict(cd)
		if c.instance_id == &"":
			out.reason = "invalid_creature_id"
			return out
		if reg.has(c.instance_id):
			out.reason = "duplicate_creature_id"
			return out
		reg[c.instance_id] = c

	# 3) rebuild party (references only).
	var party := CreatureParty.new()
	for sid in snap.party_layout.get("ordered_instance_ids", []):
		var id := StringName(sid)
		var c := reg.get(id, null) as CreatureInstance
		if c == null:
			out.reason = "missing_creature_reference"
			return out
		if not party.add_creature(c):
			out.reason = "party_rebuild_failed"
			return out

	# 4) rebuild storage (references only), guarding cross-box duplication.
	var storage := CreatureStorage.new()
	var seen_storage := {}
	for boxd in snap.storage_layout.get("boxes", []):
		var box := StorageBox.from_dict(boxd, reg)
		if box.corrupted:
			out.reason = "invalid_storage_slot"
			return out
		for s in box.slots():
			var c := s as CreatureInstance
			if c != null:
				if seen_storage.has(c.instance_id):
					out.reason = "double_ownership"
					return out
				seen_storage[c.instance_id] = true
		storage._boxes.append(box)

	# Publish only after every V2 component is valid and fully rebuilt.
	out.ok = true
	out.schema_version = snap.schema_version
	out.migrated_from_version = int(migration.migrated_from_version)
	out.party = party
	out.storage = storage
	out.inventory = inventory
	return out
