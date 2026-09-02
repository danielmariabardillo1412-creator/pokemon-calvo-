class_name TrainerRosterStructuralFormulaSensitivityTestSuite
extends TrainerRosterStructuralFormulaComparisonTestSuite

const SENSITIVITY_ID := "c3c_structural_capped_units_local_sensitivity_v1"
const CONTEXT_WEIGHTS_BP := [2500, 3000, 3500]
const ROLE_UNIT_BP := 2500
const OFFENSE_UNIT_BP := 1000
const RESISTANCE_UNIT_BP := 1000
const IMMUNITY_UNIT_BP := 1500
const ABSOLUTE_FLOOR_BP := 8000

const CAP_PROFILES := [
	{
		"id": "compact",
		"role_cap": 1,
		"offense_cap": 2,
		"resistance_cap": 2,
		"immunity_cap": 1,
	},
	{
		"id": "baseline",
		"role_cap": 2,
		"offense_cap": 3,
		"resistance_cap": 3,
		"immunity_cap": 2,
	},
	{
		"id": "broad",
		"role_cap": 2,
		"offense_cap": 4,
		"resistance_cap": 4,
		"immunity_cap": 2,
	},
]


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("structural_sensitivity_dataset_loaded", not normalized.is_empty())
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
	_check.call("structural_sensitivity_probe_has_1021_eligible_species", members.size() == 1021)
	if members.size() < ROSTER_SIZE:
		return

	var report_a: Dictionary = _build_sensitivity_report(catalog, members)
	var report_b: Dictionary = _build_sensitivity_report(catalog, members)
	_check.call("structural_sensitivity_id_recorded", String(report_a.get("sensitivity_id", "")) == SENSITIVITY_ID)
	_check.call("structural_sensitivity_has_nine_local_variants", int(report_a.get("variant_count", 0)) == CAP_PROFILES.size() * CONTEXT_WEIGHTS_BP.size())
	_check.call("structural_sensitivity_member_occurrences_balanced", int(report_a.get("member_occurrences", 0)) == members.size() * ROSTER_SIZE * SCHEDULE_STRIDES.size())
	_check.call("structural_sensitivity_report_deterministic", report_a == report_b)
	_check.call("structural_sensitivity_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call("structural_sensitivity_is_test_only", not report_a.has("production_structural_value_model_id") and not report_a.has("structural_value_bp"))
	_check.call("structural_sensitivity_baseline_matches_c3c_capped_units", bool(report_a.get("baseline_matches_c3c_capped_units", false)))
	_check.call("structural_sensitivity_caps_are_memberwise_monotonic", bool(report_a.get("caps_memberwise_monotonic", false)))
	_check.call("structural_sensitivity_all_variants_preserve_absolute_floor", _all_variant_metric_is(report_a, "absolute_floor_violations", 0))
	_check.call("structural_sensitivity_all_variants_have_no_negative_marginal", _all_marginal_metric_is(report_a, "cases_with_negative_survivor_delta", 0))
	_check.call("structural_sensitivity_all_variants_respond_to_marginal_change", _all_marginal_metric_positive(report_a, "cases_with_positive_survivor_delta"))
	_check.call("structural_sensitivity_low_signal_never_gets_context_bonus", bool(report_a.get("low_signal_context_bonus_is_zero", false)))
	_check.call("structural_sensitivity_schedule_spreads_recorded", _all_variant_metric_nonnegative(report_a, "schedule_mean_spread_bp"))
	_check.call("structural_sensitivity_synthetic_cap_monotonicity", _synthetic_cap_monotonicity())
	_check.call("structural_sensitivity_synthetic_weight_neighborhood_bounded", _synthetic_weight_neighborhood_bounded())

	print("\n=== TRAINER ROSTER STRUCTURAL FORMULA LOCAL SENSITIVITY ===")
	print(JSON.stringify(report_a))


func _build_sensitivity_report(
	catalog: DefinitionCatalog,
	members: Array[Dictionary],
) -> Dictionary:
	var evaluator := TrainerRosterStrategicValueEvaluator.new(catalog)
	var specs: Array[Dictionary] = _variant_specs()
	var accumulators: Dictionary = {}
	var schedule_sums: Dictionary = {}
	for spec in specs:
		var variant_id := String(spec.get("id", ""))
		accumulators[variant_id] = _new_sensitivity_accumulator()
		schedule_sums[variant_id] = []

	var member_occurrences: int = 0
	var baseline_matches: bool = true
	var caps_monotonic: bool = true
	var low_signal_context_bonus_is_zero: bool = true

	for raw_stride in SCHEDULE_STRIDES:
		var stride: int = int(raw_stride)
		var per_schedule_sum: Dictionary = {}
		for spec in specs:
			per_schedule_sum[String(spec.get("id", ""))] = 0
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
				var metrics: Dictionary = _formula_metrics(member, disjoint_by_id.get(instance_id, {}) as Dictionary)
				member_occurrences += 1
				schedule_occurrences += 1
				var scores_by_weight: Dictionary = {}
				for spec in specs:
					var variant_id := String(spec.get("id", ""))
					var score: int = _sensitivity_score(metrics, spec)
					var accumulator: Dictionary = accumulators[variant_id] as Dictionary
					_accumulate_sensitivity_score(accumulator, score, metrics)
					accumulators[variant_id] = accumulator
					per_schedule_sum[variant_id] = int(per_schedule_sum.get(variant_id, 0)) + score
					var weight_key := String.num_int64(int(spec.get("context_weight_bp", 0)))
					if not scores_by_weight.has(weight_key):
						scores_by_weight[weight_key] = {}
					var weight_scores: Dictionary = scores_by_weight[weight_key] as Dictionary
					weight_scores[String(spec.get("cap_profile_id", ""))] = score
					scores_by_weight[weight_key] = weight_scores
					if String(spec.get("cap_profile_id", "")) == "baseline" and int(spec.get("context_weight_bp", 0)) == 3000:
						baseline_matches = baseline_matches and score == _candidate_score("capped_units_blend", metrics)
					if int(metrics.get("role_max_bp", 0)) < 7500 and int(metrics.get("unique_units", 0)) == 0:
						low_signal_context_bonus_is_zero = low_signal_context_bonus_is_zero and _context_score(metrics, spec) == 0
				for weight_key in scores_by_weight.keys():
					var scores: Dictionary = scores_by_weight[weight_key] as Dictionary
					caps_monotonic = caps_monotonic and int(scores.get("compact", 0)) <= int(scores.get("baseline", 0)) and int(scores.get("baseline", 0)) <= int(scores.get("broad", 0))
		for spec in specs:
			var variant_id := String(spec.get("id", ""))
			var means: Array = schedule_sums[variant_id] as Array
			means.append(_mean_bp(int(per_schedule_sum.get(variant_id, 0)), schedule_occurrences))
			schedule_sums[variant_id] = means

	var marginal: Dictionary = _sensitivity_marginal_report(evaluator, members, specs)
	var variants: Dictionary = {}
	for spec in specs:
		var variant_id := String(spec.get("id", ""))
		var accumulator: Dictionary = accumulators[variant_id] as Dictionary
		var schedule_means: Array = schedule_sums[variant_id] as Array
		variants[variant_id] = _finalize_sensitivity_variant(
			spec,
			accumulator,
			marginal.get(variant_id, {}) as Dictionary,
			member_occurrences,
			schedule_means,
		)

	return {
		"sensitivity_id": SENSITIVITY_ID,
		"eligible_species": members.size(),
		"roster_size": ROSTER_SIZE,
		"schedule_count": SCHEDULE_STRIDES.size(),
		"member_occurrences": member_occurrences,
		"variant_count": specs.size(),
		"variant_ids": _variant_ids(specs),
		"baseline_matches_c3c_capped_units": baseline_matches,
		"caps_memberwise_monotonic": caps_monotonic,
		"low_signal_context_bonus_is_zero": low_signal_context_bonus_is_zero,
		"variants": variants,
	}


func _variant_specs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for raw_profile in CAP_PROFILES:
		var profile: Dictionary = raw_profile as Dictionary
		for raw_weight in CONTEXT_WEIGHTS_BP:
			var weight: int = int(raw_weight)
			out.append({
				"id": "%s_w%d" % [String(profile.get("id", "")), int(weight / 100)],
				"cap_profile_id": String(profile.get("id", "")),
				"context_weight_bp": weight,
				"role_cap": int(profile.get("role_cap", 0)),
				"offense_cap": int(profile.get("offense_cap", 0)),
				"resistance_cap": int(profile.get("resistance_cap", 0)),
				"immunity_cap": int(profile.get("immunity_cap", 0)),
			})
	return out


func _sensitivity_score(metrics: Dictionary, spec: Dictionary) -> int:
	var absolute_capacity: int = clampi(int(metrics.get("absolute_capacity_bp", 0)), 0, 10000)
	var context_score: int = _context_score(metrics, spec)
	var context_weight_bp: int = clampi(int(spec.get("context_weight_bp", 0)), 0, 10000)
	var absolute_weight_bp: int = 10000 - context_weight_bp
	var floor_score: int = roundi(float(absolute_capacity * ABSOLUTE_FLOOR_BP) / 10000.0)
	var blended_score: int = roundi(
		(float(absolute_capacity * absolute_weight_bp) + float(context_score * context_weight_bp)) / 10000.0
	)
	return clampi(maxi(floor_score, blended_score), 0, 10000)


func _context_score(metrics: Dictionary, spec: Dictionary) -> int:
	return mini(
		10000,
		mini(maxi(0, int(metrics.get("unique_role_count", 0))), maxi(0, int(spec.get("role_cap", 0)))) * ROLE_UNIT_BP
		+ mini(maxi(0, int(metrics.get("unique_offense_count", 0))), maxi(0, int(spec.get("offense_cap", 0)))) * OFFENSE_UNIT_BP
		+ mini(maxi(0, int(metrics.get("unique_exclusive_resistance_count", 0))), maxi(0, int(spec.get("resistance_cap", 0)))) * RESISTANCE_UNIT_BP
		+ mini(maxi(0, int(metrics.get("unique_immunity_count", 0))), maxi(0, int(spec.get("immunity_cap", 0)))) * IMMUNITY_UNIT_BP,
	)


func _new_sensitivity_accumulator() -> Dictionary:
	return {
		"sum": 0,
		"min": 10000,
		"max": 0,
		"ge_7500": 0,
		"ge_9000": 0,
		"ceiling_count": 0,
		"strong_role_redundant_sum": 0,
		"strong_role_redundant_count": 0,
		"moderate_unique_sum": 0,
		"moderate_unique_count": 0,
		"low_signal_no_unique_sum": 0,
		"low_signal_no_unique_count": 0,
		"absolute_floor_violations": 0,
	}


func _accumulate_sensitivity_score(
	accumulator: Dictionary,
	score: int,
	metrics: Dictionary,
) -> void:
	accumulator["sum"] = int(accumulator.get("sum", 0)) + score
	accumulator["min"] = mini(int(accumulator.get("min", 10000)), score)
	accumulator["max"] = maxi(int(accumulator.get("max", 0)), score)
	if score >= 7500:
		accumulator["ge_7500"] = int(accumulator.get("ge_7500", 0)) + 1
	if score >= 9000:
		accumulator["ge_9000"] = int(accumulator.get("ge_9000", 0)) + 1
	if score == 10000:
		accumulator["ceiling_count"] = int(accumulator.get("ceiling_count", 0)) + 1
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
	var floor_score: int = roundi(float(int(metrics.get("absolute_capacity_bp", 0)) * ABSOLUTE_FLOOR_BP) / 10000.0)
	if score < floor_score:
		accumulator["absolute_floor_violations"] = int(accumulator.get("absolute_floor_violations", 0)) + 1


func _sensitivity_marginal_report(
	evaluator: TrainerRosterStrategicValueEvaluator,
	members: Array[Dictionary],
	specs: Array[Dictionary],
) -> Dictionary:
	var out: Dictionary = {}
	for spec in specs:
		out[String(spec.get("id", ""))] = {
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
			var before_metrics: Dictionary = _metrics_by_id(evaluator.extract_structural_evidence(roster))
			for removed_slot in range(ROSTER_SIZE):
				var reduced: Array[Dictionary] = []
				for slot in range(ROSTER_SIZE):
					if slot != removed_slot:
						reduced.append(roster[slot])
				var after_metrics: Dictionary = _metrics_by_id(evaluator.extract_structural_evidence(reduced))
				for spec in specs:
					var variant_id := String(spec.get("id", ""))
					var positive_delta: int = 0
					var negative_delta: int = 0
					for instance_id in after_metrics.keys():
						var before: Dictionary = before_metrics.get(String(instance_id), {}) as Dictionary
						var after: Dictionary = after_metrics.get(String(instance_id), {}) as Dictionary
						var delta: int = _sensitivity_score(after, spec) - _sensitivity_score(before, spec)
						if delta > 0:
							positive_delta += delta
						elif delta < 0:
							negative_delta += -delta
					var accumulator: Dictionary = out[variant_id] as Dictionary
					accumulator["cases"] = int(accumulator.get("cases", 0)) + 1
					if positive_delta > 0:
						accumulator["cases_with_positive_survivor_delta"] = int(accumulator.get("cases_with_positive_survivor_delta", 0)) + 1
						accumulator["positive_delta_bp"] = int(accumulator.get("positive_delta_bp", 0)) + positive_delta
						accumulator["max_positive_delta_bp"] = maxi(int(accumulator.get("max_positive_delta_bp", 0)), positive_delta)
					if negative_delta > 0:
						accumulator["cases_with_negative_survivor_delta"] = int(accumulator.get("cases_with_negative_survivor_delta", 0)) + 1
						accumulator["negative_delta_bp"] = int(accumulator.get("negative_delta_bp", 0)) + negative_delta
					out[variant_id] = accumulator
	return out


func _finalize_sensitivity_variant(
	spec: Dictionary,
	accumulator: Dictionary,
	marginal: Dictionary,
	count: int,
	schedule_means: Array,
) -> Dictionary:
	var min_schedule: int = 10000
	var max_schedule: int = 0
	for raw_mean in schedule_means:
		var mean: int = int(raw_mean)
		min_schedule = mini(min_schedule, mean)
		max_schedule = maxi(max_schedule, mean)
	return {
		"cap_profile_id": String(spec.get("cap_profile_id", "")),
		"context_weight_bp": int(spec.get("context_weight_bp", 0)),
		"caps": {
			"role": int(spec.get("role_cap", 0)),
			"offense": int(spec.get("offense_cap", 0)),
			"exclusive_resistance": int(spec.get("resistance_cap", 0)),
			"immunity": int(spec.get("immunity_cap", 0)),
		},
		"mean_bp": _mean_bp(int(accumulator.get("sum", 0)), count),
		"min_bp": int(accumulator.get("min", 0)),
		"max_bp": int(accumulator.get("max", 0)),
		"ge_7500_count": int(accumulator.get("ge_7500", 0)),
		"ge_9000_count": int(accumulator.get("ge_9000", 0)),
		"ceiling_count": int(accumulator.get("ceiling_count", 0)),
		"strong_role_redundant_mean_bp": _mean_bp(int(accumulator.get("strong_role_redundant_sum", 0)), int(accumulator.get("strong_role_redundant_count", 0))),
		"moderate_unique_mean_bp": _mean_bp(int(accumulator.get("moderate_unique_sum", 0)), int(accumulator.get("moderate_unique_count", 0))),
		"low_signal_no_unique_mean_bp": _mean_bp(int(accumulator.get("low_signal_no_unique_sum", 0)), int(accumulator.get("low_signal_no_unique_count", 0))),
		"absolute_floor_violations": int(accumulator.get("absolute_floor_violations", 0)),
		"schedule_means_bp": schedule_means.duplicate(),
		"schedule_mean_spread_bp": max_schedule - min_schedule,
		"marginal_removal": marginal.duplicate(true),
	}


func _variant_ids(specs: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for spec in specs:
		out.append(String(spec.get("id", "")))
	return out


func _all_variant_metric_is(report: Dictionary, metric: String, expected: int) -> bool:
	for raw_variant in (report.get("variants", {}) as Dictionary).values():
		var variant: Dictionary = raw_variant as Dictionary
		if int(variant.get(metric, -1)) != expected:
			return false
	return true


func _all_variant_metric_nonnegative(report: Dictionary, metric: String) -> bool:
	for raw_variant in (report.get("variants", {}) as Dictionary).values():
		var variant: Dictionary = raw_variant as Dictionary
		if int(variant.get(metric, -1)) < 0:
			return false
	return true


func _all_marginal_metric_is(report: Dictionary, metric: String, expected: int) -> bool:
	for raw_variant in (report.get("variants", {}) as Dictionary).values():
		var variant: Dictionary = raw_variant as Dictionary
		var marginal: Dictionary = variant.get("marginal_removal", {}) as Dictionary
		if int(marginal.get(metric, -1)) != expected:
			return false
	return true


func _all_marginal_metric_positive(report: Dictionary, metric: String) -> bool:
	for raw_variant in (report.get("variants", {}) as Dictionary).values():
		var variant: Dictionary = raw_variant as Dictionary
		var marginal: Dictionary = variant.get("marginal_removal", {}) as Dictionary
		if int(marginal.get(metric, 0)) <= 0:
			return false
	return true


func _synthetic_cap_monotonicity() -> bool:
	var metrics := _synthetic_metrics(7000, 2, 4, 4, 2)
	for raw_weight in CONTEXT_WEIGHTS_BP:
		var compact := _spec_for("compact", int(raw_weight))
		var baseline := _spec_for("baseline", int(raw_weight))
		var broad := _spec_for("broad", int(raw_weight))
		if not (_sensitivity_score(metrics, compact) <= _sensitivity_score(metrics, baseline) and _sensitivity_score(metrics, baseline) <= _sensitivity_score(metrics, broad)):
			return false
	return true


func _synthetic_weight_neighborhood_bounded() -> bool:
	var metrics := _synthetic_metrics(7000, 2, 3, 3, 2)
	var scores: Array[int] = []
	for raw_weight in CONTEXT_WEIGHTS_BP:
		scores.append(_sensitivity_score(metrics, _spec_for("baseline", int(raw_weight))))
	var low: int = 10000
	var high: int = 0
	for score in scores:
		low = mini(low, score)
		high = maxi(high, score)
	return low >= roundi(7000.0 * 0.80) and high <= 10000 and high - low <= 1500


func _spec_for(profile_id: String, context_weight_bp: int) -> Dictionary:
	for spec in _variant_specs():
		if String(spec.get("cap_profile_id", "")) == profile_id and int(spec.get("context_weight_bp", 0)) == context_weight_bp:
			return spec
	return {}
