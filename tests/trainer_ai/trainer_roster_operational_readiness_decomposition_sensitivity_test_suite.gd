class_name TrainerRosterOperationalReadinessDecompositionSensitivityTestSuite
extends TrainerRosterOperationalReadinessFormulaComparisonTestSuite

const SENSITIVITY_ID := "c3f_c_current_readiness_decomposition_sensitivity_v1"
const REAL_DATA_SAMPLE_STRIDE_C3FC := 8
const COMPONENT_VALUES := [0, 2500, 5000, 7500, 10000]
const BLEND_VARIANTS := {
	"hp_heavy_60_20_20": {"hp": 6000, "route": 2000, "status": 2000},
	"baseline_55_25_20": {"hp": 5500, "route": 2500, "status": 2000},
	"route_heavy_45_35_20": {"hp": 4500, "route": 3500, "status": 2000},
	"status_heavy_45_25_30": {"hp": 4500, "route": 2500, "status": 3000},
	"capability_heavy_40_30_30": {"hp": 4000, "route": 3000, "status": 3000},
}


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_readiness_decomposition_sensitivity()


func _test_readiness_decomposition_sensitivity() -> void:
	_enable_runtime_team_moves()
	_check.call(
		"readiness_decomposition_sensitivity_id_recorded",
		SENSITIVITY_ID == "c3f_c_current_readiness_decomposition_sensitivity_v1",
	)
	_check.call("readiness_decomposition_has_five_blend_variants", BLEND_VARIANTS.size() == 5)
	_check.call("readiness_decomposition_blend_weights_are_normalized", _all_blend_weights_normalized())

	var ranking_a := _components_from_values(4000, 10000, 10000, 0)
	var ranking_b := _components_from_values(8000, 6000, 6000, 0)
	var hp_heavy_a := _blend_score(ranking_a, BLEND_VARIANTS["hp_heavy_60_20_20"] as Dictionary)
	var hp_heavy_b := _blend_score(ranking_b, BLEND_VARIANTS["hp_heavy_60_20_20"] as Dictionary)
	var capability_a := _blend_score(ranking_a, BLEND_VARIANTS["capability_heavy_40_30_30"] as Dictionary)
	var capability_b := _blend_score(ranking_b, BLEND_VARIANTS["capability_heavy_40_30_30"] as Dictionary)
	_check.call(
		"readiness_decomposition_reasonable_weights_can_reverse_ranking",
		hp_heavy_a == 6400
		and hp_heavy_b == 7200
		and capability_a == 7600
		and capability_b == 6800
		and hp_heavy_b > hp_heavy_a
		and capability_a > capability_b,
	)

	var blend_collision_a := _components_from_values(10000, 10000, 0, 0)
	var blend_collision_b := _components_from_values(10000, 2000, 10000, 0)
	var baseline_weights := BLEND_VARIANTS["baseline_55_25_20"] as Dictionary
	_check.call(
		"readiness_decomposition_blend_has_semantic_collision",
		_blend_score(blend_collision_a, baseline_weights) == 8000
		and _blend_score(blend_collision_b, baseline_weights) == 8000
		and _immediate_tuple(blend_collision_a) != _immediate_tuple(blend_collision_b),
	)

	var product_collision_a := _components_from_values(5000, 10000, 10000, 0)
	var product_collision_b := _components_from_values(10000, 5000, 10000, 0)
	_check.call(
		"readiness_decomposition_product_has_semantic_collision",
		_product_score(product_collision_a) == 5000
		and _product_score(product_collision_b) == 5000
		and _immediate_tuple(product_collision_a) != _immediate_tuple(product_collision_b),
	)

	var zero_status := _components_from_values(10000, 10000, 0, 0)
	var zero_route := _components_from_values(10000, 0, 10000, 0)
	var zero_hp := _components_from_values(0, 10000, 10000, 0)
	_check.call(
		"readiness_decomposition_zero_component_exposes_blend_product_disagreement",
		_blend_score(zero_status, baseline_weights) == 8000
		and _blend_score(zero_route, baseline_weights) == 7500
		and _blend_score(zero_hp, baseline_weights) == 4500
		and _product_score(zero_status) == 0
		and _product_score(zero_route) == 0
		and _product_score(zero_hp) == 0,
	)

	_check.call(
		"readiness_decomposition_all_aggregates_componentwise_monotonic",
		_all_aggregates_componentwise_monotonic(),
	)

	var healthy := _ready_view(
		"c3fc_healthy",
		TC_FIRE_A,
		StatBlock.new(100, 160, 80, 90, 80, 110),
		[TC_FIRE_PHYS, TC_SUPPORT],
	)
	var healthy_evidence := _operational_evidence(healthy)
	var healthy_components := _component_vector(healthy_evidence)

	var low_hp := healthy.duplicate(true)
	low_hp["current_hp"] = 40
	var low_hp_components := _component_vector(_operational_evidence(low_hp))
	_check.call(
		"readiness_decomposition_healing_hp_is_monotonic",
		int(low_hp_components.get("hp_state_bp", -1)) < int(healthy_components.get("hp_state_bp", -2))
		and _all_aggregate_scores_leq(low_hp_components, healthy_components),
	)

	var depleted := healthy.duplicate(true)
	_set_move_pp(depleted, TC_FIRE_PHYS, 0, 20)
	var depleted_components := _component_vector(_operational_evidence(depleted))
	_check.call(
		"readiness_decomposition_restoring_pp_is_monotonic",
		int(depleted_components.get("route_retention_bp", -1)) < int(healthy_components.get("route_retention_bp", -2))
		and _all_aggregate_scores_leq(depleted_components, healthy_components),
	)

	var burned := healthy.duplicate(true)
	_set_status(burned, StatusSystem.BURN, 0, 0)
	var burned_components := _component_vector(_operational_evidence(burned))
	_check.call(
		"readiness_decomposition_curing_status_is_monotonic",
		int(burned_components.get("immediate_status_action_bp", -1))
		< int(healthy_components.get("immediate_status_action_bp", -2))
		and _all_aggregate_scores_leq(burned_components, healthy_components),
	)

	var sleeping := healthy.duplicate(true)
	_set_status(sleeping, StatusSystem.SLEEP, 2, 0)
	var sleeping_components := _component_vector(_operational_evidence(sleeping))
	_check.call(
		"readiness_decomposition_sleep_keeps_nonzero_asset_components_visible",
		int(sleeping_components.get("hp_state_bp", 0)) == 10000
		and int(sleeping_components.get("route_retention_bp", 0)) == 10000
		and int(sleeping_components.get("immediate_status_action_bp", -1)) == 0
		and _blend_score(sleeping_components, baseline_weights) == 8000
		and _product_score(sleeping_components) == 0,
	)

	var poisoned := healthy.duplicate(true)
	_set_status(poisoned, StatusSystem.POISON, 0, 0)
	var poison_components := _component_vector(_operational_evidence(poisoned))
	_check.call(
		"readiness_decomposition_attrition_is_separate_from_immediate_tuple",
		_immediate_tuple(poison_components) == _immediate_tuple(healthy_components)
		and int(healthy_components.get("attrition_pressure_bp", -1)) == 0
		and int(poison_components.get("attrition_pressure_bp", 0)) > 0,
	)

	var item_ready := healthy.duplicate(true)
	item_ready["held_item_id"] = "c3fc_item"
	item_ready["held_item_consumed"] = false
	var item_consumed := item_ready.duplicate(true)
	item_consumed["held_item_consumed"] = true
	_check.call(
		"readiness_decomposition_held_item_remains_outside_components",
		_component_vector(_operational_evidence(item_ready))
		== _component_vector(_operational_evidence(item_consumed)),
	)

	var report_a := _build_c3fc_real_data_report()
	var report_b := _build_c3fc_real_data_report()
	_check.call("readiness_decomposition_real_data_report_deterministic", report_a == report_b)
	_check.call("readiness_decomposition_real_data_report_json_serializable", not JSON.stringify(report_a).is_empty())
	_check.call(
		"readiness_decomposition_real_data_sample_expected",
		int(report_a.get("sample_members", -1)) == 128,
	)
	_check.call(
		"readiness_decomposition_real_data_has_component_diversity",
		int(report_a.get("distinct_immediate_component_vectors", 0)) > 8,
	)
	_check.call(
		"readiness_decomposition_real_data_aggregates_are_not_equivalent",
		int(report_a.get("aggregate_mean_spread_bp", 0)) > 0,
	)
	_check.call(
		"readiness_decomposition_real_data_preserves_unselected_scalar",
		report_a.has("selected_operational_readiness_formula")
		and report_a.get("selected_operational_readiness_formula") == null
		and String(report_a.get("recommended_interface", "")) == "decomposed_components_first"
		and not report_a.has("production_operational_readiness_bp"),
	)

	print("\n=== TRAINER ROSTER CURRENT READINESS DECOMPOSITION SENSITIVITY ===")
	print(JSON.stringify(report_a))


