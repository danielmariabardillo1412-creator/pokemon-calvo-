extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 TANDA03: native FieldSession edge paths (reserve, capture, defeat,
# Transform, persistent SaveV2) through actual prebattle FieldItemService.equip.
# No UI simulation; no changes to protected production systems.
const BOUNDARY_OUT := "res://.godot/parallel_items/w01_autorun_v3_boundaries"
var boundaries_ok: int = 0
var captures_ok: int = 0
var defeats_ok: int = 0
var transforms_ok: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_v3_boundaries")
	create_timer(750.0).timeout.connect(func():
		if not done:
			push_error("W01 V3 native field boundary timeout")
			quit(2))

func _run_v3_boundaries() -> void:
	destination = BOUNDARY_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("W01 V3 boundary catalog ready", Variants.apply(catalogs))
	current_case = "T03_07_reserve_switch_capture"
	await _reserve_capture()
	current_case = "T03_07_defeat_retention"
	await _defeat_retention()
	current_case = "T03_07_transform_save_capture"
	await _transform_capture()
	check("W01 V3 three independent native boundary cases", boundaries_ok == 3)
	check("W01 V3 2 captures published from native battle", captures_ok == 2)
	check("W01 V3 1 defeat without false consumed item", defeats_ok == 1)
	check("W01 V3 1 Transform survived save/restore", transforms_ok == 1)
	var data: Dictionary = {"schema_version": 1, "tanda": "03",
		"checks": checks, "errors": errors, "boundaries": boundaries_ok,
		"captures": captures_ok, "defeats": defeats_ok, "transforms": transforms_ok,
		"limitations": ["Real native FieldSession and battle settlement, no UI rendering",
			"Other special interactions (Trick, Fling) remain outside this scope"]}
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("V3 boundary evidence writable", file != null)
	if file != null:
		file.store_string(JSON.stringify(data, "  "))
		file.close()
	done = true
	if errors.is_empty():
		print("W01_V3_BOUNDARIES PASS cases=3 captures=2 defeats=1 transforms=1 checks=", checks)
	else:
		print("W01_V3_BOUNDARIES FAIL cases=", boundaries_ok,
			" errors=", errors.size(), " checks=", checks)
	quit(0 if errors.is_empty() else 1)

func _reserve_capture() -> void:
	var id := &"ghost_gem"
	var f: Dictionary = _owner_with_gem(id, "shadow_ball")
	var owner: PlayerCollection = f.owner
	var service: RefCounted = f.service
	check("reserve: service equips original Gem to owned bench",
		service.equip(id, &"reserve").get("accepted", false))
	check("reserve: real Master Ball bag entry",
		owner.inventory.add(&"master_ball", 1))
	var before: Dictionary = _roundtrip(owner, "reserve_ghost_pre")
	if not before.valid:
		return
	owner = before.owner
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self,
		_mon(&"mew", 100, &"foe", ["amnesia"]), [19, 2, 3, 4])
	check("reserve: real field session opens", opened)
	if not opened:
		await session.close()
		return
	check("reserve: correct gem only belongs to bench",
		session.battle_state().creature(&"own").held_item_id == &""
		and session.battle_state().creature(&"reserve").held_item_id == id)
	var switched: Dictionary = await session.submit("switch 2", session.revision)
	check("reserve: switch 2 accepted with unchanged gem stock",
		switched.get("accepted", false)
		and session.battle_state().active_for_side(&"side_a").instance_id == &"reserve"
		and not session.battle_state().creature(&"reserve").held_item_consumed
		and owner.inventory.quantity(id) == 1)
	var hit: Dictionary = await session.submit("move 2", session.revision)
	check("reserve: genuine ghost hit now consumes only bench item",
		hit.get("accepted", false)
		and session.battle_state().creature(&"reserve").held_item_consumed
		and session.battle_state().creature(&"own").held_item_id == &"")
	var back: Dictionary = await session.submit("switch 1", session.revision)
	check("reserve: return to own without item resurrection",
		back.get("accepted", false)
		and session.battle_state().active_for_side(&"side_a").instance_id == &"own")
	var return_bench: Dictionary = await session.submit("switch 2", session.revision)
	check("reserve: second entry keeps consumed flag",
		return_bench.get("accepted", false)
		and session.battle_state().active_for_side(&"side_a").instance_id == &"reserve"
		and session.battle_state().creature(&"reserve").held_item_consumed)
	var snapshot: Dictionary = session.snapshot()
	var loaded := _roundtrip(owner, "reserve_ghost_active_pre_capture")
	check("reserve: campaign save remains unspent pending settlement",
		loaded.valid and not owner.owned_creature(&"reserve").held_item_consumed)
	var caught: Dictionary = await session.capture(&"master_ball", session.revision)
	check("reserve: canonical Master Ball capture settles",
		caught.get("accepted", false) and session.completion_reason == "CAPTURED")
	check("reserve: capture publishes spent Gem exactly once to owner",
		owner.owned_creature(&"reserve").held_item_consumed
		and owner.owned_creature(&"reserve").held_item_id == id
		and owner.inventory.quantity(id) == 1
		and owner.inventory.quantity(&"master_ball") == 0)
	var final := _roundtrip(owner, "reserve_ghost_after_capture")
	check("reserve: captured result survives V2 disk reload",
		final.valid and final.owner.owned_creature(&"reserve").held_item_consumed
		and final.owner.inventory.quantity(id) == 1)
	await session.close()
	boundaries_ok += 1
	captures_ok += 1
	print("W01_V3_BOUNDARY_ROW PASS kind=reserve_capture gem=ghost_gem")

