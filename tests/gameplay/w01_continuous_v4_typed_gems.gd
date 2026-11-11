extends "res://tests/gameplay/w01_continuous_v4_stage_held_l3.gd"

# Focused W01 QA coverage for five genuine typed Gems absent from V4 staging.
# Exact item/move combinations checked against historical W01 TANDA03 manifest.
const GEM_MOVES := {
	"fire_gem": "fire_punch",
	"water_gem": "surf",
	"electric_gem": "thunderbolt",
	"grass_gem": "energy_ball",
	"ice_gem": "ice_beam"
}
var verified_rows: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_typed_gems")
	create_timer(1100.0).timeout.connect(func():
		if not done:
			push_error("W01 typed gem staging timeout")
			quit(2))

func _typed_case(item_name: String, move_name: String, mode: String) -> Dictionary:
	current_case = "W01_V4_TYPED_" + item_name + "_" + mode
	var start_errors: int = errors.size()
	var id := StringName(item_name)
	var owner := PlayerCollection.new()
	check("owned party " + item_name + mode,
		owner.party.add_creature(_mon(&"mew", 100, &"own", [move_name]))
		and owner.party.add_creature(_mon(&"mew", 100, &"reserve", ["tackle"])))
	check("physical gem stock " + item_name + mode, owner.inventory.add(id, 2))
	var service := ItemService.new()
	check("IA6 service configured " + item_name + mode,
		service.configure(owner, catalogs, func(): return true) and service.holdable(id))
	if mode != "none":
		check("real gem equipped " + item_name + mode,
			service.equip(id, &"own" if mode == "active" else &"reserve").get("accepted", false))
	check("physical stock after equip " + item_name + mode,
		owner.inventory.quantity(id) == (2 if mode == "none" else 1))
	var pre := _saved(owner, item_name + "_" + mode + "_typed_pre")
	if not pre.get("valid", false):
		return {"valid": false}
	owner = pre.owner
	var foe := _mon(&"caterpie", 1, &"foe", ["growl"])
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("native session opens " + item_name + mode, opened)
	if not opened:
		await session.close()
		return {"valid": false}
	check("native exact holder " + item_name + mode,
		session.battle_state().creature(&"own").held_item_id == (id if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id == (id if mode == "reserve" else &""))
	var hp_before: int = session.battle_state().creature(&"foe").current_hp
	var attack: Dictionary = await session.submit("move 1", session.revision)
	check("real typed move accepted " + item_name + mode, attack.get("accepted", false))
	var hp_after: int = session.battle_state().creature(&"foe").current_hp
	check("native typed attack damages foe " + item_name + mode, hp_after < hp_before)
	check("active-only genuine gem consumption " + item_name + mode,
		session.battle_state().creature(&"own").held_item_consumed == (mode == "active")
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("no premature owner publication " + item_name + mode,
		not owner.owned_creature(&"own").held_item_consumed
		and not owner.owned_creature(&"reserve").held_item_consumed)
	check("natural native victory " + item_name + mode, session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("real settlement publishes once " + item_name + mode,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var post := _saved(owner, item_name + "_" + mode + "_typed_post")
	if post.get("valid", false):
		owner = post.owner
		check("SaveV2 spent only when active " + item_name + mode,
			owner.owned_creature(&"own").held_item_consumed == (mode == "active")
			and not owner.owned_creature(&"reserve").held_item_consumed
			and owner.inventory.quantity(id) == (2 if mode == "none" else 1))
		service = ItemService.new()
		check("loaded owner real service " + item_name + mode,
			service.configure(owner, catalogs, func(): return true))
		if mode == "active":
			check("spent typed gem not refunded " + item_name,
				service.unequip(&"own").get("accepted", false)
				and owner.inventory.quantity(id) == 1)
		if mode == "reserve":
			check("untouched reserve gem refunded exactly once " + item_name,
				service.unequip(&"reserve").get("accepted", false)
				and owner.inventory.quantity(id) == 2)
	await session.close()
	return {"valid": errors.size() == start_errors and post.get("valid", false),
		"item": item_name, "move": move_name, "mode": mode}

func _run_typed_gems() -> void:
	destination = "res://.godot/parallel_items/w01_v4_typed_gems"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional overlay", Variants.apply(catalogs))
	for item_name: String in GEM_MOVES:
		var move_name: String = String(GEM_MOVES[item_name])
		for mode: String in ["active", "none", "reserve"]:
			var result: Dictionary = await _typed_case(item_name, move_name, mode)
			cases.append(result)
			if result.get("valid", false):
				verified_rows += 1
	check("all five canonical Gem types and three modes", verified_rows == 15)
	done = true
	if errors.is_empty() and verified_rows == 15:
		print("W01_V4_TYPED_GEMS PASS items=5 modes=15 checks=", checks)
		quit(0)
	else:
		print("W01_V4_TYPED_GEMS FAIL rows=", verified_rows, " checks=", checks,
			" errors=", errors.size())
		quit(1)
