extends RefCounted

# Field mutations of a staged owned creature. Recovery rules are compiled from
# pinned RHH data and checked against the accepted native medicine contract.
const Training = preload("res://modules/inventory/field_training_effects.gd")
const Mochi = preload("res://modules/inventory/field_mochi_effects.gd")
const PPBoost = preload("res://modules/inventory/field_pp_boost_effects.gd")
const Abilities = preload("res://modules/inventory/field_ability_effects.gd")
const Friendship = preload("res://modules/inventory/field_friendship_effects.gd")
const Medicine = preload("res://modules/inventory/battle_medicine_profile.gd")
const RECOVERY_PROFILE := "res://modules/inventory/imported_recovery_v19.json"
static var _recovery: Dictionary = {}
const STATUS := {"brn": "burn", "psn": "poison", "tox": "badly_poisoned", "par": "paralysis", "slp": "sleep", "frz": "freeze"}
const EV_BERRIES := {"pomeg_berry": "hp", "kelpsy_berry": "attack", "qualot_berry": "defense", "hondew_berry": "special_attack", "grepa_berry": "special_defense", "tamato_berry": "speed"}


static func deny(reason: String) -> Dictionary:
	return {"accepted": false, "status": "REJECTED", "reason": reason}


static func _load_recovery() -> void:
	if _recovery.is_empty():
		_recovery = JSON.parse_string(FileAccess.get_file_as_string(RECOVERY_PROFILE)).items


static func imported_recovery_items() -> Dictionary:
	_load_recovery()
	return _recovery.duplicate(true)


static func recovery_items() -> Dictionary:
	# Preserve the older extra-recovery view: native medicine and bitter herbs
	# have separate presentation contracts, even though their executor is shared.
	_load_recovery()
	var result: Dictionary = {}
	for id: String in _recovery:
		if recovery_supports(StringName(id)): result[id] = _recovery_spec(StringName(id))
	return result


static func recovery_supports(item_id: StringName) -> bool:
	_load_recovery()
	return _recovery.has(String(item_id)) and not Medicine.supports(item_id) and not bitter_supports(item_id)


static func bitter_supports(item_id: StringName) -> bool:
	return _recovery_spec(item_id).has("friendship_loss")


static func consumes_on_use(item_id: StringName) -> bool:
	# Other families retain their existing one-unit transaction.
	_load_recovery()
	return bool(_recovery.get(String(item_id), {}).get("consume", true))


static func supports(item_id: StringName) -> bool:
	_load_recovery()
	return Mochi.supports(item_id) or Abilities.supports(item_id) or PPBoost.supports(item_id) or Training.supports(item_id) or EV_BERRIES.has(String(item_id)) or _recovery.has(String(item_id))


static func source_validation_error(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> String:
	# Validate raw EV values before CreatureInstance serialization can coerce them.
	if Mochi.supports(item_id): return Mochi.validation_error(creature, move_slot, catalogs)
	if Abilities.supports(item_id): return Abilities.validation_error(creature, move_slot, catalogs)
	if PPBoost.supports(item_id): return PPBoost.validation_error(creature, move_slot, catalogs)
	if bitter_supports(item_id) and (creature == null or creature.friendship < 0 or creature.friendship > 255): return "invalid_training_state"
	return Training.validation_error(creature, move_slot, catalogs) if Training.supports(item_id) else ""


static func _recovery_spec(item_id: StringName) -> Dictionary:
	_load_recovery()
	return _recovery.get(String(item_id), {}).get("effect", {}).duplicate(true)


static func pp_target_required(item_id: StringName) -> bool:
	return PPBoost.supports(item_id) or _recovery_spec(item_id).get("scope", "") == "one"


static func pp_boost_supports(item_id: StringName) -> bool:
	return PPBoost.supports(item_id)


static func apply(creature: CreatureInstance, item_id: StringName, move_slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	if creature == null or creature.is_knocked_out(): return deny("creature_knocked_out")
	if Mochi.supports(item_id): return Mochi.apply(creature, item_id, move_slot, catalogs)
	if Abilities.supports(item_id): return Abilities.apply(creature, item_id, move_slot, catalogs)
	if PPBoost.supports(item_id): return PPBoost.apply(creature, item_id, move_slot, catalogs)
	if Training.supports(item_id): return Training.apply(creature, item_id, move_slot, catalogs)
	if EV_BERRIES.has(String(item_id)): return _ev_berry(creature, item_id, move_slot, catalogs)
	var spec := _recovery_spec(item_id)
	if spec.is_empty(): return deny("field_effect_not_connected")
	if spec.has("friendship_loss") and (creature.friendship < 0 or creature.friendship > 255): return deny("invalid_training_state")
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
	if spec.has("friendship_loss"):
		var tier := 0 if creature.friendship < 100 else 1 if creature.friendship < 200 else 2
		# Apply negative friendship only after a real recovery, without bonuses.
		creature.friendship = maxi(0, creature.friendship - int(spec.friendship_loss[tier]))
	return {"accepted": true, "status": "APPLIED", "action": "bitter_medicine" if spec.has("friendship_loss") else "medicine"}


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
