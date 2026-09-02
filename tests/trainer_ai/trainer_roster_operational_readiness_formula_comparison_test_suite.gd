class_name TrainerRosterOperationalReadinessFormulaComparisonTestSuite
extends TrainerRosterOperationalEvidenceAuditTestSuite

const COMPARISON_ID := "c3f_b_current_operational_readiness_formula_comparison_v1"
const REAL_DATA_SAMPLE_STRIDE := 8
const CANDIDATE_IDS: Array[String] = [
	"hp_only",
	"naive_mean_pp_blend",
	"route_retention_blend",
	"route_action_status_blend",
	"route_action_status_product",
	"active_tick_assumption_product",
]


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_readiness_formula_comparison()


func _test_readiness_formula_comparison() -> void:
	_enable_runtime_team_moves()
	var full := _ready_view(
		"c3fb_full",
		TC_FIRE_A,
		StatBlock.new(100, 160, 80, 90, 80, 110),
		[TC_FIRE_PHYS, TC_SUPPORT],
	)
	var full_evidence := _operational_evidence(full)
	var full_scores := _candidate_scores(full_evidence)
	_check.call("readiness_formula_comparison_id_recorded", COMPARISON_ID == "c3f_b_current_operational_readiness_formula_comparison_v1")
	_check.call("readiness_formula_candidate_count", CANDIDATE_IDS.size() == 6)
	_check.call("readiness_formula_healthy_full_is_ceiling", _all_candidate_scores_equal(full_scores, 10000))
	_check.call("readiness_formula_scores_bounded", _scores_bounded(full_scores))

	var low_hp := full.duplicate(true)
	low_hp["current_hp"] = 40
	var low_hp_scores := _candidate_scores(_operational_evidence(low_hp))
	_check.call(
		"readiness_formula_lower_hp_never_improves",
		_candidate_scores_componentwise_leq(low_hp_scores, full_scores),
	)

	var physical_depleted := full.duplicate(true)
	_set_move_pp(physical_depleted, TC_FIRE_PHYS, 0, 20)
	var physical_depleted_evidence := _operational_evidence(physical_depleted)
	var physical_depleted_scores := _candidate_scores(physical_depleted_evidence)
	_check.call(
		"readiness_formula_route_depletion_never_improves",
		_candidate_scores_componentwise_leq(physical_depleted_scores, full_scores),
	)
	_check.call(
		"readiness_formula_hp_control_is_pp_blind",
		int(physical_depleted_scores.get("hp_only", -1)) == int(full_scores.get("hp_only", -2)),
	)

	var restored := physical_depleted.duplicate(true)
	_set_move_pp(restored, TC_FIRE_PHYS, 20, 20)
	var restored_scores := _candidate_scores(_operational_evidence(restored))
	_check.call(
		"readiness_formula_restoring_pp_never_hurts",
		_candidate_scores_componentwise_leq(physical_depleted_scores, restored_scores),
	)

	var redundant_routes := _ready_view(
		"c3fb_redundant",
		TC_FIRE_A,
		StatBlock.new(100, 170, 80, 70, 80, 110),
		[TC_FIRE_PHYS, TC_GROUND_PHYS],
	)
	var redundant_full_scores := _candidate_scores(_operational_evidence(redundant_routes))
	var redundant_one_down := redundant_routes.duplicate(true)
	_set_move_pp(redundant_one_down, TC_FIRE_PHYS, 0, 20)
	var redundant_down_evidence := _operational_evidence(redundant_one_down)
	var redundant_down_scores := _candidate_scores(redundant_down_evidence)
	_check.call(
		"readiness_formula_naive_pp_penalizes_redundant_route",
		int(redundant_down_scores.get("naive_mean_pp_blend", 10000)) < int(redundant_full_scores.get("naive_mean_pp_blend", 0)),
	)
	_check.call(
		"readiness_formula_route_retention_preserves_redundant_capability",
		_route_retention_bp(redundant_down_evidence) == 10000
		and int(redundant_down_scores.get("route_retention_blend", -1)) == 10000,
	)

	var support_depleted := full.duplicate(true)
	_set_move_pp(support_depleted, TC_SUPPORT, 0, 20)
	var support_depleted_evidence := _operational_evidence(support_depleted)
	var support_depleted_scores := _candidate_scores(support_depleted_evidence)
	_check.call(
		"readiness_formula_naive_equal_mean_collision_reproduced",
		_naive_runtime_pp_mean_bp(physical_depleted_evidence) == 5000
		and _naive_runtime_pp_mean_bp(support_depleted_evidence) == 5000
		and int(physical_depleted_scores.get("naive_mean_pp_blend", -1))
		== int(support_depleted_scores.get("naive_mean_pp_blend", -2)),
	)
	_check.call(
		"readiness_formula_route_vectors_survive_equal_mean_collision",
		physical_depleted_evidence.get("available_pp_sensitive_role_max_bp", {})
		!= support_depleted_evidence.get("available_pp_sensitive_role_max_bp", {}),
	)

	var symmetric_stats := StatBlock.new(100, 160, 80, 160, 80, 120)
	var physical_only := _ready_view("c3fb_phys", TC_FIRE_A, symmetric_stats, [TC_FIRE_PHYS])
	var special_only := _ready_view("c3fb_spec", TC_FIRE_A, symmetric_stats, [TC_FIRE_SPEC])
	_set_status(physical_only, StatusSystem.BURN, 0, 0)
	_set_status(special_only, StatusSystem.BURN, 0, 0)
	var physical_burn_evidence := _operational_evidence(physical_only)
	var special_burn_evidence := _operational_evidence(special_only)
	var physical_burn_scores := _candidate_scores(physical_burn_evidence)
	var special_burn_scores := _candidate_scores(special_burn_evidence)
	_check.call(
		"readiness_formula_burn_penalizes_physical_more_than_special",
		_status_action_factor_bp(physical_burn_evidence) < _status_action_factor_bp(special_burn_evidence)
		and int(physical_burn_scores.get("route_action_status_blend", 10000))
		< int(special_burn_scores.get("route_action_status_blend", 0)),
	)

	var fast := _ready_view(
		"c3fb_fast",
		TC_ELECTRIC,
		StatBlock.new(100, 130, 80, 200, 70, 80),
		[TC_ELECTRIC_PHYS],
	)
	var slow := _ready_view(
		"c3fb_slow",
		TC_ELECTRIC,
		StatBlock.new(100, 130, 80, 45, 70, 80),
		[TC_ELECTRIC_PHYS],
	)
	_set_status(fast, StatusSystem.PARALYSIS, 0, 0)
	_set_status(slow, StatusSystem.PARALYSIS, 0, 0)
	var fast_paralysis := _operational_evidence(fast)
	var slow_paralysis := _operational_evidence(slow)
	var fast_roles := fast_paralysis.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
	var slow_roles := slow_paralysis.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
	_check.call(
		"readiness_formula_paralysis_penalizes_fast_dependency_more",
		int(fast_roles.get("fast_attacker", 0)) > int(slow_roles.get("fast_attacker", 0))
		and _status_action_factor_bp(fast_paralysis) < _status_action_factor_bp(slow_paralysis),
	)

	var sleep := full.duplicate(true)
	_set_status(sleep, StatusSystem.SLEEP, 2, 0)
	var sleep_evidence := _operational_evidence(sleep)
	var freeze := full.duplicate(true)
	_set_status(freeze, StatusSystem.FREEZE, 0, 0)
	var freeze_evidence := _operational_evidence(freeze)
	_check.call(
		"readiness_formula_sleep_current_action_factor_zero",
		_status_action_factor_bp(sleep_evidence) == 0,
	)
	_check.call(
		"readiness_formula_freeze_current_action_factor_matches_thaw",
		_status_action_factor_bp(freeze_evidence) == _operational_ruleset.freeze_thaw_chance_basis_points,
	)

	var poison := full.duplicate(true)
	_set_status(poison, StatusSystem.POISON, 0, 0)
	var poison_evidence := _operational_evidence(poison)
	var poison_scores := _candidate_scores(poison_evidence)
	var toxic := full.duplicate(true)
	_set_status(toxic, StatusSystem.BADLY_POISONED, 0, 3)
	var toxic_evidence := _operational_evidence(toxic)
	var toxic_scores := _candidate_scores(toxic_evidence)
	_check.call(
		"readiness_formula_poison_does_not_fake_immediate_action_loss",
		_status_action_factor_bp(poison_evidence) == 10000
		and int(poison_scores.get("route_action_status_blend", -1)) == 10000,
	)
	_check.call(
		"readiness_formula_attrition_is_separate_horizon_assumption",
		_next_active_tick_loss_bp(poison_evidence) > 0
		and _next_active_tick_loss_bp(toxic_evidence) > _next_active_tick_loss_bp(poison_evidence)
		and int(poison_scores.get("active_tick_assumption_product", 10000)) < 10000
		and int(toxic_scores.get("active_tick_assumption_product", 10000))
		< int(poison_scores.get("active_tick_assumption_product", 0)),
	)

	var consumed := full.duplicate(true)
	consumed["held_item_id"] = "c3fb_item"
	consumed["held_item_consumed"] = true
	var item_ready := full.duplicate(true)
	item_ready["held_item_id"] = "c3fb_item"
	item_ready["held_item_consumed"] = false
	_check.call(
		"readiness_formula_held_item_still_evidence_only",
		_candidate_scores(_operational_evidence(consumed))
		== _candidate_scores(_operational_evidence(item_ready)),
	)

	var report_a := _build_comparison_report()
	var report_b := _build_comparison_report()
	_check.call("readiness_formula_real_data_report_deterministic", report_a == report_b)
	_check.call("readiness_formula_real_data_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call(
		"readiness_formula_real_data_sample_is_broad",
		int(report_a.get("sample_members", 0)) >= 100,
	)
	_check.call(
		"readiness_formula_real_data_detects_redundant_pp_penalty_cases",
		int(report_a.get("naive_penalizes_but_route_preserves_cases", 0)) > 0,
	)
	_check.call(
		"readiness_formula_real_data_has_physical_and_special_burn_samples",
		int(report_a.get("burn_physical_dominant_count", 0)) > 0
		and int(report_a.get("burn_special_dominant_count", 0)) > 0,
	)
	_check.call(
		"readiness_formula_real_data_burn_role_sensitivity",
		int(report_a.get("burn_physical_dominant_mean_penalty_bp", 0))
		> int(report_a.get("burn_special_dominant_mean_penalty_bp", 0)),
	)
	_check.call(
		"readiness_formula_real_data_poison_horizon_divergence",
		int(report_a.get("poison_immediate_penalty_cases", -1)) == 0
		and int(report_a.get("poison_active_tick_penalty_cases", 0)) == int(report_a.get("sample_members", -1)),
	)
	_check.call(
		"readiness_formula_comparison_remains_test_only",
		report_a.has("selected_operational_readiness_formula")
		and report_a.get("selected_operational_readiness_formula") == null
		and not report_a.has("production_operational_readiness_bp")
		and not report_a.has("between_battle_recovery_policy")
		and not report_a.has("replacement_policy"),
	)

	print("\n=== TRAINER ROSTER CURRENT READINESS FORMULA COMPARISON ===")
	print(JSON.stringify(report_a))


