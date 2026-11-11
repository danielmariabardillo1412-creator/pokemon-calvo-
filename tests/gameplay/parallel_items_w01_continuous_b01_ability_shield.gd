extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 continuous B01/01: equip real held Ability Shield; live Showdown
# Gastro Acid block event; settle and SaveV2. No global ability rule changed.
const SHIELD_OUT := "res://.godot/parallel_items/w01_continuous_b01_ability_shield"
var shield_results: Array = []
var shield_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_shield")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("W01 B01 Ability Shield L3 watchdog")
			quit(2))

func _shield_case(mode: String) -> Dictionary:
	var before_errors: int = errors.size()
	var player := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["reflect", "psychic"])
	var bench := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.ability_id = &"synchronize"
	bench.ability_id = &"synchronize"
	check("Ability Shield genuine party " + mode,
		player.party.add_creature(own) and player.party.add_creature(bench))
	check("Ability Shield genuine bag item " + mode,
		player.inventory.add(&"ability_shield", 1))
	var service := ItemService.new()
	check("Ability Shield field holdability " + mode,
		service.configure(player, catalogs, func(): return true)
		and service.holdable(&"ability_shield"))
	if mode != "none":
		var recipient: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Ability Shield equip from bag to owner " + mode,
			service.equip(&"ability_shield", recipient).get("accepted", false)
			and player.inventory.quantity(&"ability_shield") == 0)
	var pre := _roundtrip(player, "b01_shield_" + mode + "_pre")
	if not pre.valid: return {"valid": false}
	player = pre.owner
	var foe := _mon(&"mew", 100, &"foe", ["amnesia" if mode == "neutral" else "gastro_acid"])
	foe.ability_id = &"synchronize"
	foe.current_hp = 70
	var session := FieldSession.new(catalogs, player, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Ability Shield real wild battle opens " + mode, opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Ability Shield real Gastro Acid turn accepted " + mode, first.get("accepted", false))
	var blocked: bool = false
	for event in first.get("events", []):
		if event is BattleEvent and event.kind == BattleEvent.ITEM_TRIGGERED:
			if String(event.metadata.get("item_id", "")) == "ability_shield" and String(event.metadata.get("reason", "")) == "ability_protected":
				blocked = true
	check("Ability Shield actual native translated ITEM_TRIGGERED block " + mode,
		blocked == (mode == "active"))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	check("Ability Shield live owner and ability persist " + mode,
		live.held_item_id == (&"ability_shield" if mode == "active" or mode == "neutral" else &"")
		and live.ability_id == &"synchronize"
		and not live.held_item_consumed
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"ability_shield" if mode == "reserve" else &""))
	var steps: int = 0
	while session.phase() != "finished" and steps < 8:
		var reply: Dictionary = await session.submit("move 2", session.revision)
		check("Ability Shield actual finishing attack " + mode,
			reply.get("accepted", false))
		steps += 1
	check("Ability Shield battle ends by victory " + mode, session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Ability Shield actual settlement completes " + mode,
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var saved := _roundtrip(player, "b01_shield_" + mode + "_post")
	if saved.valid:
		check("Ability Shield SaveV2 no duplicate or consumed item " + mode,
			saved.owner.inventory.quantity(&"ability_shield") == (1 if mode == "none" else 0)
			and saved.owner.owned_creature(&"own").held_item_id ==
				(&"ability_shield" if mode == "active" or mode == "neutral" else &"")
			and saved.owner.owned_creature(&"reserve").held_item_id ==
				(&"ability_shield" if mode == "reserve" else &"")
			and not saved.owner.owned_creature(&"own").held_item_consumed
			and not saved.owner.owned_creature(&"reserve").held_item_consumed)
	await session.close()
	return {"mode":mode,"blocked":blocked,
		"valid":errors.size() == before_errors and saved.valid}

func _run_shield() -> void:
	destination = SHIELD_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Ability Shield canonical catalog and forms", Variants.apply(catalogs))
	for mode in ["active","none","reserve","neutral"]:
		current_case = "W01_B01_01_shield_" + mode
		var row: Dictionary = await _shield_case(mode)
		shield_results.append(row)
		if row.get("valid", false): shield_passes += 1
	check("Ability Shield 4 real field scenarios", shield_passes == 4)
	var f: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Ability Shield evidence file writable", f != null)
	if f != null:
		f.store_string(JSON.stringify({"block":"B01","row":"01","item":"ability_shield",
			"checks":checks,"rows":shield_results,"errors":errors},"  "))
		f.close()
	done = true
	if errors.is_empty() and shield_passes == 4:
		print("W01_B01_L3_ROW PASS row=01 id=ability_shield modes=4 checks=", checks)
		quit(0)
	else:
		print("W01_B01_L3_ROW FAIL row=01 id=ability_shield modes=", shield_passes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
