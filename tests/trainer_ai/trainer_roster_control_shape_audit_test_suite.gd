class_name TrainerRosterControlShapeAuditTestSuite
extends RefCounted

const DATA_PATH := "res://data/normalized/pokemon_api.json"
const PROBE_LEVEL := 50
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const HIGH_RELIABILITY_BP := 7500

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var normalized: Dictionary = _load_json(DATA_PATH)
	_check.call("control_shape_audit_dataset_loaded", not normalized.is_empty())
	if normalized.is_empty():
		return

	var game_data: GameData = GameData.from_dict(normalized)
	var catalog: DefinitionCatalog = game_data.to_definition_catalog()
	var species_ids: Array[StringName] = game_data.species_catalog.all_ids()
	_check.call("control_shape_audit_species_count_canonical", species_ids.size() == 1025)

	var report_a: Dictionary = _build_report(game_data, catalog, species_ids)
	var report_b: Dictionary = _build_report(game_data, catalog, species_ids)
	var eligible: int = int(report_a.get("eligible_species", 0))
	var missing: int = int(report_a.get("species_without_probe_moves", 0))
	var sentinels: Dictionary = report_a.get("sentinels", {}) as Dictionary

	_check.call("control_shape_audit_accounts_for_all_species", eligible + missing == species_ids.size())
	_check.call("control_shape_audit_finds_multi_move_control", int(report_a.get("species_with_multiple_control_moves", 0)) > 0)
	_check.call("control_shape_audit_finds_multiple_effect_keys", int(report_a.get("species_with_multiple_control_effect_keys", 0)) > 0)
	_check.call("control_shape_audit_finds_single_high_reliability_route", int(report_a.get("species_with_one_high_reliability_control_move", 0)) > 0)
	_check.call("control_shape_audit_finds_multiple_high_reliability_routes", int(report_a.get("species_with_multiple_high_reliability_control_moves", 0)) > 0)
	_check.call("control_shape_audit_report_deterministic", report_a == report_b)
	_check.call("control_shape_audit_report_json_serializable", not JSON.stringify(report_a).is_empty())

	var thunder_wave: Dictionary = sentinels.get("thunder_wave", {}) as Dictionary
	var screech: Dictionary = sentinels.get("screech", {}) as Dictionary
	var dynamic_punch: Dictionary = sentinels.get("dynamic_punch", {}) as Dictionary
	var rock_slide: Dictionary = sentinels.get("rock_slide", {}) as Dictionary
	var moonblast: Dictionary = sentinels.get("moonblast", {}) as Dictionary
	var icy_wind: Dictionary = sentinels.get("icy_wind", {}) as Dictionary

	_check.call(
		"control_shape_thunder_wave_is_reliable_dedicated_status",
		int(thunder_wave.get("best_attempt_reliability_bp", 0)) == 9000
		and bool(thunder_wave.get("dedicated_control", false))
		and (thunder_wave.get("effect_keys", []) as Array).has("status:paralysis"),
	)
	_check.call(
		"control_shape_screech_tracks_accuracy_and_two_stage_intensity",
		int(screech.get("best_attempt_reliability_bp", 0)) == 8500
		and int(screech.get("strongest_stat_drop_stages", 0)) == 2
		and bool(screech.get("dedicated_control", false)),
	)
	_check.call(
		"control_shape_dynamic_punch_is_powerful_but_half_reliable_damaging_control",
		int(dynamic_punch.get("best_attempt_reliability_bp", 0)) == 5000
		and bool(dynamic_punch.get("damaging_control", false))
		and not bool(dynamic_punch.get("dedicated_control", true)),
	)
	_check.call(
		"control_shape_rock_slide_secondary_is_accuracy_weighted",
		int(rock_slide.get("best_attempt_reliability_bp", 0)) == 2700
		and bool(rock_slide.get("damaging_control", false)),
	)
	_check.call(
		"control_shape_moonblast_uses_runtime_chance_not_double_metadata",
		int(moonblast.get("best_runtime_effect_bp", 0)) == 3000
		and int(moonblast.get("best_attempt_reliability_bp", 0)) == 3000
		and bool(moonblast.get("damaging_control", false)),
	)
	_check.call(
		"control_shape_icy_wind_is_high_reliability_damaging_control",
		int(icy_wind.get("best_attempt_reliability_bp", 0)) == 9500
		and bool(icy_wind.get("damaging_control", false))
		and (icy_wind.get("effect_keys", []) as Array).has("stat:speed"),
	)

	print("\n=== TRAINER CONTROL SHAPE AUDIT ===")
	print(JSON.stringify(report_a))


