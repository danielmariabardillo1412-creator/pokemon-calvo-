extends SceneTree

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Playback = preload("res://scenes/visual/battle_animation_playback.gd")
const Plan = preload("res://scenes/visual/battle_timeline_plan.gd")
var _passed := 0
var _failures: Array[String] = []
var _seen: Array[Dictionary] = []
var _capture := false
var _captures := 0


func _initialize() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")


func _run() -> void:
	_test_plans()
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	_check("real_game_ready", scene.is_demo_ready())
	_configure(scene, "miraidon", "iron_hands", "iron_moth")
	print("TIMELINE_AUDIT wild_start")
	await _encounter(scene)
	var ui = scene.battle_presentation
	ui._playback.set_process(false)
	ui._arena.set_process(false)
	ui._playback.pose_started.connect(func(entry: Dictionary): _seen.append(entry))
	_fixture_moves(ui.session.battle_state())
	_seen.clear()
	var before: Dictionary = ui._playback._snapshot()
	var events: Array[BattleEvent] = ui.submit_player_move(&"tackle")
	_check("wild_real_turn_resolved", not events.is_empty())
	_check("wild_starts_playback", ui._playback.is_playing())
	_check("hp_does_not_jump_to_final_result", ui.displayed_player_hp() == int(before.views.back.hp) and ui.displayed_enemy_hp() == int(before.views.front.hp))
	var later_action := ""
	for step: Dictionary in ui._playback._sequence:
		if step.event_kind == String(BattleEvent.ACTION_USED) and step.side == "front":
			later_action = step.text
	_check("future_message_is_not_revealed_early", not later_action.is_empty() and not later_action in ui._event_log.text)
	_check("diagnostic_log_is_still_immediate", later_action in ui._playback._logs)
	_check("wild_commands_locked", ui._move_buttons[0].disabled and ui._run_button.disabled and ui._capture_buttons[0].disabled and ui._switch_selector.disabled)
	var state: BattleState = ui.session.battle_state()
	var resolved: Dictionary = state.to_dict().duplicate(true)
	var capture_state: int = scene._capture_rng.state
	var escape_state: int = scene._escape_rng.state
	var balls_before: int = scene.demo_inventory_quantity(&"master_ball")
	ui._refresh_view()
	_check("refresh_cannot_unlock_mid_playback", ui._move_buttons[0].disabled and ui._capture_buttons[0].disabled)
	_check("refresh_cannot_reveal_final_hp", ui.displayed_player_hp() == int(before.views.back.hp) and ui.displayed_enemy_hp() == int(before.views.front.hp))
	_check("busy_move_rejected_locally", ui.submit_player_move(&"tackle").is_empty())
	_check("busy_switch_rejected_locally", ui.submit_player_switch(&"technical_bench").reason == "visual_playback_busy")
	_check("busy_ball_rejected_locally", ui.submit_capture_ball(&"master_ball").reason == "visual_playback_busy")
	_check("busy_run_rejected_locally", ui.submit_player_run().reason == "visual_playback_busy")
	_check("busy_continue_rejected_locally", not ui.continue_after_completion())
	_check("busy_requests_preserve_domain", state.to_dict() == resolved)
	_check("busy_requests_preserve_capture_rng", scene._capture_rng.state == capture_state)
	_check("busy_requests_preserve_escape_rng", scene._escape_rng.state == escape_state)
	_check("busy_requests_preserve_inventory", scene.demo_inventory_quantity(&"master_ball") == balls_before)
	await _drain(ui, "wild_turn")
	_check("wild_exact_event_order", _seen == ui._playback.build_sequence(_serialized(events), before, ui._playback._messages))
	_check("playback_does_not_resolve_turn_again", state.to_dict() == resolved)
	_check("buttons_restored_after_playback", not ui._move_buttons[0].disabled and not ui._run_button.disabled)
	_check("idle_restored", ui._arena.player_preview_state == "" and ui._arena.enemy_preview_state == "")
	_check("shared_effect_does_not_leak_to_idle", ui._arena._effect_kind == "" and ui._arena._effect_side == "")
	_check("authoritative_hp_kept", ui.displayed_player_hp() == ui.session.player_active().current_hp and ui.displayed_enemy_hp() == ui.session.current_wild().current_hp)
	_check("final_message_is_revealed", later_action in ui._event_log.text)
	_check("technical_log_noise_not_shown", not "pp changed" in ui._event_log.text and not "turn ended" in ui._event_log.text)

	_seen.clear()
	var switched: WildBattleCommandResult = ui.submit_player_switch(&"technical_bench")
	_check("real_switch_accepted", switched.accepted)
	await _drain(ui, "wild_switch")
	_check("switch_restores_correct_species", ui._arena.player_species == &"iron_hands")
	_check("switch_has_visual_boundary", not _seen.is_empty() and _seen[0].event_kind == String(BattleEvent.SWITCHED))
	_seen.clear()
	var failed_ball: WildBattleCommandResult = ui.submit_capture_ball(&"poke_ball")
	_check("failed_capture_is_real", failed_ball.accepted and not failed_ball.session_completed)
	_check("failed_capture_opponent_animated", ui._playback.is_playing())
	_check("failed_capture_shakes_match_result", _shake_count(ui._playback._sequence) == failed_ball.capture_outcome.resolution.result.shake_count)
	var failed_capture_rng: int = scene._capture_rng.state
	var failed_capture_state: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
	await _drain(ui, "failed_capture_response")
	_check("failed_capture_visual_preserves_rng_and_turn", scene._capture_rng.state == failed_capture_rng and ui.session.battle_state().to_dict() == failed_capture_state)
	_check("failed_capture_restores_original_image", ui._arena._enemy_visible and ui._arena.enemy_species == &"iron_moth")
	_check("breakout_precedes_opponent_response", _index_of_kind(_seen, "capture_breakout") >= 0 and _index_of_kind(_seen, "capture_breakout") < _index_of_kind(_seen, String(BattleEvent.ACTION_USED)))
	var captured: WildBattleCommandResult = ui.submit_capture_ball(&"master_ball")
	_check("capture_success_unchanged", captured.accepted and captured.session_completed)
	_check("capture_waits_for_presentation", ui._playback.is_playing() and not ui.continue_after_completion())
	var fake_attack := false
	for step: Dictionary in ui._playback._sequence:
		fake_attack = fake_attack or step.event_kind == String(BattleEvent.ACTION_USED)
	_check("capture_no_fake_attack", not fake_attack)
	var captured_id := captured.capture_outcome.resolution.captured.instance_id
	var captured_data := captured.capture_outcome.resolution.captured.to_dict().duplicate(true)
	var capture_rng_after: int = scene._capture_rng.state
	var captured_party_size: int = scene.demo_party_size()
	_check("capture_shakes_match_result", _shake_count(ui._playback._sequence) == captured.capture_outcome.resolution.result.shake_count)
	_check("capture_does_not_reveal_success_early", ui._arena._capture_phase == "throw" and not ui._continue_button.visible and ui._turn_label.text != "Capturado")
	_check("duplicate_capture_blocked_during_visual", not ui.submit_capture_ball(&"master_ball").accepted)
	await _drain(ui, "capture_success")
	_check("capture_presentation_never_rerolls", scene._capture_rng.state == capture_rng_after)
	_check("capture_preserves_exact_owned_instance", ui.session.player.party.get_creature(captured_id) == captured.capture_outcome.resolution.captured and captured.capture_outcome.resolution.captured.to_dict() == captured_data)
	_check("capture_does_not_duplicate_or_consume_again", scene.demo_party_size() == captured_party_size and scene.demo_inventory_quantity(&"master_ball") == 0)
	_check("caught_target_stays_hidden", not ui._arena._enemy_visible and ui._arena._capture_phase == "caught")
	_check("capture_returns_to_map", ui.continue_after_completion())

	_configure(scene, "miraidon", "iron_hands", "iron_moth")
	_check("real_trainer_battle_starts", scene.start_demo_trainer_battle())
	print("TIMELINE_AUDIT trainer_start")
	var trainer_ui = scene.trainer_battle_presentation
	trainer_ui._playback.set_process(false)
	trainer_ui._arena.set_process(false)
	trainer_ui._playback.pose_started.connect(func(entry: Dictionary): _seen.append(entry))
	_fixture_moves(trainer_ui.session.battle_state())
	_seen.clear()
	before = trainer_ui._playback._snapshot()
	var trainer_events: Array[BattleEvent] = trainer_ui.submit_player_move(&"tackle")
	_check("autonomous_trainer_turn_resolves", not trainer_events.is_empty())
	_check("trainer_starts_playback", trainer_ui._playback.is_playing())
	var trainer_state: BattleState = trainer_ui.session.battle_state()
	var trainer_resolved: Dictionary = trainer_state.to_dict().duplicate(true)
	var proposal: Dictionary = trainer_ui.session.last_trainer_action_proposal_report.duplicate(true)
	_check("trainer_busy_move_blocked", trainer_ui.submit_player_move(&"tackle").is_empty())
	_check("trainer_busy_switch_blocked", trainer_ui.submit_player_switch(&"technical_bench").is_empty())
	await _drain(trainer_ui, "trainer_turn")
	_check("trainer_exact_event_order", _seen == trainer_ui._playback.build_sequence(_serialized(trainer_events), before, trainer_ui._playback._messages))
	_check("trainer_domain_unchanged_during_playback", trainer_state.to_dict() == trainer_resolved)
	_check("trainer_ai_report_unchanged", trainer_ui.session.last_trainer_action_proposal_report == proposal)
	# A real one-HP opponent fixture exercises settlement releasing BattleState.
	trainer_ui.session.opponent_active().current_hp = 1
	trainer_ui.session.player_active().stats.speed = 10000
	var owned: CreatureInstance = trainer_ui.session.player.owned_creature(trainer_ui.session.player_active().instance_id)
	var definition: CreatureSpecies = scene._catalogs.species_catalog.get_by_id(owned.species_id)
	owned.experience = ProgressionRuleset.experience_for_level(definition.growth_rate, 51) - 1
	trainer_ui.session.player_active().experience = owned.experience
	trainer_ui._refresh_view()
	var ko_events: Array[BattleEvent] = trainer_ui.submit_player_move(&"tackle")
	_check("ko_resolved_by_domain", not ko_events.is_empty() and trainer_ui.session.status == TrainerBattleSession.COMPLETED)
	_check("ko_animation_survives_settlement", trainer_ui._playback.is_playing() and trainer_ui.session.battle_state() == null)
	_check("ko_return_waits_for_animation", not trainer_ui.continue_after_completion() and trainer_ui._continue_button.disabled)
	_check("ko_label_not_revealed_before_timeline_finishes", trainer_ui._turn_label.text != "Combate terminado" and not trainer_ui._continue_button.visible)
	await _drain(trainer_ui, "trainer_ko")
	_check("ko_retains_last_creature_images", trainer_ui._arena.player_species == &"miraidon" and trainer_ui._arena.enemy_species == &"iron_moth")
	_check("ko_target_stays_hidden", not trainer_ui._arena._enemy_visible)
	_check("ko_return_enabled", trainer_ui._continue_button.visible and not trainer_ui._continue_button.disabled)
	_check("settlement_fixture_levels_up", owned.level > 50)
	_check("final_hud_reads_completed_progression", trainer_ui.displayed_player_hp() == owned.current_hp and int(trainer_ui._player_hp.max_value) == owned.stats.max_hp and ("Nv.%d" % owned.level) in trainer_ui._player_label.text)
	_check("ko_can_return", trainer_ui.continue_after_completion() and scene.player.movement_enabled)

	_configure(scene, "miraidon", "iron_hands", "iron_moth")
	print("TIMELINE_AUDIT cancel_and_natural_start")
	await _encounter(scene)
	_fixture_moves(ui.session.battle_state())
	ui.submit_player_move(&"tackle")
	_check("cancel_fixture_is_playing", ui._playback.is_playing())
	var cancel_state: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
	var cancelled_tail := String(ui._playback._sequence.back().text)
	ui.hide()
	_check("hiding_cancels_without_timers", not ui._playback.is_playing())
	_check("cancel_does_not_change_battle", ui.session.battle_state().to_dict() == cancel_state)
	_check("cancel_flushes_remaining_messages", cancelled_tail in ui._event_log.text)
	_check("cancel_reconciles_displayed_hp", ui.displayed_player_hp() == ui.session.player_active().current_hp and ui.displayed_enemy_hp() == ui.session.current_wild().current_hp)
	ui.open_for_active_battle()
	_check("reopen_restores_idle", ui._arena.player_preview_state == "" and ui._arena.enemy_preview_state == "" and not ui._move_buttons[0].disabled)
	# Exercise actual frame processing as well as deterministic manual stepping.
	_seen.clear()
	ui._arena.set_process(true)
	ui._playback.set_process(true)
	ui.submit_player_move(&"tackle")
	var natural_state: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
	var deadline := Time.get_ticks_msec() + 12000
	var advanced_frame := false
	while ui._playback.is_playing() and Time.get_ticks_msec() < deadline:
		await process_frame
		var pose: Dictionary = ui._playback._sequence[ui._playback._index] if ui._playback.is_playing() else {}
		if not pose.is_empty():
			var species: StringName = ui._arena.player_species if pose.side == "back" else ui._arena.enemy_species
			var clip: Dictionary = Catalog.animation(species, pose.side, pose.state)
			var elapsed: float = ui._arena._player_time if pose.side == "back" else ui._arena._enemy_time
			advanced_frame = advanced_frame or Catalog.frame_index(clip, elapsed) > 0
	_check("natural_clock_completes", not ui._playback.is_playing())
	print("TIMELINE_AUDIT natural_finished")
	_check("natural_clock_advances_real_frames", advanced_frame)
	_check("natural_clock_keeps_domain_unchanged", ui.session.battle_state().to_dict() == natural_state)
	_check("natural_clock_plays_four_poses", _seen.size() == 4)
	if ui._playback.is_playing():
		ui._playback.cancel()
	ui._arena.set_process(false)
	ui._playback.set_process(false)
	ui.submit_capture_ball(&"master_ball")
	var cancelled_capture_size: int = scene.demo_party_size()
	ui._playback.advance(0.8)
	ui.hide()
	_check("cancelled_capture_finishes_truthfully", not ui._playback.is_playing() and not ui._arena._enemy_visible and ui._arena._capture_phase == "caught" and scene.demo_party_size() == cancelled_capture_size)
	ui.continue_after_completion()

	_configure(scene, "charizard", "pikachu", "wailord")
	print("TIMELINE_AUDIT ordinary_start")
	await _encounter(scene)
	_fixture_moves(ui.session.battle_state())
	var idle_events: Array[BattleEvent] = ui.submit_player_move(&"tackle")
	_check("ordinary_species_real_turn_resolves", not idle_events.is_empty())
	_check("ordinary_species_gets_shared_motion_not_replacement", ui._playback.is_playing() and ui._arena.player_preview_state == "reposo" and ui._arena.player_species == &"charizard" and ui._arena.enemy_species == &"wailord")
	await _drain(ui, "ordinary_shared_motion")
	ui.submit_capture_ball(&"master_ball")
	await _drain(ui, "ordinary_capture")
	ui.continue_after_completion()
	await _lifecycle_cases(scene)

	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed, "failures": _failures,
		"captures": _captures, "scope": "All-base-species shared timeline and lifecycle plans, real wild/trainer turns, capture success/failure/storage, exact semantic shakes, switch/forced switch/faint/flee, cancellation, HUD pacing and authoritative identity/RNG invariants. No per-move VFX certification."}
	DirAccess.make_dir_recursive_absolute("res://.godot/animation_checks")
	var output := FileAccess.open("res://.godot/animation_checks/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t") + "\n")
	output.close()
	print("BATTLE_ANIMATION_RESULT " + JSON.stringify(result))
	scene.queue_free()
	Catalog.clear_cache()
	await process_frame
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _test_plans() -> void:
	var playback := Playback.new()
	var custom := 0
	for key: String in Catalog.species_rows():
		if not bool(Catalog.species_rows()[key].provisional):
			continue
		custom += 1
		var before := _bindings(key, key)
		var events := [
			_event(BattleEvent.ACTION_USED, "a", "b"),
			_event(BattleEvent.DAMAGE_APPLIED, "a", "b", 1),
			_event(BattleEvent.ACTION_USED, "b", "a"),
			_event(BattleEvent.DAMAGE_APPLIED, "b", "a", 1)]
		var original: Array = events.duplicate(true)
		var plan: Array[Dictionary] = playback.build_sequence(events, before)
		_check("four_poses/" + key, plan.size() == 4)
		if plan.size() == 4:
			_check("ordered_sides/" + key, [plan[0].side, plan[1].side, plan[2].side, plan[3].side] == ["back", "front", "front", "back"])
			_check("attack_and_damage/" + key, [plan[0].state, plan[1].state, plan[2].state, plan[3].state] == ["ataque", "dano", "ataque", "dano"])
			for step: Dictionary in plan:
				_check("native_clip_duration/" + key, is_equal_approx(step.duration, Catalog.animation(StringName(key), step.side, step.state).seconds))
		_check("events_not_mutated/" + key, events == original)
	_check("all_fourteen_have_event_bindings", custom == 14)
	var before := _bindings("miraidon", "iron_moth")
	var miss := [_event(BattleEvent.ACTION_USED, "a", "b"), _event(BattleEvent.MOVE_MISSED, "a", "b"), _event(BattleEvent.DAMAGE_APPLIED, "a", "b", 0)]
	_check("miss_only_animates_attempt", playback.build_sequence(miss, before).size() == 1)
	var healing := playback.build_sequence([_event(BattleEvent.ACTION_PREVENTED, "a", "b"), _event(BattleEvent.HP_RECOVERED, "a", "a", 10), _event(BattleEvent.ACTION_REJECTED, "a", "b")], before)
	_check("prevention_heal_and_rejection_do_not_invent_hit", healing.size() == 1 and healing[0].effect == "heal")
	var residual := playback.build_sequence([_event(BattleEvent.STATUS_DAMAGE, "", "b", 2), _event(BattleEvent.RECOIL_DAMAGE, "a", "a", 2)], before)
	_check("residual_and_recoil_use_actual_recipient", residual.size() == 2 and residual[0].side == "front" and residual[1].side == "back")
	_check("residual_and_recoil_project_declared_amounts", residual[0].after_views.front.hp == 98 and residual[1].after_views.back.hp == 98)
	var mixed := _bindings("charizard", "wailord")
	mixed.creatures.b.hp = 50
	var hits := playback.build_sequence([_event(BattleEvent.DAMAGE_APPLIED, "a", "b", 10), _event(BattleEvent.DAMAGE_APPLIED, "a", "b", 7), _event(BattleEvent.HP_RECOVERED, "b", "b", 20)], mixed)
	_check("multi_hit_and_heal_hp_projection", hits.size() == 3 and hits[0].after_views.front.hp == 40 and hits[1].after_views.front.hp == 33 and hits[2].after_views.front.hp == 53)
	_check("healing_is_not_an_impact", hits[2].effect == "heal" and hits[2].state == "reposo")
	var limits := playback.build_sequence([_event(BattleEvent.DAMAGE_APPLIED, "a", "b", 999), _event(BattleEvent.HP_RECOVERED, "b", "b", 999)], mixed)
	_check("displayed_hp_stays_in_bounds", limits[0].after_views.front.hp == 0 and limits[1].after_views.front.hp == 100)
	_check("unknown_instance_not_animated", playback.build_sequence([_event(BattleEvent.ACTION_USED, "not_a_creature", "b")], before).is_empty())
	before.creatures["bench"] = {"instance_id": "bench", "species": "miraidon", "side": "back"}
	var switches := playback.build_sequence([_event(BattleEvent.ACTION_USED, "bench", "b"), _event(BattleEvent.SWITCHED, "a", "bench"), _event(BattleEvent.DAMAGE_APPLIED, "b", "a", 1), _event(BattleEvent.DAMAGE_APPLIED, "b", "bench", 1)], before)
	_check("same_species_switch_uses_instance_identity", switches.size() == 3 and switches[0].views.back.instance_id == "a" and switches[1].views.back.instance_id == "bench" and switches[2].state == "dano")
	var shared := playback.build_sequence([_event(BattleEvent.ACTION_USED, "a", "b")], _bindings("charizard", "wailord"))
	_check("missing_attack_keeps_source_art_with_shared_motion", shared.size() == 1 and shared[0].state == "reposo" and shared[0].effect == "action")
	_test_all_species_plans(playback)
	_test_lifecycle_plans(playback)
	playback.free()


