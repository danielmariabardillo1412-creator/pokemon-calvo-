class_name TrainerPokemonLoadout
extends RefCounted

const SCHEMA_VERSION := 1

const ROLE_BALANCED := &"balanced"
const ROLE_PHYSICAL_ATTACKER := &"physical_attacker"
const ROLE_SPECIAL_ATTACKER := &"special_attacker"
const ROLE_FAST_ATTACKER := &"fast_attacker"
const ROLE_BULKY_PHYSICAL := &"bulky_physical"
const ROLE_BULKY_SPECIAL := &"bulky_special"
const ROLE_SUPPORT := &"support"

const QUALITY_BASIC := &"basic"
const QUALITY_TRAINED := &"trained"
const QUALITY_EXPERT := &"expert"

const ROLES: Array[StringName] = [
	ROLE_BALANCED,
	ROLE_PHYSICAL_ATTACKER,
	ROLE_SPECIAL_ATTACKER,
	ROLE_FAST_ATTACKER,
	ROLE_BULKY_PHYSICAL,
	ROLE_BULKY_SPECIAL,
	ROLE_SUPPORT,
]
const QUALITIES: Array[StringName] = [QUALITY_BASIC, QUALITY_TRAINED, QUALITY_EXPERT]

var species_id: StringName = &""
var level: int = 1
var role_id: StringName = ROLE_BALANCED
var quality_id: StringName = QUALITY_BASIC
var nature_id: StringName = ProgressionRuleset.NEUTRAL_NATURE
var ivs: Dictionary = {}
var evs: Dictionary = {}
var ability_id: StringName = &""
var held_item_id: StringName = &""
var move_ids: Array[StringName] = []
var source_id: StringName = &"authored"


func to_dict() -> Dictionary:
	var moves: Array[String] = []
	for move_id in move_ids:
		moves.append(String(move_id))
	return {
		"schema_version": SCHEMA_VERSION,
		"species_id": String(species_id),
		"level": level,
		"role_id": String(role_id),
		"quality_id": String(quality_id),
		"nature_id": String(nature_id),
		"ivs": _canonical_stats(ivs),
		"evs": _canonical_stats(evs),
		"ability_id": String(ability_id),
		"held_item_id": String(held_item_id),
		"move_ids": moves,
		"source_id": String(source_id),
	}


static func from_dict(data: Dictionary) -> TrainerPokemonLoadout:
	assert(int(data.get("schema_version", -1)) == SCHEMA_VERSION, "Unsupported trainer loadout schema")
	var out := TrainerPokemonLoadout.new()
	out.species_id = StringName(data.get("species_id", ""))
	out.level = int(data.get("level", 1))
	out.role_id = StringName(data.get("role_id", String(ROLE_BALANCED)))
	out.quality_id = StringName(data.get("quality_id", String(QUALITY_BASIC)))
	out.nature_id = StringName(data.get("nature_id", String(ProgressionRuleset.NEUTRAL_NATURE)))
	out.ivs = _canonical_stats(data.get("ivs", {}) as Dictionary)
	out.evs = _canonical_stats(data.get("evs", {}) as Dictionary)
	out.ability_id = StringName(data.get("ability_id", ""))
	out.held_item_id = StringName(data.get("held_item_id", ""))
	for raw_id in data.get("move_ids", []):
		out.move_ids.append(StringName(raw_id))
	out.source_id = StringName(data.get("source_id", "authored"))
	return out


func signature() -> String:
	return JSON.stringify(to_dict())


static func _canonical_stats(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in ProgressionRuleset.STAT_KEYS:
		out[key] = int(source.get(key, 0))
	return out
