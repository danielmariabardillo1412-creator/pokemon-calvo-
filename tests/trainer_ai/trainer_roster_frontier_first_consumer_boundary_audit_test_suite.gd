class_name TrainerRosterFrontierFirstConsumerBoundaryAuditTestSuite
extends TrainerRosterParetoFrontierConsumptionAuditTestSuite

# C3f-l is deliberately test/audit-only. It audits the boundary between the
# rival-agnostic component-first Pareto frontier and the first plausible
# behavioral consumer, strategic switching. It must not change production
# behavior or authorize pruning/selection.

const AUDIT_ID_C3FL := "c3f_l_first_behavior_consumer_boundary_audit_v1"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_switching_consumer_boundary()


func _test_switching_consumer_boundary() -> void:
	var report_a := _build_c3fl_report()
	var report_b := _build_c3fl_report()

	_check.call(
		"frontier_consumer_boundary_audit_id_recorded",
		String(report_a.get("audit_id", "")) == AUDIT_ID_C3FL,
	)
	_check.call(
		"frontier_consumer_boundary_targets_existing_switching_model",
		String(report_a.get("candidate_consumer_model_id", "")) == TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
	)
	_check.call(
		"frontier_consumer_boundary_uses_certified_frontier_model",
		String(report_a.get("frontier_model_id", "")) == TrainerRosterParetoFrontier.MODEL_ID,
	)
	_check.call(
		"frontier_consumer_boundary_has_single_component_first_frontier_member",
		int(report_a.get("frontier_count", -1)) == 1
		and (report_a.get("frontier_instance_ids", []) as Array) == ["frontier_water"],
	)
	_check.call(
		"frontier_consumer_boundary_counter_is_component_first_dominated",
		(report_a.get("dominated_instance_ids", []) as Array).has("dominated_grass"),
	)
	_check.call(
		"frontier_consumer_boundary_dominated_counter_has_better_matchup_offense",
		int(report_a.get("dominated_counter_offense_bp", -1))
		> int(report_a.get("frontier_member_offense_bp", -1)),
	)
	_check.call(
		"frontier_consumer_boundary_dominated_counter_has_lower_public_threat",
		int(report_a.get("dominated_counter_public_threat_bp", 999999))
		< int(report_a.get("frontier_member_public_threat_bp", -1)),
	)
	_check.call(
		"frontier_consumer_boundary_dominated_counter_outscores_frontier_member",
		bool(report_a.get("dominated_counter_outscores_frontier_member", false)),
	)
	_check.call(
		"frontier_consumer_boundary_hard_pruning_is_not_safe_for_switching",
		not bool(report_a.get("hard_frontier_pruning_safe_for_switching", true))
		and not bool(report_a.get("frontier_selection_authorized", true))
		and not bool(report_a.get("frontier_score_bonus_authorized", true)),
	)
	_check.call(
		"frontier_consumer_boundary_keeps_behavior_integration_unauthorized",
		not bool(report_a.get("behavior_integration_authorized", true)),
	)
	_check.call(
		"frontier_consumer_boundary_recommends_context_before_pruning",
		String(report_a.get("required_ordering", ""))
		== "legal_and_contextual_switch_evidence_before_any_nonbinding_frontier_use",
	)
	_check.call("frontier_consumer_boundary_report_deterministic", report_a == report_b)
	_check.call(
		"frontier_consumer_boundary_report_json_serializable",
		JSON.parse_string(JSON.stringify(report_a)) is Dictionary,
	)

	print("\n=== TRAINER ROSTER FRONTIER FIRST CONSUMER BOUNDARY AUDIT ===")
	print(JSON.stringify(report_a))


