extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Binding = preload("res://modules/battle/application/binding_move_rules.gd")
const Live = preload("res://modules/battle/application/live_move_profile.gd")
const DEST := "res://.godot/binding_checks/"
var _done := false
var _visual_samples: Array = []


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	create_timer(180).timeout.connect(func():
		if not _done: quit(2))
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for id: StringName in Binding.CONTRACTS:
		check("binding contract " + String(id), Binding.supports(catalog.move(id)) and Live.reason(catalog.move(id)).is_empty())
		var altered := MoveDefinition.from_dict(catalog.move(id).to_dict())
		altered.power += 1
		check("altered binding contract fails closed " + String(id), Live.reason(altered) == "mechanics_contract_mismatch")
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13): _binding_case(id, side, seed_value)
	_edges_binding()
	await _visual_binding()
	var hashes := {}
	for path: String in ["modules/battle/application/binding_move_rules.gd", "modules/battle/application/live_move_profile.gd", "modules/battle/application/turn_executor.gd", "modules/battle/application/switch_move_rules.gd", "modules/battle/effects/battle_effect_executor.gd", "modules/battle/server/authoritative_battle_server.gd", "modules/battle/presentation/live_move_event_text.gd", "modules/battle/presentation/battle_presentation_controller.gd", "modules/battle/presentation/trainer_battle_presentation_controller.gd", "modules/localization/spanish_game_text.gd", "modules/gameplay/wild_adventure_session.gd", "modules/trainer_ai/trainer_observation_builder.gd", "modules/trainer_ai/trainer_plausible_world_factory.gd", "tests/battle/binding_move_test_runner.gd", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var result := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "gpu": gpu,
		"cases": samples.size(), "moves": Binding.CONTRACTS.keys(), "captures": captures, "visual_samples": _visual_samples, "source_sha256": hashes}
	FileAccess.open(DEST + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	_done = true
	print("BINDING_MOVES ", result.status, " checks=", checks, " cases=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _bound_fixture(id: StringName = &"infestation", side: StringName = &"side_a", seed_value: int = 7) -> Dictionary:
	var f := _fixture(id, side, seed_value)
	Live.apply(f.state)
	f.actor.species_id = &"mew"; f.target.species_id = &"blastoise"
	f.actor.add_move(&"haze", catalog)
	return f


func _idle(f: Dictionary) -> Array[BattleEvent]:
	return f.server.submit_reaction_turn(BattleAction.new(f.state.turn + 1, f.actor.instance_id, &"haze", f.target.instance_id, BattleAction.MOVE, f.side), &"side_b" if f.side == &"side_a" else &"side_a")


func _residual(events: Array[BattleEvent]) -> int:
	var damage := 0
	for event: BattleEvent in events:
		if event.kind == BattleEvent.STATUS_DAMAGE and event.metadata.get("binding", false): damage += event.amount
	return damage


func _victim_switch(f: Dictionary) -> BattleAction:
	var side := f.state.side_for_creature(f.target.instance_id) as BattleSide
	return BattleAction.new(f.state.turn + 1, f.target.instance_id, &"", &"", BattleAction.SWITCH, side.side_id, side.party_ids[1])


func _binding_case(id: StringName, side: StringName, seed_value: int) -> void:
	var f := _bound_fixture(id, side, seed_value)
	var before: Dictionary = f.server.snapshot()
	var definition := catalog.move(id).to_dict().duplicate(true)
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(before))), catalog)
	var events := _reaction(f)
	var replay := restored.submit_reaction_turn(BattleAction.new(1, f.actor.instance_id, id, f.target.instance_id, BattleAction.MOVE, side), &"side_b" if side == &"side_a" else &"side_a")
	var label := "%s/%s/%d" % [id, side, seed_value]
	check(label + " snapshot events/RNG roundtrip", _rows(events) == _rows(replay) and f.server.snapshot() == restored.snapshot())
	check(label + " native first-tick clock and damage", int(Binding.record(f.target).get("duration", 0)) in [4, 5] and _residual(events) == 250)
	check(label + " exactly one paid move", _count(events, BattleEvent.ACTION_USED) == 1 and f.actor.move_slot(id).current_pp == catalog.move(id).pp - 1)
	check(label + " frozen canonical definition", catalog.move(id).to_dict() == definition)
	var locked: Dictionary = f.server.snapshot()
	var rejection: Array[BattleEvent] = f.server.submit_reaction_turn(_victim_switch(f), side)
	check(label + " switch rejected without mutation", _count(rejection, BattleEvent.ACTION_REJECTED) == 1 and f.server.snapshot() == locked)
	var victim_side: StringName = f.state.side_for_creature(f.target.instance_id).side_id
	var switch_candidates := 0
	for action: BattleAction in TrainerActionSpace.from_server(f.server, victim_side):
		if action.action_type == BattleAction.SWITCH: switch_candidates += 1
	check(label + " AI shares the same blocked switches", switch_candidates == 0)
	var loaded := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(locked))), catalog)
	var continued := _idle(f)
	var copied := loaded.submit_reaction_turn(BattleAction.new(2, f.actor.instance_id, &"haze", f.target.instance_id, BattleAction.MOVE, side), &"side_b" if side == &"side_a" else &"side_a")
	check(label + " continuation tick is deterministic", _rows(continued) == _rows(copied) and loaded.snapshot() == f.server.snapshot() and _residual(continued) == 250)
	samples.append({"move": String(id), "side": String(side), "seed": seed_value})


