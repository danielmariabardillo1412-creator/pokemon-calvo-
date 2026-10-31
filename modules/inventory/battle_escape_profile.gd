extends RefCounted

# Declarative bag effects. Ordinary Run and held Smoke Ball are separate rules.
const PATH := "res://modules/inventory/battle_escape_profile.json"
const Selection = preload("res://modules/inventory/item_selection_policy.gd")
const Content = preload("res://modules/gameplay/randomlock_content_policy.gd")
static var _items: Dictionary = {}
static var _selection: RefCounted


static func items() -> Dictionary:
	if _items.is_empty(): _items = JSON.parse_string(FileAccess.get_file_as_string(PATH)).items
	return _items.duplicate(true)


static func supports(item_id: StringName) -> bool:
	return items().has(String(item_id))


static func permitted(item_id: StringName, catalog: DefinitionCatalog) -> bool:
	if not supports(item_id) or catalog == null or catalog.item(item_id) == null: return false
	if _selection == null:
		_selection = Selection.new()
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Content.DATA_PATH))
		_selection.configure(JSON.parse_string(FileAccess.get_file_as_string(Selection.PATH)), data.items)
	return _selection.content_allowed(item_id)


static func resolution(attempts: int) -> Dictionary:
	return {"escaped": true, "attempt": attempts, "odds": WildEscapeRuleset.ROLL_MAX + 1, "roll": -1, "rng_consumed": false, "reason": ""}
