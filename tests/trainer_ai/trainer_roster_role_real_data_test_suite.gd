class_name TrainerRosterRoleRealDataTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const PROBE_ID := "runtime_levelup_l50_neutral_probe_v1"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const HIGH_ROLE_BP := 7500
const VERY_HIGH_ROLE_BP := 9000
const ROLE_IDS := [
	"physical_attacker",
	"special_attacker",
	"fast_attacker",
	"bulky_physical",
	"bulky_special",
	"support",
]

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("role_real_data_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	_check.call("role_real_data_species_count_canonical", species_ids.size() == 1025)

	var report_a: Dictionary = _build_report(game_data, catalog, species_ids)
	var report_b: Dictionary = _build_report(game_data, catalog, species_ids)
	var eligible_count: int = int(report_a.get("eligible_species", 0))
	var no_probe_moves: int = int(report_a.get("species_without_probe_moves", 0))

	_check.call("role_real_data_probe_accounts_for_all_species", eligible_count + no_probe_moves == species_ids.size())
	_check.call("role_real_data_probe_has_eligible_species", eligible_count > 0)
	_check.call("role_real_data_all_scores_are_basis_points", bool(report_a.get("all_scores_in_range", false)))
	_check.call("role_real_data_probe_moves_all_runtime_supported", bool(report_a.get("all_probe_moves_runtime_supported", false)))
	_check.call("role_real_data_probe_never_exceeds_four_moves", bool(report_a.get("probe_move_cap_respected", false)))
	_check.call("role_real_data_report_is_deterministic", report_a == report_b)
	_check.call("role_real_data_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call("role_real_data_role_model_id_preserved", bool(report_a.get("role_model_id_consistent", false)))

	print("\n=== TRAINER ROLE REAL DATA AUDIT ===")
	print(JSON.stringify(report_a))


func _build_report(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var inference := TrainerRosterRoleInference.new()
	var role_stats: Dictionary = {}
	for role_id in ROLE_IDS:
		role_stats[role_id] = {
			"sum": 0,
			"zero": 0,
			"ge_5000": 0,
			"ge_7500": 0,
			"ge_9000": 0,
			"eq_10000": 0,
		}

	var eligible_count: int = 0
	var no_probe_moves: int = 0
	var all_scores_in_range: bool = true
	var all_probe_moves_runtime_supported: bool = true
	var probe_move_cap_respected: bool = true
	var role_model_id_consistent: bool = true
	var multi_role_histogram: Dictionary = {}
	var top_role_tie_histogram: Dictionary = {}
	var physical_bulk_signals: Array[int] = []
	var special_bulk_signals: Array[int] = []
	var records: Array[Dictionary] = []

	for species_id in species_ids:
		var species: CreatureSpecies = game_data.species_catalog.get_by_id(species_id)
		if species == null:
			continue
		var probe_moves: Array[StringName] = _probe_moves(species, catalog)
		if probe_moves.is_empty():
			no_probe_moves += 1
			continue
		eligible_count += 1
		probe_move_cap_respected = probe_move_cap_respected and probe_moves.size() <= ProgressionRuleset.MOVE_SLOTS_MAX
		for move_id in probe_moves:
			var move: MoveDefinition = catalog.move(move_id)
			if move == null or move.classification != RUNTIME_SUPPORTED:
				all_probe_moves_runtime_supported = false

		var member_view: Dictionary = _member_probe(species, probe_moves)
		var result: Dictionary = inference.infer_role_scores(member_view, catalog)
		role_model_id_consistent = role_model_id_consistent and String(result.get("model_id", "")) == TrainerRosterRoleInference.ROLE_MODEL_ID
		var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
		var evidence: Dictionary = result.get("intrinsic_evidence", {}) as Dictionary
		var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
		var high_role_count: int = 0
		var top_score: int = 0
		var top_ties: int = 0

		for role_id in ROLE_IDS:
			var score: int = int(scores.get(role_id, 0))
			all_scores_in_range = all_scores_in_range and score >= 0 and score <= 10000
			var stats: Dictionary = role_stats[role_id] as Dictionary
			stats["sum"] = int(stats.get("sum", 0)) + score
			if score == 0:
				stats["zero"] = int(stats.get("zero", 0)) + 1
			if score >= 5000:
				stats["ge_5000"] = int(stats.get("ge_5000", 0)) + 1
			if score >= HIGH_ROLE_BP:
				stats["ge_7500"] = int(stats.get("ge_7500", 0)) + 1
				high_role_count += 1
			if score >= VERY_HIGH_ROLE_BP:
				stats["ge_9000"] = int(stats.get("ge_9000", 0)) + 1
			if score == 10000:
				stats["eq_10000"] = int(stats.get("eq_10000", 0)) + 1
			if score > top_score:
				top_score = score
				top_ties = 1
			elif score == top_score:
				top_ties += 1

		var high_key := String.num_int64(high_role_count)
		multi_role_histogram[high_key] = int(multi_role_histogram.get(high_key, 0)) + 1
		var tie_key := String.num_int64(top_ties)
		top_role_tie_histogram[tie_key] = int(top_role_tie_histogram.get(tie_key, 0)) + 1

		var physical_bulk_signal: int = int(capabilities.get("physical_bulk_signal", 0))
		var special_bulk_signal: int = int(capabilities.get("special_bulk_signal", 0))
		physical_bulk_signals.append(physical_bulk_signal)
		special_bulk_signals.append(special_bulk_signal)
		records.append({
			"species_id": String(species_id),
			"scores": scores.duplicate(true),
			"physical_bulk_signal": physical_bulk_signal,
			"special_bulk_signal": special_bulk_signal,
			"probe_moves": _stringify_ids(probe_moves),
		})

	var physical_bulk_median: int = _median_int(physical_bulk_signals)
	var special_bulk_median: int = _median_int(special_bulk_signals)
	var high_physical_below_median: int = 0
	var high_special_below_median: int = 0
	var saturated_examples: Array[Dictionary] = []
	var physical_shape_examples: Array[Dictionary] = []
	var special_shape_examples: Array[Dictionary] = []

	for record in records:
		var scores: Dictionary = record.get("scores", {}) as Dictionary
		var high_roles: int = 0
		for role_id in ROLE_IDS:
			if int(scores.get(role_id, 0)) >= HIGH_ROLE_BP:
				high_roles += 1
		if high_roles >= 4 and saturated_examples.size() < 8:
			saturated_examples.append({
				"species_id": record.get("species_id", ""),
				"high_roles": high_roles,
				"scores": scores.duplicate(true),
				"probe_moves": (record.get("probe_moves", []) as Array).duplicate(),
			})

		if int(scores.get("bulky_physical", 0)) >= VERY_HIGH_ROLE_BP and int(record.get("physical_bulk_signal", 0)) <= physical_bulk_median:
			high_physical_below_median += 1
			if physical_shape_examples.size() < 6:
				physical_shape_examples.append({
					"species_id": record.get("species_id", ""),
					"score": int(scores.get("bulky_physical", 0)),
					"absolute_bulk": int(record.get("physical_bulk_signal", 0)),
				})
		if int(scores.get("bulky_special", 0)) >= VERY_HIGH_ROLE_BP and int(record.get("special_bulk_signal", 0)) <= special_bulk_median:
			high_special_below_median += 1
			if special_shape_examples.size() < 6:
				special_shape_examples.append({
					"species_id": record.get("species_id", ""),
					"score": int(scores.get("bulky_special", 0)),
					"absolute_bulk": int(record.get("special_bulk_signal", 0)),
				})

	var role_summary: Dictionary = {}
	for role_id in ROLE_IDS:
		var stats: Dictionary = role_stats[role_id] as Dictionary
		role_summary[role_id] = {
			"mean_bp": int(stats.get("sum", 0)) / maxi(1, eligible_count),
			"zero": int(stats.get("zero", 0)),
			"ge_5000": int(stats.get("ge_5000", 0)),
			"ge_7500": int(stats.get("ge_7500", 0)),
			"ge_9000": int(stats.get("ge_9000", 0)),
			"eq_10000": int(stats.get("eq_10000", 0)),
		}

	return {
		"probe_id": PROBE_ID,
		"probe_level": PROBE_LEVEL,
		"species_total": species_ids.size(),
		"eligible_species": eligible_count,
		"species_without_probe_moves": no_probe_moves,
		"all_scores_in_range": all_scores_in_range,
		"all_probe_moves_runtime_supported": all_probe_moves_runtime_supported,
		"probe_move_cap_respected": probe_move_cap_respected,
		"role_model_id_consistent": role_model_id_consistent,
		"high_role_threshold_bp": HIGH_ROLE_BP,
		"very_high_role_threshold_bp": VERY_HIGH_ROLE_BP,
		"role_summary": role_summary,
		"high_role_count_histogram": multi_role_histogram,
		"top_role_tie_histogram": top_role_tie_histogram,
		"absolute_bulk_medians": {
			"physical": physical_bulk_median,
			"special": special_bulk_median,
		},
		"very_high_bulk_affinity_at_or_below_absolute_median": {
			"physical": high_physical_below_median,
			"special": high_special_below_median,
		},
		"saturated_examples": saturated_examples,
		"relative_physical_bulk_shape_examples": physical_shape_examples,
		"relative_special_bulk_shape_examples": special_shape_examples,
	}


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
		"instance_id": "role_real_probe_%s" % String(species.id),
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


func _median_int(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var sorted_values: Array[int] = values.duplicate()
	sorted_values.sort()
	var middle: int = sorted_values.size() / 2
	if sorted_values.size() % 2 == 1:
		return sorted_values[middle]
	return (sorted_values[middle - 1] + sorted_values[middle]) / 2


func _stringify_ids(ids: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for id in ids:
		out.append(String(id))
	return out


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