func _edges_binding() -> void:
	for id: StringName in Binding.CONTRACTS:
		var f := _bound_fixture(id)
		f.actor.held_item_id = &"grip_claw"
		var ticks := 1 if _residual(_reaction(f)) > 0 else 0
		for turn in range(2, 9):
			if _residual(_idle(f)) > 0: ticks += 1
		check("Grip Claw expires after seven ticks " + String(id), ticks == 7 and Binding.record(f.target).is_empty())
		var band := _bound_fixture(id)
		band.actor.held_item_id = &"binding_band"
		check("Binding Band fixed residual " + String(id), _residual(_reaction(band)) == 333)
		var repeated := _bound_fixture(id)
		_reaction(repeated)
		var clock: int = Binding.record(repeated.target).duration
		_reaction(repeated)
		check("re-hit does not extend duration " + String(id), int(Binding.record(repeated.target).duration) == clock - 1)
		var contact := _bound_fixture(id)
		contact.target.ability_id = &"iron_barbs"
		_reaction(contact)
		check("detached contact correction " + String(id), contact.actor.current_hp == (1750 if Binding.execution_move(catalog.move(id)).makes_contact else 2000) and not catalog.move(id).makes_contact)
	for ghost in [false, true]:
		var free := _bound_fixture()
		if ghost: free.target.species_id = &"gengar"
		else: free.target.held_item_id = &"shed_shell"
		_reaction(free)
		check("Ghost/Shed Shell can leave while still taking binding damage", not Binding.record(free.target).is_empty() and not Binding.switch_blocked(free.state, free.target, catalog))
		var switched: Array[BattleEvent] = free.server.submit_reaction_turn(_victim_switch(free), &"side_a")
		check("Ghost/Shed Shell switch cleans binding", _count(switched, BattleEvent.SWITCHED) == 1 and Binding.record(free.target).is_empty())
	var leave := _bound_fixture()
	_reaction(leave)
	var replacement: StringName = leave.state.side_for_creature(leave.actor.instance_id).party_ids[1]
	leave.server.submit_reaction_turn(BattleAction.new(2, leave.actor.instance_id, &"", &"", BattleAction.SWITCH, &"side_a", replacement), &"side_b")
	check("source switch releases victim immediately", Binding.record(leave.target).is_empty())
	var death := _bound_fixture()
	_reaction(death); death.actor.current_hp = 1; death.target.add_move(&"dragon_rage", catalog)
	var before_hp: int = death.target.current_hp
	death.server.submit_reaction_turn(BattleAction.new(2, death.target.instance_id, &"dragon_rage", death.actor.instance_id, BattleAction.MOVE, &"side_b"), &"side_a")
	check("source KO stops residual before replacement can inherit source", Binding.record(death.target).is_empty() and death.target.current_hp == before_hp)
	var leftovers := _bound_fixture()
	_reaction(leftovers); leftovers.target.current_hp = 130; leftovers.target.held_item_id = &"leftovers"
	_idle(leftovers)
	check("Leftovers heals before binding residual", leftovers.target.current_hp == 5)
	var magic := _bound_fixture(); magic.target.ability_id = &"magic_guard"
	check("Magic Guard skips residual but not binding", _residual(_reaction(magic)) == 0 and not Binding.record(magic.target).is_empty())
	var baton := _bound_fixture(); _reaction(baton); baton.target.add_move(&"baton_pass", catalog)
	baton.server.submit_reaction_turn(BattleAction.new(2, baton.target.instance_id, &"baton_pass", baton.actor.instance_id, BattleAction.MOVE, &"side_b"), &"side_a")
	var chosen: StringName = baton.state.pending_switch.candidate_ids[0]
	var transferred: Array[BattleEvent] = baton.server.submit_switch_choice(&"side_b", chosen, 2)
	check("Baton Pass transfers binding without reroll", not Binding.record(baton.state.creature(chosen)).is_empty() and Binding.record(baton.target).is_empty() and _residual(transferred) == 250)
	var privacy := _bound_fixture(); _reaction(privacy)
	var memory := TrainerBattleMemory.new(); memory.begin(privacy.state, &"side_b")
	var first := TrainerObservationBuilder.build(privacy.state, &"side_b", memory).to_dict()
	var secret := Binding.record(privacy.target); secret.duration = 7; secret.divisor = 6
	privacy.target.status_state.add_volatile(Binding.KEY, secret)
	var second := TrainerObservationBuilder.build(privacy.state, &"side_b", memory).to_dict()
	check("trainer view does not expose hidden duration/divisor", first == second)
	privacy.target.reconcile_post_battle()
	check("postbattle/capture cleanup removes binding", Binding.record(privacy.target).is_empty())


