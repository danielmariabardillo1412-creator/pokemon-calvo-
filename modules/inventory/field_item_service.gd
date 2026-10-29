extends RefCounted

const Selection = preload("res://modules/inventory/item_selection_policy.gd")
const Content = preload("res://modules/gameplay/randomlock_content_policy.gd")
const Medicine = preload("res://modules/inventory/battle_medicine_profile.gd")
const FieldEffects = preload("res://modules/inventory/field_item_effects.gd")
const PROFILE := "res://modules/inventory/item_connections_v1.json"
static var _shared_selection: RefCounted
static var _shared_content: RefCounted
static var _shared_profile: Dictionary = {}
var owner: PlayerCollection
var catalogs: DefinitionCatalog
var guard: Callable
var selection: RefCounted
var content: RefCounted
var profile: Dictionary = {}
var _holdable: Dictionary = {}
var sleep_clocks: Dictionary = {}


func configure(collection: PlayerCollection, definitions: DefinitionCatalog, may_mutate: Callable, clocks: Dictionary = {}) -> bool:
	owner = collection; catalogs = definitions; guard = may_mutate
	sleep_clocks = clocks
	if _shared_selection == null:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Content.DATA_PATH))
		_shared_selection = Selection.new(); _shared_content = Content.new()
		_shared_selection.configure(JSON.parse_string(FileAccess.get_file_as_string(Selection.PATH)), data.items)
		_shared_content.configure(JSON.parse_string(FileAccess.get_file_as_string(Content.CONFIG_PATH)), data)
		_shared_profile = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	selection = _shared_selection; content = _shared_content
	profile = _shared_profile.duplicate(true); _holdable.clear()
	for id: String in profile.get("holdable_ids", []): _holdable[id] = true
	return owner != null and catalogs != null and guard.is_valid() and selection.valid and content.valid


func _deny(reason: String, status := "REJECTED") -> Dictionary:
	return {"accepted": false, "reason": reason, "status": status}


func _boundary(item_id: StringName = &"") -> String:
	if owner == null or catalogs == null or not guard.is_valid() or not guard.call(): return "field_locked"
	if owner.inventory == null or owner.inventory.corrupted: return "invalid_inventory"
	if item_id != &"" and not selection.content_allowed(item_id): return selection.exclusion_reason(item_id)
	return ""


func _bag_copy() -> PlayerInventory:
	return PlayerInventory.from_dict(owner.inventory.to_dict())


func _publish_bag(staged: PlayerInventory) -> void:
	var ids: Dictionary = {}
	for id: StringName in owner.inventory.all_item_ids(): ids[id] = true
	for id: StringName in staged.all_item_ids(): ids[id] = true
	for id: StringName in ids: owner.inventory.set_quantity(id, staged.quantity(id))


func holdable(item_id: StringName) -> bool:
	return _holdable.has(String(item_id)) and selection.content_allowed(item_id)


func equip(item_id: StringName, creature_id: StringName) -> Dictionary:
	var error := _boundary(item_id)
	if error != "": return _deny(error)
	var creature := owner.owned_creature(creature_id)
	if creature == null: return _deny("creature_not_owned")
	if not holdable(item_id): return _deny("holdability_not_supported", "NEEDS_CONTEXT")
	if creature.held_item_id == item_id and not creature.held_item_consumed: return _deny("already_equipped")
	var staged := _bag_copy()
	if not staged.remove(item_id): return _deny("item_not_owned")
	if creature.held_item_id != &"" and not creature.held_item_consumed:
		if not staged.add(creature.held_item_id): return _deny("inventory_capacity")
	_publish_bag(staged)
	creature.held_item_id = item_id; creature.held_item_consumed = false
	return {"accepted": true, "status": "APPLIED", "action": "equip", "item_id": String(item_id)}


func unequip(creature_id: StringName) -> Dictionary:
	var error := _boundary()
	if error != "": return _deny(error)
	var creature := owner.owned_creature(creature_id)
	if creature == null: return _deny("creature_not_owned")
	if creature.held_item_id == &"": return _deny("nothing_equipped")
	var staged := _bag_copy()
	if not creature.held_item_consumed and not staged.add(creature.held_item_id): return _deny("inventory_capacity")
	_publish_bag(staged)
	creature.held_item_id = &""; creature.held_item_consumed = false
	return {"accepted": true, "status": "APPLIED", "action": "unequip"}