func _defeat_retention() -> void:
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 1, &"own", ["reflect", "shadow_ball"])
	check("defeat: own creature in actual collection", owner.party.add_creature(own))
	check("defeat: one actual Ghost Gem bag item", owner.inventory.add(&"ghost_gem", 1))
	var service := ItemService.new()
	check("defeat: existing service configured",
		service.configure(owner, catalogs, func(): return true))
	check("defeat: equip service accepts gem", service.equip(&"ghost_gem", &"own").get("accepted", false))
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self,
		_mon(&"mew", 100, &"foe", ["shadow_ball"]), [19, 2, 3, 4])
	check("defeat: native field session opens", opened)
	if not opened:
		await session.close()
		return
	var hit: Dictionary = await session.submit("move 1", session.revision)
	check("defeat: foe attacks before low-level holder", hit.get("accepted", false))
	check("defeat: owner faints without spending match-type gem",
		session.battle_state().creature(&"own").is_knocked_out()
		and not session.battle_state().creature(&"own").held_item_consumed)
	check("defeat: native completion is genuine", session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("defeat: authoritative settlement does not consume held item",
		settled.get("accepted", false) and session.completion_reason == "DEFEAT"
		and owner.owned_creature(&"own").held_item_id == &"ghost_gem"
		and not owner.owned_creature(&"own").held_item_consumed
		and owner.inventory.quantity(&"ghost_gem") == 0)
	var saved := _roundtrip(owner, "defeat_ghost")
	check("defeat: restored owner retains one unchanged Gem",
		saved.valid and saved.owner.owned_creature(&"own").held_item_id == &"ghost_gem"
		and not saved.owner.owned_creature(&"own").held_item_consumed
		and saved.owner.inventory.quantity(&"ghost_gem") == 0)
	await session.close()
	boundaries_ok += 1
	defeats_ok += 1
	print("W01_V3_BOUNDARY_ROW PASS kind=defeat gem=ghost_gem")

func _transform_capture() -> void:
	var owner := PlayerCollection.new()
	var ditto := _mon(&"ditto", 100, &"own", ["transform", "reflect"])
	var second := _mon(&"mew", 100, &"reserve", ["reflect"])
	check("Transform: actual owned Ditto and alternate creature",
		owner.party.add_creature(ditto) and owner.party.add_creature(second))
	check("Transform: real gem and Master Ball in bag",
		owner.inventory.add(&"ghost_gem", 2)
		and owner.inventory.add(&"master_ball", 1))
	var service := ItemService.new()
	check("Transform: FieldItemService configures", service.configure(owner, catalogs, func(): return true))
	check("Transform: gem equipped without injecting held flag",
		service.equip(&"ghost_gem", &"own").get("accepted", false)
		and owner.inventory.quantity(&"ghost_gem") == 1)
	var loaded := _roundtrip(owner, "transform_ghost_pre")
	if not loaded.valid:
		return
	owner = loaded.owner
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self,
		_mon(&"mew", 100, &"foe", ["shadow_ball", "amnesia"]), [19, 2, 3, 4])
	check("Transform: real field session opens", opened)
	if not opened:
		await session.close()
		return
	var transformed: Dictionary = await session.submit("move 1", session.revision)
	check("Transform: first real move accepted", transformed.get("accepted", false)
		and not session.battle_state().creature(&"own").held_item_consumed)
	var snapshot: Dictionary = session.snapshot()
	var owner_saved := _roundtrip(owner, "transform_ghost_mid")
	check("Transform: owner SaveV2 unchanged before native settlement", owner_saved.valid
		and not owner.owned_creature(&"own").held_item_consumed)
	if not owner_saved.valid:
		await session.close()
		return
	await session.close()
	owner = owner_saved.owner
	session = FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var restored: bool = await session.restore_saved(self, snapshot)
	check("Transform: native session restores mid-Transform exactly",
		restored and session.snapshot() == snapshot)
	if not restored:
		await session.close()
		return
	var transformed_hit: Dictionary = await session.submit("move 1", session.revision)
	check("Transform: borrowed Shadow Ball activates gem exactly once",
		transformed_hit.get("accepted", false)
		and session.battle_state().creature(&"own").held_item_consumed)
	var captured: Dictionary = await session.capture(&"master_ball", session.revision)
	check("Transform: real capture settles spent item",
		captured.get("accepted", false) and session.completion_reason == "CAPTURED"
		and owner.owned_creature(&"own").held_item_id == &"ghost_gem"
		and owner.owned_creature(&"own").held_item_consumed
		and owner.inventory.quantity(&"ghost_gem") == 1)
	var final := _roundtrip(owner, "transform_ghost_after")
	check("Transform: saved owner no longer transformed and spent item persisted",
		final.valid and final.owner.owned_creature(&"own").species_id == &"ditto"
		and final.owner.owned_creature(&"own").held_item_consumed
		and final.owner.inventory.quantity(&"ghost_gem") == 1)
	await session.close()
	boundaries_ok += 1
	captures_ok += 1
	transforms_ok += 1
	print("W01_V3_BOUNDARY_ROW PASS kind=transform_capture gem=ghost_gem")
