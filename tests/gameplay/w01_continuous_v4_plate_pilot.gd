extends "res://tests/gameplay/w01_continuous_v4_stage_held_l3.gd"

# W01 V4: four elemental Plates, true native damage and full owner SaveV2.
# Do not infer any Arceus-form mechanics from this item-only damage test.
const PLATE_MOVES := {
	"flame_plate": "flamethrower",
	"splash_plate": "surf",
	"zap_plate": "thunderbolt",
	"meadow_plate": "energy_ball"
}
var plate_rows: Array = []
var plate_passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_plate_matrix")
	create_timer(1100.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 plate pilot timeout")
			quit(2))

func _plate_lane(item_name: String, move_name: String, mode: String) -> Dictionary:
	current_case = "V4_PLATE_" + item_name + "_" + mode
	var err_before: int = errors.size()
	var id := StringName(item_name)
	var owner := PlayerCollection.new()
	check("plate party " + current_case,
		owner.party.add_creature(_mon(&"mew", 100, &"own", [move_name, "tackle" if move_name == "shadow_ball" else "shadow_ball"]))
		and owner.party.add_creature(_mon(&"mew", 100, &"reserve", ["reflect"])))
	check("single genuine Plate in bag " + current_case, owner.inventory.add(id, 1))
	var service := ItemService.new()
	check("IA6 Plate supported " + current_case,
		service.configure(owner, catalogs, func(): return true) and service.holdable(id))
	if mode != "none":
		check("equip real Plate in lane " + current_case,
			service.equip(id, &"own" if mode == "active" else &"reserve").get("accepted", false))
	check("no duplicate bag Plate after equip " + current_case,
		owner.inventory.quantity(id) == (1 if mode == "none" else 0))
	var prior := _saved(owner, item_name + "_" + mode + "_plate_pre")
	if not prior.get("valid", false):
		return {"valid": false, "damage": -1}
	owner = prior.owner
	var foe := _mon(&"mew", 100, &"foe", ["growl"])
	foe.current_hp = foe.stats.max_hp
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("native Plate session begins " + current_case, opened)
	if not opened:
		await session.close()
		return {"valid": false, "damage": -1}
	check("only exact native holder has Plate " + current_case,
		session.battle_state().creature(&"own").held_item_id == (id if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id == (id if mode == "reserve" else &""))
	var hp_before: int = session.battle_state().creature(&"foe").current_hp
	var command: Dictionary = await session.submit("move 1", session.revision)
	check("native type move accepted " + current_case, command.get("accepted", false))
	var damage: int = hp_before - session.battle_state().creature(&"foe").current_hp
	check("real nonlethal first hit " + current_case,
		damage > 0 and session.battle_state().creature(&"foe").current_hp > 0)
	check("no premature campaign mutation " + current_case,
		owner.owned_creature(&"own").held_item_id == (id if mode == "active" else &"")
		and owner.owned_creature(&"reserve").held_item_id == (id if mode == "reserve" else &"")
		and not owner.owned_creature(&"own").held_item_consumed)
	var turns: int = 0
	while session.phase() != "finished" and turns < 12:
		var next: Dictionary = await session.submit("move 2", session.revision)
		check("native finishing move accepted " + current_case + str(turns), next.get("accepted", false))
		turns += 1
	check("real native victory " + current_case, session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("real victory settlement " + current_case,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var after := _saved(owner, item_name + "_" + mode + "_plate_post")
	if after.get("valid", false):
		owner = after.owner
		check("Plate not consumed and persisted by SaveV2 " + current_case,
			owner.inventory.quantity(id) == (1 if mode == "none" else 0)
			and owner.owned_creature(&"own").held_item_id == (id if mode == "active" else &"")
			and owner.owned_creature(&"reserve").held_item_id == (id if mode == "reserve" else &"")
			and not owner.owned_creature(&"own").held_item_consumed
			and not owner.owned_creature(&"reserve").held_item_consumed)
	await session.close()
	return {"valid": errors.size() == err_before and after.get("valid", false),
		"item": item_name, "mode": mode, "damage": damage}

func _run_plate_matrix() -> void:
	destination = "res://.godot/parallel_items/w01_v4_plate_matrix"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay real", Variants.apply(catalogs))
	for item_name: String in PLATE_MOVES:
		var base: int = plate_rows.size()
		for mode: String in ["active", "none", "reserve"]:
			var row: Dictionary = await _plate_lane(item_name, PLATE_MOVES[item_name], mode)
			plate_rows.append(row)
			if row.get("valid", false):
				plate_passed += 1
		if plate_rows.size() == base + 3:
			var a: Dictionary = plate_rows[base]
			var n: Dictionary = plate_rows[base + 1]
			var r: Dictionary = plate_rows[base + 2]
			check("Plate type damage boosts active only " + item_name,
				a.get("valid", false) and n.get("valid", false) and r.get("valid", false)
				and int(a.damage) > int(n.damage)
				and int(n.damage) == int(r.damage))
	check("all four Plates three modes", plate_passed == 12)
	done = true
	if errors.is_empty() and plate_passed == 12:
		print("W01_V4_PLATE_PILOT PASS items=4 modes=12 checks=", checks)
		quit(0)
	else:
		print("W01_V4_PLATE_PILOT FAIL modes=", plate_passed, " errors=", errors.size(), " checks=", checks)
		quit(1)
