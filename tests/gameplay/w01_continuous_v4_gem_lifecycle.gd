extends "res://tests/gameplay/w01_continuous_v4_stage_held_l3.gd"

# Narrow staging-only positive/negative Native Gem lifecycle; reuse tested SaveV2 helper.
var gem_passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_gem_lifecycle")
	create_timer(300.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 native gem lifecycle timeout")
			quit(2))

func _gem_case(mode: String) -> bool:
	current_case = "V4_GEM_LIFECYCLE_" + mode
	var start_errors: int = errors.size()
	var id := &"normal_gem"
	var owner := PlayerCollection.new()
	check("two creatures owned " + mode,
		owner.party.add_creature(_mon(&"mew", 100, &"own", ["tackle"]))
		and owner.party.add_creature(_mon(&"mew", 100, &"reserve", ["tackle"])))
	check("two physical gems issued " + mode, owner.inventory.add(id, 2))
	var svc := ItemService.new()
	check("real service binds " + mode, svc.configure(owner, catalogs, func(): return true))
	if mode != "none":
		check("real equip " + mode, svc.equip(id, &"own" if mode == "active" else &"reserve").get("accepted", false))
	check("one unit per genuine equip " + mode,
		owner.inventory.quantity(id) == (2 if mode == "none" else 1))
	var saved := _saved(owner, "gem_" + mode + "_before")
	if not saved.get("valid", false):
		return false
	owner = saved.owner
	var foe := _mon(&"caterpie", 1, &"foe", ["growl"])
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("native session begins " + mode, opened)
	if not opened:
		await session.close()
		return false
	check("native owner and reserve isolation before move " + mode,
		session.battle_state().creature(&"own").held_item_id == (id if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id == (id if mode == "reserve" else &""))
	var hp_before: int = session.battle_state().creature(&"foe").current_hp
	var move: Dictionary = await session.submit("move 1", session.revision)
	check("native move accepted " + mode, move.get("accepted", false))
	check("native real damage " + mode, session.battle_state().creature(&"foe").current_hp < hp_before)
	check("Gem consumption only active " + mode,
		session.battle_state().creature(&"own").held_item_consumed == (mode == "active")
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("owner not settled prematurely " + mode,
		not owner.owned_creature(&"own").held_item_consumed)
	check("battle reaches real victory " + mode, session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("authoritative native settlement " + mode,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	check("owner spent flag only for active holder " + mode,
		owner.owned_creature(&"own").held_item_consumed == (mode == "active")
		and not owner.owned_creature(&"reserve").held_item_consumed)
	var after := _saved(owner, "gem_" + mode + "_after")
	if after.get("valid", false):
		owner = after.owner
		check("SaveV2 persists correct stock and spent flag " + mode,
			owner.inventory.quantity(id) == (2 if mode == "none" else 1)
			and owner.owned_creature(&"own").held_item_consumed == (mode == "active")
			and not owner.owned_creature(&"reserve").held_item_consumed)
		svc = ItemService.new()
		check("rebind after SaveV2 " + mode, svc.configure(owner, catalogs, func(): return true))
		if mode == "active":
			check("spent gem unequips without refund",
				svc.unequip(&"own").get("accepted", false)
				and owner.inventory.quantity(id) == 1
				and owner.owned_creature(&"own").held_item_id == &"")
			check("fresh unit can be refitted once",
				svc.equip(id, &"own").get("accepted", false)
				and owner.inventory.quantity(id) == 0
				and not owner.owned_creature(&"own").held_item_consumed)
		elif mode == "reserve":
			check("unused reserve gem unequips with exactly one refund",
				svc.unequip(&"reserve").get("accepted", false)
				and owner.inventory.quantity(id) == 2
				and owner.owned_creature(&"reserve").held_item_id == &"")
	await session.close()
	return errors.size() == start_errors and after.get("valid", false)

func _run_gem_lifecycle() -> void:
	destination = "res://.godot/parallel_items/w01_v4_gem_lifecycle"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	for mode in ["active", "none", "reserve"]:
		if await _gem_case(mode):
			gem_passed += 1
	check("three real Gem native modes", gem_passed == 3)
	done = true
	if errors.is_empty() and gem_passed == 3:
		print("W01_V4_GEM_LIFECYCLE PASS modes=3 checks=", checks)
		quit(0)
	else:
		print("W01_V4_GEM_LIFECYCLE FAIL modes=", gem_passed, " checks=", checks, " errors=", errors.size())
		quit(1)