func _build_report(
	game_data: GameData,
	catalog: DefinitionCatalog,
	species_ids: Array[StringName],
) -> Dictionary:
	var inference := TrainerRosterRoleInference.new()
	var eligible: int = 0
	var missing: int = 0
	var species_with_control: int = 0
	var species_with_multiple_control_moves: int = 0
	var species_with_multiple_control_effect_keys: int = 0
	var species_with_one_high_reliability_control_move: int = 0
	var species_with_multiple_high_reliability_control_moves: int = 0
	var current_control_eq_10000: int = 0
	var current_max_with_one_control_move: int = 0
	var current_max_with_multiple_control_moves: int = 0
	var current_max_with_one_high_reliability_move: int = 0
	var current_max_with_multiple_high_reliability_moves: int = 0
	var current_max_without_high_reliability_move: int = 0
	var control_move_count_histogram: Dictionary = {}
	var effect_key_count_histogram: Dictionary = {}
	var effect_family_count_histogram: Dictionary = {}
	var high_reliability_move_count_histogram: Dictionary = {}
	var second_best_reliability_histogram: Dictionary = {}
	var strongest_stat_drop_histogram: Dictionary = {}
	var one_control_move_examples: Array[Dictionary] = []
	var multi_control_move_examples: Array[Dictionary] = []
	var one_move_multi_effect_examples: Array[Dictionary] = []
	var repeated_effect_axis_examples: Array[Dictionary] = []

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
		var role_result: Dictionary = inference.infer_role_scores(member, catalog)
		var evidence: Dictionary = role_result.get("intrinsic_evidence", {}) as Dictionary
		var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary
		var current_control_bp: int = clampi(int(capabilities.get("control_signal_bp", 0)), 0, 10000)

		var control_move_count: int = 0
		var dedicated_control_move_count: int = 0
		var damaging_control_move_count: int = 0
		var high_reliability_move_count: int = 0
		var strongest_stat_drop_stages: int = 0
		var effect_keys: Dictionary = {}
		var effect_families: Dictionary = {}
		var move_reliabilities: Array[int] = []
		var control_move_ids: Array[String] = []
		var dedicated_control_move_ids: Array[String] = []
		var damaging_control_move_ids: Array[String] = []

		for move_id in moves:
			var move: MoveDefinition = catalog.move(move_id)
			if move == null:
				continue
			var move_audit: Dictionary = _audit_move(move)
			if int(move_audit.get("effect_key_count", 0)) <= 0:
				continue
			control_move_count += 1
			control_move_ids.append(String(move_id))
			var reliability_bp: int = int(move_audit.get("best_attempt_reliability_bp", 0))
			move_reliabilities.append(reliability_bp)
			if reliability_bp >= HIGH_RELIABILITY_BP:
				high_reliability_move_count += 1
			if bool(move_audit.get("dedicated_control", false)):
				dedicated_control_move_count += 1
				dedicated_control_move_ids.append(String(move_id))
			if bool(move_audit.get("damaging_control", false)):
				damaging_control_move_count += 1
				damaging_control_move_ids.append(String(move_id))
			strongest_stat_drop_stages = maxi(
				strongest_stat_drop_stages,
				int(move_audit.get("strongest_stat_drop_stages", 0)),
			)
			for key in move_audit.get("effect_keys", []) as Array:
				effect_keys[String(key)] = true
			for family in move_audit.get("effect_families", []) as Array:
				effect_families[String(family)] = true

		move_reliabilities.sort()
		move_reliabilities.reverse()
		var best_reliability_bp: int = move_reliabilities[0] if not move_reliabilities.is_empty() else 0
		var second_best_reliability_bp: int = move_reliabilities[1] if move_reliabilities.size() >= 2 else 0
		var effect_key_ids: Array[String] = _sorted_dictionary_keys(effect_keys)
		var effect_family_ids: Array[String] = _sorted_dictionary_keys(effect_families)

		if control_move_count > 0:
			species_with_control += 1
		if control_move_count >= 2:
			species_with_multiple_control_moves += 1
		if effect_key_ids.size() >= 2:
			species_with_multiple_control_effect_keys += 1
		if high_reliability_move_count == 1:
			species_with_one_high_reliability_control_move += 1
		elif high_reliability_move_count >= 2:
			species_with_multiple_high_reliability_control_moves += 1

		if current_control_bp == 10000:
			current_control_eq_10000 += 1
			if control_move_count == 1:
				current_max_with_one_control_move += 1
			elif control_move_count >= 2:
				current_max_with_multiple_control_moves += 1
			if high_reliability_move_count == 0:
				current_max_without_high_reliability_move += 1
			elif high_reliability_move_count == 1:
				current_max_with_one_high_reliability_move += 1
			else:
				current_max_with_multiple_high_reliability_moves += 1

		_increment_histogram(control_move_count_histogram, control_move_count)
		_increment_histogram(effect_key_count_histogram, effect_key_ids.size())
		_increment_histogram(effect_family_count_histogram, effect_family_ids.size())
		_increment_histogram(high_reliability_move_count_histogram, high_reliability_move_count)
		_increment_bucket_histogram(second_best_reliability_histogram, second_best_reliability_bp)
		_increment_histogram(strongest_stat_drop_histogram, strongest_stat_drop_stages)

		var example := {
			"species_id": String(species_id),
			"current_control_bp": current_control_bp,
			"best_reliability_bp": best_reliability_bp,
			"second_best_reliability_bp": second_best_reliability_bp,
			"control_move_count": control_move_count,
			"high_reliability_move_count": high_reliability_move_count,
			"dedicated_control_move_count": dedicated_control_move_count,
			"damaging_control_move_count": damaging_control_move_count,
			"effect_keys": effect_key_ids.duplicate(),
			"effect_families": effect_family_ids.duplicate(),
			"strongest_stat_drop_stages": strongest_stat_drop_stages,
			"control_move_ids": control_move_ids.duplicate(),
			"dedicated_control_move_ids": dedicated_control_move_ids.duplicate(),
			"damaging_control_move_ids": damaging_control_move_ids.duplicate(),
			"probe_moves": _stringify_ids(moves),
		}
		if control_move_count == 1 and one_control_move_examples.size() < 12:
			one_control_move_examples.append(example.duplicate(true))
		if control_move_count >= 3 and multi_control_move_examples.size() < 12:
			multi_control_move_examples.append(example.duplicate(true))
		if control_move_count == 1 and effect_key_ids.size() >= 2 and one_move_multi_effect_examples.size() < 12:
			one_move_multi_effect_examples.append(example.duplicate(true))
		if control_move_count >= 2 and effect_key_ids.size() == 1 and repeated_effect_axis_examples.size() < 12:
			repeated_effect_axis_examples.append(example.duplicate(true))

	return {
		"probe_id": "control_shape_levelup_l50_v1",
		"species_total": species_ids.size(),
		"eligible_species": eligible,
		"species_without_probe_moves": missing,
		"species_with_control": species_with_control,
		"species_with_multiple_control_moves": species_with_multiple_control_moves,
		"species_with_multiple_control_effect_keys": species_with_multiple_control_effect_keys,
		"species_with_one_high_reliability_control_move": species_with_one_high_reliability_control_move,
		"species_with_multiple_high_reliability_control_moves": species_with_multiple_high_reliability_control_moves,
		"current_control_eq_10000": current_control_eq_10000,
		"current_max_with_one_control_move": current_max_with_one_control_move,
		"current_max_with_multiple_control_moves": current_max_with_multiple_control_moves,
		"current_max_without_high_reliability_move": current_max_without_high_reliability_move,
		"current_max_with_one_high_reliability_move": current_max_with_one_high_reliability_move,
		"current_max_with_multiple_high_reliability_moves": current_max_with_multiple_high_reliability_moves,
		"control_move_count_histogram": control_move_count_histogram,
		"effect_key_count_histogram": effect_key_count_histogram,
		"effect_family_count_histogram": effect_family_count_histogram,
		"high_reliability_move_count_histogram": high_reliability_move_count_histogram,
		"second_best_reliability_histogram": second_best_reliability_histogram,
		"strongest_stat_drop_histogram": strongest_stat_drop_histogram,
		"one_control_move_examples": one_control_move_examples,
		"multi_control_move_examples": multi_control_move_examples,
		"one_move_multi_effect_examples": one_move_multi_effect_examples,
		"repeated_effect_axis_examples": repeated_effect_axis_examples,
		"sentinels": _sentinel_report(catalog),
	}


