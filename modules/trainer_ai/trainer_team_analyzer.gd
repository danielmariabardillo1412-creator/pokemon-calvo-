class_name TrainerTeamAnalyzer
extends RefCounted

const MODEL_ID := "trainer_team_analysis_v1"
const RANDOM_CUP_MODEL_ID := "trainer_team_analysis_random_cup_v1"
const STRONG_ROLE_BP := 7500
const INFERRED_ROLE_IDS := [
	"physical_attacker",
	"special_attacker",
	"fast_attacker",
	"bulky_physical",
	"bulky_special",
	"support",
]

var _catalog: DefinitionCatalog
var _loadout_factory: TrainerLoadoutFactory
var _role_inference: TrainerRosterRoleInference


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog
	_loadout_factory = TrainerLoadoutFactory.new(catalog)
	_role_inference = TrainerRosterRoleInference.new()


func analyze(team: TrainerTeamDefinition) -> Dictionary:
	if team == null or _catalog == null:
		return _empty_result()

	var role_counts: Dictionary = {}
	var species_type_counts: Dictionary = {}
	var attack_type_counts: Dictionary = {}
	var valid_members: Array[TrainerPokemonLoadout] = []
	for loadout in team.loadouts:
		if loadout == null:
			continue
		var species := _catalog.species(loadout.species_id)
		if species == null:
			continue
		valid_members.append(loadout)
		_increment(role_counts, String(loadout.role_id))
		for type_id in species.type_ids_resolved():
			_increment(species_type_counts, String(type_id))
		for move_id in loadout.move_ids:
			var move := _catalog.move(move_id)
			if move != null and move.power > 0:
				_increment(attack_type_counts, String(move.type_id))

	var weakness_counts: Dictionary = {}
	var resistance_counts: Dictionary = {}
	var coverage_counts: Dictionary = {}
	for attack_type_id in _catalog.type_catalog.all_ids():
		var weak := 0
		var resistant := 0
		for loadout in valid_members:
			var species := _catalog.species(loadout.species_id)
			var multiplier := _type_effectiveness(attack_type_id, species)
			if multiplier > 1.0001:
				weak += 1
			elif multiplier < 0.9999:
				resistant += 1
		weakness_counts[String(attack_type_id)] = weak
		resistance_counts[String(attack_type_id)] = resistant

		var coverage := 0
		for move_type_raw in attack_type_counts.keys():
			if _catalog.type_multiplier(StringName(move_type_raw), attack_type_id) > 1.0001:
				coverage += 1
		coverage_counts[String(attack_type_id)] = coverage

	var score := _role_synergy_score(role_counts)
	score += attack_type_counts.size() * 220
	var covered_types := 0
	for defender_type in coverage_counts.keys():
		if int(coverage_counts[defender_type]) > 0:
			covered_types += 1
	score += covered_types * 90

	var shared_weaknesses: Array[String] = []
	var uncovered_shared_weaknesses: Array[String] = []
	for attack_type in weakness_counts.keys():
		var weak_count := int(weakness_counts[attack_type])
		if weak_count >= 2:
			shared_weaknesses.append(String(attack_type))
		if weak_count >= 3:
			score -= (weak_count - 2) * 500
		if weak_count >= 2 and int(resistance_counts.get(attack_type, 0)) == 0:
			uncovered_shared_weaknesses.append(String(attack_type))
			score -= 700
	for own_type in species_type_counts.keys():
		var count := int(species_type_counts[own_type])
		if count > 2:
			score -= (count - 2) * 250

	shared_weaknesses.sort()
	uncovered_shared_weaknesses.sort()
	return {
		"model": MODEL_ID,
		"member_count": valid_members.size(),
		"synergy_score": score,
		"role_counts": role_counts,
		"species_type_counts": species_type_counts,
		"attack_type_counts": attack_type_counts,
		"weakness_counts": weakness_counts,
		"resistance_counts": resistance_counts,
		"coverage_counts": coverage_counts,
		"covered_defender_type_count": covered_types,
		"shared_weaknesses": shared_weaknesses,
		"uncovered_shared_weaknesses": uncovered_shared_weaknesses,
	}


