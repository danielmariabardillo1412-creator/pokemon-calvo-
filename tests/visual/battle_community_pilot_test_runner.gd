extends SceneTree

const Pilot = preload("res://scenes/visual/battle_community_move_pilot.gd")
const Plan = preload("res://scenes/visual/battle_timeline_plan.gd")
const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
var _passed := 0
var _failures: Array[String] = []
var _captures := 0
var _capture := false
var _pilots_seen := 0
const OUTPUT := "res://.godot/battle_community_checks/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var ui = scene.battle_presentation
	_check("small_pack_available", ui._playback._community.available)
	_check("small_pack_ten_clips", ui._playback._community.preview.pack.get("clips", []).size() == 10)
	_unit_semantics(ui._playback._community, scene._catalogs)
	_configure(scene)
	await _encounter(scene)
	var state: BattleState = ui.session.battle_state()
	_check("natural_learnset_kept_ivy", &"ivy_cudgel" in ui.session.player_active().move_ids)
	_fixture_moves(state)
	ui.session.current_wild().stats.max_hp = 2000
	ui.session.current_wild().current_hp = 2000
	ui._refresh_view()
	var events: Array[BattleEvent] = ui.submit_player_move(&"ivy_cudgel")
	_check("real_turn_resolved", not events.is_empty())
	var resolved := state.to_dict().duplicate(true)
	var capture_rng: int = scene._capture_rng.state
	var escape_rng: int = scene._escape_rng.state
	_check("both_real_hits_bound", _resource_count(ui._playback._sequence) == 2)
	_check("commands_locked", ui.submit_player_move(&"ivy_cudgel").is_empty() and ui._move_buttons[0].disabled)
	await _drain(ui, "wild")
	_check("no_domain_or_battle_rng_mutation", state.to_dict() == resolved)
	_check("no_external_rng_mutation", scene._capture_rng.state == capture_rng and scene._escape_rng.state == escape_rng)
	_check("resource_cleared_after_turn", not ui._playback._community.preview.visible and ui._playback._community.preview.visible_cells() == 0)
	# Re-enter a confirmed-hit clip, then cancel before its impact cue.
	ui.submit_player_move(&"ivy_cudgel")
	while ui._playback.is_playing() and not ui._playback._sequence[ui._playback._index].has("community_clip"):
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
	_check("cancel_fixture_reached_clip", ui._playback.is_playing())
	var pending: String = ui._playback._sequence[ui._playback._index].text
	var cancel_state := state.to_dict().duplicate(true)
	ui.hide()
	_check("cancel_clears_resource", not ui._playback.is_playing() and not ui._playback._community.preview.visible)
	_check("cancel_flushes_pending_text", pending in ui._event_log.text)
	_check("cancel_preserves_domain", state.to_dict() == cancel_state)
	ui.open_for_active_battle()
	_check("reopen_has_no_resource", not ui._playback._community.preview.visible)
	# A real miss: only test creature stages/RNG are set, never move definitions.
	ui.session.player_active().stat_stages.change(StatStages.ACCURACY, -6)
	ui.session.current_wild().stat_stages.change(StatStages.EVASION, 6)
	state.rng_state = 42
	events = ui.submit_player_move(&"ivy_cudgel")
	var missed := false
	for event: BattleEvent in events:
		missed = missed or event.kind == BattleEvent.MOVE_MISSED and event.actor_id == ui.session.player_active().instance_id
	_check("real_miss_fixture", missed)
	var player_clips := 0
	for step: Dictionary in ui._playback._sequence:
		player_clips += int(step.get("community_clip", "") == "ivy_cudgel/back")
	_check("real_miss_does_not_play_hit", player_clips == 0)
	await _drain(ui, "miss")
	ui.submit_capture_ball(&"master_ball")
	await _drain(ui, "cleanup")
	_check("capture_returns_after_pilot", ui.continue_after_completion())
	# The trainer session can release BattleState after KO before replay starts.
	_configure(scene)
	_check("trainer_started", scene.start_demo_trainer_battle())
	var trainer = scene.trainer_battle_presentation
	trainer._playback.set_process(false)
	trainer._arena.set_process(false)
	_fixture_moves(trainer.session.battle_state())
	trainer.session.opponent_active().current_hp = 1
	trainer.session.player_active().stats.speed = 10000
	trainer._refresh_view()
	events = trainer.submit_player_move(&"ivy_cudgel")
	_check("trainer_ko_completed", not events.is_empty() and trainer.session.battle_state() == null)
	_check("trainer_ko_clip_survives_settlement", _resource_count(trainer._playback._sequence) == 1)
	await _drain(trainer, "trainer_ko")
	_check("trainer_ko_hidden_after_pilot", not trainer._arena._enemy_visible and not trainer._playback._community.preview.visible)
	_check("trainer_return", trainer.continue_after_completion())
	# Normal engine frame processing, also through wild KO settlement. No forced
	# moveset here: level-50 Ogerpon already knows Ivy Cudgel from its real learnset.
	_configure(scene)
	await _encounter(scene)
	ui.session.current_wild().current_hp = 1
	ui._refresh_view()
	ui._playback.set_process(true)
	ui._arena.set_process(true)
	var owned_id: StringName = ui.session.player_active().instance_id
	events = ui.submit_player_move(&"ivy_cudgel")
	_check("natural_wild_ko_resolved", not events.is_empty() and ui.session.battle_state() == null)
	var owned: CreatureInstance = ui.session.player.owned_creature(owned_id)
	var settled: Dictionary = owned.to_dict().duplicate(true) if owned != null else {}
	var rng_after: int = scene._capture_rng.state
	var deadline := Time.get_ticks_msec() + 12000
	var frames_advanced := false
	while ui._playback.is_playing() and Time.get_ticks_msec() < deadline:
		await process_frame
		frames_advanced = frames_advanced or ui._playback._community.preview.current_frame > 5
	_check("natural_clock_completed", not ui._playback.is_playing())
	_check("natural_clock_advanced_resource", frames_advanced)
	_check("natural_clock_preserved_settlement", owned != null and not settled.is_empty() and owned.to_dict() == settled and scene._capture_rng.state == rng_after)
	_check("natural_ko_keeps_target_hidden", not ui._arena._enemy_visible and not ui._playback._community.preview.visible)
	_check("natural_ko_return", ui.continue_after_completion())
	await _exercise_tera(scene)
	await _exercise_elementals(scene)
	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed,
		"failures": _failures, "captures": _captures, "clips_seen": _pilots_seen,
		"pack_sha256": FileAccess.get_sha256(Pilot.PACK),
		"binding_sha256": FileAccess.get_sha256("res://scenes/visual/battle_community_move_pilot.gd"),
		"playback_sha256": FileAccess.get_sha256("res://scenes/visual/battle_animation_playback.gd"),
		"preview_sha256": FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd"),
		"field_sha256": FileAccess.get_sha256("res://scenes/visual/field_demo.gd"),
		"test_sha256": FileAccess.get_sha256("res://tests/visual/battle_community_pilot_test_runner.gd"),
		"dataset_sha256": FileAccess.get_sha256("res://data/normalized/pokemon_api.json"),
		"scope": "Five whitelisted move visuals bound to real damage; elemental statuses remain authoritative, no new mechanics, full move coverage or blanket partial admission"}
	for filename: String in ["result.json", "gpu_result.json" if _capture else "headless_result.json"]:
		var file := FileAccess.open(OUTPUT + filename, FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "\t") + "\n")
		file.close()
	print("BATTLE_COMMUNITY_PILOT_RESULT " + JSON.stringify(result))
	scene.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _unit_semantics(pilot: Node, catalogs: DefinitionCatalog, move: String = "ivy_cudgel") -> void:
	var a := {"instance_id": "a", "species": "ogerpon", "side": "back", "hp": 100, "max_hp": 100, "visible": true}
	var b := {"instance_id": "b", "species": "wailord", "side": "front", "hp": 100, "max_hp": 100, "visible": true}
	var before := {"views": {"back": a.duplicate(), "front": b.duplicate()}, "creatures": {"a": a, "b": b},
		"moves": {move: Visuals.metadata(catalogs.move(StringName(move)))}}
	var action := {"kind": String(BattleEvent.ACTION_USED), "move_id": move, "actor_id": "a", "target_id": "b"}
	for row: Array in [[BattleEvent.DAMAGE_APPLIED, 20, "a", "b", true], [BattleEvent.DAMAGE_APPLIED, 0, "a", "b", false],
		[BattleEvent.MOVE_MISSED, 0, "a", "b", false], [BattleEvent.RECOIL_DAMAGE, 20, "a", "a", false],
		[BattleEvent.DAMAGE_APPLIED, 20, "b", "a", false], [BattleEvent.STATUS_DAMAGE, 20, "a", "b", false]]:
		var event := {"kind": String(row[0]), "move_id": move, "actor_id": row[2], "target_id": row[3], "amount": row[1]}
		var steps := Plan.build([action, event], before)
		var original := steps.duplicate(true)
		var decorated: Array[Dictionary] = pilot.decorate(steps, before)
		_check("gate/%s/%s/%s" % [row[0], row[1], row[2]], (_resource_count(decorated) > 0) == bool(row[4]))
		if row[4]:
			_check("community_replaces_generic_hit", not decorated.back().has("move_visual"))
			_check("no_double_cast", decorated[0].has("community_preparation") and not decorated[0].has("move_visual"))
		_check("pure_decoration", steps == original)
	var plan := Plan.build([action, {"kind": String(BattleEvent.DAMAGE_APPLIED), "move_id": move, "actor_id": "a", "target_id": "b", "amount": 20}], before)
	var rejected: Array = ["DATA_ONLY", "RUNTIME_SUPPORTED", "UNSUPPORTED"] if move == "tera_blast" else ["DATA_ONLY", "PARTIAL_RUNTIME", "UNSUPPORTED"]
	for classification: String in rejected:
		var unsupported := before.duplicate(true)
		unsupported.moves[move].classification = classification
		_check("classification_gate/" + classification, _resource_count(pilot.decorate(plan, unsupported)) == 0)
	if move == "tera_blast":
		for row: Array in [["type_id", "fire"], ["category", "physical"], ["power", 100], ["target", "user"], ["effects_empty", false]]:
			var changed := before.duplicate(true)
			changed.moves[move][row[0]] = row[1]
			_check("tera_contract_rejects/" + String(row[0]), _resource_count(pilot.decorate(plan, changed)) == 0)
		for id: String in ["nature_power", "secret_power", "hard_press", "max_flare"]:
			var changed := before.duplicate(true)
			changed.moves[id] = changed.moves[move].duplicate(true)
			var forged := plan.duplicate(true)
			for step: Dictionary in forged:
				if step.has("move_visual"):
					step.move_visual.move_id = id
			_check("no_blanket_partial_admission/" + id, _resource_count(pilot.decorate(forged, changed)) == 0)
	if move in ["flamethrower", "thunderbolt", "ice_beam"]:
		for row: Array in [["type_id", "ghost"], ["category", "physical"], ["power", 100], ["target", "user"]]:
			var changed := before.duplicate(true)
			changed.moves[move][row[0]] = row[1]
			_check("elemental_contract_rejects/%s/%s" % [move, row[0]], _resource_count(pilot.decorate(plan, changed)) == 0)
	var unavailable := Pilot.new()
	root.add_child(unavailable)
	var arena := Control.new()
	root.add_child(arena)
	unavailable.configure(arena, "res://.godot/battle_ivy_pilot/not_present.json")
	_check("missing_pack_falls_back", not unavailable.available and unavailable.decorate(plan, before) == plan)
	unavailable.queue_free()
	arena.queue_free()
	var legacy := Pilot.new()
	root.add_child(legacy)
	var legacy_arena := Control.new()
	root.add_child(legacy_arena)
	legacy.configure(legacy_arena, Pilot.LEGACY_PACK)
	_check("legacy_pack_accepted", legacy.available)
	_check("legacy_does_not_invent_tera", not legacy._indices.has("tera_blast/back"))
	legacy.queue_free()
	legacy_arena.queue_free()
	var base := Pilot.new()
	root.add_child(base)
	var base_arena := Control.new()
	root.add_child(base_arena)
	base.configure(base_arena, Pilot.BASE_PACK)
	_check("base_pair_accepted", base.available and base._indices.size() == 4 and not base._indices.has("flamethrower/back"))
	base.queue_free()
	base_arena.queue_free()


