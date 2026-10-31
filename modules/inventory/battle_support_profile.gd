extends RefCounted

# O110 battle-support capabilities, not another battle engine. The native
# candidate (native_bag_effects.cjs) owns every effect through the pinned
# simulator's own APIs; this service only answers capability questions for the
# application session, the spend validator and the view.
const PATH := "res://modules/inventory/battle_support_profile.json"

static var _items: Dictionary = {}


static func items() -> Dictionary:
	if _items.is_empty():
		_items = JSON.parse_string(FileAccess.get_file_as_string(PATH)).get("items", {})
	return _items.duplicate(true)


static func row(item_id: StringName) -> Dictionary:
	return items().get(String(item_id), {})


static func supports(item_id: StringName) -> bool:
	return items().has(String(item_id))


static func consumable(item_id: StringName) -> bool:
	return bool(row(item_id).get("consumable", false))


static func reusable(item_id: StringName) -> bool:
	return supports(item_id) and not consumable(item_id)


static func target_scope(item_id: StringName) -> StringName:
	return StringName(row(item_id).get("target", ""))


static func effect(item_id: StringName) -> StringName:
	return StringName(row(item_id).get("effect", ""))
