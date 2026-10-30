extends "res://tests/gameplay/field_held_v16.gd"

const V20 := "res://.godot/field_held_v20/"
const MISC_IDS: Array[StringName]=[&"black_flute",&"blue_flute",&"blue_scarf",&"fluffy_tail",&"green_scarf",&"pink_scarf",&"poke_doll",&"red_flute",&"red_scarf",&"white_flute",&"yellow_flute",&"yellow_scarf"]

func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done:push_error("FIELD_HELD_V20 timeout");quit(2))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V20)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	if not capture:
		for i in MISC_IDS.size():await _medicine_case(MISC_IDS[i],["keep","fling","trick","knock_off"][i%4],MISC_IDS[i]==&"blue_flute")
	for pair: Array in [["blue_flute","keep"],["blue_scarf","fling"],["fluffy_tail","trick"],["yellow_flute","keep"]]:await _map_misc(StringName(pair[0]),pair[1])
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors,"routes":routes,"gpu":capture}
	var file:=FileAccess.open(V20+("gpu.json" if capture else "godot.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("FIELD_HELD_V20 ",report.status," checks=",checks," GPU=",capture)
	quit(0 if errors.is_empty() else 1)

func _map_misc(id: StringName,route: String) -> void:
	scene=load("res://scenes/visual/field_demo.tscn").instantiate();root.add_child(scene)
	await process_frame;await physics_frame
	var config: Dictionary=scene._active_config.duplicate(true)
	config.encounter_chance_percent=100;config.wild_species_id="wailord";config.wild_min_level=50;config.wild_max_level=50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection=scene.field_collection();var own_id:=owner.party.get_creatures()[0].instance_id
	var c:=_with_moves(own_id,["growl","fling","trick"],false);c.friendship=100
	check("real owner setup",owner.replace_owned_same_identity(c))
	owner.inventory.add(id,3);owner.inventory.add(&"master_ball",2)
	var initial:=_physical_medicine(owner,id)
	check("bag opens",scene.toggle_item_bag());var bag: Control=scene._item_bag
	_select(bag,String(id));check("real equip "+String(id),bag._apply("equip").accepted and _physical_medicine(owner,id)==initial)
	var before:=snapshot(bag.service)
	check("bag use not granted by held metadata",not bag._apply("use").accepted and snapshot(bag.service)==before)
	bag.hide();await process_frame
	var bridge=scene._native_battles;bridge.save_path=V20+("gpu_" if capture else "headless_")+String(id)+".json"
	check("equipped save",bridge.save_game());check("equipped load",await bridge.load_game())
	scene.player.global_position=Vector2(420,150);await scene._on_player_step_completed(scene.player.global_position)
	var view=bridge.view;view._playback.set_process(false)
	var ready: bool=view.session!=null and view.session.battle_state()!=null
	check("new equipped ID enters native: "+bridge.last_error,ready)
	if not ready:scene.queue_free();await process_frame;return
	var choice: String={"keep":"move 1","fling":"move 2","trick":"move 3"}[route]
	var result: Dictionary=await view.choose(choice);check("real item action "+String(id),result.accepted)
	if not result.accepted:await view.session.close();scene.queue_free();await process_frame;return
	await _drain_view(view)
	check("changed item state save",bridge.save_game())
	var loaded: bool=await bridge.load_game();check("changed item state load: "+bridge.last_error,loaded)
	if not loaded:await view.session.close();scene.queue_free();await process_frame;return
	view._playback.set_process(false)
	check("real capture settles transfer",(await view.adventure_command("master")).accepted)
	await _drain_view(view);await bridge.leave_battle()
	owner=scene.field_collection();var expected:=initial-(1 if route=="fling" else 0)
	check("physical units neither lost nor duplicated",_physical_medicine(owner,id)==expected)
	check("post-combat bag opens",scene.toggle_item_bag());bag=scene._item_bag;_select(bag,String(id))
	if id==&"blue_flute":
		status(owner.owned_creature(own_id),&"sleep")
		bridge.clocks[String(own_id)]={"version":"0.10.11","start_time":3,"time":2}
		bag.refresh();_select(bag,String(id))
		check("imported Blue Flute still cures after native settlement",bag._apply("use").accepted and owner.owned_creature(own_id).status_state.persistent_id==&"" and bridge.clocks.is_empty())
		check("field flute remains reusable while another unit is held",_physical_medicine(owner,id)==expected)
		if capture:
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
			check("GPU equipped flute capture",root.get_texture().get_image().save_png(V20+"misc_bag.png")==OK)
	else:
		before=snapshot(bag.service)
		check("unsupported special use stays rejected",not bag._apply("use").accepted and snapshot(bag.service)==before)
	bag.hide();await process_frame
	check("settled field save",bridge.save_game());check("settled field load",await bridge.load_game())
	check("physical units persist",_physical_medicine(scene.field_collection(),id)==expected)
	routes.append({"item_id":String(id),"route":"map_"+route,"special_use_implemented":id==&"blue_flute","physical_units":expected})
	if view.session!=null:await view.session.close()
	scene.queue_free();await process_frame
