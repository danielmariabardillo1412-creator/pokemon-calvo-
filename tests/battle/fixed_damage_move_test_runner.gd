extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Fixed = preload("res://modules/battle/application/fixed_damage_move_rules.gd")
const Live = preload("res://modules/battle/application/live_move_profile.gd")
const Sub = preload("res://modules/battle/application/substitute_rules.gd")
const DEST := "res://.godot/fixed_damage_checks/"
var _completed := false
var _visual_done := false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	create_timer(180).timeout.connect(func():
		if not _completed:
			push_error("FIXED_DAMAGE batch timed out")
			quit(2))
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for id: StringName in Fixed.CONTRACTS:
		check("canonical fixed contract " + String(id), Fixed.supports(catalog.move(id)) and Live.reason(catalog.move(id)).is_empty())
		for field: String in ["power", "accuracy", "pp", "priority", "crit_rate_bp", "makes_contact", "type_id", "target", "damage_class"]:
			var row := catalog.move(id).to_dict()
			if field == "makes_contact": row[field] = not row[field]
			elif field == "type_id": row[field] = "water"
			elif field == "target": row[field] = "user"
			elif field == "damage_class": row[field] = "status"
			else: row[field] = int(row[field]) + 1
			check("altered fixed contract rejected " + String(id) + "/" + field, Live.reason(MoveDefinition.from_dict(row)) == "mechanics_contract_mismatch")
		var altered := MoveDefinition.from_dict(catalog.move(id).to_dict())
		altered.effect_specs.append(BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.SELF, 50))
		check("new effect cannot silently join fixed contract " + String(id), not Fixed.supports(altered))
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13): _case(id, side, seed_value)
	_edges_fixed()
	await _visual_fixed()
	check("visual fixed lifecycle completed", _visual_done)
	var hashes := {}
	for path: String in ["modules/battle/application/fixed_damage_move_rules.gd", "modules/battle/application/live_move_profile.gd", "modules/battle/application/turn_executor.gd", "modules/battle/effects/battle_effect_executor.gd", "tests/battle/fixed_damage_move_test_runner.gd", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "cases": samples.size(), "moves": Fixed.CONTRACTS.keys(), "captures": captures,
		"source_sha256": hashes, "newly_admitted": ["dragon_rage", "sonic_boom", "seismic_toss", "night_shade", "super_fang", "natures_madness"],
		"corrected_existing": ["ruination"], "reference_package": "@pkmn/sim@0.10.11"}
	FileAccess.open(DEST + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	_completed = true
	print("FIXED_DAMAGE_MOVES ", report.status, " checks=", checks, " cases=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _fixed_fixture(id: StringName, side: StringName = &"side_a", seed_value: int = 7) -> Dictionary:
	var f := _fixture(id, side, seed_value)
	Live.apply(f.state)
	f.target.current_hp = 101
	return f


func _expected(id: StringName) -> int:
	if id == &"dragon_rage": return 40
	if id == &"sonic_boom": return 20
	return 50 # level 50, or floor(101 current HP / 2)


func _case(id: StringName, side: StringName, seed_value: int) -> void:
	var f := _fixed_fixture(id, side, seed_value)
	var label := "%s/%s/%d" % [id, side, seed_value]
	var before: Dictionary = f.server.snapshot()
	var canonical := catalog.move(id).to_dict().duplicate(true)
	var pp: int = f.actor.move_slot(id).current_pp
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(before))), catalog)
	var events := _reaction(f)
	var replay := restored.submit_reaction_turn(BattleAction.new(1, f.actor.instance_id, id, f.target.instance_id, BattleAction.MOVE, side), &"side_b" if side == &"side_a" else &"side_a")
	check(label + " exact fixed HP", f.target.current_hp == 101 - _expected(id) and _count(events, BattleEvent.DAMAGE_APPLIED) == 1)
	check(label + " authoritative action and PP", _count(events, BattleEvent.ACTION_USED) == 1 and _count(events, BattleEvent.ACTION_REJECTED) == 0 and f.actor.move_slot(id).current_pp == pp - 1)
	check(label + " no critical or type scaling event", _count(events, BattleEvent.CRITICAL_HIT) == 0 and _count(events, BattleEvent.TYPE_EFFECTIVENESS) == 0)
	check(label + " JSON deterministic continuation", _rows(events) == _rows(replay) and f.server.snapshot() == restored.snapshot())
	check(label + " canonical move stays frozen", catalog.move(id).to_dict() == canonical)
	var rng := SeededRandomSource.new(seed_value)
	rng.roll_basis_points(10000)
	check(label + " no damage variance/critical RNG draws", f.state.rng_state == rng.state())
	check(label + " full turn completed once", _count(events, BattleEvent.TURN_ENDED) == 1)
	samples.append({"move": String(id), "side": String(side), "seed": seed_value, "damage": 101 - f.target.current_hp})


