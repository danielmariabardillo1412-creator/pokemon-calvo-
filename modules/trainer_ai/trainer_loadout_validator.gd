class_name TrainerLoadoutValidator
extends RefCounted

const MODEL_ID := "trainer_loadout_validation_v1"

var _catalog: DefinitionCatalog
var _registry := BattleEffectRegistry.new()


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog


func validate(loadout: TrainerPokemonLoadout) -> Dictionary:
	var errors: Array[String] = []
	if loadout == null:
		return _result(false, ["loadout_null"])
	if _catalog == null:
		return _result(false, ["catalog_null"])

	var species := _catalog.species(loadout.species_id)
	if species == null:
		errors.append("species_unknown")
	if loadout.level < ProgressionRuleset.MIN_LEVEL or loadout.level > ProgressionRuleset.MAX_LEVEL:
		errors.append("level_out_of_range")
	if not TrainerPokemonLoadout.ROLES.has(loadout.role_id):
		errors.append("role_unknown")
	if not TrainerPokemonLoadout.QUALITIES.has(loadout.quality_id):
		errors.append("quality_unknown")
	if not ProgressionRuleset.is_valid_nature(loadout.nature_id):
		errors.append("nature_unknown")

	_validate_stats(loadout.ivs, true, errors)
	_validate_stats(loadout.evs, false, errors)

	if species != null:
		_validate_ability(loadout, species, errors)
	_validate_item(loadout, errors)
	if species != null:
		_validate_moves(loadout, species, errors)

	return _result(errors.is_empty(), errors)


func _validate_stats(source: Dictionary, ivs: bool, errors: Array[String]) -> void:
	var total := 0
	for key in ProgressionRuleset.STAT_KEYS:
		var value := int(source.get(key, 0))
		if ivs:
			if value < ProgressionRuleset.IV_MIN or value > ProgressionRuleset.IV_MAX:
				errors.append("iv_out_of_range:%s" % key)
		else:
			if value < 0 or value > ProgressionRuleset.EV_PER_STAT_MAX:
				errors.append("ev_out_of_range:%s" % key)
			total += value
	if not ivs and total > ProgressionRuleset.EV_TOTAL_MAX:
		errors.append("ev_total_exceeded")


func _validate_ability(
	loadout: TrainerPokemonLoadout,
	species: CreatureSpecies,
	errors: Array[String],
) -> void:
	if loadout.ability_id == &"":
		return
	if _catalog.ability(loadout.ability_id) == null:
		errors.append("ability_unknown")
		return
	if not species.ability_ids.has(loadout.ability_id):
		errors.append("ability_not_species_compatible")
	if not _registry.runtime_supported_ability_ids().has(loadout.ability_id):
		errors.append("ability_not_runtime_supported")


func _validate_item(loadout: TrainerPokemonLoadout, errors: Array[String]) -> void:
	if loadout.held_item_id == &"":
		return
	if _catalog.item(loadout.held_item_id) == null:
		errors.append("held_item_unknown")
		return
	if not _registry.runtime_supported_item_ids().has(loadout.held_item_id):
		errors.append("held_item_not_runtime_supported")


func _validate_moves(
	loadout: TrainerPokemonLoadout,
	species: CreatureSpecies,
	errors: Array[String],
) -> void:
	if loadout.move_ids.is_empty():
		errors.append("moveset_empty")
	if loadout.move_ids.size() > ProgressionRuleset.MOVE_SLOTS_MAX:
		errors.append("moveset_too_large")
	var seen: Dictionary = {}
	for move_id in loadout.move_ids:
		if seen.has(move_id):
			errors.append("duplicate_move:%s" % String(move_id))
		else:
			seen[move_id] = true
		if _catalog.move(move_id) == null:
			errors.append("move_unknown:%s" % String(move_id))
			continue
		if not _species_can_use_move(species, loadout.level, move_id):
			errors.append("move_not_species_compatible:%s" % String(move_id))


func _species_can_use_move(
	species: CreatureSpecies,
	level: int,
	move_id: StringName,
) -> bool:
	for raw_entry in species.learnset:
		if not (raw_entry is LearnSetEntry):
			continue
		var entry := raw_entry as LearnSetEntry
		if entry.move_id != move_id:
			continue
		if entry.method == LearnsetSystem.LEVEL_UP:
			if entry.level <= level:
				return true
		elif TrainerPublicCoverageBeliefInference.is_supported_coverage_method(entry.method):
			# Dataset does not retain exact version_group. This means public species
			# compatibility, not a claim of generation-specific legality.
			return true
	return false


func _result(valid: bool, errors: Array[String]) -> Dictionary:
	return {
		"valid": valid,
		"errors": errors.duplicate(),
		"model": MODEL_ID,
	}
