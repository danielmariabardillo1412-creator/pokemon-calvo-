class_name TrainerRosterControlProbabilityAuditTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const HIGH_ROLE_BP := 7500

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("control_probability_audit_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	_check.call("control_probability_audit_species_count_canonical", species_ids.size() == 1025)

	var report_a: Dictionary = _build_report(game_data, catalog, species_ids)
	var report_b: Dictionary = _build_report(game_data, catalog, species_ids)
	var eligible: int = int(report_a.get("eligible_species", 0))
	var missing: int = int(report_a.get("species_without_probe_moves", 0))
	var sentinels: Dictionary = report_a.get("sentinels", {}) as Dictionary

	_check.call("control_probability_audit_accounts_for_all_species", eligible + missing == species_ids.size())
	_check.call("control_probability_audit_matches_current_inference", int(report_a.get("production_signal_mismatch_species", -1)) == 0)
	_check.call("control_probability_audit_finds_double_encoded_paths", int(report_a.get("species_with_double_encoded_control_path", 0)) > 0)
	_check.call("control_probability_audit_finds_accuracy_reductions", int(report_a.get("species_reduced_by_base_accuracy", 0)) > 0)
	_check.call("control_probability_audit_report_deterministic", report_a == report_b)
	_check.call("control_probability_audit_report_json_serializable", not JSON.stringify(report_a).is_empty())

	var moonblast: Dictionary = sentinels.get("moonblast", {}) as Dictionary
	var rock_slide: Dictionary = sentinels.get("rock_slide", {}) as Dictionary
	var screech: Dictionary = sentinels.get("screech", {}) as Dictionary
	var dynamic_punch: Dictionary = sentinels.get("dynamic_punch", {}) as Dictionary
	_check.call(
		"control_probability_audit_moonblast_metadata_double_counts_chance",
		int(moonblast.get("production_control_bp", 0)) > 0
		and int(moonblast.get("runtime_effect_control_bp", 0)) > int(moonblast.get("production_control_bp", 0)),
	)
	_check.call(
		"control_probability_audit_rock_slide_wrapper_matches_runtime_chance",
		int(rock_slide.get("production_control_bp", -1)) == int(rock_slide.get("runtime_effect_control_bp", -2))
		and int(rock_slide.get("runtime_effect_control_bp", 0)) > 0
		and int(rock_slide.get("runtime_effect_control_bp", 0)) < 10000,
	)
	_check.call(
		"control_probability_audit_screech_base_accuracy_reduces_control",
		int(screech.get("base_accuracy_weighted_control_bp", 0)) > 0
		and int(screech.get("base_accuracy_weighted_control_bp", 0)) < int(screech.get("runtime_effect_control_bp", 0)),
	)
	_check.call(
		"control_probability_audit_dynamic_punch_base_accuracy_reduces_control",
		int(dynamic_punch.get("base_accuracy_weighted_control_bp", 0)) > 0
		and int(dynamic_punch.get("base_accuracy_weighted_control_bp", 0)) < int(dynamic_punch.get("runtime_effect_control_bp", 0)),
	)

	print("\n=== TRAINER CONTROL PROBABILITY AUDIT ===")
	print(JSON.stringify(report_a))


func _build_report(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var inference := TrainerRosterRoleInference.new()
	var eligible: int = 0
	var missing: int = 0
	var production_signal_mismatch_species: int = 0
	var production_lt_runtime_effect: int = 0
	var production_eq_runtime_effect: int = 0
	var production_gt_runtime_effect: int = 0
	var species_reduced_by_base_accuracy: int = 0
	var species_with_double_encoded_control_path: int = 0
	var species_with_direct_nonchance_probability_metadata: int = 0
	var current_control_eq_10000: int = 0
	var runtime_effect_control_eq_10000: int = 0
	var base_accuracy_control_eq_10000: int = 0
	var current_control_ge_7500: int = 0
	var runtime_effect_control_ge_7500: int = 0
	var base_accuracy_control_ge_7500: int = 0
	var support_eq_10000_reduced_below_10000_by_accuracy: int = 0
	var support_ge_7500_drops_below_7500_by_accuracy: int = 0
	var control_move_count_histogram: Dictionary = {}
	var deterministic_effect_move_count_histogram: Dictionary = {}
	var high_accuracy_control_move_count_histogram: Dictionary = {}
	var dedicated_control_move_count_histogram: Dictionary = {}
	var damaging_control_move_count_histogram: Dictionary = {}
	var production_vs_runtime_examples: Array[Dictionary] = []
	var accuracy_reduction_examples: Array[Dictionary] = []
	var single_high_control_route_examples: Array[Dictionary] = []

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
		var evidence: Dictionary = result.get("intrinsic_evidence", {}) as Dictionary
		var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
		var scores: Dictionary = result.get("role_scores_bp", {}) as Dictionary
		var production_control_bp: int = clampi(int(capabilities.get("control_signal_bp", 0)), 0, 10000)
		var sustain_bp: int = clampi(int(capabilities.get("sustain_signal_bp", 0)), 0, 10000)
		var support_bp: int = clampi(int(scores.get("support", 0)), 0, 10000)

		var recomputed_production_bp: int = 0
		var runtime_effect_control_bp: int = 0
		var base_accuracy_control_bp: int = 0
		var control_move_count: int = 0
		var deterministic_effect_move_count: int = 0
		var high_accuracy_control_move_count: int = 0
		var dedicated_control_move_count: int = 0
		var damaging_control_move_count: int = 0
		var double_encoded: bool = false
		var direct_nonchance_probability_metadata: bool = false
		var high_accuracy_control_move_ids: Array[String] = []

		for move_id in moves:
			var move: MoveDefinition = catalog.move(move_id)
			if move == null:
				continue
			var move_audit: Dictionary = _audit_move(move)
			var move_production_bp: int = int(move_audit.get("production_control_bp", 0))
			var move_runtime_bp: int = int(move_audit.get("runtime_effect_control_bp", 0))
			var move_accuracy_bp: int = int(move_audit.get("base_accuracy_weighted_control_bp", 0))
			recomputed_production_bp = maxi(recomputed_production_bp, move_production_bp)
			runtime_effect_control_bp = maxi(runtime_effect_control_bp, move_runtime_bp)
			base_accuracy_control_bp = maxi(base_accuracy_control_bp, move_accuracy_bp)
			if move_runtime_bp > 0:
				control_move_count += 1
				if move_runtime_bp == 10000:
					deterministic_effect_move_count += 1
				if move_accuracy_bp >= HIGH_ROLE_BP:
					high_accuracy_control_move_count += 1
					high_accuracy_control_move_ids.append(String(move_id))
				if move.power > 0:
					damaging_control_move_count += 1
				else:
					dedicated_control_move_count += 1
			double_encoded = double_encoded or bool(move_audit.get("has_double_encoded_control_path", false))
			direct_nonchance_probability_metadata = (
				direct_nonchance_probability_metadata
				or bool(move_audit.get("has_direct_nonchance_probability_metadata", false))
			)

		if production_control_bp != recomputed_production_bp:
			production_signal_mismatch_species += 1
		if production_control_bp < runtime_effect_control_bp:
			production_lt_runtime_effect += 1
			if production_vs_runtime_examples.size() < 12:
				production_vs_runtime_examples.append({
					"species_id": String(species_id),
					"production_control_bp": production_control_bp,
					"runtime_effect_control_bp": runtime_effect_control_bp,
					"base_accuracy_control_bp": base_accuracy_control_bp,
					"probe_moves": _stringify_ids(moves),
				})
		elif production_control_bp > runtime_effect_control_bp:
			production_gt_runtime_effect += 1
		else:
			production_eq_runtime_effect += 1

		if base_accuracy_control_bp < runtime_effect_control_bp:
			species_reduced_by_base_accuracy += 1
			if accuracy_reduction_examples.size() < 12:
				accuracy_reduction_examples.append({
					"species_id": String(species_id),
					"production_control_bp": production_control_bp,
					"runtime_effect_control_bp": runtime_effect_control_bp,
					"base_accuracy_control_bp": base_accuracy_control_bp,
					"support_bp": support_bp,
					"probe_moves": _stringify_ids(moves),
				})
		if double_encoded:
			species_with_double_encoded_control_path += 1
		if direct_nonchance_probability_metadata:
			species_with_direct_nonchance_probability_metadata += 1

		if production_control_bp == 10000:
			current_control_eq_10000 += 1
		if runtime_effect_control_bp == 10000:
			runtime_effect_control_eq_10000 += 1
		if base_accuracy_control_bp == 10000:
			base_accuracy_control_eq_10000 += 1
		if production_control_bp >= HIGH_ROLE_BP:
			current_control_ge_7500 += 1
		if runtime_effect_control_bp >= HIGH_ROLE_BP:
			runtime_effect_control_ge_7500 += 1
		if base_accuracy_control_bp >= HIGH_ROLE_BP:
			base_accuracy_control_ge_7500 += 1

		var accuracy_support_proxy: int = maxi(base_accuracy_control_bp, sustain_bp)
		if support_bp == 10000 and accuracy_support_proxy < 10000:
			support_eq_10000_reduced_below_10000_by_accuracy += 1
		if support_bp >= HIGH_ROLE_BP and accuracy_support_proxy < HIGH_ROLE_BP:
			support_ge_7500_drops_below_7500_by_accuracy += 1

		_increment_histogram(control_move_count_histogram, control_move_count)
		_increment_histogram(deterministic_effect_move_count_histogram, deterministic_effect_move_count)
		_increment_histogram(high_accuracy_control_move_count_histogram, high_accuracy_control_move_count)
		_increment_histogram(dedicated_control_move_count_histogram, dedicated_control_move_count)
		_increment_histogram(damaging_control_move_count_histogram, damaging_control_move_count)

		if high_accuracy_control_move_count == 1 and single_high_control_route_examples.size() < 12:
			single_high_control_route_examples.append({
				"species_id": String(species_id),
				"production_control_bp": production_control_bp,
				"runtime_effect_control_bp": runtime_effect_control_bp,
				"base_accuracy_control_bp": base_accuracy_control_bp,
				"high_accuracy_control_move_ids": high_accuracy_control_move_ids.duplicate(),
				"probe_moves": _stringify_ids(moves),
			})

	return {
		"probe_id": "control_probability_accuracy_levelup_l50_v1",
		"species_total": species_ids.size(),
		"eligible_species": eligible,
		"species_without_probe_moves": missing,
		"production_signal_mismatch_species": production_signal_mismatch_species,
		"production_lt_runtime_effect": production_lt_runtime_effect,
		"production_eq_runtime_effect": production_eq_runtime_effect,
		"production_gt_runtime_effect": production_gt_runtime_effect,
		"species_reduced_by_base_accuracy": species_reduced_by_base_accuracy,
		"species_with_double_encoded_control_path": species_with_double_encoded_control_path,
		"species_with_direct_nonchance_probability_metadata": species_with_direct_nonchance_probability_metadata,
		"current_control_eq_10000": current_control_eq_10000,
		"runtime_effect_control_eq_10000": runtime_effect_control_eq_10000,
		"base_accuracy_control_eq_10000": base_accuracy_control_eq_10000,
		"current_control_ge_7500": current_control_ge_7500,
		"runtime_effect_control_ge_7500": runtime_effect_control_ge_7500,
		"base_accuracy_control_ge_7500": base_accuracy_control_ge_7500,
		"support_eq_10000_reduced_below_10000_by_accuracy": support_eq_10000_reduced_below_10000_by_accuracy,
		"support_ge_7500_drops_below_7500_by_accuracy": support_ge_7500_drops_below_7500_by_accuracy,
		"control_move_count_histogram": control_move_count_histogram,
		"deterministic_effect_move_count_histogram": deterministic_effect_move_count_histogram,
		"high_accuracy_control_move_count_histogram": high_accuracy_control_move_count_histogram,
		"dedicated_control_move_count_histogram": dedicated_control_move_count_histogram,
		"damaging_control_move_count_histogram": damaging_control_move_count_histogram,
		"production_vs_runtime_examples": production_vs_runtime_examples,
		"accuracy_reduction_examples": accuracy_reduction_examples,
		"single_high_control_route_examples": single_high_control_route_examples,
		"sentinels": _sentinel_report(catalog, inference),
	}


func _audit_move(move: MoveDefinition) -> Dictionary:
	var production_bp: int = 0
	var runtime_bp: int = 0
	var has_double_encoded: bool = false
	var has_direct_nonchance_probability_metadata: bool = false
	for spec in move.effect_specs:
		production_bp = maxi(production_bp, _metadata_control_bp(spec, 10000))
		runtime_bp = maxi(runtime_bp, _runtime_control_bp(spec, 10000))
		has_double_encoded = has_double_encoded or _has_double_encoded_control_path(spec, false)
		has_direct_nonchance_probability_metadata = (
			has_direct_nonchance_probability_metadata
			or _has_direct_nonchance_probability_metadata(spec, false)
		)
	var accuracy_bp: int = _base_accuracy_bp(move)
	return {
		"production_control_bp": production_bp,
		"runtime_effect_control_bp": runtime_bp,
		"base_accuracy_bp": accuracy_bp,
		"base_accuracy_weighted_control_bp": runtime_bp * accuracy_bp / 10000,
		"has_double_encoded_control_path": has_double_encoded,
		"has_direct_nonchance_probability_metadata": has_direct_nonchance_probability_metadata,
	}


func _metadata_control_bp(spec: BattleEffectSpec, inherited_bp: int) -> int:
	if spec == null:
		return 0
	var effective_bp: int = inherited_bp * clampi(spec.chance_basis_points, 0, 10000) / 10000
	var control_bp: int = effective_bp if _is_control_leaf(spec) else 0
	for child in spec.children:
		control_bp = maxi(control_bp, _metadata_control_bp(child, effective_bp))
	return control_bp


func _runtime_control_bp(spec: BattleEffectSpec, inherited_bp: int) -> int:
	if spec == null:
		return 0
	var effective_bp: int = inherited_bp
	if spec.kind == BattleEffectSpec.CHANCE:
		effective_bp = inherited_bp * clampi(spec.chance_basis_points, 0, 10000) / 10000
	var control_bp: int = effective_bp if _is_control_leaf(spec) else 0
	for child in spec.children:
		control_bp = maxi(control_bp, _runtime_control_bp(child, effective_bp))
	return control_bp


func _is_control_leaf(spec: BattleEffectSpec) -> bool:
	if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
		return spec.target == BattleEffectSpec.OPPONENT and spec.value < 0
	if spec.kind == BattleEffectSpec.INFLICT_STATUS:
		return spec.target == BattleEffectSpec.OPPONENT
	if spec.kind == BattleEffectSpec.FLINCH:
		return spec.target == BattleEffectSpec.OPPONENT
	return false


func _has_double_encoded_control_path(spec: BattleEffectSpec, inside_chance: bool) -> bool:
	if spec == null:
		return false
	if (
		inside_chance
		and _is_control_leaf(spec)
		and spec.kind != BattleEffectSpec.CHANCE
		and spec.chance_basis_points > 0
		and spec.chance_basis_points < 10000
	):
		return true
	var child_inside_chance: bool = inside_chance or spec.kind == BattleEffectSpec.CHANCE
	for child in spec.children:
		if _has_double_encoded_control_path(child, child_inside_chance):
			return true
	return false


func _has_direct_nonchance_probability_metadata(spec: BattleEffectSpec, inside_chance: bool) -> bool:
	if spec == null:
		return false
	if (
		not inside_chance
		and spec.kind != BattleEffectSpec.CHANCE
		and _is_control_leaf(spec)
		and spec.chance_basis_points > 0
		and spec.chance_basis_points < 10000
	):
		return true
	var child_inside_chance: bool = inside_chance or spec.kind == BattleEffectSpec.CHANCE
	for child in spec.children:
		if _has_direct_nonchance_probability_metadata(child, child_inside_chance):
			return true
	return false


func _base_accuracy_bp(move: MoveDefinition) -> int:
	if move.accuracy < 0:
		return 10000
	return clampi(move.accuracy * 100, 0, 10000)


func _sentinel_report(catalog: DefinitionCatalog, inference: TrainerRosterRoleInference) -> Dictionary:
	var out: Dictionary = {}
	for move_id in ["moonblast", "discharge", "rock_slide", "screech", "dynamic_punch", "thunder_wave", "lunge"]:
		var sid := StringName(move_id)
		var move: MoveDefinition = catalog.move(sid)
		if move == null:
			out[move_id] = {"missing": true}
			continue
		var audit: Dictionary = _audit_move(move)
		var member := {
			"instance_id": "control_probability_%s" % move_id,
			"stats": StatBlock.new(200, 100, 100, 100, 100, 100).to_dict(),
			"move_ids": [move_id],
		}
		var evidence: Dictionary = inference.extract_intrinsic_evidence(member, catalog)
		var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
		audit["inference_control_bp"] = int(capabilities.get("control_signal_bp", 0))
		audit["accuracy"] = move.accuracy
		audit["power"] = move.power
		out[move_id] = audit
	return out


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
		"instance_id": "control_probability_%s" % String(species.id),
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
