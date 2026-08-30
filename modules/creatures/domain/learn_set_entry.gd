class_name LearnSetEntry
extends RefCounted

# One learnable move at a given level. Pure data record.
# version_group/order are provenance fields: progression may ignore them after a
# ruleset-specific learnset has been selected, but the importer must not erase them.
var level: int = 1
var move_id: StringName = &""
var method: String = "level_up"
var version_group: StringName = &""
var order: int = -1

func _init(
	p_level: int = 1,
	p_move_id: StringName = &"",
	p_method: String = "level_up",
	p_version_group: StringName = &"",
	p_order: int = -1,
) -> void:
	level = p_level
	move_id = p_move_id
	method = p_method
	version_group = p_version_group
	order = p_order

func to_dict() -> Dictionary:
	var out := {"level": level, "move_id": String(move_id), "method": method}
	# Preserve historical serialized shape for old fixtures/saves when provenance
	# was not present.
	if version_group != &"":
		out["version_group"] = String(version_group)
	if order >= 0:
		out["order"] = order
	return out

static func from_dict(d: Dictionary) -> LearnSetEntry:
	return LearnSetEntry.new(
		int(d.get("level", 1)),
		StringName(d.get("move_id", "")),
		String(d.get("method", "level_up")),
		StringName(d.get("version_group", "")),
		int(d.get("order", -1)),
	)
