class_name MoveCatalog
extends RefCounted

# Injectable, in-memory catalog of immutable move definitions. Not an autoload.
var _entries: Dictionary = {}

func add(def: MoveDefinition) -> void:
	_entries[def.id] = def

func get_by_id(id: StringName) -> MoveDefinition:
	return _entries.get(id) as MoveDefinition

func has(id: StringName) -> bool:
	return _entries.has(id)

func all_ids() -> Array[StringName]:
	return _entries.keys()

func size() -> int:
	return _entries.size()

func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for id in _entries.keys():
		d[String(id)] = (_entries[id] as MoveDefinition).to_dict()
	return d

static func from_dict(d: Dictionary) -> MoveCatalog:
	var c := MoveCatalog.new()
	for id in d.keys():
		c.add(MoveDefinition.from_dict(d[id]))
	return c