func _test_lifecycle_plans(playback: Node) -> void:
	for key: String in Catalog.species_rows():
		var before := _bindings(key, key)
		var original := before.duplicate(true)
		var capture := Plan.command(_capture_entry("SUCCESS", 3), before)
		_check("all_species_capture_stages/" + key, capture.size() == 7 and capture[0].capture_phase == "throw" and capture[1].capture_phase == "absorb" and capture[6].capture_phase == "caught")
		_check("all_species_capture_hidden_after_absorption/" + key, capture[0].views.front.get("visible", true) and not capture[1].after_views.front.visible and not capture.back().after_views.front.visible)
		var faint: Array[Dictionary] = playback.build_sequence([_event(BattleEvent.KNOCKED_OUT, "", "b")], before)
		_check("all_species_shared_faint/" + key, faint.size() == 1 and faint[0].effect == "faint" and not faint[0].after_views.front.visible)
		before.creatures["bench"] = {"instance_id": "bench", "species": key, "side": "back", "hp": 100, "max_hp": 100}
		var switch: Array[Dictionary] = playback.build_sequence([_event(BattleEvent.SWITCHED, "a", "bench")], before)
		_check("all_species_switch_phases/" + key, switch.size() == 2 and switch[0].effect == "withdraw" and switch[1].effect == "send_out")
		var forced: Array[Dictionary] = playback.build_sequence([_event(BattleEvent.KNOCKED_OUT, "", "a"), _event(BattleEvent.SWITCHED, "a", "bench")], before)
		_check("forced_switch_does_not_withdraw_fainted_again/" + key, forced.size() == 2 and forced[0].effect == "faint" and forced[1].effect == "send_out" and forced[1].views.back.instance_id == "bench")
		before.creatures.erase("bench")
		_check("lifecycle_does_not_mutate_snapshot/" + key, before == original)
	var before := _bindings("charizard", "wailord")
	for shakes in 3:
		var failed := Plan.command(_capture_entry("FAILED", shakes), before)
		_check("failed_semantic_shake_count/%s" % shakes, _shake_count(failed) == shakes and failed.back().capture_phase == "breakout" and failed.back().after_views.front.get("visible", true))
	_check("rejected_capture_has_no_visual", Plan.command({"kind": "capture", "accepted": false}, before).is_empty())
	_check("invalid_capture_has_no_visual", Plan.command(_capture_entry("INVALID", 0), before).is_empty())
	var wrong_target := _capture_entry("SUCCESS", 3)
	wrong_target.capture_outcome.capture.result.target_id = "foreign"
	_check("foreign_capture_target_not_substituted", Plan.command(wrong_target, before).is_empty())
	_check("out_of_contract_shakes_not_fabricated", Plan.command(_capture_entry("SUCCESS", 99), before).is_empty())
	_check("failed_escape_does_not_hide_actor", Plan.command({"kind": "run", "accepted": true, "session_completed": false, "escape_resolution": {"escaped": false}}, before).is_empty())
	var fled := Plan.command({"kind": "run", "accepted": true, "session_completed": true, "escape_resolution": {"escaped": true}}, before)
	_check("successful_escape_only_hides_player", fled.size() == 1 and not fled[0].after_views.back.visible and fled[0].after_views.front.get("visible", true))


