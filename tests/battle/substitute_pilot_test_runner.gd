extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Sub = preload("res://modules/battle/application/substitute_rules.gd")
const SUB_OUTPUT := "res://.godot/substitute_checks/"
const SubPilot = preload("res://scenes/visual/battle_substitute_pilot.gd")
const Timeline = preload("res://scenes/visual/battle_timeline_plan.gd")
const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
const Arena = preload("res://scenes/visual/battle_art.gd")
var _effects := BattleEffectExecutor.new()
var _registry := BattleEffectRegistry.new()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SUB_OUTPUT)
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for move: StringName in [&"substitute", &"shed_tail"]:
		check("canonical " + String(move), Sub.supports(catalog.move(move)))
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13):
				_creation_case(move, side, seed_value)
	_boundaries()
	_damage_cases()
	_transfer_cases()
	await _sub_visual_cases()
	if gpu: check("all nine GPU captures completed", captures.size() == 9)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks,
		"errors": errors, "core_samples": samples, "captures": captures, "gpu": gpu,
		"source_sha256": _source_hashes(), "pack_sha256": FileAccess.get_sha256(SubPilot.SUB_PACK),
		"scope": "Explicit substitute_rules_enabled singles pilot; no default/trainer AI rollout",
		"reference": "https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts",
		"reference_sha256": "43b516fdc01721f53f01de555479dd3d248e5e29d2a6f5072a7bd4a3585a5027"}
	FileAccess.open(SUB_OUTPUT + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ", true) + "\n")
	print("SUBSTITUTE_PILOT ", report.status, " checks=", checks, " samples=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _sub_fixture(move: StringName = &"substitute", side: StringName = &"side_a", seed_value: int = 7) -> Dictionary:
	var f := _fixture(move, side, seed_value)
	f.state.substitute_rules_enabled = true
	f.actor.stats.max_hp = 201
	f.actor.current_hp = 201
	return f


func _creation_case(move: StringName, side: StringName, seed_value: int) -> void:
	var f := _sub_fixture(move, side, seed_value)
	var pp: int = f.actor.move_slot(move).current_pp
	f.actor.stat_stages.change(StatStages.ATTACK, 2)
	f.actor.status_state.add_volatile(&"focus_energy", {"level": 2})
	var events := _reaction(f)
	var label := "%s/%s/%d" % [move, side, seed_value]
	check(label + " creation and distinct HP cost", _count(events, BattleEvent.SUBSTITUTE_CREATED) == 1 and _count(events, BattleEvent.HP_COST) == 1 and _count(events, BattleEvent.DAMAGE_APPLIED) == 0)
	check(label + " rounded cost and doll HP", f.actor.current_hp == (100 if move == &"shed_tail" else 151) and Sub.hp(f.actor) == 50)
	check(label + " one PP", f.actor.move_slot(move).current_pp == pp - 1)
	var snapshot: Dictionary = f.server.snapshot()
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), catalog)
	check(label + " JSON round trip", snapshot == restored.snapshot())
	if move == &"shed_tail":
		check(label + " pending choice", f.state.phase == BattleState.WAITING_FOR_SWITCH and _count(events, BattleEvent.TURN_ENDED) == 0)
		var rejected: Array[BattleEvent] = f.server.submit_switch_choice(side, f.actor.instance_id, f.state.turn)
		check(label + " invalid unchanged", _count(rejected, BattleEvent.ACTION_REJECTED) == 1 and snapshot == f.server.snapshot())
		var incoming := &"a3" if side == &"side_a" else &"b3"
		var continued: Array[BattleEvent] = f.server.submit_switch_choice(side, incoming, f.state.turn)
		var replayed: Array[BattleEvent] = restored.submit_switch_choice(side, incoming, f.state.turn)
		check(label + " deterministic choice", _rows(continued) == _rows(replayed) and f.server.snapshot() == restored.snapshot())
		var replacement: CreatureInstance = f.state.creature(incoming)
		check(label + " only doll transferred", Sub.hp(replacement) == 50 and replacement.current_hp == 2000 and replacement.stat_stages.get_stage(StatStages.ATTACK) == 0 and not replacement.status_state.has_volatile(&"focus_energy") and not f.actor.status_state.has_volatile(&"substitute"))
		check(label + " same turn one end", f.state.turn == 1 and _count(continued, BattleEvent.TURN_ENDED) == 1 and _count(continued, BattleEvent.SUBSTITUTE_TRANSFERRED) == 1)
		events.append_array(continued)
	else:
		check(label + " no pending switch", f.state.phase == BattleState.WAITING_FOR_ACTIONS and _count(events, BattleEvent.TURN_ENDED) == 1)
	samples.append({"move": String(move), "side": String(side), "seed": seed_value, "events": _rows(events)})


