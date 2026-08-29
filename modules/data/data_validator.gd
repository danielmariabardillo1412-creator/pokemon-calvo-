class_name DataValidator
extends RefCounted

# Shared validation helpers for the data pipeline. No game logic.

const ID_PATTERN := "^[a-z0-9_]+$"

static func is_valid_id(id: StringName) -> bool:
	if id == &"" or String(id) != String(id).to_lower():
		return false
	var re := RegEx.new()
	re.compile(ID_PATTERN)
	return re.search(String(id)) != null

static func is_valid_stat(value: int) -> bool:
	return value >= 1 and value <= 255

static func is_valid_pow(value: int) -> bool:
	return value >= 0 and value <= 255
