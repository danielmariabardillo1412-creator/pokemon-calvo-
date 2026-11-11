extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 B02/10 Meadow Plate damage only; NO Arceus form logic.
const MEADOW_OUT := "res://.godot/parallel_items/w01_continuous_b02_meadow_plate"
var meadow_results: Array = []
var meadow_passes: int = 0

func _initialize() -> void:
	capture=false
	call_deferred("_run_meadow")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("W01 Meadow Plate L3 watchdog")
			quit(2))

func _meadow_trial(mode:String)->Dictionary:
	var before_errors:int=errors.size()
	var active:bool=mode.begins_with("active")
	var reserve:bool=mode.begins_with("reserve")
	var grass:bool=mode.ends_with("grass")
	var owner:=PlayerCollection.new()
	var own:=_mon(&"mew",100,&"own",["energy_ball","psychic"] if grass else ["tackle","psychic"])
	var bench:=_mon(&"mew",100,&"reserve",["reflect"])
	check("Meadow Plate owned party",owner.party.add_creature(own) and owner.party.add_creature(bench))
	check("Meadow Plate actual bag one unit",owner.inventory.add(&"meadow_plate",1))
	var service:=ItemService.new()
	check("Meadow Plate selected equipment policy",
		service.configure(owner,catalogs,func():return true)
		and service.holdable(&"meadow_plate"))
	if active or reserve:
		check("Meadow Plate real equip",
			service.equip(&"meadow_plate",&"own" if active else &"reserve").get("accepted",false)
			and owner.inventory.quantity(&"meadow_plate")==0)
	var pre:=_roundtrip(owner,"b02_meadow_"+mode+"_pre")
	if not pre.valid:return {"valid":false}
	owner=pre.owner
	var foe:=_mon(&"mew",100,&"foe",["tackle"])
	foe.current_hp=250
	var session:=FieldSession.new(catalogs,owner,{},"gen9calvounifiedv1")
	var opened:bool=await session.begin_wild(self,foe,[19,2,3,4])
	check("Meadow Plate field native battle starts",opened)
	if not opened:
		await session.close()
		return {"valid":false}
	var foe_before:int=session.battle_state().creature(&"foe").current_hp
	var first:Dictionary=await session.submit("move 1",session.revision)
	check("Meadow Plate real attack accepted",first.get("accepted",false))
	var foe_after:int=session.battle_state().creature(&"foe").current_hp
	var dealt:int=foe_before-foe_after
	check("Meadow Plate true hit without early faint",dealt>0 and foe_after>0)
	var own_live:CreatureInstance=session.battle_state().creature(&"own")
	check("Meadow Plate type boost leaves species and owner unchanged",
		own_live.species_id==&"mew"
		and own_live.held_item_id==(&"meadow_plate" if active else &"")
		and not own_live.held_item_consumed
		and session.battle_state().creature(&"reserve").held_item_id==
			(&"meadow_plate" if reserve else &""))
	var turns:int=0
	while session.phase()!="finished" and turns<8:
		var turn:Dictionary=await session.submit("move 2",session.revision)
		check("Meadow Plate actual battle finisher",turn.get("accepted",false))
		turns+=1
	check("Meadow Plate actual wild victory",session.phase()=="finished")
	var settled:Dictionary=session.settle_finished_battle()
	check("Meadow Plate authoritative settlement",
		settled.get("accepted",false) and session.completion_reason=="VICTORY")
	var post:=_roundtrip(owner,"b02_meadow_"+mode+"_post")
	if post.valid:
		check("Meadow Plate SaveV2 unchanged Mew species and nonconsumable item",
			post.owner.inventory.quantity(&"meadow_plate")==(1 if not active and not reserve else 0)
			and post.owner.owned_creature(&"own").species_id==&"mew"
			and post.owner.owned_creature(&"own").held_item_id==(&"meadow_plate" if active else &"")
			and not post.owner.owned_creature(&"own").held_item_consumed
			and post.owner.owned_creature(&"reserve").held_item_id==(&"meadow_plate" if reserve else &""))
	await session.close()
	return {"mode":mode,"valid":errors.size()==before_errors and post.valid,"dealt":dealt}

func _run_meadow()->void:
	destination=MEADOW_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Meadow Plate canonical catalog",Variants.apply(catalogs))
	for mode in ["active_grass","none_grass","reserve_grass","active_wrong","none_wrong"]:
		current_case="W01_B02_10_meadow_"+mode
		var row:Dictionary=await _meadow_trial(mode)
		meadow_results.append(row)
		if row.get("valid",false):meadow_passes+=1
	check("Meadow Plate five real L3 scenarios",meadow_passes==5)
	if meadow_results.size()==5:
		check("Meadow Plate boosts only Grass-type damage when held by attacker",
			int(meadow_results[0].dealt)>int(meadow_results[1].dealt)
			and int(meadow_results[1].dealt)==int(meadow_results[2].dealt))
		check("Meadow Plate wrong-type Tackle gets no benefit",
			int(meadow_results[3].dealt)==int(meadow_results[4].dealt))
	var f:FileAccess=FileAccess.open(destination+"/report.json",FileAccess.WRITE)
	check("Meadow Plate evidence output",f!=null)
	if f!=null:
		f.store_string(JSON.stringify({"block":"B02","row":"18",
			"cases":meadow_results,"checks":checks,"errors":errors},"  "))
		f.close()
	done=true
	if errors.is_empty() and meadow_passes==5:
		print("W01_B02_L3_ROW PASS row=18 id=meadow_plate modes=5 checks=",checks)
		quit(0)
	else:
		print("W01_B02_L3_ROW FAIL row=18 id=meadow_plate modes=",meadow_passes,
			" errors=",errors.size()," checks=",checks)
		quit(1)
