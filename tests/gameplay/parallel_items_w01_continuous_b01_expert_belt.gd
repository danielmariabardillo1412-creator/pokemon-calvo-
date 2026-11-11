extends "res://tests/gameplay/parallel_items_w01_autorun_v3.gd"

# W01 CONTINUOUS_V2 B01/05 Expert Belt already native; complete L3 field path.
const BELT_OUT := "res://.godot/parallel_items/w01_continuous_b01_expert_belt"
var belt_rows: Array = []
var belt_passes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_belt")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("Expert Belt L3 watchdog")
			quit(2))

func _belt_case(mode: String) -> Dictionary:
	var start_errors: int=errors.size()
	var neutral: bool=mode.begins_with("neutral")
	var active: bool=mode.ends_with("active")
	var reserve: bool=mode=="super_reserve"
	var owner:=PlayerCollection.new()
	var own:=_mon(&"mew",100,&"own",["tackle","psychic"] if neutral else ["thunder_shock","psychic"])
	var bench:=_mon(&"mew",100,&"reserve",["reflect"])
	check("Expert Belt authentic party",owner.party.add_creature(own) and owner.party.add_creature(bench))
	check("Expert Belt bag one physical unit",owner.inventory.add(&"expert_belt",1))
	var service:=ItemService.new()
	check("Expert Belt selected field holdability",
		service.configure(owner,catalogs,func():return true)
		and service.holdable(&"expert_belt"))
	if active or reserve:
		check("Expert Belt genuine equip",
			service.equip(&"expert_belt",&"own" if active else &"reserve").get("accepted",false)
			and owner.inventory.quantity(&"expert_belt")==0)
	var pre:=_roundtrip(owner,"b01_belt_"+mode+"_pre")
	if not pre.valid:return {"valid":false}
	owner=pre.owner
	var foe:=_mon(&"gyarados",100,&"foe",["tackle"])
	foe.current_hp=300
	var session:=FieldSession.new(catalogs,owner,{},"gen9calvounifiedv1")
	var opened:bool=await session.begin_wild(self,foe,[19,2,3,4])
	check("Expert Belt actual native field session",opened)
	if not opened:
		await session.close()
		return {"valid":false}
	var foe_before:int=session.battle_state().creature(&"foe").current_hp
	var first:Dictionary=await session.submit("move 1",session.revision)
	check("Expert Belt native damaging move accepted",first.get("accepted",false))
	var remaining:int=session.battle_state().creature(&"foe").current_hp
	var damaged:int=foe_before-remaining
	check("Expert Belt actual move damages without early knockout",damaged>0 and remaining>0)
	var live:CreatureInstance=session.battle_state().creature(&"own")
	check("Expert Belt true owner and nonconsumption",
		live.held_item_id==(&"expert_belt" if active else &"")
		and not live.held_item_consumed
		and session.battle_state().creature(&"reserve").held_item_id==
			(&"expert_belt" if reserve else &""))
	var turns:int=0
	while session.phase()!="finished" and turns<9:
		var turn:Dictionary=await session.submit("move 2",session.revision)
		check("Expert Belt natural battle finisher",turn.get("accepted",false))
		turns+=1
	check("Expert Belt true victory",session.phase()=="finished")
	var settled:Dictionary=session.settle_finished_battle()
	check("Expert Belt genuine settlement",
		settled.get("accepted",false) and session.completion_reason=="VICTORY")
	var saved:=_roundtrip(owner,"b01_belt_"+mode+"_post")
	if saved.valid:
		check("Expert Belt SaveV2 owner/item stock never duplicated",
			saved.owner.inventory.quantity(&"expert_belt")== (1 if not active and not reserve else 0)
			and saved.owner.owned_creature(&"own").held_item_id==(&"expert_belt" if active else &"")
			and saved.owner.owned_creature(&"reserve").held_item_id==(&"expert_belt" if reserve else &"")
			and not saved.owner.owned_creature(&"own").held_item_consumed
			and not saved.owner.owned_creature(&"reserve").held_item_consumed)
	await session.close()
	return {"mode":mode,"valid":errors.size()==start_errors and saved.valid,"damaged":damaged}

func _run_belt() -> void:
	destination=BELT_OUT
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("Expert Belt canonical catalog",Variants.apply(catalogs))
	for mode in ["super_active","super_none","super_reserve","neutral_active","neutral_none"]:
		current_case="W01_B01_05_expertbelt_"+mode
		var row:Dictionary=await _belt_case(mode)
		belt_rows.append(row)
		if row.get("valid",false):belt_passes+=1
	check("Expert Belt five real field sessions",belt_passes==5)
	if belt_rows.size()==5:
		check("Expert Belt real super-effective boost only for active owner",
			int(belt_rows[0].damaged)>int(belt_rows[1].damaged)
			and int(belt_rows[1].damaged)==int(belt_rows[2].damaged))
		check("Expert Belt no neutral damage boost",
			int(belt_rows[3].damaged)==int(belt_rows[4].damaged))
	var f:FileAccess=FileAccess.open(destination+"/report.json",FileAccess.WRITE)
	check("Expert Belt evidence output",f!=null)
	if f!=null:
		f.store_string(JSON.stringify({"block":"B01","row":"05","id":"expert_belt",
			"rows":belt_rows,"checks":checks,"errors":errors},"  "))
		f.close()
	done=true
	if errors.is_empty() and belt_passes==5:
		print("W01_B01_L3_ROW PASS row=05 id=expert_belt modes=5 checks=",checks)
		quit(0)
	else:
		print("W01_B01_L3_ROW FAIL row=05 id=expert_belt modes=",belt_passes,
			" errors=",errors.size()," checks=",checks)
		quit(1)
