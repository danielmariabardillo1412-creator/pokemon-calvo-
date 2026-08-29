class_name AbilityCatalog
extends RefCounted

# Injectable, in-memory catalog of immutable ability definitions. Not an autoload.
var _entries: Dictionary = {}

func add(def: AbilityDefinition) -> void:
	_entries[def.id] = def

func get_by_id(id: StringName) -> AbilityDefinition:
	return _entries.get(id) as AbilityDefinition

func has(id: StringName) -> bool:
	return _entries.has(id)

func all_ids() -> Array[StringName]:
	return _entries.keys()

func size() -> int:
	return _entries.size()

func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for id in _entries.keys():
		d[String(id)] = (_entries[id] as AbilityDefinition).to_dict()
	return d

static func from_dict(d: Dictionary) -> AbilityCatalog:
	var c := AbilityCatalog.new()
	for id in d.keys():
		c.add(AbilityDefinition.from_dict(d[id]))
	return c
