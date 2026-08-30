class_name TrainerTeamComposer
extends RefCounted

const MODEL_ID := "trainer_team_composer_greedy_v1"

var _catalog: DefinitionCatalog
var _loadout_generator: TrainerRoleLoadoutGenerator
var _loadout_validator: TrainerLoadoutValidator
var _analyzer: TrainerTeamAnalyzer


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog
	_loadout_generator = TrainerRoleLoadoutGenerator.new(catalog)
	_loadout_validator = TrainerLoadoutValidator.new(catalog)
	_analyzer = TrainerTeamAnalyzer.new(catalog)


func compose(
	team_id: StringName,
	species_pool: Array[StringName],
	level: int,
	target_size: int,
	quality_id: StringName,
	allow_duplicate_species: bool = false,
) -> TrainerTeamDefinition:
	if _catalog == null or team_id == &"" or target_size < 1 or target_size > PartyRuleset.MAX_PARTY:
		return null
	if species_pool.is_empty():
		return null

	var pool := species_pool.duplicate()
	pool.sort_custom(func(a: StringName, b: StringName): return String(a) < String(b))
	var team := TrainerTeamDefinition.new()
	team.team_id = team_id
	team.allow_duplicate_species = allow_duplicate_species
	team.source_id = &"greedy_composed_v1"
	var used_species: Dictionary = {}

	while team.loadouts.size() < target_size:
		var best: TrainerPokemonLoadout = null
		var best_score := -2147483648
		var best_key := ""
		for species_id in pool:
			if not allow_duplicate_species and used_species.has(species_id):
				continue
			var species := _catalog.species(species_id)
			if species == null:
				continue
			for role_id in TrainerPokemonLoadout.ROLES:
				var candidate := _loadout_generator.generate(species_id, level, role_id, quality_id)
				if candidate == null:
					continue
				if not bool(_loadout_validator.validate(candidate).get("valid", false)):
					continue
				var trial := _with_candidate(team, candidate)
				var analysis := _analyzer.analyze(trial)
				var score := int(analysis.get("synergy_score", 0))
				score += _role_fit(species, role_id) * 4
				# Prefer a new role when scores are otherwise close; the analyzer already
				# rewards diversity, this small term makes the intent explicit.
				if not _team_has_role(team, role_id):
					score += 300
				var key := "%s|%s" % [String(species_id), String(role_id)]
				if best == null or score > best_score or (score == best_score and key < best_key):
					best = candidate
					best_score = score
					best_key = key
		if best == null:
			return null
		team.loadouts.append(TrainerPokemonLoadout.from_dict(best.to_dict()))
		used_species[best.species_id] = true

	team.lead_index = _select_lead_index(team)
	return team


func _with_candidate(
	team: TrainerTeamDefinition,
	candidate: TrainerPokemonLoadout,
) -> TrainerTeamDefinition:
	var out := TrainerTeamDefinition.new()
	out.team_id = team.team_id
	out.allow_duplicate_species = team.allow_duplicate_species
	out.source_id = team.source_id
	for loadout in team.loadouts:
		out.loadouts.append(TrainerPokemonLoadout.from_dict(loadout.to_dict()))
	out.loadouts.append(TrainerPokemonLoadout.from_dict(candidate.to_dict()))
	return out


func _team_has_role(team: TrainerTeamDefinition, role_id: StringName) -> bool:
	for loadout in team.loadouts:
		if loadout != null and loadout.role_id == role_id:
			return true
	return false


func _role_fit(species: CreatureSpecies, role_id: StringName) -> int:
	if species == null:
		return 0
	match role_id:
		TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER:
			return species.base_attack * 2 + species.base_speed
		TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER:
			return species.base_special_attack * 2 + species.base_speed
		TrainerPokemonLoadout.ROLE_FAST_ATTACKER:
			return species.base_speed * 2 + maxi(species.base_attack, species.base_special_attack)
		TrainerPokemonLoadout.ROLE_BULKY_PHYSICAL:
			return species.base_hp + species.base_defense * 2
		TrainerPokemonLoadout.ROLE_BULKY_SPECIAL:
			return species.base_hp + species.base_special_defense * 2
		TrainerPokemonLoadout.ROLE_SUPPORT:
			return species.base_hp + species.base_defense + species.base_special_defense
		_:
			return (
				species.base_hp + species.base_attack + species.base_defense
				+ species.base_speed + species.base_special_attack + species.base_special_defense
			) / 2


func _select_lead_index(team: TrainerTeamDefinition) -> int:
	var best_index := 0
	var best_score := -2147483648
	for index in range(team.loadouts.size()):
		var loadout := team.loadouts[index]
		var species := _catalog.species(loadout.species_id)
		if species == null:
			continue
		var score := species.base_speed
		match loadout.role_id:
			TrainerPokemonLoadout.ROLE_FAST_ATTACKER:
				score += 1200
			TrainerPokemonLoadout.ROLE_SUPPORT:
				score += 800
			TrainerPokemonLoadout.ROLE_BULKY_PHYSICAL, TrainerPokemonLoadout.ROLE_BULKY_SPECIAL:
				score += 300
			_:
				score += 500
		if score > best_score:
			best_score = score
			best_index = index
	return best_index