func _drain_binding(ui: Control) -> void:
	var limit := 0
	while ui._playback.is_playing() and limit < 1000:
		ui._playback._process(0.1); limit += 1
	check("playback completes", not ui._playback.is_playing())


func _visual_binding() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	for id: StringName in Binding.CONTRACTS:
		var config: Dictionary = scene.test_panel.current_configuration().duplicate(true)
		config.player_team = [{"species_id": "vulpix_alola__shiny", "level": 50}, {"species_id": "pikachu", "level": 50}]
		config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50; config.encounter_chance_percent = 100
		check("ordinary boot " + String(id), scene._bootstrap_demo(config)); scene._configure_presentations()
		check("ordinary encounter " + String(id), scene._director.on_step(scene.TECHNICAL_ZONE_ID).battle_started)
		var ui = scene.battle_presentation
		var actor: CreatureInstance = scene._session.player_active()
		var target: CreatureInstance = scene._session.current_wild()
		actor.moveset.clear(); actor.move_ids.clear(); actor.add_move(id, scene._catalogs)
		target.moveset.clear(); target.move_ids.clear(); target.add_move(&"swords_dance", scene._catalogs)
		actor.stats.max_hp = 4000; actor.current_hp = 4000; actor.stats.speed = 200
		target.stats.max_hp = 4000; target.current_hp = 4000; target.stats.speed = 1
		actor.stat_stages = StatStages.from_dict({"accuracy": 6}); target.stat_stages = StatStages.from_dict({"evasion": -6})
		ui.open_for_active_battle(); await process_frame; await process_frame; ui._playback.set_process(false)
		check("ordinary menu admits " + String(id), id in ui.available_move_ids())
		var events: Array[BattleEvent] = ui.submit_player_move(id)
		check("real game creates binding and residual " + String(id), not Binding.record(target).is_empty() and _residual(events) == 500)
		var snapshot: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
		var native := false; var limit := 0
		while ui._playback.is_playing() and limit < 1000:
			var entry: Dictionary = ui._playback._sequence[ui._playback._index]
			if entry.get("catalog_clip", "") == String(id) + "/back" and not native:
				ui._playback._process(minf(0.3, float(entry.duration) * 0.4)); native = true
				await _capture_binding(String(id) + "_native")
			ui._playback._process(0.1); limit += 1
		check("native playback preserves authoritative state " + String(id), native and not ui._playback.is_playing() and ui.session.battle_state().to_dict() == snapshot)
		check("binding HUD matches authoritative HP " + String(id), ui.displayed_enemy_hp() == target.current_hp)
		_visual_samples.append({"move": String(id), "actor_level": actor.level, "target_hp": target.current_hp, "displayed_hp": ui.displayed_enemy_hp(), "residual_damage": _residual(events)})
		await _capture_binding(String(id) + "_after")
		# A second turn traps the player, exercising the real command/UI boundary.
		actor.moveset.clear(); actor.move_ids.clear(); actor.add_move(&"haze", scene._catalogs)
		target.moveset.clear(); target.move_ids.clear(); target.add_move(&"infestation", scene._catalogs)
		ui.submit_player_move(&"haze"); _drain_binding(ui)
		check("trapped player's manual switch controls are disabled", ui.available_switch_instance_ids().is_empty())
		var turn: int = ui.session.battle_state().turn
		var attempt: int = ui.session.escape_attempts()
		var rng_state: int = ui._escape_rng.state
		var blocked: WildBattleCommandResult = ui.submit_player_run()
		check("blocked RUN consumes turn without rolling escape RNG", blocked.accepted and blocked.turn_consumed and not blocked.escape_resolution.escaped and not blocked.escape_resolution.rng_consumed and ui._escape_rng.state == rng_state and ui.session.escape_attempts() == attempt and ui.session.battle_state().turn == turn + 1)
		_drain_binding(ui)
		if id == &"infestation":
			var caught: WildBattleCommandResult = ui.submit_capture_ball(&"master_ball")
			check("binding does not forbid a legitimate capture", caught.accepted and caught.session_completed)
			if caught.capture_outcome != null and caught.capture_outcome.resolution != null and caught.capture_outcome.resolution.captured != null:
				check("actual capture clears both owned binding states", Binding.record(caught.capture_outcome.resolution.captured).is_empty() and Binding.record(actor).is_empty())
			else: check("capture returns owned creature", false)
		_drain_binding(ui); ui._playback.cancel(); ui.hide()
	scene.queue_free(); await process_frame


func _capture_binding(label: String) -> void:
	if not gpu: return
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var path := DEST + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