func _capture_entry(status: String, shakes: int) -> Dictionary:
	return {"kind": "capture", "accepted": true, "session_completed": status == "SUCCESS",
		"capture_outcome": {"capture": {"result": {"status": status, "shake_count": shakes, "ball_id": "poke_ball", "target_id": "b"}}}}


func _shake_count(sequence: Array) -> int:
	var count := 0
	for step: Dictionary in sequence:
		if step.get("capture_phase", "") == "shake":
			count += 1
	return count


func _index_of_kind(sequence: Array, kind: String) -> int:
	for index in sequence.size():
		if sequence[index].event_kind == kind:
			return index
	return -1


func _lifecycle_cases(scene: Node) -> void:
	print("TIMELINE_AUDIT lifecycle_storage_and_forced_switch")
	_configure(scene, "charizard", "pikachu", "wailord")
	var extras := ["bulbasaur", "squirtle", "eevee", "pidgey"] # Castform is excluded from the current game pool.
	for index in extras.size():
		scene.test_panel._player_species_inputs[index + 2].text = extras[index]
		scene.test_panel._player_level_inputs[index + 2].value = 50
	scene.restart_field_run()
	scene.player.set_physics_process(false)
	await _encounter(scene)
	var ui = scene.battle_presentation
	_check("new_encounter_clears_previous_visibility", ui._arena._player_visible and ui._arena._enemy_visible and ui._arena._capture_phase == "")
	var target: CreatureInstance = ui.session.current_wild()
	var capture_rng_before: int = scene._capture_rng.state
	var stored: WildBattleCommandResult = ui.submit_capture_ball(&"master_ball")
	_check("full_party_capture_routes_to_storage", stored.accepted and stored.session_completed and stored.capture_outcome.routing.stored)
	await _drain(ui, "storage_capture")
	_check("stored_capture_keeps_identity", ui.session.player.storage.get_creature(target.instance_id) == stored.capture_outcome.resolution.captured)
	_check("storage_visual_does_not_consume_rng", scene._capture_rng.state == capture_rng_before)
	_check("stored_capture_keeps_party_at_six", scene.demo_party_size() == 6)
	_check("storage_capture_returns", ui.continue_after_completion())

	_configure(scene, "charizard", "pikachu", "iron_moth")
	_check("forced_switch_trainer_starts", scene.start_demo_trainer_battle())
	var trainer = scene.trainer_battle_presentation
	_fixture_moves(trainer.session.battle_state())
	trainer.session.player_active().current_hp = 1
	trainer.session.opponent_active().stats.speed = 10000
	trainer._refresh_view()
	_seen.clear()
	var events: Array[BattleEvent] = trainer.submit_player_move(&"tackle")
	_check("player_ko_forced_switch_is_real", not events.is_empty() and trainer.session.player_active().instance_id == &"technical_bench")
	var after: Dictionary = trainer.session.battle_state().to_dict().duplicate(true)
	await _drain(trainer, "player_faint_forced_switch")
	_check("forced_switch_restores_living_bench_image", trainer._arena._player_visible and trainer._arena.player_species == &"pikachu")
	_check("forced_switch_visual_does_not_touch_domain", trainer.session.battle_state().to_dict() == after)
	_check("faint_before_send_out", _index_of_kind(_seen, String(BattleEvent.KNOCKED_OUT)) < _index_of_kind(_seen, String(BattleEvent.SWITCHED)))
	trainer.session.opponent_active().current_hp = 1
	trainer.session.player_active().stats.speed = 100000
	trainer._refresh_view()
	trainer.submit_player_move(&"tackle")
	await _drain(trainer, "forced_switch_cleanup_ko")
	_check("forced_switch_battle_returns", trainer.continue_after_completion())

	_configure(scene, "miraidon", "pikachu", "wailord")
	await _encounter(scene)
	var escape_rng_before: int = scene._escape_rng.state
	var fled: WildBattleCommandResult = ui.submit_player_run()
	_check("real_escape_succeeds", fled.accepted and fled.session_completed and fled.escape_resolution.escaped)
	_check("escape_waits_for_visual", ui._playback.is_playing() and not ui.continue_after_completion())
	await _drain(ui, "escape")
	_check("escape_image_matches_result", not ui._arena._player_visible and ui._arena._enemy_visible)
	_check("escape_animation_does_not_consume_rng", scene._escape_rng.state == escape_rng_before)
	_check("escape_returns", ui.continue_after_completion())


