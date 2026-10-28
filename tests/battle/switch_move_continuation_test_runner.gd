extends SceneTree

const Rules = preload("res://modules/battle/application/switch_move_rules.gd")
const OUTPUT := "res://.godot/switch_move_checks/"
var catalog: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var samples: Array = []
var captures: Array = []
var gpu := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok and errors.size() < 60:
		errors.append(label)
		push_error(label)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for move: StringName in Rules.PIVOTS + Rules.PHAZES:
		check("exact canonical contract " + String(move), Rules.supports(catalog.move(move)))
		var original := catalog.move(move).to_dict().duplicate(true)
		var local := Rules.execution_move(catalog.move(move))
		check("contact correction detached " + String(move), local != catalog.move(move) and local.makes_contact == (move != &"volt_switch") and catalog.move(move).to_dict() == original)
		for side in ["side_a", "side_b"]:
			for seed_value in range(1, 13):
				if move in Rules.PIVOTS:
					_pivot_case(move, StringName(side), seed_value)
				else:
					_phaze_case(move, StringName(side), seed_value)
	_edges()
	await _visual_cases()
	var hashes := {}
	for path: String in ["modules/battle/domain/battle_state.gd", "modules/battle/domain/battle_event.gd", "modules/battle/application/turn_executor.gd", "modules/battle/application/switch_move_rules.gd", "modules/battle/server/authoritative_battle_server.gd", "modules/gameplay/wild_adventure_session.gd", "scenes/visual/field_battle_presentation.gd", "scenes/visual/field_demo.gd", "scenes/visual/battle_external_damage_pilot.gd", "scenes/visual/battle_animation_playback.gd", "scenes/visual/battle_timeline_plan.gd", "tests/battle/switch_move_continuation_test_runner.gd", "data/normalized/pokemon_api.json", "data/raw/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "core_samples": samples, "captures": captures, "source_sha256": hashes,
		"enabled_scope": "Explicit singles switch_move_rules_enabled; F7 wild demo only. Historical/default sessions and trainer AI remain disabled.",
		"limitations": ["Trainer UI/AI replacement choice and search continuation are not rolled out.", "Roar/Whirlwind and other status pivots are not enabled.", "Ability suppression/Mold Breaker, Substitute damage interception and Dynamax mechanics are separate pending work.", "Single wild encounters only; no doubles."]}
	var file := FileAccess.open(OUTPUT + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ", true) + "\n")
	print("SWITCH_MOVE_CONTINUATION ", report.status, " checks=", checks, " samples=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _fixture(move: StringName, side_id: StringName = &"side_a", seed_value: int = 7) -> Dictionary:
	var a := CreatureInstance.new(&"a", &"charizard", 50, StatBlock.new(2000, 100, 100, 200, 100, 100), [move if side_id == &"side_a" else &"tackle"])
	var b := CreatureInstance.new(&"b", &"wailord", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [move if side_id == &"side_b" else &"tackle"])
	var a2 := CreatureInstance.new(&"a2", &"pikachu", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [&"tackle"])
	var a3 := CreatureInstance.new(&"a3", &"blastoise", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [&"tackle"])
	var b2 := CreatureInstance.new(&"b2", &"pikachu", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [&"tackle"])
	var b3 := CreatureInstance.new(&"b3", &"blastoise", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [&"tackle"])
	var state := BattleState.create_with_parties(&"switch_mechanics", [a, a2, a3], [b, b2, b3], seed_value)
	state.switch_move_rules_enabled = true
	var actor := a if side_id == &"side_a" else b
	var target := b if side_id == &"side_a" else a
	actor.stats.speed = 200
	target.stats.speed = 100
	actor.stat_stages.change(StatStages.ACCURACY, 6)
	target.stat_stages.change(StatStages.EVASION, -6)
	return {"state": state, "server": AuthoritativeBattleServer.new(state, catalog),
		"actor": actor, "target": target, "side": side_id, "move": move}


func _action(f: Dictionary) -> BattleAction:
	return BattleAction.new(f.state.turn + 1, f.actor.instance_id, f.move,
		f.target.instance_id, BattleAction.MOVE, f.side)


func _reaction(f: Dictionary) -> Array[BattleEvent]:
	return f.server.submit_reaction_turn(_action(f), &"side_b" if f.side == &"side_a" else &"side_a")


func _turn(f: Dictionary) -> Array[BattleEvent]:
	var opposing := BattleAction.new(f.state.turn + 1, f.target.instance_id, &"tackle",
		f.actor.instance_id, BattleAction.MOVE, &"side_b" if f.side == &"side_a" else &"side_a")
	return f.server.submit_turn([_action(f), opposing] as Array[BattleAction])


func _count(events: Array[BattleEvent], kind: StringName) -> int:
	var count := 0
	for event in events:
		if event.kind == kind:
			count += 1
	return count


func _rows(events: Array[BattleEvent]) -> Array:
	var rows := []
	for event in events:
		rows.append(event.to_dict())
	return rows


func _pivot_case(move: StringName, side: StringName, seed_value: int) -> void:
	var f := _fixture(move, side, seed_value)
	var label := "%s/%s/%d" % [move, side, seed_value]
	var pp: int = f.actor.move_slot(move).current_pp
	f.actor.status_state.persistent_id = &"poison"
	f.actor.stat_stages.change(StatStages.ATTACK, 2)
	var events := _turn(f)
	check(label + " pauses after one move", f.state.phase == BattleState.WAITING_FOR_SWITCH and _count(events, BattleEvent.ACTION_USED) == 1)
	check(label + " one PP", f.actor.move_slot(move).current_pp == pp - 1)
	check(label + " no end turn before choice", _count(events, BattleEvent.TURN_ENDED) == 0 and _count(events, BattleEvent.STATUS_DAMAGE) == 0)
	check(label + " request emitted", _count(events, BattleEvent.SWITCH_REQUESTED) == 1 and f.state.remaining_turn_actions.size() == 1)
	var snapshot: Dictionary = f.server.snapshot().duplicate(true)
	var request: Dictionary = f.server.pending_switch_request()
	request["candidate_ids"].clear()
	check(label + " request detached", not f.server.pending_switch_request().candidate_ids.is_empty())
	for choice: Array in [[&"wrong_side", &"a2", 1], [side, f.actor.instance_id, 1], [side, f.target.instance_id, 1], [side, &"unknown", 1], [side, &"a2", 2]]:
		var rejected: Array[BattleEvent] = f.server.submit_switch_choice(choice[0], choice[1], choice[2])
		check(label + " invalid choice unchanged", _count(rejected, BattleEvent.ACTION_REJECTED) == 1 and snapshot == f.server.snapshot())
	var rejected: Array[BattleEvent] = f.server.submit_turn([] as Array[BattleAction])
	check(label + " new command blocked", _count(rejected, BattleEvent.ACTION_REJECTED) == 1 and snapshot == f.server.snapshot())
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), catalog)
	check(label + " paused snapshot round trip", restored.snapshot() == snapshot)
	# Choose the THIRD party member, proving the engine does not pick the first bench.
	var incoming := &"a3" if side == &"side_a" else &"b3"
	var continued: Array[BattleEvent] = f.server.submit_switch_choice(side, incoming, 1)
	var replayed: Array[BattleEvent] = restored.submit_switch_choice(side, incoming, 1)
	check(label + " resume deterministic", _rows(continued) == _rows(replayed) and f.server.snapshot() == restored.snapshot())
	check(label + " same turn completes once", f.state.turn == 1 and f.state.phase == BattleState.WAITING_FOR_ACTIONS and _count(continued, BattleEvent.TURN_ENDED) == 1)
	check(label + " chosen bench active", f.state.active_for_side(side).instance_id == incoming and continued[0].kind == BattleEvent.SWITCHED and continued[0].move_id == move and continued[0].metadata.cause == "pivot")
	check(label + " enemy hits incoming", f.state.creature(incoming).current_hp < 2000 and f.actor.current_hp == 2000 and _count(continued, BattleEvent.ACTION_USED) == 1)
	check(label + " switch clears stages not poison", f.actor.stat_stages.get_stage(StatStages.ATTACK) == 0 and f.actor.status_state.persistent_id == &"poison" and _count(continued, BattleEvent.STATUS_DAMAGE) == 0)
	check(label + " continuation emptied", f.state.pending_switch.is_empty() and f.state.remaining_turn_actions.is_empty())
	snapshot = f.server.snapshot().duplicate(true)
	check(label + " double submit rejected", _count(f.server.submit_switch_choice(side, incoming, 1), BattleEvent.ACTION_REJECTED) == 1 and snapshot == f.server.snapshot())
	samples.append({"move": String(move), "side": String(side), "seed": seed_value, "first": _rows(events), "continuation": _rows(continued)})