func analyze_random_cup(team: TrainerTeamDefinition) -> Dictionary:
	if team == null or _catalog == null:
		return _empty_random_cup_result()

	var result: Dictionary = analyze(team)
	var authored_role_counts: Dictionary = result.get("role_counts", {}) as Dictionary
	var role_independent_score: int = (
		int(result.get("synergy_score", 0)) - _role_synergy_score(authored_role_counts)
	)
	var role_counts: Dictionary = {}
	var role_score_sums_bp: Dictionary = _zero_role_scores()
	var role_max_scores_bp: Dictionary = _zero_role_scores()
	var member_role_inference: Array[Dictionary] = []
	var uninferred_member_indices: Array[int] = []

	for index in range(team.loadouts.size()):
		var loadout: TrainerPokemonLoadout = team.loadouts[index]
		if loadout == null or _catalog.species(loadout.species_id) == null:
			continue
		var instance_id: StringName = StringName("team_analysis_member_%d" % index)
		var creature: CreatureInstance = _loadout_factory.materialize(loadout, instance_id)
		if creature == null:
			uninferred_member_indices.append(index)
			continue
		var inference_result: Dictionary = _role_inference.infer_role_scores(
			creature.to_dict(),
			_catalog,
		)
		var role_scores_bp: Dictionary = inference_result.get("role_scores_bp", {}) as Dictionary
		if role_scores_bp.is_empty():
			uninferred_member_indices.append(index)
			continue

		for raw_role_id in INFERRED_ROLE_IDS:
			var role_id := String(raw_role_id)
			var role_score: int = clampi(int(role_scores_bp.get(role_id, 0)), 0, 10000)
			role_score_sums_bp[role_id] = int(role_score_sums_bp.get(role_id, 0)) + role_score
			role_max_scores_bp[role_id] = maxi(
				int(role_max_scores_bp.get(role_id, 0)),
				role_score,
			)
			if role_score >= STRONG_ROLE_BP:
				_increment(role_counts, role_id)

		member_role_inference.append({
			"member_index": index,
			"species_id": String(loadout.species_id),
			"role_scores_bp": role_scores_bp.duplicate(true),
			"role_model_id": String(inference_result.get("model_id", "")),
			"support_model_id": String(inference_result.get("support_model_id", "")),
		})

	var absent_roles: Array[String] = []
	var unique_strong_roles: Array[String] = []
	var redundant_strong_roles: Array[String] = []
	for raw_role_id in INFERRED_ROLE_IDS:
		var role_id := String(raw_role_id)
		var count: int = int(role_counts.get(role_id, 0))
		if count <= 0:
			absent_roles.append(role_id)
		elif count == 1:
			unique_strong_roles.append(role_id)
		else:
			redundant_strong_roles.append(role_id)

	result["model"] = RANDOM_CUP_MODEL_ID
	result["synergy_score"] = role_independent_score + _role_synergy_score(role_counts)
	result["role_counts"] = role_counts
	result["role_presence_threshold_bp"] = STRONG_ROLE_BP
	result["role_score_sums_bp"] = role_score_sums_bp
	result["role_max_scores_bp"] = role_max_scores_bp
	result["absent_strong_roles"] = absent_roles
	result["unique_strong_roles"] = unique_strong_roles
	result["redundant_strong_roles"] = redundant_strong_roles
	result["inferred_member_count"] = member_role_inference.size()
	result["uninferred_member_indices"] = uninferred_member_indices
	result["member_role_inference"] = member_role_inference
	return result


func _role_synergy_score(role_counts: Dictionary) -> int:
	var score: int = role_counts.size() * 500
	if int(role_counts.get(String(TrainerPokemonLoadout.ROLE_SUPPORT), 0)) > 0:
		score += 600
	if int(role_counts.get(String(TrainerPokemonLoadout.ROLE_FAST_ATTACKER), 0)) > 0:
		score += 400
	var physical_roles: int = (
		int(role_counts.get(String(TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER), 0))
		+ int(role_counts.get(String(TrainerPokemonLoadout.ROLE_FAST_ATTACKER), 0))
	)
	var special_roles: int = int(
		role_counts.get(String(TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER), 0)
	)
	if physical_roles > 0 and special_roles > 0:
		score += 500
	return score


func _zero_role_scores() -> Dictionary:
	var out: Dictionary = {}
	for raw_role_id in INFERRED_ROLE_IDS:
		out[String(raw_role_id)] = 0
	return out


func _type_effectiveness(attack_type_id: StringName, defender: CreatureSpecies) -> float:
	if defender == null:
		return 1.0
	var multiplier := 1.0
	for defender_type_id in defender.type_ids_resolved():
		multiplier *= _catalog.type_multiplier(attack_type_id, defender_type_id)
	return multiplier


func _increment(target: Dictionary, key: String) -> void:
	target[key] = int(target.get(key, 0)) + 1


func _empty_result() -> Dictionary:
	return {
		"model": MODEL_ID,
		"member_count": 0,
		"synergy_score": 0,
		"role_counts": {},
		"species_type_counts": {},
		"attack_type_counts": {},
		"weakness_counts": {},
		"resistance_counts": {},
		"coverage_counts": {},
		"covered_defender_type_count": 0,
		"shared_weaknesses": [],
		"uncovered_shared_weaknesses": [],
	}


func _empty_random_cup_result() -> Dictionary:
	var result: Dictionary = _empty_result()
	result["model"] = RANDOM_CUP_MODEL_ID
	result["role_presence_threshold_bp"] = STRONG_ROLE_BP
	result["role_score_sums_bp"] = _zero_role_scores()
	result["role_max_scores_bp"] = _zero_role_scores()
	result["absent_strong_roles"] = INFERRED_ROLE_IDS.duplicate()
	result["unique_strong_roles"] = []
	result["redundant_strong_roles"] = []
	result["inferred_member_count"] = 0
	result["uninferred_member_indices"] = []
	result["member_role_inference"] = []
	return result
