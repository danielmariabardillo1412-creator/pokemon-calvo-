extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Healing = preload("res://modules/battle/application/healing_move_rules.gd")
const Live = preload("res://modules/battle/application/live_move_profile.gd")
const DEST := "res://.godot/healing_checks/"
var _done := false
var visual_samples: Array = []


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	create_timer(180).timeout.connect(func():
		if not _done: quit(2))
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for id: StringName in Healing.CONTRACTS:
		check("canonical contract " + String(id), Healing.supports(catalog.move(id)) and Live.reason(catalog.move(id)).is_empty())
		for key: String in ["power", "pp", "accuracy", "priority", "makes_contact", "type_id", "damage_class", "target", "crit_rate_bp"]:
			var data := catalog.move(id).to_dict()
			if key == "makes_contact": data[key] = true
			elif key == "type_id": data[key] = "dark"
			elif key == "damage_class": data[key] = "physical"
			elif key == "target": data[key] = "entire-field"
			else: data[key] = int(data[key]) + 1
			check("contract mutation rejected " + String(id) + "/" + key, Live.reason(MoveDefinition.from_dict(data)) == "mechanics_contract_mismatch")
		var tampered := MoveDefinition.from_dict(catalog.move(id).to_dict())
		tampered.effect_specs.append(BattleEffectSpec.new(BattleEffectSpec.DAMAGE))
		check("unexpected canonical effect rejected " + String(id), not Healing.supports(tampered))
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13): _case(id, side, seed_value)
	_edges_healing()
	_rest_cycles()
	await _visual_healing()
	var hashes := {}
	for path: String in ["modules/battle/application/healing_move_rules.gd", "modules/battle/application/live_move_profile.gd", "modules/battle/application/turn_executor.gd", "modules/status/domain/battle_status_state.gd", "modules/status/application/status_system.gd", "tests/battle/healing_move_test_runner.gd", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var result := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "gpu": gpu,
		"cases": samples.size(), "moves": Healing.CONTRACTS.keys(), "captures": captures, "visual_samples": visual_samples, "source_sha256": hashes}
	FileAccess.open(DEST + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	_done = true
	print("HEALING_MOVES ", result.status, " checks=", checks, " cases=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _healing_fixture(id: StringName, side: StringName = &"side_a", seed_value: int = 7) -> Dictionary:
	var f := _fixture(id, side, seed_value)
	Live.apply(f.state)
	for creature_id: StringName in f.state.participant_ids:
		var c: CreatureInstance = f.state.creature(creature_id)
		c.stats.max_hp = 101; c.current_hp = 17
		c.status_state.persistent_id = &"burn"
		c.status_state.toxic_counter = 9
		c.status_ids.assign([&"burn"])
	if id == &"life_dew": f.actor.status_state.clear_persistent(); f.actor.status_ids.clear()
	f.actor.stat_stages = StatStages.from_dict({"accuracy": -6})
	f.target.stat_stages = StatStages.from_dict({"evasion": 6})
	return f


func _case(id: StringName, side: StringName, seed_value: int) -> void:
	var f := _healing_fixture(id, side, seed_value)
	var label := "%s/%s/%d" % [id, side, seed_value]
	var canonical := catalog.move(id).to_dict().duplicate(true)
	var snapshot: Dictionary = f.server.snapshot()
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(snapshot))), catalog)
	var events := _reaction(f)
	var replay := restored.submit_reaction_turn(BattleAction.new(1, f.actor.instance_id, id, f.target.instance_id, BattleAction.MOVE, side), &"side_b" if side == &"side_a" else &"side_a")
	check(label + " authoritative deterministic save/replay", _rows(events) == _rows(replay) and restored.snapshot() == f.server.snapshot())
	check(label + " executes once and pays PP", _count(events, BattleEvent.ACTION_USED) == 1 and f.actor.move_slot(id).current_pp == catalog.move(id).pp - 1)
	check(label + " bypasses accuracy/evasion without RNG", _count(events, BattleEvent.MOVE_MISSED) == 0 and f.state.rng_state == seed_value)
	check(label + " full turn once", _count(events, BattleEvent.TURN_ENDED) == 1)
	var expected_heal := 0
	if id in [&"life_dew", &"jungle_healing", &"lunar_blessing"]: expected_heal = 25
	elif id == &"purify": expected_heal = 51
	elif id == &"rest": expected_heal = 84
	var hp_restored := 0
	for event: BattleEvent in events:
		if event.kind == BattleEvent.HP_RECOVERED and event.target_id == f.actor.instance_id: hp_restored += event.amount
	check(label + " exact recovered HP", hp_restored == expected_heal)
	var expected_cures := 3 if id in [&"aromatherapy", &"heal_bell"] else (0 if id == &"life_dew" else 1)
	check(label + " cures only intended recipients", _count(events, BattleEvent.STATUS_CURED) == expected_cures)
	var own_side: BattleSide = f.state.side_for_creature(f.actor.instance_id)
	for id2: StringName in own_side.party_ids:
		if id2 == f.actor.instance_id: continue
		var ally: CreatureInstance = f.state.creature(id2)
		check(label + " reserve HP untouched", ally.current_hp == 17)
		check(label + " reserve status scope", ally.status_state.persistent_id == (&"" if id in [&"aromatherapy", &"heal_bell"] else &"burn"))
	check(label + " canonical definition unchanged", catalog.move(id).to_dict() == canonical)
	if id == &"rest": check(label + " fixed sleep state", f.actor.status_state.persistent_id == &"sleep" and f.actor.status_state.turns_remaining == 2 and f.actor.status_state.rest_sleep)
	elif id != &"purify": check(label + " user cured/healthy", f.actor.status_state.persistent_id == &"")
	else: check(label + " purify cures opponent and leaves user status", f.target.status_state.persistent_id == &"" and f.actor.status_state.persistent_id == &"burn")
	samples.append({"move": String(id), "side": String(side), "seed": seed_value, "recovered_hp": hp_restored})


