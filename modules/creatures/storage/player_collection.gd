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


# Convenience: which creature container currently owns the instance (or null).
func location_of(instance_id: StringName) -> StringName:
	if party.contains_instance_id(instance_id):
		return &"PARTY"
	if storage.contains_instance_id(instance_id):
		return &"STORAGE"
	return &""
