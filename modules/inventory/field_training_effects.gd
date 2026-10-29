extends RefCounted

const Friendship = preload("res://modules/inventory/field_friendship_effects.gd")

# Applies modern EV items only to a staged owned creature. No UI/IO/inventory/RNG.
const VITAMINS := {"hp_up": "hp", "protein": "attack", "iron": "defense", "calcium": "special_attack", "zinc": "special_defense", "carbos": "speed"}
const WINGS := {"health_wing": "hp", "muscle_wing": "attack", "resist_wing": "defense", "genius_wing": "special_attack", "clever_wing": "special_defense", "swift_wing": "speed"}


static func supports(item_id: StringName) -> bool:
	return VITAMINS.has(String(item_id)) or WINGS.has(String(item_id))


static func validation_error(creature: CreatureInstance, move_slot: int, catalogs: DefinitionCatalog) -> String:
	if creature == null or creature.is_knocked_out(): return "creature_knocked_out"
	if move_slot != -1: return "unexpected_move_slot"
	if catalogs == null or catalogs.species(creature.species_id) == null: return "unknown_species"
	if creature.friendship < 0 or creature.friendship > 255: return "invalid_training_state"
	var total := 0
	for key: Variant in creature.evs:
		if not ProgressionRuleset.STAT_KEYS.has(key): return "invalid_training_state"
		var value: Variant = creature.evs[key]
		if not (value is int or value is float) or not is_finite(value) or value < 0 or value > ProgressionRuleset.EV_PER_STAT_MAX or value != int(value): return "invalid_training_state"
		total += int(value)
	if total > ProgressionRuleset.EV_TOTAL_MAX: return "invalid_training_state"
	return ""


static func apply(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if not supports(item_id): return {"accepted": false, "status": "REJECTED", "reason": "field_effect_not_connected"}
	var error := validation_error(creature, move_slot, catalogs)
	if error != "": return {"accepted": false, "status": "REJECTED", "reason": error}
	var vitamin := VITAMINS.has(String(item_id))
	var stat: String = VITAMINS.get(String(item_id), WINGS.get(String(item_id), ""))
	var total := 0
	for key: Variant in creature.evs: total += int(creature.evs[key])
	var old_ev := int(creature.evs.get(stat, 0))
	var gain := mini(10 if vitamin else 1, mini(ProgressionRuleset.EV_PER_STAT_MAX - old_ev, ProgressionRuleset.EV_TOTAL_MAX - total))
	if gain <= 0: return {"accepted": false, "status": "REJECTED", "reason": "item_has_no_effect"}
	var old_hp := creature.current_hp
	var old_max := creature.stats.max_hp
	creature.evs[stat] = old_ev + gain
	Friendship.increase(creature, [5, 3, 2] if vitamin else [3, 2, 1])
	creature.recalculate_stats(catalogs.species(creature.species_id), ProgressionRuleset.new())
	creature.current_hp = clampi(old_hp + creature.stats.max_hp - old_max, 1, creature.stats.max_hp)
	return {"accepted": true, "status": "APPLIED", "action": "ev_training", "stat_id": stat, "ev_added": gain}
