class_name TrainerIntelligenceControllerCampaignTestSuite
extends TrainerIntelligenceFoundationTestSuite


func run(check_callback: Callable) -> void:
	_check = check_callback
	_catalog = _import_pokeapi().to_definition_catalog()
	_add_test_moves()
	_test_controller_campaign_snapshot_transport()


func _test_controller_campaign_snapshot_transport() -> void:
	var state := _battle_state(252)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var controller := TrainerIntelligenceController.new(&"side_b", TrainerBrain.new(), _catalog)
	_check.call("intel_controller_campaign_begin", controller.begin(server))
	controller.choose_action(server)
	_check.call(
		"intel_controller_campaign_default_empty",
		controller.last_context != null and controller.last_context.campaign_snapshot.is_empty(),
	)

	var source := {
		"schema_version": 1,
		"round_index": 3,
		"own_roster": {
			"alive_instance_ids": ["intel_trainer", "intel_trainer_bench"],
		},
	}
	controller.set_campaign_snapshot(source)
	source["round_index"] = 99
	var source_roster := source.get("own_roster", {}) as Dictionary
	var source_alive := source_roster.get("alive_instance_ids", []) as Array
	source_alive.append("source_leak")
	controller.choose_action(server)
	var first_context := controller.last_context
	_check.call(
		"intel_controller_campaign_source_detached",
		first_context != null and int(first_context.campaign_snapshot.get("round_index", 0)) == 3,
	)
	var first_roster := first_context.campaign_snapshot.get("own_roster", {}) as Dictionary
	var first_alive := first_roster.get("alive_instance_ids", []) as Array
	_check.call(
		"intel_controller_campaign_nested_detached",
		not first_alive.has("source_leak") and first_alive.size() == 2,
	)

	controller.set_campaign_snapshot({
		"schema_version": 1,
		"round_index": 4,
		"own_roster": {
			"alive_instance_ids": ["intel_trainer"],
		},
	})
	controller.choose_action(server)
	var second_context := controller.last_context
	_check.call(
		"intel_controller_campaign_refreshes_next_context",
		second_context != null and int(second_context.campaign_snapshot.get("round_index", 0)) == 4,
	)
	_check.call(
		"intel_controller_campaign_previous_context_stable",
		int(first_context.campaign_snapshot.get("round_index", 0)) == 3 and first_alive.size() == 2,
	)

	controller.set_campaign_snapshot({})
	controller.choose_action(server)
	_check.call(
		"intel_controller_campaign_can_clear",
		controller.last_context != null and controller.last_context.campaign_snapshot.is_empty(),
	)
