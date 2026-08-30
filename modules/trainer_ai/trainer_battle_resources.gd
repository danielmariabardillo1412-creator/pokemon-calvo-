class_name TrainerBattleResources
extends RefCounted

# Finite, side-owned consumable stock for one trainer battle loadout.
# This is deliberately NOT the global item catalog: an NPC can only use what is
# explicitly present here. FASE 30 will make supported entries actionable.

const SCHEMA_VERSION := 1

var _quantities: Dictionary = {}


func quantity(item_id: StringName) -> int:
	return int(_quantities.get(item_id, 0))


func has(item_id: StringName, amount: int = 1) -> bool:
	return InventoryRuleset.is_valid_item_id(item_id) and amount > 0 and quantity(item_id) >= amount


func set_quantity(item_id: StringName, amount: int) -> bool:
	if not InventoryRuleset.is_valid_item_id(item_id) or not InventoryRuleset.is_valid_quantity(amount):
		return false
	if amount == 0:
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = amount
	return true


func add(item_id: StringName, amount: int = 1) -> bool:
	if not InventoryRuleset.is_valid_item_id(item_id) or amount <= 0:
		return false
	var next := quantity(item_id) + amount
	if not InventoryRuleset.is_valid_stored_quantity(next):
		return false
	_quantities[item_id] = next
	return true


func consume(item_id: StringName, amount: int = 1) -> bool:
	if not has(item_id, amount):
		return false
	return set_quantity(item_id, quantity(item_id) - amount)


func distinct_item_count() -> int:
	return _quantities.size()


func total_uses() -> int:
	var total := 0
	for amount in _quantities.values():
		total += int(amount)
	return total


func is_empty() -> bool:
	return _quantities.is_empty()


func all_item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for raw_id in _quantities.keys():
		out.append(StringName(raw_id))
	out.sort_custom(func(a, b): return String(a) < String(b))
	return out


func to_dict() -> Dictionary:
	var quantities: Dictionary = {}
	for item_id in all_item_ids():
		quantities[String(item_id)] = quantity(item_id)
	return {
		"schema_version": SCHEMA_VERSION,
		"quantities": quantities,
	}


func duplicate_resources() -> TrainerBattleResources:
	return TrainerBattleResources.from_dict(to_dict())


func validate() -> Dictionary:
	for item_id in _quantities.keys():
		var sid := StringName(item_id)
		var amount := int(_quantities[item_id])
		if not InventoryRuleset.is_valid_item_id(sid):
			return {"ok": false, "reason": "invalid_item_id"}
		if not InventoryRuleset.is_valid_stored_quantity(amount):
			return {"ok": false, "reason": "invalid_quantity"}
	return {"ok": true, "reason": ""}


static func from_dict(data: Dictionary) -> TrainerBattleResources:
	var out := TrainerBattleResources.new()
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return out
	var raw_quantities: Variant = data.get("quantities", {})
	if not (raw_quantities is Dictionary):
		return out
	var keys := (raw_quantities as Dictionary).keys()
	keys.sort_custom(func(a, b): return String(a) < String(b))
	for raw_id in keys:
		var item_id := StringName(raw_id)
		var amount := int((raw_quantities as Dictionary).get(raw_id, 0))
		if InventoryRuleset.is_valid_item_id(item_id) and InventoryRuleset.is_valid_stored_quantity(amount):
			out._quantities[item_id] = amount
	return out
