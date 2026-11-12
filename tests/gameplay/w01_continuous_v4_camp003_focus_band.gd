extends "res://tests/gameplay/item_automation_v28.gd"

# Isolated CAMP003 Focus Band RNG + nonlethal controls.
# Historical fixture: Mew 1 HP vs Seismic Toss, seeds 1..24, and Tackle seed 19.
var lethal_witnesses: int = 0
var lethal_failures: int = 0
var valid_lanes: int = 0
var attempted_lanes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_focus_band")
	create_timer(1800.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP003 Focus Band timeout")
			quit(2))

func _band_activated(session: RefCounted) -> bool:
	var logs: Array = session._checkpoint.get("snapshot", {}).get("native", {}).get("log", [])
	for entry: String in logs:
		if entry.begins_with("|-activate|") and entry.contains("Focus Band"):
			return true
	return false

func _band_case(seed: int, mode: String, lethal: bool) -> Dictionary:
	current_case = "C003_BAND_" + ("lethal_" if lethal else "nonlethal_") + str(seed) + "_" + mode
	var error_before: int = errors.size()
	automation = {"actor_species": "mew", "level": 100,
		"format": "gen9calvounifiedv1", "seed": [seed, 2, 3, 4],
		"physical_move": "reflect", "special_move": "water_gun",
		"speed_target": "mew", "damage_target": "mew"}
	var prepared: Dictionary = _fixture({"id": "focus_band"}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	_set_effect_moves(actor, "reflect")
	if lethal:
		actor.current_hp = 1
	prepared.foe = _mon(&"mew", 100, &"foe", ["seismic_toss" if lethal else "tackle"])
	var owner_before: Dictionary = _owner_data(owner)
	check("two physical Focus Bands " + current_case, _units(owner, &"focus_band") == 2)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var started: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check("native Focus Band session starts " + current_case, started)
	if not started:
		await session.close()
		return {"valid": false}
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var hp_before: int = live.current_hp
	check("native starts at designed HP " + current_case,
		hp_before == (1 if lethal else live.stats.max_hp))
	check("native item belongs exclusively to selected lane " + current_case,
		live.held_item_id == (&"focus_band" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"focus_band" if mode == "reserve" else &""))
	var command: Dictionary = await session.submit("move 1", session.revision)
	check("native turn accepted " + current_case, command.get("accepted", false))
	if not command.get("accepted", false):
		await session.close()
		return {"valid": false}
	live = session.battle_state().creature(&"own")
	var hp_after: int = live.current_hp
	var activated: bool = _band_activated(session)
	check("native Focus Band never consumed " + current_case,
		not live.held_item_consumed
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("no owner mutation before settlement " + current_case,
		_owner_data(owner) == owner_before)
	if lethal:
		check("controls knocked out at one HP " + current_case,
			(mode == "active" and hp_after in [0, 1]) or
			(mode != "active" and hp_after == 0))
		if mode == "active":
			check("survival at 1 HP iff real Focus Band activation " + current_case,
				(hp_after == 1) == activated)
		else:
			check("no false native Focus Band activation " + current_case,
				not activated)
	else:
		check("nonlethal hit actually damages and does not KO " + current_case,
			hp_after > 0 and hp_after < hp_before)
		check("nonlethal Focus Band never activates " + current_case,
			not activated)
	var snapshot: Dictionary = session.snapshot()
	var restored: Dictionary = await _restore_probe(session, owner,
		"c003_band_" + ("lethal_" if lethal else "nonlethal_") + str(seed) + "_" + mode,
		"Focus Band native SaveV2 " + mode)
	if not restored.get("valid", false):
		return {"valid": false}
	session = restored.session
	check("exact native checkpoint after disk restore " + current_case,
		session.snapshot() == snapshot)
	check("exact owner after disk restore " + current_case,
		_owner_data(restored.owner) == owner_before)
	check("Focus Band native HP and consumption survive restore " + current_case,
		session.battle_state().creature(&"own").current_hp == hp_after
		and not session.battle_state().creature(&"own").held_item_consumed)
	await session.close()
	return {"valid": errors.size() == error_before, "mode": mode,
		"hp_before": hp_before, "hp_after": hp_after, "activated": activated}

func _run_focus_band() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_focus_band"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional overlay", Variants.apply(catalogs))
	for seed: int in range(1, 25):
		var lanes: Dictionary = {}
		for mode: String in ["active", "none", "reserve"]:
			lanes[mode] = await _band_case(seed, mode, true)
			attempted_lanes += 1
			if lanes[mode].get("valid", false):
				valid_lanes += 1
		check("three native lethal lanes for seed " + str(seed),
			lanes.active.get("valid", false) and lanes.none.get("valid", false)
			and lanes.reserve.get("valid", false))
		if lanes.active.get("valid", false) and lanes.none.get("valid", false) and lanes.reserve.get("valid", false):
			check("controls both knocked out at same seed " + str(seed),
				lanes.none.hp_after == 0 and lanes.reserve.hp_after == 0)
			check("focus band active survives only when native activation " + str(seed),
				(lanes.active.hp_after == 1) == lanes.active.activated)
			if lanes.active.activated:
				lethal_witnesses += 1
			else:
				lethal_failures += 1
	var normal: Dictionary = {}
	for mode: String in ["active", "none", "reserve"]:
		normal[mode] = await _band_case(19, mode, false)
		attempted_lanes += 1
		if normal[mode].get("valid", false):
			valid_lanes += 1
	check("three nonlethal controls certified",
		normal.active.get("valid", false) and normal.none.get("valid", false)
		and normal.reserve.get("valid", false))
	if normal.active.get("valid", false) and normal.none.get("valid", false) and normal.reserve.get("valid", false):
		check("nonlethal HP loss unchanged by Focus Band and reserve",
			normal.active.hp_after == normal.none.hp_after
			and normal.none.hp_after == normal.reserve.hp_after)
	check("Focus Band native RNG true witness", lethal_witnesses > 0)
	check("Focus Band native RNG false witness", lethal_failures > 0)
	check("75 genuine native SaveV2 lanes", attempted_lanes == 75 and valid_lanes == 75)
	done = true
	if errors.is_empty() and valid_lanes == 75:
		print("W01_V4_C003_FOCUS_BAND PASS rows=75 positive=", lethal_witnesses,
			" negative=", lethal_failures, " checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_FOCUS_BAND FAIL rows=", valid_lanes,
			" positive=", lethal_witnesses, " negative=", lethal_failures,
			" checks=", checks, " errors=", errors.size())
		quit(1)
