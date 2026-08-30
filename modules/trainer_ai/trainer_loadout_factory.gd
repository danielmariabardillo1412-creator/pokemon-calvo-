class_name TrainerLoadoutFactory
extends RefCounted

const MODEL_ID := "trainer_loadout_materializer_v1"

var _catalog: DefinitionCatalog
var _validator: TrainerLoadoutValidator
var last_validation: Dictionary = {}


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog
	_validator = TrainerLoadoutValidator.new(catalog)


func materialize(
	loadout: TrainerPokemonLoadout,
	instance_id: StringName,
) -> CreatureInstance:
	last_validation = _validator.validate(loadout)
	if not bool(last_validation.get("valid", false)):
		return null
	var species := _catalog.species(loadout.species_id)
	if species == null or instance_id == &"":
		last_validation = {
			"valid": false,
			"errors": ["materialization_identity_invalid"],
			"model": MODEL_ID,
		}
		return null

	var creature := CreatureInstance.new(
		instance_id,
		loadout.species_id,
		loadout.level,
		StatBlock.new(),
		[],
	)
	creature.ivs = loadout.ivs.duplicate(true)
	creature.evs = loadout.evs.duplicate(true)
	creature.nature_id = loadout.nature_id
	creature.ability_id = loadout.ability_id
	creature.held_item_id = loadout.held_item_id
	creature.experience = ProgressionRuleset.experience_for_level(species.growth_rate, loadout.level)
	creature.recalculate_stats(species, ProgressionRuleset.new())
	creature.current_hp = creature.stats.max_hp

	for move_id in loadout.move_ids:
		var move := _catalog.move(move_id)
		if move == null:
			return null
		var slot := BattleMoveSlot.new(move_id)
		slot.initialize(move)
		creature.moveset.append(slot)
		creature.move_ids.append(move_id)
	return creature
