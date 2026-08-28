class_name TypeDefinition
extends Resource

# Canonical, immutable type definition (data layer). ID is the stable key.
@export var id: StringName
@export var display_name: String
@export var effectiveness: Dictionary = {}

func _init(p_display_name: String = "", p_effectiveness: Dictionary = {}):
	display_name = p_display_name
	var eff := {}
	for k in p_effectiveness.keys():
		eff[String(k)] = float(p_effectiveness[k])
	effectiveness = eff

func multiplier_against(defender_type_id: StringName) -> float:
	return float(effectiveness.get(String(defender_type_id), 1.0))

func to_dict() -> Dictionary:
	var eff: Dictionary = {}
	for k in effectiveness.keys():
		eff[String(k)] = float(effectiveness[k])
	return {
		"id": String(id),
		"display_name": display_name,
		"effectiveness": eff,
	}

static func from_dict(d: Dictionary) -> TypeDefinition:
	var t := TypeDefinition.new()
	t.id = StringName(d.get("id", ""))
	t.display_name = d.get("display_name", "")
	var eff: Dictionary = {}
	for k in d.get("effectiveness", {}).keys():
		eff[String(k)] = float(d["effectiveness"][k])
	t.effectiveness = eff
	return t
