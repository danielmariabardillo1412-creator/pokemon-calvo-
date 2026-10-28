extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const StatusPilot = preload("res://scenes/visual/battle_status_switch_pilot.gd")
const Timeline = preload("res://scenes/visual/battle_timeline_plan.gd")
const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
const Arena = preload("res://scenes/visual/battle_art.gd")
const STATUS_OUTPUT := "res://.godot/status_switch_checks/"
var native_seen := {}


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(STATUS_OUTPUT)
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var arena := Arena.new()
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(arena)
	await process_frame
	var pilot := StatusPilot.new()
	root.add_child(pilot)
	pilot.configure(arena)
	await process_frame
	check("ten status sources available", pilot.available and pilot._indices.size() == 10)
	if not pilot.available:
		quit(1)
		return
	for move: StringName in Rules.STATUS_PHAZES + Rules.STATUS_PIVOTS:
		check("canonical status contract " + String(move), Rules.supports_status(catalog.move(move)))
		check("status never contact " + String(move), not Rules.execution_move(catalog.move(move)).makes_contact)
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13):
				await _status_case(move, side, seed_value, pilot, arena)
	_status_edges()
	_visual_gates(pilot)
	arena.queue_free()
	pilot.queue_free()
	await process_frame
	await _visual_cases()
	var hashes := {}
	for path: String in ["modules/battle/application/switch_move_rules.gd", "modules/battle/application/turn_executor.gd", "modules/battle/domain/battle_event.gd", "modules/battle/domain/battle_state.gd", "modules/battle/server/authoritative_battle_server.gd", "modules/gameplay/wild_adventure_session.gd", "scenes/visual/field_demo.gd", "scenes/visual/battle_status_switch_pilot.gd", "scenes/visual/battle_animation_playback.gd", "scenes/visual/battle_timeline_plan.gd", "scenes/visual/field_battle_presentation.gd", "tests/battle/status_switch_move_test_runner.gd", "tests/battle/switch_move_continuation_test_runner.gd", "tools/visual/build_status_switch_pilot.py", "data/normalized/pokemon_api.json", "data/raw/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "core_samples": samples, "native_clip_ids": native_seen.keys(), "captures": captures,
		"source_sha256": hashes, "pack_sha256": FileAccess.get_sha256(StatusPilot.STATUS_PACK),
		"mechanics_added": ["roar", "whirlwind", "teleport", "baton_pass", "parting_shot"],
		"remaining_unimplemented": ["ally_switch", "chilly_reception", "hail", "rain_dance", "sandstorm", "shed_tail", "snowscape", "substitute", "transform"],
		"scope": "Explicit singles pilot. Native sources unchanged. Core trainer format and both sides tested; full trainer UI/AI rollout remains pending.",
		"limitations": ["Baton Pass transfers stages and the declared currently represented volatile subset, not every future volatile mechanic.", "Prankster, ability suppression/Mold Breaker, Magic Coat, side shields and full Substitute/Dynamax interactions are not certified.", "All 19 global handoffs remain open until production rollout/interactions are certified."]}
	var file := FileAccess.open(STATUS_OUTPUT + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ", true) + "\n")
	print("STATUS_SWITCH_MOVES ", report.status, " checks=", checks, " core_samples=", samples.size(), " native_clips=", native_seen.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _projection(state: BattleState) -> Dictionary:
	var result := {"views": {}, "creatures": {}, "moves": {}, "switch_move_rules_enabled": state.switch_move_rules_enabled}
	for side: BattleSide in state.sides:
		var image_side := "back" if side.side_id == &"side_a" else "front"
		for id: StringName in side.party_ids:
			var c := state.creature(id)
			var row := {"instance_id": String(id), "species": String(c.species_id), "side": image_side, "name": String(c.species_id), "level": c.level, "hp": c.current_hp, "max_hp": c.stats.max_hp, "visible": not c.is_knocked_out()}
			result.creatures[String(id)] = row
			if id == side.active_id:
				result.views[image_side] = row.duplicate(true)
			for slot: BattleMoveSlot in c.moveset:
				result.moves[String(slot.move_id)] = Visuals.metadata(catalog.move(slot.move_id))
	return result


func _status_case(move: StringName, side: StringName, seed_value: int, pilot: Node, arena: Control) -> void:
	var f := _fixture(move, side, seed_value)
	var before := _projection(f.state)
	var label := "%s/%s/%d" % [move, side, seed_value]
	var pp: int = f.actor.move_slot(move).current_pp
	if move == &"baton_pass":
		f.actor.stat_stages.change(StatStages.ATTACK, 2)
		f.actor.stat_stages.change(StatStages.DEFENSE, -1)
		f.actor.status_state.add_volatile(&"focus_energy", {"stage": 2})
		f.actor.status_state.persistent_id = &"poison"
	var events := _reaction(f)
	check(label + " executes and consumes one PP", _count(events, BattleEvent.ACTION_USED) == 1 and f.actor.move_slot(move).current_pp == pp - 1)
	check(label + " successful status event", _count(events, BattleEvent.MOVE_EFFECT_RESOLVED) == 1)
	check(label + " no damage event", _count(events, BattleEvent.DAMAGE_APPLIED) == 0)
	var snapshot: Dictionary = f.server.snapshot().duplicate(true)
	var sequence: Array[Dictionary] = pilot.decorate(Timeline.build(_rows(events), before), before)
	check(label + " pure projection", snapshot == f.server.snapshot())
	var native_steps := []
	for step: Dictionary in sequence:
		if step.get("status_switch_native", false):
			native_steps.append(step)
	check(label + " exactly one native status clip", native_steps.size() == 1)
	if native_steps.size() == 1:
		var step: Dictionary = native_steps[0]
		check(label + " no fake HP change", step.views == step.after_views)
		if not native_seen.has(String(step.community_clip)):
			native_seen[String(step.community_clip)] = true
			arena.player_species = StringName(before.views.back.species)
			arena.enemy_species = StringName(before.views.front.species)
			pilot.show_entry(step, arena, float(step.community_impact) + 0.1)
			check(label + " particles visible", pilot.preview.visible_cells() > 0 and not pilot.preview._sprites[0].visible and not pilot.preview._sprites[1].visible and not pilot.preview._layers.back.visible and not pilot.preview._layers.front.visible)
			await _capture(String(step.community_clip).replace("/", "_") + "_native")
			pilot.clear()
	if move in Rules.STATUS_PIVOTS:
		check(label + " status pivot pauses", f.state.phase == BattleState.WAITING_FOR_SWITCH and _count(events, BattleEvent.TURN_ENDED) == 0)
		if move == &"parting_shot":
			check(label + " two stat drops before choosing", f.target.stat_stages.get_stage(StatStages.ATTACK) == -1 and f.target.stat_stages.get_stage(StatStages.SPECIAL_ATTACK) == -1)
		var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), catalog)
		check(label + " pending snapshot round trip", snapshot == restored.snapshot())
		var incoming := &"a3" if side == &"side_a" else &"b3"
		var continued: Array[BattleEvent] = f.server.submit_switch_choice(side, incoming, 1)
		var replayed: Array[BattleEvent] = restored.submit_switch_choice(side, incoming, 1)
		check(label + " restored continuation exact", _rows(continued) == _rows(replayed) and restored.snapshot() == f.server.snapshot())
		check(label + " one end turn", f.state.turn == 1 and _count(continued, BattleEvent.TURN_ENDED) == 1 and f.state.active_for_side(side).instance_id == incoming)
		if move == &"baton_pass":
			var c: CreatureInstance = f.state.creature(incoming)
			check(label + " stages and permitted volatile passed", c.stat_stages.get_stage(StatStages.ATTACK) == 2 and c.stat_stages.get_stage(StatStages.DEFENSE) == -1 and c.status_state.has_volatile(&"focus_energy"))
			check(label + " persistent status not passed", c.status_state.persistent_id == &"" and f.actor.status_state.persistent_id == &"poison" and f.actor.stat_stages.get_stage(StatStages.ATTACK) == 0 and not f.actor.status_state.has_volatile(&"focus_energy"))
		samples.append({"move": String(move), "side": String(side), "seed": seed_value, "events": _rows(events), "continuation": _rows(continued)})
	else:
		check(label + " forced change without input", _count(events, BattleEvent.SWITCHED) == 1 and f.state.phase == BattleState.WAITING_FOR_ACTIONS and f.state.opponent_of(f.actor.instance_id) != f.target)
		samples.append({"move": String(move), "side": String(side), "seed": seed_value, "events": _rows(events)})


