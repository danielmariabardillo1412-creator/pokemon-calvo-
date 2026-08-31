class_name TrainerArchetypeLibrary
extends RefCounted

const MODEL_ID := "trainer_archetype_library_v1"


static func defaults() -> Dictionary:
	var out: Dictionary = {}
	for archetype in [
		novice(),
		standard(),
		ace(),
		leader(),
		elite(),
		champion(),
		special_boss(),
	]:
		out[archetype.archetype_id] = archetype
	return out


static func by_id(archetype_id: StringName) -> TrainerArchetypeDefinition:
	var archetypes := defaults()
	var found := archetypes.get(archetype_id) as TrainerArchetypeDefinition
	return found.duplicate_archetype() if found != null else null


static func novice() -> TrainerArchetypeDefinition:
	return _make(
		TrainerArchetypeDefinition.TIER_NOVICE,
		0,
		2,
		TrainerPokemonLoadout.QUALITY_BASIC,
		TrainerArchetypeDefinition.BRAIN_TACTICAL,
		TrainerProfile.BALANCED,
		TrainerSearchBudget.constrained(1, 1, 24, 2),
		{},
		0,
	)


static func standard() -> TrainerArchetypeDefinition:
	return _make(
		TrainerArchetypeDefinition.TIER_STANDARD,
		1,
		3,
		TrainerPokemonLoadout.QUALITY_TRAINED,
		TrainerArchetypeDefinition.BRAIN_TACTICAL,
		TrainerProfile.BALANCED,
		TrainerSearchBudget.constrained(1, 1, 48, 2),
		{},
		0,
	)


static func ace() -> TrainerArchetypeDefinition:
	return _make(
		TrainerArchetypeDefinition.TIER_ACE,
		2,
		3,
		TrainerPokemonLoadout.QUALITY_TRAINED,
		TrainerArchetypeDefinition.BRAIN_STRATEGIC_SEARCH,
		TrainerProfile.BALANCED,
		TrainerSearchBudget.constrained(1, 2, 96, 3),
		{&"super_potion": 1},
		0,
	)


static func leader() -> TrainerArchetypeDefinition:
	return _make(
		TrainerArchetypeDefinition.TIER_LEADER,
		3,
		4,
		TrainerPokemonLoadout.QUALITY_EXPERT,
		TrainerArchetypeDefinition.BRAIN_STRATEGIC_SEARCH,
		TrainerProfile.TECHNICAL,
		TrainerSearchBudget.constrained(2, 2, 128, 3),
		{&"hyper_potion": 1},
		0,
	)


static func elite() -> TrainerArchetypeDefinition:
	return _make(
		TrainerArchetypeDefinition.TIER_ELITE,
		4,
		5,
		TrainerPokemonLoadout.QUALITY_EXPERT,
		TrainerArchetypeDefinition.BRAIN_STRATEGIC_SEARCH,
		TrainerProfile.TECHNICAL,
		TrainerSearchBudget.constrained(2, 3, 180, 3),
		{&"full_restore": 1},
		0,
	)


static func champion() -> TrainerArchetypeDefinition:
	return _make(
		TrainerArchetypeDefinition.TIER_CHAMPION,
		5,
		6,
		TrainerPokemonLoadout.QUALITY_EXPERT,
		TrainerArchetypeDefinition.BRAIN_STRATEGIC_SEARCH,
		TrainerProfile.TECHNICAL,
		TrainerSearchBudget.constrained(2, 4, 220, 4),
		{&"full_restore": 1},
		0,
	)


static func special_boss() -> TrainerArchetypeDefinition:
	return _make(
		TrainerArchetypeDefinition.TIER_SPECIAL_BOSS,
		6,
		6,
		TrainerPokemonLoadout.QUALITY_EXPERT,
		TrainerArchetypeDefinition.BRAIN_STRATEGIC_SEARCH,
		TrainerProfile.TECHNICAL,
		TrainerSearchBudget.constrained(2, 4, 256, 4),
		{&"full_restore": 1, &"hyper_potion": 1},
		1,
	)


static func _make(
	id: StringName,
	rank: int,
	team_size: int,
	quality: StringName,
	brain_kind: StringName,
	profile_id: StringName,
	budget: TrainerSearchBudget,
	bag_items: Dictionary,
	reserved_revive_cap: int,
) -> TrainerArchetypeDefinition:
	var out := TrainerArchetypeDefinition.new()
	out.archetype_id = id
	out.tier_rank = rank
	out.team_size = team_size
	out.loadout_quality_id = quality
	out.brain_kind = brain_kind
	out.profile_id = profile_id
	out.search_budget = budget.duplicate_budget()
	out.bag_items = bag_items.duplicate(true)
	out.reserved_revive_cap = reserved_revive_cap
	out.source_id = &"default_archetype_v1"
	return out
