class_name AbilityDefinition
extends Resource

# Canonical, immutable ability definition (data layer). ID is the stable key.
@export var id: StringName
@export var display_name: String
@export var description: String = ""
@export var effect_id: StringName = &""

func _init(p_id: StringName = &"", p_name: String = "", p_desc: String = "", p_effect: StringName = &"") -> void:
	id = p_id
	display_name = p_name
	description = p_desc
	effect_id = p_effect

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"description": description,
		"effect_id": String(effect_id),
	}

static func from_dict(d: Dictionary) -> AbilityDefinition:
	return AbilityDefinition.new(
		StringName(d.get("id", "")),
		d.get("display_name", ""),
		d.get("description", ""),
		StringName(d.get("effect_id", "")),
	)