func _boundaries() -> void:
	for move: StringName in [&"substitute", &"shed_tail"]:
		for hp_value in [49, 50, 51, 100, 101, 102, 201]:
			var f := _sub_fixture(move)
			f.actor.current_hp = hp_value
			var cost := 101 if move == &"shed_tail" else 50
			var events := _reaction(f)
			check("boundary %s/%d" % [move, hp_value], (Sub.hp(f.actor) == 50 and f.actor.current_hp == hp_value - cost) if hp_value > cost else (Sub.hp(f.actor) == 0 and f.actor.current_hp == hp_value and _count(events, BattleEvent.SUBSTITUTE_FAILED) == 1))
		for failure in ["existing", "no_reserve", "no_switch_rules", "tiny_hp"]:
			if move == &"substitute" and failure in ["no_reserve", "no_switch_rules"]: continue
			var f := _sub_fixture(move)
			if failure == "existing": f.actor.status_state.add_volatile(&"substitute", {"hp": 7, "max_hp": 50})
			if failure == "no_reserve":
				f.state.creature(&"a2").current_hp = 0
				f.state.creature(&"a3").current_hp = 0
			if failure == "no_switch_rules": f.state.switch_move_rules_enabled = false
			if failure == "tiny_hp":
				f.actor.stats.max_hp = 1
				f.actor.current_hp = 1
			var before_hp: int = f.actor.current_hp
			var events := _reaction(f)
			check(String(move) + "/" + failure, f.actor.current_hp == before_hp and _count(events, BattleEvent.SUBSTITUTE_FAILED) == 1 and _count(events, BattleEvent.SWITCH_REQUESTED) == 0)
	var legacy := _fixture(&"substitute")
	var old_events := _reaction(legacy)
	check("disabled mode has no doll or new context", Sub.hp(legacy.actor) == 0 and not legacy.server.snapshot().has("substitute_context") and _count(old_events, BattleEvent.HP_COST) == 0)


func _context(f: Dictionary, move_id: StringName = &"tackle") -> BattleEffectContext:
	return BattleEffectContext.new(f.state, f.actor, f.target, catalog.move(move_id), catalog,
		BattleRuleset.new(), SeededRandomSource.new(42), [] as Array[BattleEvent])


