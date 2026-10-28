extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Stage = preload("res://modules/battle/application/stat_stage_move_rules.gd")
const Live = preload("res://modules/battle/application/live_move_profile.gd")
const DEST := "res://.godot/stat_stage_move_checks/"
var _completed := false
var _visual_done := false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	create_timer(180).timeout.connect(func():
		if not _completed:
			push_error("STAT_STAGE batch aborted/timed out")
			quit(2))
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for id: StringName in Stage.TYPES:
		check("canonical contract " + String(id), Stage.supports(catalog.move(id)) and Live.reason(catalog.move(id)).is_empty())
		var invalid := MoveDefinition.from_dict(catalog.move(id).to_dict())
		invalid.priority = 5
		check("changed contract fails closed " + String(id), not Stage.supports(invalid) and Live.reason(invalid) == "mechanics_contract_mismatch")
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13): _case(id, side, seed_value)
	_edges_stage()
	await _visual_stage()
	check("visual lifecycle completed", _visual_done)
	var hashes := {}
	for path: String in ["modules/battle/application/stat_stage_move_rules.gd", "modules/battle/application/live_move_profile.gd", "modules/battle/application/turn_executor.gd", "modules/battle/effects/battle_effect_executor.gd", "modules/battle/domain/battle_event.gd", "modules/battle/presentation/live_move_event_text.gd", "modules/battle/presentation/spanish_battle_presentation_controller.gd", "scenes/visual/live_battle_catalog.gd", "scenes/visual/battle_timeline_plan.gd", "tests/battle/stat_stage_move_test_runner.gd", "data/normalized/pokemon_api.json", "data/raw/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "cases": samples.size(), "moves": Stage.TYPES.keys(), "captures": captures,
		"newly_admitted": Stage.STATUS_IDS, "source_sha256": hashes,
		"reference_sha256": FileAccess.get_sha256(DEST + "moves.ts"),
		"reference_actions_sha256": FileAccess.get_sha256(DEST + "battle-actions.ts")}
	FileAccess.open(DEST + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	_completed = true
	print("STAT_STAGE_MOVES ", report.status, " checks=", checks, " cases=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _stage_fixture(id: StringName, side: StringName = &"side_a", seed_value: int = 1) -> Dictionary:
	var f := _fixture(id, side, seed_value)
	Live.apply(f.state)
	f.actor.stat_stages = StatStages.from_dict({"attack": -3, "defense": 2, "special_attack": -1, "special_defense": 4, "speed": -2, "accuracy": 3, "evasion": -4})
	f.target.stat_stages = StatStages.from_dict({"attack": 2, "defense": -3, "special_attack": 4, "special_defense": -1, "speed": 3, "accuracy": -2, "evasion": 1})
	return f


func _case(id: StringName, side: StringName, seed_value: int) -> void:
	var f := _stage_fixture(id, side, seed_value)
	var label := "%s/%s/%d" % [id, side, seed_value]
	var own: Dictionary = f.actor.stat_stages.to_dict()
	var other: Dictionary = f.target.stat_stages.to_dict()
	var baseline := f.server.snapshot() as Dictionary
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(baseline))), catalog)
	var pp: int = f.actor.move_slot(id).current_pp
	var definition := catalog.move(id).to_dict()
	var events := _reaction(f)
	var replay := restored.submit_reaction_turn(BattleAction.new(1, f.actor.instance_id, id, f.target.instance_id, BattleAction.MOVE, side), &"side_b" if side == &"side_a" else &"side_a")
	check(label + " deterministic JSON continuation", _rows(events) == _rows(replay) and f.server.snapshot() == restored.snapshot())
	check(label + " resolves once and pays one PP", _count(events, BattleEvent.ACTION_USED) == 1 and f.actor.move_slot(id).current_pp == pp - 1 and _count(events, BattleEvent.TURN_ENDED) == 1)
	check(label + " canonical definition untouched", catalog.move(id).to_dict() == definition)
	if id == &"haze":
		check(label + " clears both active stages", f.actor.stat_stages.to_dict() == StatStages.new().to_dict() and f.target.stat_stages.to_dict() == StatStages.new().to_dict())
	elif id in [&"heart_swap", &"power_swap", &"guard_swap"]:
		var ids: Array[StringName] = StatStages.ALL.duplicate()
		if id == &"power_swap": ids.assign([StatStages.ATTACK, StatStages.SPECIAL_ATTACK])
		elif id == &"guard_swap": ids.assign([StatStages.DEFENSE, StatStages.SPECIAL_DEFENSE])
		for stat: StringName in StatStages.ALL:
			check(label + " exact swap subset " + String(stat), f.actor.stat_stages.get_stage(stat) == int(other[String(stat)] if stat in ids else own[String(stat)]) and f.target.stat_stages.get_stage(stat) == int(own[String(stat)] if stat in ids else other[String(stat)]))
	elif id == &"topsy_turvy":
		for stat: StringName in StatStages.ALL:
			check(label + " exact inversion " + String(stat), f.target.stat_stages.get_stage(stat) == -int(other[String(stat)]) and f.actor.stat_stages.get_stage(stat) == int(own[String(stat)]))
	elif id == &"clear_smog":
		check(label + " resets target after real damage", f.target.current_hp < 2000 and f.target.stat_stages.to_dict() == StatStages.new().to_dict() and f.actor.stat_stages.to_dict() == own)
	elif id == &"spectral_thief":
		for stat: StringName in StatStages.ALL:
			check(label + " steals only positive stages " + String(stat), f.target.stat_stages.get_stage(stat) == mini(0, int(other[String(stat)])) and f.actor.stat_stages.get_stage(stat) == clampi(int(own[String(stat)]) + maxi(0, int(other[String(stat)])), -6, 6))
		var expected := DamageCalculator.new().calculate(f.actor, f.target, Stage.execution_move(catalog.move(id)), catalog, SeededRandomSource.new(seed_value))
		check(label + " stolen Attack participates in same strike", int(expected.amount) == 2000 - f.target.current_hp)
	else:
		var changed := 0
		for stat: StringName in StatStages.ALL:
			var difference: int = f.actor.stat_stages.get_stage(stat) - int(own[String(stat)])
			if difference != 0:
				changed += 1
				check(label + " random stat raises by two", difference == mini(2, 6 - int(own[String(stat)])))
		check(label + " affects exactly one self stat", changed == 1 and f.target.stat_stages.to_dict() == other)
	check(label + " bench stages untouched", f.state.creature(&"a2").stat_stages.to_dict() == StatStages.new().to_dict() and f.state.creature(&"b2").stat_stages.to_dict() == StatStages.new().to_dict())
	if id in Stage.STATUS_IDS:
		check(label + " no fabricated HP damage", f.actor.current_hp == 2000 and f.target.current_hp == 2000 and _count(events, BattleEvent.DAMAGE_APPLIED) == 0)
	samples.append({"move": String(id), "side": String(side), "seed": seed_value})