func _edges_healing() -> void:
	for id: StringName in Healing.CONTRACTS:
		var f := _healing_fixture(id)
		for creature_id: StringName in f.state.participant_ids:
			var c: CreatureInstance = f.state.creature(creature_id)
			c.current_hp = c.stats.max_hp; c.status_state.clear_persistent(); c.status_ids.clear()
		check("healthy/full failure still pays PP " + String(id), _count(_reaction(f), BattleEvent.MOVE_EFFECT_FAILED) == 1 and f.actor.move_slot(id).current_pp == catalog.move(id).pp - 1)
		var fork_source := _healing_fixture(id)
		var before: Dictionary = fork_source.server.snapshot()
		var fork := BattleSimulationFork.from_state(fork_source.state, catalog)
		fork.server.submit_reaction_turn(_action(fork_source), &"side_b")
		check("independent AI simulation " + String(id), fork_source.server.snapshot() == before and fork.state().to_dict() != before)
		check("shared legal AI/player candidate " + String(id), id in Live.moves(fork_source.actor, catalog))
	for id: StringName in Healing.HEALING:
		var blocked := _healing_fixture(id)
		blocked.actor.status_state.add_volatile(&"heal_block")
		var events := _reaction(blocked)
		check("heal block prevents whole move " + String(id), _count(events, BattleEvent.HP_RECOVERED) == 0 and _count(events, BattleEvent.STATUS_CURED) == 0 and _count(events, BattleEvent.MOVE_EFFECT_FAILED) == 1)
	for id: StringName in [&"aromatherapy", &"heal_bell"]:
		var f := _healing_fixture(id)
		var party: Array[StringName] = f.state.side_for_creature(f.actor.instance_id).party_ids
		f.state.creature(party[1]).current_hp = 0
		f.state.creature(party[2]).ability_id = &"good_as_gold"
		var events := _reaction(f)
		check("party cure skips fainted, inactive Good as Gold does not block " + String(id), _count(events, BattleEvent.STATUS_CURED) == 2 and f.state.creature(party[1]).current_hp == 0)
		f = _healing_fixture(id); party = f.state.side_for_creature(f.actor.instance_id).party_ids
		f.actor.ability_id = &"soundproof" if id == &"heal_bell" else &"sap_sipper"
		f.state.creature(party[1]).ability_id = f.actor.ability_id
		check("self/reserve abilities do not block modern party cure " + String(id), _count(_reaction(f), BattleEvent.STATUS_CURED) == 3)
	for pair: Array in [[101, 25, 25], [102, 25, 26], [103, 26, 26], [104, 26, 26], [105, 26, 26], [106, 26, 27], [107, 27, 27]]:
		for id: StringName in [&"life_dew", &"jungle_healing", &"lunar_blessing"]:
			var f := _healing_fixture(id)
			f.actor.stats.max_hp = pair[0]; f.actor.current_hp = 1
			var restored := 0
			for event: BattleEvent in _reaction(f):
				if event.kind == BattleEvent.HP_RECOVERED: restored += event.amount
			check("quarter HP reference rounding %s/%d" % [id, pair[0]], restored == pair[2 if id == &"life_dew" else 1])
	for ability: StringName in [&"insomnia", &"vital_spirit", &"comatose", &"sweet_veil", &"purifying_salt"]:
		var f := _healing_fixture(&"rest"); f.actor.ability_id = ability
		var events := _reaction(f)
		check("Rest sleep immunity atomic " + String(ability), _count(events, BattleEvent.MOVE_EFFECT_FAILED) == 1 and _count(events, BattleEvent.HP_RECOVERED) == 0 and f.actor.status_state.persistent_id == &"burn")
	for ability: StringName in [&"", &"infiltrator", &"magic_bounce", &"good_as_gold"]:
		var f := _healing_fixture(&"purify")
		if ability == &"infiltrator": f.actor.ability_id = ability
		else: f.target.ability_id = ability
		if ability in [&"", &"infiltrator"]: f.target.status_state.add_volatile(&"substitute", {"hp": 25, "max_hp": 25})
		var events := _reaction(f)
		check("Purify shield/reflection " + String(ability), _count(events, BattleEvent.STATUS_CURED) == (1 if ability in [&"infiltrator", &"magic_bounce"] else 0))
		if ability == &"magic_bounce": check("reflected Purify cures original user", f.actor.status_state.persistent_id == &"" and f.target.status_state.persistent_id == &"burn")
	var sleep := BattleStatusState.new()
	check("legacy status wire unchanged", not sleep.to_dict().has("rest_sleep"))
	sleep.rest_sleep = true; sleep.persistent_id = &"sleep"; sleep.turns_remaining = 2
	check("Rest additive status round trip", BattleStatusState.from_dict(sleep.to_dict()).to_dict() == sleep.to_dict())
	sleep.clear_persistent()
	check("curing clears all sleep/toxic fields", not sleep.rest_sleep and sleep.turns_remaining == 0 and sleep.toxic_counter == 0)


