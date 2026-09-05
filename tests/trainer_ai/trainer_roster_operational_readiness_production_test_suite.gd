class_name TrainerRosterOperationalReadinessProductionTestSuite
extends TrainerRosterOperationalReadinessDecompositionSensitivityTestSuite

const PRODUCTION_MODEL_ID := "trainer_roster_current_operational_components_v1"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_operational_readiness_production()


func _test_operational_readiness_production() -> void:
	_enable_runtime_team_moves()
	var evaluator := TrainerRosterOperationalReadinessEvaluator.new(_catalog, _operational_ruleset)
	var full := _ready_view(
		"c3fd_full",
		TC_FIRE_A,
		StatBlock.new(100, 160, 80, 90, 80, 110),
		[TC_FIRE_PHYS, TC_SUPPORT],
	)
	full["is_active"] = true
	var full_snapshot := full.duplicate(true)
	var full_result := evaluator.evaluate_current_components([full])
	var full_component := _production_member(full_result, "c3fd_full")
	var audit_evidence := _operational_evidence(full)
	_check.call(
		"readiness_production_model_recorded",
		String(full_result.get("model_id", "")) == PRODUCTION_MODEL_ID,
	)
	_check.call(
		"readiness_production_counts_valid_members",
		int(full_result.get("member_count", -1)) == 1 and not full_component.is_empty(),
	)
	_check.call(
		"readiness_production_healthy_components_are_ceiling",
		int(full_component.get("hp_state_bp", -1)) == 10000
		and int(full_component.get("route_retention_bp", -1)) == 10000
		and int(full_component.get("immediate_status_action_bp", -1)) == 10000,
	)
	_check.call("readiness_production_does_not_mutate_input", full == full_snapshot)

	var full_route := (full_component.get("breakdown", {}) as Dictionary).get("route_retention", {}) as Dictionary
	_check.call(
		"readiness_production_c3fa_route_evidence_parity",
		full_route.get("runtime_move_pp", []) == audit_evidence.get("runtime_move_pp", [])
		and full_route.get("available_runtime_move_ids", []) == audit_evidence.get("available_runtime_move_ids", [])
		and full_route.get("depleted_runtime_move_ids", []) == audit_evidence.get("depleted_runtime_move_ids", [])
		and full_route.get("all_pp_sensitive_role_max_bp", {}) == audit_evidence.get("all_pp_sensitive_role_max_bp", {})
		and full_route.get("available_pp_sensitive_role_max_bp", {}) == audit_evidence.get("available_pp_sensitive_role_max_bp", {}),
	)
	_check.call(
		"readiness_production_c3fb_component_parity",
		int(full_component.get("hp_state_bp", -1))
		== int((audit_evidence.get("hp", {}) as Dictionary).get("hp_ratio_bp", -2))
		and int(full_component.get("route_retention_bp", -1)) == _route_retention_bp(audit_evidence)
		and int(full_component.get("immediate_status_action_bp", -1)) == _status_action_factor_bp(audit_evidence),
	)

	var hp_25 := full.duplicate(true)
	hp_25["current_hp"] = 25
	var hp_50 := full.duplicate(true)
	hp_50["current_hp"] = 50
	var hp_25_component := _production_member(evaluator.evaluate_current_components([hp_25]), "c3fd_full")
	var hp_50_component := _production_member(evaluator.evaluate_current_components([hp_50]), "c3fd_full")
	_check.call(
		"readiness_production_hp_is_monotonic",
		int(hp_25_component.get("hp_state_bp", -1)) == 2500
		and int(hp_50_component.get("hp_state_bp", -1)) == 5000
		and int(hp_25_component.get("hp_state_bp", 10001))
		< int(hp_50_component.get("hp_state_bp", -1))
		and int(hp_50_component.get("hp_state_bp", 10001))
		< int(full_component.get("hp_state_bp", -1)),
	)

	var redundant := _ready_view(
		"c3fd_redundant",
		TC_FIRE_A,
		StatBlock.new(100, 170, 80, 70, 80, 110),
		[TC_FIRE_PHYS, TC_GROUND_PHYS],
	)
	_set_move_pp(redundant, TC_FIRE_PHYS, 0, 20)
	var redundant_component := _production_member(evaluator.evaluate_current_components([redundant]), "c3fd_redundant")
	var redundant_evidence := _operational_evidence(redundant)
	_check.call(
		"readiness_production_route_aware_preserves_redundant_capability",
		int(redundant_component.get("route_retention_bp", -1)) == 10000
		and int(redundant_component.get("route_retention_bp", -1)) == _route_retention_bp(redundant_evidence),
	)
	var redundant_route := (redundant_component.get("breakdown", {}) as Dictionary).get("route_retention", {}) as Dictionary
	_check.call(
		"readiness_production_route_breakdown_keeps_depleted_route",
		(redundant_route.get("depleted_runtime_move_ids", []) as Array).has(String(TC_FIRE_PHYS))
		and (redundant_route.get("available_runtime_move_ids", []) as Array).has(String(TC_GROUND_PHYS)),
	)

	var symmetric_stats := StatBlock.new(100, 160, 80, 160, 80, 120)
	var physical_burn := _ready_view("c3fd_phys", TC_FIRE_A, symmetric_stats, [TC_FIRE_PHYS])
	var special_burn := _ready_view("c3fd_spec", TC_FIRE_A, symmetric_stats, [TC_FIRE_SPEC])
	_set_status(physical_burn, StatusSystem.BURN, 0, 0)
	_set_status(special_burn, StatusSystem.BURN, 0, 0)
	var physical_component := _production_member(evaluator.evaluate_current_components([physical_burn]), "c3fd_phys")
	var special_component := _production_member(evaluator.evaluate_current_components([special_burn]), "c3fd_spec")
	_check.call(
		"readiness_production_burn_is_role_dependent",
		int(physical_component.get("immediate_status_action_bp", 10000))
		< int(special_component.get("immediate_status_action_bp", 0))
		and int(physical_component.get("immediate_status_action_bp", -1))
		== _status_action_factor_bp(_operational_evidence(physical_burn))
		and int(special_component.get("immediate_status_action_bp", -1))
		== _status_action_factor_bp(_operational_evidence(special_burn)),
	)

	var fast := _ready_view(
		"c3fd_fast",
		TC_ELECTRIC,
		StatBlock.new(100, 130, 80, 200, 70, 80),
		[TC_ELECTRIC_PHYS],
	)
	var slow := _ready_view(
		"c3fd_slow",
		TC_ELECTRIC,
		StatBlock.new(100, 130, 80, 45, 70, 80),
		[TC_ELECTRIC_PHYS],
	)
	_set_status(fast, StatusSystem.PARALYSIS, 0, 0)
	_set_status(slow, StatusSystem.PARALYSIS, 0, 0)
	var fast_component := _production_member(evaluator.evaluate_current_components([fast]), "c3fd_fast")
	var slow_component := _production_member(evaluator.evaluate_current_components([slow]), "c3fd_slow")
	_check.call(
		"readiness_production_paralysis_depends_on_speed_role",
		int(fast_component.get("immediate_status_action_bp", 10000))
		< int(slow_component.get("immediate_status_action_bp", 0))
		and int(fast_component.get("immediate_status_action_bp", -1))
		== _status_action_factor_bp(_operational_evidence(fast))
		and int(slow_component.get("immediate_status_action_bp", -1))
		== _status_action_factor_bp(_operational_evidence(slow)),
	)

	var sleep := full.duplicate(true)
	_set_status(sleep, StatusSystem.SLEEP, 2, 0)
	var freeze := full.duplicate(true)
	_set_status(freeze, StatusSystem.FREEZE, 0, 0)
	var sleep_component := _production_member(evaluator.evaluate_current_components([sleep]), "c3fd_full")
	var freeze_component := _production_member(evaluator.evaluate_current_components([freeze]), "c3fd_full")
	_check.call(
		"readiness_production_sleep_blocks_current_action",
		int(sleep_component.get("immediate_status_action_bp", -1)) == 0,
	)
	_check.call(
		"readiness_production_freeze_matches_runtime_thaw_chance",
		int(freeze_component.get("immediate_status_action_bp", -1))
		== _operational_ruleset.freeze_thaw_chance_basis_points,
	)

	var poison := full.duplicate(true)
	poison["is_active"] = true
	_set_status(poison, StatusSystem.POISON, 0, 0)
	var toxic := full.duplicate(true)
	toxic["is_active"] = true
	_set_status(toxic, StatusSystem.BADLY_POISONED, 0, 3)
	var poison_component := _production_member(evaluator.evaluate_current_components([poison]), "c3fd_full")
	var toxic_component := _production_member(evaluator.evaluate_current_components([toxic]), "c3fd_full")
	var poison_attrition := poison_component.get("attrition", {}) as Dictionary
	var toxic_attrition := toxic_component.get("attrition", {}) as Dictionary
	_check.call(
		"readiness_production_poison_is_attrition_not_immediate_action_loss",
		int(poison_component.get("immediate_status_action_bp", -1)) == 10000
		and int(poison_attrition.get("next_active_tick_loss_max_hp_bp", 0)) > 0
		and int(poison_attrition.get("next_active_tick_loss_max_hp_bp", -1))
		== _next_active_tick_loss_bp(_operational_evidence(poison)),
	)
	_check.call(
		"readiness_production_toxic_advances_next_tick_counter",
		int(toxic_attrition.get("toxic_counter_before", -1)) == 3
		and int(toxic_attrition.get("toxic_counter_for_next_tick", -1)) == 4
		and int(toxic_attrition.get("next_active_tick_loss_max_hp_bp", 0))
		> int(poison_attrition.get("next_active_tick_loss_max_hp_bp", 10000)),
	)
	_check.call(
		"readiness_production_attrition_integer_damage_matches_runtime",
		int(poison_attrition.get("next_active_tick_raw_damage_hp", -1))
		== maxi(1, 100 / _operational_ruleset.poison_max_hp_divisor)
		and int(toxic_attrition.get("next_active_tick_raw_damage_hp", -1))
		== maxi(1, 100 * 4 / _operational_ruleset.badly_poisoned_max_hp_divisor)
		and bool(poison_attrition.get("next_active_tick_applies_now", false))
		and bool(toxic_attrition.get("next_active_tick_applies_now", false)),
	)
	var low_poison := poison.duplicate(true)
	low_poison["current_hp"] = 5
	var low_poison_attrition := (
		_production_member(evaluator.evaluate_current_components([low_poison]), "c3fd_full").get("attrition", {})
		as Dictionary
	)
	_check.call(
		"readiness_production_attrition_applied_damage_caps_at_current_hp",
		int(low_poison_attrition.get("next_active_tick_raw_damage_hp", 0)) > 5
		and int(low_poison_attrition.get("next_active_tick_applied_damage_hp", -1)) == 5,
	)

	var item_ready := full.duplicate(true)
	item_ready["held_item_id"] = "c3fd_item"
	item_ready["held_item_consumed"] = false
	var item_consumed := item_ready.duplicate(true)
	item_consumed["held_item_consumed"] = true
	var ready_component := _production_member(evaluator.evaluate_current_components([item_ready]), "c3fd_full")
	var consumed_component := _production_member(evaluator.evaluate_current_components([item_consumed]), "c3fd_full")
	_check.call(
		"readiness_production_held_item_is_evidence_only",
		_numeric_signature(ready_component) == _numeric_signature(consumed_component)
		and ready_component.get("attrition", {}) == consumed_component.get("attrition", {}),
	)
	_check.call(
		"readiness_production_held_item_availability_is_explicit",
		bool((ready_component.get("held_item", {}) as Dictionary).get("available", false))
		and not bool((consumed_component.get("held_item", {}) as Dictionary).get("available", true))
		and String(ready_component.get("held_item_id", "")) == "c3fd_item"
		and bool(consumed_component.get("held_item_consumed", false)),
	)

	var transients := full.duplicate(true)
	transients["stat_stages"] = {"attack": 6, "speed": -6}
	var transient_status := transients.get("status_state", {}) as Dictionary
	transient_status["volatile"] = {"confusion": {"turns": 3}, "flinch": true}
	transients["status_state"] = transient_status
	var transient_component := _production_member(evaluator.evaluate_current_components([transients]), "c3fd_full")
	_check.call(
		"readiness_production_transients_do_not_change_output",
		transient_component == full_component,
	)
	_check.call(
		"readiness_production_transient_exclusions_are_auditable",
		(transient_component.get("excluded_transient_fields", []) as Array).has("stat_stages")
		and (transient_component.get("excluded_transient_fields", []) as Array).has("status_state.volatile"),
	)

	var ko := poison.duplicate(true)
	ko["current_hp"] = 0
	ko["is_active"] = true
	var ko_component := _production_member(evaluator.evaluate_current_components([ko]), "c3fd_full")
	var ko_attrition := ko_component.get("attrition", {}) as Dictionary
	_check.call(
		"readiness_production_knocked_out_member_is_retained",
		bool(ko_component.get("is_knocked_out", false))
		and int(ko_component.get("hp_state_bp", -1)) == 0
		and bool(ko_attrition.get("next_active_tick_formula_defined", false))
		and not bool(ko_attrition.get("next_active_tick_applies_now", true))
		and int(ko_attrition.get("next_active_tick_applied_damage_hp", -1)) == 0,
	)

	var bench_poison := poison.duplicate(true)
	bench_poison["is_active"] = false
	var bench_attrition := (
		_production_member(evaluator.evaluate_current_components([bench_poison]), "c3fd_full").get("attrition", {})
		as Dictionary
	)
	_check.call(
		"readiness_production_attrition_distinguishes_active_from_bench",
		bool(bench_attrition.get("next_active_tick_formula_defined", false))
		and not bool(bench_attrition.get("next_active_tick_applies_now", true)),
	)

	var external_noise := full.duplicate(true)
	external_noise["opponent"] = {"hidden": true}
	external_noise["rival"] = {"memory": 1}
	external_noise["belief"] = {"secret": 1}
	external_noise["profile"] = {"preservation": 9999}
	external_noise["rng"] = 12345
	external_noise["campaign_snapshot"] = {"future_bracket": ["x"]}
	var noisy_component := _production_member(evaluator.evaluate_current_components([external_noise]), "c3fd_full")
	_check.call(
		"readiness_production_ignores_external_policy_and_hidden_context",
		noisy_component == full_component,
	)

	var invalid_result := evaluator.evaluate_current_components([42, {}, full])
	_check.call(
		"readiness_production_invalid_members_fail_closed",
		int(invalid_result.get("member_count", -1)) == 1
		and (invalid_result.get("skipped_invalid_member_indices", []) as Array) == [0, 1],
	)
	var null_result := TrainerRosterOperationalReadinessEvaluator.new(null).evaluate_current_components([full])
	_check.call(
		"readiness_production_null_catalog_fails_closed",
		String(null_result.get("model_id", "")) == PRODUCTION_MODEL_ID
		and int(null_result.get("member_count", -1)) == 0
		and (null_result.get("member_components", []) as Array).is_empty(),
	)

	var repeat := evaluator.evaluate_current_components([full, poison, toxic])
	var repeat_again := evaluator.evaluate_current_components([full, poison, toxic])
	_check.call("readiness_production_is_deterministic", repeat == repeat_again)
	var parsed: Variant = JSON.parse_string(JSON.stringify(repeat))
	_check.call("readiness_production_is_json_serializable", parsed is Dictionary)
	_check.call(
		"readiness_production_does_not_expose_blocked_scalar_or_policy",
		not _contains_forbidden_key(repeat),
	)