func _edges_stage() -> void:
	for id: StringName in [&"power_swap", &"guard_swap", &"heart_swap", &"haze"]:
		var f := _stage_fixture(id)
		f.actor.ability_id = &"contrary"
		f.target.ability_id = &"simple"
		f.actor.status_state.add_volatile(&"substitute", {"hp": 500, "max_hp": 500})
		f.target.status_state.add_volatile(&"substitute", {"hp": 500, "max_hp": 500})
		f.actor.status_state.add_volatile(&"focus_energy")
		var events := _reaction(f)
		check(String(id) + " direct assignments bypass substitute and boost modifiers", _count(events, BattleEvent.SUBSTITUTE_BLOCKED) == 0 and _count(events, BattleEvent.STAT_STAGES_REASSIGNED) == 2)
		check(String(id) + " keeps substitute and unrelated volatile", f.actor.status_state.has_volatile(&"focus_energy") and f.target.status_state.volatile[&"substitute"].hp == 500)
	var blocked := _stage_fixture(&"topsy_turvy")
	blocked.target.status_state.add_volatile(&"substitute", {"hp": 500, "max_hp": 500})
	var saved: Dictionary = blocked.target.stat_stages.to_dict()
	check("Topsy blocked by doll", _count(_reaction(blocked), BattleEvent.SUBSTITUTE_BLOCKED) == 1 and blocked.target.stat_stages.to_dict() == saved)
	blocked = _stage_fixture(&"topsy_turvy")
	blocked.actor.ability_id = &"infiltrator"
	blocked.target.status_state.add_volatile(&"substitute", {"hp": 500, "max_hp": 500})
	check("Topsy Infiltrator bypasses doll", _count(_reaction(blocked), BattleEvent.STAT_STAGES_REASSIGNED) == 1 and blocked.target.stat_stages.get_stage(StatStages.ATTACK) == -2)
	var reflected := _stage_fixture(&"topsy_turvy")
	reflected.target.ability_id = &"magic_bounce"
	check("Topsy reflects once", _count(_reaction(reflected), BattleEvent.MOVE_REFLECTED) == 1 and reflected.actor.stat_stages.get_stage(StatStages.ATTACK) == 3 and reflected.target.stat_stages.get_stage(StatStages.ATTACK) == 2)
	var zero := _stage_fixture(&"topsy_turvy")
	zero.target.stat_stages = StatStages.new()
	var rng_before: int = zero.state.rng_state
	check("Topsy neutral target fails without fake result or RNG", _count(_reaction(zero), BattleEvent.MOVE_EFFECT_FAILED) == 1 and zero.state.rng_state == rng_before)
	for id: StringName in [&"clear_smog", &"spectral_thief"]:
		for hp in [1, 500]:
			var f := _stage_fixture(id)
			f.target.status_state.add_volatile(&"substitute", {"hp": hp, "max_hp": hp})
			var before: Dictionary = f.target.stat_stages.to_dict()
			var events := _reaction(f)
			if id == &"clear_smog":
				check("Clear Smog doll blocks reset even if it breaks", f.target.stat_stages.to_dict() == before and _count(events, BattleEvent.STAT_STAGES_REASSIGNED) == 0)
			else:
				check("Spectral Thief bypasses doll and steals", f.target.status_state.volatile[&"substitute"].hp == hp and f.target.current_hp < 2000 and f.target.stat_stages.get_stage(StatStages.ATTACK) == 0)
		var immune := _stage_fixture(id)
		immune.target.species_id = &"steelix" if id == &"clear_smog" else &"snorlax"
		var before: Dictionary = immune.target.stat_stages.to_dict()
		var events := _reaction(immune)
		check(String(id) + " immunity prevents damage and stage effects", immune.target.current_hp == 2000 and immune.target.stat_stages.to_dict() == before and _count(events, BattleEvent.STAT_STAGES_REASSIGNED) == 0)
	var miss := _stage_fixture(&"spectral_thief")
	miss.actor.stat_stages = StatStages.from_dict({"accuracy": -6})
	miss.target.stat_stages = StatStages.from_dict({"evasion": 6, "attack": 3})
	check("Spectral miss does not steal", _count(_reaction(miss), BattleEvent.MOVE_MISSED) == 1 and miss.target.stat_stages.get_stage(StatStages.ATTACK) == 3)
	var contact := _stage_fixture(&"spectral_thief")
	contact.target.ability_id = &"iron_barbs"
	check("Spectral correct contact triggers existing retaliation", _count(_reaction(contact), BattleEvent.ABILITY_TRIGGERED) > 0 and contact.actor.current_hp < 2000 and not catalog.move(&"spectral_thief").makes_contact)
	for ability: StringName in [&"simple", &"contrary"]:
		var f := _stage_fixture(&"spectral_thief")
		f.actor.ability_id = ability
		_reaction(f)
		check("Spectral receiving boosts honors " + String(ability), f.actor.stat_stages.get_stage(StatStages.ATTACK) == (1 if ability == &"simple" else -5) and f.target.stat_stages.get_stage(StatStages.ATTACK) == 0)
	for ability: StringName in [&"", &"simple", &"contrary"]:
		var f := _stage_fixture(&"acupressure")
		f.actor.ability_id = ability
		var stages := {}
		for id: StringName in StatStages.ALL: stages[String(id)] = 6
		stages["speed"] = 0
		f.actor.stat_stages = StatStages.from_dict(stages)
		f.actor.status_state.add_volatile(&"substitute", {"hp": 500, "max_hp": 500})
		_reaction(f)
		check("Acupressure chooses only uncapped stat and honors " + String(ability), f.actor.stat_stages.get_stage(StatStages.SPEED) == (-2 if ability == &"contrary" else (4 if ability == &"simple" else 2)))
	var capped := _stage_fixture(&"acupressure")
	for id: StringName in StatStages.ALL: capped.actor.stat_stages.change(id, 12)
	rng_before = capped.state.rng_state
	check("Acupressure all capped fails without random draw", _count(_reaction(capped), BattleEvent.MOVE_EFFECT_FAILED) == 1 and capped.state.rng_state == rng_before)
	var legacy := _stage_fixture(&"haze")
	legacy.state.live_moves_enabled = false
	var before: Dictionary = legacy.actor.stat_stages.to_dict()
	check("flag-off legacy snapshot behavior stays unchanged", _count(_reaction(legacy), BattleEvent.STAT_STAGES_REASSIGNED) == 0 and legacy.actor.stat_stages.to_dict() == before)
	var f := _stage_fixture(&"heart_swap")
	var live_snapshot := f.server.snapshot() as Dictionary
	var fork := BattleSimulationFork.from_state(f.state, catalog)
	fork.submit_turn([_action(f), BattleAction.new(1, f.target.instance_id, &"tackle", f.actor.instance_id, BattleAction.MOVE, &"side_b")] as Array[BattleAction])
	check("AI simulation executes stages without changing live state/RNG", f.server.snapshot() == live_snapshot and fork.state().creature(f.actor.instance_id).stat_stages.get_stage(StatStages.ATTACK) == 2)