func _rest_cycles() -> void:
	for ability: StringName in [&"", &"early_bird"]:
		var f := _healing_fixture(&"rest"); f.actor.ability_id = ability
		f.target.status_state.clear_persistent(); f.target.status_ids.clear()
		_reaction(f)
		f.actor.add_move(&"haze", catalog); f.move = &"haze"
		var sleeps := 1 if ability == &"early_bird" else 2
		for turn in range(sleeps):
			var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(f.server.snapshot()))), catalog)
			var action := _action(f)
			var events := _reaction(f)
			check("Rest asleep action %s/%d" % [ability, turn], _count(events, BattleEvent.ACTION_PREVENTED) == 1 and f.actor.move_slot(&"haze").current_pp == catalog.move(&"haze").pp)
			check("Rest asleep save/replay %s/%d" % [ability, turn], _rows(events) == _rows(restored.submit_reaction_turn(action, &"side_b")) and restored.snapshot() == f.server.snapshot())
		var wake := _reaction(f)
		check("Rest wakes and acts " + String(ability), _count(wake, BattleEvent.ACTION_USED) == 1 and f.actor.status_state.persistent_id == &"" and not f.actor.status_state.rest_sleep)
	var f := _healing_fixture(&"rest")
	f.target.status_state.clear_persistent(); f.target.status_ids.clear()
	_reaction(f)
	var sleeper: CreatureInstance = f.actor
	var reserve_id: StringName = f.state.side_for_creature(sleeper.instance_id).party_ids[1]
	var reserve: CreatureInstance = f.state.creature(reserve_id)
	reserve.status_state.clear_persistent(); reserve.status_ids.clear(); reserve.current_hp = 101
	var switched: Array[BattleEvent] = f.server.submit_reaction_turn(BattleAction.new(2, sleeper.instance_id, &"", &"", BattleAction.SWITCH, &"side_a", reserve_id), &"side_b")
	check("switch preserves fixed Rest sleep while inactive", _count(switched, BattleEvent.SWITCHED) == 1 and sleeper.status_state.rest_sleep and sleeper.status_state.turns_remaining == 2)
	var restored := BattleState.from_dict(JSON.parse_string(JSON.stringify(f.server.snapshot())))
	check("benched Rest survives save/load", restored.creature(sleeper.instance_id).status_state.rest_sleep and restored.creature(sleeper.instance_id).status_state.turns_remaining == 2)
	reserve.add_move(&"heal_bell", catalog)
	f.actor = reserve; f.move = &"heal_bell"
	var cured := _reaction(f)
	check("party cure clears benched Rest timer and marker", _count(cured, BattleEvent.STATUS_CURED) >= 1 and sleeper.status_state.persistent_id == &"" and not sleeper.status_state.rest_sleep and sleeper.status_state.turns_remaining == 0)


