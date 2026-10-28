extends "res://tests/battle/switch_move_continuation_test_runner.gd"

const Doubles = preload("res://modules/battle/server/doubles_position_battle.gd")
const Plan = preload("res://scenes/visual/doubles_timeline_plan.gd")
const Demo = preload("res://scenes/visual/doubles_position_demo.gd")
const ALLY_OUTPUT := "res://.godot/ally_switch_checks/"
var _live_complete := false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ALLY_OUTPUT)
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("frozen Ally Switch contract", Doubles.supports_ally_switch(catalog.move(&"ally_switch")))
	for side: StringName in [&"side_a", &"side_b"]:
		for position in 2:
			for seed_value in range(1, 13): _position_case(side, position, seed_value)
	_repeat_cases()
	_edges()
	await _live_cases()
	check("live cases completed", _live_complete)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"gpu": gpu, "core_samples": samples, "captures": captures, "source_sha256": _source_hashes(),
		"format": Doubles.FORMAT, "pack_sha256": FileAccess.get_sha256(Demo.PACK), "references": ["https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts"],
		"limitations": ["Explicit 2-vs-2 adapter; no reserves, abilities/items, spread moves, capture, progression, trainer AI or matchmaking.",
			"Four diagnostic damage moves only. Existing singles API and snapshots remain separate.",
			"Four-body camera and movement are an adaptation; original Ally Switch clips have body tracks but no particle cells."]}
	FileAccess.open(ALLY_OUTPUT + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ", true) + "\n")
	print("ALLY_SWITCH_PILOT ", report.status, " checks=", checks, " samples=", samples.size(), " captures=", captures.size(), " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _double_fixture(side: StringName = &"side_a", position: int = 0, seed_value: int = 7) -> Dictionary:
	var creatures: Array[CreatureInstance] = []
	for n in 4:
		var c := CreatureInstance.new(StringName(["a0", "a1", "b0", "b1"][n]), StringName(["gardevoir", "pikachu", "charizard", "blastoise"][n]), 50,
			StatBlock.new(2000, 100, 100, [50, 60, 200, 150][n], 100, 100), [&"ally_switch", &"tackle", &"water_gun", &"quick_attack", &"extreme_speed"])
		creatures.append(c)
	var state := BattleState.create_with_parties(&"ally_switch_pilot", [creatures[0], creatures[1]], [creatures[2], creatures[3]], seed_value)
	var layout := {"side_a": ["a0", "a1"], "side_b": ["b0", "b1"]}
	if position == 1: layout[String(side)].reverse()
	var server := Doubles.new(state, catalog, layout)
	return {"state": state, "server": server, "actor": state.creature(&"a0" if side == &"side_a" else &"b0"),
		"ally": state.creature(&"a1" if side == &"side_a" else &"b1"), "side": side}


func _commands(f: Dictionary, swap: bool = true) -> Array[BattleAction]:
	var result: Array[BattleAction] = []
	var opposite := "side_b" if f.side == &"side_a" else "side_a"
	for id: StringName in f.server.living_ids():
		var owner: BattleSide = f.state.side_for_creature(id)
		var move := &"tackle"
		var target: StringName = f.actor.instance_id
		if owner.side_id == f.side:
			target = StringName(f.server.slots[opposite][0])
		else: move = &"water_gun" if id == &"b0" or id == &"a0" else &"quick_attack"
		if id == f.actor.instance_id and swap:
			move = &"ally_switch"
			target = id
		result.append(BattleAction.new(f.state.turn + 1, id, move, target, BattleAction.MOVE, owner.side_id))
	return result


func _position_case(side: StringName, position: int, seed_value: int) -> void:
	var f := _double_fixture(side, position, seed_value)
	var before: Dictionary = f.server.snapshot()
	var label := "%s/%d/%d" % [side, position, seed_value]
	var packet := _commands(f)
	var packet_before := []
	for action: BattleAction in packet: packet_before.append(action.to_dict())
	var replay = Doubles.from_snapshot(JSON.parse_string(JSON.stringify(before)), catalog)
	check(label + " four-actor snapshot round trip", replay != null and replay.snapshot() == before and f.state.active_ids.size() == 4)
	var reversed := packet.duplicate()
	reversed.reverse()
	var events: Array[BattleEvent] = f.server.submit_turn(packet)
	var replayed: Array[BattleEvent] = replay.submit_turn(reversed)
	check(label + " packet permutation deterministic", _rows(events) == _rows(replayed) and f.server.snapshot() == replay.snapshot())
	var after_packet := []
	for action: BattleAction in packet: after_packet.append(action.to_dict())
	check(label + " caller packet immutable", packet_before == after_packet)
	check(label + " swap at priority +2", events[0].kind == BattleEvent.ACTION_USED and events[0].move_id == &"ally_switch" and _count(events, BattleEvent.ALLY_POSITIONS_SWAPPED) == 1)
	check(label + " positions swapped not reserves", int(f.server.position_of(f.actor.instance_id).slot) == 1 - position and int(f.server.position_of(f.ally.instance_id).slot) == position and _count(events, BattleEvent.SWITCHED) == 0)
	check(label + " one PP and one end turn", f.actor.move_slot(&"ally_switch").current_pp == 14 and _count(events, BattleEvent.ACTION_USED) == 4 and _count(events, BattleEvent.TURN_ENDED) == 1 and f.state.turn == 1)
	check(label + " incoming occupant takes both targeted hits", f.actor.current_hp == 2000 and f.ally.current_hp < 2000 and _count(events, BattleEvent.POSITION_TARGET_RESOLVED) == 2)
	for event: BattleEvent in events:
		if event.kind == BattleEvent.DAMAGE_APPLIED and f.state.side_for_creature(event.actor_id).side_id != side:
			check(label + " actual damage recipient", event.target_id == f.ally.instance_id)
	check(label + " party identity untouched", f.state.sides[0].party_ids == ([&"a0", &"a1"] as Array[StringName]) and f.state.sides[1].party_ids == ([&"b0", &"b1"] as Array[StringName]))
	var restored = Doubles.from_snapshot(JSON.parse_string(JSON.stringify(f.server.snapshot())), catalog)
	check(label + " swapped snapshot restores positions PP and RNG", restored != null and restored.snapshot() == f.server.snapshot())
	samples.append({"side": String(side), "starting_position": position, "seed": seed_value, "events": _rows(events)})


func _repeat_cases() -> void:
	var seen_success := false
	var seen_failure := false
	for seed_value in range(1, 25):
		var f := _double_fixture(&"side_a", 0, seed_value)
		for id: StringName in f.state.participant_ids:
			f.state.creature(id).stats.max_hp = 100000
			f.state.creature(id).current_hp = 100000
		for attempt in 8:
			var snapshot: Dictionary = f.server.snapshot()
			var entry: Dictionary = snapshot.ally_switch_stall.get("a0", {})
			var counter := int(entry.get("counter", 1)) if int(entry.get("last_turn", -2)) == f.state.turn else 1
			var expected := counter == 1 or SeededRandomSource.new(f.state.rng_state).next_index(counter) == 0
			var restored = Doubles.from_snapshot(JSON.parse_string(JSON.stringify(snapshot)), catalog)
			var commands := _commands(f)
			var events: Array[BattleEvent] = f.server.submit_turn(commands)
			var repeated: Array[BattleEvent] = restored.submit_turn(commands)
			check("repeat restored deterministic", _rows(events) == _rows(repeated) and f.server.snapshot() == restored.snapshot())
			check("repeat exact denominator", (_count(events, BattleEvent.ALLY_POSITIONS_SWAPPED) == 1) == expected and f.actor.move_slot(&"ally_switch").current_pp == 14 - attempt)
			seen_success = seen_success or (expected and counter > 1)
			seen_failure = seen_failure or not expected
		var gap: Array[BattleEvent] = f.server.submit_turn(_commands(f, false))
		var fresh: Array[BattleEvent] = f.server.submit_turn(_commands(f))
		check("one intervening turn expires streak", _count(fresh, BattleEvent.ALLY_POSITIONS_SWAPPED) == 1 and _count(gap, BattleEvent.ALLY_POSITIONS_SWAPPED) == 0)
	check("repeat matrix has success and failure", seen_success and seen_failure)


func _edges() -> void:
	for failure in ["count", "duplicate", "side", "target", "self", "move", "switch", "turn", "pp"]:
		var f := _double_fixture()
		var packet := _commands(f)
		match failure:
			"count": packet.pop_back()
			"duplicate": packet[1] = packet[0]
			"side": packet[0].side_id = &"side_b"
			"target": packet[2].target_id = &"b1"
			"self": packet[0].target_id = &"a1"
			"move": packet[0].move_id = &"surf"
			"switch": packet[0].action_type = BattleAction.SWITCH
			"turn": packet[0].turn = 2
			"pp": f.actor.move_slot(&"ally_switch").current_pp = 0
		var snapshot: Dictionary = f.server.snapshot()
		var events: Array[BattleEvent] = f.server.submit_turn(packet)
		check("reject atomic " + failure, _count(events, BattleEvent.ACTION_REJECTED) == 1 and f.server.snapshot() == snapshot)
	for unsupported in ["ability", "item", "weather", "substitute"]:
		var f := _double_fixture()
		match unsupported:
			"ability": f.actor.ability_id = &"intimidate"
			"item": f.actor.held_item_id = &"leftovers"
			"weather": f.state.weather_rules_enabled = true
			"substitute": f.actor.status_state.add_volatile(&"substitute", {"hp": 20})
		var snapshot: Dictionary = f.server.snapshot()
		check("unsupported scope fails closed " + unsupported, _count(f.server.submit_turn(_commands(f)), BattleEvent.ACTION_REJECTED) == 1 and f.server.snapshot() == snapshot)
	var f := _double_fixture()
	f.actor.status_state.add_volatile(&"flinch", {})
	var blocked: Array[BattleEvent] = f.server.submit_turn(_commands(f))
	check("flinch prevents swap without PP", _count(blocked, BattleEvent.ALLY_POSITIONS_SWAPPED) == 0 and f.actor.move_slot(&"ally_switch").current_pp == 15)
	f = _double_fixture()
	f.ally.current_hp = 0
	var alone: Array[BattleEvent] = f.server.submit_turn(_commands(f))
	check("no living ally fails without position change", _count(alone, BattleEvent.ALLY_SWITCH_FAILED) == 1 and f.server.slots.side_a == ["a0", "a1"] and f.actor.move_slot(&"ally_switch").current_pp == 14)
	f = _double_fixture()
	f.ally.current_hp = 1
	f.state.creature(&"b0").stats.speed = 10000
	var lethal := _commands(f)
	lethal[2].move_id = &"extreme_speed"
	lethal[2].target_id = &"a1"
	lethal[3].target_id = &"a1"
	var knocked: Array[BattleEvent] = f.server.submit_turn(lethal)
	check("faster equal-priority hit removes ally before swap", f.ally.is_knocked_out() and _count(knocked, BattleEvent.ALLY_POSITIONS_SWAPPED) == 0 and _count(knocked, BattleEvent.ALLY_SWITCH_FAILED) == 1)
	check("fainted target position retargets surviving enemy", _count(knocked, BattleEvent.POSITION_TARGET_RESOLVED) >= 1 and f.actor.current_hp < 2000)
	f = _double_fixture()
	f.actor.status_state.persistent_id = &"poison"
	f.actor.stat_stages.change(StatStages.ATTACK, 2)
	var status: Array[BattleEvent] = f.server.submit_turn(_commands(f))
	check("swap retains identity status and stages", f.actor.status_state.persistent_id == &"poison" and f.actor.stat_stages.get_stage(StatStages.ATTACK) == 2 and _count(status, BattleEvent.STATUS_DAMAGE) == 1)
	for field in ["format", "slots", "stall"]:
		var snapshot: Dictionary = f.server.snapshot()
		if field == "format": snapshot.format = "singles"
		if field == "slots": snapshot.slots.side_a = ["a0", "a0"]
		if field == "stall": snapshot.ally_switch_stall.a0.counter = 2
		check("invalid restored context rejected " + field, Doubles.from_snapshot(snapshot, catalog) == null)
	var legacy := _fixture(&"ally_switch")
	var old := _reaction(legacy)
	check("legacy singles not promoted to doubles", legacy.state.active_ids.size() == 2 and _count(old, BattleEvent.ALLY_POSITIONS_SWAPPED) == 0)

	f = _double_fixture()
	var both := _commands(f)
	both[1].move_id = &"ally_switch"
	both[1].target_id = &"a1"
	var twice: Array[BattleEvent] = f.server.submit_turn(both)
	check("both allied users swap independently and return", _count(twice, BattleEvent.ALLY_POSITIONS_SWAPPED) == 2 and f.server.slots.side_a == ["a0", "a1"] and f.actor.move_slot(&"ally_switch").current_pp == 14 and f.ally.move_slot(&"ally_switch").current_pp == 14)
	f = _double_fixture()
	both = _commands(f)
	both[2].move_id = &"ally_switch"
	both[2].target_id = &"b0"
	var both_sides: Array[BattleEvent] = f.server.submit_turn(both)
	check("both sides swap with independently bound targets", _count(both_sides, BattleEvent.ALLY_POSITIONS_SWAPPED) == 2 and _count(both_sides, BattleEvent.POSITION_TARGET_RESOLVED) == 2)
	for seed_value in range(1, 25):
		f = _double_fixture(&"side_a", 0, seed_value)
		for id: StringName in f.state.participant_ids: f.state.creature(id).stats.speed = 100
		var packet := _commands(f, false)
		for action: BattleAction in packet: action.move_id = &"tackle"
		var restored = Doubles.from_snapshot(f.server.snapshot(), catalog)
		var shuffled := packet.duplicate()
		shuffled.reverse()
		var tied: Array[BattleEvent] = f.server.submit_turn(packet)
		var replayed: Array[BattleEvent] = restored.submit_turn(shuffled)
		check("four-way tie permutation/RNG stable", _rows(tied) == _rows(replayed) and f.server.snapshot() == restored.snapshot())
	f = _double_fixture()
	f.state.creature(&"b0").current_hp = 1
	f.state.creature(&"b1").current_hp = 1
	var terminal := _commands(f, false)
	for index in 2:
		terminal[index].move_id = &"extreme_speed"
		terminal[index].target_id = &"b0" if index == 0 else &"b1"
	var ended: Array[BattleEvent] = f.server.submit_turn(terminal)
	check("last active enemies end once without their attacks", f.state.phase == BattleState.FINISHED and _count(ended, BattleEvent.BATTLE_ENDED) == 1 and _count(ended, BattleEvent.ACTION_USED) == 2 and _count(ended, BattleEvent.TURN_ENDED) == 0)
	var snapshot: Dictionary = f.server.snapshot()
	check("finished snapshot and rejection stable", Doubles.from_snapshot(JSON.parse_string(JSON.stringify(snapshot)), catalog) != null and _count(f.server.submit_turn(terminal), BattleEvent.ACTION_REJECTED) == 1 and f.server.snapshot() == snapshot)
	f = _double_fixture()
	var single := AuthoritativeBattleServer.new(f.state, catalog)
	snapshot = single.snapshot()
	check("singles API rejects accidental four-actor turn", _count(single.submit_turn(_commands(f)), BattleEvent.ACTION_REJECTED) == 1 and snapshot == single.snapshot())
	f = _double_fixture()
	f.server.submit_turn(_commands(f))
	snapshot = f.server.snapshot()
	snapshot.ally_switch_stall.a0.counter = 729
	var chosen_seed := -1
	for value in range(1, 10000):
		if SeededRandomSource.new(value).next_index(729) == 0:
			chosen_seed = value
			break
	check("capped chance fixture available", chosen_seed > 0)
	snapshot.battle.rng_state = chosen_seed
	f.server = Doubles.from_snapshot(snapshot, catalog)
	var capped: Array[BattleEvent] = f.server.submit_turn(_commands(f))
	check("consecutive denominator caps at 729", _count(capped, BattleEvent.ALLY_POSITIONS_SWAPPED) == 1 and int(f.server.snapshot().ally_switch_stall.a0.counter) == 729)


func _live_cases() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	for n in 4: await process_frame
	var party_before: Dictionary = scene._session.player.party.to_dict().duplicate(true)
	check("F12 opens existing field overlay", scene.open_doubles_demo())
	var ui: Control = scene._doubles_demo
	ui.set_process(false)
	check("F12 movement locked and original source pinned", not scene.player.movement_enabled and ui.available)
	for side: StringName in [&"side_a", &"side_b"]:
		for position in 2:
			ui.reset_scenario()
			var f := _double_fixture(side, position, 107)
			ui.server = f.server
			ui.show_projection(Plan.projection(ui.server.snapshot()))
			for id: String in ui._choices:
				ui._choices[id].move.select(0 if id == String(f.actor.instance_id) else 1)
				ui._choices[id].target.select(position if f.state.side_for_creature(StringName(id)).side_id != side else 0)
			ui._refresh_controls()
			var label := "%s_%d" % [side, position]
			await _capture(label + "_before")
			var events: Array[BattleEvent] = ui.submit_selected_turn()
			check("F12 four actions and real swap", _count(events, BattleEvent.ACTION_USED) == 4 and _count(events, BattleEvent.ALLY_POSITIONS_SWAPPED) == 1)
			var final: Dictionary = ui.server.snapshot()
			check("F12 locks inputs during replay", ui._submit.disabled and ui._choices.a0.move.disabled)
			var saw_swap := false
			var hit := false
			var steps := 0
			while ui._index >= 0 and steps < 60:
				var step: Dictionary = ui._sequence[ui._index]
				var kind := String(step.event.kind)
				if kind == String(BattleEvent.ALLY_POSITIONS_SWAPPED):
					saw_swap = true
					check("swap projection never alters HP", step.before.units[String(f.actor.instance_id)].hp == step.after.units[String(f.actor.instance_id)].hp and step.before.units[String(f.ally.instance_id)].hp == step.after.units[String(f.ally.instance_id)].hp)
					ui.advance(float(step.duration) * 0.28)
					await _capture(label + "_swap")
				if kind == String(BattleEvent.DAMAGE_APPLIED) and String(step.event.target_id) == String(f.ally.instance_id) and not hit:
					hit = true
					ui.advance(float(step.duration) * 0.5)
					await _capture(label + "_redirected_hit")
				ui.advance(maxf(0, float(ui._sequence[ui._index].duration) - float(ui._elapsed)) + 0.000001)
				steps += 1
			check("F12 bounded replay and confirmed redirected hit", ui._index == -1 and saw_swap and hit)
			check("F12 pure projection preserves HP PP RNG", final == ui.server.snapshot())
			check("F12 final positions and HP match server", ui.arena.step.after == Plan.projection(final))
			await _capture(label + "_after")
			check("F12 controls restored", not ui._submit.disabled and not ui._choices.a0.move.disabled)
	ui.reset_scenario()
	ui.server.state.creature(&"b0").current_hp = 1
	ui._choices.a0.move.select(4)
	ui._choices.a1.move.select(1)
	ui._choices.b0.move.select(1)
	ui._choices.b1.move.select(1)
	ui.submit_selected_turn()
	while ui._index >= 0: ui.advance(10.0)
	check("F12 disables fainted recipient and selects live position", ui._choices.a0.target.is_item_disabled(0) and ui._choices.a0.target.selected == 1 and ui._choices.b0.move.disabled)
	var following: Array[BattleEvent] = ui.submit_selected_turn()
	while ui._index >= 0: ui.advance(10.0)
	check("F12 submits three living actions after one KO", _count(following, BattleEvent.ACTION_REJECTED) == 0 and _count(following, BattleEvent.ACTION_USED) == 3)
	check("main party untouched by F12", party_before == scene._session.player.party.to_dict())
	scene._close_doubles_demo()
	check("closing resumes map movement", not ui.visible and scene.player.movement_enabled)
	check("reopening starts fresh doubles encounter", scene.open_doubles_demo() and ui.server.state.turn == 0)
	scene._close_doubles_demo()
	scene.queue_free()
	await process_frame
	if gpu: check("sixteen GPU captures completed", captures.size() == 16)
	_live_complete = true


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame
	RenderingServer.force_draw(false)
	var path := ALLY_OUTPUT + label + ".png"
	check("GPU capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})


func _source_hashes() -> Dictionary:
	var result := {}
	for path: String in ["modules/battle/server/doubles_position_battle.gd", "modules/battle/server/authoritative_battle_server.gd", "modules/battle/domain/turn_resolver.gd", "modules/battle/domain/battle_event.gd", "tests/battle/ally_switch_pilot_test_runner.gd", "scenes/visual/field_demo.gd", "scenes/visual/doubles_position_demo.gd", "scenes/visual/doubles_timeline_plan.gd", "scenes/visual/doubles_battle_art.gd", "tools/visual/build_ally_switch_pilot.py", "data/raw/pokemon_api.json", "data/normalized/pokemon_api.json", ".godot/move_batch_catalog/index.json", "scenes/visual/community_move_preview.gd"]:
		result[path] = FileAccess.get_sha256("res://" + path)
	return result
