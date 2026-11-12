extends "res://tests/gameplay/item_automation_v28.gd"

# W01 CAMP003 Light Clay: historical Reflect seeds 19/23 and no-screen seed 19.
# Real native battle + owner/checkpoint disk SaveV2, active/none/reserve.
const CLAY_CASES := [
	{"id":"reflect_19", "seed":19, "move":"reflect", "screen":true},
	{"id":"reflect_23", "seed":23, "move":"reflect", "screen":true},
	{"id":"no_screen_19", "seed":19, "move":"tackle", "screen":false}
]
var lanes_passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_light_clay")
	create_timer(750.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 CAMP003 Light Clay timeout")
			quit(2))

func _screen_duration(session: RefCounted) -> int:
	var snapshot: Dictionary = session._checkpoint.get("snapshot", {}).get("native", {})
	var sides: Array = snapshot.get("sides", [])
	if sides.is_empty():
		return -1
	var conditions: Dictionary = sides[0].get("sideConditions", {})
	var reflect_state: Variant = conditions.get("reflect", {})
	return int(reflect_state.get("duration", 0)) if reflect_state is Dictionary else 0

func _clay_lane(spec: Dictionary, mode: String) -> Dictionary:
	current_case = "W01_C003_CLAY_" + String(spec.id) + "_" + mode
	var prior_errors: int = errors.size()
	automation = {"actor_species":"mew","level":100,"format":"gen9calvounifiedv1",
		"seed":[int(spec.seed),2,3,4],"physical_move":String(spec.move),
		"special_move":"water_gun","speed_target":"mew","damage_target":"mew"}
	var f: Dictionary = _fixture({"id":"light_clay"}, "physical_damage", mode)
	var owner: PlayerCollection = f.owner
	_set_effect_moves(owner.owned_creature(&"own"), String(spec.move))
	var foe := _mon(&"mew", 100, &"foe", ["amnesia"])
	var owner_before: Dictionary = _owner_data(owner)
	check("two physical Light Clays " + current_case, _units(owner, &"light_clay") == 2)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, automation.seed)
	check("native Light Clay session starts " + current_case, opened)
	if not opened:
		await session.close()
		return {"valid":false}
	check("native owner and reserve are exact " + current_case,
		session.battle_state().creature(&"own").held_item_id ==
			(&"light_clay" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"light_clay" if mode == "reserve" else &""))
	var action: Dictionary = await session.submit("move 1", session.revision)
	check("native first move accepted " + current_case, action.get("accepted", false))
	if not action.get("accepted", false):
		await session.close()
		return {"valid":false}
	var duration: int = _screen_duration(session)
	check("duration snapshot is readable " + current_case, duration >= 0)
	check("Light Clay not consumed " + current_case,
		not session.battle_state().creature(&"own").held_item_consumed
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("owner not prematurely mutated " + current_case, _owner_data(owner) == owner_before)
	var snapshot: Dictionary = session.snapshot()
	var reloaded: Dictionary = await _restore_probe(session, owner,
		"c003_clay_" + String(spec.id) + "_" + mode,
		"Light Clay SaveV2 " + mode)
	if not reloaded.get("valid", false):
		return {"valid":false}
	session = reloaded.session
	check("exact battle checkpoint after SaveV2 " + current_case, session.snapshot() == snapshot)
	check("exact collection after SaveV2 " + current_case,
		_owner_data(reloaded.owner) == owner_before)
	check("Light Clay effect duration persists in native checkpoint " + current_case,
		_screen_duration(session) == duration)
	await session.close()
	return {"valid":errors.size() == prior_errors, "duration":duration, "mode":mode}

func _run_light_clay() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_light_clay"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional overlay", Variants.apply(catalogs))
	for spec: Dictionary in CLAY_CASES:
		var lanes: Dictionary = {}
		for mode: String in ["active","none","reserve"]:
			lanes[mode] = await _clay_lane(spec, mode)
			if lanes[mode].get("valid", false):
				lanes_passed += 1
		check("all three native lanes valid " + String(spec.id),
			lanes.active.get("valid", false) and lanes.none.get("valid", false)
			and lanes.reserve.get("valid", false))
		if lanes.active.get("valid", false) and lanes.none.get("valid", false) and lanes.reserve.get("valid", false):
			if bool(spec.screen):
				check("Reflejo gains exactly three extra turns only on active Light Clay holder " + String(spec.id),
					lanes.none.duration > 0
					and lanes.active.duration == lanes.none.duration + 3
					and lanes.none.duration == lanes.reserve.duration)
			else:
				check("non-screen move must never create Reflect " + String(spec.id),
					lanes.active.duration == 0
					and lanes.none.duration == 0
					and lanes.reserve.duration == 0)
	check("nine historical Light Clay SaveV2 lanes", lanes_passed == 9)
	done = true
	if errors.is_empty() and lanes_passed == 9:
		print("W01_V4_C003_LIGHT_CLAY PASS modes=9 checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_LIGHT_CLAY FAIL modes=", lanes_passed,
			" checks=", checks, " errors=", errors.size())
		quit(1)
