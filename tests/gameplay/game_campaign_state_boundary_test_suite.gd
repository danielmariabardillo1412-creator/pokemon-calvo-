class_name GameCampaignStateBoundaryTestSuite
extends RefCounted


func run(check: Callable) -> void:
	var blank := GameCampaignState.new()
	check.call("gf1a_boundary_location_requires_init", not blank.set_location(&"route_1", &"entry"))
	check.call("gf1a_boundary_flag_requires_init", not blank.set_story_flag(&"intro_done"))
	check.call("gf1a_boundary_defeat_requires_init", not blank.mark_trainer_defeated(&"trainer_1"))
	check.call("gf1a_boundary_stage_requires_init", not blank.advance_campaign_stage(1))

	var state := GameCampaignState.new()
	state.initialize_new(&"campaign_boundary", &"starter_town", &"home")
	check.call(
		"gf1a_boundary_same_location_idempotent",
		state.set_location(&"starter_town", &"home")
		and state.current_map_id == &"starter_town"
		and state.current_spawn_id == &"home",
	)
	check.call("gf1a_boundary_stage_can_jump_forward", state.advance_campaign_stage(5) and state.campaign_stage == 5)
	check.call(
		"gf1a_boundary_campaign_identity_stable",
		state.set_location(&"route_1", &"town_gate") and state.campaign_id == &"campaign_boundary",
	)

	state.set_story_flag(&"intro_done")
	var copied_flags := state.story_flag_ids()
	copied_flags.clear()
	check.call("gf1a_boundary_flag_id_list_detached", state.has_story_flag(&"intro_done"))

	state.mark_trainer_defeated(&"trainer_1")
	var copied_trainers := state.defeated_trainer_ids()
	copied_trainers.clear()
	check.call("gf1a_boundary_trainer_id_list_detached", state.is_trainer_defeated(&"trainer_1"))

	state.set_story_flag(&"missing_flag", false)
	check.call("gf1a_boundary_clearing_absent_flag_is_safe", not state.has_story_flag(&"missing_flag"))

	var snapshot := state.to_dict()
	check.call(
		"gf1a_boundary_snapshot_uses_json_safe_ids",
		snapshot.campaign_id is String
		and snapshot.current_map_id is String
		and snapshot.current_spawn_id is String
		and snapshot.story_flags is Array
		and snapshot.defeated_trainers is Array,
	)