func evolution_options(item_id: StringName, creature_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var creature := owner.owned_creature(creature_id)
	if creature == null: return result
	var species := catalogs.species(creature.species_id)
	if species == null: return result
	for record: EvolutionRecord in EvolutionSystem.evolution_candidates(species, {"level": creature.level, "item_id": item_id}, catalogs):
		if record.trigger == EvolutionSystem.TRIGGER_USE_ITEM and record.item_id == item_id and content.species_allowed(String(record.species_id)):
			result.append(record.species_id)
	return result


func evolve(item_id: StringName, creature_id: StringName, requested_target: StringName = &"") -> Dictionary:
	var error := _boundary(item_id)
	if error != "": return _deny(error)
	var creature := owner.owned_creature(creature_id)
	if creature == null: return _deny("creature_not_owned")
	if catalogs.species(creature.species_id) == null: return _deny("unknown_species")
	if not owner.inventory.has(item_id): return _deny("item_not_owned")
	var options := evolution_options(item_id, creature_id)
	if options.is_empty():
		for record: EvolutionRecord in catalogs.species(creature.species_id).evolutions:
			if record.item_id == item_id and EvolutionSystem.classify_record(record, catalogs, creature.species_id) != EvolutionSystem.RUNTIME_SUPPORTED:
				return _deny("evolution_requires_additional_mechanic", "DEPENDENCY_MISSING")
		return _deny("no_eligible_evolution")
	if requested_target == &"":
		if options.size() != 1: return _deny("evolution_target_required", "NEEDS_CONTEXT")
		requested_target = options[0]
	if not options.has(requested_target): return _deny("invalid_evolution_target")
	var evolved := EvolutionSystem.apply_evolution(creature, requested_target, catalogs, ProgressionRuleset.new())
	if evolved == null or evolved.instance_id != creature.instance_id: return _deny("evolution_failed")
	if evolved.ability_id != &"" and not content.ability_allowed(String(evolved.ability_id)): return _deny("evolution_ability_route_pending", "DEPENDENCY_MISSING")
	var staged := _bag_copy()
	if not staged.remove(item_id): return _deny("item_not_owned")
	if not owner.replace_owned_same_identity(evolved): return _deny("ownership_changed")
	_publish_bag(staged)
	return {"accepted": true, "status": "APPLIED", "action": "evolve", "species_id": String(requested_target), "creature_id": String(creature_id)}


func machine_move(item_id: StringName) -> StringName:
	return StringName(profile.get("machine_rows", {}).get(String(item_id), {}).get(profile.get("active_machine_version", ""), ""))


func teach(item_id: StringName, creature_id: StringName, replace_slot := -1) -> Dictionary:
	var error := _boundary(item_id)
	if error != "": return _deny(error)
	var creature := owner.owned_creature(creature_id)
	if creature == null: return _deny("creature_not_owned")
	if not owner.inventory.has(item_id): return _deny("item_not_owned")
	if not profile.machine_rows.has(String(item_id)): return _deny("not_a_machine")
	# Do not infer consumption for a legacy profile from a modern description.
	if profile.active_machine_version != "scarlet-violet": return _deny("machine_profile_rules_pending", "DEPENDENCY_MISSING")
	var move_id := machine_move(item_id)
	if move_id == &"": return _deny("machine_not_in_active_version", "NEEDS_CONTEXT")
	if not content.move_learnable(String(move_id)) or catalogs.move(move_id) == null: return _deny("move_not_permitted")
	var species := catalogs.species(creature.species_id)
	if species == null: return _deny("unknown_species")
	var compatible := false
	var has_version := false
	for entry: LearnSetEntry in species.learnset:
		if entry.method != "machine" or String(entry.version_group) != profile.active_machine_version: continue
		has_version = true
		if entry.move_id == move_id: compatible = true
	if not has_version: return _deny("species_machine_version_context_missing", "NEEDS_CONTEXT")
	if not compatible: return _deny("machine_incompatible")
	if creature.has_move(move_id): return _deny("move_already_known")
	if replace_slot < -1 or replace_slot >= creature.moveset.size(): return _deny("invalid_move_slot")
	if creature.moveset.size() >= ProgressionRuleset.MOVE_SLOTS_MAX and replace_slot == -1: return _deny("move_replacement_required", "NEEDS_CONTEXT")
	var copy := CreatureInstance.from_dict(creature.to_dict())
	var changed := copy.add_move(move_id, catalogs) if replace_slot == -1 else copy.replace_move(copy.moveset[replace_slot].move_id, move_id, catalogs)
	if not changed: return _deny("move_not_changed")
	var staged := _bag_copy()
	if not staged.remove(item_id): return _deny("item_not_owned")
	if not owner.replace_owned_same_identity(copy): return _deny("ownership_changed")
	_publish_bag(staged)
	return {"accepted": true, "status": "APPLIED", "action": "teach", "move_id": String(move_id), "version": profile.active_machine_version}


func use_item(item_id: StringName, creature_id: StringName, replace_slot := -1, target_species: StringName = &"") -> Dictionary:
	var error := _boundary(item_id)
	if error != "": return _deny(error)
	if FieldEffects.supports(item_id):
		return _apply_field_effect(item_id, creature_id, replace_slot)
	if profile.machine_rows.has(String(item_id)): return teach(item_id, creature_id, replace_slot)
	if not evolution_options(item_id, creature_id).is_empty(): return evolve(item_id, creature_id, target_species)
	var creature := owner.owned_creature(creature_id)
	if creature != null and catalogs.species(creature.species_id) != null:
		for record: EvolutionRecord in catalogs.species(creature.species_id).evolutions:
			if record.item_id == item_id: return evolve(item_id, creature_id, target_species)
	return _deny("field_effect_not_connected", "DEPENDENCY_MISSING")


func _apply_field_effect(item_id: StringName, creature_id: StringName, move_slot: int) -> Dictionary:
	var creature := owner.owned_creature(creature_id)
	if creature == null: return _deny("creature_not_owned")
	if not owner.inventory.has(item_id): return _deny("item_not_owned")
	if creature.is_knocked_out(): return _deny("creature_knocked_out")
	if not creature.battle_transform_original.is_empty(): return _deny("temporary_battle_state")
	var source_error := FieldEffects.source_validation_error(creature, item_id, move_slot, catalogs)
	if source_error != "": return _deny(source_error)
	if FieldEffects.pp_boost_supports(item_id) and not content.move_learnable(String(creature.moveset[move_slot].move_id)):
		return _deny("move_not_permitted")
	var copy := CreatureInstance.from_dict(creature.to_dict())
	var result: Dictionary = FieldEffects.apply(copy, item_id, move_slot, catalogs)
	if not result.accepted: return result
	var staged := _bag_copy()
	if not staged.remove(item_id): return _deny("item_not_owned")
	if not owner.replace_owned_same_identity(copy): return _deny("ownership_changed")
	_publish_bag(staged)
	if creature.status_state.persistent_id == &"sleep" and copy.status_state.persistent_id != &"sleep": sleep_clocks.erase(String(creature_id))
	result["item_id"] = String(item_id); result["creature_id"] = String(creature_id)
	return result
