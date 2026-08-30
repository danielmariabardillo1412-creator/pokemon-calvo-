class_name LearnSetEntry
extends RefCounted

# One learnable move at a given level/method.
# version_group_id/order are optional provenance: historical fixtures that predate
# DATA-01 remain byte-compatible when these values are absent/default.
var level: int = 1
var move_id: StringName = &""
var method: String = "level_up"
var version_group_id: StringName = &""
var order: int = -1


func _init(
	p_level: int = 1,
	p_move_id: StringName = &"",
	p_method: String = "level_up",
	p_version_group_id: StringName = &"",
	p_order: int = -1,
) -> void:
	level = p_level
	move_id = p_move_id
	method = p_method
	version_group_id = p_version_group_id
	order = p_order


func to_dict() -> Dictionary:
	var out := {"level": level, "move_id": String(move_id), "method": method}
	if version_group_id != &"":
		out["version_group_id"] = String(version_group_id)
	if order >= 0:
		out["order"] = order
	return out


static func from_dict(d: Dictionary) -> LearnSetEntry:
	return LearnSetEntry.new(
		int(d.get("level", 1)),
		StringName(d.get("move_id", "")),
		String(d.get("method", "level_up")),
		StringName(d.get("version_group_id", "")),
		int(d.get("order", -1)),
	)
