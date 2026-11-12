extends "res://tests/gameplay/item_automation_v28.gd"

# W01 CAMP003 Quick Claw native RNG with matching 1..12 historical seeds
# and positive-priority controls. Does not replace full historical runner.
var rng_witnessed: int = 0
var rng_not_activated: int = 0
var rows_ok: int = 0
var total_rows: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_claw")
	create_timer(1600.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP003 Quick Claw timeout")
			quit(2))

func _first_move_and_activation(session: RefCounted) -> Dictionary:
	var messages: Array = session._checkpoint.get("snapshot", {}).get("native", {}).get("log", [])
	var first := ""
	var claw := false
	for entry: String in messages:
		if entry.contains("item: Quick Claw"):
			claw = true
		if first == "" and entry.begins_with("|move|"):
			first = "own" if entry.begins_with("|move|p1a:") else "foe"
	return {"first": first, "claw": claw}

func _case(seed: int, mode: String, priority: bool) -> Dictionary:
	current_case = "C003_CLAW_" + ("priority_" if priority else "rng_") + str(seed) + "_" + mode
	var prior_errors: int = errors.size()
	automation = {"actor_species": "mew", "level": 100, "format": "gen9calvounifiedv1",
		"seed": [seed, 2, 3, 4], "physical_move": "quick_attack" if priority else "tackle",
		"special_move": "water_gun", "speed_target": "gengar", "damage_target": "gengar"}
	var prepared: Dictionary = _fixture({"id": "quick_claw"}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	prepared.foe = _mon(&"gengar", 100, &"foe", ["tackle"])
	var before_owner: Dictionary = _owner_data(owner)
	check("two physical Quick Claws preserved", _units(owner, &"quick_claw") == 2)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check("native Quick Claw opens", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	check("native exact holder", session.battle_state().creature(&"own").held_item_id ==
		(&"quick_claw" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id ==
		(&"quick_claw" if mode == "reserve" else &""))
	var move: Dictionary = await session.submit("move 1", session.revision)
	check("native attack accepted", move.get("accepted", false))
	var evidence := _first_move_and_activation(session)
	check("native first actor visible", evidence.first in ["own", "foe"])
	check("Quick Claw never consumed in live battle",
		not session.battle_state().creature(&"own").held_item_consumed
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("no premature collection settlement", _owner_data(owner) == before_owner)
	var prior_snapshot: Dictionary = session.snapshot()
	var restored: Dictionary = await _restore_probe(session, owner,
		"c003_claw_" + ("priority_" if priority else "rng_") + str(seed) + "_" + mode,
		"Quick Claw SaveV2 " + mode)
	if not restored.get("valid", false):
		return {"valid": false}
	session = restored.session
	check("native checkpoint equal after SaveV2", session.snapshot() == prior_snapshot)
	check("owner equal after SaveV2", _owner_data(restored.owner) == before_owner)
	await session.close()
	return {"valid": errors.size() == prior_errors, "first": evidence.first,
		"claw": evidence.claw, "mode": mode}

func _run_claw() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_quick_claw"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional overlay", Variants.apply(catalogs))
	for seed: int in range(1, 13):
		var lanes: Dictionary = {}
		for mode: String in ["active", "none", "reserve"]:
			lanes[mode] = await _case(seed, mode, false)
			total_rows += 1
			if lanes[mode].get("valid", false):
				rows_ok += 1
		check("three real RNG modes valid for seed " + str(seed),
			lanes.active.get("valid", false) and lanes.none.get("valid", false)
			and lanes.reserve.get("valid", false))
		if lanes.active.get("valid", false) and lanes.none.get("valid", false) and lanes.reserve.get("valid", false):
			check("Gengar acts first in both RNG controls " + str(seed),
				lanes.none.first == "foe" and lanes.reserve.first == "foe")
			check("priority changes iff native Quick Claw activation " + str(seed),
				lanes.active.first == ("own" if lanes.active.claw else "foe")
				and not lanes.none.claw and not lanes.reserve.claw)
			if lanes.active.claw:
				rng_witnessed += 1
			else:
				rng_not_activated += 1
	var priority_lanes: Dictionary = {}
	for mode: String in ["active", "none", "reserve"]:
		priority_lanes[mode] = await _case(19, mode, true)
		total_rows += 1
		if priority_lanes[mode].get("valid", false):
			rows_ok += 1
	check("priority-control move precedes foe with or without held Quick Claw",
		priority_lanes.active.get("valid", false) and priority_lanes.none.get("valid", false)
		and priority_lanes.reserve.get("valid", false)
		and priority_lanes.active.first == "own"
		and priority_lanes.none.first == "own"
		and priority_lanes.reserve.first == "own")
	check("native Quick Claw actually activates on historical RNG seeds", rng_witnessed > 0)
	check("native Quick Claw also has nonactivation RNG witnesses", rng_not_activated > 0)
	check("39 native cases with SaveV2 passed", total_rows == 39 and rows_ok == 39)
	done = true
	if errors.is_empty() and rows_ok == 39:
		print("W01_V4_C003_CLAW PASS rows=39 positive=", rng_witnessed,
			" negative=", rng_not_activated, " checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_CLAW FAIL rows=", rows_ok, " positive=", rng_witnessed,
			" negative=", rng_not_activated, " checks=", checks, " errors=", errors.size())
		quit(1)