func _test_all_species_plans(playback: Node) -> void:
	for key: String in Catalog.species_rows():
		var before := _bindings(key, key)
		var original := before.duplicate(true)
		var events := [_event(BattleEvent.ACTION_USED, "a", "b"), _event(BattleEvent.DAMAGE_APPLIED, "a", "b", 17),
			_event(BattleEvent.ACTION_USED, "b", "a"), _event(BattleEvent.DAMAGE_APPLIED, "b", "a", 9)]
		var plan: Array[Dictionary] = playback.build_sequence(events, before, ["acción a", "daño b", "acción b", "daño a"])
		_check("complete_four_step_timeline/" + key, plan.size() == 4)
		if plan.size() != 4:
			continue
		_check("all_species_event_order/" + key, [plan[0].side, plan[1].side, plan[2].side, plan[3].side] == ["back", "front", "front", "back"])
		_check("opponent_hp_at_impact_only/" + key, plan[0].after_views.front.hp == 100 and plan[1].views.front.hp == 100 and plan[1].after_views.front.hp == 83)
		_check("player_hp_at_impact_only/" + key, plan[2].views.back.hp == 100 and plan[3].views.back.hp == 100 and plan[3].after_views.back.hp == 91)
		_check("projector_preserves_snapshot/" + key, before == original)
		for step: Dictionary in plan:
			_check("available_pose_not_alias/" + key, Catalog.species_rows()[key].states.has(step.state))
			_check("finite_positive_duration/" + key, is_finite(float(step.duration)) and step.duration > 0.0)


