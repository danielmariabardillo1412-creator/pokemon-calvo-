extends "res://tests/gameplay/item_mochi_v13.gd"

const V14 := "res://.godot/field_held_v14/"
var routes: Array = []

func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done: push_error("FIELD_HELD_V14 timeout"); quit(2))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V14)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	await _roundtrips()
	await _generic_moves()
	for route: String in ["keep","fling","trick_capture"]: await _map_route(route)
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors,"routes":routes,"gpu":capture}
	var file:=FileAccess.open(V14+("gpu.json" if capture else "godot.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("FIELD_HELD_V14 ",report.status," checks=",checks," GPU=",capture)
	quit(0 if errors.is_empty() else 1)

func _with_moves(id: StringName, moves: Array, bell: bool) -> CreatureInstance:
	var c:=_make(&"mew",50,{},"hardy",id)
	c.moveset.clear();c.move_ids.clear()
	for move: String in moves: c.add_move(StringName(move),catalogs)
	if bell: c.held_item_id=&"soothe_bell"
	return c

func _roundtrips() -> void:
	for format: String in ["gen9customgame","gen8customgame","gen9calvounifiedv1"]:
		for consumed in [false,true]:
			var c:=_with_moves(&"bell_owner",["growl"],true);c.friendship=100;c.held_item_consumed=consumed
			var service:=_service(c,&"protein");service.owner.inventory.add(&"master_ball")
			check("existing field Bell multiplier still applies",service.use_item(&"protein",c.instance_id).accepted and service.owner.owned_creature(c.instance_id).friendship==(103 if consumed else 104))
			var before:=snapshot(service)
			var session:=Native.new(catalogs,service.owner,format)
			var opened: bool=await session.begin_wild(self,_with_moves(&"bell_wild",["growl"],false),[23,19,29,43])
			check("native Bell start "+format,opened)
			if opened:
				check("entry preserves campaign and physical slot",snapshot(service)==before and session.battle_state().creature(c.instance_id).held_item_consumed==consumed)
				var saved:=session.snapshot();await session.close();session=Native.new(catalogs,service.owner,format)
				check("native Bell restore",await session.restore_saved(self,saved))
				var result: Dictionary=await session.submit("move 1",session.revision)
				check("native Bell ordinary turn projects",result.accepted and session.battle_state().creature(c.instance_id).held_item_consumed==consumed)
				check("capture settles Bell slot without resurrection",(await session.capture(&"master_ball",session.revision)).accepted and service.owner.owned_creature(c.instance_id).held_item_consumed==consumed)
				check("Bell identity preserved",service.owner.owned_creature(c.instance_id).held_item_id==&"soothe_bell")
			await session.close()
	var c:=_with_moves(&"unknown_owner",["growl"],false);c.held_item_id=&"unreviewed_field_item"
	var service:=_service(c,&"protein");var before:=snapshot(service)
	var session:=Native.new(catalogs,service.owner,"gen9calvounifiedv1")
	check("unreviewed item still rejected",not await session.begin_wild(self,_with_moves(&"unknown_wild",["growl"],false),[23,19,29,43]) and session.last_error=="Unknown held item" and snapshot(service)==before)
	await session.close()

func _generic_moves() -> void:
	for move: String in ["fling","trick","knock_off"]:
		var own:=_with_moves(&"generic_own",["growl" if move=="knock_off" else move],true)
		var foe:=_with_moves(&"generic_foe",["knock_off" if move=="knock_off" else "growl"],false)
		var service:=_service(own,&"protein");service.owner.inventory.add(&"master_ball")
		var before:=snapshot(service);var session:=Native.new(catalogs,service.owner,"gen9calvounifiedv1")
		var opened: bool=await session.begin_wild(self,foe,[23,19,29,43]);check("generic move encounter "+move,opened)
		if opened:
			var result: Dictionary=await session.submit("move 1",session.revision)
			check("native generic item event projects "+move,result.accepted and snapshot(service)==before)
			if result.accepted:
				check("Bell removed from actor by native move",session.battle_state().creature(own.instance_id).held_item_consumed)
				if move=="trick":check("Bell goes to recipient",session.battle_state().creature(foe.instance_id).held_item_id==&"soothe_bell" and not session.battle_state().creature(foe.instance_id).held_item_consumed)
				check("generic item state settles",(await session.capture(&"master_ball",session.revision)).accepted)
				check("no Bell resurrection in original slot",service.owner.owned_creature(own.instance_id).held_item_consumed)
				routes.append({"route":move,"projected":true,"settled":true})
		await session.close()

func _drain_view(view: Control) -> void:
	for i in 2000:
		if not view._playback.is_playing():break
		view._playback.advance(0.25)
	await process_frame

func _physical_bells(owner: PlayerCollection) -> int:
	var result:=owner.inventory.quantity(&"soothe_bell")
	for c: CreatureInstance in owner.party.get_creatures()+owner.storage.get_all_creatures():
		if c.held_item_id==&"soothe_bell" and not c.held_item_consumed:result+=1
	return result

func _map_route(route: String) -> void:
	scene=load("res://scenes/visual/field_demo.tscn").instantiate();root.add_child(scene)
	await process_frame;await physics_frame
	var config: Dictionary=scene._active_config.duplicate(true)
	config.encounter_chance_percent=100;config.wild_species_id="wailord";config.wild_min_level=50;config.wild_max_level=50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection=scene.field_collection();var id:=owner.party.get_creatures()[0].instance_id
	var c:=_with_moves(id,["growl","fling","trick"],false);c.friendship=100
	check("real Bell owner",owner.replace_owned_same_identity(c))
	owner.inventory.add(&"soothe_bell",2);owner.inventory.add(&"protein");owner.inventory.add(&"master_ball",2)
	check("real Bell bag opens",scene.toggle_item_bag());var bag=scene._item_bag
	_select(bag,"soothe_bell");check("real Bell equip",bag._apply("equip").accepted)
	_select(bag,"protein");check("real Bell boosts field friendship",bag._apply("use").accepted and owner.owned_creature(id).friendship==104)
	if capture and route=="keep":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		check("Bell bag capture",root.get_texture().get_image().save_png(V14+"bell_bag.png")==OK)
		check("Bell bag fits",bag.position.y>=0 and bag.position.y+bag.size.y<=root.size.y)
	bag.hide();await process_frame
	var bridge=scene._native_battles;bridge.save_path=V14+("gpu_" if capture else "headless_")+route+".json"
	check("Bell field save",bridge.save_game());check("Bell field load",await bridge.load_game())
	scene.player.global_position=Vector2(420,150);await scene._on_player_step_completed(scene.player.global_position)
	var view=bridge.view;view._playback.set_process(false)
	var ready: bool=view.session!=null and view.session.battle_state()!=null
	check("equipped Bell really enters map battle: "+bridge.last_error,ready)
	if not ready:scene.queue_free();await process_frame;return
	check("native receives Bell and trained state",view.session.battle_state().creature(id).held_item_id==&"soothe_bell" and view.session.battle_state().creature(id).evs.attack==10 and view.session.battle_state().creature(id).friendship==104)
	check("Bell battle checkpoint save",bridge.save_game());check("Bell battle checkpoint load",await bridge.load_game());view._playback.set_process(false)
	var choice: String={"keep":"move 1","fling":"move 2","trick_capture":"move 3"}[route]
	var result: Dictionary=await view.choose(choice);check("real Bell action "+route,result.accepted)
	if not result.accepted:
		await view.session.close();scene.queue_free();await process_frame;return
	await _drain_view(view)
	var wild_id: StringName=view.session.battle_state().active_for_side(&"side_b").instance_id
	check("Bell item state checkpoint save",bridge.save_game());check("Bell item state checkpoint load",await bridge.load_game());view._playback.set_process(false)
	check("Bell encounter capture",(await view.adventure_command("master")).accepted)
	await _drain_view(view);await bridge.leave_battle()
	owner=scene.field_collection()
	check("Bell physical count after settlement",_physical_bells(owner)==(1 if route=="fling" else 2))
	check("field trained values survive native settlement",owner.owned_creature(id).friendship==104 and owner.owned_creature(id).evs.attack==10)
	if route!="keep":
		check("no removed Bell in actor",owner.owned_creature(id).held_item_consumed)
		check("post-battle bag opens",scene.toggle_item_bag());bag=scene._item_bag
		var before: int=owner.inventory.quantity(&"soothe_bell")
		check("unequip cannot refund removed Bell",bag.service.unequip(id).accepted and owner.inventory.quantity(&"soothe_bell")==before)
		if route=="trick_capture":
			check("captured recipient owns actual Bell",owner.owned_creature(wild_id).held_item_id==&"soothe_bell" and not owner.owned_creature(wild_id).held_item_consumed)
			check("captured Bell can be returned once",bag.service.unequip(wild_id).accepted and owner.inventory.quantity(&"soothe_bell")==before+1)
		check("physical count after unequipping",_physical_bells(owner)==(1 if route=="fling" else 2))
		bag.hide();await process_frame
	check("settled Bell field save",bridge.save_game());check("settled Bell field load",await bridge.load_game())
	check("saved Bell physical count",_physical_bells(scene.field_collection())==(1 if route=="fling" else 2))
	routes.append({"route":"map_"+route,"physical_bells":_physical_bells(scene.field_collection()),"save_load":true})
	if view.session!=null:await view.session.close()
	scene.queue_free();await process_frame
