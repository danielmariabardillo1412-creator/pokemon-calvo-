class_name WildEncounterRuleset
extends RefCounted

const SCHEMA_VERSION := 1
const ID := &"calvo_wild_encounters_v1"
const CHANCE_BP_MIN := 0
const CHANCE_BP_MAX := 10000
const MAX_SLOT_WEIGHT := 1000000
const MAX_TOTAL_WEIGHT := 2000000000


static func is_valid_chance_bp(value: int) -> bool:
	return value >= CHANCE_BP_MIN and value <= CHANCE_BP_MAX


static func is_valid_level(value: int) -> bool:
	return value >= 1 and value <= ProgressionRuleset.MAX_LEVEL


static func is_valid_weight(value: int) -> bool:
	return value > 0 and value <= MAX_SLOT_WEIGHT