func _phaze_case(move: StringName, side: StringName, seed_value: int) -> void:
	var f := _fixture(move, side, seed_value)
	var label := "%s/%s/%d" % [move, side, seed_value]
	var snapshot: Dictionary = f.server.snapshot().duplicate(true)
	var replay := AuthoritativeBattleServer.new(BattleState.from_dict(snapshot), catalog)
	var action := _action(f)
	var skipped := &"side_b" if side == &"side_a" else &"side_a"
	var events: Array[BattleEvent] = f.server.submit_reaction_turn(action, skipped)
	var replayed: Array[BattleEvent] = replay.submit_reaction_turn(BattleAction.from_dict(action.to_dict()), skipped)
	check(label + " seeded forced choice deterministic", _rows(events) == _rows(replayed) and f.server.snapshot() == replay.snapshot())
	check(label + " one forced switch", _count(events, BattleEvent.SWITCHED) == 1 and _count(events, BattleEvent.SWITCH_REQUESTED) == 0)
	check(label + " target loses active slot", f.state.opponent_of(f.actor.instance_id).instance_id != f.target.instance_id and f.state.active_for_side(side) == f.actor)
	check(label + " damage precedes switch", events.find(_find(events, BattleEvent.DAMAGE_APPLIED)) < events.find(_find(events, BattleEvent.SWITCHED)))
	check(label + " phaze event provenance", _find(events, BattleEvent.SWITCHED).metadata.cause == "phaze" and _find(events, BattleEvent.SWITCHED).move_id == move)
	check(label + " end turn once", _count(events, BattleEvent.TURN_ENDED) == 1 and f.state.turn == 1)
	samples.append({"move": String(move), "side": String(side), "seed": seed_value, "events": _rows(events)})


