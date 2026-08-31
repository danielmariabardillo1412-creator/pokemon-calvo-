class_name TrainerArchetypeDefinition
extends RefCounted

const SCHEMA_VERSION := 1

const TIER_NOVICE := &"novice"
const TIER_STANDARD := &"standard"
const TIER_ACE := &"ace"
const TIER_LEADER := &"leader"
const TIER_ELITE := &"elite"
const TIER_CHAMPION := &"champion"
const TIER_SPECIAL_BOSS := &"special_boss"

const TIERS: Array[StringName] = [
	TIER_NOVICE,
	TIER_STANDARD,
	TIER_ACE,
	TIER_LEADER,
	TIER_ELITE,
	TIER_CHAMPION,
	TIER_SPECIAL_BOSS,
]

const BRAIN_TACTICAL := &"tactical"
# Semantic archetype id preserved from the interrupted FASE 34 draft. Runtime
# resolution deliberately maps this to the newest composite strategic brain.
const BRAIN_STRATEGIC_SEARCH := &"strategic_search"
const BRAIN_KINDS: Array[StringName] = [BRAIN_TACTICAL, BRAIN_STRATEGIC_SEARCH]

const PROFILE_IDS: Array[StringName] = [
	TrainerProfile.BALANCED,
	TrainerProfile.AGGRESSIVE,
	TrainerProfile.CAUTIOUS,
	TrainerProfile.TECHNICAL,
]

var archetype_id: StringName = TIER_STANDARD
var tier_rank: int = 1
var team_size: int = 3
var loadout_quality_id: StringName = TrainerPokemonLoadout.QUALITY_TRAINED
var brain_kind: StringName = BRAIN_TACTICAL
var profile_id: StringName = TrainerProfile.BALANCED
var search_budget: TrainerSearchBudget = TrainerSearchBudget.constrained(1, 1, 48, 2)
var bag_items: Dictionary = {}
var allow_duplicate_species: bool = false
# Reservation only. Revive is intentionally not a runtime trainer item in FASE 34.
# A future special-encounter layer may materialize at most this reserved allowance.
var reserved_revive_cap: int = 0
var source_id: StringName = &"authored"


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not TIERS.has(archetype_id):
		errors.append("unknown_archetype_id:%s" % String(archetype_id))
	else:
		var expected_rank := _expected_rank(archetype_id)
		if tier_rank != expected_rank:
			errors.append("tier_rank_mismatch:%s:%d:%d" % [String(archetype_id), tier_rank, expected_rank])
	if team_size < 1 or team_size > PartyRuleset.MAX_PARTY:
		errors.append("team_size_out_of_range:%d" % team_size)
	if not TrainerPokemonLoadout.QUALITIES.has(loadout_quality_id):
		errors.append("unknown_loadout_quality:%s" % String(loadout_quality_id))
	if not BRAIN_KINDS.has(brain_kind):
		errors.append("unknown_brain_kind:%s" % String(brain_kind))
	if not PROFILE_IDS.has(profile_id):
		errors.append("unknown_profile_id:%s" % String(profile_id))
	if search_budget == null:
		errors.append("search_budget_missing")

	var registry := BattleEffectRegistry.new()
	for raw_id in bag_items.keys():
		var item_id := StringName(raw_id)
		var amount := int(bag_items[raw_id])
		if item_id == &"":
			errors.append("bag_item_id_empty")
		elif not registry.is_trainer_item_supported(item_id):
			errors.append("unsupported_bag_item:%s" % String(item_id))
		if amount < 0:
			errors.append("bag_item_negative:%s" % String(item_id))

	if reserved_revive_cap < 0 or reserved_revive_cap > 1:
		errors.append("reserved_revive_cap_out_of_range:%d" % reserved_revive_cap)
	if archetype_id != TIER_SPECIAL_BOSS and reserved_revive_cap != 0:
		errors.append("reserved_revive_requires_special_boss")
	if source_id == &"":
		errors.append("source_id_empty")
	return errors


func is_valid() -> bool:
	return validate().is_empty()


func total_bag_items() -> int:
	var total := 0
	for raw_id in bag_items.keys():
		total += maxi(0, int(bag_items[raw_id]))
	return total


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
	out.archetype_id = StringName(data.get("archetype_id", String(TIER_STANDARD)))
	out.tier_rank = int(data.get("tier_rank", 1))
	out.team_size = int(data.get("team_size", 3))
	out.loadout_quality_id = StringName(data.get("loadout_quality_id", String(TrainerPokemonLoadout.QUALITY_TRAINED)))
	out.brain_kind = StringName(data.get("brain_kind", String(BRAIN_TACTICAL)))
	out.profile_id = StringName(data.get("profile_id", String(TrainerProfile.BALANCED)))
	var budget_data := data.get("search_budget", {}) as Dictionary
	out.search_budget = TrainerSearchBudget.constrained(
		int(budget_data.get("depth_turns", 1)),
		int(budget_data.get("max_worlds", 1)),
		int(budget_data.get("max_simulations", 48)),
		int(budget_data.get("max_actions_per_side", 2)),
	)
	var raw_items := data.get("bag_items", {}) as Dictionary
	for raw_id in raw_items.keys():
		var amount := int(raw_items[raw_id])
		if amount != 0:
			out.bag_items[StringName(raw_id)] = amount
	out.allow_duplicate_species = bool(data.get("allow_duplicate_species", false))
	out.reserved_revive_cap = int(data.get("reserved_revive_cap", 0))
	out.source_id = StringName(data.get("source_id", "authored"))
	return out


func duplicate_archetype() -> TrainerArchetypeDefinition:
	return TrainerArchetypeDefinition.from_dict(to_dict())


func signature() -> String:
	return JSON.stringify(to_dict())


static func _expected_rank(tier_id: StringName) -> int:
	match tier_id:
		TIER_NOVICE:
			return 0
		TIER_STANDARD:
			return 1
		TIER_ACE:
			return 2
		TIER_LEADER:
			return 3
		TIER_ELITE:
			return 4
		TIER_CHAMPION:
			return 5
		TIER_SPECIAL_BOSS:
			return 6
		_:
			return -1