func _drain(ui: Control, label: String) -> void:
	var limit := 0
	while ui._playback.is_playing() and limit < 100:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		if entry.has("community_clip"):
			_pilots_seen += 1
			var side := String(entry.side)
			var initial := int(entry.views[side].hp)
			var final := int(entry.after_views[side].hp)
			ui._playback.advance(float(entry.community_impact) - 0.05)
			var shown: int = ui.displayed_player_hp() if side == "back" else ui.displayed_enemy_hp()
			_check("hp_waits_for_impact/" + label, shown == initial)
			_check("text_waits_for_impact/" + label, not ui._playback._community_text_shown)
			var preview: Control = ui._playback._community.preview
			var expected_particles := 0
			for cel: Variant in preview.clip.frames[preview.current_frame]:
				if cel is Array and int(cel[7]) >= 0 and int(cel[6]) == 1 and float(cel[8]) > 0.0:
					expected_particles += 1
			# Thunderbolt intentionally pauses before its second strike; a blank
			# source frame is not a failed render or an invitation to invent cels.
			_check("particle_sample_matches_source/" + label, preview.visible and preview.visible_cells() == expected_particles)
			_check("no_duplicate_bodies/" + label, not ui._playback._community.preview._arena.visible and not ui._playback._community.preview._sprites[0].visible and not ui._playback._community.preview._sprites[1].visible)
			_check("no_fullscreen_plates/" + label, not ui._playback._community.preview._layers.back.visible and not ui._playback._community.preview._layers.front.visible)
			await _shot(ui, label + "_" + String(entry.community_clip).replace("/", "_") + "_windup")
			ui._playback.advance(0.25)
			shown = ui.displayed_player_hp() if side == "back" else ui.displayed_enemy_hp()
			# A 1-HP KO rounds to 1 until halfway through the interpolation window.
			_check("hp_moves_or_rounds_single_hp/" + label, shown >= final and shown <= initial and (shown < initial or initial - final == 1))
			_check("text_revealed_at_impact/" + label, String(entry.text) in ui._event_log.text)
			_check("generic_overlay_not_doubled/" + label, ui._arena._move_visual.is_empty())
			await _shot(ui, label + "_" + String(entry.community_clip).replace("/", "_") + "_impact")
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		limit += 1
	_check("drain_bounded/" + label, not ui._playback.is_playing())


