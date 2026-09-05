class_name TrainerRosterStructuralRealDataAuditTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const AUDIT_ID := "c3b_structural_real_data_balanced_cycles_v1"
const PROBE_ID := "runtime_levelup_l50_neutral_probe_v1"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const ROSTER_SIZE := 6
const SCHEDULE_STRIDES := [173, 389]
const MARGINAL_SAMPLE_ROSTERS_PER_SCHEDULE := 24

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("structural_real_data_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = _lexically_sorted_species_ids(game_data.species_catalog)
	_check.call("structural_real_data_species_count_canonical", species_ids.size() == 1025)
	var species_id_strings: Array[String] = _stringify_ids(species_ids)
	var lexical_copy: Array[String] = species_id_strings.duplicate()
	lexical_copy.sort()
	_check.call("structural_real_data_species_order_is_lexical", species_id_strings == lexical_copy)

	var probe: Dictionary = _build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)
	_check.call("structural_real_data_probe_accounts_for_all_species", members.size() + int(probe.get("species_without_probe_moves", 0)) == species_ids.size())
	_check.call("structural_real_data_probe_has_1021_eligible_species", members.size() == 1021)
	_check.call("structural_real_data_probe_moves_runtime_supported", bool(probe.get("all_probe_moves_runtime_supported", false)))
	_check.call("structural_real_data_probe_move_cap_respected", bool(probe.get("probe_move_cap_respected", false)))
	if members.size() < ROSTER_SIZE:
		return

	var report_a: Dictionary = _build_report(catalog, members)
	var report_b: Dictionary = _build_report(catalog, members)
	_check.call("structural_real_data_audit_id_recorded", String(report_a.get("audit_id", "")) == AUDIT_ID)
	_check.call("structural_real_data_uses_two_balanced_schedules", int(report_a.get("schedule_count", 0)) == SCHEDULE_STRIDES.size())
	_check.call("structural_real_data_roster_count_expected", int(report_a.get("roster_count", 0)) == members.size() * SCHEDULE_STRIDES.size())
	_check.call("structural_real_data_member_occurrences_balanced", int(report_a.get("member_occurrences", 0)) == members.size() * ROSTER_SIZE * SCHEDULE_STRIDES.size())
	_check.call("structural_real_data_all_rosters_have_six_members", bool(report_a.get("all_rosters_full", false)))
	_check.call("structural_real_data_structural_model_consistent", bool(report_a.get("structural_model_consistent", false)))
	_check.call("structural_real_data_has_unique_role_occurrences", int(report_a.get("occurrences_with_unique_role", 0)) > 0)
	_check.call("structural_real_data_has_redundant_role_occurrences", int(report_a.get("occurrences_with_redundant_role", 0)) > 0)
	_check.call("structural_real_data_has_unique_offensive_coverage", int(report_a.get("occurrences_with_unique_offensive_coverage", 0)) > 0)
	_check.call("structural_real_data_has_unique_defensive_evidence", int(report_a.get("occurrences_with_unique_resistance_or_immunity", 0)) > 0)
	_check.call("structural_real_data_removal_can_create_new_uniqueness", int((report_a.get("marginal_removal", {}) as Dictionary).get("cases_with_new_uniqueness", 0)) > 0)
	_check.call("structural_real_data_report_deterministic", report_a == report_b)
	_check.call("structural_real_data_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call("structural_real_data_audit_does_not_freeze_scalar", not report_a.has("structural_value_bp") and not report_a.has("permadeath_loss_cost_bp"))

	print("\n=== TRAINER ROSTER STRUCTURAL REAL DATA AUDIT ===")
	print(JSON.stringify(report_a))


func _build_probe_members(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var members: Array[Dictionary] = []
	var no_probe_moves: int = 0
	var all_runtime_supported: bool = true
	var move_cap_respected: bool = true
	for species_id in species_ids:
		var species: CreatureSpecies = game_data.species_catalog.get_by_id(species_id)
		if species == null:
			continue
		var probe_moves: Array[StringName] = _probe_moves(species, catalog)
		if probe_moves.is_empty():
			no_probe_moves += 1
			continue
		move_cap_respected = move_cap_respected and probe_moves.size() <= ProgressionRuleset.MOVE_SLOTS_MAX
		for move_id in probe_moves:
			var move: MoveDefinition = catalog.move(move_id)
			all_runtime_supported = all_runtime_supported and move != null and move.classification == RUNTIME_SUPPORTED
		members.append(_member_probe(species, probe_moves))
	return {
		"probe_id": PROBE_ID,
		"members": members,
		"species_without_probe_moves": no_probe_moves,
		"all_probe_moves_runtime_supported": all_runtime_supported,
		"probe_move_cap_respected": move_cap_respected,
	}


func _build_report(catalog: DefinitionCatalog, members: Array[Dictionary]) -> Dictionary:
	var evaluator := TrainerRosterStrategicValueEvaluator.new(catalog)
	var unique_role_histogram: Dictionary = {}
	var redundant_role_histogram: Dictionary = {}
	var unique_offense_histogram: Dictionary = {}
	var redundant_offense_histogram: Dictionary = {}
	var unique_resistance_histogram: Dictionary = {}
	var redundant_resistance_histogram: Dictionary = {}
	var unique_immunity_histogram: Dictionary = {}
	var redundant_immunity_histogram: Dictionary = {}
	var strong_role_count_histogram: Dictionary = {}
	var role_max_histogram: Dictionary = {}
	var correlations: Dictionary = {
		"unique_role_vs_unique_offense": _new_correlation(),
		"unique_role_vs_unique_resistance": _new_correlation(),
		"unique_offense_vs_unique_resistance": _new_correlation(),
		"unique_resistance_vs_unique_immunity": _new_correlation(),
		"role_max_vs_total_unique_units": _new_correlation(),
	}
	var occurrences_with_unique_role: int = 0
	var occurrences_with_redundant_role: int = 0
	var occurrences_with_unique_offense: int = 0
	var occurrences_with_unique_defense: int = 0
	var all_rosters_full: bool = true
	var structural_model_consistent: bool = true
	var roster_count: int = 0
	var member_occurrences: int = 0
	var strong_redundant_examples: Array[Dictionary] = []
	var moderate_unique_examples: Array[Dictionary] = []
	var sparse_examples: Array[Dictionary] = []
	var seen_strong_redundant: Dictionary = {}
	var seen_moderate_unique: Dictionary = {}
	var seen_sparse: Dictionary = {}
	var schedule_reports: Array[Dictionary] = []

	for raw_stride in SCHEDULE_STRIDES:
		var stride: int = int(raw_stride)
		var schedule_rosters: int = 0
		var schedule_occurrences: int = 0
		var schedule_unique_role_occurrences: int = 0
		var schedule_unique_offense_occurrences: int = 0
		for anchor in range(members.size()):
			var roster: Array[Dictionary] = _scheduled_roster(members, anchor, stride)
			var evidence: Dictionary = evaluator.extract_structural_evidence(roster)
			roster_count += 1
			schedule_rosters += 1
			all_rosters_full = all_rosters_full and int(evidence.get("member_count", -1)) == ROSTER_SIZE
			structural_model_consistent = structural_model_consistent and String(evidence.get("model_id", "")) == TrainerRosterStrategicValueEvaluator.STRUCTURAL_EVIDENCE_MODEL_ID
			for raw_member in evidence.get("member_evidence", []):
				if not (raw_member is Dictionary):
					continue
				var member: Dictionary = raw_member as Dictionary
				member_occurrences += 1
				schedule_occurrences += 1
				var unique_roles: int = (member.get("unique_strong_role_ids", []) as Array).size()
				var redundant_roles: int = (member.get("redundant_strong_role_ids", []) as Array).size()
				var unique_offense: int = (member.get("unique_offensive_coverage_type_ids", []) as Array).size()
				var redundant_offense: int = (member.get("redundant_offensive_coverage_type_ids", []) as Array).size()
				var unique_resistance: int = (member.get("unique_resistance_type_ids", []) as Array).size()
				var redundant_resistance: int = (member.get("redundant_resistance_type_ids", []) as Array).size()
				var unique_immunity: int = (member.get("unique_immunity_type_ids", []) as Array).size()
				var redundant_immunity: int = (member.get("redundant_immunity_type_ids", []) as Array).size()
				var strong_roles: int = (member.get("strong_role_ids", []) as Array).size()
				var role_max: int = int(member.get("role_score_max_bp", 0))
				var unique_units: int = _unique_units(member)
				_histogram_increment(unique_role_histogram, unique_roles)
				_histogram_increment(redundant_role_histogram, redundant_roles)
				_histogram_increment(unique_offense_histogram, unique_offense)
				_histogram_increment(redundant_offense_histogram, redundant_offense)
				_histogram_increment(unique_resistance_histogram, unique_resistance)
				_histogram_increment(redundant_resistance_histogram, redundant_resistance)
				_histogram_increment(unique_immunity_histogram, unique_immunity)
				_histogram_increment(redundant_immunity_histogram, redundant_immunity)
				_histogram_increment(strong_role_count_histogram, strong_roles)
				_histogram_increment(role_max_histogram, int(role_max / 1000))
				if unique_roles > 0:
					occurrences_with_unique_role += 1
					schedule_unique_role_occurrences += 1
				if redundant_roles > 0:
					occurrences_with_redundant_role += 1
				if unique_offense > 0:
					occurrences_with_unique_offense += 1
					schedule_unique_offense_occurrences += 1
				if unique_resistance > 0 or unique_immunity > 0:
					occurrences_with_unique_defense += 1
				_corr_add(correlations["unique_role_vs_unique_offense"] as Dictionary, unique_roles, unique_offense)
				_corr_add(correlations["unique_role_vs_unique_resistance"] as Dictionary, unique_roles, unique_resistance)
				_corr_add(correlations["unique_offense_vs_unique_resistance"] as Dictionary, unique_offense, unique_resistance)
				_corr_add(correlations["unique_resistance_vs_unique_immunity"] as Dictionary, unique_resistance, unique_immunity)
				_corr_add(correlations["role_max_vs_total_unique_units"] as Dictionary, role_max, unique_units)
				var species_id := String(member.get("species_id", ""))
				if role_max >= 9000 and unique_roles == 0 and redundant_roles > 0:
					_append_example_once(strong_redundant_examples, seen_strong_redundant, species_id, member)
				if role_max >= 5000 and role_max < 7500 and unique_units > 0:
					_append_example_once(moderate_unique_examples, seen_moderate_unique, species_id, member)
				if role_max < 5000 and int(member.get("runtime_supported_damaging_move_count", 0)) == 0:
					_append_example_once(sparse_examples, seen_sparse, species_id, member)
		schedule_reports.append({
			"stride": stride,
			"roster_count": schedule_rosters,
			"member_occurrences": schedule_occurrences,
			"occurrences_with_unique_role": schedule_unique_role_occurrences,
			"occurrences_with_unique_offensive_coverage": schedule_unique_offense_occurrences,
		})

	var finalized_correlations: Dictionary = {}
	for key in correlations.keys():
		finalized_correlations[String(key)] = _corr_bp(correlations[key] as Dictionary)

	return {
		"audit_id": AUDIT_ID,
		"probe_id": PROBE_ID,
		"eligible_species": members.size(),
		"roster_size": ROSTER_SIZE,
		"schedule_count": SCHEDULE_STRIDES.size(),
		"schedule_reports": schedule_reports,
		"roster_count": roster_count,
		"member_occurrences": member_occurrences,
		"all_rosters_full": all_rosters_full,
		"structural_model_consistent": structural_model_consistent,
		"occurrences_with_unique_role": occurrences_with_unique_role,
		"occurrences_with_redundant_role": occurrences_with_redundant_role,
		"occurrences_with_unique_offensive_coverage": occurrences_with_unique_offense,
		"occurrences_with_unique_resistance_or_immunity": occurrences_with_unique_defense,
		"unique_role_count_histogram": unique_role_histogram,
		"redundant_role_count_histogram": redundant_role_histogram,
		"unique_offensive_coverage_count_histogram": unique_offense_histogram,
		"redundant_offensive_coverage_count_histogram": redundant_offense_histogram,
		"unique_resistance_count_histogram": unique_resistance_histogram,
		"redundant_resistance_count_histogram": redundant_resistance_histogram,
		"unique_immunity_count_histogram": unique_immunity_histogram,
		"redundant_immunity_count_histogram": redundant_immunity_histogram,
		"strong_role_count_histogram": strong_role_count_histogram,
		"role_max_decile_histogram": role_max_histogram,
		"correlations_bp": finalized_correlations,
		"strong_but_role_redundant_examples": strong_redundant_examples,
		"moderate_but_structurally_unique_examples": moderate_unique_examples,
		"sparse_evidence_examples": sparse_examples,
		"marginal_removal": _marginal_removal_report(evaluator, members),
	}


func _scheduled_roster(members: Array[Dictionary], anchor: int, stride: int) -> Array[Dictionary]:
	var roster: Array[Dictionary] = []
	for slot in range(ROSTER_SIZE):
		var index: int = (anchor + slot * stride) % members.size()
		roster.append((members[index] as Dictionary).duplicate(true))
	return roster


func _marginal_removal_report(
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
			var before_by_id: Dictionary = _member_map(baseline)
			for removed_slot in range(ROSTER_SIZE):
				var reduced: Array[Dictionary] = []
				for slot in range(ROSTER_SIZE):
					if slot != removed_slot:
						reduced.append(roster[slot])
				var after: Dictionary = evaluator.extract_structural_evidence(reduced)
				var case_gain: int = 0
				for raw_after_member in after.get("member_evidence", []):
					if not (raw_after_member is Dictionary):
						continue
					var after_member: Dictionary = raw_after_member as Dictionary
					var instance_id := String(after_member.get("instance_id", ""))
					var before_member: Dictionary = before_by_id.get(instance_id, {}) as Dictionary
					case_gain += maxi(0, _unique_units(after_member) - _unique_units(before_member))
				cases += 1
				if case_gain > 0:
					cases_with_new_uniqueness += 1
					new_unique_units += case_gain
					if examples.size() < 8:
						examples.append({
							"stride": stride,
							"anchor": anchor,
							"removed_species_id": String(roster[removed_slot].get("species_id", "")),
							"new_unique_units": case_gain,
						})
	return {
		"sample_rosters_per_schedule": MARGINAL_SAMPLE_ROSTERS_PER_SCHEDULE,
		"cases": cases,
		"cases_with_new_uniqueness": cases_with_new_uniqueness,
		"new_unique_units": new_unique_units,
		"examples": examples,
	}


func _member_map(evidence: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for raw_member in evidence.get("member_evidence", []):
		if raw_member is Dictionary:
			var member: Dictionary = raw_member as Dictionary
			out[String(member.get("instance_id", ""))] = member
	return out


func _unique_units(member: Dictionary) -> int:
	return (
		(member.get("unique_strong_role_ids", []) as Array).size()
		+ (member.get("unique_offensive_coverage_type_ids", []) as Array).size()
		+ (member.get("unique_resistance_type_ids", []) as Array).size()
		+ (member.get("unique_immunity_type_ids", []) as Array).size()
	)


func _append_example_once(
	out: Array[Dictionary],
	seen: Dictionary,
	species_id: String,
	member: Dictionary,
) -> void:
	if out.size() >= 8 or species_id.is_empty() or seen.has(species_id):
		return
	seen[species_id] = true
	out.append({
		"species_id": species_id,
		"role_score_max_bp": int(member.get("role_score_max_bp", 0)),
		"strong_role_ids": (member.get("strong_role_ids", []) as Array).duplicate(),
		"unique_strong_role_ids": (member.get("unique_strong_role_ids", []) as Array).duplicate(),
		"redundant_strong_role_ids": (member.get("redundant_strong_role_ids", []) as Array).duplicate(),
		"unique_offensive_coverage_type_ids": (member.get("unique_offensive_coverage_type_ids", []) as Array).duplicate(),
		"unique_resistance_type_ids": (member.get("unique_resistance_type_ids", []) as Array).duplicate(),
		"unique_immunity_type_ids": (member.get("unique_immunity_type_ids", []) as Array).duplicate(),
		"runtime_supported_damaging_move_count": int(member.get("runtime_supported_damaging_move_count", 0)),
	})


func _new_correlation() -> Dictionary:
	return {"n": 0, "sx": 0.0, "sy": 0.0, "sxx": 0.0, "syy": 0.0, "sxy": 0.0}


func _corr_add(acc: Dictionary, x: int, y: int) -> void:
	acc["n"] = int(acc.get("n", 0)) + 1
	acc["sx"] = float(acc.get("sx", 0.0)) + float(x)
	acc["sy"] = float(acc.get("sy", 0.0)) + float(y)
	acc["sxx"] = float(acc.get("sxx", 0.0)) + float(x * x)
	acc["syy"] = float(acc.get("syy", 0.0)) + float(y * y)
	acc["sxy"] = float(acc.get("sxy", 0.0)) + float(x * y)


func _corr_bp(acc: Dictionary) -> int:
	var n: float = float(acc.get("n", 0))
	if n <= 1.0:
		return 0
	var sx: float = float(acc.get("sx", 0.0))
	var sy: float = float(acc.get("sy", 0.0))
	var sxx: float = float(acc.get("sxx", 0.0))
	var syy: float = float(acc.get("syy", 0.0))
	var sxy: float = float(acc.get("sxy", 0.0))
	var numerator: float = n * sxy - sx * sy
	var denominator_sq: float = (n * sxx - sx * sx) * (n * syy - sy * sy)
	if denominator_sq <= 0.0:
		return 0
	return clampi(int(round(numerator / sqrt(denominator_sq) * 10000.0)), -10000, 10000)


func _histogram_increment(histogram: Dictionary, value: int) -> void:
	var key := String.num_int64(value)
	histogram[key] = int(histogram.get(key, 0)) + 1


func _member_probe(species: CreatureSpecies, move_ids: Array[StringName]) -> Dictionary:
	var ivs: Dictionary = {}
	var evs: Dictionary = {}
	for stat_key in ProgressionRuleset.STAT_KEYS:
		ivs[stat_key] = ProgressionRuleset.IV_MAX
		evs[stat_key] = 0
	var stats: StatBlock = StatCalculator.compute(
		species.base_stat_block(),
		ivs,
		evs,
		ProgressionRuleset.NEUTRAL_NATURE,
		PROBE_LEVEL,
	)
	return {
		"instance_id": "structural_real_probe_%s" % String(species.id),
		"species_id": String(species.id),
		"level": PROBE_LEVEL,
		"current_hp": stats.max_hp,
		"stats": stats.to_dict(),
		"move_ids": _stringify_ids(move_ids),
	}


func _probe_moves(species: CreatureSpecies, catalog: DefinitionCatalog) -> Array[StringName]:
	var candidates: Array[Dictionary] = []
	for raw_entry in species.learnset:
		if not raw_entry is LearnSetEntry:
			continue
		var entry := raw_entry as LearnSetEntry
		if entry.method != LearnsetSystem.LEVEL_UP or entry.level > PROBE_LEVEL:
			continue
		var move: MoveDefinition = catalog.move(entry.move_id) if catalog != null else null
		if move == null or move.classification != RUNTIME_SUPPORTED:
			continue
		candidates.append({
			"level": entry.level,
			"order": entry.order,
			"move_id": entry.move_id,
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_level: int = int(a.get("level", 0))
		var b_level: int = int(b.get("level", 0))
		if a_level != b_level:
			return a_level < b_level
		var a_order: int = int(a.get("order", -1))
		var b_order: int = int(b.get("order", -1))
		if a_order != b_order:
			return a_order < b_order
		return String(a.get("move_id", "")) < String(b.get("move_id", ""))
	)
	var ordered: Array[StringName] = []
	for candidate in candidates:
		var move_id := StringName(String(candidate.get("move_id", "")))
		if ordered.has(move_id):
			ordered.erase(move_id)
		ordered.append(move_id)
	var out: Array[StringName] = []
	var start: int = maxi(0, ordered.size() - ProgressionRuleset.MOVE_SLOTS_MAX)
	for index in range(start, ordered.size()):
		out.append(ordered[index])
	return out


func _lexically_sorted_species_ids(catalog: SpeciesCatalog) -> Array[StringName]:
	var lexical_ids: Array[String] = []
	if catalog == null:
		return []
	for raw_id in catalog.all_ids():
		lexical_ids.append(String(raw_id))
	lexical_ids.sort()
	var out: Array[StringName] = []
	for lexical_id in lexical_ids:
		out.append(StringName(lexical_id))
	return out


func _stringify_ids(ids: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for id in ids:
		out.append(String(id))
	return out


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
