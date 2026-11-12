extends "res://tests/gameplay/item_automation_v28.gd"

# CAMP003 Assault Vest status lock: genuine Showdown request and rejection,
# distinct from status protection in unrelated historical fixtures.
var vest_rows: Array = []
var vest_passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_vest")
	create_timer(450.0).timeout.connect(func():
		if not done:
			push_error("W01 CAMP003 Assault Vest timeout")
			quit(2))

func _lane(mode: String) -> Dictionary:
	current_case = "W01_C003_VEST_" + mode
	var start_errors: int = errors.size()
	automation = {"actor_species": "mew", "level": 100, "format": "gen9calvounifiedv1",
		"seed": [19, 2, 3, 4], "physical_move": "tackle",
		"special_move": "water_gun", "speed_target": "mew", "damage_target": "mew"}
	var prepared: Dictionary = _fixture({"id": "assault_vest"}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var own: CreatureInstance = owner.owned_creature(&"own")
	own.moveset.clear(); own.move_ids.clear()
	check("real Tackle move " + mode, own.add_move(&"tackle", catalogs))
	check("real Reflect status move " + mode, own.add_move(&"reflect", catalogs))
	prepared.foe = _mon(&"mew", 100, &"foe", ["amnesia"])
	var before_owner := _owner_data(owner)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var started: bool = await session.begin_wild(self, prepared.foe, automation.seed)
	check("native session starts " + mode, started)
	if not started:
		await session.close()
		return {"valid": false}
	check("native holder exact " + mode,
		session.battle_state().creature(&"own").held_item_id ==
			(&"assault_vest" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"assault_vest" if mode == "reserve" else &""))
	var view: Dictionary = session._checkpoint.get("views", {}).get("p1", {}).get("request", {})
	var entries: Array = view.get("active", [])
	var moves: Array = entries[0].get("moves", []) if entries.size() > 0 else []
	check("native request exposes Tackle and Reflect " + mode, moves.size() >= 2)
	var status_disabled: bool = moves.size() >= 2 and bool(moves[1].get("disabled", false))
	check("Assault Vest prohibits status only on active holder " + mode,
		status_disabled == (mode == "active"))
	var frozen_snapshot: Dictionary = session.snapshot()
	if mode == "active":
		var rejected: Dictionary = await session.submit("move 2", session.revision)
		check("illegal native status command rejected " + mode,
			not rejected.get("accepted", false))
		check("illegal status command has no battle state mutation " + mode,
			session.snapshot() == frozen_snapshot)
	var accepted: Dictionary = await session.submit("move 1", session.revision)
	check("legal native physical Tackle accepted " + mode, accepted.get("accepted", false))
	check("Assault Vest remains unconsumed after legal Tackle " + mode,
		not session.battle_state().creature(&"own").held_item_consumed
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("owner not prematurely mutated " + mode, _owner_data(owner) == before_owner)
	var turn_snapshot: Dictionary = session.snapshot()
	var restored: Dictionary = await _restore_probe(session, owner,
		"c003_vest_" + mode, "vest real SaveV2 " + mode)
	if not restored.get("valid", false):
		return {"valid": false}
	session = restored.session
	owner = restored.owner
	check("battle checkpoint exact after disk restore " + mode,
		session.snapshot() == turn_snapshot)
	check("owner exact after disk restore " + mode,
		_owner_data(owner) == before_owner)
	await session.close()
	return {"valid": errors.size() == start_errors, "mode": mode,
		"status_disabled": status_disabled}

func _run_vest() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_vest"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlays", Variants.apply(catalogs))
	for mode: String in ["active", "none", "reserve"]:
		var row: Dictionary = await _lane(mode)
		vest_rows.append(row)
		if row.get("valid", false):
			vest_passed += 1
	check("three native Assault Vest lanes", vest_passed == 3)
	if vest_rows.size() == 3:
		check("only real active holder blocks status command",
			vest_rows[0].get("valid", false) and vest_rows[1].get("valid", false)
			and vest_rows[2].get("valid", false)
			and vest_rows[0].get("status_disabled", false)
			and not vest_rows[1].get("status_disabled", true)
			and not vest_rows[2].get("status_disabled", true))
	done = true
	if errors.is_empty() and vest_passed == 3:
		print("W01_V4_C003_VEST PASS modes=3 checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_VEST FAIL modes=", vest_passed, " errors=", errors.size(),
			" checks=", checks)
		quit(1)
