extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Live = preload("res://modules/battle/application/live_move_profile.gd")
const Library = preload("res://scenes/visual/live_battle_catalog.gd")
const OUTPUT_LIVE := "res://.godot/live_integration_checks/"
const SPECIALS: Array[StringName] = [&"circle_throw", &"dragon_tail", &"flip_turn", &"u_turn", &"volt_switch", &"roar", &"whirlwind", &"teleport", &"baton_pass", &"parting_shot", &"rain_dance", &"hail", &"sandstorm", &"snowscape", &"chilly_reception", &"substitute", &"shed_tail", &"transform"]
var admission := {}
var registered := 0
var _completed := false
var _game_completed := false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_LIVE)
	create_timer(240).timeout.connect(func():
		if not _completed:
			push_error("LIVE integration timeout")
			quit(1))
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	catalog = GameData.from_dict(data).to_definition_catalog()
	for id: String in data.moves:
		var reason := Live.reason(catalog.move(StringName(id)))
		if not admission.has(reason): admission[reason] = []
		admission[reason].append(id)
		if reason.is_empty(): _runtime_case(StringName(id))
	for id: StringName in SPECIALS: check("special admitted " + String(id), Live.reason(catalog.move(id)).is_empty())
	check("Ally Switch limited to doubles", Live.reason(catalog.move(&"ally_switch")) == "requires_doubles")
	_profile_edges()
	_trainer_sessions()
	await _library_audit()
	await _game_cases()
	check("real game cases completed", _game_completed)
	_completed = true
	var hashes := {}
	hashes["modules/battle/application/stat_stage_move_rules.gd"] = FileAccess.get_sha256("res://modules/battle/application/stat_stage_move_rules.gd")
	hashes["modules/battle/application/fixed_damage_move_rules.gd"] = FileAccess.get_sha256("res://modules/battle/application/fixed_damage_move_rules.gd")
	hashes["modules/battle/application/variable_power_move_rules.gd"] = FileAccess.get_sha256("res://modules/battle/application/variable_power_move_rules.gd")
	hashes["modules/battle/application/binding_move_rules.gd"] = FileAccess.get_sha256("res://modules/battle/application/binding_move_rules.gd")
	for path: String in ["modules/battle/application/healing_move_rules.gd", "modules/status/domain/battle_status_state.gd", "modules/status/application/status_system.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	hashes["modules/battle/domain/turn_resolver.gd"] = FileAccess.get_sha256("res://modules/battle/domain/turn_resolver.gd")
	for path: String in ["modules/battle/application/live_move_profile.gd", "modules/battle/application/turn_executor.gd", "modules/battle/domain/battle_state.gd", "modules/battle/server/authoritative_battle_server.gd", "modules/battle/domain/damage_calculator.gd", "modules/battle/effects/battle_effect_executor.gd", "modules/battle/simulation/battle_simulation_fork.gd", "modules/gameplay/wild_adventure_session.gd", "modules/gameplay/trainer_battle_session.gd", "modules/trainer_ai/trainer_action_space.gd", "modules/trainer_ai/trainer_observation.gd", "modules/trainer_ai/trainer_observation_builder.gd", "modules/trainer_ai/trainer_plausible_world_factory.gd", "modules/battle/presentation/battle_presentation_controller.gd", "modules/battle/presentation/trainer_battle_presentation_controller.gd", "modules/battle/presentation/spanish_battle_presentation_controller.gd", "modules/battle/presentation/simple_battle_opponent_policy.gd", "modules/battle/presentation/live_move_event_text.gd", "scenes/overworld/technical_overworld.gd", "scenes/visual/field_demo.gd", "scenes/visual/battle_animation_playback.gd", "scenes/visual/battle_timeline_plan.gd", "scenes/visual/live_battle_catalog.gd", "tools/visual/build_live_battle_catalog.py", "tests/battle/live_move_integration_test_runner.gd", "data/normalized/pokemon_api.json", "data/raw/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "admission": admission, "runtime_samples": samples, "registered_clips": registered,
		"captures": captures, "source_sha256": hashes, "visual_pack_sha256": FileAccess.get_sha256(Library.PACK)}
	FileAccess.open(OUTPUT_LIVE + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ", true) + "\n")
	print("LIVE_MOVE_INTEGRATION ", report.status, " checks=", checks, " admitted=", admission.get("", []).size(), " registry=", registered, " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _runtime_case(id: StringName) -> void:
	var f := _fixture(id)
	Live.apply(f.state)
	var snapshot := f.server.snapshot() as Dictionary
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), catalog)
	check("live context round trip " + String(id), restored.snapshot() == snapshot)
	var events := _reaction(f)
	var replayed := restored.submit_reaction_turn(_action_from_snapshot(snapshot, id), &"side_b")
	check("admitted move executes " + String(id), _count(events, BattleEvent.ACTION_USED) == 1 and _count(events, BattleEvent.ACTION_REJECTED) == 0)
	check("live execution deterministic " + String(id), _rows(events) == _rows(replayed) and f.server.snapshot() == restored.snapshot())
	for n in 3:
		if f.state.phase != BattleState.WAITING_FOR_SWITCH: break
		var side := StringName(f.state.pending_switch.side_id)
		var choice := Live.replacement(f.state, side, catalog)
		var continued: Array[BattleEvent] = f.server.submit_switch_choice(side, choice, f.state.turn)
		events.append_array(continued)
	check("no stranded continuation " + String(id), f.state.phase != BattleState.WAITING_FOR_SWITCH)
	samples.append({"move": String(id), "events": _rows(events)})


func _action_from_snapshot(snapshot: Dictionary, id: StringName) -> BattleAction:
	return BattleAction.new(int(snapshot.turn) + 1, &"a", id, &"b", BattleAction.MOVE, &"side_a")


func _profile_edges() -> void:
	var f := _fixture(&"ally_switch")
	Live.apply(f.state)
	var snapshot := f.server.snapshot() as Dictionary
	check("blocked move rejects before PP/RNG", _count(_reaction(f), BattleEvent.ACTION_REJECTED) == 1 and f.server.snapshot() == snapshot)
	f.actor.moveset.clear()
	f.actor.move_ids.clear()
	f.actor.add_move(&"splash", catalog)
	f.target.species_id = &"gengar"
	check("forced fallback is available", Live.moves(f.actor, catalog) == ([&"struggle"] as Array[StringName]))
	var fallback := BattleAction.new(1, &"a", &"struggle", &"b", BattleAction.MOVE, &"side_a")
	var before_hp: int = f.actor.current_hp
	var events: Array[BattleEvent] = f.server.submit_reaction_turn(fallback, &"side_b")
	check("fallback hits Ghost and costs quarter HP", f.target.current_hp < 2000 and f.actor.current_hp == before_hp - 500 and _count(events, BattleEvent.ACTION_REJECTED) == 0)
	check("fallback does not mutate permanent learnset", f.actor.move_ids == ([&"splash"] as Array[StringName]))
	for pair in [[201, 151], [202, 151], [203, 152]]:
		var max_hp: int = pair[0]
		var boundary := _fixture(&"splash")
		Live.apply(boundary.state)
		boundary.actor.stats.max_hp = max_hp
		boundary.actor.current_hp = max_hp
		boundary.actor.stat_stages.change(StatStages.ACCURACY, -12)
		boundary.target.stat_stages.change(StatStages.EVASION, 12)
		var result: Array[BattleEvent] = boundary.server.submit_reaction_turn(fallback, &"side_b")
		check("forced fallback rounds quarter HP and cannot miss", boundary.actor.current_hp == int(pair[1]) and _count(result, BattleEvent.MOVE_MISSED) == 0)
	f = _fixture(&"u_turn")
	Live.apply(f.state)
	var fork := BattleSimulationFork.from_state(f.state, catalog)
	var original := f.server.snapshot() as Dictionary
	var enemy := BattleAction.new(1, &"b", &"tackle", &"a", BattleAction.MOVE, &"side_b")
	var simulated := fork.submit_turn([_action(f), enemy] as Array[BattleAction])
	check("AI simulation completes pending pivot", fork.state().phase != BattleState.WAITING_FOR_SWITCH and _count(simulated, BattleEvent.SWITCHED) == 1)
	check("AI fork leaves live snapshot/RNG untouched", original == f.server.snapshot())

	var owner := TrainerDualSideBattleMemoryOwner.new()
	f.state.turn = 1
	f.state.weather = {"id": "rain", "turns_remaining": 8, "set_turn": 1}
	owner.begin(f.state)
	var observed := TrainerObservationBuilder.build(f.state, &"side_a", owner.snapshot_for_side(f.state, &"side_a"))
	var public_before := observed.public_battle_context.duplicate(true)
	f.state.weather.turns_remaining = 5
	var observed_again := TrainerObservationBuilder.build(f.state, &"side_a", owner.snapshot_for_side(f.state, &"side_a"))
	check("AI public context retains rules without hidden RNG/weather rock", observed_again.public_battle_context == public_before and public_before.live_moves_enabled and not JSON.stringify(observed.to_dict()).contains("rng_state"))
	f.state.creature(&"a2").add_move(&"thunderbolt", catalog)
	f.state.creature(&"a3").add_move(&"water_gun", catalog)
	var untouched := f.server.snapshot() as Dictionary
	var choice := Live.replacement(f.state, &"side_a", catalog)
	check("replacement choice reads without mutating state/RNG", f.server.snapshot() == untouched and choice == &"a2")
	f.target.stats.defense = 1
	f.target.stats.special_defense = 99999
	f.target.current_hp = 1
	check("replacement ignores hidden opposing stats/HP", Live.replacement(f.state, &"side_a", catalog) == choice)
	f.target.species_id = &"golem"
	check("replacement responds to public opposing typing", Live.replacement(f.state, &"side_a", catalog) == &"a3")


func _trainer_sessions() -> void:
	for move: StringName in [&"u_turn", &"baton_pass", &"chilly_reception", &"shed_tail"]:
		var f := _fixture(move)
		var collection := PlayerCollection.new()
		collection.party.add_creature(f.state.creature(&"a"))
		collection.party.add_creature(f.state.creature(&"a2"))
		collection.party.add_creature(f.state.creature(&"a3"))
		var session := TrainerBattleSession.new(collection, catalog)
		session.live_moves_enabled = true
		check("trainer live start", session.begin_battle(&"live_test", [f.state.creature(&"b"), f.state.creature(&"b2"), f.state.creature(&"b3")] as Array[CreatureInstance]))
		var state := session.battle_state()
		check("trainer all mechanisms enabled", state.live_moves_enabled and state.transform_rules_enabled and state.substitute_rules_enabled and state.weather_rules_enabled)
		var own := BattleAction.new(1, &"a", move, &"b", BattleAction.MOVE, &"side_a")
		var other := BattleAction.new(1, &"b", &"tackle", &"a", BattleAction.MOVE, &"side_b")
		var events := session.submit_player_action(own, other)
		check("trainer player chooses pending replacement", state.phase == BattleState.WAITING_FOR_SWITCH and _count(events, BattleEvent.SWITCH_REQUESTED) == 1)
		var continued := session.submit_switch_choice(&"side_a", &"a3", 1)
		check("trainer choice resumes once without memory loss", state.phase == BattleState.WAITING_FOR_ACTIONS and state.turn == 1 and _count(continued, BattleEvent.TURN_ENDED) == 1 and session.trainer_memory_wiring_ready())
		f = _fixture(&"u_turn", &"side_b")
		collection = PlayerCollection.new()
		collection.party.add_creature(f.state.creature(&"a"))
		session = TrainerBattleSession.new(collection, catalog)
		session.live_moves_enabled = true
		session.begin_battle(&"npc_pivot", [f.state.creature(&"b"), f.state.creature(&"b2")] as Array[CreatureInstance])
		events = session.submit_player_action(BattleAction.new(1, &"a", &"tackle", &"b", BattleAction.MOVE, &"side_a"), BattleAction.new(1, &"b", &"u_turn", &"a", BattleAction.MOVE, &"side_b"))
		check("NPC pivot selected automatically same turn", session.battle_state().phase == BattleState.WAITING_FOR_ACTIONS and _count(events, BattleEvent.SWITCHED) == 1 and session.trainer_memory_wiring_ready())


func _library_audit() -> void:
	var arena := preload("res://scenes/visual/battle_art.gd").new()
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.player_species = &"charizard"
	arena.enemy_species = &"wailord"
	root.add_child(arena)
	var library := Library.new()
	root.add_child(library)
	library.configure(arena)
	check("all 1822 clips registered", library.available and library.bindings.size() == 1822)
	var previous := ""
	for key: String in library.bindings:
		var path: String = library.bindings[key].path
		if path != previous: await process_frame
		previous = path
		check("source shard loads " + key, library._load(key))
		if not is_instance_valid(library.preview): continue
		library.preview.size = arena.size
		library.preview.back_species = &"charizard"
		library.preview.front_species = &"wailord"
		for frame in [0, int(library.bindings[key].frames) / 2, int(library.bindings[key].frames) - 1]:
			check("clip frame valid " + key, library.preview.show_frame(frame))
		registered += 1
	library.clear()
	library.queue_free()
	arena.queue_free()
	await process_frame


func _game_cases() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	for n in 4: await process_frame
	for move: StringName in [&"absorb", &"swords_dance", &"recover", &"double_team"]:
		_configure(scene)
		check("ordinary wild and trainer sessions enable live integration", scene._session.live_moves_enabled and scene._trainer_session.live_moves_enabled)
		var ui: Control = await _encounter(scene)
		var state: BattleState = ui.session.battle_state()
		check("ordinary battle gets all eighteen mechanisms", state.live_moves_enabled and state.switch_move_rules_enabled and state.weather_rules_enabled and state.substitute_rules_enabled and state.transform_rules_enabled)
		var actor: CreatureInstance = ui.session.player_active()
		var target := state.opponent_of(actor.instance_id)
		_set_moves(actor, [move])
		_set_moves(target, [&"tackle"])
		actor.stats.max_hp = 2000
		actor.current_hp = 1500
		actor.stats.speed = 10000
		target.stats.max_hp = 2000
		target.current_hp = 2000
		ui._refresh_view()
		var events: Array[BattleEvent] = ui.submit_player_move(move)
		check("ordinary move accepted without F-key preset", _count(events, BattleEvent.ACTION_REJECTED) == 0 and _count(events, BattleEvent.ACTION_USED) == 2)
		var snapshot := state.to_dict().duplicate(true)
		await _drain(ui, String(move))
		check("catalog playback never changes mechanics/RNG", snapshot == state.to_dict())
		check("live bodies and controls restored", ui._arena._player_visible and ui._arena._enemy_visible and not ui._playback._live_catalog.preview.visible)
		await _capture(String(move) + "_after")
		ui.submit_capture_ball(&"master_ball")
		await _drain(ui, "capture")
		check("capture clears native catalog and returns to map", not ui._playback._live_catalog.preview.visible and ui.continue_after_completion())
	_configure(scene)
	var fallback_ui: Control = await _encounter(scene)
	var fallback_actor: CreatureInstance = fallback_ui.session.player_active()
	_set_moves(fallback_actor, [&"splash"])
	fallback_actor.stats.max_hp = 2000
	fallback_actor.current_hp = 2000
	fallback_ui.session.current_wild().stats.max_hp = 2000
	fallback_ui.session.current_wild().current_hp = 2000
	_set_moves(fallback_ui.session.current_wild(), [&"tackle"])
	fallback_ui._refresh_view()
	check("normal UI offers virtual Struggle without a slot", fallback_ui.available_move_ids() == ([&"struggle"] as Array[StringName]) and fallback_ui.move_button_count() == 1)
	var fallback_events: Array[BattleEvent] = fallback_ui.submit_player_move(&"struggle")
	await _drain(fallback_ui, "virtual_fallback")
	check("normal UI fallback executes without softlock or permanent move", _count(fallback_events, BattleEvent.ACTION_USED) == 2 and fallback_actor.move_ids == ([&"splash"] as Array[StringName]) and fallback_actor.current_hp < 1501)
	fallback_ui.submit_capture_ball(&"master_ball")
	await _drain(fallback_ui, "fallback_capture")
	check("fallback encounter returns normally", fallback_ui.continue_after_completion())
	_configure(scene)
	check("normal trainer battle starts", scene.start_demo_trainer_battle())
	var trainer: Control = scene.trainer_battle_presentation
	trainer._playback.set_process(false)
	var state: BattleState = trainer.session.battle_state()
	for id: StringName in state.participant_ids:
		var creature := state.creature(id)
		creature.stats.max_hp = 2000
		creature.current_hp = 2000
		_set_moves(creature, [&"tackle"])
	_set_moves(trainer.session.player_active(), [&"u_turn"])
	trainer.session.player_active().stats.speed = 10000
	trainer._refresh_view()
	var events: Array[BattleEvent] = trainer.submit_player_move(&"u_turn")
	check("normal trainer brain accepts integrated move", not events.is_empty() and _count(events, BattleEvent.ACTION_REJECTED) == 0)
	await _drain(trainer, "trainer_pivot")
	check("normal trainer UI offers human replacement", state.phase == BattleState.WAITING_FOR_SWITCH and trainer.switch_control_enabled())
	await _capture("trainer_choice")
	var incoming: StringName = trainer.available_switch_instance_ids()[-1]
	var resumed: Array[BattleEvent] = trainer.submit_player_switch(incoming)
	await _drain(trainer, "trainer_resume")
	check("normal trainer UI resumes without new turn", state.turn == 1 and state.phase == BattleState.WAITING_FOR_ACTIONS and _count(resumed, BattleEvent.TURN_ENDED) == 1 and trainer.session.last_error.is_empty())
	await _capture("trainer_resumed")
	scene.queue_free()
	await process_frame
	_game_completed = true


func _configure(scene: Node) -> void:
	for field: LineEdit in scene.test_panel._player_species_inputs: field.text = ""
	for field: LineEdit in scene.test_panel._trainer_species_inputs: field.text = ""
	for index in 3:
		scene.test_panel._player_species_inputs[index].text = ["charizard", "pikachu", "blastoise"][index]
		scene.test_panel._player_level_inputs[index].value = 50
		scene.test_panel._trainer_species_inputs[index].text = ["wailord", "pikachu", "blastoise"][index]
		scene.test_panel._trainer_level_inputs[index].value = 50
	scene.test_panel._wild_species_input.text = "wailord"
	scene.test_panel._wild_min_level.value = 50
	scene.test_panel._wild_max_level.value = 50
	scene.test_panel._encounter_chance.value = 100
	scene.restart_field_run()


func _encounter(scene: Node) -> Control:
	scene.player.set_physics_process(false)
	scene.player.global_position = Vector2(420, 150)
	scene.player.reset_step_meter()
	await physics_frame
	for n in 24:
		scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		await physics_frame
		if scene.has_active_demo_battle(): break
	check("ordinary real wild encounter", scene.has_active_demo_battle())
	scene.battle_presentation._playback.set_process(false)
	return scene.battle_presentation


func _set_moves(creature: CreatureInstance, ids: Array[StringName]) -> void:
	creature.moveset.clear()
	creature.move_ids.clear()
	for id: StringName in ids: creature.add_move(id, catalog)


func _drain(ui: Control, label: String) -> void:
	var steps := 0
	while ui._playback.is_playing() and steps < 160:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		if entry.has("catalog_clip"):
			ui._playback.advance(float(entry.duration) * 0.5)
			check("lazy clip visible with genuine source bodies", ui._playback._live_catalog.preview.visible and not ui._playback._live_catalog.preview._arena.visible)
			if label in ["absorb", "swords_dance", "recover", "double_team"] and entry.catalog_origin == "back": await _capture(label + "_native")
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		steps += 1
	check("bounded live playback " + label, not ui._playback.is_playing())


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame
	RenderingServer.force_draw(false)
	var path := OUTPUT_LIVE + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
