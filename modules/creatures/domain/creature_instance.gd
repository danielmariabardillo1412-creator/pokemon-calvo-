class_name CreatureInstance
extends RefCounted

# Live, mutable per-creature state. This is the SINGLE persistent source of truth for
# a creature's progression and current battle-agnostic state. Battle Core mutates the
# same object (HP, status_state, moveset.current_pp) in place; the Progression Core
# reads/writes level/experience/IVs/EVs/nature and recomputes `stats`.
#
# Identity is `instance_id` (a stable StringName). It is NOT a NodePath, array index or
# Resource UID, so the same CreatureInstance can live in a party, PC, savegame or network
# message without rebinding.

var instance_id: StringName
var species_id: StringName
var level: int
var experience: int = 0
var ivs: Dictionary = {}            # stat_key -> int 0..31
var evs: Dictionary = {}            # stat_key -> int 0..252
var nature_id: StringName = &"hardy"
var friendship: int = 0
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
	move_ids = []
	for m in p_move_ids:
		move_ids.append(m)
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


# Recompute persistent stats from the species base + IV/EV/nature. Keeps current_hp
# within the new maximum.
func recalculate_stats(species: CreatureSpecies, ruleset: ProgressionRuleset) -> void:
	var base := species.base_stat_block()
	stats = StatCalculator.compute(base, ivs, evs, nature_id, level)
	current_hp = mini(current_hp, stats.max_hp)


func has_move(move_id: StringName) -> bool:
	for slot in moveset:
		if (slot as BattleMoveSlot).move_id == move_id:
			return true
	return false


func move_slot(move_id: StringName) -> BattleMoveSlot:
	for slot in moveset:
		if (slot as BattleMoveSlot).move_id == move_id:
			return slot
	return null


# Append a move to the moveset (does not enforce the 4-move cap; callers decide).
# Returns true if added.
func add_move(move_id: StringName, catalog: DefinitionCatalog) -> bool:
	if has_move(move_id):
		return false
	var slot := BattleMoveSlot.new(move_id)
	var definition = catalog.move(move_id)
	if definition != null:
		slot.initialize(definition)
	moveset.append(slot)
	move_ids.append(move_id)
	return true


# Replace an existing move with another. Returns true if the old move was present.
func replace_move(old_move_id: StringName, new_move_id: StringName, catalog: DefinitionCatalog) -> bool:
	if not has_move(old_move_id):
		return false
	for i in moveset.size():
		var slot := moveset[i] as BattleMoveSlot
		if slot.move_id == old_move_id:
			var new_slot := BattleMoveSlot.new(new_move_id)
			var definition = catalog.move(new_move_id)
			if definition != null:
				new_slot.initialize(definition)
			moveset[i] = new_slot
			if i < move_ids.size():
				move_ids[i] = new_move_id
			return true
	return false


func initialize_move_pp(catalog: DefinitionCatalog) -> void:
	for slot in moveset:
		var definition := catalog.move((slot as BattleMoveSlot).move_id)
		if definition != null:
			(slot as BattleMoveSlot).initialize(definition)


# Post-battle persistence reconciliation: drop volatile battle-only statuses (flinch,
# confusion, ...), keep the persistent status, clamp HP and PP to legal ranges.
func reconcile_post_battle() -> void:
	status_state.volatile.clear()
	current_hp = clampi(current_hp, 0, stats.max_hp)
	for slot in moveset:
		var s := slot as BattleMoveSlot
		s.current_pp = clampi(s.current_pp, 0, s.max_pp)


func to_dict() -> Dictionary:
	var serialized_moves: Array[String] = []
	for move_id in move_ids:
		serialized_moves.append(String(move_id))
	var serialized_moveset: Array[Dictionary] = []
	for slot in moveset:
		serialized_moveset.append((slot as BattleMoveSlot).to_dict())
	var serialized_statuses: Array[String] = []
	for status_id in status_ids:
		serialized_statuses.append(String(status_id))
	var iv_out: Dictionary = {}
	for k in ivs.keys():
		iv_out[String(k)] = int(ivs[k])
	var ev_out: Dictionary = {}
	for k in evs.keys():
		ev_out[String(k)] = int(evs[k])
	return {
		"instance_id": String(instance_id),
		"species_id": String(species_id),
		"level": level,
		"experience": experience,
		"ivs": iv_out,
		"evs": ev_out,
		"nature_id": String(nature_id),
		"friendship": friendship,
		"current_hp": current_hp,
		"stats": stats.to_dict(),
		"move_ids": serialized_moves,
		"moveset": serialized_moveset,
		"status_ids": serialized_statuses,
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
	creature.experience = maxi(0, int(data.get("experience", 0)))
	creature.ivs = data.get("ivs", {})
	creature.evs = data.get("evs", {})
	creature.nature_id = StringName(data.get("nature_id", "hardy"))
	creature.friendship = int(data.get("friendship", 0))
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
