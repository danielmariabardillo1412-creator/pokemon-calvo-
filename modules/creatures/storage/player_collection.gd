class_name PlayerCollection
extends RefCounted

# Aggregate holding the player's live party + storage + inventory. Owns the deposit/withdraw
# operations that MOVE a CreatureInstance between party and storage while preserving its identity
# (same object). Inventory is independent mutable player state and is persisted by SaveGame V2.
# Neither party nor storage ever creates/rerolls the creature; this aggregate just relocates it.

var party: CreatureParty = CreatureParty.new()
var storage: CreatureStorage = CreatureStorage.new()
var inventory: PlayerInventory = PlayerInventory.new()


# PARTY -> STORAGE. Same CreatureInstance, removed from party and added to storage.
# Rolls back if storage cannot accept it (no loss).
func deposit(instance_id: StringName) -> bool:
	var c := party.get_creature(instance_id)
	if c == null:
		return false
	if not party.remove_creature(instance_id):
		return false
	if not storage.add_creature(c):
		party.add_creature(c)  # rollback
		return false
	return true


# STORAGE -> PARTY. Only if party is not full. Same CreatureInstance, removed from storage and
# added to party. Rolls back if party cannot accept it (no duplication).
func withdraw(instance_id: StringName) -> bool:
	if party.is_full():
		return false
	var c := storage.get_creature(instance_id)
	if c == null:
		return false
	if not storage.remove_creature(instance_id):
		return false
	if not party.add_creature(c):
		storage.add_creature(c)  # rollback
		return false
	return true


# Return the currently owned object regardless of whether it lives in Party or Storage.
# If ownership is corrupt (same id in both), return null so callers cannot silently pick one copy.
func owned_creature(instance_id: StringName) -> CreatureInstance:
	var in_party := party.contains_instance_id(instance_id)
	var in_storage := storage.contains_instance_id(instance_id)
	if in_party == in_storage:
		return null
	return party.get_creature(instance_id) if in_party else storage.get_creature(instance_id)


# EvolutionSystem intentionally returns a NEW CreatureInstance with the SAME instance_id. Replace
# the object in exactly the container that owns that identity while preserving Party order or the
# exact Storage box/slot. Refuse missing ownership or double-ownership instead of guessing.
func replace_owned_same_identity(creature: CreatureInstance) -> bool:
	if creature == null or creature.instance_id == &"":
		return false
	var in_party := party.contains_instance_id(creature.instance_id)
	var in_storage := storage.contains_instance_id(creature.instance_id)
	if in_party == in_storage:
		return false
	if in_party:
		return party.replace_same_identity(creature)
	return storage.replace_same_identity(creature)


# Convenience: which creature container currently owns the instance (or empty).
func location_of(instance_id: StringName) -> StringName:
	var in_party := party.contains_instance_id(instance_id)
	var in_storage := storage.contains_instance_id(instance_id)
	if in_party and not in_storage:
		return &"PARTY"
	if in_storage and not in_party:
		return &"STORAGE"
	return &""
