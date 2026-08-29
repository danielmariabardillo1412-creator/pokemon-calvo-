class_name SaveGameRepository
extends RefCounted

# Build/validate/persist and transactionally load the savegame. DOMAIN (snapshot building +
# validation + reconstruction) is kept separate from IO (SaveGameSerializer). Load is all-or-nothing:
# it returns a LoadResult only when the whole file is valid, never a partially mutated state.

var _serializer: SaveGameSerializer = SaveGameSerializer.new()


func save_state(path: String, party: CreatureParty, storage: CreatureStorage) -> SaveResult:
	var snap := SaveGameData.build(party, storage)
	var v := snap.validate()
	if not v.ok:
		var r := SaveResult.new()
		r.reason = v.reason
		return r
	return _serializer.write_atomic(path, snap)


func save_collection(path: String, pc: PlayerCollection) -> SaveResult:
	return save_state(path, pc.party, pc.storage)


# Transactional load. Returns ok=false (with reason) on any structural/validation failure.
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

	var snap := SaveGameData.from_dict(d)
	var v := snap.validate()
	if not v.ok:
		out.reason = v.reason
		return out

	# 1) canonical creature registry (each instance built exactly once).
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

	# 2) rebuild party (references only).
	var party := CreatureParty.new()
	for sid in snap.party_layout.get("ordered_instance_ids", []):
		var id := StringName(sid)
		var c := reg.get(id, null) as CreatureInstance
		if c == null:
			out.reason = "missing_creature_reference"
			return out
		party.add_creature(c)

	# 3) rebuild storage (references only), guarding cross-box duplication.
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

	out.ok = true
	out.schema_version = snap.schema_version
	out.party = party
	out.storage = storage
	return out
