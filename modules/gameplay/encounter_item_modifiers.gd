extends RefCounted

# O120 encounter-rate rule for Cleanse Tag and Pure Incense. Pure domain rule:
# no UI, no IO, no RNG of its own and no new persistent fields.
#
# Reference: Essentials 8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b,
# 012_Overworld/002_Battle triggering/003_Overworld_WildEncounters.rb:
#   first_pkmn = $player.first_pokemon
#   when :CLEANSETAG then encounter_chance *= 2.0 / 3 ; min_steps_needed *= 4 / 3.0
#   when :PUREINCENSE then encounter_chance *= 2.0 / 3 ; min_steps_needed *= 4 / 3.0
# first_pokemon is the first non-egg party member, fainted or not (001_Trainer.rb).
#
# The current profile has no minimum-step semantics, so the step-period half of
# the reference is NOT representable: the verified scope is the rate only
# (PARTIAL_VERIFIED_RATE_ONLY). The resolver and its RNG stay intact because the
# helper returns a validated COPY of the table and never edits the original.

const CLEANSE_TAG := &"cleanse_tag"
const PURE_INCENSE := &"pure_incense"
const RATE_NUMERATOR := 2
const RATE_DENOMINATOR := 3


static func supports(item_id: StringName) -> bool:
	return item_id == CLEANSE_TAG or item_id == PURE_INCENSE


static func modified_chance_bp(base_bp: int) -> int:
	# 0 keeps the table disabled; a positive chance keeps at least one basis
	# point so a legal encounter is never silently erased by rounding.
	if base_bp <= 0:
		return base_bp
	return maxi(1, roundi(float(base_bp) * RATE_NUMERATOR / RATE_DENOMINATOR))


# Item held by the effective leader, or &"" when absent/already consumed.
static func leader_item(party: Array) -> StringName:
	for creature: Variant in party:
		if creature == null:
			continue
		if bool(creature.held_item_consumed) or creature.held_item_id == &"":
			return &""
		return creature.held_item_id
	return &""


static func prepare_table(table: WildEncounterTable, party: Array) -> WildEncounterTable:
	# Returns the original table untouched unless the leader really holds an
	# active Cleanse Tag/Pure Incense and the modified copy validates.
	if table == null or table.corrupted:
		return table
	if not supports(leader_item(party)):
		return table
	var copy := WildEncounterTable.from_dict(table.to_dict())
	if copy.corrupted:
		return table
	copy.encounter_chance_bp = modified_chance_bp(table.encounter_chance_bp)
	if not copy.validate().ok:
		return table
	return copy