func _damage_cases() -> void:
	var f := _sub_fixture()
	f.target.status_state.add_volatile(&"substitute", {"hp": 30, "max_hp": 50})
	var c := _context(f)
	var fixed := BattleEffectSpec.new(BattleEffectSpec.FIXED_DAMAGE, BattleEffectSpec.OPPONENT, 90)
	_effects.execute(fixed, c, _registry)
	check("overflow discarded and genuine sub events", f.target.current_hp == 2000 and Sub.hp(f.target) == 0 and c.last_damage == 30 and c.body_damage == 0 and _count(c.events, BattleEvent.DAMAGE_APPLIED) == 0 and _count(c.events, BattleEvent.SUBSTITUTE_BROKEN) == 1)
	var status := BattleEffectSpec.new(BattleEffectSpec.INFLICT_STATUS, BattleEffectSpec.OPPONENT, 0, 0, 10000, &"poison")
	var chance := BattleEffectSpec.new(BattleEffectSpec.CHANCE, BattleEffectSpec.OPPONENT, 0, 0, 5000).with_child(status)
	var rng_before: int = c.rng.state()
	_effects.execute(chance, c, _registry)
	check("breaking hit blocks secondary without chance RNG", f.target.status_state.persistent_id == &"" and c.rng.state() == rng_before and _count(c.events, BattleEvent.SUBSTITUTE_BLOCKED) == 1)
	_effects.execute(BattleEffectSpec.new(BattleEffectSpec.FLINCH), c, _registry)
	_effects.execute(BattleEffectSpec.new(BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.OPPONENT, -1, 0, 10000, &"", StatStages.DEFENSE), c, _registry)
	check("break also blocks flinch and stage", not f.target.status_state.has_volatile(&"flinch") and f.target.stat_stages.get_stage(StatStages.DEFENSE) == 0)
	f.actor.current_hp = 100
	_effects.execute(BattleEffectSpec.new(BattleEffectSpec.DRAIN, BattleEffectSpec.SELF, 0, 5000), c, _registry)
	_effects.execute(BattleEffectSpec.new(BattleEffectSpec.RECOIL, BattleEffectSpec.SELF, 0, 5000), c, _registry)
	check("drain recoil use capped doll damage", f.actor.current_hp == 100 and _count(c.events, BattleEvent.HP_RECOVERED) == 1 and _count(c.events, BattleEvent.RECOIL_DAMAGE) == 1)
	_effects.execute(fixed, c, _registry)
	check("next strike damages body", f.target.current_hp == 1910 and c.body_damage == 90 and not c.last_hit_substitute)
	for bypass in ["sound", "infiltrator", "trigger", "disabled"]:
		f = _sub_fixture()
		f.target.status_state.add_volatile(&"substitute", {"hp": 50, "max_hp": 50})
		c = _context(f, &"hyper_voice" if bypass == "sound" else &"tackle")
		if bypass == "infiltrator": f.actor.ability_id = &"infiltrator"
		if bypass == "trigger": c.is_trigger = true
		if bypass == "disabled": f.state.substitute_rules_enabled = false
		_effects.execute(fixed, c, _registry)
		check("bypass " + bypass, Sub.hp(f.target) == 50 and f.target.current_hp == 1910 and _count(c.events, BattleEvent.SUBSTITUTE_DAMAGED) == 0)
	f = _sub_fixture()
	f.target.status_state.add_volatile(&"substitute", {"hp": 1, "max_hp": 50})
	c = _context(f)
	var multi := BattleEffectSpec.new(BattleEffectSpec.MULTI_HIT, BattleEffectSpec.OPPONENT, 0, 0, 10000, &"", &"", 2, 2)
	_effects.execute(multi, c, _registry)
	check("multi-hit breaks then hits body", _count(c.events, BattleEvent.SUBSTITUTE_DAMAGED) == 1 and _count(c.events, BattleEvent.DAMAGE_APPLIED) == 1 and f.target.current_hp < 2000 and c.body_damage > 0 and c.last_damage == c.body_damage + 1)
	f = _sub_fixture()
	f.target.status_state.add_volatile(&"substitute", {"hp": 50, "max_hp": 50})
	c = _context(f)
	_effects.execute(BattleEffectSpec.new(BattleEffectSpec.MAX_HP_DAMAGE, BattleEffectSpec.OPPONENT, 0, 1000), c, _registry)
	check("fractional direct damage intercepted", f.target.current_hp == 2000 and Sub.hp(f.target) == 0 and c.last_damage == 50)
	for move: StringName in [&"circle_throw", &"dragon_tail", &"u_turn"]:
		f = _sub_fixture(move)
		f.target.status_state.add_volatile(&"substitute", {"hp": 1, "max_hp": 50})
		f.target.ability_id = &"rough_skin"
		var events := _reaction(f)
		check(String(move) + " no contact retaliation through doll", f.actor.current_hp == 201 and _count(events, BattleEvent.ABILITY_TRIGGERED) == 0)
		check(String(move) + " phaze blocked / pivot allowed", _count(events, BattleEvent.SWITCH_REQUESTED) == (1 if move == &"u_turn" else 0) and _count(events, BattleEvent.SWITCHED) == 0)

	f = _sub_fixture(&"dragon_tail")
	f.actor.ability_id = &"infiltrator"
	f.target.status_state.add_volatile(&"substitute", {"hp": 50, "max_hp": 50})
	var infiltrated := _reaction(f)
	check("Infiltrator damaging phaze bypasses doll", _count(infiltrated, BattleEvent.SWITCHED) == 1 and _count(infiltrated, BattleEvent.DAMAGE_APPLIED) == 1 and _count(infiltrated, BattleEvent.SUBSTITUTE_DAMAGED) == 0)
	f = _sub_fixture()
	f.target.status_state.add_volatile(&"substitute", {"hp": 50, "max_hp": 50})
	c = _context(f)
	_effects.execute(status, c, _registry)
	check("ordinary status blocked by intact doll", f.target.status_state.persistent_id == &"" and Sub.hp(f.target) == 50)
	c = _context(f, &"sing")
	_effects.execute(status, c, _registry)
	check("sound status bypasses intact doll", f.target.status_state.persistent_id == &"poison" and Sub.hp(f.target) == 50)


