class_name ItemDefinition
extends Resource

# Canonical, immutable item definition (data layer). ID is the stable key.
@export var id: StringName
@export var display_name: String
@export var description: String = ""
@export var category: StringName = &""

func _init(p_id: StringName = &"", p_name: String = "", p_desc: String = "", p_cat: StringName = &"") -> void:
	id = p_id
	display_name = p_name
	description = p_desc
	category = p_cat

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"description": description,
		"category": String(category),
	}

static func from_dict(d: Dictionary) -> ItemDefinition:
	return ItemDefinition.new(
		StringName(d.get("id", "")),
		d.get("display_name", ""),
		d.get("description", ""),
		StringName(d.get("category", "")),
	)