func _component_vector(evidence: Dictionary) -> Dictionary:
	return {
		"hp_state_bp": clampi(int((evidence.get("hp", {}) as Dictionary).get("hp_ratio_bp", 0)), 0, 10000),
		"route_retention_bp": clampi(_route_retention_bp(evidence), 0, 10000),
		"immediate_status_action_bp": clampi(_status_action_factor_bp(evidence), 0, 10000),
		"attrition_pressure_bp": clampi(_next_active_tick_loss_bp(evidence), 0, 10000),
	}


func _components_from_values(hp_bp: int, route_bp: int, status_bp: int, attrition_bp: int) -> Dictionary:
	return {
		"hp_state_bp": clampi(hp_bp, 0, 10000),
		"route_retention_bp": clampi(route_bp, 0, 10000),
		"immediate_status_action_bp": clampi(status_bp, 0, 10000),
		"attrition_pressure_bp": clampi(attrition_bp, 0, 10000),
	}


func _immediate_tuple(components: Dictionary) -> Array[int]:
	return [
		int(components.get("hp_state_bp", 0)),
		int(components.get("route_retention_bp", 0)),
		int(components.get("immediate_status_action_bp", 0)),
	]


func _blend_score(components: Dictionary, weights: Dictionary) -> int:
	var hp_bp := clampi(int(components.get("hp_state_bp", 0)), 0, 10000)
	var route_bp := clampi(int(components.get("route_retention_bp", 0)), 0, 10000)
	var status_bp := clampi(int(components.get("immediate_status_action_bp", 0)), 0, 10000)
	return clampi(
		(
			hp_bp * int(weights.get("hp", 0))
			+ route_bp * int(weights.get("route", 0))
			+ status_bp * int(weights.get("status", 0))
		) / 10000,
		0,
		10000,
	)


