extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Transform = preload("res://modules/battle/application/transform_rules.gd")
const Timeline = preload("res://scenes/visual/battle_timeline_plan.gd")
const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
const Pilot = preload("res://scenes/visual/battle_transform_pilot.gd")
var _live_completed := false
const TRANS_OUTPUT := "res://.godot/transform_checks/"


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(TRANS_OUTPUT)
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("frozen Transform contract", Transform.supports(catalog.move(&"transform")) and catalog.move(&"transform").classification == "UNSUPPORTED")
	for species: StringName in [&"wailord", &"pikachu", &"charizard"]:
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13): _copy_case(side, species, seed_value)
	_edges()
	_capture_cases()
	await _live_cases()
	check("live cases completed without script abort", _live_completed)
	if gpu: check("all capture frames completed", captures.size() == 12)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks,
		"errors": errors, "gpu": gpu, "core_samples": samples, "captures": captures,
		"source_sha256": _source_hashes(), "pack_sha256": FileAccess.get_sha256(Pilot.PACK),
		"scope": "Explicit F11 modern singles Transform pilot; not a global/AI rollout",
		"limitations": ["No Imposter automation or full ability-start lifecycle beyond represented ON_SWITCH_IN ability callbacks.",
			"No certification of dynamic types/forms, Tera, Dynamax, Illusion or every move-specific exception.",
			"Source clip contains body tracks, no particles. Appearance change uses the existing artwork and an adapted transition at frame 8/15."],
		"references": ["https://github.com/smogon/pokemon-showdown/blob/master/sim/pokemon.ts", "https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts"]}
	FileAccess.open(TRANS_OUTPUT + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ", true) + "\n")
	print("TRANSFORM_PILOT ", report.status, " checks=", checks, " samples=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _t_fixture(side: StringName = &"side_a", species: StringName = &"wailord", seed_value: int = 7) -> Dictionary:
	var f := _fixture(&"transform", side, seed_value)
	f.state.transform_rules_enabled = true
	f.actor.species_id = &"ditto"
	f.actor.level = 37
	f.actor.stats = StatBlock.new(301, 67, 89, 201, 79, 83)
	f.actor.current_hp = 201
	f.actor.ability_id = &"limber"
	f.target.species_id = species
	f.target.level = 79
	f.target.stats = StatBlock.new(2000, 161, 203, 122, 181, 221)
	f.target.ability_id = &"torrent"
	f.target.stat_stages.change(StatStages.ATTACK, 3)
	f.target.stat_stages.change(StatStages.EVASION, -1)
	f.target.status_state.add_volatile(&"focus_energy", {"level": 2})
	f.target.moveset.clear()
	f.target.move_ids.clear()
	for move: StringName in [&"tackle", &"water_gun", &"struggle"]: f.target.add_move(move, catalog)
	f.target.move_slot(&"tackle").current_pp = 0
	return f


func _copy_case(side: StringName, species: StringName, seed_value: int) -> void:
	var f := _t_fixture(side, species, seed_value)
	var label := "%s/%s/%d" % [side, species, seed_value]
	var original := f.actor.to_dict() as Dictionary
	var target_before := f.target.to_dict() as Dictionary
	var before := _projection(f.state)
	var pp: int = f.actor.move_slot(&"transform").current_pp
	var events := _reaction(f)
	check(label + " one resolved transformation", _count(events, BattleEvent.TRANSFORMED) == 1 and _count(events, BattleEvent.TRANSFORM_FAILED) == 0)
	check(label + " preserves HP level and identity", f.actor.instance_id == StringName(original.instance_id) and f.actor.current_hp == 201 and f.actor.stats.max_hp == 301 and f.actor.level == 37 and f.actor.base_species_id() == &"ditto")
	var expected_stats := f.target.stats.to_dict() as Dictionary
	expected_stats.max_hp = 301
	check(label + " copies raw non-HP stats species ability stages", f.actor.stats.to_dict() == expected_stats and f.actor.species_id == species and f.actor.ability_id == &"torrent" and f.actor.stat_stages.to_dict() == f.target.stat_stages.to_dict())
	check(label + " fresh copied PP bounded by base PP", f.actor.move_slot(&"tackle").current_pp == 5 and f.actor.move_slot(&"water_gun").max_pp == 5 and f.actor.move_slot(&"struggle").current_pp == mini(5, catalog.move(&"struggle").pp))
	check(label + " paid original PP once", int(f.actor.battle_transform_original.moveset[0].current_pp) == pp - 1 and _count(events, BattleEvent.PP_CHANGED) == 1)
	check(label + " target untouched", f.target.to_dict() == target_before)
	check(label + " crit volatile deep copied", f.actor.status_state.volatile[&"focus_energy"] == f.target.status_state.volatile[&"focus_energy"])
	var snapshot: Dictionary = f.server.snapshot()
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), catalog)
	check(label + " transformed JSON round trip", restored.snapshot() == snapshot)
	var plan := Timeline.build(_rows(events), before)
	var image_side := "back" if side == &"side_a" else "front"
	var transition := plan.filter(func(step): return step.get("event_kind") == String(BattleEvent.TRANSFORMED))
	check(label + " timeline original-to-copied correct side", transition.size() == 1 and transition[0].views[image_side].species == "ditto" and transition[0].after_views[image_side].species == String(species) and transition[0].views[image_side].hp == transition[0].after_views[image_side].hp)
	var action := BattleAction.new(2, f.actor.instance_id, &"water_gun", f.target.instance_id, BattleAction.MOVE, side)
	var skipped := &"side_b" if side == &"side_a" else &"side_a"
	var continued: Array[BattleEvent] = f.server.submit_reaction_turn(action, skipped)
	var replayed: Array[BattleEvent] = restored.submit_reaction_turn(action, skipped)
	check(label + " copied command deterministic", _rows(continued) == _rows(replayed) and f.server.snapshot() == restored.snapshot() and f.actor.move_slot(&"water_gun").current_pp == 4)
	check(label + " copied move does damage", _count(continued, BattleEvent.DAMAGE_APPLIED) == 1 and f.target.current_hp < 2000)
	var damage := DamageCalculator.new().calculate(f.actor, f.target, catalog.move(&"water_gun"), catalog, SeededRandomSource.new(42))
	check(label + " copied typing drives STAB", int(damage.stab_basis_points) == (15000 if species == &"wailord" else 10000))
	f.actor.stats.attack += 1
	f.actor.status_state.volatile[&"focus_energy"].level = 9
	check(label + " copied objects detached", f.target.stats.attack == 161 and int(f.target.status_state.volatile[&"focus_energy"].level) == 2)
	var incoming := &"a3" if side == &"side_a" else &"b3"
	var switch_action := BattleAction.new(3, f.actor.instance_id, &"", &"", BattleAction.SWITCH, side, incoming)
	var switched: Array[BattleEvent] = f.server.submit_reaction_turn(switch_action, skipped)
	check(label + " switch restores original stats ability paid PP", f.actor.battle_transform_original.is_empty() and f.actor.species_id == &"ditto" and f.actor.stats.to_dict() == original.stats and f.actor.ability_id == &"limber" and f.actor.move_slot(&"transform").current_pp == pp - 1 and not f.actor.has_move(&"water_gun"))
	check(label + " withdrawal precedes reversion display", _count(switched, BattleEvent.TRANSFORM_REVERTED) == 1 and switched[0].kind == BattleEvent.SWITCHED)
	samples.append({"side": String(side), "species": String(species), "seed": seed_value,
		"copy": _rows(events), "copied_action": _rows(continued), "switch": _rows(switched)})


