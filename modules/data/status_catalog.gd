class_name StatusCatalog
extends RefCounted

# Injectable, in-memory catalog of immutable status definitions. Not an autoload.
var _entries: Dictionary = {}

func add(def: StatusDefinition) -> void:
	_entries[def.id] = def

func get_by_id(id: StringName) -> StatusDefinition:
	return _entries.get(id) as StatusDefinition

func has(id: StringName) -> bool:
	return _entries.has(id)

func all_ids() -> Array[StringName]:
	return _entries.keys()

func size() -> int:
	return _entries.size()

func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for id in _entries.keys():
		d[String(id)] = (_entries[id] as StatusDefinition).to_dict()
	return d

static func from_dict(d: Dictionary) -> StatusCatalog:
	var c := StatusCatalog.new()
	for id in d.keys():
		c.add(StatusDefinition.from_dict(d[id]))
	return c
