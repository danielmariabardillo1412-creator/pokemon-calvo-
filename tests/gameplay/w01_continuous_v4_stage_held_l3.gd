extends "res://tests/gameplay/item_automation_v28.gd"

# W01 V4: NO_DIFF_NEEDED must be demonstrated against IA6 staging game seams.
# Real Inventory -> FieldItemService -> NativeSession -> settlement -> SaveV2.
const ItemService = preload("res://modules/inventory/field_item_service.gd")
const FieldSession = preload("res://modules/gameplay/field_native_session.gd")
const OUT := "res://.godot/parallel_items/w01_v4_stage_l3"
var cases: Array = []
var passed: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_held_stage")
	create_timer(1050.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 staging held L3 timed out")
			quit(2))

func _saved(owner: PlayerCollection, label: String) -> Dictionary:
	var before: Dictionary = _owner_data(owner)
	var repository := SaveGameRepository.new()
	var file: String = "user://w01_v4_stage_" + label + ".json"
	var written: SaveResult = repository.save_collection(file, owner)
	check(label + " writes actual disk SaveV2", written.ok)
	if not written.ok:
		return {"valid": false}
	var loaded: LoadResult = repository.load(file)
	check(label + " reads actual disk SaveV2", loaded.ok)
	if not loaded.ok:
		return {"valid": false}
	var restored := PlayerCollection.new()
	restored.party = loaded.party
	restored.storage = loaded.storage
	restored.inventory = loaded.inventory
	check(label + " complete loaded state stable", _owner_data(restored) == before)
	return {"valid": true, "owner": restored}