func _shot(_ui: Control, name: String) -> void:
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	for side: String in ["back", "front"]:
		_check("actual_body_anchor/" + name + side, _ui._arena._visual_centers.has(side) and Vector2(_ui._playback._community.preview._actors[side].center).is_equal_approx(Vector2(_ui._arena._visual_centers.get(side, Vector2.INF))))
	if "tera_blast" in name:
		var preview: Control = _ui._playback._community.preview
		var entry: Dictionary = _ui._playback._sequence[_ui._playback._index]
		_check("tera_reaches_actual_target/" + name, preview.affine_particle_path and preview._sprites[2].position.is_equal_approx(Vector2(preview._actors[String(entry.side)].center)))
	elif name.ends_with("_impact") and ("flamethrower" in name or "thunderbolt" in name or "ice_beam" in name):
		var entry: Dictionary = _ui._playback._sequence[_ui._playback._index]
		var side := String(entry.side)
		var nearest := INF
		for sprite: Sprite2D in _ui._playback._community.preview._sprites:
			if sprite.visible:
				nearest = minf(nearest, sprite.position.distance_to(_ui._arena._visual_centers[side]))
		_check("elemental_hits_target_envelope/" + name, nearest < maxf(24.0, float(_ui._arena._visual_radii[side])))
	_check("capture/" + name, root.get_texture().get_image().save_png(OUTPUT + name + ".png") == OK)
	_captures += 1


