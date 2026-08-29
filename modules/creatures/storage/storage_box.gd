class_name StorageBox
extends RefCounted

# A single ordered box of creature slots. Slots are ordered; each slot holds at most one
# CreatureInstance (or null when empty). Identity is by `instance_id`, so the SAME
# CreatureInstance object that lives in the party can be placed here.
#
# Serialization stores slot REFERENCES (instance_id) only; the canonical creature data lives in
# the savegame creature registry. `from_dict` therefore needs the registry to rebuild instances.

var box_id: StringName
var name: String = ""
var capacity: int = 30
var _slots: Array = []          # Array[CreatureInstance | null], length == capacity
var corrupted: bool = false     # set by from_dict if a slot referenced a missing creature


func _init(p_box_id: StringName = &"", p_capacity: int = 30, p_name: String = "") -> void:
	box_id = p_box_id
	capacity = maxi(1, p_capacity)
	name = p_name
	_ensure_capacity()


func _ensure_capacity() -> void:
	while _slots.size() < capacity:
		_slots.append(null)


func creature_at(slot: int) -> CreatureInstance:
	if slot < 0 or slot >= _slots.size():
		return null
	return _slots[slot] as CreatureInstance


func set_slot(slot: int, creature: CreatureInstance) -> bool:
	if slot < 0 or slot >= _slots.size():
		return false
	_slots[slot] = creature
	return true


func insert_at(slot: int, creature: CreatureInstance) -> bool:
	if creature == null:
		return false
	if slot < 0 or slot >= _slots.size():
		return false
	if _slots[slot] != null:
		return false
	if contains(creature.instance_id):
		return false
	_slots[slot] = creature
	return true


# Insert at the first free slot. Returns the slot index, or -1 if full.
func insert(creature: CreatureInstance) -> int:
	var s := first_free_slot()
	if s < 0:
		return -1
	if insert_at(s, creature):
		return s
	return -1


func remove_at(slot: int) -> CreatureInstance:
	if slot < 0 or slot >= _slots.size():
		return null
	var c := _slots[slot] as CreatureInstance
	_slots[slot] = null
	return c


func move_slot(from: int, to: int) -> bool:
	if from < 0 or from >= _slots.size() or to < 0 or to >= _slots.size():
		return false
	if from == to:
		return true
	if _slots[to] != null:
		return false
	var c := _slots[from] as CreatureInstance
	if c == null:
		return false
	_slots[to] = c
	_slots[from] = null
	return true


func swap_slots(a: int, b: int) -> bool:
	if a < 0 or a >= _slots.size() or b < 0 or b >= _slots.size():
		return false
	if a == b:
		return true
	var tmp := _slots[a] as CreatureInstance
	_slots[a] = _slots[b]
	_slots[b] = tmp
	return true


func contains(instance_id: StringName) -> bool:
	for s in _slots:
		var c := s as CreatureInstance
		if c != null and c.instance_id == instance_id:
			return true
	return false


func first_free_slot() -> int:
	for i in _slots.size():
		if _slots[i] == null:
			return i
	return -1


func is_full() -> bool:
	return first_free_slot() < 0


func size() -> int:
	var n := 0
	for s in _slots:
		if s != null:
			n += 1
	return n


func slots() -> Array:
	return _slots.duplicate()


func to_dict() -> Dictionary:
	var out: Array = []
	for s in _slots:
		var c := s as CreatureInstance
		out.append(String(c.instance_id) if c != null else null)
	return {
		"box_id": String(box_id),
		"name": name,
		"capacity": capacity,
		"slots": out,
	}


# `reg` is a Dictionary { instance_id: CreatureInstance } used to resolve slot references.
static func from_dict(d: Dictionary, reg: Dictionary) -> StorageBox:
	var box := StorageBox.new(StringName(d.get("box_id", "")), int(d.get("capacity", 30)), d.get("name", ""))
	box._slots = []
	var raw: Array = d.get("slots", [])
	if raw.size() != box.capacity:
		box.corrupted = true
	for sid in raw:
		if sid == null or sid == "":
			box._slots.append(null)
		else:
			var c := reg.get(StringName(sid), null) as CreatureInstance
			if c == null:
				box.corrupted = true
				box._slots.append(null)
			else:
				box._slots.append(c)
	box._ensure_capacity()
	return box