func _candidate_scores(evidence: Dictionary) -> Dictionary:
	var hp_bp := int((evidence.get("hp", {}) as Dictionary).get("hp_ratio_bp", 0))
	var naive_pp_bp := _naive_runtime_pp_mean_bp(evidence)
	var route_bp := _route_retention_bp(evidence)
	var status_action_bp := _status_action_factor_bp(evidence)
	var active_tick_retention_bp := _active_tick_retention_bp(evidence)
	var route_action_product := hp_bp * route_bp / 10000
	route_action_product = route_action_product * status_action_bp / 10000
	return {
		"hp_only": hp_bp,
		"naive_mean_pp_blend": clampi((hp_bp * 7000 + naive_pp_bp * 3000) / 10000, 0, 10000),
		"route_retention_blend": clampi((hp_bp * 7000 + route_bp * 3000) / 10000, 0, 10000),
		"route_action_status_blend": clampi((hp_bp * 5500 + route_bp * 2500 + status_action_bp * 2000) / 10000, 0, 10000),
		"route_action_status_product": clampi(route_action_product, 0, 10000),
		"active_tick_assumption_product": clampi(route_action_product * active_tick_retention_bp / 10000, 0, 10000),
	}


func _route_retention_bp(evidence: Dictionary) -> int:
	var all_scores := evidence.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
	var available_scores := evidence.get("available_pp_sensitive_role_max_bp", {}) as Dictionary
	var total_all := 0
	var total_available := 0
	for role_id in PP_SENSITIVE_ROLE_IDS:
		var all_score := clampi(int(all_scores.get(role_id, 0)), 0, 10000)
		var available_score := clampi(int(available_scores.get(role_id, 0)), 0, all_score)
		total_all += all_score
		total_available += available_score
	if total_all <= 0:
		return 10000
	return clampi(total_available * 10000 / total_all, 0, 10000)