func _configure(scene: Node) -> void:
	for field: LineEdit in scene.test_panel._player_species_inputs:
		field.text = ""
	for field: LineEdit in scene.test_panel._trainer_species_inputs:
		field.text = ""
	scene.test_panel._player_species_inputs[0].text = "ogerpon"
	scene.test_panel._player_level_inputs[0].value = 50
	scene.test_panel._player_species_inputs[1].text = "pikachu"
	scene.test_panel._player_level_inputs[1].value = 50
	scene.test_panel._trainer_species_inputs[0].text = "wailord"
	scene.test_panel._trainer_level_inputs[0].value = 50
	scene.test_panel._wild_species_input.text = "wailord"
	scene.test_panel._wild_min_level.value = 50
	scene.test_panel._wild_max_level.value = 50
	scene.test_panel._encounter_chance.value = 100
	scene.restart_field_run()
	scene.player.set_physics_process(false)
	scene.battle_presentation._playback.set_process(false)
	scene.battle_presentation._arena.set_process(false)


func _encounter(scene: Node) -> void:
	scene.player.global_position = Vector2(420, 150)
	scene.player.reset_step_meter()
	await physics_frame
	for step in 24:
		scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		await physics_frame
		if scene.has_active_demo_battle():
			break
	_check("real_grass_encounter", scene.has_active_demo_battle())