func _build_c3fl_report() -> Dictionary:
	# Reuse the already-certified FASE31 fixture catalog only as a test harness.
	# Its inherited builder emits three fixture assertions, so provide a no-op
	# callback before invoking it. No production class is modified and no
	# switching code receives frontier data.
	var switch_fixture := TrainerStrategicSwitchingV2TestSuite.new()
	switch_fixture._check = Callable(self, "_ignore_fixture_check")
	switch_fixture._build_catalog()
	var catalog: DefinitionCatalog = switch_fixture._catalog

	var active_moves: Array[StringName] = [&"sw_chip"]
	var water_moves: Array[StringName] = [&"sw_water_strike"]
	var grass_moves: Array[StringName] = [&"sw_grass_strike"]
	var foe_moves: Array[StringName] = [&"sw_water_strike"]

	var active: CreatureInstance = switch_fixture._mon(
		&"boundary_active",
		&"sw_normal_mon",
		active_moves,
		100,
		70,
		55,
		60,
	)
	var frontier_water: CreatureInstance = switch_fixture._mon(
		&"frontier_water",
		&"sw_water_mon",
		water_moves,
		100,
		110,
		60,
		80,
	)
	var dominated_grass: CreatureInstance = switch_fixture._mon(
		&"dominated_grass",
		&"sw_grass_mon",
		grass_moves,
		100,
		120,
		120,
		80,
	)
	var foe: CreatureInstance = switch_fixture._mon(
		&"boundary_foe",
		&"sw_water_mon",
		foe_moves,
		120,
		125,
		90,
		75,
	)

	var server: AuthoritativeBattleServer = switch_fixture._server_from_parties(
		[active, frontier_water, dominated_grass],
		[foe],
	)
	var brain := StrategicSwitchingTrainerBrain.new(
		catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)
	var controller := TrainerIntelligenceController.new(&"side_a", brain, catalog)
	var begin_ok := controller.begin(server)
	controller.memory.reveal_move(&"boundary_foe", &"sw_water_strike")
	controller.belief.sync_revealed(controller.memory)
	var chosen_action := controller.choose_action(server)
	var context := controller.last_context

	var water_action: BattleAction = switch_fixture._find_switch(context, &"frontier_water")
	var grass_action: BattleAction = switch_fixture._find_switch(context, &"dominated_grass")
	var switch_evaluator := TrainerStrategicSwitchEvaluatorV2.new(catalog, TrainerProfile.balanced())
	var water_eval := switch_evaluator.evaluate(context, water_action)
	var grass_eval := switch_evaluator.evaluate(context, grass_action)
	var water_metadata := water_eval.get("metadata", {}) as Dictionary
	var grass_metadata := grass_eval.get("metadata", {}) as Dictionary

	# This is a valid component-first shape in which water dominates grass in all
	# four frontier dimensions. The tactical opponent is intentionally absent from
	# the contract, exactly as required by C3f-k.
	var contract := {
		"model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"structural_model_id": "c3fl_synthetic_structural_v1",
		"structural_formula_id": "c3fl_synthetic_formula_v1",
		"operational_model_id": "c3fl_synthetic_operational_v1",
		"member_count": 3,
		"member_states": [
			_c3fl_member_state("boundary_active", "sw_normal_mon", 5000, 5000, 5000, 5000, true),
			_c3fl_member_state("frontier_water", "sw_water_mon", 9000, 9000, 9000, 9000, false),
			_c3fl_member_state("dominated_grass", "sw_grass_mon", 7000, 7000, 7000, 7000, false),
		],
	}
	var frontier := TrainerRosterParetoFrontier.new().evaluate(contract)
	var frontier_ids := frontier.get("frontier_instance_ids", []) as Array
	var dominated_ids := frontier.get("dominated_instance_ids", []) as Array
	var water_score := int(water_eval.get("score", 0))
	var grass_score := int(grass_eval.get("score", 0))

	return {
		"audit_id": AUDIT_ID_C3FL,
		"candidate_consumer": "strategic_switching",
		"candidate_consumer_model_id": TrainerStrategicSwitchEvaluatorV2.MODEL_ID,
		"frontier_model_id": TrainerRosterParetoFrontier.MODEL_ID,
		"source_contract_model_id": TrainerRosterComponentFirstContract.MODEL_ID,
		"controller_begin_ok": begin_ok,
		"controller_produced_action": chosen_action != null,
		"switch_actions_available": water_action != null and grass_action != null,
		"frontier_count": int(frontier.get("frontier_count", -1)),
		"frontier_instance_ids": frontier_ids.duplicate(),
		"dominated_instance_ids": dominated_ids.duplicate(),
		"frontier_member_switch_score": water_score,
		"dominated_counter_switch_score": grass_score,
		"frontier_member_offense_bp": int(water_metadata.get("incoming_offense_damage_basis_points", 0)),
		"dominated_counter_offense_bp": int(grass_metadata.get("incoming_offense_damage_basis_points", 0)),
		"frontier_member_public_threat_bp": int(water_metadata.get("incoming_public_threat_damage_basis_points", 0)),
		"dominated_counter_public_threat_bp": int(grass_metadata.get("incoming_public_threat_damage_basis_points", 0)),
		"dominated_counter_outscores_frontier_member": grass_score > water_score,
		"hard_frontier_pruning_safe_for_switching": false,
		"frontier_selection_authorized": false,
		"frontier_score_bonus_authorized": false,
		"behavior_integration_authorized": false,
		"required_ordering": "legal_and_contextual_switch_evidence_before_any_nonbinding_frontier_use",
		"safe_interpretation": "frontier_is_roster_state_evidence_not_a_switch_candidate_filter",
	}


func _c3fl_member_state(
	instance_id: String,
	species_id: String,
	structural_value_bp: int,
	hp_state_bp: int,
	route_retention_bp: int,
	immediate_status_action_bp: int,
	is_active: bool,
) -> Dictionary:
	return {
		"instance_id": instance_id,
		"species_id": species_id,
		"availability_state": "surviving",
		"structural": {
			"available": true,
			"model_id": "c3fl_synthetic_structural_v1",
			"formula_id": "c3fl_synthetic_formula_v1",
			"species_id": species_id,
			"structural_value_bp": structural_value_bp,
			"breakdown": {},
		},
		"operational": {
			"available": true,
			"model_id": "c3fl_synthetic_operational_v1",
			"species_id": species_id,
			"is_active": is_active,
			"is_knocked_out": false,
			"hp_state_bp": hp_state_bp,
			"route_retention_bp": route_retention_bp,
			"immediate_status_action_bp": immediate_status_action_bp,
			"attrition": {},
			"held_item": {},
			"breakdown": {},
		},
	}


func _ignore_fixture_check(_name: String, _condition: bool) -> void:
	pass
