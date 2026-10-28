extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/doubles_backend.gd")
const Singles = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Adapter = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const OUT := "res://.godot/native_doubles_checks/"
const IDS := ["after_you", "ally_switch", "aromatic_mist", "coaching", "dragon_cheer", "follow_me", "helping_hand", "hold_hands", "quash", "rage_powder", "spotlight"]
var catalog: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var active: RefCounted
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label); printerr(active.last_error if active != null else "")


func mon(id: String, moves: Array, species: String = "mew", level: int = 50) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(catalog.species(StringName(species)), level, catalog, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""; return c


func _run() -> void:
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	if "--export" in OS.get_cmdline_user_args():
		var rows := {"ally": mon("ally", ["tackle", "protect"], "druddigon").to_dict(), "foe0": mon("foe0", ["reflect", "tackle"]).to_dict(), "foe1": mon("foe1", ["reflect", "tackle"]).to_dict()}
		for id: String in IDS: rows[id] = mon("actor", [id, "protect", "tackle"], "mew", 60).to_dict()
		var f := FileAccess.open(OUT + "prototypes.json", FileAccess.WRITE); f.store_string(JSON.stringify(rows)); f.close(); print("DOUBLES_PROTOTYPES ", rows.size()); quit(); return
	create_timer(180).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			check("watchdog", false); _finish())
	var cases: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT + "cases.json"))
	var projected: Array = []
	active = Backend.new(catalog)
	for row: Dictionary in cases:
		active._origin = row.origin
		var before: BattleState = active._mirror(row.before)
		var after: BattleState = active._mirror(row.after)
		var result := Adapter.project(row.before, row.after, active._moves, active._policy, active._species)
		check("mirror and protocol " + row.case_id + " " + str(result.unknown), before != null and after != null and result.ok)
		if after != null:
			check("four native active identities " + row.case_id, after.active_ids.size() == 4)
			for side: Dictionary in row.after.roster:
				for p: Dictionary in side.pokemon:
					var c := after.creature(StringName(p.instance_id))
					check("HP/PP exact " + row.case_id + "/" + p.instance_id, c.current_hp == int(p.hp) and c.moveset[0].current_pp == int(p.moves[0].pp))
		projected.append({"id": row.id, "case_id": row.case_id, "ok": result.ok, "unknown": result.unknown})
	var f := FileAccess.open(OUT + "projection.json", FileAccess.WRITE); f.store_string(JSON.stringify(projected)); f.close()
	for row: Dictionary in cases:
		var a: Array[CreatureInstance] = []; var b: Array[CreatureInstance] = []
		for p: Dictionary in row.origin.p1: a.append(CreatureInstance.from_dict(p))
		for p: Dictionary in row.origin.p2: b.append(CreatureInstance.from_dict(p))
		active = Backend.new(catalog)
		check("live doubles opens " + row.case_id, await active.open(self, a, b, [int(row.seed), 2, 3, 4]))
		var before: Dictionary = active.snapshot()
		var result: Dictionary = await active.submit_pair(row.choices, active.revision)
		check("live native double action " + row.case_id, result.accepted and active._checkpoint.state_hash == row.after.state_hash)
		check("no mutation of source collection " + row.case_id, a[0].current_hp == int(row.origin.p1[0].current_hp))
		if row.id == "ally_switch":
			check("swap semantic event " + row.case_id, result.events.any(func(e): return e.kind == BattleEvent.ALLY_POSITIONS_SWAPPED))
		if row.seed == 1 and row.side == "p1":
			var saved: Dictionary = active.snapshot(); var restored := Backend.new(catalog)
			check("doubles checkpoint restores " + row.id, await restored.restore_saved(self, saved) and restored.snapshot() == saved and restored.active_ids("p1") == active.active_ids("p1"))
			await restored.close()
			var singles := Singles.new(catalog)
			check("singles cannot load doubles checkpoint " + row.id, not await singles.restore_saved(self, saved) and singles._client == null)
			var committed: Dictionary = active.snapshot()
			check("stale turn does not advance either side " + row.id, not (await active.submit_pair(row.choices, active.revision - 1)).accepted and active.snapshot() == committed)
		await active.close()
	await _invalid_and_replacements()
	await _double_replacements()
	_finish()