func _edges() -> void:
	var legacy := _t_fixture()
	legacy.state.transform_rules_enabled = false
	var old := _reaction(legacy)
	check("default mode unchanged", legacy.actor.species_id == &"ditto" and legacy.actor.battle_transform_original.is_empty() and not legacy.server.snapshot().has("transform_context") and _count(old, BattleEvent.TRANSFORMED) == 0)
	for failure in ["substitute", "infiltrator_substitute", "illusion", "dynamax", "target_transformed"]:
		var f := _t_fixture()
		if failure in ["substitute", "infiltrator_substitute"]: f.target.status_state.add_volatile(&"substitute", {"hp": 50})
		if failure == "infiltrator_substitute": f.actor.ability_id = &"infiltrator"
		if failure in ["illusion", "dynamax"]: f.target.status_state.add_volatile(StringName(failure), {})
		if failure == "target_transformed": f.target.battle_transform_original = {"species_id": "ditto"}
		var pp: int = f.actor.move_slot(&"transform").current_pp
		var events := _reaction(f)
		check("failure atomic " + failure, f.actor.species_id == &"ditto" and f.actor.battle_transform_original.is_empty() and f.actor.move_slot(&"transform").current_pp == pp - 1 and _count(events, BattleEvent.TRANSFORM_FAILED) == 1)
	var f := _t_fixture()
	f.target.add_move(&"transform", catalog)
	f.actor.held_item_id = &"oran_berry"
	f.target.held_item_id = &"leftovers"
	f.actor.ivs = {"attack": 7}
	f.actor.evs = {"speed": 12}
	f.actor.experience = 900
	f.actor.nature_id = &"adamant"
	f.actor.status_state.add_volatile(&"confusion", {"turns_remaining": 2})
	f.target.status_state.add_volatile(&"ingrain", {})
	_reaction(f)
	check("does not copy target item progression or other volatiles", f.actor.held_item_id == &"oran_berry" and f.actor.ivs == {"attack": 7} and f.actor.evs == {"speed": 12} and f.actor.experience == 900 and f.actor.nature_id == &"adamant" and f.actor.status_state.has_volatile(&"confusion") and not f.actor.status_state.has_volatile(&"ingrain"))
	var again := BattleAction.new(2, f.actor.instance_id, &"transform", f.target.instance_id, BattleAction.MOVE, &"side_a")
	var second: Array[BattleEvent] = f.server.submit_reaction_turn(again, &"side_b")
	check("already transformed cannot nest baseline", _count(second, BattleEvent.TRANSFORM_FAILED) == 1 and f.actor.move_slot(&"transform").current_pp == 4 and f.actor.battle_transform_original.species_id == "ditto")
	var persistent := CreatureInstance.from_dict(JSON.parse_string(JSON.stringify(f.actor.to_dict())))
	persistent.reconcile_post_battle()
	check("reconciliation restores serialized overlay", persistent.species_id == &"ditto" and persistent.move_slot(&"transform").current_pp == 9 and persistent.battle_transform_original.is_empty() and persistent.status_state.volatile.is_empty())
	f = _t_fixture()
	f.state.battle_started = true
	f.target.ability_id = &"intimidate"
	var events := _reaction(f)
	check("copied supported ability starts immediately", f.actor.ability_id == &"intimidate" and _count(events, BattleEvent.ABILITY_TRIGGERED) == 1 and f.target.stat_stages.get_stage(StatStages.ATTACK) == 2)
	f = _t_fixture()
	f.actor.status_state.add_volatile(&"substitute", {"hp": 37, "max_hp": 75})
	f.actor.status_state.persistent_id = &"poison"
	_reaction(f)
	check("own substitute and persistent status retained", f.actor.status_state.volatile[&"substitute"].hp == 37 and f.actor.status_state.persistent_id == &"poison" and f.actor.current_hp < 201)
	# Terminal cleanup and XP must use original species, even when a transformed
	# loser had copied a completely different base experience yield.
	f = _t_fixture()
	_reaction(f)
	for id: StringName in [&"b", &"b2", &"b3"]: f.state.creature(id).current_hp = 0
	var terminal := f.server.submit_reaction_turn(BattleAction.new(2, &"a", &"tackle", &"b", BattleAction.MOVE, &"side_a"), &"side_b") as Array[BattleEvent]
	check("terminal restores winner before progression", f.state.phase == BattleState.FINISHED and f.actor.species_id == &"ditto" and f.actor.move_slot(&"transform").current_pp == 9 and _count(terminal, BattleEvent.TRANSFORM_REVERTED) == 1)
	f = _t_fixture()
	_reaction(f)
	f.actor.current_hp = 0
	f.server.submit_reaction_turn(BattleAction.new(2, &"b", &"water_gun", &"a", BattleAction.MOVE, &"side_b"), &"side_a")
	check("KO restores before automatic replacement", f.actor.species_id == &"ditto" and f.actor.current_hp == 0 and f.actor.battle_transform_original.is_empty())
	f = _t_fixture()
	_reaction(f)
	f.actor.current_hp = 0
	f.state.winner_id = &"b"
	var outcome := BattleOutcome.from_battle_state(f.state, GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))))
	check("outcome participant uses original identity", outcome.participants[0].species_id == String(f.target.base_species_id()) and outcome.defeated[0].species_id == "ditto")

	f = _t_fixture()
	f.state.substitute_rules_enabled = true
	f.actor.status_state.add_volatile(&"substitute", {"hp": 25, "max_hp": 75})
	f.target.add_move(&"baton_pass", catalog)
	_reaction(f)
	var baton: Array[BattleEvent] = f.server.submit_reaction_turn(BattleAction.new(2, &"a", &"baton_pass", &"b", BattleAction.MOVE, &"side_a"), &"side_b")
	check("copied Baton Pass pauses with original baseline", _count(baton, BattleEvent.SWITCH_REQUESTED) == 1 and f.state.phase == BattleState.WAITING_FOR_SWITCH and f.actor.battle_transform_original.species_id == "ditto")
	var saved: Dictionary = f.server.snapshot()
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(saved))), catalog)
	check("transformed pending switch JSON stable", restored.snapshot() == saved)
	var resumed: Array[BattleEvent] = f.server.submit_switch_choice(&"side_a", &"a3", 2)
	var replayed: Array[BattleEvent] = restored.submit_switch_choice(&"side_a", &"a3", 2)
	check("restored copied pivot deterministic", _rows(resumed) == _rows(replayed) and f.server.snapshot() == restored.snapshot())
	var incoming: CreatureInstance = f.state.creature(&"a3")
	check("Baton passes stages and doll but not transformation", incoming.species_id == &"blastoise" and incoming.battle_transform_original.is_empty() and incoming.stat_stages.get_stage(StatStages.ATTACK) == 3 and incoming.status_state.volatile[&"substitute"].hp == 25 and f.actor.species_id == &"ditto" and f.actor.move_slot(&"transform").current_pp == 9)
	f = _t_fixture()
	f.state.battle_kind = &"wild"
	f.target.add_move(&"roar", catalog)
	_reaction(f)
	var flee: Array[BattleEvent] = f.server.submit_reaction_turn(BattleAction.new(2, &"a", &"roar", &"b", BattleAction.MOVE, &"side_a"), &"side_b")
	# Level is deliberately retained at 37, below target 79: phazing fails by
	# level rather than adopting the copied target's level.
	check("copied form retains own level for phaze", f.state.phase != BattleState.FINISHED and _count(flee, BattleEvent.SWITCH_EFFECT_FAILED) == 1 and f.actor.level == 37)
	f.actor.level = 100
	f.server.submit_reaction_turn(BattleAction.new(3, &"a", &"roar", &"b", BattleAction.MOVE, &"side_a"), &"side_b")
	check("forced escape restores original before release", f.state.phase == BattleState.FINISHED and f.state.end_reason == &"forced_escape" and f.actor.species_id == &"ditto" and f.actor.battle_transform_original.is_empty())