func _status_edges() -> void:
	for move: StringName in Rules.STATUS_PHAZES + Rules.STATUS_PIVOTS:
		var f := _fixture(move)
		f.state.switch_move_rules_enabled = false
		var events := _reaction(f)
		check("legacy status still data only " + String(move), _count(events, BattleEvent.MOVE_EFFECT_RESOLVED) == 0 and _count(events, BattleEvent.SWITCHED) == 0 and f.state.phase == BattleState.WAITING_FOR_ACTIONS)
		f = _fixture(move)
		for id: StringName in f.state.participant_ids:
			if id not in f.state.active_ids:
				f.state.creature(id).current_hp = 0
		events = _reaction(f)
		check("no reserve no choice " + String(move), f.state.phase == BattleState.WAITING_FOR_ACTIONS and _count(events, BattleEvent.SWITCHED) == 0)
		check("parting still lowers stats without bench " + String(move), f.target.stat_stages.get_stage(StatStages.ATTACK) == (-1 if move == &"parting_shot" else 0))
	for move: StringName in Rules.STATUS_PHAZES:
		var selected := {}
		for seed_value in range(1, 25):
			var f := _fixture(move, &"side_a", seed_value)
			var events := _reaction(f)
			selected[String(_find(events, BattleEvent.SWITCHED).target_id)] = true
		check("seeded phaze explores both benches " + String(move), selected.size() == 2)
		for blocker: StringName in [&"suction_cups", &"guard_dog", &"ingrain", &"substitute", &"soundproof"]:
			var f := _fixture(move)
			if blocker in [&"ingrain", &"substitute"]:
				f.target.status_state.add_volatile(blocker)
			else:
				f.target.ability_id = blocker
			var events := _reaction(f)
			var should_block := blocker not in [&"substitute", &"soundproof"] or (blocker == &"soundproof" and move == &"roar")
			check("status phaze blocker " + String(move) + String(blocker), (_count(events, BattleEvent.SWITCHED) == 0) == should_block)
		for side: StringName in [&"side_a", &"side_b"]:
			for level in [49, 50, 51]:
				var f := _fixture(move, side)
				f.state.battle_kind = &"wild"
				f.actor.level = level
				var events := _reaction(f)
				check("wild status phaze level " + String(move) + String(side) + str(level), (f.state.phase == BattleState.FINISHED) == (level >= 50) and f.state.winner_id == &"" and _count(events, BattleEvent.SWITCHED) == 0)
	# Modern Teleport: owned Pokemon pivots even in a wild encounter, wild user flees.
	for side: StringName in [&"side_a", &"side_b"]:
		var f := _fixture(&"teleport", side)
		f.state.battle_kind = &"wild"
		f.actor.level = 1
		f.actor.status_state.add_volatile(&"ingrain")
		var events := _reaction(f)
		check("modern teleport " + String(side), (f.state.phase == BattleState.FINISHED) == (side == &"side_b") and (_count(events, BattleEvent.SWITCH_REQUESTED) == 1) == (side == &"side_a"))
	# Transfer excludes flinch/arbitrary flags and applies before on-entry abilities.
	var f := _fixture(&"baton_pass")
	f.actor.status_state.add_volatile(&"flinch")
	var payload: Dictionary = Rules.baton_payload(f.actor)
	check("flinch not passed", not payload.volatile.has("flinch"))
	f.actor.status_state.remove_volatile(&"flinch")
	f.actor.stat_stages.change(StatStages.ATTACK, 2)
	f.state.creature(&"a3").ability_id = &"intimidate"
	var events := _reaction(f)
	events = f.server.submit_switch_choice(&"side_a", &"a3", 1)
	check("baton entry ability still runs", f.state.creature(&"a3").stat_stages.get_stage(StatStages.ATTACK) == 2 and f.target.stat_stages.get_stage(StatStages.ATTACK) == -1 and _count(events, BattleEvent.ABILITY_TRIGGERED) == 1)
	for ability: StringName in [&"soundproof", &"clear_body", &"white_smoke", &"full_metal_body", &"hyper_cutter", &"contrary", &"simple", &"defiant", &"competitive", &"mirror_armor"]:
		f = _fixture(&"parting_shot")
		f.target.ability_id = ability
		events = _reaction(f)
		var blocked := ability in [&"soundproof", &"clear_body", &"white_smoke", &"full_metal_body"]
		check("parting ability pivot gate " + String(ability), (f.state.phase == BattleState.WAITING_FOR_SWITCH) == not blocked)
		var atk: int = f.target.stat_stages.get_stage(StatStages.ATTACK)
		var spa: int = f.target.stat_stages.get_stage(StatStages.SPECIAL_ATTACK)
		if ability == &"contrary": check("contrary reversed", atk == 1 and spa == 1)
		elif ability == &"simple": check("simple doubles", atk == -2 and spa == -2)
		elif ability == &"defiant": check("defiant twice", atk == 3 and spa == -1)
		elif ability == &"competitive": check("competitive twice", atk == -1 and spa == 3)
		elif ability == &"hyper_cutter": check("hyper cutter only attack", atk == 0 and spa == -1)
		elif ability == &"mirror_armor": check("mirror armor redirected", atk == 0 and spa == 0 and f.actor.stat_stages.get_stage(StatStages.ATTACK) == -1)
	f = _fixture(&"parting_shot")
	f.target.stat_stages.change(StatStages.ATTACK, -6)
	f.target.stat_stages.change(StatStages.SPECIAL_ATTACK, -6)
	events = _reaction(f)
	check("parting cannot pivot with both stats capped", f.state.phase == BattleState.WAITING_FOR_ACTIONS and _count(events, BattleEvent.SWITCH_EFFECT_FAILED) == 1)
	for move: StringName in [&"roar", &"whirlwind", &"parting_shot"]:
		f = _fixture(move)
		f.target.ability_id = &"magic_bounce"
		events = _reaction(f)
		check("one reflection " + String(move), _count(events, BattleEvent.MOVE_REFLECTED) == 1 and _count(events, BattleEvent.PP_CHANGED) == 1)
		if move == &"parting_shot":
			check("reflected parting uses reflector bench", f.state.pending_switch.get("side_id") == "side_b" and f.actor.stat_stages.get_stage(StatStages.ATTACK) == -1)
		else:
			check("reflected phaze changes original user", f.state.active_for_side(&"side_a").instance_id != &"a" and f.state.active_for_side(&"side_b").instance_id == &"b")
	var misses := 0
	for seed_value in range(1, 31):
		f = _fixture(&"parting_shot", &"side_a", seed_value)
		f.actor.stat_stages.change(StatStages.ACCURACY, -12)
		f.target.stat_stages.change(StatStages.EVASION, 12)
		events = _reaction(f)
		if _count(events, BattleEvent.MOVE_MISSED) > 0:
			misses += 1
			check("missed parting does nothing", _count(events, BattleEvent.MOVE_EFFECT_RESOLVED) == 0 and f.state.phase == BattleState.WAITING_FOR_ACTIONS and f.target.stat_stages.get_stage(StatStages.ATTACK) == 0)
	check("parting misses exercised", misses > 15)