func _visual_healing() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene); await process_frame; await physics_frame
	for id: StringName in Healing.CONTRACTS:
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
		actor.stats.max_hp = 2000; actor.current_hp = 700; actor.stats.speed = 200
		target.stats.max_hp = 2000; target.current_hp = 2000; target.stats.speed = 1
		if id != &"life_dew": actor.status_state.persistent_id = &"burn"; actor.status_ids.assign([&"burn"])
		if id == &"purify": target.status_state.persistent_id = &"burn"; target.status_ids.assign([&"burn"])
		ui.open_for_active_battle(); await process_frame; await process_frame; ui._playback.set_process(false)
		check("ordinary menu admits " + String(id), id in ui.available_move_ids())
		var events: Array[BattleEvent] = ui.submit_player_move(id)
		check("ordinary command executes " + String(id), _count(events, BattleEvent.ACTION_USED) >= 1 and _count(events, BattleEvent.ACTION_REJECTED) == 0)
		for event: BattleEvent in events:
			if event.kind in [BattleEvent.HP_RECOVERED, BattleEvent.STATUS_CURED]:
				var text: String = preload("res://modules/battle/presentation/live_move_event_text.gd").describe(event, "Origen", "Objetivo", scene._catalogs)
				check("localized recovery/cure text " + String(id), not text.is_empty() and not text.contains("Evento de combate"))
		var snapshot: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
		var native := false; var limit := 0
		while ui._playback.is_playing() and limit < 1000:
			var entry: Dictionary = ui._playback._sequence[ui._playback._index]
			if entry.get("catalog_clip", "") == String(id) + "/back" and not native:
				ui._playback._process(minf(0.3, float(entry.duration) * 0.4)); native = true
				await _capture_healing(String(id) + "_native")
			ui._playback._process(0.1); limit += 1
		check("native playback preserves state " + String(id), native and not ui._playback.is_playing() and ui.session.battle_state().to_dict() == snapshot)
		check("healing HUD matches authoritative HP " + String(id), ui.displayed_player_hp() == actor.current_hp and ui.displayed_enemy_hp() == target.current_hp)
		visual_samples.append({"move": String(id), "player_hp": actor.current_hp, "displayed_player_hp": ui.displayed_player_hp(), "enemy_hp": target.current_hp, "displayed_enemy_hp": ui.displayed_enemy_hp()})
		await _capture_healing(String(id) + "_after")
		ui._playback.cancel(); ui.hide()
	scene.queue_free(); await process_frame


func _capture_healing(label: String) -> void:
	if not gpu: return
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	var path := DEST + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
