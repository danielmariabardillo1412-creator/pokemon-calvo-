class_name TrainerRosterSupportFormulaComparisonTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const HIGH_ROLE_BP := 7500
const CANDIDATE_IDS := [
	"legacy",
	"reliability_max",
	"balanced_evidence",
	"portfolio_evidence",
]
const CORE_PRIMARY_ROLE_IDS := [
	"physical_attacker",
	"special_attacker",
	"bulky_physical",
	"bulky_special",
	"support",
]
const SENTINEL_IDS := [
	"abomasnow",
	"aerodactyl",
	"alcremie",
	"amoonguss",
	"ampharos",
	"annihilape",
	"arcanine",
	"archaludon",
	"araquanid",
	"bellibolt",
]

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("support_formula_comparison_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	_check.call("support_formula_comparison_species_count_canonical", species_ids.size() == 1025)

	var report_a: Dictionary = _build_report(game_data, catalog, species_ids)
	var report_b: Dictionary = _build_report(game_data, catalog, species_ids)
	var candidates: Dictionary = report_a.get("candidates", {}) as Dictionary
	var legacy: Dictionary = candidates.get("legacy", {}) as Dictionary
	var sentinels: Dictionary = report_a.get("sentinels", {}) as Dictionary

	_check.call("support_formula_comparison_eligible_species_canonical", int(report_a.get("eligible_species", 0)) == 1021)
	_check.call("support_formula_comparison_accounts_for_all_species", int(report_a.get("eligible_species", 0)) + int(report_a.get("species_without_probe_moves", 0)) == species_ids.size())
	_check.call("support_formula_comparison_has_four_candidates", candidates.size() == CANDIDATE_IDS.size())
	_check.call("support_formula_comparison_legacy_matches_current_ceiling", int(legacy.get("support_eq_10000", -1)) == 441)
	_check.call("support_formula_comparison_legacy_matches_current_high_support", int(legacy.get("support_ge_7500", -1)) == 444)
	_check.call("support_formula_comparison_sentinels_present", sentinels.size() == SENTINEL_IDS.size())
	_check.call("support_formula_comparison_report_deterministic", report_a == report_b)
	_check.call("support_formula_comparison_report_json_serializable", not JSON.stringify(report_a).is_empty())

	_run_formula_invariants()

	print("\n=== TRAINER SUPPORT FORMULA COMPARISON ===")
	print(JSON.stringify(report_a))


func _run_formula_invariants() -> void:
	var weak: Dictionary = _synthetic_capabilities(3000, 3000, 0, 1, 1, 1, 0, 1, 0, 0)
	var reliable: Dictionary = _synthetic_capabilities(10000, 9000, 0, 1, 1, 1, 1, 0, 0, 0)
	var redundant: Dictionary = _synthetic_capabilities(10000, 9000, 8500, 2, 2, 1, 2, 0, 1, 0)
	var broad: Dictionary = _synthetic_capabilities(10000, 9000, 8500, 3, 3, 2, 3, 0, 2, 0)
	var sustained: Dictionary = broad.duplicate(true)
	sustained["sustain_signal_bp"] = 5000
	var zero: Dictionary = _synthetic_capabilities(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	for candidate_id in CANDIDATE_IDS:
		var id := String(candidate_id)
		if id == "legacy":
			continue
		var weak_score: int = _candidate_support(id, weak)
		var reliable_score: int = _candidate_support(id, reliable)
		var redundant_score: int = _candidate_support(id, redundant)
		var broad_score: int = _candidate_support(id, broad)
		var sustained_score: int = _candidate_support(id, sustained)
		_check.call("support_formula_%s_range" % id, weak_score >= 0 and sustained_score <= 10000)
		_check.call("support_formula_%s_reliability_monotonic" % id, reliable_score >= weak_score)
		_check.call("support_formula_%s_redundancy_monotonic" % id, redundant_score >= reliable_score)
		_check.call("support_formula_%s_breadth_monotonic" % id, broad_score >= redundant_score)
		_check.call("support_formula_%s_sustain_monotonic" % id, sustained_score >= broad_score)
		_check.call("support_formula_%s_fail_closed_zero" % id, _candidate_support(id, zero) == 0)

	var damaging_only: Dictionary = _synthetic_capabilities(10000, 9000, 0, 1, 1, 1, 0, 1, 1, 0)
	var dedicated: Dictionary = damaging_only.duplicate(true)
	dedicated["control_dedicated_move_count"] = 1
	dedicated["control_damaging_move_count"] = 0
	_check.call("support_formula_balanced_values_dedicated_source", _candidate_support("balanced_evidence", dedicated) >= _candidate_support("balanced_evidence", damaging_only))
	_check.call("support_formula_portfolio_values_dedicated_source", _candidate_support("portfolio_evidence", dedicated) >= _candidate_support("portfolio_evidence", damaging_only))


func _build_report(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var inference := TrainerRosterRoleInference.new()
	var eligible: int = 0
	var missing: int = 0
	var candidate_summaries: Dictionary = {}
	for candidate_id in CANDIDATE_IDS:
		candidate_summaries[String(candidate_id)] = _empty_candidate_summary()
	var sentinels: Dictionary = {}

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
		var production_scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
		var evidence: Dictionary = result.get("intrinsic_evidence", {}) as Dictionary
		var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
		var best_offense: int = maxi(
			int(production_scores.get("physical_attacker", 0)),
			int(production_scores.get("special_attacker", 0)),
		)
		var best_bulk: int = maxi(
			int(production_scores.get("bulky_physical", 0)),
			int(production_scores.get("bulky_special", 0)),
		)

		var candidate_scores: Dictionary = {}
		for candidate_id in CANDIDATE_IDS:
			var id := String(candidate_id)
			var support_bp: int = _candidate_support(id, capabilities)
			candidate_scores[id] = support_bp
			var summary: Dictionary = candidate_summaries.get(id, {}) as Dictionary
			_accumulate_candidate_summary(summary, support_bp, production_scores, capabilities, best_offense, best_bulk)

		var species_key := String(species_id)
		if SENTINEL_IDS.has(species_key):
			sentinels[species_key] = {
				"probe_moves": _stringify_ids(moves),
				"best_offense_bp": best_offense,
				"best_bulk_bp": best_bulk,
				"production_support_bp": int(production_scores.get("support", 0)),
				"candidate_support_bp": candidate_scores,
				"control_signal_bp": int(capabilities.get("control_signal_bp", 0)),
				"control_best_runtime_effect_bp": int(capabilities.get("control_best_runtime_effect_bp", 0)),
				"control_reliability_bp": int(capabilities.get("control_reliability_bp", 0)),
				"control_secondary_reliability_bp": int(capabilities.get("control_secondary_reliability_bp", 0)),
				"control_move_count": int(capabilities.get("control_move_count", 0)),
				"control_effect_key_count": int(capabilities.get("control_effect_key_count", 0)),
				"control_effect_family_count": int(capabilities.get("control_effect_family_count", 0)),
				"control_dedicated_move_count": int(capabilities.get("control_dedicated_move_count", 0)),
				"control_damaging_move_count": int(capabilities.get("control_damaging_move_count", 0)),
				"control_strongest_stat_drop_stages": int(capabilities.get("control_strongest_stat_drop_stages", 0)),
				"sustain_signal_bp": int(capabilities.get("sustain_signal_bp", 0)),
			}

	for candidate_id in CANDIDATE_IDS:
		var id := String(candidate_id)
		var summary: Dictionary = candidate_summaries.get(id, {}) as Dictionary
		var total_support: int = int(summary.get("support_sum", 0))
		summary["mean_support_bp"] = total_support / eligible if eligible > 0 else 0
		summary.erase("support_sum")

	return {
		"probe_id": "support_formula_comparison_levelup_l50_v1",
		"species_total": species_ids.size(),
		"eligible_species": eligible,
		"species_without_probe_moves": missing,
		"candidates": candidate_summaries,
		"sentinels": sentinels,
	}


func _empty_candidate_summary() -> Dictionary:
	return {
		"support_sum": 0,
		"support_positive": 0,
		"support_ge_7500": 0,
		"support_eq_10000": 0,
		"support_top_unique": 0,
		"support_top_collision": 0,
		"support_top_collision_with_offense": 0,
		"support_top_collision_with_bulk": 0,
		"support_ge_7500_with_high_offense": 0,
		"support_eq_10000_with_high_offense": 0,
		"single_control_only_ge_7500": 0,
		"single_damaging_control_only_ge_7500": 0,
		"single_dedicated_reliable_control_ge_7500": 0,
	}


func _accumulate_candidate_summary(
	summary: Dictionary,
	support_bp: int,
	production_scores: Dictionary,
	capabilities: Dictionary,
	best_offense: int,
	best_bulk: int,
) -> void:
	summary["support_sum"] = int(summary.get("support_sum", 0)) + support_bp
	if support_bp > 0:
		summary["support_positive"] = int(summary.get("support_positive", 0)) + 1
	if support_bp >= HIGH_ROLE_BP:
		summary["support_ge_7500"] = int(summary.get("support_ge_7500", 0)) + 1
		if best_offense >= HIGH_ROLE_BP:
			summary["support_ge_7500_with_high_offense"] = int(summary.get("support_ge_7500_with_high_offense", 0)) + 1
	if support_bp == 10000:
		summary["support_eq_10000"] = int(summary.get("support_eq_10000", 0)) + 1
		if best_offense >= HIGH_ROLE_BP:
			summary["support_eq_10000_with_high_offense"] = int(summary.get("support_eq_10000_with_high_offense", 0)) + 1

	var candidate_scores: Dictionary = production_scores.duplicate(true)
	candidate_scores["support"] = support_bp
	var top_roles: Array[String] = _top_roles(candidate_scores, CORE_PRIMARY_ROLE_IDS)
	if top_roles.size() == 1 and top_roles[0] == "support":
		summary["support_top_unique"] = int(summary.get("support_top_unique", 0)) + 1
	elif top_roles.has("support"):
		summary["support_top_collision"] = int(summary.get("support_top_collision", 0)) + 1
		if top_roles.has("physical_attacker") or top_roles.has("special_attacker"):
			summary["support_top_collision_with_offense"] = int(summary.get("support_top_collision_with_offense", 0)) + 1
		if top_roles.has("bulky_physical") or top_roles.has("bulky_special"):
			summary["support_top_collision_with_bulk"] = int(summary.get("support_top_collision_with_bulk", 0)) + 1

	var move_count: int = int(capabilities.get("control_move_count", 0))
	var dedicated_count: int = int(capabilities.get("control_dedicated_move_count", 0))
	var damaging_count: int = int(capabilities.get("control_damaging_move_count", 0))
	var reliability: int = int(capabilities.get("control_reliability_bp", 0))
	var sustain: int = int(capabilities.get("sustain_signal_bp", 0))
	if support_bp >= HIGH_ROLE_BP and move_count == 1 and sustain == 0:
		summary["single_control_only_ge_7500"] = int(summary.get("single_control_only_ge_7500", 0)) + 1
		if dedicated_count == 0 and damaging_count == 1:
			summary["single_damaging_control_only_ge_7500"] = int(summary.get("single_damaging_control_only_ge_7500", 0)) + 1
		if dedicated_count == 1 and reliability >= HIGH_ROLE_BP:
			summary["single_dedicated_reliable_control_ge_7500"] = int(summary.get("single_dedicated_reliable_control_ge_7500", 0)) + 1

	# best_bulk is deliberately kept in the signature: collision counts above inspect the
	# exact top-role set, while this makes future audit extensions explicit without
	# recomputing production scores.
	if best_bulk < 0:
		push_error("unreachable negative bulk affinity")


func _candidate_support(candidate_id: String, capabilities: Dictionary) -> int:
	var legacy_control: int = clampi(int(capabilities.get("control_signal_bp", 0)), 0, 10000)
	var sustain: int = clampi(int(capabilities.get("sustain_signal_bp", 0)), 0, 10000)
	if candidate_id == "legacy":
		return maxi(legacy_control, sustain)

	var reliability: int = clampi(int(capabilities.get("control_reliability_bp", 0)), 0, 10000)
	if candidate_id == "reliability_max":
		return maxi(reliability, sustain)

	var control_score: int = _composite_control_score(capabilities, candidate_id == "portfolio_evidence")
	if candidate_id == "balanced_evidence":
		return maxi(control_score, sustain)
	if candidate_id == "portfolio_evidence":
		var primary: int = maxi(control_score, sustain)
		var secondary: int = mini(control_score, sustain)
		return clampi(primary + secondary / 5, 0, 10000)
	return 0


func _composite_control_score(capabilities: Dictionary, portfolio: bool) -> int:
	var move_count: int = maxi(0, int(capabilities.get("control_move_count", 0)))
	if move_count <= 0:
		return 0
	var runtime_effect: int = clampi(int(capabilities.get("control_best_runtime_effect_bp", 0)), 0, 10000)
	var reliability: int = clampi(int(capabilities.get("control_reliability_bp", 0)), 0, 10000)
	var secondary: int = clampi(int(capabilities.get("control_secondary_reliability_bp", 0)), 0, 10000)
	var effect_count: int = maxi(0, int(capabilities.get("control_effect_key_count", 0)))
	var family_count: int = maxi(0, int(capabilities.get("control_effect_family_count", 0)))
	var dedicated_count: int = maxi(0, int(capabilities.get("control_dedicated_move_count", 0)))
	var strongest_drop: int = maxi(0, int(capabilities.get("control_strongest_stat_drop_stages", 0)))

	var move_breadth: int = _breadth_bp(move_count)
	var effect_breadth: int = _breadth_bp(effect_count)
	var family_breadth: int = _breadth_bp(family_count)
	var dedicated_ratio: int = clampi(dedicated_count * 10000 / move_count, 0, 10000)
	var stage_intensity: int = clampi(mini(strongest_drop, 2) * 5000, 0, 10000)

	var reliability_weight: int = 55 if portfolio else 65
	var secondary_weight: int = 15 if portfolio else 5
	var weighted: int = (
		reliability * reliability_weight
		+ runtime_effect * 10
		+ secondary * secondary_weight
		+ move_breadth * 5
		+ effect_breadth * 5
		+ family_breadth * 3
		+ dedicated_ratio * 4
		+ stage_intensity * 3
	)
	return clampi(weighted / 100, 0, 10000)


func _breadth_bp(count: int) -> int:
	if count <= 0:
		return 0
	if count == 1:
		return 5000
	if count == 2:
		return 7500
	return 10000


func _synthetic_capabilities(
	runtime_effect: int,
	reliability: int,
	secondary: int,
	move_count: int,
	effect_count: int,
	family_count: int,
	dedicated_count: int,
	damaging_count: int,
	strongest_drop: int,
	sustain: int,
) -> Dictionary:
	return {
		"control_signal_bp": reliability,
		"control_best_runtime_effect_bp": runtime_effect,
		"control_reliability_bp": reliability,
		"control_secondary_reliability_bp": secondary,
		"control_move_count": move_count,
		"control_effect_key_count": effect_count,
		"control_effect_family_count": family_count,
		"control_dedicated_move_count": dedicated_count,
		"control_damaging_move_count": damaging_count,
		"control_strongest_stat_drop_stages": strongest_drop,
		"sustain_signal_bp": sustain,
	}


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
		"instance_id": "support_formula_comparison_%s" % String(species.id),
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
