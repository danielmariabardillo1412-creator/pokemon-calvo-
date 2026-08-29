class_name CreatureInstance
extends RefCounted

var instance_id: StringName
var species_id: StringName
var level: int
var current_hp: int
var stats: StatBlock
var move_ids: Array[StringName]
var status_ids: Array[StringName]
var moveset: Array[BattleMoveSlot] = []
var stat_stages := StatStages.new()
var status_state := BattleStatusState.new()
var ability_id: StringName = &""
var held_item_id: StringName = &""
var held_item_consumed: bool = false


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
	for move_id in move_ids:
		moveset.append(BattleMoveSlot.new(move_id))


func is_knocked_out() -> bool:
	return current_hp <= 0


func apply_damage(amount: int) -> int:
	var old_hp := current_hp
	current_hp = maxi(0, current_hp - maxi(0, amount))
	return old_hp - current_hp


func recover_hp(amount: int) -> int:
	var old_hp := current_hp
	current_hp = mini(stats.max_hp, current_hp + maxi(0, amount))
	return current_hp - old_hp


func initialize_move_pp(catalog: DefinitionCatalog) -> void:
	for slot in moveset:
		var definition := catalog.move(slot.move_id)
		if definition != null:
			slot.initialize(definition)


func move_slot(move_id: StringName) -> BattleMoveSlot:
	for slot in moveset:
		if slot.move_id == move_id:
			return slot
	return null


func to_dict() -> Dictionary:
	var serialized_moves: Array[String] = []
	for move_id in move_ids:
		serialized_moves.append(String(move_id))
	var serialized_statuses: Array[String] = []
	for status_id in status_ids:
		serialized_statuses.append(String(status_id))
	var serialized_moveset: Array[Dictionary] = []
	for slot in moveset:
		serialized_moveset.append(slot.to_dict())
	return {
		"instance_id": String(instance_id),
		"species_id": String(species_id),
		"level": level,
		"current_hp": current_hp,
		"stats": stats.to_dict(),
		"move_ids": serialized_moves,
		"status_ids": serialized_statuses,
		"moveset": serialized_moveset,
		"stat_stages": stat_stages.to_dict(),
		"status_state": status_state.to_dict(),
		"ability_id": String(ability_id),
		"held_item_id": String(held_item_id),
		"held_item_consumed": held_item_consumed,
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
	if data.has("moveset"):
		creature.moveset.clear()
		creature.move_ids.clear()
		for slot_data in data.get("moveset", []):
			var slot := BattleMoveSlot.from_dict(slot_data)
			creature.moveset.append(slot)
			creature.move_ids.append(slot.move_id)
	for status_id in data.get("status_ids", []):
		creature.status_ids.append(StringName(status_id))
	creature.stat_stages = StatStages.from_dict(data.get("stat_stages", {}))
	creature.status_state = BattleStatusState.from_dict(data.get("status_state", {}))
	creature.ability_id = StringName(data.get("ability_id", ""))
	creature.held_item_id = StringName(data.get("held_item_id", ""))
	creature.held_item_consumed = bool(data.get("held_item_consumed", false))
	return creature