func _edges_fixed() -> void:
	for id: StringName in Fixed.CONTRACTS:
		var miss := _fixed_fixture(id, &"side_a", 1)
		miss.actor.stat_stages = StatStages.from_dict({"accuracy": -6})
		miss.target.stat_stages = StatStages.from_dict({"evasion": 6})
		var missed := _reaction(miss)
		check("miss pays PP without fixed effect " + String(id), _count(missed, BattleEvent.MOVE_MISSED) == 1 and miss.target.current_hp == 101 and miss.actor.move_slot(id).current_pp == catalog.move(id).pp - 1)
		var ruleset := BattleRuleset.new()
		ruleset.critical_chance_denominator = 1
		var burn := _fixed_fixture(id)
		burn.actor.status_state.persistent_id = &"burn"
		burn.server = AuthoritativeBattleServer.new(burn.state, catalog, ruleset)
		var events := _reaction(burn)
		check("burn and forced critical do not scale fixed damage " + String(id), burn.target.current_hp == 101 - _expected(id) and _count(events, BattleEvent.CRITICAL_HIT) == 0)
		var legacy := _fixed_fixture(id)
		legacy.state.live_moves_enabled = false
		_reaction(legacy)
		check("flag-off legacy damage remains unchanged " + String(id), legacy.target.current_hp == 101 if id != &"ruination" else legacy.target.current_hp > 90)
		var fork_source := _fixed_fixture(id)
		var baseline: Dictionary = fork_source.server.snapshot()
		var fork := BattleSimulationFork.from_state(fork_source.state, catalog)
		fork.server.submit_reaction_turn(_action(fork_source), &"side_b")
		check("AI fork applies fixed effect independently " + String(id), fork.state().creature(fork_source.target.instance_id).current_hp == 101 - _expected(id) and fork_source.server.snapshot() == baseline)
		check("same move is a legal live AI/player candidate " + String(id), id in Live.moves(fork_source.actor, catalog))
	var contact := _fixed_fixture(&"super_fang")
	contact.target.ability_id = &"iron_barbs"
	var contact_events := _reaction(contact)
	check("Super Fang detached contact activates existing Iron Barbs", contact.actor.current_hp == 1750 and _count(contact_events, BattleEvent.ABILITY_TRIGGERED) == 1 and not catalog.move(&"super_fang").makes_contact)
	for doll_hp in [1, 500]:
		var doll := _fixed_fixture(&"super_fang")
		doll.target.status_state.add_volatile(&"substitute", {"hp": doll_hp, "max_hp": doll_hp})
		_reaction(doll)
		check("half damage uses body HP, clipped by doll " + str(doll_hp), doll.target.current_hp == 101 and Sub.hp(doll.target) == maxi(0, doll_hp - 50))
	var ko := _fixed_fixture(&"dragon_rage")
	ko.target.current_hp = 3
	var knockout := _reaction(ko)
	check("KO clips to remaining body HP and substitutes once", ko.target.current_hp == 0 and _count(knockout, BattleEvent.KNOCKED_OUT) == 1 and _count(knockout, BattleEvent.SWITCHED) == 1)
	var empty := _fixed_fixture(&"night_shade")
	empty.actor.move_slot(&"night_shade").current_pp = 0
	var empty_events := _reaction(empty)
	check("zero PP rejects before executing fixed effect", _count(empty_events, BattleEvent.ACTION_REJECTED) == 1 and empty.target.current_hp == 101)


func _visual_fixed() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	for id: StringName in Fixed.CONTRACTS:
		var config: Dictionary = scene.test_panel.current_configuration().duplicate(true)
		config.player_team = [{"species_id": "vulpix_alola__shiny", "level": 50}]
		config.trainer_team = [{"species_id": "pikachu", "level": 50}]
		config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50; config.encounter_chance_percent = 100
		check("ordinary game boot " + String(id), scene._bootstrap_demo(config))
		scene._configure_presentations()
		var started = scene._director.on_step(scene.TECHNICAL_ZONE_ID)
		check("ordinary encounter " + String(id), started.battle_started)
		if not started.battle_started: return
		var ui = scene.battle_presentation
		var actor: CreatureInstance = scene._session.player_active()
		var target: CreatureInstance = scene._session.current_wild()
		actor.moveset.clear(); actor.move_ids.clear(); actor.add_move(id, scene._catalogs)
		# Splash is excluded by the real game profile and becomes Struggle. Its
		# recoil would KO a low-HP opponent and contaminate this exact-HP check.
		target.moveset.clear(); target.move_ids.clear(); target.add_move(&"swords_dance", scene._catalogs)
		actor.stats.max_hp = 2000; actor.current_hp = 2000; actor.stats.speed = 200
		target.stats.max_hp = 2000; target.current_hp = 101; target.stats.speed = 1
		actor.stat_stages = StatStages.from_dict({"accuracy": 6})
		target.stat_stages = StatStages.from_dict({"evasion": -6})
		ui.open_for_active_battle()
		await process_frame
		await process_frame
		ui._playback.set_process(false)
		check("ordinary menu admits " + String(id), id in ui.available_move_ids())
		var events: Array[BattleEvent] = ui.submit_player_move(id)
		check("ordinary UI applies actual exact damage " + String(id), target.current_hp == 101 - _expected(id) and _count(events, BattleEvent.ACTION_REJECTED) == 0)
		if ui.session.battle_state() == null: return
		var snapshot: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
		var native := false
		var remaining := 0
		while ui._playback.is_playing() and remaining < 1000:
			var entry: Dictionary = ui._playback._sequence[ui._playback._index]
			if entry.get("catalog_clip", "") == String(id) + "/back" and not native:
				ui._playback._process(minf(0.3, float(entry.duration) * 0.4))
				native = true
				check("native clip visible " + String(id), ui._playback._live_catalog.preview != null and ui._playback._live_catalog.preview.visible and ui._playback._live_catalog.preview.size.x > 0)
				await _capture_fixed(String(id) + "_native")
			ui._playback._process(0.1)
			remaining += 1
		check("native playback completes " + String(id), native and not ui._playback.is_playing())
		check("playback preserves resolved state " + String(id), ui.session.battle_state().to_dict() == snapshot)
		check("regional shiny survives " + String(id), actor.is_shiny and ui._arena.player_species == &"vulpix_alola__shiny")
		await _capture_fixed(String(id) + "_after")
		ui._playback.cancel()
		ui.hide()
	_visual_done = true
	scene.queue_free()
	await process_frame


func _capture_fixed(label: String) -> void:
	if not gpu: return
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var path := DEST + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
