extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 B01/04 Big Root L3: authentic native Absorb with fixed foe and true SaveV2.
const ROOT_OUT := "res://.godot/parallel_items/w01_continuous_b01_big_root"
var root_rows: Array = []
var root_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_root")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("Big Root L3 watchdog")
			quit(2))

func _root_trial(mode: String) -> Dictionary:
	var count_before: int = errors.size()
	var active: bool = mode == "active" or mode == "no_drain"
	var player := PlayerCollection.new()
	var own := _mon(&"mew", 100, &"own",
		["tackle", "psychic"] if mode == "no_drain" else ["absorb", "psychic"])
	var bench := _mon(&"mew", 100, &"reserve", ["reflect"])
	own.current_hp = 120
	check("Big Root actual party",
		player.party.add_creature(own) and player.party.add_creature(bench))
	check("Big Root actual bag stock", player.inventory.add(&"big_root", 1))
	var service := ItemService.new()
	check("Big Root selected equipment route",
		service.configure(player, catalogs, func(): return true)
		and service.holdable(&"big_root"))
	if mode != "none":
		var recipient: StringName = &"reserve" if mode == "reserve" else &"own"
		check("Big Root real field equip",
			service.equip(&"big_root", recipient).get("accepted", false)
			and player.inventory.quantity(&"big_root") == 0)
	var pre := _roundtrip(player, "b01_bigroot_" + mode + "_pre")
	if not pre.valid: return {"valid":false}
	player = pre.owner
	var foe := _mon(&"swampert", 100, &"foe", ["growl"])
	foe.current_hp = 200
	var session := FieldSession.new(catalogs, player, {}, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [19, 2, 3, 4])
	check("Big Root field native battle opens", opened)
	if not opened:
		await session.close()
		return {"valid":false}
	var actor_hp: int = session.battle_state().creature(&"own").current_hp
	var foe_hp: int = session.battle_state().creature(&"foe").current_hp
	var first: Dictionary = await session.submit("move 1",session.revision)
	check("Big Root real damaging first move",first.get("accepted",false))
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var healing: int = live.current_hp - actor_hp
	var damaged: int = foe_hp - session.battle_state().creature(&"foe").current_hp
	check("Big Root first move actually damages",damaged>0)
	check("Big Root positive drain or non-drain negative",
		(healing==0 if mode=="no_drain" else healing>0))
	check("Big Root owner and nonconsumable flag",
		live.held_item_id == (&"big_root" if active else &"")
		and not live.held_item_consumed
		and session.battle_state().creature(&"reserve").held_item_id ==
			(&"big_root" if mode=="reserve" else &""))
	var steps: int=0
	while session.phase()!="finished" and steps<9:
		var turn:Dictionary=await session.submit("move 2",session.revision)
		check("Big Root native ending turn",turn.get("accepted",false))
		steps+=1
	check("Big Root real natural victory",session.phase()=="finished")
	var settled:Dictionary=session.settle_finished_battle()
	check("Big Root real encounter settlement",
		settled.get("accepted",false) and session.completion_reason=="VICTORY")
	var post:=_roundtrip(player,"b01_bigroot_"+mode+"_post")
	if post.valid:
		check("Big Root SaveV2 real nonconsumable ownership",
			post.owner.inventory.quantity(&"big_root")==(1 if mode=="none" else 0)
			and post.owner.owned_creature(&"own").held_item_id ==
				(&"big_root" if active else &"")
			and not post.owner.owned_creature(&"own").held_item_consumed
			and post.owner.owned_creature(&"reserve").held_item_id ==
				(&"big_root" if mode=="reserve" else &""))
	await session.close()
	return {"mode":mode,"valid":errors.size()==count_before and post.valid,
		"damaged":damaged,"healed":healing}

func _run_root() -> void:
	destination=ROOT_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Big Root canonical catalog",Variants.apply(catalogs))
	for mode in ["active","none","reserve","no_drain"]:
		current_case="W01_B01_04_bigroot_"+mode
		var row:Dictionary=await _root_trial(mode)
		root_rows.append(row)
		if row.get("valid",false):root_passes+=1
	check("Big Root four true L3 modes",root_passes==4)
	if root_rows.size()==4:
		check("Big Root active actually boosts drain healing",
			int(root_rows[0].healed)>int(root_rows[1].healed)
			and int(root_rows[1].healed)==int(root_rows[2].healed)
			and int(root_rows[3].healed)==0)
		check("Big Root changes healing not attack power",
			int(root_rows[0].damaged)==int(root_rows[1].damaged)
			and int(root_rows[1].damaged)==int(root_rows[2].damaged))
	var f:FileAccess=FileAccess.open(destination+"/report.json",FileAccess.WRITE)
	check("Big Root evidence writable",f!=null)
	if f!=null:
		f.store_string(JSON.stringify({"row":"04","id":"big_root",
			"checks":checks,"rows":root_rows,"errors":errors},"  "))
		f.close()
	done=true
	if errors.is_empty() and root_passes==4:
		print("W01_B01_L3_ROW PASS row=04 id=big_root modes=4 checks=",checks)
		quit(0)
	else:
		print("W01_B01_L3_ROW FAIL row=04 id=big_root modes=",root_passes,
			" errors=",errors.size()," checks=",checks)
		quit(1)
