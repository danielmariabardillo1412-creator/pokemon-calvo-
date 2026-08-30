class_name TrainerTeamFactory
extends RefCounted

const MODEL_ID := "trainer_team_materializer_v1"

var _validator: TrainerTeamValidator
var _loadout_factory: TrainerLoadoutFactory
var last_validation: Dictionary = {}


func _init(catalog: DefinitionCatalog) -> void:
	_validator = TrainerTeamValidator.new(catalog)
	_loadout_factory = TrainerLoadoutFactory.new(catalog)


func materialize(team: TrainerTeamDefinition) -> Array[CreatureInstance]:
	var authored: Array[CreatureInstance] = []
	last_validation = _validator.validate(team)
	if not bool(last_validation.get("valid", false)):
		return authored
	for index in range(team.loadouts.size()):
		var loadout := team.loadouts[index]
		var instance_id := StringName("%s_%02d_%s" % [
			String(team.team_id),
			index + 1,
			String(loadout.species_id),
		])
		var creature := _loadout_factory.materialize(loadout, instance_id)
		if creature == null:
			authored.clear()
			last_validation = {
				"valid": false,
				"errors": ["member_materialization_failed:%d" % index],
				"member_errors": {index: _loadout_factory.last_validation.duplicate(true)},
				"model": MODEL_ID,
			}
			return authored
		authored.append(creature)

	# The battle/session stack commonly treats roster[0] as the initial active. Preserve
	# authored member data/IDs but rotate only the returned battle roster so lead_index
	# has operational meaning without mutating the TrainerTeamDefinition.
	if team.lead_index <= 0:
		return authored
	var ordered: Array[CreatureInstance] = []
	ordered.append(authored[team.lead_index])
	for index in range(authored.size()):
		if index != team.lead_index:
			ordered.append(authored[index])
	return ordered