func _transfer_cases() -> void:
	var f := _sub_fixture(&"shed_tail")
	var first := _turn(f)
	check("shed pauses enemy until choice", _count(first, BattleEvent.ACTION_USED) == 1 and f.state.remaining_turn_actions.size() == 1)
	var continued: Array[BattleEvent] = f.server.submit_switch_choice(&"side_a", &"a3", 1)
	check("queued enemy hits incoming doll", f.state.creature(&"a3").current_hp == 2000 and _count(continued, BattleEvent.SUBSTITUTE_DAMAGED) == 1)
	f = _sub_fixture(&"baton_pass")
	f.actor.status_state.add_volatile(&"substitute", {"hp": 17, "max_hp": 50})
	_reaction(f)
	f.server.submit_switch_choice(&"side_a", &"a3", 1)
	check("baton keeps remaining doll HP", Sub.hp(f.state.creature(&"a3")) == 17 and Sub.hp(f.actor) == 0)
	f = _sub_fixture()
	f.actor.status_state.add_volatile(&"substitute", {"hp": 17, "max_hp": 50})
	var switched := BattleAction.new(1, &"a", &"", &"", BattleAction.SWITCH, &"side_a", &"a2")
	f.server.submit_reaction_turn(switched, &"side_b")
	check("ordinary switch clears without transfer", Sub.hp(f.actor) == 0 and Sub.hp(f.state.creature(&"a2")) == 0)
	f = _sub_fixture()
	f.actor.status_state.add_volatile(&"substitute", {"hp": 17, "max_hp": 50})
	f.actor.status_state.persistent_id = &"poison"
	_reaction(f)
	check("poison bypasses doll", f.actor.current_hp < 201 and Sub.hp(f.actor) == 17)
	f = _sub_fixture()
	f.state.weather_rules_enabled = true
	f.state.weather = {"id": "hail", "turns_remaining": 5, "set_turn": 0}
	f.actor.status_state.add_volatile(&"substitute", {"hp": 17, "max_hp": 50})
	var weather_events := _reaction(f)
	check("weather chip bypasses doll", f.actor.current_hp < 201 and Sub.hp(f.actor) == 17 and _count(weather_events, BattleEvent.STATUS_DAMAGE) > 0)


