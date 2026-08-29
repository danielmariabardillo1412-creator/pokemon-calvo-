class_name LearnSetEntry
extends RefCounted

# One learnable move at a given level. Pure data record.
var level: int = 1
var move_id: StringName = &""
var method: String = "level_up"

func _init(p_level: int = 1, p_move_id: StringName = &"", p_method: String = "level_up") -> void:
	level = p_level
	move_id = p_move_id
	method = p_method

func to_dict() -> Dictionary:
	return {"level": level, "move_id": String(move_id), "method": method}

static func from_dict(d: Dictionary) -> LearnSetEntry:
	return LearnSetEntry.new(int(d.get("level", 1)), StringName(d.get("move_id", "")), String(d.get("method", "level_up")))