func _find(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event.kind == kind:
			return event
	return BattleEvent.new()


func _edges() -> void:
	for move: StringName in Rules.PIVOTS:
		var slow := _fixture(move)
		slow.actor.stats.speed = 1
		var first := _turn(slow)
		check("slow pivot responds before choice " + String(move), _count(first, BattleEvent.ACTION_USED) == 2 and slow.actor.current_hp < 2000 and slow.state.remaining_turn_actions.is_empty() and _count(first, BattleEvent.TURN_ENDED) == 0)
		var next: Array[BattleEvent] = slow.server.submit_switch_choice(&"side_a", &"a3", 1)
		check("slow pivot no second response " + String(move), _count(next, BattleEvent.ACTION_USED) == 0 and _count(next, BattleEvent.TURN_ENDED) == 1 and slow.state.creature(&"a3").current_hp == 2000)
	for move: StringName in Rules.PHAZES:
		var pair := _fixture(move)
		pair.target.moveset.assign([BattleMoveSlot.new(move, 20, 20)])
		pair.target.move_ids.assign([move])
		var first: Array[BattleEvent] = pair.server.submit_turn([_action(pair), BattleAction.new(1, &"b", move, &"a", BattleAction.MOVE, &"side_b")] as Array[BattleAction])
		check("expelled queued actor cannot act " + String(move), _count(first, BattleEvent.ACTION_USED) == 1 and pair.target.move_slot(move).current_pp == 20 and _count(first, BattleEvent.SWITCHED) == 1)
	for move: StringName in Rules.PIVOTS + Rules.PHAZES:
		var f := _fixture(move)
		f.state.switch_move_rules_enabled = false
		var events := _reaction(f)
		check("legacy mode unchanged " + String(move), _count(events, BattleEvent.SWITCHED) == 0 and _count(events, BattleEvent.SWITCH_REQUESTED) == 0 and not f.server.snapshot().has("switch_move_context"))
		f = _fixture(move)
		for id: StringName in f.state.participant_ids:
			if id not in f.state.active_ids:
				f.state.creature(id).current_hp = 0
		events = _reaction(f)
		check("no living bench " + String(move), f.state.phase == BattleState.WAITING_FOR_ACTIONS and _count(events, BattleEvent.SWITCHED) == 0 and _count(events, BattleEvent.SWITCH_REQUESTED) == 0)
		f = _fixture(move)
		f.state.creature(&"a2").current_hp = 0
		f.state.creature(&"b2").current_hp = 0
		events = _reaction(f)
		if move in Rules.PIVOTS:
			var fixed: Dictionary = f.server.snapshot().duplicate(true)
			check("KO bench choice rejected " + String(move), _count(f.server.submit_switch_choice(&"side_a", &"a2", 1), BattleEvent.ACTION_REJECTED) == 1 and f.server.snapshot() == fixed)
		else:
			check("forced choice excludes KO " + String(move), f.state.opponent_of(&"a").instance_id == &"b3")
		f = _fixture(move)
		f.target.current_hp = 1
		events = _reaction(f)
		if move in Rules.PIVOTS:
			check("KO plus pivot not fake phaze " + String(move), _count(events, BattleEvent.SWITCHED) == 1 and _count(events, BattleEvent.SWITCH_REQUESTED) == 1)
		else:
			check("KO no double phaze " + String(move), _count(events, BattleEvent.SWITCHED) == 1 and _find(events, BattleEvent.SWITCHED).move_id == &"")
		f = _fixture(move)
		for id: StringName in f.state.sides[1].party_ids:
			f.state.creature(id).current_hp = 0 if id != &"b" else 1
		events = _reaction(f)
		check("last enemy KO ends without request " + String(move), f.state.phase == BattleState.FINISHED and _count(events, BattleEvent.SWITCH_REQUESTED) == 0)
		f = _fixture(move)
		f.target.species_id = &"diglett" if move == &"volt_switch" else (&"clefairy" if move == &"dragon_tail" else &"gastly")
		if move in [&"volt_switch", &"dragon_tail", &"circle_throw"]:
			events = _reaction(f)
			check("immunity prevents special effect " + String(move), f.target.current_hp == 2000 and _count(events, BattleEvent.SWITCHED) == 0 and _count(events, BattleEvent.SWITCH_REQUESTED) == 0)
		f = _fixture(move)
		f.actor.current_hp = 1
		f.target.ability_id = &"iron_barbs"
		if move != &"volt_switch":
			events = _reaction(f)
			check("contact KO cancels switch effect " + String(move), f.actor.is_knocked_out() and _count(events, BattleEvent.SWITCH_REQUESTED) == 0 and _find(events, BattleEvent.SWITCHED).move_id == &"")
	for move: StringName in Rules.PHAZES:
		for blocker: StringName in [&"suction_cups", &"guard_dog", &"ingrain", &"substitute", &"dynamax"]:
			var f := _fixture(move)
			if blocker in [&"suction_cups", &"guard_dog"]:
				f.target.ability_id = blocker
			else:
				f.target.status_state.add_volatile(blocker)
			var events := _reaction(f)
			check("phaze blocked " + String(move) + String(blocker), _count(events, BattleEvent.SWITCHED) == 0 and _count(events, BattleEvent.SWITCH_EFFECT_FAILED) == 1 and f.target.current_hp < 2000)
		for side: StringName in [&"side_a", &"side_b"]:
			for level in [49, 50, 51]:
				var f := _fixture(move, side)
				f.state.battle_kind = &"wild"
				f.actor.level = level
				var events := _reaction(f)
				check("wild level rule " + String(move) + String(side) + str(level), (f.state.phase == BattleState.FINISHED) == (level >= 50) and _count(events, BattleEvent.SWITCHED) == 0)
				check("wild escape no winner " + str(level), f.state.winner_id == &"" and (f.state.end_reason == &"forced_escape") == (level >= 50))
	# Two pivots in one turn pause twice; end-turn damage runs only after both choices.
	var f := _fixture(&"u_turn")
	f.target.moveset.assign([BattleMoveSlot.new(&"u_turn", 20, 20)])
	f.target.move_ids.assign([&"u_turn"])
	f.state.creature(&"b3").status_state.persistent_id = &"poison"
	var events: Array[BattleEvent] = f.server.submit_turn([_action(f), BattleAction.new(1, &"b", &"u_turn", &"a", BattleAction.MOVE, &"side_b")] as Array[BattleAction])
	check("two pivots first pause", f.state.phase == BattleState.WAITING_FOR_SWITCH)
	events = f.server.submit_switch_choice(&"side_a", &"a3", 1)
	check("two pivots second pause targets incoming", f.state.phase == BattleState.WAITING_FOR_SWITCH and f.state.pending_switch.side_id == "side_b" and _find(events, BattleEvent.DAMAGE_APPLIED).target_id == &"a3" and _count(events, BattleEvent.TURN_ENDED) == 0)
	events = f.server.submit_switch_choice(&"side_b", &"b3", 1)
	check("two pivots one end turn", _count(events, BattleEvent.TURN_ENDED) == 1 and _count(events, BattleEvent.STATUS_DAMAGE) == 1 and f.state.creature(&"b3").current_hp == 1750 and f.state.turn == 1)
	# Failed accuracy cannot pause; do not mutate canonical move definitions.
	var misses := 0
	for seed_value in range(1, 41):
		f = _fixture(&"u_turn", &"side_a", seed_value)
		f.actor.stat_stages.change(StatStages.ACCURACY, -12)
		f.target.stat_stages.change(StatStages.EVASION, 12)
		events = _reaction(f)
		if _count(events, BattleEvent.MOVE_MISSED) > 0:
			misses += 1
			check("miss no pivot " + str(seed_value), f.state.phase == BattleState.WAITING_FOR_ACTIONS and _count(events, BattleEvent.SWITCH_REQUESTED) == 0)
	check("miss cases actually exercised", misses > 20)


func _visual_cases() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	for n in 4:
		await process_frame
	scene.player.set_physics_process(false)
	for index in 5:
		check("F7 preset ready " + str(index), scene.cycle_switch_move_test())
		scene.player.set_physics_process(false)
		var move: StringName = scene.EXTERNAL_DAMAGE_TEST_MOVES[index]
		check("F7 three-member party", scene._session.player.party.size() == 3 and scene._session.switch_move_rules_enabled)
		scene.player.global_position = Vector2(420, 150)
		scene.player.reset_step_meter()
		await physics_frame
		for n in 24:
			scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
			await physics_frame
			if scene.has_active_demo_battle():
				break
		check("F7 real encounter", scene.has_active_demo_battle())
		var ui = scene.battle_presentation
		ui._playback.set_process(false)
		var state: BattleState = ui.session.battle_state()
		var player := ui.session.player_active() as CreatureInstance
		var enemy := ui.session.current_wild() as CreatureInstance
		player.stats.max_hp = 2000
		player.current_hp = 2000
		player.stats.speed = 10000
		player.stat_stages.change(StatStages.ACCURACY, 6)
		enemy.stats.max_hp = 2000
		enemy.current_hp = 2000
		enemy.stat_stages.change(StatStages.EVASION, -6)
		ui._refresh_view()
		var initial_xp := player.experience
		var events: Array[BattleEvent] = ui.submit_player_move(move)
		check("F7 no preset while battle", not scene.cycle_switch_move_test())
		var fixed := state.to_dict().duplicate(true)
		await _drain(ui, String(move))
		check("replay does not advance battle " + String(move), fixed == state.to_dict())
		if move in Rules.PIVOTS:
			check("F7 player choice enabled", state.phase == BattleState.WAITING_FOR_SWITCH and ui.switch_control_enabled() and ui._move_buttons[0].disabled and ui._capture_buttons[0].disabled and ui._run_button.disabled)
			await _capture(String(move) + "_choice")
			var ids: Array[StringName] = ui.available_switch_instance_ids()
			var chosen: StringName = ids.back()
			var out: WildBattleCommandResult = ui.submit_player_switch(chosen)
			check("F7 choice continuation accepted", out.accepted and not out.turn_consumed and state.turn == 1 and state.active_for_side(&"side_a").instance_id == chosen)
			check("F7 busy choice blocked", not ui.submit_player_switch(ids[0]).accepted)
			fixed = state.to_dict().duplicate(true)
			await _drain(ui, String(move) + "_entry")
			check("F7 authoritative chosen sprite", fixed == state.to_dict() and ui._arena.player_species == state.creature(chosen).species_id and not ui._move_buttons[0].disabled)
			ui.submit_capture_ball(&"master_ball")
			await _drain(ui, "capture")
		else:
			check("F7 forced escape settled", ui.session.completion_reason == WildAdventureSession.COMPLETED_FLED and ui.session.battle_state() == null and player.experience == initial_xp)
			check("F7 forced escape hides target", not ui._arena._enemy_visible)
		check("F7 return to map", ui.continue_after_completion())
		if errors.size() > 20:
			break
	scene.restart_field_run()
	check("restart disables pilot", not scene._session.switch_move_rules_enabled)
	scene.queue_free()
	await process_frame


func _drain(ui: Control, label: String) -> void:
	var steps := 0
	while ui._playback.is_playing() and steps < 120:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		if entry.has("community_clip"):
			check("pilot mechanics label " + label, entry.special_effect_implemented and not entry.external_damage_only and not "sigue pendiente" in String(entry.text))
			ui._playback.advance(float(entry.community_impact) + 0.09)
			await _capture(label + "_hit")
		elif entry.get("effect") == "send_out":
			ui._playback.advance(float(entry.duration) * 0.8)
			await _capture(label + "_send_out")
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		steps += 1
	check("bounded animation " + label, not ui._playback.is_playing())


func _capture(label: String) -> void:
	if not gpu:
		return
	await process_frame
	RenderingServer.force_draw(false)
	var path := OUTPUT + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
