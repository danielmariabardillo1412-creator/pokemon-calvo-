class_name TrainerTeamDefinition
extends RefCounted

const SCHEMA_VERSION := 1

var team_id: StringName = &""
var loadouts: Array[TrainerPokemonLoadout] = []
var lead_index: int = 0
var allow_duplicate_species: bool = false
var source_id: StringName = &"authored"


func to_dict() -> Dictionary:
	var serialized: Array[Dictionary] = []
	for loadout in loadouts:
		if loadout != null:
			serialized.append(loadout.to_dict())
	return {
		"schema_version": SCHEMA_VERSION,
		"team_id": String(team_id),
		"loadouts": serialized,
		"lead_index": lead_index,
		"allow_duplicate_species": allow_duplicate_species,
		"source_id": String(source_id),
	}


static func from_dict(data: Dictionary) -> TrainerTeamDefinition:
	assert(int(data.get("schema_version", -1)) == SCHEMA_VERSION, "Unsupported trainer team schema")
	var out := TrainerTeamDefinition.new()
	out.team_id = StringName(data.get("team_id", ""))
	out.lead_index = int(data.get("lead_index", 0))
	out.allow_duplicate_species = bool(data.get("allow_duplicate_species", false))
	out.source_id = StringName(data.get("source_id", "authored"))
	for raw_loadout in data.get("loadouts", []):
		out.loadouts.append(TrainerPokemonLoadout.from_dict(raw_loadout as Dictionary))
	return out


func signature() -> String:
	return JSON.stringify(to_dict())


func size() -> int:
	return loadouts.size()
