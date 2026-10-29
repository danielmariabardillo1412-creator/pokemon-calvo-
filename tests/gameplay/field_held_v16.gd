extends "res://tests/gameplay/field_held_v14.gd"

const V16 := "res://.godot/field_held_v16/"
const MEDICINES: Array[StringName]=[&"antidote",&"awakening",&"burn_heal",&"elixir",&"energy_powder",&"energy_root",&"ether",&"fresh_water",&"full_heal",&"full_restore",&"heal_powder",&"hyper_potion",&"ice_heal",&"lava_cookie",&"lemonade",&"max_elixir",&"max_ether",&"max_potion",&"moomoo_milk",&"old_gateau",&"paralyze_heal",&"potion",&"soda_pop",&"super_potion"]

func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done:push_error("FIELD_HELD_V16 timeout");quit(2))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V16)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	if not capture:
		for i in MEDICINES.size():await _medicine_case(MEDICINES[i],["keep","fling","trick","knock_off"][i%4])
	for pair: Array in [["potion","keep"],["max_elixir","fling"],["full_heal","trick"],["energy_root","keep"]]:
		await _map_medicine(StringName(pair[0]),pair[1])
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors,"routes":routes,"gpu":capture}
	var file:=FileAccess.open(V16+("gpu.json" if capture else "godot.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("FIELD_HELD_V16 ",report.status," checks=",checks," GPU=",capture)
	quit(0 if errors.is_empty() else 1)

func _physical_medicine(owner: PlayerCollection,id: StringName) -> int:
	var count:=owner.inventory.quantity(id)
	for c: CreatureInstance in owner.party.get_creatures()+owner.storage.get_all_creatures():
		if c.held_item_id==id and not c.held_item_consumed:count+=1
	return count

func _medicine_case(id: StringName,route: String) -> void:
	var own:=_with_moves(&"medicine_own",["fling" if route=="fling" else "trick" if route=="trick" else "growl"],false)
	own.friendship=100
	var service:=_service(own,id);service.owner.inventory.add(&"master_ball")
	check("existing medicine use supported "+String(id),Effects.supports(id))
	check("real medicine equip "+String(id),service.equip(id,own.instance_id).accepted and _physical_medicine(service.owner,id)==3)
	var before:=snapshot(service)
	var foe:=_with_moves(&"medicine_foe",["knock_off" if route=="knock_off" else "growl"],false)
	var session:=Native.new(catalogs,service.owner,"gen9calvounifiedv1")
	var opened: bool=await session.begin_wild(self,foe,[23,19,29,43])
	check("equipped medicine starts native "+String(id)+": "+session.last_error,opened)
	if not opened:await session.close();return
	check("native receives exact ID without campaign writes",session.battle_state().creature(own.instance_id).held_item_id==id and snapshot(service)==before)
	var saved:=session.snapshot();await session.close();session=Native.new(catalogs,service.owner,"gen9calvounifiedv1")
	var restored: bool=await session.restore_saved(self,saved)
	check("medicine checkpoint restores "+String(id),restored)
	if not restored:await session.close();return
	var original:=session.snapshot()
	check("wrong revision cannot spend medicine",not (await session.submit("move 1",session.revision+1)).accepted and session.snapshot()==original)
	var result: Dictionary=await session.submit("move 1",session.revision)
	check("medicine turn projects "+String(id)+route,result.accepted and snapshot(service)==before)
	if not result.accepted:await session.close();return
	var active:=session.battle_state().creature(own.instance_id)
	check("medicine state follows native ownership",active.held_item_id==id and active.held_item_consumed==(route!="keep"))
	if route=="trick":
		var receiver:=session.battle_state().creature(foe.instance_id)
		check("Trick recipient has actual medicine",receiver.held_item_id==id and not receiver.held_item_consumed)
	var changed:=session.snapshot();await session.close();session=Native.new(catalogs,service.owner,"gen9calvounifiedv1")
	check("changed item state checkpoint restores",await session.restore_saved(self,changed))
	check("capture publishes medicine state",(await session.capture(&"master_ball",session.revision)).accepted)
	check("physical medicine count after settlement",_physical_medicine(service.owner,id)==(2 if route in ["fling","knock_off"] else 3))
	var quantity: int=service.owner.inventory.quantity(id)
	check("original slot unequips without phantom refund",service.unequip(own.instance_id).accepted and service.owner.inventory.quantity(id)==quantity+(1 if route=="keep" else 0))
	if route=="trick":check("captured receiver returns transferred unit",service.unequip(foe.instance_id).accepted)
	check("inventory equals physical units after unequips",service.owner.inventory.quantity(id)==(2 if route in ["fling","knock_off"] else 3))
	check("holding bitter medicine changes no friendship",service.owner.owned_creature(own.instance_id).friendship==100)
	routes.append({"medicine":String(id),"route":route,"physical_remaining":_physical_medicine(service.owner,id),"restored_after_item_change":true})
	await session.close()

func _map_medicine(id: StringName,route: String) -> void:
	scene=load("res://scenes/visual/field_demo.tscn").instantiate();root.add_child(scene)
	await process_frame;await physics_frame
	var config: Dictionary=scene._active_config.duplicate(true)
	config.encounter_chance_percent=100;config.wild_species_id="wailord";config.wild_min_level=50;config.wild_max_level=50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection=scene.field_collection();var own_id:=owner.party.get_creatures()[0].instance_id
	var c:=_with_moves(own_id,["growl","fling","trick"],false);c.friendship=100;c.current_hp=100;status(c,&"poison")
	check("map medicine owner",owner.replace_owned_same_identity(c))
	owner.inventory.add(id,3);owner.inventory.add(&"master_ball",2)
	var initial:=_physical_medicine(owner,id)
	check("map medicine bag opens",scene.toggle_item_bag());var bag=scene._item_bag
	_select(bag,String(id));check("map equips actual medicine",bag._apply("equip").accepted and _physical_medicine(owner,id)==initial)
	check("equip does not use the medicine",owner.owned_creature(own_id).current_hp==100 and owner.owned_creature(own_id).status_state.persistent_id==&"poison" and owner.owned_creature(own_id).friendship==100)
	if capture and id==&"potion":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		check("medicine bag screenshot",root.get_texture().get_image().save_png(V16+"medicine_bag.png")==OK)
		check("medicine bag fits viewport",bag.position.y>=0 and bag.position.y+bag.size.y<=root.size.y)
	bag.hide();await process_frame
	var bridge=scene._native_battles;bridge.save_path=V16+("gpu_" if capture else "headless_")+String(id)+".json"
	check("equipped medicine field save",bridge.save_game());check("equipped medicine field load",await bridge.load_game())
	scene.player.global_position=Vector2(420,150);await scene._on_player_step_completed(scene.player.global_position)
	var view=bridge.view;view._playback.set_process(false)
	var ready: bool=view.session!=null and view.session.battle_state()!=null
	check("map medicine enters battle: "+bridge.last_error,ready)
	if not ready:scene.queue_free();await process_frame;return
	var choice: String={"keep":"move 1","fling":"move 2","trick":"move 3"}[route]
	var result: Dictionary=await view.choose(choice);check("map medicine action "+String(id),result.accepted)
	if not result.accepted:await view.session.close();scene.queue_free();await process_frame;return
	await _drain_view(view)
	check("medicine changed-state save",bridge.save_game())
	var loaded: bool=await bridge.load_game();check("medicine changed-state load: "+bridge.last_error,loaded)
	if not loaded:await view.session.close();scene.queue_free();await process_frame;return
	view._playback.set_process(false)
	check("medicine encounter capture",(await view.adventure_command("master")).accepted)
	await _drain_view(view);await bridge.leave_battle()
	owner=scene.field_collection()
	var expected:=initial-(1 if route=="fling" else 0)
	check("map physical medicine count",_physical_medicine(owner,id)==expected)
	check("held medicine does not apply friendship penalty",owner.owned_creature(own_id).friendship==100)
	# A separate explicit use from the bag still invokes the existing field service.
	check("post-combat medicine bag opens",scene.toggle_item_bag());bag=scene._item_bag
	_select(bag,String(id));var before:=owner.owned_creature(own_id).to_dict()
	check("explicit medicine use still succeeds",bag._apply("use").accepted)
	var after:=owner.owned_creature(own_id)
	if id==&"potion":check("Potion field effect stays 20 HP",after.current_hp==mini(after.stats.max_hp,int(before.current_hp)+20))
	if id==&"energy_root":check("Energy Root field heal and bitterness stay separate",after.current_hp==mini(after.stats.max_hp,int(before.current_hp)+120) and after.friendship==90)
	if id==&"full_heal":check("Full Heal explicit use cures actor",after.status_state.persistent_id==&"" and after.friendship==100)
	if id==&"max_elixir":
		var restored_pp:=true
		for slot: BattleMoveSlot in after.moveset:restored_pp=restored_pp and slot.current_pp==slot.max_pp
		check("Max Elixir explicit use restores all PP",restored_pp)
	check("explicit use spends exactly one additional physical unit",_physical_medicine(owner,id)==expected-1)
	bag.hide();await process_frame
	check("final medicine field save",bridge.save_game());check("final medicine field load",await bridge.load_game())
	check("final medicine persistence",_physical_medicine(scene.field_collection(),id)==expected-1 and scene.field_collection().owned_creature(own_id).friendship==(90 if id==&"energy_root" else 100))
	routes.append({"medicine":String(id),"route":"map_"+route,"explicit_field_use":true,"physical_remaining":expected-1})
	if view.session!=null:await view.session.close()
	scene.queue_free();await process_frame
