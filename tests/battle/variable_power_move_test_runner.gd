extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Variable = preload("res://modules/battle/application/variable_power_move_rules.gd")
const Live = preload("res://modules/battle/application/live_move_profile.gd")
const DEST := "res://.godot/variable_power_checks/"
var _done := false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	create_timer(180).timeout.connect(func():
		if not _done: quit(2))
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	for id: StringName in Variable.CONTRACTS:
		check("canonical contract " + String(id), Variable.supports(catalog.move(id)) and Live.reason(catalog.move(id)).is_empty())
		for key: String in ["power", "pp", "accuracy", "priority", "makes_contact", "type_id", "damage_class", "target", "crit_rate_bp"]:
			var row := catalog.move(id).to_dict()
			if key == "makes_contact": row[key] = true
			elif key == "type_id": row[key] = "water"
			elif key == "damage_class": row[key] = "status"
			elif key == "target": row[key] = "user"
			else: row[key] = int(row[key]) + 1
			check("contract mutation rejected " + String(id) + "/" + key, Live.reason(MoveDefinition.from_dict(row)) == "mechanics_contract_mismatch")
		for side: StringName in [&"side_a", &"side_b"]:
			for seed_value in range(1, 13): _variable_case(id, side, seed_value)
	_edges_variable()
	await _visual_variable()
	var hashes := {}
	for path: String in ["modules/battle/application/variable_power_move_rules.gd", "modules/battle/application/live_move_profile.gd", "modules/battle/application/turn_executor.gd", "modules/battle/domain/turn_resolver.gd", "modules/battle/effects/battle_effect_executor.gd", "tests/battle/variable_power_move_test_runner.gd", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var result := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "cases": samples.size(), "moves": Variable.CONTRACTS.keys(), "captures": captures, "source_sha256": hashes}
	FileAccess.open(DEST + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	_done = true
	print("VARIABLE_POWER_MOVES ", result.status, " checks=", checks, " cases=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _variable_fixture(id: StringName, side: StringName = &"side_a", seed_value: int = 7) -> Dictionary:
	var f := _fixture(id, side, seed_value)
	Live.apply(f.state)
	f.actor.friendship = 255
	return f


func _power(events: Array[BattleEvent], actor: StringName) -> int:
	for event: BattleEvent in events:
		if event.actor_id != actor: continue
		if event.kind == BattleEvent.DAMAGE_APPLIED: return int(event.metadata.get("resolved_power", 0))
		if event.kind == BattleEvent.SUBSTITUTE_DAMAGED: return int(event.metadata.get("damage", {}).get("resolved_power", 0))
	return 0


func _variable_case(id: StringName, side: StringName, seed_value: int) -> void:
	var f := _variable_fixture(id, side, seed_value)
	var label := "%s/%s/%d" % [id, side, seed_value]
	var before: Dictionary = f.server.snapshot()
	var canonical := catalog.move(id).to_dict().duplicate(true)
	var pp: int = f.actor.move_slot(id).current_pp
	var restored := AuthoritativeBattleServer.new(BattleState.from_dict(JSON.parse_string(JSON.stringify(before))), catalog)
	var events := _reaction(f)
	var replay := restored.submit_reaction_turn(_action_from_before(before, f), &"side_b" if side == &"side_a" else &"side_a")
	check(label + " JSON continuation and RNG", _rows(events) == _rows(replay) and f.server.snapshot() == restored.snapshot())
	check(label + " one authoritative action pays PP", _count(events, BattleEvent.ACTION_USED) == 1 and _count(events, BattleEvent.ACTION_REJECTED) == 0 and f.actor.move_slot(id).current_pp == pp - 1)
	check(label + " variable power reaches actual damage", _power(events, f.actor.instance_id) > 0 and f.target.current_hp < 2000)
	check(label + " canonical move unchanged", catalog.move(id).to_dict() == canonical and not catalog.move(id).makes_contact)
	check(label + " live context stays serializable", BattleState.from_dict(f.state.to_dict()).to_dict() == f.state.to_dict())
	check(label + " turn completes once", _count(events, BattleEvent.TURN_ENDED) == 1)
	samples.append({"move": String(id), "side": String(side), "seed": seed_value, "power": _power(events, f.actor.instance_id)})


func _action_from_before(_before: Dictionary, f: Dictionary) -> BattleAction:
	return BattleAction.new(1, f.actor.instance_id, f.move, f.target.instance_id, BattleAction.MOVE, f.side)


func _edges_variable() -> void:
	for id: StringName in Variable.CONTRACTS:
		var contact := _variable_fixture(id)
		contact.target.ability_id = &"iron_barbs"
		_reaction(contact)
		check("contact is corrected on detached definition " + String(id), contact.actor.current_hp == (2000 if id == &"electro_ball" else 1750) and not catalog.move(id).makes_contact)
		var legacy := _variable_fixture(id)
		legacy.state.live_moves_enabled = false
		check("flag off keeps old non-execution " + String(id), _power(_reaction(legacy), legacy.actor.instance_id) == 0 and legacy.target.current_hp == 2000)
		var f := _variable_fixture(id)
		var original: Dictionary = f.server.snapshot()
		var fork := BattleSimulationFork.from_state(f.state, catalog)
		var events := fork.server.submit_reaction_turn(_action(f), &"side_b")
		check("AI fork executes independently " + String(id), _power(events, f.actor.instance_id) > 0 and f.server.snapshot() == original and id in Live.moves(f.actor, catalog))
	for pp in range(1, 6):
		var f := _variable_fixture(&"trump_card")
		f.actor.move_slot(&"trump_card").current_pp = pp
		check("Trump Card uses PP after payment " + str(pp), _power(_reaction(f), f.actor.instance_id) == [200, 80, 60, 50, 40][pp - 1])
	for id: StringName in [&"return", &"frustration"]:
		for friendship in [0, 255]:
			var f := _variable_fixture(id)
			f.actor.friendship = friendship
			var after := BattleState.from_dict(JSON.parse_string(JSON.stringify(f.state.to_dict())))
			check("friendship survives state restore " + String(id), after.creature(f.actor.instance_id).friendship == friendship)
			check("friendship endpoint " + String(id) + str(friendship), _power(_reaction(f), f.actor.instance_id) == (102 if (id == &"return") == (friendship == 255) else 1))
	var slow := _variable_fixture(&"flail")
	slow.actor.current_hp = 100
	slow.actor.stats.speed = 1
	slow.target.stats.speed = 200
	slow.target.moveset.clear(); slow.target.move_ids.clear(); slow.target.add_move(&"dragon_rage", catalog)
	var events: Array[BattleEvent] = slow.server.submit_turn([_action(slow), BattleAction.new(1, slow.target.instance_id, &"dragon_rage", slow.actor.instance_id, BattleAction.MOVE, &"side_b")] as Array[BattleAction])
	check("Flail sees HP lost earlier in the same turn", slow.actor.current_hp == 60 and _power(events, slow.actor.instance_id) == 200)
	var speed := _variable_fixture(&"electro_ball")
	speed.actor.stats.speed = 3; speed.target.stats.speed = 1
	speed.actor.stat_stages.change(StatStages.SPEED, -1)
	var ruleset := BattleRuleset.new()
	check("exact speed boundary avoids basis-point truncation", TurnResolver.live_effective_speed(speed.actor, ruleset) == 2 and TurnResolver.new()._effective_speed(speed.actor, ruleset) == 1)
	var rng := SeededRandomSource.new(1)
	var first := TurnResolver.new().resolve_order([_action(speed), BattleAction.new(1, speed.target.instance_id, &"tackle", speed.actor.instance_id, BattleAction.MOVE, &"side_b")] as Array[BattleAction], speed.state, catalog, rng)
	check("live ordering shares exact speed without false tie RNG", first[0].actor_id == speed.actor.instance_id and rng.state() == 1)
	var immune := _variable_fixture(&"electro_ball")
	immune.target.species_id = &"sandshrew"
	check("type immunity has no power/damage event", _power(_reaction(immune), immune.actor.instance_id) == 0 and immune.target.current_hp == 2000)


func _visual_variable() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	for id: StringName in Variable.CONTRACTS:
		var config: Dictionary = scene.test_panel.current_configuration().duplicate(true)
		config.player_team = [{"species_id": "vulpix_alola__shiny", "level": 50}]
		config.trainer_team = [{"species_id": "pikachu", "level": 50}]
		config.wild_species_id = "wailord"; config.wild_min_level = 50; config.wild_max_level = 50; config.encounter_chance_percent = 100
		check("ordinary boot " + String(id), scene._bootstrap_demo(config))
		scene._configure_presentations()
		check("ordinary encounter " + String(id), scene._director.on_step(scene.TECHNICAL_ZONE_ID).battle_started)
		var ui = scene.battle_presentation
		var actor: CreatureInstance = scene._session.player_active()
		var target: CreatureInstance = scene._session.current_wild()
		actor.moveset.clear(); actor.move_ids.clear(); actor.add_move(id, scene._catalogs)
		target.moveset.clear(); target.move_ids.clear(); target.add_move(&"swords_dance", scene._catalogs)
		actor.stats.max_hp = 4000; actor.current_hp = 4000; actor.stats.speed = 200; actor.friendship = 255
		target.stats.max_hp = 4000; target.current_hp = 4000; target.stats.speed = 1
		actor.stat_stages = StatStages.from_dict({"accuracy": 6})
		target.stat_stages = StatStages.from_dict({"evasion": -6})
		ui.open_for_active_battle()
		await process_frame
		await process_frame
		ui._playback.set_process(false)
		check("ordinary menu " + String(id), id in ui.available_move_ids())
		var events: Array[BattleEvent] = ui.submit_player_move(id)
		check("ordinary real power/damage " + String(id), _power(events, actor.instance_id) > 0 and target.current_hp < 4000 and _count(events, BattleEvent.ACTION_REJECTED) == 0)
		var snapshot: Dictionary = ui.session.battle_state().to_dict().duplicate(true)
		var native := false
		var limit := 0
		while ui._playback.is_playing() and limit < 1000:
			var entry: Dictionary = ui._playback._sequence[ui._playback._index]
			if entry.get("catalog_clip", "") == String(id) + "/back" and not native:
				ui._playback._process(minf(0.3, float(entry.duration) * 0.4))
				native = true
				check("existing clip visible " + String(id), ui._playback._live_catalog.preview != null and ui._playback._live_catalog.preview.visible and ui._playback._live_catalog.preview.size.x > 0)
				await _capture_variable(String(id) + "_native")
			ui._playback._process(0.1)
			limit += 1
		check("playback completes " + String(id), native and not ui._playback.is_playing())
		check("playback preserves server state " + String(id), ui.session.battle_state().to_dict() == snapshot)
		check("shiny regional preserved " + String(id), actor.is_shiny and ui._arena.player_species == &"vulpix_alola__shiny")
		await _capture_variable(String(id) + "_after")
		ui._playback.cancel(); ui.hide()
	scene.queue_free()
	await process_frame


func _capture_variable(label: String) -> void:
	if not gpu: return
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var path := DEST + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