func _visual_stage() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	for id: StringName in Stage.TYPES:
		var config: Dictionary = scene.test_panel.current_configuration().duplicate(true)
		config.player_team = [{"species_id": "vulpix_alola__shiny", "level": 50}]
		config.trainer_team = [{"species_id": "pikachu", "level": 50}]
		config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50; config.encounter_chance_percent = 100
		check("ordinary scene config " + String(id), scene._bootstrap_demo(config))
		scene._configure_presentations()
		var started = scene._director.on_step(scene.TECHNICAL_ZONE_ID)
		check("ordinary wild encounter " + String(id), started.battle_started)
		if not started.battle_started: return
		var ui = scene.battle_presentation
		var actor: CreatureInstance = scene._session.player_active()
		var target: CreatureInstance = scene._session.current_wild()
		actor.moveset.clear(); actor.move_ids.clear(); actor.add_move(id, scene._catalogs)
		target.moveset.clear(); target.move_ids.clear(); target.add_move(&"splash", scene._catalogs)
		actor.stats.max_hp = 2000; actor.current_hp = 2000; actor.stats.speed = 200
		target.stats.max_hp = 2000; target.current_hp = 2000; target.stats.speed = 1
		actor.stat_stages = StatStages.from_dict({"attack": -2, "defense": 1})
		target.stat_stages = StatStages.from_dict({"attack": 2, "defense": 3, "special_attack": 1})
		ui.open_for_active_battle()
		# Let the newly visible battle panel finish layout before manually stepping
		# its playback; a zero-size first frame is not a source-art defect.
		await process_frame
		await process_frame
		ui._playback.set_process(false)
		check("ordinary menu admits " + String(id), id in ui.available_move_ids())
		var events: Array[BattleEvent] = ui.submit_player_move(id)
		check("actual UI resolves " + String(id), _count(events, BattleEvent.ACTION_USED) > 0 and _count(events, BattleEvent.ACTION_REJECTED) == 0)
		var snapshot: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
		var native := false
		var remaining := 0
		while ui._playback.is_playing() and remaining < 1000:
			var entry: Dictionary = ui._playback._sequence[ui._playback._index]
			if entry.get("catalog_clip", "") == String(id) + "/back" and not native:
				ui._playback._process(minf(0.3, float(entry.duration) * 0.4))
				native = true
				check("native clip present " + String(id), ui._playback._live_catalog.preview != null and ui._playback._live_catalog.preview.visible)
				check("native arena has completed layout " + String(id), ui._playback._live_catalog.preview.size.x > 0 and ui._playback._live_catalog.preview.size.y > 0)
				await _capture_stage(String(id) + "_native")
			ui._playback._process(0.1)
			remaining += 1
		check("native effect and playback finish " + String(id), native and not ui._playback.is_playing())
		check("playback keeps mechanical snapshot unchanged " + String(id), ui.session.battle_state().to_dict() == snapshot)
		check("shiny regional appearance survives " + String(id), actor.is_shiny and ui._arena.player_species == &"vulpix_alola__shiny")
		await _capture_stage(String(id) + "_after")
		ui._playback.cancel()
		ui.hide()
	_visual_done = true
	scene.queue_free()
	await process_frame


func _capture_stage(label: String) -> void:
	if not gpu: return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := DEST + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
