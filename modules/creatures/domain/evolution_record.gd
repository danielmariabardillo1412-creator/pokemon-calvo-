class_name EvolutionRecord
extends RefCounted

# A single evolution path from a species to another. Pure data record.
# The legacy fields remain first-class for current runtime compatibility. V3 also
# preserves source version/condition metadata so unsupported mechanics are not lost.
var species_id: StringName = &""
var min_level: int = 0
var trigger: StringName = &"level_up"
var item_id: StringName = &""
var version_group: StringName = &""
var is_default: bool = true
var conditions: Dictionary = {}

func _init(
	p_species_id: StringName = &"",
	p_min_level: int = 0,
	p_trigger: StringName = &"level_up",
	p_item_id: StringName = &"",
	p_version_group: StringName = &"",
	p_is_default: bool = true,
	p_conditions: Dictionary = {},
) -> void:
	species_id = p_species_id
	min_level = p_min_level
	trigger = p_trigger
	item_id = p_item_id
	version_group = p_version_group
	is_default = p_is_default
	conditions = p_conditions.duplicate(true)

func to_dict() -> Dictionary:
	var out := {
		"species_id": String(species_id),
		"min_level": min_level,
		"trigger": String(trigger),
		"item_id": String(item_id),
	}
	# Optional V3 provenance is omitted for legacy entries, preserving old serialized shape.
	if version_group != &"":
		out["version_group"] = String(version_group)
	if not is_default:
		out["is_default"] = false
	if not conditions.is_empty():
		out["conditions"] = conditions.duplicate(true)
	return out

static func from_dict(d: Dictionary) -> EvolutionRecord:
	return EvolutionRecord.new(
		StringName(d.get("species_id", "")),
		int(d.get("min_level", 0)),
		StringName(d.get("trigger", "level_up")),
		StringName(d.get("item_id", "")),
		StringName(d.get("version_group", "")),
		bool(d.get("is_default", true)),
		d.get("conditions", {}) as Dictionary,
	)