func _fixture_moves(state: BattleState, move: StringName = &"ivy_cudgel", pp: int = 10) -> void:
	for id: StringName in state.participant_ids:
		var creature := state.creature(id)
		creature.moveset.assign([BattleMoveSlot.new(move, pp, pp)])
		creature.move_ids.assign([move])


func _exercise_tera(scene: Node) -> void:
	var ui = scene.battle_presentation
	_unit_semantics(ui._playback._community, scene._catalogs, "tera_blast")
	_configure(scene)
	_check("manual_tera_preset", scene.prepare_tera_visual_test())
	_check("manual_tera_explicit_notice", "ENSAYO TERA NORMAL" in scene._notice_label.text)
	_check("manual_tera_not_natural_learnset", &"tera_blast" in scene._session.player.party.get_active().move_ids)
	if _capture:
		await process_frame
		await RenderingServer.frame_post_draw
		_check("manual_preset_map_capture", root.get_texture().get_image().save_png(OUTPUT + "tera_test_preset_map.png") == OK)
		_captures += 1
	await _encounter(scene)
	_check("preset_blocked_during_battle", not scene.prepare_tera_visual_test())
	var state: BattleState = ui.session.battle_state()
	_fixture_moves(state, &"tera_blast")
	for id: StringName in state.participant_ids:
		state.creature(id).stats.max_hp = 2000
		state.creature(id).current_hp = 2000
	ui._refresh_view()
	var events: Array[BattleEvent] = ui.submit_player_move(&"tera_blast")
	_check("tera_both_real_hits", not events.is_empty() and _resource_count(ui._playback._sequence) == 2)
	_check("tera_input_locked", ui.submit_player_move(&"tera_blast").is_empty())
	var resolved := state.to_dict().duplicate(true)
	var capture_rng: int = scene._capture_rng.state
	var escape_rng: int = scene._escape_rng.state
	for step: Dictionary in ui._playback._sequence:
		if step.has("community_clip"):
			_check("tera_own_timing", is_equal_approx(step.duration, 3.5) and is_equal_approx(step.community_impact, 2.35) and is_equal_approx(step.community_hp_end, 2.95))
	await _drain(ui, "tera_wild")
	_check("tera_domain_rng_unchanged", state.to_dict() == resolved and scene._capture_rng.state == capture_rng and scene._escape_rng.state == escape_rng)
	_check("tera_layers_cleared", not ui._playback._community.preview.visible and ui._playback._community.preview.visible_cells() == 0)
	ui.submit_player_move(&"tera_blast")
	while ui._playback.is_playing() and not ui._playback._sequence[ui._playback._index].has("community_clip"):
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
	_check("tera_cancel_reached_clip", ui._playback.is_playing())
	resolved = state.to_dict().duplicate(true)
	ui.hide()
	_check("tera_cancel_clears", not ui._playback.is_playing() and not ui._playback._community.preview.visible)
	_check("tera_cancel_preserves_domain", state.to_dict() == resolved)
	ui.open_for_active_battle()
	ui.session.player_active().stat_stages.change(StatStages.ACCURACY, -6)
	ui.session.current_wild().stat_stages.change(StatStages.EVASION, 6)
	events = ui.submit_player_move(&"tera_blast")
	var missed := false
	for event: BattleEvent in events:
		missed = missed or event.kind == BattleEvent.MOVE_MISSED and event.actor_id == ui.session.player_active().instance_id
	_check("tera_real_miss", missed)
	var player_clips := 0
	for step: Dictionary in ui._playback._sequence:
		player_clips += int(step.get("community_clip", "") == "tera_blast/back")
	_check("tera_miss_has_no_hit", player_clips == 0)
	await _drain(ui, "tera_miss")
	ui.submit_capture_ball(&"master_ball")
	await _drain(ui, "tera_capture")
	_check("tera_capture_return", ui.continue_after_completion())
	scene.restart_field_run()
	_check("restart_restores_learnset", not &"tera_blast" in scene._session.player.party.get_active().move_ids)
	_configure(scene)
	_check("tera_trainer_started", scene.start_demo_trainer_battle())
	var trainer = scene.trainer_battle_presentation
	trainer._playback.set_process(false)
	trainer._arena.set_process(false)
	_fixture_moves(trainer.session.battle_state(), &"tera_blast")
	trainer.session.opponent_active().current_hp = 1
	trainer.session.player_active().stats.speed = 10000
	trainer._refresh_view()
	events = trainer.submit_player_move(&"tera_blast")
	_check("tera_trainer_ko_settled", not events.is_empty() and trainer.session.battle_state() == null and _resource_count(trainer._playback._sequence) == 1)
	await _drain(trainer, "tera_trainer_ko")
	_check("tera_trainer_clean", not trainer._arena._enemy_visible and not trainer._playback._community.preview.visible)
	_check("tera_trainer_return", trainer.continue_after_completion())
	_configure(scene)
	_check("tera_natural_clock_preset", scene.prepare_tera_visual_test())
	await _encounter(scene)
	ui.session.current_wild().current_hp = 1
	ui.session.player_active().stats.speed = 10000
	ui._refresh_view()
	ui._playback.set_process(true)
	ui._arena.set_process(true)
	var owned_id: StringName = ui.session.player_active().instance_id
	events = ui.submit_player_move(&"tera_blast")
	_check("tera_natural_clock_ko", not events.is_empty() and ui.session.battle_state() == null)
	var owned: CreatureInstance = ui.session.player.owned_creature(owned_id)
	var settled: Dictionary = owned.to_dict().duplicate(true)
	var deadline := Time.get_ticks_msec() + 12000
	var advanced := false
	while ui._playback.is_playing() and Time.get_ticks_msec() < deadline:
		await process_frame
		advanced = advanced or ui._playback._community.preview.current_frame >= 48
	_check("tera_natural_clock_completed", advanced and not ui._playback.is_playing())
	_check("tera_natural_clock_preserved_settlement", owned.to_dict() == settled)
	_check("tera_natural_clock_cleanup", not ui._arena._enemy_visible and not ui._playback._community.preview.visible)
	_check("tera_natural_return", ui.continue_after_completion())