func _product_score(components: Dictionary) -> int:
	var score := clampi(int(components.get("hp_state_bp", 0)), 0, 10000)
	score = score * clampi(int(components.get("route_retention_bp", 0)), 0, 10000) / 10000
	score = score * clampi(int(components.get("immediate_status_action_bp", 0)), 0, 10000) / 10000
	return clampi(score, 0, 10000)


func _all_blend_weights_normalized() -> bool:
	for raw_weights in BLEND_VARIANTS.values():
		var weights := raw_weights as Dictionary
		if int(weights.get("hp", 0)) + int(weights.get("route", 0)) + int(weights.get("status", 0)) != 10000:
			return false
	return true


func _all_aggregates_componentwise_monotonic() -> bool:
	for dimension in ["hp_state_bp", "route_retention_bp", "immediate_status_action_bp"]:
		for base_a in COMPONENT_VALUES:
			for base_b in COMPONENT_VALUES:
				var fixed := _components_from_values(int(base_a), int(base_b), int(base_b), 0)
				var previous_blends: Dictionary = {}
				var previous_product := -1
				for raw_value in COMPONENT_VALUES:
					var current := fixed.duplicate(true)
					current[dimension] = int(raw_value)
					for variant_id in BLEND_VARIANTS.keys():
						var current_score := _blend_score(current, BLEND_VARIANTS[variant_id] as Dictionary)
						if previous_blends.has(variant_id) and current_score < int(previous_blends[variant_id]):
							return false
						previous_blends[variant_id] = current_score
					var current_product := _product_score(current)
					if previous_product >= 0 and current_product < previous_product:
						return false
					previous_product = current_product
	return true


func _all_aggregate_scores_leq(a: Dictionary, b: Dictionary) -> bool:
	for variant_id in BLEND_VARIANTS.keys():
		if _blend_score(a, BLEND_VARIANTS[variant_id] as Dictionary) > _blend_score(b, BLEND_VARIANTS[variant_id] as Dictionary):
			return false
	return _product_score(a) <= _product_score(b)


