extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Weather = preload("res://modules/battle/application/weather_rules.gd")
const WEATHER_OUTPUT := "res://.godot/weather_checks/"


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(WEATHER_OUTPUT)
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for move: StringName in Weather.MOVES:
		check("weather contract " + String(move), Weather.supports(catalog.move(move)))
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13): _weather_case(move, side, seed_value)
	_weather_edges()
	await _visual_cases()
	var hashes := {}
	for path: String in ["modules/battle/application/weather_rules.gd", "modules/battle/application/turn_executor.gd", "modules/battle/domain/battle_state.gd", "modules/battle/domain/battle_event.gd", "modules/battle/domain/damage_calculator.gd", "modules/battle/effects/battle_effect_executor.gd", "modules/status/application/status_system.gd", "modules/gameplay/wild_adventure_session.gd", "scenes/visual/battle_weather_cast_pilot.gd", "scenes/visual/battle_weather_layer.gd", "scenes/visual/battle_status_switch_pilot.gd", "scenes/visual/battle_animation_playback.gd", "scenes/visual/battle_timeline_plan.gd", "scenes/visual/field_battle_presentation.gd", "scenes/visual/field_demo.gd", "tests/battle/weather_pilot_test_runner.gd", "tools/visual/build_weather_pilot.py", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "core_samples": samples, "captures": captures, "source_sha256": hashes,
		"mechanics_added": ["rain_dance", "hail", "sandstorm", "snowscape", "chilly_reception"],
		"remaining_unimplemented": ["ally_switch", "shed_tail", "substitute", "transform"],
		"scope": "Explicit F9 wild singles weather pilot; trainer-format authoritative core sampled on both sides, no trainer UI/AI rollout.",
		"limitations": ["No global rollout or certification of every weather-dependent move/ability.", "Only Rain Dish and Ice Body recovery plus declared weather chip immunities/suppression are implemented here; speed/evasion abilities, Dry Skin/Hydration and weather-specific move formulas remain pending.", "No ability suppression/Neutralizing Gas, item suppression or automatic weather-setting ability lifecycle."]}
	var file := FileAccess.open(WEATHER_OUTPUT + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ", true) + "\n")
	print("WEATHER_PILOT ", report.status, " checks=", checks, " core_samples=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _weather_fixture(move: StringName, side: StringName = &"side_a", seed_value: int = 7) -> Dictionary:
	var f := _fixture(move, side, seed_value)
	f.state.weather_rules_enabled = true
	f.actor.add_move(&"swords_dance", catalog)
	return f


func _quiet(f: Dictionary) -> Array[BattleEvent]:
	return f.server.submit_reaction_turn(BattleAction.new(f.state.turn + 1, f.actor.instance_id,
		&"swords_dance", f.target.instance_id, BattleAction.MOVE, f.side), &"side_b" if f.side == &"side_a" else &"side_a")


func _weather_case(move: StringName, side: StringName, seed_value: int) -> void:
	var f := _weather_fixture(move, side, seed_value)
	var label := "%s/%s/%d" % [move, side, seed_value]
	var pp: int = f.actor.move_slot(move).current_pp
	var initial_rng: int = f.state.rng_state
	var events := _reaction(f)
	check(label + " weather committed", _count(events, BattleEvent.WEATHER_CHANGED) == 1 and f.state.weather.id == String(Weather.MOVES[move]))
	check(label + " one PP and no weather RNG", f.actor.move_slot(move).current_pp == pp - 1 and f.state.rng_state == initial_rng)
	var snapshot: Dictionary = f.server.snapshot().duplicate(true)
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), catalog)
	check(label + " weather snapshot round trip", restored.snapshot() == snapshot)
	if move == &"chilly_reception":
		check(label + " snow before replacement with no tick", f.state.phase == BattleState.WAITING_FOR_SWITCH and int(f.state.weather.turns_remaining) == 5 and _count(events, BattleEvent.WEATHER_UPKEEP) == 0)
		var incoming := &"a3" if side == &"side_a" else &"b3"
		var continuation: Array[BattleEvent] = f.server.submit_switch_choice(side, incoming, 1)
		var replayed: Array[BattleEvent] = restored.submit_switch_choice(side, incoming, 1)
		check(label + " resumed weather exact", _rows(continuation) == _rows(replayed) and f.server.snapshot() == restored.snapshot())
		check(label + " resumed tick once", f.state.turn == 1 and int(f.state.weather.turns_remaining) == 4 and _count(continuation, BattleEvent.TURN_ENDED) == 1)
	else:
		check(label + " first residual accounted", int(f.state.weather.turns_remaining) == 4 and _count(events, BattleEvent.TURN_ENDED) == 1)
		var ticks := _count(events, BattleEvent.STATUS_DAMAGE)
		for n in range(2, 6):
			var continued := _quiet(f)
			ticks += _count(continued, BattleEvent.STATUS_DAMAGE)
			check(label + " completed weather turn " + str(n), f.state.turn == n and _count(continued, BattleEvent.TURN_ENDED) == 1)
			check(label + " expires exactly " + str(n), f.state.weather.is_empty() == (n == 5))
		check(label + " residual callback stops on expiration", ticks == (8 if move in [&"hail", &"sandstorm"] else 0))
	samples.append({"move": String(move), "side": String(side), "seed": seed_value, "initial_events": _rows(events), "snapshot_after_start": snapshot})