func _capture_cases() -> void:
	var data := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json")))
	var f := _t_fixture(&"side_b", &"charizard")
	_reaction(f)
	var context := CaptureBattleContext.new()
	context.is_wild = true
	context.battle_finished = false
	var attempt := CaptureAttempt.new(f.actor, &"poke_ball", context)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var expected := CaptureRuleset.new().catch_probability(data.species_catalog.get_by_id(&"ditto").capture_rate, 1.0, 1.0, 301, 201)
	var captured := CaptureSystem.resolve(attempt, rng, data, null)
	check("capture probability uses original species", is_equal_approx(captured.result.probability, expected))
	check("failed capture retains overlay", captured.result.status == CaptureResult.FAILED and not f.actor.battle_transform_original.is_empty())
	attempt.ball_id = &"master_ball"
	captured = CaptureSystem.resolve(attempt, rng, data, null)
	check("successful capture restores same instance original identity", captured.result.status == CaptureResult.SUCCESS and captured.captured == f.actor and captured.captured.species_id == &"ditto" and captured.captured.stats.max_hp == 301 and captured.captured.has_move(&"transform") and not captured.captured.has_move(&"water_gun"))


func _projection(state: BattleState) -> Dictionary:
	var result := {"views": {}, "creatures": {}, "moves": {}, "transform_rules_enabled": state.transform_rules_enabled}
	for side: BattleSide in state.sides:
		var image_side := "back" if side.side_id == &"side_a" else "front"
		for id: StringName in side.party_ids:
			var c := state.creature(id)
			var row := {"instance_id": String(id), "species": String(c.species_id), "side": image_side, "name": String(c.base_species_id()), "level": c.level, "hp": c.current_hp, "max_hp": c.stats.max_hp, "visible": not c.is_knocked_out()}
			result.creatures[String(id)] = row
			if id == side.active_id: result.views[image_side] = row.duplicate(true)
			for slot: BattleMoveSlot in c.moveset: result.moves[String(slot.move_id)] = Visuals.metadata(catalog.move(slot.move_id))
	return result


