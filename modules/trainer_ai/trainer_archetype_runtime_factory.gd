class_name TrainerArchetypeRuntimeFactory
extends RefCounted

const MODEL_ID := "trainer_archetype_runtime_factory_v1"

var _catalog: DefinitionCatalog
var _composer: TrainerTeamComposer
var _team_factory: TrainerTeamFactory


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog
	_composer = TrainerTeamComposer.new(catalog) if catalog != null else null
	_team_factory = TrainerTeamFactory.new(catalog) if catalog != null else null


func profile_for(archetype: TrainerArchetypeDefinition) -> TrainerProfile:
	if not _is_usable(archetype):
		return null
	match archetype.profile_id:
		TrainerProfile.BALANCED:
			return TrainerProfile.balanced()
		TrainerProfile.AGGRESSIVE:
			return TrainerProfile.aggressive()
		TrainerProfile.CAUTIOUS:
			return TrainerProfile.cautious()
		TrainerProfile.TECHNICAL:
			return TrainerProfile.technical()
		_:
			return null


func brain_for(archetype: TrainerArchetypeDefinition) -> TrainerBrain:
	if not _is_usable(archetype):
		return null
	var profile := profile_for(archetype)
	if profile == null:
		return null
	match archetype.brain_kind:
		TrainerArchetypeDefinition.BRAIN_TACTICAL:
			return TacticalTrainerBrain.new(_catalog, profile)
		TrainerArchetypeDefinition.BRAIN_STRATEGIC_SEARCH:
			# The archetype id is intentionally stable, but the implementation is the
			# newest safe composite: bounded search + item awareness + switching V2.
			return StrategicSwitchingTrainerBrain.new(
				_catalog,
				profile,
				archetype.search_budget.duplicate_budget(),
			)
		_:
			return null


func controller_for(
	side_id: StringName,
	archetype: TrainerArchetypeDefinition,
) -> TrainerIntelligenceController:
	if side_id == &"":
		return null
	var brain := brain_for(archetype)
	if brain == null:
		return null
	# The controller remains the information firewall. Archetypes choose policy and
	# compute budget only; they never receive BattleState or hidden rival resources.
	return TrainerIntelligenceController.new(side_id, brain, _catalog)


func compose_team(
	archetype: TrainerArchetypeDefinition,
	team_id: StringName,
	species_pool: Array[StringName],
	level: int,
) -> TrainerTeamDefinition:
	if not _is_usable(archetype) or _composer == null:
		return null
	return _composer.compose(
		team_id,
		species_pool,
		level,
		archetype.team_size,
		archetype.loadout_quality_id,
		archetype.allow_duplicate_species,
	)


func materialize_team(
	archetype: TrainerArchetypeDefinition,
	team_id: StringName,
	species_pool: Array[StringName],
	level: int,
) -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	if _team_factory == null:
		return out
	var team := compose_team(archetype, team_id, species_pool, level)
	if team == null:
		return out
	return _team_factory.materialize(team)


func item_inventory_for(archetype: TrainerArchetypeDefinition) -> BattleSideItemInventory:
	if not _is_usable(archetype):
		return null
	var inventory := BattleSideItemInventory.new()
	for raw_id in archetype.bag_items.keys():
		var amount := int(archetype.bag_items[raw_id])
		if amount > 0:
			inventory.set_quantity(StringName(raw_id), amount)
	return inventory


func apply_item_inventory(
	state: BattleState,
	side_id: StringName,
	archetype: TrainerArchetypeDefinition,
) -> bool:
	if state == null or side_id == &"":
		return false
	var inventory := item_inventory_for(archetype)
	if inventory == null:
		return false
	state.set_item_inventory_for_side(side_id, inventory)
	return true


func _is_usable(archetype: TrainerArchetypeDefinition) -> bool:
	return _catalog != null and archetype != null and archetype.is_valid()
