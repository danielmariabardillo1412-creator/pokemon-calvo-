class_name PlayerInventory
extends RefCounted

# Sparse, deterministic item bag keyed by stable item_id. Counts are mutable player state;
# item definitions remain immutable in ItemCatalog. No UI, Nodes, autoloads, filesystem or RNG.

var ruleset: InventoryRuleset = InventoryRuleset.new()
var corrupted: bool = false
var corruption_reason: String = ""
var _quantities: Dictionary = {}


func quantity(item_id: StringName) -> int:
	return int(_quantities.get(item_id, 0))


func has(item_id: StringName, amount: int = 1) -> bool:
	if not InventoryRuleset.is_valid_item_id(item_id) or amount <= 0:
		return false
	return quantity(item_id) >= amount


func add(item_id: StringName, amount: int = 1) -> bool:
	if not InventoryRuleset.is_valid_item_id(item_id) or amount <= 0:
		return false
	var next := quantity(item_id) + amount
	if not InventoryRuleset.is_valid_stored_quantity(next):
		return false
	_quantities[item_id] = next
	return true


func remove(item_id: StringName, amount: int = 1) -> bool:
	if not InventoryRuleset.is_valid_item_id(item_id) or amount <= 0:
		return false
	var current := quantity(item_id)
	if current < amount:
		return false
	var next := current - amount
	if next <= 0:
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = next
	return true


func set_quantity(item_id: StringName, amount: int) -> bool:
	if not InventoryRuleset.is_valid_item_id(item_id) or not InventoryRuleset.is_valid_quantity(amount):
		return false
	if amount == 0:
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = amount
	return true


func is_empty() -> bool:
	return _quantities.is_empty()


func item_count() -> int:
	return _quantities.size()


func clear() -> void:
	_quantities.clear()


func all_item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for raw_id in _quantities.keys():
		out.append(StringName(raw_id))
	# StringName ordering is not guaranteed to be lexical; sort by its stable text form so
	# serialization is deterministic across processes/platforms.
	out.sort_custom(func(a, b): return String(a) < String(b))
	return out


func to_dict() -> Dictionary:
	var quantities := {}
	for item_id in all_item_ids():
		quantities[String(item_id)] = quantity(item_id)
	return {
		"schema_version": InventoryRuleset.SCHEMA_VERSION,
		"ruleset_id": String(InventoryRuleset.ID),
		"quantities": quantities,
	}


# Strict standalone reconstruction. Invalid input is not silently repaired: a corrupt object is
# returned with an empty bag and an explicit reason so callers can reject the payload transactionally.
static func from_dict(d: Dictionary) -> PlayerInventory:
	var inv := PlayerInventory.new()

	# Validate untrusted metadata before casting. This method is used by savegame validation, so a
	# hostile but parseable JSON payload must become a corrupt inventory, never a runtime type error.
	var raw_version: Variant = d.get("schema_version", null)
	if raw_version == null:
		return _corrupt(inv, "missing_schema")
	if not (raw_version is int or raw_version is float):
		return _corrupt(inv, "invalid_schema_type")
	var version := int(raw_version)
	if float(version) != float(raw_version) or version <= 0:
		return _corrupt(inv, "invalid_schema_value")
	if version != InventoryRuleset.SCHEMA_VERSION:
		return _corrupt(inv, "unsupported_schema")

	var raw_ruleset: Variant = d.get("ruleset_id", null)
	if raw_ruleset == null:
		return _corrupt(inv, "missing_ruleset_id")
	if not (raw_ruleset is String or raw_ruleset is StringName):
		return _corrupt(inv, "invalid_ruleset_type")
	var ruleset_id := StringName(raw_ruleset)
	if ruleset_id == &"":
		return _corrupt(inv, "missing_ruleset_id")
	if ruleset_id != InventoryRuleset.ID:
		return _corrupt(inv, "unsupported_ruleset")

	var raw_quantities: Variant = d.get("quantities", null)
	if not (raw_quantities is Dictionary):
		return _corrupt(inv, "invalid_quantities_type")

	var staged := {}
	for raw_id in (raw_quantities as Dictionary).keys():
		if not (raw_id is String or raw_id is StringName):
			return _corrupt(inv, "invalid_item_id_type")
		var item_id := StringName(raw_id)
		if not InventoryRuleset.is_valid_item_id(item_id):
			return _corrupt(inv, "empty_item_id")
		var raw_amount: Variant = (raw_quantities as Dictionary)[raw_id]
		if not (raw_amount is int or raw_amount is float):
			return _corrupt(inv, "invalid_quantity_type")
		var amount := int(raw_amount)
		if float(amount) != float(raw_amount):
			return _corrupt(inv, "invalid_quantity_fraction")
		if not InventoryRuleset.is_valid_stored_quantity(amount):
			return _corrupt(inv, "invalid_quantity")
		if staged.has(item_id):
			return _corrupt(inv, "duplicate_item_id")
		staged[item_id] = amount

	inv._quantities = staged
	return inv


func validate() -> Dictionary:
	if corrupted:
		return {"ok": false, "reason": corruption_reason}
	for item_id in _quantities.keys():
		var sid := StringName(item_id)
		var amount := int(_quantities[item_id])
		if not InventoryRuleset.is_valid_item_id(sid):
			return {"ok": false, "reason": "empty_item_id"}
		if not InventoryRuleset.is_valid_stored_quantity(amount):
			return {"ok": false, "reason": "invalid_quantity"}
	return {"ok": true, "reason": ""}


static func _corrupt(inv: PlayerInventory, reason: String) -> PlayerInventory:
	inv.corrupted = true
	inv.corruption_reason = reason
	inv._quantities.clear()
	return inv
