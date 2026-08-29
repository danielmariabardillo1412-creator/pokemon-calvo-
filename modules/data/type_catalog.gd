class_name TypeCatalog
extends RefCounted

# Injectable, in-memory catalog of immutable type definitions. Not an autoload.
var _entries: Dictionary = {}

func add(def: TypeDefinition) -> void:
	_entries[def.id] = def

func get_by_id(id: StringName) -> TypeDefinition:
	return _entries.get(id) as TypeDefinition

func has(id: StringName) -> bool:
	return _entries.has(id)

func all_ids() -> Array[StringName]:
	return _entries.keys()

func size() -> int:
	return _entries.size()

func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for id in _entries.keys():
		d[String(id)] = (_entries[id] as TypeDefinition).to_dict()
	return d

static func from_dict(d: Dictionary) -> TypeCatalog:
	var c := TypeCatalog.new()
	for id in d.keys():
		c.add(TypeDefinition.from_dict(d[id]))
	return c
