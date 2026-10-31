extends RefCounted

# Pinned RHH mochi effect tables: +10 EV or reset all EV; no friendship flags.
# Pure staged mutation. The existing item service owns inventory/publication.
const Training = preload("res://modules/inventory/field_training_effects.gd")
const MOCHIS := {"health_mochi": "hp", "muscle_mochi": "attack", "resist_mochi": "defense",
	"genius_mochi": "special_attack", "clever_mochi": "special_defense", "swift_mochi": "speed"}

static func supports(id: StringName) -> bool:
	return id == &"fresh_start_mochi" or MOCHIS.has(String(id))

static func validation_error(c: CreatureInstance, slot: int, catalogs: DefinitionCatalog) -> String:
	var error := Training.validation_error(c, slot, catalogs)
	if error != "": return error
	if not c.battle_transform_original.is_empty(): return "temporary_battle_state"
	if c.level < 1 or c.level > 100 or c.stats == null or c.status_state == null or c.stat_stages == null or c.current_hp > c.stats.max_hp or not ProgressionRuleset.is_valid_nature(c.nature_id): return "invalid_mochi_state"
	for key: Variant in c.ivs:
		var value: Variant = c.ivs[key]
		if not ProgressionRuleset.STAT_KEYS.has(key) or not (value is int or value is float): return "invalid_mochi_state"
		if not is_finite(value) or value != int(value) or value < 0 or value > 31: return "invalid_mochi_state"
	var expected := StatCalculator.compute(catalogs.species(c.species_id).base_stat_block(), c.ivs, c.evs, c.nature_id, c.level)
	if c.stats.to_dict() != expected.to_dict(): return "invalid_mochi_state"
	if c.move_ids.size() != c.moveset.size() or c.moveset.size() > 4: return "invalid_pp_state"
	for i in c.moveset.size():
		var move := c.moveset[i]
		if move == null or move.move_id != c.move_ids[i] or catalogs.move(move.move_id) == null: return "invalid_pp_state"
		if move.max_pp < 1 or move.current_pp < 0 or move.current_pp > move.max_pp: return "invalid_pp_state"
	return ""

static func apply(c: CreatureInstance, id: StringName, slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if not supports(id): return {"accepted": false, "status": "REJECTED", "reason": "field_effect_not_connected"}
	var error := validation_error(c, slot, catalogs)
	if error != "": return {"accepted": false, "status": "REJECTED", "reason": error}
	var total := 0
	for key: Variant in c.evs: total += int(c.evs[key])
	var reset := id == &"fresh_start_mochi"
	var stat: String = MOCHIS.get(String(id), "")
	var gain := 0 if reset else mini(10, mini(ProgressionRuleset.EV_PER_STAT_MAX - int(c.evs.get(stat, 0)), ProgressionRuleset.EV_TOTAL_MAX - total))
	if (reset and total == 0) or (not reset and gain == 0): return {"accepted": false, "status": "REJECTED", "reason": "item_has_no_effect"}
	var old_hp := c.current_hp; var old_max := c.stats.max_hp
	if reset:
		for key: Variant in c.evs: c.evs[key] = 0
	else: c.evs[stat] = int(c.evs.get(stat, 0)) + gain
	c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new())
	c.current_hp = clampi(old_hp + c.stats.max_hp - old_max, 1, c.stats.max_hp)
	return {"accepted": true, "status": "APPLIED", "action": "ev_reset" if reset else "ev_training",
		"stat_id": stat, "ev_added": gain, "ev_removed": total if reset else 0}
