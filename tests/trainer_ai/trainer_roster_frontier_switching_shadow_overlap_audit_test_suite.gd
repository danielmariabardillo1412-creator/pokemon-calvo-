class_name TrainerRosterFrontierSwitchingShadowOverlapAuditTestSuite
extends TrainerRosterFrontierFirstConsumerBoundaryAuditTestSuite

# C3f-m is deliberately shadow/audit-only. It measures how often the passive,
# rival-agnostic component-first Pareto frontier overlaps the contextual switch
# optimum. Frontier membership never enters TrainerStrategicSwitchEvaluatorV2,
# never changes a score, and never filters a legal action.

const AUDIT_ID_C3FM := "c3f_m_switching_frontier_shadow_overlap_audit_v1"
const ROSTER_SAMPLE_STRIDE := 8
const OPPONENT_OFFSETS := [37, 503]
const EVIDENCE_MODES := ["species_fallback", "revealed_damaging_move"]
const EXPECTED_ROSTERS := 128
const EXPECTED_SCENARIOS := 512
const EXPECTED_SWITCH_CANDIDATES_PER_SCENARIO := 5


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_switching_frontier_shadow_overlap()


func _test_switching_frontier_shadow_overlap() -> void:
	var report_a := _build_c3fm_report()
	var report_b := _build_c3fm_report()

	_check.call(
		"frontier_shadow_overlap_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FM,
	)
	_check.call(
		"frontier_shadow_overlap_uses_production_models",
		String(report_a.get("frontier_model_id", "")) == TrainerRosterParetoFrontier.MODEL_ID
		and String(report_a.get("source_contract_model_id", "")) == TrainerRosterComponentFirstContract.MODEL_ID
		and String(report_a.get("switching_model_id", "")) == TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
	)
	_check.call(
		"frontier_shadow_overlap_uses_canonical_real_data",
		int(report_a.get("eligible_species", 0)) == EXPECTED_ELIGIBLE_SPECIES
		and int(report_a.get("sample_stride", -1)) == ROSTER_SAMPLE_STRIDE,
	)
	_check.call(
		"frontier_shadow_overlap_uses_expected_matrix",
		int(report_a.get("sampled_rosters", 0)) == EXPECTED_ROSTERS
		and int(report_a.get("opponent_context_pairs", 0)) == EXPECTED_ROSTERS * OPPONENT_OFFSETS.size()
		and int(report_a.get("scenarios", 0)) == EXPECTED_SCENARIOS,
	)
	_check.call(
		"frontier_shadow_overlap_opponent_selection_complete",
		int(report_a.get("opponent_selection_failures", -1)) == 0
		and int(report_a.get("context_build_failures", -1)) == 0,
	)
	_check.call(
		"frontier_shadow_overlap_contract_and_frontier_valid",
		int(report_a.get("contract_validation_failures", -1)) == 0
		and int(report_a.get("frontier_validation_failures", -1)) == 0,
	)
	_check.call(
		"frontier_shadow_overlap_switch_candidate_accounting",
		int(report_a.get("switch_candidate_occurrences", 0))
		== EXPECTED_SCENARIOS * EXPECTED_SWITCH_CANDIDATES_PER_SCENARIO
		and int(report_a.get("candidate_partition_mismatches", -1)) == 0,
	)
	_check.call(
		"frontier_shadow_overlap_frontier_bench_accounting",
		int(report_a.get("contexts_with_frontier_bench", -1))
		+ int(report_a.get("contexts_without_frontier_bench", -1))
		== EXPECTED_SCENARIOS,
	)
	_check.call(
		"frontier_shadow_overlap_optimum_accounting",
		int(report_a.get("best_set_intersects_frontier_cases", -1))
		+ int(report_a.get("hard_frontier_pruning_loses_all_optima_cases", -1))
		== EXPECTED_SCENARIOS,
	)
	_check.call(
		"frontier_shadow_overlap_frontier_only_score_accounting",
		int(report_a.get("frontier_only_exact_optimum_cases", -1))
		+ int(report_a.get("frontier_only_score_loss_cases", -1))
		+ int(report_a.get("contexts_without_frontier_bench", -1))
		== EXPECTED_SCENARIOS,
	)
	_check.call(
		"frontier_shadow_overlap_ties_are_set_semantics",
		String(report_a.get("best_set_semantics", "")) == "all_equal_max_score_switch_ids"
		and not bool(report_a.get("lexical_best_selection_used", true)),
	)
	_check.call(
		"frontier_shadow_overlap_evidence_pair_accounting",
		int(report_a.get("evidence_pair_comparisons", -1)) == EXPECTED_ROSTERS * OPPONENT_OFFSETS.size()
		and int(report_a.get("evidence_changed_best_set_cases", -1)) >= 0,
	)
	_check.call(
		"frontier_shadow_overlap_remains_shadow_only",
		String(report_a.get("recommended_switching_use", ""))
		== "shadow_observability_only_not_candidate_filter"
		and not bool(report_a.get("frontier_pruning_authorized", true))
		and not bool(report_a.get("frontier_score_bonus_authorized", true))
		and not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call(
		"frontier_shadow_overlap_c3fl_safety_barrier_preserved",
		not bool(report_a.get("hard_frontier_pruning_safe_for_switching", true)),
	)
	_check.call("frontier_shadow_overlap_report_deterministic", report_a == report_b)
	_check.call(
		"frontier_shadow_overlap_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER FRONTIER SWITCHING SHADOW OVERLAP AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fm_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"audit_id": AUDIT_ID_C3FM, "eligible_species": 0}

	var game_data := GameData.from_dict(normalized)
	var catalog := game_data.to_definition_catalog()
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe := helper._build_probe_members(game_data, catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)

	var fixture_catalog := _catalog
	_catalog = catalog
	var contract_builder := TrainerRosterComponentFirstContract.new(catalog, _operational_ruleset)
	var frontier_evaluator := TrainerRosterParetoFrontier.new()
	var switching_evaluator := TrainerStrategicSwitchEvaluatorV2.new(catalog, TrainerProfile.balanced())

	var sampled_rosters := 0
	var opponent_context_pairs := 0
	var scenarios := 0
	var switch_candidate_occurrences := 0
	var opponent_selection_failures := 0
	var context_build_failures := 0
	var contract_validation_failures := 0
	var frontier_validation_failures := 0
	var candidate_partition_mismatches := 0
	var contexts_with_frontier_bench := 0
	var contexts_without_frontier_bench := 0
	var best_set_intersects_frontier_cases := 0
	var best_set_contains_dominated_cases := 0
	var best_set_dominated_only_cases := 0
	var hard_frontier_pruning_loses_all_optima_cases := 0
	var frontier_only_exact_optimum_cases := 0
	var frontier_only_score_loss_cases := 0
	var frontier_only_score_loss_sum := 0
	var frontier_only_score_loss_max := 0
	var evidence_pair_comparisons := 0
	var evidence_changed_best_set_cases := 0
	var frontier_bench_count_histogram: Dictionary = {}
	var best_set_size_histogram: Dictionary = {}
	var mode_summary: Dictionary = {}
	for mode in EVIDENCE_MODES:
		mode_summary[String(mode)] = _new_mode_summary()
	var loss_examples: Array[Dictionary] = []
	var no_frontier_bench_examples: Array[Dictionary] = []

	var schedule_stride := int(TrainerRosterStructuralRealDataAuditTestSuite.SCHEDULE_STRIDES[0])
	for anchor in range(0, members.size(), ROSTER_SAMPLE_STRIDE):
		var roster := helper._scheduled_roster(members, anchor, schedule_stride)
		var degraded := _degraded_roster(roster, sampled_rosters)
		var contract := contract_builder.build_contract(degraded)
		var frontier := frontier_evaluator.evaluate(contract)
		sampled_rosters += 1

		if (
			String(contract.get("model_id", "")) != TrainerRosterComponentFirstContract.MODEL_ID
			or int(contract.get("member_count", -1)) != degraded.size()
		):
			contract_validation_failures += 1
		if (
			String(frontier.get("model_id", "")) != TrainerRosterParetoFrontier.MODEL_ID
			or not bool(frontier.get("input_contract_valid", false))
		):
			frontier_validation_failures += 1

		var frontier_ids := _c3fm_string_array(frontier.get("frontier_instance_ids", []) as Array)
		var dominated_ids := _c3fm_string_array(frontier.get("dominated_instance_ids", []) as Array)
		var active_id := String(degraded[0].get("instance_id", ""))
		var own_ids: Dictionary = {}
		for member in degraded:
			own_ids[String(member.get("instance_id", ""))] = true

		var banned_opponent_ids := own_ids.duplicate()
		for raw_offset in OPPONENT_OFFSETS:
			var opponent := _select_real_opponent(
				members,
				(anchor + int(raw_offset)) % maxi(1, members.size()),
				banned_opponent_ids,
				catalog,
			)
			if opponent.is_empty():
				opponent_selection_failures += 1
				continue
			var opponent_id := String(opponent.get("instance_id", ""))
			banned_opponent_ids[opponent_id] = true
			opponent_context_pairs += 1
			var fallback_best_ids: Array[String] = []

			for mode_index in range(EVIDENCE_MODES.size()):
				var mode := String(EVIDENCE_MODES[mode_index])
				var context := _build_shadow_context(degraded, opponent, mode, catalog)
				if context == null:
					context_build_failures += 1
					continue
				var outcome := _evaluate_shadow_switches(
					context,
					active_id,
					frontier_ids,
					dominated_ids,
					switching_evaluator,
				)
				if not bool(outcome.get("valid", false)):
					context_build_failures += 1
					continue

				scenarios += 1
				var candidate_count := int(outcome.get("candidate_count", 0))
				switch_candidate_occurrences += candidate_count
				candidate_partition_mismatches += int(outcome.get("candidate_partition_mismatches", 0))
				var frontier_bench_count := int(outcome.get("frontier_bench_count", 0))
				_c3fm_histogram_increment(frontier_bench_count_histogram, frontier_bench_count)
				var best_ids := _c3fm_string_array(outcome.get("best_switch_ids", []) as Array)
				_c3fm_histogram_increment(best_set_size_histogram, best_ids.size())

				var has_frontier_bench := bool(outcome.get("has_frontier_bench", false))
				var best_intersects_frontier := bool(outcome.get("best_set_intersects_frontier", false))
				var best_contains_dominated := bool(outcome.get("best_set_contains_dominated", false))
				if has_frontier_bench:
					contexts_with_frontier_bench += 1
				else:
					contexts_without_frontier_bench += 1
					if no_frontier_bench_examples.size() < 8:
						no_frontier_bench_examples.append(_scenario_example(
							anchor,
							mode,
							opponent,
							outcome,
							frontier_ids,
							dominated_ids,
						))
				if best_intersects_frontier:
					best_set_intersects_frontier_cases += 1
				else:
					hard_frontier_pruning_loses_all_optima_cases += 1
					best_set_dominated_only_cases += 1
				if best_contains_dominated:
					best_set_contains_dominated_cases += 1

				if has_frontier_bench:
					var global_best_score := int(outcome.get("global_best_score", 0))
					var frontier_best_score := int(outcome.get("frontier_best_score", 0))
					if frontier_best_score == global_best_score:
						frontier_only_exact_optimum_cases += 1
					else:
						var loss := maxi(0, global_best_score - frontier_best_score)
						frontier_only_score_loss_cases += 1
						frontier_only_score_loss_sum += loss
						frontier_only_score_loss_max = maxi(frontier_only_score_loss_max, loss)
						if loss_examples.size() < 12:
							var example := _scenario_example(
								anchor,
								mode,
								opponent,
								outcome,
								frontier_ids,
								dominated_ids,
							)
							example["frontier_only_score_loss"] = loss
							loss_examples.append(example)

				var summary := mode_summary.get(mode, {}) as Dictionary
				summary["scenarios"] = int(summary.get("scenarios", 0)) + 1
				if best_intersects_frontier:
					summary["preserves_any_optimum"] = int(summary.get("preserves_any_optimum", 0)) + 1
				else:
					summary["loses_all_optima"] = int(summary.get("loses_all_optima", 0)) + 1
				if best_contains_dominated:
					summary["best_set_contains_dominated"] = int(summary.get("best_set_contains_dominated", 0)) + 1
				if not has_frontier_bench:
					summary["no_frontier_bench"] = int(summary.get("no_frontier_bench", 0)) + 1
				mode_summary[mode] = summary

				if mode_index == 0:
					fallback_best_ids = best_ids.duplicate()
				else:
					evidence_pair_comparisons += 1
					if best_ids != fallback_best_ids:
						evidence_changed_best_set_cases += 1

	_catalog = fixture_catalog
	var mean_loss := (
		frontier_only_score_loss_sum / frontier_only_score_loss_cases
		if frontier_only_score_loss_cases > 0
		else 0
	)
	var sample_supports_hard_pruning := (
		hard_frontier_pruning_loses_all_optima_cases == 0
		and contexts_without_frontier_bench == 0
	)
	return {
		"audit_id": AUDIT_ID_C3FM,
		"dataset_probe_id": TrainerRosterStructuralRealDataAuditTestSuite.PROBE_ID,
		"eligible_species": members.size(),
		"sample_stride": ROSTER_SAMPLE_STRIDE,
		"sampled_rosters": sampled_rosters,
		"opponent_offsets": OPPONENT_OFFSETS.duplicate(),
		"opponent_context_pairs": opponent_context_pairs,
		"evidence_modes": EVIDENCE_MODES.duplicate(),
		"scenarios": scenarios,
		"switch_candidate_occurrences": switch_candidate_occurrences,
		"opponent_selection_failures": opponent_selection_failures,
		"context_build_failures": context_build_failures,
		"contract_validation_failures": contract_validation_failures,
		"frontier_validation_failures": frontier_validation_failures,
		"candidate_partition_mismatches": candidate_partition_mismatches,
		"source_contract_model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"frontier_model_id": TrainerRosterParetoFrontier.MODEL_ID,
		"switching_model_id": TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
		"contexts_with_frontier_bench": contexts_with_frontier_bench,
		"contexts_without_frontier_bench": contexts_without_frontier_bench,
		"best_set_intersects_frontier_cases": best_set_intersects_frontier_cases,
		"best_set_contains_dominated_cases": best_set_contains_dominated_cases,
		"best_set_dominated_only_cases": best_set_dominated_only_cases,
		"hard_frontier_pruning_loses_all_optima_cases": hard_frontier_pruning_loses_all_optima_cases,
		"frontier_only_exact_optimum_cases": frontier_only_exact_optimum_cases,
		"frontier_only_score_loss_cases": frontier_only_score_loss_cases,
		"frontier_only_score_loss_sum": frontier_only_score_loss_sum,
		"frontier_only_score_loss_mean": mean_loss,
		"frontier_only_score_loss_max": frontier_only_score_loss_max,
		"frontier_bench_count_histogram": frontier_bench_count_histogram,
		"best_set_size_histogram": best_set_size_histogram,
		"evidence_pair_comparisons": evidence_pair_comparisons,
		"evidence_changed_best_set_cases": evidence_changed_best_set_cases,
		"evidence_mode_summary": mode_summary,
		"loss_examples": loss_examples,
		"no_frontier_bench_examples": no_frontier_bench_examples,
		"best_set_semantics": "all_equal_max_score_switch_ids",
		"lexical_best_selection_used": false,
		"sample_supports_hard_pruning": sample_supports_hard_pruning,
		"hard_frontier_pruning_safe_for_switching": false,
		"frontier_pruning_authorized": false,
		"frontier_score_bonus_authorized": false,
		"behavior_integration_authorized": false,
		"recommended_switching_use": "shadow_observability_only_not_candidate_filter",
	}


func _select_real_opponent(
	members: Array[Dictionary],
	start_index: int,
	banned_ids: Dictionary,
	catalog: DefinitionCatalog,
) -> Dictionary:
	if members.is_empty():
		return {}
	for step in range(members.size()):
		var member := members[(start_index + step) % members.size()] as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		if instance_id.is_empty() or banned_ids.has(instance_id):
			continue
		if _deterministic_damaging_move_id(member, catalog).is_empty():
			continue
		return member.duplicate(true)
	return {}


func _deterministic_damaging_move_id(member: Dictionary, catalog: DefinitionCatalog) -> String:
	for raw_move_id in member.get("move_ids", []):
		var move_id := StringName(String(raw_move_id))
		var move := catalog.move(move_id)
		if move != null and move.power > 0 and move.classification == "RUNTIME_SUPPORTED":
			return String(move_id)
	return ""


func _build_shadow_context(
	own_roster: Array[Dictionary],
	opponent_member: Dictionary,
	mode: String,
	catalog: DefinitionCatalog,
) -> TrainerDecisionContext:
	if own_roster.size() < 2 or opponent_member.is_empty():
		return null
	var observation := TrainerObservation.new()
	observation.battle_id = &"c3fm_shadow"
	observation.turn = 1
	observation.phase = &"action_selection"
	observation.observer_side_id = &"side_a"
	observation.opponent_side_id = &"side_b"
	observation.own_active_id = StringName(String(own_roster[0].get("instance_id", "")))

	var own_party: Array[Dictionary] = []
	for raw_member in own_roster:
		own_party.append(raw_member.duplicate(true))
	observation.own_party = own_party

	var revealed_move_ids: Array[String] = []
	if mode == "revealed_damaging_move":
		var revealed_move_id := _deterministic_damaging_move_id(opponent_member, catalog)
		if revealed_move_id.is_empty():
			return null
		revealed_move_ids.append(revealed_move_id)
	var opponent_view: Dictionary = {
		"instance_id": String(opponent_member.get("instance_id", "")),
		"species_id": String(opponent_member.get("species_id", "")),
		"level": int(opponent_member.get("level", TrainerRosterStructuralRealDataAuditTestSuite.PROBE_LEVEL)),
		"hp_ratio_basis_points": 10000,
		"is_knocked_out": false,
		"revealed_move_ids": revealed_move_ids,
		"stat_stages": {},
	}
	observation.opponent_active_id = StringName(String(opponent_view.get("instance_id", "")))
	var observed_opponents: Array[Dictionary] = [opponent_view]
	observation.observed_opponents = observed_opponents

	var context := TrainerDecisionContext.new()
	context.observation = observation
	context.belief_snapshot = {"hypotheses": {}}
	context.memory_snapshot = {"event_log": []}
	context.campaign_snapshot = {}
	for slot in range(1, own_party.size()):
		var target_id := StringName(String(own_party[slot].get("instance_id", "")))
		context.legal_actions.append(BattleAction.new(
			1,
			observation.own_active_id,
			&"",
			&"",
			BattleAction.SWITCH,
			&"side_a",
			target_id,
		))
	return context


func _evaluate_shadow_switches(
	context: TrainerDecisionContext,
	active_id: String,
	frontier_ids: Array[String],
	dominated_ids: Array[String],
	evaluator: TrainerStrategicSwitchEvaluatorV2,
) -> Dictionary:
	if context == null or evaluator == null:
		return {"valid": false}
	var scores: Dictionary = {}
	var best_ids: Array[String] = []
	var global_best_score := -2147483648
	var frontier_best_score := -2147483648
	var frontier_bench_count := 0
	var partition_mismatches := 0

	for action in context.legal_actions:
		if action == null or action.action_type != BattleAction.SWITCH:
			continue
		var candidate_id := String(action.switch_instance_id)
		if candidate_id.is_empty() or candidate_id == active_id:
			continue
		var result := evaluator.evaluate(context, action)
		var score := int(result.get("score", 0))
		scores[candidate_id] = score
		if not frontier_ids.has(candidate_id) and not dominated_ids.has(candidate_id):
			partition_mismatches += 1
		if frontier_ids.has(candidate_id):
			frontier_bench_count += 1
			frontier_best_score = maxi(frontier_best_score, score)
		if score > global_best_score:
			global_best_score = score
			best_ids = [candidate_id]
		elif score == global_best_score:
			best_ids.append(candidate_id)

	best_ids.sort()
	var best_intersects_frontier := false
	var best_contains_dominated := false
	for candidate_id in best_ids:
		if frontier_ids.has(candidate_id):
			best_intersects_frontier = true
		if dominated_ids.has(candidate_id):
			best_contains_dominated = true
	return {
		"valid": not scores.is_empty(),
		"candidate_count": scores.size(),
		"candidate_scores": scores,
		"candidate_partition_mismatches": partition_mismatches,
		"global_best_score": global_best_score if not scores.is_empty() else 0,
		"best_switch_ids": best_ids,
		"has_frontier_bench": frontier_bench_count > 0,
		"frontier_bench_count": frontier_bench_count,
		"frontier_best_score": frontier_best_score if frontier_bench_count > 0 else 0,
		"best_set_intersects_frontier": best_intersects_frontier,
		"best_set_contains_dominated": best_contains_dominated,
	}


func _scenario_example(
	anchor: int,
	mode: String,
	opponent: Dictionary,
	outcome: Dictionary,
	frontier_ids: Array[String],
	dominated_ids: Array[String],
) -> Dictionary:
	return {
		"anchor": anchor,
		"evidence_mode": mode,
		"opponent_species_id": String(opponent.get("species_id", "")),
		"frontier_instance_ids": frontier_ids.duplicate(),
		"dominated_instance_ids": dominated_ids.duplicate(),
		"best_switch_ids": (outcome.get("best_switch_ids", []) as Array).duplicate(),
		"global_best_score": int(outcome.get("global_best_score", 0)),
		"frontier_best_score": int(outcome.get("frontier_best_score", 0)),
		"frontier_bench_count": int(outcome.get("frontier_bench_count", 0)),
	}


func _new_mode_summary() -> Dictionary:
	return {
		"scenarios": 0,
		"preserves_any_optimum": 0,
		"loses_all_optima": 0,
		"best_set_contains_dominated": 0,
		"no_frontier_bench": 0,
	}


func _c3fm_histogram_increment(histogram: Dictionary, value: int) -> void:
	var key := String.num_int64(value)
	histogram[key] = int(histogram.get(key, 0)) + 1


func _c3fm_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for raw_value in values:
		out.append(String(raw_value))
	out.sort()
	return out