func _live_cases() -> void:
	var arena := preload("res://scenes/visual/battle_art.gd").new()
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(arena)
	var pilot := Pilot.new()
	root.add_child(pilot)
	pilot.configure(arena)
	check("two original timelines pinned", pilot.available and pilot._indices.size() == 2)
	for species: StringName in [&"wailord", &"pikachu", &"charizard"]:
		var f := _t_fixture(&"side_b", species)
		var before := _projection(f.state)
		var events := _reaction(f)
		var sequence: Array[Dictionary] = pilot.decorate(Timeline.build(_rows(events), before), before)
		var bound := sequence.filter(func(step): return step.has("transform_binding"))
		check("front timeline appearance confirmed", bound.size() == 1 and bound[0].transform_binding == "transform/front" and is_equal_approx(bound[0].duration, 0.75))
		arena.player_species = StringName(bound[0].after_views.back.species)
		arena.enemy_species = StringName(bound[0].after_views.front.species)
		await _capture(String(species) + "_front_copied")
		before.transform_rules_enabled = false
		var disabled: Array[Dictionary] = pilot.decorate(Timeline.build(_rows(events), before), before)
		check("appearance pilot gated", not disabled.any(func(step): return step.has("transform_binding")))
	arena.queue_free()
	pilot.queue_free()
	await process_frame
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	for n in 4: await process_frame
	for index in 3:
		check("F11 preset ready", scene.cycle_transform_test())
		scene.player.set_physics_process(false)
		var species: StringName = scene.TRANSFORM_TEST_SPECIES[index]
		scene.player.global_position = Vector2(420, 150)
		scene.player.reset_step_meter()
		await physics_frame
		for n in 24:
			scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
			await physics_frame
			if scene.has_active_demo_battle(): break
		check("F11 real encounter", scene.has_active_demo_battle())
		var ui = scene.battle_presentation
		ui._playback.set_process(false)
		var state: BattleState = ui.session.battle_state()
		var actor: CreatureInstance = ui.session.player_active()
		var target := state.opponent_of(actor.instance_id)
		check("real Ditto versus preset species", actor.species_id == &"ditto" and target.species_id == species and state.transform_rules_enabled)
		actor.stats.max_hp = 2001
		actor.current_hp = 2001
		actor.stats.speed = 10000
		target.stats.max_hp = 2001
		target.current_hp = 2001
		target.moveset.clear()
		target.move_ids.clear()
		for move: StringName in [&"tackle", &"water_gun"]: target.add_move(move, catalog)
		ui._refresh_view()
		var events: Array[BattleEvent] = ui.submit_player_move(&"transform")
		check("real transformation confirmed", _count(events, BattleEvent.TRANSFORMED) == 1 and actor.species_id == species)
		var fixed := state.to_dict().duplicate(true)
		await _drain(ui, String(species), true)
		check("replay leaves state unchanged", state.to_dict() == fixed)
		check("real copied commands and own name", ui.available_move_ids() == actor.move_ids and actor.move_slot(&"tackle").current_pp == 5 and ui._player_label.text.begins_with("Ditto"))
		await _capture(String(species) + "_back_copied")
		var move_events: Array[BattleEvent] = ui.submit_player_move(&"water_gun")
		check("real copied attack accepted with temporary PP", _count(move_events, BattleEvent.ACTION_USED) == 2 and actor.move_slot(&"water_gun").current_pp == 4)
		await _drain(ui, "attack")
		var outgoing_id: StringName = actor.instance_id
		var candidates: Array[StringName] = ui.available_switch_instance_ids()
		check("real switch accepted", ui.submit_player_switch(candidates[-1]).accepted)
		await _drain(ui, "switch_out")
		check("reserve identity restored", actor.species_id == &"ditto" and actor.battle_transform_original.is_empty() and actor.move_slot(&"transform").current_pp == 9)
		check("return Ditto accepted", ui.submit_player_switch(outgoing_id).accepted)
		await _drain(ui, "return")
		check("restored sprite and move menu", ui._arena.player_species == &"ditto" and ui.available_move_ids() == ([&"transform"] as Array[StringName]))
		await _capture(String(species) + "_restored")
		# Capture while the player is transformed exercises party cleanup with the
		# live authoritative object, rather than merely calling a restore helper.
		ui.submit_player_move(&"transform")
		await _drain(ui, "copy_again")
		ui.submit_capture_ball(&"master_ball")
		await _drain(ui, "capture")
		check("capture completion restores player object", actor.species_id == &"ditto" and actor.battle_transform_original.is_empty() and actor.move_slot(&"transform").current_pp == 8 and ui._playback._final_views.back.species == "ditto")
		check("return after capture", ui.continue_after_completion())
	check("escape preset", scene.cycle_transform_test())
	var ui = await _enter(scene)
	var actor: CreatureInstance = ui.session.player_active()
	var target: CreatureInstance = ui.session.battle_state().opponent_of(actor.instance_id)
	actor.stats.max_hp = 2001
	actor.current_hp = 2001
	ui.submit_player_move(&"transform")
	await _drain(ui, "escape_copy")
	check("escaped fixture transformed", not actor.battle_transform_original.is_empty())
	actor.stats.speed = 100000
	target.stats.speed = 1
	var escaped = ui.submit_player_run()
	await _drain(ui, "escape")
	check("successful run restores live party", escaped.accepted and escaped.session_completed and actor.species_id == &"ditto" and actor.battle_transform_original.is_empty())
	check("return after escape", ui.continue_after_completion())
	check("wild copy capture preset", scene.cycle_transform_test())
	ui = await _enter(scene)
	actor = ui.session.player_active()
	target = ui.session.battle_state().opponent_of(actor.instance_id)
	var original_species: StringName = target.species_id
	var original_stats: Dictionary = target.stats.to_dict()
	actor.add_move(&"tackle", catalog)
	actor.stats.speed = 10000
	target.stats.max_hp = 2001
	target.current_hp = 2001
	original_stats.max_hp = 2001
	target.moveset.clear()
	target.move_ids.clear()
	target.add_move(&"transform", catalog)
	ui._refresh_view()
	var wild_copy: Array[BattleEvent] = ui.submit_player_move(&"tackle")
	await _drain(ui, "wild_copy")
	check("real wild opponent transforms", _count(wild_copy, BattleEvent.TRANSFORMED) == 1 and target.species_id == &"ditto" and target.base_species_id() == original_species)
	ui.submit_capture_ball(&"master_ball")
	await _drain(ui, "wild_capture")
	check("real captured identity and moves restored", target.species_id == original_species and target.battle_transform_original.is_empty() and target.stats.to_dict() == original_stats and target.move_slot(&"transform").current_pp == 9 and ui.session.player.party.get_creatures().has(target))
	check("return after wild capture", ui.continue_after_completion())
	scene.restart_field_run()
	check("reset disables Transform and restores natural team", not scene._session.transform_rules_enabled)
	scene.queue_free()
	await process_frame
	_live_completed = true


