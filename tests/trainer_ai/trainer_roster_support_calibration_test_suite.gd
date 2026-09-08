class_name TrainerRosterSupportCalibrationTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const HIGH_ROLE_BP := 7500
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
	_check.call("support_calibration_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	_check.call("support_calibration_species_count_canonical", species_ids.size() == 1025)

	var report_a: Dictionary = _build_report(game_data, catalog, species_ids)
	var report_b: Dictionary = _build_report(game_data, catalog, species_ids)
	var eligible: int = int(report_a.get("eligible_species", 0))
	var missing: int = int(report_a.get("species_without_probe_moves", 0))
	var source_counts: Dictionary = report_a.get("support_source_counts", {}) as Dictionary
	var source_total: int = 0
	for raw_count in source_counts.values():
		source_total += int(raw_count)

	_check.call("support_calibration_accounts_for_all_species", eligible + missing == species_ids.size())
	_check.call("support_calibration_sources_account_for_eligible_species", source_total == eligible)
	_check.call("support_calibration_observes_support_cases", int(report_a.get("support_positive", 0)) > 0)
	_check.call("support_calibration_observes_max_support_cases", int(report_a.get("support_eq_10000", 0)) > 0)
	_check.call("support_calibration_report_deterministic", report_a == report_b)
	_check.call("support_calibration_report_json_serializable", not JSON.stringify(report_a).is_empty())

	print("\n=== TRAINER SUPPORT CALIBRATION AUDIT ===")
	print(JSON.stringify(report_a))


func _build_report(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var inference := TrainerRosterRoleInference.new()
	var eligible: int = 0
	var missing: int = 0
	var support_positive: int = 0
	var support_ge_7500: int = 0
	var support_eq_10000: int = 0
	var support_top_unique: int = 0
	var support_top_collision: int = 0
	var support_top_collision_with_offense: int = 0
	var support_top_collision_with_bulk: int = 0
	var support_ge_7500_with_high_offense: int = 0
	var support_eq_10000_with_high_offense: int = 0
	var support_eq_10000_single_supportive_move: int = 0
	var support_eq_10000_single_control_only_move: int = 0
	var support_eq_10000_single_sustain_only_move: int = 0
	var support_eq_10000_single_supportive_damaging_move: int = 0
	var support_eq_10000_multiple_supportive_moves: int = 0
	var support_source_counts := {
		"none": 0,
		"control_only": 0,
		"sustain_only": 0,
		"control_and_sustain": 0,
	}
	var max_support_source_counts := {
		"control_only": 0,
		"sustain_only": 0,
		"control_and_sustain": 0,
	}
	var supportive_move_count_histogram: Dictionary = {}
	var control_move_count_histogram: Dictionary = {}
	var sustain_move_count_histogram: Dictionary = {}
	var damaging_supportive_move_count_histogram: Dictionary = {}
	var max_support_examples: Array[Dictionary] = []
	var single_source_high_offense_examples: Array[Dictionary] = []

	for species_id in species_ids:
		var species: CreatureSpecies = game_data.species_catalog.get_by_id(species_id)
		if species == null:
			continue
		var moves: Array[StringName] = _probe_moves(species, catalog)
		if moves.is_empty():
			missing += 1
			continue
		eligible += 1

		var member: Dictionary = _member_probe(species, moves)
		var result: Dictionary = inference.infer_role_scores(member, catalog)
		var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
		var evidence: Dictionary = result.get("intrinsic_evidence", {}) as Dictionary
		var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
		var control_bp: int = clampi(int(capabilities.get("control_signal_bp", 0)), 0, 10000)
		var sustain_bp: int = clampi(int(capabilities.get("sustain_signal_bp", 0)), 0, 10000)
		var support_bp: int = int(scores.get("support", 0))
		var source_category: String = _support_source_category(control_bp, sustain_bp)
		support_source_counts[source_category] = int(support_source_counts.get(source_category, 0)) + 1

		var supportive_move_count: int = 0
		var control_move_count: int = 0
		var sustain_move_count: int = 0
		var damaging_supportive_move_count: int = 0
		var supportive_move_ids: Array[String] = []
		var damaging_supportive_move_ids: Array[String] = []
		for move_id in moves:
			var single_moves: Array[StringName] = [move_id]
			var single_member: Dictionary = _member_probe(species, single_moves)
			var single_evidence: Dictionary = inference.extract_intrinsic_evidence(single_member, catalog)
			var single_capabilities: Dictionary = single_evidence.get("capability_evidence", {}) as Dictionary
			var move_control_bp: int = clampi(int(single_capabilities.get("control_signal_bp", 0)), 0, 10000)
			var move_sustain_bp: int = clampi(int(single_capabilities.get("sustain_signal_bp", 0)), 0, 10000)
			if move_control_bp > 0:
				control_move_count += 1
			if move_sustain_bp > 0:
				sustain_move_count += 1
			if move_control_bp > 0 or move_sustain_bp > 0:
				supportive_move_count += 1
				supportive_move_ids.append(String(move_id))
				var move: MoveDefinition = catalog.move(move_id)
				if move != null and move.power > 0:
					damaging_supportive_move_count += 1
					damaging_supportive_move_ids.append(String(move_id))

		_increment_histogram(supportive_move_count_histogram, supportive_move_count)
		_increment_histogram(control_move_count_histogram, control_move_count)
		_increment_histogram(sustain_move_count_histogram, sustain_move_count)
		_increment_histogram(damaging_supportive_move_count_histogram, damaging_supportive_move_count)

		if support_bp > 0:
			support_positive += 1
		if support_bp >= HIGH_ROLE_BP:
			support_ge_7500 += 1
		if support_bp == 10000:
			support_eq_10000 += 1
			max_support_source_counts[source_category] = int(max_support_source_counts.get(source_category, 0)) + 1
			if supportive_move_count == 1:
				support_eq_10000_single_supportive_move += 1
				if control_move_count == 1 and sustain_move_count == 0:
					support_eq_10000_single_control_only_move += 1
				elif sustain_move_count == 1 and control_move_count == 0:
					support_eq_10000_single_sustain_only_move += 1
				if damaging_supportive_move_count == 1:
					support_eq_10000_single_supportive_damaging_move += 1
			else:
				support_eq_10000_multiple_supportive_moves += 1

		var best_offense: int = maxi(
			int(scores.get("physical_attacker", 0)),
			int(scores.get("special_attacker", 0)),
		)
		if support_bp >= HIGH_ROLE_BP and best_offense >= HIGH_ROLE_BP:
			support_ge_7500_with_high_offense += 1
		if support_bp == 10000 and best_offense >= HIGH_ROLE_BP:
			support_eq_10000_with_high_offense += 1

		var top_roles: Array[String] = _top_roles(scores, CORE_PRIMARY_ROLE_IDS)
		if top_roles.size() == 1 and top_roles[0] == "support":
			support_top_unique += 1
		elif top_roles.has("support"):
			support_top_collision += 1
			if top_roles.has("physical_attacker") or top_roles.has("special_attacker"):
				support_top_collision_with_offense += 1
			if top_roles.has("bulky_physical") or top_roles.has("bulky_special"):
				support_top_collision_with_bulk += 1

		if support_bp == 10000 and max_support_examples.size() < 12:
			max_support_examples.append({
				"species_id": String(species_id),
				"source_category": source_category,
				"control_bp": control_bp,
				"sustain_bp": sustain_bp,
				"supportive_move_count": supportive_move_count,
				"control_move_count": control_move_count,
				"sustain_move_count": sustain_move_count,
				"damaging_supportive_move_count": damaging_supportive_move_count,
				"supportive_move_ids": supportive_move_ids.duplicate(),
				"damaging_supportive_move_ids": damaging_supportive_move_ids.duplicate(),
				"scores": scores.duplicate(true),
				"probe_moves": _stringify_ids(moves),
			})

		if (
			support_bp == 10000
			and supportive_move_count == 1
			and best_offense >= HIGH_ROLE_BP
			and single_source_high_offense_examples.size() < 12
		):
			single_source_high_offense_examples.append({
				"species_id": String(species_id),
				"best_offense_bp": best_offense,
				"control_bp": control_bp,
				"sustain_bp": sustain_bp,
				"supportive_move_ids": supportive_move_ids.duplicate(),
				"damaging_supportive_move_ids": damaging_supportive_move_ids.duplicate(),
				"scores": scores.duplicate(true),
				"probe_moves": _stringify_ids(moves),
			})

	return {
		"probe_id": "support_calibration_levelup_l50_v1",
		"species_total": species_ids.size(),
		"eligible_species": eligible,
		"species_without_probe_moves": missing,
		"support_positive": support_positive,
		"support_ge_7500": support_ge_7500,
		"support_eq_10000": support_eq_10000,
		"support_source_counts": support_source_counts,
		"support_eq_10000_source_counts": max_support_source_counts,
		"supportive_move_count_histogram": supportive_move_count_histogram,
		"control_move_count_histogram": control_move_count_histogram,
		"sustain_move_count_histogram": sustain_move_count_histogram,
		"damaging_supportive_move_count_histogram": damaging_supportive_move_count_histogram,
		"support_top_unique": support_top_unique,
		"support_top_collision": support_top_collision,
		"support_top_collision_with_offense": support_top_collision_with_offense,
		"support_top_collision_with_bulk": support_top_collision_with_bulk,
		"support_ge_7500_with_high_offense": support_ge_7500_with_high_offense,
		"support_eq_10000_with_high_offense": support_eq_10000_with_high_offense,
		"support_eq_10000_single_supportive_move": support_eq_10000_single_supportive_move,
		"support_eq_10000_single_control_only_move": support_eq_10000_single_control_only_move,
		"support_eq_10000_single_sustain_only_move": support_eq_10000_single_sustain_only_move,
		"support_eq_10000_single_supportive_damaging_move": support_eq_10000_single_supportive_damaging_move,
		"support_eq_10000_multiple_supportive_moves": support_eq_10000_multiple_supportive_moves,
		"max_support_examples": max_support_examples,
		"single_source_high_offense_examples": single_source_high_offense_examples,
	}


func _support_source_category(control_bp: int, sustain_bp: int) -> String:
	if control_bp > 0 and sustain_bp > 0:
		return "control_and_sustain"
	if control_bp > 0:
		return "control_only"
	if sustain_bp > 0:
		return "sustain_only"
	return "none"


func _top_roles(scores: Dictionary, role_ids: Array) -> Array[String]:
	var top_score: int = -1
	var top_roles: Array[String] = []
	for role_id in role_ids:
		var score: int = int(scores.get(role_id, 0))
		if score > top_score:
			top_score = score
			top_roles = [String(role_id)]
		elif score == top_score:
			top_roles.append(String(role_id))
	return top_roles


func _increment_histogram(histogram: Dictionary, count: int) -> void:
	var key := String.num_int64(count)
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
		"instance_id": "support_calibration_%s" % String(species.id),
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