func _status_action_factor_bp(evidence: Dictionary) -> int:
	var status := evidence.get("persistent_status", {}) as Dictionary
	var status_id := StringName(String(status.get("status_id", "")))
	var effects := status.get("runtime_effects", {}) as Dictionary
	var all_scores := evidence.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
	match status_id:
		&"":
			return 10000
		StatusSystem.BURN:
			var physical := clampi(int(all_scores.get("physical_attacker", 0)), 0, 10000)
			var special := clampi(int(all_scores.get("special_attacker", 0)), 0, 10000)
			var dependency_den := maxi(1, maxi(physical, special))
			var physical_dependency_bp := physical * 10000 / dependency_den if physical > 0 else 0
			var physical_multiplier_bp := clampi(int(effects.get("physical_damage_multiplier_bp", 10000)), 0, 10000)
			var penalty_if_pure_physical := 10000 - physical_multiplier_bp
			return clampi(10000 - penalty_if_pure_physical * physical_dependency_bp / 10000, 0, 10000)
		StatusSystem.PARALYSIS:
			var skip_chance_bp := clampi(int(effects.get("action_skip_chance_bp", 0)), 0, 10000)
			var action_availability_bp := 10000 - skip_chance_bp
			var max_role := 0
			for role_id in PP_SENSITIVE_ROLE_IDS:
				max_role = maxi(max_role, int(all_scores.get(role_id, 0)))
			var fast_score := clampi(int(all_scores.get("fast_attacker", 0)), 0, 10000)
			var fast_dependency_bp := fast_score * 10000 / maxi(1, max_role) if fast_score > 0 else 0
			var speed_multiplier_bp := clampi(int(effects.get("speed_multiplier_bp", 10000)), 0, 10000)
			var speed_factor_bp := 10000 - (10000 - speed_multiplier_bp) * fast_dependency_bp / 10000
			return clampi(action_availability_bp * speed_factor_bp / 10000, 0, 10000)
		StatusSystem.SLEEP:
			return 0 if int(status.get("turns_remaining", 0)) > 0 else 10000
		StatusSystem.FREEZE:
			return clampi(int(effects.get("thaw_chance_bp", 0)), 0, 10000)
		StatusSystem.POISON, StatusSystem.BADLY_POISONED:
			return 10000
		_:
			return 10000