func _weather_edges() -> void:
	for move: StringName in Weather.MOVES:
		var f := _weather_fixture(move)
		f.state.weather_rules_enabled = false
		var events := _reaction(f)
		check("legacy weather remains disabled " + String(move), f.state.weather.is_empty() and _count(events, BattleEvent.WEATHER_CHANGED) == 0 and not f.state.to_dict().has("weather_context"))
		f = _weather_fixture(move)
		f.actor.held_item_id = Weather.ROCKS[Weather.MOVES[move]]
		events = _reaction(f)
		check("correct rock extends " + String(move), int(f.state.weather.turns_remaining) == (8 if move == &"chilly_reception" else 7))
		f = _weather_fixture(move)
		f.actor.held_item_id = Weather.ROCKS[Weather.MOVES[move]]
		f.actor.held_item_consumed = true
		events = _reaction(f)
		check("consumed rock cannot extend " + String(move), int(f.state.weather.turns_remaining) == (5 if move == &"chilly_reception" else 4))
	for move: StringName in [&"rain_dance", &"hail", &"sandstorm", &"snowscape"]:
		var f := _weather_fixture(move)
		_reaction(f)
		var events := _reaction(f)
		check("same weather cannot restart timer " + String(move), _count(events, BattleEvent.WEATHER_FAILED) == 1 and int(f.state.weather.turns_remaining) == 3)
	var f := _weather_fixture(&"rain_dance")
	_reaction(f)
	f.actor.add_move(&"sandstorm", catalog)
	f.move = &"sandstorm"
	var events := _reaction(f)
	check("weather replaces previous weather", f.state.weather.id == "sandstorm" and int(f.state.weather.turns_remaining) == 4 and _find(events, BattleEvent.WEATHER_CHANGED).metadata.previous == "rain")
	# Already snowing still permits Chilly Reception to pivot without refreshing it.
	f = _weather_fixture(&"chilly_reception")
	f.state.weather = {"id": "snow", "turns_remaining": 2}
	events = _reaction(f)
	check("chilly pivots under existing snow", f.state.phase == BattleState.WAITING_FOR_SWITCH and int(f.state.weather.turns_remaining) == 2 and _count(events, BattleEvent.WEATHER_FAILED) == 1)
	check("existing snow still confirms chilly cast", _count(events, BattleEvent.MOVE_EFFECT_RESOLVED) == 1)
	f.server.submit_switch_choice(&"side_a", &"a3", 1)
	check("existing snow ticks once after chilly", int(f.state.weather.turns_remaining) == 1)
	# Real damage execution, identical seeds/stats, only weather differs.
	for spec: Array in [[&"water_gun", "rain", &"wailord", true], [&"flamethrower", "rain", &"wailord", false], [&"water_gun", "sandstorm", &"golem", false], [&"tackle", "snow", &"lapras", false]]:
		var amounts := []
		for wet in [false, true]:
			f = _weather_fixture(&"rain_dance")
			f.target.species_id = spec[2]
			f.actor.add_move(spec[0], catalog)
			f.move = spec[0]
			if wet: f.state.weather = {"id": spec[1], "turns_remaining": 5}
			events = _reaction(f)
			amounts.append(_find(events, BattleEvent.DAMAGE_APPLIED).amount)
		check("real weather damage modifier " + String(spec[0]) + spec[1], amounts[1] > amounts[0] if spec[3] else amounts[1] < amounts[0])
	for ability: StringName in [&"cloud_nine", &"air_lock"]:
		f = _weather_fixture(&"hail")
		f.target.ability_id = ability
		events = _reaction(f)
		check("suppression preserves timer without chip " + String(ability), _count(events, BattleEvent.STATUS_DAMAGE) == 0 and int(f.state.weather.turns_remaining) == 4 and Weather.effective(f.state) == &"" and _find(events, BattleEvent.WEATHER_CHANGED).metadata.weather.suppressed)
		f.target.ability_id = &""
		check("suppression ends when ability leaves", Weather.effective(f.state) == &"hail")
	for ability: StringName in [&"magic_guard", &"overcoat", &"snow_cloak", &"slush_rush", &"ice_body"]:
		f = _weather_fixture(&"hail")
		f.target.ability_id = ability
		_reaction(f)
		check("hail ability immunity " + String(ability), f.target.current_hp == 2000)
	for species: StringName in [&"golem", &"diglett", &"magnemite"]:
		f = _weather_fixture(&"sandstorm")
		f.target.species_id = species
		_reaction(f)
		check("sand type immunity " + String(species), f.target.current_hp == 2000)
	f = _weather_fixture(&"sandstorm")
	f.target.held_item_id = &"safety_goggles"
	_reaction(f)
	check("goggles prevent weather chip", f.target.current_hp == 2000)
	for spec: Array in [[&"rain_dance", &"rain_dish"], [&"hail", &"ice_body"], [&"snowscape", &"ice_body"]]:
		f = _weather_fixture(spec[0])
		f.target.ability_id = spec[1]
		f.target.current_hp = 1000
		events = _reaction(f)
		check("weather recovery " + String(spec[0]), f.target.current_hp == 1125 and _count(events, BattleEvent.HP_RECOVERED) == 1)
	# Weather KO cannot give newly sent-out Pokemon another residual/status tick.
	f = _weather_fixture(&"hail")
	f.actor.current_hp = 1
	var incoming: CreatureInstance = f.state.creature(&"a2")
	incoming.current_hp = 1700
	incoming.status_state.persistent_id = &"poison"
	incoming.held_item_id = &"leftovers"
	events = _reaction(f)
	check("weather KO replacement no extra end-turn effects", f.state.active_for_side(&"side_a") == incoming and incoming.current_hp == 1700 and _count(events, BattleEvent.SWITCHED) == 1)
	# Tiny party: weather KO ends battle once; no end-turn continuation or revive.
	f = _weather_fixture(&"hail")
	for id: StringName in f.state.sides[0].party_ids: f.state.creature(id).current_hp = 0 if id != &"a" else 1
	events = _reaction(f)
	check("weather last KO settles once", f.state.phase == BattleState.FINISHED and _count(events, BattleEvent.BATTLE_ENDED) == 1 and _count(events, BattleEvent.TURN_ENDED) == 0)


