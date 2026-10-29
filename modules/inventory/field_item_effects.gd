extends RefCounted

# Field mutations of a staged owned creature. Medicine amounts come from the same
# contract as native battles. EV berries follow the pinned Essentials reference.
const Training = preload("res://modules/inventory/field_training_effects.gd")
const PPBoost = preload("res://modules/inventory/field_pp_boost_effects.gd")
const Friendship = preload("res://modules/inventory/field_friendship_effects.gd")
const Medicine = preload("res://modules/inventory/battle_medicine_profile.gd")
const BITTER_HERBS := {"energy_powder": ["super_potion", 5, 10], "energy_root": ["hyper_potion", 10, 15], "heal_powder": ["full_heal", 5, 10]}
const RECOVERY_PROFILE := "res://modules/inventory/field_recovery_profile.json"
static var _recovery: Dictionary = {}
const STATUS := {"brn": "burn", "psn": "poison", "tox": "badly_poisoned", "par": "paralysis", "slp": "sleep", "frz": "freeze"}
const EV_BERRIES := {"pomeg_berry": "hp", "kelpsy_berry": "attack", "qualot_berry": "defense", "hondew_berry": "special_attack", "grepa_berry": "special_defense", "tamato_berry": "speed"}


static func deny(reason: String) -> Dictionary:
	return {"accepted": false, "status": "REJECTED", "reason": reason}


static func recovery_items() -> Dictionary:
	if _recovery.is_empty():
		_recovery = JSON.parse_string(FileAccess.get_file_as_string(RECOVERY_PROFILE)).items
	return _recovery.duplicate(true)


static func recovery_supports(item_id: StringName) -> bool:
	return recovery_items().has(String(item_id))


static func supports(item_id: StringName) -> bool:
	return PPBoost.supports(item_id) or Training.supports(item_id) or Medicine.supports(item_id) or EV_BERRIES.has(String(item_id)) or BITTER_HERBS.has(String(item_id)) or recovery_supports(item_id)


static func source_validation_error(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> String:
	# Validate raw EV values before CreatureInstance serialization can coerce them.
	if PPBoost.supports(item_id): return PPBoost.validation_error(creature, move_slot, catalogs)
	return Training.validation_error(creature, move_slot, catalogs) if Training.supports(item_id) else ""


static func _recovery_spec(item_id: StringName) -> Dictionary:
	return Medicine.items().get(String(item_id), recovery_items().get(String(item_id), {}))


static func pp_target_required(item_id: StringName) -> bool:
	return PPBoost.supports(item_id) or _recovery_spec(item_id).get("scope", "") == "one"


static func pp_boost_supports(item_id: StringName) -> bool:
	return PPBoost.supports(item_id)


static func apply(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if creature == null or creature.is_knocked_out(): return deny("creature_knocked_out")
	if PPBoost.supports(item_id): return PPBoost.apply(creature, item_id, move_slot, catalogs)
	if Training.supports(item_id): return Training.apply(creature, item_id, move_slot, catalogs)
	if EV_BERRIES.has(String(item_id)): return _ev_berry(creature, item_id, move_slot, catalogs)
	if BITTER_HERBS.has(String(item_id)): return _bitter_herb(creature, item_id, move_slot, catalogs)
	var spec := _recovery_spec(item_id)
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
		var amount: int = int(spec.heal) if not spec.heal is String else creature.stats.max_hp
		if spec.heal is String and spec.heal == "quarter": amount = maxi(1, creature.stats.max_hp / 4)
		creature.recover_hp(amount)
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


static func _bitter_herb(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if creature.friendship < 0 or creature.friendship > 255: return deny("invalid_training_state")
	var herb: Array = BITTER_HERBS[String(item_id)]
	# Reuse modern medicine effects on the staged creature; never consume twice.
	var result := apply(creature, StringName(herb[0]), move_slot, catalogs)
	if not result.accepted: return result
	var loss := int(herb[2] if creature.friendship >= 200 else herb[1])
	# Negative changes receive neither Soothe Bell nor capture-origin bonuses.
	creature.friendship = maxi(0, creature.friendship - loss)
	result["action"] = "bitter_medicine"
	return result


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
	Friendship.increase(creature, [10, 5, 2])
	creature.recalculate_stats(species, ProgressionRuleset.new())
	# Preserve the HP deficit across a maximum change; Pomeg must never cause a KO.
	creature.current_hp = clampi(old_hp + creature.stats.max_hp - old_max, 1, creature.stats.max_hp)
	return {"accepted": true, "status": "APPLIED", "action": "ev_berry", "stat_id": stat, "ev_removed": old_ev - int(creature.evs[stat])}