func _audit_move(move: MoveDefinition) -> Dictionary:
	var routes: Array[Dictionary] = []
	for spec in move.effect_specs:
		_collect_control_routes(spec, 10000, routes)
	var accuracy_bp: int = _base_accuracy_bp(move)
	var best_runtime_effect_bp: int = 0
	var best_attempt_reliability_bp: int = 0
	var strongest_stat_drop_stages: int = 0
	var effect_keys: Dictionary = {}
	var effect_families: Dictionary = {}
	for route in routes:
		var runtime_effect_bp: int = int(route.get("runtime_effect_bp", 0))
		best_runtime_effect_bp = maxi(best_runtime_effect_bp, runtime_effect_bp)
		best_attempt_reliability_bp = maxi(
			best_attempt_reliability_bp,
			runtime_effect_bp * accuracy_bp / 10000,
		)
		var key: String = String(route.get("effect_key", ""))
		var family: String = String(route.get("effect_family", ""))
		if not key.is_empty():
			effect_keys[key] = true
		if not family.is_empty():
			effect_families[family] = true
		strongest_stat_drop_stages = maxi(
			strongest_stat_drop_stages,
			int(route.get("stat_drop_stages", 0)),
		)
	var effect_key_ids: Array[String] = _sorted_dictionary_keys(effect_keys)
	var effect_family_ids: Array[String] = _sorted_dictionary_keys(effect_families)
	return {
		"move_id": String(move.id),
		"accuracy": move.accuracy,
		"accuracy_bp": accuracy_bp,
		"power": move.power,
		"route_count": routes.size(),
		"effect_key_count": effect_key_ids.size(),
		"effect_keys": effect_key_ids,
		"effect_families": effect_family_ids,
		"best_runtime_effect_bp": best_runtime_effect_bp,
		"best_attempt_reliability_bp": best_attempt_reliability_bp,
		"strongest_stat_drop_stages": strongest_stat_drop_stages,
		"dedicated_control": not routes.is_empty() and move.power <= 0,
		"damaging_control": not routes.is_empty() and move.power > 0,
	}


