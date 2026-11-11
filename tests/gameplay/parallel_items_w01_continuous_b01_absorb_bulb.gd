extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 B01/02. Real FieldItemService -> battle Water hit -> +1 Special Attack
# and consumable held Bulb -> settlement -> disk SaveV2.
const BULB_OUT := "res://.godot/parallel_items/w01_continuous_b01_absorb_bulb"
var bulb_rows: Array = []
var bulb_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_bulb")
	create_timer(850.0).timeout.connect(func():
		if not done:
			push_error("Absorb Bulb B01 L3 watchdog")
			quit(2))

func _bulb_trial(mode: String) -> Dictionary:
	var before_errors: int = errors.size()
	var active: bool = mode == "active" or mode == "nonwater"
	var triggered: bool = mode == "active"
	var player := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own", ["reflect", "psychic"])
	var reserve := _mon(&"mew", 100, &"reserve", ["reflect"])
	check("Absorb Bulb owned party", player.party.add_creature(own)
		and player.party.add_creature(reserve))
	check("Absorb Bulb physical inventory", player.inventory.add(&"absorb_bulb", 1))
	var service := ItemService.new()
	check("Absorb Bulb selected holdability",
		service.configure(player, catalogs, func(): return true)
		and service.holdable(&"absorb_bulb"))
	if mode != "none":
		var target: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Absorb Bulb genuine equip",
			service.equip(&"absorb_bulb", target).get("accepted", false)
			and player.inventory.quantity(&"absorb_bulb") == 0)
	var pre := _roundtrip(player, "b01_bulb_" + mode + "_pre")
	if not pre.valid: return {"valid": false}
	player = pre.owner
	var foe := _mon(&"mew", 20, &"foe", ["tackle" if mode == "nonwater" else "water_gun"])
	foe.current_hp = 70
	var session := FieldSession.new(catalogs, player, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Absorb Bulb real native wild encounter", opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var old_hp: int = session.battle_state().creature(&"own").current_hp
	var first: Dictionary = await session.submit("move 1", session.revision)
	check("Absorb Bulb native first turn accepted", first.get("accepted", false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	check("Absorb Bulb foe must actually inflict damage", live.current_hp < old_hp)
	check("Absorb Bulb native +1 SpA only after Water hit",
		live.stat_stages.get_stage(&"special_attack") == (1 if triggered else 0))
	check("Absorb Bulb spent flag and owner correct",
		live.held_item_id == (&"absorb_bulb" if active else &"")
		and live.held_item_consumed == triggered
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"absorb_bulb" if mode == "reserve" else &"")
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	var before_campaign: CreatureInstance = player.owned_creature(&"own")
	check("Absorb Bulb no premature campaign mutation",
		before_campaign.stat_stages.get_stage(&"special_attack") == 0
		and not before_campaign.held_item_consumed)
	var steps: int = 0
	while session.phase() != "finished" and steps < 6:
		var next: Dictionary = await session.submit("move 2", session.revision)
		check("Absorb Bulb natural victory turn", next.get("accepted", false))
		steps += 1
	check("Absorb Bulb natural victory", session.phase() == "finished")
	var settled: Dictionary = session.settle_finished_battle()
	check("Absorb Bulb authoritative settlement",
		settled.get("accepted", false) and session.completion_reason == "VICTORY")
	var saved := _roundtrip(player, "b01_bulb_" + mode + "_post")
	if saved.valid:
		var restored: CreatureInstance = saved.owner.owned_creature(&"own")
		var restored_reserve: CreatureInstance = saved.owner.owned_creature(&"reserve")
		check("Absorb Bulb SaveV2 retains spent flag but clears battle-only boost",
			saved.owner.inventory.quantity(&"absorb_bulb") == (1 if mode == "none" else 0)
			and restored.held_item_id == (&"absorb_bulb" if active else &"")
			and restored.held_item_consumed == triggered
			and restored.stat_stages.get_stage(&"special_attack") == 0
			and restored_reserve.held_item_id ==
				(&"absorb_bulb" if mode == "reserve" else &"")
			and not restored_reserve.held_item_consumed)
	await session.close()
	return {"mode":mode,"triggered":triggered,"valid":errors.size() == before_errors and saved.valid}

func _run_bulb() -> void:
	destination = BULB_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Absorb Bulb canonical variants", Variants.apply(catalogs))
	for mode in ["active","none","reserve","nonwater"]:
		current_case = "W01_B01_02_bulb_" + mode
		var row: Dictionary = await _bulb_trial(mode)
		bulb_rows.append(row)
		if row.get("valid", false): bulb_passes += 1
	check("Absorb Bulb four real L3 trials", bulb_passes == 4)
	var f: FileAccess = FileAccess.open(destination + "/report.json", FileAccess.WRITE)
	check("Absorb Bulb evidence output", f != null)
	if f != null:
		f.store_string(JSON.stringify({"block":"B01","id":"absorb_bulb",
			"checks":checks,"rows":bulb_rows,"errors":errors},"  "))
		f.close()
	done = true
	if errors.is_empty() and bulb_passes == 4:
		print("W01_B01_L3_ROW PASS row=02 id=absorb_bulb modes=4 checks=", checks)
		quit(0)
	else:
		print("W01_B01_L3_ROW FAIL row=02 id=absorb_bulb modes=", bulb_passes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
