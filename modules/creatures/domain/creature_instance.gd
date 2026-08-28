class_name CreatureInstance
extends RefCounted

var instance_id: StringName
var species_id: StringName
var level: int
var current_hp: int
var stats: StatBlock
var move_ids: Array[StringName]
var status_ids: Array[StringName]


func _init(
	p_instance_id: StringName = &"",
	p_species_id: StringName = &"",
	p_level: int = 1,
	p_stats: StatBlock = null,
	p_move_ids: Array[StringName] = [],
) -> void:
	instance_id = p_instance_id
	species_id = p_species_id
	level = maxi(1, p_level)
	stats = p_stats if p_stats != null else StatBlock.new()
	current_hp = stats.max_hp
	move_ids = p_move_ids.duplicate()
	status_ids = []


func is_knocked_out() -> bool:
	return current_hp <= 0


func apply_damage(amount: int) -> int:
	var old_hp := current_hp
	current_hp = maxi(0, current_hp - maxi(0, amount))
	return old_hp - current_hp


func to_dict() -> Dictionary:
	var serialized_moves: Array[String] = []
	for move_id in move_ids:
		serialized_moves.append(String(move_id))
	var serialized_statuses: Array[String] = []
	for status_id in status_ids:
		serialized_statuses.append(String(status_id))
	return {
		"instance_id": String(instance_id),
		"species_id": String(species_id),
		"level": level,
		"current_hp": current_hp,
		"stats": stats.to_dict(),
		"move_ids": serialized_moves,
		"status_ids": serialized_statuses,
	}


static func from_dict(data: Dictionary) -> CreatureInstance:
	var restored_moves: Array[StringName] = []
	for move_id in data.get("move_ids", []):
		restored_moves.append(StringName(move_id))
	var creature := CreatureInstance.new(
		StringName(data.get("instance_id", "")),
		StringName(data.get("species_id", "")),
		int(data.get("level", 1)),
		StatBlock.from_dict(data.get("stats", {})),
		restored_moves,
	)
	creature.current_hp = clampi(int(data.get("current_hp", creature.stats.max_hp)), 0, creature.stats.max_hp)
	for status_id in data.get("status_ids", []):
		creature.status_ids.append(StringName(status_id))
	return creature