func _projection(state: BattleState) -> Dictionary:
	var result := {"views": {}, "creatures": {}, "moves": {}, "substitute_rules_enabled": state.substitute_rules_enabled}
	for side: BattleSide in state.sides:
		var image_side := "back" if side.side_id == &"side_a" else "front"
		for id: StringName in side.party_ids:
			var c := state.creature(id)
			var row := {"instance_id": String(id), "species": String(c.species_id), "side": image_side, "name": String(c.species_id), "level": c.level, "hp": c.current_hp, "max_hp": c.stats.max_hp, "visible": not c.is_knocked_out()}
			if state.substitute_rules_enabled and Sub.hp(c) > 0: row["substitute"] = Sub.record(c)
			result.creatures[String(id)] = row
			if id == side.active_id: result.views[image_side] = row.duplicate(true)
			for slot: BattleMoveSlot in c.moveset:
				result.moves[String(slot.move_id)] = Visuals.metadata(catalog.move(slot.move_id))
	return result


func _sub_visual_cases() -> void:
	var arena := Arena.new()
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(arena)
	var pilot := SubPilot.new()
	root.add_child(pilot)
	pilot.configure(arena)
	await process_frame
	check("four pinned native clips available", pilot.available and pilot._indices.size() == 4)
	for move: StringName in [&"substitute", &"shed_tail"]:
		for side: StringName in [&"side_a", &"side_b"]:
			var f := _sub_fixture(move, side)
			var before := _projection(f.state)
			var events := _reaction(f)
			var snapshot: Dictionary = f.server.snapshot()
			var plan := Timeline.build(_rows(events), before)
			var sequence: Array[Dictionary] = pilot.decorate(plan, before)
			check("projection pure", snapshot == f.server.snapshot())
			var native := 0
			for step: Dictionary in sequence:
				if not step.has("community_clip"): continue
				native += 1
				var image_side := "back" if side == &"side_a" else "front"
				check("creation changes doll not body HP", step.views[image_side].hp == step.after_views[image_side].hp and step.views[image_side].get("substitute", {}).is_empty() and step.after_views[image_side].substitute.hp == 50)
				arena.player_species = &"charizard"
				arena.enemy_species = &"wailord"
				arena.set_runtime_substitutes(step.after_views)
				arena.set_runtime_visibility(image_side != "back", image_side != "front")
				pilot.show_entry(step, arena, float(step.duration) * 0.5)
				check("native particles without duplicate bodies", pilot.preview.visible_cells() > 0 and not pilot.preview._sprites[0].visible and not pilot.preview._sprites[1].visible)
				await _capture(String(move) + "_" + image_side + "_native")
				pilot.clear()
			check("one native creation", native == 1)
			before.substitute_rules_enabled = false
			var disabled: Array[Dictionary] = pilot.decorate(plan, before)
			check("native gated", not disabled.any(func(step): return step.has("community_clip")))
	arena.queue_free()
	pilot.queue_free()
	await process_frame
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	for n in 4: await process_frame
	for index in 2:
		check("F10 preset ready", scene.cycle_substitute_test())
		scene.player.set_physics_process(false)
		var move: StringName = scene.SUBSTITUTE_TEST_MOVES[index]
		scene.player.global_position = Vector2(420, 150)
		scene.player.reset_step_meter()
		await physics_frame
		for n in 24:
			scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
			await physics_frame
			if scene.has_active_demo_battle(): break
		check("F10 real encounter", scene.has_active_demo_battle())
		var ui = scene.battle_presentation
		ui._playback.set_process(false)
		var state: BattleState = ui.session.battle_state()
		check("F10 rules enabled explicitly", state.substitute_rules_enabled and state.switch_move_rules_enabled)
		for id: StringName in state.participant_ids:
			state.creature(id).stats.max_hp = 2001
			state.creature(id).current_hp = 2001
		var actor: CreatureInstance = ui.session.player_active()
		var enemy := state.opponent_of(actor.instance_id)
		actor.stats.speed = 10000
		enemy.moveset.clear()
		enemy.move_ids.clear()
		enemy.add_move(&"tackle", catalog)
		enemy.stat_stages.change(StatStages.ACCURACY, 6)
		actor.stat_stages.change(StatStages.EVASION, -6)
		ui._refresh_view()
		var events: Array[BattleEvent] = ui.submit_player_move(move)
		check("real creation", _count(events, BattleEvent.SUBSTITUTE_CREATED) == 1)
		var fixed := state.to_dict().duplicate(true)
		await _drain(ui, String(move))
		check("playback never changes server", state.to_dict() == fixed)
		check("doll in detached final views", not ui._playback._final_views.back.get("substitute", {}).is_empty())
		await _capture(String(move) + "_persistent")
		if move == &"shed_tail":
			check("real shed waiting for choice", state.phase == BattleState.WAITING_FOR_SWITCH)
			var candidates: Array[StringName] = ui.available_switch_instance_ids()
			check("real shed choice accepted", ui.submit_player_switch(candidates[-1]).accepted)
			await _drain(ui, "shed_entry")
			actor = ui.session.player_active()
			check("real incoming protected", actor.current_hp == 2001 and Sub.hp(actor) < 500 and Sub.hp(actor) > 0)
			await _capture("shed_entry_doll")
		# Force one deterministic overflow hit, leaving the creature unharmed.
		actor.status_state.add_volatile(&"substitute", {"hp": 1, "max_hp": 500})
		actor.stats.speed = 10000
		actor.add_move(&"tackle", catalog)
		ui._refresh_view()
		var before_hp: int = actor.current_hp
		events = ui.submit_player_move(&"tackle")
		check("real break emitted", _count(events, BattleEvent.SUBSTITUTE_BROKEN) == 1 and actor.current_hp == before_hp)
		await _drain(ui, "break_" + String(move))
		check("real body restored", ui._playback._final_views.back.get("substitute", {}).is_empty())
		await _capture(String(move) + "_broken")
		ui.submit_capture_ball(&"master_ball")
		await _drain(ui, "capture")
		check("return after capture", ui.continue_after_completion())
	scene.restart_field_run()
	check("reset disables substitute pilot", not scene._session.substitute_rules_enabled)
	scene.queue_free()
	await process_frame


