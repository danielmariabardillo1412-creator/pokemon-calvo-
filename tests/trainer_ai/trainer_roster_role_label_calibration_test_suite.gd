class_name TrainerRosterRoleLabelCalibrationTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const HIGH_ROLE_BP := 7500
const PRIMARY_MARGIN_BP := 1000
const SECONDARY_MARGIN_BP := 1500
const ALL_ROLE_IDS := [
	"physical_attacker",
	"special_attacker",
	"fast_attacker",
	"bulky_physical",
	"bulky_special",
	"support",
]
const CORE_PRIMARY_ROLE_IDS := [
	"physical_attacker",
	"special_attacker",
	"bulky_physical",
	"bulky_special",
	"support",
]

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("role_label_calibration_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	_check.call("role_label_calibration_species_count_canonical", species_ids.size() == 1025)

	var report_a: Dictionary = _build_report(game_data, catalog, species_ids)
	var report_b: Dictionary = _build_report(game_data, catalog, species_ids)
	var eligible: int = int(report_a.get("eligible_species", 0))
	var missing: int = int(report_a.get("species_without_probe_moves", 0))
	_check.call("role_label_calibration_accounts_for_all_species", eligible + missing == species_ids.size())
	_check.call("role_label_calibration_has_eligible_species", eligible > 0)
	_check.call("role_label_calibration_hierarchy_does_not_increase_top_ties", int(report_a.get("core_multi_top_ties", 0)) <= int(report_a.get("flat_multi_top_ties", 0)))
	_check.call("role_label_calibration_report_deterministic", report_a == report_b)
	_check.call("role_label_calibration_report_json_serializable", not JSON.stringify(report_a).is_empty())

	print("\n=== TRAINER ROLE LABEL CALIBRATION AUDIT ===")
	print(JSON.stringify(report_a))


func _build_report(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var inference := TrainerRosterRoleInference.new()
	var records: Array[Dictionary] = []
	var absolute_values: Dictionary = {}
	for role_id in CORE_PRIMARY_ROLE_IDS:
		absolute_values[role_id] = []

	var eligible: int = 0
	var missing: int = 0
	var fast_equals_best_offense: int = 0
	var flat_multi_top_ties: int = 0
	var core_multi_top_ties: int = 0
	var support_top_collision: int = 0
	var support_unique_top: int = 0
	var unique_core_primary: int = 0
	var unique_core_gap_500: int = 0
	var unique_core_gap_1000: int = 0
	var unique_core_gap_1500: int = 0
	var confident_core_primary: int = 0
	var fast_secondary_modifier: int = 0
	var primary_distribution: Dictionary = {}
	var secondary_count_histogram: Dictionary = {}
	var core_tie_histogram: Dictionary = {}

	for species_id in species_ids:
		var species: CreatureSpecies = game_data.species_catalog.get_by_id(species_id)
		if species == null:
			continue
		var moves: Array[StringName] = _probe_moves(species, catalog)
		if moves.is_empty():
			missing += 1
			continue
		eligible += 1

		var result: Dictionary = inference.infer_role_scores(_member_probe(species, moves), catalog)
		var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
		var evidence: Dictionary = result.get("intrinsic_evidence", {}) as Dictionary
		var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
		var absolute_by_role := {
			"physical_attacker": maxi(0, int(capabilities.get("physical_damage_signal", 0))),
			"special_attacker": maxi(0, int(capabilities.get("special_damage_signal", 0))),
			"bulky_physical": maxi(0, int(capabilities.get("physical_bulk_signal", 0))),
			"bulky_special": maxi(0, int(capabilities.get("special_bulk_signal", 0))),
			"support": maxi(
				clampi(int(capabilities.get("control_signal_bp", 0)), 0, 10000),
				clampi(int(capabilities.get("sustain_signal_bp", 0)), 0, 10000),
			),
		}
		for role_id in CORE_PRIMARY_ROLE_IDS:
			var values: Array = absolute_values[role_id] as Array
			values.append(int(absolute_by_role.get(role_id, 0)))

		var flat_top: Dictionary = _top_summary(scores, ALL_ROLE_IDS)
		var core_top: Dictionary = _top_summary(scores, CORE_PRIMARY_ROLE_IDS)
		var flat_ties: int = int(flat_top.get("tie_count", 0))
		var core_ties: int = int(core_top.get("tie_count", 0))
		if flat_ties > 1:
			flat_multi_top_ties += 1
		if core_ties > 1:
			core_multi_top_ties += 1
		var tie_key := String.num_int64(core_ties)
		core_tie_histogram[tie_key] = int(core_tie_histogram.get(tie_key, 0)) + 1

		var best_offense: int = maxi(
			int(scores.get("physical_attacker", 0)),
			int(scores.get("special_attacker", 0)),
		)
		if best_offense > 0 and int(scores.get("fast_attacker", 0)) == best_offense:
			fast_equals_best_offense += 1
		if int(scores.get("fast_attacker", 0)) >= HIGH_ROLE_BP:
			fast_secondary_modifier += 1

		var top_score: int = int(core_top.get("top_score", 0))
		var second_score: int = int(core_top.get("second_score", 0))
		var gap: int = maxi(0, top_score - second_score)
		var top_roles: Array = core_top.get("top_roles", []) as Array
		if top_roles.has("support") and top_roles.size() > 1:
			support_top_collision += 1
		elif top_roles.size() == 1 and String(top_roles[0]) == "support":
			support_unique_top += 1

		var primary_role := ""
		if core_ties == 1:
			unique_core_primary += 1
			primary_role = String(top_roles[0])
			primary_distribution[primary_role] = int(primary_distribution.get(primary_role, 0)) + 1
			if gap >= 500:
				unique_core_gap_500 += 1
			if gap >= 1000:
				unique_core_gap_1000 += 1
			if gap >= 1500:
				unique_core_gap_1500 += 1
			if top_score >= HIGH_ROLE_BP and gap >= PRIMARY_MARGIN_BP:
				confident_core_primary += 1

		var secondary_count: int = 0
		if core_ties == 1:
			for role_id in CORE_PRIMARY_ROLE_IDS:
				if role_id == primary_role:
					continue
				var score: int = int(scores.get(role_id, 0))
				if score >= HIGH_ROLE_BP and score >= top_score - SECONDARY_MARGIN_BP:
					secondary_count += 1
		var secondary_key := String.num_int64(secondary_count)
		secondary_count_histogram[secondary_key] = int(secondary_count_histogram.get(secondary_key, 0)) + 1

		records.append({
			"species_id": String(species_id),
			"scores": scores.duplicate(true),
			"primary_role": primary_role,
			"primary_top_score": top_score,
			"primary_gap": gap,
			"core_ties": core_ties,
			"absolute_by_role": absolute_by_role,
		})

	var absolute_medians: Dictionary = {}
	for role_id in CORE_PRIMARY_ROLE_IDS:
		absolute_medians[role_id] = _median_variant_array(absolute_values[role_id] as Array)

	var shape_only_unique_primary: int = 0
	var shape_only_by_role: Dictionary = {}
	var shape_only_examples: Array[Dictionary] = []
	for record in records:
		var primary_role := String(record.get("primary_role", ""))
		if primary_role.is_empty():
			continue
		var absolute_by_role: Dictionary = record.get("absolute_by_role", {}) as Dictionary
		var absolute_value: int = int(absolute_by_role.get(primary_role, 0))
		var median_value: int = int(absolute_medians.get(primary_role, 0))
		if absolute_value <= median_value:
			shape_only_unique_primary += 1
			shape_only_by_role[primary_role] = int(shape_only_by_role.get(primary_role, 0)) + 1
			if shape_only_examples.size() < 10:
				shape_only_examples.append({
					"species_id": record.get("species_id", ""),
					"primary_role": primary_role,
					"top_score": int(record.get("primary_top_score", 0)),
					"gap": int(record.get("primary_gap", 0)),
					"absolute_value": absolute_value,
					"role_absolute_median": median_value,
				})

	return {
		"probe_id": "role_label_calibration_levelup_l50_v1",
		"species_total": species_ids.size(),
		"eligible_species": eligible,
		"species_without_probe_moves": missing,
		"flat_multi_top_ties": flat_multi_top_ties,
		"core_multi_top_ties": core_multi_top_ties,
		"core_top_tie_histogram": core_tie_histogram,
		"fast_equals_best_offense": fast_equals_best_offense,
		"fast_secondary_modifier_ge_7500": fast_secondary_modifier,
		"support_top_collision": support_top_collision,
		"support_unique_top": support_unique_top,
		"unique_core_primary": unique_core_primary,
		"unique_core_primary_gap_ge_500": unique_core_gap_500,
		"unique_core_primary_gap_ge_1000": unique_core_gap_1000,
		"unique_core_primary_gap_ge_1500": unique_core_gap_1500,
		"confident_core_primary_top_ge_7500_gap_ge_1000": confident_core_primary,
		"primary_distribution": primary_distribution,
		"secondary_candidate_histogram_top_minus_1500_and_ge_7500": secondary_count_histogram,
		"role_absolute_medians": absolute_medians,
		"shape_only_unique_primary_at_or_below_role_absolute_median": shape_only_unique_primary,
		"shape_only_by_role": shape_only_by_role,
		"shape_only_examples": shape_only_examples,
	}


func _top_summary(scores: Dictionary, role_ids: Array) -> Dictionary:
	var top_score: int = -1
	var second_score: int = -1
	var top_roles: Array[String] = []
	for role_id in role_ids:
		var score: int = int(scores.get(role_id, 0))
		if score > top_score:
			second_score = top_score
			top_score = score
			top_roles = [String(role_id)]
		elif score == top_score:
			top_roles.append(String(role_id))
		elif score > second_score:
			second_score = score
	if second_score < 0:
		second_score = top_score
	if top_roles.size() > 1:
		second_score = top_score
	return {
		"top_score": maxi(0, top_score),
		"second_score": maxi(0, second_score),
		"tie_count": top_roles.size(),
		"top_roles": top_roles,
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
	var move_strings: Array[String] = []
	for move_id in move_ids:
		move_strings.append(String(move_id))
	return {
		"instance_id": "role_label_probe_%s" % String(species.id),
		"species_id": String(species.id),
		"level": PROBE_LEVEL,
		"current_hp": stats.max_hp,
		"stats": stats.to_dict(),
		"move_ids": move_strings,
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


func _median_variant_array(values: Array) -> int:
	if values.is_empty():
		return 0
	var sorted_values: Array[int] = []
	for value in values:
		sorted_values.append(int(value))
	sorted_values.sort()
	var middle: int = sorted_values.size() / 2
	if sorted_values.size() % 2 == 1:
		return sorted_values[middle]
	return (sorted_values[middle - 1] + sorted_values[middle]) / 2


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
