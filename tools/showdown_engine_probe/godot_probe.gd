extends SceneTree

const Client = preload("res://tools/showdown_engine_probe/pipe_client.gd")
const EventProjection = preload("res://tools/showdown_engine_probe/event_projection.gd")
const Timeline = preload("res://scenes/visual/battle_timeline_plan.gd")
const DEST := "res://.godot/showdown_engine_probe/"
var checks: Array = []
var frames := 0
var presentation_result := {}
var _finished := false


func _initialize() -> void:
	process_frame.connect(func(): frames += 1)
	call_deferred("_run")


func check(label: String, valid: bool) -> void:
	checks.append({"name": label, "status": "PASS" if valid else "FAIL"})
	if not valid: push_error(label)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var node_path: String = args[0] if not args.is_empty() else "D:/Herramientas/NodeJS/node.exe"
	var client := Client.new()
	create_timer(60).timeout.connect(func():
		if not _finished:
			check("probe completes before watchdog deadline", false)
			await client.close(self)
			_finish(client))
	check("Godot creates a persistent local Node pipe", client.start(node_path))
	if client.pid < 0: quit(1); return
	var hello: Dictionary = await client.exchange(self, {"op": "hello"})
	check("pinned simulator handshake", hello.get("ok", false) and hello.get("result", {}).get("version") == "0.10.11")
	var catalog := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var rng := RandomNumberGenerator.new(); rng.seed = 37
	var rules := ProgressionRuleset.new()
	var player := CreatureFactory.create(catalog.species(&"charizard"), 50, catalog, rules, rng,
		{"instance_id": &"real_game_player", "nature_id": &"adamant", "moves": [&"flamethrower", &"protect", &"reflect", &"stealth_rock"]})
	var enemy := CreatureFactory.create(catalog.species(&"blastoise"), 50, catalog, rules, rng,
		{"instance_id": &"real_game_enemy", "nature_id": &"calm", "moves": [&"tackle"]})
	player.current_hp -= 7
	player.moveset[0].current_pp -= 2
	var original := player.to_dict().duplicate(true)
	var teams := {"p1": [player.to_dict()], "p2": [enemy.to_dict()]}
	var started: Dictionary = await client.exchange(self, {"op": "start", "id": "live_import", "seed": [1, 2, 3, 4], "teams": teams})
	check("actual CreatureFactory DTO imports without altering stats", started.get("ok", false))
	if not started.get("ok", false):
		printerr(JSON.stringify(started)); await client.close(self); _finish(client); return
	var result: Dictionary = started.result
	check("stable game instance identity retained", result.own[0].instance_id == "real_game_player")
	check("persistent HP and PP imported", int(result.own[0].hp) == player.current_hp and int(result.own[0].moves[0].pp) == player.moveset[0].current_pp)
	check("native choice request supplies moves", result.request.active[0].moves.size() == 4)
	var protected_turn: Dictionary = await client.exchange(self, {"op": "choose", "id": "live_import", "choices": {"p1": "move 2", "p2": "move 1"}})
	check("Godot commands resolve native Protect", protected_turn.get("ok", false) and int(protected_turn.result.own[0].hp) == player.current_hp)
	var saved: Dictionary = await client.exchange(self, {"op": "snapshot", "id": "live_import"})
	check("Godot receives native JSON snapshot", saved.get("ok", false) and saved.result.snapshot.has("native"))
	var file := FileAccess.open(DEST + "native_snapshot.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(saved.result.snapshot)); file.close()
	var restored_snapshot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEST + "native_snapshot.json"))
	var restored: Dictionary = await client.exchange(self, {"op": "restore", "id": "replayed", "snapshot": restored_snapshot})
	if not restored.get("ok", false): printerr("RESTORE_DIAGNOSTIC ", JSON.stringify(restored))
	check("snapshot survives Godot JSON disk round trip", restored.get("ok", false))
	var command := {"op": "choose", "id": "live_import", "choices": {"p1": "move 1", "p2": "move 1"}}
	var actual: Dictionary = await client.exchange(self, command)
	command.id = "replayed"
	var replayed: Dictionary = await client.exchange(self, command)
	if not actual.get("ok", false) or not replayed.get("ok", false): printerr("CONTINUATION_DIAGNOSTIC ", JSON.stringify([actual.get("error"), replayed.get("error")]))
	if actual.get("ok", false) and replayed.get("ok", false):
		actual.result.erase("elapsed_ms"); replayed.result.erase("elapsed_ms")
		check("same native RNG continuation and public protocol", actual.result == replayed.result)
	else: check("native continuation commands succeed", false)
	check("sandbox does not mutate live CreatureInstance", player.to_dict() == original)
	var resolved: Dictionary = await client.exchange(self, {"op": "snapshot", "id": "live_import"})
	var projected := EventProjection.project(saved.result.snapshot, resolved.result.snapshot, [&"flamethrower", &"tackle", &"protect"])
	check("sample native turn translates without unknown protocol effects", projected.unmapped.is_empty())
	var a := {"instance_id": String(player.instance_id), "side": "player", "species": String(player.species_id), "hp": player.current_hp, "max_hp": player.stats.max_hp, "visible": true}
	var b := {"instance_id": String(enemy.instance_id), "side": "enemy", "species": String(enemy.species_id), "hp": enemy.current_hp, "max_hp": enemy.stats.max_hp, "visible": true}
	var before_presentation := {"views": {"player": a, "enemy": b}, "creatures": {String(player.instance_id): a, String(enemy.instance_id): b}, "moves": {}}
	for id: StringName in [&"flamethrower", &"tackle", &"protect"]: before_presentation.moves[String(id)] = catalog.move(id).to_dict()
	var timeline := Timeline.build(projected.events, before_presentation)
	check("existing Godot timeline consumes native-engine events", not timeline.is_empty())
	var final_views: Dictionary = timeline.back().after_views if not timeline.is_empty() else {}
	check("existing timeline reaches native resolved HP", int(final_views.get("player", {}).get("hp", -1)) == int(actual.result.own[0].hp))
	check("enemy timeline HP matches native trusted state", int(final_views.get("enemy", {}).get("hp", -1)) == int(resolved.result.snapshot.native.sides[1].pokemon[0].hp))
	presentation_result = {"event_count": projected.events.size(), "unknown": projected.unmapped, "timeline_steps": timeline.size(), "source": "Showdown native turn projected to existing BattleTimelinePlan", "limits": "Damage/status subset; no complete renderer or UI integration claim"}
	var before_bad: Dictionary = await client.exchange(self, {"op": "snapshot", "id": "live_import"})
	var rejected: Dictionary = await client.exchange(self, {"op": "choose", "id": "live_import", "choices": {"p1": "switch 99", "p2": "move 1"}})
	var after_bad: Dictionary = await client.exchange(self, {"op": "snapshot", "id": "live_import"})
	check("invalid command leaves worker state unchanged", not rejected.get("ok", true) and before_bad.result.snapshot == after_bad.result.snapshot)
	var unknown: Dictionary = await client.exchange(self, {"op": "unknown_command"})
	check("unsupported command fails explicitly", not unknown.get("ok", true))
	var alive: Dictionary = await client.exchange(self, {"op": "hello"})
	check("worker continues after a rejected request", alive.get("ok", false))
	var candidates := []
	for i in 64: candidates.append({"p1": "move 2" if i % 2 == 0 else "move 3", "p2": "move 1"})
	var frames_before := frames
	var branches: Dictionary = await client.exchange(self, {"op": "branches", "id": "live_import", "candidates": candidates})
	check("one IPC request batches 64 planning forks", branches.get("ok", false) and branches.result.results.size() == 64 and branches.result.source_unchanged)
	check("Godot main loop keeps processing while worker computes", frames > frames_before)
	check("worker stderr is empty", client.stderr_text.is_empty())
	var oversized: Dictionary = await client.exchange(self, {"op": "hello", "padding": "x".repeat(256 * 1024)})
	check("oversized input rejected before transmission", not oversized.get("ok", true) and oversized.get("error") == "oversized request")
	var still_alive: Dictionary = await client.exchange(self, {"op": "hello"})
	check("size rejection leaves connection usable", still_alive.get("ok", false))
	check("owned child process exits during cleanup", await client.close(self))
	var dead := Client.new()
	check("crash test starts its own worker", dead.start(node_path))
	await dead.exchange(self, {"op": "hello"})
	OS.kill(dead.pid)
	await create_timer(0.03).timeout
	var lost: Dictionary = await dead.exchange(self, {"op": "hello"}, 500)
	check("worker death produces an explicit failure", not lost.get("ok", true))
	check("crashed worker cleanup completes", await dead.close(self))
	_finish(client)


func _finish(client: RefCounted) -> void:
	_finished = true
	var passed := 0
	for c: Dictionary in checks:
		if c.status == "PASS": passed += 1
	var timings: Array = client.timings.duplicate()
	timings.sort()
	var report := {"status": "PASS" if passed == checks.size() else "FAIL", "checks": checks,
		"godot": Engine.get_version_info().string, "transport": "OS.execute_with_pipe; nonblocking JSONL; local child process",
		"frames_processed": frames, "rpc_count": timings.size(), "rpc_ms": client.timings,
		"rpc_median_ms": timings[timings.size() / 2] if not timings.is_empty() else -1,
		"worker_stderr": client.stderr_text, "production_server_replaced": false}
	report["presentation_probe"] = presentation_result
	FileAccess.open(DEST + "godot_tests.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("SHOWDOWN_ENGINE_GODOT ", report.status, " ", passed, "/", checks.size(), " RPC=", timings.size())
	quit(0 if passed == checks.size() else 1)