func _case(kind: String, mode: String) -> Dictionary:
	var start_errors: int = errors.size()
	var item: StringName = StringName(kind)
	var active: bool = mode == "active" or mode == "full"
	var reserve: bool = mode == "reserve"
	var own_moves: Array = ["dragon_pulse", "shadow_ball"] if kind == "draco_plate" else ["reflect", "shadow_ball"]
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", own_moves)
	var bench := _mon(&"mew", 100, &"reserve", ["reflect"])
	if kind == "leftovers":
		own.current_hp = own.stats.max_hp if mode == "full" else 150
	elif kind == "sitrus_berry":
		own.current_hp = 120
	check("stage held canonical party " + kind + "/" + mode,
		owner.party.add_creature(own) and owner.party.add_creature(bench))
	check("stage held one real stock unit " + kind + "/" + mode,
		owner.inventory.add(item, 1))
	var service := ItemService.new()
	check("staging IA6 FieldItemService accepts policy " + kind + "/" + mode,
		service.configure(owner, catalogs, func(): return true) and service.holdable(item))
	if active or reserve:
		var target: StringName = &"own" if active else &"reserve"
		check("staging IA6 exact bag equip " + kind + "/" + mode,
			service.equip(item, target).get("accepted", false)
			and owner.inventory.quantity(item) == 0)
	var before := _saved(owner, kind + "_" + mode + "_pre")
	if not before.valid:
		return {"valid": false, "id": kind, "mode": mode}
	owner = before.owner
	var prior_hp: int = owner.owned_creature(&"own").current_hp
	var max_hp: int = owner.owned_creature(&"own").stats.max_hp
	var foe := _mon(&"mew", 100, &"foe", ["growl"]) if kind == "draco_plate" else _mon(&"caterpie", 1, &"foe", ["growl"])
	if kind == "draco_plate":
		foe.current_hp = 250
	var encounter := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var started: bool = await encounter.begin_wild(self, foe, [19, 2, 3, 4])
	check("staging genuine FieldNativeSession begins " + kind + "/" + mode, started)
	if not started:
		await encounter.close()
		return {"valid": false, "id": kind, "mode": mode}
	var entry_hp: int = encounter.battle_state().creature(&"own").current_hp
	var expected_entry: int = prior_hp
	if kind == "sitrus_berry" and active:
		expected_entry += maxi(1, int(max_hp / 4))
	check("stage native entry HP and single Sitrus activation " + kind + "/" + mode,
		entry_hp == expected_entry)
	check("stage live held item and reserve match exact ownership " + kind + "/" + mode,
		encounter.battle_state().creature(&"own").held_item_id == (item if active else &"")
		and encounter.battle_state().creature(&"reserve").held_item_id == (item if reserve else &""))
	var foe_before: int = encounter.battle_state().creature(&"foe").current_hp
	var first: Dictionary = await encounter.submit("move 1", encounter.revision)
	check("stage native first command accepted " + kind + "/" + mode, first.get("accepted", false))
	var own_live: CreatureInstance = encounter.battle_state().creature(&"own")
	var delta: int = own_live.current_hp - entry_hp
	var dealt: int = foe_before - encounter.battle_state().creature(&"foe").current_hp
	if kind == "leftovers":
		var healing: int = maxi(1, int(max_hp / 16)) if active and mode != "full" else 0
		check("stage Leftovers real residual only active injured owner " + mode, delta == healing)
	elif kind == "sitrus_berry":
		check("stage Sitrus not duplicated at first turn " + mode,
			delta == 0 and own_live.held_item_consumed == active)
	else:
		check("stage Draco Plate native positive nonlethal hit " + mode,
			dealt > 0 and encounter.battle_state().creature(&"foe").current_hp > 0)
	check("stage equipped item remains original holder after native turn " + kind + "/" + mode,
		own_live.held_item_id == (item if active else &"")
		and encounter.battle_state().creature(&"reserve").held_item_id == (item if reserve else &""))
	var turns: int = 0
	while encounter.phase() != "finished" and turns < 8:
		var attack: Dictionary = await encounter.submit("move 2", encounter.revision)
		check("stage natural finishing action accepted " + kind + "/" + mode, attack.get("accepted", false))
		turns += 1
	check("stage natural battle finished " + kind + "/" + mode, encounter.phase() == "finished")
	var settled: Dictionary = encounter.settle_finished_battle()
	check("stage authoritative settlement " + kind + "/" + mode,
		settled.get("accepted", false) and encounter.completion_reason == "VICTORY")
	var after := _saved(owner, kind + "_" + mode + "_post")
	if after.valid:
		check("stage SaveV2 item identity and spent flag persisted " + kind + "/" + mode,
			after.owner.inventory.quantity(item) == (1 if not active and not reserve else 0)
			and after.owner.owned_creature(&"own").held_item_id == (item if active else &"")
			and after.owner.owned_creature(&"reserve").held_item_id == (item if reserve else &"")
			and after.owner.owned_creature(&"own").held_item_consumed == (active and kind == "sitrus_berry")
			and not after.owner.owned_creature(&"reserve").held_item_consumed)
	await encounter.close()
	return {"valid": errors.size() == start_errors and after.valid, "id": kind,
		"mode": mode, "dealt": dealt, "delta": delta, "entry_hp": entry_hp}

func _run_held_stage() -> void:
	destination = OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("stage regional overlay applied", Variants.apply(catalogs))
	for item in ["leftovers", "sitrus_berry", "draco_plate"]:
		var start_idx: int = cases.size()
		for mode in (["active", "none", "reserve", "full"] if item == "leftovers" else ["active", "none", "reserve"]):
			current_case = "V4_" + item + "_" + mode
			var result: Dictionary = await _case(item, mode)
			cases.append(result)
			if result.get("valid", false):
				passed += 1
		if item == "draco_plate" and cases.size() == start_idx + 3:
			check("stage only active Draco holder boosts real type damage",
				int(cases[start_idx].dealt) > int(cases[start_idx + 1].dealt)
				and int(cases[start_idx + 1].dealt) == int(cases[start_idx + 2].dealt))
	check("staging ten true L3 routes", passed == 10)
	var out: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("stage L3 evidence report writable", out != null)
	if out != null:
		out.store_string(JSON.stringify({"mission":"W01_V4", "cases":cases,
			"checks":checks,"errors":errors}, "  "))
		out.close()
	done = true
	if errors.is_empty() and passed == 10:
		print("W01_V4_STAGE_L3 PASS modes=10 checks=", checks)
		quit(0)
	else:
		print("W01_V4_STAGE_L3 FAIL modes=", passed, " errors=", errors.size(),
			" checks=", checks)
		quit(1)
