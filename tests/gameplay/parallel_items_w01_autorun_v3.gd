extends "res://tests/gameplay/parallel_items_w01_autorun_v2.gd"

# W01 TANDA03: real inventory/FieldItemService.equip -> genuine field session
# -> item consumption -> settlement -> full SaveGameRepository disk roundtrip.
# Separate from all historical tests, no shared production modifications.
const V3_FIXTURE := "res://tests/fixtures/parallel_items/w01_autorun_v3.json"
const V3_PROGRESS := "res://docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V3_PROGRESS.csv"
const V3_OUTPUT := "res://.godot/parallel_items/w01_autorun_v3"
const ItemService = preload("res://modules/inventory/field_item_service.gd")
const FieldSession = preload("res://modules/gameplay/field_native_session.gd")
var v3_results: Array = []
var v3_real_settlements: int = 0
var v3_real_equips: int = 0
var v3_legacy: int = 0
var v3_rejected: int = 0
var v3_reserve: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_autorun_v3")
	create_timer(1150.0).timeout.connect(func():
		if not done:
			push_error("W01 TANDA03 exceeded bounded native integration time")
			quit(2))

func _owner_with_gem(id: StringName, attack: String, quantity: int = 2) -> Dictionary:
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", [attack, "reflect"])
	var bench := _mon(&"mew", 100, &"reserve", ["reflect", attack])
	check("L3 own/bench independent creature identities", owner.party.add_creature(own)
		and owner.party.add_creature(bench) and own != bench)
	check("L3 actual bag receives gem quantity", owner.inventory.add(id, quantity)
		and owner.inventory.quantity(id) == quantity)
	var service: RefCounted = ItemService.new()
	check("L3 existing FieldItemService with canonical policy",
		service.configure(owner, catalogs, func(): return true))
	check("L3 selected Gem is holdable via real content policy", service.holdable(id))
	return {"owner": owner, "service": service}

func _loaded_owner(result: LoadResult) -> PlayerCollection:
	var owner := PlayerCollection.new()
	owner.party = result.party
	owner.storage = result.storage
	owner.inventory = result.inventory
	return owner

func _roundtrip(owner: PlayerCollection, label: String) -> Dictionary:
	var path := "user://w01_v3_" + label + ".json"
	var repo := SaveGameRepository.new()
	var before := _owner_data(owner)
	var wrote: SaveResult = repo.save_collection(path, owner)
	check(label + " actual SaveV2 disk write", wrote.ok)
	if not wrote.ok:
		return {"valid": false}
	var loaded: LoadResult = repo.load(path)
	check(label + " actual SaveV2 disk load", loaded.ok)
	if not loaded.ok:
		return {"valid": false}
	var restored: PlayerCollection = _loaded_owner(loaded)
	check(label + " SaveV2 bag+party+storage exact", _owner_data(restored) == before)
	return {"valid": true, "owner": restored, "disk": path}