func _enter(scene: Node) -> Control:
	scene.player.set_physics_process(false)
	scene.player.global_position = Vector2(420, 150)
	scene.player.reset_step_meter()
	await physics_frame
	for n in 24:
		scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		await physics_frame
		if scene.has_active_demo_battle(): break
	check("extra real encounter", scene.has_active_demo_battle())
	scene.battle_presentation._playback.set_process(false)
	return scene.battle_presentation


func _drain(ui: Control, label: String, record_transition: bool = false) -> void:
	var steps := 0
	while ui._playback.is_playing() and steps < 150:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		if entry.has("transform_binding"):
			var side := String(entry.side)
			var before: Dictionary = entry.views[side]
			var after: Dictionary = entry.after_views[side]
			check("appearance never changes HP", before.hp == after.hp and before.max_hp == after.max_hp)
			ui._playback.advance(0.399)
			check("original image before handoff", (ui._arena.player_species if side == "back" else ui._arena.enemy_species) == StringName(before.species))
			ui._playback.advance(0.002)
			check("copied image at handoff", (ui._arena.player_species if side == "back" else ui._arena.enemy_species) == StringName(after.species))
			ui._playback.advance(0.2)
			if record_transition: await _capture(label + "_transition")
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		steps += 1
	check("bounded playback " + label, not ui._playback.is_playing())


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame
	RenderingServer.force_draw(false)
	var path := TRANS_OUTPUT + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})


func _source_hashes() -> Dictionary:
	var result := {}
	for path: String in ["modules/creatures/domain/creature_instance.gd", "modules/battle/application/transform_rules.gd", "modules/battle/application/turn_executor.gd", "modules/battle/domain/battle_state.gd", "modules/battle/domain/battle_event.gd", "modules/battle/domain/battle_outcome.gd", "modules/capture/capture_system.gd", "modules/gameplay/wild_adventure_session.gd", "modules/battle/presentation/spanish_battle_presentation_controller.gd", "scenes/visual/battle_transform_pilot.gd", "scenes/visual/battle_animation_playback.gd", "scenes/visual/battle_timeline_plan.gd", "scenes/visual/battle_art.gd", "scenes/visual/field_demo.gd", "scenes/visual/field_battle_presentation.gd", "tools/visual/build_transform_pilot.py", "tests/battle/transform_pilot_test_runner.gd", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		result[path] = FileAccess.get_sha256("res://" + path)
	return result
