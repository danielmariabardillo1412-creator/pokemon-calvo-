extends RefCounted

# Changes only a staged owned creature. No inventory, UI, IO, services or RNG.
# Existing max_pp uniquely encodes 0..3 boosts for the canonical 5+ PP moves;
# do not introduce another counter or change the save schema.
const Friendship = preload("res://modules/inventory/field_friendship_effects.gd")

static func supports(item_id: StringName) -> bool:
	return item_id in [&"pp_up", &"pp_max"]

static func boost_count(base_pp: int, max_pp: int) -> int:
	for count in 4:
		if max_pp == base_pp + base_pp * count / 5: return count
	return -1

static func validation_error(creature: CreatureInstance, move_slot: int, catalogs: DefinitionCatalog) -> String:
	if creature == null or creature.is_knocked_out(): return "creature_knocked_out"
	if move_slot < 0 or move_slot >= creature.moveset.size(): return "move_slot_required"
	if catalogs == null: return "unknown_move"
	if creature.friendship < 0 or creature.friendship > 255: return "invalid_training_state"
	if creature.moveset.size() != creature.move_ids.size() or creature.moveset.size() > ProgressionRuleset.MOVE_SLOTS_MAX: return "invalid_pp_state"
	# Validate the original slots before serialization can dereference a null slot
	# or conceal an inconsistent move-ID list. Do not mutate/repair corrupt data.
	for index in creature.moveset.size():
		var slot := creature.moveset[index]
		if slot == null or slot.move_id != creature.move_ids[index] or catalogs.move(slot.move_id) == null: return "invalid_pp_state"
		if slot.max_pp < 1 or slot.current_pp < 0 or slot.current_pp > slot.max_pp: return "invalid_pp_state"
	var selected := creature.moveset[move_slot]
	var base_pp := catalogs.move(selected.move_id).pp
	if base_pp < 5: return "item_has_no_effect"
	if boost_count(base_pp, selected.max_pp) < 0: return "invalid_pp_state"
	return ""

static func apply(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if not supports(item_id): return {"accepted": false, "status": "REJECTED", "reason": "field_effect_not_connected"}
	var error := validation_error(creature, move_slot, catalogs)
	if error != "": return {"accepted": false, "status": "REJECTED", "reason": error}
	var slot := creature.moveset[move_slot]
	var base_pp := catalogs.move(slot.move_id).pp
	var before_count := boost_count(base_pp, slot.max_pp)
	if before_count == 3: return {"accepted": false, "status": "REJECTED", "reason": "item_has_no_effect"}
	var count := 3 if item_id == &"pp_max" else before_count + 1
	var new_max := base_pp + base_pp * count / 5
	var added := new_max - slot.max_pp
	# Mainline behavior preserves PP already spent: increase current by the same
	# delta as max. This is neither a full restoration nor a spent-PP reset.
	slot.max_pp = new_max
	slot.current_pp += added
	Friendship.increase(creature, [5, 3, 2])
	return {"accepted": true, "status": "APPLIED", "action": "pp_boost", "boosted_move_id": String(slot.move_id),
		"move_slot": move_slot, "previous_boosts": before_count, "boosts": count, "max_pp_added": added, "new_max_pp": new_max}