func _real_cycle(entry: Dictionary) -> Dictionary:
	var id := StringName(entry.id)
	var attack: String = String(entry.attack)
	var case_before: int = errors.size()
	var prepared := _owner_with_gem(id, attack)
	var owner: PlayerCollection = prepared.owner
	var service: RefCounted = prepared.service
	var first := service.equip(id, &"own")
	check("real item equip accepted " + String(id), first.get("accepted", false)
		and first.get("status") == "APPLIED")
	check("real bag spends one unit at equip " + String(id),
		owner.inventory.quantity(id) == 1
		and owner.owned_creature(&"own").held_item_id == id
		and not owner.owned_creature(&"own").held_item_consumed
		and owner.owned_creature(&"reserve").held_item_id == &"")
	v3_real_equips += 1
	var loaded := _roundtrip(owner, String(id) + "_before_battle")
	if not loaded.valid:
		return {"valid": false}
	owner = loaded.owner
	# Use the actual FieldNativeSession used by field_native_bridge.gd, not a fake
	# battle object and not a private mutation of native_engine.cjs.
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var foe := _mon(&"caterpie", 1, &"foe", ["growl"])
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("existing native field adapter accepts real equipped owner " + String(id),
		opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var live: CreatureInstance = session.battle_state().creature(&"own")
	check("real native adapter received equipped original item " + String(id),
		live != null and live.held_item_id == id and not live.held_item_consumed)
	var before_hp: int = session.battle_state().creature(&"foe").current_hp
	var command: Dictionary = await session.submit("move 1", session.revision)
	check("native Gem hit committed and not synthetically applied " + String(id),
		command.get("accepted", false))
	if not command.get("accepted", false):
		await session.close()
		return {"valid": false}
	live = session.battle_state().creature(&"own")
	var after_hp: int = session.battle_state().creature(&"foe").current_hp
	check("real native Gem attack inflicts damage and consumes " + String(id),
		after_hp < before_hp and live.held_item_id == id and live.held_item_consumed)
	check("no premature campaign publication before settlement " + String(id),
		owner.inventory.quantity(id) == 1
		and owner.owned_creature(&"own").held_item_id == id
		and not owner.owned_creature(&"own").held_item_consumed)
	# Settlement is the authoritative game state boundary: battle-only spent
	# held item is not presumed persisted merely because a native log exists.
	check("real battle has reached settlement phase " + String(id),
		session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("real battle settlement publishes consumed item " + String(id),
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	check("live PlayerCollection spent flag published once " + String(id),
		owner.owned_creature(&"own").held_item_id == id
		and owner.owned_creature(&"own").held_item_consumed
		and owner.inventory.quantity(id) == 1
		and owner.owned_creature(&"reserve").held_item_id == &"")
	var after := _roundtrip(owner, String(id) + "_after_settlement")
	if after.valid:
		owner = after.owner
		check("full SaveV2 disk load preserves exactly one spent Gem " + String(id),
			owner.owned_creature(&"own").held_item_id == id
			and owner.owned_creature(&"own").held_item_consumed
			and owner.inventory.quantity(id) == 1 and _units(owner, id) == 1)
		var reconfigure := ItemService.new()
		check("existing real equip service reconfigures after disk restore " + String(id),
			reconfigure.configure(owner, catalogs, func(): return true))
		var unequipped: Dictionary = reconfigure.unequip(&"own")
		check("spent Gem cannot be refunded on unequip " + String(id),
			unequipped.get("accepted", false)
			and owner.inventory.quantity(id) == 1
			and owner.owned_creature(&"own").held_item_id == &""
			and _units(owner, id) == 1)
		var refitted: Dictionary = reconfigure.equip(id, &"own")
		check("fresh copy can be explicitly equipped without resurrecting spent copy " + String(id),
			refitted.get("accepted", false)
			and owner.inventory.quantity(id) == 0
			and owner.owned_creature(&"own").held_item_id == id
			and not owner.owned_creature(&"own").held_item_consumed
			and _units(owner, id) == 1)
		var final_save := _roundtrip(owner, String(id) + "_refitted")
		check("refitted last physical Gem persists exactly once " + String(id),
			final_save.valid and final_save.owner.inventory.quantity(id) == 0
			and final_save.owner.owned_creature(&"own").held_item_id == id
			and not final_save.owner.owned_creature(&"own").held_item_consumed)
	v3_real_settlements += 1
	await session.close()
	return {"valid": errors.size() == case_before and after.valid,
		"id": String(id), "family": String(entry.batch), "savev2": after.valid,
		"settled": settled.get("accepted", false), "original_sha": FileAccess.get_sha256(after.disk) if after.valid else ""}

func _rejections() -> void:
	var id := &"ghost_gem"
	var pre := _owner_with_gem(id, "shadow_ball", 1)
	var pc: PlayerCollection = pre.owner
	var svc: RefCounted = pre.service
	var original: String = JSON.stringify(_owner_data(pc))
	var foreign: Dictionary = svc.equip(id, &"not_our_creature")
	check("rejected foreign creature doesn't mutate inventory", not foreign.get("accepted", false)
		and foreign.get("reason") == "creature_not_owned"
		and JSON.stringify(_owner_data(pc)) == original)
	v3_rejected += 1
	var equip: Dictionary = svc.equip(id, &"own")
	check("one real item can be equipped and stock becomes zero", equip.get("accepted", false)
		and pc.inventory.quantity(id) == 0)
	var snapshot: String = JSON.stringify(_owner_data(pc))
	var repeat: Dictionary = svc.equip(id, &"own")
	check("duplicate equip rejected transactionally", not repeat.get("accepted", false)
		and repeat.get("reason") == "already_equipped"
		and JSON.stringify(_owner_data(pc)) == snapshot)
	v3_rejected += 1
	var missing: Dictionary = svc.equip(id, &"reserve")
	check("zero remaining inventory cannot equip to reserve", not missing.get("accepted", false)
		and missing.get("reason") == "item_not_owned"
		and JSON.stringify(_owner_data(pc)) == snapshot)
	v3_rejected += 1
	check("replacement inventory allows second item", pc.inventory.add(&"normal_gem", 1))
	var swapped: Dictionary = svc.equip(&"normal_gem", &"own")
	check("safe substitution returns old Gem without duplication", swapped.get("accepted", false)
		and pc.inventory.quantity(&"ghost_gem") == 1
		and pc.inventory.quantity(&"normal_gem") == 0
		and pc.owned_creature(&"own").held_item_id == &"normal_gem"
		and _units(pc, &"ghost_gem") == 1
		and _units(pc, &"normal_gem") == 1)
	v3_rejected += 1
	var again: Dictionary = svc.equip(id, &"own")
	check("replacing back restores same total number of physical units",
		again.get("accepted", false)
		and pc.inventory.quantity(id) == 0
		and pc.inventory.quantity(&"normal_gem") == 1
		and pc.owned_creature(&"own").held_item_id == id
		and _units(pc, &"ghost_gem") == 1
		and _units(pc, &"normal_gem") == 1)
	v3_rejected += 1

func _legacy() -> void:
	var a := _owner_with_gem(&"fairy_gem", "moonblast", 1)
	var owner: PlayerCollection = a.owner
	check("legacy probe FieldItemService equips real Fairy Gem",
		a.service.equip(&"fairy_gem", &"own").get("accepted", false))
	var consumed: CreatureInstance = owner.owned_creature(&"own")
	consumed.held_item_consumed = true # Construct a *legacy persisted* consumed record, not a simulated battle.
	var legacy: Dictionary = SaveGameData.build(owner.party, owner.storage, owner.inventory).to_dict()
	legacy["schema_version"] = 1
	legacy["format_id"] = "calvo_save_v1"
	legacy.erase("inventory")
	var raw: Dictionary = legacy.duplicate(true)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(legacy)
	check("legacy V1 migrates exactly and keeps original input immutable",
		decoded.ok and legacy == raw)
	if not decoded.ok:
		return
	var old: PlayerCollection = _loaded_owner(decoded)
	check("legacy cannot reconstruct phantom bag from previously consumed held Gem",
		old.inventory.quantity(&"fairy_gem") == 0
		and old.owned_creature(&"own").held_item_consumed
		and old.owned_creature(&"own").held_item_id == &"fairy_gem"
		and _units(old, &"fairy_gem") == 0)
	var service := ItemService.new()
	check("legacy migrated service configures", service.configure(old, catalogs, func(): return true))
	var una: Dictionary = service.unequip(&"own")
	check("legacy consumed Gem does not refund or get synthesized",
		una.get("accepted", false)
		and old.inventory.quantity(&"fairy_gem") == 0
		and old.owned_creature(&"own").held_item_id == &"")
	var modern := _roundtrip(old, "legacy_fairy_resave")
	check("legacy migrated file persists as V2 without phantom Gem",
		modern.valid and modern.owner.inventory.quantity(&"fairy_gem") == 0)
	v3_legacy += 1

func _run_autorun_v3() -> void:
	destination = V3_OUTPUT
	DirAccess.make_dir_recursive_absolute(destination)
	var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(V3_FIXTURE))
	check("TANDA03 fixture is canonical JSON", f is Dictionary)
	if not f is Dictionary:
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("TANDA03 canonical regional overlay loaded", Variants.apply(catalogs))
	check("TANDA03 schema and worker unchanged",
		f.get("kind") == "AUTORUN_V3_W01_L3_GEMS"
		and f.get("schema_version") == 1 and f.get("worker") == "W01"
		and f.get("tanda") == "03" and f.get("format") == "gen9calvounifiedv1")
	var entries: Array = f.get("items", [])
	check("18 distinct canonical Gem IDs across C005/T01/T02", entries.size() == 18)
	if entries.size() != 18:
		quit(2)
		return
	var seen_ids: Dictionary = {}
	var groups: Dictionary = {"C005": 0, "V1": 0, "V2": 0}
	for entry: Dictionary in entries:
		var id: String = String(entry.id)
		check("TANDA03 distinct item " + id, not seen_ids.has(id))
		seen_ids[id] = true
		check("TANDA03 only original certified Gems", groups.has(String(entry.batch)))
		groups[String(entry.batch)] = int(groups.get(String(entry.batch), 0)) + 1
		current_case = id + "/field_equip_battle_settle_save"
		var result: Dictionary = await _real_cycle(entry)
		v3_results.append(result)
		if result.get("valid", false):
			print("W01_V3_L3_ROW PASS id=", id, " batch=", entry.batch,
				" route=inventory_equip_battle_settle_save_v2")
		else:
			print("W01_V3_L3_ROW FAIL id=", id, " batch=", entry.batch)
	check("TANDA03 original three + T01 ten + T02 five groups preserved",
		groups == {"C005": 3, "V1": 10, "V2": 5})
	check("TANDA03 real FieldItemService equips cover 18", v3_real_equips == 18)
	check("TANDA03 real native settlement and SaveV2 cover 18", v3_real_settlements == 18)
	current_case = "T03_06_rejections"
	_rejections()
	check("TANDA03 negative transactional item cases", v3_rejected == 5)
	current_case = "T03_08_legacy"
	_legacy()
	check("TANDA03 V1 legacy migration with no phantom inventory", v3_legacy == 1)
	var report: Dictionary = {"schema_version": 1, "tanda": "03", "worker": "W01",
		"checks": checks, "errors": errors, "real_equips": v3_real_equips,
		"real_settlements": v3_real_settlements, "rejections": v3_rejected,
		"legacy": v3_legacy, "rows": v3_results, "groups": groups,
		"limitations": ["Headless real FieldItemService, FieldNativeSession and SaveGameRepository, not UI scene",
			"Capture/defeat/Transform and real map UI not certified by this runner",
			"18 are prior certified IDs, zero new item mechanics"]}
	var report_file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("TANDA03 evidence output writable", report_file != null)
	if report_file != null:
		report_file.store_string(JSON.stringify(report, "  "))
		report_file.close()
	done = true
	if errors.is_empty():
		print("W01_V3_GODOT PASS ids=", v3_real_settlements,
			" rejections=", v3_rejected, " legacy=", v3_legacy,
			" checks=", checks)
	else:
		print("W01_V3_GODOT FAIL ids=", v3_real_settlements, " errors=", errors.size(),
			" checks=", checks)
	quit(0 if errors.is_empty() else 1)