func _visual_cases() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	for n in 4: await process_frame
	for index in 5:
		check("F9 preset ready", scene.cycle_weather_test())
		scene.player.set_physics_process(false)
		var move: StringName = scene.WEATHER_TEST_MOVES[index]
		scene.player.global_position = Vector2(420, 150)
		scene.player.reset_step_meter()
		await physics_frame
		for n in 24:
			scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
			await physics_frame
			if scene.has_active_demo_battle(): break
		check("F9 real encounter", scene.has_active_demo_battle())
		var ui = scene.battle_presentation
		ui._playback.set_process(false)
		ui._playback._weather_layer.set_process(false)
		var state: BattleState = ui.session.battle_state()
		for id: StringName in state.participant_ids:
			state.creature(id).stats.max_hp = 2000
			state.creature(id).current_hp = 2000
		ui.session.player_active().stats.speed = 10000
		ui._refresh_view()
		var events: Array[BattleEvent] = ui.submit_player_move(move)
		check("F9 weather changed in real battle", _count(events, BattleEvent.WEATHER_CHANGED) == 1)
		var fixed := state.to_dict().duplicate(true)
		await _drain(ui, String(move))
		check("F9 replay preserves authoritative state", fixed == state.to_dict())
		check("F9 weather loop persists", ui._playback._weather_layer.preview.visible and ui._playback._weather_layer.current.id == String(Weather.MOVES[move]))
		ui._playback._weather_layer._process(0.65)
		check("weather common cadence preserved", ui._playback._weather_layer.preview.clip.frames.size() == (20 if move == &"sandstorm" else 30))
		check("weather loop never advances battle", fixed == state.to_dict())
		await _capture(String(move) + "_persistent")
		if move == &"chilly_reception":
			check("F9 snow present before selection", state.phase == BattleState.WAITING_FOR_SWITCH and int(state.weather.turns_remaining) == 5)
			var chosen: StringName = ui.available_switch_instance_ids()[0]
			check("F9 chilly choice accepted", ui.submit_player_switch(chosen).accepted)
			await _drain(ui, "chilly_entry")
			check("F9 snow continued same turn", state.turn == 1 and int(state.weather.turns_remaining) == 4)
			await _capture("chilly_entry_snow")
		ui.submit_capture_ball(&"master_ball")
		await _drain(ui, "capture")
		check("F9 weather cleared after capture", not ui._playback._weather_layer.preview.visible)
		check("F9 returns to map", ui.continue_after_completion())
	scene.restart_field_run()
	check("F9 reset disables weather", not scene._session.weather_rules_enabled)
	scene.queue_free()
	await process_frame


func _drain(ui: Control, label: String) -> void:
	var n := 0
	while ui._playback.is_playing() and n < 150:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		if entry.get("event_kind") == String(BattleEvent.WEATHER_CHANGED):
			check("native weather cast bound", entry.has("community_clip"))
			ui._playback.advance(float(entry.duration) * 0.5)
			ui._playback._weather_layer._process(float(entry.duration) * 0.5)
			check("persistent weather has no native bodies", not ui._playback._weather_layer.preview._arena.visible and not ui._playback._weather_layer.preview._sprites[0].visible and not ui._playback._weather_layer.preview._sprites[1].visible)
			await _capture(label + "_cast")
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		n += 1
	check("bounded weather playback", not ui._playback.is_playing())


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame
	RenderingServer.force_draw(false)
	var path := WEATHER_OUTPUT + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
