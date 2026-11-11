extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01/09: authentic native Poison heal and non-Poison penalty, inventory to SaveV2.
const SLUDGE_OUT := "res://.godot/parallel_items/w01_v4_black_sludge"
var sludge_results: Array = []
var sludge_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_sludge")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("Black Sludge L3 watchdog")
			quit(2))

func _sludge_case(kind: String, mode: String) -> Dictionary:
	var start_errors: int = errors.size()
	var player := PlayerCollection.new()
	var own_species: StringName = &"gengar" if kind == "poison" else &"mew"
	var own := _mon(own_species, 100, &"own", ["reflect", "shadow_ball"])
	var reserve := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.current_hp = own.stats.max_hp if mode == "full" else 150
	check("Black Sludge actual owned party " + kind + "/" + mode,
		player.party.add_creature(own) and player.party.add_creature(reserve))
	check("Black Sludge actual inventory stock",
		player.inventory.add(&"black_sludge", 1))
	var service := ItemService.new()
	check("Black Sludge real equip service enabled",
		service.configure(player, catalogs, func(): return true)
		and service.holdable(&"black_sludge"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Black Sludge genuine bag equip",
			service.equip(&"black_sludge", target).get("accepted", false)
			and player.inventory.quantity(&"black_sludge") == 0)
	var pre := _roundtrip(player, "sludge_" + kind + "_" + mode + "_pre")
	if not pre.valid: return {"valid": false}
	player = pre.owner
	var health: int = player.owned_creature(&"own").current_hp
	var maximum: int = player.owned_creature(&"own").stats.max_hp
	var foe := _mon(&"caterpie", 1, &"foe", ["growl"])
	var session := FieldSession.new(catalogs, player, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Black Sludge genuine native field session", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Black Sludge true end-turn processed", first.get("accepted", false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var delta: int = live.current_hp-health
	var active: bool = mode == "active" or mode == "full"
	var expected: int = 0
	if active and kind == "poison" and mode != "full":
		expected = maxi(1, maximum / 16)
	elif active and kind != "poison":
		expected = -maxi(1, maximum / 8)
	check("Black Sludge actual residual and full HP control " + kind + "/" + mode,
		delta == expected)
	check("Black Sludge nonconsumable owner unchanged",
		live.held_item_id == (&"black_sludge" if active else &"")
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"black_sludge" if mode == "reserve" else &"")
		and not live.held_item_consumed)
	var attempts: int = 0
	while session.phase() != "finished" and attempts < 6:
		var result: Dictionary = await session.submit("move 2", session.revision)
		check("Black Sludge actual finishing blow " + kind + "/" + mode,
			result.get("accepted", false))
		attempts += 1
	check("Black Sludge natural wild victory", session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Black Sludge actual encounter settlement",
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var post := _roundtrip(player, "sludge_" + kind + "_" + mode + "_post")
	if post.valid:
		check("Black Sludge exact stock and SaveV2 retained",
			post.owner.inventory.quantity(&"black_sludge") == (1 if mode == "none" else 0)
			and post.owner.owned_creature(&"own").held_item_id ==
				(&"black_sludge" if active else &"")
			and post.owner.owned_creature(&"reserve").held_item_id ==
				(&"black_sludge" if mode == "reserve" else &"")
			and not post.owner.owned_creature(&"own").held_item_consumed
			and not post.owner.owned_creature(&"reserve").held_item_consumed)
	await session.close()
	return {"valid": errors.size() == start_errors and post.valid,
		"kind": kind, "mode": mode, "delta": delta, "expected": expected}

func _run_sludge() -> void:
	destination = SLUDGE_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Black Sludge canonical game catalog", Variants.apply(catalogs))
	for mode in ["active", "none", "reserve", "full"]:
		current_case = "T04_09_poison_" + mode
		var a: Dictionary = await _sludge_case("poison", mode)
		sludge_results.append(a)
		if a.get("valid", false): sludge_passes += 1
	for mode in ["active", "none", "reserve"]:
		current_case = "T04_09_nonpoison_" + mode
		var a: Dictionary = await _sludge_case("nonpoison", mode)
		sludge_results.append(a)
		if a.get("valid", false): sludge_passes += 1
	check("Black Sludge seven true L3 modes", sludge_passes == 7)
	var f: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Black Sludge report output", f != null)
	if f != null:
		f.store_string(JSON.stringify({"worker":"W01", "row":"09",
			"rows":sludge_results,"checks":checks,"errors":errors}, "  "))
		f.close()
	done = true
	if errors.is_empty() and sludge_passes == 7:
		print("W01_V4_L3_ROW PASS row=09 id=black_sludge modes=7 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=09 id=black_sludge modes=", sludge_passes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
