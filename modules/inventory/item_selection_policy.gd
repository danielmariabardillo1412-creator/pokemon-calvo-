extends RefCounted

## Content filtering, separate from item effects. Never edits the owner's bag.
const PATH := "res://config/item_selection_v1.json"
var valid := false
var errors: Array[String] = []
var _items := {}
var _ids := {}
var _categories := {}


func configure(config: Dictionary, items: Dictionary) -> bool:
	valid = false; errors.clear(); _items.clear(); _ids.clear(); _categories.clear()
	if config.get("schema_version") != 1 or config.get("profile_id") != "calvo_item_selection_v1": errors.append("item_policy_version")
	if items.is_empty(): errors.append("empty_item_catalog")
	if not config.get("excluded_ids") is Dictionary or not config.get("excluded_categories") is Dictionary: errors.append("item_policy_shape"); return false
	for id: Variant in items:
		if not id is String or not items[id] is Dictionary or items[id].get("id") != id or not items[id].get("category") is String: errors.append("invalid_item_definition"); continue
		_items[id] = items[id].duplicate(true)
	for id: Variant in config.excluded_ids:
		if not id is String or not _items.has(id) or not config.excluded_ids[id] is String or String(config.excluded_ids[id]).is_empty(): errors.append("invalid_excluded_item"); continue
		_ids[id] = config.excluded_ids[id]
	for category: Variant in config.excluded_categories:
		if not category is String or not config.excluded_categories[category] is String or String(config.excluded_categories[category]).is_empty() or not _items.values().any(func(row): return row.category == category): errors.append("invalid_excluded_category"); continue
		_categories[category] = config.excluded_categories[category]
	valid = errors.is_empty(); return valid


func exclusion_reason(id: StringName) -> String:
	if not valid: return "invalid_item_policy"
	if not _items.has(String(id)): return "unknown_item"
	return String(_ids.get(String(id), _categories.get(_items[String(id)].category, "")))


func content_allowed(id: StringName) -> bool:
	return exclusion_reason(id).is_empty()


## A future loot/shop pool must supply supported IDs, not the whole data catalog.
func can_generate(id: StringName, usable_ids: Dictionary) -> bool:
	return content_allowed(id) and usable_ids.has(String(id)) and usable_ids[String(id)] == true