func _bindings(player: String, enemy: String) -> Dictionary:
	var a := {"instance_id": "a", "species": player, "side": "back", "hp": 100, "max_hp": 100, "level": 50}
	var b := {"instance_id": "b", "species": enemy, "side": "front", "hp": 100, "max_hp": 100, "level": 50}
	return {"views": {"back": a.duplicate(), "front": b.duplicate()}, "creatures": {"a": a, "b": b}}


func _event(kind: StringName, actor: String, target: String, amount: int = 0) -> Dictionary:
	return {"kind": String(kind), "actor_id": actor, "target_id": target, "amount": amount}


func _serialized(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		result.append(event.to_dict())
	return result


func _configure(scene: Node, player: String, bench: String, enemy: String) -> void:
	for index in scene.test_panel._player_species_inputs.size():
		scene.test_panel._player_species_inputs[index].text = ""
	for index in scene.test_panel._trainer_species_inputs.size():
		scene.test_panel._trainer_species_inputs[index].text = ""
	scene.test_panel._player_species_inputs[0].text = player
	scene.test_panel._player_level_inputs[0].value = 50
	scene.test_panel._player_species_inputs[1].text = bench
	scene.test_panel._player_level_inputs[1].value = 50
	scene.test_panel._trainer_species_inputs[0].text = enemy
	scene.test_panel._trainer_level_inputs[0].value = 50
	scene.test_panel._wild_species_input.text = enemy
	scene.test_panel._wild_min_level.value = 50
	scene.test_panel._wild_max_level.value = 50
	scene.test_panel._encounter_chance.value = 100
	scene.restart_field_run()
	scene.player.set_physics_process(false)


func _encounter(scene: Node) -> void:
	scene.player.global_position = Vector2(420, 150)
	scene.player.reset_step_meter()
	await physics_frame
	for step in 24:
		scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		await physics_frame
		if scene.has_active_demo_battle():
			break
	_check("encounter_through_real_grass", scene.has_active_demo_battle())


func _fixture_moves(state: BattleState) -> void:
	# In-memory test fixture only: use a predictable supported move, not edits to
	# production learnsets, definitions or randomlocke rules.
	for id: StringName in state.participant_ids:
		var creature := state.creature(id)
		creature.moveset.assign([BattleMoveSlot.new(&"tackle", 35, 35)])
		creature.move_ids.assign([&"tackle"])


func _drain(ui: Control, label: String) -> void:
	var limit := 0
	while ui._playback.is_playing() and limit < 100:
		var step: Dictionary = ui._playback._sequence[ui._playback._index]
		var elapsed := float(step.duration) * 0.5
		var fraction := 0.25 if step.get("capture_phase", "") == "shake" else 0.5
		ui._playback.advance(float(ui._playback._remaining) * fraction)
		for side: String in ["back", "front"]:
			var initial_hp := int(step.views.get(side, {}).get("hp", 0))
			var final_hp := int(step.after_views.get(side, {}).get("hp", initial_hp))
			if absi(initial_hp - final_hp) >= 2:
				var shown: int = ui.displayed_player_hp() if side == "back" else ui.displayed_enemy_hp()
				if step.has("catalog_clip"):
					_check("native_hp_waits_for_clip_completion/" + label, shown == initial_hp)
				else:
					_check("intermediate_hp_is_display_only/" + label, shown > mini(initial_hp, final_hp) and shown < maxi(initial_hp, final_hp))
		if step.side == "back":
			ui._arena._player_time = elapsed
		else:
			ui._arena._enemy_time = elapsed
		ui._arena.queue_redraw()
		if _capture:
			await process_frame
			await process_frame
			# A covered/minimized test window may skip automatic draws. Request an
			# actual GPU frame instead of waiting indefinitely for frame_post_draw.
			RenderingServer.force_draw(false)
			DirAccess.make_dir_recursive_absolute("res://.godot/animation_checks")
			var saved := root.get_texture().get_image().save_png("res://.godot/animation_checks/%s_%02d_%s_%s.png" % [label, limit, step.side, step.state]) == OK
			_check("capture/" + label, saved)
			if saved:
				_captures += 1
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		limit += 1
	_check("bounded_playback/" + label, not ui._playback.is_playing() and limit < 100)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
