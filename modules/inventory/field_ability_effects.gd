extends RefCounted

# Pure ability-slot adapter for the Scarlet/Violet item profile. Ability effects
# in combat remain entirely in the native engine. No inventory/UI/IO/RNG access.
const Training = preload("res://modules/inventory/field_training_effects.gd")

static func supports(item_id: StringName) -> bool:
	return item_id in [&"ability_capsule", &"ability_patch"]

static func deny(reason: String, status := "REJECTED") -> Dictionary:
	return {"accepted": false, "status": status, "reason": reason}

static func validation_error(c: CreatureInstance, slot: int, catalogs: DefinitionCatalog) -> String:
	if c == null or c.is_knocked_out(): return "creature_knocked_out"
	if slot != -1: return "unexpected_move_slot"
	if not c.battle_transform_original.is_empty(): return "temporary_battle_state"
	var error := Training.validation_error(c, -1, catalogs)
	if error != "": return error
	if c.stats == null or c.current_hp > c.stats.max_hp or c.level < 1 or c.level > 100 or c.experience < 0: return "invalid_ability_state"
	for value: Variant in c.stats.to_dict().values():
		if int(value) < 1: return "invalid_ability_state"
	for key: Variant in c.ivs:
		var value: Variant = c.ivs[key]
		if not ProgressionRuleset.STAT_KEYS.has(key): return "invalid_ability_state"
		if not (value is int or value is float) or not is_finite(value) or value != int(value) or value < 0 or value > 31: return "invalid_ability_state"
	if c.move_ids.size() != c.moveset.size() or c.moveset.size() > 4: return "invalid_pp_state"
	for index in c.moveset.size():
		var move := c.moveset[index]
		if move == null or move.move_id != c.move_ids[index] or catalogs.move(move.move_id) == null: return "invalid_pp_state"
		if move.max_pp < 1 or move.current_pp < 0 or move.current_pp > move.max_pp: return "invalid_pp_state"
	return ""

static func preview(c: CreatureInstance, item_id: StringName, catalogs: DefinitionCatalog) -> Dictionary:
	if not supports(item_id): return deny("field_effect_not_connected")
	var error := validation_error(c, -1, catalogs)
	if error != "": return deny(error)
	var species := catalogs.species(c.species_id)
	var slots: Dictionary = {}
	var represented: Dictionary = {}
	for row: Dictionary in species.ability_slots:
		var number: Variant = row.get("slot")
		if not (number is int or number is float) or not is_finite(number) or number != int(number): return deny("ability_slot_metadata_invalid", "DEPENDENCY_MISSING")
		var index := int(number)
		var id := StringName(str(row.get("ability_id", "")))
		if index not in [1, 2, 3] or slots.has(index) or not row.get("is_hidden") is bool: return deny("ability_slot_metadata_invalid", "DEPENDENCY_MISSING")
		if row.is_hidden != (index == 3) or not species.ability_ids.has(id) or catalogs.ability(id) == null: return deny("ability_slot_metadata_invalid", "DEPENDENCY_MISSING")
		slots[index] = id; represented[id] = true
	for id: StringName in species.ability_ids:
		if not represented.has(id): return deny("ability_slot_metadata_missing", "DEPENDENCY_MISSING")
	var matches: Array[int] = []
	for index: int in slots:
		if slots[index] == c.ability_id: matches.append(index)
	if matches.is_empty(): return deny("ability_source_not_in_slots", "DEPENDENCY_MISSING")
	if matches.size() > 1:
		if matches.has(3): return deny("ability_slot_ambiguous", "DEPENDENCY_MISSING")
		if item_id == &"ability_capsule": return deny("item_has_no_effect")
		# Equal normal IDs still have one unambiguous Patch destination. Do not
		# invent a genetic normal slot, but do permit the observable hidden ID.
	var current: int = matches[0]
	var destination: int
	if item_id == &"ability_capsule":
		if current == 3 or not slots.has(1) or not slots.has(2) or slots[1] == slots[2]: return deny("item_has_no_effect")
		destination = 2 if current == 1 else 1
	else:
		# Gen IX reversion chooses the FIRST normal slot, never an imagined
		# previous slot or a random ability. Source uses 1/2/3, not 0/1/2.
		destination = 1 if current == 3 else 3
		if not slots.has(destination): return deny("item_has_no_effect")
	var target: StringName = slots[destination]
	if target == c.ability_id: return deny("item_has_no_effect")
	# Both Darmanitan forms can gain Zen Mode through a Patch, but the native
	# mirror rejects its automatic form transition. Preserve the item until
	# that separate form route is supported; reverting an existing one is safe.
	if target == &"zen_mode": return deny("ability_form_route_pending", "DEPENDENCY_MISSING")
	return {"accepted": true, "status": "APPLIED", "action": "ability_change", "ability_id": String(target),
		"previous_ability_id": String(c.ability_id), "source_slots": matches, "target_slot": destination}

static func apply(c: CreatureInstance, item_id: StringName, slot: int, catalogs: DefinitionCatalog) -> Dictionary:
	var error := validation_error(c, slot, catalogs)
	if error != "": return deny(error)
	var result := preview(c, item_id, catalogs)
	if result.accepted: c.ability_id = StringName(result.ability_id)
	return result
