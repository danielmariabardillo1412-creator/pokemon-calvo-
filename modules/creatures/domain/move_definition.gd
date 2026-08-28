class_name MoveDefinition
extends Resource

# Canonical, immutable move definition (data layer). ID is the stable key.
@export var id: StringName
@export var display_name: String
@export var power: int = 0
@export var type_id: StringName = &"normal"
@export var priority: int = 0

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"power": power,
		"type_id": String(type_id),
		"priority": priority,
	}

static func from_dict(d: Dictionary) -> MoveDefinition:
	var m := MoveDefinition.new()
	m.id = StringName(d.get("id", ""))
	m.display_name = d.get("display_name", "")
	m.power = int(d.get("power", 0))
	m.type_id = StringName(d.get("type_id", "normal"))
	m.priority = int(d.get("priority", 0))
	return m
