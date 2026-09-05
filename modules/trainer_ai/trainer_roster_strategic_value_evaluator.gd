class_name TrainerRosterStrategicValueEvaluator
extends RefCounted

# C3a extracts stable structural evidence from the surviving own roster.
# C3d adds the selected structural scalar as a separate consumer so the evidence
# contract remains auditable and does not acquire campaign-policy semantics.

const STRUCTURAL_EVIDENCE_MODEL_ID := "trainer_roster_structural_evidence_v1"
const STRUCTURAL_VALUE_MODEL_ID := "trainer_roster_structural_value_capped_units_blend_v1"
const STRUCTURAL_VALUE_FORMULA_ID := "capped_units_blend_baseline_w30_v1"
const STRUCTURAL_UNIQUE_ROLE_CAP := 2
const STRUCTURAL_UNIQUE_OFFENSE_CAP := 3
const STRUCTURAL_UNIQUE_EXCLUSIVE_RESISTANCE_CAP := 3
const STRUCTURAL_UNIQUE_IMMUNITY_CAP := 2
const STRUCTURAL_ROLE_UNIT_BP := 2500
const STRUCTURAL_OFFENSE_UNIT_BP := 1000
const STRUCTURAL_EXCLUSIVE_RESISTANCE_UNIT_BP := 1000
const STRUCTURAL_IMMUNITY_UNIT_BP := 1500
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const STRONG_ROLE_BP := 7500
const ROLE_IDS := [
	"physical_attacker",
	"special_attacker",
	"fast_attacker",
	"bulky_physical",
	"bulky_special",
	"support",
]

var _catalog: DefinitionCatalog
var _role_inference := TrainerRosterRoleInference.new()


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog


func extract_structural_evidence(own_party: Array) -> Dictionary:
	if _catalog == null or _catalog.type_catalog == null:
		return _empty_result()

	var all_type_ids: Array[StringName] = _all_type_ids()
	var strong_role_counts: Dictionary = _zero_role_counts()
	var offensive_coverage_counts: Dictionary = {}
	var resistance_counts: Dictionary = {}
	var immunity_counts: Dictionary = {}
	var members: Array[Dictionary] = []
	var skipped_knocked_out_instance_ids: Array[String] = []
	var skipped_invalid_member_indices: Array[int] = []

	for index in range(own_party.size()):
		var raw_member: Variant = own_party[index]
		if not (raw_member is Dictionary):
			skipped_invalid_member_indices.append(index)
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		var species_id := StringName(String(member.get("species_id", "")))
		if instance_id.is_empty() or _catalog.species(species_id) == null:
			skipped_invalid_member_indices.append(index)
			continue
		if int(member.get("current_hp", 0)) <= 0 or bool(member.get("is_knocked_out", false)):
			skipped_knocked_out_instance_ids.append(instance_id)
			continue

		var inference: Dictionary = _role_inference.infer_role_scores(member, _catalog)
		var role_scores: Dictionary = inference.get("role_scores_bp", {}) as Dictionary
		var strong_roles: Array[String] = []
		var role_score_max_bp: int = 0
		var role_score_sum_bp: int = 0
		for raw_role_id in ROLE_IDS:
			var role_id := String(raw_role_id)
			var role_score: int = clampi(int(role_scores.get(role_id, 0)), 0, 10000)
			role_score_max_bp = maxi(role_score_max_bp, role_score)
			role_score_sum_bp += role_score
			if role_score >= STRONG_ROLE_BP:
				strong_roles.append(role_id)
				_increment(strong_role_counts, role_id)

		var offensive_coverage: Array[String] = _offensive_coverage_type_ids(member, all_type_ids)
		for type_id in offensive_coverage:
			_increment(offensive_coverage_counts, type_id)

		var defensive: Dictionary = _defensive_type_evidence(species_id, all_type_ids)
		var resisted: Array = defensive.get("resisted_attack_type_ids", []) as Array
		var immune: Array = defensive.get("immune_attack_type_ids", []) as Array
		for type_id in resisted:
			_increment(resistance_counts, String(type_id))
		for type_id in immune:
			_increment(immunity_counts, String(type_id))

		var intrinsic: Dictionary = inference.get("intrinsic_evidence", {}) as Dictionary
		var move_features: Dictionary = intrinsic.get("move_features", {}) as Dictionary
		members.append({
			"instance_id": instance_id,
			"species_id": String(species_id),
			"role_model_id": String(inference.get("model_id", "")),
			"support_model_id": String(inference.get("support_model_id", "")),
			"role_scores_bp": role_scores.duplicate(true),
			"role_score_max_bp": role_score_max_bp,
			"role_score_sum_bp": role_score_sum_bp,
			"strong_role_ids": strong_roles,
			"runtime_supported_move_count": int(move_features.get("runtime_supported_count", 0)),
			"runtime_supported_damaging_move_count": _runtime_supported_damaging_move_count(member),
			"offensive_coverage_type_ids": offensive_coverage,
			"resisted_attack_type_ids": resisted.duplicate(),
			"immune_attack_type_ids": immune.duplicate(),
		})

	for index in range(members.size()):
		var member: Dictionary = members[index]
		member["unique_strong_role_ids"] = _partition_unique(
			member.get("strong_role_ids", []) as Array,
			strong_role_counts,
		)
		member["redundant_strong_role_ids"] = _partition_redundant(
			member.get("strong_role_ids", []) as Array,
			strong_role_counts,
		)
		member["unique_offensive_coverage_type_ids"] = _partition_unique(
			member.get("offensive_coverage_type_ids", []) as Array,
			offensive_coverage_counts,
		)
		member["redundant_offensive_coverage_type_ids"] = _partition_redundant(
			member.get("offensive_coverage_type_ids", []) as Array,
			offensive_coverage_counts,
		)
		member["unique_resistance_type_ids"] = _partition_unique(
			member.get("resisted_attack_type_ids", []) as Array,
			resistance_counts,
		)
		member["redundant_resistance_type_ids"] = _partition_redundant(
			member.get("resisted_attack_type_ids", []) as Array,
			resistance_counts,
		)
		member["unique_immunity_type_ids"] = _partition_unique(
			member.get("immune_attack_type_ids", []) as Array,
			immunity_counts,
		)
		member["redundant_immunity_type_ids"] = _partition_redundant(
			member.get("immune_attack_type_ids", []) as Array,
			immunity_counts,
		)
		members[index] = member

	return {
		"model_id": STRUCTURAL_EVIDENCE_MODEL_ID,
		"role_presence_threshold_bp": STRONG_ROLE_BP,
		"member_count": members.size(),
		"strong_role_counts": strong_role_counts,
		"offensive_coverage_counts": offensive_coverage_counts,
		"resistance_counts": resistance_counts,
		"immunity_counts": immunity_counts,
		"skipped_knocked_out_instance_ids": skipped_knocked_out_instance_ids,
		"skipped_invalid_member_indices": skipped_invalid_member_indices,
		"member_evidence": members,
	}