func _build_c3fc_real_data_report() -> Dictionary:
	var helper := TrainerRosterStructuralRealDataAuditTestSuite.new()
	var normalized: Dictionary = helper._load_json(TrainerRosterStructuralRealDataAuditTestSuite.DATA_PATH)
	if normalized.is_empty():
		return {"sensitivity_id": SENSITIVITY_ID, "sample_members": 0}
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
	var component_signatures: Dictionary = {}
	var aggregate_sums: Dictionary = {"product": 0}
	var aggregate_mins: Dictionary = {"product": 10001}
	var aggregate_maxs: Dictionary = {"product": -1}
	for variant_id in BLEND_VARIANTS.keys():
		aggregate_sums[variant_id] = 0
		aggregate_mins[variant_id] = 10001
		aggregate_maxs[variant_id] = -1

	var hp_cycle := [2500, 5000, 7500, 10000]
	for index in range(0, members.size(), REAL_DATA_SAMPLE_STRIDE_C3FC):
		var member := _real_member_with_full_pp(members[index])
		var stats := member.get("stats", {}) as Dictionary
		var max_hp := maxi(1, int(stats.get("max_hp", 1)))
		var target_hp_bp := int(hp_cycle[sample_members % hp_cycle.size()])
		member["current_hp"] = maxi(1, max_hp * target_hp_bp / 10000)

		var move_ids := member.get("move_ids", []) as Array
		if sample_members % 2 == 0 and not move_ids.is_empty():
			var first_move_id := StringName(String(move_ids[0]))
			var move := real_catalog.move(first_move_id)
			if move != null:
				_set_move_pp(member, first_move_id, 0, maxi(1, int(move.pp)))

		match sample_members % 3:
			0:
				_set_status(member, StatusSystem.BURN, 0, 0)
			1:
				_set_status(member, StatusSystem.PARALYSIS, 0, 0)
			_:
				_set_status(member, &"", 0, 0)

		var components := _component_vector(_operational_evidence(member))
		component_signatures[JSON.stringify(_immediate_tuple(components))] = true
		for variant_id in BLEND_VARIANTS.keys():
			var score := _blend_score(components, BLEND_VARIANTS[variant_id] as Dictionary)
			aggregate_sums[variant_id] = int(aggregate_sums[variant_id]) + score
			aggregate_mins[variant_id] = mini(int(aggregate_mins[variant_id]), score)
			aggregate_maxs[variant_id] = maxi(int(aggregate_maxs[variant_id]), score)
		var product_score := _product_score(components)
		aggregate_sums["product"] = int(aggregate_sums["product"]) + product_score
		aggregate_mins["product"] = mini(int(aggregate_mins["product"]), product_score)
		aggregate_maxs["product"] = maxi(int(aggregate_maxs["product"]), product_score)
		sample_members += 1

	_catalog = fixture_catalog
	var aggregate_means: Dictionary = {}
	var min_mean := 10001
	var max_mean := -1
	for aggregate_id in aggregate_sums.keys():
		var mean_score := int(aggregate_sums[aggregate_id]) / maxi(1, sample_members)
		aggregate_means[aggregate_id] = mean_score
		min_mean = mini(min_mean, mean_score)
		max_mean = maxi(max_mean, mean_score)

	return {
		"sensitivity_id": SENSITIVITY_ID,
		"sample_stride": REAL_DATA_SAMPLE_STRIDE_C3FC,
		"sample_members": sample_members,
		"distinct_immediate_component_vectors": component_signatures.size(),
		"aggregate_means_bp": aggregate_means,
		"aggregate_mins_bp": aggregate_mins,
		"aggregate_maxs_bp": aggregate_maxs,
		"aggregate_mean_spread_bp": maxi(0, max_mean - min_mean),
		"synthetic_weight_ranking_reversal_proven": true,
		"blend_semantic_collision_proven": true,
		"product_semantic_collision_proven": true,
		"attrition_kept_separate": true,
		"held_item_in_components": false,
		"recommended_interface": "decomposed_components_first",
		"selected_operational_readiness_formula": null,
	}
