extends RefCounted

# W02 authorised mint pilot, precisely blocks 04/09 and IA6 authorised MINT-L3 pilots 01 (lonely/mild/naive) and 02 (adamant/modest/timid).
# No inventory, save IO, mutation of live owner or global stat-rule changes.
const MINTS := {
	"naughty_mint": "naughty",
	"gentle_mint": "gentle",
	"lonely_mint": "lonely",
	"mild_mint": "mild",
	"naive_mint": "naive",
	"adamant_mint": "adamant",
	"modest_mint": "modest",
	"timid_mint": "timid",
	"rash_mint": "rash",
	"sassy_mint": "sassy",
	"serious_mint": "serious",
}


static func supports(item_id: StringName) -> bool:
	return MINTS.has(String(item_id))


static func reject(reason: String) -> Dictionary:
	return {"accepted": false, "status": "REJECTED", "reason": reason}


static func apply(candidate: CreatureInstance, item_id: StringName, catalogs: DefinitionCatalog) -> Dictionary:
	if not supports(item_id): return reject("field_effect_not_connected")
	if candidate == null or candidate.is_knocked_out(): return reject("creature_knocked_out")
	if not candidate.battle_transform_original.is_empty(): return reject("temporary_battle_state")
	if catalogs == null: return reject("unknown_species")
	var species: CreatureSpecies = catalogs.species(candidate.species_id)
	if species == null: return reject("unknown_species")
	if not ProgressionRuleset.is_valid_nature(candidate.nature_id): return reject("invalid_original_nature")
	if candidate.effective_nature_id != &"" and not ProgressionRuleset.is_valid_nature(candidate.effective_nature_id):
		return reject("invalid_effective_nature")
	if candidate.stats == null or candidate.current_hp <= 0 or candidate.current_hp > candidate.stats.max_hp:
		return reject("invalid_mint_state")
	if candidate.level < 1 or candidate.level > 100: return reject("invalid_mint_state")
	var current_nature: StringName = candidate.nature_id if candidate.effective_nature_id == &"" else candidate.effective_nature_id
	var expected: StatBlock = StatCalculator.compute(
		species.base_stat_block(), candidate.ivs, candidate.evs, current_nature, candidate.level)
	if expected.to_dict() != candidate.stats.to_dict(): return reject("invalid_mint_state")
	var desired: StringName = StringName(MINTS[String(item_id)])
	if not ProgressionRuleset.is_valid_nature(desired): return reject("invalid_effective_nature")
	if current_nature == desired: return reject("item_has_no_effect")
	var old_hp: int = candidate.current_hp
	var before: Dictionary = candidate.stats.to_dict()
	candidate.effective_nature_id = desired
	candidate.recalculate_stats(species, ProgressionRuleset.new())
	if candidate.stats.to_dict() == before:
		candidate.effective_nature_id = current_nature if current_nature != candidate.nature_id else &""
		candidate.recalculate_stats(species, ProgressionRuleset.new())
		return reject("item_has_no_effect")
	if candidate.stats.max_hp != int(before.max_hp) or candidate.current_hp != old_hp:
		return reject("invalid_mint_state")
	return {"accepted": true, "status": "APPLIED", "action": "effective_nature",
		"effective_nature_id": String(desired), "original_nature_id": String(candidate.nature_id)}