func _exercise_elementals(scene: Node) -> void:
	var ui = scene.battle_presentation
	for move: StringName in [&"flamethrower", &"thunderbolt", &"ice_beam"]:
		_unit_semantics(ui._playback._community, scene._catalogs, String(move))
		_configure(scene)
		_check("elemental_manual_preset/" + move, scene.cycle_elemental_visual_test())
		_check("elemental_cycle_selects/" + move, scene._session.player.party.get_active().move_ids == [move])
		if _capture and move == &"flamethrower":
			await process_frame
			await RenderingServer.frame_post_draw
			_check("elemental_preset_map_capture", root.get_texture().get_image().save_png(OUTPUT + "elemental_test_preset_map.png") == OK)
			_captures += 1
		await _encounter(scene)
		var preset_index: int = scene._elemental_test_index
		_check("elemental_preset_locked/" + move, not scene.cycle_elemental_visual_test() and scene._elemental_test_index == preset_index)
		var state: BattleState = ui.session.battle_state()
		var definition: MoveDefinition = scene._catalogs.move(move)
		_fixture_moves(state, move, definition.pp)
		for id: StringName in state.participant_ids:
			var creature := state.creature(id)
			creature.stats.max_hp = 2000
			creature.current_hp = 2000
			creature.ability_id = &"" # No ability immunity in this effect/secondary-status fixture.
		ui.session.player_active().stats.speed = 10000
		var seed_value := _elemental_seed(state, scene._catalogs, move, false)
		_check("elemental_both_hit_seed/" + move, seed_value > 0)
		state.rng_state = seed_value
		ui.session._battle_server._rng = SeededRandomSource.new(seed_value)
		ui._refresh_view()
		var events: Array[BattleEvent] = ui.submit_player_move(move)
		_check("elemental_both_real_hits/" + move, not events.is_empty() and _resource_count(ui._playback._sequence) == 2)
		_check("elemental_pp_once/" + move, ui.session.player_active().move_slot(move).current_pp == definition.pp - 1)
		for step: Dictionary in ui._playback._sequence:
			if step.has("community_clip"):
				var origin := String(step.community_clip).get_file()
				var expected_frames := 20 if move == &"flamethrower" and origin == "front" else 19 if move == &"flamethrower" else 27 if move == &"thunderbolt" else 28
				_check("elemental_native_duration/%s/%s" % [move, origin], is_equal_approx(step.duration, float(expected_frames) / 20.0))
		var resolved := state.to_dict().duplicate(true)
		var capture_rng: int = scene._capture_rng.state
		var escape_rng: int = scene._escape_rng.state
		await _drain(ui, "elemental_" + String(move))
		_check("elemental_domain_rng_unchanged/" + move, state.to_dict() == resolved and scene._capture_rng.state == capture_rng and scene._escape_rng.state == escape_rng)
		# Find a seeded real secondary effect via detached server simulation, then
		# execute it once through the normal field command. Never force a status or
		# replace a move definition, reroll during replay, or change probabilities.
		seed_value = _elemental_seed(state, scene._catalogs, move, true)
		_check("elemental_secondary_seed/" + move, seed_value > 0)
		state.rng_state = seed_value
		ui.session._battle_server._rng = SeededRandomSource.new(seed_value)
		events = ui.submit_player_move(move)
		var status_events := 0
		var expected_status: String = {"flamethrower": "burn", "thunderbolt": "paralysis", "ice_beam": "freeze"}[String(move)]
		for event: BattleEvent in events:
			status_events += int(event.kind == BattleEvent.STATUS_APPLIED and event.actor_id == ui.session.player_active().instance_id and event.target_id == ui.session.current_wild().instance_id and event.metadata.get("status_id") == expected_status)
		_check("elemental_real_secondary/" + move, status_events > 0)
		for step: Dictionary in ui._playback._sequence:
			if step.has("community_clip"):
				_check("secondary_does_not_duplicate_hit/" + move, step.event_kind == String(BattleEvent.DAMAGE_APPLIED))
		resolved = state.to_dict().duplicate(true)
		await _drain(ui, "elemental_proc_" + String(move))
		_check("elemental_secondary_domain_unchanged/" + move, state.to_dict() == resolved)
		_check("elemental_clean_after_proc/" + move, not ui._playback._community.preview.visible and ui._arena._move_visual.is_empty())
		ui.submit_capture_ball(&"master_ball")
		await _drain(ui, "elemental_cleanup_" + String(move))
		_check("elemental_capture_return/" + move, ui.continue_after_completion())
	var initial_ids: Array = scene._session.player.party.get_active().move_ids.duplicate()
	_check("unknown_preset_rejected", not scene.prepare_visual_move_test(&"max_flare") and scene._session.player.party.get_active().move_ids == initial_ids)
	# Cycle wraps; ordinary restart restores the factory's exact natural moveset.
	scene.restart_field_run()
	var natural: Array = scene._session.player.party.get_active().move_ids.duplicate()
	_check("elemental_cycle_wraps", scene.cycle_elemental_visual_test() and scene._session.player.party.get_active().move_ids == [&"flamethrower"])
	scene.restart_field_run()
	_check("elemental_restart_restores_natural", scene._session.player.party.get_active().move_ids == natural)