func _collect_control_routes(
	spec: BattleEffectSpec,
	inherited_runtime_bp: int,
	out: Array[Dictionary],
) -> void:
	if spec == null:
		return
	var effective_runtime_bp: int = inherited_runtime_bp
	if spec.kind == BattleEffectSpec.CHANCE:
		effective_runtime_bp = inherited_runtime_bp * clampi(spec.chance_basis_points, 0, 10000) / 10000

	if _is_control_leaf(spec):
		out.append({
			"effect_key": _control_effect_key(spec),
			"effect_family": _control_effect_family(spec),
			"runtime_effect_bp": effective_runtime_bp,
			"stat_drop_stages": -spec.value if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE and spec.value < 0 else 0,
		})

	for child in spec.children:
		_collect_control_routes(child, effective_runtime_bp, out)


func _is_control_leaf(spec: BattleEffectSpec) -> bool:
	if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
		return spec.target == BattleEffectSpec.OPPONENT and spec.value < 0
	if spec.kind == BattleEffectSpec.INFLICT_STATUS:
		return spec.target == BattleEffectSpec.OPPONENT
	if spec.kind == BattleEffectSpec.FLINCH:
		return spec.target == BattleEffectSpec.OPPONENT
	return false


func _control_effect_key(spec: BattleEffectSpec) -> String:
	if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
		return "stat:%s" % String(spec.stat_id)
	if spec.kind == BattleEffectSpec.INFLICT_STATUS:
		return "status:%s" % String(spec.status_id)
	if spec.kind == BattleEffectSpec.FLINCH:
		return "flinch"
	return ""


func _control_effect_family(spec: BattleEffectSpec) -> String:
	if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
		return "stat_debuff"
	if spec.kind == BattleEffectSpec.INFLICT_STATUS:
		return "status"
	if spec.kind == BattleEffectSpec.FLINCH:
		return "flinch"
	return ""


func _base_accuracy_bp(move: MoveDefinition) -> int:
	if move.accuracy < 0:
		return 10000
	return clampi(move.accuracy * 100, 0, 10000)


func _sentinel_report(catalog: DefinitionCatalog) -> Dictionary:
	var out: Dictionary = {}
	for move_id in ["thunder_wave", "screech", "dynamic_punch", "rock_slide", "moonblast", "icy_wind"]:
		var move: MoveDefinition = catalog.move(StringName(move_id))
		if move == null:
			out[move_id] = {"missing": true}
			continue
		out[move_id] = _audit_move(move)
	return out


func _increment_histogram(histogram: Dictionary, count: int) -> void:
	var key := String.num_int64(count)
	histogram[key] = int(histogram.get(key, 0)) + 1


func _increment_bucket_histogram(histogram: Dictionary, value_bp: int) -> void:
	var key := "0"
	if value_bp >= 9000:
		key = "9000_10000"
	elif value_bp >= 7500:
		key = "7500_8999"
	elif value_bp >= 5000:
		key = "5000_7499"
	elif value_bp > 0:
		key = "1_4999"
	histogram[key] = int(histogram.get(key, 0)) + 1


func _sorted_dictionary_keys(source: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw_key in source.keys():
		out.append(String(raw_key))
	out.sort()
	return out


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
		"instance_id": "control_shape_%s" % String(species.id),
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
