class_name TrainerArchetypeDefinition
extends RefCounted

const SCHEMA_VERSION := 1

const BRAIN_TACTICAL := &"tactical"
const BRAIN_STRATEGIC_SEARCH := &"strategic_search"
const BRAIN_KINDS: Array[StringName] = [BRAIN_TACTICAL, BRAIN_STRATEGIC_SEARCH]

const TIER_NOVICE := &"novice"
const TIER_STANDARD := &"standard"
const TIER_ACE := &"ace"
const TIER_LEADER := &"leader"
const TIER_ELITE := &"elite"
const TIER_CHAMPION := &"champion"
const TIER_SPECIAL_BOSS := &"special_boss"

var archetype_id: StringName = &""
var tier_rank: int = 0
var team_size: int = 1
var loadout_quality_id: StringName = TrainerPokemonLoadout.QUALITY_BASIC
var brain_kind: StringName = BRAIN_TACTICAL
var profile_id: StringName = TrainerProfile.BALANCED
var search_budget: TrainerSearchBudget = TrainerSearchBudget.constrained(1, 1, 32, 2)
var bag_items: Dictionary = {}
var allow_duplicate_species: bool = false
# Reserved policy only. FASE 34 never materializes Revive. A future phase may turn
# this reservation into one finite item for explicitly special encounters.
var reserved_revive_cap: int = 0
var source_id: StringName = &"authored"


func to_dict() -> Dictionary:
	var items: Dictionary = {}
	var keys := bag_items.keys()
	keys.sort_custom(func(a, b): return String(a) < String(b))
	for raw_id in keys:
		var amount := int(bag_items[raw_id])
		if amount > 0:
			items[String(raw_id)] = amount
	return {
		"schema_version": SCHEMA_VERSION,
		"archetype_id": String(archetype_id),
		"tier_rank": tier_rank,
		"team_size": team_size,
		"loadout_quality_id": String(loadout_quality_id),
		"brain_kind": String(brain_kind),
		"profile_id": String(profile_id),
		"search_budget": search_budget.to_dict() if search_budget != null else {},
		"bag_items": items,
		"allow_duplicate_species": allow_duplicate_species,
		"reserved_revive_cap": reserved_revive_cap,
		"source_id": String(source_id),
	}


static func from_dict(data: Dictionary) -> TrainerArchetypeDefinition:
	assert(int(data.get("schema_version", -1)) == SCHEMA_VERSION, "Unsupported trainer archetype schema")
	var out := TrainerArchetypeDefinition.new()
	out.archetype_id = StringName(data.get("archetype_id", ""))
	out.tier_rank = int(data.get("tier_rank", 0))
	out.team_size = int(data.get("team_size", 1))
	out.loadout_quality_id = StringName(data.get("loadout_quality_id", String(TrainerPokemonLoadout.QUALITY_BASIC)))
	out.brain_kind = StringName(data.get("brain_kind", String(BRAIN_TACTICAL)))
	out.profile_id = StringName(data.get("profile_id", String(TrainerProfile.BALANCED)))
	var budget_data := data.get("search_budget", {}) as Dictionary
	out.search_budget = TrainerSearchBudget.constrained(
		int(budget_data.get("depth_turns", 1)),
		int(budget_data.get("max_worlds", 1)),
		int(budget_data.get("max_simulations", 32)),
		int(budget_data.get("max_actions_per_side", 2)),
	)
	for raw_id in (data.get("bag_items", {}) as Dictionary).keys():
		var amount := int((data.get("bag_items", {}) as Dictionary)[raw_id])
		if amount > 0:
			out.bag_items[StringName(raw_id)] = amount
	out.allow_duplicate_species = bool(data.get("allow_duplicate_species", false))
	out.reserved_revive_cap = int(data.get("reserved_revive_cap", 0))
	out.source_id = StringName(data.get("source_id", "authored"))
	return out


func signature() -> String:
	return JSON.stringify(to_dict())
