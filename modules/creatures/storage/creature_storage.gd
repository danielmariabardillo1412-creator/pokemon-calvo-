class_name CreatureStorage
extends RefCounted

# Persistent creature storage (the "PC"/boxes). Pure domain state: holds references to the SAME
# CreatureInstance objects owned by the player. NO Node, NO autoload, NO UI.
#
# Invariants enforced:
#  - An instance_id appears at most once across ALL boxes.
#  - A slot holds at most one creature.
#  - A creature cannot be in two boxes/slots at once.
#  - Moving leaves the origin empty and the destination with the same instance.
#  - Invalid operations never corrupt state.

var ruleset: StorageRuleset = StorageRuleset.new()
var _boxes: Array[StorageBox] = []


func _next_box_id() -> StringName:
	return StringName("box_%d" % _boxes.size())


func ensure_box() -> StorageBox:
	var b := StorageBox.new(_next_box_id(), ruleset.BOX_CAPACITY)
	_boxes.append(b)
	return b


# --- Queries ---------------------------------------------------------------

func box_count() -> int:
	return _boxes.size()


func get_box(index: int) -> StorageBox:
	if index < 0 or index >= _boxes.size():
		return null
	return _boxes[index]


func get_boxes() -> Array[StorageBox]:
	return _boxes.duplicate()


func contains_instance_id(instance_id: StringName) -> bool:
	return not locate(instance_id).is_empty()


func get_creature(instance_id: StringName) -> CreatureInstance:
	var loc := locate(instance_id)
	if loc.is_empty():
		return null
	return _boxes[loc.box_index].creature_at(loc.slot)


func locate(instance_id: StringName) -> Dictionary:
	for bi in _boxes.size():
		var box := _boxes[bi] as StorageBox
		for si in box.capacity:
			var c := box.creature_at(si)
			if c != null and c.instance_id == instance_id:
				return {"box_index": bi, "slot": si}
	return {}


func find_first_free_slot() -> Dictionary:
	for bi in _boxes.size():
		var box := _boxes[bi] as StorageBox
		var s := box.first_free_slot()
		if s >= 0:
			return {"box_index": bi, "slot": s}
	return {}


func ensure_capacity_for(_extra: int) -> void:
	while find_first_free_slot().is_empty():
		ensure_box()


func get_all_creatures() -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	for box in _boxes:
		for s in (box as StorageBox).slots():
			var c := s as CreatureInstance
			if c != null:
				out.append(c)
	return out


# --- Mutations -------------------------------------------------------------

func add_creature(creature: CreatureInstance) -> bool:
	if creature == null:
		return false
	if contains_instance_id(creature.instance_id):
		return false
	var free := find_first_free_slot()
	if free.is_empty():
		ensure_capacity_for(1)
		free = find_first_free_slot()
	if free.is_empty():
		return false
	return (_boxes[free.box_index] as StorageBox).insert_at(free.slot, creature)


# Replace the object occupying an existing identity while preserving exact box/slot location.
# Used by evolution because EvolutionSystem returns a new object with the same instance_id.
func replace_same_identity(creature: CreatureInstance) -> bool:
	if creature == null or creature.instance_id == &"":
		return false
	var loc := locate(creature.instance_id)
	if loc.is_empty():
		return false
	var box := _boxes[loc.box_index] as StorageBox
	return box.set_slot(loc.slot, creature)


func remove_creature(instance_id: StringName) -> bool:
	var loc := locate(instance_id)
	if loc.is_empty():
		return false
	(_boxes[loc.box_index] as StorageBox).remove_at(loc.slot)
	return true


func move_between_boxes(instance_id: StringName, to_box_index: int, to_slot: int) -> bool:
	var loc := locate(instance_id)
	if loc.is_empty():
		return false
	if to_box_index < 0 or to_box_index >= _boxes.size():
		return false
	var target := _boxes[to_box_index] as StorageBox
	if to_slot < 0 or to_slot >= target.capacity:
		return false
	if target.creature_at(to_slot) != null:
		return false
	var creature := (_boxes[loc.box_index] as StorageBox).creature_at(loc.slot)
	(_boxes[loc.box_index] as StorageBox).remove_at(loc.slot)
	if not target.insert_at(to_slot, creature):
		(_boxes[loc.box_index] as StorageBox).insert_at(loc.slot, creature)  # rollback
		return false
	return true


func swap_slots(box_a: int, slot_a: int, box_b: int, slot_b: int) -> bool:
	if box_a < 0 or box_a >= _boxes.size() or box_b < 0 or box_b >= _boxes.size():
		return false
	var a := _boxes[box_a] as StorageBox
	var b := _boxes[box_b] as StorageBox
	if slot_a < 0 or slot_a >= a.capacity or slot_b < 0 or slot_b >= b.capacity:
		return false
	var ca := a.creature_at(slot_a)
	var cb := b.creature_at(slot_b)
	# Identity-preserving swap: exchanging the two occupants (or one occupant + one empty).
	a.set_slot(slot_a, cb)
	b.set_slot(slot_b, ca)
	return true


# --- Serialization ---------------------------------------------------------

func to_dict() -> Dictionary:
	var boxes: Array[Dictionary] = []
	for box in _boxes:
		boxes.append((box as StorageBox).to_dict())
	return {
		"schema_version": ruleset.SCHEMA_VERSION,
		"ruleset_id": String(ruleset.ID),
		"boxes": boxes,
	}


# `reg` is { instance_id: CreatureInstance } used to resolve slot references.
# Returns a CreatureStorage; check `.corrupted` boxes via `is_corrupted()` afterwards.
static func from_dict(d: Dictionary, reg: Dictionary) -> CreatureStorage:
	var st := CreatureStorage.new()
	for boxd in d.get("boxes", []):
		var box := StorageBox.from_dict(boxd, reg)
		st._boxes.append(box)
	return st


func is_corrupted() -> bool:
	for box in _boxes:
		if (box as StorageBox).corrupted:
			return true
	return false
