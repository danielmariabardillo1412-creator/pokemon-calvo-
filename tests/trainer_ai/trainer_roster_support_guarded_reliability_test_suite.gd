class_name TrainerRosterSupportGuardedReliabilityTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const HIGH_ROLE_BP := 7500
const VERY_HIGH_ROLE_BP := 9000
const SUSTAIN_CORROBORATION_BP := 5000
const UNCONFIRMED_SPECIALIST_CAP_BP := 9500
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
	_check.call("support_guarded_reliability_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	_check.call("support_guarded_reliability_species_count_canonical", species_ids.size() == 1025)

	var report_a: Dictionary = _build_report(game_data, catalog, species_ids)
	var report_b: Dictionary = _build_report(game_data, catalog, species_ids)
	var baseline: Dictionary = report_a.get("reliability_max", {}) as Dictionary
	var guarded: Dictionary = report_a.get("guarded_reliability", {}) as Dictionary
	var sentinels: Dictionary = report_a.get("sentinels", {}) as Dictionary

	_check.call("support_guarded_reliability_eligible_species_canonical", int(report_a.get("eligible_species", 0)) == 1021)
	_check.call("support_guarded_reliability_accounts_for_all_species", int(report_a.get("eligible_species", 0)) + int(report_a.get("species_without_probe_moves", 0)) == species_ids.size())
	_check.call("support_guarded_reliability_baseline_high", int(baseline.get("support_ge_7500", -1)) == 414)
	_check.call("support_guarded_reliability_baseline_ceiling", int(baseline.get("support_eq_10000", -1)) == 240)
	_check.call("support_guarded_reliability_sentinels_present", sentinels.size() == SENTINEL_IDS.size())
	_check.call("support_guarded_reliability_report_deterministic", report_a == report_b)
	_check.call("support_guarded_reliability_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call("support_guarded_reliability_range", int(guarded.get("support_min", -1)) >= 0 and int(guarded.get("support_max", -1)) <= 10000)

	_run_formula_invariants()

	print("\n=== TRAINER SUPPORT GUARDED RELIABILITY ===")
	print(JSON.stringify(report_a))


func _run_formula_invariants() -> void:
	var zero: Dictionary = _synthetic_capabilities(0, 0, 0, 0, 0, 0)
	var sustain_only: Dictionary = zero.duplicate(true)
	sustain_only["sustain_signal_bp"] = 5000
	var unconfirmed_perfect: Dictionary = _synthetic_capabilities(10000, 0, 1, 0, 1, 0)
	var unconfirmed_near: Dictionary = _synthetic_capabilities(9500, 0, 1, 0, 1, 0)
	var dedicated_single: Dictionary = _synthetic_capabilities(10000, 0, 1, 1, 0, 0)
	var corroborated_routes: Dictionary = _synthetic_capabilities(9500, 8500, 2, 1, 1, 0)
	var corroborated_sustain: Dictionary = _synthetic_capabilities(9500, 0, 1, 1, 0, 5000)
	var weak_breadth: Dictionary = _synthetic_capabilities(5000, 3000, 4, 0, 4, 0)
	var below_cap: Dictionary = _synthetic_capabilities(8500, 0, 1, 1, 0, 0)

	_check.call("support_guarded_reliability_fail_closed_zero", _guarded_support(zero) == 0)
	_check.call("support_guarded_reliability_sustain_only_preserved", _guarded_support(sustain_only) == 5000)
	_check.call("support_guarded_reliability_unconfirmed_perfect_capped", _guarded_support(unconfirmed_perfect) == UNCONFIRMED_SPECIALIST_CAP_BP)
	_check.call("support_guarded_reliability_unconfirmed_near_preserved", _guarded_support(unconfirmed_near) == UNCONFIRMED_SPECIALIST_CAP_BP)
	_check.call("support_guarded_reliability_single_dedicated_not_auto_ceiling", _guarded_support(dedicated_single) == UNCONFIRMED_SPECIALIST_CAP_BP)
	_check.call("support_guarded_reliability_second_reliable_route_confirms_ceiling", _guarded_support(corroborated_routes) == 10000)
	_check.call("support_guarded_reliability_sustain_confirms_dedicated_route", _guarded_support(corroborated_sustain) == 10000)
	_check.call("support_guarded_reliability_weak_breadth_does_not_inflate", _guarded_support(weak_breadth) == 5000)
	_check.call("support_guarded_reliability_below_cap_preserved", _guarded_support(below_cap) == 8500)


func _build_report(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var inference := TrainerRosterRoleInference.new()
	var eligible: int = 0
	var missing: int = 0
	var baseline_summary: Dictionary = _empty_summary()
	var guarded_summary: Dictionary = _empty_summary()
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

		var reliability_bp: int = maxi(
			clampi(int(capabilities.get("control_reliability_bp", 0)), 0, 10000),
			clampi(int(capabilities.get("sustain_signal_bp", 0)), 0, 10000),
		)
		var guarded_bp: int = _guarded_support(capabilities)
		_accumulate_summary(baseline_summary, reliability_bp, production_scores, capabilities, best_offense)
		_accumulate_summary(guarded_summary, guarded_bp, production_scores, capabilities, best_offense)

		var species_key := String(species_id)
		if SENTINEL_IDS.has(species_key):
			sentinels[species_key] = {
				"probe_moves": _stringify_ids(moves),
				"best_offense_bp": best_offense,
				"production_support_bp": int(production_scores.get("support", 0)),
				"reliability_max_bp": reliability_bp,
				"guarded_reliability_bp": guarded_bp,
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

	_finalize_summary(baseline_summary, eligible)
	_finalize_summary(guarded_summary, eligible)
	return {
		"probe_id": "support_guarded_reliability_levelup_l50_v1",
		"species_total": species_ids.size(),
		"eligible_species": eligible,
		"species_without_probe_moves": missing,
		"reliability_max": baseline_summary,
		"guarded_reliability": guarded_summary,
		"sentinels": sentinels,
	}


func _empty_summary() -> Dictionary:
	return {
		"support_sum": 0,
		"support_min": 10001,
		"support_max": -1,
		"support_positive": 0,
		"support_ge_7500": 0,
		"support_ge_9000": 0,
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
		"eq_10000_single_control": 0,
		"eq_10000_single_damaging_control": 0,
		"eq_10000_single_dedicated_control": 0,
		"eq_10000_multi_control": 0,
		"eq_10000_with_sustain": 0,
	}


func _accumulate_summary(
	summary: Dictionary,
	support_bp: int,
	production_scores: Dictionary,
	capabilities: Dictionary,
	best_offense: int,
) -> void:
	summary["support_sum"] = int(summary.get("support_sum", 0)) + support_bp
	summary["support_min"] = mini(int(summary.get("support_min", 10001)), support_bp)
	summary["support_max"] = maxi(int(summary.get("support_max", -1)), support_bp)
	if support_bp > 0:
		summary["support_positive"] = int(summary.get("support_positive", 0)) + 1
	if support_bp >= HIGH_ROLE_BP:
		summary["support_ge_7500"] = int(summary.get("support_ge_7500", 0)) + 1
		if best_offense >= HIGH_ROLE_BP:
			summary["support_ge_7500_with_high_offense"] = int(summary.get("support_ge_7500_with_high_offense", 0)) + 1
	if support_bp >= VERY_HIGH_ROLE_BP:
		summary["support_ge_9000"] = int(summary.get("support_ge_9000", 0)) + 1
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
	if support_bp == 10000:
		if move_count == 1:
			summary["eq_10000_single_control"] = int(summary.get("eq_10000_single_control", 0)) + 1
			if dedicated_count == 0 and damaging_count == 1:
				summary["eq_10000_single_damaging_control"] = int(summary.get("eq_10000_single_damaging_control", 0)) + 1
			if dedicated_count == 1:
				summary["eq_10000_single_dedicated_control"] = int(summary.get("eq_10000_single_dedicated_control", 0)) + 1
		elif move_count >= 2:
			summary["eq_10000_multi_control"] = int(summary.get("eq_10000_multi_control", 0)) + 1
		if sustain > 0:
			summary["eq_10000_with_sustain"] = int(summary.get("eq_10000_with_sustain", 0)) + 1


func _finalize_summary(summary: Dictionary, eligible: int) -> void:
	var total_support: int = int(summary.get("support_sum", 0))
	summary["mean_support_bp"] = total_support / eligible if eligible > 0 else 0
	summary.erase("support_sum")


func _guarded_support(capabilities: Dictionary) -> int:
	var reliability: int = clampi(int(capabilities.get("control_reliability_bp", 0)), 0, 10000)
	var secondary: int = clampi(int(capabilities.get("control_secondary_reliability_bp", 0)), 0, 10000)
	var dedicated_count: int = maxi(0, int(capabilities.get("control_dedicated_move_count", 0)))
	var sustain: int = clampi(int(capabilities.get("sustain_signal_bp", 0)), 0, 10000)

	if sustain >= 10000:
		return 10000

	var route_confirmed: bool = reliability >= VERY_HIGH_ROLE_BP and secondary >= HIGH_ROLE_BP
	var sustain_confirmed: bool = (
		reliability >= VERY_HIGH_ROLE_BP
		and sustain >= SUSTAIN_CORROBORATION_BP
		and dedicated_count > 0
	)
	if route_confirmed or sustain_confirmed:
		return 10000

	return mini(maxi(reliability, sustain), UNCONFIRMED_SPECIALIST_CAP_BP)


func _synthetic_capabilities(
	reliability: int,
	secondary: int,
	move_count: int,
	dedicated_count: int,
	damaging_count: int,
	sustain: int,
) -> Dictionary:
	return {
		"control_reliability_bp": reliability,
		"control_secondary_reliability_bp": secondary,
		"control_move_count": move_count,
		"control_effect_key_count": move_count,
		"control_effect_family_count": mini(move_count, 2),
		"control_dedicated_move_count": dedicated_count,
		"control_damaging_move_count": damaging_count,
		"control_strongest_stat_drop_stages": 0,
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
		"instance_id": "support_guarded_reliability_%s" % String(species.id),
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