func evaluate_structural_value(own_party: Array) -> Dictionary:
	var evidence: Dictionary = extract_structural_evidence(own_party)
	if _catalog == null or _catalog.type_catalog == null:
		return _empty_structural_value_result()

	var raw_members: Array = evidence.get("member_evidence", []) as Array
	var disjoint_by_id: Dictionary = _disjoint_structural_value_metrics(raw_members)
	var member_values: Array[Dictionary] = []
	for raw_member in raw_members:
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		var disjoint: Dictionary = disjoint_by_id.get(instance_id, {}) as Dictionary
		member_values.append(_structural_value_member(member, disjoint))

	return {
		"model_id": STRUCTURAL_VALUE_MODEL_ID,
		"formula_id": STRUCTURAL_VALUE_FORMULA_ID,
		"evidence_model_id": STRUCTURAL_EVIDENCE_MODEL_ID,
		"role_presence_threshold_bp": STRONG_ROLE_BP,
		"member_count": member_values.size(),
		"skipped_knocked_out_instance_ids": (evidence.get("skipped_knocked_out_instance_ids", []) as Array).duplicate(),
		"skipped_invalid_member_indices": (evidence.get("skipped_invalid_member_indices", []) as Array).duplicate(),
		"member_values": member_values,
	}


func _structural_value_member(member: Dictionary, disjoint: Dictionary) -> Dictionary:
	var role_scores: Dictionary = member.get("role_scores_bp", {}) as Dictionary
	var top_scores: Array[int] = []
	for raw_score in role_scores.values():
		top_scores.append(clampi(int(raw_score), 0, 10000))
	top_scores.sort()
	top_scores.reverse()
	var role_max_bp: int = 0 if top_scores.is_empty() else top_scores[0]
	var role_second_bp: int = 0 if top_scores.size() < 2 else top_scores[1]
	var absolute_capacity_bp: int = roundi(float(role_max_bp * 3 + role_second_bp) / 4.0)

	var unique_role_ids: Array = member.get("unique_strong_role_ids", []) as Array
	var unique_offense_ids: Array = member.get("unique_offensive_coverage_type_ids", []) as Array
	var unique_exclusive_resistance_ids: Array = disjoint.get("unique_exclusive_resistance_type_ids", []) as Array
	var unique_immunity_ids: Array = disjoint.get("unique_immunity_type_ids", []) as Array
	var unique_role_count: int = unique_role_ids.size()
	var unique_offense_count: int = unique_offense_ids.size()
	var unique_exclusive_resistance_count: int = unique_exclusive_resistance_ids.size()
	var unique_immunity_count: int = unique_immunity_ids.size()
	var capped_role_count: int = mini(unique_role_count, STRUCTURAL_UNIQUE_ROLE_CAP)
	var capped_offense_count: int = mini(unique_offense_count, STRUCTURAL_UNIQUE_OFFENSE_CAP)
	var capped_exclusive_resistance_count: int = mini(
		unique_exclusive_resistance_count,
		STRUCTURAL_UNIQUE_EXCLUSIVE_RESISTANCE_CAP,
	)
	var capped_immunity_count: int = mini(unique_immunity_count, STRUCTURAL_UNIQUE_IMMUNITY_CAP)
	var context_bp: int = mini(
		10000,
		capped_role_count * STRUCTURAL_ROLE_UNIT_BP
		+ capped_offense_count * STRUCTURAL_OFFENSE_UNIT_BP
		+ capped_exclusive_resistance_count * STRUCTURAL_EXCLUSIVE_RESISTANCE_UNIT_BP
		+ capped_immunity_count * STRUCTURAL_IMMUNITY_UNIT_BP,
	)
	var absolute_floor_bp: int = roundi(float(absolute_capacity_bp) * 0.80)
	var blended_score_bp: int = roundi(
		float(absolute_capacity_bp) * 0.70
		+ float(context_bp) * 0.30
	)
	var structural_value_bp: int = clampi(maxi(absolute_floor_bp, blended_score_bp), 0, 10000)

	return {
		"instance_id": String(member.get("instance_id", "")),
		"species_id": String(member.get("species_id", "")),
		"structural_value_bp": structural_value_bp,
		"breakdown": {
			"role_max_bp": role_max_bp,
			"role_second_bp": role_second_bp,
			"absolute_capacity_bp": absolute_capacity_bp,
			"unique_role_count": unique_role_count,
			"unique_offense_count": unique_offense_count,
			"unique_exclusive_resistance_count": unique_exclusive_resistance_count,
			"unique_immunity_count": unique_immunity_count,
			"unique_strong_role_ids": unique_role_ids.duplicate(),
			"unique_offensive_coverage_type_ids": unique_offense_ids.duplicate(),
			"unique_exclusive_resistance_type_ids": unique_exclusive_resistance_ids.duplicate(),
			"unique_immunity_type_ids": unique_immunity_ids.duplicate(),
			"capped_unique_counts": {
				"roles": capped_role_count,
				"offense": capped_offense_count,
				"exclusive_resistance": capped_exclusive_resistance_count,
				"immunity": capped_immunity_count,
			},
			"context_bp": context_bp,
			"absolute_floor_bp": absolute_floor_bp,
			"blended_score_bp": blended_score_bp,
			"selected_score_source": "absolute_floor" if absolute_floor_bp >= blended_score_bp else "context_blend",
		},
	}


