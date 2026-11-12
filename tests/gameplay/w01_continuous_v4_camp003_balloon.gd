extends "res://tests/gameplay/item_automation_v28.gd"

# CAMP003 Air Balloon scenarios extracted as a narrow standalone staging adapter.
# Real native first-turn state and SaveV2 checkpoint restore, not a fake immunity.
const BALLOON_CASES := [
	{"id": "ground_immune", "foe": "garchomp", "move": "earthquake", "seed": 19},
	{"id": "normal_pop", "foe": "snorlax", "move": "tackle", "seed": 23},
	{"id": "no_hit", "foe": "mew", "move": "amnesia", "seed": 23}
]
var observations: Array = []
var completed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_balloon")
	create_timer(600.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 CAMP003 Air Balloon timeout")
			quit(2))

func _balloon_probe(row: Dictionary, mode: String) -> Dictionary:
	current_case = "V4_BALLOON_" + String(row.id) + "_" + mode
	var error_start: int = errors.size()
	automation = {
		"actor_species": "mew", "level": 100, "format": "gen9calvounifiedv1",
		"seed": [int(row.seed), 2, 3, 4],
		"physical_move": "reflect", "special_move": "water_gun",
		"speed_target": String(row.foe), "damage_target": String(row.foe)
	}
	var prepared: Dictionary = _fixture({"id": "air_balloon"}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	_set_effect_moves(actor, "reflect")
	var foe := _mon(StringName(row.foe), 100, &"foe", [String(row.move)])
	var item := &"air_balloon"
	check("physical item exactly twice before battle", _units(owner, item) == 2)
	var owner_before: Dictionary = _owner_data(owner)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, automation.seed)
	check("real native balloon session opens", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	check("real native holder identity",
		session.battle_state().creature(&"own").held_item_id == (item if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id == (item if mode == "reserve" else &""))
	var initial_hp: int = session.battle_state().creature(&"own").current_hp
	var move: Dictionary = await session.submit("move 1", session.revision)
	check("valid native reflect turn", move.get("accepted", false))
	if not move.get("accepted", false):
		await session.close()
		return {"valid": false}
	var actor_live: CreatureInstance = session.battle_state().creature(&"own")
	var reserve_live: CreatureInstance = session.battle_state().creature(&"reserve")
	var delta: int = initial_hp - actor_live.current_hp
	var consumed: bool = actor_live.held_item_consumed
	var reserve_consumed: bool = reserve_live.held_item_consumed
	var checkpoint := session.snapshot()
	check("no owner publication prior to battle settlement", _owner_data(owner) == owner_before)
	var persisted: Dictionary = await _restore_probe(session, owner,
		"balloon_" + String(row.id) + "_" + mode, "balloon SaveV2 " + mode)
	if not persisted.get("valid", false):
		return {"valid": false}
	session = persisted.session
	owner = persisted.owner
	check("native checkpoint exact after SaveV2 restore", session.snapshot() == checkpoint)
	check("native HP/consumption exact after restore",
		initial_hp - session.battle_state().creature(&"own").current_hp == delta
		and session.battle_state().creature(&"own").held_item_consumed == consumed
		and session.battle_state().creature(&"reserve").held_item_consumed == reserve_consumed)
	check("owner persisted without early mutation", _owner_data(owner) == owner_before)
	await session.close()
	return {"valid": errors.size() == error_start, "mode": mode,
		"delta": delta, "consumed": consumed, "reserve_consumed": reserve_consumed}

func _run_balloon() -> void:
	destination = "res://.godot/parallel_items/w01_v4_balloon"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay for CAMP003", Variants.apply(catalogs))
	for row: Dictionary in BALLOON_CASES:
		var base: int = observations.size()
		for mode: String in ["active", "none", "reserve"]:
			var result: Dictionary = await _balloon_probe(row, mode)
			observations.append(result)
			if result.get("valid", false):
				completed += 1
		if observations.size() == base + 3:
			var a: Dictionary = observations[base]
			var n: Dictionary = observations[base + 1]
			var r: Dictionary = observations[base + 2]
			check("CAMP003 all three native modes " + String(row.id),
				a.get("valid", false) and n.get("valid", false) and r.get("valid", false))
			if a.get("valid", false) and n.get("valid", false) and r.get("valid", false):
				check("Air Balloon never consumed from reserve " + String(row.id),
					not r.reserve_consumed)
				check("Air Balloon reserve HP equals no-item control " + String(row.id),
					r.delta == n.delta)
				match String(row.id):
					"ground_immune":
						check("Air Balloon alone blocks real Ground hit",
							a.delta == 0 and n.delta > 0 and not a.consumed)
					"normal_pop":
						check("normal hit pops only active Balloon",
							a.delta > 0 and a.delta == n.delta and a.consumed)
					"no_hit":
						check("non-damaging turn never pops Balloon",
							a.delta == 0 and n.delta == 0 and not a.consumed)
	check("CAMP003 Air Balloon nine modes", completed == 9)
	done = true
	if errors.is_empty() and completed == 9:
		print("W01_V4_BALLOON PASS cases=3 modes=9 checks=", checks)
		quit(0)
	else:
		print("W01_V4_BALLOON FAIL modes=", completed,
			" checks=", checks, " errors=", errors.size())
		quit(1)
