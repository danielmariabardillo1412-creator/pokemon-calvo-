class_name ItemCatalog
extends RefCounted

# Injectable, in-memory catalog of immutable item definitions. Not an autoload.
var _entries: Dictionary = {}

func add(def: ItemDefinition) -> void:
	_entries[def.id] = def

func get_by_id(id: StringName) -> ItemDefinition:
	return _entries.get(id) as ItemDefinition

func has(id: StringName) -> bool:
	return _entries.has(id)

func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in _entries.keys():
		out.append(k)
	return out

func size() -> int:
	return _entries.size()

func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for id in _entries.keys():
		d[String(id)] = (_entries[id] as ItemDefinition).to_dict()
	return d

static func from_dict(d: Dictionary) -> ItemCatalog:
	var c := ItemCatalog.new()
	for id in d.keys():
		c.add(ItemDefinition.from_dict(d[id]))
	return c