func _next_active_tick_loss_bp(evidence: Dictionary) -> int:
	var status := evidence.get("persistent_status", {}) as Dictionary
	var status_id := StringName(String(status.get("status_id", "")))
	var effects := status.get("runtime_effects", {}) as Dictionary
	var divisor := maxi(0, int(effects.get("residual_max_hp_divisor", 0)))
	if divisor <= 0:
		return 0
	if status_id == StatusSystem.BADLY_POISONED:
		var next_counter := maxi(1, int(status.get("toxic_counter", 0)) + 1)
		return clampi(next_counter * 10000 / divisor, 0, 10000)
	if status_id == StatusSystem.BURN or status_id == StatusSystem.POISON:
		return clampi(10000 / divisor, 0, 10000)
	return 0


func _active_tick_retention_bp(evidence: Dictionary) -> int:
	var hp_bp := int((evidence.get("hp", {}) as Dictionary).get("hp_ratio_bp", 0))
	if hp_bp <= 0:
		return 10000
	var loss_bp := _next_active_tick_loss_bp(evidence)
	if loss_bp <= 0:
		return 10000
	var post_tick_hp_bp := maxi(0, hp_bp - loss_bp)
	return clampi(post_tick_hp_bp * 10000 / hp_bp, 0, 10000)


func _ready_view(
	instance_id: String,
	species_id: StringName,
	stats: StatBlock,
	moves: Array[StringName],
) -> Dictionary:
	var view := _view(StringName(instance_id), species_id, stats, moves)
	for move_id in moves:
		var move := _catalog.move(move_id)
		var max_pp := maxi(1, int(move.pp)) if move != null else 1
		_set_move_pp(view, move_id, max_pp, max_pp)
	view["current_hp"] = stats.max_hp
	view["status_state"] = {
		"persistent_id": "",
		"turns_remaining": 0,
		"toxic_counter": 0,
		"volatile": {},
	}
	view["held_item_id"] = ""
	view["held_item_consumed"] = false
	return view


