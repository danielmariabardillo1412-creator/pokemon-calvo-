class_name LoadResult
extends RefCounted

var ok: bool = false
var reason: String = ""
var schema_version: int = 0
# 0 means the file was already current. 1 means legacy Savegame V1 was migrated in-memory.
var migrated_from_version: int = 0
var party: CreatureParty = null
var storage: CreatureStorage = null
var inventory: PlayerInventory = null
