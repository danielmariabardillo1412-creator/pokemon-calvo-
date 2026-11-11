extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 T04/10: test the held Sitrus Berry, NOT the W02 field medicine action.
const SITRUS_OUT := "res://.godot/parallel_items/w01_v4_sitrus_berry"
var sitrus_rows: Array = []
var sitrus_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_sitrus")
	create_timer(850.0).timeout.connect(func():
		if not done:
			push_error("W01 Sitrus Berry L3 timeout")
			quit(2))

func _one_sitrus(entry: Dictionary) -> Dictionary:
	var name: String = String(entry.name)
	var mode: String = String(entry.mode)
	var hp_setting: int = int(entry.hp)
	var should_consume: bool = bool(entry.consume)
	var errors_before: int = errors.size()
	var owner := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["reflect", "tackle"])
	var bench := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.current_hp = own.stats.max_hp if hp_setting == -1 else hp_setting
	var max_hp: int = own.stats.max_hp
	check("Sitrus genuine threshold test uses canonical max HP " + name,
		max_hp >= 340)
	if name == "active_at_half":
		check("Sitrus exact half HP boundary", hp_setting == max_hp / 2)
	if name == "active_above_half":
		check("Sitrus exact above-half HP boundary", hp_setting == int(max_hp / 2) + 1)
	check("Sitrus authentic owned party " + name,
		owner.party.add_creature(own) and owner.party.add_creature(bench))
	check("Sitrus authentic physical inventory " + name,
		owner.inventory.add(&"sitrus_berry", 1))
	var service := ItemService.new()
	check("Sitrus held FieldItemService configure " + name,
		service.configure(owner, catalogs, func(): return true)
		and service.holdable(&"sitrus_berry"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Sitrus real bag equip " + name,
			service.equip(&"sitrus_berry", target).get("accepted", false)
			and owner.inventory.quantity(&"sitrus_berry") == 0)
	var pre := _roundtrip(owner, "sitrus_" + name + "_pre")
	if not pre.valid: return {"valid": false}
	owner = pre.owner
	var start_hp: int = owner.owned_creature(&"own").current_hp
	var foe := _mon(&"caterpie", 1, &"foe", ["growl"])
	var session := FieldSession.new(catalogs, owner, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Sitrus genuine native field encounter begins " + name, opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var initial: Dictionary = await session.submit("move 1", session.revision)
	check("Sitrus genuine first turn processed " + name, initial.get("accepted", false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var after_hp: int = live.current_hp
	var expected_hp: int = start_hp + (maxi(1, int(max_hp / 4)) if should_consume else 0)
	check("Sitrus authentic quarter-HP recovery and no early activation " + name,
		after_hp == expected_hp)
	check("Sitrus consumed precisely once and original holder stays stable " + name,
		live.held_item_id == (&"sitrus_berry" if mode == "active" else &"")
		and live.held_item_consumed == should_consume
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"sitrus_berry" if mode == "reserve" else &"")
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("Sitrus no premature mutation of campaign outside battle " + name,
		owner.owned_creature(&"own").current_hp == start_hp
		and not owner.owned_creature(&"own").held_item_consumed)
	var finished: Dictionary = await session.submit("move 2", session.revision)
	check("Sitrus actual finishing blow accepted " + name, finished.get("accepted", false))
	check("Sitrus genuine wild victory " + name, session.phase() == "finished")
	check("Sitrus no second activation when finishing turn " + name,
		session.battle_state().creature(&"own").current_hp == after_hp
		and session.battle_state().creature(&"own").held_item_consumed == should_consume)
	var settled: Dictionary = session.settle_finished_battle()
	check("Sitrus authoritative native settlement " + name,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var saved := _roundtrip(owner, "sitrus_" + name + "_post")
	if saved.valid:
		var own_post: CreatureInstance = saved.owner.owned_creature(&"own")
		var bench_post: CreatureInstance = saved.owner.owned_creature(&"reserve")
		check("Sitrus full SaveV2 identity and stock without ghosts " + name,
			saved.owner.inventory.quantity(&"sitrus_berry") == (1 if mode == "none" else 0)
			and own_post.held_item_id == (&"sitrus_berry" if mode == "active" else &"")
			and own_post.held_item_consumed == should_consume
			and bench_post.held_item_id == (&"sitrus_berry" if mode == "reserve" else &"")
			and not bench_post.held_item_consumed
			and own_post.current_hp == after_hp)
		if should_consume:
			var after_service := ItemService.new()
			check("Sitrus new FieldItemService binds loaded owner", after_service.configure(
				saved.owner, catalogs, func(): return true))
			var remove_spent: Dictionary = after_service.unequip(&"own")
			check("Sitrus consumed Berry cannot return phantom unit to backpack",
				remove_spent.get("accepted", false)
				and saved.owner.inventory.quantity(&"sitrus_berry") == 0
				and saved.owner.owned_creature(&"own").held_item_id == &"")
			var second_save := _roundtrip(saved.owner, "sitrus_" + name + "_unequipped")
			check("Sitrus spent unequip remains zero after SaveV2",
				second_save.valid and second_save.owner.inventory.quantity(&"sitrus_berry") == 0)
	await session.close()
	return {"valid": errors.size() == errors_before and saved.valid,
		"name": name, "mode": mode, "consume": should_consume,
		"before_hp": start_hp, "after_hp": after_hp}

func _run_sitrus() -> void:
	destination = SITRUS_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Sitrus canonical variants loaded", Variants.apply(catalogs))
	var scenarios: Array = [
		{"name":"active_low","mode":"active","hp":120,"consume":true},
		{"name":"active_at_half","mode":"active","hp":170,"consume":true},
		{"name":"active_above_half","mode":"active","hp":171,"consume":false},
		{"name":"active_full","mode":"active","hp":-1,"consume":false},
		{"name":"none_low","mode":"none","hp":120,"consume":false},
		{"name":"reserve_low","mode":"reserve","hp":120,"consume":false}]
	for entry: Dictionary in scenarios:
		current_case = "T04_10_sitrus_" + String(entry.name)
		var result: Dictionary = await _one_sitrus(entry)
		sitrus_rows.append(result)
		if result.get("valid", false): sitrus_passes += 1
	check("Sitrus six true L3 routes including 50pct boundary", sitrus_passes == 6)
	var file: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Sitrus evidence output", file != null)
	if file != null:
		file.store_string(JSON.stringify({"worker":"W01","row":"10",
			"rows":sitrus_rows,"checks":checks,"errors":errors}, "  "))
		file.close()
	done = true
	if errors.is_empty() and sitrus_passes == 6:
		print("W01_V4_L3_ROW PASS row=10 id=sitrus_berry modes=6 checks=", checks)
		quit(0)
	else:
		print("W01_V4_L3_ROW FAIL row=10 id=sitrus_berry modes=", sitrus_passes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