func _production_member(result: Dictionary, instance_id: String) -> Dictionary:
	for raw_member in result.get("member_components", []):
		if not (raw_member is Dictionary):
			continue
		var member := raw_member as Dictionary
		if String(member.get("instance_id", "")) == instance_id:
			return member
	return {}


func _numeric_signature(component: Dictionary) -> Dictionary:
	return {
		"hp_state_bp": int(component.get("hp_state_bp", -1)),
		"route_retention_bp": int(component.get("route_retention_bp", -1)),
		"immediate_status_action_bp": int(component.get("immediate_status_action_bp", -1)),
	}


func _contains_forbidden_key(value: Variant) -> bool:
	var forbidden := {
		"operational_readiness_bp": true,
		"permadeath_loss_cost_bp": true,
		"between_battle_recovery_policy": true,
		"replacement_policy": true,
		"campaign_snapshot": true,
		"opponent": true,
		"rival": true,
		"belief": true,
		"profile": true,
		"rng": true,
		"blend_weights": true,
		"product_score": true,
		"post_recovery_readiness_bp": true,
	}
	if value is Dictionary:
		for raw_key in (value as Dictionary).keys():
			var key := String(raw_key)
			if forbidden.has(key):
				return true
			if _contains_forbidden_key((value as Dictionary).get(raw_key)):
				return true
	elif value is Array:
		for item in value as Array:
			if _contains_forbidden_key(item):
				return true
	return false
