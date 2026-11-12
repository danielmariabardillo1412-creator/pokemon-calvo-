extends "res://tests/gameplay/item_automation_v28.gd"

# CAMP003 Flame Orb: exact historical burn/non-burn contexts, live native
# battle, 3 ownership modes and independent SaveV2 checkpoint restore.
const SCENARIOS := [
	{"id": "end_turn_burn_19", "species": "mew", "attack": "reflect", "seed": 19, "fire_immune": false},
	{"id": "end_turn_burn_23", "species": "mew", "attack": "reflect", "seed": 23, "fire_immune": false},
	{"id": "fire_type_immune_19", "species": "charizard", "attack": "scratch", "seed": 19, "fire_immune": true}
]
var orb_passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_flame_orb")
	create_timer(750.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP003 Flame Orb timeout")
			quit(2))

func _orb_lane(scenario: Dictionary, mode: String) -> Dictionary:
	current_case = "W01_C003_FLAME_" + String(scenario.id) + "_" + mode
	var start_errors: int = errors.size()
	automation = {"actor_species": String(scenario.species), "level": 100,
		"format": "gen9calvounifiedv1", "seed": [int(scenario.seed), 2, 3, 4],
		"physical_move": String(scenario.attack), "special_move": "water_gun",
		"speed_target": "mew", "damage_target": "mew"}
	var f: Dictionary = _fixture({"id": "flame_orb"}, "physical_damage", mode)
	var owner: PlayerCollection = f.owner
	var own: CreatureInstance = owner.owned_creature(&"own")
	_set_effect_moves(own, String(scenario.attack))
	f.foe = _mon(&"mew", 100, &"foe", ["amnesia"])
	var before_owner: Dictionary = _owner_data(owner)
	check("two physical Flame Orb copies" + current_case, _units(owner, &"flame_orb") == 2)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, f.foe, automation.seed)
	check("real native Flame Orb battle starts" + current_case, opened)
	if not opened:
		await session.close()
		return {"valid": false}
	check("native exact held item owner " + current_case,
		session.battle_state().creature(&"own").held_item_id ==
			(&"flame_orb" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"flame_orb" if mode == "reserve" else &""))
	var command: Dictionary = await session.submit("move 1", session.revision)
	check("legal native first turn accepted " + current_case, command.get("accepted", false))
	if not command.get("accepted", false):
		await session.close()
		return {"valid": false}
	var active: CreatureInstance = session.battle_state().creature(&"own")
	var reserve: CreatureInstance = session.battle_state().creature(&"reserve")
	var status: String = String(active.status_state.persistent_id)
	var reserve_status: String = String(reserve.status_state.persistent_id)
	check("Flame Orb end-turn status only correct active holder " + current_case,
		status == ("burn" if mode == "active" and not bool(scenario.fire_immune) else "")
		and reserve_status == "")
	check("Flame Orb stays physical, never consumed " + current_case,
		not active.held_item_consumed and not reserve.held_item_consumed)
	check("no premature item/status publication to owner " + current_case,
		_owner_data(owner) == before_owner)
	var pre_restore: Dictionary = session.snapshot()
	var restored: Dictionary = await _restore_probe(session, owner,
		"c003_flame_" + String(scenario.id) + "_" + mode,
		"Flame Orb SaveV2 " + mode)
	if not restored.get("valid", false):
		return {"valid": false}
	session = restored.session
	check("real native battle snapshot stable after SaveV2 " + current_case,
		session.snapshot() == pre_restore)
	check("restored owner remains exact " + current_case,
		_owner_data(restored.owner) == before_owner)
	check("native burn and item consumption preserved across SaveV2 " + current_case,
		String(session.battle_state().creature(&"own").status_state.persistent_id) == status
		and not session.battle_state().creature(&"own").held_item_consumed)
	await session.close()
	return {"valid": errors.size() == start_errors,
		"status": status, "reserve_status": reserve_status, "mode": mode}

func _run_flame_orb() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_flame_orb"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional variants available", Variants.apply(catalogs))
	for scenario: Dictionary in SCENARIOS:
		var lanes: Dictionary = {}
		for mode: String in ["active", "none", "reserve"]:
			lanes[mode] = await _orb_lane(scenario, mode)
			if lanes[mode].get("valid", false):
				orb_passed += 1
		check("three valid native modes " + String(scenario.id),
			lanes.active.get("valid", false)
			and lanes.none.get("valid", false)
			and lanes.reserve.get("valid", false))
		if lanes.active.get("valid", false) and lanes.none.get("valid", false) and lanes.reserve.get("valid", false):
			check("only active non-Fire carrier burns " + String(scenario.id),
				lanes.active.status == ("" if bool(scenario.fire_immune) else "burn")
				and lanes.none.status == "" and lanes.reserve.status == "")
	check("nine CAMP003 Flame Orb SaveV2 lanes", orb_passed == 9)
	done = true
	if errors.is_empty() and orb_passed == 9:
		print("W01_V4_C003_FLAME_ORB PASS modes=9 checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_FLAME_ORB FAIL modes=", orb_passed,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
