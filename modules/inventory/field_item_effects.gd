extends RefCounted

# Field mutations of a staged owned creature. Medicine amounts come from the same
# contract as native battles. EV berries follow the pinned Essentials reference.
const Medicine = preload("res://modules/inventory/battle_medicine_profile.gd")
const STATUS := {"brn": "burn", "psn": "poison", "tox": "badly_poisoned", "par": "paralysis", "slp": "sleep", "frz": "freeze"}
const EV_BERRIES := {"pomeg_berry": "hp", "kelpsy_berry": "attack", "qualot_berry": "defense", "hondew_berry": "special_attack", "grepa_berry": "special_defense", "tamato_berry": "speed"}


static func deny(reason: String) -> Dictionary:
	return {"accepted": false, "status": "REJECTED", "reason": reason}


static func pp_target_required(item_id: StringName) -> bool:
	return Medicine.items().get(String(item_id), {}).get("scope", "") == "one"


static func apply(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if creature == null or creature.is_knocked_out(): return deny("creature_knocked_out")
	if EV_BERRIES.has(String(item_id)): return _ev_berry(creature, item_id, move_slot, catalogs)
	var spec: Dictionary = Medicine.items().get(String(item_id), {})
	if spec.is_empty(): return deny("field_effect_not_connected")
	var slots: Array[BattleMoveSlot] = []
	if spec.has("pp"):
		if spec.scope == "one":
			if move_slot < 0 or move_slot >= creature.moveset.size(): return deny("move_slot_required")
			slots.append(creature.moveset[move_slot])
		else:
			if move_slot != -1: return deny("unexpected_move_slot")
			slots.assign(creature.moveset)
	elif move_slot != -1: return deny("unexpected_move_slot")
	var before := creature.to_dict()
	if spec.has("heal"):
		creature.recover_hp(creature.stats.max_hp if spec.heal is String else int(spec.heal))
	var status := String(creature.status_state.persistent_id)
	var cure: bool = not status.is_empty() and spec.get("cure") is String and spec.cure == "all"
	if spec.get("cure") is Array:
		for code: String in spec.cure:
			if STATUS.get(code) == status: cure = true
	if cure:
		creature.status_state.clear_persistent(); creature.status_ids.clear()
		creature.status_state.remove_volatile(&"nightmare")
	if spec.get("confusion", false): creature.status_state.remove_volatile(&"confusion")
	for slot: BattleMoveSlot in slots:
		slot.current_pp = mini(slot.max_pp, slot.current_pp + (slot.max_pp if spec.pp is String else int(spec.pp)))
	if creature.to_dict() == before: return deny("item_has_no_effect")
	return {"accepted": true, "status": "APPLIED", "action": "medicine"}


static func _ev_berry(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if move_slot != -1: return deny("unexpected_move_slot")
	var species := catalogs.species(creature.species_id)
	if species == null: return deny("unknown_species")
	var stat: String = EV_BERRIES[String(item_id)]
	var old_ev := int(creature.evs.get(stat, 0))
	if creature.friendship < 0 or creature.friendship > 255 or old_ev < 0 or old_ev > 252: return deny("invalid_training_state")
	if old_ev == 0 and creature.friendship == 255: return deny("item_has_no_effect")
	var old_hp := creature.current_hp
	var old_max := creature.stats.max_hp
	creature.evs[stat] = maxi(0, old_ev - 10)
	# Capture-ball/map bonuses need origin metadata absent from CreatureInstance.
	# Keep those contexts explicit in ITEM_PENDING_V4 rather than infer an origin.
	var gain: int = [10, 5, 2][mini(2, creature.friendship / 100)]
	if creature.held_item_id == &"soothe_bell" and not creature.held_item_consumed: gain = gain * 3 / 2
	creature.friendship = mini(255, creature.friendship + gain)
	creature.recalculate_stats(species, ProgressionRuleset.new())
	# Preserve the HP deficit across a maximum change; Pomeg must never cause a KO.
	creature.current_hp = clampi(old_hp + creature.stats.max_hp - old_max, 1, creature.stats.max_hp)
	return {"accepted": true, "status": "APPLIED", "action": "ev_berry", "stat_id": stat, "ev_removed": old_ev - int(creature.evs[stat])}