func _all_candidate_scores_equal(scores: Dictionary, expected: int) -> bool:
	for candidate_id in CANDIDATE_IDS:
		if int(scores.get(candidate_id, -1)) != expected:
			return false
	return true


func _scores_bounded(scores: Dictionary) -> bool:
	for candidate_id in CANDIDATE_IDS:
		var score := int(scores.get(candidate_id, -1))
		if score < 0 or score > 10000:
			return false
	return true


func _candidate_scores_componentwise_leq(a: Dictionary, b: Dictionary) -> bool:
	for candidate_id in CANDIDATE_IDS:
		if int(a.get(candidate_id, 10001)) > int(b.get(candidate_id, -1)):
			return false
	return true


func _build_comparison_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"comparison_id": COMPARISON_ID, "sample_members": 0}
	var game_data := GameData.from_dict(normalized)
	var real_catalog := game_data.to_definition_catalog()
	var species_ids: Array[StringName] = helper._lexically_sorted_species_ids(game_data.species_catalog)
	var probe: Dictionary = helper._build_probe_members(game_data, real_catalog, species_ids)
	var members: Array[Dictionary] = []
	for raw_member in probe.get("members", []):
		if raw_member is Dictionary:
			members.append(raw_member as Dictionary)

	var fixture_catalog := _catalog
	_catalog = real_catalog
	var sample_members := 0
	var naive_penalizes_but_route_preserves_cases := 0
	var burn_physical_count := 0
	var burn_special_count := 0
	var burn_physical_penalty_sum := 0
	var burn_special_penalty_sum := 0
	var poison_immediate_penalty_cases := 0
	var poison_active_tick_penalty_cases := 0
	var route_vs_naive_depletion_delta_sum := 0
	var sampled_species: Array[String] = []

	for index in range(0, members.size(), REAL_DATA_SAMPLE_STRIDE):
		var member := _real_member_with_full_pp(members[index])
		var healthy_evidence := _operational_evidence(member)
		var healthy_scores := _candidate_scores(healthy_evidence)
		if not _all_candidate_scores_equal(healthy_scores, 10000):
			_catalog = fixture_catalog
			return {"comparison_id": COMPARISON_ID, "sample_members": -1}
		sample_members += 1
		if sampled_species.size() < 12:
			sampled_species.append(String(member.get("species_id", "")))

		var move_ids := member.get("move_ids", []) as Array
		if move_ids.size() >= 2:
			var depleted := member.duplicate(true)
			_set_move_pp(depleted, StringName(String(move_ids[0])), 0, maxi(1, int((_move_evidence(healthy_evidence, String(move_ids[0])) as Dictionary).get("max_pp", 1))))
			var depleted_evidence := _operational_evidence(depleted)
			var depleted_scores := _candidate_scores(depleted_evidence)
			var naive_score := int(depleted_scores.get("naive_mean_pp_blend", 0))
			var route_score := int(depleted_scores.get("route_retention_blend", 0))
			route_vs_naive_depletion_delta_sum += route_score - naive_score
			if naive_score < 10000 and route_score == 10000:
				naive_penalizes_but_route_preserves_cases += 1

		var all_roles := healthy_evidence.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
		var physical := int(all_roles.get("physical_attacker", 0))
		var special := int(all_roles.get("special_attacker", 0))
		var burned := member.duplicate(true)
		_set_status(burned, StatusSystem.BURN, 0, 0)
		var burn_scores := _candidate_scores(_operational_evidence(burned))
		var burn_penalty := 10000 - int(burn_scores.get("route_action_status_blend", 10000))
		if physical > special:
			burn_physical_count += 1
			burn_physical_penalty_sum += burn_penalty
		elif special > physical:
			burn_special_count += 1
			burn_special_penalty_sum += burn_penalty

		var poisoned := member.duplicate(true)
		_set_status(poisoned, StatusSystem.POISON, 0, 0)
		var poison_scores := _candidate_scores(_operational_evidence(poisoned))
		if int(poison_scores.get("route_action_status_blend", -1)) < 10000:
			poison_immediate_penalty_cases += 1
		if int(poison_scores.get("active_tick_assumption_product", 10000)) < 10000:
			poison_active_tick_penalty_cases += 1

	_catalog = fixture_catalog
	return {
		"comparison_id": COMPARISON_ID,
		"candidate_ids": CANDIDATE_IDS.duplicate(),
		"sample_stride": REAL_DATA_SAMPLE_STRIDE,
		"sample_members": sample_members,
		"sampled_species_examples": sampled_species,
		"naive_penalizes_but_route_preserves_cases": naive_penalizes_but_route_preserves_cases,
		"route_minus_naive_depletion_score_delta_sum": route_vs_naive_depletion_delta_sum,
		"burn_physical_dominant_count": burn_physical_count,
		"burn_special_dominant_count": burn_special_count,
		"burn_physical_dominant_mean_penalty_bp": burn_physical_penalty_sum / maxi(1, burn_physical_count),
		"burn_special_dominant_mean_penalty_bp": burn_special_penalty_sum / maxi(1, burn_special_count),
		"poison_immediate_penalty_cases": poison_immediate_penalty_cases,
		"poison_active_tick_penalty_cases": poison_active_tick_penalty_cases,
		"attrition_candidate_requires_active_end_turn_assumption": true,
		"held_item_in_scalar": false,
		"selected_operational_readiness_formula": null,
	}


func _real_member_with_full_pp(member: Dictionary) -> Dictionary:
	var out := member.duplicate(true)
	var moveset: Array[Dictionary] = []
	for raw_move_id in out.get("move_ids", []):
		var move_id := StringName(String(raw_move_id))
		var move := _catalog.move(move_id)
		if move == null or move.classification != RUNTIME_SUPPORTED:
			continue
		var max_pp := maxi(1, int(move.pp))
		moveset.append({"move_id": String(move_id), "current_pp": max_pp, "max_pp": max_pp})
	out["moveset"] = moveset
	var stats := out.get("stats", {}) as Dictionary
	out["current_hp"] = int(stats.get("max_hp", 0))
	out["status_state"] = {
		"persistent_id": "",
		"turns_remaining": 0,
		"toxic_counter": 0,
		"volatile": {},
	}
	out["held_item_id"] = ""
	out["held_item_consumed"] = false
	return out