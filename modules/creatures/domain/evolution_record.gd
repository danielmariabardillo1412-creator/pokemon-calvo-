class_name EvolutionRecord
extends RefCounted

# A single evolution path from a species to another. Pure data record.
var species_id: StringName = &""
var min_level: int = 0
var trigger: StringName = &"level_up"
var item_id: StringName = &""

func _init(p_species_id: StringName = &"", p_min_level: int = 0, p_trigger: StringName = &"level_up", p_item_id: StringName = &"") -> void:
	species_id = p_species_id
	min_level = p_min_level
	trigger = p_trigger
	item_id = p_item_id

func to_dict() -> Dictionary:
	return {"species_id": String(species_id), "min_level": min_level, "trigger": String(trigger), "item_id": String(item_id)}

static func from_dict(d: Dictionary) -> EvolutionRecord:
	return EvolutionRecord.new(
		StringName(d.get("species_id", "")),
		int(d.get("min_level", 0)),
		StringName(d.get("trigger", "level_up")),
		StringName(d.get("item_id", "")),
	)
