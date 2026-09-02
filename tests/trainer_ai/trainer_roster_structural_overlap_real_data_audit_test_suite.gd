class_name TrainerRosterStructuralOverlapRealDataAuditTestSuite
extends TrainerRosterStructuralRealDataAuditTestSuite

const REFINED_AUDIT_ID := "c3b_structural_defense_disjoint_audit_v1"


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("structural_overlap_real_data_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = _lexically_sorted_species_ids(game_data.species_catalog)
	var probe: Dictionary = _build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)
	_check.call("structural_overlap_real_data_probe_has_1021_eligible_species", members.size() == 1021)
	if members.size() < ROSTER_SIZE:
		return

	var report_a: Dictionary = _build_refined_report(catalog, members)
	var report_b: Dictionary = _build_refined_report(catalog, members)
	_check.call("structural_overlap_real_data_audit_id_recorded", String(report_a.get("audit_id", "")) == REFINED_AUDIT_ID)
	_check.call("structural_overlap_real_data_member_occurrences_balanced", int(report_a.get("member_occurrences", 0)) == members.size() * ROSTER_SIZE * SCHEDULE_STRIDES.size())
	_check.call("structural_overlap_real_data_detects_raw_vs_disjoint_difference", int(report_a.get("occurrences_with_defensive_semantic_difference", 0)) > 0)
	_check.call("structural_overlap_real_data_detects_raw_overcount_cases", int(report_a.get("raw_unique_defense_gt_disjoint_occurrences", 0)) > 0)
	_check.call("structural_overlap_real_data_detects_raw_undercount_cases", int(report_a.get("raw_unique_defense_lt_disjoint_occurrences", 0)) > 0)
	_check.call("structural_overlap_real_data_has_exclusive_resistance_uniqueness", int(report_a.get("occurrences_with_unique_exclusive_resistance", 0)) > 0)
	_check.call("structural_overlap_real_data_marginal_removal_uses_disjoint_defense", int((report_a.get("marginal_removal_disjoint", {}) as Dictionary).get("cases_with_new_uniqueness", 0)) > 0)
	_check.call("structural_overlap_real_data_report_deterministic", report_a == report_b)
	_check.call("structural_overlap_real_data_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call("structural_overlap_real_data_does_not_freeze_scalar", not report_a.has("structural_value_bp") and not report_a.has("permadeath_loss_cost_bp"))

	print("\n=== TRAINER ROSTER STRUCTURAL DEFENSE DISJOINT AUDIT ===")
	print(JSON.stringify(report_a))


func _build_refined_report(
	catalog: DefinitionCatalog,
	members: Array[Dictionary],
) -> Dictionary:
	var evaluator := TrainerRosterStrategicValueEvaluator.new(catalog)
	var unique_exclusive_resistance_histogram: Dictionary = {}
	var redundant_exclusive_resistance_histogram: Dictionary = {}
	var low_signal_no_unique_examples: Array[Dictionary] = []
	var seen_low_signal: Dictionary = {}
	var distortion_examples: Array[Dictionary] = []
	var raw_gt: int = 0
	var raw_lt: int = 0
	var raw_eq: int = 0
	var semantic_difference_occurrences: int = 0
	var absolute_defense_unit_delta: int = 0
	var net_raw_minus_disjoint_defense_units: int = 0
	var occurrences_with_unique_exclusive_resistance: int = 0
	var low_signal_no_unique_occurrences: int = 0
	var member_occurrences: int = 0
	var correlations: Dictionary = {
		"unique_exclusive_resistance_vs_unique_immunity": _new_correlation(),
		"unique_offense_vs_unique_exclusive_resistance": _new_correlation(),
		"unique_role_vs_unique_exclusive_resistance": _new_correlation(),
		"role_max_vs_total_unique_units_disjoint": _new_correlation(),
	}

	for raw_stride in SCHEDULE_STRIDES:
		var stride: int = int(raw_stride)
		for anchor in range(members.size()):
			var roster: Array[Dictionary] = _scheduled_roster(members, anchor, stride)
			var evidence: Dictionary = evaluator.extract_structural_evidence(roster)
			var disjoint_by_id: Dictionary = _disjoint_member_metrics(evidence)
			for raw_member in evidence.get("member_evidence", []):
				if not (raw_member is Dictionary):
					continue
				var member: Dictionary = raw_member as Dictionary
				var instance_id := String(member.get("instance_id", ""))
				var metrics: Dictionary = disjoint_by_id.get(instance_id, {}) as Dictionary
				member_occurrences += 1
				var unique_exclusive_resistance: int = (metrics.get("unique_exclusive_resistance_type_ids", []) as Array).size()
				var redundant_exclusive_resistance: int = (metrics.get("redundant_exclusive_resistance_type_ids", []) as Array).size()
				var unique_immunity: int = (metrics.get("unique_immunity_type_ids", []) as Array).size()
				var raw_unique_defense: int = int(metrics.get("raw_unique_defense_units", 0))
				var disjoint_unique_defense: int = int(metrics.get("disjoint_unique_defense_units", 0))
				var total_unique_disjoint: int = int(metrics.get("total_unique_units_disjoint", 0))
				var unique_roles: int = (member.get("unique_strong_role_ids", []) as Array).size()
				var unique_offense: int = (member.get("unique_offensive_coverage_type_ids", []) as Array).size()
				var role_max: int = int(member.get("role_score_max_bp", 0))
				_histogram_increment(unique_exclusive_resistance_histogram, unique_exclusive_resistance)
				_histogram_increment(redundant_exclusive_resistance_histogram, redundant_exclusive_resistance)
				if unique_exclusive_resistance > 0:
					occurrences_with_unique_exclusive_resistance += 1
				var delta: int = raw_unique_defense - disjoint_unique_defense
				absolute_defense_unit_delta += absi(delta)
				net_raw_minus_disjoint_defense_units += delta
				if delta > 0:
					raw_gt += 1
				elif delta < 0:
					raw_lt += 1
				else:
					raw_eq += 1
				if delta != 0:
					semantic_difference_occurrences += 1
					if distortion_examples.size() < 10:
						distortion_examples.append({
							"species_id": String(member.get("species_id", "")),
							"raw_unique_defense_units": raw_unique_defense,
							"disjoint_unique_defense_units": disjoint_unique_defense,
							"unique_resistance_type_ids_raw": (member.get("unique_resistance_type_ids", []) as Array).duplicate(),
							"unique_exclusive_resistance_type_ids": (metrics.get("unique_exclusive_resistance_type_ids", []) as Array).duplicate(),
							"unique_immunity_type_ids": (metrics.get("unique_immunity_type_ids", []) as Array).duplicate(),
						})
				if role_max < 7500 and total_unique_disjoint == 0:
					low_signal_no_unique_occurrences += 1
					var species_id := String(member.get("species_id", ""))
					if low_signal_no_unique_examples.size() < 10 and not seen_low_signal.has(species_id):
						seen_low_signal[species_id] = true
						low_signal_no_unique_examples.append({
							"species_id": species_id,
							"role_score_max_bp": role_max,
							"runtime_supported_damaging_move_count": int(member.get("runtime_supported_damaging_move_count", 0)),
							"redundant_strong_role_ids": (member.get("redundant_strong_role_ids", []) as Array).duplicate(),
							"redundant_offensive_coverage_type_ids": (member.get("redundant_offensive_coverage_type_ids", []) as Array).duplicate(),
							"redundant_exclusive_resistance_type_ids": (metrics.get("redundant_exclusive_resistance_type_ids", []) as Array).duplicate(),
							"redundant_immunity_type_ids": (metrics.get("redundant_immunity_type_ids", []) as Array).duplicate(),
						})
				_corr_add(correlations["unique_exclusive_resistance_vs_unique_immunity"] as Dictionary, unique_exclusive_resistance, unique_immunity)
				_corr_add(correlations["unique_offense_vs_unique_exclusive_resistance"] as Dictionary, unique_offense, unique_exclusive_resistance)
				_corr_add(correlations["unique_role_vs_unique_exclusive_resistance"] as Dictionary, unique_roles, unique_exclusive_resistance)
				_corr_add(correlations["role_max_vs_total_unique_units_disjoint"] as Dictionary, role_max, total_unique_disjoint)

	var finalized_correlations: Dictionary = {}
	for key in correlations.keys():
		finalized_correlations[String(key)] = _corr_bp(correlations[key] as Dictionary)

	return {
		"audit_id": REFINED_AUDIT_ID,
		"eligible_species": members.size(),
		"roster_size": ROSTER_SIZE,
		"schedule_count": SCHEDULE_STRIDES.size(),
		"member_occurrences": member_occurrences,
		"occurrences_with_defensive_semantic_difference": semantic_difference_occurrences,
		"raw_unique_defense_gt_disjoint_occurrences": raw_gt,
		"raw_unique_defense_lt_disjoint_occurrences": raw_lt,
		"raw_unique_defense_equal_disjoint_occurrences": raw_eq,
		"absolute_unique_defense_unit_delta": absolute_defense_unit_delta,
		"net_raw_minus_disjoint_unique_defense_units": net_raw_minus_disjoint_defense_units,
		"occurrences_with_unique_exclusive_resistance": occurrences_with_unique_exclusive_resistance,
		"unique_exclusive_resistance_count_histogram": unique_exclusive_resistance_histogram,
		"redundant_exclusive_resistance_count_histogram": redundant_exclusive_resistance_histogram,
		"correlations_bp": finalized_correlations,
		"low_signal_no_unique_occurrences": low_signal_no_unique_occurrences,
		"low_signal_no_unique_examples": low_signal_no_unique_examples,
		"defensive_semantic_distortion_examples": distortion_examples,
		"marginal_removal_disjoint": _marginal_removal_disjoint(evaluator, members),
	}


func _disjoint_member_metrics(evidence: Dictionary) -> Dictionary:
	var exclusive_resistance_counts: Dictionary = {}
	var immunity_counts: Dictionary = {}
	var exclusive_by_id: Dictionary = {}
	var immunity_by_id: Dictionary = {}
	for raw_member in evidence.get("member_evidence", []):
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		var immune_set: Dictionary = {}
		for raw_type_id in member.get("immune_attack_type_ids", []):
			var type_id := String(raw_type_id)
			immune_set[type_id] = true
			immunity_counts[type_id] = int(immunity_counts.get(type_id, 0)) + 1
		var exclusive: Array[String] = []
		for raw_type_id in member.get("resisted_attack_type_ids", []):
			var type_id := String(raw_type_id)
			if immune_set.has(type_id):
				continue
			exclusive.append(type_id)
			exclusive_resistance_counts[type_id] = int(exclusive_resistance_counts.get(type_id, 0)) + 1
		exclusive.sort()
		exclusive_by_id[instance_id] = exclusive
		var immunity_ids: Array[String] = []
		for raw_type_id in member.get("immune_attack_type_ids", []):
			immunity_ids.append(String(raw_type_id))
		immunity_ids.sort()
		immunity_by_id[instance_id] = immunity_ids

	var out: Dictionary = {}
	for raw_member in evidence.get("member_evidence", []):
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
		var raw_unique_defense_units: int = (
			(member.get("unique_resistance_type_ids", []) as Array).size()
			+ (member.get("unique_immunity_type_ids", []) as Array).size()
		)
		var disjoint_unique_defense_units: int = unique_exclusive.size() + unique_immunity.size()
		var total_unique_units_disjoint: int = (
			(member.get("unique_strong_role_ids", []) as Array).size()
			+ (member.get("unique_offensive_coverage_type_ids", []) as Array).size()
			+ disjoint_unique_defense_units
		)
		out[instance_id] = {
			"unique_exclusive_resistance_type_ids": unique_exclusive,
			"redundant_exclusive_resistance_type_ids": redundant_exclusive,
			"unique_immunity_type_ids": unique_immunity,
			"redundant_immunity_type_ids": redundant_immunity,
			"raw_unique_defense_units": raw_unique_defense_units,
			"disjoint_unique_defense_units": disjoint_unique_defense_units,
			"total_unique_units_disjoint": total_unique_units_disjoint,
		}
	return out


func _marginal_removal_disjoint(
	evaluator: TrainerRosterStrategicValueEvaluator,
	members: Array[Dictionary],
) -> Dictionary:
	var cases: int = 0
	var cases_with_new_uniqueness: int = 0
	var new_unique_units: int = 0
	var examples: Array[Dictionary] = []
	for raw_stride in SCHEDULE_STRIDES:
		var stride: int = int(raw_stride)
		var sample_count: int = mini(MARGINAL_SAMPLE_ROSTERS_PER_SCHEDULE, members.size())
		for anchor in range(sample_count):
			var roster: Array[Dictionary] = _scheduled_roster(members, anchor, stride)
			var baseline: Dictionary = evaluator.extract_structural_evidence(roster)
			var before_disjoint: Dictionary = _disjoint_member_metrics(baseline)
			for removed_slot in range(ROSTER_SIZE):
				var reduced: Array[Dictionary] = []
				for slot in range(ROSTER_SIZE):
					if slot != removed_slot:
						reduced.append(roster[slot])
				var after: Dictionary = evaluator.extract_structural_evidence(reduced)
				var after_disjoint: Dictionary = _disjoint_member_metrics(after)
				var case_gain: int = 0
				for instance_id in after_disjoint.keys():
					var after_metrics: Dictionary = after_disjoint[instance_id] as Dictionary
					var before_metrics: Dictionary = before_disjoint.get(instance_id, {}) as Dictionary
					case_gain += maxi(
						0,
						int(after_metrics.get("total_unique_units_disjoint", 0))
						- int(before_metrics.get("total_unique_units_disjoint", 0)),
					)
				cases += 1
				if case_gain > 0:
					cases_with_new_uniqueness += 1
					new_unique_units += case_gain
					if examples.size() < 8:
						examples.append({
							"stride": stride,
							"anchor": anchor,
							"removed_species_id": String(roster[removed_slot].get("species_id", "")),
							"new_unique_units_disjoint": case_gain,
						})
	return {
		"sample_rosters_per_schedule": MARGINAL_SAMPLE_ROSTERS_PER_SCHEDULE,
		"cases": cases,
		"cases_with_new_uniqueness": cases_with_new_uniqueness,
		"new_unique_units": new_unique_units,
		"examples": examples,
	}
