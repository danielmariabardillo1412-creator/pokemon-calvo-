class_name TrainerTeamValidator
extends RefCounted

const MODEL_ID := "trainer_team_validation_v1"

var _loadout_validator: TrainerLoadoutValidator


func _init(catalog: DefinitionCatalog) -> void:
	_loadout_validator = TrainerLoadoutValidator.new(catalog)


func validate(team: TrainerTeamDefinition) -> Dictionary:
	var errors: Array[String] = []
	var member_errors: Dictionary = {}
	if team == null:
		return _result(false, ["team_null"], {})
	if team.team_id == &"":
		errors.append("team_id_empty")
	if team.loadouts.is_empty():
		errors.append("team_empty")
	if team.loadouts.size() > PartyRuleset.MAX_PARTY:
		errors.append("team_too_large")
	if not team.loadouts.is_empty() and (team.lead_index < 0 or team.lead_index >= team.loadouts.size()):
		errors.append("lead_index_out_of_range")

	var species_counts: Dictionary = {}
	for index in range(team.loadouts.size()):
		var loadout := team.loadouts[index]
		if loadout == null:
			member_errors[index] = ["loadout_null"]
			continue
		var validation := _loadout_validator.validate(loadout)
		if not bool(validation.get("valid", false)):
			member_errors[index] = (validation.get("errors", []) as Array).duplicate()
		var key := String(loadout.species_id)
		species_counts[key] = int(species_counts.get(key, 0)) + 1

	if not team.allow_duplicate_species:
		for species_id in species_counts.keys():
			if int(species_counts[species_id]) > 1:
				errors.append("duplicate_species:%s" % String(species_id))

	return _result(errors.is_empty() and member_errors.is_empty(), errors, member_errors)


func _result(valid: bool, errors: Array[String], member_errors: Dictionary) -> Dictionary:
	return {
		"valid": valid,
		"errors": errors.duplicate(),
		"member_errors": member_errors.duplicate(true),
		"model": MODEL_ID,
	}
