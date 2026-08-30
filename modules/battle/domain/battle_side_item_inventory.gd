class_name BattleSideItemInventory
extends RefCounted

# Battle-scoped, finite trainer resources. This is intentionally separate from
# PlayerInventory: Battle Core must be able to snapshot/fork trainer items without
# depending on player persistence or giving AI brains mutable inventory references.

var _quantities: Dictionary = {}


func quantity(item_id: StringName) -> int:
	return int(_quantities.get(item_id, 0))


func has(item_id: StringName, amount: int = 1) -> bool:
	return item_id != &"" and amount > 0 and quantity(item_id) >= amount


func set_quantity(item_id: StringName, amount: int) -> bool:
	if item_id == &"" or amount < 0:
		return false
	if amount == 0:
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = amount
	return true


func add(item_id: StringName, amount: int = 1) -> bool:
	if item_id == &"" or amount <= 0:
		return false
	_quantities[item_id] = quantity(item_id) + amount
	return true


func consume(item_id: StringName, amount: int = 1) -> bool:
	if not has(item_id, amount):
		return false
	return set_quantity(item_id, quantity(item_id) - amount)


func all_item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for raw_id in _quantities.keys():
		out.append(StringName(raw_id))
	out.sort_custom(func(a, b): return String(a) < String(b))
	return out


func is_empty() -> bool:
	return _quantities.is_empty()


func to_dict() -> Dictionary:
	var quantities: Dictionary = {}
	for item_id in all_item_ids():
		quantities[String(item_id)] = quantity(item_id)
	return {"quantities": quantities}


static func from_dict(data: Dictionary) -> BattleSideItemInventory:
	var inventory := BattleSideItemInventory.new()
	var raw_quantities: Variant = data.get("quantities", {})
	if not (raw_quantities is Dictionary):
		return inventory
	for raw_id in (raw_quantities as Dictionary).keys():
		var item_id := StringName(raw_id)
		var amount := maxi(0, int((raw_quantities as Dictionary)[raw_id]))
		if item_id != &"" and amount > 0:
			inventory._quantities[item_id] = amount
	return inventory


func duplicate_inventory() -> BattleSideItemInventory:
	return BattleSideItemInventory.from_dict(to_dict())