func _invalid_and_replacements() -> void:
	active = Backend.new(catalog)
	var a := [mon("own0", ["tackle"]), mon("own1", ["tackle"]), mon("reserve", ["tackle"])] as Array[CreatureInstance]
	var b := [mon("foe0", ["tackle"]), mon("foe1", ["tackle"])] as Array[CreatureInstance]
	a[0].current_hp = 1
	check("reserve fixture opens", await active.open(self, a, b))
	var saved: Dictionary = active.snapshot()
	for invalid: Dictionary in [{"p1": "move 1 1, move 99 1", "p2": "move 1 1, move 1 1"}, {"p1": "move 1 -1, move 1 1", "p2": "move 1 1, move 1 1"}]:
		check("invalid partial choice rolls back both sides", not (await active.submit_pair(invalid, active.revision)).accepted and active.snapshot() == saved)
	check("no singles command shortcut", not (await active.submit("move 1", active.revision)).accepted and active.snapshot() == saved)
	check("real KO requests replacement", (await active.submit_pair({"p1": "move 1 1, move 1 1", "p2": "move 1 1, move 1 1"}, active.revision)).accepted and active.phase() == "replacement")
	saved = active.snapshot()
	var restored := Backend.new(catalog)
	check("replacement request survives reload", await restored.restore_saved(self, saved) and restored.phase() == "replacement")
	await restored.close()
	check("only required side chooses replacement", (await active.submit_pair({"p1": "switch 3, pass"}, active.revision)).accepted and active.active_ids("p1")[0] == "reserve")
	await active.close()


func _double_replacements() -> void:
	for weak_side: String in ["p1", "p2"]:
		active = Backend.new(catalog)
		var weak := [mon("weak0", ["tackle"], "mew", 5), mon("weak1", ["tackle"], "mew", 5), mon("reserve0", ["tackle"]), mon("reserve1", ["tackle"])] as Array[CreatureInstance]
		weak[0].current_hp = 1; weak[1].current_hp = 1
		var strong := [mon("strong0", ["tackle"]), mon("strong1", ["tackle"])] as Array[CreatureInstance]
		check("both KO fixture opens " + weak_side, await active.open(self, weak if weak_side == "p1" else strong, strong if weak_side == "p1" else weak))
		check("two actual KOs " + weak_side, (await active.submit_pair({"p1": "move 1 1, move 1 2", "p2": "move 1 1, move 1 2"}, active.revision)).accepted and active.phase() == "replacement" and active.request(weak_side).get("forceSwitch") == [true, true])
		var saved: Dictionary = active.snapshot()
		check("duplicate reserve rolls back " + weak_side, not (await active.submit_pair({weak_side: "switch 3, switch 3"}, active.revision)).accepted and active.snapshot() == saved)
		check("both distinct reserves enter " + weak_side, (await active.submit_pair({weak_side: "switch 3, switch 4"}, active.revision)).accepted and active.active_ids(weak_side) == ["reserve0", "reserve1"])
		check("target API has companion and opponents " + weak_side, active.targets(weak_side, 0, "adjacentAlly").size() == 1 and int(active.targets(weak_side, 0, "adjacentAlly")[0].location) == -2 and active.targets(weak_side, 0, "adjacentFoe").size() == 2)
		saved = active.snapshot()
		check("unknown side cannot advance " + weak_side, not (await active.submit_pair({"intruder": "move 1"}, active.revision)).accepted and active.snapshot() == saved)
		check("special profile not silently enabled " + weak_side, not (await active.submit_pair({"p1": "move 1 1 mega, move 1 1", "p2": "move 1 1, move 1 1"}, active.revision)).accepted and active.snapshot() == saved)
		await active.close()


func _finish() -> void:
	if done: return
	done = true
	var f := FileAccess.open(OUT + "gameplay.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors}, "  ")); f.close()
	print("DOUBLES_GODOT ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