func _visual_gates(pilot: Node) -> void:
	var f := _fixture(&"baton_pass")
	var before := _projection(f.state)
	var events := _reaction(f)
	var sequence := Timeline.build(_rows(events), before)
	before.switch_move_rules_enabled = false
	check("default presentation not promoted", pilot.decorate(sequence, before) == sequence)
	for id: String in StatusPilot.PROFILES:
		var metadata := Visuals.metadata(catalog.move(StringName(id)))
		check("status metadata accepted " + id, pilot._accepts(id, metadata))
		metadata.power = 1
		check("wrong metadata rejected " + id, not pilot._accepts(id, metadata))
	var fallback := StatusPilot.new()
	var arena := Control.new()
	root.add_child(arena)
	root.add_child(fallback)
	fallback.configure(arena, "res://.godot/no_status_pack_here.json")
	before.switch_move_rules_enabled = true
	check("missing pack fallback", not fallback.available and fallback.decorate(sequence, before) == sequence)
	fallback.queue_free()
	arena.queue_free()


func _visual_cases() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	for n in 4: await process_frame
	for index in 5:
		check("F8 preset ready", scene.cycle_status_switch_test())
		scene.player.set_physics_process(false)
		var move: StringName = scene.STATUS_SWITCH_TEST_MOVES[index]
		scene.player.global_position = Vector2(420, 150)
		scene.player.reset_step_meter()
		await physics_frame
		for n in 24:
			scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
			await physics_frame
			if scene.has_active_demo_battle(): break
		check("F8 real encounter", scene.has_active_demo_battle())
		var ui = scene.battle_presentation
		ui._playback.set_process(false)
		var state: BattleState = ui.session.battle_state()
		var actor := ui.session.player_active() as CreatureInstance
		var target := ui.session.current_wild() as CreatureInstance
		actor.stats.max_hp = 2000
		actor.current_hp = 2000
		actor.stats.speed = 10000
		actor.stat_stages.change(StatStages.ACCURACY, 6)
		target.stats.max_hp = 2000
		target.current_hp = 2000
		target.stat_stages.change(StatStages.EVASION, -6)
		ui._refresh_view()
		var initial_experience := actor.experience
		var events: Array[BattleEvent] = ui.submit_player_move(move)
		check("F8 actual resolved effect", _count(events, BattleEvent.MOVE_EFFECT_RESOLVED) == 1)
		var fixed := state.to_dict().duplicate(true)
		await _drain(ui, String(move))
		check("F8 replay never mutates state", fixed == state.to_dict())
		check("F8 blocked during battle", not scene.cycle_status_switch_test())
		if move in Rules.STATUS_PIVOTS:
			check("F8 prompts for player choice", state.phase == BattleState.WAITING_FOR_SWITCH and ui.switch_control_enabled() and ui._move_buttons[0].disabled)
			await _capture(String(move) + "_choice")
			var chosen: StringName = ui.available_switch_instance_ids().back()
			var result: WildBattleCommandResult = ui.submit_player_switch(chosen)
			check("F8 explicit bench selection", result.accepted and not result.turn_consumed and state.active_for_side(&"side_a").instance_id == chosen)
			await _drain(ui, String(move) + "_entry")
			if move == &"baton_pass": check("F8 passed boosts into real party", state.creature(chosen).stat_stages.get_stage(StatStages.ATTACK) == 2)
			ui.submit_capture_ball(&"master_ball")
			await _drain(ui, "capture")
		else:
			check("F8 escape without victory/capture", ui.session.completion_reason == WildAdventureSession.COMPLETED_FLED and actor.experience == initial_experience)
		check("F8 return to map", ui.continue_after_completion())
	scene.restart_field_run()
	check("F8 restart restores learnset and disables mechanics", not scene._session.switch_move_rules_enabled and scene._session.player.party.get_active().move_slot(&"parting_shot") == null)
	scene.queue_free()
	await process_frame


func _drain(ui: Control, label: String) -> void:
	var steps := 0
	while ui._playback.is_playing() and steps < 120:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		if entry.get("status_switch_native", false):
			check("native status no artificial HP", entry.views == entry.after_views)
			ui._playback.advance(float(entry.community_impact) + 0.1)
			check("native status clean layers", ui._playback._status_switch.preview.visible_cells() > 0 and not ui._playback._status_switch.preview._sprites[0].visible and not ui._playback._status_switch.preview._sprites[1].visible)
			await _capture(label + "_live")
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		steps += 1
	check("bounded F8 playback", not ui._playback.is_playing())


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame
	RenderingServer.force_draw(false)
	var path := STATUS_OUTPUT + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