func _elemental_seed(state: BattleState, catalogs: DefinitionCatalog, move: StringName, require_status: bool) -> int:
	var actor_id: StringName = state.active_for_side(&"side_a").instance_id
	var target_id: StringName = state.active_for_side(&"side_b").instance_id
	var expected_status: String = {"flamethrower": "burn", "thunderbolt": "paralysis", "ice_beam": "freeze"}[String(move)]
	for seed_value in range(1, 301):
		var copy := BattleState.from_dict(state.to_dict())
		copy.rng_state = seed_value
		var server := AuthoritativeBattleServer.new(copy, catalogs)
		var events := server.submit_turn([
			BattleAction.new(copy.turn + 1, actor_id, move, target_id, BattleAction.MOVE, &"side_a"),
			BattleAction.new(copy.turn + 1, target_id, move, actor_id, BattleAction.MOVE, &"side_b")])
		var hits := 0
		var statuses := 0
		var actor_statuses := 0
		for event: BattleEvent in events:
			hits += int(event.move_id == move and event.kind == BattleEvent.DAMAGE_APPLIED)
			if event.kind == BattleEvent.STATUS_APPLIED:
				statuses += 1
				actor_statuses += int(event.actor_id == actor_id and event.target_id == target_id and event.metadata.get("status_id") == expected_status)
		if require_status and actor_statuses > 0 or not require_status and hits == 2 and statuses == 0:
			return seed_value
	return -1


func _resource_count(steps: Array[Dictionary]) -> int:
	var count := 0
	for step: Dictionary in steps:
		count += int(step.has("community_clip"))
	return count


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