func _disjoint_structural_value_metrics(members: Array) -> Dictionary:
	var exclusive_resistance_counts: Dictionary = {}
	var immunity_counts: Dictionary = {}
	var exclusive_by_id: Dictionary = {}
	var immunity_by_id: Dictionary = {}
	for raw_member in members:
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		var immune_set: Dictionary = {}
		var immunity_ids: Array[String] = []
		for raw_type_id in member.get("immune_attack_type_ids", []):
			var type_id := String(raw_type_id)
			immune_set[type_id] = true
			immunity_ids.append(type_id)
			_increment(immunity_counts, type_id)
		immunity_ids.sort()
		immunity_by_id[instance_id] = immunity_ids

		var exclusive_ids: Array[String] = []
		for raw_type_id in member.get("resisted_attack_type_ids", []):
			var type_id := String(raw_type_id)
			if immune_set.has(type_id):
				continue
			exclusive_ids.append(type_id)
			_increment(exclusive_resistance_counts, type_id)
		exclusive_ids.sort()
		exclusive_by_id[instance_id] = exclusive_ids

	var out: Dictionary = {}
	for raw_member in members:
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		var unique_exclusive: Array[String] = []
		var redundant_exclusive: Array[String] = []
		for raw_type_id in exclusive_by_id.get(instance_id, []):
			var type_id := String(raw_type_id)
			if int(exclusive_resistance_counts.get(type_id, 0)) == 1:
				unique_exclusive.append(type_id)
			else:
				redundant_exclusive.append(type_id)
		var unique_immunity: Array[String] = []
		var redundant_immunity: Array[String] = []
		for raw_type_id in immunity_by_id.get(instance_id, []):
			var type_id := String(raw_type_id)
			if int(immunity_counts.get(type_id, 0)) == 1:
				unique_immunity.append(type_id)
			else:
				redundant_immunity.append(type_id)
		unique_exclusive.sort()
		redundant_exclusive.sort()
		unique_immunity.sort()
		redundant_immunity.sort()
		out[instance_id] = {
			"unique_exclusive_resistance_type_ids": unique_exclusive,
			"redundant_exclusive_resistance_type_ids": redundant_exclusive,
			"unique_immunity_type_ids": unique_immunity,
			"redundant_immunity_type_ids": redundant_immunity,
		}
	return out


