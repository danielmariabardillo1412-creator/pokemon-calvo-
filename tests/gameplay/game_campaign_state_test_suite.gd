class_name GameCampaignStateTestSuite
extends RefCounted


func run(check: Callable) -> void:
	_test_initialization_is_atomic(check)
	_test_location_is_atomic(check)
	_test_starter_is_write_once(check)
	_test_story_flags(check)
	_test_defeated_trainers(check)
	_test_campaign_stage_is_monotonic(check)
	_test_snapshot_is_deterministic_and_detached(check)
	_test_validation(check)


func _test_initialization_is_atomic(check: Callable) -> void:
	var state := GameCampaignState.new()
	check.call("gf1a_uninitialized_is_not_ready", not state.is_initialized())
	check.call("gf1a_uninitialized_validation_fails", state.validate().reason == "missing_campaign_id")
	check.call("gf1a_rejects_empty_campaign_id", not state.initialize_new(&"", &"starter_town", &"home"))
	check.call("gf1a_failed_init_keeps_campaign_empty", state.campaign_id == &"")
	check.call("gf1a_rejects_empty_map_id", not state.initialize_new(&"campaign_1", &"", &"home"))
	check.call("gf1a_rejects_empty_spawn_id", not state.initialize_new(&"campaign_1", &"starter_town", &""))
	check.call("gf1a_valid_init_succeeds", state.initialize_new(&"campaign_1", &"starter_town", &"home"))
	check.call(
		"gf1a_init_publishes_complete_location",
		state.is_initialized()
		and state.campaign_id == &"campaign_1"
		and state.current_map_id == &"starter_town"
		and state.current_spawn_id == &"home",
	)
	check.call(
		"gf1a_reinitialize_fails_closed",
		not state.initialize_new(&"campaign_2", &"other", &"other_spawn")
		and state.campaign_id == &"campaign_1"
		and state.current_map_id == &"starter_town",
	)


func _test_location_is_atomic(check: Callable) -> void:
	var state := _ready_state()
	check.call("gf1a_location_rejects_empty_map", not state.set_location(&"", &"route_spawn"))
	check.call(
		"gf1a_failed_location_keeps_both_fields",
		state.current_map_id == &"starter_town" and state.current_spawn_id == &"home",
	)
	check.call("gf1a_location_rejects_empty_spawn", not state.set_location(&"route_1", &""))
	check.call("gf1a_location_transition_succeeds", state.set_location(&"route_1", &"town_gate"))
	check.call(
		"gf1a_location_transition_updates_pair",
		state.current_map_id == &"route_1" and state.current_spawn_id == &"town_gate",
	)


func _test_starter_is_write_once(check: Callable) -> void:
	var blank := GameCampaignState.new()
	check.call("gf1a_starter_requires_initialized_campaign", not blank.choose_starter(&"bulbasaur"))
	var state := _ready_state()
	check.call("gf1a_starter_rejects_empty_species", not state.choose_starter(&""))
	check.call("gf1a_starter_initially_absent", not state.has_starter())
	check.call("gf1a_first_starter_choice_succeeds", state.choose_starter(&"bulbasaur"))
	check.call("gf1a_starter_presence_recorded", state.has_starter() and state.starter_species_id == &"bulbasaur")
	check.call("gf1a_same_starter_choice_is_idempotent", state.choose_starter(&"bulbasaur"))
	check.call(
		"gf1a_starter_rebind_rejected",
		not state.choose_starter(&"charmander") and state.starter_species_id == &"bulbasaur",
	)


func _test_story_flags(check: Callable) -> void:
	var state := _ready_state()
	check.call("gf1a_story_flag_rejects_empty_id", not state.set_story_flag(&""))
	check.call("gf1a_story_flag_can_be_set", state.set_story_flag(&"met_professor") and state.has_story_flag(&"met_professor"))
	check.call("gf1a_story_flag_set_is_idempotent", state.set_story_flag(&"met_professor"))
	state.set_story_flag(&"received_map")
	check.call(
		"gf1a_story_flags_are_sorted",
		state.story_flag_ids() == [&"met_professor", &"received_map"],
	)
	check.call(
		"gf1a_story_flag_can_be_cleared",
		state.set_story_flag(&"met_professor", false) and not state.has_story_flag(&"met_professor"),
	)