func _drain(ui: Control, label: String) -> void:
	var steps := 0
	while ui._playback.is_playing() and steps < 150:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		if entry.get("event_kind") == String(BattleEvent.SUBSTITUTE_DAMAGED):
			var side := String(entry.side)
			check("doll hit leaves HUD HP intact", entry.views[side].hp == entry.after_views[side].hp)
			check("doll hit uses honest generic impact", not entry.has("community_clip") and entry.get("move_visual", {}).get("phase") == "hit")
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		steps += 1
	check("bounded playback " + label, not ui._playback.is_playing())


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame
	RenderingServer.force_draw(false)
	var path := SUB_OUTPUT + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})


func _source_hashes() -> Dictionary:
	var result := {}
	for path: String in ["modules/battle/application/switch_move_rules.gd", "modules/battle/application/substitute_rules.gd", "modules/battle/application/turn_executor.gd", "modules/battle/domain/battle_state.gd", "modules/battle/domain/battle_event.gd", "modules/battle/effects/battle_effect_context.gd", "modules/battle/effects/battle_effect_executor.gd", "modules/gameplay/wild_adventure_session.gd", "scenes/visual/battle_animation_playback.gd", "scenes/visual/battle_art.gd", "scenes/visual/battle_substitute_pilot.gd", "scenes/visual/battle_timeline_plan.gd", "scenes/visual/battle_move_visuals.gd", "scenes/visual/field_demo.gd", "scenes/visual/field_battle_presentation.gd", "tools/visual/build_substitute_pilot.py", "tests/battle/substitute_pilot_test_runner.gd", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		result[path] = FileAccess.get_sha256("res://" + path)
	return result