func _all_type_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for type_id in _catalog.type_catalog.all_ids():
		out.append(StringName(type_id))
	out.sort()
	return out


func _offensive_coverage_type_ids(
	member: Dictionary,
	all_type_ids: Array[StringName],
) -> Array[String]:
	var covered: Dictionary = {}
	for raw_move_id in member.get("move_ids", []):
		var move: MoveDefinition = _catalog.move(StringName(String(raw_move_id)))
		if move == null or move.classification != RUNTIME_SUPPORTED or move.power <= 0:
			continue
		for defender_type_id in all_type_ids:
			if _catalog.type_multiplier(move.type_id, defender_type_id) > 1.0001:
				covered[String(defender_type_id)] = true
	return _sorted_keys(covered)


func _runtime_supported_damaging_move_count(member: Dictionary) -> int:
	var count: int = 0
	for raw_move_id in member.get("move_ids", []):
		var move: MoveDefinition = _catalog.move(StringName(String(raw_move_id)))
		if move != null and move.classification == RUNTIME_SUPPORTED and move.power > 0:
			count += 1
	return count


func _defensive_type_evidence(
	species_id: StringName,
	all_type_ids: Array[StringName],
) -> Dictionary:
	var species: CreatureSpecies = _catalog.species(species_id)
	if species == null:
		return {
			"resisted_attack_type_ids": [],
			"immune_attack_type_ids": [],
		}
	var resisted: Array[String] = []
	var immune: Array[String] = []
	for attack_type_id in all_type_ids:
		var multiplier: float = 1.0
		for defender_type_id in species.type_ids_resolved():
			multiplier *= _catalog.type_multiplier(attack_type_id, defender_type_id)
		if multiplier < 0.9999:
			resisted.append(String(attack_type_id))
		if multiplier < 0.0001:
			immune.append(String(attack_type_id))
	resisted.sort()
	immune.sort()
	return {
		"resisted_attack_type_ids": resisted,
		"immune_attack_type_ids": immune,
	}


func _partition_unique(values: Array, counts: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw_value in values:
		var value := String(raw_value)
		if int(counts.get(value, 0)) == 1:
			out.append(value)
	out.sort()
	return out


func _partition_redundant(values: Array, counts: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw_value in values:
		var value := String(raw_value)
		if int(counts.get(value, 0)) > 1:
			out.append(value)
	out.sort()
	return out


func _sorted_keys(values: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw_key in values.keys():
		out.append(String(raw_key))
	out.sort()
	return out


func _zero_role_counts() -> Dictionary:
	var out: Dictionary = {}
	for raw_role_id in ROLE_IDS:
		out[String(raw_role_id)] = 0
	return out


func _increment(target: Dictionary, key: String) -> void:
	target[key] = int(target.get(key, 0)) + 1


func _empty_structural_value_result() -> Dictionary:
	return {
		"model_id": STRUCTURAL_VALUE_MODEL_ID,
		"formula_id": STRUCTURAL_VALUE_FORMULA_ID,
		"evidence_model_id": STRUCTURAL_EVIDENCE_MODEL_ID,
		"role_presence_threshold_bp": STRONG_ROLE_BP,
		"member_count": 0,
		"skipped_knocked_out_instance_ids": [],
		"skipped_invalid_member_indices": [],
		"member_values": [],
	}


func _empty_result() -> Dictionary:
	return {
		"model_id": STRUCTURAL_EVIDENCE_MODEL_ID,
		"role_presence_threshold_bp": STRONG_ROLE_BP,
		"member_count": 0,
		"strong_role_counts": _zero_role_counts(),
		"offensive_coverage_counts": {},
		"resistance_counts": {},
		"immunity_counts": {},
		"skipped_knocked_out_instance_ids": [],
		"skipped_invalid_member_indices": [],
		"member_evidence": [],
	}
