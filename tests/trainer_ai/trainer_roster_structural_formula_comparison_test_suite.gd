extends TrainerRosterStructuralRealDataAuditTestSuite

const COMPARISON_ID := "c3c_structural_formula_comparison_v1"
const CANDIDATE_IDS := [
	"role_max_only",
	"naive_unique_units_additive",
	"family_presence_blend",
	"capped_units_blend",
	"guarded_family_bonus",
]

var _disjoint_helper := TrainerRosterStructuralOverlapRealDataAuditTestSuite.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("structural_formula_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	species_ids.sort()
	var probe: Dictionary = _build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)
	_check.call("structural_formula_probe_has_1021_eligible_species", members.size() == 1021)
	if members.size() < ROSTER_SIZE:
		return

	var report_a: Dictionary = _build_formula_report(catalog, members)
	var report_b: Dictionary = _build_formula_report(catalog, members)
	_check.call("structural_formula_comparison_id_recorded", String(report_a.get("comparison_id", "")) == COMPARISON_ID)
	_check.call("structural_formula_candidate_count", (report_a.get("candidate_ids", []) as Array).size() == CANDIDATE_IDS.size())
	_check.call("structural_formula_member_occurrences_balanced", int(report_a.get("member_occurrences", 0)) == members.size() * ROSTER_SIZE * SCHEDULE_STRIDES.size())
	_check.call("structural_formula_report_deterministic", report_a == report_b)
	_check.call("structural_formula_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call("structural_formula_comparison_is_test_only", not report_a.has("production_structural_value_model_id"))

	var candidates: Dictionary = report_a.get("candidates", {}) as Dictionary
	_check.call("structural_formula_role_max_control_has_no_marginal_response", _marginal_positive_cases(candidates, "role_max_only") == 0)
	_check.call("structural_formula_context_candidates_respond_to_marginal_change", _marginal_positive_cases(candidates, "family_presence_blend") > 0 and _marginal_positive_cases(candidates, "capped_units_blend") > 0 and _marginal_positive_cases(candidates, "guarded_family_bonus") > 0)
	_check.call("structural_formula_all_candidates_monotonic_under_removal", _all_candidates_no_negative_marginal(candidates))
	_check.call("structural_formula_context_candidates_preserve_absolute_floor", _context_candidates_preserve_floor(candidates))
	_check.call("structural_formula_naive_additive_reaches_at_least_as_many_ceilings_as_capped_blend", _candidate_metric(candidates, "naive_unique_units_additive", "ceiling_count") >= _candidate_metric(candidates, "capped_units_blend", "ceiling_count"))
	_check.call("structural_formula_low_signal_no_unique_never_gets_context_bonus", bool(report_a.get("low_signal_no_unique_context_bonus_is_zero", false)))
	_check.call("structural_formula_one_hp_invariant", bool(report_a.get("one_hp_score_invariant", false)))
	_check.call("structural_formula_ko_can_change_survivor_context", bool(report_a.get("ko_changes_survivor_context", false)))
	_check.call("structural_formula_synthetic_monotonicity", _synthetic_monotonicity())
	_check.call("structural_formula_synthetic_redundancy_does_not_erase_capacity", _synthetic_redundancy_floor())
	_check.call("structural_formula_synthetic_breadth_caps", _synthetic_breadth_caps())

	print("\n=== TRAINER ROSTER STRUCTURAL FORMULA COMPARISON ===")
	print(JSON.stringify(report_a))


func _build_formula_report(catalog: DefinitionCatalog, members: Array[Dictionary]) -> Dictionary:
	var evaluator := TrainerRosterStrategicValueEvaluator.new(catalog)
	var candidate_accumulators: Dictionary = {}
	for raw_candidate_id in CANDIDATE_IDS:
		candidate_accumulators[String(raw_candidate_id)] = _new_candidate_accumulator()

	var member_occurrences: int = 0
	var low_signal_no_unique_context_bonus_is_zero: bool = true
	var schedule_reports: Array[Dictionary] = []
	for raw_stride in SCHEDULE_STRIDES:
		var stride: int = int(raw_stride)
		var schedule_sums: Dictionary = {}
		for raw_candidate_id in CANDIDATE_IDS:
			schedule_sums[String(raw_candidate_id)] = 0
		var schedule_occurrences: int = 0
		for anchor in range(members.size()):
			var roster: Array[Dictionary] = _scheduled_roster(members, anchor, stride)
			var evidence: Dictionary = evaluator.extract_structural_evidence(roster)
			var disjoint_by_id: Dictionary = _disjoint_helper._disjoint_member_metrics(evidence)
			for raw_member in evidence.get("member_evidence", []):
				if not (raw_member is Dictionary):
					continue
				var member: Dictionary = raw_member as Dictionary
				var instance_id := String(member.get("instance_id", ""))
				var disjoint: Dictionary = disjoint_by_id.get(instance_id, {}) as Dictionary
				var metrics: Dictionary = _formula_metrics(member, disjoint)
				member_occurrences += 1
				schedule_occurrences += 1
				if int(metrics.get("role_max_bp", 0)) < 7500 and int(metrics.get("unique_units", 0)) == 0:
					low_signal_no_unique_context_bonus_is_zero = low_signal_no_unique_context_bonus_is_zero and int(metrics.get("family_presence_context_bp", -1)) == 0 and int(metrics.get("capped_units_context_bp", -1)) == 0
				for raw_candidate_id in CANDIDATE_IDS:
					var candidate_id := String(raw_candidate_id)
					var score: int = _candidate_score(candidate_id, metrics)
					var accumulator: Dictionary = candidate_accumulators[candidate_id] as Dictionary
					_accumulate_score(accumulator, score, metrics)
					candidate_accumulators[candidate_id] = accumulator
					schedule_sums[candidate_id] = int(schedule_sums.get(candidate_id, 0)) + score
		var means: Dictionary = {}
		for raw_candidate_id in CANDIDATE_IDS:
			var candidate_id := String(raw_candidate_id)
			means[candidate_id] = _mean_bp(int(schedule_sums.get(candidate_id, 0)), schedule_occurrences)
		schedule_reports.append({
			"stride": stride,
			"member_occurrences": schedule_occurrences,
			"candidate_mean_bp": means,
		})

	var marginal: Dictionary = _marginal_formula_report(evaluator, members)
	var candidates: Dictionary = {}
	for raw_candidate_id in CANDIDATE_IDS:
		var candidate_id := String(raw_candidate_id)
		var accumulator: Dictionary = candidate_accumulators[candidate_id] as Dictionary
		var candidate_marginal: Dictionary = marginal.get(candidate_id, {}) as Dictionary
		candidates[candidate_id] = _finalize_candidate(accumulator, candidate_marginal, member_occurrences)

	var hp_and_ko: Dictionary = _hp_and_ko_probe(evaluator, members)
	return {
		"comparison_id": COMPARISON_ID,
		"candidate_ids": CANDIDATE_IDS.duplicate(),
		"eligible_species": members.size(),
		"roster_size": ROSTER_SIZE,
		"schedule_count": SCHEDULE_STRIDES.size(),
		"member_occurrences": member_occurrences,
		"schedule_reports": schedule_reports,
		"candidates": candidates,
		"low_signal_no_unique_context_bonus_is_zero": low_signal_no_unique_context_bonus_is_zero,
		"one_hp_score_invariant": bool(hp_and_ko.get("one_hp_score_invariant", false)),
		"ko_changes_survivor_context": bool(hp_and_ko.get("ko_changes_survivor_context", false)),
		"hp_and_ko_probe": hp_and_ko,
	}


func _formula_metrics(member: Dictionary, disjoint: Dictionary) -> Dictionary:
	var unique_roles: int = (member.get("unique_strong_role_ids", []) as Array).size()
	var redundant_roles: int = (member.get("redundant_strong_role_ids", []) as Array).size()
	var unique_offense: int = (member.get("unique_offensive_coverage_type_ids", []) as Array).size()
	var redundant_offense: int = (member.get("redundant_offensive_coverage_type_ids", []) as Array).size()
	var unique_resistance: int = (disjoint.get("unique_exclusive_resistance_type_ids", []) as Array).size()
	var redundant_resistance: int = (disjoint.get("redundant_exclusive_resistance_type_ids", []) as Array).size()
	var unique_immunity: int = (disjoint.get("unique_immunity_type_ids", []) as Array).size()
	var redundant_immunity: int = (disjoint.get("redundant_immunity_type_ids", []) as Array).size()
	var role_scores: Dictionary = member.get("role_scores_bp", {}) as Dictionary
	var top_scores: Array[int] = []
	for raw_score in role_scores.values():
		top_scores.append(clampi(int(raw_score), 0, 10000))
	top_scores.sort()
	top_scores.reverse()
	var role_max: int = 0 if top_scores.is_empty() else top_scores[0]
	var role_second: int = 0 if top_scores.size() < 2 else top_scores[1]
	var absolute_capacity: int = roundi(float(role_max * 3 + role_second) / 4.0)
	var unique_family_count: int = 0
	for count in [unique_roles, unique_offense, unique_resistance, unique_immunity]:
		if int(count) > 0:
			unique_family_count += 1
	var unique_units: int = unique_roles + unique_offense + unique_resistance + unique_immunity
	var redundant_units: int = redundant_roles + redundant_offense + redundant_resistance + redundant_immunity
	var family_presence_context: int = mini(10000, unique_family_count * 2500)
	var capped_units_context: int = mini(
		10000,
		mini(unique_roles, 2) * 2500
		+ mini(unique_offense, 3) * 1000
		+ mini(unique_resistance, 3) * 1000
		+ mini(unique_immunity, 2) * 1500,
	)
	return {
		"species_id": String(member.get("species_id", "")),
		"instance_id": String(member.get("instance_id", "")),
		"role_max_bp": role_max,
		"role_second_bp": role_second,
		"absolute_capacity_bp": absolute_capacity,
		"unique_role_count": unique_roles,
		"redundant_role_count": redundant_roles,
		"unique_offense_count": unique_offense,
		"redundant_offense_count": redundant_offense,
		"unique_exclusive_resistance_count": unique_resistance,
		"redundant_exclusive_resistance_count": redundant_resistance,
		"unique_immunity_count": unique_immunity,
		"redundant_immunity_count": redundant_immunity,
		"unique_family_count": unique_family_count,
		"unique_units": unique_units,
		"redundant_units": redundant_units,
		"family_presence_context_bp": family_presence_context,
		"capped_units_context_bp": capped_units_context,
	}


func _candidate_score(candidate_id: String, metrics: Dictionary) -> int:
	var role_max: int = clampi(int(metrics.get("role_max_bp", 0)), 0, 10000)
	var absolute_capacity: int = clampi(int(metrics.get("absolute_capacity_bp", 0)), 0, 10000)
	var unique_units: int = maxi(0, int(metrics.get("unique_units", 0)))
	var unique_family_count: int = maxi(0, int(metrics.get("unique_family_count", 0)))
	var family_presence_context: int = clampi(int(metrics.get("family_presence_context_bp", 0)), 0, 10000)
	var capped_units_context: int = clampi(int(metrics.get("capped_units_context_bp", 0)), 0, 10000)
	match candidate_id:
		"role_max_only":
			return role_max
		"naive_unique_units_additive":
			return mini(10000, absolute_capacity + unique_units * 750)
		"family_presence_blend":
			return _floor_blend(absolute_capacity, family_presence_context)
		"capped_units_blend":
			return _floor_blend(absolute_capacity, capped_units_context)
		"guarded_family_bonus":
			return mini(10000, absolute_capacity + mini(2000, unique_family_count * 500))
		_:
			return 0


func _floor_blend(absolute_capacity: int, context_bp: int) -> int:
	var floor_score: int = roundi(float(absolute_capacity) * 0.80)
	var blended_score: int = roundi(float(absolute_capacity) * 0.70 + float(context_bp) * 0.30)
	return clampi(maxi(floor_score, blended_score), 0, 10000)


func _new_candidate_accumulator() -> Dictionary:
	return {
		"sum": 0,
		"min": 10000,
		"max": 0,
		"ge_7500": 0,
		"ge_9000": 0,
		"ceiling_count": 0,
		"score_histogram": {},
		"strong_role_redundant_sum": 0,
		"strong_role_redundant_count": 0,
		"moderate_unique_sum": 0,
		"moderate_unique_count": 0,
		"low_signal_no_unique_sum": 0,
		"low_signal_no_unique_count": 0,
		"absolute_floor_violations": 0,
	}


func _accumulate_score(accumulator: Dictionary, score: int, metrics: Dictionary) -> void:
	accumulator["sum"] = int(accumulator.get("sum", 0)) + score
	accumulator["min"] = mini(int(accumulator.get("min", 10000)), score)
	accumulator["max"] = maxi(int(accumulator.get("max", 0)), score)
	if score >= 7500:
		accumulator["ge_7500"] = int(accumulator.get("ge_7500", 0)) + 1
	if score >= 9000:
		accumulator["ge_9000"] = int(accumulator.get("ge_9000", 0)) + 1
	if score == 10000:
		accumulator["ceiling_count"] = int(accumulator.get("ceiling_count", 0)) + 1
	var histogram: Dictionary = accumulator.get("score_histogram", {}) as Dictionary
	var bucket: int = int(score / 500)
	histogram[bucket] = int(histogram.get(bucket, 0)) + 1
	accumulator["score_histogram"] = histogram
	var role_max: int = int(metrics.get("role_max_bp", 0))
	var unique_roles: int = int(metrics.get("unique_role_count", 0))
	var redundant_roles: int = int(metrics.get("redundant_role_count", 0))
	var unique_units: int = int(metrics.get("unique_units", 0))
	if role_max >= 9000 and unique_roles == 0 and redundant_roles > 0:
		accumulator["strong_role_redundant_sum"] = int(accumulator.get("strong_role_redundant_sum", 0)) + score
		accumulator["strong_role_redundant_count"] = int(accumulator.get("strong_role_redundant_count", 0)) + 1
	if role_max >= 5000 and role_max < 7500 and unique_units > 0:
		accumulator["moderate_unique_sum"] = int(accumulator.get("moderate_unique_sum", 0)) + score
		accumulator["moderate_unique_count"] = int(accumulator.get("moderate_unique_count", 0)) + 1
	if role_max < 7500 and unique_units == 0:
		accumulator["low_signal_no_unique_sum"] = int(accumulator.get("low_signal_no_unique_sum", 0)) + score
		accumulator["low_signal_no_unique_count"] = int(accumulator.get("low_signal_no_unique_count", 0)) + 1
	var floor_bp: int = roundi(float(int(metrics.get("absolute_capacity_bp", 0))) * 0.80)
	if score < floor_bp:
		accumulator["absolute_floor_violations"] = int(accumulator.get("absolute_floor_violations", 0)) + 1


func _finalize_candidate(accumulator: Dictionary, marginal: Dictionary, count: int) -> Dictionary:
	return {
		"mean_bp": _mean_bp(int(accumulator.get("sum", 0)), count),
		"min_bp": int(accumulator.get("min", 0)),
		"max_bp": int(accumulator.get("max", 0)),
		"ge_7500_count": int(accumulator.get("ge_7500", 0)),
		"ge_9000_count": int(accumulator.get("ge_9000", 0)),
		"ceiling_count": int(accumulator.get("ceiling_count", 0)),
		"score_histogram_500bp": (accumulator.get("score_histogram", {}) as Dictionary).duplicate(true),
		"strong_role_redundant_mean_bp": _mean_bp(int(accumulator.get("strong_role_redundant_sum", 0)), int(accumulator.get("strong_role_redundant_count", 0))),
		"strong_role_redundant_count": int(accumulator.get("strong_role_redundant_count", 0)),
		"moderate_unique_mean_bp": _mean_bp(int(accumulator.get("moderate_unique_sum", 0)), int(accumulator.get("moderate_unique_count", 0))),
		"moderate_unique_count": int(accumulator.get("moderate_unique_count", 0)),
		"low_signal_no_unique_mean_bp": _mean_bp(int(accumulator.get("low_signal_no_unique_sum", 0)), int(accumulator.get("low_signal_no_unique_count", 0))),
		"low_signal_no_unique_count": int(accumulator.get("low_signal_no_unique_count", 0)),
		"absolute_floor_violations": int(accumulator.get("absolute_floor_violations", 0)),
		"marginal_removal": marginal.duplicate(true),
	}


func _marginal_formula_report(
	evaluator: TrainerRosterStrategicValueEvaluator,
	members: Array[Dictionary],
) -> Dictionary:
	var out: Dictionary = {}
	for raw_candidate_id in CANDIDATE_IDS:
		out[String(raw_candidate_id)] = {
			"cases": 0,
			"cases_with_positive_survivor_delta": 0,
			"cases_with_negative_survivor_delta": 0,
			"positive_delta_bp": 0,
			"negative_delta_bp": 0,
			"max_positive_delta_bp": 0,
		}
	for raw_stride in SCHEDULE_STRIDES:
		var stride: int = int(raw_stride)
		var sample_count: int = mini(MARGINAL_SAMPLE_ROSTERS_PER_SCHEDULE, members.size())
		for anchor in range(sample_count):
			var roster: Array[Dictionary] = _scheduled_roster(members, anchor, stride)
			var before_evidence: Dictionary = evaluator.extract_structural_evidence(roster)
			var before_metrics: Dictionary = _metrics_by_id(before_evidence)
			for removed_slot in range(ROSTER_SIZE):
				var reduced: Array[Dictionary] = []
				for slot in range(ROSTER_SIZE):
					if slot != removed_slot:
						reduced.append(roster[slot])
				var after_evidence: Dictionary = evaluator.extract_structural_evidence(reduced)
				var after_metrics: Dictionary = _metrics_by_id(after_evidence)
				for raw_candidate_id in CANDIDATE_IDS:
					var candidate_id := String(raw_candidate_id)
					var positive_delta: int = 0
					var negative_delta: int = 0
					for instance_id in after_metrics.keys():
						var before: Dictionary = before_metrics.get(String(instance_id), {}) as Dictionary
						var after: Dictionary = after_metrics.get(String(instance_id), {}) as Dictionary
						var delta: int = _candidate_score(candidate_id, after) - _candidate_score(candidate_id, before)
						if delta > 0:
							positive_delta += delta
						elif delta < 0:
							negative_delta += -delta
					var accumulator: Dictionary = out[candidate_id] as Dictionary
					accumulator["cases"] = int(accumulator.get("cases", 0)) + 1
					if positive_delta > 0:
						accumulator["cases_with_positive_survivor_delta"] = int(accumulator.get("cases_with_positive_survivor_delta", 0)) + 1
						accumulator["positive_delta_bp"] = int(accumulator.get("positive_delta_bp", 0)) + positive_delta
						accumulator["max_positive_delta_bp"] = maxi(int(accumulator.get("max_positive_delta_bp", 0)), positive_delta)
					if negative_delta > 0:
						accumulator["cases_with_negative_survivor_delta"] = int(accumulator.get("cases_with_negative_survivor_delta", 0)) + 1
						accumulator["negative_delta_bp"] = int(accumulator.get("negative_delta_bp", 0)) + negative_delta
					out[candidate_id] = accumulator
	return out


func _metrics_by_id(evidence: Dictionary) -> Dictionary:
	var disjoint_by_id: Dictionary = _disjoint_helper._disjoint_member_metrics(evidence)
	var out: Dictionary = {}
	for raw_member in evidence.get("member_evidence", []):
		if not (raw_member is Dictionary):
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		out[instance_id] = _formula_metrics(member, disjoint_by_id.get(instance_id, {}) as Dictionary)
	return out


func _hp_and_ko_probe(
	evaluator: TrainerRosterStrategicValueEvaluator,
	members: Array[Dictionary],
) -> Dictionary:
	var roster: Array[Dictionary] = _scheduled_roster(members, 0, int(SCHEDULE_STRIDES[0]))
	var baseline_evidence: Dictionary = evaluator.extract_structural_evidence(roster)
	var baseline_metrics: Dictionary = _metrics_by_id(baseline_evidence)
	var low_hp_roster: Array[Dictionary] = []
	for raw_member in roster:
		var member: Dictionary = (raw_member as Dictionary).duplicate(true)
		member["current_hp"] = 1
		member["is_knocked_out"] = false
		low_hp_roster.append(member)
	var low_hp_metrics: Dictionary = _metrics_by_id(evaluator.extract_structural_evidence(low_hp_roster))
	var one_hp_invariant: bool = _score_maps_equal(baseline_metrics, low_hp_metrics)

	var ko_roster: Array[Dictionary] = []
	for index in range(roster.size()):
		var member: Dictionary = (roster[index] as Dictionary).duplicate(true)
		if index == 0:
			member["current_hp"] = 0
			member["is_knocked_out"] = true
		ko_roster.append(member)
	var ko_metrics: Dictionary = _metrics_by_id(evaluator.extract_structural_evidence(ko_roster))
	var ko_changes: bool = false
	for instance_id in ko_metrics.keys():
		var before: Dictionary = baseline_metrics.get(String(instance_id), {}) as Dictionary
		var after: Dictionary = ko_metrics.get(String(instance_id), {}) as Dictionary
		for candidate_id in ["family_presence_blend", "capped_units_blend", "guarded_family_bonus"]:
			if _candidate_score(String(candidate_id), before) != _candidate_score(String(candidate_id), after):
				ko_changes = true
				break
		if ko_changes:
			break
	return {
		"one_hp_score_invariant": one_hp_invariant,
		"ko_changes_survivor_context": ko_changes,
		"baseline_member_count": baseline_metrics.size(),
		"ko_member_count": ko_metrics.size(),
	}


func _score_maps_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for instance_id in a.keys():
		if not b.has(instance_id):
			return false
		var metrics_a: Dictionary = a[instance_id] as Dictionary
		var metrics_b: Dictionary = b[instance_id] as Dictionary
		for raw_candidate_id in CANDIDATE_IDS:
			var candidate_id := String(raw_candidate_id)
			if _candidate_score(candidate_id, metrics_a) != _candidate_score(candidate_id, metrics_b):
				return false
	return true


func _marginal_positive_cases(candidates: Dictionary, candidate_id: String) -> int:
	var candidate: Dictionary = candidates.get(candidate_id, {}) as Dictionary
	var marginal: Dictionary = candidate.get("marginal_removal", {}) as Dictionary
	return int(marginal.get("cases_with_positive_survivor_delta", 0))


func _all_candidates_no_negative_marginal(candidates: Dictionary) -> bool:
	for raw_candidate_id in CANDIDATE_IDS:
		var candidate: Dictionary = candidates.get(String(raw_candidate_id), {}) as Dictionary
		var marginal: Dictionary = candidate.get("marginal_removal", {}) as Dictionary
		if int(marginal.get("cases_with_negative_survivor_delta", 0)) != 0:
			return false
	return true


func _context_candidates_preserve_floor(candidates: Dictionary) -> bool:
	for candidate_id in ["family_presence_blend", "capped_units_blend", "guarded_family_bonus"]:
		var candidate: Dictionary = candidates.get(String(candidate_id), {}) as Dictionary
		if int(candidate.get("absolute_floor_violations", -1)) != 0:
			return false
	return true


func _candidate_metric(candidates: Dictionary, candidate_id: String, metric: String) -> int:
	return int((candidates.get(candidate_id, {}) as Dictionary).get(metric, 0))


func _synthetic_monotonicity() -> bool:
	var base := _synthetic_metrics(7000, 0, 0, 0, 0)
	var role_unique := _synthetic_metrics(7000, 1, 0, 0, 0)
	var broad_unique := _synthetic_metrics(7000, 1, 2, 2, 1)
	for candidate_id in ["naive_unique_units_additive", "family_presence_blend", "capped_units_blend", "guarded_family_bonus"]:
		var base_score: int = _candidate_score(String(candidate_id), base)
		var role_score: int = _candidate_score(String(candidate_id), role_unique)
		var broad_score: int = _candidate_score(String(candidate_id), broad_unique)
		if role_score < base_score or broad_score < role_score:
			return false
	return true


func _synthetic_redundancy_floor() -> bool:
	var base := _synthetic_metrics(8000, 0, 0, 0, 0)
	base["redundant_units"] = 0
	var redundant: Dictionary = base.duplicate(true)
	redundant["redundant_units"] = 40
	for candidate_id in ["family_presence_blend", "capped_units_blend", "guarded_family_bonus"]:
		if _candidate_score(String(candidate_id), redundant) != _candidate_score(String(candidate_id), base):
			return false
	return true


func _synthetic_breadth_caps() -> bool:
	var capped := _synthetic_metrics(6000, 2, 3, 3, 2)
	var absurd := _synthetic_metrics(6000, 20, 30, 30, 20)
	return (
		int(capped.get("capped_units_context_bp", 0)) == 10000
		and int(absurd.get("capped_units_context_bp", 0)) == 10000
		and _candidate_score("capped_units_blend", capped) == _candidate_score("capped_units_blend", absurd)
		and _candidate_score("family_presence_blend", capped) == _candidate_score("family_presence_blend", absurd)
		and _candidate_score("guarded_family_bonus", capped) == _candidate_score("guarded_family_bonus", absurd)
	)


func _synthetic_metrics(
	absolute_capacity: int,
	unique_roles: int,
	unique_offense: int,
	unique_resistance: int,
	unique_immunity: int,
) -> Dictionary:
	var family_count: int = 0
	for count in [unique_roles, unique_offense, unique_resistance, unique_immunity]:
		if int(count) > 0:
			family_count += 1
	var unique_units: int = unique_roles + unique_offense + unique_resistance + unique_immunity
	return {
		"role_max_bp": absolute_capacity,
		"role_second_bp": absolute_capacity,
		"absolute_capacity_bp": absolute_capacity,
		"unique_role_count": unique_roles,
		"redundant_role_count": 0,
		"unique_offense_count": unique_offense,
		"redundant_offense_count": 0,
		"unique_exclusive_resistance_count": unique_resistance,
		"redundant_exclusive_resistance_count": 0,
		"unique_immunity_count": unique_immunity,
		"redundant_immunity_count": 0,
		"unique_family_count": family_count,
		"unique_units": unique_units,
		"redundant_units": 0,
		"family_presence_context_bp": mini(10000, family_count * 2500),
		"capped_units_context_bp": mini(
			10000,
			mini(unique_roles, 2) * 2500
			+ mini(unique_offense, 3) * 1000
			+ mini(unique_resistance, 3) * 1000
			+ mini(unique_immunity, 2) * 1500,
		),
	}


func _mean_bp(total: int, count: int) -> int:
	if count <= 0:
		return 0
	return roundi(float(total) / float(count))
