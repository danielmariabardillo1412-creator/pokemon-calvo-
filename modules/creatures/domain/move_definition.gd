class_name MoveDefinition
extends Resource

# Canonical, immutable move definition (data layer). ID is the stable key.
@export var id: StringName
@export var display_name: String
@export var power: int = 0
@export var type_id: StringName = &"normal"
@export var priority: int = 0
# Extended metadata (data only; gameplay logic lands in Battle Core V2).
@export var damage_class: String = "physical"
@export var accuracy: int = 100
@export var pp: int = 0
@export var target: String = "selected"
@export var effect_summary: String = ""
@export var classification: String = "DATA_ONLY"
# Structured battle metadata (schema v2).
var effect_specs: Array[BattleEffectSpec] = []
var crit_rate_bp: int = 0
var makes_contact: bool = false


func to_dict() -> Dictionary:
	var specs: Array[Dictionary] = []
	for spec in effect_specs:
		specs.append(spec.to_dict())
	return {
		"id": String(id),
		"display_name": display_name,
		"power": power,
		"type_id": String(type_id),
		"priority": priority,
		"damage_class": damage_class,
		"accuracy": accuracy,
		"pp": pp,
		"target": target,
		"effect_summary": effect_summary,
		"classification": classification,
		"effect_specs": specs,
		"crit_rate_bp": crit_rate_bp,
		"makes_contact": makes_contact,
	}

static func from_dict(d: Dictionary) -> MoveDefinition:
	var m := MoveDefinition.new()
	m.id = StringName(d.get("id", ""))
	m.display_name = d.get("display_name", "")
	m.power = int(d.get("power", 0))
	m.type_id = StringName(d.get("type_id", "normal"))
	m.priority = int(d.get("priority", 0))
	m.damage_class = String(d.get("damage_class", "physical"))
	m.accuracy = int(d.get("accuracy", 100))
	m.pp = int(d.get("pp", 0))
	m.target = String(d.get("target", "selected"))
	m.effect_summary = String(d.get("effect_summary", ""))
	m.classification = String(d.get("classification", "DATA_ONLY"))
	m.crit_rate_bp = int(d.get("crit_rate_bp", 0))
	m.makes_contact = bool(d.get("makes_contact", false))
	for spec_data in d.get("effect_specs", []):
		m.effect_specs.append(BattleEffectSpec.from_dict(spec_data))
	return m