func _test_defeated_trainers(check: Callable) -> void:
	var state := _ready_state()
	check.call("gf1a_trainer_defeat_rejects_empty_id", not state.mark_trainer_defeated(&""))
	check.call(
		"gf1a_trainer_defeat_records_fact",
		state.mark_trainer_defeated(&"route_1_youngster")
		and state.is_trainer_defeated(&"route_1_youngster"),
	)
	check.call("gf1a_trainer_defeat_is_idempotent", state.mark_trainer_defeated(&"route_1_youngster"))
	state.mark_trainer_defeated(&"gym_1_leader")
	check.call(
		"gf1a_defeated_trainers_are_sorted",
		state.defeated_trainer_ids() == [&"gym_1_leader", &"route_1_youngster"],
	)


func _test_campaign_stage_is_monotonic(check: Callable) -> void:
	var state := _ready_state()
	check.call("gf1a_campaign_stage_starts_zero", state.campaign_stage == 0)
	check.call("gf1a_campaign_stage_can_advance", state.advance_campaign_stage(2) and state.campaign_stage == 2)
	check.call("gf1a_campaign_stage_same_value_idempotent", state.advance_campaign_stage(2))
	check.call(
		"gf1a_campaign_stage_cannot_regress",
		not state.advance_campaign_stage(1) and state.campaign_stage == 2,
	)
	check.call("gf1a_campaign_stage_rejects_negative", not state.advance_campaign_stage(-1))


func _test_snapshot_is_deterministic_and_detached(check: Callable) -> void:
	var first := _ready_state()
	first.set_story_flag(&"z_flag")
	first.set_story_flag(&"a_flag")
	first.mark_trainer_defeated(&"trainer_z")
	first.mark_trainer_defeated(&"trainer_a")
	first.choose_starter(&"squirtle")
	first.advance_campaign_stage(3)

	var second := _ready_state()
	second.set_story_flag(&"a_flag")
	second.set_story_flag(&"z_flag")
	second.mark_trainer_defeated(&"trainer_a")
	second.mark_trainer_defeated(&"trainer_z")
	second.choose_starter(&"squirtle")
	second.advance_campaign_stage(3)

	var snapshot := first.to_dict()
	check.call("gf1a_snapshot_schema_exact", snapshot.schema_version == 1 and snapshot.ruleset_id == "calvo_game_campaign_v1")
	check.call(
		"gf1a_snapshot_core_fields_exact",
		snapshot.campaign_id == "campaign_1"
		and snapshot.current_map_id == "starter_town"
		and snapshot.current_spawn_id == "home"
		and snapshot.starter_species_id == "squirtle"
		and snapshot.campaign_stage == 3,
	)
	check.call("gf1a_snapshot_flags_sorted", snapshot.story_flags == ["a_flag", "z_flag"])
	check.call("gf1a_snapshot_trainers_sorted", snapshot.defeated_trainers == ["trainer_a", "trainer_z"])
	check.call(
		"gf1a_snapshot_deterministic_across_insertion_order",
		JSON.stringify(first.to_dict()) == JSON.stringify(second.to_dict()),
	)
	(snapshot.story_flags as Array).append("mutated_outside")
	(snapshot.defeated_trainers as Array).clear()
	check.call(
		"gf1a_snapshot_is_detached",
		not first.has_story_flag(&"mutated_outside") and first.defeated_trainer_ids().size() == 2,
	)


func _test_validation(check: Callable) -> void:
	var state := _ready_state()
	check.call("gf1a_ready_state_validates", bool(state.validate().ok))
	state.set_story_flag(&"valid_flag")
	state.mark_trainer_defeated(&"valid_trainer")
	state.choose_starter(&"bulbasaur")
	state.advance_campaign_stage(4)
	check.call("gf1a_populated_state_validates", bool(state.validate().ok))


func _ready_state() -> GameCampaignState:
	var state := GameCampaignState.new()
	state.initialize_new(&"campaign_1", &"starter_town", &"home")
	return state
